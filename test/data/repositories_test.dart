import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/data/memory_repository_impl.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

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
      snapshotResolver: () => null, // デモ相当: ローカルのみ（同期しない）
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

    final ops = await outbox.pendingOps(ownerId: 'user-1');
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

    final ops = await outbox.pendingOps(ownerId: 'user-1');
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

    final ops = await outbox.pendingOps(ownerId: 'user-1');
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

    final op = (await outbox.pendingOps(ownerId: 'user-1'))
        .singleWhere((o) => o.entityTable == SyncEntity.memoryPhotos);
    expect(op.payload.containsKey('local_path'), isFalse);
    expect(op.payload['upload_status'], 'local_only');
  });

  // --------------------------------------------------------------------
  // C-01: 認証主体ごとのローカルデータ完全分離（必須テスト）
  // --------------------------------------------------------------------
  group('ユーザー分離（C-01）', () {
    late GenbaRepositoryImpl genbaRepoB;
    late MemoryRepositoryImpl memoryRepoB;

    setUp(() {
      genbaRepoB = GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-2',
        remoteResolver: () => null,
      );
      memoryRepoB = MemoryRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-2',
      );
    });

    test('2ユーザーが同一DBを切り替えても互いの現場・Outboxが見えない', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-a',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      await genbaRepoB.upsertGenba(
        makeGenba(
          id: 'genba-b',
          ownerId: 'user-2',
          eventDate: DateTime(2026, 8, 2),
        ),
      );

      final aList = await genbaRepo.watchAll().first;
      final bList = await genbaRepoB.watchAll().first;
      expect(aList.map((a) => a.genba.id), ['genba-a']);
      expect(bList.map((a) => a.genba.id), ['genba-b']);

      final aOps = await outbox.pendingOps(ownerId: 'user-1');
      final bOps = await outbox.pendingOps(ownerId: 'user-2');
      expect(aOps.map((o) => o.entityId), ['genba-a']);
      expect(bOps.map((o) => o.entityId), ['genba-b']);
    });

    test('別ownerが作った同一IDの現場は watchById で見えない', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-x',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      // user-2 は同一DBに同じID('genba-x')の行が存在しないため null。
      final seenByB = await genbaRepoB.watchById('genba-x').first;
      expect(seenByB, isNull);
    });

    test('別ownerの同一IDに対する削除は何も変更しない（負例）', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-x',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      // user-2 の視点から同じID を削除しようとしても、owner が一致しないため
      // WHERE 句にヒットせず user-1 の行は残る。
      final result = await genbaRepoB.deleteGenba('genba-x');
      expect(result.isOk, isTrue); // 削除対象0件でも操作自体は成功として扱う
      final stillThere = await genbaRepo.watchById('genba-x').first;
      expect(stillThere, isNotNull);
    });

    test('別ownerの同一IDに対するTodo upsertは拒否され、原本は変更されない（負例）', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-x',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      await genbaRepo.upsertTodo(
        makeTodo(
          id: 'todo-x',
          genbaId: 'genba-x',
          ownerId: 'user-1',
          name: '原本',
        ),
      );
      // user-2 が同一ID 'todo-x' を upsert しようとした場合、Drift の
      // insertOnConflictUpdate は owner を見ず id だけで競合判定するため、
      // 何もしなければ user-1 の行を上書きしてしまう。事前チェックで拒否する。
      final result = await genbaRepoB.upsertTodo(
        makeTodo(
          id: 'todo-x',
          genbaId: 'genba-x',
          ownerId: 'user-2',
          name: '改ざん',
        ),
      );
      expect(result.isOk, isFalse);
      expect(result.failureOrNull?.message, contains('別ユーザー'));

      final aAggregate = await genbaRepo.watchById('genba-x').first;
      expect(aAggregate!.todos.single.name, '原本');
      expect(aAggregate.todos.single.ownerId, 'user-1');
    });

    test('owner不一致のupsertはAuthFailureで拒否される（推測ID/なりすまし対策）', () async {
      // genbaRepo の owner resolver は user-1 だが、渡す entity の ownerId が
      // user-2 の場合は拒否する（払い出し済みentityの偽装防止）。
      final result = await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-spoof',
          ownerId: 'user-2',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      expect(result.isOk, isFalse);
      expect(result.failureOrNull?.message, contains('所有者'));
      final all = await genbaRepo.watchAll().first;
      expect(all, isEmpty);
    });

    test('思い出も owner ごとに分離される', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-x',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 6, 1),
        ),
      );
      await memoryRepo.upsertEntry(
        MemoryEntry(
          id: 'e1',
          genbaId: 'genba-x',
          ownerId: 'user-1',
          impression: 'user-1の感想',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );

      // user-2 は同じ genbaId を照会しても自分の行がないので空。
      final bundleB = await memoryRepoB.watchByGenbaId('genba-x').first;
      expect(bundleB.entry, isNull);

      final bundleA = await memoryRepo.watchByGenbaId('genba-x').first;
      expect(bundleA.entry?.impression, 'user-1の感想');
    });

    test('未認証（owner未解決）ではクエリを発行せず空を返す', () async {
      final unauthenticated = GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => null,
        remoteResolver: () => null,
      );
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-x',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      expect(await unauthenticated.watchAll().first, isEmpty);
      expect(await unauthenticated.watchById('genba-x').first, isNull);
    });
  });

  // --------------------------------------------------------------------
  // C-01: 子データの親owner整合（存在しない親・別ownerの親・推測IDを拒否）
  // --------------------------------------------------------------------
  group('親owner整合（C-01）', () {
    test('親現場が存在しない子(Todo)のupsertは拒否され、ローカルもOutboxも作られない', () async {
      final result = await genbaRepo.upsertTodo(
        makeTodo(
          id: 'todo-orphan',
          genbaId: 'genba-missing',
          ownerId: 'user-1',
        ),
      );
      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await db.select(db.todos).get(), isEmpty);
      expect(await outbox.pendingOps(ownerId: 'user-1'), isEmpty);
    });

    test('別ownerの親現場にぶら下げる子(Ticket)のupsertは拒否される（推測ID対策）', () async {
      // user-2 が genba-b を持つ。
      final repoB = GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-2',
        remoteResolver: () => null,
      );
      await repoB.upsertGenba(
        makeGenba(
          id: 'genba-b',
          ownerId: 'user-2',
          eventDate: DateTime(2026, 8, 1),
        ),
      );

      // user-1 が user-2 の genba-b にチケットを追加しようとする。
      final result = await genbaRepo.upsertTicket(
        makeTicket(id: 'tk-x', genbaId: 'genba-b', ownerId: 'user-1'),
      );
      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isA<ValidationFailure>());
      // user-1 のチケットは作られない。
      final tickets = await (db.select(db.tickets)
            ..where((t) => t.ownerId.equals('user-1')))
          .get();
      expect(tickets, isEmpty);
    });

    test('親グループが無い推し(Member)のupsertは拒否される', () async {
      final oshiRepo = OshiRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-1',
      );
      final result = await oshiRepo.upsertMember(
        OshiMember(
          id: 'mem-orphan',
          groupId: 'group-missing',
          ownerId: 'user-1',
          name: '推しメン',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await db.select(db.oshiMembers).get(), isEmpty);
    });

    test('自分の親現場が存在する子は正常に作成できる（回帰）', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-ok',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final result = await genbaRepo.upsertTodo(
        makeTodo(id: 'todo-ok', genbaId: 'genba-ok', ownerId: 'user-1'),
      );
      expect(result.isOk, isTrue);
      expect(await db.select(db.todos).get(), hasLength(1));
    });
  });
}
