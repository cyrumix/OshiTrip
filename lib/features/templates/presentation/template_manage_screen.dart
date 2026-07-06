import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/providers.dart';
import '../../genba/domain/genba.dart';
import '../application/template_providers.dart';
import '../domain/template_presets.dart';
import '../domain/todo_template.dart';

const _uuid = Uuid();

/// テンプレート管理画面。標準プリセットは閲覧・適用のみ（編集不可）で表示し、
/// ユーザーテンプレートは新規作成・名称変更・項目CRUD・並び替え・削除できる。
class TemplateManageScreen extends ConsumerWidget {
  const TemplateManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(userTemplatesProvider);
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'テンプレートを管理',
      floatingActionButton: AppFab(
        heroTag: 'template_new_fab',
        tooltip: 'テンプレートを新規作成',
        onPressed: () => _createTemplate(context, ref),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SectionHeader(title: '標準プリセット（閲覧・適用のみ）'),
          for (final preset in kAllPresets)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: 6,
              ),
              child: AppCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PresetDetailScreen(preset: preset),
                  ),
                ),
                child: _TemplateRow(
                  name: preset.name,
                  itemType: preset.itemType,
                  itemCount: preset.items.length,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          const SectionHeader(title: 'マイテンプレート'),
          templatesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpace.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Text(
                'テンプレートの読み込みに失敗しました。',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTokens.of(context).textSecondary),
              ),
            ),
            data: (templates) {
              if (templates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    AppSpace.sm,
                    AppSpace.lg,
                    AppSpace.lg,
                  ),
                  child: Text(
                    'まだ自分のテンプレートはありません。右下の＋から作成するか、'
                    'Todo・持ち物タブの「現在の内容をテンプレートに保存」で作れます。',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTokens.of(context).textSecondary),
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in templates)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: 6,
                      ),
                      child: AppCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TemplateEditScreen(templateId: t.template.id),
                          ),
                        ),
                        child: _TemplateRow(
                          name: t.template.name,
                          itemType: t.template.itemType,
                          itemCount: t.items.length,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createTemplate(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<TodoTemplate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _NewTemplateSheet(),
      ),
    );
    if (created == null || !context.mounted) return;
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return;
    final result =
        await ref.read(templateRepositoryProvider).upsertTemplate(created);
    if (!context.mounted) return;
    if (result.isOk) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TemplateEditScreen(templateId: created.id),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.message)),
      );
    }
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.name,
    required this.itemType,
    required this.itemCount,
    this.trailing,
  });

  final String name;
  final TodoItemType itemType;
  final int itemCount;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tokens.primarySoft,
          ),
          child: Icon(
            itemType == TodoItemType.belonging
                ? Icons.backpack_outlined
                : Icons.check_box_outlined,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${itemType.label}・$itemCount項目',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.textSecondary),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 新規テンプレート作成シート（名称 + 種別）。作成した [TodoTemplate] を返す。
class _NewTemplateSheet extends ConsumerStatefulWidget {
  const _NewTemplateSheet();

  @override
  ConsumerState<_NewTemplateSheet> createState() => _NewTemplateSheetState();
}

class _NewTemplateSheetState extends ConsumerState<_NewTemplateSheet> {
  final _name = TextEditingController();
  TodoItemType _type = TodoItemType.todo;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テンプレート名を入力してください')),
      );
      return;
    }
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final now = ref.read(clockProvider).now().toUtc();
    Navigator.of(context).pop(
      TodoTemplate(
        id: _uuid.v4(),
        ownerId: owner,
        name: _name.text.trim(),
        itemType: _type,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'テンプレートを新規作成',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.md),
          Text('種別', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpace.sm,
            children: [
              for (final type in TodoItemType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'テンプレート名 *'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('作成して項目を追加'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 標準プリセットの読み取り専用詳細（閲覧のみ、編集・削除不可）。
class _PresetDetailScreen extends StatelessWidget {
  const _PresetDetailScreen({required this.preset});

  final TemplatePreset preset;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return AppScaffold(
      title: preset.name,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          96,
        ),
        children: [
          Text(
            '${preset.itemType.label}・${preset.items.length}項目（標準プリセット・編集不可）',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final item in preset.items)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator, size: 18),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: Text(item.name)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ユーザーテンプレートの編集画面（名称変更・項目追加/編集/削除・並び替え・削除）。
class TemplateEditScreen extends ConsumerWidget {
  const TemplateEditScreen({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(userTemplatesProvider).valueOrNull;
    final found = templates
        ?.where((t) => t.template.id == templateId)
        .cast<TodoTemplateWithItems?>()
        .firstOrNull;

    // 削除された（ストリームから消えた）場合は自動で戻る。
    if (templates != null && found == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const AppScaffold(title: 'テンプレート', body: SizedBox.shrink());
    }
    if (found == null) {
      return const AppScaffold(
        title: 'テンプレート',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _TemplateEditBody(bundle: found);
  }
}

class _TemplateEditBody extends ConsumerWidget {
  const _TemplateEditBody({required this.bundle});

  final TodoTemplateWithItems bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = bundle.template;
    final items = bundle.sortedItems;
    final repo = ref.read(templateRepositoryProvider);

    Future<void> rename() async {
      final name = await _promptText(
        context,
        title: 'テンプレート名を変更',
        initial: template.name,
        label: 'テンプレート名 *',
      );
      if (name == null || name.isEmpty || !context.mounted) return;
      final now = ref.read(clockProvider).now().toUtc();
      final res = await repo.upsertTemplate(
        template.copyWith(name: name, updatedAt: now),
      );
      if (context.mounted) {
        _snack(
          context,
          res.isOk ? '名称を変更しました' : res.failureOrNull!.message,
        );
      }
    }

    Future<void> deleteTemplate() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('テンプレートを削除'),
          content: Text('「${template.name}」を削除します。この操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除する'),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      final res = await repo.deleteTemplate(template.id);
      if (!context.mounted) return;
      if (res.isOk) {
        unawaited(Navigator.of(context).maybePop());
      } else {
        _snack(context, res.failureOrNull!.message);
      }
    }

    Future<void> addItem() async {
      final result = await _showItemEditor(
        context,
        itemType: template.itemType,
      );
      if (result == null || !context.mounted) return;
      final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
      final now = ref.read(clockProvider).now().toUtc();
      final res = await repo.upsertItem(
        TodoTemplateItem(
          id: _uuid.v4(),
          templateId: template.id,
          ownerId: owner,
          name: result.name,
          priority:
              template.itemType == TodoItemType.todo ? result.priority : null,
          memo: result.memo,
          sortOrder: items.isEmpty ? 0 : items.last.sortOrder + 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (context.mounted && !res.isOk) {
        _snack(context, res.failureOrNull!.message);
      }
    }

    Future<void> editItem(TodoTemplateItem item) async {
      final result = await _showItemEditor(
        context,
        itemType: template.itemType,
        existing: item,
      );
      if (result == null || !context.mounted) return;
      final now = ref.read(clockProvider).now().toUtc();
      final res = await repo.upsertItem(
        item.copyWith(
          name: result.name,
          priority:
              template.itemType == TodoItemType.todo ? result.priority : null,
          memo: result.memo,
          updatedAt: now,
        ),
      );
      if (context.mounted && !res.isOk) {
        _snack(context, res.failureOrNull!.message);
      }
    }

    Future<void> deleteItem(TodoTemplateItem item) async {
      final res = await repo.deleteItem(item.id);
      if (context.mounted && !res.isOk) {
        _snack(context, res.failureOrNull!.message);
      }
    }

    // onReorderItem は削除後の最終 index を渡す（newIndex 補正は不要）。
    Future<void> reorder(int oldIndex, int newIndex) async {
      final reordered = [...items];
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);
      final now = ref.read(clockProvider).now().toUtc();
      final renumbered = [
        for (var i = 0; i < reordered.length; i++)
          reordered[i].copyWith(sortOrder: i, updatedAt: now),
      ];
      final res = await repo.saveTemplateWithItems(
        template: template.copyWith(updatedAt: now),
        items: renumbered,
      );
      if (context.mounted && !res.isOk) {
        _snack(context, res.failureOrNull!.message);
      }
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(template.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'テンプレート名を変更',
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed: rename,
          ),
          PopupMenuButton<String>(
            tooltip: 'その他',
            onSelected: (v) {
              if (v == 'delete') deleteTemplate();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('テンプレートを削除…')),
            ],
          ),
        ],
      ),
      floatingActionButton: AppFab(
        heroTag: 'template_item_fab',
        tooltip: '項目を追加',
        onPressed: addItem,
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Text(
                  '${template.itemType.label}の項目がありません。右下の＋から追加してください。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.of(context).textSecondary,
                      ),
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                96,
              ),
              itemCount: items.length,
              onReorderItem: reorder,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  key: ValueKey(item.id),
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(right: AppSpace.sm),
                            child: Icon(Icons.drag_indicator, size: 20),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name),
                              if (template.itemType == TodoItemType.todo &&
                                  item.priority == TodoPriority.high)
                                Text(
                                  '重要',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            AppTokens.of(context).textSecondary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '編集',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => editItem(item),
                        ),
                        IconButton(
                          tooltip: '削除',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => deleteItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// 項目編集の入力結果（名前・重要度・メモ）。
class _ItemEditResult {
  const _ItemEditResult({required this.name, this.priority, this.memo});
  final String name;
  final TodoPriority? priority;
  final String? memo;
}

Future<_ItemEditResult?> _showItemEditor(
  BuildContext context, {
  required TodoItemType itemType,
  TodoTemplateItem? existing,
}) {
  return showModalBottomSheet<_ItemEditResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _ItemEditorSheet(itemType: itemType, existing: existing),
    ),
  );
}

class _ItemEditorSheet extends StatefulWidget {
  const _ItemEditorSheet({required this.itemType, this.existing});

  final TodoItemType itemType;
  final TodoTemplateItem? existing;

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _memo;
  late TodoPriority _priority;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _memo = TextEditingController(text: widget.existing?.memo ?? '');
    _priority = widget.existing?.priority ?? TodoPriority.normal;
  }

  @override
  void dispose() {
    _name.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名前を入力してください')));
      return;
    }
    Navigator.of(context).pop(
      _ItemEditResult(
        name: _name.text.trim(),
        // 持ち物は重要度を持たない。
        priority: widget.itemType == TodoItemType.todo ? _priority : null,
        memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? '項目を編集' : '${widget.itemType.label}の項目を追加',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '名前 *'),
          ),
          // 持ち物には重要度を持たせない（Todo のみ表示する）。
          if (widget.itemType == TodoItemType.todo) ...[
            const SizedBox(height: AppSpace.md),
            Text('重要度', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                for (final p in TodoPriority.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _memo,
            decoration: const InputDecoration(labelText: 'メモ'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('保存する'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  required String initial,
  required String label,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      initial: initial,
      label: label,
    ),
  );
}

/// 名前入力ダイアログ。TextEditingController をダイアログ自身のライフサイクルで
/// 所有・破棄する（showDialog の Future 完了＝pop 呼び出し時点であり、退場
/// アニメーション中はまだ TextField が生存しているため、呼び出し元で
/// `whenComplete(controller.dispose)` すると「disposed 後の Controller 使用」で
/// 描画中に例外が出る。genba_form_screen の _NamePromptDialog と同じ構造）。
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.initial,
    required this.label,
  });

  final String title;
  final String initial;
  final String label;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('変更する'),
        ),
      ],
    );
  }
}
