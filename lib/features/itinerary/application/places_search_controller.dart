import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/places_gateway.dart';

/// 施設検索（Autocomplete New）の状態区分。UI は [PlacesSearchStatus.empty] /
/// [unavailable] / [error] のとき手動入力への導線を出す（§8.2/§4）。
enum PlacesSearchStatus {
  /// 未入力・中断直後。
  idle,

  /// 入力が最小文字数（既定3）未満。API は呼ばない。
  tooShort,

  /// autocomplete 実行中。
  loading,

  /// 候補あり。
  results,

  /// 候補ゼロ。
  empty,

  /// Google 未設定・無効・上限（[UnavailableFailure]）。
  unavailable,

  /// 通信・timeout 等の失敗。
  error,
}

/// 施設検索の不変な状態スナップショット。
@immutable
class PlacesSearchState {
  const PlacesSearchState({
    this.status = PlacesSearchStatus.idle,
    this.query = '',
    this.suggestions = const [],
    this.failure,
  });

  final PlacesSearchStatus status;
  final String query;
  final List<PlaceSuggestion> suggestions;
  final Failure? failure;

  /// 結果なし／利用不可／失敗のときは手動入力へ移れる（§8.2「結果なし／中断／
  /// timeout から手動入力へ移動」）。
  bool get canFallbackToManual =>
      status == PlacesSearchStatus.empty ||
      status == PlacesSearchStatus.unavailable ||
      status == PlacesSearchStatus.error;

  PlacesSearchState copyWith({
    PlacesSearchStatus? status,
    String? query,
    List<PlaceSuggestion>? suggestions,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      PlacesSearchState(
        status: status ?? this.status,
        query: query ?? this.query,
        suggestions: suggestions ?? this.suggestions,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

/// Autocomplete (New) の検索制御（ADR-0010 §5・itinerary-plan-spec §8.2）。
///
/// - 3文字以上でのみ検索し、[debounce]（既定450ms）で件数を抑える
/// - 古い（stale）レスポンスは破棄し、最新の結果だけ反映する
/// - 1検索セッションに1つの session token（UUIDv4）を使い、候補選択の
///   Place Details まで同じ token を使う。**セッション完了・中断後は token を
///   再利用しない**（次のクエリで新しい token を発行する）
/// - 未設定・障害・上限は型で表し、手動入力へ縮退できる
///
/// ネットワーク実体は [PlacesGateway]、token 生成は [generateToken] を注入する
/// （テスト容易性）。
class PlacesSearchController extends ChangeNotifier {
  PlacesSearchController({
    required PlacesGateway gateway,
    required String Function() generateToken,
    Duration debounce = const Duration(milliseconds: 450),
    int minChars = 3,
    PlacesLocationBias? bias,
  })  : _gateway = gateway,
        _generateToken = generateToken,
        _debounceDuration = debounce,
        _minChars = minChars,
        _bias = bias;

  final PlacesGateway _gateway;
  final String Function() _generateToken;
  final Duration _debounceDuration;
  final int _minChars;
  final PlacesLocationBias? _bias;

  PlacesSearchState _state = const PlacesSearchState();
  PlacesSearchState get state => _state;

  Timer? _debounce;

  /// 現在の検索セッションの token（未確立なら null）。
  PlacesSessionToken? _sessionToken;

  /// 発行済みリクエストの通し番号（stale 判定用）。
  int _seq = 0;

  bool _disposed = false;

  /// 入力変化。最小文字数未満は API を呼ばず [tooShort]。以上は debounce 後に
  /// autocomplete を実行する。連続入力で古い呼び出しは破棄される。
  void onQueryChanged(String input) {
    final q = input.trim();
    _debounce?.cancel();
    if (q.length < _minChars) {
      _seq++; // 進行中があれば stale 化して破棄する
      _emit(
        _state.copyWith(
          status: PlacesSearchStatus.tooShort,
          query: q,
          suggestions: const [],
          clearFailure: true,
        ),
      );
      return;
    }
    _debounce = Timer(_debounceDuration, () => _runAutocomplete(q));
  }

  Future<void> _runAutocomplete(String query) async {
    // セッション未確立なら新しい token を発行して開始する。
    _sessionToken ??= PlacesSessionToken(_generateToken());
    final token = _sessionToken!;
    final seq = ++_seq;
    _emit(
      _state.copyWith(
        status: PlacesSearchStatus.loading,
        query: query,
        clearFailure: true,
      ),
    );
    final result = await _gateway.autocomplete(
      input: query,
      sessionToken: token,
      bias: _bias,
    );
    if (_disposed || seq != _seq) return; // stale（新しい入力/中断）→破棄
    result.when(
      ok: (list) => _emit(
        _state.copyWith(
          status: list.isEmpty
              ? PlacesSearchStatus.empty
              : PlacesSearchStatus.results,
          suggestions: list,
          clearFailure: true,
        ),
      ),
      err: (f) => _emit(
        _state.copyWith(
          status: f is UnavailableFailure
              ? PlacesSearchStatus.unavailable
              : PlacesSearchStatus.error,
          suggestions: const [],
          failure: f,
        ),
      ),
    );
  }

  /// 候補を選択して Place Details を取得する。autocomplete と**同じ** session
  /// token で1セッションを完了し、以後その token は再利用しない。
  /// セッション未確立での選択は [ValidationFailure]。
  Future<Result<PlaceDetails>> select(PlaceSuggestion suggestion) async {
    final token = _sessionToken;
    if (token == null) {
      return const Err(ValidationFailure('検索セッションがありません'));
    }
    _debounce?.cancel();
    final result = await _gateway.placeDetails(
      placeId: suggestion.placeId,
      sessionToken: token,
    );
    // セッション完了 → token 破棄（再利用禁止。次クエリで新 token）。
    _sessionToken = null;
    _seq++;
    return result;
  }

  /// 候補未選択で検索を離れる（中断）。セッションを終了し token を破棄する。
  /// 破棄した token は再利用しない（次のクエリで新しい token を発行）。
  void abandon() {
    _debounce?.cancel();
    _sessionToken = null;
    _seq++; // 進行中応答を stale 化
    _emit(const PlacesSearchState());
  }

  /// 現在の session token（テスト・デバッグ用。値そのものは UI/ログに出さない）。
  @visibleForTesting
  String? get debugSessionToken => _sessionToken?.value;

  void _emit(PlacesSearchState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
