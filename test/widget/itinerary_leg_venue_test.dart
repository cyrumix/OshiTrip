import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 移動区間の時刻初期値・所要自動計算・金額欄/通貨欄（item 2/3/4）、
/// 「会場を追加」（item 8）を検証する。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'lv-gb-1';
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

  testWidgets('移動区間: 端点選択で出発=移動元終了/到着=移動先開始が初期値になり、所要が自動計算・金額欄あり通貨欄なし',
      (tester) async {
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
    final repo = container.read(itineraryRepositoryProvider);
    await repo
        .upsertPlan(makeItineraryPlan(ownerId: ownerId, genbaId: genbaId));
    // 移動元スポットA（終了16:00）、移動先スポットB（開始17:00）。
    await repo.saveSpotBundle(
      spot: makeItinerarySpot(id: 'spA', ownerId: ownerId, name: '地点A'),
      entry: makeItineraryEntry(
        id: 'enA',
        ownerId: ownerId,
        kind: ItineraryEntryKind.spot,
        spotId: 'spA',
        localDate: DateTime(2026, 8, 1),
        startAt: DateTime.utc(2026, 8, 1, 15, 0),
        endAt: DateTime.utc(2026, 8, 1, 16, 0),
      ),
      links: const [],
    );
    await repo.saveSpotBundle(
      spot: makeItinerarySpot(id: 'spB', ownerId: ownerId, name: '地点B'),
      entry: makeItineraryEntry(
        id: 'enB',
        ownerId: ownerId,
        kind: ItineraryEntryKind.spot,
        spotId: 'spB',
        localDate: DateTime(2026, 8, 1),
        startAt: DateTime.utc(2026, 8, 1, 17, 0),
      ),
      links: const [],
    );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    await tapAddMenu(tester, '移動区間を追加');
    // 金額（円）欄はあり、通貨欄・所要（分）入力欄は無い（item 3/4）。
    expect(find.widgetWithText(TextField, '金額（円）'), findsOneWidget);
    expect(find.widgetWithText(TextField, '通貨（例: JPY）'), findsNothing);
    expect(find.widgetWithText(TextField, '所要（分）'), findsNothing);

    // 出発=地点A、到着=地点B を選ぶ。
    await tester.tap(find.byKey(const Key('leg_origin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('地点A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('地点B').last);
    await tester.pumpAndSettle();

    // 出発=移動元の終了(16:00)、到着=移動先の開始(17:00)が初期値として入る（item 2）。
    // 時刻の表示書式はロケール依存のため、両時刻フィールドが「未設定」でなく、
    // かつ自動計算の所要が 16:00→17:00=約60分になることで初期値の適用を検証する。
    expect(find.text('未設定'), findsNothing);
    expect(find.textContaining('約60分'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('会場を追加: 現場の会場をライブ・イベント会場スポットとして計画へ追加する（item 8）', (tester) async {
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
            endTimeMinutes: 20 * 60,
          ),
        );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    await tapAddMenu(tester, '会場を追加');
    await tester.pumpAndSettle();

    // 会場がスポットとして計画に追加される（カテゴリ=会場、訪問日=開催日、
    // 開始=開場17:00、終了=終演20:00）。
    final plan = (await container
            .read(itineraryRepositoryProvider)
            .watchByGenbaId(genbaId)
            .first)
        .single;
    final venueSpot = plan.spots
        .where((s) => s.category == ItinerarySpotCategory.venue)
        .toList();
    expect(venueSpot, hasLength(1));
    expect(venueSpot.single.name, '大阪城ホール');
    final entry =
        plan.entries.where((e) => e.spotId == venueSpot.single.id).single;
    expect(entry.localDate, DateTime(2026, 8, 1));
    expect(entry.startAt?.toLocal().hour, 17);
    expect(entry.endAt?.toLocal().hour, 20);

    await unmountApp(tester);
  });

  testWidgets('会場未登録なら「先に会場を登録してください」と案内する（item 8）', (tester) async {
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

    await tapAddMenu(tester, '会場を追加');
    await tester.pump();
    expect(find.textContaining('先に会場を登録してください'), findsOneWidget);

    await unmountApp(tester);
  });
}
