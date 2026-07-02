import '../../../core/error/result.dart';
import 'memory.dart';

/// 思い出のリポジトリ抽象。
abstract interface class MemoryRepository {
  Stream<MemoryBundle> watchByGenbaId(String genbaId);

  Future<Result<void>> upsertEntry(MemoryEntry entry);

  Future<Result<void>> addPhoto(MemoryPhoto photo);
  Future<Result<void>> updatePhoto(MemoryPhoto photo);
  Future<Result<void>> deletePhoto(String id);

  Future<Result<void>> upsertSetlistItem(SetlistItem item);
  Future<Result<void>> deleteSetlistItem(String id);

  Future<Result<void>> upsertGoodsItem(GoodsItem item);
  Future<Result<void>> deleteGoodsItem(String id);

  Future<Result<void>> upsertVisitedPlace(VisitedPlace place);
  Future<Result<void>> deleteVisitedPlace(String id);
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
