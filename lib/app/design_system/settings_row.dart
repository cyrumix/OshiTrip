import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 設定行（design-spec §4/§11）。アイコン・項目名・現在値・遷移矢印。
///
/// 危険操作は [destructive] で通常項目と視覚的に分離する（Error 色 + 文言）。
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;

  /// 現在値（例: 「ライト」「ピンク」）。
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final fg = destructive ? scheme.error : scheme.onSurface;
    return ListTile(
      // アイコンは淡い円形の面に載せる（デザイン刷新: カード型の統一感）。
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: destructive ? scheme.errorContainer : tokens.primarySoft,
        ),
        child: Icon(
          icon,
          size: 20,
          color: destructive ? scheme.error : scheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          if (onTap != null && showChevron) ...[
            const SizedBox(width: AppSpace.xs),
            Icon(Icons.chevron_right, color: tokens.textSecondary),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
