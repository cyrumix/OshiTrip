import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/result.dart';
import '../application/social_providers.dart';
import '../domain/friendship.dart';
import '../domain/profile.dart';

/// フレンド画面（追加要件 §2 / §9）。
///
/// フレンド一覧・申請中（送信）・受信した申請を3タブで表示し、承認/拒否/削除を
/// 行う。フレンド申請の**送信**は共有メンバー一覧から行う（無制限検索はしない,
/// §7）ため、この画面には検索欄を置かない。
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0;

  Future<void> _run(Future<Result<void>> Function() action) async {
    final result = await action();
    if (!mounted) return;
    result.when(
      ok: (_) => ref.invalidate(friendsViewProvider),
      err: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _copyMyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('フレンドコードをコピーしました')),
    );
  }

  /// フレンドコードを入力して申請する。コード完全一致でのみ相手を特定する
  /// （無制限検索はしない）。searchable=false の相手でもコードなら送れる。
  Future<void> _openAddByCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _FriendCodeDialog(),
    );
    if (code == null || code.isEmpty || !mounted) return;
    final result =
        await ref.read(friendRepositoryProvider).sendRequestByCode(code);
    if (!mounted) return;
    result.when(
      ok: (status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == FriendshipStatus.accepted
                  ? 'フレンドになりました'
                  : 'フレンド申請を送りました',
            ),
          ),
        );
        ref.invalidate(friendsViewProvider);
      },
      err: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Widget _friendCodeHeader() {
    final theme = Theme.of(context);
    final code = ref.watch(myProfileProvider).valueOrNull?.friendCode ?? '';
    return AppCard(
      margin:
          const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'あなたのフレンドコード',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  code.isEmpty ? '—' : code,
                  key: const Key('my_friend_code'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (code.isNotEmpty)
                IconButton(
                  key: const Key('copy_friend_code'),
                  tooltip: 'コピー',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copyMyCode(code),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('add_by_friend_code'),
              onPressed: _openAddByCode,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('フレンドコードで追加'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewAsync = ref.watch(friendsViewProvider);

    return AppScaffold(
      title: 'フレンド',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _friendCodeHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.sm,
            ),
            child: SegmentTabs(
              tabs: _tabLabels(viewAsync.valueOrNull),
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(friendsViewProvider),
              child: viewAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: 'フレンド情報を取得できませんでした',
                  description: '通信状況を確認して、引き下げて再読み込みしてください',
                ),
                data: (view) => _TabBody(
                  tab: _tab,
                  view: view,
                  onAccept: (e) => _run(
                    () => ref
                        .read(friendRepositoryProvider)
                        .respond(e.friendship.id, accept: true),
                  ),
                  onReject: (e) => _run(
                    () => ref
                        .read(friendRepositoryProvider)
                        .respond(e.friendship.id, accept: false),
                  ),
                  onRemove: (e) => _run(
                    () => ref
                        .read(friendRepositoryProvider)
                        .removeFriend(e.otherId),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _tabLabels(FriendsView? view) {
    final incoming = view?.incoming.length ?? 0;
    return [
      'フレンド',
      '申請中',
      incoming > 0 ? '受信 ($incoming)' : '受信',
    ];
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.tab,
    required this.view,
    required this.onAccept,
    required this.onReject,
    required this.onRemove,
  });

  final int tab;
  final FriendsView view;
  final ValueChanged<FriendEntry> onAccept;
  final ValueChanged<FriendEntry> onReject;
  final ValueChanged<FriendEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    final entries = switch (tab) {
      1 => view.outgoing,
      2 => view.incoming,
      _ => view.friends,
    };
    if (entries.isEmpty) {
      return _emptyFor(tab);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.lg),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, i) => _FriendTile(
        entry: entries[i],
        trailing: _actionsFor(tab, entries[i]),
      ),
    );
  }

  Widget _emptyFor(int tab) => EmptyState(
        icon: switch (tab) {
          1 => Icons.outgoing_mail,
          2 => Icons.mark_email_unread_outlined,
          _ => Icons.group_outlined,
        },
        message: switch (tab) {
          1 => '送信中の申請はありません',
          2 => '受信した申請はありません',
          _ => 'フレンドがまだいません',
        },
        description: switch (tab) {
          _ => 'フレンドコードで追加するか、現場の共有メンバー一覧から申請を送れます',
        },
      );

  Widget _actionsFor(int tab, FriendEntry entry) {
    switch (tab) {
      case 2: // 受信: 承認 / 拒否
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: '承認',
              icon: const Icon(Icons.check),
              onPressed: () => onAccept(entry),
            ),
            const SizedBox(width: AppSpace.xs),
            IconButton(
              tooltip: '拒否',
              icon: const Icon(Icons.close),
              onPressed: () => onReject(entry),
            ),
          ],
        );
      case 1: // 申請中: 取り消し
        return TextButton(
          onPressed: () => onRemove(entry),
          child: const Text('取消'),
        );
      default: // フレンド: 削除
        return IconButton(
          tooltip: 'フレンドを削除',
          icon: const Icon(Icons.person_remove_outlined),
          onPressed: () => onRemove(entry),
        );
    }
  }
}

/// フレンドコード入力ダイアログ。controller を自身の State で破棄する
/// （ダイアログ退場アニメーション中に破棄済み controller を使わないため）。
class _FriendCodeDialog extends StatefulWidget {
  const _FriendCodeDialog();

  @override
  State<_FriendCodeDialog> createState() => _FriendCodeDialogState();
}

class _FriendCodeDialogState extends State<_FriendCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('フレンドコードで追加'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('相手のフレンドコード（例: OSHI-7K3P-Q9A2）を入力すると申請できます。'),
              const SizedBox(height: AppSpace.sm),
              TextField(
                key: const Key('friend_code_input'),
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'フレンドコード'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('friend_code_submit'),
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text('申請'),
          ),
        ],
      );
}

/// プロフィール付きのフレンド行（一覧・申請での共通表示）。
class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.entry, required this.trailing});

  final FriendEntry entry;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Profile? p = entry.profile;
    final subtitle = [
      if (p?.favoriteName != null && p!.favoriteName!.isNotEmpty)
        '推し: ${p.favoriteName}',
      if (p?.bio != null && p!.bio!.isNotEmpty) p.bio!,
    ].join(' · ');

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
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          trailing,
        ],
      ),
    );
  }
}
