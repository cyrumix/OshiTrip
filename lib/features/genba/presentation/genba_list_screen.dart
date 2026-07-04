import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../application/genba_providers.dart';
import '../domain/genba.dart';
import 'widgets/genba_event_list_card.dart';

/// 現場一覧（当日を含む未来の現場、§5 / design-spec §6.3・R7）。
///
/// - 各カードは日付・公演名・グループ・会場・残日数・推しカラー罫線と、
///   状態（中止/予定/準備中/本日/余韻中）を文字＋アイコンで表示する。
/// - 未来の中止現場も消さずに表示し、詳細から編集・中止取消できる（H-07）。
/// - タブ切替後もスクロール位置を保持し（§5）、FAB が最終カードと
///   Bottom Navigation を覆わない余白を確保する。
class GenbaListScreen extends ConsumerWidget {
  const GenbaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingGenbasProvider);
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();
    return AppScaffold(
      title: '現場',
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(genbaRepositoryProvider).refreshFromRemote();
          ref.read(syncEngineProvider).poke();
        },
        child: AsyncValueView<List<GenbaAggregate>>(
          value: upcoming,
          isEmpty: (list) => list.isEmpty,
          loadingView: const LoadingSkeleton.list(),
          emptyView: EmptyView(
            icon: Icons.event_note,
            message: 'これからの現場がありません',
            description: '終了した現場は「思い出」タブに表示されます。',
            actionLabel: '現場を登録する',
            onAction: () => context.push('/genba/new'),
          ),
          data: (list) => ListView(
            key: const PageStorageKey('genba_list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            children: [
              for (final aggregate in list)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: 6,
                  ),
                  child: GenbaEventListCard(
                    aggregate: aggregate,
                    now: now,
                    alwaysShowStatus: true,
                  ),
                ),
              // FAB が最終カードと Bottom Navigation を覆わない余白（§5）。
              const SizedBox(height: 96),
            ],
          ),
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
