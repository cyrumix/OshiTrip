import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../../genba/domain/genba_schedule.dart';
import 'widgets/genba_card.dart';
import 'widgets/today_card.dart';

/// ホーム（§6）。未来の現場を近い順に表示し、当日は最上部を当日モードへ。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingGenbasProvider);
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();

    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(genbaRepositoryProvider).refreshFromRemote();
          ref.read(syncEngineProvider).poke();
        },
        child: AsyncValueView<List<GenbaAggregate>>(
          value: upcoming,
          isEmpty: (list) => list.isEmpty,
          emptyView: EmptyView(
            icon: Icons.event_note,
            message: '予定している現場がありません',
            description: '最初の現場を登録すると、残り日数とやることが自動で整理されます。',
            actionLabel: '現場を登録する',
            onAction: () => context.push('/genba/new'),
          ),
          data: (list) {
            // 当日（本日/余韻中）の現場は開始時刻順に最上部へ（§6.2）。
            final todayItems = list.where((a) {
              final s = deriveGenbaStatus(a.genba, now);
              return s == GenbaStatus.today || s == GenbaStatus.afterglow;
            }).toList()
              ..sort(
                (a, b) => (a.genba.startTimeMinutes ?? 0)
                    .compareTo(b.genba.startTimeMinutes ?? 0),
              );
            final rest = list.where((a) => !todayItems.contains(a)).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final today in todayItems)
                  TodayCard(aggregate: today, now: now),
                for (final aggregate in rest)
                  GenbaCard(aggregate: aggregate, now: now),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: () => context.push('/genba/new'),
        icon: const Icon(Icons.add),
        label: const Text('現場を登録'),
      ),
    );
  }
}
