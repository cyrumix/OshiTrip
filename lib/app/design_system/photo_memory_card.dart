import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'favorite_button.dart';
import 'image_state_note.dart';

/// 思い出カード＝半券（design-spec §4/§8・一覧刷新 D-252）。
///
/// 終わった現場の「切り取った半券」。表紙写真の有無で2形態を持つ:
/// - **表紙写真あり**: 写真を主役に見せ、ミシン目の下へ日付・公演名・会場・記録件数の
///   メタ帯（半券）を置く。
/// - **表紙写真なし**: 推しカラーのアクセントと公演情報で構成した「券面」を見せる。
///   灰色の汎用プレースホルダー画像は使わない。
///
/// 表紙が設定されているのに表示できない場合（端末から削除・権限喪失など）は
/// 「写真なし」と区別して理由を明示する（§12）。
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
  /// 非null のとき券面上に明示し、「写真なし」と区別する（§12）。
  final String? coverUnavailableNote;
  final int photoCount;
  final int setlistCount;
  final bool hasImpression;

  /// 「参戦済み」等の明示参加ラベル（attended のときのみ渡す, §8）。
  final String? attendedLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  /// 券面（写真なし）・写真デコード失敗時の推しカラー。
  final Color accentColor;

  /// 記録がまだ無い場合の誘導（例: 「記録を残す」ボタン）。
  final Widget? emptyHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: coverFile != null ? _photoForm(context) : _ticketFaceForm(context),
    );
  }

  /// 表紙写真あり: 写真ヒーロー → ミシン目 → 半券メタ帯。
  Widget _photoForm(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 168,
              width: double.infinity,
              child: Semantics(
                image: true,
                label: coverAltText ?? '$titleの表紙写真',
                child: Image.file(
                  coverFile!,
                  fit: BoxFit.cover,
                  // 読み込み失敗は灰色で隠さず、推しカラー面＋理由で示す（§12）。
                  errorBuilder: (_, __, ___) => Stack(
                    fit: StackFit.expand,
                    children: [
                      _AccentWash(accent: accentColor),
                      const Positioned(
                        left: AppSpace.sm,
                        bottom: AppSpace.sm,
                        child: ImageStateNote(message: '表紙を読み込めませんでした'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 写真の下端を少し暗く落として、白字バッジの視認性を確保する。
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpace.xs,
              right: AppSpace.xs,
              child: _FavoriteBubble(
                isFavorite: isFavorite,
                onToggle: onFavoriteToggle,
                subject: title,
              ),
            ),
            if (attendedLabel != null)
              Positioned(
                left: AppSpace.sm,
                top: AppSpace.sm,
                child: _AttendedBadge(label: attendedLabel!),
              ),
          ],
        ),
        _MemoryPerforation(
          notchColor: tokens.backgroundBottom,
          dashColor: tokens.divider,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.primarySoft.withValues(alpha: .18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: _MetaBlock(
              title: title,
              subtitle: subtitle,
              dateLabel: dateLabel,
              venue: venue,
              photoCount: photoCount,
              setlistCount: setlistCount,
              hasImpression: hasImpression,
              emptyHint: emptyHint,
              dateEmphasized: false,
            ),
          ),
        ),
      ],
    );
  }

  /// 表紙写真なし: 券面（アクセント＋公演情報）。灰色プレースホルダーは使わない。
  Widget _ticketFaceForm(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Stack(
      children: [
        // 面: 白〜淡紫のごく控えめな斜めグラデーション（券面の紙面）。
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    tokens.primarySoft.withValues(alpha: .28),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: AppSpace.md,
          bottom: AppSpace.md,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accentColor, accentColor.withValues(alpha: .40)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            22,
            AppSpace.lg - 2,
            AppSpace.xs,
            AppSpace.lg - 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _MetaBlock(
                    title: title,
                    subtitle: subtitle,
                    dateLabel: dateLabel,
                    venue: venue,
                    photoCount: photoCount,
                    setlistCount: setlistCount,
                    hasImpression: hasImpression,
                    emptyHint: emptyHint,
                    dateEmphasized: true,
                    attendedLabel: attendedLabel,
                    // 表紙が「あるはずが表示不可」の理由（写真なしと区別, §12）。
                    unavailableNote: coverUnavailableNote,
                  ),
                ),
              ),
              _FavoriteBubble(
                isFavorite: isFavorite,
                onToggle: onFavoriteToggle,
                subject: title,
                plain: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// カード本文（日付・公演名・アーティスト・会場・記録件数）。写真あり=メタ帯、
/// 写真なし=券面本文の両方で使う。
class _MetaBlock extends StatelessWidget {
  const _MetaBlock({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.venue,
    required this.photoCount,
    required this.setlistCount,
    required this.hasImpression,
    required this.emptyHint,
    required this.dateEmphasized,
    this.attendedLabel,
    this.unavailableNote,
  });

  final String title;
  final String? subtitle;
  final String dateLabel;
  final String? venue;
  final int photoCount;
  final int setlistCount;
  final bool hasImpression;
  final Widget? emptyHint;

  /// true: 券面（日付を推しカラーで強調）。false: 半券メタ帯（従属）。
  final bool dateEmphasized;

  /// 券面フォームでのみ本文に含める参戦バッジ。
  final String? attendedLabel;
  final String? unavailableNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: dateEmphasized
                ? theme.colorScheme.primary
                : tokens.textSecondary,
            fontWeight: dateEmphasized ? FontWeight.w600 : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: tokens.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (venue != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 13, color: tokens.textSecondary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  venue!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (unavailableNote != null) ...[
          const SizedBox(height: AppSpace.sm),
          ImageStateNote(message: unavailableNote!),
        ],
        const SizedBox(height: AppSpace.sm),
        // バッジ・記録件数は Wrap で折り返す（文字200%でも溢れない, §14）。
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (attendedLabel != null) _AttendedBadge(label: attendedLabel!),
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
          ],
        ),
        if (emptyHint != null)
          Align(alignment: Alignment.centerLeft, child: emptyHint!),
      ],
    );
  }
}

/// 参戦済みバッジ（推しカラー面＋白字）。
class _AttendedBadge extends StatelessWidget {
  const _AttendedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// お気に入りボタン。写真の上では半透明の丸面を敷いて押しやすくする。
class _FavoriteBubble extends StatelessWidget {
  const _FavoriteBubble({
    required this.isFavorite,
    required this.onToggle,
    required this.subject,
    this.plain = false,
  });

  final bool isFavorite;
  final VoidCallback? onToggle;
  final String subject;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final button = FavoriteButton(
      isFavorite: isFavorite,
      onPressed: onToggle,
      subjectLabel: subject,
    );
    if (plain) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: button,
    );
  }
}

/// 推しカラーのウォッシュ（写真デコード失敗時の背景。灰色にしない, §12）。
class _AccentWash extends StatelessWidget {
  const _AccentWash({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.25), tokens.primarySoft],
        ),
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

/// 写真と半券メタ帯の境界（左右両端の半円ノッチ＋破線）。ノッチはカード背後の
/// 背景色で塗って「切り込み」に見せる。
class _MemoryPerforation extends StatelessWidget {
  const _MemoryPerforation({required this.notchColor, required this.dashColor});

  final Color notchColor;
  final Color dashColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      width: double.infinity,
      child: CustomPaint(
        painter:
            _PerforationPainter(notchColor: notchColor, dashColor: dashColor),
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({
    required this.notchColor,
    required this.dashColor,
  });

  final Color notchColor;
  final Color dashColor;

  static const double _notchRadius = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final notch = Paint()
      ..color = notchColor
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(0, y), _notchRadius, notch);
    canvas.drawCircle(Offset(size.width, y), _notchRadius, notch);

    final dash = Paint()
      ..color = dashColor
      ..strokeWidth = 1;
    const dashW = 4.0;
    const gapW = 4.0;
    var x = _notchRadius + 3;
    final endX = size.width - _notchRadius - 3;
    while (x < endX) {
      final segEnd = (x + dashW) < endX ? x + dashW : endX;
      canvas.drawLine(Offset(x, y), Offset(segEnd, y), dash);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter old) =>
      old.notchColor != notchColor || old.dashColor != dashColor;
}
