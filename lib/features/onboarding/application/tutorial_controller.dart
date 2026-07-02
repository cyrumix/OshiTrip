import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';

/// チュートリアル完了状態（端末保存・設定から再表示可、§4.1）。
class TutorialDoneNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final value = await ref.watch(kvStoreProvider).get(KvKeys.tutorialDone);
    return value == '1';
  }

  Future<void> complete() async {
    await ref.read(kvStoreProvider).put(KvKeys.tutorialDone, '1');
    state = const AsyncData(true);
  }

  /// 設定の「チュートリアルをもう一度見る」用。
  Future<void> reset() async {
    await ref.read(kvStoreProvider).remove(KvKeys.tutorialDone);
    state = const AsyncData(false);
  }
}

final tutorialDoneProvider =
    AsyncNotifierProvider<TutorialDoneNotifier, bool>(TutorialDoneNotifier.new);
