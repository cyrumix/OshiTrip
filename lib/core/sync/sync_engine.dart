import 'dart:async';

import '../error/failure.dart';
import '../logging/app_logger.dart';
import '../network/connectivity.dart';
import 'outbox_operation.dart';
import 'outbox_store.dart';
import 'remote_mutation_client.dart';

/// Outbox を順番にリモートへ流す同期エンジン（ADR-0005 / §15.3）。
///
/// - UI は通信完了を待たない。書き込み側は enqueue 後に [poke] するだけ。
/// - 冪等再送: mutationId ベース。ネットワーク失敗は pending のまま残し、
///   接続回復・再poke で再送する。内容は失わない。
/// - 競合（リモートの方が新しい）は conflict として記録し自動再送しない。
/// - [remote] が null（デモモード・未ログイン）の間は何もしない。
class SyncEngine {
  SyncEngine({
    required OutboxStore store,
    required RemoteMutationClient? Function() remoteResolver,
    required ConnectivityObserver connectivity,
    required AppLogger logger,
  })  : _store = store,
        _remoteResolver = remoteResolver,
        _connectivity = connectivity,
        _logger = logger {
    _connectivitySub = _connectivity.onlineChanges.listen((online) {
      if (online) poke();
    });
  }

  final OutboxStore _store;
  final RemoteMutationClient? Function() _remoteResolver;
  final ConnectivityObserver _connectivity;
  final AppLogger _logger;

  StreamSubscription<bool>? _connectivitySub;
  bool _running = false;
  bool _pokedWhileRunning = false;

  /// 同期を非同期に開始する（多重起動は抑止）。
  void poke() {
    unawaited(drain());
  }

  /// pending の Outbox 操作を順に適用する。
  Future<void> drain() async {
    if (_running) {
      _pokedWhileRunning = true;
      return;
    }
    _running = true;
    try {
      do {
        _pokedWhileRunning = false;
        await _drainOnce();
      } while (_pokedWhileRunning);
    } finally {
      _running = false;
    }
  }

  Future<void> _drainOnce() async {
    final remote = _remoteResolver();
    if (remote == null) return;
    if (!await _connectivity.isOnline) return;

    await _store.deleteSynced();
    final ops = await _store.pendingOps();
    for (final op in ops) {
      await _store.updateStatus(op.mutationId, OutboxStatus.syncing);
      final result = await remote.apply(op);
      final stop = await result.when(
        ok: (_) async {
          await _store.updateStatus(op.mutationId, OutboxStatus.synced);
          return false;
        },
        err: (failure) async {
          switch (failure) {
            case NetworkFailure():
              // オフライン扱い: pending に戻して中断（後で再送）。
              await _store.updateStatus(
                op.mutationId,
                OutboxStatus.pending,
                error: failure.message,
                incrementAttempts: true,
              );
              return true;
            case ConflictFailure():
              await _store.updateStatus(
                op.mutationId,
                OutboxStatus.conflict,
                error: failure.message,
                incrementAttempts: true,
              );
              _logger.warn(
                'sync conflict',
                context: {
                  'entity': op.entityTable,
                  'mutation_id': op.mutationId,
                },
              );
              return false;
            default:
              await _store.updateStatus(
                op.mutationId,
                OutboxStatus.failed,
                error: failure.message,
                incrementAttempts: true,
              );
              _logger.warn(
                'sync failed',
                context: {
                  'entity': op.entityTable,
                  'mutation_id': op.mutationId,
                  'failure': failure.runtimeType.toString(),
                },
              );
              return false;
          }
        },
      );
      if (stop) break;
    }
    await _store.deleteSynced();
  }

  /// 失敗した操作を再送対象へ戻して再同期する。
  Future<void> retryFailed() async {
    await _store.retryFailed();
    await drain();
  }

  void dispose() {
    unawaited(_connectivitySub?.cancel());
  }
}
