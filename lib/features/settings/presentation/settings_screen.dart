import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../onboarding/application/tutorial_controller.dart';
import '../application/oshi_color_controller.dart';
import '../application/settings_controller.dart';

/// 設定トップ（design-spec §11）。階層型リスト。
///
/// 通知設定・プライバシー共有は未実装のため、押せる見せかけの行を
/// 出さない（§11/§15.4）。危険操作（ログアウト・削除）は通常項目と
/// 視覚的に分離する。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    final oshiHex = ref.watch(oshiColorProvider).valueOrNull;
    final oshiName = oshiColorPresets
            .where((p) => p.hex == oshiHex)
            .map((p) => p.name)
            .firstOrNull ??
        (oshiHex != null ? 'カスタム' : '未設定');

    return AppScaffold(
      title: '設定',
      body: ListView(
        key: const PageStorageKey('settings_list'),
        children: [
          const _SectionLabel('アカウント'),
          SettingsRow(
            icon: Icons.person_outline,
            title: 'アカウント設定',
            value: user?.email,
            subtitle: user?.isDemo ?? false ? 'デモモード（端末内のみ・サーバー未接続）' : null,
            onTap: () => context.push('/settings/account'),
          ),
          const Divider(),
          const _SectionLabel('表示'),
          SettingsRow(
            icon: Icons.brightness_6_outlined,
            title: 'テーマ設定',
            value: switch (themeMode) {
              ThemeMode.system => '端末に合わせる',
              ThemeMode.light => 'ライト',
              ThemeMode.dark => 'ダーク',
            },
            onTap: () => context.push('/settings/theme'),
          ),
          SettingsRow(
            icon: Icons.palette_outlined,
            title: '推しカラー設定',
            value: oshiName,
            onTap: () => context.push('/settings/oshi-color'),
          ),
          const Divider(),
          const _SectionLabel('データ'),
          SettingsRow(
            icon: Icons.storage_outlined,
            title: 'データ管理',
            onTap: () => context.push('/settings/data'),
          ),
          const Divider(),
          const _SectionLabel('ヘルプ'),
          SettingsRow(
            icon: Icons.replay_outlined,
            title: 'チュートリアルをもう一度見る',
            showChevron: false,
            onTap: () async {
              await ref.read(tutorialDoneProvider.notifier).reset();
              // redirect によりオンボーディングへ遷移する。
            },
          ),
          SettingsRow(
            icon: Icons.info_outline,
            title: env.appTitle,
            subtitle: 'バージョン 0.1.0 / 環境: ${env.flavor.name}'
                '${env.isDemoMode ? '（デモモード）' : ''}',
            showChevron: false,
          ),
          const Divider(),
          // 危険操作は通常項目と分離（§11）。
          const _SectionLabel('ログアウト・削除'),
          SettingsRow(
            icon: Icons.logout,
            title: 'ログアウト',
            showChevron: false,
            onTap: () async {
              final failure =
                  await ref.read(authControllerProvider.notifier).signOut();
              if (failure != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
