import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// セクション見出し（design-spec §4）。見出し＋件数＋右側アクション。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.xl,
      AppSpace.lg,
      AppSpace.sm,
    ),
  });

  final String title;

  /// 件数（null なら非表示）。
  final int? count;

  /// 右側アクション（例: 「追加」ボタン）。
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                children: [
                  if (count != null)
                    TextSpan(
                      text: '　$count件',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: tokens.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
