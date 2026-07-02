import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../auth/application/auth_controller.dart';
import '../../onboarding/application/tutorial_controller.dart';
import '../application/settings_controller.dart';

/// 設定（§13の基礎: テーマ・チュートリアル再表示・アカウント・データ削除・アプリ情報）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionLabel('表示'),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).setMode(v);
              }
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('端末の設定に合わせる'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('ライト'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('ダーク'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionLabel('ヘルプ'),
          ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: const Text('チュートリアルをもう一度見る'),
            onTap: () async {
              await ref.read(tutorialDoneProvider.notifier).reset();
              // redirect によりオンボーディングへ遷移する。
            },
          ),
          const Divider(),
          const _SectionLabel('アカウント'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(user?.email ?? '未ログイン'),
            subtitle: user?.isDemo ?? false
                ? const Text('デモモード（端末内のみ・サーバー未接続）')
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
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
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'アカウントとデータを削除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
          const Divider(),
          const _SectionLabel('アプリ情報'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(env.appTitle),
            subtitle: Text(
              'バージョン 0.1.0 / 環境: ${env.flavor.name}'
              '${env.isDemoMode ? '（デモモード）' : ''}',
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// アカウント削除は危険操作として二段階で確認する。
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final first = await confirmDangerAction(
      context,
      title: 'アカウントとデータを削除',
      message: '現場・思い出・マイ推しなど、すべてのデータがサーバーから削除されます。'
          'この操作は取り消せません。',
      confirmLabel: '続ける',
    );
    if (!first || !context.mounted) return;
    final second = await confirmDangerAction(
      context,
      title: '最終確認',
      message: '本当に削除しますか？削除後は復元できません。',
      confirmLabel: '完全に削除する',
    );
    if (!second || !context.mounted) return;

    final result = await ref.read(accountRepositoryProvider).deleteAccount();
    if (!context.mounted) return;
    result.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アカウントを削除しました')),
        );
        context.go('/login');
      },
      err: (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
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
