import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../sharing/domain/genba_invite.dart';
import '../../sharing/domain/share.dart';
import '../application/member_providers.dart';

/// 招待URL参加確認画面（追加要件 §3/§9）。
///
/// token のプレビュー（現場名・公演名・日付・オーナー・参加後の権限）を表示し、
/// 「参加する」で `genba_shares` へ追加（参加済み/オーナーは重複追加せず現場へ）。
class InviteJoinScreen extends ConsumerStatefulWidget {
  const InviteJoinScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteJoinScreen> createState() => _InviteJoinScreenState();
}

class _InviteJoinScreenState extends ConsumerState<InviteJoinScreen> {
  bool _joining = false;

  Future<void> _join(String genbaId) async {
    setState(() => _joining = true);
    final result =
        await ref.read(genbaInviteRepositoryProvider).joinByToken(widget.token);
    if (!mounted) return;
    setState(() => _joining = false);
    result.when(
      ok: (_) => _goToGenba(genbaId),
      err: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  void _goToGenba(String genbaId) {
    // 参加後・参加済みとも現場詳細へ遷移する（重複参加はサーバーが防ぐ）。
    context.go('/genba/$genbaId');
  }

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(invitePreviewProvider(widget.token));

    return AppScaffold(
      title: '現場に参加',
      body: previewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _InviteError(
          message: '招待リンクを確認できませんでした',
        ),
        data: (preview) {
          if (preview == null) {
            return const _InviteError(message: '招待リンクを確認できませんでした');
          }
          if (!preview.valid) {
            return _InviteError(message: inviteReasonMessage(preview.reason));
          }
          return _PreviewView(
            preview: preview,
            joining: _joining,
            onJoin: () => _join(preview.genbaId),
            onOpen: () => _goToGenba(preview.genbaId),
            onCancel: () => context.mounted ? context.pop() : null,
          );
        },
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.preview,
    required this.joining,
    required this.onJoin,
    required this.onOpen,
    required this.onCancel,
  });

  final InvitePreview preview;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OshiAvatar(
                    name: preview.ownerDisplayName ?? '?',
                    size: 40,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      '${preview.ownerDisplayName ?? 'オーナー'} さんの現場',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                preview.title ?? '現場',
                style: theme.textTheme.headlineSmall,
              ),
              if (preview.artistName != null) ...[
                const SizedBox(height: 2),
                Text(preview.artistName!, style: theme.textTheme.titleMedium),
              ],
              if (preview.eventDate != null) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(_formatDate(preview.eventDate!)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpace.md),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '参加後の権限: ${_roleLabel(preview.defaultRole)}',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (preview.alreadyMember) ...[
          Text(
            'すでにこの現場に参加しています',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(onPressed: onOpen, child: const Text('現場を開く')),
        ] else ...[
          FilledButton(
            onPressed: joining ? null : onJoin,
            child: joining
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('参加する'),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(onPressed: onCancel, child: const Text('キャンセル')),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';
}

class _InviteError extends StatelessWidget {
  const _InviteError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.link_off,
        message: message,
        description: 'オーナーに新しい招待リンクをもらってください',
      );
}

String _roleLabel(ShareRole role) => switch (role) {
      ShareRole.owner => 'オーナー',
      ShareRole.editor => '編集可',
      ShareRole.viewer => '閲覧のみ',
    };
