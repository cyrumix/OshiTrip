import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_map_links.dart';

import '../helpers/fixtures.dart';

/// 旅程Phase 3 / 地図モードの座標・外部リンク・ピン選定（itinerary-plan-spec §5・
/// ADR-0010 §4）。地図/外部遷移のためだけに Google の追加取得はしない（純粋関数）。
void main() {
  group('spotHasMapPin（手動座標のあるスポットだけピン）', () {
    test('緯度・経度が両方あるときだけ true', () {
      expect(
        spotHasMapPin(makeItinerarySpot(latitude: 35.0, longitude: 139.0)),
        isTrue,
      );
      expect(spotHasMapPin(makeItinerarySpot()), isFalse);
      // 片方だけは不可（座標として無効）。
      expect(spotHasMapPin(makeItinerarySpot(latitude: 35.0)), isFalse);
      expect(spotHasMapPin(makeItinerarySpot(longitude: 139.0)), isFalse);
    });
  });

  group('spotGoogleMapsUrl（Place ID→座標→名称の優先, 追加取得なし）', () {
    test('Place ID があれば Place ID URL（座標より優先）', () {
      final spot = makeItinerarySpot(latitude: 35.0, longitude: 139.0)
          .copyWith(googlePlaceId: 'ChIJ_abc');
      final uri = spotGoogleMapsUrl(spot);
      expect(uri.queryParameters['query_place_id'], 'ChIJ_abc');
    });

    test('Place ID なし・座標ありなら座標 URL', () {
      final uri = spotGoogleMapsUrl(
        makeItinerarySpot(latitude: 35.5, longitude: 139.7),
      );
      expect(uri.queryParameters['query'], '35.5,139.7');
      expect(uri.queryParameters.containsKey('query_place_id'), isFalse);
    });

    test('Place ID も座標も無ければ名称検索 URL', () {
      final uri = spotGoogleMapsUrl(makeItinerarySpot(name: '幕張メッセ'));
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['query'], '幕張メッセ');
    });
  });

  group('partitionSpotsForMap（座標あり=ピン / 座標なし=一覧）', () {
    test('座標の有無で分割し、入力順を保つ', () {
      final spots = [
        makeItinerarySpot(id: 's1', latitude: 35.0, longitude: 139.0),
        makeItinerarySpot(id: 's2'), // 座標なし
        makeItinerarySpot(id: 's3', latitude: 34.7, longitude: 135.5),
        makeItinerarySpot(id: 's4'), // 座標なし
      ];
      final r = partitionSpotsForMap(spots);
      expect(r.pinned.map((s) => s.id), ['s1', 's3']);
      expect(r.listed.map((s) => s.id), ['s2', 's4']);
    });

    test('空入力は両方空', () {
      final r = partitionSpotsForMap(const []);
      expect(r.pinned, isEmpty);
      expect(r.listed, isEmpty);
    });
  });
}
