import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// お気に入りボタン（design-spec §4）。
///
/// 状態をハートの形（塗り/輪郭）とラベル・Semantics で表現し、色だけに
/// 依存しない（§14）。失敗時のロールバックは呼び出し側の責務
/// （即時反映→失敗で戻す, §13）。
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.subjectLabel = 'お気に入り',
  });

  final bool isFavorite;
  final VoidCallback? onPressed;

  /// 対象の名称（読み上げ: 「〈対象〉をお気に入りに追加/から外す」）。
  final String subjectLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final tooltip =
        isFavorite ? '$subjectLabelをお気に入りから外す' : '$subjectLabelをお気に入りに追加';
    return Semantics(
      // トグルの現在状態を読み上げへ含める。
      toggled: isFavorite,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        isSelected: isFavorite,
        selectedIcon: Icon(Icons.favorite, color: tokens.favorite),
        icon: const Icon(Icons.favorite_outline),
      ),
    );
  }
}
