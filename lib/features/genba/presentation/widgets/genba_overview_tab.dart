import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/images/image_store.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../home/presentation/widgets/genba_card.dart';
import '../../application/genba_actions_controller.dart';
import '../../domain/genba.dart';
import '../../domain/genba_preparation.dart';
import '../../domain/genba_schedule.dart';
import 'action_feedback.dart';

/// 現場詳細の「概要」タブ（design-spec §7.2）。
///
/// 公演情報・参加状態・状態操作・準備サマリ・次のアクション・
/// ヒーロー画像の管理をまとめる。編集はタブ内・ダイアログで行い、
/// 長大な1画面にしない。
class GenbaOverviewTab extends ConsumerWidget {
  const GenbaOverviewTab({
    super.key,
    required this.aggregate,
    required this.now,
  });

  final GenbaAggregate aggregate;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    final status = deriveGenbaStatus(genba, now);
    final prep = GenbaPreparation.of(aggregate);
    final nextAction = deriveNextAction(aggregate, now);
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return ListView(
      key: PageStorageKey('genba_tab_overview_${genba.id}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        96,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GenbaStatusChip(status: status),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      genba.artistName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                [
                  '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}',
                  if (genba.doorTimeMinutes != null)
                    '開場 ${formatMinutes(genba.doorTimeMinutes!)}',
                  if (genba.startTimeMinutes != null)
                    '開演 ${formatMinutes(genba.startTimeMinutes!)}',
                  if (genba.endTimeMinutes != null)
                    '終演 ${formatMinutes(genba.endTimeMinutes!)}',
                ].join('　'),
              ),
              if (genba.venue != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text('会場: ${genba.venue}'),
              ],
              if (genba.performanceType != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text('種別: ${genba.performanceType}'),
              ],
              _StatusActionsSection(genba: genba, status: status),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _AttendanceCard(genba: genba),
        const SizedBox(height: AppSpace.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '準備サマリ',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  PrepChip(label: 'チケット', state: prep.ticket),
                  PrepChip(label: '交通', state: prep.transport),
                  PrepChip(label: '宿泊', state: prep.lodging),
                  if (aggregate.incompleteTodoCount > 0)
                    Chip(
                      avatar: const Icon(Icons.check_box_outlined, size: 16),
                      label: Text('Todo残り${aggregate.incompleteTodoCount}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (nextAction != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  '次にやる: ${nextAction.label}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _HeroImageManageCard(genba: genba),
      ],
    );
  }
}

/// 明示的な参加状態（§7.2 / design-spec §12.1）。日時から自動導出しない。
/// 「参戦済み」は attended を明示した場合のみ（§8/§10 の統計と一致）。
class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.genba});

  final Genba genba;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final busy = ref
        .watch(genbaActionsControllerProvider(genba.id))
        .contains(GenbaActionsController.attendanceKey);

    Future<void> setStatus(AttendanceStatus status) async {
      final failure = await ref
          .read(genbaActionsControllerProvider(genba.id).notifier)
          .setAttendanceStatus(genba, status);
      if (context.mounted) handleActionResult(context, failure);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参加状態',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
          if (genba.isCanceled)
            const Text('この現場は中止として記録されています。中止の取り消しは右上メニューから行えます。')
          else
            Wrap(
              spacing: AppSpace.sm,
              children: [
                for (final status in const [
                  AttendanceStatus.planned,
                  AttendanceStatus.attended,
                  AttendanceStatus.notAttended,
                ])
                  ChoiceChip(
                    label: Text(status.label),
                    selected: genba.attendanceStatus == status,
                    onSelected: busy ? null : (_) => setStatus(status),
                  ),
              ],
            ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '「参戦済み」にすると、思い出の絞り込みとマイ推しの参戦数に反映されます。',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTokens.of(context).textSecondary),
          ),
        ],
      ),
    );
  }
}

/// 状態操作（終演した／取消・訂正／思い出を記録する）。すべて
/// [GenbaActionsController] 経由で loading・二重タップ防止・型付き失敗表示を
/// 一貫させる（H-07/M-01）。
class _StatusActionsSection extends ConsumerWidget {
  const _StatusActionsSection({required this.genba, required this.status});

  final Genba genba;
  final GenbaStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(genbaActionsControllerProvider(genba.id))
        .contains(GenbaActionsController.endedKey);
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);

    Future<void> markEnded() async {
      final confirmed = await confirmAction(
        context,
        title: '終演した',
        message: '現在時刻で終演したことにします。「余韻中」に切り替わり、思い出の入力を案内します。',
        confirmLabel: '終演した',
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller().markEnded(genba);
      if (context.mounted) handleActionResult(context, failure);
    }

    Future<void> undoEnded() async {
      final confirmed = await confirmAction(
        context,
        title: '終演の取消',
        message: '手動で設定した終演を取り消し、予定の日時から状態を自動で判定し直します。',
        confirmLabel: '取り消す',
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller().undoMarkEnded(genba);
      if (context.mounted) handleActionResult(context, failure);
    }

    Future<void> correctEnded() async {
      final base =
          genba.manualEndedAt?.toLocal() ?? ref.read(clockProvider).now();
      final date = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (time == null || !context.mounted) return;
      final corrected =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final failure = await controller().correctEndedAt(genba, corrected);
      if (context.mounted) handleActionResult(context, failure);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genba.manualEndedAt != null) ...[
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    '手動で終演済みにしています'
                    '（${_formatDt(genba.manualEndedAt!.toLocal())}）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpace.xs,
            children: [
              TextButton.icon(
                onPressed: busy ? null : undoEnded,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('取り消す'),
              ),
              TextButton.icon(
                onPressed: busy ? null : correctEnded,
                icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                label: const Text('時刻を訂正'),
              ),
            ],
          ),
        ],
        if (status == GenbaStatus.today) ...[
          const SizedBox(height: AppSpace.md),
          OutlinedButton.icon(
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.flag_outlined, size: 18),
            label: const Text('終演した（余韻中にする）'),
            onPressed: busy ? null : markEnded,
          ),
        ],
        if (status == GenbaStatus.afterglow ||
            status == GenbaStatus.memory) ...[
          const SizedBox(height: AppSpace.md),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('思い出を記録する'),
            onPressed: () => context.push('/memories/${genba.id}/edit'),
          ),
        ],
      ],
    );
  }

  String _formatDt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

/// 現場ヒーロー画像の管理（端末内・同期対象外, H-04）。選択・差替え・削除。
/// チケット画像とは別用途で、ヒーローへ流用しない（design-spec §12）。
class _HeroImageManageCard extends ConsumerWidget {
  const _HeroImageManageCard({required this.genba});

  final Genba genba;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return;
    final store = ref.read(imageStoreProvider);
    String storedRef;
    try {
      storedRef = await store.import(
        ownerId: owner,
        category: ImageCategory.genbaHero,
        source: File(picked.path),
      );
    } on ImageStorageException catch (e) {
      if (context.mounted) {
        handleActionResult(
          context,
          StorageFailure(message: 'ヒーロー画像の保存に失敗しました', cause: e),
        );
      }
      return;
    }
    final failure = await ref
        .read(genbaActionsControllerProvider(genba.id).notifier)
        .setHeroImage(genba, storedRef);
    if (context.mounted) handleActionResult(context, failure);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(genbaActionsControllerProvider(genba.id).notifier)
        .removeHeroImage(genba);
    if (context.mounted) handleActionResult(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(genbaActionsControllerProvider(genba.id))
        .contains(GenbaActionsController.heroImageKey);
    final hasImage = genba.heroImageLocalPath != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '公演用画像',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'この現場の上部に表示する画像です（チケット画像は使われません）。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTokens.of(context).textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              TextButton.icon(
                onPressed: busy ? null : () => _pick(context, ref),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(hasImage ? '画像を差し替え' : 'ヒーロー画像を選択'),
              ),
              if (hasImage)
                TextButton.icon(
                  onPressed: busy ? null : () => _remove(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('画像を外す'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
