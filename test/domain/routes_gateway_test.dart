import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_field_mask.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_gateway.dart';

/// 旅程Phase 4 / Routes 外部境界（ADR-0010 §1/§8・itinerary-plan-spec §6/§8.3）:
/// Field Mask allowlist・ワイルドカード拒否・Google Maps 経路URL生成・
/// Google 無効時の型付き縮退（UnavailableFailure）・地点の signature/hasLocation
/// を検証する。
void main() {
  group('Field Mask allowlist（旅程Phase 4）', () {
    test('本番 Field Mask は許可フィールドのみ・順序固定', () {
      expect(buildRoutesFieldMask(), kRoutesAllowedFields.join(','));
    });

    test('allowlist の各フィールドは許可される', () {
      expect(routesFieldMaskError(kRoutesAllowedFields), isNull);
      expect(
        routesFieldMaskError(['routes.duration', 'routes.distanceMeters']),
        isNull,
      );
      expect(routesFieldMaskError([' routes.duration ']), isNull);
    });

    test('ワイルドカード `*` は拒否', () {
      expect(routesFieldMaskError(['*']), isNotNull);
      expect(routesFieldMaskError(['routes.duration', '*']), isNotNull);
      expect(routesFieldMaskStringError('*'), isNotNull);
    });

    test('polyline・座標等の高単価/規約外フィールドは allowlist 外で拒否される', () {
      for (final f in [
        'routes.polyline.encodedPolyline',
        'routes.legs.steps.polyline',
        'routes.routeLabels',
        'routes.travelAdvisory.tollInfo',
      ]) {
        expect(
          routesFieldMaskError(['routes.duration', f]),
          isNotNull,
          reason: '$f は取得しない',
        );
      }
    });

    test('空・空要素は拒否', () {
      expect(routesFieldMaskError(const []), isNotNull);
      expect(routesFieldMaskError(['routes.duration', '']), isNotNull);
    });
  });

  group('RouteEndpoint（地点の signature/hasLocation）', () {
    test('Place ID があれば hasLocation=true、signatureはplace ID優先', () {
      const e = RouteEndpoint(placeId: 'ChIJ_abc', latitude: 1, longitude: 2);
      expect(e.hasLocation, isTrue);
      expect(e.signature, 'place:ChIJ_abc');
    });

    test('Place ID が無く座標だけでも hasLocation=true', () {
      const e = RouteEndpoint(latitude: 35.681236, longitude: 139.767125);
      expect(e.hasLocation, isTrue);
      expect(e.signature, 'latlng:35.681236,139.767125');
    });

    test('どちらも無ければ hasLocation=false', () {
      const e = RouteEndpoint();
      expect(e.hasLocation, isFalse);
      expect(e.signature, 'unknown');
    });
  });

  group('googleMapsDirectionsUrl（追加Routes取得なし, §6.2）', () {
    test('Place ID優先で経路URLを生成する', () {
      const origin = RouteEndpoint(placeId: 'ChIJ_origin');
      const destination = RouteEndpoint(placeId: 'ChIJ_dest');
      final uri = googleMapsDirectionsUrl(origin, destination)!;
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['origin'], 'place_id:ChIJ_origin');
      expect(uri.queryParameters['destination'], 'place_id:ChIJ_dest');
    });

    test('Place IDが無ければ緯度経度で生成する', () {
      const origin = RouteEndpoint(latitude: 1, longitude: 2);
      const destination = RouteEndpoint(latitude: 3, longitude: 4);
      final uri = googleMapsDirectionsUrl(origin, destination)!;
      expect(uri.queryParameters['origin'], '1.0,2.0');
      expect(uri.queryParameters['destination'], '3.0,4.0');
    });

    test('どちらかに位置情報が無ければ null', () {
      const origin = RouteEndpoint(latitude: 1, longitude: 2);
      const destination = RouteEndpoint();
      expect(googleMapsDirectionsUrl(origin, destination), isNull);
    });
  });

  group('UnavailableRoutesGateway（未設定/無効時の型付き縮退, §1）', () {
    test('computeRoute は常に UnavailableFailure を返す', () async {
      const gateway = UnavailableRoutesGateway();
      final r = await gateway.computeRoute(
        RouteLiveRequest(
          origin: const RouteEndpoint(latitude: 1, longitude: 2),
          destination: const RouteEndpoint(latitude: 3, longitude: 4),
          travelMode: ItineraryTravelMode.walking,
          representativeDepartureUtc: DateTime.utc(2026, 7, 9),
        ),
      );
      expect(r.isOk, isFalse);
      expect(r.failureOrNull, isA<UnavailableFailure>());
    });
  });

  group('AppEnv.googleRoutesAvailable', () {
    AppEnv env({required bool enabled, bool supabase = true}) => AppEnv(
          flavor: Flavor.production,
          supabaseUrl: supabase ? 'https://real.supabase.co' : '',
          supabaseAnonKey: supabase ? 'anon-real-key' : '',
          logLevelName: 'info',
          googleMapsEnabled: enabled,
        );

    test('有効＋Supabase設定済みでのみ利用可能', () {
      expect(env(enabled: true).googleRoutesAvailable, isTrue);
    });

    test('無効なら利用不可（既定は無効）', () {
      expect(env(enabled: false).googleRoutesAvailable, isFalse);
    });

    test('Supabase未設定では有効でも利用不可', () {
      expect(
        env(enabled: true, supabase: false).googleRoutesAvailable,
        isFalse,
      );
    });
  });
}
