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
    // 画像削除の再試行キューも対象 owner 分を消す（Issue2）。実ファイルは下の
    // imageStore.purgeOwner が owner 単位で全削除するため、キュー行は不要になる。
    // 他 owner のキューには触れない。
    await (db.delete(db.pendingImageDeletions)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.setlistItems)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.goodsItems)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.visitedPlaces)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.memoryEntries)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.oshiAnniversaries)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.oshiMembers)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.oshiGroups)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.todoTemplateItems)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.todoTemplates)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    // 旅程は子（leg/entry/link/spot）→ 親（plan）の順に削除する。
    await (db.delete(db.itineraryLegs)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.itineraryEntries)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.itinerarySpotLinks)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.itinerarySpots)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.itineraryPlans)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.genbas)..where((t) => t.ownerId.equals(ownerId))).go();
    await (db.delete(db.outboxOps)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.formDrafts)..where((t) => t.ownerId.equals(ownerId)))
        .go();
    await (db.delete(db.remoteVersions)
          ..where((t) => t.ownerId.equals(ownerId)))
        .go();
    // owner 単位の端末設定（推しカラー等、`<key>.<ownerId>` 形式）も削除する。
    // 端末共通の AppKvs（テーマ・チュートリアル等, D-45）には触れない。
    await (db.delete(db.appKvs)
          ..where((t) => t.key.equals(KvKeys.oshiAccentColorFor(ownerId))))
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
