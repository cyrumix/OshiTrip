import '../../../core/error/result.dart';
import 'oshi.dart';

/// マイ推しのリポジトリ抽象（ローカルCRUD + 同期）。
abstract interface class OshiRepository {
  Stream<List<OshiGroupWithMembers>> watchAll();

  Future<Result<void>> upsertGroup(OshiGroup group);
  Future<Result<void>> deleteGroup(String id);

  Future<Result<void>> upsertMember(OshiMember member);
  Future<Result<void>> deleteMember(String id);
}
