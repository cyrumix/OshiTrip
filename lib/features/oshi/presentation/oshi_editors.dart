import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../application/oshi_actions_controller.dart';
import '../domain/oshi.dart';

/// マイ推しの編集ダイアログ群（グループ／メンバー／記念日）。
///
/// 推し画像は端末内・同期対象外（H-04）。編集セッションで import した参照を
/// 追跡し、キャンセルや差替えで不要になったものを孤立させず削除する。

Future<void> showGroupEditor(
  BuildContext context,
  WidgetRef ref, {
  OshiGroup? existing,
}) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final kind = TextEditingController(text: existing?.kind ?? '');
  final color = TextEditingController(text: existing?.color ?? '');
  final memo = TextEditingController(text: existing?.memo ?? '');

  final owner = existing?.ownerId ??
      (ref.read(authRepositoryProvider).currentUser?.id ?? '');
  var imageLocalPath = existing?.imageLocalPath;
  final sessionImports = <String>[];
  var saved = false;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickImage() async {
          final picked =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked == null || owner.isEmpty) return;
          try {
            final storedRef = await ref.read(imageStoreProvider).import(
                  ownerId: owner,
                  category: ImageCategory.oshiImage,
                  source: File(picked.path),
                );
            sessionImports.add(storedRef);
            setState(() => imageLocalPath = storedRef);
          } on ImageStorageException {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('グループ画像の保存に失敗しました')),
              );
            }
          }
        }

        final localRef = imageLocalPath;
        final file = localRef == null
            ? null
            : ref.read(imageStoreProvider).tryResolveOwned(owner, localRef);
        return AlertDialog(
          title: Text(existing == null ? '推しグループを追加' : 'グループを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: file == null ? null : FileImage(file),
                      child: file == null
                          ? const Icon(Icons.groups_outlined)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: pickImage,
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text(file == null ? 'グループ画像を選択' : '画像を差し替え'),
                      ),
                    ),
                    if (localRef != null)
                      IconButton(
                        tooltip: 'グループ画像を外す',
                        onPressed: () => setState(() => imageLocalPath = null),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration:
                      const InputDecoration(labelText: 'グループ／アーティスト名 *'),
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
                    helperText: '現場カードの罫線やリングに使用します',
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
                // 空名は保存しない・保存中の再タップは無視（二重タップ防止）。
                if (name.text.trim().isEmpty || saving) return;
                setState(() => saving = true);
                final now = ref.read(clockProvider).now().toUtc();
                // 書き込みは application 層（R7）。
                final failure = await ref
                    .read(oshiActionsControllerProvider.notifier)
                    .saveGroup(
                      OshiGroup(
                        id: existing?.id ?? const Uuid().v4(),
                        ownerId: existing?.ownerId ?? owner,
                        name: name.text.trim(),
                        kind:
                            kind.text.trim().isEmpty ? null : kind.text.trim(),
                        color: color.text.trim().isEmpty
                            ? null
                            : color.text.trim(),
                        memo:
                            memo.text.trim().isEmpty ? null : memo.text.trim(),
                        imageLocalPath: imageLocalPath,
                        isFavorite: existing?.isFavorite ?? false,
                        createdAt: existing?.createdAt ?? now,
                        updatedAt: now,
                      ),
                    );
                saved = failure == null;
                if (context.mounted) {
                  Navigator.pop(context);
                  if (failure != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message)),
                    );
                  }
                }
              },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        );
      },
    ),
  );

  // ダイアログ終了後の孤立画像清掃（owner スコープのみ、他ユーザーに触れない）。
  if (owner.isNotEmpty) {
    final store = ref.read(imageStoreProvider);
    if (saved) {
      final original = existing?.imageLocalPath;
      if (original != null && original != imageLocalPath) {
        await store.deleteRef(owner, original);
      }
      for (final r in sessionImports) {
        if (r != imageLocalPath) await store.deleteRef(owner, r);
      }
    } else {
      for (final r in sessionImports) {
        await store.deleteRef(owner, r);
      }
    }
  }
}

Future<void> showMemberEditor(
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

  final owner = existing?.ownerId ??
      (ref.read(authRepositoryProvider).currentUser?.id ?? '');
  var imageLocalPath = existing?.imageLocalPath;
  final sessionImports = <String>[];
  var saved = false;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickImage() async {
          final picked =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (picked == null || owner.isEmpty) return;
          try {
            final storedRef = await ref.read(imageStoreProvider).import(
                  ownerId: owner,
                  category: ImageCategory.oshiImage,
                  source: File(picked.path),
                );
            sessionImports.add(storedRef);
            setState(() => imageLocalPath = storedRef);
          } on ImageStorageException {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('推し画像の保存に失敗しました')),
              );
            }
          }
        }

        final localRef = imageLocalPath;
        final file = localRef == null
            ? null
            : ref.read(imageStoreProvider).tryResolveOwned(owner, localRef);
        return AlertDialog(
          title: Text(existing == null ? 'メンバーを追加' : 'メンバーを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: file == null ? null : FileImage(file),
                      child: file == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: pickImage,
                        icon:
                            const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text(file == null ? '推し画像を選択' : '画像を差し替え'),
                      ),
                    ),
                    if (localRef != null)
                      IconButton(
                        tooltip: '推し画像を外す',
                        onPressed: () => setState(() => imageLocalPath = null),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
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
                if (name.text.trim().isEmpty || saving) return;
                setState(() => saving = true);
                final now = ref.read(clockProvider).now().toUtc();
                final failure = await ref
                    .read(oshiActionsControllerProvider.notifier)
                    .saveMember(
                      OshiMember(
                        id: existing?.id ?? const Uuid().v4(),
                        groupId: groupId,
                        ownerId: existing?.ownerId ?? owner,
                        name: name.text.trim(),
                        rank: rank,
                        color: color.text.trim().isEmpty
                            ? null
                            : color.text.trim(),
                        oshiSince: oshiSince,
                        birthday: birthday,
                        memo:
                            memo.text.trim().isEmpty ? null : memo.text.trim(),
                        imageLocalPath: imageLocalPath,
                        createdAt: existing?.createdAt ?? now,
                        updatedAt: now,
                      ),
                    );
                saved = failure == null;
                if (context.mounted) {
                  Navigator.pop(context);
                  if (failure != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message)),
                    );
                  }
                }
              },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        );
      },
    ),
  );

  // ダイアログ終了後の孤立画像清掃（owner スコープのみ、他ユーザーに触れない）。
  if (owner.isNotEmpty) {
    final store = ref.read(imageStoreProvider);
    if (saved) {
      // 差替え/クリアで捨てた旧画像と、不採用の中間 import を削除。
      final original = existing?.imageLocalPath;
      if (original != null && original != imageLocalPath) {
        await store.deleteRef(owner, original);
      }
      for (final r in sessionImports) {
        if (r != imageLocalPath) await store.deleteRef(owner, r);
      }
    } else {
      // キャンセル: 今回 import した未確定画像は全て孤立するため削除。
      for (final r in sessionImports) {
        await store.deleteRef(owner, r);
      }
    }
  }
}

/// ユーザー定義記念日の追加・編集（design-spec §10/§12.1）。
Future<void> showAnniversaryEditor(
  BuildContext context,
  WidgetRef ref, {
  required OshiGroup group,
  required List<OshiMember> members,
  OshiAnniversary? existing,
}) async {
  final label = TextEditingController(text: existing?.label ?? '');
  var date = existing?.date;
  String? memberId = existing?.memberId;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? '記念日を追加' : '記念日を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(
                  labelText: '記念日の名前 *',
                  helperText: '例: メジャーデビュー日・初現場の日',
                ),
                autofocus: true,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日付 *'),
                subtitle: Text(date == null ? '未設定' : formatDateOnly(date!)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? ref.read(clockProvider).now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = picked);
                },
              ),
              if (members.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Text('紐づけ（任意）', style: Theme.of(context).textTheme.labelLarge),
                Wrap(
                  spacing: AppSpace.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('グループ全体'),
                      selected: memberId == null,
                      onSelected: (_) => setState(() => memberId = null),
                    ),
                    for (final m in members)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: memberId == m.id,
                        onSelected: (_) => setState(() => memberId = m.id),
                      ),
                  ],
                ),
              ],
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
              final text = label.text.trim();
              final picked = date;
              if (text.isEmpty || picked == null || saving) return;
              setState(() => saving = true);
              final now = ref.read(clockProvider).now().toUtc();
              final failure = await ref
                  .read(oshiActionsControllerProvider.notifier)
                  .saveAnniversary(
                    OshiAnniversary(
                      id: existing?.id ?? const Uuid().v4(),
                      ownerId: existing?.ownerId ?? group.ownerId,
                      groupId: group.id,
                      memberId: memberId,
                      label: text,
                      date: picked,
                      createdAt: existing?.createdAt ?? now,
                      updatedAt: now,
                    ),
                  );
              if (context.mounted) {
                Navigator.pop(context);
                if (failure != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(failure.message)));
                }
              }
            },
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    ),
  );
}
