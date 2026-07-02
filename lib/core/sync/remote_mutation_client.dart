import '../error/result.dart';
import 'outbox_operation.dart';

/// Outbox の操作をリモートへ適用するクライアント抽象。
///
/// 実装（Supabase）は data 層。テストでは fake に差し替える。
abstract interface class RemoteMutationClient {
  /// 1件の操作を冪等に適用する。
  ///
  /// - 適用済み mutationId（サーバー側 outbox_operations に記録）なら成功扱い。
  /// - last-write-wins: リモートの updated_at が payload より新しい場合は
  ///   [ConflictFailure] を返す（呼び出し側が競合として記録する）。
  Future<Result<void>> apply(OutboxOperation op);
}
