import 'dart:async';

/// 同期 drain の駆動タイミングを一元管理する（H-02）。
///
/// SyncEngine が「どう送るか」を担うのに対し、Coordinator は「いつ送るか」を
/// 担う。次のイベントで現在 owner の Outbox drain を起動する:
/// - アプリ起動直後（[start] の初回 drain）
/// - 認証セッションの復元・ログイン完了（[onAuthenticated]）
/// - アプリの resume（[onAppResumed]）
/// - バックオフ待機明けの定期再送（[retryInterval] の周期タイマー）
///
/// オンライン復帰時の drain は SyncEngine が接続監視を購読して行うため、ここ
/// では扱わない。ローカル enqueue 直後の drain は各 Repository が enqueue 後に
/// engine.poke() するため同様にここでは扱わない（責務の二重化を避ける）。
///
/// [drain] は `() => syncEngine.drain()` を渡す想定。テストでは呼び出し回数を
/// 数える関数を注入し、実タイマー・sleep なしで各トリガーを検証できる
/// （[retryInterval] を null にすれば周期タイマーは作らない）。
class SyncCoordinator {
  SyncCoordinator({
    required Future<void> Function() drain,
    Duration? retryInterval = const Duration(seconds: 60),
  })  : _drain = drain,
        _retryInterval = retryInterval;

  final Future<void> Function() _drain;
  final Duration? _retryInterval;

  Timer? _retryTimer;
  bool _started = false;

  /// 監視を開始する。多重開始しない。開始時に一度 drain を試みる（起動時同期）。
  void start() {
    if (_started) return;
    _started = true;
    _trigger();
    final interval = _retryInterval;
    if (interval != null) {
      _retryTimer = Timer.periodic(interval, (_) => _trigger());
    }
  }

  /// 認証が確定（セッション復元・ログイン）したときに呼ぶ。
  void onAuthenticated() => _trigger();

  /// アプリが前面復帰したときに呼ぶ（バックグラウンド中に貯まった変更を流す）。
  void onAppResumed() => _trigger();

  void _trigger() {
    // drain は完了を待たない（UI をブロックしない）。多重 drain は SyncEngine
    // 側の running ガードで抑止される。
    unawaited(_drain());
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
