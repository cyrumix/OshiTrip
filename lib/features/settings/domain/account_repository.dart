import '../../../core/error/result.dart';

/// アカウント操作の境界。
///
/// アカウント削除はサーバー側 RPC（`delete_account`）で関連データを
/// カスケード削除する設計（ADR-0008）。RPC 未デプロイの環境では
/// 失敗を失敗として返し、成功したように見せない。
abstract interface class AccountRepository {
  /// 危険操作。呼び出し側で再確認ダイアログを必須とする。
  Future<Result<void>> deleteAccount();
}
