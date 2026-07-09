import 'itinerary_leg.dart';

/// 経路再計算の重複抑止・single-flight・stale判定に使う fingerprint
/// （旅程Phase 4, itinerary-plan-spec §6.3/§8.3）。
///
/// 同一の出発地点・到着地点・移動手段・代表時刻帯なら同一文字列を返し、
/// いずれかが変われば別文字列になる純粋関数。位置・日時・手段の変化を
/// 1つの値で表せるため、[isLegStale] や single-flight のキーにそのまま使える。
///
/// [originSignature]/[destinationSignature] は呼び出し側が用意する地点の識別子
/// （[RouteEndpoint.signature] を想定）。
String routeRequestFingerprint({
  required String originSignature,
  required String destinationSignature,
  required ItineraryTravelMode travelMode,
  required String representativeTimeBucket,
}) =>
    '$originSignature|$destinationSignature|'
    '${travelMode.name}|$representativeTimeBucket';
