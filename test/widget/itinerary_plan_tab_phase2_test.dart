import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/presentation/plan_tab.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// Phase 2レビュー点3/点5/レスポンシブ: 会場ヘッダの融合表示、移動区間(leg)の
/// 追加・表示・削除、時刻/所要/距離/運賃の表示、狭幅・横向き・文字200%での破綻なし。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'plan2-gb-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<void> openPlanTab(WidgetTester tester) async {
    final tab =
        find.descendant(of: find.byType(TabBar), matching: find.text('計画'));
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  Future<void> tapAddMenu(WidgetTester tester, String itemLabel) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel));
    await tester.pumpAndSettle();
  }

  Future<void> addSpot(WidgetTester tester, String name) async {
    await tapAddMenu(tester, 'スポットを追加（自分で入力）');
    await tester.enterText(find.byType(TextField).first, name);
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();
    // SnackBar を消してから次の操作へ（FABの位置ずれ回避）。
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('公演日に会場ヘッダ（会場名）が融合タイムラインへ固定表示される', (tester) async {
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
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
            venue: '大阪城ホール',
            doorTimeMinutes: 17 * 60,
            startTimeMinutes: 18 * 60,
          ),
        );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    // 計画を作るため1件追加（アンカー・会場は計画表示時に出る）。
    await addSpot(tester, '集合');

    expect(find.text('会場 大阪城ホール'), findsOneWidget);
    expect(find.text('公演 開場'), findsOneWidget);
    expect(find.text('公演 開演'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('移動区間を追加→表示→削除できる', (tester) async {
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
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    await addSpot(tester, 'A地点');
    await addSpot(tester, 'B地点');

    // 移動区間を追加。
    await tapAddMenu(tester, '移動区間を追加');
    await tester.tap(find.byKey(const Key('leg_origin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A地点').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B地点').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 区間が表示される（既定は徒歩、端点ラベル付き）。
    expect(find.text('移動 徒歩'), findsOneWidget);
    expect(find.text('A地点 → B地点'), findsOneWidget);
    final legs1 = (await container
            .read(itineraryRepositoryProvider)
            .watchByGenbaId(genbaId)
            .first)
        .single
        .legs;
    expect(legs1, hasLength(1));

    // 削除（区間カードを可視化してからメニューを開く。ピン留めTabBar裏を回避）。
    final legMenu = find.byTooltip('移動区間の操作');
    await tester.ensureVisible(legMenu);
    await tester.pumpAndSettle();
    await tester.tap(legMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('移動区間を削除…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(find.text('移動 徒歩'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('移動区間は手段・時刻・所要・距離・運賃を表示する', (tester) async {
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
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final gr = container.read(genbaRepositoryProvider);
    await gr.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    final repo = container.read(itineraryRepositoryProvider);
    await repo
        .upsertPlan(makeItineraryPlan(ownerId: ownerId, genbaId: genbaId));
    await repo.upsertEntry(
      makeItineraryEntry(
        id: 'ex',
        ownerId: ownerId,
        kind: ItineraryEntryKind.note,
        titleOverride: 'X地点',
      ),
    );
    await repo.upsertEntry(
      makeItineraryEntry(
        id: 'ey',
        ownerId: ownerId,
        kind: ItineraryEntryKind.note,
        titleOverride: 'Y地点',
      ),
    );
    await repo.upsertLeg(
      makeItineraryLeg(
        id: 'leg-disp',
        ownerId: ownerId,
        originEntryId: 'ex',
        destinationEntryId: 'ey',
        durationMinutes: 30,
        distanceMeters: 1000,
        fareAmountMinor: 500,
        fareCurrency: 'JPY',
        departureAt: DateTime.utc(2026, 8, 1, 0, 0),
        arrivalAt: DateTime.utc(2026, 8, 1, 0, 30),
      ),
    );
    await tester.pumpAndSettle();
    // 前提: 計画・項目・区間がDBに保存されている。
    final seeded = (await container
            .read(itineraryRepositoryProvider)
            .watchByGenbaId(genbaId)
            .first)
        .single;
    expect(seeded.entries, hasLength(2), reason: 'note entries seeded');
    expect(seeded.legs, hasLength(1), reason: 'leg seeded');
    await openPlanTab(tester);

    expect(find.text('移動 徒歩'), findsOneWidget);
    expect(find.text('X地点 → Y地点'), findsOneWidget);
    expect(find.textContaining('約30分'), findsOneWidget);
    expect(find.textContaining('1.0km'), findsOneWidget);
    expect(find.textContaining('500 JPY'), findsOneWidget);
    expect(find.textContaining('発 →'), findsOneWidget);

    await unmountApp(tester);
  });

  // 計画タブ単体を、指定サイズ・文字倍率で pump し、会場・アンカー・スポット・
  // 移動区間を1画面に載せる（周辺画面のchromeを除いて融合表示の破綻を検証）。
  Future<void> pumpPlanTabOnly(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final genba = makeGenba(
      id: genbaId,
      ownerId: ownerId,
      eventDate: DateTime(2026, 8, 1),
      venue: '大阪城ホール',
      doorTimeMinutes: 17 * 60,
      startTimeMinutes: 18 * 60,
      endTimeMinutes: 20 * 60,
    );
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      textScale: textScale,
      child: PlanTab(genbaAggregate: GenbaAggregate(genba: genba)),
    );
    // 親genba + 計画 + 訪問項目 + 移動区間 を用意（融合表示を厚めに検証）。
    await container.read(genbaRepositoryProvider).upsertGenba(genba);
    final repo = container.read(itineraryRepositoryProvider);
    await repo.upsertPlan(
      makeItineraryPlan(ownerId: ownerId, genbaId: genbaId),
    );
    await repo.upsertEntry(
      makeItineraryEntry(
        id: 'ea',
        ownerId: ownerId,
        kind: ItineraryEntryKind.note,
        titleOverride: '集合してから物販に並ぶ予定',
        localDate: DateTime(2026, 8, 1),
        startAt: DateTime.utc(2026, 8, 1, 16, 0),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('狭幅320pt・文字200%でも会場/アンカー/項目が破綻なく表示される', (tester) async {
    await pumpPlanTabOnly(
      tester,
      size: const Size(320, 2200),
      textScale: 2.0,
    );
    // オーバーフロー例外が出れば pumpAndSettle 中に失敗する。表示も確認。
    expect(find.text('会場 大阪城ホール'), findsOneWidget);
    expect(find.text('公演 開演'), findsOneWidget);
    // Semantics: アンカーは時刻付きの読み上げラベルを持つ。
    expect(find.bySemanticsLabel(RegExp('公演開演')), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('横向き（wide-short）でもタイムラインが破綻なく表示される', (tester) async {
    await pumpPlanTabOnly(tester, size: const Size(1600, 480));
    expect(find.text('会場 大阪城ホール'), findsOneWidget);
    await unmountApp(tester);
  });
}
