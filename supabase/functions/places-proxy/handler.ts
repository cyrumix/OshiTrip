// Places プロキシの Google 呼び出し＋費用計上（テスト可能な単位, 旅程Phase 3）。
//
// Deno.serve を持たないため、fetch/計上を注入して単体テストできる（index.ts が
// 本番 deps で呼ぶ）。費用計上のタイミング（Fix4）: 全入力検証・認証・レート制限を
// 通過し、Google へ送信を試みる**直前に1回だけ** increment する。timeout や通信
// 例外でも計上済みにする（送信を試みたリクエストは保守的に数える）。Google へ
// 送らなかった不正リクエストは数えない。集計 RPC 失敗は安全側: Google を呼ばず
// unavailable にする。

import {
  mapGoogleStatus,
  type PlacesErrorKind,
  safeLogMeta,
  sanitizeAttributions,
} from "./policy.ts";

export interface GoogleCallDeps {
  // 注入された fetch（AbortSignal を尊重する）。
  fetchFn: (url: string, init: RequestInit) => Promise<Response>;
  // 費用計上（失敗時は throw する）。
  incrementUsage: (sku: string) => Promise<void>;
  // 非機微メタのみを受けるログ関数（任意）。
  log?: (meta: Record<string, unknown>) => void;
}

export interface GoogleCallOptions {
  environment: string;
  url: string;
  method: "GET" | "POST";
  apiKey: string;
  fieldMask: string;
  timeoutMs: number;
  sku: string;
  action: string;
  body?: string;
  transform: (data: unknown) => unknown;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function errorResponse(kind: PlacesErrorKind, status: number): Response {
  return jsonResponse({ error: kind }, status); // type だけ返す（機微情報なし）
}

export async function callGoogle(
  opts: GoogleCallOptions,
  deps: GoogleCallDeps,
): Promise<Response> {
  // 1) 送信を試みる直前に 1 回だけ計上する（timeout/例外でも計上済みにする）。
  try {
    await deps.incrementUsage(opts.sku);
  } catch {
    // 集計 RPC 失敗 → 安全側: Google を呼ばず unavailable。
    return errorResponse("unavailable", 503);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), opts.timeoutMs);
  let status = 0;
  try {
    const res = await deps.fetchFn(opts.url, {
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
    if (!res.ok) {
      const kind = mapGoogleStatus(res.status);
      deps.log?.(safeLogMeta({
        action: opts.action,
        sku: opts.sku,
        environment: opts.environment,
        status,
        errorKind: kind,
      }));
      return errorResponse(kind, status === 429 ? 429 : 502);
    }
    const data = await res.json();
    const out = opts.transform(data);
    deps.log?.(safeLogMeta({
      action: opts.action,
      sku: opts.sku,
      environment: opts.environment,
      status,
      suggestionCount: countSuggestions(out),
    }));
    return jsonResponse(out, 200);
  } catch (e) {
    const kind: PlacesErrorKind =
      (e instanceof DOMException && e.name === "AbortError")
        ? "timeout"
        : "upstream_error";
    deps.log?.(safeLogMeta({
      action: opts.action,
      sku: opts.sku,
      environment: opts.environment,
      status,
      errorKind: kind,
    }));
    return errorResponse(kind, kind === "timeout" ? 504 : 502);
  } finally {
    clearTimeout(timer);
  }
}

function countSuggestions(out: unknown): number | undefined {
  if (out && typeof out === "object" && "suggestions" in out) {
    const s = (out as { suggestions?: unknown }).suggestions;
    return Array.isArray(s) ? s.length : undefined;
  }
  return undefined;
}

// Google 応答 → 最小 DTO（Place ID・表示テキストのみ）。名称・住所は一時表示用。
export function transformAutocomplete(data: unknown): unknown {
  const suggestions =
    (data as { suggestions?: unknown[] })?.suggestions ?? [];
  return {
    suggestions: suggestions.map((s) => {
      const p = (s as { placePrediction?: Record<string, unknown> })
        .placePrediction ?? {};
      const structured = (p.structuredFormat ?? {}) as Record<string, unknown>;
      const main = (structured.mainText ?? {}) as { text?: string };
      const secondary = (structured.secondaryText ?? {}) as { text?: string };
      const text = (p.text ?? {}) as { text?: string };
      return {
        placeId: p.placeId ?? "",
        primaryText: main.text ?? text.text ?? "",
        secondaryText: secondary.text ?? null,
      };
    }),
  };
}

// Place Details → 最小 DTO。attributions は許可フィールドだけへ変換（透過しない）。
export function transformDetails(data: unknown): unknown {
  const d = (data ?? {}) as Record<string, unknown>;
  const displayName = (d.displayName ?? {}) as { text?: string };
  return {
    placeId: d.id ?? "",
    displayName: displayName.text ?? null,
    formattedAddress: d.formattedAddress ?? null,
    attributions: sanitizeAttributions(d.attributions),
  };
}
