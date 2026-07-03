import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_mutation_client.dart';
import 'package:oshi_trip/core/sync/retry_policy.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';

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
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-1', remote: remote),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      clock: clock,
      // これらのテストは冪等再送・順序・競合が主題なので、バックオフを無効化して
      // （待機0で）即再送できるようにする。バックオフ自体は専用テストで検証する。
      retryPolicy: const RetryPolicy(
        base: Duration.zero,
        maxInterval: Duration.zero,
        jitterRatio: 0,
      ),
      randomJitter: () => 0.5,
    );
    addTearDown(engine.dispose);
  });

  test('pending の操作を順に適用し、成功分は片付ける', () async {
    await store.enqueue(op('m1'));
    await store.enqueue(op('m2'));
    await engine.drain();

    expect(remote.applied.map((o) => o.mutationId), ['m1', 'm2']);
    expect(await store.pendingOps(ownerId: 'user-1'), isEmpty);
  });

  test('ネットワーク失敗は pending のまま残り、再送で同じ mutationId を使う（冪等再送）', () async {
    await store.enqueue(op('m1'));
    remote.failures['m1'] = const NetworkFailure();

    await engine.drain();
    var pending = await store.pendingOps(ownerId: 'user-1');
    expect(pending, hasLength(1));
    expect(pending.first.status, OutboxStatus.pending);
    expect(pending.first.attempts, 1);

    // 接続回復後の再送: 同一 mutationId で成功する
    await engine.drain();
    expect(remote.applied.single.mutationId, 'm1');
    pending = await store.pendingOps(ownerId: 'user-1');
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

    final counts = await store.watchStatusCounts(ownerId: 'user-1').first;
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
    final counts = await store.watchStatusCounts(ownerId: 'user-1').first;
    expect(counts[OutboxStatus.conflict], 1);

    await engine.drain();
    expect(remote.applied, isEmpty);
  });

  test('リモート未接続（デモ/未ログイン）の間は何も送らない', () async {
    final offlineEngine = SyncEngine(
      store: store,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(offlineEngine.dispose);

    await store.enqueue(op('m1'));
    await offlineEngine.drain();
    expect(await store.pendingOps(ownerId: 'user-1'), hasLength(1));
  });

  test('owner未解決（ログアウト中）の間は何も送らない', () async {
    SyncAuthSnapshot? snapshot =
        SyncAuthSnapshot(ownerId: 'user-1', remote: remote);
    final scopedEngine = SyncEngine(
      store: store,
      snapshotResolver: () => snapshot,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(scopedEngine.dispose);

    await store.enqueue(op('m1'));
    snapshot = null; // ログアウト相当
    await scopedEngine.drain();
    expect(remote.applied, isEmpty);
    expect(await store.pendingOps(ownerId: 'user-1'), hasLength(1));
  });

  test('別ownerのpendingは同期対象にならない（C-01: Outboxのowner限定）', () async {
    await store.enqueue(op('m1')); // owner: user-1
    await store.enqueue(
      OutboxOperation(
        mutationId: 'm-other',
        ownerId: 'user-2',
        entityTable: 'genbas',
        entityId: 'entity-other',
        opType: OutboxOpType.upsert,
        payload: const {'id': 'entity-other'},
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );

    await engine.drain(); // engine は user-1 に固定

    expect(remote.applied.map((o) => o.mutationId), ['m1']);
    // user-2 の op は user-1 の drain で送信も削除もされず残っている。
    final ownerTwoPending = await store.pendingOps(ownerId: 'user-2');
    expect(ownerTwoPending.map((o) => o.mutationId), ['m-other']);
  });

  test(
    'Aのremote処理の遅延中にBへ切り替えても、Aのopは一度もBのremoteへ渡らない（C-01）',
    () async {
      // A の remote.apply を「シグナルするまで完了しない」遅延実装にする。
      final gateA = Completer<void>();
      final remoteA = _GatedRemote(gate: gateA.future);
      final remoteB = FakeRemote();

      // 認証スナップショットを差し替え可能にする（A → B）。
      var current = SyncAuthSnapshot(ownerId: 'user-1', remote: remoteA);
      final switchingEngine = SyncEngine(
        store: store,
        snapshotResolver: () => current,
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      );
      addTearDown(switchingEngine.dispose);

      // A の op と、同一DBに残る B の op を用意する。
      await store.enqueue(op('a1')); // owner: user-1
      await store.enqueue(
        OutboxOperation(
          mutationId: 'b1',
          ownerId: 'user-2',
          entityTable: 'genbas',
          entityId: 'entity-b1',
          opType: OutboxOpType.upsert,
          payload: const {'id': 'entity-b1'},
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

      // drain 開始（A の apply で止まる）。
      final draining = switchingEngine.drain();
      await remoteA.started; // apply に入ったことを確認

      // ここで B へ切り替え（A の apply はまだ完了していない）。
      current = SyncAuthSnapshot(ownerId: 'user-2', remote: remoteB);

      // A の apply を完了させ、drain を終わらせる。
      gateA.complete();
      await draining;

      // A の op は A の remote にのみ渡り、B の remote には一度も渡らない。
      expect(remoteA.applied.map((o) => o.mutationId), ['a1']);
      expect(remoteB.applied, isEmpty);

      // B の op は A の drain では送られず pending のまま残る。
      final bPending = await store.pendingOps(ownerId: 'user-2');
      expect(bPending.map((o) => o.mutationId), ['b1']);
    },
  );

  test('pauseForAuthTransitionは実行中drainの完了を待ってから戻る（C-01排他制御）', () async {
    final gate = Completer<void>();
    final gated = _GatedRemote(gate: gate.future);
    var applyFinished = false;

    final pausableEngine = SyncEngine(
      store: store,
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-1', remote: gated),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(pausableEngine.dispose);

    await store.enqueue(op('m1'));
    final draining = pausableEngine.drain();
    await gated.started;

    // pause は in-flight な apply の完了を待つ。
    final paused = pausableEngine.pauseForAuthTransition().then((_) {
      // pause が戻る時点で drain（apply）は完了しているはず。
      expect(applyFinished, isTrue);
    });

    gate.complete();
    applyFinished = true;
    await draining;
    await paused;

    // pause 中は新規 drain が始まらない（m2 は送られない）。
    await store.enqueue(op('m2'));
    await pausableEngine.drain();
    expect(gated.applied.map((o) => o.mutationId), ['m1']);
  });
}

/// apply が [gate] 完了までブロックする擬似リモート。認証切替中の
/// in-flight remote mutation を再現する。
class _GatedRemote implements RemoteMutationClient {
  _GatedRemote({required this.gate});

  final Future<void> gate;
  final List<OutboxOperation> applied = [];
  final Completer<void> _started = Completer<void>();

  /// apply に入ったら完了する Future（テスト側の同期用）。
  Future<void> get started => _started.future;

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    if (!_started.isCompleted) _started.complete();
    await gate;
    applied.add(op);
    return const Ok(null);
  }
}
