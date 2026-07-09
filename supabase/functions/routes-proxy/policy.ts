// Routes プロキシの純粋な方針ロジック（旅程Phase 4 / ADR-0010 §8・
// itinerary-plan-spec §6.2/§6.3/§8.3）。
//
// ここはネットワーク・DB に触れない純粋関数だけを置く。Field Mask allowlist は
// クライアント側 Dart（routes_field_mask.dart）と同じ許可集合を根拠にする
// （どちらか一方をすり抜けても、もう一方で拒否できるようにする）。
//
// 確認日: 2026-07-09（developers.google.com/maps/documentation/routes/
// usage-and-billing）。Compute Routes の SKU は Essentials/Pro/Enterprise の
// 3層で、"Essentials: 基本機能・中間waypoint最大10"、"Pro: TRAFFIC_AWARE /
// TRAFFIC_AWARE_OPTIMAL route modifier使用時"、"Enterprise: two-wheel routing
// 等の高度機能使用時"。このプロキシは routingPreference を一切送らず、
// travelMode に TWO_WHEELER を使わない（BICYCLE のみ）ため、対応4手段は常に
// 最安の Essentials に収まる。
//
// 公共交通の制約（developers.google.com/maps/documentation/routes/
// transit-route, 2026-07-09）: departureTime/arrivalTime は RFC3339 UTC 必須、
// 対応範囲は現在時刻から過去7日〜未来100日。中間waypoint非対応。運賃は全ステップ
// で算定可能な場合のみ返る。

export const ROUTES_ALLOWED_FIELDS = [
  "routes.duration",
  "routes.distanceMeters",
  "routes.localizedValues.transitFare",
  "routes.legs.steps.transitDetails.transitLine.name",
  "routes.legs.steps.transitDetails.transitLine.nameShort",
  "routes.legs.steps.transitDetails.transitLine.vehicle.type",
  "routes.legs.steps.transitDetails.headsign",
  "routes.legs.steps.transitDetails.stopDetails.departureStop.name",
  "routes.legs.steps.transitDetails.stopDetails.arrivalStop.name",
] as const;

/// アプリが対応する移動手段（taxi/flight/other は手動入力のまま、Routesを
/// 呼ばない, itinerary-plan-spec §6.1）。Google の travelMode 表記へ変換する。
export const ROUTES_TRAVEL_MODE: Record<string, string> = {
  walking: "WALK",
  transit: "TRANSIT",
  driving: "DRIVE",
  bicycling: "BICYCLE", // TWO_WHEELER は使わない（Enterprise SKU回避）。
};

export function fieldMaskError(
  fields: string[],
  allowed: readonly string[],
): string | null {
  if (fields.length === 0) return "empty field mask";
  const set = new Set(allowed);
  for (const raw of fields) {
    const f = raw.trim();
    if (f.length === 0) return "empty field in mask";
    if (f === "*") return "wildcard field mask is forbidden";
    if (!set.has(f)) return `field not allowed: ${f}`;
  }
  return null;
}

export function buildFieldMask(allowed: readonly string[]): string {
  return allowed.join(",");
}

export type RoutesErrorKind =
  | "unavailable" // kill switch / 未設定 / 予算上限 / entitlement無し
  | "rate_limited" // ユーザー別レート上限
  | "unauthorized" // 未認証
  | "not_entitled" // 認証済みだが非プレミアム
  | "invalid_request" // 入力不正（対応外mode・時刻範囲外・endpoint欠落等）
  | "timeout" // 上流タイムアウト
  | "upstream_error"; // Google 側エラー

export function mapGoogleStatus(status: number): RoutesErrorKind {
  if (status === 429) return "rate_limited";
  if (status === 400) return "invalid_request";
  if (status === 401 || status === 403) return "unavailable";
  return "upstream_error";
}

export function isKillSwitchOn(value: string | undefined): boolean {
  if (!value) return false;
  const v = value.trim().toLowerCase();
  return v === "1" || v === "true" || v === "on";
}

/// Google Routes transit の対応範囲（過去7日〜未来100日, 確認済み）。
export const ROUTES_MIN_PAST_DAYS = 7;
export const ROUTES_MAX_FUTURE_DAYS = 100;

/// 代表出発日時が transit の対応範囲内かを検証する（範囲外は明示的に拒否する）。
export function isWithinTransitTimeRange(
  representativeUtc: Date,
  now: Date,
): boolean {
  const diffDays =
    (representativeUtc.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
  return diffDays >= -ROUTES_MIN_PAST_DAYS && diffDays <= ROUTES_MAX_FUTURE_DAYS;
}

/// 経路取得の1地点として有効か（Place ID または緯度経度のどちらかが必要）。
export function hasValidLocation(
  endpoint: { placeId?: string; latitude?: number; longitude?: number } | undefined,
): boolean {
  if (!endpoint) return false;
  if (typeof endpoint.placeId === "string" && endpoint.placeId.length > 0) {
    return true;
  }
  return typeof endpoint.latitude === "number" &&
    typeof endpoint.longitude === "number";
}

/// ログに出してよい非機微メタだけを抽出する（origin/destination・座標・
/// Place ID・運賃額は決して含めない）。
export function safeLogMeta(meta: {
  action: string;
  travelMode?: string;
  environment: string;
  status: number;
  errorKind?: RoutesErrorKind;
}): Record<string, unknown> {
  return {
    action: meta.action,
    travel_mode: meta.travelMode ?? null,
    environment: meta.environment,
    status: meta.status,
    error_kind: meta.errorKind ?? null,
  };
}
