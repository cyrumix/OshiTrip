import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 計画タブ（§7.3）: 手動スポットの追加→タイムライン表示→編集→削除、
/// 交通の参照取り込み（重複防止）、URLスキーム拒否、公演アンカー表示。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'plan-gb-1';
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

  testWidgets('空→手動スポット追加→タイムライン表示→編集→削除', (tester) async {
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
            title: '計画テスト公演',
            eventDate: DateTime(2026, 8, 1),
            startTimeMinutes: 18 * 60,
          ),
        );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    // 計画をまだ作っていなくても、公演予定は最初から確認できる。
    expect(find.text('計画はまだありません'), findsNothing);
    expect(find.text('公演 開演'), findsOneWidget);
    expect(find.textContaining('計画テスト公演'), findsWidgets);

    // スポットを追加（施設名は Google候補＋手入力の一体型フィールド）。
    await tapAddMenu(tester, 'スポットを追加（自分で入力）');
    expect(find.widgetWithText(TextField, '施設名 *'), findsOneWidget);
    // Google未設定（デモ環境）では候補は出ず、手入力として動く。
    expect(find.textContaining('そのまま手入力できます'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '東京タワー');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 訪問日の初期値は本日(2026/7/2)ではなく、現場開催日(2026/8/1)になる（点4）。
    // したがって候補ではなく開催日のセクションに出る。
    expect(find.text('東京タワー'), findsOneWidget);
    expect(find.text('候補（日付未定）'), findsNothing);
    expect(find.textContaining('2026/8/1'), findsWidgets);
    // DBにも spot + 訪問項目が保存され、訪問日が開催日で入る。
    final plans = await container
        .read(itineraryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(plans, hasLength(1));
    expect(plans.single.spots.single.name, '東京タワー');
    final spotEntries = plans.single.entries
        .where((e) => e.kind == ItineraryEntryKind.spot)
        .toList();
    expect(spotEntries, hasLength(1));
    expect(spotEntries.single.localDate, DateTime(2026, 8, 1));

    // 編集: メニュー→編集→改名。
    await tester.tap(find.byTooltip('操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '東京スカイツリー');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();
    expect(find.text('東京スカイツリー'), findsOneWidget);

    // 削除。
    await tester.tap(find.byTooltip('操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('旅程から削除…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(find.text('東京スカイツリー'), findsNothing);
    final after = await container
        .read(itineraryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(after.single.spots, isEmpty);

    await unmountApp(tester);
  });

  testWidgets('公演アンカー（開演）がタイムラインに固定表示される', (tester) async {
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
            doorTimeMinutes: 17 * 60,
            startTimeMinutes: 18 * 60,
          ),
        );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    expect(find.text('公演 開場'), findsOneWidget);
    expect(find.text('公演 開演'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('登録済みの交通を参照追加でき、重複は「追加済み」で防止される', (tester) async {
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
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTransport(
      makeTransportRef(
        id: 'tr-1',
        genbaId: genbaId,
        ownerId: ownerId,
        method: TransportMethod.shinkansen,
        fromPlace: '東京',
        toPlace: '大阪',
      ),
    );
    await tester.pumpAndSettle();
    await openPlanTab(tester);

    await tapAddMenu(tester, '登録済みの交通を追加');
    expect(find.text('往路 新幹線'), findsOneWidget);
    // 「追加」ボタン（FAB ラベルと衝突しないよう TextButton に限定）。
    await tester.tap(find.widgetWithText(TextButton, '追加'));
    await tester.pumpAndSettle();

    // タイムラインに交通が参照表示される（複製されない）。
    expect(find.text('往路 新幹線'), findsOneWidget);
    final plans = await container
        .read(itineraryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(
      plans.single.entries
          .where((e) => e.kind == ItineraryEntryKind.transport)
          .single
          .transportId,
      'tr-1',
    );

    // SnackBar を消してから再度メニューを開く（FABの位置ずれ回避）。
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // 再度開くと「追加済み」で重複防止（追加ボタンは出ない）。
    await tapAddMenu(tester, '登録済みの交通を追加');
    expect(find.text('追加済み'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '追加'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('スポットのURLは危険スキームを拒否する', (tester) async {
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

    await tapAddMenu(tester, 'スポットを追加（自分で入力）');
    await tester.tap(find.text('URLを追加'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'URL（https）'),
      'javascript:alert(1)',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    // ダイアログは閉じず、エラー表示（http/https のみ）。
    expect(find.textContaining('http/https'), findsOneWidget);

    await unmountApp(tester);
  });
}
