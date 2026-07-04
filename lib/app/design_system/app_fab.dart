import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 共通FAB（HOME刷新デザイン案）。
///
/// 「＋」アイコンのみの正方形寄り角丸。菫のグラデーション面に、下端へ
/// かすかな暁の縁光をにじませる（夜明けの光＝これから増える現場の予感）。
/// 中身は [FloatingActionButton] のままなのでタップ領域・Semantics・
/// Tooltip の挙動は標準どおり。
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.heroTag,
    this.icon = Icons.add,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final Object? heroTag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    const radius = 19.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroGradientEnd, tokens.heroGradientMid],
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.heroGradientMid.withValues(alpha: .4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          // 下端の暁の縁光。
          BoxShadow(
            color: tokens.dawn.withValues(alpha: .45),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(icon),
      ),
    );
  }
}
