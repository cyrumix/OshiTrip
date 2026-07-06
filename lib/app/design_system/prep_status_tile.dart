import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';

/// 準備状況（Todo/交通/宿泊/チケット等）を示す白タイル（デザイン刷新）。
///
/// [PrepStatusRow] で複数並べると、Wrap特有の「最終行が左に寄って
/// 余白が偏る」見た目を避け、常に等分割で揃った印象になる。
class PrepStatusTile extends StatelessWidget {
  const PrepStatusTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.attention = false,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;

  /// 「未登録」「準備中」「残り3件」等の短い状態値。
  final String value;

  /// 注意を引きたい状態（未登録・期限超過等）を強調する。
  final bool attention;
  final VoidCallback? onTap;

  /// タイル数が多い（5件以上）場合に、崩れないよう一段詰めた見た目にする
  /// （[PrepStatusRow] が件数に応じて渡す）。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final circleSize = compact ? 28.0 : 34.0;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 2 : AppSpace.xs,
        vertical: compact ? AppSpace.sm : AppSpace.md,
      ),
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.primarySoft,
              ),
              child: Icon(icon, size: compact ? 15 : 18, color: scheme.primary),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textSecondary,
                fontSize: compact ? 10 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: attention ? FontWeight.w800 : FontWeight.w600,
                color: attention ? scheme.primary : scheme.onSurface,
                fontSize: compact ? 10.5 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// [PrepStatusTile] を常に等分割の1行へ並べる（§4）。
/// 件数に関わらず Row + Expanded で均等配置し、Wrap の折り返し時に
/// 最終行が左詰めになる問題を避ける。5件以上ではタイル自体も一段詰めて
/// 崩れないようにする（§レイアウトが5項目になっても崩れないよう調整）。
class PrepStatusRow extends StatelessWidget {
  const PrepStatusRow({super.key, required this.tiles});

  final List<PrepStatusTile> tiles;

  @override
  Widget build(BuildContext context) {
    final compact = tiles.length >= 5;
    final gap = compact ? AppSpace.xs : AppSpace.sm;
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: compact
                ? PrepStatusTile(
                    icon: tiles[i].icon,
                    label: tiles[i].label,
                    value: tiles[i].value,
                    attention: tiles[i].attention,
                    onTap: tiles[i].onTap,
                    compact: true,
                  )
                : tiles[i],
          ),
        ],
      ],
    );
  }
}
