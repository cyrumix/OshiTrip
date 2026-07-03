import 'package:drift/drift.dart';

import 'app_database.dart';

/// 親レコードが現在 owner に属さない（存在しない・別owner・推測ID）ことを
/// 示す番兵例外（C-01）。Repository の transaction 内で投げ、呼び出し側で
/// 型付き Failure（ValidationFailure）へ変換する。
class ParentOwnershipException implements Exception {
  const ParentOwnershipException(this.parentTable, this.parentId);

  final String parentTable;
  final String parentId;

  @override
  String toString() =>
      'ParentOwnershipException($parentTable/$parentId は現在ownerに属さない)';
}

/// owner 境界を強制する共通クエリ群（C-01）。
///
/// テーブル名は [SyncEntity] 由来の固定文字列のみを渡す前提で、
/// 生SQLの `$table` 埋め込みは安全（ユーザー入力を連結しない）。
extension OwnerGuard on AppDatabase {
  /// [table] に [id] の行が既に存在し、その owner が [owner] と異なるか。
  ///
  /// upsert は `id` 主キーの `insertOnConflictUpdate` が owner を見ずに
  /// 既存行を更新してしまうため、書き込み前にこれで別owner行の乗っ取りを防ぐ。
  Future<bool> existsForOtherOwner(
    String table,
    String id,
    String owner,
  ) async {
    final row = await customSelect(
      'SELECT 1 FROM $table WHERE id = ? AND owner_id != ? LIMIT 1',
      variables: [Variable.withString(id), Variable.withString(owner)],
    ).getSingleOrNull();
    return row != null;
  }

  /// [parentTable] に [parentId] の行が存在し、かつ現在 [owner] に属するか。
  ///
  /// 子データ（ticket/todo/memory/...）の作成前に、親（genba / oshi_group）が
  /// 現在ownerのものであることを確認するために使う。
  Future<bool> parentBelongsToOwner(
    String parentTable,
    String parentId,
    String owner,
  ) async {
    final row = await customSelect(
      'SELECT 1 FROM $parentTable WHERE id = ? AND owner_id = ? LIMIT 1',
      variables: [
        Variable.withString(parentId),
        Variable.withString(owner),
      ],
    ).getSingleOrNull();
    return row != null;
  }

  /// 推しメン [memberId] が、現在 [owner] に属し、かつグループ [groupId] に
  /// 所属するか（記念日の member_id 整合検証用, C-01 / R6独立レビュー）。
  Future<bool> memberInGroupOfOwner(
    String memberId,
    String groupId,
    String owner,
  ) async {
    final row = await customSelect(
      'SELECT 1 FROM oshi_members '
      'WHERE id = ? AND group_id = ? AND owner_id = ? LIMIT 1',
      variables: [
        Variable.withString(memberId),
        Variable.withString(groupId),
        Variable.withString(owner),
      ],
    ).getSingleOrNull();
    return row != null;
  }
}
