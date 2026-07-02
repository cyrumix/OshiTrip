import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../sync/outbox_operation.dart';

/// 同期状態のバナー。必要な場面（未同期・失敗・デモ）だけ表示する（§6判断基準）。
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envProvider);
    final counts = ref.watch(outboxStatusProvider).valueOrNull ?? const {};
    final failed = (counts[OutboxStatus.failed] ?? 0) +
        (counts[OutboxStatus.conflict] ?? 0);
    final pending = (counts[OutboxStatus.pending] ?? 0) +
        (counts[OutboxStatus.syncing] ?? 0);

    if (env.isDemoMode) {
      return _Banner(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        icon: Icons.science_outlined,
        text: 'デモモード（端末内のみ保存）',
        semanticsLabel: 'デモモードで動作中',
      );
    }
    if (failed > 0) {
      return _Banner(
        color: Theme.of(context).colorScheme.errorContainer,
        icon: Icons.sync_problem,
        text: '同期できていない変更が$failed件あります',
        semanticsLabel: '同期失敗',
        action: TextButton(
          onPressed: () => ref.read(syncEngineProvider).retryFailed(),
          child: const Text('再試行'),
        ),
      );
    }
    if (pending > 0) {
      return _Banner(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        icon: Icons.cloud_upload_outlined,
        text: '端末保存済み・同期待ち $pending件',
        semanticsLabel: '同期待ち',
      );
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
    required this.semanticsLabel,
    this.action,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String semanticsLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Material(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
      ),
    );
  }
}
