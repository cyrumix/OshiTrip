import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../home/presentation/widgets/genba_card.dart';
import '../application/genba_providers.dart';
import '../domain/genba.dart';

/// 現場一覧（当日を含む未来の現場、§5）。
class GenbaListScreen extends ConsumerWidget {
  const GenbaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingGenbasProvider);
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();
    return Scaffold(
      appBar: AppBar(title: const Text('現場')),
      body: AsyncValueView<List<GenbaAggregate>>(
        value: upcoming,
        isEmpty: (list) => list.isEmpty,
        emptyView: EmptyView(
          icon: Icons.event_note,
          message: 'これからの現場がありません',
          description: '終了した現場は「思い出」タブに表示されます。',
          actionLabel: '現場を登録する',
          onAction: () => context.push('/genba/new'),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final aggregate in list)
              GenbaCard(aggregate: aggregate, now: now),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'genba_fab',
        onPressed: () => context.push('/genba/new'),
        tooltip: '現場を登録',
        child: const Icon(Icons.add),
      ),
    );
  }
}
