import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/widgets/sync_status_banner.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/genba/presentation/genba_detail_screen.dart';
import '../features/genba/presentation/genba_form_screen.dart';
import '../features/genba/presentation/genba_list_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/memory/presentation/memory_detail_screen.dart';
import '../features/memory/presentation/memory_edit_screen.dart';
import '../features/memory/presentation/memory_list_screen.dart';
import '../features/onboarding/application/tutorial_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/oshi/presentation/oshi_screens.dart';
import '../features/settings/presentation/settings_screen.dart';

/// ルーティング（go_router / StatefulShellRoute, ADR-0004）。
///
/// redirect で「チュートリアル未完了 → オンボーディング」
/// 「未認証 → ログイン」を制御する（§4.1 / §14）。
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier(0);
  ref
    ..listen(currentUserProvider, (_, __) => refreshNotifier.value++)
    ..listen(tutorialDoneProvider, (_, __) => refreshNotifier.value++)
    ..onDispose(refreshNotifier.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = ref.read(currentUserProvider);
    final tutorialAsync = ref.read(tutorialDoneProvider);
    final location = state.matchedLocation;

    final loading = authAsync.isLoading || tutorialAsync.isLoading;
    if (loading) {
      return location == '/splash' ? null : '/splash';
    }

    final tutorialDone = tutorialAsync.valueOrNull ?? false;
    final signedIn = authAsync.valueOrNull != null;
    final isAuthRoute = location == '/login' ||
        location == '/signup' ||
        location == '/password-reset';

    if (!tutorialDone) {
      return location == '/onboarding' ? null : '/onboarding';
    }
    if (!signedIn) {
      return isAuthRoute ? null : '/login';
    }
    if (isAuthRoute || location == '/onboarding' || location == '/splash') {
      return '/';
    }
    return null;
  }

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/genba',
                builder: (context, state) => const GenbaListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const GenbaFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => GenbaDetailScreen(
                      genbaId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => GenbaFormScreen(
                          genbaId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/memories',
                builder: (context, state) => const MemoryListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => MemoryDetailScreen(
                      genbaId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => MemoryEditScreen(
                          genbaId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/oshi',
                builder: (context, state) => const OshiListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// 5タブのシェル（§5）。タブ状態は StatefulShellRoute が保持する。
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
            tooltip: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: '現場',
            tooltip: '現場一覧',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_album_outlined),
            selectedIcon: Icon(Icons.photo_album),
            label: '思い出',
            tooltip: '思い出一覧',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'マイ推し',
            tooltip: 'マイ推し',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
            tooltip: '設定',
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(semanticsLabel: '起動中'),
      ),
    );
  }
}
