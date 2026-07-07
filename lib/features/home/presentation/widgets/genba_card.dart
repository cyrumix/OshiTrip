import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../genba/domain/genba.dart';
import '../../../genba/domain/genba_preparation.dart';
import '../../../genba/domain/genba_schedule.dart';

/// 通常ホーム/現場一覧の現場カード（§6.1）。
///
/// カード全体を警告色にせず、未準備項目ごとに状態チップで示す。
class GenbaCard extends StatelessWidget {
  const GenbaCard({super.key, required this.aggregate, required this.now});

  final GenbaAggregate aggregate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genba = aggregate.genba;
    final status = deriveGenbaStatus(genba, now);
    final prep = GenbaPreparation.of(aggregate);
    final nextAction = deriveNextAction(aggregate, now);
    final days = daysUntil(genba, now);

    return Card(
      child: InkWell(
        onTap: () => context.push('/genba/${genba.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GenbaStatusChip(status: status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      genba.artistName,
                      style: theme.textTheme.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    days == 0
                        ? '本日'
                        : days > 0
                            ? 'あと$days日'
                            : '${-days}日前',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    semanticsLabel: days == 0
                        ? '公演は本日です'
                        : days > 0
                            ? '公演まであと$days日'
                            : '公演から${-days}日経過',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(genba.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                [
                  _formatDate(genba.eventDate),
                  if (genba.startTimeMinutes != null)
                    '${formatMinutes(genba.startTimeMinutes!)}開演',
                  if (genba.venue != null) genba.venue!,
                ].join('・'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (aggregate.incompleteTodoCount > 0)
                    Chip(
                      avatar: const Icon(Icons.check_box_outlined, size: 16),
                      label: Text('Todo残り${aggregate.incompleteTodoCount}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  BelongingPrepChip(state: prep.belonging),
                  PrepChip(label: 'チケット', state: prep.ticket),
                  PrepChip(label: '交通', state: prep.transport),
                  PrepChip(label: '宿泊', state: prep.lodging),
                ],
              ),
              if (nextAction != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.arrow_forward, size: 16),
                    label: Text('次にやる: ${nextAction.label}'),
                    onPressed: () => context.push('/genba/${genba.id}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}/${d.month}/${d.day}';
}

/// 現場状態チップ。色だけに依存せず文字＋アイコンでも状態を示す（§15.4/§14）。
class GenbaStatusChip extends StatelessWidget {
  const GenbaStatusChip({super.key, required this.status});

  final GenbaStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      GenbaStatus.today => (scheme.primary, scheme.onPrimary),
      GenbaStatus.afterglow => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      GenbaStatus.canceled => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    final icon = switch (status) {
      GenbaStatus.scheduled => Icons.event_outlined,
      GenbaStatus.preparing => Icons.hourglass_bottom,
      GenbaStatus.today => Icons.celebration_outlined,
      GenbaStatus.afterglow => Icons.nightlight_outlined,
      GenbaStatus.memory => Icons.photo_album_outlined,
      GenbaStatus.canceled => Icons.block,
    };
    return Semantics(
      label: '状態: ${status.label}',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// 準備状態チップ（不要/未登録/準備中/準備OK をアイコン+文字で表現）。
class PrepChip extends StatelessWidget {
  const PrepChip({super.key, required this.label, required this.state});

  final String label;
  final CategoryPrepState state;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      CategoryPrepState.ready => Icons.check_circle_outline,
      CategoryPrepState.inProgress => Icons.hourglass_bottom,
      CategoryPrepState.notRegistered => Icons.radio_button_unchecked,
      CategoryPrepState.notRequired => Icons.remove_circle_outline,
    };
    return Semantics(
      label: '$label: ${state.label}',
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text('$label ${state.label}'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// 持ち物の準備状態チップ（未登録/未対応/準備OK）。Todoの残数表示とは別集計
/// なので、[PrepChip]（チケット/交通/宿泊用）とは別の状態型を受け取る。
class BelongingPrepChip extends StatelessWidget {
  const BelongingPrepChip({super.key, required this.state});

  final BelongingPrepState state;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      BelongingPrepState.ready => Icons.check_circle_outline,
      BelongingPrepState.pending => Icons.hourglass_bottom,
      BelongingPrepState.notRegistered => Icons.radio_button_unchecked,
    };
    return Semantics(
      label: '持ち物: ${state.label}',
      child: Chip(
        avatar: Icon(icon, size: 16),
        label: Text('持ち物 ${state.label}'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
