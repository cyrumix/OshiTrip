import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/connectivity.dart';
import '../core/providers.dart';
import '../features/settings/application/settings_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// アプリルート。日本語基準・ライト/ダーク両対応（§15.4）。
class OshiExpeditionApp extends ConsumerWidget {
  const OshiExpeditionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final env = ref.watch(envProvider);
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    return MaterialApp.router(
      title: env.appTitle,
      routerConfig: router,
      builder: (context, child) =>
          _SyncLifecycleHost(child: child ?? const SizedBox.shrink()),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: env.flavor != Flavor.production,
    );
  }
}

/// 同期 drain の駆動を app ライフサイクルへ接続する（H-02）。
///
/// - 起動時に [SyncCoordinator.start]（初回 drain）。
/// - 認証確定（復元/ログイン）で [SyncCoordinator.onAuthenticated]。
/// - resume で [SyncCoordinator.onAppResumed] ＋ 接続の再判定。
class _SyncLifecycleHost extends ConsumerStatefulWidget {
  const _SyncLifecycleHost({required this.child});

  final Widget child;

  @override
  ConsumerState<_SyncLifecycleHost> createState() => _SyncLifecycleHostState();
}

class _SyncLifecycleHostState extends ConsumerState<_SyncLifecycleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(syncCoordinatorProvider).start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncCoordinatorProvider).onAppResumed();
      final connectivity = ref.read(connectivityProvider);
      if (connectivity is ReachabilityConnectivity) {
        connectivity.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // sessionSync を有効化: 認証確定（セッション復元・ログイン）で drain＋
    // 背景 pull（genba→memory/oshi）、ログアウトで pull 重複防止をリセットする。
    ref.watch(sessionSyncProvider);
    return widget.child;
  }
}
