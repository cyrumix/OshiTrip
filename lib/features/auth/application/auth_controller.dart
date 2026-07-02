import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../domain/auth_repository.dart';

/// 認証操作の実行と送信中状態。
///
/// 各操作の戻り値は UI 表示用の [Failure]（null なら成功）。
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> signIn(String email, String password) async {
    final failure =
        await _run((repo) => repo.signIn(email: email, password: password));
    if (failure == null) _afterSignIn();
    return failure;
  }

  Future<Failure?> signUp(String email, String password) async {
    final failure =
        await _run((repo) => repo.signUp(email: email, password: password));
    if (failure == null) _afterSignIn();
    return failure;
  }

  Future<Failure?> sendPasswordReset(String email) =>
      _run((repo) => repo.sendPasswordReset(email));

  Future<Failure?> signOut() => _run((repo) => repo.signOut());

  Future<Failure?> _run<T>(
    Future<Result<T>> Function(AuthRepository repo) action,
  ) async {
    state = const AsyncLoading();
    final result = await action(ref.read(authRepositoryProvider));
    state = const AsyncData(null);
    return result.failureOrNull;
  }

  /// ログイン直後: リモートの現場をローカルへ取り込み、Outboxを流す。
  /// UIは完了を待たない（キャッシュ先行・バックグラウンド更新）。
  void _afterSignIn() {
    ref.read(syncEngineProvider).poke();
    unawaited(ref.read(genbaRepositoryProvider).refreshFromRemote());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
