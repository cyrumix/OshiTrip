import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/design_system/design_system.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
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

  testWidgets('思い出は年ごとにまとまり、各年に「n現場・n参戦」サマリーが出る（§8 半券ホルダー）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryListScreen(),
    );
    final repo = container.read(genbaRepositoryProvider);
    // 2026年: 2現場（うち1参戦）、2025年: 1現場（0参戦）。
    await repo.upsertGenba(
      makeGenba(
        id: 'y26-a',
        ownerId: ownerId,
        title: '2026春公演',
        eventDate: DateTime(2026, 5, 1),
        attendanceStatus: AttendanceStatus.attended,
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'y26-b',
        ownerId: ownerId,
        title: '2026冬公演',
        eventDate: DateTime(2026, 1, 20),
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'y25-a',
        ownerId: ownerId,
        title: '2025公演',
        eventDate: DateTime(2025, 11, 3),
      ),
    );
    await tester.pumpAndSettle();

    // 年ヘッダとサマリー（参戦0の年は「n現場」のみ）。ラベルは「…。ふりかえりを見る」。
    final h2026 = find.bySemanticsLabel(RegExp('2026年、2現場・1参戦'));
    final h2025 = find.bySemanticsLabel(RegExp('2025年、1現場'));
    expect(h2026, findsOneWidget);
    expect(h2025, findsOneWidget);

    // 新しい年が先（2026ヘッダが2025ヘッダより上）。
    final y2026 = tester.getTopLeft(h2026);
    final y2025 = tester.getTopLeft(h2025);
    expect(y2026.dy, lessThan(y2025.dy));

    // 同一年内は新しい現場が先（2026春=5月 が 2026冬=1月 より上）。
    final springDy = tester.getTopLeft(find.text('2026春公演')).dy;
    final winterDy = tester.getTopLeft(find.text('2026冬公演')).dy;
    expect(springDy, lessThan(winterDy));
    // 2025の現場は2026ヘッダより下（グルーピングされている）。
    expect(tester.getTopLeft(find.text('2025公演')).dy, greaterThan(y2025.dy));
    await unmountApp(tester);
  });

  testWidgets('年ヘッダをタップすると「◯年のふりかえり」が開く（§8/M5）', (tester) async {
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
        id: 'r-1',
        ownerId: ownerId,
        title: 'ふりかえり公演A',
        artistName: 'ABC',
        eventDate: DateTime(2026, 5, 1),
        venue: '東京ドーム',
        attendanceStatus: AttendanceStatus.attended,
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'r-2',
        ownerId: ownerId,
        title: 'ふりかえり公演B',
        artistName: 'ABC',
        eventDate: DateTime(2026, 3, 1),
        venue: '東京ドーム',
      ),
    );
    await tester.pumpAndSettle();

    // 年ヘッダをタップ → ふりかえりシート。
    await tester.tap(find.bySemanticsLabel(RegExp('2026年、2現場・1参戦')));
    await tester.pumpAndSettle();

    // ふりかえりシートが開く（見出しはシート固有）。
    expect(find.text('2026年のふりかえり'), findsOneWidget);
    expect(find.text('よく会いに行った'), findsOneWidget);
    expect(find.text('よく行った会場'), findsOneWidget);
    // よく会いに行った推し・よく行った会場が集計される（カードにも出るため複数可）。
    expect(find.text('ABC'), findsWidgets);
    expect(find.text('東京ドーム'), findsWidgets);
    // 主役の数字（現場数・参戦数）の単位はシート固有。
    expect(find.text('参戦'), findsOneWidget);
    expect(find.text('現場'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('ふりかえりの写真数はバンドルから集計され、0に潰さない（レビュー是正）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryListScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'pc-1',
            ownerId: ownerId,
            title: '写真集計公演',
            eventDate: DateTime(2026, 4, 1),
          ),
        );
    // この現場に写真を2枚登録（ふりかえりで反映されること）。
    final memoryRepo = container.read(memoryRepositoryProvider);
    for (final id in ['ph-1', 'ph-2']) {
      await memoryRepo.addPhoto(
        MemoryPhoto(
          id: id,
          genbaId: 'pc-1',
          ownerId: ownerId,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
    }
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('2026年、1現場')));
    await tester.pumpAndSettle();

    expect(find.text('2026年のふりかえり'), findsOneWidget);
    // 写真ミニスタッツに 2枚（バンドルからの集計）。0枚に潰れていない。
    expect(find.text('2枚'), findsOneWidget);
    await unmountApp(tester);
  });
}
