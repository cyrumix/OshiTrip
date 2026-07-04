import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// カードの見た目バリエーション（design-spec §4）。
enum AppCardVariant { standard, warning }

/// 標準カード（design-spec §4）。
///
/// 影は控えめにし、背景差＋1pxの境界で階層を表現する。押下可能な場合は
/// [onTap] を渡す（InkWell のフィードバック付き）。警告カードは
/// [AppCardVariant.warning]（Error 系の面・紫で代用しない）。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.standard,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.margin = EdgeInsets.zero,
    this.color,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// 面の色の明示指定（例: Primary Light の淡紫カード）。
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    final (surface, border) = switch (variant) {
      AppCardVariant.warning => (
          scheme.errorContainer,
          scheme.error.withValues(alpha: 0.4),
        ),
      AppCardVariant.standard => (color ?? scheme.surface, tokens.divider),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: border),
    );
    return Padding(
      padding: margin,
      child: Material(
        color: surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            // タップ操作をこのカードのノードに閉じ込める（親カードや隣接
            // 要素と1つの巨大な読み上げノードへマージさせない, §14）。
            : Semantics(
                container: true,
                button: true,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(padding: padding, child: child),
                ),
              ),
      ),
    );
  }
}
