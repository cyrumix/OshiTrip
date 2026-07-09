/// Google Routes API (Compute Routes) の Field Mask allowlist と検証
/// （旅程Phase 4・ADR-0010 §6・itinerary-plan-spec §6.2/§8.3）。
///
/// 確認日: 2026-07-09（developers.google.com/maps/documentation/routes/choose_fields、
/// .../reference/rest/v2/TopLevel/computeRoutes）。polyline・座標・交通機関以外の
/// 追加情報は要求しない（§6.2 の最小範囲、SKU=Essentials維持のため
/// `routingPreference`/`extraComputations` に関わるフィールドも含めない）。
///
/// このモジュールは純粋関数のみで、ネットワークに触れない（クライアント・
/// Edge Function の双方で同じ許可集合を根拠にできるよう Dart 側にも定義する,
/// `places_field_mask.dart` と同型）。
library;

/// Compute Routes の許可フィールド（順序＝送出順。空白なしカンマ区切り）。
/// 徒歩距離・所要時間・運賃表示・公共交通の路線/乗換概要だけに限定する。
const List<String> kRoutesAllowedFields = [
  'routes.duration',
  'routes.distanceMeters',
  'routes.localizedValues.transitFare',
  'routes.legs.steps.transitDetails.transitLine.name',
  'routes.legs.steps.transitDetails.transitLine.nameShort',
  'routes.legs.steps.transitDetails.transitLine.vehicle.type',
  'routes.legs.steps.transitDetails.headsign',
  'routes.legs.steps.transitDetails.stopDetails.departureStop.name',
  'routes.legs.steps.transitDetails.stopDetails.arrivalStop.name',
];

/// 本番用の Routes Field Mask 文字列。
String buildRoutesFieldMask() => kRoutesAllowedFields.join(',');

/// Field Mask を検証する。問題があれば理由、無ければ null。
///
/// 拒否: 空・`*`（ワイルドカード）・allowlist 外のフィールド（前後空白は許容し
/// trim して判定する）。polyline・座標等の高単価/規約外フィールドは allowlist に
/// 無いため自動的に拒否される。
String? routesFieldMaskError(List<String> fields) {
  if (fields.isEmpty) return 'Field Mask が空です';
  final allowed = kRoutesAllowedFields.toSet();
  for (final raw in fields) {
    final f = raw.trim();
    if (f.isEmpty) return 'Field Mask に空のフィールドが含まれます';
    if (f == '*') return 'ワイルドカード Field Mask は禁止です';
    if (!allowed.contains(f)) return '許可されていないフィールドです: $f';
  }
  return null;
}

/// カンマ区切りの Field Mask 文字列を検証する（[routesFieldMaskError] の文字列版。
/// Edge Function からのヘッダ相当を想定）。
String? routesFieldMaskStringError(String mask) =>
    routesFieldMaskError(mask.split(','));
