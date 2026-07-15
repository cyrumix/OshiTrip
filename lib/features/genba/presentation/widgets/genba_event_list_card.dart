import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../home/presentation/widgets/genba_card.dart';
import '../../../oshi/application/oshi_providers.dart';
import '../../domain/genba.dart';
import '../../domain/genba_preparation.dart';
import '../../domain/genba_schedule.dart';

/// 現場1件の一覧カード（design-spec §6.3 / R7）。ホームの「今後の現場」と
/// 現場一覧タブで共用する。
///
/// - 日付・公演名・グループ・会場・残日数・推しカラー罫線（[EventListCard]）
/// - 状態（中止/予定/準備中/本日/余韻中）を文字＋アイコンで表示
/// - チケット/交通/宿泊/Todo の準備状態チップ
/// - 「次にやる」1アクション
class GenbaEventListCard extends ConsumerWidget {
  const GenbaEventListCard({
    super.key,
    required this.aggregate,
    required this.now,
    this.alwaysShowStatus = false,
    this.minimal = false,
  });

  final GenbaAggregate aggregate;
  final DateTime now;

  /// true: 状態チップを常に表示（現場一覧）。false: 中止のみ表示（ホームは
  /// 並び順とヒーローで文脈が伝わるため、チップは異常状態に限定する）。
  final bool alwaysShowStatus;

  /// true: 最小構成（日付・残日数・会場・公演名のみ）。準備状況や次アクションは
  /// 一覧に出さず現場詳細で確認する方針（HOMEの今後の現場）。
  final bool minimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    final scheme = Theme.of(context).colorScheme;
    final accent =
        resolveOshiAccent(ref, scheme, oshiGroupId: genba.oshiGroupId);
    final status = deriveGenbaStatus(genba, now);

    // 最小構成: 日付（曜日つき）・残日数・会場・公演名のみ。中止だけは
    // 安全上つねに明示する（誤って現地へ向かわないため）。
    if (minimal) {
      return EventListCard(
        minimal: true,
        title: genba.title,
        dateLabel: formatEventDate(genba.eventDate),
        venue: genba.venue,
        daysUntil: daysUntil(genba, now),
        accentColor: accent,
        onTap: () => context.push('/genba/${genba.id}'),
        statusChips: [
          if (status == GenbaStatus.canceled) GenbaStatusChip(status: status),
        ],
      );
    }

    final prep = GenbaPreparation.of(aggregate);
    final nextAction = deriveNextAction(aggregate, now);

    return EventListCard(
      title: genba.title,
      subtitle: genba.artistName,
      dateLabel: [
        formatEventDate(genba.eventDate),
        if (genba.startTimeMinutes != null)
          '${formatMinutes(genba.startTimeMinutes!)}開演',
      ].join('・'),
      venue: genba.venue,
      daysUntil: daysUntil(genba, now),
      accentColor: accent,
      onTap: () => context.push('/genba/${genba.id}'),
      // 券面の状態バッジ（会場の下）。中止は安全上つねに明示。
      statusChips: [
        if (alwaysShowStatus || status == GenbaStatus.canceled)
          GenbaStatusChip(status: status),
      ],
      // 半券の準備タイル。並び順は固定: Todo → 持ち物 → チケット → 交通 → 宿泊。
      prepTiles: [
        TodoPrepChip(
          total:
              aggregate.todos.where((t) => t.type == TodoItemType.todo).length,
          remaining: aggregate.incompleteTodoCount,
        ),
        BelongingPrepChip(state: prep.belonging),
        PrepChip(label: 'チケット', state: prep.ticket),
        PrepChip(label: '交通', state: prep.transport),
        PrepChip(label: '宿泊', state: prep.lodging),
      ],
      // タイル列の直下に全幅1行で「次にやる」を出す。
      nextAction: nextAction == null
          ? null
          : _NextActionBar(
              // 文言は既存ロジック（deriveNextAction）の表示文字をそのまま使う。
              label: '次にやる: ${nextAction.label}',
              onTap: () => context.push('/genba/${genba.id}'),
            ),
    );
  }
}

/// 「次にやる」全幅バー（半券タイル列の直下・1行・省略）。淡紫の面に矢印＋
/// 次の1アクション文言を出して誘導する。文言は呼び出し側の既存ロジックに従う。
class _NextActionBar extends StatelessWidget {
  const _NextActionBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      container: true,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              color: tokens.primarySoft,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
