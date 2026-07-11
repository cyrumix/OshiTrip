import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/itinerary/data/places_gateway_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/places_gateway.dart';

/// payload・応答を記録／注入する fake transport（Supabase 非依存で実 Gateway を
/// 検証する。routes_gateway_impl_test と同設計）。
class _FakeTransport implements PlacesProxyTransport {
  _FakeTransport({this.response, this.throwError});
  final PlacesProxyResponse? response;
  final Object? throwError;

  int callCount = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<PlacesProxyResponse> invoke(Map<String, dynamic> body) async {
    callCount++;
    lastBody = body;
    if (throwError != null) throw throwError!;
    return response!;
  }
}

const _token = PlacesSessionToken('session-token-1');

void main() {
  group('autocomplete', () {
    test('places-proxy へ action/input/sessionToken/bias を送る', () async {
      final t = _FakeTransport(
        response: const PlacesProxyResponse(
          status: 200,
          data: {'suggestions': <dynamic>[]},
        ),
      );
      await PlacesGatewayImpl(transport: t).autocomplete(
        input: '東京タワー',
        sessionToken: _token,
        bias: const PlacesLocationBias(latitude: 35.6, longitude: 139.7),
      );
      expect(t.callCount, 1);
      expect(t.lastBody!['action'], 'autocomplete');
      expect(t.lastBody!['input'], '東京タワー');
      expect(t.lastBody!['sessionToken'], 'session-token-1');
      final bias = t.lastBody!['locationBias'] as Map<String, dynamic>;
      final circle = bias['circle'] as Map<String, dynamic>;
      expect((circle['center'] as Map)['latitude'], 35.6);
    });

    test('応答を候補リストへ変換する（placeId空は除外・欠落耐性）', () async {
      final t = _FakeTransport(
        response: const PlacesProxyResponse(
          status: 200,
          data: {
            'suggestions': [
              {
                'placeId': 'ChIJ_1',
                'primaryText': '東京タワー',
                'secondaryText': '東京都港区',
              },
              {'placeId': '', 'primaryText': '無効'},
              {'primaryText': 'placeIdなし'},
            ],
          },
        ),
      );
      final result = await PlacesGatewayImpl(transport: t).autocomplete(
        input: '東京',
        sessionToken: _token,
      );
      final list = result.valueOrNull!;
      expect(list, hasLength(1));
      expect(list.single.placeId, 'ChIJ_1');
      expect(list.single.primaryText, '東京タワー');
      expect(list.single.secondaryText, '東京都港区');
    });

    test('unavailable エラーは UnavailableFailure（手動フォールバック）', () async {
      final t = _FakeTransport(
        response:
            const PlacesProxyResponse(status: 503, errorKind: 'unavailable'),
      );
      final result = await PlacesGatewayImpl(transport: t)
          .autocomplete(input: '東京', sessionToken: _token);
      expect(result.failureOrNull, isA<UnavailableFailure>());
    });

    test('通信例外は NetworkFailure', () async {
      final t = _FakeTransport(throwError: TimeoutException('timeout'));
      final result = await PlacesGatewayImpl(transport: t)
          .autocomplete(input: '東京', sessionToken: _token);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('placeDetails', () {
    test('places-proxy へ action/placeId/sessionToken を送る', () async {
      final t = _FakeTransport(
        response: const PlacesProxyResponse(
          status: 200,
          data: {'placeId': 'ChIJ_1'},
        ),
      );
      await PlacesGatewayImpl(transport: t)
          .placeDetails(placeId: 'ChIJ_1', sessionToken: _token);
      expect(t.lastBody!['action'], 'details');
      expect(t.lastBody!['placeId'], 'ChIJ_1');
      expect(t.lastBody!['sessionToken'], 'session-token-1');
    });

    test('応答を名称・住所・帰属へ変換する', () async {
      final t = _FakeTransport(
        response: const PlacesProxyResponse(
          status: 200,
          data: {
            'placeId': 'ChIJ_1',
            'displayName': '東京タワー',
            'formattedAddress': '東京都港区芝公園4-2-8',
            'attributions': [
              {'provider': 'Example', 'providerUri': 'https://example.com'},
            ],
          },
        ),
      );
      final result = await PlacesGatewayImpl(transport: t)
          .placeDetails(placeId: 'ChIJ_1', sessionToken: _token);
      final details = result.valueOrNull!;
      expect(details.placeId, 'ChIJ_1');
      expect(details.displayName, '東京タワー');
      expect(details.formattedAddress, '東京都港区芝公園4-2-8');
      expect(details.attributions, hasLength(1));
      expect(details.attributions.single.provider, 'Example');
    });

    test('unauthorized は AuthFailure', () async {
      final t = _FakeTransport(
        response:
            const PlacesProxyResponse(status: 401, errorKind: 'unauthorized'),
      );
      final result = await PlacesGatewayImpl(transport: t)
          .placeDetails(placeId: 'ChIJ_1', sessionToken: _token);
      expect(result.failureOrNull, isA<AuthFailure>());
    });
  });
}
