// Places プロキシ Edge Function（旅程Phase 3 / ADR-0010 §2/§3）。
//
// Web Service 用 Google API キーはこのサーバー側だけに置き、アプリへ埋め込まない。
// このプロキシは以下を強制する:
//   - Supabase 認証（platform verify_jwt + コード内 getUser 二重確認）
//   - ユーザー別レート制限（places_rate_limit / RPC）
//   - Field Mask allowlist（`*` と非許可フィールドを拒否）
//   - リクエスト timeout
//   - Google エラーの型付き変換
//   - 機能 kill switch（環境変数）
//   - ログから検索文・住所・座標・Place ID を除外（safeLogMeta のみログ）
//   - 費用集計（api_usage_daily / RPC）
//   - Google 由来の名称・住所を共有 DB へ書かない（この関数は一切 DB 書込みしない）
//
// 注意: 本環境（Docker/Deno/Supabase なし）では未デプロイ・未実行の成果物。
// import・API 形状は Supabase Edge Functions（Deno）標準に合わせている。

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  AUTOCOMPLETE_ALLOWED_FIELDS,
  buildFieldMask,
  fieldMaskError,
  isKillSwitchOn,
  isSearchableInput,
  mapGoogleStatus,
  PLACE_DETAILS_ALLOWED_FIELDS,
  type PlacesErrorKind,
  safeLogMeta,
} from "./policy.ts";

const GOOGLE_BASE = "https://places.googleapis.com/v1";

function env(name: string, fallback = ""): string {
  return Deno.env.get(name) ?? fallback;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function errorResponse(kind: PlacesErrorKind, status: number): Response {
  // メッセージに機微情報を含めない（type だけ返す）。
  return jsonResponse({ error: kind }, status);
}

Deno.serve(async (req: Request): Promise<Response> => {
  const environment = env("ENVIRONMENT", "development");

  if (req.method !== "POST") {
    return errorResponse("invalid_request", 405);
  }

  // 1) kill switch
  if (isKillSwitchOn(env("PLACES_KILL_SWITCH"))) {
    return errorResponse("unavailable", 503);
  }

  // 2) 認証（ユーザーを確定）
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabaseUrl = env("SUPABASE_URL");
  const anonKey = env("SUPABASE_ANON_KEY");
  const serviceKey = env("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return errorResponse("unavailable", 503);
  }
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData } = await userClient.auth.getUser();
  const user = userData?.user;
  if (!user) {
    return errorResponse("unauthorized", 401);
  }

  // 3) レート制限（内容は保存しない・件数のみ）。service role で RPC を呼ぶ。
  const admin = createClient(supabaseUrl, serviceKey);
  const rateLimit = parseInt(env("PLACES_RATE_LIMIT", "60"), 10);
  const rateWindow = parseInt(env("PLACES_RATE_WINDOW_SECONDS", "60"), 10);
  const { data: allowed, error: rlError } = await admin.rpc(
    "check_and_increment_rate_limit",
    { p_owner: user.id, p_limit: rateLimit, p_window_seconds: rateWindow },
  );
  if (rlError) return errorResponse("unavailable", 503);
  if (allowed === false) return errorResponse("rate_limited", 429);

  // 4) 入力の解釈
  let payload: {
    action?: string;
    input?: string;
    placeId?: string;
    sessionToken?: string;
    locationBias?: unknown;
  };
  try {
    payload = await req.json();
  } catch {
    return errorResponse("invalid_request", 400);
  }
  const action = payload.action;
  const sessionToken = payload.sessionToken;
  if (!sessionToken) return errorResponse("invalid_request", 400);

  const apiKey = env("GOOGLE_PLACES_API_KEY");
  if (!apiKey) return errorResponse("unavailable", 503);

  const timeoutMs = parseInt(env("PLACES_TIMEOUT_MS", "5000"), 10);

  if (action === "autocomplete") {
    const input = payload.input ?? "";
    if (!isSearchableInput(input)) {
      return errorResponse("invalid_request", 400);
    }
    const mask = buildFieldMask(AUTOCOMPLETE_ALLOWED_FIELDS);
    if (fieldMaskError(mask.split(","), AUTOCOMPLETE_ALLOWED_FIELDS)) {
      return errorResponse("invalid_request", 400);
    }
    return await callGoogle({
      environment,
      admin,
      url: `${GOOGLE_BASE}/places:autocomplete`,
      method: "POST",
      apiKey,
      fieldMask: mask,
      timeoutMs,
      sku: "autocomplete",
      body: JSON.stringify({
        input,
        sessionToken,
        locationBias: payload.locationBias ?? undefined,
      }),
      transform: (data) => transformAutocomplete(data),
    });
  }

  if (action === "details") {
    const placeId = payload.placeId ?? "";
    if (!placeId) return errorResponse("invalid_request", 400);
    const mask = buildFieldMask(PLACE_DETAILS_ALLOWED_FIELDS);
    if (fieldMaskError(mask.split(","), PLACE_DETAILS_ALLOWED_FIELDS)) {
      return errorResponse("invalid_request", 400);
    }
    const url = `${GOOGLE_BASE}/places/${encodeURIComponent(placeId)}` +
      `?sessionToken=${encodeURIComponent(sessionToken)}`;
    return await callGoogle({
      environment,
      admin,
      url,
      method: "GET",
      apiKey,
      fieldMask: mask,
      timeoutMs,
      sku: "place_details",
      transform: (data) => transformDetails(data),
    });
  }

  return errorResponse("invalid_request", 400);
});

async function callGoogle(opts: {
  environment: string;
  admin: ReturnType<typeof createClient>;
  url: string;
  method: "GET" | "POST";
  apiKey: string;
  fieldMask: string;
  timeoutMs: number;
  sku: string;
  body?: string;
  transform: (data: unknown) => unknown;
}): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), opts.timeoutMs);
  let status = 0;
  let errorKind: PlacesErrorKind | undefined;
  try {
    const res = await fetch(opts.url, {
      method: opts.method,
      signal: controller.signal,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": opts.apiKey,
        "X-Goog-FieldMask": opts.fieldMask,
      },
      body: opts.body,
    });
    status = res.status;
    // 課金対象の Google 呼び出しを1件として集計（内容は保存しない）。
    await opts.admin.rpc("increment_api_usage", {
      p_environment: opts.environment,
      p_service: "places",
      p_sku: opts.sku,
    });
    if (!res.ok) {
      errorKind = mapGoogleStatus(res.status);
      logSafe(opts, status, undefined, errorKind);
      return errorResponse(errorKind, status === 429 ? 429 : 502);
    }
    const data = await res.json();
    const out = opts.transform(data);
    logSafe(opts, status, countSuggestions(out), undefined);
    return jsonResponse(out, 200);
  } catch (e) {
    errorKind = (e instanceof DOMException && e.name === "AbortError")
      ? "timeout"
      : "upstream_error";
    logSafe(opts, status, undefined, errorKind);
    return errorResponse(errorKind, errorKind === "timeout" ? 504 : 502);
  } finally {
    clearTimeout(timer);
  }
}

function logSafe(
  opts: { sku: string; environment: string },
  status: number,
  suggestionCount: number | undefined,
  errorKind: PlacesErrorKind | undefined,
): void {
  // 検索文・住所・座標・Place ID を含めない安全なメタだけ出す。
  console.log(JSON.stringify(safeLogMeta({
    action: opts.sku === "autocomplete" ? "autocomplete" : "details",
    sku: opts.sku,
    environment: opts.environment,
    status,
    suggestionCount,
    errorKind,
  })));
}

function countSuggestions(out: unknown): number | undefined {
  if (out && typeof out === "object" && "suggestions" in out) {
    const s = (out as { suggestions?: unknown }).suggestions;
    return Array.isArray(s) ? s.length : undefined;
  }
  return undefined;
}

// Google 応答 → 最小 DTO（Place ID・表示テキストのみ）。名称・住所は一時表示用。
function transformAutocomplete(data: unknown): unknown {
  const suggestions =
    (data as { suggestions?: unknown[] })?.suggestions ?? [];
  return {
    suggestions: suggestions.map((s) => {
      const p = (s as { placePrediction?: Record<string, unknown> })
        .placePrediction ?? {};
      const structured = (p.structuredFormat ?? {}) as Record<string, unknown>;
      const main = (structured.mainText ?? {}) as { text?: string };
      const secondary =
        (structured.secondaryText ?? {}) as { text?: string };
      const text = (p.text ?? {}) as { text?: string };
      return {
        placeId: p.placeId ?? "",
        primaryText: main.text ?? text.text ?? "",
        secondaryText: secondary.text ?? null,
      };
    }),
  };
}

function transformDetails(data: unknown): unknown {
  const d = (data ?? {}) as Record<string, unknown>;
  const displayName = (d.displayName ?? {}) as { text?: string };
  return {
    placeId: d.id ?? "",
    displayName: displayName.text ?? null,
    formattedAddress: d.formattedAddress ?? null,
    attributions: Array.isArray(d.attributions) ? d.attributions : [],
  };
}
