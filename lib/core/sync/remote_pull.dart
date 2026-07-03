import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'outbox_store.dart';

/// リモートから取得した行を owner 限定でローカルへ差分適用する共通処理（H-02）。
///
/// - 取り込み対象は [rows] のうち `owner_id == owner` のものだけ（RLS で通常は
///   それ以外来ないが防御的に再検証）。
/// - ローカルに未同期変更（pending/… の Outbox）が残る行は上書きしない。かつ
///   その行の版キャッシュも不用意に進めない。
/// - 差分削除の比較対象は「現在 owner のローカル行」のみ。他 owner の行は
///   読み込み・比較・削除のいずれもしない（C-01）。
/// - 取り込んだ行の `version`（サーバー版）を [RemoteVersions] へ保存し、次回
///   送信の base_version に使う。リモート削除を取り込んだら版キャッシュも消す。
///
/// テーブル名は [SyncEntity] 由来の固定文字列のみを渡す前提。
///
/// [isStale] は認証切替の検出用（H-02）。ローカル適用の直前に呼び、true なら
/// 挿入・上書き・差分削除・version更新を一切行わず中断する（別owner/世代に
/// なった pull がローカルへ書き込まないようにする）。
Future<void> applyPulledRowsInto<T extends Table, R>({
  required AppDatabase db,
  required OutboxStore outbox,
  required String owner,
  required String tableName,
  required List<Map<String, dynamic>> rows,
  required Insertable<R> Function(Map<String, dynamic> json) toCompanion,
  required TableInfo<T, R> table,
  required TextColumn Function(T table) idColumn,
  required TextColumn Function(T table) ownerColumn,
  required String Function(R row) idOf,
  bool Function()? isStale,
}) async {
  // ローカル適用の直前チェック: 別owner/世代になっていたら何も書かない。
  if (isStale?.call() ?? false) return;
  final remoteIds = <String>{};
  for (final row in rows) {
    final id = row['id'] as String;
    final rowOwner = row['owner_id'] as String?;
    if (rowOwner != owner) continue;
    remoteIds.add(id);
    // 未同期ローカル変更がある行は上書きせず、版キャッシュも進めない。
    if (await outbox.hasPendingFor(tableName, id, owner)) continue;
    await db.into(table).insertOnConflictUpdate(toCompanion(row));
    await _saveVersion(db, owner, tableName, id, row['version']);
  }
  // 差分削除の直前にも再チェック（この間に認証が切り替わっていないか）。
  if (isStale?.call() ?? false) return;
  final localRows = await (db.select(table)
        ..where((t) => ownerColumn(t).equals(owner)))
      .get();
  for (final localRow in localRows) {
    final localId = idOf(localRow);
    if (remoteIds.contains(localId)) continue;
    if (await outbox.hasPendingFor(tableName, localId, owner)) continue;
    await (db.delete(table)
          ..where(
            (t) => idColumn(t).equals(localId) & ownerColumn(t).equals(owner),
          ))
        .go();
    // リモートに無い＝削除済みとみなし、版キャッシュも削除する。
    await _deleteVersion(db, owner, tableName, localId);
  }
}

Future<void> _saveVersion(
  AppDatabase db,
  String owner,
  String tableName,
  String entityId,
  Object? version,
) async {
  if (version is! int) return; // 版が無ければ触れない
  await db.into(db.remoteVersions).insertOnConflictUpdate(
        RemoteVersionsCompanion.insert(
          ownerId: owner,
          entityTable: tableName,
          entityId: entityId,
          version: version,
        ),
      );
}

Future<void> _deleteVersion(
  AppDatabase db,
  String owner,
  String tableName,
  String entityId,
) =>
    (db.delete(db.remoteVersions)
          ..where(
            (t) =>
                t.ownerId.equals(owner) &
                t.entityTable.equals(tableName) &
                t.entityId.equals(entityId),
          ))
        .go();
