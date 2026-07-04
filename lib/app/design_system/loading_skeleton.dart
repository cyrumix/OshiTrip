import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// カード配置を保ったスケルトン（design-spec §4/§13）。
///
/// 実データへの切替で大きなレイアウトシフトを起こさないよう、
/// 実カードと近い高さで面を確保する。Reduce Motion 時は明滅しない。
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.cardCount = 3,
    this.cardHeight = 96,
    this.showHero = false,
  });

  /// 一覧向け: 大きなヒーロー枠 + カード数枠。
  const LoadingSkeleton.list({super.key, this.cardCount = 4})
      : cardHeight = 96,
        showHero = false;

  /// ホーム向け: ヒーロー + カード枠。
  const LoadingSkeleton.hero({super.key, this.cardCount = 2})
      : cardHeight = 96,
        showHero = true;

  final int cardCount;
  final double cardHeight;
  final bool showHero;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 0.9,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);
    if (reduce) {
      _controller.stop();
      _controller.value = 0.7;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: '読み込み中',
      child: FadeTransition(
        opacity: _controller,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            if (widget.showHero) ...[
              _Block(color: base, height: 200, radius: AppRadius.hero),
              const SizedBox(height: AppSpace.lg),
            ],
            for (var i = 0; i < widget.cardCount; i++) ...[
              _Block(
                color: base,
                height: widget.cardHeight,
                radius: AppRadius.card,
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.color,
    required this.height,
    required this.radius,
  });

  final Color color;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
