import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/itinerary/domain/places_field_mask.dart';
import 'package:oshi_trip/features/itinerary/domain/places_gateway.dart';

/// 旅程Phase 3 / 外部境界（ADR-0010 §1/§6・itinerary-plan-spec §4.3/§8.2）:
/// Field Mask allowlist・ワイルドカード拒否・Place ID URL 生成・Google 無効時の
/// 型付き縮退（UnavailableFailure）を検証する。
void main() {
  group('Field Mask allowlist（ADR-0010 §6）', () {
    test('本番 Field Mask は id/displayName/formattedAddress/attributions のみ', () {
      expect(
        buildPlaceDetailsFieldMask(),
        'id,displayName,formattedAddress,attributions',
      );
    });

    test('allowlist の各フィールドは許可される', () {
      expect(placeDetailsFieldMaskError(kPlaceDetailsAllowedFields), isNull);
      expect(
        placeDetailsFieldMaskError(['id', 'displayName']),
        isNull,
      );
      // 前後空白は許容（trim して判定）。
      expect(placeDetailsFieldMaskError([' id ', 'attributions']), isNull);
    });

    test('ワイルドカード `*` は拒否', () {
      expect(placeDetailsFieldMaskError(['*']), isNotNull);
      expect(placeDetailsFieldMaskError(['id', '*']), isNotNull);
      expect(placeDetailsFieldMaskStringError('*'), isNotNull);
    });

    test('高単価/規約外フィールドは allowlist 外で拒否される', () {
      for (final f in [
        'location', // 座標
        'photos', // 写真
        'internationalPhoneNumber', // 電話
        'websiteUri', // Webサイト
        'currentOpeningHours', // 営業時間
        'rating', // 評価
        'reviews', // レビュー
        'primaryType', // primary type
        'types',
      ]) {
        expect(
          placeDetailsFieldMaskError(['id', f]),
          isNotNull,
          reason: '$f は取得しない',
        );
      }
    });

    test('空・空要素は拒否', () {
      expect(placeDetailsFieldMaskError(const []), isNotNull);
      expect(placeDetailsFieldMaskError(['id', '']), isNotNull);
    });
  });

  group('Place ID → Google Maps URL（追加Details取得なし, §4.3）', () {
    test('Place ID から検索URLを生成する', () {
      final uri = googleMapsPlaceUrl('ChIJ_test_123');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query_place_id'], 'ChIJ_test_123');
    });
  });

  group('UnavailablePlacesGateway（未設定/無効時の型付き縮退, §1）', () {
    const gateway = UnavailablePlacesGateway();
    const token = PlacesSessionToken('tok');

    test('autocomplete は UnavailableFailure を返す', () async {
      final r = await gateway.autocomplete(input: 'とう', sessionToken: token);
      expect(r.isOk, isFalse);
      expect(r.failureOrNull, isA<UnavailableFailure>());
    });

    test('placeDetails は UnavailableFailure を返す', () async {
      final r =
          await gateway.placeDetails(placeId: 'ChIJ', sessionToken: token);
      expect(r.isOk, isFalse);
      expect(r.failureOrNull, isA<UnavailableFailure>());
    });
  });

  group('AppEnv.googlePlacesAvailable', () {
    AppEnv env({
      required Flavor flavor,
      required bool enabled,
      bool supabase = true,
    }) =>
        AppEnv(
          flavor: flavor,
          supabaseUrl: supabase ? 'https://real.supabase.co' : '',
          supabaseAnonKey: supabase ? 'anon-real-key' : '',
          logLevelName: 'info',
          googleMapsEnabled: enabled,
        );

    test('有効＋Supabase 設定済みでのみ利用可能', () {
      expect(
        env(flavor: Flavor.production, enabled: true).googlePlacesAvailable,
        isTrue,
      );
    });

    test('無効なら利用不可（既定は無効）', () {
      expect(
        env(flavor: Flavor.production, enabled: false).googlePlacesAvailable,
        isFalse,
      );
      // 既定コンストラクタは googleMapsEnabled=false。
      const def = AppEnv(
        flavor: Flavor.production,
        supabaseUrl: 'https://real.supabase.co',
        supabaseAnonKey: 'anon-real-key',
        logLevelName: 'info',
      );
      expect(def.googleMapsEnabled, isFalse);
      expect(def.googlePlacesAvailable, isFalse);
    });

    test('Supabase 未設定（デモ相当）では有効でも利用不可', () {
      expect(
        env(flavor: Flavor.development, enabled: true, supabase: false)
            .googlePlacesAvailable,
        isFalse,
      );
    });

    test('地図SDKキーは Web Service 用ではない（既定は空）', () {
      const def = AppEnv(
        flavor: Flavor.production,
        supabaseUrl: 'u',
        supabaseAnonKey: 'k',
        logLevelName: 'info',
      );
      expect(def.googleMapsApiKey, '');
    });
  });
}
