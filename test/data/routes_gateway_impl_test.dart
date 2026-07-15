import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/itinerary/data/routes_gateway_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_gateway.dart';

/// payload・応答を記録／注入する fake transport（Supabase 非依存で実 Gateway を
/// 検証する）。
class _FakeTransport implements RoutesProxyTransport {
  _FakeTransport({this.response, this.throwError});
  final RoutesProxyResponse? response;
  final Object? throwError;

  int callCount = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<RoutesProxyResponse> invoke(Map<String, dynamic> body) async {
    callCount++;
    lastBody = body;
    if (throwError != null) throw throwError!;
    return response!;
  }
}

RouteLiveRequest _request({
  ItineraryTravelMode mode = ItineraryTravelMode.transit,
  RouteEndpoint? origin,
  RouteEndpoint? destination,
  DateTime? departureUtc,
}) =>
    RouteLiveRequest(
      origin: origin ?? const RouteEndpoint(placeId: 'ChIJ_origin'),
      destination:
          destination ?? const RouteEndpoint(latitude: 35.1, longitude: 139.2),
      travelMode: mode,
      representativeDepartureUtc: departureUtc ?? DateTime.utc(2026, 7, 9, 3),
    );

void main() {
  final clock = FixedClock(DateTime.utc(2026, 7, 9, 12));

  RoutesGatewayImpl gateway(_FakeTransport t) =>
      RoutesGatewayImpl(transport: t, clock: clock);

  group('payload 送出（修正1）', () {
    test('routes-proxy へ正しい payload を送る（placeId優先・座標フォールバック・UTC）', () async {
      final transport = _FakeTransport(
        response: const RoutesProxyResponse(
          status: 200,
          data: {'durationMinutes': 10, 'distanceMeters': 800},
        ),
      );
      await gateway(transport).computeRoute(_request());

      expect(transport.callCount, 1);
      final body = transport.lastBody!;
      expect(body['origin'], {'placeId': 'ChIJ_origin'});
      expect(body['destination'], {'latitude': 35.1, 'longitude': 139.2});
      expect(body['travelMode'], 'transit');
      // 代表出発日時は UTC ISO8601。
      expect(body['representativeDepartureUtc'], '2026-07-09T03:00:00.000Z');
      // Gateway層が日本語優先・国内・メートル法を必ず付与する（item 2/8/9）。
      expect(body['languageCode'], 'ja');
      expect(body['regionCode'], 'JP');
      expect(body['units'], 'METRIC');
    });

    test('payload に Google API キーを一切含めない（キーはサーバー保持, ADR-0010 §3）', () async {
      final transport = _FakeTransport(
        response: const RoutesProxyResponse(
          status: 200,
          data: {'durationMinutes': 1, 'distanceMeters': 1},
        ),
      );
      await gateway(transport).computeRoute(_request());
      // 送出キーは固定集合のみ。api/key 系のフィールドは存在しない。
      expect(
        transport.lastBody!.keys.toSet(),
        {
          'origin',
          'destination',
          'travelMode',
          'representativeDepartureUtc',
          'languageCode',
          'regionCode',
          'units',
        },
      );
      final flat = transport.lastBody!.keys.join(',').toLowerCase();
      expect(flat.contains('key'), isFalse);
      expect(flat.contains('apikey'), isFalse);
    });

    test('travelMode は wire 文字列へ変換される（walking/driving/bicycling）', () async {
      for (final entry in {
        ItineraryTravelMode.walking: 'walking',
        ItineraryTravelMode.driving: 'driving',
        ItineraryTravelMode.bicycling: 'bicycling',
      }.entries) {
        final transport = _FakeTransport(
          response: const RoutesProxyResponse(
            status: 200,
            data: {'durationMinutes': 1, 'distanceMeters': 1},
          ),
        );
        await gateway(transport).computeRoute(_request(mode: entry.key));
        expect(transport.lastBody!['travelMode'], entry.value);
      }
    });

    test('taxi/flight/other は送信せず ValidationFailure（非対応・費用制御）', () async {
      for (final mode in [
        ItineraryTravelMode.taxi,
        ItineraryTravelMode.flight,
        ItineraryTravelMode.other,
      ]) {
        final transport = _FakeTransport(
          response: const RoutesProxyResponse(status: 200, data: {}),
        );
        final result =
            await gateway(transport).computeRoute(_request(mode: mode));
        expect(transport.callCount, 0, reason: '$mode は送信しない');
        expect(result.failureOrNull, isA<ValidationFailure>());
      }
    });
  });

  group('応答→RouteLiveResult 変換（修正1）', () {
    test('成功: 所要時間・距離・運賃・乗換ステップ・requestedAt(受信時刻UTC)', () async {
      final transport = _FakeTransport(
        response: const RoutesProxyResponse(
          status: 200,
          data: {
            'durationMinutes': 15,
            'distanceMeters': 2000,
            'fareText': '¥180',
            'transitSteps': [
              {
                'lineName': 'JR山手線',
                'lineNameShort': '山手線',
                'headsign': '渋谷方面',
                'departureStopName': '新宿駅',
                'arrivalStopName': '渋谷駅',
              },
            ],
          },
        ),
      );
      final result = await gateway(transport).computeRoute(_request());
      final live = result.valueOrNull!;
      expect(live.durationMinutes, 15);
      expect(live.distanceMeters, 2000);
      expect(live.fareText, '¥180');
      expect(live.transitSteps.single.lineName, 'JR山手線');
      expect(live.transitSteps.single.departureStopName, '新宿駅');
      // requestedAt はクライアント受信時刻（FixedClock）をUTCで。
      expect(live.requestedAt, DateTime.utc(2026, 7, 9, 12));
    });

    test('欠落フィールドがあってもクラッシュしない（0埋め・null許容）', () async {
      final transport = _FakeTransport(
        response: const RoutesProxyResponse(status: 200, data: {}),
      );
      final result = await gateway(transport).computeRoute(_request());
      final live = result.valueOrNull!;
      expect(live.durationMinutes, 0);
      expect(live.distanceMeters, 0);
      expect(live.fareText, isNull);
      expect(live.transitSteps, isEmpty);
    });

    test('transitSteps が想定外の型でも無視して空にする', () async {
      final transport = _FakeTransport(
        response: const RoutesProxyResponse(
          status: 200,
          data: {
            'durationMinutes': 5,
            'distanceMeters': 300,
            'transitSteps': 'not-a-list',
          },
        ),
      );
      final result = await gateway(transport).computeRoute(_request());
      expect(result.valueOrNull!.transitSteps, isEmpty);
    });
  });

  group('エラー種別→Failure 変換（修正1）', () {
    Future<Failure?> failFor(String kind, int status) async {
      final transport = _FakeTransport(
        response: RoutesProxyResponse(status: status, errorKind: kind),
      );
      final r = await gateway(transport).computeRoute(_request());
      return r.failureOrNull;
    }

    test('not_entitled → PermissionFailure', () async {
      expect(await failFor('not_entitled', 403), isA<PermissionFailure>());
    });
    test('unauthorized → AuthFailure', () async {
      expect(await failFor('unauthorized', 401), isA<AuthFailure>());
    });
    test('rate_limited → NetworkFailure', () async {
      expect(await failFor('rate_limited', 429), isA<NetworkFailure>());
    });
    test('invalid_request → ValidationFailure', () async {
      expect(await failFor('invalid_request', 400), isA<ValidationFailure>());
    });
    test('unavailable → UnavailableFailure', () async {
      expect(await failFor('unavailable', 503), isA<UnavailableFailure>());
    });
    test('timeout/upstream_error → NetworkFailure', () async {
      expect(await failFor('timeout', 504), isA<NetworkFailure>());
      expect(await failFor('upstream_error', 502), isA<NetworkFailure>());
    });

    test('kind不明時は status で概略判定する', () {
      expect(routesProxyErrorToFailure(null, 403), isA<PermissionFailure>());
      expect(routesProxyErrorToFailure(null, 429), isA<NetworkFailure>());
      expect(routesProxyErrorToFailure(null, 400), isA<ValidationFailure>());
      expect(routesProxyErrorToFailure(null, 500), isA<NetworkFailure>());
    });
  });

  group('トランスポート例外の変換（修正1）', () {
    test('TimeoutException は NetworkFailure', () async {
      final transport = _FakeTransport(throwError: TimeoutException('slow'));
      final r = await gateway(transport).computeRoute(_request());
      expect(r.failureOrNull, isA<NetworkFailure>());
    });

    test('通信断（一般例外）も NetworkFailure', () async {
      final transport = _FakeTransport(throwError: StateError('socket down'));
      final r = await gateway(transport).computeRoute(_request());
      expect(r.failureOrNull, isA<NetworkFailure>());
    });
  });
}
