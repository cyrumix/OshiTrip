import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../../oshi/application/oshi_providers.dart';
import '../../oshi/domain/oshi.dart';
import '../application/genba_form_controller.dart';
import '../domain/genba_schedule.dart';

/// 現場作成/編集フォーム（§7.2）。
///
/// 必須項目（グループ/アーティスト・公演名・日付）から始め、
/// 追加情報は「詳細を追加」で段階的に開示する。入力途中は自動保存される。
class GenbaFormScreen extends ConsumerStatefulWidget {
  const GenbaFormScreen({super.key, this.genbaId});

  /// null = 新規作成。
  final String? genbaId;

  @override
  ConsumerState<GenbaFormScreen> createState() => _GenbaFormScreenState();
}

class _GenbaFormScreenState extends ConsumerState<GenbaFormScreen> {
  TextEditingController? _artist;
  TextEditingController? _title;
  TextEditingController? _venue;
  TextEditingController? _type;
  bool _restoredShown = false;
  bool _submitting = false;

  @override
  void dispose() {
    _artist?.dispose();
    _title?.dispose();
    _venue?.dispose();
    _type?.dispose();
    super.dispose();
  }

  void _ensureControllers(GenbaFormState form) {
    if (_artist != null) return;
    _artist = TextEditingController(text: form.artistName);
    _title = TextEditingController(text: form.title);
    _venue = TextEditingController(text: form.venue);
    _type = TextEditingController(text: form.performanceType);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(genbaFormControllerProvider(widget.genbaId).notifier)
          .submit();
      if (!mounted) return;
      result.when(
        ok: (outcome) {
          // 推し選択が安全側へ補正された場合は、その旨を優先して案内する
          // （黙って保存しない, R5独立レビュー #1）。
          final message = outcome.oshiCorrectionMessage != null
              ? '端末に保存しました（${outcome.oshiCorrectionMessage}）'
              : '端末に保存しました';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
          if (widget.genbaId == null) {
            context.pushReplacement('/genba/${outcome.id}');
          } else {
            context.pop();
          }
        },
        err: (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message))),
      );
    } finally {
      // 保存中表示は成功・失敗いずれの経路でも必ず解除する（万一 submit() が
      // 想定外に例外を投げても、保存ボタンが無効なまま固まらないようにする
      // 多層防御, R5再々レビュー）。
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(genbaFormControllerProvider(widget.genbaId));
    final controller =
        ref.read(genbaFormControllerProvider(widget.genbaId).notifier);
    final isEdit = widget.genbaId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '現場を編集' : '現場を登録')),
      body: formAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (form) {
          _ensureControllers(form);
          if (form.restoredFromDraft && !_restoredShown) {
            _restoredShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('入力途中の下書きを復元しました')),
                );
              }
            });
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OshiSection(
                selectedGroupId: form.oshiGroupId,
                selectedMemberIds: form.oshiMemberIds,
                onGroupSelected: (group) {
                  controller.selectOshiGroup(
                    group?.id,
                    artistName: group?.name,
                  );
                  if (group != null) _artist!.text = group.name;
                },
                onMemberToggled: controller.toggleOshiMember,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _artist,
                decoration: const InputDecoration(
                  labelText: 'グループ／アーティスト名 *',
                ),
                onChanged: (v) =>
                    controller.mutate((s) => s.copyWith(artistName: v)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: '公演名 *'),
                onChanged: (v) =>
                    controller.mutate((s) => s.copyWith(title: v)),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日付 *'),
                subtitle: Text(
                  form.eventDate == null
                      ? '未選択'
                      : formatDateOnly(form.eventDate!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        form.eventDate ?? ref.read(clockProvider).now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    controller.mutate((s) => s.copyWith(eventDate: picked));
                  }
                },
              ),
              const Divider(),
              ExpansionTile(
                title: const Text('詳細を追加（任意）'),
                subtitle: const Text('会場・時間・公演種別・遠征の有無'),
                initiallyExpanded: isEdit,
                childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  TextField(
                    controller: _venue,
                    decoration: const InputDecoration(labelText: '会場'),
                    onChanged: (v) =>
                        controller.mutate((s) => s.copyWith(venue: v)),
                  ),
                  const SizedBox(height: 12),
                  _TimeField(
                    label: '開場',
                    minutes: form.doorTimeMinutes,
                    onChanged: (m) => controller.mutate(
                      (s) => m == null
                          ? s.copyWith(clearDoorTime: true)
                          : s.copyWith(doorTimeMinutes: m),
                    ),
                  ),
                  _TimeField(
                    label: '開演',
                    minutes: form.startTimeMinutes,
                    onChanged: (m) => controller.mutate(
                      (s) => m == null
                          ? s.copyWith(clearStartTime: true)
                          : s.copyWith(startTimeMinutes: m),
                    ),
                  ),
                  _TimeField(
                    label: '終演予定',
                    minutes: form.endTimeMinutes,
                    allowNextDay: true,
                    onChanged: (m) => controller.mutate(
                      (s) => m == null
                          ? s.copyWith(clearEndTime: true)
                          : s.copyWith(endTimeMinutes: m),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _type,
                    decoration: const InputDecoration(
                      labelText: '公演種別（ライブ・リリイベ・舞台 など）',
                    ),
                    onChanged: (v) => controller
                        .mutate((s) => s.copyWith(performanceType: v)),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '遠征しますか？（交通・宿泊の要否に反映されます）',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'yes', label: Text('遠征する')),
                      ButtonSegment(value: 'no', label: Text('しない')),
                      ButtonSegment(value: 'unknown', label: Text('未定')),
                    ],
                    selected: {
                      switch (form.isExpedition) {
                        true => 'yes',
                        false => 'no',
                        null => 'unknown',
                      },
                    },
                    onSelectionChanged: (selection) {
                      controller.setExpedition(
                        switch (selection.first) {
                          'yes' => true,
                          'no' => false,
                          _ => null,
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting || !form.isValid ? null : _submit,
                child: Text(
                  isEdit ? '保存する' : '登録する',
                  semanticsLabel: isEdit ? '現場を保存する' : '現場を登録する',
                ),
              ),
              if (!form.isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'グループ／アーティスト名・公演名・日付を入力すると登録できます',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

/// マイ推し（グループ＋メンバー）から選択する。事前登録が無くても、その場で
/// 新しい推し・メンバーを作成できる導線を常に用意する（§9「事前のマイ推し登録を
/// 必須にしない」）。推しデータの取得は StreamProvider の AsyncValue を
/// loading / error / data で明示的に出し分け、固定ダミーは使わない（§2.5/§19）。
class _OshiSection extends ConsumerWidget {
  const _OshiSection({
    required this.selectedGroupId,
    required this.selectedMemberIds,
    required this.onGroupSelected,
    required this.onMemberToggled,
  });

  final String? selectedGroupId;
  final List<String> selectedMemberIds;
  final void Function(OshiGroup? group) onGroupSelected;
  final void Function(String memberId, bool selected) onMemberToggled;

  Future<void> _quickAddGroup(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, title: '推しを登録');
    if (name == null || name.isEmpty || !context.mounted) return;
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return;
    final group = OshiGroup(
      id: const Uuid().v4(),
      ownerId: owner,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    final result = await ref.read(oshiRepositoryProvider).upsertGroup(group);
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    // 作成した推しをそのまま現場に紐づける（登録の手間を1往復にする）。
    onGroupSelected(group);
  }

  Future<void> _quickAddMember(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    final name = await _promptName(context, title: 'メンバーを登録');
    if (name == null || name.isEmpty || !context.mounted) return;
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return;
    final member = OshiMember(
      id: const Uuid().v4(),
      groupId: groupId,
      ownerId: owner,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    final result = await ref.read(oshiRepositoryProvider).upsertMember(member);
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    // 作成したメンバーをそのまま推しメンとして選択する。
    onMemberToggled(member.id, true);
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
  }) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名前 *'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('登録'),
          ),
        ],
      ),
    );
    nameController.dispose();
    return name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(oshiGroupsProvider);
    return groupsAsync.when(
      loading: () => const _OshiLoading(),
      error: (_, __) => const _OshiError(),
      data: (groups) {
        final selected = groups
            .where((g) => g.group.id == selectedGroupId)
            .map((g) => g.members)
            .firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('マイ推し', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in groups)
                  ChoiceChip(
                    label: Text(g.group.name),
                    selected: selectedGroupId == g.group.id,
                    onSelected: (isSelected) =>
                        onGroupSelected(isSelected ? g.group : null),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(groups.isEmpty ? '推しを登録' : '新しい推しを登録'),
                  onPressed: () => _quickAddGroup(context, ref),
                ),
              ],
            ),
            if (selectedGroupId != null) ...[
              const SizedBox(height: 12),
              Text(
                '推しメン（複数選択できます）',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              if (selected == null || selected.isEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'このグループのメンバーはまだ登録されていません。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.person_add_alt, size: 18),
                      label: const Text('メンバーを登録'),
                      onPressed: () =>
                          _quickAddMember(context, ref, selectedGroupId!),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in selected)
                      FilterChip(
                        label: Text(m.name),
                        selected: selectedMemberIds.contains(m.id),
                        onSelected: (isSelected) =>
                            onMemberToggled(m.id, isSelected),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: const Text('メンバーを登録'),
                      onPressed: () =>
                          _quickAddMember(context, ref, selectedGroupId!),
                    ),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }
}

class _OshiLoading extends StatelessWidget {
  const _OshiLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'マイ推しを読み込み中…',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OshiError extends StatelessWidget {
  const _OshiError();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'マイ推しの読み込みに失敗しました。時間をおいて再度お試しください。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onChanged,
    this.allowNextDay = false,
  });

  final String label;
  final int? minutes;
  final void Function(int? minutes) onChanged;

  /// 翌日にまたがる時刻（深夜公演の終演）を許可する。
  final bool allowNextDay;

  @override
  Widget build(BuildContext context) {
    final isNextDay = minutes != null && minutes! >= 24 * 60;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        minutes == null
            ? '未設定'
            : '${formatMinutes(minutes!)}${isNextDay ? '（翌日）' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (minutes != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: '$labelをクリア',
              onPressed: () => onChanged(null),
            ),
          const Icon(Icons.access_time),
        ],
      ),
      onTap: () async {
        final base = minutes == null ? null : minutes! % (24 * 60);
        final picked = await showTimePicker(
          context: context,
          initialTime: base == null
              ? const TimeOfDay(hour: 18, minute: 0)
              : TimeOfDay(hour: base ~/ 60, minute: base % 60),
        );
        if (picked == null || !context.mounted) return;
        var total = picked.hour * 60 + picked.minute;
        if (allowNextDay) {
          final nextDay = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('$labelの日付'),
              content: const Text('この時刻は公演日の当日ですか、翌日（日跨ぎ）ですか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('当日'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('翌日'),
                ),
              ],
            ),
          );
          if (nextDay == true) total += 24 * 60;
        }
        onChanged(total);
      },
    );
  }
}
