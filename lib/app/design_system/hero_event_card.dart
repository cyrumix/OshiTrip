import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'image_state_note.dart';

/// 次の現場ヒーローカード（design-spec §4/§6.2）。
///
/// - 写真がある場合は暗めのオーバーレイを重ねて文字可読性を保つ（§12）。
/// - 写真がない場合は Primary〜Primary Light のグラデーションと淡い光表現。
/// - 残日数を最も大きく表示し、単位と強弱を付ける（§3）。
/// - カード下部に Todo/交通/宿泊/チケット等の状態ショートカットを載せる。
class HeroEventCard extends StatelessWidget {
  const HeroEventCard({
    super.key,
    required this.title,
    required this.artistName,
    required this.dateLabel,
    required this.daysUntil,
    this.leadLabel = '次の現場まで',
    this.timeLabel,
    this.venue,
    this.imageFile,
    this.imageAltText,
    this.imageUnavailableNote,
    this.statusItems = const <Widget>[],
    this.onTap,
  });

  final String title;
  final String artistName;
  final String dateLabel;

  /// 残日数（0 = 本日、負値 = n日前）。表示・読み上げはカード内で組み立てる。
  final int daysUntil;

  /// 残日数の上に出す短いリード（例: 「次の現場まで」）。
  final String leadLabel;
  final String? timeLabel;
  final String? venue;

  /// 現場ヒーロー画像（チケット画像を流用しない, §12）。
  final File? imageFile;
  final String? imageAltText;

  /// 設定済み画像を表示できない理由（端末から削除・権限喪失など）。
  /// 非null のとき紫フォールバック上に [ImageStateNote] で明示し、
  /// 「画像未設定」と区別する（§12: placeholderだけで隠さない）。
  final String? imageUnavailableNote;

  /// 下部の状態ショートカット（[StatusIconItem] を想定・均等割）。
  final List<Widget> statusItems;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final hasPhoto = imageFile != null;
    // 写真上でもグラデーション上でも可読な白系文字。
    const fg = Colors.white;
    final daysLabel = daysUntil == 0
        ? '本日'
        : daysUntil > 0
            ? 'あと$daysUntil日'
            : '${-daysUntil}日前';
    final daysSemantics = daysUntil == 0
        ? '公演は本日です'
        : daysUntil > 0
            ? '公演まであと$daysUntil日'
            : '公演から${-daysUntil}日経過';

    // ラベルは内部の Text / StatusIconItem がそれぞれ読み上げに寄与する
    // （状態ショートカットの読み上げを失わないよう、まとめて exclude しない）。
    return Semantics(
      button: onTap != null,
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // 背景: 写真 or グラデーション + 抽象的な光（§6.2）。
              Positioned.fill(
                child: hasPhoto
                    ? Semantics(
                        image: true,
                        label: imageAltText ?? '公演の画像',
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          // 読み込み失敗は fallback だけで隠さず明示する（§12）。
                          errorBuilder: (_, __, ___) => Stack(
                            fit: StackFit.expand,
                            children: [
                              _GradientBackground(tokens: tokens),
                              const Positioned(
                                left: AppSpace.sm,
                                top: AppSpace.sm,
                                child: ImageStateNote(
                                  message: '画像を読み込めませんでした',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _GradientBackground(tokens: tokens),
              ),
              // 設定済み画像が端末に無い・読めない場合の明示（§12）。
              if (!hasPhoto && imageUnavailableNote != null)
                Positioned(
                  left: AppSpace.sm,
                  top: AppSpace.sm,
                  child: ImageStateNote(message: imageUnavailableNote!),
                ),
              // 可読性オーバーレイ（写真時は濃く、グラデ時は淡く）。
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tokens.heroOverlay
                            .withValues(alpha: hasPhoto ? 0.35 : 0.05),
                        tokens.heroOverlay
                            .withValues(alpha: hasPhoto ? 0.75 : 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                label: daysSemantics,
                excludeSemantics: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          leadLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: fg.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // 残日数を最大サイズで（§3: 28〜40sp・単位と強弱）。
                      Text.rich(
                        TextSpan(
                          children: daysUntil == 0
                              ? [
                                  const TextSpan(
                                    text: '本日',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ]
                              : [
                                  TextSpan(
                                    text: daysUntil > 0 ? 'あと ' : '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${daysUntil.abs()}',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                  TextSpan(
                                    text: daysUntil > 0 ? ' 日' : ' 日前',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                          style: const TextStyle(color: fg),
                        ),
                        semanticsLabel: daysLabel,
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artistName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: fg.withValues(alpha: 0.9)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        [
                          dateLabel,
                          if (timeLabel != null) timeLabel!,
                          if (venue != null) venue!,
                        ].join('　'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: fg.withValues(alpha: 0.9)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (statusItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.lg),
                        // 状態ショートカットの4分割（§6.2）。面を少し分けて
                        // 写真上でも読めるようにする。
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Row(
                            children: [
                              for (final item in statusItems)
                                Expanded(child: item),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
        ),
      ),
      // 抽象的な光の表現（夜明け前の淡い光, §1/§6.2）。
      child: CustomPaint(painter: _GlowPainter(tokens.primarySoft)),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.glow);

  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [glow.withValues(alpha: 0.55), glow.withValues(alpha: 0)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.1),
          radius: size.width * 0.6,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.glow != glow;
}
