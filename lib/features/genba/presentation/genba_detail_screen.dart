import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../home/presentation/widgets/genba_card.dart';
import '../application/genba_providers.dart';
import '../domain/genba.dart';
import '../domain/genba_schedule.dart';
import 'widgets/child_editors.dart';

/// 現場詳細（§7）。子データ（チケット/交通/宿泊/Todo/メモ）を追加・編集・削除できる。
class GenbaDetailScreen extends ConsumerWidget {
  const GenbaDetailScreen({super.key, required this.genbaId});

  final String genbaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregateAsync = ref.watch(genbaByIdProvider(genbaId));
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();

    return Scaffold(
      body: AsyncValueView<GenbaAggregate?>(
        value: aggregateAsync,
        isEmpty: (a) => a == null,
        emptyView: const EmptyView(message: '現場が見つかりませんでした'),
        data: (aggregate) {
          final a = aggregate!;
          final genba = a.genba;
          final status = deriveGenbaStatus(genba, now);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(genba.title, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    tooltip: '現場を編集',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/genba/$genbaId/edit'),
                  ),
                  _MoreMenu(aggregate: a, status: status),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GenbaStatusChip(status: status),
                          const SizedBox(width: 8),
                          Text(
                            genba.artistName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}',
                          if (genba.doorTimeMinutes != null)
                            '開場 ${formatMinutes(genba.doorTimeMinutes!)}',
                          if (genba.startTimeMinutes != null)
                            '開演 ${formatMinutes(genba.startTimeMinutes!)}',
                          if (genba.endTimeMinutes != null)
                            '終演 ${formatMinutes(genba.endTimeMinutes!)}',
                        ].join('　'),
                      ),
                      if (genba.venue != null) ...[
                        const SizedBox(height: 4),
                        Text('会場: ${genba.venue}'),
                      ],
                      if (genba.performanceType != null) ...[
                        const SizedBox(height: 4),
                        Text('種別: ${genba.performanceType}'),
                      ],
                      if (status == GenbaStatus.today) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('終演した（余韻中にする）'),
                          onPressed: () => _markEnded(ref, genba),
                        ),
                      ],
                      if (status == GenbaStatus.afterglow ||
                          status == GenbaStatus.memory) ...[
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('思い出を記録する'),
                          onPressed: () =>
                              context.push('/memories/$genbaId/edit'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverList.list(
                children: [
                  _TicketSection(aggregate: a),
                  _TransportSection(aggregate: a),
                  _LodgingSection(aggregate: a),
                  _TodoSection(aggregate: a),
                  _MemoSection(aggregate: a),
                  const SizedBox(height: 48),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markEnded(WidgetRef ref, Genba genba) async {
    final now = ref.read(clockProvider).now().toUtc();
    await ref
        .read(genbaRepositoryProvider)
        .upsertGenba(genba.copyWith(manualEndedAt: now));
  }
}

class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.aggregate, required this.status});

  final GenbaAggregate aggregate;
  final GenbaStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    return PopupMenuButton<String>(
      tooltip: 'その他の操作',
      onSelected: (value) async {
        final repo = ref.read(genbaRepositoryProvider);
        switch (value) {
          case 'cancel':
            await repo.upsertGenba(genba.copyWith(isCanceled: true));
          case 'uncancel':
            await repo.upsertGenba(genba.copyWith(isCanceled: false));
          case 'delete':
            final confirmed = await confirmDangerAction(
              context,
              title: '現場を削除',
              message:
                  '「${genba.title}」とチケット・交通・宿泊・Todo・メモ・思い出の記録をすべて削除します。この操作は取り消せません。',
            );
            if (confirmed) {
              final result = await repo.deleteGenba(genba.id);
              if (context.mounted && result.isOk) {
                context.go('/genba');
              }
            }
        }
      },
      itemBuilder: (context) => [
        if (!genba.isCanceled)
          const PopupMenuItem(value: 'cancel', child: Text('中止にする'))
        else
          const PopupMenuItem(value: 'uncancel', child: Text('中止を取り消す')),
        const PopupMenuItem(value: 'delete', child: Text('現場を削除…')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TicketSection extends ConsumerWidget {
  const _TicketSection({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genbaId = aggregate.genba.id;
    return _SectionCard(
      title: 'チケット',
      trailing: TextButton.icon(
        onPressed: () => showTicketEditor(context, ref, genbaId: genbaId),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('追加'),
      ),
      children: [
        if (aggregate.tickets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('未登録。取得状況を記録しておくと当日すぐ確認できます。'),
          ),
        for (final ticket in aggregate.tickets)
          ListTile(
            contentPadding: EdgeInsets.zero,
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
              onPressed: () async {
                final ok = await confirmDangerAction(
                  context,
                  title: 'チケットを削除',
                  message: 'このチケット情報を削除します。',
                );
                if (ok) {
                  await ref
                      .read(genbaRepositoryProvider)
                      .deleteTicket(ticket.id);
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
      ],
    );
  }
}

class _TransportSection extends ConsumerWidget {
  const _TransportSection({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    return _SectionCard(
      title: '交通',
      trailing: TextButton.icon(
        onPressed: () => showTransportEditor(context, ref, genbaId: genba.id),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('追加'),
      ),
      children: [
        _RequirementSelector(
          value: genba.transportRequirement,
          notRequiredLabel: '交通の登録は不要',
          onChanged: (req) => ref
              .read(genbaRepositoryProvider)
              .upsertGenba(genba.copyWith(transportRequirement: req)),
        ),
        if (genba.transportRequirement != RequirementStatus.notRequired) ...[
          if (aggregate.transports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('未登録'),
            ),
          for (final t in aggregate.transports)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                t.direction == TransportDirection.outbound
                    ? Icons.arrow_circle_right_outlined
                    : Icons.arrow_circle_left_outlined,
              ),
              title: Text(
                '${t.direction.label} ${t.method ?? ''}'.trim(),
              ),
              subtitle: (t.fromPlace != null || t.toPlace != null)
                  ? Text('${t.fromPlace ?? '?'} → ${t.toPlace ?? '?'}')
                  : null,
              trailing: IconButton(
                tooltip: '交通を削除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmDangerAction(
                    context,
                    title: '交通を削除',
                    message: 'この交通情報を削除します。',
                  );
                  if (ok) {
                    await ref
                        .read(genbaRepositoryProvider)
                        .deleteTransport(t.id);
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
        ],
      ],
    );
  }
}

class _LodgingSection extends ConsumerWidget {
  const _LodgingSection({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    return _SectionCard(
      title: '宿泊',
      trailing: TextButton.icon(
        onPressed: () => showLodgingEditor(context, ref, genbaId: genba.id),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('追加'),
      ),
      children: [
        _RequirementSelector(
          value: genba.lodgingRequirement,
          notRequiredLabel: '宿泊なし',
          onChanged: (req) => ref
              .read(genbaRepositoryProvider)
              .upsertGenba(genba.copyWith(lodgingRequirement: req)),
        ),
        if (genba.lodgingRequirement != RequirementStatus.notRequired) ...[
          if (aggregate.lodgings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('未登録'),
            ),
          for (final l in aggregate.lodgings)
            ListTile(
              contentPadding: EdgeInsets.zero,
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
                onPressed: () async {
                  final ok = await confirmDangerAction(
                    context,
                    title: '宿泊を削除',
                    message: 'この宿泊情報を削除します。',
                  );
                  if (ok) {
                    await ref.read(genbaRepositoryProvider).deleteLodging(l.id);
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
        ],
      ],
    );
  }
}

/// 「未設定 / 必要 / 不要」の選択。「不要」と「未登録」を区別する（§7.4/§7.5）。
class _RequirementSelector extends StatelessWidget {
  const _RequirementSelector({
    required this.value,
    required this.notRequiredLabel,
    required this.onChanged,
  });

  final RequirementStatus value;
  final String notRequiredLabel;
  final void Function(RequirementStatus value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('必要'),
            selected: value == RequirementStatus.required,
            onSelected: (_) => onChanged(RequirementStatus.required),
          ),
          ChoiceChip(
            label: Text(notRequiredLabel),
            selected: value == RequirementStatus.notRequired,
            onSelected: (_) => onChanged(RequirementStatus.notRequired),
          ),
          ChoiceChip(
            label: const Text('未定'),
            selected: value == RequirementStatus.unknown,
            onSelected: (_) => onChanged(RequirementStatus.unknown),
          ),
        ],
      ),
    );
  }
}

class _TodoSection extends ConsumerWidget {
  const _TodoSection({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genbaId = aggregate.genba.id;
    return _SectionCard(
      title: 'Todo（残り${aggregate.incompleteTodoCount}）',
      trailing: TextButton.icon(
        onPressed: () => showTodoEditor(context, ref, genbaId: genbaId),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('追加'),
      ),
      children: [
        if (aggregate.todos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Todoはまだありません。「追加」から準備リストを作りましょう。'),
          ),
        for (final todo in aggregate.todos)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: todo.isDone,
            onChanged: (checked) => ref
                .read(genbaRepositoryProvider)
                .upsertTodo(todo.copyWith(isDone: checked ?? false)),
            title: Text(
              todo.name,
              style: todo.isDone
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
              semanticsLabel: '${todo.name}、${todo.isDone ? '完了済み' : '未完了'}',
            ),
            subtitle:
                (todo.dueDate != null || todo.priority == TodoPriority.high)
                    ? Text(
                        [
                          if (todo.priority == TodoPriority.high) '重要',
                          if (todo.dueDate != null)
                            '期限 ${todo.dueDate!.month}/${todo.dueDate!.day}',
                        ].join(' / '),
                      )
                    : null,
            secondary: IconButton(
              tooltip: 'Todoを編集',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showTodoEditor(
                context,
                ref,
                genbaId: genbaId,
                existing: todo,
              ),
            ),
          ),
      ],
    );
  }
}

class _MemoSection extends ConsumerWidget {
  const _MemoSection({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genbaId = aggregate.genba.id;
    return _SectionCard(
      title: 'メモ',
      children: [
        for (final category in MemoCategory.values)
          Builder(
            builder: (context) {
              final memo = aggregate.memoOf(category);
              final hasBody = memo != null && memo.body.isNotEmpty;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(category.label),
                subtitle: hasBody
                    ? Text(
                        memo.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const Text('未入力'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showMemoEditor(
                  context,
                  ref,
                  genbaId: genbaId,
                  category: category,
                  existing: memo,
                ),
              );
            },
          ),
      ],
    );
  }
}
