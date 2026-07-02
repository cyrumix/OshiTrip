import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../../../core/widgets/async_view.dart';
import '../application/oshi_providers.dart';
import '../domain/oshi.dart';

/// マイ推し一覧（§9）。グループ／アーティストとメンバーのローカルCRUD。
class OshiListScreen extends ConsumerWidget {
  const OshiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(oshiGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('マイ推し')),
      body: AsyncValueView<List<OshiGroupWithMembers>>(
        value: groupsAsync,
        isEmpty: (list) => list.isEmpty,
        emptyView: EmptyView(
          icon: Icons.favorite_outline,
          message: 'まだ推しが登録されていません',
          description: 'グループやアーティストを登録すると、現場作成時に選べるようになります。',
          actionLabel: '推しを登録する',
          onAction: () => _showGroupEditor(context, ref),
        ),
        data: (groups) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final g in groups) _GroupCard(item: g),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'oshi_fab',
        onPressed: () => _showGroupEditor(context, ref),
        tooltip: '推しグループを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.item});

  final OshiGroupWithMembers item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = AppTheme.accentFromHex(item.group.color, theme.colorScheme);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.group.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'グループを編集',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _showGroupEditor(context, ref, existing: item.group),
                ),
                IconButton(
                  tooltip: 'グループを削除',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await confirmDangerAction(
                      context,
                      title: 'グループを削除',
                      message: '「${item.group.name}」とメンバーを削除します。既存の現場は削除されません。',
                    );
                    if (ok) {
                      await ref
                          .read(oshiRepositoryProvider)
                          .deleteGroup(item.group.id);
                    }
                  },
                ),
              ],
            ),
            if (item.group.kind != null) Text('種別: ${item.group.kind}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final member in item.members)
                  InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.accentFromHex(
                        member.color,
                        theme.colorScheme,
                      ),
                      radius: 8,
                    ),
                    label: Text('${member.name}（${member.rank.label}）'),
                    onPressed: () => _showMemberEditor(
                      context,
                      ref,
                      groupId: item.group.id,
                      existing: member,
                    ),
                    onDeleted: () async {
                      final ok = await confirmDangerAction(
                        context,
                        title: 'メンバーを削除',
                        message: '「${member.name}」を削除します。',
                      );
                      if (ok) {
                        await ref
                            .read(oshiRepositoryProvider)
                            .deleteMember(member.id);
                      }
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('メンバー追加'),
                  onPressed: () => _showMemberEditor(
                    context,
                    ref,
                    groupId: item.group.id,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showGroupEditor(
  BuildContext context,
  WidgetRef ref, {
  OshiGroup? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final kind = TextEditingController(text: existing?.kind ?? '');
  final color = TextEditingController(text: existing?.color ?? '');
  final memo = TextEditingController(text: existing?.memo ?? '');
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? '推しグループを追加' : 'グループを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'グループ／アーティスト名 *'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kind,
              decoration: const InputDecoration(
                labelText: '種別（アイドル・バンド・声優 など）',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: color,
              decoration: const InputDecoration(
                labelText: 'カラー（#RRGGBB）',
                helperText: 'アクセント表示に使用します',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: memo,
              decoration: const InputDecoration(labelText: 'メモ'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final now = ref.read(clockProvider).now().toUtc();
            final owner =
                ref.read(authRepositoryProvider).currentUser?.id ?? '';
            await ref.read(oshiRepositoryProvider).upsertGroup(
                  OshiGroup(
                    id: existing?.id ?? const Uuid().v4(),
                    ownerId: existing?.ownerId ?? owner,
                    name: name.text.trim(),
                    kind: kind.text.trim().isEmpty ? null : kind.text.trim(),
                    color: color.text.trim().isEmpty ? null : color.text.trim(),
                    memo: memo.text.trim().isEmpty ? null : memo.text.trim(),
                    createdAt: existing?.createdAt ?? now,
                    updatedAt: now,
                  ),
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

Future<void> _showMemberEditor(
  BuildContext context,
  WidgetRef ref, {
  required String groupId,
  OshiMember? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final color = TextEditingController(text: existing?.color ?? '');
  final memo = TextEditingController(text: existing?.memo ?? '');
  var rank = existing?.rank ?? OshiRank.oshi;
  var oshiSince = existing?.oshiSince;
  var birthday = existing?.birthday;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'メンバーを追加' : 'メンバーを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'メンバー名 *'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in OshiRank.values)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: rank == r,
                      onSelected: (_) => setState(() => rank = r),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: color,
                decoration: const InputDecoration(
                  labelText: 'メンバーカラー（#RRGGBB）',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('推し始めた日'),
                subtitle: Text(
                  oshiSince == null ? '未設定' : formatDateOnly(oshiSince!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: oshiSince ?? ref.read(clockProvider).now(),
                    firstDate: DateTime(1990),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => oshiSince = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('誕生日・記念日'),
                subtitle: Text(
                  birthday == null ? '未設定' : formatDateOnly(birthday!),
                ),
                trailing: const Icon(Icons.cake_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: birthday ?? ref.read(clockProvider).now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => birthday = picked);
                },
              ),
              TextField(
                controller: memo,
                decoration: const InputDecoration(labelText: 'メモ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final now = ref.read(clockProvider).now().toUtc();
              final owner =
                  ref.read(authRepositoryProvider).currentUser?.id ?? '';
              await ref.read(oshiRepositoryProvider).upsertMember(
                    OshiMember(
                      id: existing?.id ?? const Uuid().v4(),
                      groupId: groupId,
                      ownerId: existing?.ownerId ?? owner,
                      name: name.text.trim(),
                      rank: rank,
                      color:
                          color.text.trim().isEmpty ? null : color.text.trim(),
                      oshiSince: oshiSince,
                      birthday: birthday,
                      memo: memo.text.trim().isEmpty ? null : memo.text.trim(),
                      createdAt: existing?.createdAt ?? now,
                      updatedAt: now,
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
}
