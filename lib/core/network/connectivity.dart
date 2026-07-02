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
