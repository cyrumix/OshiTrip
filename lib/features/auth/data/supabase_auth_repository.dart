import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../domain/auth_repository.dart';

/// Supabase Auth（メールアドレス + パスワード）実装。
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  AppUser? _toAppUser(sb.User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email ?? '');

  @override
  Stream<AppUser?> authStateChanges() => _client.auth.onAuthStateChange
      .map((event) => _toAppUser(event.session?.user));

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth
          .signUp(email: email, password: password)
          .withRemoteTimeout();
      final user = _toAppUser(response.user);
      if (user == null) {
        return const Err(AuthFailure(message: '登録に失敗しました'));
      }
      return Ok(user);
    } on sb.AuthException catch (e) {
      return Err(AuthFailure(message: _authMessage(e), cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth
          .signInWithPassword(email: email, password: password)
          .withRemoteTimeout();
      final user = _toAppUser(response.user);
      if (user == null) {
        return const Err(AuthFailure());
      }
      return Ok(user);
    } on sb.AuthException catch (e) {
      return Err(AuthFailure(message: _authMessage(e), cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut().withRemoteTimeout();
      return const Ok(null);
    } on sb.AuthException catch (e) {
      return Err(AuthFailure(cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email).withRemoteTimeout();
      return const Ok(null);
    } on sb.AuthException catch (e) {
      return Err(AuthFailure(message: _authMessage(e), cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  /// Supabase のエラーメッセージをユーザー向け日本語へ変換
  /// （メールアドレス等のセンシティブ情報は含めない）。
  String _authMessage(sb.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'メールアドレスまたはパスワードが正しくありません';
    }
    if (message.contains('already registered')) {
      return 'このメールアドレスは登録済みです';
    }
    if (message.contains('password should be')) {
      return 'パスワードが短すぎます（6文字以上にしてください）';
    }
    if (message.contains('email not confirmed')) {
      return 'メールアドレスの確認が完了していません。受信メールをご確認ください';
    }
    if (message.contains('rate limit')) {
      return '試行回数が多すぎます。しばらく待ってからお試しください';
    }
    return '認証に失敗しました';
  }
}
