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
  });

  final GenbaAggregate aggregate;
  final DateTime now;

  /// true: 状態チップを常に表示（現場一覧）。false: 中止のみ表示（ホームは
  /// 並び順とヒーローで文脈が伝わるため、チップは異常状態に限定する）。
  final bool alwaysShowStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    final scheme = Theme.of(context).colorScheme;
    final accent =
        resolveOshiAccent(ref, scheme, oshiGroupId: genba.oshiGroupId);
    final status = deriveGenbaStatus(genba, now);
    final prep = GenbaPreparation.of(aggregate);
    final nextAction = deriveNextAction(aggregate, now);

    return EventListCard(
      title: genba.title,
      subtitle: genba.artistName,
      dateLabel: [
        '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}',
        if (genba.startTimeMinutes != null)
          '${formatMinutes(genba.startTimeMinutes!)}開演',
      ].join('・'),
      venue: genba.venue,
      daysUntil: daysUntil(genba, now),
      accentColor: accent,
      onTap: () => context.push('/genba/${genba.id}'),
      statusChips: [
        if (alwaysShowStatus || status == GenbaStatus.canceled)
          GenbaStatusChip(status: status),
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
      footer: nextAction == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.arrow_forward, size: 16),
                label: Text('次にやる: ${nextAction.label}'),
                onPressed: () => context.push('/genba/${genba.id}'),
              ),
            ),
    );
  }
}
