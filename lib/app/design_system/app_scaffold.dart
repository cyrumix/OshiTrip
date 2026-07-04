import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'oshitrip_logo.dart';

/// 画面の共通骨格（design-spec §4 / HOME刷新）。
///
/// 背景は単色ではなく「夜明け前の空」の縦グラデーション
/// （上に菫の靄／夜空 → 下へ静かに晴れる）＋画面上部の淡い暁の靄で、
/// 平坦にせず奥行きを持たせる。靄は静止画（アニメーションなし）で、
/// 情報の可読性と落ち着きを最優先する。
/// SafeArea・AppBar を統一し、Bottom Navigation はシェル側が保持する。
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.appBar,
    this.showLogo = false,
    required this.body,
    this.floatingActionButton,
  });

  /// AppBar タイトル（[appBar] 指定時は無視）。
  final String? title;
  final List<Widget>? actions;

  /// カスタム AppBar（Sliver 系画面では null にして body 側で構成する）。
  final PreferredSizeWidget? appBar;

  /// true: タイトルの代わりに OshiTrip ロゴを左寄せ表示（ホーム用）。
  final bool showLogo;

  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final resolvedAppBar = appBar ??
        (showLogo
            ? AppBar(
                centerTitle: false,
                titleSpacing: AppSpace.lg,
                title: const OshiTripLogo(),
                actions: actions,
              )
            : title == null
                ? null
                : AppBar(title: Text(title!), actions: actions));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .4, 1],
          colors: [
            tokens.backgroundTop,
            tokens.backgroundBottom,
            tokens.backgroundBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 画面上部の淡い暁の靄（装飾・情報を持たない）。
          Positioned(
            top: -60,
            left: -80,
            right: -80,
            height: 260,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.4),
                    radius: 1.1,
                    colors: [
                      tokens.primarySoft.withValues(alpha: .55),
                      tokens.primarySoft.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: resolvedAppBar,
            body: SafeArea(
              top: resolvedAppBar == null,
              child: body,
            ),
            floatingActionButton: floatingActionButton,
          ),
        ],
      ),
    );
  }
}
