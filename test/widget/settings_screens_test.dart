import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/settings/application/oshi_color_controller.dart';
import 'package:oshi_trip/features/settings/application/settings_controller.dart';
import 'package:oshi_trip/features/settings/presentation/oshi_color_settings_screen.dart';
import 'package:oshi_trip/features/settings/presentation/theme_settings_screen.dart';

import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 設定（design-spec §11）: テーマ設定のプレビュー選択、推しカラーの
/// プリセット/カスタム選択と即時反映・自動保存。
void main() {
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  group('テーマ設定', () {
    testWidgets('ライト/ダークのプレビューカードがあり、選択が保存される', (tester) async {
      final db = await signedInTestDb();
      addTearDown(db.close);
      final container = await pumpScreen(
        tester,
        db: db,
        clock: clock,
        child: const ThemeSettingsScreen(),
      );

      // プレビューカード2枚（選択状態は Semantics で判別できる）。
      expect(find.bySemanticsLabel('ライトテーマ'), findsOneWidget);
      expect(find.bySemanticsLabel('ダークテーマ'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('ダークテーマ'));
      await tester.pumpAndSettle();

      // 即時反映（provider）と自動保存（KV）。
      expect(
        container.read(themeModeProvider).valueOrNull,
        ThemeMode.dark,
      );
      expect(await DriftKvStore(db).get(KvKeys.themeMode), 'dark');
      expect(find.bySemanticsLabel('ダークテーマ（選択中）'), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('推しカラー設定', () {
    testWidgets('プリセット8色以上が並び、選択が保存されプレビューへ反映される', (tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = await signedInTestDb();
      addTearDown(db.close);
      final container = await pumpScreen(
        tester,
        db: db,
        clock: clock,
        child: const OshiColorSettingsScreen(),
      );

      // プリセットは8色以上（§11）。
      final swatchSemantics = find.bySemanticsLabel(
        RegExp('^推しカラー: (?!カスタム)'),
      );
      expect(
        tester.widgetList(swatchSemantics).length,
        greaterThanOrEqualTo(8),
      );

      await tester.tap(find.bySemanticsLabel('推しカラー: ピンク'));
      await tester.pumpAndSettle();

      // 自動保存（provider + KV, owner 単位のキー）。
      expect(container.read(oshiColorProvider).valueOrNull, '#FF5CA8');
      expect(
        await DriftKvStore(db).get(KvKeys.oshiAccentColorFor('demo-user-1')),
        '#FF5CA8',
      );
      // 選択リング+チェック（色だけに依存しない, §11）。
      expect(
        find.bySemanticsLabel('推しカラー: ピンク（選択中）'),
        findsOneWidget,
      );
      // プレビュー（現場カード罫線・アバターリング）が存在する。
      expect(find.text('プレビューの現場'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('カスタムの不正なカラーコードは保存されず理由が表示される', (tester) async {
      tester.view.physicalSize = const Size(1080, 2800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = await signedInTestDb();
      addTearDown(db.close);
      final container = await pumpScreen(
        tester,
        db: db,
        clock: clock,
        child: const OshiColorSettingsScreen(),
      );

      await tester.tap(find.bySemanticsLabel('推しカラー: カスタム'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ピンクっぽい色');
      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      expect(
        find.text('カラーコードは #RRGGBB 形式で入力してください'),
        findsOneWidget,
      );
      expect(container.read(oshiColorProvider).valueOrNull, isNull);
      await unmountApp(tester);
    });
  });
}
