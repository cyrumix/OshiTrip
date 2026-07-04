import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/design_system/design_system.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/presentation/memory_list_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 思い出一覧（design-spec §8）: すべて/参戦済み/お気に入りの絞り込みと
/// お気に入りトグルの実データ反映。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<void> tapSegment(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentTabs),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('参戦済みフィルタは attended を明示した現場だけを表示する（§8/§12.1）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryListScreen(),
    );

    final repo = container.read(genbaRepositoryProvider);
    // 過去現場2件: 1件だけ参戦済み。過去でも自動で attended にはならない。
    await repo.upsertGenba(
      makeGenba(
        id: 'm-attended',
        ownerId: ownerId,
        title: '参戦した公演',
        eventDate: DateTime(2026, 6, 1),
        attendanceStatus: AttendanceStatus.attended,
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'm-planned',
        ownerId: ownerId,
        title: '行けなかった公演',
        eventDate: DateTime(2026, 6, 10),
      ),
    );
    await tester.pumpAndSettle();

    // すべて: 2件。
    expect(find.text('参戦した公演'), findsOneWidget);
    expect(find.text('行けなかった公演'), findsOneWidget);
    // attended の現場カードには「参戦済み」バッジが出る。
    expect(
      find.descendant(
        of: find.byType(PhotoMemoryCard),
        matching: find.text('参戦済み'),
      ),
      findsOneWidget,
    );

    // 参戦済み: 1件のみ。
    await tapSegment(tester, '参戦済み');
    expect(find.text('参戦した公演'), findsOneWidget);
    expect(find.text('行けなかった公演'), findsNothing);

    // すべてへ戻す。
    await tapSegment(tester, 'すべて');
    expect(find.text('行けなかった公演'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('お気に入りトグルが実データへ保存され、フィルタに反映される（§8）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryListScreen(),
    );

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'm-fav',
        ownerId: ownerId,
        title: 'お気に入り候補公演',
        eventDate: DateTime(2026, 6, 1),
      ),
    );
    await tester.pumpAndSettle();

    // お気に入りフィルタ: まだ0件。
    await tapSegment(tester, 'お気に入り');
    expect(find.text('お気に入り候補公演'), findsNothing);
    expect(find.text('お気に入りの思い出がありません'), findsOneWidget);

    // すべてへ戻り、ハートを押す（即時反映, §13）。
    await tapSegment(tester, 'すべて');
    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();

    // 実データ（MemoryEntry.isFavorite）に保存されている。
    final bundle = await container
        .read(memoryRepositoryProvider)
        .watchByGenbaId('m-fav')
        .first;
    expect(bundle.entry?.isFavorite, isTrue);

    // お気に入りフィルタに現れる。
    await tapSegment(tester, 'お気に入り');
    expect(find.text('お気に入り候補公演'), findsOneWidget);
    await unmountApp(tester);
  });
}
