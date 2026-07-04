import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/genba_list_screen.dart';
import 'package:oshi_trip/features/home/presentation/home_screen.dart';
import 'package:oshi_trip/features/memory/application/memory_controllers.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/presentation/memory_list_screen.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';
import 'package:oshi_trip/features/oshi/presentation/oshi_screens.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 実画面（主要6領域）の代表マトリクス検証（design-spec §14/§15 / R7）。
///
/// 共通コンポーネント単体のマトリクス（design_system_matrix_test.dart）とは
/// 別に、実画面そのものを対象として横向き・dark・狭幅・文字200%・
/// 48dpタップ領域・Tooltip・error状態を分担して検証する。
/// 全条件×全画面の総当たりはせず、各条件を最も崩れやすい画面で代表させる。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  testWidgets('ホーム: 横向き（1200x540dp相当）でもヒーロー・FAB・主要情報が成立する', (tester) async {
    // 横向き相当の論理 1200x540。
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const HomeScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-land',
            ownerId: ownerId,
            title: '横向き検証公演',
            eventDate: DateTime(2026, 7, 12),
            venue: '横浜アリーナ',
          ),
        );
    await tester.pumpAndSettle();

    // オーバーフローがあれば pump 時に例外として検出される。
    expect(find.text('横向き検証公演'), findsOneWidget);
    expect(find.text('次の現場まで'), findsOneWidget);
    expect(find.byTooltip('現場を登録'), findsOneWidget); // FAB（アイコンのみ）
    await unmountApp(tester);
  });

  testWidgets('現場一覧: dark × 360dp でも状態チップと残日数が読める', (tester) async {
    tester.view.physicalSize = const Size(720, 1600); // 360x800dp
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      dark: true,
      child: const GenbaListScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-dark',
            ownerId: ownerId,
            title: 'ダーク検証公演',
            eventDate: DateTime(2026, 8, 1),
            venue: 'Zepp Nagoya',
          ),
        );
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('ダーク検証公演'))).brightness,
      Brightness.dark,
    );
    expect(find.text('ダーク検証公演'), findsOneWidget);
    expect(find.text('あと30日'), findsOneWidget);
    expect(find.bySemanticsLabel('状態: 予定'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('思い出一覧: 文字200%でも公演名と日付を失わない（§8/§14）', (tester) async {
    tester.view.physicalSize = const Size(720, 2800); // 360dp幅・縦長
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      textScale: 2.0,
      child: const MemoryListScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-scale',
            ownerId: ownerId,
            title: '文字拡大検証公演',
            eventDate: DateTime(2026, 6, 1),
            venue: 'Zepp Haneda',
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('文字拡大検証公演'), findsOneWidget);
    expect(find.textContaining('2026/6/1'), findsOneWidget);
    // 絞り込みタブも文字拡大で欠落しない（横スクロール可能, §14）。
    expect(find.text('すべて'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('マイ推し: 430dp で主要タップ領域が48dp以上・Tooltipを持つ（§3/§14）', (tester) async {
    tester.view.physicalSize = const Size(860, 2800); // 430dp幅
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const OshiListScreen(),
    );
    await container.read(oshiRepositoryProvider).upsertGroup(
          OshiGroup(
            id: 'og-1',
            ownerId: ownerId,
            name: 'タップ検証グループ',
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          ),
        );
    await tester.pumpAndSettle();

    // お気に入り: Tooltip（状態を含む）+ タップ領域48dp以上
    // （IconButton の materialTapTargetSize.padded を含めた実サイズで測る）。
    final favorite = find.byTooltip('タップ検証グループをお気に入りに追加');
    expect(favorite, findsOneWidget);
    final favoriteButton = find.ancestor(
      of: favorite,
      matching: find.byType(IconButton),
    );
    final favoriteSize = tester.getSize(favoriteButton);
    expect(favoriteSize.width, greaterThanOrEqualTo(48));
    expect(favoriteSize.height, greaterThanOrEqualTo(48));

    // グループ操作メニューも Tooltip を持つ。
    expect(find.byTooltip('グループの操作'), findsOneWidget);
    // FAB（推し追加）。
    final fab = find.byTooltip('推しグループを追加');
    expect(fab, findsOneWidget);
    expect(tester.getSize(fab).height, greaterThanOrEqualTo(48));
    await unmountApp(tester);
  });

  testWidgets('思い出一覧: 記録の読み込み失敗はエラーとして表示し、0件と誤認させない（§15）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [
        // 記録（bundle）ストリームの失敗を注入する。
        memoryBundleProvider.overrideWith(
          (ref, genbaId) => Stream<MemoryBundle>.error(
            const StorageFailure(message: 'テスト用の読み込み失敗'),
          ),
        ),
      ],
      child: const MemoryListScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-err',
            ownerId: ownerId,
            title: '読み込み失敗検証公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await tester.pumpAndSettle();

    // カードは現場名を出しつつ、記録は失敗として明示 + 再試行導線。
    expect(find.text('読み込み失敗検証公演'), findsOneWidget);
    expect(find.text('テスト用の読み込み失敗'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    await unmountApp(tester);
  });
}
