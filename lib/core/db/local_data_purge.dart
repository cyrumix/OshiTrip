import '../images/image_store.dart';
import '../storage/kv_store.dart';
import 'app_database.dart';

/// 指定 owner のローカルデータを全テーブルから物理削除する。
///
/// アカウント削除成功後にのみ呼び出す（§15.2「アカウント削除と関連データ削除」）。
/// ログアウト・ユーザー切替では呼ばない（owner の行は保持し、クエリ側の
/// owner 絞り込みで不可視化するだけ — 再ログイン時にデータを失わないため）。
/// 他 owner の行・ファイルには一切触れない。
/// [imageStore] を渡すと owner の画像ファイルも削除する（H-03/H-04）。
Future<void> purgeLocalDataForOwner(
  AppDatabase db,
  String ownerId, {
  ImageStore? imageStore,
}) async {
  await db.transaction(() async {
    await (db.delete(db.tickets)..where((t) => t.ownerId.equals(ownerId))).go();
    await (db.delete(db.transports)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.lodgings)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.todos)..where((t) => t.ownerId.equals(ownerId))).go();
    await (db.delete(db.genbaMemos)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.memoryPhotos)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.setlistItems)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.goodsItems)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.visitedPlaces)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.memoryEntries)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.oshiMembers)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.oshiGroups)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.genbas)..where((t) => t.ownerId.equals(ownerId))).go();
    await (db.delete(db.outboxOps)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.formDrafts)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.remoteVersions)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
  });
  // DB トランザクション確定後に物理ファイルを掃除する（別 owner は触らない）。
  await imageStore?.purgeOwner(ownerId);
}

/// 起動時に「サーバー削除済み・ローカル削除未完了」の owner が記録されて
/// いれば、ローカル purge を安全に再試行して完了させる（C-01）。
///
/// [AccountController.deleteAccount] がサーバー削除成功直後にマーカーを
/// 書き、purge 完了後にマーカーを消す。purge の途中でアプリが落ちても、
/// このマーカーが残るため次回起動でやり直せる。purge は owner 単位で
/// 冪等（対象 owner の行を消すだけ）なので、部分削除済みでも安全。
Future<void> resumePendingAccountPurge(
  AppDatabase db, {
  ImageStore? imageStore,
}) async {
  final row = await (db.select(db.appKvs)
        ..where((t) => t.key.equals(KvKeys.pendingAccountPurge)))
      .getSingleOrNull();
  final ownerId = row?.value;
  if (ownerId == null || ownerId.isEmpty) return;
  await purgeLocalDataForOwner(db, ownerId, imageStore: imageStore);
  await (db.delete(db.appKvs)
        ..where((t) => t.key.equals(KvKeys.pendingAccountPurge)))
      .go();
}
