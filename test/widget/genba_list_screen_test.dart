import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/genba_list_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 現場一覧のR7移行（design-spec §6.3 / H-07）:
/// 状態（文字＋アイコン）・準備状態・残日数・中止現場の非消失・empty状態。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  testWidgets('未来の現場が状態チップ・準備チップ・残日数つきで表示され、中止も消えない', (tester) async {
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
      child: const GenbaListScreen(),
    );

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'g-scheduled',
        ownerId: ownerId,
        title: '予定の公演',
        eventDate: DateTime(2026, 8, 1),
        venue: '東京ドーム',
        startTimeMinutes: 18 * 60,
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'g-canceled',
        ownerId: ownerId,
        title: '中止になった公演',
        eventDate: DateTime(2026, 8, 10),
        isCanceled: true,
      ),
    );
    await tester.pumpAndSettle();

    // 予定の公演: 日付・会場・残日数（7/2→8/1 = 30日）・状態チップ。
    expect(find.text('予定の公演'), findsOneWidget);
    expect(find.text('東京ドーム'), findsOneWidget);
    expect(find.text('あと30日'), findsOneWidget);
    expect(find.bySemanticsLabel('状態: 予定'), findsOneWidget);

    // 準備状態は実データから導出（チケット未登録）。
    expect(find.text('チケット 未登録'), findsNWidgets(2));

    // 未来の中止現場は一覧から消えず「中止」と分かる（H-07）。
    expect(find.text('中止になった公演'), findsOneWidget);
    expect(find.bySemanticsLabel('状態: 中止'), findsOneWidget);

    // FAB。
    expect(find.byTooltip('現場を登録'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('現場ゼロは empty 状態（説明と次の1アクション）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaListScreen(),
    );
    expect(find.text('これからの現場がありません'), findsOneWidget);
    expect(find.text('現場を登録する'), findsOneWidget);
    await unmountApp(tester);
  });
}
