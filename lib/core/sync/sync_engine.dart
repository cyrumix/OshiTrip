import 'dart:async';
import 'dart:math';

import '../error/failure.dart';
import '../logging/app_logger.dart';
import '../network/connectivity.dart';
import '../time/clock.dart';
import 'outbox_operation.dart';
import 'outbox_store.dart';
import 'remote_mutation_client.dart';
import 'retry_policy.dart';

/// 同期の一貫した認証スナップショット（C-01）。
///
/// owner と、その owner に対応する [RemoteMutationClient] を「1回の読み取りで
/// 同時に確定した組」として扱う。owner と remote を別々に読むと、await を
/// またいだ認証切替で「A の owner に B の remote」という不整合が起き得るため、
/// 必ずこの組で受け渡す。未認証・デモ・未接続では null を返す。
class SyncAuthSnapshot {
  const SyncAuthSnapshot({required this.ownerId, required this.remote});

  final String ownerId;
  final RemoteMutationClient remote;
}

/// Outbox を順番にリモートへ流す同期エンジン（ADR-0005 / §15.3）。
///
/// - UI は通信完了を待たない。書き込み側は enqueue 後に [poke] するだけ。
/// - 冪等再送: mutationId ベース。ネットワーク失敗は pending のまま残し、
///   接続回復・再poke で再送する。内容は失わない。
/// - 競合（リモートの方が新しい）は conflict として記録し自動再送しない。
/// - スナップショットが null（デモモード・未ログイン）の間は何もしない。
///
/// 認証切替の安全性（C-01）:
/// - drain は 1 回の [SyncAuthSnapshot] を先頭で確定し、以降その owner の op
///   だけを、その snapshot の remote だけへ送る。
/// - await をまたいで認証が切り替わったら、次の op を送る前に中断する。
/// - [pauseForAuthTransition] で「新規 drain の停止」と「実行中 drain の完了
///   待ち」を行い、認証主体の切替と drain を排他制御する。
class SyncEngine {
  SyncEngine({
    required OutboxStore store,
    required SyncAuthSnapshot? Function() snapshotResolver,
    required ConnectivityObserver connectivity,
    required AppLogger logger,
    Clock clock = const SystemClock(),
    RetryPolicy retryPolicy = const RetryPolicy(),
    double Function()? randomJitter,
  })  : _store = store,
        _snapshotResolver = snapshotResolver,
        _connectivity = connectivity,
        _logger = logger,
        _clock = clock,
        _retry = retryPolicy,
        _randomJitter = randomJitter ?? Random().nextDouble {
    _connectivitySub = _connectivity.onlineChanges.listen((online) {
      if (online) poke();
    });
  }

  final OutboxStore _store;

  /// owner と remote を同時に確定するスナップショット解決関数。
  final SyncAuthSnapshot? Function() _snapshotResolver;
  final ConnectivityObserver _connectivity;
  final AppLogger _logger;
  final Clock _clock;
  final RetryPolicy _retry;
  final double Function() _randomJitter;

  StreamSubscription<bool>? _connectivitySub;
  bool _running = false;
  bool _pokedWhileRunning = false;

  /// 認証切替中は新規 drain を止める（排他制御）。
  bool _paused = false;

  /// 実行中の drain の完了を待つための Future。[pauseForAuthTransition] が
  /// これを await して「実行中の remote mutation が安全に完了するまで
  /// 認証主体を切り替えない」を実現する。
  Completer<void>? _inFlight;

  /// 同期を非同期に開始する（多重起動は抑止）。
  void poke() {
    unawaited(drain());
  }

  /// 認証切替（signOut / ユーザー切替 / アカウント削除）の直前に呼ぶ。
  ///
  /// - 以降の新規 drain を停止する。
  /// - 実行中の drain（in-flight な remote mutation を含む）の完了を待つ。
  ///   完了後に呼び出し側が認証主体を切り替えることで、A の Outbox が
  ///   B のセッションへ渡ることを防ぐ。
  Future<void> pauseForAuthTransition() async {
    _paused = true;
    final inFlight = _inFlight?.future;
    if (inFlight != null) await inFlight;
  }

  /// 認証切替の完了後に呼ぶ。新規 drain を再開する。
  void resumeAfterAuthTransition() {
    _paused = false;
  }

  /// pending の Outbox 操作を順に適用する。
  Future<void> drain() async {
    if (_paused) return;
    if (_running) {
      _pokedWhileRunning = true;
      return;
    }
    _running = true;
    final completer = Completer<void>();
    _inFlight = completer;
    try {
      do {
        _pokedWhileRunning = false;
        await _drainOnce();
      } while (_pokedWhileRunning && !_paused);
    } finally {
      _running = false;
      _inFlight = null;
      completer.complete();
    }
  }

  /// [snapshot] が今なお現在の認証スナップショットか（owner が変わって
  /// いないか）を確認する。await をまたいだ切替の検出に使う。
  bool _isSnapshotCurrent(SyncAuthSnapshot snapshot) {
    final current = _snapshotResolver();
    return current != null && current.ownerId == snapshot.ownerId;
  }

  Future<void> _drainOnce() async {
    if (_paused) return;
    final snapshot = _snapshotResolver();
    if (snapshot == null) return;
    if (!await _connectivity.isOnline) return;
    // 接続確認の await をまたいで切り替わっていないか再確認する。
    if (_paused || !_isSnapshotCurrent(snapshot)) return;

    final owner = snapshot.ownerId;
    await _store.deleteSynced(ownerId: owner);
    // 送信対象は「今すぐ送ってよい（バックオフ待機が明けた）」op のみ。
    final ops = await _store.dueOps(ownerId: owner, now: _clock.now());
    for (final op in ops) {
      // 防御: この op は必ず snapshot owner に属する（dueOps で
      // 絞り込み済みだが、念のため再検証して別 owner の op を送らない）。
      if (op.ownerId != owner) continue;
      // 送信直前に、await をまたいだ認証切替を検出したら中断する。
      if (_paused || !_isSnapshotCurrent(snapshot)) break;

      await _store.updateStatus(
        op.mutationId,
        OutboxStatus.syncing,
        ownerId: owner,
      );
      // 必ず snapshot の remote（owner に対応する client）へ送る。
      final result = await snapshot.remote.apply(op);
      final stop = await result.when(
        ok: (_) async {
          await _store.updateStatus(
            op.mutationId,
            OutboxStatus.synced,
            ownerId: owner,
            clearNextRetryAt: true,
          );
          return false;
        },
        err: (failure) async {
          switch (failure) {
            case NetworkFailure():
              // オフライン扱い: pending に戻して指数バックオフを設定し中断。
              // next_retry_at を保存するので再起動後もバックオフが復元される。
              final attempts = op.attempts + 1;
              await _store.updateStatus(
                op.mutationId,
                OutboxStatus.pending,
                ownerId: owner,
                error: failure.message,
                incrementAttempts: true,
                nextRetryAt: _retry.nextRetryAt(
                  _clock.now(),
                  attempts,
                  random01: _randomJitter(),
                ),
              );
              return true;
            case ConflictFailure():
              await _store.updateStatus(
                op.mutationId,
                OutboxStatus.conflict,
                ownerId: owner,
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
                ownerId: owner,
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
      // apply の await 中に認証が切り替わっていたら、以降の op は送らない。
      if (_paused || !_isSnapshotCurrent(snapshot)) break;
    }
    await _store.deleteSynced(ownerId: owner);
  }

  /// 失敗した操作（現在ownerのみ）を再送対象へ戻して再同期する。
  Future<void> retryFailed() async {
    final snapshot = _snapshotResolver();
    if (snapshot == null) return;
    await _store.retryFailed(ownerId: snapshot.ownerId);
    await drain();
  }

  void dispose() {
    unawaited(_connectivitySub?.cancel());
  }
}
