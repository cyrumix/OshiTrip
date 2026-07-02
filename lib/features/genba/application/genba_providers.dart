import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/genba.dart';
import '../domain/genba_schedule.dart';

/// 全現場（子データ込み）のストリーム。
final genbaAggregatesProvider = StreamProvider<List<GenbaAggregate>>(
  (ref) => ref.watch(genbaRepositoryProvider).watchAll(),
);

final genbaByIdProvider = StreamProvider.family<GenbaAggregate?, String>(
  (ref, id) => ref.watch(genbaRepositoryProvider).watchById(id),
);

/// 状態判定用の現在時刻（30秒ごとに更新。テストでは固定Clockを注入）。
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => clock.now());
});

/// 未来（当日・余韻中を含む）の現場。日付が近い順。
final upcomingGenbasProvider =
    Provider<AsyncValue<List<GenbaAggregate>>>((ref) {
  final now = ref.watch(nowProvider).valueOrNull;
  return ref.watch(genbaAggregatesProvider).whenData((list) {
    final current = now ?? ref.read(clockProvider).now();
    final upcoming = list.where((a) => isUpcoming(a.genba, current)).toList()
      ..sort((a, b) => a.genba.eventDate.compareTo(b.genba.eventDate));
    return upcoming;
  });
});

/// 思い出（終了・中止済み）の現場。新しい順。
final memoryGenbasProvider = Provider<AsyncValue<List<GenbaAggregate>>>((ref) {
  final now = ref.watch(nowProvider).valueOrNull;
  return ref.watch(genbaAggregatesProvider).whenData((list) {
    final current = now ?? ref.read(clockProvider).now();
    final memories = list.where((a) => isMemory(a.genba, current)).toList()
      ..sort((a, b) => b.genba.eventDate.compareTo(a.genba.eventDate));
    return memories;
  });
});
