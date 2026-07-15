import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../genba/domain/genba.dart';
import '../../genba/presentation/widgets/memo_editors.dart';
import '../../itinerary/domain/itinerary_spot.dart';
import '../../sharing/data/shared_genba_fetcher.dart';
import '../../sharing/domain/genba_permission.dart';
import '../application/member_providers.dart';
import 'shared_edit_dialogs.dart';

const _uuid = Uuid();

/// date 型カラム用の 'YYYY-MM-DD'（null はそのまま null）。
String? _dateStr(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

/// スポット追加時の既定カテゴリ（通常の計画スポットUIと同じ観光）。
const _defaultSpotCategoryWire = 'sightseeing';

/// 計画スポットのカテゴリ選択肢（wire 値, 表示ラベル）。通常の計画スポットと
/// カテゴリ一覧がズレないよう、単一の情報源 [ItinerarySpotCategory] から生成する
/// （聖地=sacred_place を含む全カテゴリ, D-245 是正）。
List<({String wire, String label})> get _spotCategoryOptions => [
      for (final c in ItinerarySpotCategory.values)
        (wire: c.wireValue, label: c.label),
    ];

/// wire 値からカテゴリ表示ラベルを引く（未知値は wire をそのまま表示）。
String _spotCategoryLabel(String wire) {
  for (final c in ItinerarySpotCategory.values) {
    if (c.wireValue == wire) return c.label;
  }
  return wire;
}

/// 共有現場の詳細（追加要件 §1/§2/§3, D-240/D-241）。
///
/// 自分が grantee（editor/viewer）の現場をサーバー権威で取得して表示する。
/// - viewer: 閲覧のみ（編集導線を出さない）。
/// - editor: 内容を編集できる（保存は `apply_shared_mutation` RPC 経由）。
/// - 権限が無い/共有解除後は開けない（`permission.canView == false`）。
/// owner の既存 `GenbaDetailScreen` は無改変（別画面）。
class SharedGenbaDetailScreen extends ConsumerWidget {
  const SharedGenbaDetailScreen({super.key, required this.genbaId});

  final String genbaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedGenbaDetailProvider(genbaId));

    return AppScaffold(
      title: '共有された現場',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myGenbaRolesProvider);
          ref.invalidate(sharedGenbaDetailProvider(genbaId));
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _Unavailable(),
          data: (detail) {
            final data = detail.data;
            if (!detail.permission.canView || data == null) {
              return const _Unavailable();
            }
            return _Body(
              genbaId: genbaId,
              data: data,
              permission: detail.permission,
            );
          },
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.lock_outline,
            message: 'この現場は表示できません',
            description: '共有が解除されたか、権限がありません',
          ),
        ],
      );
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.genbaId,
    required this.data,
    required this.permission,
  });

  final String genbaId;
  final SharedGenbaData data;
  final GenbaPermission permission;

  bool get _canEdit => permission.canEditContent;

  Future<void> _write(
    BuildContext context,
    WidgetRef ref,
    Future<Result<void>> Function() action,
  ) async {
    final result = await action();
    if (!context.mounted) return;
    result.when(
      ok: (_) => ref.invalidate(sharedGenbaDetailProvider(genbaId)),
      err: (f) {
        // 競合時は最新状態を取り直す（他メンバーの更新を反映）。
        if (f is ConflictFailure) {
          ref.invalidate(sharedGenbaDetailProvider(genbaId));
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }

  /// apply_shared_mutation の upsert を共通化（editor 編集の保存経路）。
  Future<void> _upsert(
    BuildContext context,
    WidgetRef ref,
    String table,
    String id,
    Map<String, dynamic> payload,
    int? baseVersion,
  ) =>
      _write(
        context,
        ref,
        () => ref.read(sharedMutationClientProvider).apply(
              genbaId: genbaId,
              entityTable: table,
              entityId: id,
              opType: 'upsert',
              payload: payload,
              baseVersion: baseVersion,
            ),
      );

  /// apply_shared_mutation の delete を共通化。
  Future<void> _deleteRow(
    BuildContext context,
    WidgetRef ref,
    String table,
    String id,
    int? baseVersion,
  ) =>
      _write(
        context,
        ref,
        () => ref.read(sharedMutationClientProvider).apply(
              genbaId: genbaId,
              entityTable: table,
              entityId: id,
              opType: 'delete',
              payload: {'id': id},
              baseVersion: baseVersion,
            ),
      );

  Future<void> _toggleTodo(
    BuildContext context,
    WidgetRef ref,
    GenbaTodo t,
  ) =>
      _write(
        context,
        ref,
        () => ref.read(sharedMutationClientProvider).apply(
              genbaId: genbaId,
              entityTable: 'todos',
              entityId: t.id,
              opType: 'upsert',
              payload: {
                'id': t.id,
                'genba_id': genbaId,
                'is_done': !t.isDone,
              },
              baseVersion: data.todoVersions[t.id],
            ),
      );

  Future<void> _deleteTodo(
    BuildContext context,
    WidgetRef ref,
    GenbaTodo t,
  ) =>
      _write(
        context,
        ref,
        () => ref.read(sharedMutationClientProvider).apply(
              genbaId: genbaId,
              entityTable: 'todos',
              entityId: t.id,
              opType: 'delete',
              payload: {'id': t.id},
              baseVersion: data.todoVersions[t.id],
            ),
      );

  // ---- メモの共同編集（editor のみ, D-243/D-244）----------------------------
  // 既存の種類別メモエディタ（free/checklist/bingo/vote）を再利用し、保存だけを
  // apply_shared_mutation へ差し替える（kind/content を壊さず送る）。
  Future<Result<void>> _applySharedMemo(WidgetRef ref, GenbaMemo memo) async {
    final isNew = !data.memoVersions.containsKey(memo.id);
    final result = await ref.read(sharedMutationClientProvider).apply(
          genbaId: genbaId,
          entityTable: 'genba_memos',
          entityId: memo.id,
          opType: 'upsert',
          payload: {
            'id': memo.id,
            'genba_id': genbaId,
            'category': memo.category.name,
            'kind': memo.kind.name,
            'title': memo.title,
            'body': memo.body,
            'content': memo.content?.toJson(),
            'sort_order': memo.sortOrder,
          },
          baseVersion: isNew ? null : data.memoVersions[memo.id],
        );
    // 成功/競合とも最新状態を取り直す（競合時はエディタ側がメッセージを表示）。
    if (result.isOk || result.failureOrNull is ConflictFailure) {
      ref.invalidate(sharedGenbaDetailProvider(genbaId));
    }
    return result;
  }

  void _openMemoAdd(BuildContext context, WidgetRef ref) {
    showAddMemoFlow(
      context,
      ref,
      genbaId: genbaId,
      initialSortOrder: data.aggregate.memos.length,
      onSubmit: (m) => _applySharedMemo(ref, m),
    );
  }

  void _openMemoEdit(BuildContext context, WidgetRef ref, GenbaMemo m) {
    showMemoEditor(
      context,
      ref,
      genbaId: genbaId,
      existing: m,
      onSubmit: (mm) => _applySharedMemo(ref, mm),
    );
  }

  Future<void> _deleteMemo(
    BuildContext context,
    WidgetRef ref,
    GenbaMemo m,
  ) =>
      _write(
        context,
        ref,
        () => ref.read(sharedMutationClientProvider).apply(
              genbaId: genbaId,
              entityTable: 'genba_memos',
              entityId: m.id,
              opType: 'delete',
              payload: {'id': m.id},
              baseVersion: data.memoVersions[m.id],
            ),
      );

  // ---- 計画スポットの共同編集（editor のみ, D-245）------------------------
  // owner 用の Google Places 連携UIは共有現場で誤爆すると危険なため流用せず、
  // 名前＋種別だけの小さな共有専用ダイアログで手入力する。保存は
  // apply_shared_mutation 経由（plan_id を含めて現場所属を検証させる）。
  Future<void> _openSpotAdd(BuildContext context, WidgetRef ref) async {
    final planId = data.firstPlanId;
    if (planId == null) return; // 計画が無ければ追加不可（フォールバック）。
    final result = await showDialog<_SpotDraft>(
      context: context,
      builder: (_) => const _SpotEditorDialog(),
    );
    if (result == null || !context.mounted) return;
    final id = _uuid.v4();
    await _write(
      context,
      ref,
      () => ref.read(sharedMutationClientProvider).apply(
            genbaId: genbaId,
            entityTable: 'itinerary_spots',
            entityId: id,
            opType: 'upsert',
            payload: {
              'id': id,
              'plan_id': planId,
              'name': result.name,
              'category': result.category,
            },
            baseVersion: null,
          ),
    );
  }

  Future<void> _openSpotEdit(
    BuildContext context,
    WidgetRef ref,
    SharedSpot s,
  ) async {
    final result = await showDialog<_SpotDraft>(
      context: context,
      builder: (_) => _SpotEditorDialog(initial: s),
    );
    if (result == null || !context.mounted) return;
    await _write(
      context,
      ref,
      () => ref.read(sharedMutationClientProvider).apply(
            genbaId: genbaId,
            entityTable: 'itinerary_spots',
            entityId: s.id,
            opType: 'upsert',
            payload: {
              'id': s.id,
              'plan_id': s.planId,
              'name': result.name,
              'category': result.category,
            },
            baseVersion: s.version,
          ),
    );
  }

  Future<void> _deleteSpot(
    BuildContext context,
    WidgetRef ref,
    SharedSpot s,
  ) =>
      _write(
        context,
        ref,
        () => ref.read(sharedMutationClientProvider).apply(
              genbaId: genbaId,
              entityTable: 'itinerary_spots',
              entityId: s.id,
              opType: 'delete',
              payload: {'id': s.id},
              baseVersion: s.version,
            ),
      );

  // ---- 移動区間の共同編集（editor のみ, D-246）----------------------------
  // 端点は旅程項目（entries）から選ぶ。plan_id で現場所属を検証させる。
  Map<String, dynamic> _legPayload(String id, String planId, LegDraft d) => {
        'id': id,
        'plan_id': planId,
        'origin_entry_id': d.originEntryId,
        'destination_entry_id': d.destinationEntryId,
        'travel_mode': d.travelMode,
        'duration_minutes': d.durationMinutes,
      };

  Future<void> _openLegAdd(BuildContext context, WidgetRef ref) async {
    final planId = data.firstPlanId;
    if (planId == null || data.entries.length < 2) return;
    final draft = await showLegEditor(context, entries: data.entries);
    if (draft == null || !context.mounted) return;
    final id = _uuid.v4();
    await _upsert(
      context,
      ref,
      'itinerary_legs',
      id,
      _legPayload(id, planId, draft),
      null,
    );
  }

  Future<void> _openLegEdit(
    BuildContext context,
    WidgetRef ref,
    SharedLeg leg,
  ) async {
    final draft =
        await showLegEditor(context, entries: data.entries, initial: leg);
    if (draft == null || !context.mounted) return;
    await _upsert(
      context,
      ref,
      'itinerary_legs',
      leg.id,
      _legPayload(leg.id, leg.planId, draft),
      leg.version,
    );
  }

  Future<void> _deleteLeg(BuildContext context, WidgetRef ref, SharedLeg leg) =>
      _deleteRow(context, ref, 'itinerary_legs', leg.id, leg.version);

  // ---- チケット/交通/宿泊の共同編集（editor のみ, D-246）-------------------
  Future<void> _openTicketEditor(
    BuildContext context,
    WidgetRef ref, {
    SharedTicket? initial,
  }) async {
    final d = await showTicketEditor(context, initial: initial);
    if (d == null || !context.mounted) return;
    final id = initial?.id ?? _uuid.v4();
    await _upsert(
      context,
      ref,
      'tickets',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'seat': d.seat,
        'gate': d.gate,
        'entry_number': d.entryNumber,
        'url': d.url,
        'memo': d.memo,
        'acquisition_status': d.acquisitionStatus,
        'payment_status': d.paymentStatus,
        'issuance_status': d.issuanceStatus,
      },
      initial?.version,
    );
  }

  Future<void> _openTransportEditor(
    BuildContext context,
    WidgetRef ref, {
    SharedTransport? initial,
  }) async {
    final d = await showTransportEditor(context, initial: initial);
    if (d == null || !context.mounted) return;
    final id = initial?.id ?? _uuid.v4();
    await _upsert(
      context,
      ref,
      'transports',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'direction': d.direction,
        'method': d.method,
        'method_other': d.methodOther,
        'from_place': d.fromPlace,
        'to_place': d.toPlace,
        'reservation_number': d.reservationNumber,
        'url': d.url,
        'memo': d.memo,
      },
      initial?.version,
    );
  }

  Future<void> _openLodgingEditor(
    BuildContext context,
    WidgetRef ref, {
    SharedLodging? initial,
  }) async {
    final d = await showLodgingEditor(context, initial: initial);
    if (d == null || !context.mounted) return;
    final id = initial?.id ?? _uuid.v4();
    await _upsert(
      context,
      ref,
      'lodgings',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'name': d.name,
        'checkin_date': _dateStr(d.checkinDate),
        'checkout_date': _dateStr(d.checkoutDate),
        'address': d.address,
        'reservation_number': d.reservationNumber,
        'url': d.url,
        'memo': d.memo,
      },
      initial?.version,
    );
  }

  // ---- 思い出テキストの共同編集（editor のみ, D-245）----------------------
  // memory_entries は 1 現場 1 行。既存行が無ければ新規作成する。
  Future<void> _openMemoryEdit(BuildContext context, WidgetRef ref) async {
    final current = data.memory;
    final result = await showDialog<_MemoryDraft>(
      context: context,
      builder: (_) => _MemoryEditorDialog(initial: current),
    );
    if (result == null || !context.mounted) return;
    final id = current?.id ?? _uuid.v4();
    await _upsert(
      context,
      ref,
      'memory_entries',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'impression': result.impression,
        'best_moment': result.bestMoment,
      },
      current?.id == null ? null : current!.version,
    );
  }

  // ---- グッズ/行った場所/食べたもの/セットリストの共同編集（D-246）--------
  Future<void> _openGoodsEditor(
    BuildContext context,
    WidgetRef ref, {
    SharedGoods? initial,
  }) async {
    final d = await showGoodsEditor(context, initial: initial);
    if (d == null || !context.mounted) return;
    final id = initial?.id ?? _uuid.v4();
    await _upsert(
      context,
      ref,
      'goods_items',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'name': d.name,
        'price': d.price,
        'quantity': d.quantity,
        'memo': d.memo,
      },
      initial?.version,
    );
  }

  Future<void> _openPlaceEditor(
    BuildContext context,
    WidgetRef ref, {
    required bool isFood,
    SharedVisitedPlace? initial,
  }) async {
    final d = await showPlaceEditor(context, isFood: isFood, initial: initial);
    if (d == null || !context.mounted) return;
    final id = initial?.id ?? _uuid.v4();
    await _upsert(
      context,
      ref,
      'visited_places',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'name': d.name,
        'category': isFood ? 'food' : 'spot',
        'memo': d.memo,
      },
      initial?.version,
    );
  }

  Future<void> _openSetlistEditor(
    BuildContext context,
    WidgetRef ref, {
    SharedSetlistItem? initial,
  }) async {
    final d = await showSetlistEditor(context, initial: initial);
    if (d == null || !context.mounted) return;
    final id = initial?.id ?? _uuid.v4();
    // 追加は末尾の position（既存最大+1）。編集は既存 position を維持。
    final position = initial?.position ??
        (data.setlist.isEmpty
            ? 1
            : data.setlist
                    .map((s) => s.position)
                    .reduce((a, b) => a > b ? a : b) +
                1);
    await _upsert(
      context,
      ref,
      'setlist_items',
      id,
      {
        'id': id,
        'genba_id': genbaId,
        'position': position,
        'song_title': d.songTitle,
        'note': d.note,
      },
      initial?.version,
    );
  }

  // ---- 写真/アルバム（メタデータ編集・削除のみ。画像本体は次増分, D-246）--
  Future<void> _openPhotoEditor(
    BuildContext context,
    WidgetRef ref,
    SharedPhoto p,
  ) async {
    final d = await showPhotoCaptionEditor(context, initial: p);
    if (d == null || !context.mounted) return;
    await _upsert(
      context,
      ref,
      'memory_photos',
      p.id,
      {
        'id': p.id,
        'genba_id': genbaId,
        'caption': d.caption,
        'is_cover': d.isCover,
        'sort_order': p.sortOrder,
      },
      p.version,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final agg = data.aggregate;
    final g = agg.genba;
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        // 権限バッジ（共有 + 編集可/閲覧のみ）。
        Row(
          children: [
            _Chip(
              label: '共有',
              icon: Icons.group_outlined,
              color: theme.colorScheme.primaryContainer,
              onColor: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppSpace.xs),
            _Chip(
              label: permission.label,
              icon: _canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
              color: theme.colorScheme.secondaryContainer,
              onColor: theme.colorScheme.onSecondaryContainer,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),

        // 概要。
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.title, style: theme.textTheme.headlineSmall),
              if (g.artistName.isNotEmpty)
                Text(g.artistName, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpace.sm),
              _row(context, Icons.event_outlined, _formatDate(g.eventDate)),
              if (g.venue != null && g.venue!.isNotEmpty)
                _row(context, Icons.location_on_outlined, g.venue!),
              if (_timeLine(g).isNotEmpty)
                _row(context, Icons.schedule_outlined, _timeLine(g)),
              if (g.isCanceled) _row(context, Icons.cancel_outlined, '中止'),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.push('/genba/$genbaId/members'),
            icon: const Icon(Icons.group_outlined, size: 18),
            label: const Text('メンバーを見る'),
          ),
        ),
        const SizedBox(height: AppSpace.sm),

        // 準備状況（件数）。
        const SectionHeader(title: '準備状況'),
        AppCard(
          child: Wrap(
            spacing: AppSpace.lg,
            runSpacing: AppSpace.sm,
            children: [
              _stat(context, 'Todo', agg.incompleteTodoCount, '未完了'),
              _stat(context, '持ち物', agg.incompleteBelongingCount, '未対応'),
              _stat(context, 'チケット', agg.tickets.length, '件'),
              _stat(context, '交通', agg.transports.length, '件'),
              _stat(context, '宿泊', agg.lodgings.length, '件'),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // Todo・持ち物（editor はタップで完了トグル・削除できる）。
        if (agg.todos.isNotEmpty) ...[
          SectionHeader(
            title: 'Todo・持ち物',
            count: agg.todos.length,
            action: _canEdit
                ? Text(
                    'タップで完了',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  )
                : null,
          ),
          for (final t in agg.todos)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              onTap: _canEdit ? () => _toggleTodo(context, ref, t) : null,
              leading: Icon(
                t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: t.isDone
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              title: Text(t.name),
              trailing: _canEdit
                  ? IconButton(
                      tooltip: '削除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteTodo(context, ref, t),
                    )
                  : null,
            ),
          const SizedBox(height: AppSpace.lg),
        ],

        // メモ（自由/チェックリスト/BINGO/投票, D-244。editor は追加・編集・削除可）。
        if (agg.memos.isNotEmpty || _canEdit) ...[
          SectionHeader(
            title: 'メモ',
            count: agg.memos.length,
            action: _canEdit
                ? TextButton.icon(
                    key: const Key('memo_add_button'),
                    onPressed: () => _openMemoAdd(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('追加'),
                  )
                : null,
          ),
          for (final m in agg.memos)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              padding: const EdgeInsets.all(AppSpace.md),
              onTap: _canEdit ? () => _openMemoEdit(context, ref, m) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _MemoView(memo: m)),
                  if (_canEdit)
                    IconButton(
                      tooltip: 'メモを削除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteMemo(context, ref, m),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.lg),
        ],

        // 計画スポット（editor は追加・編集・削除できる, D-245）。
        if (data.hasPlan) ...[
          SectionHeader(
            title: '計画スポット',
            count: data.spots.length,
            action: (_canEdit && data.firstPlanId != null)
                ? TextButton.icon(
                    key: const Key('spot_add_button'),
                    onPressed: () => _openSpotAdd(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('追加'),
                  )
                : null,
          ),
          if (data.spots.isEmpty)
            Text(
              'スポットはまだありません',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          for (final s in data.spots)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpace.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              onTap: _canEdit ? () => _openSpotEdit(context, ref, s) : null,
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name),
                        Text(
                          _spotCategoryLabel(s.category),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  if (_canEdit)
                    IconButton(
                      tooltip: 'スポットを削除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteSpot(context, ref, s),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.lg),

          // 移動区間（editor は追加・編集・削除できる, D-246。端点は旅程項目）。
          if (data.legs.isNotEmpty ||
              (_canEdit && data.entries.length >= 2)) ...[
            SectionHeader(
              title: '移動区間',
              count: data.legs.length,
              action: (_canEdit && data.entries.length >= 2)
                  ? TextButton.icon(
                      key: const Key('leg_add_button'),
                      onPressed: () => _openLegAdd(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('追加'),
                    )
                  : null,
            ),
            if (data.legs.isEmpty)
              Text(
                '移動区間はまだありません',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            for (final leg in data.legs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_outlined, size: 20),
                title: Text(leg.label),
                onTap: _canEdit ? () => _openLegEdit(context, ref, leg) : null,
                trailing: _canEdit
                    ? IconButton(
                        tooltip: '移動区間を削除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteLeg(context, ref, leg),
                      )
                    : null,
              ),
            if (_canEdit && data.entries.length < 2)
              Text(
                '移動区間の追加には旅程項目が2つ以上必要です',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            const SizedBox(height: AppSpace.lg),
          ],
        ] else if (_canEdit) ...[
          // 計画未作成: editor でも共有現場からは計画本体（itinerary_plans）を
          // 作成できない（apply_shared_mutation の対象は plan 配下の子データのみ・
          // 計画作成を editor に開放するには RLS/RPC/pgTAP まで要る＝安全側で見送り,
          // D-245）。誤解を避けるため、追加導線ではなく案内を表示する。
          const SectionHeader(title: '計画スポット'),
          AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    '計画はまだ作成されていません。'
                    'オーナーが計画を作成すると共同編集できます。',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],

        // チケット（editor は追加・編集・削除できる, D-246）。
        if (data.tickets.isNotEmpty || _canEdit) ...[
          SectionHeader(
            title: 'チケット',
            count: data.tickets.length,
            action: _canEdit
                ? TextButton.icon(
                    key: const Key('ticket_add_button'),
                    onPressed: () => _openTicketEditor(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('追加'),
                  )
                : null,
          ),
          for (final t in data.tickets)
            _itemCard(
              context,
              icon: Icons.confirmation_number_outlined,
              title: _ticketTitle(t),
              subtitle: ticketAcquisitionOptions[t.acquisitionStatus],
              onEdit: _canEdit
                  ? () => _openTicketEditor(context, ref, initial: t)
                  : null,
              onDelete: _canEdit
                  ? () => _deleteRow(context, ref, 'tickets', t.id, t.version)
                  : null,
              deleteTooltip: 'チケットを削除',
            ),
          const SizedBox(height: AppSpace.lg),
        ],

        // 交通（editor は追加・編集・削除できる, D-246）。
        if (data.transports.isNotEmpty || _canEdit) ...[
          SectionHeader(
            title: '交通',
            count: data.transports.length,
            action: _canEdit
                ? TextButton.icon(
                    key: const Key('transport_add_button'),
                    onPressed: () => _openTransportEditor(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('追加'),
                  )
                : null,
          ),
          for (final t in data.transports)
            _itemCard(
              context,
              icon: Icons.directions_transit_outlined,
              title: _transportTitle(t),
              subtitle: _transportSubtitle(t),
              onEdit: _canEdit
                  ? () => _openTransportEditor(context, ref, initial: t)
                  : null,
              onDelete: _canEdit
                  ? () =>
                      _deleteRow(context, ref, 'transports', t.id, t.version)
                  : null,
              deleteTooltip: '交通を削除',
            ),
          const SizedBox(height: AppSpace.lg),
        ],

        // 宿泊（editor は追加・編集・削除できる, D-246）。
        if (data.lodgings.isNotEmpty || _canEdit) ...[
          SectionHeader(
            title: '宿泊',
            count: data.lodgings.length,
            action: _canEdit
                ? TextButton.icon(
                    key: const Key('lodging_add_button'),
                    onPressed: () => _openLodgingEditor(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('追加'),
                  )
                : null,
          ),
          for (final l in data.lodgings)
            _itemCard(
              context,
              icon: Icons.hotel_outlined,
              title: l.name.isEmpty ? '宿泊' : l.name,
              subtitle: _lodgingSubtitle(l),
              onEdit: _canEdit
                  ? () => _openLodgingEditor(context, ref, initial: l)
                  : null,
              onDelete: _canEdit
                  ? () => _deleteRow(context, ref, 'lodgings', l.id, l.version)
                  : null,
              deleteTooltip: '宿泊を削除',
            ),
          const SizedBox(height: AppSpace.lg),
        ],

        // 思い出・グッズ・行った場所/食べたもの・セットリスト・写真。
        // editor は感想テキスト（impression / best_moment）を編集できる, D-245。
        if (_hasMemorySection || _canEdit) ...[
          SectionHeader(
            title: '思い出',
            action: _canEdit
                ? TextButton.icon(
                    key: const Key('memory_edit_button'),
                    onPressed: () => _openMemoryEdit(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      (data.memory != null && !data.memory!.isEmpty)
                          ? '感想を編集'
                          : '感想を追加',
                    ),
                  )
                : null,
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.memory != null && data.memory!.impression.isNotEmpty)
                  Text(data.memory!.impression),
                if (data.memory != null && data.memory!.bestMoment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('ベストシーン: ${data.memory!.bestMoment}'),
                  ),
                if (data.memory == null || data.memory!.isEmpty)
                  Text(
                    '感想はまだありません',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],

        // グッズ・戦利品（editor は追加・編集・削除できる, D-246）。
        ..._simpleSection<SharedGoods>(
          context,
          ref,
          title: 'グッズ・戦利品',
          addKey: const Key('goods_add_button'),
          items: data.goods,
          icon: Icons.shopping_bag_outlined,
          titleOf: (g) => g.name,
          subtitleOf: _goodsSubtitle,
          onAdd: () => _openGoodsEditor(context, ref),
          onEdit: (g) => _openGoodsEditor(context, ref, initial: g),
          onDelete: (g) =>
              _deleteRow(context, ref, 'goods_items', g.id, g.version),
          deleteTooltip: 'グッズを削除',
        ),

        // 行った場所（category=spot）。
        ..._simpleSection<SharedVisitedPlace>(
          context,
          ref,
          title: '行った場所',
          addKey: const Key('place_add_button'),
          items: data.visitedSpots,
          icon: Icons.place_outlined,
          titleOf: (p) => p.name,
          subtitleOf: (p) => p.memo,
          onAdd: () => _openPlaceEditor(context, ref, isFood: false),
          onEdit: (p) =>
              _openPlaceEditor(context, ref, isFood: false, initial: p),
          onDelete: (p) =>
              _deleteRow(context, ref, 'visited_places', p.id, p.version),
          deleteTooltip: '行った場所を削除',
        ),

        // 食べたもの（category=food）。
        ..._simpleSection<SharedVisitedPlace>(
          context,
          ref,
          title: '食べたもの',
          addKey: const Key('food_add_button'),
          items: data.foods,
          icon: Icons.restaurant_outlined,
          titleOf: (p) => p.name,
          subtitleOf: (p) => p.memo,
          onAdd: () => _openPlaceEditor(context, ref, isFood: true),
          onEdit: (p) =>
              _openPlaceEditor(context, ref, isFood: true, initial: p),
          onDelete: (p) =>
              _deleteRow(context, ref, 'visited_places', p.id, p.version),
          deleteTooltip: '食べたものを削除',
        ),

        // セットリスト（editor は追加・編集・削除できる, D-246）。
        ..._simpleSection<SharedSetlistItem>(
          context,
          ref,
          title: 'セットリスト',
          addKey: const Key('setlist_add_button'),
          items: data.setlist,
          icon: Icons.music_note_outlined,
          titleOf: (s) => '${s.position}. ${s.songTitle}',
          subtitleOf: (s) => s.note,
          onAdd: () => _openSetlistEditor(context, ref),
          onEdit: (s) => _openSetlistEditor(context, ref, initial: s),
          onDelete: (s) =>
              _deleteRow(context, ref, 'setlist_items', s.id, s.version),
          deleteTooltip: '曲を削除',
        ),

        // 写真・アルバム（メタデータ編集・削除のみ。画像本体は次増分, D-246）。
        if (data.photos.isNotEmpty) ...[
          SectionHeader(title: '写真・アルバム', count: data.photos.length),
          for (final p in data.photos)
            _itemCard(
              context,
              icon: p.isCover ? Icons.star : Icons.photo_outlined,
              title: p.caption.isEmpty ? '（キャプションなし）' : p.caption,
              subtitle: p.isCover ? 'カバー写真' : null,
              onEdit: _canEdit ? () => _openPhotoEditor(context, ref, p) : null,
              onDelete: _canEdit
                  ? () =>
                      _deleteRow(context, ref, 'memory_photos', p.id, p.version)
                  : null,
              deleteTooltip: '写真を削除',
            ),
          if (_canEdit)
            Text(
              '写真の追加（画像アップロード）は準備中です'
              '（キャプション/カバー編集・削除のみ対応）',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          const SizedBox(height: AppSpace.lg),
        ],

        Text(
          _canEdit
              ? 'Todo・持ち物・メモ・計画スポット・移動区間・チケット・交通・宿泊・'
                  '思い出（感想/グッズ/行った場所/食べたもの/セットリスト）を編集できます'
                  '（写真は情報編集・削除のみ／画像アップロードは順次対応）'
              : 'この現場は閲覧専用です',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }

  /// 単純な一覧セクション（ヘッダ＋追加ボタン＋項目カード）を組み立てる共通実装。
  List<Widget> _simpleSection<T>(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Key addKey,
    required List<T> items,
    required IconData icon,
    required String Function(T) titleOf,
    required String Function(T) subtitleOf,
    required VoidCallback onAdd,
    required void Function(T) onEdit,
    required void Function(T) onDelete,
    required String deleteTooltip,
  }) {
    if (items.isEmpty && !_canEdit) return const [];
    return [
      SectionHeader(
        title: title,
        count: items.length,
        action: _canEdit
            ? TextButton.icon(
                key: addKey,
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('追加'),
              )
            : null,
      ),
      for (final it in items)
        _itemCard(
          context,
          icon: icon,
          title: titleOf(it),
          subtitle: subtitleOf(it),
          onEdit: _canEdit ? () => onEdit(it) : null,
          onDelete: _canEdit ? () => onDelete(it) : null,
          deleteTooltip: deleteTooltip,
        ),
      const SizedBox(height: AppSpace.lg),
    ];
  }

  bool get _hasMemorySection =>
      (data.memory != null && !data.memory!.isEmpty) ||
      data.photos.isNotEmpty ||
      data.setlist.isNotEmpty ||
      data.goods.isNotEmpty ||
      data.visitedPlaces.isNotEmpty;

  Widget _row(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: AppSpace.xs),
            Expanded(child: Text(text)),
          ],
        ),
      );

  String _ticketTitle(SharedTicket t) {
    if (t.seat.isNotEmpty) return '座席 ${t.seat}';
    if (t.gate.isNotEmpty) return 'ゲート ${t.gate}';
    if (t.entryNumber.isNotEmpty) return '整理番号 ${t.entryNumber}';
    return 'チケット';
  }

  String _transportTitle(SharedTransport t) {
    final dir = t.direction == 'inbound' ? '復路' : '往路';
    final method = transportMethodFromCode(t.method)?.label ??
        (t.methodOther.isNotEmpty ? t.methodOther : '交通');
    return '$dir・$method';
  }

  String _transportSubtitle(SharedTransport t) {
    if (t.fromPlace.isEmpty && t.toPlace.isEmpty) return '';
    return '${t.fromPlace} → ${t.toPlace}';
  }

  String _lodgingSubtitle(SharedLodging l) {
    String fmt(DateTime? d) => d == null ? '' : '${d.month}/${d.day}';
    final ci = fmt(l.checkinDate);
    final co = fmt(l.checkoutDate);
    if (ci.isEmpty && co.isEmpty) return l.address;
    return '$ci〜$co';
  }

  String _goodsSubtitle(SharedGoods g) {
    final parts = <String>[
      if (g.price != null) '${g.price}円',
      if (g.quantity > 1) '×${g.quantity}',
    ];
    return parts.join('・');
  }

  /// 編集可能な一覧項目カード（タップで編集・末尾に削除）。共有の各セクション共通。
  Widget _itemCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    required String deleteTooltip,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpace.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      onTap: onEdit,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: AppSpace.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: deleteTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, int count, String unit) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text('$count$unit', style: theme.textTheme.titleMedium),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';

  String _timeLine(Genba g) {
    String hm(int? m) => m == null
        ? ''
        : '${(m ~/ 60) % 24}:${(m % 60).toString().padLeft(2, '0')}';
    final parts = <String>[
      if (g.doorTimeMinutes != null) '開場 ${hm(g.doorTimeMinutes)}',
      if (g.startTimeMinutes != null) '開演 ${hm(g.startTimeMinutes)}',
      if (g.endTimeMinutes != null) '終演 ${hm(g.endTimeMinutes)}',
    ];
    return parts.join(' / ');
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: onColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

/// メモの種類別の閲覧表示（free/checklist/bingo/vote, D-244）。読取専用。
/// 編集は既存のメモエディタを再利用する（カードタップ）。
class _MemoView extends StatelessWidget {
  const _MemoView({required this.memo});

  final GenbaMemo memo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _kindIcon(memo.kind),
              size: 16,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                memo.title.isEmpty ? memo.kind.label : memo.title,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ..._body(context),
      ],
    );
  }

  List<Widget> _body(BuildContext context) {
    switch (memo.kind) {
      case MemoKind.free:
        return [if (memo.body.isNotEmpty) Text(memo.body)];
      case MemoKind.checklist:
        final items = memo.content?.checklist ?? const <MemoChecklistItem>[];
        return [
          for (final i in items)
            Row(
              children: [
                Icon(
                  i.checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: i.checked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(child: Text(i.text)),
              ],
            ),
        ];
      case MemoKind.bingo:
        final bingo = memo.content?.bingo;
        if (bingo == null) return const [];
        return [_BingoView(bingo: bingo)];
      case MemoKind.vote:
        final vote = memo.content?.vote;
        if (vote == null) return const [];
        return [_VoteView(vote: vote)];
    }
  }

  IconData _kindIcon(MemoKind kind) => switch (kind) {
        MemoKind.free => Icons.sticky_note_2_outlined,
        MemoKind.checklist => Icons.checklist_rtl,
        MemoKind.bingo => Icons.grid_view_rounded,
        MemoKind.vote => Icons.how_to_vote_outlined,
      };
}

/// BINGO の閲覧表示（サイズ・マス内容・選択状態・BINGO 判定）。
class _BingoView extends StatelessWidget {
  const _BingoView({required this.bingo});
  final MemoBingo bingo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = bingo.selected.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${bingo.size}×${bingo.size}',
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            if (bingo.hasBingo)
              Text(
                'BINGO! ×${bingo.lineCount}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: bingo.size,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < bingo.cellCount; i++)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: selected.contains(i)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  i < bingo.cells.length ? bingo.cells[i] : '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected.contains(i)
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 投票の閲覧表示（説明・選択肢・得票数・重複可否）。
class _VoteView extends StatelessWidget {
  const _VoteView({required this.vote});
  final MemoVote vote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vote.description.isNotEmpty) Text(vote.description),
        const SizedBox(height: 2),
        for (final o in vote.options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${vote.countFor(o.id)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(child: Text(o.text)),
              ],
            ),
          ),
        Text(
          '投票総数 ${vote.votes.length}'
          '${vote.allowDuplicate ? '・重複投票可' : '・1人1票'}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

/// 計画スポットの共有専用編集ダイアログの入力結果。
class _SpotDraft {
  const _SpotDraft({required this.name, required this.category});
  final String name;
  final String category;
}

/// 名前＋種別だけの小さな共有専用スポット編集UI（owner の Places 連携は流用しない）。
class _SpotEditorDialog extends StatefulWidget {
  const _SpotEditorDialog({this.initial});
  final SharedSpot? initial;

  @override
  State<_SpotEditorDialog> createState() => _SpotEditorDialogState();
}

class _SpotEditorDialogState extends State<_SpotEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late String _category = widget.initial?.category ?? _defaultSpotCategoryWire;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final options = _spotCategoryOptions;
    // 既存カテゴリが未知値（将来追加された種別など）でも other に落とさず、
    // その値を選択肢として保持する（sacred_place を含む既知値は options に有る）。
    final knownWires = options.map((o) => o.wire).toSet();
    final items = [
      if (!knownWires.contains(_category))
        DropdownMenuItem(
          value: _category,
          child: Text(_spotCategoryLabel(_category)),
        ),
      for (final o in options)
        DropdownMenuItem(value: o.wire, child: Text(o.label)),
    ];
    return AlertDialog(
      title: Text(isEdit ? 'スポットを編集' : 'スポットを追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('spot_name'),
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '名前'),
          ),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<String>(
            key: const Key('spot_category'),
            initialValue: _category,
            decoration: const InputDecoration(labelText: '種別'),
            items: items,
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('spot_save'),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              _SpotDraft(name: name, category: _category),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 思い出（感想テキスト）の共有専用編集ダイアログの入力結果。
class _MemoryDraft {
  const _MemoryDraft({required this.impression, required this.bestMoment});
  final String impression;
  final String bestMoment;
}

/// 感想（impression）とベストシーン（best_moment）だけの小さな共有専用編集UI。
class _MemoryEditorDialog extends StatefulWidget {
  const _MemoryEditorDialog({this.initial});
  final SharedMemory? initial;

  @override
  State<_MemoryEditorDialog> createState() => _MemoryEditorDialogState();
}

class _MemoryEditorDialogState extends State<_MemoryEditorDialog> {
  late final TextEditingController _impression =
      TextEditingController(text: widget.initial?.impression ?? '');
  late final TextEditingController _best =
      TextEditingController(text: widget.initial?.bestMoment ?? '');

  @override
  void dispose() {
    _impression.dispose();
    _best.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('思い出の感想'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('memory_impression'),
              controller: _impression,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(labelText: '感想'),
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              key: const Key('memory_best_moment'),
              controller: _best,
              decoration: const InputDecoration(labelText: 'ベストシーン'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('memory_save'),
            onPressed: () => Navigator.of(context).pop(
              _MemoryDraft(
                impression: _impression.text.trim(),
                bestMoment: _best.text.trim(),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      );
}
