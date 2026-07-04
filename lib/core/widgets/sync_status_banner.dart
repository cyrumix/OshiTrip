import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../sync/outbox_operation.dart';
import 'conflict_resolution_sheet.dart';

/// 同期状態のバナー。必要な場面（未同期・失敗・競合・オフライン・デモ）だけ
/// 表示する（§6判断基準 / design-spec §4・§13）。
///
/// AppShell（5タブと配下の詳細画面すべての上部）に1箇所だけ置かれ、
/// 主要6領域はこの共通部品を共有する（画面ごとの独自実装を作らない）。
/// オフライン・端末保存済み・同期中・失敗・競合を「同期済み」と誤認させず、
/// オフラインでもローカルデータは隠さない（状態だけを正確に伝える）。
/// 件数・到達性はすべて実データ（Outbox / ConnectivityObserver）由来で、
/// 架空の最終同期時刻や固定ダミーは表示しない。
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envProvider);
    final counts = ref.watch(outboxStatusProvider).valueOrNull ?? const {};
    final conflict = counts[OutboxStatus.conflict] ?? 0;
    final failed = counts[OutboxStatus.failed] ?? 0;
    final pending = (counts[OutboxStatus.pending] ?? 0) +
        (counts[OutboxStatus.syncing] ?? 0);
    // 到達性が未判定の間はオフライン表示を出さない（誤警告を避ける）。
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    if (env.isDemoMode) {
      return _Banner(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        icon: Icons.science_outlined,
        text: 'デモモード（端末内のみ保存）',
        semanticsLabel: 'デモモードで動作中',
      );
    }
    if (!online) {
      // オフライン中の再試行は成立しないため、失敗件数より先に到達性を伝える。
      final unsent = pending + failed + conflict;
      return _Banner(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        icon: Icons.cloud_off,
        text: unsent > 0
            ? 'オフライン・未同期$unsent件（端末のデータは利用できます）'
            : 'オフライン（端末のデータは利用できます）',
        semanticsLabel: 'オフライン',
      );
    }
    if (conflict > 0) {
      return _Banner(
        color: Theme.of(context).colorScheme.errorContainer,
        icon: Icons.call_merge_outlined,
        text: '他の端末の変更と競合した項目が$conflict件あります',
        semanticsLabel: '同期の競合',
        action: TextButton(
          onPressed: () => showConflictResolutionSheet(context),
          child: const Text('解決する'),
        ),
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
    return Material(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // 状態カテゴリ（オフライン/同期失敗など）を独立ノードとして
            // 読み上げる。詳細文言は隣の Text がそのまま読まれる（§14）。
            Semantics(
              label: semanticsLabel,
              container: true,
              child: Icon(icon, size: 18),
            ),
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
    );
  }
}
