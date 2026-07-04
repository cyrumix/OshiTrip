import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/router.dart';
import 'package:oshi_trip/app/theme/app_theme.dart';
import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// StatefulShellRoute の実配線テスト（design-spec §5 / R7）。
///
/// 実際の routerProvider（GoRouter + AppShell + 5タブ）を使い、
/// - タブ移動後もスクロール位置と選択状態が保持されること
/// - FAB が Bottom Navigation・最終カードと重ならないこと
/// - 同期状態バナー（共通部品）がシェル上部に出ること
/// を検証する。テーマはハーネス側でのみ InkRipple へ差し替える（D-159。
/// 本番テーマは変更しない）。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<ProviderContainer> pumpShellApp(WidgetTester tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        nowProvider.overrideWith((ref) => Stream.value(clock.now())),
        imageStoreProvider.overrideWithValue(
          ImageStore(Directory.systemTemp.createTempSync('oshi_shell_img')),
        ),
      ],
    );
    addTearDown(container.dispose);
    final theme =
        AppTheme.light().copyWith(splashFactory: InkRipple.splashFactory);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(routerProvider),
          theme: theme,
          locale: const Locale('ja'),
          supportedLocales: const [Locale('ja')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('シェル上部に同期状態バナー（デモ）が出て、5タブが揃う', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpShellApp(tester);

    // 共通の同期状態バナー（全タブ共有・デモは常時明示, §13/§15.4）。
    expect(find.text('デモモード（端末内のみ保存）'), findsOneWidget);
    // 5タブ（アイコン+日本語ラベル+Tooltip, §5）。
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final tooltip in ['ホーム', '現場一覧', '思い出一覧', 'マイ推し', '設定']) {
      expect(find.byTooltip(tooltip), findsOneWidget);
    }
    await unmountApp(tester);
  });

  testWidgets('タブ移動後もスクロール位置と選択状態が保持される（§5）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await pumpShellApp(tester);
    final repo = container.read(genbaRepositoryProvider);
    for (var i = 0; i < 10; i++) {
      await repo.upsertGenba(
        makeGenba(
          id: 'g-$i',
          ownerId: ownerId,
          title: 'スクロール検証公演$i',
          eventDate: DateTime(2026, 8, 1 + i),
        ),
      );
    }

    // 現場タブへ移動して一覧をスクロールする。
    await tester.tap(find.byTooltip('現場一覧'));
    await tester.pumpAndSettle();
    expect(find.text('スクロール検証公演0'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('スクロール検証公演0'), findsNothing);

    // 別タブへ移動して戻る。
    await tester.tap(find.byTooltip('思い出一覧'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('現場一覧'));
    await tester.pumpAndSettle();

    // スクロール位置が保持されている（先頭カードは画面外のまま）。
    expect(find.text('スクロール検証公演0'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('FAB が Bottom Navigation と重ならず、最終カードまで読める（§5）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await pumpShellApp(tester);
    final repo = container.read(genbaRepositoryProvider);
    for (var i = 0; i < 6; i++) {
      await repo.upsertGenba(
        makeGenba(
          id: 'g-$i',
          ownerId: ownerId,
          title: '余白検証公演$i',
          eventDate: DateTime(2026, 8, 1 + i),
        ),
      );
    }
    await tester.tap(find.byTooltip('現場一覧'));
    await tester.pumpAndSettle();

    final fabRect = tester.getRect(find.byType(FloatingActionButton));
    final navRect = tester.getRect(find.byType(NavigationBar));
    expect(
      fabRect.overlaps(navRect),
      isFalse,
      reason: 'FAB が Bottom Navigation を覆ってはならない',
    );
    // FAB は 48dp 以上の主要タップ領域（§3）。
    expect(fabRect.width, greaterThanOrEqualTo(48));
    expect(fabRect.height, greaterThanOrEqualTo(48));

    // 最終カードまでスクロールでき、下端余白により FAB と重ならず読める。
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    final lastCard = find.text('余白検証公演5');
    expect(lastCard, findsOneWidget);
    final lastRect = tester.getRect(lastCard);
    expect(
      lastRect.overlaps(fabRect),
      isFalse,
      reason: '最終カードの本文が FAB に覆われてはならない',
    );
    await unmountApp(tester);
  });
}
