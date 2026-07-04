import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'favorite_button.dart';
import 'image_state_note.dart';

/// 思い出カード（design-spec §4/§8）。
///
/// 表紙サムネイル・日付・公演名・会場・記録件数・お気に入りを表示する。
/// 写真がない場合は推しカラーと公演情報のプレースホルダーへ縮退する。
class PhotoMemoryCard extends StatelessWidget {
  const PhotoMemoryCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.accentColor,
    this.subtitle,
    this.venue,
    this.coverFile,
    this.coverAltText,
    this.coverUnavailableNote,
    this.photoCount = 0,
    this.setlistCount = 0,
    this.hasImpression = false,
    this.attendedLabel,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.emptyHint,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String dateLabel;
  final String? venue;

  /// 表紙写真（`MemoryPhoto.isCover` 優先の解決済みファイル）。
  final File? coverFile;
  final String? coverAltText;

  /// 表紙が設定されているのに表示できない理由（端末から削除・権限喪失など）。
  /// 非null のときプレースホルダー上に明示し、「写真なし」と区別する（§12）。
  final String? coverUnavailableNote;
  final int photoCount;
  final int setlistCount;
  final bool hasImpression;

  /// 「参戦済み」等の明示参加ラベル（attended のときのみ渡す, §8）。
  final String? attendedLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  /// 写真なしプレースホルダーの推しカラー。
  final Color accentColor;

  /// 記録がまだ無い場合の誘導（例: 「記録を残す」ボタン）。
  final Widget? emptyHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: coverFile != null
                    ? Semantics(
                        image: true,
                        label: coverAltText ?? '$titleの表紙写真',
                        child: Image.file(
                          coverFile!,
                          fit: BoxFit.cover,
                          // 読み込み失敗は placeholder だけで隠さない（§12）。
                          errorBuilder: (_, __, ___) => Stack(
                            fit: StackFit.expand,
                            children: [
                              _Placeholder(accent: accentColor, title: title),
                              const Positioned(
                                left: AppSpace.sm,
                                bottom: AppSpace.sm,
                                child: ImageStateNote(
                                  message: '表紙を読み込めませんでした',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          _Placeholder(accent: accentColor, title: title),
                          if (coverUnavailableNote != null)
                            Positioned(
                              left: AppSpace.sm,
                              bottom: AppSpace.sm,
                              child: ImageStateNote(
                                message: coverUnavailableNote!,
                              ),
                            ),
                        ],
                      ),
              ),
              // お気に入りは右上（§8）。写真上でも押せるよう面を敷く。
              Positioned(
                top: AppSpace.xs,
                right: AppSpace.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: FavoriteButton(
                    isFavorite: isFavorite,
                    onPressed: onFavoriteToggle,
                    subjectLabel: title,
                  ),
                ),
              ),
              if (attendedLabel != null)
                Positioned(
                  left: AppSpace.sm,
                  top: AppSpace.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      attendedLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                if (venue != null)
                  Text(venue!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    if (photoCount > 0)
                      _CountIcon(
                        icon: Icons.photo_outlined,
                        text: '$photoCount',
                        semantics: '写真$photoCount枚',
                      ),
                    if (setlistCount > 0)
                      _CountIcon(
                        icon: Icons.queue_music,
                        text: '$setlistCount曲',
                        semantics: 'セトリ$setlistCount曲',
                      ),
                    if (hasImpression)
                      const _CountIcon(
                        icon: Icons.edit_note_outlined,
                        text: '感想',
                        semantics: '感想あり',
                      ),
                    const Spacer(),
                    if (emptyHint != null) emptyHint!,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountIcon extends StatelessWidget {
  const _CountIcon({
    required this.icon,
    required this.text,
    required this.semantics,
  });

  final IconData icon;
  final String text;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      label: semantics,
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpace.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tokens.textSecondary),
            const SizedBox(width: 2),
            Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 写真なしプレースホルダー（§8: 推しカラー＋公演情報。権利不明画像を使わない）。
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.accent, required this.title});

  final Color accent;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.25),
            tokens.primarySoft,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_outlined,
          size: 40,
          color: accent.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
