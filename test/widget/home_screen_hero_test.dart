import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/home/presentation/home_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// ホーム（design-spec §6）: 次の現場ヒーロー・4分割状態・今後の現場。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  testWidgets('最も近い現場がヒーローで出て、残日数と4分割状態・今後の現場が表示される', (tester) async {
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
      child: const HomeScreen(),
    );

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'g-near',
        ownerId: ownerId,
        title: '一番近い公演',
        eventDate: DateTime(2026, 7, 12),
        venue: '東京ドーム',
        startTimeMinutes: 18 * 60,
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'g-far',
        ownerId: ownerId,
        title: '先の公演',
        eventDate: DateTime(2026, 9, 1),
      ),
    );
    await tester.pumpAndSettle();

    // ヒーロー: 残日数（7/2→7/12 = 10日）と「次の現場まで」。
    expect(find.text('次の現場まで'), findsOneWidget);
    // 残日数は Text.rich（'あと 10 日'）として描画される。
    expect(find.textContaining('あと 10 日'), findsOneWidget);
    expect(find.text('一番近い公演'), findsOneWidget);

    // 4分割の状態ショートカット（§6.2）。
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('交通'), findsOneWidget);
    expect(find.text('宿泊'), findsOneWidget);
    expect(find.text('チケット'), findsOneWidget);
    // チケット未登録が実データから導出されている。
    expect(find.bySemanticsLabel('チケット: 未登録'), findsOneWidget);

    // 今後の現場: ヒーローと同一現場を重複表示しない（§6.3）。
    expect(find.text('今後の現場'), findsOneWidget);
    expect(find.text('先の公演'), findsOneWidget);

    // FAB は残る。
    expect(find.text('現場を登録'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('現場ゼロは empty 状態（説明と次の1アクション）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const HomeScreen(),
    );
    expect(find.text('予定している現場がありません'), findsOneWidget);
    expect(find.text('現場を登録する'), findsOneWidget);
    await unmountApp(tester);
  });
}
