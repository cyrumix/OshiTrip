import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/domain/memory_repository.dart';

/// [MemoryRepository] を包み、お気に入り・表紙設定の失敗・遅延・呼び出し
/// 回数を制御できるデコレータ（R7: MemoryActionsController の回帰テスト用）。
///
/// 実データは委譲先（Drift裏付け）が保持するため、「失敗時にローカル状態が
/// 変わっていないこと」を実際のDB読み取りで検証できる。
class FakeMemoryRepository implements MemoryRepository {
  FakeMemoryRepository(this._inner);

  final MemoryRepository _inner;

  /// true の間、次回の [setEntryFavorite] は実行前に失敗を返す（委譲しない）。
  /// 一度使うと自動的に false へ戻る。
  bool failNextSetFavorite = false;

  /// [setEntryFavorite] 呼び出しごとの待機（二重タップ window 用）。
  Duration setFavoriteDelay = Duration.zero;

  /// [setEntryFavorite] の総呼び出し回数。
  int setFavoriteCallCount = 0;

  @override
  Future<Result<void>> setEntryFavorite({
    required String genbaId,
    required bool isFavorite,
  }) async {
    setFavoriteCallCount++;
    if (setFavoriteDelay > Duration.zero) {
      await Future<void>.delayed(setFavoriteDelay);
    }
    if (failNextSetFavorite) {
      failNextSetFavorite = false;
      return const Err(StorageFailure(message: 'テスト用の保存失敗'));
    }
    return _inner.setEntryFavorite(genbaId: genbaId, isFavorite: isFavorite);
  }

  @override
  Stream<MemoryBundle> watchByGenbaId(String genbaId) =>
      _inner.watchByGenbaId(genbaId);

  @override
  Future<Result<void>> upsertEntry(MemoryEntry entry) =>
      _inner.upsertEntry(entry);

  @override
  Future<Result<void>> addPhoto(MemoryPhoto photo) => _inner.addPhoto(photo);

  @override
  Future<Result<void>> updatePhoto(MemoryPhoto photo) =>
      _inner.updatePhoto(photo);

  @override
  Future<Result<void>> deletePhoto(String id) => _inner.deletePhoto(id);

  @override
  Future<Result<void>> deleteSubjectWithPhotos({
    required MemorySubjectType subjectType,
    required String subjectId,
  }) =>
      _inner.deleteSubjectWithPhotos(
        subjectType: subjectType,
        subjectId: subjectId,
      );

  @override
  Future<Result<void>> deleteSubjectDetachingPhotos({
    required MemorySubjectType subjectType,
    required String subjectId,
  }) =>
      _inner.deleteSubjectDetachingPhotos(
        subjectType: subjectType,
        subjectId: subjectId,
      );

  @override
  Future<void> flushPendingImageDeletions(String owner) =>
      _inner.flushPendingImageDeletions(owner);

  @override
  Future<Result<void>> setCoverPhoto({
    required String genbaId,
    required String photoId,
  }) =>
      _inner.setCoverPhoto(genbaId: genbaId, photoId: photoId);

  @override
  Future<Result<void>> upsertSetlistItem(SetlistItem item) =>
      _inner.upsertSetlistItem(item);

  @override
  Future<Result<void>> deleteSetlistItem(String id) =>
      _inner.deleteSetlistItem(id);

  @override
  Future<Result<void>> upsertGoodsItem(GoodsItem item) =>
      _inner.upsertGoodsItem(item);

  @override
  Future<Result<void>> deleteGoodsItem(String id) => _inner.deleteGoodsItem(id);

  @override
  Future<Result<void>> upsertVisitedPlace(VisitedPlace place) =>
      _inner.upsertVisitedPlace(place);

  @override
  Future<Result<void>> deleteVisitedPlace(String id) =>
      _inner.deleteVisitedPlace(id);

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) =>
      _inner.refreshFromRemote(isStale: isStale);

  @override
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId) =>
      _inner.adoptServerEntity(entityTable, entityId);
}
