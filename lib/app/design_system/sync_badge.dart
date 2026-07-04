import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 同期状態バッジ（design-spec §4）。必要な場面だけ表示する。
///
/// オフラインや端末保存済みを「同期済み」と誤認させない（§13/§15.4）。
/// 状態はアイコン＋文言で示し、色だけに依存しない（§14）。
enum SyncBadgeStatus { savedLocally, syncing, failed, conflict }

extension SyncBadgeStatusLabel on SyncBadgeStatus {
  String get label => switch (this) {
        SyncBadgeStatus.savedLocally => '端末に保存済み',
        SyncBadgeStatus.syncing => '同期中',
        SyncBadgeStatus.failed => '同期に失敗',
        SyncBadgeStatus.conflict => '競合あり',
      };
}

class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.status});

  final SyncBadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final scheme = theme.colorScheme;
    final (icon, bg, fg) = switch (status) {
      SyncBadgeStatus.savedLocally => (
          Icons.smartphone_outlined,
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
      SyncBadgeStatus.syncing => (
          Icons.sync_outlined,
          tokens.primarySoft,
          scheme.onPrimaryContainer,
        ),
      SyncBadgeStatus.failed => (
          Icons.sync_problem_outlined,
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      SyncBadgeStatus.conflict => (
          Icons.call_merge_outlined,
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
    };
    return Semantics(
      label: '同期状態: ${status.label}',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpace.xs),
            Text(
              status.label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
