import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/route_request_fingerprint.dart';

/// 旅程Phase 4: 経路再計算の重複抑止・single-flight・stale判定に使う
/// fingerprint（itinerary-plan-spec §6.3/§8.3）。
void main() {
  String fp({
    String origin = 'place:A',
    String destination = 'place:B',
    ItineraryTravelMode mode = ItineraryTravelMode.walking,
    String bucket = '平日朝',
  }) =>
      routeRequestFingerprint(
        originSignature: origin,
        destinationSignature: destination,
        travelMode: mode,
        representativeTimeBucket: bucket,
      );

  test('同一の出発・到着・手段・代表時刻帯なら同一fingerprint', () {
    expect(fp(), fp());
  });

  test('出発地点が変われば別fingerprint', () {
    expect(fp(origin: 'place:C'), isNot(fp()));
  });

  test('到着地点が変われば別fingerprint', () {
    expect(fp(destination: 'place:C'), isNot(fp()));
  });

  test('移動手段が変われば別fingerprint', () {
    expect(fp(mode: ItineraryTravelMode.transit), isNot(fp()));
  });

  test('代表時刻帯が変われば別fingerprint', () {
    expect(fp(bucket: '休日夜'), isNot(fp()));
  });
}
