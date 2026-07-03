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

  /// ログアウト。認証主体の切替と、同期 drain・背景 pull を一体的に排他制御する
  /// （C-01/H-02）: 認証状態を切り替える前に、実行中の remote mutation と
  /// 実行中の background pull の完了/中断を待つことで、前ユーザー(A)の操作・
  /// pull が次ユーザー(B)のセッションへ漏れないようにする。
  Future<Failure?> signOut() async {
    final engine = ref.read(syncEngineProvider);
    final refresher = ref.read(sessionRefresherProvider);
    await engine.pauseForAuthTransition();
    await refresher.pauseForAuthTransition();
    try {
      return await _run((repo) => repo.signOut());
    } finally {
      engine.resumeAfterAuthTransition();
      refresher.resumeAfterAuthTransition();
    }
  }

  Future<Failure?> _run<T>(
    Future<Result<T>> Function(AuthRepository repo) action,
  ) async {
    state = const AsyncLoading();
    final result = await action(ref.read(authRepositoryProvider));
    state = const AsyncData(null);
    return result.failureOrNull;
  }

  /// ログイン直後: Outbox を流し、リモートの現場・思い出・推しを owner 単位で
  /// 一度だけ背景 pull する（[SessionRefresher] が genba→memory/oshi の順序と
  /// 重複防止を担う）。UIは完了を待たない（キャッシュ先行・バックグラウンド更新）。
  /// セッション復元（currentUser の Loading→Authenticated）でも [sessionSyncProvider]
  /// 経由で同じ pull が走るが、SessionRefresher の owner 重複防止で二重には走らない。
  void _afterSignIn() {
    ref.read(syncCoordinatorProvider).onAuthenticated();
    final ownerId = ref.read(authRepositoryProvider).currentUser?.id;
    if (ownerId != null) {
      ref.read(sessionRefresherProvider).onAuthenticated(ownerId);
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
