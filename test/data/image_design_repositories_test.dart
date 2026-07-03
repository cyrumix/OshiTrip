import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/images/image_upload_status.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_pull.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/data/memory_mappers.dart';
import 'package:oshi_trip/features/memory/data/memory_repository_impl.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// R6（H-05）: 画像基調UIのデータ契約が実データへ接続され、再起動・同期後も
/// 保持されること、cover 一意性・owner分離・端末内画像参照の同期除外を検証する。
void main() {
  late final clock = FixedClock(DateTime(2026, 7, 2, 12));

  ({
    GenbaRepositoryImpl genba,
    MemoryRepositoryImpl memory,
    OshiRepositoryImpl oshi,
    OutboxStore outbox,
  }) build(
    AppDatabase db, {
    String owner = 'user-1',
    OutboxStore? outboxStore,
  }) {
    final outbox = outboxStore ?? OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    return (
      genba: GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      ),
      memory: MemoryRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
      ),
      oshi: OshiRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
      ),
      outbox: outbox,
    );
  }

  group('参加状態', () {
    test('attendance_status は保存・再読込で保持され、Outbox payload に載る', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);

      await r.genba.upsertGenba(
        makeGenba(id: 'g1', eventDate: DateTime(2026, 8, 1))
            .copyWith(attendanceStatus: AttendanceStatus.attended),
      );

      final reloaded = (await r.genba.watchById('g1').first)!.genba;
      expect(reloaded.attendanceStatus, AttendanceStatus.attended);

      final op = (await r.outbox.pendingOps(ownerId: 'user-1'))
          .firstWhere((o) => o.entityTable == SyncEntity.genbas);
      expect(op.payload['attendance_status'], 'attended');
    });

    test('中止 ⟹ 参加状態 canceled の整合が保存時に保たれる（normalizeAttendance）', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);

      await r.genba.upsertGenba(
        makeGenba(id: 'g1', eventDate: DateTime(2026, 8, 1)).copyWith(
          isCanceled: true,
          attendanceStatus: AttendanceStatus.planned, // 不整合を渡す
        ),
      );
      final reloaded = (await r.genba.watchById('g1').first)!.genba;
      expect(reloaded.attendanceStatus, AttendanceStatus.canceled);
    });
  });

  group('hero 画像', () {
    test('storage/alt は同期されるが、端末内 local 参照は Outbox payload に載らない', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);

      await r.genba.upsertGenba(
        makeGenba(id: 'g1', eventDate: DateTime(2026, 8, 1)).copyWith(
          heroImageLocalPath: 'images/user-1/hero/x.jpg',
          heroImageStoragePath: 'hero/x.jpg',
          heroImageAltText: '公演写真',
          heroImageUploadStatus: ImageUploadStatus.uploaded,
        ),
      );

      final reloaded = (await r.genba.watchById('g1').first)!.genba;
      // 端末内参照も含め、ローカルには全フィールドが保持される（再起動後表示）。
      expect(reloaded.heroImageLocalPath, 'images/user-1/hero/x.jpg');
      expect(reloaded.heroImageStoragePath, 'hero/x.jpg');
      expect(reloaded.heroImageAltText, '公演写真');
      expect(reloaded.heroImageUploadStatus, ImageUploadStatus.uploaded);

      final op = (await r.outbox.pendingOps(ownerId: 'user-1'))
          .firstWhere((o) => o.entityTable == SyncEntity.genbas);
      // local 参照は端末専用なので送らない。storage/alt は送る。
      expect(op.payload.containsKey('hero_image_local_path'), isFalse);
      expect(op.payload['hero_image_storage_path'], 'hero/x.jpg');
      expect(op.payload['hero_image_alt_text'], '公演写真');
      expect(op.payload['hero_image_upload_status'], 'uploaded');
    });
  });

  group('思い出お気に入り', () {
    test('setEntryFavorite は entry が無ければ作成し、保持・同期する', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await r.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));

      final res =
          await r.memory.setEntryFavorite(genbaId: 'g1', isFavorite: true);
      expect(res.isOk, isTrue);

      final bundle = await r.memory.watchByGenbaId('g1').first;
      expect(bundle.entry?.isFavorite, isTrue);

      final ops = await r.outbox.pendingOps(ownerId: 'user-1');
      final op =
          ops.firstWhere((o) => o.entityTable == SyncEntity.memoryEntries);
      expect(op.payload['is_favorite'], true);
    });
  });

  group('表紙 cover の一意性', () {
    test('setCoverPhoto は同一現場の cover を1件に保つ（切替で旧 cover を外す）', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await r.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));

      MemoryPhoto photo(String id, int order) => MemoryPhoto(
            id: id,
            genbaId: 'g1',
            ownerId: 'user-1',
            localPath: 'images/user-1/memory/$id.jpg',
            sortOrder: order,
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          );
      await r.memory.addPhoto(photo('p1', 0));
      await r.memory.addPhoto(photo('p2', 1));

      expect(
        (await r.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p1')).isOk,
        isTrue,
      );
      var bundle = await r.memory.watchByGenbaId('g1').first;
      expect(bundle.photos.where((p) => p.isCover).map((p) => p.id), ['p1']);

      // 別の写真へ切替 → 旧 cover は外れ、常に1件だけ。
      expect(
        (await r.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p2')).isOk,
        isTrue,
      );
      bundle = await r.memory.watchByGenbaId('g1').first;
      expect(bundle.photos.where((p) => p.isCover).map((p) => p.id), ['p2']);
    });

    test('存在しない写真を cover にしようとすると NotFoundFailure', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await r.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));
      final res = await r.memory.setCoverPhoto(genbaId: 'g1', photoId: 'nope');
      expect(res.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('推しグループ画像・お気に入り・記念日', () {
    test('グループの image_local_path は同期除外・alt/favorite は同期', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);

      await r.oshi.upsertGroup(
        OshiGroup(
          id: 'grp1',
          ownerId: 'user-1',
          name: 'グループ',
          imageLocalPath: 'images/user-1/oshi/g.jpg',
          imageAltText: 'ロゴ',
          isFavorite: true,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );

      final groups = await r.oshi.watchAll().first;
      final g = groups.single.group;
      expect(g.imageLocalPath, 'images/user-1/oshi/g.jpg');
      expect(g.imageAltText, 'ロゴ');
      expect(g.isFavorite, isTrue);

      final op = (await r.outbox.pendingOps(ownerId: 'user-1'))
          .firstWhere((o) => o.entityTable == SyncEntity.oshiGroups);
      expect(op.payload.containsKey('image_local_path'), isFalse);
      expect(op.payload['image_alt_text'], 'ロゴ');
      expect(op.payload['is_favorite'], true);
    });

    test('記念日は親グループが自分のものなら作成でき、保持・同期される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await r.oshi.upsertGroup(
        OshiGroup(
          id: 'grp1',
          ownerId: 'user-1',
          name: 'グループ',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );

      final res = await r.oshi.upsertAnniversary(
        OshiAnniversary(
          id: 'a1',
          ownerId: 'user-1',
          groupId: 'grp1',
          label: '結成記念日',
          date: DateTime(2020, 4, 1),
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      expect(res.isOk, isTrue);

      final list = await r.oshi.watchAnniversaries().first;
      expect(list.single.label, '結成記念日');
      expect(list.single.date, DateTime(2020, 4, 1));

      final op = (await r.outbox.pendingOps(ownerId: 'user-1'))
          .firstWhere((o) => o.entityTable == SyncEntity.oshiAnniversaries);
      expect(op.payload['group_id'], 'grp1');
      expect(op.payload['date'], '2020-04-01');
    });

    test('親グループが存在しない/別owner の記念日は拒否される（C-01）', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);

      // 親グループなし → 拒否
      final missing = await r.oshi.upsertAnniversary(
        OshiAnniversary(
          id: 'a1',
          ownerId: 'user-1',
          groupId: 'grp-missing',
          label: '記念日',
          date: DateTime(2020, 4, 1),
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      expect(missing.failureOrNull, isA<ValidationFailure>());

      // 別ownerのグループにぶら下げる → 拒否
      final other = build(db, owner: 'user-2');
      await other.oshi.upsertGroup(
        OshiGroup(
          id: 'grp2',
          ownerId: 'user-2',
          name: '他人のグループ',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      final cross = await r.oshi.upsertAnniversary(
        OshiAnniversary(
          id: 'a2',
          ownerId: 'user-1',
          groupId: 'grp2',
          label: '侵入記念日',
          date: DateTime(2020, 4, 1),
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      expect(cross.failureOrNull, isA<ValidationFailure>());
    });

    test('記念日も owner ごとに分離される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final a = build(db, owner: 'user-1');
      final b = build(db, owner: 'user-2');
      await a.oshi.upsertGroup(
        OshiGroup(
          id: 'grp1',
          ownerId: 'user-1',
          name: 'A',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      await a.oshi.upsertAnniversary(
        OshiAnniversary(
          id: 'a1',
          ownerId: 'user-1',
          groupId: 'grp1',
          label: 'Aの記念日',
          date: DateTime(2020, 4, 1),
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      expect(await b.oshi.watchAnniversaries().first, isEmpty);
      expect((await a.oshi.watchAnniversaries().first).single.label, 'Aの記念日');
    });
  });

  group('表紙切替の原子性（R6独立レビュー#1）', () {
    MemoryPhoto photo(String id, int order, {bool cover = false}) =>
        MemoryPhoto(
          id: id,
          genbaId: 'g1',
          ownerId: 'user-1',
          localPath: 'images/user-1/memory/$id.jpg',
          isCover: cover,
          sortOrder: order,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );

    test('Outbox登録が途中失敗すると全て巻き戻り、古い表紙が維持される', () async {
      final db = createTestDb();
      addTearDown(db.close);

      // まず通常 outbox で seed し、p1 を表紙にする。
      final seed = build(db);
      await seed.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));
      await seed.memory.addPhoto(photo('p1', 0));
      await seed.memory.addPhoto(photo('p2', 1));
      expect(
        (await seed.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p1')).isOk,
        isTrue,
      );

      // p2 へ切替。ただし transaction 内の最初の enqueue（p1のcover解除）で失敗させる。
      final throwing = _ThrowingOutbox(db, clock, failOnCall: 1);
      final r = build(db, outboxStore: throwing);
      final res = await r.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p2');
      expect(res.failureOrNull, isA<StorageFailure>());

      // ロールバックにより p1 が表紙のまま、p2 は非表紙（古い表紙が維持）。
      final bundle = await seed.memory.watchByGenbaId('g1').first;
      expect(bundle.photos.where((p) => p.isCover).map((p) => p.id), ['p1']);
    });

    test('切替成功時は新旧写真の upsert が Outbox に載り、表紙は常に1件', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await r.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));
      await r.memory.addPhoto(photo('p1', 0));
      await r.memory.addPhoto(photo('p2', 1));
      await r.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p1');

      await r.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p2');
      final bundle = await r.memory.watchByGenbaId('g1').first;
      expect(bundle.photos.where((p) => p.isCover).map((p) => p.id), ['p2']);

      // 切替では旧(p1)解除・新(p2)設定の2件が Outbox に載る（同期後も最大1件）。
      final photoOps = (await r.outbox.pendingOps(ownerId: 'user-1'))
          .where((o) => o.entityTable == SyncEntity.memoryPhotos)
          .toList();
      // p1: false→true→false, p2: false→true。最新payloadで is_cover が
      // p1=false / p2=true になっていることを確認する。
      final byId = {for (final o in photoOps) o.entityId: o};
      expect(byId['p1']?.payload['is_cover'], false);
      expect(byId['p2']?.payload['is_cover'], true);
    });

    test('別owner・別genbaの写真は cover 切替の対象にならない', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final a = build(db, owner: 'user-1');
      final b = build(db, owner: 'user-2');
      await a.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));
      await a.memory.addPhoto(photo('p1', 0));
      // user-2 が user-1 の genba g1 に対して cover を設定しようとしても、
      // 自分の owner スコープに g1 の写真が無いため対象なし（NotFound）。
      final res = await b.memory.setCoverPhoto(genbaId: 'g1', photoId: 'p1');
      expect(res.failureOrNull, isA<NotFoundFailure>());
      // user-1 の p1 は変更されない。
      final bundle = await a.memory.watchByGenbaId('g1').first;
      expect(bundle.photos.single.isCover, isFalse);
    });
  });

  group('記念日の親子整合（member_id）と削除カスケード（R6独立レビュー#2）', () {
    Future<void> seedGroupMember(
      ({
        GenbaRepositoryImpl genba,
        MemoryRepositoryImpl memory,
        OshiRepositoryImpl oshi,
        OutboxStore outbox,
      }) r, {
      required String owner,
      String groupId = 'grp1',
      String memberId = 'mem1',
    }) async {
      await r.oshi.upsertGroup(
        OshiGroup(
          id: groupId,
          ownerId: owner,
          name: 'グループ',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      await r.oshi.upsertMember(
        OshiMember(
          id: memberId,
          groupId: groupId,
          ownerId: owner,
          name: 'メンバー',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
    }

    OshiAnniversary anniv({
      String id = 'a1',
      String owner = 'user-1',
      String groupId = 'grp1',
      String? memberId,
    }) =>
        OshiAnniversary(
          id: id,
          ownerId: owner,
          groupId: groupId,
          memberId: memberId,
          label: '記念日',
          date: DateTime(2020, 4, 1),
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );

    test('正常系: memberId が同一owner・同一グループのメンバーなら作成できる', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await seedGroupMember(r, owner: 'user-1');
      final res = await r.oshi.upsertAnniversary(anniv(memberId: 'mem1'));
      expect(res.isOk, isTrue);
      expect((await r.oshi.watchAnniversaries().first).single.memberId, 'mem1');
    });

    test('負例: 存在しない memberId は拒否される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await seedGroupMember(r, owner: 'user-1');
      final res = await r.oshi.upsertAnniversary(anniv(memberId: 'nope'));
      expect(res.failureOrNull, isA<ValidationFailure>());
      expect(await r.oshi.watchAnniversaries().first, isEmpty);
    });

    test('負例: memberId が別グループのメンバーだと拒否される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await seedGroupMember(
        r,
        owner: 'user-1',
        groupId: 'grpA',
        memberId: 'mA',
      );
      await seedGroupMember(
        r,
        owner: 'user-1',
        groupId: 'grpB',
        memberId: 'mB',
      );
      // grpA の記念日に grpB のメンバーを紐づけようとする → 拒否。
      final res = await r.oshi.upsertAnniversary(
        anniv(groupId: 'grpA', memberId: 'mB'),
      );
      expect(res.failureOrNull, isA<ValidationFailure>());
    });

    test('負例: memberId が別ownerのメンバーだと拒否される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final a = build(db, owner: 'user-1');
      final b = build(db, owner: 'user-2');
      // 同一 group_id を両ownerが持ち、それぞれ別メンバー。
      await seedGroupMember(a, owner: 'user-1', groupId: 'g', memberId: 'mine');
      await seedGroupMember(
        b,
        owner: 'user-2',
        groupId: 'g',
        memberId: 'theirs',
      );
      // user-1 が自分のグループ g に、user-2 のメンバー theirs を紐づけ → 拒否。
      final res = await a.oshi.upsertAnniversary(
        anniv(groupId: 'g', memberId: 'theirs'),
      );
      expect(res.failureOrNull, isA<ValidationFailure>());
    });

    test('グループ削除でそのグループの記念日も端末から削除される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await seedGroupMember(r, owner: 'user-1');
      await r.oshi.upsertAnniversary(anniv(memberId: 'mem1'));
      expect(await r.oshi.watchAnniversaries().first, hasLength(1));

      await r.oshi.deleteGroup('grp1');
      expect(await r.oshi.watchAnniversaries().first, isEmpty);
    });

    test('メンバー削除で記念日の memberId は null になる（ON DELETE SET NULL 相当・記念日は残る）',
        () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await seedGroupMember(r, owner: 'user-1');
      await r.oshi.upsertAnniversary(anniv(memberId: 'mem1'));

      await r.oshi.deleteMember('mem1');
      final list = await r.oshi.watchAnniversaries().first;
      expect(list, hasLength(1));
      expect(list.single.memberId, isNull);
    });
  });

  group('思い出写真の端末内参照を pull で保持（R6独立レビュー#3）', () {
    test('pull は localPath を上書きせず、同期項目は更新する。新規は localPath=null', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final r = build(db);
      await r.genba
          .upsertGenba(makeGenba(id: 'g1', eventDate: DateTime(2026, 6, 1)));
      // ローカル写真 p1（端末参照あり・未同期メタ）。
      await r.memory.addPhoto(
        MemoryPhoto(
          id: 'p1',
          genbaId: 'g1',
          ownerId: 'user-1',
          localPath: 'images/user-1/memory/p1.jpg',
          caption: '旧キャプション',
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        ),
      );
      // 未同期 Outbox を消しておく（pull が上書きをスキップしないように）。
      await r.outbox.deleteSynced(ownerId: 'user-1');
      await (db.delete(db.outboxOps)..where((t) => t.ownerId.equals('user-1')))
          .go();

      // リモート行（サーバーには local_path が無い）: p1 のメタ更新 + 新規 p2。
      final rows = <Map<String, dynamic>>[
        {
          'id': 'p1',
          'genba_id': 'g1',
          'owner_id': 'user-1',
          'storage_path': 'remote/p1.jpg',
          'upload_status': 'uploaded',
          'caption': '新キャプション',
          'is_cover': true,
          'sort_order': 0,
          'created_at': fixedCreatedAt.toIso8601String(),
          'updated_at': fixedCreatedAt.toIso8601String(),
          'version': 2,
        },
        {
          'id': 'p2',
          'genba_id': 'g1',
          'owner_id': 'user-1',
          'storage_path': 'remote/p2.jpg',
          'upload_status': 'uploaded',
          'is_cover': false,
          'sort_order': 1,
          'created_at': fixedCreatedAt.toIso8601String(),
          'updated_at': fixedCreatedAt.toIso8601String(),
          'version': 1,
        },
        // 別owner の行は取り込まない。
        {
          'id': 'p-other',
          'genba_id': 'g1',
          'owner_id': 'user-2',
          'storage_path': 'remote/other.jpg',
          'is_cover': false,
          'sort_order': 0,
          'created_at': fixedCreatedAt.toIso8601String(),
          'updated_at': fixedCreatedAt.toIso8601String(),
          'version': 1,
        },
      ];

      await applyPulledRowsInto(
        db: db,
        outbox: r.outbox,
        owner: 'user-1',
        tableName: SyncEntity.memoryPhotos,
        rows: rows,
        toCompanion: (json) => photoToCompanion(
          MemoryPhoto.fromJson(json),
          preserveLocalImage: true,
        ),
        table: db.memoryPhotos,
        idColumn: (t) => t.id,
        ownerColumn: (t) => t.ownerId,
        idOf: (r) => r.id,
      );

      final bundle = await r.memory.watchByGenbaId('g1').first;
      final p1 = bundle.photos.firstWhere((p) => p.id == 'p1');
      // localPath は保持（pullで消えない）。
      expect(p1.localPath, 'images/user-1/memory/p1.jpg');
      // 同期項目は更新される。
      expect(p1.storagePath, 'remote/p1.jpg');
      expect(p1.uploadStatus, PhotoUploadStatus.uploaded);
      expect(p1.caption, '新キャプション');
      expect(p1.isCover, isTrue);
      // 新規リモート写真は localPath=null で作成される。
      final p2 = bundle.photos.firstWhere((p) => p.id == 'p2');
      expect(p2.localPath, isNull);
      expect(p2.storagePath, 'remote/p2.jpg');
      // 別owner の写真は取り込まれない。
      expect(bundle.photos.where((p) => p.id == 'p-other'), isEmpty);
    });
  });
}

/// 指定回数目の [enqueue] で例外を投げる OutboxStore（transaction ロールバック検証用）。
class _ThrowingOutbox extends OutboxStore {
  _ThrowingOutbox(super.db, super.clock, {required this.failOnCall});

  final int failOnCall;
  int _calls = 0;

  @override
  Future<void> enqueue(OutboxOperation op) async {
    _calls++;
    if (_calls == failOnCall) {
      throw StateError('injected enqueue failure');
    }
    return super.enqueue(op);
  }
}
