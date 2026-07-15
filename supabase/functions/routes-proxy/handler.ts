// Routes プロキシの Google 呼び出し＋費用計上（テスト可能な単位, 旅程Phase 4）。
//
// Deno.serve を持たないため、fetch/計上を注入して単体テストできる（index.ts が
// 本番 deps で呼ぶ）。費用計上のタイミング（places-proxy の Fix4 と同方針）:
// 全入力検証・認証・entitlement・レート制限を通過し、Google へ送信を試みる
// **直前に1回だけ** increment する。timeout や通信例外でも計上済みにする
// （送信を試みたリクエストは保守的に数える）。Google へ送らなかった不正
// リクエストは数えない。集計 RPC 失敗は安全側: Google を呼ばず unavailable にする。
//
// SKU は常に Essentials（policy.ts の方針: routingPreference を送らず、
// travelMode に TWO_WHEELER を使わないため）。

import { mapGoogleStatus, type RoutesErrorKind, safeLogMeta } from "./policy.ts";

export interface GoogleCallDeps {
  fetchFn: (url: string, init: RequestInit) => Promise<Response>;
  incrementUsage: (sku: string) => Promise<void>;
  log?: (meta: Record<string, unknown>) => void;
}

export interface GoogleCallOptions {
  environment: string;
  url: string;
  apiKey: string;
  fieldMask: string;
  timeoutMs: number;
  action: string;
  travelMode?: string;
  body: string;
  transform: (data: unknown) => unknown;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function errorResponse(kind: RoutesErrorKind, status: number): Response {
  return jsonResponse({ error: kind }, status); // type だけ返す（機微情報なし）
}

export async function callGoogle(
  opts: GoogleCallOptions,
  deps: GoogleCallDeps,
): Promise<Response> {
  // 1) 送信を試みる直前に 1 回だけ計上する（timeout/例外でも計上済みにする）。
  try {
    await deps.incrementUsage("compute_routes_essentials");
  } catch {
    return errorResponse("unavailable", 503);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), opts.timeoutMs);
  let status = 0;
  try {
    const res = await deps.fetchFn(opts.url, {
      method: "POST",
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
        travelMode: opts.travelMode,
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
      travelMode: opts.travelMode,
      environment: opts.environment,
      status,
    }));
    return jsonResponse(out, 200);
  } catch (e) {
    const kind: RoutesErrorKind =
      (e instanceof DOMException && e.name === "AbortError")
        ? "timeout"
        : "upstream_error";
    deps.log?.(safeLogMeta({
      action: opts.action,
      travelMode: opts.travelMode,
      environment: opts.environment,
      status,
      errorKind: kind,
    }));
    return errorResponse(kind, kind === "timeout" ? 504 : 502);
  } finally {
    clearTimeout(timer);
  }
}

// Google Compute Routes 応答 → 最小 DTO（durationMinutes/distanceMeters/
// fareText/transitSteps）。Dart 側 RouteLiveResult と同じ JSON 契約:
// {durationMinutes, distanceMeters, fareText|null, transitSteps: [...]}
export function transformComputeRoutes(data: unknown): unknown {
  const routes = (data as { routes?: unknown[] })?.routes ?? [];
  const route = (routes[0] ?? {}) as Record<string, unknown>;

  const durationRaw = typeof route.duration === "string" ? route.duration : "0s";
  const durationSeconds = parseInt(durationRaw.replace(/s$/, ""), 10) || 0;
  const durationMinutes = Math.round(durationSeconds / 60);

  const distanceMeters =
    typeof route.distanceMeters === "number" ? route.distanceMeters : 0;

  const localizedValues =
    (route.localizedValues ?? {}) as Record<string, unknown>;
  const transitFareLocalized =
    (localizedValues.transitFare ?? {}) as { text?: string };
  const fareText = typeof transitFareLocalized.text === "string"
    ? transitFareLocalized.text
    : null;

  const legs = (route.legs ?? []) as Array<Record<string, unknown>>;
  const transitSteps: Array<Record<string, unknown>> = [];
  let walkSeconds = 0;
  for (const leg of legs) {
    const steps = (leg.steps ?? []) as Array<Record<string, unknown>>;
    for (const step of steps) {
      // 徒歩ステップの所要を合計する（「徒歩 合計N分」の表示に使う, item 4）。
      if (step.travelMode === "WALK") {
        const raw = typeof step.staticDuration === "string"
          ? step.staticDuration
          : "0s";
        walkSeconds += parseInt(raw.replace(/s$/, ""), 10) || 0;
      }
      const details = step.transitDetails as Record<string, unknown> | undefined;
      if (!details) continue;
      const line = (details.transitLine ?? {}) as Record<string, unknown>;
      const vehicle = (line.vehicle ?? {}) as { type?: string };
      const stopDetails = (details.stopDetails ?? {}) as Record<string, unknown>;
      const departureStop =
        (stopDetails.departureStop ?? {}) as { name?: string };
      const arrivalStop = (stopDetails.arrivalStop ?? {}) as { name?: string };
      const localized =
        (details.localizedValues ?? {}) as Record<string, unknown>;
      const depLocal = (localized.departureTime ?? {}) as {
        time?: { text?: string };
      };
      const arrLocal = (localized.arrivalTime ?? {}) as {
        time?: { text?: string };
      };
      transitSteps.push({
        lineName: typeof line.name === "string" ? line.name : "",
        lineNameShort: typeof line.nameShort === "string"
          ? line.nameShort
          : null,
        vehicleType: typeof vehicle.type === "string" ? vehicle.type : null,
        headsign: typeof details.headsign === "string"
          ? details.headsign
          : null,
        departureStopName: typeof departureStop.name === "string"
          ? departureStop.name
          : null,
        arrivalStopName: typeof arrivalStop.name === "string"
          ? arrivalStop.name
          : null,
        departureTime: typeof depLocal.time?.text === "string"
          ? depLocal.time.text
          : null,
        arrivalTime: typeof arrLocal.time?.text === "string"
          ? arrLocal.time.text
          : null,
      });
    }
  }

  return {
    durationMinutes,
    distanceMeters,
    walkMinutes: Math.round(walkSeconds / 60),
    fareText,
    transitSteps,
  };
}
