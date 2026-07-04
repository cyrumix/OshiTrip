import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 現場数・思い出数・参戦数などの数値表示（design-spec §4/§10）。
///
/// 数値は保存済みデータからの導出値を渡す（固定ダミーを渡さない, §12.1）。
class CountStat extends StatelessWidget {
  const CountStat({
    super.key,
    required this.value,
    required this.label,
    this.semanticsLabel,
  });

  final int value;
  final String label;

  /// 読み上げ用（例: 「参戦数 3件（参加を明示した現場のみ）」）。
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Semantics(
      label: semanticsLabel ?? '$label $value件',
      // カード等の親ノードへマージされず、統計1件ごとに独立した
      // 読み上げノードになるよう境界を張る（§14）。
      container: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: tokens.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
