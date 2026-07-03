import '../../../core/error/result.dart';
import 'oshi.dart';

/// マイ推しのリポジトリ抽象（ローカルCRUD + 同期）。
abstract interface class OshiRepository {
  Stream<List<OshiGroupWithMembers>> watchAll();

  Future<Result<void>> upsertGroup(OshiGroup group);
  Future<Result<void>> deleteGroup(String id);

  Future<Result<void>> upsertMember(OshiMember member);
  Future<Result<void>> deleteMember(String id);

  /// リモートの推しグループ／メンバーを現在 owner 限定でローカルへ取り込む
  /// （H-02: キャッシュ先行→背景更新）。ローカル未同期変更は上書きしない。
  /// デモ・未ログインでは何もしない。
  /// [isStale] は認証切替検出用（true で以降のローカル適用を中断）。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});
}
