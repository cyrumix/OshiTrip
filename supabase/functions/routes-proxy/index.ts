// Routes プロキシ Edge Function（旅程Phase 4 / ADR-0010 §2/§3・
// itinerary-plan-spec §6/§8.3）。
//
// Web Service 用 Google API キーはこのサーバー側だけに置き、アプリへ埋め込まない。
// このプロキシは以下を強制する:
//   - Supabase 認証（platform verify_jwt + コード内 getUser 二重確認）
//   - **プレミアムentitlement検証は既定で無効**（現仕様: 全認証ユーザーが経路取得可）。
//     ROUTES_REQUIRE_PREMIUM=true の環境でのみ has_premium_routes_entitlement RPC で
//     検証し、非エンタイトルは not_entitled を返す。未設定/false なら RPC を呼ばず
//     許可する。将来のプレミアム化に備え RPC・テーブルは残す（D-232）
//   - ユーザー別レート制限（routes_rate_limit / RPC）
//   - 対応手段の限定（walking/transit/driving/bicycling のみ。taxi/flight/other
//     はこの関数に到達させない、クライアント側でも呼ばない設計だがサーバーでも
//     拒否する）
//   - transit の時刻範囲検証（過去7日〜未来100日、範囲外は invalid_request）
//   - Field Mask allowlist（`*` と非許可フィールドを拒否）。routingPreference は
//     一切送らず、travelMode に TWO_WHEELER を使わない（SKU=Essentials維持）
//   - リクエスト timeout・Google エラーの型付き変換
//   - 機能 kill switch（環境変数）
//   - ログから origin/destination・座標・Place ID・運賃額を除外（safeLogMeta のみ）
//   - 費用集計（api_usage_daily / RPC・件数のみ）: Google 送信を試みる直前に1回
//   - Google 由来の経路内容を共有DBへ一切書き込まない（この関数はDBへ書込みしない）
//
// 注意: 本環境（Docker/Deno/Supabase なし）では未デプロイ・未実行の成果物。
// Google 呼び出し＋計上の中核は handler.ts（fetch/RPC 注入で単体テスト可能）。

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  buildFieldMask,
  fieldMaskError,
  hasValidLocation,
  isFlagOn,
  isKillSwitchOn,
  isWithinTransitTimeRange,
  premiumGateError,
  ROUTES_ALLOWED_FIELDS,
  ROUTES_TRAVEL_MODE,
} from "./policy.ts";
import {
  callGoogle,
  errorResponse,
  type GoogleCallDeps,
  transformComputeRoutes,
} from "./handler.ts";

const GOOGLE_BASE = "https://routes.googleapis.com";

function env(name: string, fallback = ""): string {
  return Deno.env.get(name) ?? fallback;
}

interface RouteEndpointPayload {
  placeId?: string;
  latitude?: number;
  longitude?: number;
}

Deno.serve(async (req: Request): Promise<Response> => {
  const environment = env("ENVIRONMENT", "development");

  if (req.method !== "POST") return errorResponse("invalid_request", 405);

  // 1) kill switch
  if (isKillSwitchOn(env("ROUTES_KILL_SWITCH"))) {
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

  const admin = createClient(supabaseUrl, serviceKey);

  // 3) entitlement（現仕様: 既定で全認証ユーザー可）。
  //    ROUTES_REQUIRE_PREMIUM=true の環境でのみ has_premium_routes_entitlement を
  //    サーバーで検証する（クライアントの主張は信用しない）。未設定/false なら
  //    RPC を呼ばず認証済みユーザーを許可する。将来のプレミアム化に備え RPC・
  //    テーブルは残す（D-232）。
  const requirePremium = isFlagOn(env("ROUTES_REQUIRE_PREMIUM"));
  let entitled = false;
  if (requirePremium) {
    const { data, error: entError } = await admin.rpc(
      "has_premium_routes_entitlement",
      { p_owner: user.id },
    );
    if (entError) return errorResponse("unavailable", 503);
    entitled = data === true;
  }
  const gate = premiumGateError(requirePremium, entitled);
  if (gate) return errorResponse(gate, 403);

  // 4) レート制限（内容は保存しない・件数のみ）。
  const rateLimit = parseInt(env("ROUTES_RATE_LIMIT", "30"), 10);
  const rateWindow = parseInt(env("ROUTES_RATE_WINDOW_SECONDS", "60"), 10);
  const { data: allowed, error: rlError } = await admin.rpc(
    "check_and_increment_routes_rate_limit",
    { p_owner: user.id, p_limit: rateLimit, p_window_seconds: rateWindow },
  );
  if (rlError) return errorResponse("unavailable", 503);
  if (allowed === false) return errorResponse("rate_limited", 429);

  // 5) 入力の解釈
  let payload: {
    origin?: RouteEndpointPayload;
    destination?: RouteEndpointPayload;
    travelMode?: string;
    representativeDepartureUtc?: string;
    languageCode?: string;
    regionCode?: string;
    units?: string;
  };
  try {
    payload = await req.json();
  } catch {
    return errorResponse("invalid_request", 400);
  }

  const googleMode = payload.travelMode
    ? ROUTES_TRAVEL_MODE[payload.travelMode]
    : undefined;
  if (!googleMode) return errorResponse("invalid_request", 400); // taxi/flight/other等は非対応

  if (
    !hasValidLocation(payload.origin) || !hasValidLocation(payload.destination)
  ) {
    return errorResponse("invalid_request", 400);
  }

  const now = new Date();
  const representativeUtc = payload.representativeDepartureUtc
    ? new Date(payload.representativeDepartureUtc)
    : now;
  if (isNaN(representativeUtc.getTime())) {
    return errorResponse("invalid_request", 400);
  }
  if (
    googleMode === "TRANSIT" &&
    !isWithinTransitTimeRange(representativeUtc, now)
  ) {
    return errorResponse("invalid_request", 400); // 過去7日〜未来100日の範囲外
  }

  const mask = buildFieldMask(ROUTES_ALLOWED_FIELDS);
  if (fieldMaskError(mask.split(","), ROUTES_ALLOWED_FIELDS)) {
    return errorResponse("invalid_request", 400);
  }

  const apiKey = env("GOOGLE_ROUTES_API_KEY");
  if (!apiKey) return errorResponse("unavailable", 503);
  const timeoutMs = parseInt(env("ROUTES_TIMEOUT_MS", "5000"), 10);

  function waypoint(e: RouteEndpointPayload) {
    if (e.placeId) return { placeId: e.placeId };
    return { location: { latLng: { latitude: e.latitude, longitude: e.longitude } } };
  }

  // 経路案内・地名は日本語優先、国内利用・メートル法（item 2/8）。クライアントの
  // 指定を優先しつつ、安全側の既定（ja/JP/METRIC）へフォールバックする。
  const units = payload.units === "IMPERIAL" ? "IMPERIAL" : "METRIC";
  const body: Record<string, unknown> = {
    origin: waypoint(payload.origin!),
    destination: waypoint(payload.destination!),
    travelMode: googleMode,
    languageCode: payload.languageCode ?? "ja",
    regionCode: payload.regionCode ?? "JP",
    units,
    // routingPreference は意図的に送らない（TRAFFIC_AWARE系を避けEssentials
    // SKUを維持する, policy.ts）。
  };
  if (googleMode === "TRANSIT") {
    body.departureTime = representativeUtc.toISOString();
  }

  const deps: GoogleCallDeps = {
    fetchFn: (url, init) => fetch(url, init),
    incrementUsage: async (sku) => {
      const { error } = await admin.rpc("increment_api_usage", {
        p_environment: environment,
        p_service: "routes",
        p_sku: sku,
      });
      if (error) throw error;
    },
    log: (meta) => console.log(JSON.stringify(meta)),
  };

  return await callGoogle({
    environment,
    url: `${GOOGLE_BASE}/directions/v2:computeRoutes`,
    apiKey,
    fieldMask: mask,
    timeoutMs,
    action: "compute_routes",
    travelMode: payload.travelMode,
    body: JSON.stringify(body),
    transform: transformComputeRoutes,
  }, deps);
});
