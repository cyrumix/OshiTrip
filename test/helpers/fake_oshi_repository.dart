import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';
import 'package:oshi_trip/features/oshi/domain/oshi_repository.dart';

/// [OshiRepository] を包み、`watchAll()` のエラー注入ができるデコレータ
/// （推しデータ読み込み失敗時の `GenbaFormController.submit()` 回帰テスト用）。
///
/// 実データは委譲先の実リポジトリ（Drift裏付け）が保持するため、
/// 「読み込み失敗時に現場が保存されていないこと」を実際のDB読み取りで
/// 検証できる。
class FakeOshiRepository implements OshiRepository {
  FakeOshiRepository(this._inner);

  final OshiRepository _inner;

  /// 非nullの間、`watchAll()` は委譲せず、このエラーで即座に終了する
  /// Streamを返す（`OshiRepository.watchAll` が例えばDBアクセス失敗等で
  /// エラーを発するケースを模す）。
  Object? watchAllError;

  @override
  Stream<List<OshiGroupWithMembers>> watchAll() {
    final err = watchAllError;
    if (err != null) {
      return Stream<List<OshiGroupWithMembers>>.error(err);
    }
    return _inner.watchAll();
  }

  @override
  Future<Result<void>> upsertGroup(OshiGroup group) =>
      _inner.upsertGroup(group);

  @override
  Future<Result<void>> deleteGroup(String id) => _inner.deleteGroup(id);

  @override
  Future<Result<void>> upsertMember(OshiMember member) =>
      _inner.upsertMember(member);

  @override
  Future<Result<void>> deleteMember(String id) => _inner.deleteMember(id);

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) =>
      _inner.refreshFromRemote(isStale: isStale);
}
