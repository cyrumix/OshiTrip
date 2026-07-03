import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/local_data_scope.dart';
import '../../../core/db/local_data_purge.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';

/// アカウント削除の操作（サーバー削除 + ローカルパージ）。
///
/// アカウント削除は認証主体を変える操作のため、[AuthController.signOut] と
/// 同じ排他制御を行う（C-01）: サーバー削除 RPC の前に
/// [SyncEngine.pauseForAuthTransition] を await し、実行中の Outbox drain
/// （in-flight な remote mutation）が完了してから削除を開始する。これにより
/// 削除対象ユーザー(A)の Outbox が、削除処理中に送信されたり別セッションへ
/// 渡ったりしない。
///
/// 手順と保証（§15.2 / C-01）:
/// 1. drain を停止・完了待ち（pause）してから、サーバー RPC で削除。
///    失敗したらローカルは一切変更しない。
/// 2. サーバー削除成功後、「未完了マーカー（[KvKeys.pendingAccountPurge]）」に
///    対象 owner を記録してからローカル purge を実行する。purge 完了後に
///    マーカーを消す。purge 途中で落ちても次回起動（[resumePendingAccountPurge]）
///    で安全に再試行できる。
/// 3. purge 失敗でも [AsyncLoading] のまま固まらない（finally で必ず解除）。
/// 4. 成功・失敗・例外のいずれでも finally で SyncEngine を resume する
///    （paused のまま残さない）。
/// 5. 対象 owner の行だけを削除し、他 owner のデータは変更しない
///    （[purgeLocalDataForOwner] が owner 絞り込み）。
///
/// ログアウト・ユーザー切替では purge を呼ばない（前 owner の行はクエリ側の
/// owner 絞り込みで不可視化するだけで保持し、再ログイン時に失わないため）。
class AccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> deleteAccount() async {
    final scope = ref.read(localDataScopeProvider);
    final ownerId = scope is LocalDataScopeAuthenticated ? scope.ownerId : null;
    final db = ref.read(databaseProvider);
    final kv = ref.read(kvStoreProvider);
    final engine = ref.read(syncEngineProvider);
    final refresher = ref.read(sessionRefresherProvider);

    state = const AsyncLoading();
    // 実行中の drain（in-flight remote mutation）と背景 pull が完了/中断してから
    // 削除を開始する（H-02: pull とアカウント削除を競合させない）。
    await engine.pauseForAuthTransition();
    await refresher.pauseForAuthTransition();
    try {
      final result = await ref.read(accountRepositoryProvider).deleteAccount();
      final failure = result.failureOrNull;
      if (failure != null) {
        // サーバー削除失敗: ローカルデータは一切削除しない。
        return failure;
      }
      if (ownerId == null) return null;

      // サーバー削除は成功。ローカル削除が未完了で中断しても次回起動で
      // 再試行できるよう、先にマーカーを記録する。
      await kv.put(KvKeys.pendingAccountPurge, ownerId);
      try {
        await purgeLocalDataForOwner(
          db,
          ownerId,
          imageStore: ref.read(imageStoreProvider),
        );
        await kv.remove(KvKeys.pendingAccountPurge);
        return null;
      } catch (e) {
        // サーバーは削除済み。ローカル削除は次回起動で再試行される
        // （マーカーは残す）。失敗として通知するが、成功扱いにはしない。
        return StorageFailure(cause: e);
      }
    } finally {
      // 成功・失敗・例外のいずれでも SyncEngine と SessionRefresher を再開し、
      // AsyncLoading のまま固まらないようにする。
      engine.resumeAfterAuthTransition();
      refresher.resumeAfterAuthTransition();
      state = const AsyncData(null);
    }
  }
}

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);
