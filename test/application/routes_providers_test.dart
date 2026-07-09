import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/features/itinerary/application/routes_providers.dart';
import 'package:oshi_trip/features/itinerary/data/routes_gateway_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_gateway.dart';

/// 修正1: `routesGatewayProvider` の環境ベース選択と transport seam。
///
/// 実 SupabaseClient は単体テストで安全に構築できない（Supabase.instance 初期化が
/// 必要）ため、`routesProxyTransportProvider` を差し替えて gateway 選択を検証する。
/// env→transport の縮退（無効・クライアント無し→null）は transport provider を
/// 直接検証する。実 SupabaseClient を伴う「有効環境＋クライアントあり→実transport」
/// の配線はソースのとおり（環境依存のため単体テスト対象外）。
class _FakeTransport implements RoutesProxyTransport {
  @override
  Future<RoutesProxyResponse> invoke(Map<String, dynamic> body) async =>
      const RoutesProxyResponse(status: 200, data: {});
}

const _enabledEnv = AppEnv(
  flavor: Flavor.production,
  supabaseUrl: 'https://real.supabase.co',
  supabaseAnonKey: 'anon-real-key',
  logLevelName: 'info',
  googleMapsEnabled: true,
);

const _disabledEnv = AppEnv(
  flavor: Flavor.production,
  supabaseUrl: 'https://real.supabase.co',
  supabaseAnonKey: 'anon-real-key',
  logLevelName: 'info',
);

void main() {
  group('routesGatewayProvider の選択', () {
    test('無効環境（Routes無効）では UnavailableRoutesGateway', () {
      final container = ProviderContainer(
        overrides: [envProvider.overrideWithValue(_disabledEnv)],
      );
      addTearDown(container.dispose);
      expect(
        container.read(routesGatewayProvider),
        isA<UnavailableRoutesGateway>(),
      );
    });

    test('transport あり（有効環境相当）では実 Gateway（RoutesGatewayImpl）', () {
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(_enabledEnv),
          routesProxyTransportProvider.overrideWithValue(_FakeTransport()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(routesGatewayProvider), isA<RoutesGatewayImpl>());
    });

    test('transport が null なら UnavailableRoutesGateway', () {
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(_enabledEnv),
          routesProxyTransportProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(routesGatewayProvider),
        isA<UnavailableRoutesGateway>(),
      );
    });
  });

  group('routesProxyTransportProvider の縮退', () {
    test('Routes 無効環境では null（supabaseClient を読む前に縮退）', () {
      final container = ProviderContainer(
        overrides: [envProvider.overrideWithValue(_disabledEnv)],
      );
      addTearDown(container.dispose);
      expect(container.read(routesProxyTransportProvider), isNull);
    });

    test('有効環境でも Supabase クライアントが無ければ null', () {
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(_enabledEnv),
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(routesProxyTransportProvider), isNull);
    });
  });
}
