import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';

/// 今後の現場カード（design-spec §4/§6.3）。
///
/// 左側の推しカラー罫線・日付・会場・公演名・残日数を持つ。
/// 推しカラーは罫線のみ（本文の可読性を壊さない, §2）。
///
/// [minimal] = true のときは「日付＋残日数 → 会場 → 公演名（見出し）」だけの
/// 最小構成にする（HOMEの今後の現場: 準備状況や次アクションは詳細画面で確認
/// する方針。副題・チップ本文などのノイズを一覧から排し、編集的な階層を作る）。
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
    this.minimal = false,
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

  /// 最小構成（会場→公演名のみ、副題・フッターを出さない）。
  final bool minimal;

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
    // 残7日以内は「近づく夜明け」として温度を上げる（推しカラー×暁のピル）。
    final isSoon = days != null && days > 0 && days <= 7;

    final daysWidget = daysText == null
        ? null
        : isSoon
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: .20),
                      tokens.dawn.withValues(alpha: .26),
                    ],
                  ),
                ),
                child: Text(
                  daysText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF7A2C4E)
                        : const Color(0xFFFFD9E6),
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  semanticsLabel: daysSemantics,
                ),
              )
            : Text(
                daysText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                semanticsLabel: daysSemantics,
              );

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 推しカラーの灯芯（左端に浮かぶ小さなロウソクの芯, §2）。
          Positioned(
            left: 9,
            top: AppSpace.lg,
            bottom: AppSpace.lg,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: .45),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              AppSpace.lg - 2,
              AppSpace.lg,
              AppSpace.lg - 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: tokens.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (daysWidget != null) daysWidget,
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                if (minimal) ...[
                  // 会場（文脈）→ 公演名（見出し）の編集的な階層（§3）。
                  if (venue != null)
                    Text(
                      venue!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: tokens.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (statusChips.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: statusChips,
                    ),
                  ],
                ] else ...[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
