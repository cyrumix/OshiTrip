import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
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
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';

import '../helpers/test_db.dart';

class _FakeRemote implements RemoteMutationClient {
  final List<String> applied = [];
  final Map<String, Failure> failures = {};

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    final f = failures.remove(op.mutationId);
    if (f != null) return Err(f);
    applied.add(op.mutationId);
    return const Ok(null);
  }
}

OutboxOperation _op(String id, DateTime at) => OutboxOperation(
      mutationId: id,
      ownerId: 'user-1',
      entityTable: SyncEntity.genbas,
      entityId: 'e-$id',
      opType: OutboxOpType.upsert,
      payload: {'id': 'e-$id'},
      createdAt: at,
      updatedAt: at,
    );

void main() {
  test('ネットワーク失敗で next_retry_at を設定し、待機明けまで再送しない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));
    final store = OutboxStore(db, clock);
    final remote = _FakeRemote()..failures['m1'] = const NetworkFailure();
    final engine = SyncEngine(
      store: store,
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-1', remote: remote),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      clock: clock,
      retryPolicy: const RetryPolicy(base: Duration(seconds: 30)),
      randomJitter: () => 0.5,
    );
    addTearDown(engine.dispose);

    await store.enqueue(_op('m1', clock.now()));
    await engine.drain();

    // 送信されず、バックオフ待機が設定されている。
    expect(remote.applied, isEmpty);
    final pending = await store.pendingOps(ownerId: 'user-1');
    expect(pending.single.attempts, 1);
    expect(pending.single.nextRetryAt, isNotNull);
    // 待機中なので due ではない。
    expect(await store.dueOps(ownerId: 'user-1', now: clock.now()), isEmpty);

    // 待機明け前に drain しても送らない。
    await engine.drain();
    expect(remote.applied, isEmpty);

    // 時刻を待機明けまで進めると再送され成功する。
    clock.current = clock.now().add(const Duration(seconds: 31));
    await engine.drain();
    expect(remote.applied, ['m1']);
    expect(await store.pendingOps(ownerId: 'user-1'), isEmpty);
  });

  test('再起動（DB再open）後も next_retry_at / attempts / status を復元する', () async {
    if (Platform.isWindows) {
      open.overrideFor(OperatingSystem.windows, () {
        try {
          return DynamicLibrary.open('sqlite3.dll');
        } catch (_) {
          return DynamicLibrary.open('winsqlite3.dll');
        }
      });
    }
    final dir = Directory.systemTemp.createTempSync('oshi_backoff');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'app.sqlite');
    final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));
    final future = clock.now().add(const Duration(minutes: 5));

    // --- 起動1: enqueue し、失敗として next_retry_at を保存して閉じる ---
    final db1 = AppDatabase(NativeDatabase(File(path)));
    final store1 = OutboxStore(db1, clock);
    await store1.enqueue(_op('m1', clock.now()));
    await store1.updateStatus(
      'm1',
      OutboxStatus.pending,
      ownerId: 'user-1',
      incrementAttempts: true,
      nextRetryAt: future,
    );
    await db1.close();

    // --- 起動2: 同じファイルを開き直し、待機状態が復元されている ---
    final db2 = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db2.close);
    final store2 = OutboxStore(db2, clock);

    final restored = await store2.pendingOps(ownerId: 'user-1');
    expect(restored.single.attempts, 1);
    expect(restored.single.nextRetryAt, future);

    // 待機中は due でない。待機明けなら due。
    expect(await store2.dueOps(ownerId: 'user-1', now: clock.now()), isEmpty);
    final due = await store2.dueOps(
      ownerId: 'user-1',
      now: future.add(const Duration(seconds: 1)),
    );
    expect(due.single.mutationId, 'm1');
  });

  test('retryFailed はバックオフ待機を解除して即送信可にする', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));
    final store = OutboxStore(db, clock);
    await store.enqueue(_op('m1', clock.now()));
    await store.updateStatus(
      'm1',
      OutboxStatus.failed,
      ownerId: 'user-1',
      nextRetryAt: clock.now().add(const Duration(hours: 1)),
    );

    await store.retryFailed(ownerId: 'user-1');

    final due = await store.dueOps(ownerId: 'user-1', now: clock.now());
    expect(due.single.mutationId, 'm1');
    expect(due.single.nextRetryAt, isNull);
  });
}
