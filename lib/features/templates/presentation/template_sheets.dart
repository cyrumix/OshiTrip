import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/result.dart';
import '../../genba/domain/genba.dart';
import '../application/template_actions.dart';
import '../application/template_providers.dart';
import '../domain/template_presets.dart';
import 'template_manage_screen.dart';

/// 「テンプレートから追加」ボトムシートを開く。[existing] は現在の現場の
/// Todo/持ち物一式（重複判定・件数算出に使う）。
Future<void> showApplyTemplateSheet(
  BuildContext context, {
  required String genbaId,
  required TodoItemType itemType,
  required List<GenbaTodo> existing,
}) {
  return _showSheet(
    context,
    _ApplyTemplateSheet(
      genbaId: genbaId,
      itemType: itemType,
      existing: existing,
    ),
  );
}

/// 「現在の内容をテンプレートに保存」ボトムシートを開く。[items] はその種別の
/// 現在の項目（完了済みも候補に含める）。
Future<void> showSaveTemplateSheet(
  BuildContext context, {
  required TodoItemType itemType,
  required List<GenbaTodo> items,
}) {
  return _showSheet(
    context,
    _SaveTemplateSheet(itemType: itemType, items: items),
  );
}

Future<void> _showSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    ),
  );
}

/// テンプレート系ボトムシートの共通枠（タイトル + スクロール本文 + 下部アクション）。
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final Widget body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: PrimaryScrollController(
              controller: scrollController,
              child: body,
            ),
          ),
          if (action != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: action,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// テンプレートから追加
// ---------------------------------------------------------------------------

class _ApplyTemplateSheet extends ConsumerStatefulWidget {
  const _ApplyTemplateSheet({
    required this.genbaId,
    required this.itemType,
    required this.existing,
  });

  final String genbaId;
  final TodoItemType itemType;
  final List<GenbaTodo> existing;

  @override
  ConsumerState<_ApplyTemplateSheet> createState() =>
      _ApplyTemplateSheetState();
}

class _ApplyTemplateSheetState extends ConsumerState<_ApplyTemplateSheet> {
  TemplateOption? _selected;

  /// 選択中テンプレートの各項目を追加するか（index -> checked）。
  final Map<int, bool> _checked = {};
  bool _applying = false;

  Set<String> get _existingNames => {
        for (final t in widget.existing)
          if (t.type == widget.itemType) t.name.trim(),
      };

  void _selectTemplate(TemplateOption option) {
    setState(() {
      _selected = option;
      _checked
        ..clear()
        // 既定は全選択（重複は適用時にスキップして件数で知らせる）。
        ..addEntries([
          for (var i = 0; i < option.items.length; i++) MapEntry(i, true),
        ]);
    });
  }

  Future<void> _apply() async {
    final option = _selected;
    if (option == null || _applying) return;
    final selectedItems = [
      for (var i = 0; i < option.items.length; i++)
        if (_checked[i] ?? false) option.items[i],
    ];
    if (selectedItems.isEmpty) return;
    setState(() => _applying = true);
    final result = await ref.read(templateActionsProvider).applyTemplate(
          genbaId: widget.genbaId,
          itemType: widget.itemType,
          selected: selectedItems,
          existing: widget.existing,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    result.when(
      ok: (outcome) {
        final base = '${outcome.added}件を追加しました';
        final msg = outcome.skipped > 0
            ? '$base（${outcome.skipped}件は登録済みのため追加しませんでした）'
            : base;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
      err: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final option = _selected;
    if (option == null) {
      return _SheetScaffold(
        title: '${widget.itemType.label}をテンプレートから追加',
        body: _TemplatePicker(
          itemType: widget.itemType,
          onSelected: _selectTemplate,
        ),
      );
    }
    final checkedCount = _checked.values.where((v) => v).length;
    return _SheetScaffold(
      title: option.name,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('テンプレートを選び直す'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  for (var i = 0; i < option.items.length; i++) {
                    _checked[i] = true;
                  }
                }),
                child: const Text('すべて選択'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  for (var i = 0; i < option.items.length; i++) {
                    _checked[i] = false;
                  }
                }),
                child: const Text('すべて解除'),
              ),
            ],
          ),
          for (var i = 0; i < option.items.length; i++)
            _ApplyItemTile(
              item: option.items[i],
              checked: _checked[i] ?? false,
              alreadyRegistered:
                  _existingNames.contains(option.items[i].name.trim()),
              onChanged: (v) => setState(() => _checked[i] = v),
            ),
        ],
      ),
      action: FilledButton(
        onPressed: (checkedCount == 0 || _applying) ? null : _apply,
        child: Text(
          _applying ? '追加しています…' : '$checkedCount件を追加',
        ),
      ),
    );
  }
}

class _ApplyItemTile extends StatelessWidget {
  const _ApplyItemTile({
    required this.item,
    required this.checked,
    required this.alreadyRegistered,
    required this.onChanged,
  });

  final TemplateOptionItem item;
  final bool checked;
  final bool alreadyRegistered;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: checked,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(item.name),
      subtitle: alreadyRegistered
          ? Text(
              '登録済み',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: tokens.textSecondary),
            )
          : (item.priority == TodoPriority.high
              ? Text(
                  '重要',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: tokens.textSecondary),
                )
              : null),
    );
  }
}

/// テンプレート選択リスト（標準プリセット + ユーザーテンプレート）。
class _TemplatePicker extends ConsumerWidget {
  const _TemplatePicker({required this.itemType, required this.onSelected});

  final TodoItemType itemType;
  final ValueChanged<TemplateOption> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(templateOptionsProvider(itemType));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: AppCard(
              onTap: () => onSelected(option),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                option.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (option.isPreset) ...[
                              const SizedBox(width: AppSpace.sm),
                              const _PresetBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${option.items.length}項目',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTokens.of(context).textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PresetBadge extends StatelessWidget {
  const _PresetBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '標準',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 現在の内容をテンプレートに保存
// ---------------------------------------------------------------------------

class _SaveTemplateSheet extends ConsumerStatefulWidget {
  const _SaveTemplateSheet({required this.itemType, required this.items});

  final TodoItemType itemType;
  final List<GenbaTodo> items;

  @override
  ConsumerState<_SaveTemplateSheet> createState() => _SaveTemplateSheetState();
}

class _SaveTemplateSheetState extends ConsumerState<_SaveTemplateSheet> {
  final _name = TextEditingController();
  final Map<String, bool> _checked = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 完了済みも候補に含め、既定で全選択する。
    for (final t in widget.items) {
      _checked[t.id] = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレート名を入力してください')),
      );
      return;
    }
    final selected = [
      for (final t in widget.items)
        if (_checked[t.id] ?? false) t,
    ];
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存する項目を1つ以上選択してください')),
      );
      return;
    }
    setState(() => _saving = true);
    final Result<void> result =
        await ref.read(templateActionsProvider).saveCurrentAsTemplate(
              name: _name.text,
              itemType: widget.itemType,
              todos: selected,
            );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isOk) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.when(
            ok: (_) => 'テンプレート「${_name.text.trim()}」を保存しました',
            err: (f) => f.message,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _checked.values.where((v) => v).length;
    return _SheetScaffold(
      title: '${widget.itemType.label}をテンプレートに保存',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'テンプレート名 *'),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '保存する項目',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  for (final t in widget.items) {
                    _checked[t.id] = true;
                  }
                }),
                child: const Text('すべて選択'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  for (final t in widget.items) {
                    _checked[t.id] = false;
                  }
                }),
                child: const Text('すべて解除'),
              ),
            ],
          ),
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Text(
                '保存できる項目がありません。',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTokens.of(context).textSecondary),
              ),
            ),
          for (final t in widget.items)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked[t.id] ?? false,
              onChanged: (v) => setState(() => _checked[t.id] = v ?? false),
              title: Text(t.name),
              subtitle: t.isDone
                  ? Text(
                      '完了状態は保存されません',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTokens.of(context).textSecondary,
                          ),
                    )
                  : null,
            ),
        ],
      ),
      action: FilledButton(
        onPressed: (checkedCount == 0 || _saving) ? null : _save,
        child: Text(_saving ? '保存しています…' : '$checkedCount件を保存'),
      ),
    );
  }
}

/// TodoTab から「テンプレートを管理」画面へ遷移する。
void openTemplateManager(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const TemplateManageScreen(),
    ),
  );
}
