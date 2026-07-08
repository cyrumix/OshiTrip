// Places プロキシの純粋な方針ロジック（旅程Phase 3 / ADR-0010 §2/§6）。
//
// ここはネットワーク・DB に触れない純粋関数だけを置く。Field Mask allowlist は
// クライアント側 Dart（places_field_mask.dart）と同じ許可集合を根拠にする
// （どちらか一方をすり抜けても、もう一方で拒否できるようにする）。
//
// 注意: この関数群はログへ検索文・住所・座標・Place ID を一切出さない設計を
// 支える。ログには件数・ステータス・SKU など非機微な値だけを載せる。

/// Place Details (New) で要求してよいフィールド（決定 2026-07-08）。
/// displayName は Pro SKU だが名称表示のため許容。座標・写真・電話・営業時間・
/// 評価・レビュー・primary type は含めない（allowlist 外＝拒否）。
export const PLACE_DETAILS_ALLOWED_FIELDS = [
  "id",
  "displayName",
  "formattedAddress",
  "attributions",
] as const;

/// Autocomplete (New) の応答 Field Mask（候補表示に必要な最小限）。
/// placeId（永続化可）と表示テキストのみ。
export const AUTOCOMPLETE_ALLOWED_FIELDS = [
  "suggestions.placePrediction.placeId",
  "suggestions.placePrediction.text.text",
  "suggestions.placePrediction.structuredFormat.mainText.text",
  "suggestions.placePrediction.structuredFormat.secondaryText.text",
] as const;

/// Field Mask を検証する。問題があれば理由、無ければ null。
/// 拒否: 空・`*`（ワイルドカード）・allowlist 外・空要素。
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

/// allowlist から本番用 Field Mask 文字列を組む（空白なしカンマ区切り）。
export function buildFieldMask(allowed: readonly string[]): string {
  return allowed.join(",");
}

export type PlacesErrorKind =
  | "unavailable" // kill switch / 未設定 / 予算上限
  | "rate_limited" // ユーザー別レート上限
  | "unauthorized" // 未認証
  | "invalid_request" // 入力不正（3文字未満・Field Mask 不正等）
  | "timeout" // 上流タイムアウト
  | "upstream_error"; // Google 側エラー

/// Google Places の HTTP ステータスを型付きの種別へ変換する。
/// 本文（検索文・住所等を含み得る）はここで捨て、ログ・レスポンスへ流さない。
export function mapGoogleStatus(status: number): PlacesErrorKind {
  if (status === 429) return "rate_limited";
  if (status === 400) return "invalid_request";
  if (status === 401 || status === 403) return "unavailable";
  return "upstream_error";
}

/// 機能 kill switch（環境変数）。'1'/'true'/'on' で停止。
export function isKillSwitchOn(value: string | undefined): boolean {
  if (!value) return false;
  const v = value.trim().toLowerCase();
  return v === "1" || v === "true" || v === "on";
}

/// 入力が検索の最小要件（3文字以上・trim後）を満たすか。
export function isSearchableInput(input: string, minChars = 3): boolean {
  return input.trim().length >= minChars;
}

/// ログに出してよい非機微メタだけを抽出する（検索文・住所・座標・Place ID は
/// 決して含めない）。呼び出し側はこの戻り値だけをログに渡す。
export function safeLogMeta(meta: {
  action: string;
  sku: string;
  environment: string;
  status: number;
  suggestionCount?: number;
  errorKind?: PlacesErrorKind;
}): Record<string, unknown> {
  return {
    action: meta.action,
    sku: meta.sku,
    environment: meta.environment,
    status: meta.status,
    suggestion_count: meta.suggestionCount ?? null,
    error_kind: meta.errorKind ?? null,
  };
}
