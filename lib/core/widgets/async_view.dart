import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_system/empty_state.dart';
import '../error/failure.dart';

/// loading / empty / error / data を一貫表示する共通ビュー（§2 / ADR-0003）。
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.emptyView,
    this.loadingView,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// データが「空」とみなす条件（例: リストが空）。
  final bool Function(T data)? isEmpty;
  final Widget? emptyView;

  /// loading 表示の差し替え（例: [LoadingSkeleton]。design-spec §4/§13）。
  final Widget? loadingView;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loadingView ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                semanticsLabel: '読み込み中',
              ),
            ),
          ),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
      data: (v) {
        if (isEmpty != null && isEmpty!(v)) {
          return emptyView ?? const EmptyView(message: 'まだデータがありません');
        }
        return data(v);
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      final Failure f => f.message,
      _ => 'エラーが発生しました',
    };
    final isOffline = error is NetworkFailure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.cloud_off : Icons.error_outline,
              size: 44,
              semanticLabel: isOffline ? 'オフライン' : 'エラー',
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (isOffline) ...[
              const SizedBox(height: 4),
              Text(
                '端末に保存済みの内容は引き続き利用できます',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状態: 説明と「次の1アクション」を必ず添える（§6 / UX原則）。
/// 見た目は共通Design Systemの [EmptyState]（design-spec §4）へ委譲する。
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.description,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: message,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }
}

/// 破壊的ではないが誤操作の影響が大きい操作の確認ダイアログ（例:
/// 「終演した」— 誤って押すと状態が余韻中/思い出へ進んでしまう）。
/// [confirmDangerAction] と異なり赤色の危険色は使わない。
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'OK',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 削除などの危険操作の確認ダイアログ（削除は確認必須, §7.2）。
Future<bool> confirmDangerAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '削除する',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
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
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
