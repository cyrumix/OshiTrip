import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'image_state_note.dart';

/// 次の現場ヒーローカード（design-spec §4/§6.2 / HOME刷新「夜明け前の遠征ノート」）。
///
/// - 写真がない場合は「夜明け前の空」（藍→菫）のグラデーション。左下から
///   推しカラーを帯びた暁光が差し、底辺に暁のヘアラインがひとすじ灯る。
/// - 写真がある場合は夜空の藍スクリムを重ねて文字可読性を保つ（§12）。
/// - 残日数は大きさを一段抑えた細身の数字（叫ばない数字）で品を出す。
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
    this.accentColor,
    this.imageFile,
    this.imageAltText,
    this.imageUnavailableNote,
    this.statusItems = const <Widget>[],
    this.onTap,
  });

  /// 推しカラー。暁光とヘアラインの色に写像する（本文には使わない）。
  /// null のときは暁（dawn）のみで光らせる。
  final Color? accentColor;

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
    final tokens = AppTokens.of(context);
    final hasPhoto = imageFile != null;
    // 暁光・ヘアラインの色: 推しカラーと暁を混ぜた「その推しの夜明け」。
    final dawnLight = accentColor == null
        ? tokens.dawn
        : Color.lerp(tokens.dawn, accentColor, .55)!;
    // 写真上でもグラデーション上でも可読な白系文字。
    const fg = Colors.white;
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
                              _GradientBackground(
                                tokens: tokens,
                                dawnLight: dawnLight,
                              ),
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
                    : _GradientBackground(tokens: tokens, dawnLight: dawnLight),
              ),
              // 設定済み画像が端末に無い・読めない場合の明示（§12）。
              if (!hasPhoto && imageUnavailableNote != null)
                Positioned(
                  left: AppSpace.sm,
                  top: AppSpace.sm,
                  child: ImageStateNote(message: imageUnavailableNote!),
                ),
              // 可読性オーバーレイ（写真時は濃く、グラデ時は淡く）。
              // 黒ではなく夜空の藍＝世界観の統一（§12）。
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
                            .withValues(alpha: hasPhoto ? 0.75 : 0.30),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                label: daysSemantics,
                excludeSemantics: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (leadLabel.isNotEmpty) ...[
                                  ExcludeSemantics(
                                    child: Text(
                                      leadLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.8,
                                        color: fg.withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: fg,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    height: 1.35,
                                    letterSpacing: .2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  artistName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: fg.withValues(alpha: 0.88),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          // 残日数は白い円形バッジで示す（読み上げは
                          // 親の daysSemantics が担う）。
                          ExcludeSemantics(
                            child: _CountdownBadge(daysUntil: daysUntil),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        [
                          dateLabel,
                          if (timeLabel != null) timeLabel!,
                        ].join('　'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: fg.withValues(alpha: 0.95),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (venue != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: fg.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                venue!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: fg.withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (statusItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.lg),
                        // 状態ショートカットの4分割（§6.2）。磨りガラス風の帯に
                        // 集約し、写真上でも読めるようにする。
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
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

/// 残日数を示す白い円形バッジ（デザイン刷新）。
/// 写真・グラデーションのどちらの上でも読めるよう白面に菫の文字で固定する。
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.daysUntil});

  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final accent = tokens.heroGradientEnd;
    final (String? top, String main) = daysUntil == 0
        ? (null, '本日')
        : daysUntil > 0
            ? ('あと', '$daysUntil日')
            : (null, '${-daysUntil}日前');
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (top != null)
            Text(
              top,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: .75),
                height: 1.1,
              ),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              main,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: accent,
                height: 1.15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.tokens, required this.dawnLight});

  final AppTokens tokens;

  /// 左下から差す暁光の色（推しカラー×暁の混色）。
  final Color dawnLight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // 「夜明け前の空」: 藍 → 菫 → 明るい菫（§1/§6.2）。
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, .46, 1],
          colors: [
            tokens.heroGradientStart,
            tokens.heroGradientMid,
            tokens.heroGradientEnd,
          ],
        ),
      ),
      // 左下の地平線から差す暁光（推しカラーが空に写る）。
      child: CustomPaint(painter: _DawnGlowPainter(dawnLight)),
    );
  }
}

class _DawnGlowPainter extends CustomPainter {
  const _DawnGlowPainter(this.glow);

  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [glow.withValues(alpha: 0.5), glow.withValues(alpha: 0)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.16, size.height * 1.05),
          radius: size.width * 0.62,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _DawnGlowPainter oldDelegate) =>
      oldDelegate.glow != glow;
}
