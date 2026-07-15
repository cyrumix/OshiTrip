import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../../sharing/domain/genba_invite.dart';
import '../../sharing/domain/share.dart';
import '../application/member_providers.dart';
import '../application/social_providers.dart';
import '../domain/friendship.dart';

/// 現場の「メンバー・共有」画面（追加要件 §5/§9）。
///
/// オーナーが共有メンバーを管理する: 現在のメンバー一覧・自分の権限・フレンドから
/// 追加・権限変更（viewer/editor）・メンバー削除・メンバーへのフレンド申請。
/// 招待URLの発行/コピー/無効化は Phase 4 で接続する（本画面に導線枠を用意）。
class GenbaMembersScreen extends ConsumerWidget {
  const GenbaMembersScreen({super.key, required this.genbaId});

  final String genbaId;

  static const _uuid = Uuid();

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Result<void>> Function() action,
  ) async {
    final result = await action();
    if (!context.mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(genbaMembersProvider(genbaId));
        ref.invalidate(genbaSharesStreamProvider(genbaId));
      },
      err: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _addMember(
    BuildContext context,
    WidgetRef ref,
    String friendId,
    ShareRole role,
  ) async {
    final selfId = ref.read(currentUserIdProvider);
    if (selfId == null) return;
    final now = ref.read(clockProvider).now().toUtc();
    final share = GenbaShare(
      id: _uuid.v4(),
      ownerId: selfId,
      genbaId: genbaId,
      granteeId: friendId,
      role: role,
      createdAt: now,
      updatedAt: now,
    );
    await _run(
      context,
      ref,
      () => ref.read(genbaSharesRepositoryProvider).upsertShare(share),
    );
  }

  Future<void> _sendFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final result = await ref.read(friendRepositoryProvider).sendRequest(userId);
    if (!context.mounted) return;
    result.when(
      ok: (_) {
        ref.invalidate(myFriendshipsProvider);
        ref.invalidate(genbaMembersProvider(genbaId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレンド申請を送りました')),
        );
      },
      err: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewAsync = ref.watch(genbaMembersProvider(genbaId));

    return AppScaffold(
      title: 'メンバー・共有',
      body: viewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.wifi_off_outlined,
          message: 'メンバー情報を取得できませんでした',
        ),
        data: (view) {
          if (view.amOwner) {
            return _OwnerView(
              view: view,
              onAddFriend: (id, role) => _addMember(context, ref, id, role),
              onChangeRole: (share, role) => _run(
                context,
                ref,
                () => ref
                    .read(genbaSharesRepositoryProvider)
                    .upsertShare(share.copyWith(role: role)),
              ),
              onRemove: (share) => _run(
                context,
                ref,
                () => ref
                    .read(genbaSharesRepositoryProvider)
                    .removeShare(share.id),
              ),
              onFriendRequest: (id) => _sendFriendRequest(context, ref, id),
            );
          }
          if (view.isMember) {
            // 非オーナー（editor/viewer）: メンバー一覧と自分の権限を閲覧のみ（§4）。
            return _MemberReadOnlyView(
              view: view,
              selfId: ref.watch(currentUserIdProvider),
              onFriendRequest: (id) => _sendFriendRequest(context, ref, id),
            );
          }
          return const EmptyState(
            icon: Icons.lock_outline,
            message: 'この現場のメンバーは表示できません',
            description: '共有が解除されたか、権限がありません',
          );
        },
      ),
    );
  }
}

class _OwnerView extends StatelessWidget {
  const _OwnerView({
    required this.view,
    required this.onAddFriend,
    required this.onChangeRole,
    required this.onRemove,
    required this.onFriendRequest,
  });

  final MembersView view;
  final void Function(String friendId, ShareRole role) onAddFriend;
  final void Function(GenbaShare share, ShareRole role) onChangeRole;
  final void Function(GenbaShare share) onRemove;
  final void Function(String userId) onFriendRequest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        // 自分の権限。
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あなたの権限',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _roleLabel(view.selfRole),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // 招待URL。
        _InviteSection(genbaId: view.genbaId),
        const SizedBox(height: AppSpace.lg),

        SectionHeader(title: 'メンバー', count: view.members.length),
        FilledButton.tonalIcon(
          onPressed:
              view.addableFriends.isEmpty ? null : () => _openAddSheet(context),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(
            view.addableFriends.isEmpty ? '追加できるフレンドがいません' : 'フレンドから追加',
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // オーナー（自分）。
        _OwnerRow(profileName: view.ownerProfile?.displayName ?? 'あなた'),
        const SizedBox(height: AppSpace.sm),

        if (view.members.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: EmptyState(
              icon: Icons.group_outlined,
              message: 'まだ共有メンバーがいません',
              description: 'フレンドから追加するか、招待URLで招待できます',
            ),
          )
        else
          for (final m in view.members) ...[
            _MemberRow(
              entry: m,
              onChangeRole: (role) => onChangeRole(m.share, role),
              onRemove: () => onRemove(m.share),
              onFriendRequest: () => onFriendRequest(m.userId),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
      ],
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AddMemberSheet(
        friends: view.addableFriends,
        onPick: (id, role) {
          Navigator.of(context).pop();
          onAddFriend(id, role);
        },
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.profileName});
  final String profileName;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            OshiAvatar(name: profileName, size: 44),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                '$profileName（あなた）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const _RoleBadge(role: ShareRole.owner),
          ],
        ),
      );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.entry,
    required this.onChangeRole,
    required this.onRemove,
    required this.onFriendRequest,
  });

  final MemberEntry entry;
  final ValueChanged<ShareRole> onChangeRole;
  final VoidCallback onRemove;
  final VoidCallback onFriendRequest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          OshiAvatar(name: entry.displayName, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _FriendChip(
                  status: entry.friendStatus,
                  onRequest: onFriendRequest,
                ),
              ],
            ),
          ),
          _RoleMenu(role: entry.share.role, onChangeRole: onChangeRole),
          IconButton(
            tooltip: 'メンバーを削除',
            icon: const Icon(Icons.person_remove_outlined),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// メンバーとのフレンド状態に応じたチップ／申請ボタン（§7.8.4）。
class _FriendChip extends StatelessWidget {
  const _FriendChip({required this.status, required this.onRequest});
  final FriendshipStatus status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case FriendshipStatus.accepted:
        return _miniLabel(context, 'フレンド', Icons.people_alt_outlined);
      case FriendshipStatus.pending:
        return _miniLabel(context, '申請中', Icons.hourglass_top_outlined);
      case FriendshipStatus.none:
      case FriendshipStatus.rejected:
      case FriendshipStatus.blocked:
        return TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onRequest,
          icon: const Icon(Icons.person_add_alt, size: 16),
          label: const Text('フレンド申請'),
        );
    }
  }

  Widget _miniLabel(BuildContext context, String text, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}

class _RoleMenu extends StatelessWidget {
  const _RoleMenu({required this.role, required this.onChangeRole});
  final ShareRole role;
  final ValueChanged<ShareRole> onChangeRole;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ShareRole>(
      tooltip: '権限を変更',
      onSelected: onChangeRole,
      itemBuilder: (_) => const [
        PopupMenuItem(value: ShareRole.viewer, child: Text('閲覧のみ')),
        PopupMenuItem(value: ShareRole.editor, child: Text('編集可')),
      ],
      child: _RoleBadge(role: role, showChevron: true),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, this.showChevron = false});
  final ShareRole role;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _roleLabel(role),
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (showChevron)
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
        ],
      ),
    );
  }
}

/// 招待URLの発行・コピー・無効化（オーナー, §5.A/§9）。
class _InviteSection extends ConsumerWidget {
  const _InviteSection({required this.genbaId});
  final String genbaId;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final role = await showModalBottomSheet<ShareRole>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _InviteRoleSheet(),
    );
    if (role == null || !context.mounted) return;
    final result = await ref
        .read(genbaInviteRepositoryProvider)
        .createInvite(genbaId, role: role);
    if (!context.mounted) return;
    result.when(
      ok: (invite) async {
        ref.invalidate(genbaInvitesProvider(genbaId));
        await Clipboard.setData(ClipboardData(text: invite.url));
        if (context.mounted) _snack(context, '招待URLを作成してコピーしました');
      },
      err: (f) => _snack(context, f.message),
    );
  }

  Future<void> _copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) _snack(context, '招待URLをコピーしました');
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('招待URLを無効化しますか？'),
        content: const Text('このリンクからは参加できなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('無効化'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result =
        await ref.read(genbaInviteRepositoryProvider).revokeInvite(id);
    if (!context.mounted) return;
    result.when(
      ok: (_) => ref.invalidate(genbaInvitesProvider(genbaId)),
      err: (f) => _snack(context, f.message),
    );
  }

  void _snack(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(genbaInvitesProvider(genbaId));
    final now = ref.read(clockProvider).now().toUtc();
    final active = (invitesAsync.valueOrNull ?? const <GenbaInvite>[])
        .where((i) => i.revokedAt == null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '招待URL'),
        FilledButton.tonalIcon(
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add_link),
          label: const Text('招待URLを作成'),
        ),
        const SizedBox(height: AppSpace.sm),
        if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Text(
              'LINEやDMで送れる招待URLを作成できます',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          )
        else
          for (final invite in active) ...[
            _InviteRow(
              invite: invite,
              expired: !invite.isValidAt(now),
              onCopy: () => _copy(context, invite.url),
              onRevoke: () => _revoke(context, ref, invite.id),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
      ],
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({
    required this.invite,
    required this.expired,
    required this.onCopy,
    required this.onRevoke,
  });

  final GenbaInvite invite;
  final bool expired;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      _roleLabel(invite.defaultRole),
      if (invite.maxUses != null) '${invite.usedCount}/${invite.maxUses}回',
      if (expired) '期限切れ',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Icon(Icons.link_outlined, color: scheme.primary),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  meta,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '招待URLをコピー',
            icon: const Icon(Icons.copy_outlined),
            onPressed: expired ? null : onCopy,
          ),
          IconButton(
            tooltip: '招待URLを無効化',
            icon: const Icon(Icons.link_off),
            onPressed: onRevoke,
          ),
        ],
      ),
    );
  }
}

/// 招待URL作成時の権限選択（viewer 既定・§3）。
class _InviteRoleSheet extends StatelessWidget {
  const _InviteRoleSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Text(
              '参加後の権限を選ぶ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('閲覧のみ'),
            subtitle: const Text('現場を見られます'),
            onTap: () => Navigator.of(context).pop(ShareRole.viewer),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('編集可'),
            subtitle: const Text('現場の内容を編集できます'),
            onTap: () => Navigator.of(context).pop(ShareRole.editor),
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ),
    );
  }
}

class _AddMemberSheet extends StatelessWidget {
  const _AddMemberSheet({required this.friends, required this.onPick});

  final List<AddableFriend> friends;
  final void Function(String userId, ShareRole role) onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Text(
            'フレンドから追加',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.md),
          for (final f in friends)
            ListTile(
              leading: OshiAvatar(name: f.displayName, size: 40),
              title: Text(f.displayName),
              subtitle: const Text('権限を選んで追加'),
              trailing: Wrap(
                spacing: AppSpace.xs,
                children: [
                  OutlinedButton(
                    onPressed: () => onPick(f.userId, ShareRole.viewer),
                    child: const Text('閲覧で追加'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => onPick(f.userId, ShareRole.editor),
                    child: const Text('編集で追加'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 非オーナー（共有メンバー）向けの閲覧専用メンバー画面（§4）。
/// メンバー一覧と自分の権限を表示し、管理操作（追加/削除/権限変更/招待）は出さない。
class _MemberReadOnlyView extends StatelessWidget {
  const _MemberReadOnlyView({
    required this.view,
    required this.selfId,
    required this.onFriendRequest,
  });

  final MembersView view;
  final String? selfId;
  final void Function(String userId) onFriendRequest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あなたの権限',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _roleLabel(view.selfRole),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        SectionHeader(
          title: 'メンバー',
          count: view.members.length + (view.ownerProfile != null ? 1 : 0),
        ),
        if (view.ownerProfile != null) ...[
          _ReadOnlyMemberRow(
            name: view.ownerProfile!.displayName,
            role: ShareRole.owner,
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        for (final m in view.members) ...[
          _ReadOnlyMemberRow(
            name: m.displayName,
            role: m.share.role,
            friendStatus: m.userId == selfId ? null : m.friendStatus,
            isSelf: m.userId == selfId,
            onFriendRequest: () => onFriendRequest(m.userId),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        const SizedBox(height: AppSpace.md),
        Text(
          'メンバーの追加・削除・権限変更・招待URLの発行はオーナーのみ可能です',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }
}

class _ReadOnlyMemberRow extends StatelessWidget {
  const _ReadOnlyMemberRow({
    required this.name,
    required this.role,
    this.friendStatus,
    this.isSelf = false,
    this.onFriendRequest,
  });

  final String name;
  final ShareRole role;
  final FriendshipStatus? friendStatus;
  final bool isSelf;
  final VoidCallback? onFriendRequest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          OshiAvatar(name: name, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? '$name（あなた）' : name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (friendStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _FriendChip(
                      status: friendStatus!,
                      onRequest: onFriendRequest ?? () {},
                    ),
                  ),
              ],
            ),
          ),
          _RoleBadge(role: role),
        ],
      ),
    );
  }
}

String _roleLabel(ShareRole role) => switch (role) {
      ShareRole.owner => 'オーナー',
      ShareRole.editor => '編集可',
      ShareRole.viewer => '閲覧のみ',
    };
