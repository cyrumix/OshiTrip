/// アプリ内で扱う型付きの失敗表現。
///
/// data 層は例外を捕捉して必ず [Failure] へ変換し、画面まで素通しさせない。
sealed class Failure {
  const Failure(this.message, {this.cause});

  /// ユーザー提示可能な日本語メッセージ。センシティブ情報を含めないこと。
  final String message;

  /// 元例外（ログ用。UIには出さない）。
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message, super.cause})
      : super(message ?? '通信に失敗しました。接続を確認してください');
}

class AuthFailure extends Failure {
  const AuthFailure({String? message, super.cause})
      : super(message ?? '認証に失敗しました');
}

class PermissionFailure extends Failure {
  const PermissionFailure({String? message, super.cause})
      : super(message ?? 'この操作を行う権限がありません');
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

class ConflictFailure extends Failure {
  const ConflictFailure({String? message, super.cause})
      : super(message ?? '他の端末の変更と競合しました');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String? message, super.cause})
      : super(message ?? '対象が見つかりませんでした');
}

class StorageFailure extends Failure {
  const StorageFailure({String? message, super.cause})
      : super(message ?? '端末データの保存に失敗しました');
}

class UnknownFailure extends Failure {
  const UnknownFailure({String? message, super.cause})
      : super(message ?? '予期しないエラーが発生しました');
}
