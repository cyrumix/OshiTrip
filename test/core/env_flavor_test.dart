import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/config/flavor_guard.dart';

/// 環境分離・flavor整合性の検証（H-01/M-02）。
///
/// - デモモードは development かつ Supabase 未設定のときのみ許可される
///   （production/staging は設定不備でもデモへフォールバックしない）。
/// - Dart entry（`main_<flavor>.dart`）由来の [Flavor] と、実行中バイナリの
///   applicationId/bundle id が「既知の値との完全一致」かを [matchesFlavor] が
///   判定する（接尾辞判定ではない、H-01最終修正）。
void main() {
  group('AppEnv: 設定不備・デモフォールバック禁止', () {
    AppEnv env({
      required Flavor flavor,
      String url = '',
      String key = '',
    }) =>
        AppEnv(
          flavor: flavor,
          supabaseUrl: url,
          supabaseAnonKey: key,
          logLevelName: 'info',
        );

    test('development + Supabase未設定 は明示的デモモード', () {
      final e = env(flavor: Flavor.development);
      expect(e.hasSupabaseConfig, isFalse);
      expect(e.isDemoMode, isTrue);
    });

    test('development + Supabase設定済み はデモモードではない', () {
      final e = env(
        flavor: Flavor.development,
        url: 'https://xxxx.supabase.co',
        key: 'anon-key',
      );
      expect(e.hasSupabaseConfig, isTrue);
      expect(e.isDemoMode, isFalse);
    });

    test('staging + Supabase未設定 はデモモードにならない（禁止）', () {
      final e = env(flavor: Flavor.staging);
      expect(e.hasSupabaseConfig, isFalse);
      expect(e.isDemoMode, isFalse);
    });

    test('production + Supabase未設定 はデモモードにならない（禁止）', () {
      final e = env(flavor: Flavor.production);
      expect(e.hasSupabaseConfig, isFalse);
      expect(e.isDemoMode, isFalse);
    });

    test('production + Supabase設定済み でもデモモードではない（本番は常にデモ対象外）', () {
      final e = env(
        flavor: Flavor.production,
        url: 'https://xxxx.supabase.co',
        key: 'anon-key',
      );
      expect(e.isDemoMode, isFalse);
    });

    test('テンプレート値（your-project-ref等）は未設定扱い', () {
      final e = env(
        flavor: Flavor.development,
        url: 'https://your-project-ref.supabase.co',
        key: 'your-anon-public-key',
      );
      expect(e.hasSupabaseConfig, isFalse);
      expect(e.isDemoMode, isTrue);
    });

    test('appTitle は flavor ごとに分離される', () {
      expect(env(flavor: Flavor.development).appTitle, 'OshiTrip Dev');
      expect(env(flavor: Flavor.staging).appTitle, 'OshiTrip Staging');
      expect(env(flavor: Flavor.production).appTitle, 'OshiTrip');
    });
  });

  group('FlavorGuard: flavor と applicationId/bundle id の完全一致検証', () {
    test('development flavor は正式nativeIdのみ一致', () {
      expect(
        matchesFlavor(
          Flavor.development,
          'app.oshitrip.mobile.dev',
        ),
        isTrue,
      );
    });

    test('staging flavor は正式nativeIdのみ一致', () {
      expect(
        matchesFlavor(Flavor.staging, 'app.oshitrip.mobile.stg'),
        isTrue,
      );
    });

    test('production flavor は正式nativeIdのみ一致', () {
      expect(
        matchesFlavor(Flavor.production, 'app.oshitrip.mobile'),
        isTrue,
      );
    });

    test(
        'production の applicationId + development entry の取り違えは '
        'assertFlavorMatchesNativeId が拒否する（H-01 の核心シナリオ）', () {
      // production の Gradle flavor（接尾辞なし）でビルドされた実機だが、
      // 誤って development entry（-t lib/main_development.dart）で起動された
      // ケースを模す。
      expect(
        () => assertFlavorMatchesNativeId(
          Flavor.development,
          'app.oshitrip.mobile', // production の applicationId
        ),
        throwsA(
          isA<FlavorMismatchException>()
              .having((e) => e.flavor, 'flavor', Flavor.development)
              .having(
                (e) => e.nativeId,
                'nativeId',
                'app.oshitrip.mobile',
              ),
        ),
      );
    });

    test('development entry を development の applicationId で起動すれば拒否されない', () {
      expect(
        () => assertFlavorMatchesNativeId(
          Flavor.development,
          'app.oshitrip.mobile.dev',
        ),
        returnsNormally,
      );
    });

    group(
        'lib/main.dart（development専用の汎用エントリ）は '
        'production/staging の native id と組み合わせても必ず拒否される', () {
      // main.dart / main_development.dart はどちらも bootstrap(Flavor.development)
      // を呼ぶだけの同一内容（item5）。development flavor を Android/iOS の
      // production・staging applicationId/bundle id と組み合わせて起動する
      // 取り違えが、常に拒否されることを回帰確認する。
      const mismatches = [
        'app.oshitrip.mobile', // production
        'app.oshitrip.mobile.stg', // staging
      ];
      for (final nativeId in mismatches) {
        test('development flavor + "$nativeId" は拒否される', () {
          expect(
            () => assertFlavorMatchesNativeId(Flavor.development, nativeId),
            throwsA(isA<FlavorMismatchException>()),
          );
        });
      }
    });

    test('staging entry を production の applicationId で起動する取り違えも拒否する', () {
      expect(
        () => assertFlavorMatchesNativeId(
          Flavor.staging,
          'app.oshitrip.mobile',
        ),
        throwsA(isA<FlavorMismatchException>()),
      );
    });

    group('完全一致以外はすべて拒否する（接尾辞判定の抜け穴を塞ぐ回帰テスト）', () {
      // 旧実装（endsWith('.dev')/endsWith('.stg')、それ以外を production 扱い）
      // では、下記のようなIDを誤って一致と判定してしまっていた。完全一致の
      // 許可リストへ変更したことで、既知の3値以外はすべて拒否されることを
      // 確認する。
      const bogusIds = [
        // 無関係な別アプリがたまたま .dev/.stg で終わる場合。
        'com.evil.app.dev',
        'com.evil.app.stg',
        // 既知の base に紛らわしい接尾辞を継ぎ足したなりすまし。
        'app.oshitrip.mobile.dev.evil',
        'app.oshitrip.mobile.devil',
        'app.oshitrip.mobile.development',
        // 大文字小文字・区切り違い。
        'app.oshitrip.mobile.DEV',
        'app.oshitrip.mobile-dev',
        // 空文字・無関係な文字列（旧実装では production 扱いされていた）。
        '',
        'com.attacker.completely.unrelated.app',
        // iOS/Android の値を取り違え（development の Android id を
        // staging/production 判定に使う等）。
        'app.oshitrip.mobile.dev ', // 末尾空白
        ' app.oshitrip.mobile',
      ];

      for (final id in bogusIds) {
        test('development は "$id" を拒否する', () {
          expect(matchesFlavor(Flavor.development, id), isFalse);
        });
        test('staging は "$id" を拒否する', () {
          expect(matchesFlavor(Flavor.staging, id), isFalse);
        });
        test('production は "$id" を拒否する', () {
          expect(matchesFlavor(Flavor.production, id), isFalse);
        });
      }

      test('production は development/staging の nativeId を拒否する（旧実装で穴だった箇所）', () {
        // 旧実装は接尾辞が .dev/.stg でなければ production 扱いだったため、
        // ここには穴が無かったが、明示的に固定する回帰テストとして残す。
        expect(
          matchesFlavor(
            Flavor.production,
            'app.oshitrip.mobile.dev',
          ),
          isFalse,
        );
        expect(
          matchesFlavor(
            Flavor.production,
            'app.oshitrip.mobile.stg',
          ),
          isFalse,
        );
      });
    });

    test('allowedNativeIds は各 flavor ちょうど1件の共通IDを持つ', () {
      for (final flavor in Flavor.values) {
        expect(allowedNativeIds[flavor], hasLength(1));
      }
      // flavor 間で値が重複しない（development の id が staging/production の
      // 許可リストにも紛れ込んでいない）ことを確認する。
      final all = allowedNativeIds.values.expand((s) => s).toList();
      expect(all.toSet(), hasLength(all.length));
    });
  });
}
