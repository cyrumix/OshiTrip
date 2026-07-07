import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 共通FAB（デザイン刷新）。
///
/// 「＋」アイコンのみの円形。菫のグラデーション面＋やわらかい紫の影で
/// 画面に浮かべる。中身は [FloatingActionButton] のままなので
/// タップ領域・Semantics・Tooltip の挙動は標準どおり。
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
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.heroGradientMid.withValues(alpha: .38),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
        shape: const CircleBorder(),
        child: Icon(icon, size: 26),
      ),
    );
  }
}
