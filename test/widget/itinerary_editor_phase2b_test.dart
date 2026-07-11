import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';

/// Phase 2追補の編集画面テスト: 緯度・経度欄の非表示（点2）・既存座標の保持
/// （点3の座標保護）・スポットカテゴリ「聖地」のUI選択（点1）・移動区間の
/// 日付欄非表示（点8）。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'plan-b-gb';
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

  Future<ProviderContainer> boot(WidgetTester tester, AppDatabase db) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
            title: '追補テスト公演',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('スポット追加画面に緯度・経度欄が無く、カテゴリ「聖地」を選べる（点1/点2）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    await boot(tester, db);
    await openPlanTab(tester);

    await tapAddMenu(tester, 'スポットを追加（自分で入力）');
    // 施設名欄（Google候補＋手入力の一体型）が出る。
    expect(find.widgetWithText(TextField, '施設名 *'), findsOneWidget);

    // 緯度・経度の入力欄・説明は表示されない（点2）。
    expect(find.widgetWithText(TextField, '緯度'), findsNothing);
    expect(find.widgetWithText(TextField, '経度'), findsNothing);
    expect(find.textContaining('緯度・経度'), findsNothing);

    // カテゴリ「聖地」が選択肢として並ぶ（点1・UI）。
    expect(find.text('聖地'), findsWidgets);
    await tester.tap(find.text('聖地').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '記念すべき舞台');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    final plans = await db.select(db.itinerarySpots).get();
    expect(plans, hasLength(1));
    expect(plans.single.category, 'sacred_place');
    expect(plans.single.name, '記念すべき舞台');
  });

  testWidgets('既存スポットの編集で座標が消えない・緯度経度欄も出ない（点2/点3）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await boot(tester, db);

    // 座標つきスポット＋訪問項目を用意する。
    final repo = container.read(itineraryRepositoryProvider);
    final planRes = await repo.upsertPlan(
      makeItineraryPlan(id: 'plan-1', genbaId: genbaId, ownerId: ownerId),
    );
    expect(planRes.isOk, isTrue);
    final spotRes = await repo.upsertSpot(
      makeItinerarySpot(
        id: 'spot-1',
        planId: 'plan-1',
        ownerId: ownerId,
        name: '座標つきスポット',
        latitude: 35.658,
        longitude: 139.745,
      ),
    );
    expect(spotRes.isOk, isTrue);
    final entryRes = await repo.upsertEntry(
      makeItineraryEntry(
        id: 'entry-1',
        planId: 'plan-1',
        ownerId: ownerId,
        kind: ItineraryEntryKind.spot,
        spotId: 'spot-1',
        localDate: DateTime(2026, 8, 1),
      ),
    );
    expect(entryRes.isOk, isTrue);
    await tester.pumpAndSettle();
    await openPlanTab(tester);
    expect(find.text('座標つきスポット'), findsOneWidget);

    // 編集を開く。
    await tester.ensureVisible(find.byTooltip('操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集…'));
    await tester.pumpAndSettle();

    // 編集画面にも緯度・経度欄が無い（点2）。
    expect(find.widgetWithText(TextField, '緯度'), findsNothing);
    expect(find.widgetWithText(TextField, '経度'), findsNothing);

    // 名称だけ変更して保存する。
    await tester.enterText(find.byType(TextField).first, '改名したスポット');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 座標は保持される（誤って null で上書きしない, 点3）。
    final rows = await db.select(db.itinerarySpots).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, '改名したスポット');
    expect(rows.single.latitude, 35.658);
    expect(rows.single.longitude, 139.745);
  });

  testWidgets('移動区間の編集画面に日付入力欄が無く、時刻だけ入力する（点8）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await boot(tester, db);

    // 端点となる実予定を2件（同日）用意する。
    final repo = container.read(itineraryRepositoryProvider);
    await repo.upsertPlan(
      makeItineraryPlan(id: 'plan-1', genbaId: genbaId, ownerId: ownerId),
    );
    for (final id in ['s1', 's2']) {
      await repo.upsertSpot(
        makeItinerarySpot(
          id: id,
          planId: 'plan-1',
          ownerId: ownerId,
          name: '地点$id',
        ),
      );
      await repo.upsertEntry(
        makeItineraryEntry(
          id: 'e-$id',
          planId: 'plan-1',
          ownerId: ownerId,
          kind: ItineraryEntryKind.spot,
          spotId: id,
          localDate: DateTime(2026, 8, 1),
        ),
      );
    }
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    await tapAddMenu(tester, '移動区間を追加');
    expect(find.text('移動区間を追加'), findsOneWidget);

    // 時刻だけ入力（日付は前後予定から自動決定。説明文はUIから外した）。
    expect(find.textContaining('日付は出発元・到着先の予定日から自動'), findsNothing);
    expect(find.widgetWithText(InputDecorator, '出発時刻'), findsOneWidget);
    expect(find.widgetWithText(InputDecorator, '到着時刻'), findsOneWidget);
    // 通貨・運賃・経路概要・手動MapsURLの入力欄は通常UIに出さない（修正2/4）。
    expect(find.widgetWithText(TextField, '通貨（例: JPY）'), findsNothing);
    expect(find.widgetWithText(TextField, '運賃'), findsNothing);
    expect(find.widgetWithText(TextField, '経路概要'), findsNothing);
    expect(
      find.widgetWithText(TextField, 'Google Mapsで開くURL（任意）'),
      findsNothing,
    );
    // シート内に日付選択の導線が無い（日付は自動決定。時刻の「選択」だけ）。
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
  });

  testWidgets('2日目セクションから追加すると訪問日の初期値が2日目になる（点4 UI接続）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await boot(tester, db);

    // 1日目・2日目に実予定を1件ずつ。2日目は終了時刻15:00つき。
    final repo = container.read(itineraryRepositoryProvider);
    await repo.upsertPlan(
      makeItineraryPlan(id: 'plan-1', genbaId: genbaId, ownerId: ownerId),
    );
    await repo.upsertSpot(
      makeItinerarySpot(
        id: 'sp1',
        planId: 'plan-1',
        ownerId: ownerId,
        name: '1日目地点',
      ),
    );
    await repo.upsertEntry(
      makeItineraryEntry(
        id: 'e1',
        planId: 'plan-1',
        ownerId: ownerId,
        kind: ItineraryEntryKind.spot,
        spotId: 'sp1',
        localDate: DateTime(2026, 8, 1),
      ),
    );
    await repo.upsertSpot(
      makeItinerarySpot(
        id: 'sp2',
        planId: 'plan-1',
        ownerId: ownerId,
        name: '2日目地点',
      ),
    );
    await repo.upsertEntry(
      makeItineraryEntry(
        id: 'e2',
        planId: 'plan-1',
        ownerId: ownerId,
        kind: ItineraryEntryKind.spot,
        spotId: 'sp2',
        localDate: DateTime(2026, 8, 2),
      ).copyWith(
        startAt: DateTime.utc(2026, 8, 2, 14),
        endAt: DateTime.utc(2026, 8, 2, 15),
      ),
    );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    // 2日目セクションの「この日に追加」を押す。
    final addBtn = find.text('8/2にスポットを追加');
    await tester.ensureVisible(addBtn);
    await tester.pumpAndSettle();
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // 訪問日の初期値が2日目（本日=2026/7/2 ではない）。
    expect(find.text('2026-08-02'), findsWidgets);

    // 保存すると、DBの新規項目が2日目・開始15:00（直前予定の終了時刻）で入る。
    await tester.enterText(find.byType(TextField).first, '2日目に追加');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    final entries = await db.select(db.itineraryEntries).get();
    final created = entries.firstWhere(
      (e) => e.id != 'e1' && e.id != 'e2',
    );
    expect(created.localDate, '2026-08-02');
    expect(created.startAt, isNotNull);
    expect(DateTime.parse(created.startAt!).hour, 15);
  });
}
