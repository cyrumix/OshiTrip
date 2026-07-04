import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// アイコン・短いラベル・状態値を縦に表示する（design-spec §4/§6.2）。
///
/// ホームのヒーローカード下部の Todo/交通/宿泊/チケット 4分割などに使う。
/// 状態は色だけでなく値の文言でも示す（§14）。
class StatusIconItem extends StatelessWidget {
  const StatusIconItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.onSurface,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// 「3件」「未登録」「登録済み」等の短い状態値。
  final String value;

  /// 注意を引きたい状態（未登録・期限超過等）を太字で示す。
  final bool emphasized;

  /// 写真上など、面に合わせた文字色の明示指定。
  final Color? onSurface;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final fg = onSurface ?? theme.colorScheme.onSurface;
    final sub = onSurface?.withValues(alpha: 0.8) ?? tokens.textSecondary;
    final content = Semantics(
      label: '$label: $value',
      // ヒーローカード等の親ノードへマージされないよう境界を張る（§14）。
      container: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: AppSpace.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: sub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: content,
      ),
    );
  }
}
