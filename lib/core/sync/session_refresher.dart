import 'dart:async';

import '../error/result.dart';

/// refresh 関数の型。[isStale] は認証切替検出フック（true で以降のローカル
/// 適用を中断する）。SessionRefresher が世代/pause に基づいて渡す。
typedef ScopedRefresh = Future<Result<void>> Function(bool Function() isStale);

/// 既定の no-op refresh（未指定の追加集約を安全側で無効化する）。
Future<Result<void>> _noRefresh(bool Function() isStale) async =>
    const Ok(null);

/// 認証セッション確定（復元・ログイン）時に、リモートからのキャッシュ更新
/// （background pull）を安全な順序・重複なし・認証切替と排他して起動する（H-02）。
///
/// - 順序: genba（親集約）を先に、その後 memory / oshi を並行取得。
/// - 世代管理: pull 開始時に owner と世代を固定し、各 refresh へ「stale 判定」を
///   渡す。scope が変わった（owner 交代・pause・logout）pull は、以降のローカル
///   挿入・上書き・差分削除・version更新を一切行わない。
/// - 重複防止: 同一 owner は 1 度だけ pull（完了後は再 pull しない。logout の
///   [reset] で再度許可）。実行中の再入も抑止。
/// - pending/世代: 実行中に別 owner が認証されたら、現在の pull を無効化して
///   その owner を pending に積み、完了後に必ず実行する（取りこぼさない）。
/// - 認証切替排他: [pauseForAuthTransition] で新規 pull を止め、実行中 pull の
///   完了/中断を待つ。[resumeAfterAuthTransition] で pending を再開する。
class SessionRefresher {
  SessionRefresher({
    required ScopedRefresh refreshGenba,
    required ScopedRefresh refreshMemory,
    required ScopedRefresh refreshOshi,
    required ScopedRefresh refreshTemplate,
    required ScopedRefresh refreshItinerary,
    ScopedRefresh refreshMemoTemplate = _noRefresh,
  })  : _refreshGenba = refreshGenba,
        _refreshMemory = refreshMemory,
        _refreshOshi = refreshOshi,
        _refreshTemplate = refreshTemplate,
        _refreshItinerary = refreshItinerary,
        _refreshMemoTemplate = refreshMemoTemplate;

  final ScopedRefresh _refreshGenba;
  final ScopedRefresh _refreshMemory;
  final ScopedRefresh _refreshOshi;
  final ScopedRefresh _refreshTemplate;
  final ScopedRefresh _refreshItinerary;
  final ScopedRefresh _refreshMemoTemplate;

  int _generation = 0;
  String? _activeOwner;
  String? _pendingOwner;
  String? _lastPulledOwner;
  bool _paused = false;
  bool _running = false;
  Completer<void>? _inFlight;

  /// 直近 pull の型付き結果（通信失敗をキャッシュ表示に反映せず保持）。
  final List<Result<void>> lastResults = [];

  /// [ownerId] のセッションが確定したときに呼ぶ。
  void onAuthenticated(String ownerId) {
    if (_paused) {
      // 認証切替処理中。resume 後に実行する owner を記録しておく。
      _pendingOwner = ownerId;
      return;
    }
    if (_running) {
      if (ownerId == _activeOwner) return; // 実行中と同じ owner は無視
      // 別 owner が認証された: 実行中 pull を無効化し、完了後に実行する。
      _pendingOwner = ownerId;
      _generation++; // 実行中 pull の isStale() を true にして中断させる
      return;
    }
    if (ownerId == _lastPulledOwner) return; // このセッションで pull 済み
    _start(ownerId);
  }

  /// ログアウト・ユーザー切替で呼ぶ。次回ログインで再 pull 可能にする。
  void reset() {
    _lastPulledOwner = null;
    _pendingOwner = null;
    _generation++; // 実行中 pull があれば無効化する
  }

  /// 認証切替（signOut / ユーザー切替 / アカウント削除）の直前に呼ぶ。
  /// 新規 pull を止め、実行中 pull（in-flight な remote 取得）の完了/中断を待つ。
  Future<void> pauseForAuthTransition() async {
    _paused = true;
    _generation++; // 実行中 pull を中断させる
    final inFlight = _inFlight?.future;
    if (inFlight != null) await inFlight;
  }

  /// 認証切替の完了後に呼ぶ。pending があれば再開する。
  void resumeAfterAuthTransition() {
    _paused = false;
    final pending = _pendingOwner;
    if (pending != null && !_running) {
      _pendingOwner = null;
      _start(pending);
    }
  }

  void _start(String ownerId) {
    _activeOwner = ownerId;
    _running = true;
    final myGeneration = _generation;
    final completer = Completer<void>();
    _inFlight = completer;
    unawaited(
      _run(ownerId, myGeneration).whenComplete(() {
        _running = false;
        _activeOwner = null;
        _inFlight = null;
        completer.complete();
        // pending があり、pause 中でなければ続けて実行する（取りこぼさない）。
        final pending = _pendingOwner;
        if (pending != null && !_paused) {
          _pendingOwner = null;
          _start(pending);
        }
      }),
    );
  }

  Future<void> _run(String ownerId, int myGeneration) async {
    bool isStale() => _paused || _generation != myGeneration;
    lastResults.clear();
    if (isStale()) return;
    // genba（親集約）を先に取り込む。計画（itinerary）は genba に属するため
    // genba の後、その他の子集約と並行して取り込む。
    lastResults.add(await _refreshGenba(isStale));
    if (isStale()) return;
    final rest = await Future.wait([
      _refreshMemory(isStale),
      _refreshOshi(isStale),
      _refreshTemplate(isStale),
      _refreshItinerary(isStale),
      _refreshMemoTemplate(isStale),
    ]);
    lastResults.addAll(rest);
    // 完了時点でも current なら「この owner は pull 済み」と記録する。
    if (!isStale()) _lastPulledOwner = ownerId;
  }
}
