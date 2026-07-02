import '../../../core/error/result.dart';

/// 認証済みユーザー。
class AppUser {
  const AppUser({required this.id, required this.email, this.isDemo = false});

  final String id;
  final String email;

  /// デモモード（development で Supabase 未設定時のみ）のローカルユーザー。
  final bool isDemo;
}

/// 認証リポジトリ抽象。
abstract interface class AuthRepository {
  /// 認証状態の変化（起動直後の復元を含む）。
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// パスワード再設定メールの送信。
  Future<Result<void>> sendPasswordReset(String email);
}
