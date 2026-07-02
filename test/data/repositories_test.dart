import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_expedition/core/db/app_database.dart';
import 'package:oshi_expedition/core/logging/app_logger.dart';
import 'package:oshi_expedition/core/network/connectivity.dart';
import 'package:oshi_expedition/core/sync/outbox_operation.dart';
import 'package:oshi_expedition/core/sync/outbox_store.dart';
import 'package:oshi_expedition/core/sync/sync_engine.dart';
import 'package:oshi_expedition/core/time/clock.dart';
import 'package:oshi_expedition/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_expedition/features/genba/domain/genba.dart';
import 'package:oshi_expedition/features/memory/data/memory_repository_impl.dart';
import 'package:oshi_expedition/features/memory/domain/memory.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late OutboxStore outbox;
  late SyncEngine engine;
  late GenbaRepositoryImpl genbaRepo;
  late MemoryRepositoryImpl memoryRepo;
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    outbox = OutboxStore(db, clock);
    engine = SyncEngine(
      store: outbox,
      remoteResolver: () => null, // デモ相当: ローカルのみ
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    genbaRepo = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    memoryRepo = MemoryRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
    );
  });

  test('現場作成: ローカル即時反映 + Outbox 追加（UIは通信を待たない）', () async {
    final genba = makeGenba(eventDate: DateTime(2026, 8, 1));
    final result = await genbaRepo.upsertGenba(genba);
    expect(result.isOk, isTrue);

    final all = await genbaRepo.watchAll().first;
    expect(all, hasLength(1));
    expect(all.first.genba.title, 'テスト公演');

    final ops = await outbox.pendingOps();
    expect(ops, hasLength(1));
    expect(ops.first.entityTable, SyncEntity.genbas);
    expect(ops.first.opType, OutboxOpType.upsert);
    expect(ops.first.payload['title'], 'テスト公演');
  });

  test('未ログインの書き込みは AuthFailure（ローカルにも書かない）', () async {
    final repo = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => null,
      remoteResolver: () => null,
    );
    final result =
        await repo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    expect(result.failureOrNull?.message, contains('ログイン'));
    expect(await repo.watchAll().first, isEmpty);
  });

  test('Todo完了の更新が集約に反映され、更新ごとに Outbox が積まれる', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    await genbaRepo.upsertTodo(makeTodo());

    var aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.incompleteTodoCount, 1);

    await genbaRepo.upsertTodo(makeTodo(isDone: true));
    aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.incompleteTodoCount, 0);

    final ops = await outbox.pendingOps();
    expect(ops.where((o) => o.entityTable == SyncEntity.todos), hasLength(2));
  });

  test('メモは区分ごとに1件が維持される（upsert）', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    GenbaMemo memo(String id, String body) => GenbaMemo(
          id: id,
          genbaId: 'genba-1',
          ownerId: 'user-1',
          category: MemoCategory.meetup,
          body: body,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );
    await genbaRepo.upsertMemo(memo('m1', '東口噴水前'));
    await genbaRepo.upsertMemo(memo('m1', '西口に変更'));

    final aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.memos, hasLength(1));
    expect(aggregate.memoOf(MemoCategory.meetup)?.body, '西口に変更');
  });

  test('現場削除で子データと思い出も消える', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));
    await genbaRepo.upsertTodo(makeTodo());
    await memoryRepo.upsertEntry(
      MemoryEntry(
        id: 'e1',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        impression: '最高',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );

    await genbaRepo.deleteGenba('genba-1');
    expect(await genbaRepo.watchAll().first, isEmpty);
    final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
    expect(bundle.entry, isNull);
  });

  test('思い出入力: 同一IDのまま entry が upsert され Outbox に載る', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));
    final entry = MemoryEntry(
      id: 'e1',
      genbaId: 'genba-1',
      ownerId: 'user-1',
      impression: '短い感想',
      createdAt: fixedCreatedAt,
      updatedAt: fixedCreatedAt,
    );
    await memoryRepo.upsertEntry(entry);
    // 短い感想を本文として加筆（同じ欄, §8.2）
    await memoryRepo.upsertEntry(entry.copyWith(impression: '短い感想。翌日に加筆。'));

    final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
    expect(bundle.entry?.id, 'e1');
    expect(bundle.entry?.impression, contains('加筆'));

    final ops = await outbox.pendingOps();
    expect(
      ops.where((o) => o.entityTable == SyncEntity.memoryEntries),
      hasLength(2),
    );
  });

  test('写真は localPath を保持し、Outbox payload には localPath を載せない', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));
    await memoryRepo.addPhoto(
      MemoryPhoto(
        id: 'p1',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        localPath: r'C:\photos\live.jpg',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );

    final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
    expect(bundle.photos.single.localPath, isNotNull);
    expect(bundle.photos.single.uploadStatus, PhotoUploadStatus.localOnly);

    final op = (await outbox.pendingOps())
        .singleWhere((o) => o.entityTable == SyncEntity.memoryPhotos);
    expect(op.payload.containsKey('local_path'), isFalse);
    expect(op.payload['upload_status'], 'local_only');
  });
}
