import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/widgets/async_view.dart';
import '../application/account_controller.dart';

/// データ管理（design-spec §11）。危険操作は通常項目と視覚的に分離する。
class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return AppScaffold(
      title: 'データ管理',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Text(
            '現場・思い出・マイ推しのデータは端末に保存され、ログイン中はサーバーとも同期されます。',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpace.xl),
          // 危険操作の分離面（§11）。
          AppCard(
            variant: AppCardVariant.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '取り消せない操作',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                SettingsRow(
                  icon: Icons.delete_forever_outlined,
                  title: 'アカウントとデータを削除',
                  destructive: true,
                  showChevron: false,
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ],
            ),
          ),
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

    final failure =
        await ref.read(accountControllerProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウントを削除しました')),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }
}
