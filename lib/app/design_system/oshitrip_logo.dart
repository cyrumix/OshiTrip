import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// OshiTrip のロゴ（HOME刷新デザイン案）。
///
/// マークはアプリの哲学「夜明け前の遠征ノート」をそのまま図案化したもの:
/// 地平線（＝遠征の道のり）の上に、夜明け前にひとつだけ光る一番星
/// （＝推しに会える日）。菫→暁のグラデーションで「まもなく明ける空」を表す。
/// ワードマークは Oshi(太)+Trip(細) の太さ差で刻む（装飾フォントは使わない）。
class OshiTripLogo extends StatelessWidget {
  const OshiTripLogo({super.key, this.markSize = 19, this.showWordmark = true});

  /// マーク（星＋地平線）の一辺。
  final double markSize;

  /// ワードマーク「OshiTrip」を併記するか。
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Semantics(
      label: 'OshiTrip',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size.square(markSize),
            painter: _DawnStarPainter(
              start: tokens.heroGradientEnd,
              end: tokens.dawn,
            ),
          ),
          if (showWordmark) ...[
            const SizedBox(width: 7),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Oshi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: 'Trip',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: markSize * .71,
                letterSpacing: .3,
                color: theme.colorScheme.onSurface,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 一番星＋地平線のマーク。
class _DawnStarPainter extends CustomPainter {
  const _DawnStarPainter({required this.start, required this.end});

  /// グラデーション（菫 → 暁）。
  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [start, end],
    ).createShader(rect);

    final star = Offset(size.width * .5, size.height * .38);
    // 星のまわりの淡い光（夜明けの気配）。
    canvas.drawCircle(
      star,
      size.width * .225,
      Paint()
        ..shader = shader
        ..color = start.withValues(alpha: .2),
    );
    // 一番星。
    canvas.drawCircle(star, size.width * .108, Paint()..shader = shader);
    // 地平線（遠征の道のり）。
    final line = Paint()
      ..shader = shader
      ..strokeWidth = size.height * .075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .12, size.height * .72),
      Offset(size.width * .88, size.height * .72),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _DawnStarPainter old) =>
      old.start != start || old.end != end;
}
