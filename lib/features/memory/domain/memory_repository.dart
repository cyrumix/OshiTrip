import '../../../core/error/result.dart';
import 'memory.dart';

/// 思い出のリポジトリ抽象。
abstract interface class MemoryRepository {
  Stream<MemoryBundle> watchByGenbaId(String genbaId);

  Future<Result<void>> upsertEntry(MemoryEntry entry);

  /// 思い出単位のお気に入りを設定する（§8/§12.1）。entry が無ければ作成する。
  /// 一覧・詳細のどちらからでも呼べる。
  Future<Result<void>> setEntryFavorite({
    required String genbaId,
    required bool isFavorite,
  });

  Future<Result<void>> addPhoto(MemoryPhoto photo);
  Future<Result<void>> updatePhoto(MemoryPhoto photo);
  Future<Result<void>> deletePhoto(String id);

  /// 関連項目（グッズ/行った場所）と、それに紐づく写真メタデータ・ファイルを
  /// **原子的に**削除する（§8.4 / Issue1）。写真行・項目行の削除と Outbox 登録・
  /// 画像削除キューへの積み込みを同一トランザクションで行い、途中失敗時は DB を
  /// 全てロールバックする。画像ファイルの物理削除はトランザクション外で行い、
  /// 失敗しても再試行キューに残す（DB 側は確定済み・成功扱いにしない）。
  Future<Result<void>> deleteSubjectWithPhotos({
    required MemorySubjectType subjectType,
    required String subjectId,
  });

  /// 関連項目を削除しつつ、紐づく写真は**アルバムへ残す**（既定, §8.4）。
  /// 写真行・ファイルは削除せず、関連（subjectType/subjectId）のみ解除して
  /// album_category は元分類を維持する。項目削除と写真の関連解除を同一
  /// トランザクションで行う。
  Future<Result<void>> deleteSubjectDetachingPhotos({
    required MemorySubjectType subjectType,
    required String subjectId,
  });

  /// 画像ファイル削除の再試行キューを処理する（成功行は除去・失敗行は残す）。
  Future<void> flushPendingImageDeletions(String owner);

  /// [photoId] を表紙にする。同一現場の他の cover を必ず外し、cover は
  /// 常に最大1件（design-spec §12.1）。DB の部分ユニーク索引と、旧 cover を
  /// 先に外してから設定する順序の両方で一意性を担保する。
  Future<Result<void>> setCoverPhoto({
    required String genbaId,
    required String photoId,
  });

  Future<Result<void>> upsertSetlistItem(SetlistItem item);
  Future<Result<void>> deleteSetlistItem(String id);

  Future<Result<void>> upsertGoodsItem(GoodsItem item);
  Future<Result<void>> deleteGoodsItem(String id);

  Future<Result<void>> upsertVisitedPlace(VisitedPlace place);
  Future<Result<void>> deleteVisitedPlace(String id);

  /// リモートの思い出データ（entry / photos メタ / setlist / goods / places）を
  /// 現在 owner 限定でローカルへ取り込む（H-02: キャッシュ先行→背景更新）。
  /// ローカル未同期変更は上書きしない。デモ・未ログインでは何もしない。
  /// [isStale] は認証切替検出用（true で以降のローカル適用を中断）。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  /// 競合解決「サーバーを採用」用（R8-A 再レビュー）: [entityTable] の
  /// [entityId] 1件だけサーバー最新内容を取得しローカルへ強制適用する。
  /// 通信・保存失敗時は [Err] を返しローカルは変更しない（呼び出し側は成功後に
  /// 競合opを削除する = 失敗安全）。所有しないテーブルは失敗を返す。
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}

/// 写真アップロードの境界（§8 / 今回はローカル参照＋境界まで）。
///
/// 完全な再試行キュー・バックグラウンドアップロードは後続範囲
/// （docs/follow-up-work.md）。インターフェースと Supabase Storage への
/// 単発アップロード実装のみ提供する。
abstract interface class MemoryPhotoUploader {
  /// [photo.localPath] のファイルを認可付きストレージへアップロードし、
  /// storagePath / uploadStatus を更新した写真を返す。
  Future<Result<MemoryPhoto>> upload(MemoryPhoto photo);

  /// 認可付きの表示用URL（署名URL）を取得する。
  Future<Result<Uri>> signedUrl(MemoryPhoto photo);
}
