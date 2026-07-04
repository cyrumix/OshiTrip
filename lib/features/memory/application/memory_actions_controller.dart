import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';

/// 思い出の書き込み操作（お気に入り・表紙設定）を presentation から
/// 切り離す application 層（R7 / design-spec §8/§9/§12.1）。
///
/// [GenbaActionsController]（R5, D-111）と同じ per-key 方式:
/// - state は「進行中の操作キー集合」。同一キーの再入（二重タップ）だけを
///   無視し、無関係な操作はブロックしない。
/// - 各メソッドは [Failure]（null=成功）を返し、呼び出し側が必ず結果を
///   ユーザーへ伝える（成功していない操作を成功表示しない）。
/// - 楽観更新は行わない。DBの watch ストリームが真実であり、失敗時は
///   DBが変わっていないため表示は自然に元のまま維持される。
class MemoryActionsController
    extends AutoDisposeFamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String genbaId) => const {};

  /// [key] の操作が進行中か（ボタンの無効化表示に使う）。
  bool isBusy(String key) => state.contains(key);

  static const favoriteKey = 'favorite';
  static const coverKey = 'cover';

  Future<Failure?> _run(
    String key,
    Future<Failure?> Function() action,
  ) async {
    if (state.contains(key)) return null; // 同一操作の二重タップを無視。
    state = {...state, key};
    try {
      return await action();
    } finally {
      state = {...state}..remove(key);
    }
  }

  /// 思い出単位のお気に入りを設定する（entry が無ければ repository が作成）。
  Future<Failure?> setFavorite({required bool isFavorite}) =>
      _run(favoriteKey, () async {
        final result = await ref
            .read(memoryRepositoryProvider)
            .setEntryFavorite(genbaId: arg, isFavorite: isFavorite);
        return result.failureOrNull;
      });

  /// [photoId] を表紙にする（同一現場の cover は常に最大1件, §12.1）。
  Future<Failure?> setCoverPhoto(String photoId) => _run(coverKey, () async {
        final result = await ref
            .read(memoryRepositoryProvider)
            .setCoverPhoto(genbaId: arg, photoId: photoId);
        return result.failureOrNull;
      });
}

final memoryActionsControllerProvider = NotifierProvider.autoDispose
    .family<MemoryActionsController, Set<String>, String>(
  MemoryActionsController.new,
);
