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
//   - 費用集計（api_usage_daily / RPC・件数のみ）: Google 送信を試みる直前に1回
//     （timeout/例外でも計上。集計 RPC 失敗は安全側で unavailable, Fix4）
//   - Google 由来の名称・住所を共有 DB へ書かない（この関数は一切 DB 書込みしない）
//
// 注意: 本環境（Docker/Deno/Supabase なし）では未デプロイ・未実行の成果物。
// Google 呼び出し＋計上の中核は handler.ts（fetch/RPC 注入で単体テスト可能）。

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  AUTOCOMPLETE_ALLOWED_FIELDS,
  buildFieldMask,
  fieldMaskError,
  isKillSwitchOn,
  isSearchableInput,
  PLACE_DETAILS_ALLOWED_FIELDS,
} from "./policy.ts";
import {
  callGoogle,
  errorResponse,
  type GoogleCallDeps,
  transformAutocomplete,
  transformDetails,
} from "./handler.ts";

const GOOGLE_BASE = "https://places.googleapis.com/v1";

function env(name: string, fallback = ""): string {
  return Deno.env.get(name) ?? fallback;
}

Deno.serve(async (req: Request): Promise<Response> => {
  const environment = env("ENVIRONMENT", "development");

  if (req.method !== "POST") return errorResponse("invalid_request", 405);

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
  if (!user) return errorResponse("unauthorized", 401);

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

  // 費用計上（送信直前に1回。RPC 失敗は handler 側で unavailable へ倒す）。
  const deps: GoogleCallDeps = {
    fetchFn: (url, init) => fetch(url, init),
    incrementUsage: async (sku) => {
      const { error } = await admin.rpc("increment_api_usage", {
        p_environment: environment,
        p_service: "places",
        p_sku: sku,
      });
      if (error) throw error;
    },
    log: (meta) => console.log(JSON.stringify(meta)),
  };

  if (action === "autocomplete") {
    const input = payload.input ?? "";
    if (!isSearchableInput(input)) return errorResponse("invalid_request", 400);
    const mask = buildFieldMask(AUTOCOMPLETE_ALLOWED_FIELDS);
    if (fieldMaskError(mask.split(","), AUTOCOMPLETE_ALLOWED_FIELDS)) {
      return errorResponse("invalid_request", 400);
    }
    return await callGoogle({
      environment,
      url: `${GOOGLE_BASE}/places:autocomplete`,
      method: "POST",
      apiKey,
      fieldMask: mask,
      timeoutMs,
      sku: "autocomplete",
      action: "autocomplete",
      body: JSON.stringify({
        input,
        sessionToken,
        locationBias: payload.locationBias ?? undefined,
      }),
      transform: transformAutocomplete,
    }, deps);
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
      url,
      method: "GET",
      apiKey,
      fieldMask: mask,
      timeoutMs,
      sku: "place_details",
      action: "details",
      transform: transformDetails,
    }, deps);
  }

  return errorResponse("invalid_request", 400);
});
