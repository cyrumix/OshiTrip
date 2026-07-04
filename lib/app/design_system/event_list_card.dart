import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';

/// 今後の現場カード（design-spec §4/§6.3）。
///
/// 左側の推しカラー罫線・日付・会場・公演名・残日数を持つ。
/// 推しカラーは罫線のみ（本文の可読性を壊さない, §2）。
class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.accentColor,
    this.subtitle,
    this.venue,
    this.daysUntil,
    this.statusChips = const <Widget>[],
    this.footer,
    this.onTap,
  });

  final String title;

  /// アーティスト名など。
  final String? subtitle;
  final String dateLabel;
  final String? venue;

  /// 残日数（null = 非表示。過去は負値で「n日前」）。
  final int? daysUntil;

  /// 推しカラー罫線（推し未設定時はユーザーの推しカラー等のフォールバック）。
  final Color accentColor;

  /// 準備状態チップ等。
  final List<Widget> statusChips;

  /// 「次にやる」等の下部要素。
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final days = daysUntil;
    final daysText = days == null
        ? null
        : days == 0
            ? '本日'
            : days > 0
                ? 'あと$days日'
                : '${-days}日前';
    final daysSemantics = days == null
        ? null
        : days == 0
            ? '公演は本日です'
            : days > 0
                ? '公演まであと$days日'
                : '公演から${-days}日経過';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 推しカラーの左罫線（§2: 小面積アクセント）。
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                        ),
                        if (daysText != null)
                          Text(
                            daysText,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            semanticsLabel: daysSemantics,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (venue != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        venue!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (statusChips.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.xs,
                        children: statusChips,
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
