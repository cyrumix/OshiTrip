import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_tokens.dart';
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tile in [
                    TodoPrepChip(
                      total: aggregate.todos
                          .where((t) => t.type == TodoItemType.todo)
                          .length,
                      remaining: aggregate.incompleteTodoCount,
                    ),
                    BelongingPrepChip(state: prep.belonging),
                    PrepChip(label: 'チケット', state: prep.ticket),
                    PrepChip(label: '交通', state: prep.transport),
                    PrepChip(label: '宿泊', state: prep.lodging),
                  ])
                    Expanded(child: tile),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
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

/// 準備タイルの見た目段階。状態は必ず文字でも伝え、色は補助にする（§15.4）。
enum _PrepTier {
  /// 未登録（気づいてほしい）: ローズ系の状態文字＋淡ピンクのアイコン。
  attention,

  /// 準備中・未対応・残りあり: 無彩。
  progress,

  /// 準備OK・完了: 紫のアイコン＋紫文字。
  done,

  /// 不要: 最も控えめな無彩。
  muted,
}

/// 半券（チケット下部）に**等幅**で並べる準備タイル。
/// アイコン（上）→ ラベル → 状態 の縦積みで、モックの「均等な準備欄」を再現する。
/// [EventListCard] 側で各タイルを Expanded 化するため、自身は幅を主張しない。
class _PrepTile extends StatelessWidget {
  const _PrepTile({
    required this.icon,
    required this.label,
    required this.state,
    required this.tier,
  });

  final IconData icon;
  final String label;
  final String state;
  final _PrepTier tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final (Color iconColor, Color stateColor) = switch (tier) {
      _PrepTier.done => (scheme.primary, scheme.primary),
      _PrepTier.progress => (scheme.onSurfaceVariant, scheme.onSurfaceVariant),
      // 未登録: アイコンは淡ピンク（装飾）。状態文字は彩度を落として AA を確保。
      _PrepTier.attention => (
          tokens.favorite,
          Color.lerp(tokens.favorite, scheme.onSurface, .30)!,
        ),
      _PrepTier.muted => (tokens.textSecondary, tokens.textSecondary),
    };
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10.5,
      height: 1.1,
      color: tokens.textSecondary,
    );
    final stateStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 10.5,
      height: 1.1,
      fontWeight: FontWeight.w700,
      color: stateColor,
    );
    return Semantics(
      label: '$label: $state',
      container: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            state,
            style: stateStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Todoの準備状態チップ（未登録/残りN/完了）。持ち物とは別集計（§集計）。
class TodoPrepChip extends StatelessWidget {
  const TodoPrepChip({
    super.key,
    required this.total,
    required this.remaining,
  });

  /// 種別=Todo の総数。
  final int total;

  /// 未完了の件数。
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final (String state, _PrepTier tier) = total == 0
        ? ('未登録', _PrepTier.attention)
        : remaining > 0
            ? ('残り$remaining', _PrepTier.progress)
            : ('完了', _PrepTier.done);
    return _PrepTile(
      icon: Icons.check_box_outlined,
      label: 'Todo',
      state: state,
      tier: tier,
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
    // カテゴリが一目で分かるアイコン（チケット/交通/宿泊）。
    final icon = switch (label) {
      'チケット' => Icons.confirmation_number_outlined,
      '交通' => Icons.train_outlined,
      '宿泊' => Icons.hotel_outlined,
      _ => Icons.event_note_outlined,
    };
    final tier = switch (state) {
      CategoryPrepState.ready => _PrepTier.done,
      CategoryPrepState.inProgress => _PrepTier.progress,
      CategoryPrepState.notRegistered => _PrepTier.attention,
      CategoryPrepState.notRequired => _PrepTier.muted,
    };
    return _PrepTile(
      icon: icon,
      label: label,
      state: state.label,
      tier: tier,
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
    final tier = switch (state) {
      BelongingPrepState.ready => _PrepTier.done,
      BelongingPrepState.pending => _PrepTier.progress,
      BelongingPrepState.notRegistered => _PrepTier.attention,
    };
    return _PrepTile(
      icon: Icons.backpack_outlined,
      label: '持ち物',
      state: state.label,
      tier: tier,
    );
  }
}
