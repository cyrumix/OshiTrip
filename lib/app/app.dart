import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
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
