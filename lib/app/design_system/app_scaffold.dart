import 'package:flutter/material.dart';

/// 画面の共通骨格（design-spec §4）。
///
/// 背景（テーマの scaffoldBackground）・SafeArea・AppBar を統一する。
/// Bottom Navigation はシェル側（AppShell）が保持する。
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  /// AppBar タイトル（[appBar] 指定時は無視）。
  final String? title;
  final List<Widget>? actions;

  /// カスタム AppBar（Sliver 系画面では null にして body 側で構成する）。
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          (title == null
              ? null
              : AppBar(title: Text(title!), actions: actions)),
      body: SafeArea(top: appBar == null && title == null, child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
