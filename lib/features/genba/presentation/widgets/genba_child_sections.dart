import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../templates/presentation/template_sheets.dart';
import '../../application/genba_actions_controller.dart';
import '../../domain/genba.dart';
import 'action_feedback.dart';
import 'child_editors.dart';

/// 現場詳細の子データタブ（チケット/交通/宿泊/Todo/メモ, design-spec §7.2）。
///
/// 各タブは独立したスクロール領域。既存のCRUD（child_editors）と
/// [GenbaActionsController]（二重タップ防止・型付き失敗表示）へ接続する。

/// タブ共通のリスト外装。スクロール位置はタブ切替後も保持する（§5）。
class GenbaTabList extends StatelessWidget {
  const GenbaTabList({
    super.key,
    required this.storageKey,
    required this.children,
  });

  final String storageKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PageStorageKey(storageKey),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        96,
      ),
      children: children,
    );
  }
}

class TicketTab extends ConsumerWidget {
  const TicketTab({super.key, required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genbaId = aggregate.genba.id;
    final busyKeys = ref.watch(genbaActionsControllerProvider(genbaId));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genbaId).notifier);
    return GenbaTabList(
      storageKey: 'genba_tab_ticket_$genbaId',
      children: [
        SectionHeader(
          title: 'チケット',
          count: aggregate.tickets.length,
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          action: TextButton.icon(
            onPressed: () => showTicketEditor(context, ref, genbaId: genbaId),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('追加'),
          ),
        ),
        if (aggregate.tickets.isEmpty)
          const AppCard(
            child: Text('未登録。取得状況を記録しておくと当日すぐ確認できます。'),
          ),
        for (final ticket in aggregate.tickets)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSpace.sm),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(
                [
                  ticket.acquisitionStatus.label,
                  ticket.paymentStatus.label,
                  ticket.issuanceStatus.label,
                ].join(' / '),
              ),
              subtitle: (ticket.seat != null || ticket.entryNumber != null)
                  ? Text(
                      [
                        if (ticket.seat != null) '座席 ${ticket.seat}',
                        if (ticket.entryNumber != null)
                          '整理番号 ${ticket.entryNumber}',
                      ].join(' / '),
                    )
                  : null,
              trailing: IconButton(
                tooltip: 'チケットを削除',
                icon: const Icon(Icons.delete_outline),
                onPressed: busyKeys.contains(controller().ticketKey(ticket.id))
                    ? null
                    : () async {
                        final ok = await confirmDangerAction(
                          context,
                          title: 'チケットを削除',
                          message: 'このチケット情報を削除します。',
                        );
                        if (!ok || !context.mounted) return;
                        final failure = await controller().deleteTicket(ticket);
                        if (context.mounted) {
                          handleActionResult(context, failure);
                        }
                      },
              ),
              onTap: () => showTicketEditor(
                context,
                ref,
                genbaId: genbaId,
                existing: ticket,
              ),
            ),
          ),
      ],
    );
  }
}

class TransportTab extends ConsumerWidget {
  const TransportTab({super.key, required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    final busyKeys = ref.watch(genbaActionsControllerProvider(genba.id));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);
    return GenbaTabList(
      storageKey: 'genba_tab_transport_${genba.id}',
      children: [
        SectionHeader(
          title: '交通',
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          action: TextButton.icon(
            onPressed: () =>
                showTransportEditor(context, ref, genbaId: genba.id),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('追加'),
          ),
        ),
        RequirementSelector(
          value: genba.transportRequirement,
          notRequiredLabel: '交通の登録は不要',
          enabled: !busyKeys.contains('transportRequirement'),
          onChanged: (req) async {
            final failure =
                await controller().setTransportRequirement(genba, req);
            if (context.mounted) handleActionResult(context, failure);
          },
        ),
        if (genba.transportRequirement != RequirementStatus.notRequired) ...[
          if (aggregate.transports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text('未登録'),
            ),
          for (final t in aggregate.transports)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(
                  t.direction == TransportDirection.outbound
                      ? Icons.arrow_circle_right_outlined
                      : Icons.arrow_circle_left_outlined,
                ),
                title: Text('${t.direction.label} ${t.methodDisplay}'.trim()),
                subtitle: (t.fromPlace != null || t.toPlace != null)
                    ? Text('${t.fromPlace ?? '?'} → ${t.toPlace ?? '?'}')
                    : null,
                trailing: IconButton(
                  tooltip: '交通を削除',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: busyKeys.contains(controller().transportKey(t.id))
                      ? null
                      : () async {
                          final ok = await confirmDangerAction(
                            context,
                            title: '交通を削除',
                            message: 'この交通情報を削除します。',
                          );
                          if (!ok || !context.mounted) return;
                          final failure = await controller().deleteTransport(t);
                          if (context.mounted) {
                            handleActionResult(context, failure);
                          }
                        },
                ),
                onTap: () => showTransportEditor(
                  context,
                  ref,
                  genbaId: genba.id,
                  existing: t,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class LodgingTab extends ConsumerWidget {
  const LodgingTab({super.key, required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    final busyKeys = ref.watch(genbaActionsControllerProvider(genba.id));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);
    return GenbaTabList(
      storageKey: 'genba_tab_lodging_${genba.id}',
      children: [
        SectionHeader(
          title: '宿泊',
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          action: TextButton.icon(
            onPressed: () => showLodgingEditor(context, ref, genbaId: genba.id),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('追加'),
          ),
        ),
        RequirementSelector(
          value: genba.lodgingRequirement,
          notRequiredLabel: '宿泊なし',
          enabled: !busyKeys.contains('lodgingRequirement'),
          onChanged: (req) async {
            final failure =
                await controller().setLodgingRequirement(genba, req);
            if (context.mounted) handleActionResult(context, failure);
          },
        ),
        if (genba.lodgingRequirement != RequirementStatus.notRequired) ...[
          if (aggregate.lodgings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text('未登録'),
            ),
          for (final l in aggregate.lodgings)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.hotel_outlined),
                title: Text(l.name ?? '宿泊先'),
                subtitle: l.checkinDate != null
                    ? Text(
                        '${l.checkinDate!.month}/${l.checkinDate!.day} チェックイン',
                      )
                    : null,
                trailing: IconButton(
                  tooltip: '宿泊を削除',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: busyKeys.contains(controller().lodgingKey(l.id))
                      ? null
                      : () async {
                          final ok = await confirmDangerAction(
                            context,
                            title: '宿泊を削除',
                            message: 'この宿泊情報を削除します。',
                          );
                          if (!ok || !context.mounted) return;
                          final failure = await controller().deleteLodging(l);
                          if (context.mounted) {
                            handleActionResult(context, failure);
                          }
                        },
                ),
                onTap: () => showLodgingEditor(
                  context,
                  ref,
                  genbaId: genba.id,
                  existing: l,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// 「未設定 / 必要 / 不要」の選択。「不要」と「未登録」を区別する（§7.4/§7.5）。
class RequirementSelector extends StatelessWidget {
  const RequirementSelector({
    super.key,
    required this.value,
    required this.notRequiredLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final RequirementStatus value;
  final String notRequiredLabel;
  final void Function(RequirementStatus value) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Wrap(
        spacing: AppSpace.sm,
        children: [
          ChoiceChip(
            label: const Text('必要'),
            selected: value == RequirementStatus.required,
            onSelected:
                enabled ? (_) => onChanged(RequirementStatus.required) : null,
          ),
          ChoiceChip(
            label: Text(notRequiredLabel),
            selected: value == RequirementStatus.notRequired,
            onSelected: enabled
                ? (_) => onChanged(RequirementStatus.notRequired)
                : null,
          ),
          ChoiceChip(
            label: const Text('未定'),
            selected: value == RequirementStatus.unknown,
            onSelected:
                enabled ? (_) => onChanged(RequirementStatus.unknown) : null,
          ),
        ],
      ),
    );
  }
}

/// Todo・持ち物タブ。両方とも [GenbaTodo] を同じ仕組みで扱い、[GenbaTodo.type]
/// によってセクション分けだけを行う（入力項目・保存処理は共通）。
/// タップ即座に見た目を切り替え（楽観更新）、保存に失敗したら実際の値
/// （変更されていない）に自然に戻り、理由を SnackBar で示す
/// （H-07/M-01: 失敗を成功表示しない・ロールバック）。
class TodoTab extends ConsumerStatefulWidget {
  const TodoTab({super.key, required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  ConsumerState<TodoTab> createState() => _TodoTabState();
}

class _TodoTabState extends ConsumerState<TodoTab> {
  /// 保存中の楽観表示値（todo.id -> 表示中のチェック状態）。
  final Map<String, bool> _optimistic = {};

  Future<void> _toggle(GenbaTodo todo, bool checked) async {
    setState(() => _optimistic[todo.id] = checked);
    final genbaId = widget.aggregate.genba.id;
    final failure = await ref
        .read(genbaActionsControllerProvider(genbaId).notifier)
        .toggleTodo(todo, checked);
    if (!mounted) return;
    // ストリームが実データを反映するまでの間だけ楽観値を使う。
    // 成功・失敗いずれでも楽観値は外し、実データ（成功時は新値、失敗時は
    // 変更されていない元の値）に委ねる。
    setState(() => _optimistic.remove(todo.id));
    if (failure != null) handleActionResult(context, failure);
  }

  // sortOrder は Repository のクエリで既に昇順ソート済み（§7.6）。
  // ここでは種別ごとに絞り込むだけで、その順序を保つ（再ソートしない）。
  Widget _row(GenbaTodo todo) {
    final genbaId = widget.aggregate.genba.id;
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _optimistic[todo.id] ?? todo.isDone,
      onChanged: (checked) => _toggle(todo, checked ?? false),
      title: Text(
        todo.name,
        style: todo.isDone
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
        semanticsLabel: '${todo.name}、${todo.isDone ? '完了済み' : '未完了'}',
      ),
      subtitle: (todo.dueDate != null || todo.priority == TodoPriority.high)
          ? Text(
              [
                if (todo.priority == TodoPriority.high) '重要',
                if (todo.dueDate != null)
                  '期限 ${todo.dueDate!.month}/${todo.dueDate!.day}',
              ].join(' / '),
            )
          : null,
      secondary: IconButton(
        tooltip: '${todo.type.label}を編集',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => showTodoEditor(
          context,
          ref,
          genbaId: genbaId,
          existing: todo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genbaId = widget.aggregate.genba.id;
    final todos = widget.aggregate.todos
        .where((t) => t.type == TodoItemType.todo)
        .toList(growable: false);
    final belongings = widget.aggregate.todos
        .where((t) => t.type == TodoItemType.belonging)
        .toList(growable: false);
    final tokens = AppTokens.of(context);
    return GenbaTabList(
      storageKey: 'genba_tab_todo_$genbaId',
      children: [
        // タブ全体で「Todo・持ち物」をまとめて管理していることが分かる見出し
        // （下の2セクションは同じ仕組み=GenbaTodoの種別違いであることを示す）。
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.md),
          child: Row(
            children: [
              Icon(Icons.checklist_rtl, size: 18, color: tokens.textSecondary),
              const SizedBox(width: AppSpace.xs),
              Text(
                'Todo・持ち物',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => openTemplateManager(context),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('テンプレートを管理'),
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Todo（残り${widget.aggregate.incompleteTodoCount}）',
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          action: TextButton.icon(
            onPressed: () => showTodoEditor(
              context,
              ref,
              genbaId: genbaId,
              initialType: TodoItemType.todo,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Todoを追加'),
          ),
        ),
        _TemplateSectionActions(
          itemType: TodoItemType.todo,
          genbaId: genbaId,
          allTodos: widget.aggregate.todos,
          sectionTodos: todos,
        ),
        if (todos.isEmpty)
          const AppCard(
            child: Text('Todoはまだありません。「Todoを追加」やテンプレートから準備リストを作りましょう。'),
          )
        else
          for (final todo in todos) _row(todo),
        SectionHeader(
          title: '持ち物（残り${widget.aggregate.incompleteBelongingCount}）',
          padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
          action: TextButton.icon(
            onPressed: () => showTodoEditor(
              context,
              ref,
              genbaId: genbaId,
              initialType: TodoItemType.belonging,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('持ち物を追加'),
          ),
        ),
        _TemplateSectionActions(
          itemType: TodoItemType.belonging,
          genbaId: genbaId,
          allTodos: widget.aggregate.todos,
          sectionTodos: belongings,
        ),
        if (belongings.isEmpty)
          const AppCard(
            child: Text('持ち物はまだありません。「持ち物を追加」やテンプレートから準備リストを作りましょう。'),
          )
        else
          for (final item in belongings) _row(item),
      ],
    );
  }
}

/// 各セクション（Todo/持ち物）のテンプレート操作（追加・保存）ボタン。
class _TemplateSectionActions extends StatelessWidget {
  const _TemplateSectionActions({
    required this.itemType,
    required this.genbaId,
    required this.allTodos,
    required this.sectionTodos,
  });

  final TodoItemType itemType;
  final String genbaId;

  /// 重複判定用の現場の全項目（種別は問わず、純関数側で絞り込む）。
  final List<GenbaTodo> allTodos;

  /// このセクションの項目（「現在の内容を保存」の対象）。
  final List<GenbaTodo> sectionTodos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Wrap(
        spacing: AppSpace.sm,
        children: [
          TextButton.icon(
            onPressed: () => showApplyTemplateSheet(
              context,
              genbaId: genbaId,
              itemType: itemType,
              existing: allTodos,
            ),
            icon: const Icon(Icons.library_add_outlined, size: 18),
            label: const Text('テンプレートから追加'),
          ),
          if (sectionTodos.isNotEmpty)
            TextButton.icon(
              onPressed: () => showSaveTemplateSheet(
                context,
                itemType: itemType,
                items: sectionTodos,
              ),
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('現在の内容をテンプレートに保存'),
            ),
        ],
      ),
    );
  }
}

class MemoTab extends ConsumerWidget {
  const MemoTab({super.key, required this.aggregate});

  final GenbaAggregate aggregate;

  /// 追加時にテンプレート（種類）を選ばせる。テンプレートは初期値・入力例の補助で
  /// あり、選ばずに「テンプレートなし」も選べる（§7.7）。
  Future<void> _addMemo(BuildContext context, WidgetRef ref) async {
    final category = await showModalBottomSheet<MemoCategory>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpace.md),
              child: Text('テンプレートを選ぶ'),
            ),
            for (final c in MemoCategoryLabel.templateChoices)
              ListTile(
                leading: Icon(
                  c == MemoCategory.other
                      ? Icons.edit_note
                      : Icons.sticky_note_2_outlined,
                ),
                title: Text(c.templateChoiceLabel),
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (category == null || !context.mounted) return;
    await showMemoEditor(
      context,
      ref,
      genbaId: aggregate.genba.id,
      category: category,
      initialSortOrder: aggregate.memos.length,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genbaId = aggregate.genba.id;
    final busyKeys = ref.watch(genbaActionsControllerProvider(genbaId));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genbaId).notifier);
    final memos = aggregate.sortedMemos;
    return GenbaTabList(
      storageKey: 'genba_tab_memo_$genbaId',
      children: [
        SectionHeader(
          title: 'メモ',
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          action: TextButton.icon(
            key: const Key('memo_add_button'),
            onPressed: () => _addMemo(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('追加'),
          ),
        ),
        if (memos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Text('メモはまだありません。＋からテンプレートを選んで追加できます。'),
          ),
        for (var i = 0; i < memos.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSpace.sm),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(
                memos[i].title.isNotEmpty
                    ? memos[i].title
                    : memos[i].category.label,
              ),
              subtitle: memos[i].body.isNotEmpty
                  ? Text(
                      memos[i].body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (memos.length > 1) ...[
                    IconButton(
                      tooltip: '上へ',
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      onPressed: i == 0 || busyKeys.isNotEmpty
                          ? null
                          : () => _move(context, controller, memos, i, i - 1),
                    ),
                    IconButton(
                      tooltip: '下へ',
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      onPressed: i >= memos.length - 1 || busyKeys.isNotEmpty
                          ? null
                          : () => _move(context, controller, memos, i, i + 1),
                    ),
                  ],
                  IconButton(
                    tooltip: 'メモを削除',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: busyKeys.contains('memo:${memos[i].id}')
                        ? null
                        : () async {
                            final ok = await confirmDangerAction(
                              context,
                              title: 'メモを削除',
                              message: 'このメモを削除します。',
                            );
                            if (!ok || !context.mounted) return;
                            final failure =
                                await controller().deleteMemo(memos[i]);
                            if (context.mounted) {
                              handleActionResult(context, failure);
                            }
                          },
                  ),
                ],
              ),
              onTap: () => showMemoEditor(
                context,
                ref,
                genbaId: genbaId,
                category: memos[i].category,
                existing: memos[i],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _move(
    BuildContext context,
    GenbaActionsController Function() controller,
    List<GenbaMemo> memos,
    int from,
    int to,
  ) async {
    final next = [...memos];
    final moved = next.removeAt(from);
    next.insert(to, moved);
    final failure = await controller().reorderMemos(
      aggregate.genba.id,
      [for (final m in next) m.id],
    );
    if (context.mounted) handleActionResult(context, failure);
  }
}
