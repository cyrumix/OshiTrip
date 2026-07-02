import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_expedition/core/error/failure.dart';
import 'package:oshi_expedition/core/error/result.dart';
import 'package:oshi_expedition/core/logging/app_logger.dart';
import 'package:oshi_expedition/core/network/connectivity.dart';
import 'package:oshi_expedition/core/sync/outbox_operation.dart';
import 'package:oshi_expedition/core/sync/outbox_store.dart';
import 'package:oshi_expedition/core/sync/remote_mutation_client.dart';
import 'package:oshi_expedition/core/sync/sync_engine.dart';
import 'package:oshi_expedition/core/time/clock.dart';

import '../helpers/test_db.dart';

/// スクリプト可能な擬似リモート。
class FakeRemote implements RemoteMutationClient {
  final List<OutboxOperation> applied = [];

  /// mutationId → 返す失敗（null = 成功）。1回消費される。
  final Map<String, Failure> failures = {};

  /// 適用済み mutationId（サーバー側 outbox_operations 相当）。
  final Set<String> appliedIds = {};

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    final failure = failures.remove(op.mutationId);
    if (failure != null) return Err(failure);
    if (appliedIds.contains(op.mutationId)) {
      // 冪等: 適用済みは成功扱い・再適用しない
      return const Ok(null);
    }
    appliedIds.add(op.mutationId);
    applied.add(op);
    return const Ok(null);
  }
}

void main() {
  late FakeRemote remote;
  late OutboxStore store;
  late SyncEngine engine;
  final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));

  OutboxOperation op(String id, {String table = 'genbas'}) => OutboxOperation(
        mutationId: id,
        ownerId: 'user-1',
        entityTable: table,
        entityId: 'entity-$id',
        opType: OutboxOpType.upsert,
        payload: {'id': 'entity-$id', 'updated_at': '2026-07-02T00:00:00Z'},
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  setUp(() {
    final db = createTestDb();
    addTearDown(db.close);
    remote = FakeRemote();
    store = OutboxStore(db, clock);
    engine = SyncEngine(
      store: store,
      remoteResolver: () => remote,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
  });

  test('pending の操作を順に適用し、成功分は片付ける', () async {
    await store.enqueue(op('m1'));
    await store.enqueue(op('m2'));
    await engine.drain();

    expect(remote.applied.map((o) => o.mutationId), ['m1', 'm2']);
    expect(await store.pendingOps(), isEmpty);
  });

  test('ネットワーク失敗は pending のまま残り、再送で同じ mutationId を使う（冪等再送）', () async {
    await store.enqueue(op('m1'));
    remote.failures['m1'] = const NetworkFailure();

    await engine.drain();
    var pending = await store.pendingOps();
    expect(pending, hasLength(1));
    expect(pending.first.status, OutboxStatus.pending);
    expect(pending.first.attempts, 1);

    // 接続回復後の再送: 同一 mutationId で成功する
    await engine.drain();
    expect(remote.applied.single.mutationId, 'm1');
    pending = await store.pendingOps();
    expect(pending, isEmpty);
  });

  test('ネットワーク失敗で後続の送信を中断する（順序保持）', () async {
    await store.enqueue(op('m1'));
    await store.enqueue(op('m2'));
    remote.failures['m1'] = const NetworkFailure();

    await engine.drain();
    expect(remote.applied, isEmpty);

    await engine.drain();
    expect(remote.applied.map((o) => o.mutationId), ['m1', 'm2']);
  });

  test('その他の失敗は failed として内容を失わず保持し、自動再送しない', () async {
    await store.enqueue(op('m1'));
    remote.failures['m1'] = const PermissionFailure();

    await engine.drain();
    await engine.drain();
    expect(remote.applied, isEmpty);

    final counts = await store.watchStatusCounts().first;
    expect(counts[OutboxStatus.failed], 1);
  });

  test('retryFailed で failed を再送できる', () async {
    await store.enqueue(op('m1'));
    remote.failures['m1'] = const UnknownFailure();
    await engine.drain();

    await engine.retryFailed();
    expect(remote.applied.single.mutationId, 'm1');
  });

  test('競合（リモートが新しい）は conflict として記録され自動再送しない', () async {
    await store.enqueue(op('m1'));
    remote.failures['m1'] = const ConflictFailure();

    await engine.drain();
    final counts = await store.watchStatusCounts().first;
    expect(counts[OutboxStatus.conflict], 1);

    await engine.drain();
    expect(remote.applied, isEmpty);
  });

  test('リモート未接続（デモ/未ログイン）の間は何も送らない', () async {
    RemoteMutationClient? resolver() => null;
    final offlineEngine = SyncEngine(
      store: store,
      remoteResolver: resolver,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(offlineEngine.dispose);

    await store.enqueue(op('m1'));
    await offlineEngine.drain();
    expect(await store.pendingOps(), hasLength(1));
  });
}
