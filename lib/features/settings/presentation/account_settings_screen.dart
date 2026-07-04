import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';

/// アカウント設定（design-spec §11）。
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return AppScaffold(
      title: 'アカウント設定',
      body: ListView(
        children: [
          SettingsRow(
            icon: Icons.person_outline,
            title: user?.email ?? '未ログイン',
            subtitle: user?.isDemo ?? false ? 'デモモード（端末内のみ・サーバー未接続）' : null,
            showChevron: false,
          ),
          const Divider(),
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
        ],
      ),
    );
  }
}
