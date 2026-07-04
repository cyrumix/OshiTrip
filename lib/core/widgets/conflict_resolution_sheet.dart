import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/local_data_scope.dart';
import '../error/result.dart';
import '../providers.dart';
import '../sync/conflict_resolver.dart';
import '../sync/outbox_operation.dart';

/// 同期競合の解決シート（E-1 / R8-A）。
///
/// 競合中の各項目について、ユーザーが明示的に解決手段を選ぶ:
/// - 「サーバーを採用」: この端末の変更を破棄し、サーバーの最新内容へ更新する
///   （破棄になるため確認ダイアログを挟む）。
/// - 「この端末の変更で再送」: サーバーの現在版に合わせてこの端末の変更を
///   再送する（成功すればサーバーがこの端末の内容で更新される。サーバーが
///   さらに新しければ再び競合として残る＝黙って上書きしない）。
///
/// どの操作も競合を黙って捨てたり自動で上書きしたりしない。
Future<void> showConflictResolutionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => const _ConflictResolutionSheet(),
  );
}

class _ConflictResolutionSheet extends ConsumerWidget {
  const _ConflictResolutionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(conflictsProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('同期の競合を解決', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '他の端末での変更と競合しました。項目ごとに、どちらの内容を残すか選べます。',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          conflictsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '競合の読み込みに失敗しました',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            data: (conflicts) {
              if (conflicts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('未解決の競合はありません')),
                );
              }
              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: conflicts.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, i) => _ConflictRow(op: conflicts[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConflictRow extends ConsumerStatefulWidget {
  const _ConflictRow({required this.op});

  final OutboxOperation op;

  @override
  ConsumerState<_ConflictRow> createState() => _ConflictRowState();
}

class _ConflictRowState extends ConsumerState<_ConflictRow> {
  bool _busy = false;

  String? _ownerId() => ref.read(localDataScopeProvider).ownerIdOrNull;

  Future<void> _run(
    Future<Result<ConflictResolutionResult>> Function(String ownerId) action,
  ) async {
    final owner = _ownerId();
    if (owner == null || _busy) return;
    // 二重タップ防止: 実行中はボタンを無効化し、再入も弾く。
    setState(() => _busy = true);
    try {
      final result = await action(owner);
      if (!mounted) return;
      // 競合一覧・件数を再取得して表示へ反映する（失敗時も、状態が
      // 変わっている可能性があるため取り直す）。
      ref.invalidate(conflictsProvider);
      final message = switch (result) {
        // 通信・保存失敗は「解決しました」とは絶対に表示しない。理由と再試行を促す。
        Err(:final failure) => '${failure.message}。再試行してください',
        Ok(:final value) => switch (value) {
            ConflictResolutionResult.resolved => '競合を解決しました',
            ConflictResolutionResult.stillConflicting =>
              'サーバーがさらに更新されていました。もう一度お選びください',
            ConflictResolutionResult.notFound => '競合はすでに解決済みです',
          },
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } on Object catch (e) {
      // 想定外の例外も握りつぶさず、失敗として通知する（成功表示しない）。
      if (!mounted) return;
      ref.invalidate(conflictsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解決に失敗しました（$e）。再試行してください')),
      );
    } finally {
      // 成功・失敗・例外いずれの場合も busy を必ず解除する。
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useServer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サーバーの内容を採用'),
        content: Text(
          'この端末での「${SyncEntity.label(widget.op.entityTable)}」の変更を破棄し、'
          'サーバーの最新の内容に更新します。破棄した変更は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('破棄して採用'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      (owner) => ref
          .read(conflictResolverProvider)
          .useServer(widget.op.mutationId, ownerId: owner),
    );
  }

  Future<void> _keepLocal() => _run(
        (owner) => ref
            .read(conflictResolverProvider)
            .keepLocal(widget.op.mutationId, ownerId: owner),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = SyncEntity.label(widget.op.entityTable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.call_merge_outlined,
              size: 18,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$labelの変更が競合しています',
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _useServer,
              icon: const Icon(Icons.cloud_download_outlined, size: 18),
              label: const Text('サーバーを採用'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _keepLocal,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('この端末の変更で再送'),
            ),
          ],
        ),
      ],
    );
  }
}
