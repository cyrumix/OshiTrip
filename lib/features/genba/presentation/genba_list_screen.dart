import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../sharing/domain/share.dart';
import '../../sharing/domain/shared_genba_summary.dart';
import '../../social/application/member_providers.dart';
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
    // 共有された現場（自分が grantee）。サーバー権威のため valueOrNull で
    // owned の描画をブロックしない（取得後に自動で再描画される）。
    final shared =
        ref.watch(sharedGenbaSummariesProvider).valueOrNull ?? const [];
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();
    return AppScaffold(
      title: '現場',
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(genbaRepositoryProvider).refreshFromRemote();
          ref.read(syncEngineProvider).poke();
          ref.invalidate(sharedGenbaSummariesProvider);
        },
        child: AsyncValueView<List<GenbaAggregate>>(
          value: upcoming,
          // owned も shared も無いときだけ空状態にする。
          isEmpty: (list) => list.isEmpty && shared.isEmpty,
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
              if (shared.isNotEmpty) _SharedGenbaSection(shared: shared),
              // FAB が最終カードと Bottom Navigation を覆わない余白（§5）。
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      floatingActionButton: AppFab(
        heroTag: 'genba_fab',
        onPressed: () => context.push('/genba/new'),
        tooltip: '現場を登録',
      ),
    );
  }
}

/// 「共有された現場」節（自分が grantee の現場・§1）。共有バッジと権限を表示する。
class _SharedGenbaSection extends StatelessWidget {
  const _SharedGenbaSection({required this.shared});

  final List<SharedGenbaSummary> shared;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.sm),
        SectionHeader(title: '共有された現場', count: shared.length),
        for (final s in shared)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: 6,
            ),
            child: _SharedGenbaCard(summary: s),
          ),
      ],
    );
  }
}

class _SharedGenbaCard extends StatelessWidget {
  const _SharedGenbaCard({required this.summary});

  final SharedGenbaSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.push('/shared-genba/${summary.genbaId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                label: '共有',
                icon: Icons.group_outlined,
                color: theme.colorScheme.primaryContainer,
                onColor: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpace.xs),
              _Badge(
                label: summary.role == ShareRole.editor ? '編集可' : '閲覧のみ',
                icon: summary.role == ShareRole.editor
                    ? Icons.edit_outlined
                    : Icons.visibility_outlined,
                color: theme.colorScheme.secondaryContainer,
                onColor: theme.colorScheme.onSecondaryContainer,
              ),
              if (summary.eventDate != null) ...[
                const Spacer(),
                Text(
                  _formatDate(summary.eventDate!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(summary.title, style: theme.textTheme.titleMedium),
          if (summary.artistName != null && summary.artistName!.isNotEmpty)
            Text(
              summary.artistName!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: onColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: onColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
