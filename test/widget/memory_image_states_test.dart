import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/presentation/memory_detail_screen.dart';
import 'package:oshi_trip/features/memory/presentation/memory_list_screen.dart';
import 'package:path/path.dart' as p;

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 画像の異常状態（design-spec §12 / R7）を実画面で検証する:
/// - 端末から削除済み（missing）→ 理由の明示 + 写真の再選択導線
/// - 権限・ロック等で読めない（inaccessible）→ 理由の明示 + 再試行導線
/// - 端末に実体が無い（他端末で追加・storage のみ）→ 理由の明示
/// - 一覧の表紙も「写真なし」の装飾 placeholder と区別して明示する
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'mi-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  MemoryPhoto makePhoto({
    String id = 'p-1',
    String? localPath,
    String? storagePath,
    bool isCover = false,
  }) =>
      MemoryPhoto(
        id: id,
        genbaId: genbaId,
        ownerId: ownerId,
        localPath: localPath,
        storagePath: storagePath,
        isCover: isCover,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  Future<({ImageStore store, Directory dir})> makeImageStore() async {
    final dir = Directory.systemTemp.createTempSync('oshi_img_states');
    addTearDown(() => dir.deleteSync(recursive: true));
    return (store: ImageStore(dir), dir: dir);
  }

  testWidgets('端末から削除済み（missing）は理由と再選択導線を出す', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final img = await makeImageStore();
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [imageStoreProvider.overrideWithValue(img.store)],
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '画像検証公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await container.read(memoryRepositoryProvider).addPhoto(
          makePhoto(localPath: 'images/$ownerId/memory/deleted.jpg'),
        );
    await tester.pumpAndSettle();

    expect(find.textContaining('写真ファイルが見つかりません'), findsOneWidget);
    expect(find.textContaining('端末から削除された可能性'), findsOneWidget);
    // 対応可能な状態には再選択導線を出す（§12）。
    expect(find.text('写真を選び直す'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('読めない（inaccessible）は理由と再試行導線を出す', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final img = await makeImageStore();
    // ファイル位置にディレクトリを置く = 読み取れない状態（H-04 item3 の
    // 実分岐。実端末では権限不足・端末ロックが同じ状態に落ちる）。
    const ref = 'images/$ownerId/memory/locked.jpg';
    Directory(p.joinAll([img.dir.path, ...ref.split('/')]))
        .createSync(recursive: true);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [imageStoreProvider.overrideWithValue(img.store)],
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '画像検証公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await container
        .read(memoryRepositoryProvider)
        .addPhoto(makePhoto(localPath: ref));
    await tester.pumpAndSettle();

    expect(find.textContaining('写真を読み込めません'), findsOneWidget);
    expect(find.textContaining('権限がないか、端末がロック中'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('端末に実体が無い写真（他端末で追加）は状態を明示する', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final img = await makeImageStore();
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [imageStoreProvider.overrideWithValue(img.store)],
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '画像検証公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await container.read(memoryRepositoryProvider).addPhoto(
          makePhoto(storagePath: 'memories/$ownerId/remote.jpg'),
        );
    await tester.pumpAndSettle();

    expect(find.textContaining('この端末に写真の実体がありません'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('一覧の表紙が削除済みなら「写真なし」と区別して明示する', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final img = await makeImageStore();
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [imageStoreProvider.overrideWithValue(img.store)],
      child: const MemoryListScreen(),
    );
    final genbaRepo = container.read(genbaRepositoryProvider);
    // 過去の現場 = 思い出一覧に出る。
    await genbaRepo.upsertGenba(
      makeGenba(
        id: genbaId,
        ownerId: ownerId,
        title: '表紙が消えた公演',
        eventDate: DateTime(2026, 6, 1),
      ),
    );
    await genbaRepo.upsertGenba(
      makeGenba(
        id: 'mi-2',
        ownerId: ownerId,
        title: '写真なしの公演',
        eventDate: DateTime(2026, 5, 1),
      ),
    );
    await container.read(memoryRepositoryProvider).addPhoto(
          makePhoto(
            localPath: 'images/$ownerId/memory/gone.jpg',
            isCover: true,
          ),
        );
    await tester.pumpAndSettle();

    // 表紙削除済み → 状態を明示。写真なし現場 → 明示なし（装飾 placeholder のみ）。
    expect(find.text('表紙の写真が端末にありません'), findsOneWidget);
    expect(find.text('表紙が消えた公演'), findsOneWidget);
    expect(find.text('写真なしの公演'), findsOneWidget);
    await unmountApp(tester);
  });
}
