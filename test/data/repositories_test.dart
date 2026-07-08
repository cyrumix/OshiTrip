import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/db/local_data_purge.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_pull.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_mappers.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/data/memory_repository_impl.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// ファイル削除が必ず失敗する ImageStore（Issue1: 削除失敗が再試行対象になる検証）。
class _ThrowingImageStore extends ImageStore {
  _ThrowingImageStore(super.baseDir);

  @override
  Future<void> deleteRefStrict(String ownerId, String ref) async {
    throw const FileSystemException('forced delete failure');
  }
}

/// ref に 'FAIL' を含むときだけ削除に失敗する ImageStore（Issue2: 1件失敗でも
/// 他の行が処理されることの検証）。それ以外は成功（冪等・実ファイル不要）。
class _SelectiveFailImageStore extends ImageStore {
  _SelectiveFailImageStore(super.baseDir);

  @override
  Future<void> deleteRefStrict(String ownerId, String ref) async {
    if (ref.contains('FAIL')) {
      throw const FileSystemException('forced delete failure');
    }
  }
}

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

  test('Todo削除でentity_table=todos、op_type=deleteのOutboxが1件作られる', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    await genbaRepo.upsertTodo(makeTodo(id: 'todo-del-1'));

    final result = await genbaRepo.deleteTodo('todo-del-1');
    expect(result.isOk, isTrue);

    final aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.todos, isEmpty);

    final ops = await outbox.pendingOps(ownerId: 'user-1');
    final deleteOps = ops.where(
      (o) =>
          o.entityTable == SyncEntity.todos && o.opType == OutboxOpType.delete,
    );
    expect(deleteOps, hasLength(1));
    expect(deleteOps.single.entityId, 'todo-del-1');
  });

  test(
      'ローカルのどのownerにも存在しないIDのTodo削除は成功し、'
      '同期用にOutboxへdeleteを積む（冪等削除の維持）', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    // 'todo-ghost' はローカルのどのownerにも存在しない（例: 別端末で既に
    // 削除済み、あるいはリモートの変更をまだpullしていない等）。この場合は
    // 「別ownerのデータがローカルに存在する」ケースには当たらないため、
    // 従来どおり成功として扱い、同期のためのdelete Outboxを積む。
    final result = await genbaRepo.deleteTodo('todo-ghost');
    expect(result.isOk, isTrue);

    final ops = await outbox.pendingOps(ownerId: 'user-1');
    final deleteOps = ops.where(
      (o) =>
          o.entityTable == SyncEntity.todos &&
          o.opType == OutboxOpType.delete &&
          o.entityId == 'todo-ghost',
    );
    expect(deleteOps, hasLength(1));
  });

  test('未ログインでのTodo削除はAuthFailureで、Outboxも作られない（削除失敗）', () async {
    final unauth = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => null,
      remoteResolver: () => null,
    );
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    await genbaRepo.upsertTodo(makeTodo(id: 'todo-del-2'));

    final result = await unauth.deleteTodo('todo-del-2');
    expect(result.isOk, isFalse);
    expect(result.failureOrNull?.message, contains('ログイン'));

    // Outboxにdelete opは積まれず、元データも残る。
    final ops = await outbox.pendingOps(ownerId: 'user-1');
    expect(
      ops.where(
        (o) =>
            o.entityTable == SyncEntity.todos &&
            o.opType == OutboxOpType.delete,
      ),
      isEmpty,
    );
    final aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.todos, hasLength(1));
  });

  test('持ち物として保存・再読み込みしても種別が維持され、Outbox payloadにも含まれる', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    await genbaRepo.upsertTodo(makeTodo(type: TodoItemType.belonging));

    final aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.todos.single.type, TodoItemType.belonging);
    expect(aggregate.incompleteTodoCount, 0);
    expect(aggregate.incompleteBelongingCount, 1);

    final ops = await outbox.pendingOps(ownerId: 'user-1');
    final todoOp = ops.singleWhere((o) => o.entityTable == SyncEntity.todos);
    expect(todoOp.payload['type'], 'belonging');
  });

  test('リモートからpullした行の種別がローカルへ反映される（種別欠落時はtodoへ後方互換）', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));

    final rows = <Map<String, dynamic>>[
      {
        'id': 'todo-remote-1',
        'genba_id': 'genba-1',
        'owner_id': 'user-1',
        'name': 'リモートの持ち物',
        'type': 'belonging',
        'is_done': false,
        'priority': 'normal',
        'sort_order': 0,
        'created_at': fixedCreatedAt.toIso8601String(),
        'updated_at': fixedCreatedAt.toIso8601String(),
      },
      {
        // 種別キー自体が無い古い形式のサーバー行（移行前）でも todo として扱う。
        'id': 'todo-remote-2',
        'genba_id': 'genba-1',
        'owner_id': 'user-1',
        'name': 'リモートの旧形式Todo',
        'is_done': false,
        'priority': 'normal',
        'sort_order': 1,
        'created_at': fixedCreatedAt.toIso8601String(),
        'updated_at': fixedCreatedAt.toIso8601String(),
      },
    ];
    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.todos,
      rows: rows,
      toCompanion: (json) => todoToCompanion(GenbaTodo.fromJson(json)),
      table: db.todos,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );

    final aggregate = (await genbaRepo.watchAll().first).first;
    final remote1 = aggregate.todos.firstWhere((t) => t.id == 'todo-remote-1');
    final remote2 = aggregate.todos.firstWhere((t) => t.id == 'todo-remote-2');
    expect(remote1.type, TodoItemType.belonging);
    expect(remote2.type, TodoItemType.todo);
  });

  test('メモはID単位でupsert。同一IDは更新、同一種類でも別IDは複数保持できる', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 8, 1)));
    GenbaMemo memo(String id, String body, {int sortOrder = 0}) => GenbaMemo(
          id: id,
          genbaId: 'genba-1',
          ownerId: 'user-1',
          category: MemoCategory.meetup,
          title: '集合場所',
          body: body,
          sortOrder: sortOrder,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );
    // 同一IDの再upsertは更新（1件）。
    await genbaRepo.upsertMemo(memo('m1', '東口噴水前'));
    await genbaRepo.upsertMemo(memo('m1', '西口に変更'));
    // 同一種類でも別IDは別メモとして残る（複数化, §7.7）。
    await genbaRepo.upsertMemo(memo('m2', '二次会は駅前', sortOrder: 1));

    final aggregate = (await genbaRepo.watchAll().first).first;
    expect(aggregate.memos, hasLength(2));
    expect(aggregate.firstMemoOf(MemoCategory.meetup)?.body, '西口に変更');
    expect(
      aggregate.sortedMemos.map((m) => m.body),
      ['西口に変更', '二次会は駅前'],
    );
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

  test('関連項目に紐づく写真: 実在しない subject は拒否、実在すれば保存（§8.4）', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));

    // 実在しないグッズへ紐づけると検証失敗（孤立 subject_id を作らない）。
    final rejected = await memoryRepo.addPhoto(
      MemoryPhoto(
        id: 'p-x',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        albumCategory: MemoryAlbumCategory.goods,
        subjectType: MemorySubjectType.goods,
        subjectId: 'missing-goods',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    expect(rejected.isOk, isFalse);
    // 拒否時はローカル行も Outbox も作らない。
    expect((await memoryRepo.watchByGenbaId('genba-1').first).photos, isEmpty);

    // グッズを追加してから紐づけると保存できる。
    await memoryRepo.upsertGoodsItem(
      GoodsItem(
        id: 'goods-1',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        name: 'アクスタ',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    final ok = await memoryRepo.addPhoto(
      MemoryPhoto(
        id: 'p-goods',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        albumCategory: MemoryAlbumCategory.goods,
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    expect(ok.isOk, isTrue);
    final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
    expect(bundle.photosForSubject('goods-1').single.id, 'p-goods');
  });

  test('関連項目を削除しても写真はアルバムへ残る（既定, §8.4）', () async {
    await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));
    await memoryRepo.upsertGoodsItem(
      GoodsItem(
        id: 'goods-1',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        name: 'ラバーバンド',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await memoryRepo.addPhoto(
      MemoryPhoto(
        id: 'p-goods',
        genbaId: 'genba-1',
        ownerId: 'user-1',
        albumCategory: MemoryAlbumCategory.goods,
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );

    // グッズ項目を削除しても、写真はカスケードで消えずアルバムに残る。
    final del = await memoryRepo.deleteGoodsItem('goods-1');
    expect(del.isOk, isTrue);
    final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
    expect(bundle.goods, isEmpty);
    expect(bundle.photos.map((p) => p.id), contains('p-goods'));
    // アルバムのグッズ分類には残ったまま表示できる。
    expect(
      bundle.photosInAlbum(MemoryAlbumCategory.goods).single.id,
      'p-goods',
    );
  });

  // --------------------------------------------------------------------
  // Issue1: 関連項目と写真の原子的削除（中途半端に消えない）
  // --------------------------------------------------------------------
  group('関連項目と写真の原子的削除（Issue1）', () {
    Future<void> seedGoodsWithPhotos(int n) async {
      await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));
      await memoryRepo.upsertGoodsItem(
        GoodsItem(
          id: 'goods-1',
          genbaId: 'genba-1',
          ownerId: 'user-1',
          name: 'アクスタ',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      for (var i = 0; i < n; i++) {
        final r = await memoryRepo.addPhoto(
          MemoryPhoto(
            id: 'ph-$i',
            genbaId: 'genba-1',
            ownerId: 'user-1',
            localPath: 'memory-photos/user-1/memoryPhoto/ph-$i.jpg',
            albumCategory: MemoryAlbumCategory.goods,
            subjectType: MemorySubjectType.goods,
            subjectId: 'goods-1',
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          ),
        );
        expect(r.isOk, isTrue);
      }
    }

    Future<int> queueCount() async =>
        (await db.select(db.pendingImageDeletions).get()).length;

    test('1. 写真3枚＋グッズの一括削除に成功する', () async {
      await seedGoodsWithPhotos(3);
      final res = await memoryRepo.deleteSubjectWithPhotos(
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
      );
      expect(res.isOk, isTrue);
      final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
      expect(bundle.photos, isEmpty);
      expect(bundle.goods, isEmpty);
      // 写真3件＋グッズ1件の削除が Outbox に載る。
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops
            .where(
              (o) =>
                  o.entityTable == SyncEntity.memoryPhotos &&
                  o.opType == OutboxOpType.delete,
            )
            .length,
        3,
      );
      expect(
        ops.where(
          (o) =>
              o.entityTable == SyncEntity.goodsItems &&
              o.opType == OutboxOpType.delete,
        ),
        hasLength(1),
      );
      // ファイルは削除キューへ積まれる（この repo は ImageStore 未接続=flush no-op）。
      expect(await queueCount(), 3);
    });

    test('2. 2枚目の削除失敗で DB 変更が全て戻る', () async {
      await seedGoodsWithPhotos(3);
      final opsBefore = (await outbox.pendingOps(ownerId: 'user-1')).length;
      memoryRepo.deleteFailStage = 'photo:2';
      final res = await memoryRepo.deleteSubjectWithPhotos(
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
      );
      memoryRepo.deleteFailStage = null;
      expect(res.isOk, isFalse);
      final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
      // 一部だけ消えない: 写真3枚もグッズも残る。
      expect(bundle.photos, hasLength(3));
      expect(bundle.goods, hasLength(1));
      // 削除キュー・Outbox の delete も作られていない（ロールバック）。
      expect(await queueCount(), 0);
      expect((await outbox.pendingOps(ownerId: 'user-1')).length, opsBefore);
    });

    test('3. 項目削除の失敗で写真が残る（全ロールバック）', () async {
      await seedGoodsWithPhotos(2);
      memoryRepo.deleteFailStage = 'subject';
      final res = await memoryRepo.deleteSubjectWithPhotos(
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
      );
      memoryRepo.deleteFailStage = null;
      expect(res.isOk, isFalse);
      final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
      expect(bundle.photos, hasLength(2));
      expect(bundle.goods, hasLength(1));
      expect(await queueCount(), 0);
    });

    test('4. Outbox 登録の失敗で全て戻る', () async {
      await seedGoodsWithPhotos(2);
      memoryRepo.deleteFailStage = 'outbox';
      final res = await memoryRepo.deleteSubjectWithPhotos(
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
      );
      memoryRepo.deleteFailStage = null;
      expect(res.isOk, isFalse);
      final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
      expect(bundle.photos, hasLength(2));
      expect(bundle.goods, hasLength(1));
      expect(await queueCount(), 0);
    });

    test('5. ファイル削除失敗は再試行対象として記録される', () async {
      await seedGoodsWithPhotos(2);
      // ファイル削除が必ず失敗する ImageStore を接続した repo で削除する。
      final dir = Directory.systemTemp.createTempSync('oshi_img_fail');
      addTearDown(() => dir.deleteSync(recursive: true));
      final failingRepo = MemoryRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-1',
        imageStoreResolver: () => _ThrowingImageStore(dir),
      );
      final res = await failingRepo.deleteSubjectWithPhotos(
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
      );
      // DB 側は確定（成功）。ファイル削除の失敗は成功扱いにしない＝キューに残す。
      expect(res.isOk, isTrue);
      final rows = await db.select(db.pendingImageDeletions).get();
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.attempts >= 1), isTrue);
      expect(rows.every((r) => (r.lastError ?? '').isNotEmpty), isTrue);
    });

    test('6. 「アルバムに残す」で写真行もファイルも残り、関連だけ解除される', () async {
      await seedGoodsWithPhotos(3);
      final res = await memoryRepo.deleteSubjectDetachingPhotos(
        subjectType: MemorySubjectType.goods,
        subjectId: 'goods-1',
      );
      expect(res.isOk, isTrue);
      final bundle = await memoryRepo.watchByGenbaId('genba-1').first;
      expect(bundle.goods, isEmpty);
      // 写真は残り、関連（subject）だけ解除、album_category は goods を維持。
      expect(bundle.photos, hasLength(3));
      for (final p in bundle.photos) {
        expect(p.subjectId, isNull);
        expect(p.subjectType, isNull);
        expect(p.albumCategory, MemoryAlbumCategory.goods);
      }
      // ファイル削除キューには積まれない（残すため）。
      expect(await queueCount(), 0);
      // アルバムのグッズ分類から引き続き確認できる。
      expect(bundle.photosInAlbum(MemoryAlbumCategory.goods), hasLength(3));
    });
  });

  // --------------------------------------------------------------------
  // Issue2: 画像削除キューの自動再試行（flush）
  // --------------------------------------------------------------------
  group('画像削除キューの再試行（Issue2）', () {
    MemoryRepositoryImpl repoWith(ImageStore store) => MemoryRepositoryImpl(
          db: db,
          outbox: outbox,
          syncEngine: engine,
          clock: clock,
          ownerIdResolver: () => 'user-1',
          imageStoreResolver: () => store,
        );

    Future<void> seedQueue(
      String id,
      String owner,
      String ref, {
      int attempts = 0,
    }) =>
        db.into(db.pendingImageDeletions).insert(
              PendingImageDeletionsCompanion.insert(
                id: id,
                ownerId: owner,
                ref: ref,
                attempts: Value(attempts),
                createdAt: fixedCreatedAt.toIso8601String(),
                updatedAt: fixedCreatedAt.toIso8601String(),
              ),
            );

    Future<List<PendingImageDeletionRow>> queueRows() =>
        db.select(db.pendingImageDeletions).get();

    ImageStore workingStore() =>
        ImageStore(Directory.systemTemp.createTempSync('oshi_img_ok'));

    test('3. 成功した行だけキューから消える', () async {
      await seedQueue('q1', 'user-1', 'images/user-1/memory_photo/a.jpg');
      await seedQueue('q2', 'user-1', 'images/user-1/memory_photo/b.jpg');
      await repoWith(workingStore()).flushPendingImageDeletions('user-1');
      expect(await queueRows(), isEmpty);
    });

    test('2. 失敗した行は残り、attempts と lastError が増える', () async {
      await seedQueue('q1', 'user-1', 'images/user-1/memory_photo/a.jpg');
      final dir = Directory.systemTemp.createTempSync('oshi_img_fail');
      addTearDown(() => dir.deleteSync(recursive: true));
      await repoWith(_ThrowingImageStore(dir))
          .flushPendingImageDeletions('user-1');
      final rows = await queueRows();
      expect(rows, hasLength(1));
      expect(rows.single.attempts, 1);
      expect((rows.single.lastError ?? '').isNotEmpty, isTrue);
    });

    test('4. 複数行のうち1件失敗しても他は処理される', () async {
      await seedQueue('q1', 'user-1', 'images/user-1/memory_photo/ok1.jpg');
      await seedQueue('q2', 'user-1', 'images/user-1/memory_photo/FAIL.jpg');
      await seedQueue('q3', 'user-1', 'images/user-1/memory_photo/ok2.jpg');
      final dir = Directory.systemTemp.createTempSync('oshi_img_sel');
      addTearDown(() => dir.deleteSync(recursive: true));
      await repoWith(_SelectiveFailImageStore(dir))
          .flushPendingImageDeletions('user-1');
      final rows = await queueRows();
      // 失敗した1件だけ残る。
      expect(rows.map((r) => r.id), ['q2']);
      expect(rows.single.attempts, 1);
    });

    test('5. 別 owner のキューには触れない', () async {
      await seedQueue('q1', 'user-1', 'images/user-1/memory_photo/a.jpg');
      await seedQueue('q2', 'user-2', 'images/user-2/memory_photo/b.jpg');
      await repoWith(workingStore()).flushPendingImageDeletions('user-1');
      final rows = await queueRows();
      // user-2 の行は残る。
      expect(rows.map((r) => r.id), ['q2']);
    });

    test('7. 多重実行しても例外や二重削除が起きない', () async {
      await seedQueue('q1', 'user-1', 'images/user-1/memory_photo/a.jpg');
      await seedQueue('q2', 'user-1', 'images/user-1/memory_photo/b.jpg');
      final repo = repoWith(workingStore());
      // 並行実行（ガードで一方はスキップ）＋逐次再実行（冪等）でも安全。
      await Future.wait([
        repo.flushPendingImageDeletions('user-1'),
        repo.flushPendingImageDeletions('user-1'),
      ]);
      await repo.flushPendingImageDeletions('user-1');
      expect(await queueRows(), isEmpty);
    });

    test('6. ローカルデータ削除で対象 owner のキューだけ消える', () async {
      await seedQueue('q1', 'user-1', 'images/user-1/memory_photo/a.jpg');
      await seedQueue('q2', 'user-2', 'images/user-2/memory_photo/b.jpg');
      await purgeLocalDataForOwner(
        db,
        'user-1',
        imageStore: workingStore(),
      );
      final rows = await queueRows();
      expect(rows.map((r) => r.id), ['q2']);
    });
  });

  // --------------------------------------------------------------------
  // Issue3: 分類と関連先の整合（Repository 側の強制）
  // --------------------------------------------------------------------
  group('分類と関連の整合（Issue3・Repository）', () {
    Future<void> seedGenbaAndPlaces() async {
      await genbaRepo.upsertGenba(makeGenba(eventDate: DateTime(2026, 6, 1)));
      await memoryRepo.upsertVisitedPlace(
        VisitedPlace(
          id: 'spot-1',
          genbaId: 'genba-1',
          ownerId: 'user-1',
          name: '聖地',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      await memoryRepo.upsertVisitedPlace(
        VisitedPlace(
          id: 'food-1',
          genbaId: 'genba-1',
          ownerId: 'user-1',
          name: 'ラーメン',
          category: 'food',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
    }

    MemoryPhoto photo({
      required MemoryAlbumCategory album,
      MemorySubjectType? type,
      String? subjectId,
      String id = 'p-1',
      String genbaId = 'genba-1',
    }) =>
        MemoryPhoto(
          id: id,
          genbaId: genbaId,
          ownerId: 'user-1',
          albumCategory: album,
          subjectType: type,
          subjectId: subjectId,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );

    test('食べたもの→spot、行った場所→food は種別不一致で拒否', () async {
      await seedGenbaAndPlaces();
      final foodToSpot = await memoryRepo.addPhoto(
        photo(
          album: MemoryAlbumCategory.food,
          type: MemorySubjectType.visitedPlace,
          subjectId: 'spot-1',
        ),
      );
      expect(foodToSpot.isOk, isFalse);
      final placeToFood = await memoryRepo.addPhoto(
        photo(
          album: MemoryAlbumCategory.visitedPlace,
          type: MemorySubjectType.visitedPlace,
          subjectId: 'food-1',
        ),
      );
      expect(placeToFood.isOk, isFalse);
      // 正しい対応は保存できる。
      final ok = await memoryRepo.addPhoto(
        photo(
          album: MemoryAlbumCategory.food,
          type: MemorySubjectType.visitedPlace,
          subjectId: 'food-1',
          id: 'p-ok',
        ),
      );
      expect(ok.isOk, isTrue);
    });

    test('形状違反（event に subject）は Repository で拒否', () async {
      await seedGenbaAndPlaces();
      final res = await memoryRepo.addPhoto(
        photo(
          album: MemoryAlbumCategory.event,
          type: MemorySubjectType.goods,
          subjectId: 'spot-1',
        ),
      );
      expect(res.isOk, isFalse);
    });

    test('別genba の項目参照は拒否', () async {
      await seedGenbaAndPlaces();
      await genbaRepo.upsertGenba(
        makeGenba(id: 'genba-2', eventDate: DateTime(2026, 6, 2)),
      );
      final res = await memoryRepo.addPhoto(
        photo(
          album: MemoryAlbumCategory.visitedPlace,
          type: MemorySubjectType.visitedPlace,
          subjectId: 'spot-1', // genba-1 の項目を genba-2 の写真から参照
          genbaId: 'genba-2',
          id: 'p-x',
        ),
      );
      expect(res.isOk, isFalse);
    });
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

    test('別ownerの同一IDに対する削除はAuthFailureで拒否され、原本もOutboxも変更しない（負例）', () async {
      await genbaRepo.upsertGenba(
        makeGenba(
          id: 'genba-x',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      // user-2 の視点から同じID を削除しようとしても、実削除自体は owner付き
      // WHERE 句にヒットせず user-1 の行は残る。しかし事前チェック無しでは
      // 「削除対象0件でも成功」となり、実行していないuser-2側に不要な
      // delete Outboxが積まれてしまうため、ローカルに別ownerの同一IDが
      // 存在する削除自体を型付きFailureで拒否する。
      final result = await genbaRepoB.deleteGenba('genba-x');
      expect(result.isOk, isFalse);
      expect(result.failureOrNull?.message, contains('別ユーザー'));

      final stillThere = await genbaRepo.watchById('genba-x').first;
      expect(stillThere, isNotNull);

      final bOps = await outbox.pendingOps(ownerId: 'user-2');
      expect(
        bOps.where(
          (o) =>
              o.entityTable == SyncEntity.genbas &&
              o.opType == OutboxOpType.delete,
        ),
        isEmpty,
      );
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
    });

    test('別ownerの同一IDに対するTodo削除はAuthFailureで拒否され、原本もOutboxも変更しない（負例）',
        () async {
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
      // user-2 の視点から同じID 'todo-x' を削除しようとしても、ローカルに
      // 別owner（user-1）の同一IDが存在するため型付きFailureで拒否される
      // （削除対象0件でも成功扱いにすると、不要な delete Outboxが積まれる）。
      final result = await genbaRepoB.deleteTodo('todo-x');
      expect(result.isOk, isFalse);
      expect(result.failureOrNull?.message, contains('別ユーザー'));

      final stillThere = await genbaRepo.watchById('genba-x').first;
      expect(stillThere!.todos, hasLength(1));
      expect(stillThere.todos.single.name, '原本');

      final bOps = await outbox.pendingOps(ownerId: 'user-2');
      expect(
        bOps.where(
          (o) =>
              o.entityTable == SyncEntity.todos &&
              o.opType == OutboxOpType.delete,
        ),
        isEmpty,
      );
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
