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
                  Expanded(
                    child: Text(
                      '概要',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _EditPill(
                    onPressed: () => context.push('/genba/${genba.id}/edit'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      genba.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  GenbaStatusChip(status: status),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              _InfoRow(
                label: '日付',
                value:
                    '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}',
              ),
              _InfoRow(label: 'グループ', value: genba.artistName),
              if (genba.venue != null)
                _InfoRow(label: '会場', value: genba.venue!),
              if (genba.doorTimeMinutes != null ||
                  genba.startTimeMinutes != null ||
                  genba.endTimeMinutes != null)
                _InfoRow(
                  label: '開場 / 開演',
                  value: [
                    if (genba.doorTimeMinutes != null)
                      formatMinutes(genba.doorTimeMinutes!),
                    if (genba.startTimeMinutes != null)
                      formatMinutes(genba.startTimeMinutes!),
                    if (genba.endTimeMinutes != null)
                      '終演 ${formatMinutes(genba.endTimeMinutes!)}',
                  ].join(' / '),
                ),
              if (genba.performanceType != null)
                _InfoRow(
                  label: '種別',
                  // 「その他」で補足自由入力があればそれを、無ければラベルを表示。
                  value: genba.performanceType == PerformanceType.other &&
                          (genba.performanceTypeOther?.trim().isNotEmpty ??
                              false)
                      ? genba.performanceTypeOther!.trim()
                      : genba.performanceType!.label,
                ),
              _StatusActionsSection(genba: genba, status: status),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _TodoPreviewCard(aggregate: aggregate, now: now),
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
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpace.md),
              // Wrap ではなく常に等分割の Row にし、件数が3〜4件で
              // 変動しても最終行が左詰めにならないようにする。
              PrepStatusRow(
                tiles: [
                  if (aggregate.incompleteTodoCount > 0)
                    PrepStatusTile(
                      icon: Icons.check_box_outlined,
                      label: 'Todo',
                      value: '残り${aggregate.incompleteTodoCount}',
                      attention: true,
                      onTap: () =>
                          DefaultTabController.of(context).animateTo(1),
                    ),
                  // 持ち物はTodoとは別集計（対応状況）で常に表示する
                  // （§持ち物の準備ステータス）。
                  PrepStatusTile(
                    icon: Icons.backpack_outlined,
                    label: '持ち物',
                    value: prep.belonging.label,
                    attention: prep.belonging.needsAttention,
                    onTap: () => DefaultTabController.of(context).animateTo(1),
                  ),
                  PrepStatusTile(
                    icon: Icons.confirmation_number_outlined,
                    label: 'チケット',
                    value: prep.ticket.label,
                    attention: prep.ticket.needsAttention,
                    onTap: () => DefaultTabController.of(context).animateTo(2),
                  ),
                  PrepStatusTile(
                    icon: Icons.train_outlined,
                    label: '交通',
                    value: prep.transport.label,
                    attention: prep.transport.needsAttention,
                    onTap: () => DefaultTabController.of(context).animateTo(3),
                  ),
                  PrepStatusTile(
                    icon: Icons.hotel_outlined,
                    label: '宿泊',
                    value: prep.lodging.label,
                    attention: prep.lodging == CategoryPrepState.notRegistered,
                    onTap: () => DefaultTabController.of(context).animateTo(4),
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

/// 概要カード右上の小さな「編集」ピル（モックアップ準拠）。
class _EditPill extends StatelessWidget {
  const _EditPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: const Text('編集'),
    );
  }
}

/// 「ラベル: 値」の整った1行（モックアップの概要カード準拠）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// 概要タブ内の「やることリスト」プレビュー（モックアップ準拠）。
///
/// 直近の未完了を先頭に最大5件。チェックは楽観更新し、失敗時は
/// 実データへ戻して理由を示す（TodoTab と同じ扱い）。期限超過は
/// Error 色の「期限」表示で示す（色だけに依存しない, §14）。
class _TodoPreviewCard extends ConsumerStatefulWidget {
  const _TodoPreviewCard({required this.aggregate, required this.now});

  final GenbaAggregate aggregate;
  final DateTime now;

  @override
  ConsumerState<_TodoPreviewCard> createState() => _TodoPreviewCardState();
}

class _TodoPreviewCardState extends ConsumerState<_TodoPreviewCard> {
  final Map<String, bool> _optimistic = {};

  Future<void> _toggle(GenbaTodo todo, bool checked) async {
    setState(() => _optimistic[todo.id] = checked);
    final failure = await ref
        .read(
          genbaActionsControllerProvider(widget.aggregate.genba.id).notifier,
        )
        .toggleTodo(todo, checked);
    if (!mounted) return;
    setState(() => _optimistic.remove(todo.id));
    if (failure != null) handleActionResult(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    // 「やることリスト」プレビューはTodo種別のみ（持ち物は含めない。
    // 持ち物の状況はTodo・持ち物タブの専用セクションで確認する）。
    final todos = widget.aggregate.todos
        .where((t) => t.type == TodoItemType.todo)
        .toList(growable: false);
    final total = todos.length;
    final remaining = widget.aggregate.incompleteTodoCount;
    // 未完了（期限が近い順・期限なしは後ろ）→ 完了の順に並べ、先頭5件。
    final sorted = [...todos]..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        final ad = a.dueDate, bd = b.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    final preview = sorted.take(5).toList();
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'やることリスト',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: AppSpace.sm),
              if (total > 0)
                Text(
                  '未完了 $remaining/$total',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(1),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('すべて見る ›'),
              ),
            ],
          ),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(
                'Todoはまだありません。Todoタブから準備リストを作りましょう。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.textSecondary),
              ),
            )
          else
            for (final todo in preview)
              _TodoPreviewRow(
                todo: todo,
                checked: _optimistic[todo.id] ?? todo.isDone,
                overdue: !(_optimistic[todo.id] ?? todo.isDone) &&
                    todo.dueDate != null &&
                    todo.dueDate!.isBefore(today),
                onChanged: (v) => _toggle(todo, v),
              ),
        ],
      ),
    );
  }
}

class _TodoPreviewRow extends StatelessWidget {
  const _TodoPreviewRow({
    required this.todo,
    required this.checked,
    required this.overdue,
    required this.onChanged,
  });

  final GenbaTodo todo;
  final bool checked;
  final bool overdue;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final scheme = theme.colorScheme;
    final due = todo.dueDate;
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                todo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked
                      ? tokens.textSecondary
                      : overdue
                          ? scheme.error
                          : null,
                  fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                ),
                semanticsLabel: '${todo.name}、${checked ? '完了済み' : '未完了'}'
                    '${overdue ? '、期限超過' : ''}',
              ),
            ),
            if (due != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpace.sm),
                child: Text(
                  overdue
                      ? '期限: ${due.year}/${due.month}/${due.day}'
                      : '${due.year}/${due.month}/${due.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: overdue ? scheme.error : tokens.textSecondary,
                    fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
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
