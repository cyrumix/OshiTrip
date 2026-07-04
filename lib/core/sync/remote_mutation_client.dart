import '../error/result.dart';
import 'outbox_operation.dart';

/// Outbox の操作をリモートへ適用するクライアント抽象。
///
/// 実装（Supabase）は data 層。テストでは fake に差し替える。
abstract interface class RemoteMutationClient {
  /// 1件の操作を冪等に適用する。
  ///
  /// - 適用済み mutationId（サーバー側 outbox_operations に記録）なら成功扱い。
  /// - 競合判定はサーバー側の単調増加 `version`（CAS）で行う。端末時計や
  ///   `updated_at` の比較は用いない（H-02, decisions.md D-63）。送信した
  ///   base_version がサーバーの現在versionと一致しない場合に
  ///   [ConflictFailure] を返す（呼び出し側が競合として記録する）。
  Future<Result<void>> apply(OutboxOperation op);
}
