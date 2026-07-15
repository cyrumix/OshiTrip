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

/// 名称に加えて Place ID を併記して Google Maps 検索を開く URL（施設名で確実に
/// 目的地を特定する。Google 公式の `search/?api=1&query=&query_place_id=` 形式）。
Uri googleMapsQueryWithPlaceIdUrl(String query, String placeId) => Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': query, 'query_place_id': placeId},
    );

/// スポットを Google Maps で開く URL を決める（追加の Places 取得はしない, §5）。
/// 優先度: 名称＋Place ID（施設名で正確に特定）→ Place IDのみ → 手動座標 →
/// 名称検索。いずれも既存の保存値だけから生成し、課金 API を呼ばない。手入力
/// スポットでも施設名（必須）があるので常に生成できる（item 6）。
Uri spotGoogleMapsUrl(ItinerarySpot spot) {
  final placeId = spot.googlePlaceId;
  final name = spot.name.trim();
  if (placeId != null && placeId.isNotEmpty) {
    // 施設名があれば名称＋Place ID（検索結果が施設名で表示される）。
    return name.isNotEmpty
        ? googleMapsQueryWithPlaceIdUrl(name, placeId)
        : googleMapsPlaceUrl(placeId);
  }
  final lat = spot.latitude;
  final lng = spot.longitude;
  if (lat != null && lng != null) {
    return googleMapsCoordinatesUrl(lat, lng);
  }
  return googleMapsQueryUrl(spot.name);
}

/// 経路URLの端点（施設名・住所・座標・Place ID から text クエリを決める）。
class MapRouteEndpoint {
  const MapRouteEndpoint({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.placeId,
  });
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  /// Google Maps `dir` の origin/destination に使う text（優先: 施設名 → 住所 →
  /// 「lat,lng」）。いずれも無ければ null（経路を作れない）。
  String? get queryText {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final a = address?.trim();
    if (a != null && a.isNotEmpty) return a;
    if (latitude != null && longitude != null) return '$latitude,$longitude';
    return null;
  }
}

/// 施設名・住所・座標・Place ID から Google Maps「経路」URL（`dir/?api=1`）を作る。
/// origin/destination は text（施設名→住所→座標）で必須。Place ID があれば
/// `origin_place_id`/`destination_place_id` を併記して精度を上げる（Google 公式形式）。
/// text が空なら生成しない（null）。手入力スポットでも施設名・住所があれば経路を
/// 開ける（item 5 フォールバック）。
Uri? googleMapsRouteUrl({
  required MapRouteEndpoint origin,
  required MapRouteEndpoint destination,
  String? travelMode,
}) {
  final o = origin.queryText;
  final d = destination.queryText;
  if (o == null || d == null) return null;
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': o,
    if (origin.placeId != null && origin.placeId!.isNotEmpty)
      'origin_place_id': origin.placeId!,
    'destination': d,
    if (destination.placeId != null && destination.placeId!.isNotEmpty)
      'destination_place_id': destination.placeId!,
    if (travelMode != null && travelMode.isNotEmpty) 'travelmode': travelMode,
  });
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
