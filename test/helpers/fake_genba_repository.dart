import 'dart:async';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/domain/genba_repository.dart';

/// [GenbaRepository] を包み、テストから任意のメソッドの失敗・遅延・呼び出し
/// 回数を制御できるデコレータ（保存失敗ロールバック・二重タップの回帰テスト用）。
///
/// 実データは委譲先の実リポジトリ（Drift裏付け）が保持するため、
/// 「失敗時にローカル状態が変わっていないこと」を実際のDB読み取りで検証できる。
class FakeGenbaRepository implements GenbaRepository {
  FakeGenbaRepository(this._inner);

  final GenbaRepository _inner;

  /// true の間、次回の現場書き込み（[upsertGenba] / [mutateGenba]）は実行前に
  /// 失敗を返す（委譲はしない = ローカルへ反映されない）。一度使うと自動的に
  /// false へ戻る（「保存失敗ロールバック」テスト用の一発失敗）。
  bool failNextUpsertGenba = false;

  /// 現場書き込み（[upsertGenba] / [mutateGenba]）を呼ぶたびにこの時間だけ
  /// 待ってから処理する（二重タップ時に1回目がまだ進行中の window を安定して
  /// 作るため）。
  Duration upsertGenbaDelay = Duration.zero;

  /// 現場書き込み（[upsertGenba] / [mutateGenba]）の総呼び出し回数。
  int upsertGenbaCallCount = 0;

  @override
  Future<Result<void>> upsertGenba(Genba genba) async {
    upsertGenbaCallCount++;
    if (upsertGenbaDelay > Duration.zero) {
      await Future<void>.delayed(upsertGenbaDelay);
    }
    if (failNextUpsertGenba) {
      failNextUpsertGenba = false;
      return const Err(StorageFailure(message: 'テスト用の保存失敗'));
    }
    return _inner.upsertGenba(genba);
  }

  @override
  Future<Result<Genba>> mutateGenba(
    String genbaId,
    Genba Function(Genba current) update,
  ) async {
    // 現場フィールド更新も upsertGenba と同じ書き込み系として計測・失敗注入する
    // （actions controller は現場更新をこちらへ移したため、既存の失敗/遅延/
    // 回数フックがそのまま効く必要がある）。
    upsertGenbaCallCount++;
    if (upsertGenbaDelay > Duration.zero) {
      await Future<void>.delayed(upsertGenbaDelay);
    }
    if (failNextUpsertGenba) {
      failNextUpsertGenba = false;
      return const Err(StorageFailure(message: 'テスト用の保存失敗'));
    }
    return _inner.mutateGenba(genbaId, update);
  }

  @override
  Stream<List<GenbaAggregate>> watchAll() => _inner.watchAll();

  @override
  Stream<GenbaAggregate?> watchById(String id) => _inner.watchById(id);

  @override
  Future<Result<void>> deleteGenba(String id) => _inner.deleteGenba(id);

  @override
  Future<Result<void>> upsertTicket(Ticket ticket) =>
      _inner.upsertTicket(ticket);

  @override
  Future<Result<void>> deleteTicket(String id) => _inner.deleteTicket(id);

  @override
  Future<Result<void>> upsertTransport(Transport transport) =>
      _inner.upsertTransport(transport);

  @override
  Future<Result<void>> deleteTransport(String id) => _inner.deleteTransport(id);

  @override
  Future<Result<void>> upsertLodging(Lodging lodging) =>
      _inner.upsertLodging(lodging);

  @override
  Future<Result<void>> deleteLodging(String id) => _inner.deleteLodging(id);

  /// true の間、次回の [upsertTodo] 呼び出しは実行前に失敗を返す（委譲しない）。
  /// 一度使うと自動的に false へ戻る（Todo楽観更新のロールバック回帰テスト用）。
  bool failNextUpsertTodo = false;

  /// 次回の [upsertTodo] を明示的に「停止」できるゲート。設定すると、次の
  /// upsertTodo 呼び出しは委譲せずこの Completer の future を返し、テストが
  /// complete するまで未完了のまま留まる。これにより楽観更新の途中状態を
  /// 安定して観測でき、保存結果（成功/失敗）を実時間 delay に依存せず注入できる。
  Completer<Result<void>>? nextUpsertTodoGate;

  @override
  Future<Result<void>> upsertTodo(GenbaTodo todo) async {
    final gate = nextUpsertTodoGate;
    if (gate != null) {
      nextUpsertTodoGate = null;
      // テストが gate.complete(...) するまで保存は完了しない（微小遅延にも
      // 依存しない）。成功で complete された場合のみ実データへ委譲する。
      final result = await gate.future;
      if (result.isOk) return _inner.upsertTodo(todo);
      return result;
    }
    if (failNextUpsertTodo) {
      failNextUpsertTodo = false;
      return const Err(StorageFailure(message: 'テスト用のTodo保存失敗'));
    }
    return _inner.upsertTodo(todo);
  }

  /// true の間、次回の [deleteTodo] 呼び出しは実行前に失敗を返す（委譲しない）。
  /// 一度使うと自動的に false へ戻る（Todo/持ち物削除の失敗回帰テスト用）。
  bool failNextDeleteTodo = false;

  /// 次回の [deleteTodo] を明示的に「停止」できるゲート。設定すると、次の
  /// deleteTodo 呼び出しは委譲せずこの Completer の future を返し、テストが
  /// complete するまで未完了のまま留まる（実時間 delay に依存しない）。
  Completer<Result<void>>? nextDeleteTodoGate;

  /// [deleteTodo] の総呼び出し回数（二重実行防止で「実際には呼ばれていない」
  /// ことを検証するため）。
  int deleteTodoCallCount = 0;

  @override
  Future<Result<void>> deleteTodo(String id) async {
    deleteTodoCallCount++;
    final gate = nextDeleteTodoGate;
    if (gate != null) {
      nextDeleteTodoGate = null;
      final result = await gate.future;
      if (result.isOk) return _inner.deleteTodo(id);
      return result;
    }
    if (failNextDeleteTodo) {
      failNextDeleteTodo = false;
      return const Err(StorageFailure(message: 'テスト用のTodo削除失敗'));
    }
    return _inner.deleteTodo(id);
  }

  @override
  Future<Result<void>> upsertMemo(GenbaMemo memo) => _inner.upsertMemo(memo);

  @override
  Future<Result<void>> deleteMemo(String id) => _inner.deleteMemo(id);

  @override
  Future<Result<void>> reorderMemos({
    required String genbaId,
    required List<String> orderedIds,
  }) =>
      _inner.reorderMemos(genbaId: genbaId, orderedIds: orderedIds);

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) =>
      _inner.refreshFromRemote(isStale: isStale);

  @override
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId) =>
      _inner.adoptServerEntity(entityTable, entityId);
}
