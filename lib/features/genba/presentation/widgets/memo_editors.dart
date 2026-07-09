import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/error/result.dart';
import '../../../../core/providers.dart';
import '../../application/memo_template_providers.dart';
import '../../domain/genba.dart';
import '../../domain/memo_template_presets.dart';

const _uuid = Uuid();

/// メモ追加フロー（§7.7 改訂）: メモ種類を選ぶ → その種類のテンプレートを選ぶ
/// （テンプレートなしも可）→ 種類別エディタで編集して保存する。
Future<void> showAddMemoFlow(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  required int initialSortOrder,
}) async {
  final kind = await _pickMemoKind(context);
  if (kind == null || !context.mounted) return;

  final choice = await _pickMemoTemplate(context, ref, kind);
  if (choice == null || !context.mounted) return; // 中断

  final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
  final now = ref.read(clockProvider).now().toUtc();
  final seed = _seedMemo(
    kind: kind,
    option: choice.option,
    genbaId: genbaId,
    ownerId: owner,
    sortOrder: initialSortOrder,
    now: now,
    id: _uuid.v4(),
  );
  if (!context.mounted) return;
  await _openMemoEditor(context, ref, memo: seed, isEdit: false);
}

/// 既存メモを種類別エディタで編集する。
Future<void> showMemoEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  required GenbaMemo existing,
}) =>
    _openMemoEditor(context, ref, memo: existing, isEdit: true);

Future<void> _openMemoEditor(
  BuildContext context,
  WidgetRef ref, {
  required GenbaMemo memo,
  required bool isEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _MemoEditorSheet(memo: memo, isEdit: isEdit),
    ),
  );
}

// ---------------------------------------------------------------------------
// 種類選択・テンプレート選択
// ---------------------------------------------------------------------------

IconData _kindIcon(MemoKind kind) => switch (kind) {
      MemoKind.free => Icons.sticky_note_2_outlined,
      MemoKind.checklist => Icons.checklist_rtl,
      MemoKind.bingo => Icons.grid_view_rounded,
      MemoKind.vote => Icons.how_to_vote_outlined,
    };

Future<MemoKind?> _pickMemoKind(BuildContext context) {
  final theme = Theme.of(context);
  return showModalBottomSheet<MemoKind>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.sm,
            ),
            child: Text('メモの種類を選ぶ', style: theme.textTheme.titleLarge),
          ),
          for (final kind in MemoKind.values)
            ListTile(
              key: Key('memo_kind_${kind.name}'),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(_kindIcon(kind)),
              ),
              title: Text(kind.label),
              subtitle: Text(kind.description),
              onTap: () => Navigator.of(context).pop(kind),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
      ),
    ),
  );
}

/// テンプレート選択の結果（[option] が null なら「テンプレートなし」）。
class _MemoTemplateChoice {
  const _MemoTemplateChoice(this.option);
  final MemoTemplateOption? option;
}

Future<_MemoTemplateChoice?> _pickMemoTemplate(
  BuildContext context,
  WidgetRef ref,
  MemoKind kind,
) {
  return showModalBottomSheet<_MemoTemplateChoice>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final theme = Theme.of(context);
        final options = ref.watch(memoTemplateOptionsProvider(kind));
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.lg,
                  AppSpace.sm,
                ),
                child: Text(
                  '${kind.label}のテンプレート',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              ListTile(
                key: const Key('memo_template_none'),
                leading: const Icon(Icons.edit_note),
                title: const Text('テンプレートなし'),
                subtitle: const Text('空の状態から作成する'),
                onTap: () =>
                    Navigator.of(context).pop(const _MemoTemplateChoice(null)),
              ),
              for (final option in options)
                ListTile(
                  leading: Icon(_kindIcon(option.kind)),
                  title: Text(option.name),
                  trailing: option.isPreset
                      ? const _PresetBadge()
                      : IconButton(
                          tooltip: 'テンプレートを削除',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            await ref
                                .read(memoTemplateRepositoryProvider)
                                .deleteTemplate(option.id);
                          },
                        ),
                  onTap: () =>
                      Navigator.of(context).pop(_MemoTemplateChoice(option)),
                ),
              const SizedBox(height: AppSpace.sm),
            ],
          ),
        );
      },
    ),
  );
}

class _PresetBadge extends StatelessWidget {
  const _PresetBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '標準',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// シード（テンプレート → メモの初期状態）
// ---------------------------------------------------------------------------

GenbaMemo _seedMemo({
  required MemoKind kind,
  MemoTemplateOption? option,
  required String genbaId,
  required String ownerId,
  required int sortOrder,
  required DateTime now,
  required String id,
}) {
  return GenbaMemo(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    category: option?.category ?? MemoCategory.other,
    kind: kind,
    title: option?.title ?? '',
    body: option?.body ?? '',
    content: _seedContent(kind, option?.content),
    sortOrder: sortOrder,
    createdAt: now,
    updatedAt: now,
  );
}

MemoContent? _seedContent(MemoKind kind, MemoContent? from) {
  switch (kind) {
    case MemoKind.free:
      return null;
    case MemoKind.checklist:
      return MemoContent(
        checklist: [
          for (final i in from?.checklist ?? const <MemoChecklistItem>[])
            i.copyWith(checked: false),
        ],
      );
    case MemoKind.bingo:
      final b = from?.bingo;
      return MemoContent(
        bingo: b == null
            ? const MemoBingo(size: 3)
            : b.copyWith(selected: const []),
      );
    case MemoKind.vote:
      final v = from?.vote;
      return MemoContent(
        vote: (v ?? const MemoVote()).copyWith(votes: const []),
      );
  }
}

// ---------------------------------------------------------------------------
// 種類別エディタ
// ---------------------------------------------------------------------------

class _ChecklistRow {
  _ChecklistRow({required this.id, required this.controller, this.checked});
  final String id;
  final TextEditingController controller;
  bool? checked;
}

class _OptionRow {
  _OptionRow({required this.id, required this.controller});
  final String id;
  final TextEditingController controller;
}

class _MemoEditorSheet extends ConsumerStatefulWidget {
  const _MemoEditorSheet({required this.memo, required this.isEdit});

  final GenbaMemo memo;
  final bool isEdit;

  @override
  ConsumerState<_MemoEditorSheet> createState() => _MemoEditorSheetState();
}

class _MemoEditorSheetState extends ConsumerState<_MemoEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _voteDescription;

  // checklist
  final List<_ChecklistRow> _checklist = [];

  // bingo
  int _bingoSize = 3;
  List<TextEditingController> _bingoCells = [];
  Set<int> _bingoSelected = {};
  bool _bingoInputMode = true;

  // vote
  final List<_OptionRow> _options = [];
  bool _allowDuplicate = false;
  List<MemoVoteRecord> _votes = [];

  bool _saving = false;

  MemoKind get _kind => widget.memo.kind;
  String get _voterId =>
      ref.read(authRepositoryProvider).currentUser?.id ?? widget.memo.ownerId;

  @override
  void initState() {
    super.initState();
    final m = widget.memo;
    _title = TextEditingController(text: m.title);
    _body = TextEditingController(text: m.body);
    _voteDescription =
        TextEditingController(text: m.content?.vote?.description ?? '');

    for (final item in m.content?.checklist ?? const <MemoChecklistItem>[]) {
      _checklist.add(
        _ChecklistRow(
          id: item.id,
          controller: TextEditingController(text: item.text),
          checked: item.checked,
        ),
      );
    }

    final bingo = m.content?.bingo;
    _bingoSize = bingo?.size ?? 3;
    _bingoSelected = {...?bingo?.selected};
    _rebuildBingoCells(bingo?.cells ?? const []);
    _bingoInputMode = !widget.isEdit; // 編集で開いたらプレイ寄りに

    final vote = m.content?.vote;
    _allowDuplicate = vote?.allowDuplicate ?? false;
    _votes = [...?vote?.votes];
    for (final o in vote?.options ?? const <MemoVoteOption>[]) {
      _options.add(
        _OptionRow(id: o.id, controller: TextEditingController(text: o.text)),
      );
    }
  }

  void _rebuildBingoCells(List<String> cells) {
    for (final c in _bingoCells) {
      c.dispose();
    }
    final count = _bingoSize * _bingoSize;
    _bingoCells = [
      for (var i = 0; i < count; i++)
        TextEditingController(text: i < cells.length ? cells[i] : ''),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _voteDescription.dispose();
    for (final r in _checklist) {
      r.controller.dispose();
    }
    for (final c in _bingoCells) {
      c.dispose();
    }
    for (final o in _options) {
      o.controller.dispose();
    }
    super.dispose();
  }

  MemoContent? _buildContent() {
    switch (_kind) {
      case MemoKind.free:
        return null;
      case MemoKind.checklist:
        return MemoContent(
          checklist: [
            for (var i = 0; i < _checklist.length; i++)
              MemoChecklistItem(
                id: _checklist[i].id,
                text: _checklist[i].controller.text.trim(),
                checked: _checklist[i].checked ?? false,
                sortOrder: i,
              ),
          ]..removeWhere((it) => it.text.isEmpty),
        );
      case MemoKind.bingo:
        return MemoContent(
          bingo: MemoBingo(
            size: _bingoSize,
            cells: [for (final c in _bingoCells) c.text.trim()],
            selected: _bingoSelected.toList()..sort(),
          ),
        );
      case MemoKind.vote:
        final options = [
          for (var i = 0; i < _options.length; i++)
            MemoVoteOption(
              id: _options[i].id,
              text: _options[i].controller.text.trim(),
              sortOrder: i,
            ),
        ]..removeWhere((o) => o.text.isEmpty);
        final keepIds = options.map((o) => o.id).toSet();
        return MemoContent(
          vote: MemoVote(
            description: _voteDescription.text.trim(),
            options: options,
            votes: _votes.where((v) => keepIds.contains(v.optionId)).toList(),
            allowDuplicate: _allowDuplicate,
          ),
        );
    }
  }

  GenbaMemo _buildMemo(DateTime now) => widget.memo.copyWith(
        title: _title.text.trim(),
        body: _body.text.trim(),
        content: _buildContent(),
        updatedAt: now,
      );

  bool _isEmpty(GenbaMemo m) {
    if (m.title.isNotEmpty) return false;
    switch (m.kind) {
      case MemoKind.free:
        return m.body.isEmpty;
      case MemoKind.checklist:
        return (m.content?.checklist ?? const []).isEmpty;
      case MemoKind.bingo:
        return (m.content?.bingo?.cells ?? const []).every((c) => c.isEmpty);
      case MemoKind.vote:
        return (m.content?.vote?.options ?? const []).isEmpty;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final now = ref.read(clockProvider).now().toUtc();
    final memo = _buildMemo(now);
    if (_isEmpty(memo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルか内容を入力してください')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(genbaRepositoryProvider).upsertMemo(memo);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(result, 'メモを保存しました');
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result =
        await ref.read(genbaRepositoryProvider).deleteMemo(widget.memo.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(result, 'メモを削除しました');
  }

  Future<void> _saveAsTemplate() async {
    final controller = TextEditingController(
      text: _title.text.trim().isNotEmpty ? _title.text.trim() : _kind.label,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('テンプレートとして保存'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'テンプレート名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final now = ref.read(clockProvider).now().toUtc();
    final memo = _buildMemo(now);
    final result = await ref
        .read(memoTemplateActionsProvider)
        .saveMemoAsTemplate(name: name, memo: memo);
    if (!mounted) return;
    _showResult(result, 'テンプレートに保存しました');
  }

  void _showResult(Result<void> result, String okMessage) {
    final message = result.when(ok: (_) => okMessage, err: (f) => f.message);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isEdit ? 'メモを編集' : '${_kind.label}を追加';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 12, AppSpace.sm, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'テンプレートとして保存',
                  icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: _saving ? null : _saveAsTemplate,
                ),
                if (widget.isEdit)
                  IconButton(
                    tooltip: '削除',
                    color: theme.colorScheme.error,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _saving ? null : _delete,
                  ),
                IconButton(
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close),
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpace.lg),
              children: [
                TextField(
                  key: const Key('memo_title'),
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpace.md),
                ..._kindBody(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppSpace.lg, 4, AppSpace.lg, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('memo_save'),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: '保存中',
                          ),
                        )
                      : const Text('保存する'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _kindBody() => switch (_kind) {
        MemoKind.free => _freeBody(),
        MemoKind.checklist => _checklistBody(),
        MemoKind.bingo => _bingoBody(),
        MemoKind.vote => _voteBody(),
      };

  // ---- 自由メモ ----
  List<Widget> _freeBody() => [
        TextField(
          key: const Key('memo_body'),
          controller: _body,
          decoration: const InputDecoration(
            labelText: '本文',
            alignLabelWithHint: true,
          ),
          maxLines: 6,
        ),
      ];

  // ---- チェックリスト ----
  List<Widget> _checklistBody() {
    return [
      for (var i = 0; i < _checklist.length; i++)
        Padding(
          key: ValueKey('checklist_${_checklist[i].id}'),
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: Row(
            children: [
              Checkbox(
                value: _checklist[i].checked ?? false,
                onChanged: (v) =>
                    setState(() => _checklist[i].checked = v ?? false),
              ),
              Expanded(
                child: TextField(
                  controller: _checklist[i].controller,
                  decoration: const InputDecoration(
                    hintText: '項目',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: '項目を削除',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _checklist[i].controller.dispose();
                    _checklist.removeAt(i);
                  });
                },
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('checklist_add'),
          onPressed: () => setState(
            () => _checklist.add(
              _ChecklistRow(
                id: _uuid.v4(),
                controller: TextEditingController(),
                checked: false,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('項目を追加'),
        ),
      ),
    ];
  }

  // ---- BINGO ----
  List<Widget> _bingoBody() {
    final theme = Theme.of(context);
    final bingo = MemoBingo(
      size: _bingoSize,
      cells: [for (final c in _bingoCells) c.text],
      selected: _bingoSelected.toList(),
    );
    final lines = bingo.lineCount;
    return [
      Wrap(
        spacing: AppSpace.sm,
        children: [
          for (final size in [3, 4, 5])
            ChoiceChip(
              label: Text('$size×$size'),
              selected: _bingoSize == size,
              onSelected: (_) => setState(() {
                _bingoSize = size;
                _bingoSelected = {};
                _rebuildBingoCells(const []);
              }),
            ),
        ],
      ),
      const SizedBox(height: AppSpace.sm),
      Row(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('入力')),
              ButtonSegment(value: false, label: Text('プレイ')),
            ],
            selected: {_bingoInputMode},
            onSelectionChanged: (s) =>
                setState(() => _bingoInputMode = s.first),
          ),
          const Spacer(),
          if (lines > 0)
            Text(
              'BINGO! ×$lines',
              key: const Key('bingo_result'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpace.sm),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: _bingoSize,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (var i = 0; i < _bingoCells.length; i++)
            _BingoCell(
              key: ValueKey('bingo_cell_$i'),
              controller: _bingoCells[i],
              inputMode: _bingoInputMode,
              selected: _bingoSelected.contains(i),
              onToggle: () => setState(() {
                if (_bingoSelected.contains(i)) {
                  _bingoSelected.remove(i);
                } else {
                  _bingoSelected.add(i);
                }
              }),
            ),
        ],
      ),
    ];
  }

  // ---- 投票 ----
  List<Widget> _voteBody() {
    final theme = Theme.of(context);
    final voter = _voterId;
    return [
      TextField(
        controller: _voteDescription,
        decoration: const InputDecoration(
          labelText: '説明（任意）',
          alignLabelWithHint: true,
        ),
        maxLines: 2,
      ),
      const SizedBox(height: AppSpace.sm),
      SwitchListTile(
        key: const Key('vote_allow_duplicate'),
        contentPadding: EdgeInsets.zero,
        title: const Text('重複投票を許可'),
        subtitle: Text(
          _allowDuplicate ? '同じ人が複数の選択肢へ投票できます' : '1人1票（他へ入れると切り替わります）',
        ),
        value: _allowDuplicate,
        onChanged: (v) => setState(() => _allowDuplicate = v),
      ),
      const SizedBox(height: AppSpace.sm),
      for (var i = 0; i < _options.length; i++)
        Padding(
          key: ValueKey('vote_option_${_options[i].id}'),
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: Row(
            children: [
              _VoteButton(
                count: _votes.where((v) => v.optionId == _options[i].id).length,
                voted: _votes.any(
                  (v) => v.optionId == _options[i].id && v.voterId == voter,
                ),
                onTap: () => setState(() {
                  _votes = _castVote(_options[i].id, voter);
                }),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: TextField(
                  controller: _options[i].controller,
                  decoration: const InputDecoration(
                    hintText: '選択肢',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: '選択肢を削除',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() {
                  _votes = _votes
                      .where((v) => v.optionId != _options[i].id)
                      .toList();
                  _options[i].controller.dispose();
                  _options.removeAt(i);
                }),
              ),
            ],
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('vote_add_option'),
          onPressed: () => setState(
            () => _options.add(
              _OptionRow(id: _uuid.v4(), controller: TextEditingController()),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('選択肢を追加'),
        ),
      ),
      Text(
        '投票総数: ${_votes.length}',
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  /// 現在の状態に純粋ロジック（[MemoVote.castVote]）を適用して票リストを返す。
  List<MemoVoteRecord> _castVote(String optionId, String voter) {
    final vote = MemoVote(votes: _votes, allowDuplicate: _allowDuplicate);
    return vote.castVote(voterId: voter, optionId: optionId).votes;
  }
}

class _BingoCell extends StatelessWidget {
  const _BingoCell({
    super.key,
    required this.controller,
    required this.inputMode,
    required this.selected,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool inputMode;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    if (inputMode) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          maxLines: 2,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '入力',
            contentPadding: EdgeInsets.all(2),
          ),
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(
          controller.text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.count,
    required this.voted,
    required this.onTap,
  });

  final int count;
  final bool voted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: voted
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              voted ? Icons.how_to_vote : Icons.how_to_vote_outlined,
              size: 16,
              color: voted
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: theme.textTheme.labelLarge?.copyWith(
                color: voted
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
