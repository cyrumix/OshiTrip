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
  Set<String> forceEntityIds = const {},
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
    // ただし [forceEntityIds]（ユーザーが「サーバーを採用」を明示選択した対象）は、
    // 競合opが残っていても強制的にサーバー内容で上書きし版キャッシュも進める
    // （自動同期では起きず、対象ownerの当該エンティティのみ）。
    final forced = forceEntityIds.contains(id);
    if (!forced && await outbox.hasPendingFor(tableName, id, owner)) continue;
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
    // サーバー採用の対象がサーバー側で削除されていれば、競合opが残っていても
    // ローカル行を削除する（それ以外の未同期行は従来どおり保護する）。
    final forced = forceEntityIds.contains(localId);
    if (!forced && await outbox.hasPendingFor(tableName, localId, owner)) {
      continue;
    }
    await (db.delete(table)
          ..where(
            (t) => idColumn(t).equals(localId) & ownerColumn(t).equals(owner),
          ))
        .go();
    // リモートに無い＝削除済みとみなし、版キャッシュも削除する。
    await _deleteVersion(db, owner, tableName, localId);
  }
}

/// 競合解決「この端末の変更で再送」用: 指定エンティティ1件だけ、サーバーの
/// 現在版を版キャッシュへ整合させる（ローカル行は上書きしない）。
///
/// 通常の pull（[applyPulledRowsInto]）は「未同期変更がある行は版キャッシュを
/// 進めない」ことで無条件上書きを防ぐが、ユーザーが明示的に「この端末の変更で
/// サーバーを上書きする」と選んだ場合は、そのエンティティに限り最新のサーバー
/// 版を base_version として送れるよう版キャッシュを整合させる必要がある。
/// これは自動同期では決して起きず、ユーザー操作でのみ実行される（版CASの
/// 安全性は維持される — reconcile 後もサーバーが更に進んでいれば再送は再び
/// conflict になる）。
///
/// - [rows] は該当テーブルのサーバー行一覧（RLS で owner 限定）。
/// - サーバーに該当行があれば版キャッシュをその version に更新し true。
/// - サーバーに無ければ（他端末で削除された）版キャッシュを削除し false。
///   その後の keep-local upsert は base_version=null で送られ、サーバー側の
///   INSERT 経路（存在しない行の新規作成）で成立する。
Future<bool> reconcileServerVersionInto({
  required AppDatabase db,
  required String owner,
  required String tableName,
  required String entityId,
  required List<Map<String, dynamic>> rows,
}) async {
  for (final row in rows) {
    if (row['id'] != entityId) continue;
    if (row['owner_id'] != owner) continue; // 防御的 owner 再検証（C-01）
    await _saveVersion(db, owner, tableName, entityId, row['version']);
    return true;
  }
  await deleteRemoteVersion(db, owner, tableName, entityId);
  return false;
}

/// [owner] 限定でエンティティの版キャッシュを削除する（競合解決「サーバー採用」
/// の前処理。削除後の再pullでサーバーの正しい版を取り直す）。他 owner の版
/// キャッシュには触れない（C-01）。
Future<void> deleteRemoteVersion(
  AppDatabase db,
  String owner,
  String tableName,
  String entityId,
) =>
    _deleteVersion(db, owner, tableName, entityId);

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
