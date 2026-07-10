import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 概要タブの「次の予定」カード（§7.9）: 開催当日かつ計画にユーザー追加項目が
/// ある場合のみ、概要カードの下・やることリストの前に表示する。計画未作成、
/// または開催当日でない場合は表示しない。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'ov-gb-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 9));

  Future<void> openTab(WidgetTester tester, String label) async {
    final tab =
        find.descendant(of: find.byType(TabBar), matching: find.text(label));
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  testWidgets('開催当日かつスポット追加済みなら「次の予定」カードを表示する', (tester) async {
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
            eventDate: DateTime(2026, 7, 2),
          ),
        );
    await tester.pumpAndSettle();

    // 計画タブでスポットを1件追加する。
    await openTab(tester, '計画');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スポットを追加（自分で入力）'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '集合場所');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 概要タブへ戻ると「次の予定」カードが出る。
    await openTab(tester, '概要');
    expect(find.text('次の予定'), findsOneWidget);
    expect(find.textContaining('集合場所'), findsWidgets);

    await unmountApp(tester);
  });

  testWidgets('計画未作成なら「次の予定」カードを表示しない', (tester) async {
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
            eventDate: DateTime(2026, 7, 2),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('次の予定'), findsNothing);

    await unmountApp(tester);
  });

  testWidgets('開催当日でなければスポット追加済みでも「次の予定」カードを表示しない', (tester) async {
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
    // 開催日は本日(2026/7/2)ではない。
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();

    await openTab(tester, '計画');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スポットを追加（自分で入力）'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '集合場所');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    await openTab(tester, '概要');
    expect(find.text('次の予定'), findsNothing);

    await unmountApp(tester);
  });
}
