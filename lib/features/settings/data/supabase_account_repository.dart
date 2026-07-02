import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/account_repository.dart';

/// アカウント削除の Supabase RPC 境界実装。
///
/// サーバー側 `delete_account()`（SECURITY DEFINER、マイグレーションで定義）
/// を呼び出し、ユーザーデータをカスケード削除して auth ユーザーを消す。
/// RPC が未デプロイ・失敗の場合は Failure を返す（成功したように見せない）。
class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _client.rpc<void>('delete_account');
      await _client.auth.signOut();
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(
        UnknownFailure(
          message: 'アカウント削除に失敗しました。時間をおいて再度お試しください',
          cause: e,
        ),
      );
    } on AuthException catch (e) {
      return Err(AuthFailure(cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }
}

/// デモモード用: サーバーが存在しないため、その旨を明示して失敗させる。
class DemoAccountRepository implements AccountRepository {
  const DemoAccountRepository();

  @override
  Future<Result<void>> deleteAccount() async {
    return const Err(
      ValidationFailure('デモモードにはサーバー上のアカウントがありません。ログアウトで端末データを終了できます'),
    );
  }
}
