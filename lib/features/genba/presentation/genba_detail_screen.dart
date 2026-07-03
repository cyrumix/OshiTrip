import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/failure.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../home/presentation/widgets/genba_card.dart';
import '../application/genba_actions_controller.dart';
import '../application/genba_providers.dart';
import '../domain/genba.dart';
import '../domain/genba_schedule.dart';
import 'widgets/child_editors.dart';

/// [GenbaActionsController] の結果を一貫して処理する: 失敗時は理由を
/// SnackBar で示し、成功していない操作を成功表示しない（H-07/M-01）。
void _handleActionResult(BuildContext context, Failure? failure) {
  if (failure == null) return;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(failure.message)));
}

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
              SliverToBoxAdapter(child: _HeroImageSection(genba: genba)),
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
                      _StatusActionsSection(genba: genba, status: status),
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
}

/// 状態操作（終演した／取消・訂正／思い出を記録する）。すべて
/// [GenbaActionsController] 経由で loading・二重タップ防止・型付き失敗表示を
/// 一貫させる（H-07/M-01）。
class _StatusActionsSection extends ConsumerWidget {
  const _StatusActionsSection({required this.genba, required this.status});

  final Genba genba;
  final GenbaStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(genbaActionsControllerProvider(genba.id))
        .contains(GenbaActionsController.endedKey);
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);

    Future<void> markEnded() async {
      final confirmed = await confirmAction(
        context,
        title: '終演した',
        message: '現在時刻で終演したことにします。「余韻中」に切り替わり、思い出の入力を案内します。',
        confirmLabel: '終演した',
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller().markEnded(genba);
      if (context.mounted) _handleActionResult(context, failure);
    }

    Future<void> undoEnded() async {
      final confirmed = await confirmAction(
        context,
        title: '終演の取消',
        message: '手動で設定した終演を取り消し、予定の日時から状態を自動で判定し直します。',
        confirmLabel: '取り消す',
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller().undoMarkEnded(genba);
      if (context.mounted) _handleActionResult(context, failure);
    }

    Future<void> correctEnded() async {
      final base =
          genba.manualEndedAt?.toLocal() ?? ref.read(clockProvider).now();
      final date = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (time == null || !context.mounted) return;
      final corrected =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final failure = await controller().correctEndedAt(genba, corrected);
      if (context.mounted) _handleActionResult(context, failure);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genba.manualEndedAt != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '手動で終演済みにしています'
                    '（${_formatDt(genba.manualEndedAt!.toLocal())}）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: busy ? null : undoEnded,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('取り消す'),
              ),
              TextButton.icon(
                onPressed: busy ? null : correctEnded,
                icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                label: const Text('時刻を訂正'),
              ),
            ],
          ),
        ],
        if (status == GenbaStatus.today) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.flag_outlined, size: 18),
            label: const Text('終演した（余韻中にする）'),
            onPressed: busy ? null : markEnded,
          ),
        ],
        if (status == GenbaStatus.afterglow ||
            status == GenbaStatus.memory) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('思い出を記録する'),
            onPressed: () => context.push('/memories/${genba.id}/edit'),
          ),
        ],
      ],
    );
  }

  String _formatDt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.aggregate, required this.status});

  final GenbaAggregate aggregate;
  final GenbaStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    // このメニューは現場全体に対する操作（中止/削除）なので、他の子データ
    // 操作が進行中でも独立して押せてよいが、cancel/uncancel/delete同士の
    // 二重タップは防ぐ（それぞれ専用キーで個別にガードされる）。ここでは
    // メニュー自体を「何かが進行中なら開かない」簡易ガードとして扱う。
    final busy = ref.watch(genbaActionsControllerProvider(genba.id)).isNotEmpty;
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);

    Future<void> cancel() async {
      final confirmed = await confirmDangerAction(
        context,
        title: '現場を中止にする',
        message: '「${genba.title}」を中止にします。現場一覧には「中止」として残り、'
            '公演日を過ぎると思い出に記録として残ります。あとで取り消せます。',
        confirmLabel: '中止にする',
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller().cancel(genba);
      if (context.mounted) _handleActionResult(context, failure);
    }

    Future<void> uncancel() async {
      final failure = await controller().uncancel(genba);
      if (context.mounted) _handleActionResult(context, failure);
    }

    Future<void> delete() async {
      final confirmed = await confirmDangerAction(
        context,
        title: '現場を削除',
        message:
            '「${genba.title}」とチケット・交通・宿泊・Todo・メモ・思い出の記録をすべて削除します。この操作は取り消せません。',
      );
      if (!confirmed || !context.mounted) return;
      // 削除前に紐づく画像参照を収集する（削除後は取得できないため）。
      final imageRefs = <String>[
        if (genba.heroImageLocalPath != null) genba.heroImageLocalPath!,
        for (final t in aggregate.tickets)
          if (t.imageLocalPath != null) t.imageLocalPath!,
      ];
      final failure = await controller().deleteGenba(
        genba: genba,
        imageRefs: imageRefs,
        collectMemoryPhotoRefs: () async {
          final bundle = await ref
              .read(memoryRepositoryProvider)
              .watchByGenbaId(genba.id)
              .first;
          return [
            for (final ph in bundle.photos)
              if (ph.localPath != null) ph.localPath!,
          ];
        },
      );
      if (!context.mounted) return;
      if (failure == null) {
        context.go('/genba');
      } else {
        _handleActionResult(context, failure);
      }
    }

    return PopupMenuButton<String>(
      tooltip: 'その他の操作',
      enabled: !busy,
      onSelected: (value) {
        switch (value) {
          case 'cancel':
            cancel();
          case 'uncancel':
            uncancel();
          case 'delete':
            delete();
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

/// 現場ヒーロー画像（端末内・同期対象外, H-04）。選択・表示・差替え・削除。
/// [GenbaActionsController] 経由で二重タップ防止・型付き失敗表示を行う。
class _HeroImageSection extends ConsumerWidget {
  const _HeroImageSection({required this.genba});

  final Genba genba;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return;
    final store = ref.read(imageStoreProvider);
    String storedRef;
    try {
      storedRef = await store.import(
        ownerId: owner,
        category: ImageCategory.genbaHero,
        source: File(picked.path),
      );
    } on ImageStorageException catch (e) {
      if (context.mounted) {
        _handleActionResult(
          context,
          StorageFailure(message: 'ヒーロー画像の保存に失敗しました', cause: e),
        );
      }
      return;
    }
    final failure = await ref
        .read(genbaActionsControllerProvider(genba.id).notifier)
        .setHeroImage(genba, storedRef);
    if (context.mounted) _handleActionResult(context, failure);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(genbaActionsControllerProvider(genba.id).notifier)
        .removeHeroImage(genba);
    if (context.mounted) _handleActionResult(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(genbaActionsControllerProvider(genba.id))
        .contains(GenbaActionsController.heroImageKey);
    final ref0 = genba.heroImageLocalPath;
    final file = ref0 == null
        ? null
        : ref.read(imageStoreProvider).tryResolveOwned(
              genba.ownerId,
              ref0,
            );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _HeroPlaceholder(),
                ),
              ),
            )
          else
            const _HeroPlaceholder(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: busy ? null : () => _pick(context, ref),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(file == null ? 'ヒーロー画像を選択' : '画像を差し替え'),
              ),
              if (ref0 != null)
                IconButton(
                  tooltip: 'ヒーロー画像を外す',
                  onPressed: busy ? null : () => _remove(context, ref),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.image_outlined, size: 40)),
      ),
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
    final busyKeys = ref.watch(genbaActionsControllerProvider(genbaId));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genbaId).notifier);
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
                        _handleActionResult(context, failure);
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
    final busyKeys = ref.watch(genbaActionsControllerProvider(genba.id));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);
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
          enabled: !busyKeys.contains('transportRequirement'),
          onChanged: (req) async {
            final failure =
                await controller().setTransportRequirement(genba, req);
            if (context.mounted) _handleActionResult(context, failure);
          },
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
                          _handleActionResult(context, failure);
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
    final busyKeys = ref.watch(genbaActionsControllerProvider(genba.id));
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);
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
          enabled: !busyKeys.contains('lodgingRequirement'),
          onChanged: (req) async {
            final failure =
                await controller().setLodgingRequirement(genba, req);
            if (context.mounted) _handleActionResult(context, failure);
          },
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
                          _handleActionResult(context, failure);
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
    this.enabled = true,
  });

  final RequirementStatus value;
  final String notRequiredLabel;
  final void Function(RequirementStatus value) onChanged;
  final bool enabled;

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

/// Todo完了チェック。タップ即座に見た目を切り替え（楽観更新）、保存に失敗したら
/// 実際の値（変更されていない）に自然に戻り、理由を SnackBar で示す
/// （H-07/M-01: 失敗を成功表示しない・ロールバック）。
class _TodoSection extends ConsumerStatefulWidget {
  const _TodoSection({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  ConsumerState<_TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends ConsumerState<_TodoSection> {
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
    if (failure != null) _handleActionResult(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final genbaId = widget.aggregate.genba.id;
    return _SectionCard(
      title: 'Todo（残り${widget.aggregate.incompleteTodoCount}）',
      trailing: TextButton.icon(
        onPressed: () => showTodoEditor(context, ref, genbaId: genbaId),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('追加'),
      ),
      children: [
        if (widget.aggregate.todos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Todoはまだありません。「追加」から準備リストを作りましょう。'),
          ),
        for (final todo in widget.aggregate.todos)
          CheckboxListTile(
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
