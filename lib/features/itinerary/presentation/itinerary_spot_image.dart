import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/image_status_provider.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';

/// スポットのユーザー画像を型付き状態（present / missing / inaccessible）で
/// 表示する共有ウィジェット（H-04 item3・R7 / Phase 2レビュー点6）。
///
/// - present: 実ファイルを [Image.file] で表示。代替テキスト（[Semantics] alt）に
///   施設名を含める（画像を読み上げ可能にする）。
/// - missing: 端末から削除された・参照が不正。「画像が見つかりません」を表示。
/// - inaccessible: 権限不足・ロック等で読めない。再試行ボタンで再判定する。
///
/// [imageRef] が null（未設定）のときは何も表示しない。保存に失敗した画像は
/// そもそも [imageRef] に載らない（import 失敗時に参照を確定しない）ため、
/// 「失敗した画像を保存済みとして表示する」ことはない。
class ItinerarySpotImage extends ConsumerWidget {
  const ItinerarySpotImage({
    super.key,
    required this.ownerId,
    required this.imageRef,
    required this.facilityName,
    this.size = 64,
  });

  final String ownerId;
  final String? imageRef;
  final String facilityName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = imageRef;
    if (r == null || ownerId.isEmpty) return const SizedBox.shrink();

    final status =
        ref.watch(imageAssetStatusProvider((ownerId: ownerId, ref: r)));
    switch (status) {
      case ImageAssetStatus.present:
        final file = ref.read(imageStoreProvider).tryResolveOwned(ownerId, r);
        if (file == null) {
          return _Placeholder(
            size: size,
            icon: Icons.broken_image_outlined,
            message: '画像が見つかりません',
            semanticsLabel: '$facilityName の画像は見つかりません',
          );
        }
        return Semantics(
          image: true,
          label: '$facilityName の画像',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // 実ファイルが読めても復号に失敗しうる（破損・種別不整合）ため、
              // その場合も「保存済み」に見せず読み込み不可の代替を出す。
              errorBuilder: (context, error, stack) => _Placeholder(
                size: size,
                icon: Icons.image_not_supported_outlined,
                message: '画像を読み込めません',
                semanticsLabel: '$facilityName の画像を読み込めません',
              ),
            ),
          ),
        );
      case ImageAssetStatus.missing:
        return _Placeholder(
          size: size,
          icon: Icons.broken_image_outlined,
          message: '画像が見つかりません',
          semanticsLabel: '$facilityName の画像は見つかりません',
        );
      case ImageAssetStatus.inaccessible:
        return _Placeholder(
          size: size,
          icon: Icons.lock_outline,
          message: '読み込めません',
          semanticsLabel: '$facilityName の画像を読み込めません（権限・ロック）',
          onRetry: () => ref.invalidate(
            imageAssetStatusProvider((ownerId: ownerId, ref: r)),
          ),
        );
    }
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.size,
    required this.icon,
    required this.message,
    required this.semanticsLabel,
    this.onRetry,
  });

  final double size;
  final IconData icon;
  final String message;
  final String semanticsLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ),
            if (onRetry != null)
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  '再試行',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
