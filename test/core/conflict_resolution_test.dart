import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/conflict_resolver.dart';
import 'package:oshi_trip/core/sync/mutation_transport.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_pull.dart';
import 'package:oshi_trip/core/sync/retry_policy.dart';
import 'package:oshi_trip/core/sync/supabase_remote_mutation_client.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_mappers.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// サーバー `apply_mutation` を模した擬似トランスポート（版CAS＋冪等台帳）。
/// remote_mutation_client_test.dart と同じ挙動。
class _FakeTransport implements MutationTransport {
  final Map<String, int> versions = {}; // entityId -> version
  final Set<String> ledger = {}; // 適用済み mutationId

  @override
  Future<Result<MutationOutcome>> apply(
    OutboxOperation op, {
    required int? baseVersion,
  }) async {
    if (ledger.contains(op.mutationId)) {
      return Ok(
        MutationOutcome(
          status: MutationStatus.applied,
          version: versions[op.entityId],
        ),
      );
    }
    if (op.opType == OutboxOpType.delete) {
      versions.remove(op.entityId);
      ledger.add(op.mutationId);
      return const Ok(MutationOutcome(status: MutationStatus.applied));
    }
    final current = versions[op.entityId];
    if (current != null && (baseVersion == null || current != baseVersion)) {
      return Ok(
        MutationOutcome(status: MutationStatus.conflict, version: current),
      );
    }
    final newVersion = (current ?? 0) + 1;
    versions[op.entityId] = newVersion;
    ledger.add(op.mutationId);
    return Ok(
      MutationOutcome(status: MutationStatus.applied, version: newVersion),
    );
  }
}

void main() {
  final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));

  OutboxOperation upsertOp(
    String mutationId,
    String entityId, {
    String owner = 'user-1',
    OutboxStatus status = OutboxStatus.conflict,
  }) =>
      OutboxOperation(
        mutationId: mutationId,
        ownerId: owner,
        entityTable: SyncEntity.genbas,
        entityId: entityId,
        opType: OutboxOpType.upsert,
        payload: {'id': entityId, 'title': 'この端末の編集'},
        status: status,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<int?> cachedVersion(AppDatabase db, String entityId) async {
    final row = await (db.select(db.remoteVersions)
          ..where(
            (t) =>
                t.ownerId.equals('user-1') &
                t.entityTable.equals(SyncEntity.genbas) &
                t.entityId.equals(entityId),
          ))
        .getSingleOrNull();
    return row?.version;
  }

  Future<void> seedVersion(
    AppDatabase db,
    String entityId,
    int version, {
    String owner = 'user-1',
  }) {
    return db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: owner,
            entityTable: SyncEntity.genbas,
            entityId: entityId,
            version: version,
          ),
        );
  }

  group('OutboxStore の競合解決メソッド（owner分離）', () {
    late AppDatabase db;
    late OutboxStore store;

    setUp(() {
      db = createTestDb();
      addTearDown(db.close);
      store = OutboxStore(db, clock);
    });

    test('conflictOps は自分の競合のみ返す（別ownerは返さない, C-01）', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      await store.enqueue(upsertOp('m2', 'g2', owner: 'user-2'));
      // pending は含めない
      await store.enqueue(upsertOp('m3', 'g3', status: OutboxStatus.pending));

      final own = await store.conflictOps(ownerId: 'user-1');
      expect(own.map((o) => o.mutationId), ['m1']);
      final other = await store.conflictOps(ownerId: 'user-2');
      expect(other.map((o) => o.mutationId), ['m2']);
    });

    test('discardConflict は自分の競合行のみ削除する', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      // 別ownerからは削除できない
      final wrongOwner = await store.discardConflict('m1', ownerId: 'user-2');
      expect(wrongOwner, isFalse);
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNotNull);

      final ok = await store.discardConflict('m1', ownerId: 'user-1');
      expect(ok, isTrue);
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNull);
    });

    test('discardConflict は競合以外の状態を消さない', () async {
      await store.enqueue(upsertOp('m1', 'g1', status: OutboxStatus.pending));
      final ok = await store.discardConflict('m1', ownerId: 'user-1');
      expect(ok, isFalse);
      final pending = await store.pendingOps(ownerId: 'user-1');
      expect(pending.map((o) => o.mutationId), ['m1']);
    });

    test('reopenConflict は競合を pending へ戻す（別ownerは戻せない）', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      expect(await store.reopenConflict('m1', ownerId: 'user-2'), isFalse);
      expect(await store.reopenConflict('m1', ownerId: 'user-1'), isTrue);
      final pending = await store.pendingOps(ownerId: 'user-1');
      expect(pending.map((o) => o.mutationId), ['m1']);
      expect(pending.single.status, OutboxStatus.pending);
    });

    test('競合状態は永続化され、再起動（別Storeインスタンス）後も解決できる', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      // 「再起動」相当: 同じDBに新しいStoreを作る。
      final store2 = OutboxStore(db, clock);
      final conflicts = await store2.conflictOps(ownerId: 'user-1');
      expect(conflicts.map((o) => o.mutationId), ['m1']);
      expect(await store2.discardConflict('m1', ownerId: 'user-1'), isTrue);
      expect(await store2.conflictOps(ownerId: 'user-1'), isEmpty);
    });
  });

  group('reconcileServerVersionInto（keep-local の版整合）', () {
    late AppDatabase db;
    setUp(() {
      db = createTestDb();
      addTearDown(db.close);
    });

    test('サーバー行があれば版キャッシュをその version へ更新する', () async {
      await seedVersion(db, 'g1', 5); // 古い base
      final found = await reconcileServerVersionInto(
        db: db,
        owner: 'user-1',
        tableName: SyncEntity.genbas,
        entityId: 'g1',
        rows: [
          {'id': 'g1', 'owner_id': 'user-1', 'version': 6},
        ],
      );
      expect(found, isTrue);
      expect(await cachedVersion(db, 'g1'), 6);
    });

    test('サーバーに無ければ版キャッシュを削除して false（新規INSERT経路へ）', () async {
      await seedVersion(db, 'g1', 5);
      final found = await reconcileServerVersionInto(
        db: db,
        owner: 'user-1',
        tableName: SyncEntity.genbas,
        entityId: 'g1',
        rows: const [],
      );
      expect(found, isFalse);
      expect(await cachedVersion(db, 'g1'), isNull);
    });

    test('別ownerのサーバー行は取り込まない（C-01）', () async {
      final found = await reconcileServerVersionInto(
        db: db,
        owner: 'user-1',
        tableName: SyncEntity.genbas,
        entityId: 'g1',
        rows: [
          {'id': 'g1', 'owner_id': 'user-2', 'version': 9},
        ],
      );
      expect(found, isFalse);
      expect(await cachedVersion(db, 'g1'), isNull);
    });
  });

  group('ConflictResolver 統合（useServer / keepLocal）', () {
    late AppDatabase db;
    late OutboxStore store;
    late _FakeTransport transport;
    late SupabaseRemoteMutationClient client;
    late SyncEngine engine;

    setUp(() {
      db = createTestDb();
      addTearDown(db.close);
      store = OutboxStore(db, clock);
      transport = _FakeTransport();
      client = SupabaseRemoteMutationClient(transport, db);
      engine = SyncEngine(
        store: store,
        snapshotResolver: () =>
            SyncAuthSnapshot(ownerId: 'user-1', remote: client),
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
        clock: clock,
        retryPolicy: const RetryPolicy(
          base: Duration.zero,
          maxInterval: Duration.zero,
          jitterRatio: 0,
        ),
        randomJitter: () => 0.5,
      );
      addTearDown(engine.dispose);
    });

    // ローカル genbas 行のタイトルを読む（サーバー内容が反映されたか確認用）。
    Future<String?> localTitle(String id) async {
      final row = await (db.select(db.genbas)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return row?.title;
    }

    /// サーバー採用の seam。[adopt] を差し替えて成功／失敗／実適用を注入する。
    ConflictResolver resolver({
      List<Map<String, dynamic>> serverRows = const [],
      required ServerEntityAdopter adopt,
    }) {
      return ConflictResolver(
        store: store,
        db: db,
        fetchRemoteRows: (table) async => serverRows,
        adoptServerEntity: adopt,
        drain: () => engine.drain(),
      );
    }

    /// 実リポジトリの adoptServerEntity 相当（サーバー行を強制適用してから Ok）。
    ServerEntityAdopter applyingAdopter(
      List<Map<String, dynamic>> serverRows,
      List<String> calls,
    ) {
      return (table, id) async {
        calls.add('$table:$id');
        await applyPulledRowsInto(
          db: db,
          outbox: store,
          owner: 'user-1',
          tableName: table,
          rows: serverRows,
          toCompanion: (json) => genbaToCompanion(Genba.fromJson(json)),
          table: db.genbas,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          forceEntityIds: {id},
        );
        return const Ok(null);
      };
    }

    test('useServer 成功: サーバー内容を適用してから競合opを削除する（失敗安全順序）', () async {
      // ローカルには古い内容の g1 と、競合中の op（この端末の編集）。
      await db.into(db.genbas).insertOnConflictUpdate(
            genbaToCompanion(
              makeGenba(
                id: 'g1',
                ownerId: 'user-1',
                title: '古いローカル',
                eventDate: DateTime(2026, 8, 1),
              ),
            ),
          );
      await store.enqueue(upsertOp('m1', 'g1'));
      final serverRows = [
        makeGenba(
          id: 'g1',
          ownerId: 'user-1',
          title: 'サーバー最新',
          eventDate: DateTime(2026, 8, 1),
        ).toJson(),
      ];
      final calls = <String>[];
      final r = resolver(adopt: applyingAdopter(serverRows, calls));

      final result = await r.useServer('m1', ownerId: 'user-1');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, ConflictResolutionResult.resolved);
      // サーバー内容がローカルへ反映され、その後で競合opが消えた。
      expect(await localTitle('g1'), 'サーバー最新');
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNull);
      expect(calls, ['${SyncEntity.genbas}:g1']);
    });

    test('useServer 失敗(NetworkFailure): 競合opを削除せず未解決のまま Err を返す', () async {
      await db.into(db.genbas).insertOnConflictUpdate(
            genbaToCompanion(
              makeGenba(
                id: 'g1',
                ownerId: 'user-1',
                title: '古いローカル',
                eventDate: DateTime(2026, 8, 1),
              ),
            ),
          );
      await seedVersion(db, 'g1', 5); // stale 版（触られないこと）。
      await store.enqueue(upsertOp('m1', 'g1'));
      var adoptCalled = false;
      final r = resolver(
        adopt: (table, id) async {
          adoptCalled = true;
          return const Err(NetworkFailure());
        },
      );

      final result = await r.useServer('m1', ownerId: 'user-1');

      expect(adoptCalled, isTrue);
      // 成功扱いにしない。
      expect(result, isA<Err<ConflictResolutionResult>>());
      expect(
        (result as Err<ConflictResolutionResult>).failure,
        isA<NetworkFailure>(),
      );
      // 競合opは残り（再試行可能）、ローカルも版キャッシュも不変。
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNotNull);
      expect(await localTitle('g1'), '古いローカル');
      expect(await cachedVersion(db, 'g1'), 5);
    });

    test('useServer タイムアウト相当の失敗は resolved にならない', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      final r = resolver(
        adopt: (table, id) async =>
            Err(NetworkFailure(cause: TimeoutException('遅延'))),
      );
      final result = await r.useServer('m1', ownerId: 'user-1');
      expect(result, isA<Err<ConflictResolutionResult>>());
      expect(result.valueOrNull, isNot(ConflictResolutionResult.resolved));
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNotNull);
    });

    test('useServer: 別ownerの競合は解決できない（adoptを呼ばない）', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      var adoptCalled = false;
      final r = resolver(
        adopt: (table, id) async {
          adoptCalled = true;
          return const Ok(null);
        },
      );
      final result = await r.useServer('m1', ownerId: 'user-2');
      expect(result.valueOrNull, ConflictResolutionResult.notFound);
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNotNull);
      expect(adoptCalled, isFalse);
    });

    test('useServer 失敗: 別ownerの競合には影響しない（C-01）', () async {
      await store.enqueue(upsertOp('m1', 'g1'));
      await store.enqueue(upsertOp('m9', 'g9', owner: 'user-2'));
      final r =
          resolver(adopt: (table, id) async => const Err(NetworkFailure()));

      final result = await r.useServer('m1', ownerId: 'user-1');
      expect(result, isA<Err<ConflictResolutionResult>>());
      // 別ownerの競合は無傷。
      expect(await store.conflictById('m9', ownerId: 'user-2'), isNotNull);
    });

    // keepLocal 系は adopt を使わない（no-op adopter を渡す）。
    Future<Result<void>> noopAdopt(String table, String id) async =>
        const Ok<void>(null);

    test('keepLocal: サーバー版へ整合して再送し、サーバーがこの端末の内容で更新される', () async {
      // サーバーは g1 を version=6 に進めている（他端末更新）。
      transport.versions['g1'] = 6;
      // ローカルには古い base=5 のキャッシュと、競合中の op（この端末の編集）。
      await seedVersion(db, 'g1', 5);
      await store.enqueue(upsertOp('m1', 'g1'));

      final r = resolver(
        serverRows: [
          {'id': 'g1', 'owner_id': 'user-1', 'version': 6},
        ],
        adopt: noopAdopt,
      );
      final result = await r.keepLocal('m1', ownerId: 'user-1');

      expect(result.valueOrNull, ConflictResolutionResult.resolved);
      // サーバーはこの端末の再送で version 7 へ更新された。
      expect(transport.versions['g1'], 7);
      // 競合は解消し、版キャッシュは最新（7）。
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNull);
      expect(await cachedVersion(db, 'g1'), 7);
    });

    test('keepLocal: reconcile後にサーバーが更に進んでいれば再び競合として残る（黙って上書きしない）', () async {
      // fetch時点ではサーバー版6だが、drain時にはサーバーが7へ進んだ状況。
      await seedVersion(db, 'g1', 5);
      await store.enqueue(upsertOp('m1', 'g1'));
      final r = resolver(
        serverRows: [
          {'id': 'g1', 'owner_id': 'user-1', 'version': 6}, // reconcileは6を採用
        ],
        adopt: noopAdopt,
      );
      // drain時のサーバー現在版は7（fetch後にさらに更新された）。
      transport.versions['g1'] = 7;

      final result = await r.keepLocal('m1', ownerId: 'user-1');
      expect(result.valueOrNull, ConflictResolutionResult.stillConflicting);
      // 競合は解消されず残る（上書きされていない）。
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNotNull);
      // サーバーは7のまま（この端末の内容で上書きされていない）。
      expect(transport.versions['g1'], 7);
    });

    test('keepLocal: サーバーに行が無ければ base=null で新規作成として再送成功', () async {
      // サーバーには g1 が存在しない（他端末で削除された）。ローカルは競合中。
      await seedVersion(db, 'g1', 5);
      await store.enqueue(upsertOp('m1', 'g1'));
      final r = resolver(serverRows: const [], adopt: noopAdopt);
      final result = await r.keepLocal('m1', ownerId: 'user-1');
      expect(result.valueOrNull, ConflictResolutionResult.resolved);
      // 新規INSERT経路で version=1 から作成される。
      expect(transport.versions['g1'], 1);
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNull);
    });

    test('keepLocal: サーバー取得失敗は競合を維持し Err を返す（握りつぶさない）', () async {
      await seedVersion(db, 'g1', 5);
      await store.enqueue(upsertOp('m1', 'g1'));
      final r = ConflictResolver(
        store: store,
        db: db,
        fetchRemoteRows: (table) async =>
            throw const NetworkFailure(message: '取得失敗'),
        adoptServerEntity: noopAdopt,
        drain: () => engine.drain(),
      );
      final result = await r.keepLocal('m1', ownerId: 'user-1');
      expect(result, isA<Err<ConflictResolutionResult>>());
      // 競合は維持され、版キャッシュも不変。
      expect(await store.conflictById('m1', ownerId: 'user-1'), isNotNull);
      expect(await cachedVersion(db, 'g1'), 5);
    });
  });

  group('SyncEngineの競合記録 → 解決の一連の流れ', () {
    test('競合はconflictとして記録され、useServerで消える（永久放置しない）', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final store = OutboxStore(db, clock);
      final transport = _FakeTransport();
      final client = SupabaseRemoteMutationClient(transport, db);
      final engine = SyncEngine(
        store: store,
        snapshotResolver: () =>
            SyncAuthSnapshot(ownerId: 'user-1', remote: client),
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
        clock: clock,
        retryPolicy: const RetryPolicy(
          base: Duration.zero,
          maxInterval: Duration.zero,
          jitterRatio: 0,
        ),
        randomJitter: () => 0.5,
      );
      addTearDown(engine.dispose);

      // サーバーは既に version=3。ローカルは未pull（キャッシュ無し）→ base=null
      // 送信 → 既存行に対して conflict。
      transport.versions['g1'] = 3;
      await store.enqueue(upsertOp('m1', 'g1', status: OutboxStatus.pending));
      await engine.drain();

      final counts = await store.watchStatusCounts(ownerId: 'user-1').first;
      expect(counts[OutboxStatus.conflict], 1);

      // useServer で解決（adopt はサーバー内容取得・適用のスパイ）。
      final adoptCalls = <String>[];
      final r = ConflictResolver(
        store: store,
        db: db,
        fetchRemoteRows: (t) async => const [],
        adoptServerEntity: (table, id) async {
          adoptCalls.add('$table:$id');
          return const Ok(null);
        },
        drain: () => engine.drain(),
      );
      final result = await r.useServer('m1', ownerId: 'user-1');
      expect(result.valueOrNull, ConflictResolutionResult.resolved);
      final after = await store.watchStatusCounts(ownerId: 'user-1').first;
      expect(after[OutboxStatus.conflict] ?? 0, 0);
      expect(adoptCalls, ['${SyncEntity.genbas}:g1']);
    });
  });
}
