import 'dart:async';

/// 接続監視の抽象。
///
/// 実装は差し替え可能（テストでは fake を注入）。既定実装はプラグインに
/// 依存せず「常時オンライン仮定 + 失敗時バックオフ」で動作する。
/// OSレベルの接続イベント連動は後続範囲（docs/follow-up-work.md）。
abstract interface class ConnectivityObserver {
  Future<bool> get isOnline;

  /// オンライン復帰などの変化通知（同期エンジンの再駆動に使う）。
  Stream<bool> get onlineChanges;
}

class AlwaysOnlineConnectivity implements ConnectivityObserver {
  const AlwaysOnlineConnectivity();

  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<bool> get onlineChanges => const Stream.empty();
}

/// 実接続監視（H-02）。プラグインに依存せず、注入された [probe] で
/// 到達性を能動的に確認する。
///
/// 方針:
/// - 「OSがオンライン」＝「サーバー到達可能」とはみなさない。[probe] は実際に
///   サーバーへ到達できるかを返す（実装は Supabase への軽量リクエスト等）。
/// - [isOnline] は直近の判定を返す（送信のたびに二重の往復をしないため）。
///   実際の到達性は送信自体で確定し、通信失敗は [NetworkFailure]→pending として
///   呼び出し側（SyncEngine）が扱う。
/// - [refresh] で即時再判定し、オフライン→オンラインの遷移時に [onlineChanges]
///   へ通知する（同期の再駆動トリガー）。[start] で周期的に [refresh] する。
///
/// テストでは [probe] に fake を注入し、[refresh] を直接呼んで遷移を検証できる
/// （実タイマー・sleep に依存しない）。
class ReachabilityConnectivity implements ConnectivityObserver {
  ReachabilityConnectivity({
    required Future<bool> Function() probe,
    Duration pollInterval = const Duration(seconds: 30),
    bool initialOnline = true,
  })  : _probe = probe,
        _pollInterval = pollInterval,
        _online = initialOnline;

  final Future<bool> Function() _probe;
  final Duration _pollInterval;
  bool _online;
  Timer? _timer;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  /// 周期的な到達性チェックを開始する（本番用）。多重起動しない。
  void start() {
    _timer ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  /// 即時に到達性を再判定する。オフライン→オンラインの遷移で通知する。
  Future<void> refresh() async {
    bool result;
    try {
      result = await _probe();
    } catch (_) {
      result = false;
    }
    if (result != _online) {
      _online = result;
      if (!_controller.isClosed) _controller.add(result);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(_controller.close());
  }
}

/// テスト・デモ用の手動切替接続。
class ManualConnectivity implements ConnectivityObserver {
  ManualConnectivity({bool online = true}) : _online = online;

  bool _online;
  final List<void Function(bool)> _listeners = [];

  set online(bool value) {
    _online = value;
    for (final l in List.of(_listeners)) {
      l(value);
    }
  }

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onlineChanges {
    late final void Function(bool) listener;
    return Stream<bool>.multi((controller) {
      listener = controller.add;
      _listeners.add(listener);
      controller.onCancel = () => _listeners.remove(listener);
    });
  }
}
