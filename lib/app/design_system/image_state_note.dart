import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 画像の異常状態（見つからない・読み込めない・権限喪失など）を、装飾用
/// プレースホルダーと区別して明示する小さなノート（design-spec §12 / R7）。
///
/// 写真上・プレースホルダー上のどちらでも読めるよう暗めの面に白文字で載せる。
/// 状態はアイコン＋文言で示し、色だけに依存しない（§14）。ユーザーが対応
/// できる場合は [action]（再試行・画像の再選択など）を添える。
class ImageStateNote extends StatelessWidget {
  const ImageStateNote({
    super.key,
    required this.message,
    this.icon = Icons.image_not_supported_outlined,
    this.action,
  });

  final String message;
  final IconData icon;

  /// 再試行・再選択などの導線（任意）。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: ExcludeSemantics(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpace.xs),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
