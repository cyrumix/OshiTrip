/// Google Places (New) の Field Mask allowlist と検証（ADR-0010 §6・
/// itinerary-plan-spec §4.3/§8.2）。
///
/// MVP で取得してよいのは Place ID・名称・住所・表示に必要な帰属情報だけ。
/// 電話・Webサイト・営業時間・写真・評価・レビュー・primary type・座標は
/// 要求しない。`*`（ワイルドカード）は本番で禁止する。
///
/// このモジュールは純粋関数のみで、ネットワークに触れない（クライアント・
/// Edge Function の双方で同じ許可集合を根拠にできるよう Dart 側にも定義する）。
library;

/// Place Details (New) の許可フィールド（順序＝送出順。空白なしカンマ区切り）。
/// - id / attributions: Essentials(IDs Only) 相当
/// - formattedAddress: Essentials 相当
/// - displayName: Pro 相当（名称表示のため許容, decisions 2026-07-08 記録）
const List<String> kPlaceDetailsAllowedFields = [
  'id',
  'displayName',
  'formattedAddress',
  'attributions',
];

/// 本番用の Place Details Field Mask 文字列（`id,displayName,formattedAddress,attributions`）。
String buildPlaceDetailsFieldMask() => kPlaceDetailsAllowedFields.join(',');

/// Field Mask を検証する。問題があれば理由、無ければ null。
///
/// 拒否: 空・`*`（ワイルドカード）・allowlist 外のフィールド（前後空白は許容し
/// trim して判定する）。高単価/規約外フィールド（座標・写真・電話等）は
/// allowlist に無いため自動的に拒否される。
String? placeDetailsFieldMaskError(List<String> fields) {
  if (fields.isEmpty) return 'Field Mask が空です';
  const allowed = {'id', 'displayName', 'formattedAddress', 'attributions'};
  for (final raw in fields) {
    final f = raw.trim();
    if (f.isEmpty) return 'Field Mask に空のフィールドが含まれます';
    if (f == '*') return 'ワイルドカード Field Mask は禁止です';
    if (!allowed.contains(f)) return '許可されていないフィールドです: $f';
  }
  return null;
}

/// カンマ区切りの Field Mask 文字列を検証する（[placeDetailsFieldMaskError] の
/// 文字列版。Edge Function からのヘッダ相当を想定）。
String? placeDetailsFieldMaskStringError(String mask) =>
    placeDetailsFieldMaskError(mask.split(','));
