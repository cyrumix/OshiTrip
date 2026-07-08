import 'itinerary_spot.dart';
import 'places_gateway.dart' show googleMapsPlaceUrl;

/// 地図モードの座標・外部リンク・ピン選定（itinerary-plan-spec §5・ADR-0010 §4）。
///
/// すべて純粋関数。地図表示・外部遷移のためだけに Google の追加取得（座標・
/// Place Details・Routes）はしない。座標は**手動入力のみ**を使う。

/// スポットが地図ピンを表示できるか。手動座標（緯度・経度が両方）が揃っている
/// ときだけ true（§5「手動座標のあるスポットだけピン表示」）。
bool spotHasMapPin(ItinerarySpot spot) =>
    spot.latitude != null && spot.longitude != null;

/// 座標から Google Maps を開く URL。
Uri googleMapsCoordinatesUrl(double latitude, double longitude) => Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': '$latitude,$longitude'},
    );

/// 名称で Google Maps を検索する URL（座標も Place ID も無いとき）。
Uri googleMapsQueryUrl(String query) => Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': query},
    );

/// スポットを Google Maps で開く URL を決める（追加の Places 取得はしない, §5）。
/// 優先度: 保存済み Place ID（永続化可能な唯一の Google 識別子）→ 手動座標 →
/// 名称検索。いずれも既存の保存値だけから生成し、課金 API を呼ばない。
Uri spotGoogleMapsUrl(ItinerarySpot spot) {
  final placeId = spot.googlePlaceId;
  if (placeId != null && placeId.isNotEmpty) {
    return googleMapsPlaceUrl(placeId);
  }
  final lat = spot.latitude;
  final lng = spot.longitude;
  if (lat != null && lng != null) {
    return googleMapsCoordinatesUrl(lat, lng);
  }
  return googleMapsQueryUrl(spot.name);
}

/// 地図モード用に、スポットを「ピン表示可（座標あり）」と「一覧のみ（座標なし）」
/// へ分ける（§5）。座標なしスポットは一覧＋Google Maps 外部導線で扱い、地図の
/// ためだけに座標を取得しない。並び順は入力順を保つ。
({List<ItinerarySpot> pinned, List<ItinerarySpot> listed}) partitionSpotsForMap(
  Iterable<ItinerarySpot> spots,
) {
  final pinned = <ItinerarySpot>[];
  final listed = <ItinerarySpot>[];
  for (final s in spots) {
    (spotHasMapPin(s) ? pinned : listed).add(s);
  }
  return (pinned: pinned, listed: listed);
}
