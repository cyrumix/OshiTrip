import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/presentation/memory_album_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';

/// 思い出アルバム（§8.4）: 分類チップでの絞り込みと、写真ゼロ時の空状態。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'al-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  MemoryPhoto makePhoto(
    String id, {
    required MemoryAlbumCategory category,
    String? subjectId,
    MemorySubjectType? subjectType,
    int sortOrder = 0,
  }) =>
      MemoryPhoto(
        id: id,
        genbaId: genbaId,
        ownerId: ownerId,
        albumCategory: category,
        subjectId: subjectId,
        subjectType: subjectType,
        sortOrder: sortOrder,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  Future<dynamic> pump(WidgetTester tester) async {
    // 分類チップ（横スクロール・遅延生成）を全件同時に可視化するため、
    // 横幅を広めに取る（画面外チップは build されず find できないため）。
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryAlbumScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: 'アルバム検証',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    return container;
  }

  testWidgets('分類チップに各件数が出て、選択で絞り込める（§8.4）', (tester) async {
    final container = await pump(tester);
    final repo = container.read(memoryRepositoryProvider);
    // グッズ写真は実在するグッズへ紐づける（Repository の実在検証を満たす）。
    await repo.upsertGoodsItem(
      GoodsItem(
        id: 'goods-1',
        genbaId: genbaId,
        ownerId: ownerId,
        name: 'アクスタ',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await repo
        .addPhoto(makePhoto('p-event', category: MemoryAlbumCategory.event));
    await repo.addPhoto(
      makePhoto(
        'p-goods',
        category: MemoryAlbumCategory.goods,
        subjectId: 'goods-1',
        subjectType: MemorySubjectType.goods,
        sortOrder: 1,
      ),
    );
    await tester.pumpAndSettle();

    // 各分類チップに件数が出る（すべて2 / 当日1 / グッズ1 / 他0）。
    expect(find.text('すべて（2）'), findsOneWidget);
    expect(find.text('当日の写真（1）'), findsOneWidget);
    expect(find.text('グッズ・戦利品（1）'), findsOneWidget);
    expect(find.text('行った場所（0）'), findsOneWidget);
    expect(find.text('食べたもの（0）'), findsOneWidget);

    // 「食べたもの」を選ぶと0件 → 空状態。
    await tester.tap(find.text('食べたもの（0）'));
    await tester.pumpAndSettle();
    expect(find.textContaining('「食べたもの」の写真はまだありません'), findsOneWidget);
  });

  testWidgets('写真ゼロなら全体の空状態を表示する', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('写真はまだありません'), findsOneWidget);
    expect(find.text('すべて（0）'), findsOneWidget);
  });

  testWidgets('320pt幅・文字200%でもオーバーフローせずグリッド表示できる（§9 a11y）', (tester) async {
    // 最小想定幅 320pt・文字倍率200%。overflow が出れば takeException で検出。
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      textScale: 2,
      child: const MemoryAlbumScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '狭幅検証',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    final repo = container.read(memoryRepositoryProvider);
    for (var i = 0; i < 5; i++) {
      await repo.addPhoto(
        makePhoto('p-$i', category: MemoryAlbumCategory.event, sortOrder: i),
      );
    }
    await tester.pumpAndSettle();

    // レイアウト例外（RenderFlex overflow 等）が出ていない。
    expect(tester.takeException(), isNull);
    // 正方形グリッド（統一サムネイル）が構築される。
    expect(find.byType(GridView), findsOneWidget);
    // 分類チップは横スクロールで先頭が見えている。
    expect(find.text('すべて（5）'), findsOneWidget);
  });
}
