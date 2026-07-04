import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/design_system/design_system.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/presentation/memory_detail_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 思い出詳細（design-spec §9）: カルーセル 1/N・お気に入り・閲覧タブ・
/// 写真なし縮退。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'md-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  MemoryPhoto makePhoto(String id, {int sortOrder = 0}) => MemoryPhoto(
        id: id,
        genbaId: genbaId,
        ownerId: ownerId,
        sortOrder: sortOrder,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  testWidgets('写真カルーセルに 1/N が出て、閲覧タブで感想・セトリを切り替えられる', (tester) async {
    // カルーセル(4:3)の下の感想カードまで1画面に収める縦長ビューポート
    // （他の画面テストと同じ実機相当サイズ。遅延ビルドの sliver が
    // ビューポート外で未構築になり誤って0件になるのを避ける）。
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
      child: const MemoryDetailScreen(genbaId: genbaId),
    );

    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '思い出の公演',
            eventDate: DateTime(2026, 6, 1),
            venue: 'Zepp',
          ),
        );
    final memoryRepo = container.read(memoryRepositoryProvider);
    await memoryRepo.addPhoto(makePhoto('p-1'));
    await memoryRepo.addPhoto(makePhoto('p-2', sortOrder: 1));
    await memoryRepo.upsertEntry(
      MemoryEntry(
        id: 'e-1',
        genbaId: genbaId,
        ownerId: ownerId,
        impression: '声出しできて最高だった',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await memoryRepo.upsertSetlistItem(
      SetlistItem(
        id: 's-1',
        genbaId: genbaId,
        ownerId: ownerId,
        position: 1,
        songTitle: 'オープニング曲',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await tester.pumpAndSettle();

    // カルーセルの現在位置 1/N（§9）。
    expect(find.text('1/2'), findsOneWidget);
    // アップロード未完了は「端末に保存済み」を出し、成功と誤認させない（§12.1）。
    expect(find.text('端末に保存済み'), findsOneWidget);

    // 感想タブ（既定）に日記カード。
    expect(find.text('声出しできて最高だった'), findsOneWidget);

    // セトリタブへ切替。
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentTabs),
        matching: find.text('セトリ'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('オープニング曲'), findsOneWidget);
    expect(find.text('声出しできて最高だった'), findsNothing);

    // 編集入口（閲覧と分離, §9）。
    expect(find.text('記録する'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('お気に入り操作が実データへ反映される（§9/§12.1）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '思い出の公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    // 写真なしでも感想を主役に成立する（§9）。
    await container.read(memoryRepositoryProvider).upsertEntry(
          MemoryEntry(
            id: 'e-1',
            genbaId: genbaId,
            ownerId: ownerId,
            impression: '写真はないけど最高',
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('写真はないけど最高'), findsOneWidget);
    expect(find.byType(SegmentTabs), findsOneWidget);

    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();
    final bundle = await container
        .read(memoryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(bundle.entry?.isFavorite, isTrue);
    await unmountApp(tester);
  });

  testWidgets('記録ゼロは「まだ記録がありません」へ縮退する', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '記録なしの公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('まだ記録がありません'), findsOneWidget);
    await unmountApp(tester);
  });
}
