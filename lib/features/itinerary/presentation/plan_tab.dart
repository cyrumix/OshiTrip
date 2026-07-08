import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/domain/genba.dart';
import '../application/itinerary_actions_controller.dart';
import '../application/itinerary_providers.dart';
import '../application/itinerary_timeline.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/itinerary_schedule.dart';
import '../domain/itinerary_spot.dart';
import '../domain/itinerary_spot_link.dart';
import 'external_link.dart';
import 'itinerary_editors.dart';
import 'itinerary_import_and_leg.dart';
import 'itinerary_spot_image.dart';

/// 現場詳細「計画」タブ（design-spec §7.3）。公演を固定アンカーにした日別
/// タイムラインを主表示にする。Google連携はまだ出さず、手動入力を主要導線とする。
class PlanTab extends ConsumerWidget {
  const PlanTab({super.key, required this.genbaAggregate});

  final GenbaAggregate genbaAggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = genbaAggregate.genba;
    final plansAsync = ref.watch(itineraryPlansProvider(genba.id));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: plansAsync.maybeWhen(
        data: (plans) => _AddMenu(
          genbaAggregate: genbaAggregate,
          plan: plans.isEmpty ? null : plans.first,
        ),
        orElse: () => null,
      ),
      body: AsyncValueView<List<ItineraryPlanAggregate>>(
        value: plansAsync,
        loadingView: const LoadingSkeleton.list(cardCount: 4),
        isEmpty: (plans) => plans.isEmpty,
        emptyView: const EmptyView(
          message: '計画はまだありません',
          description: '現場の前後に行きたい場所を追加しましょう。右下の＋から手動で登録できます。',
          icon: Icons.map_outlined,
        ),
        data: (plans) => _PlanTimeline(
          genbaAggregate: genbaAggregate,
          aggregate: plans.first,
        ),
      ),
    );
  }
}

/// タイムライン項目の短い表示名（leg の端点ラベル等に使う）。
String _timelineEntryLabel(ItineraryTimelineEntry item) {
  switch (item.entry.kind) {
    case ItineraryEntryKind.spot:
      return item.spot?.name ?? '（スポット）';
    case ItineraryEntryKind.transport:
      final t = item.transport;
      if (t == null) return '交通（削除済み）';
      return '${t.direction.label} ${t.methodDisplay}'.trim();
    case ItineraryEntryKind.lodging:
      return item.lodging?.name ?? '宿泊先';
    case ItineraryEntryKind.note:
      return item.entry.titleOverride ?? 'メモ';
  }
}

class _PlanTimeline extends ConsumerWidget {
  const _PlanTimeline({
    required this.genbaAggregate,
    required this.aggregate,
  });

  final GenbaAggregate genbaAggregate;
  final ItineraryPlanAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = genbaAggregate.genba;
    final timeline = buildItineraryTimeline(
      aggregate: aggregate,
      genba: genba,
      transports: genbaAggregate.transports,
      lodgings: genbaAggregate.lodgings,
    );
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    // 公演日のみ会場ヘッダを付ける（会場名。住所はGenbaに項目が無いため名称のみ）。
    final eventDateKey = DateTime(
      genba.eventDate.year,
      genba.eventDate.month,
      genba.eventDate.day,
    );
    final venueName = genba.venue?.trim();
    final venue = (venueName != null && venueName.isNotEmpty)
        ? ItineraryVenue(name: venueName)
        : null;

    // 各日を会場・アンカー・項目を融合した1本の行列にする（§5.1）。
    final dayRows = <ItineraryTimelineDay, List<ItineraryRow>>{
      for (final day in timeline.days)
        day: buildItineraryDayRows(
          day,
          venue: day.date == eventDateKey ? venue : null,
        ),
    };

    // 全日通しの表示順（leg の隣接判定用）＋候補も末尾に含める。
    final orderedEntries = <ItineraryTimelineEntry>[
      for (final day in timeline.days)
        for (final row in dayRows[day]!)
          if (row is ItineraryEntryRow) row.item,
      ...timeline.candidates,
    ];
    final placements = placeItineraryLegs(
      orderedEntries: orderedEntries,
      legs: aggregate.legs,
      labelOf: _timelineEntryLabel,
    );
    final adjacentByAfterId = <String, List<ItineraryLegPlacement>>{};
    for (final p in placements.where((p) => p.adjacent)) {
      adjacentByAfterId.putIfAbsent(p.afterEntryId!, () => []).add(p);
    }
    final orphanLegs = placements.where((p) => !p.adjacent).toList();

    return ListView(
      key: PageStorageKey('plan_tab_${genba.id}'),
      padding:
          const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 96),
      children: [
        if (!isOnline)
          const AppCard(
            margin: EdgeInsets.only(bottom: AppSpace.sm),
            child: Text('オフライン中。保存済みの計画は閲覧・編集でき、復旧後に同期します。'),
          ),
        for (final day in timeline.days)
          _DaySection(
            day: day,
            rows: dayRows[day]!,
            aggregate: aggregate,
            genbaAggregate: genbaAggregate,
            adjacentByAfterId: adjacentByAfterId,
          ),
        if (orphanLegs.isNotEmpty) ...[
          const SectionHeader(
            title: '移動区間（端点が離れている・別日）',
            padding: EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
          ),
          for (final p in orphanLegs)
            _LegRow(
              placement: p,
              aggregate: aggregate,
              genbaAggregate: genbaAggregate,
            ),
        ],
        if (timeline.candidates.isNotEmpty) ...[
          const SectionHeader(
            title: '候補（日付未定）',
            padding: EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
          ),
          for (final item in timeline.candidates) ...[
            _EntryCard(
              item: item,
              aggregate: aggregate,
              genbaAggregate: genbaAggregate,
              dayOrder: const [],
              warnTight: false,
            ),
            // 候補どうしの隣接区間もここで表示し、落とさない（点3）。
            for (final p in adjacentByAfterId[item.entry.id] ??
                const <ItineraryLegPlacement>[])
              _LegRow(
                placement: p,
                aggregate: aggregate,
                genbaAggregate: genbaAggregate,
              ),
          ],
        ],
        if (timeline.days.isEmpty && timeline.candidates.isEmpty)
          const AppCard(
            child: Text('公演アンカー以外の予定はまだありません。＋から追加しましょう。'),
          ),
      ],
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({
    required this.day,
    required this.rows,
    required this.aggregate,
    required this.genbaAggregate,
    required this.adjacentByAfterId,
  });

  final ItineraryTimelineDay day;
  final List<ItineraryRow> rows;
  final ItineraryPlanAggregate aggregate;
  final GenbaAggregate genbaAggregate;
  final Map<String, List<ItineraryLegPlacement>> adjacentByAfterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tight = itineraryTightConnections(
      dayEntries: day.entries,
      legs: aggregate.legs,
    );
    final dayOrder = day.entries.map((e) => e.entry).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title:
              '${day.date.year}/${day.date.month}/${day.date.day}（${_weekday(day.date)}）',
          padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
        ),
        if (rows.isEmpty)
          Text(
            'この日の予定はありません',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final row in rows) ...[
          switch (row) {
            ItineraryVenueRow(:final venue) => _VenueRow(venue: venue),
            ItineraryAnchorRow(:final anchor) => _AnchorRow(anchor: anchor),
            ItineraryEntryRow(:final item) => _EntryCard(
                item: item,
                aggregate: aggregate,
                genbaAggregate: genbaAggregate,
                dayOrder: dayOrder,
                warnTight: tight.contains(item.entry.id),
              ),
          },
          // この項目の直後に隣接する移動区間を差し込む。
          if (row is ItineraryEntryRow)
            for (final p in adjacentByAfterId[row.item.entry.id] ??
                const <ItineraryLegPlacement>[])
              _LegRow(
                placement: p,
                aggregate: aggregate,
                genbaAggregate: genbaAggregate,
              ),
        ],
        // この日に直接スポットを追加する（訪問日の初期値=この日, 点4）。
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openSpotEditorWithDefaults(
              context,
              ref,
              planId: aggregate.plan.id,
              ownerId: aggregate.plan.ownerId,
              genbaAggregate: genbaAggregate,
              plan: aggregate,
              contextDate: day.date,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text('${day.date.month}/${day.date.day}にスポットを追加'),
          ),
        ),
      ],
    );
  }

  static String _weekday(DateTime d) =>
      const ['月', '火', '水', '木', '金', '土', '日'][d.weekday - 1];
}

class _VenueRow extends StatelessWidget {
  const _VenueRow({required this.venue});
  final ItineraryVenue venue;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: tokens.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.stadium_outlined, size: 18),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '会場 ${venue.name}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  semanticsLabel: '会場 ${venue.name}'
                      '${venue.address != null ? ' ${venue.address}' : ''}',
                ),
                if (venue.address != null)
                  Text(
                    venue.address!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  const _AnchorRow({required this.anchor});
  final ItineraryAnchor anchor;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final time =
        '${(anchor.minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(anchor.minuteOfDay % 60).toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: tokens.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin_outlined, size: 18),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              '公演 ${anchor.kind.label}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              semanticsLabel: '公演${anchor.kind.label} $time',
            ),
          ),
          Text(
            time,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// 移動区間の表示（手段・時刻・所要・距離・運賃・経路概要）。編集/削除・
/// Google Maps を開く（ドメイン確認あり）を備える。端点が離れている場合は
/// 出発/到着のラベルを添えて落とさず表示する（点3）。
class _LegRow extends ConsumerWidget {
  const _LegRow({
    required this.placement,
    required this.aggregate,
    required this.genbaAggregate,
  });

  final ItineraryLegPlacement placement;
  final ItineraryPlanAggregate aggregate;
  final GenbaAggregate genbaAggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leg = placement.leg;
    final theme = Theme.of(context);
    final details = <String>[
      if (leg.durationMinutes != null) '約${leg.durationMinutes}分',
      if (leg.distanceMeters != null) _formatDistance(leg.distanceMeters!),
      if (leg.fareAmountMinor != null && leg.fareCurrency != null)
        '${leg.fareAmountMinor} ${leg.fareCurrency}',
    ];
    final times = _formatLegTimes(leg.departureAt, leg.arrivalAt);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.alt_route, size: 20),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '移動 ${leg.travelMode.label}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${placement.originLabel} → ${placement.destinationLabel}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (times != null)
                      Text(times, style: theme.textTheme.bodyMedium),
                    if (details.isNotEmpty)
                      Text(
                        details.join('・'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (leg.routeSummary != null)
                      Text(
                        leg.routeSummary!,
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              _menu(context, ref),
            ],
          ),
          if (!placement.adjacent)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(
                '出発と到着の項目が並んでいません（別日・順序が離れている・端点が削除）',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          if (leg.googleMapsUrl != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openExternalUrlWithConfirm(
                  context,
                  url: leg.googleMapsUrl!,
                  label: 'Google Maps',
                ),
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Google Mapsで開く'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: '移動区間の操作',
      onSelected: (v) {
        switch (v) {
          case 'edit':
            _edit(context, ref);
          case 'delete':
            _delete(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('編集…')),
        PopupMenuItem(value: 'delete', child: Text('移動区間を削除…')),
      ],
    );
  }

  void _edit(BuildContext context, WidgetRef ref) {
    final options = buildLegEntryOptions(
      aggregate: aggregate,
      genbaAggregate: genbaAggregate,
      labelOf: _optionLabel,
    );
    showItineraryLegEditor(
      context,
      ref,
      planId: aggregate.plan.id,
      ownerId: aggregate.plan.ownerId,
      options: options,
      existing: placement.leg,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDangerAction(
      context,
      title: '移動区間を削除',
      message:
          '「${placement.originLabel} → ${placement.destinationLabel}」の移動区間を削除します。',
    );
    if (!ok || !context.mounted) return;
    final failure = await ref
        .read(itineraryActionsControllerProvider(aggregate.plan.id).notifier)
        .deleteLeg(placement.leg.id);
    if (context.mounted && failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  String _optionLabel(ItineraryEntry e) {
    if (e.kind == ItineraryEntryKind.spot) {
      final spot = aggregate.spots.firstWhereOrNull((s) => s.id == e.spotId);
      if (spot != null) return spot.name;
    }
    return e.titleOverride ?? e.kind.name;
  }

  static String _formatDistance(int meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)}km' : '${meters}m';

  static String? _formatLegTimes(DateTime? departure, DateTime? arrival) {
    String fmt(DateTime d) {
      final l = d.toLocal();
      return '${l.hour.toString().padLeft(2, '0')}:'
          '${l.minute.toString().padLeft(2, '0')}';
    }

    if (departure == null && arrival == null) return null;
    final dep = departure != null ? fmt(departure) : '—';
    final arr = arrival != null ? fmt(arrival) : '—';
    return '$dep 発 → $arr 着';
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({
    required this.item,
    required this.aggregate,
    required this.genbaAggregate,
    required this.dayOrder,
    required this.warnTight,
  });

  final ItineraryTimelineEntry item;
  final ItineraryPlanAggregate aggregate;
  final GenbaAggregate genbaAggregate;
  final List<ItineraryEntry> dayOrder;
  final bool warnTight;

  ItineraryActionsController _controller(WidgetRef ref) =>
      ref.read(itineraryActionsControllerProvider(aggregate.plan.id).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = item.entry;
    final busyKeys =
        ref.watch(itineraryActionsControllerProvider(aggregate.plan.id));
    final idx = dayOrder.indexWhere((e) => e.id == entry.id);
    final title = _title();
    final links = entry.kind == ItineraryEntryKind.spot && item.spot != null
        ? aggregate.linksOf(item.spot!.id)
        : const <ItinerarySpotLink>[];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.entry.kind == ItineraryEntryKind.spot &&
                  item.spot?.userImageLocalPath != null) ...[
                ItinerarySpotImage(
                  ownerId: item.spot!.ownerId,
                  imageRef: item.spot!.userImageLocalPath,
                  facilityName: title,
                  size: 48,
                ),
                const SizedBox(width: AppSpace.sm),
              ] else ...[
                Icon(_icon(), size: 20),
                const SizedBox(width: AppSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_kindLabel()}・${_timeLabel(context)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_subtitle() != null)
                      Text(
                        _subtitle()!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              // 日内の並び替え（時刻順と矛盾する場合は確認）。
              if (dayOrder.length > 1) ...[
                IconButton(
                  tooltip: '上へ',
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: idx <= 0 || busyKeys.isNotEmpty
                      ? null
                      : () => _reorder(context, ref, idx, idx - 1),
                ),
                IconButton(
                  tooltip: '下へ',
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: idx < 0 ||
                          idx >= dayOrder.length - 1 ||
                          busyKeys.isNotEmpty
                      ? null
                      : () => _reorder(context, ref, idx, idx + 1),
                ),
              ],
              _menu(context, ref),
            ],
          ),
          if (warnTight)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '前の予定＋移動＋余裕でこの開始時刻に間に合わない可能性があります',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          if (item.isReferenceMissing)
            _MissingRefBanner(
              onConvert: () => _convertToNote(context, ref),
              onRemove: () => _remove(context, ref),
            ),
          for (final link in links)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openExternalUrlWithConfirm(
                  context,
                  url: link.url,
                  label: link.label ?? link.kind.label,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  link.label?.isNotEmpty == true
                      ? link.label!
                      : link.kind.label,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _icon() => switch (item.entry.kind) {
        ItineraryEntryKind.spot => _categoryIcon(),
        ItineraryEntryKind.transport => Icons.directions_transit,
        ItineraryEntryKind.lodging => Icons.hotel_outlined,
        ItineraryEntryKind.note => Icons.sticky_note_2_outlined,
      };

  IconData _categoryIcon() => switch (item.spot?.category) {
        ItinerarySpotCategory.restaurant => Icons.restaurant,
        ItinerarySpotCategory.cafe => Icons.local_cafe_outlined,
        ItinerarySpotCategory.station => Icons.train_outlined,
        ItinerarySpotCategory.airport => Icons.flight_outlined,
        ItinerarySpotCategory.shopping => Icons.shopping_bag_outlined,
        ItinerarySpotCategory.lodging => Icons.hotel_outlined,
        ItinerarySpotCategory.venue => Icons.stadium_outlined,
        ItinerarySpotCategory.sacredPlace => Icons.auto_awesome_outlined,
        _ => Icons.place_outlined,
      };

  String _kindLabel() => switch (item.entry.kind) {
        ItineraryEntryKind.spot => item.spot?.category.label ?? 'スポット',
        ItineraryEntryKind.transport => '交通',
        ItineraryEntryKind.lodging => '宿泊',
        ItineraryEntryKind.note => 'メモ',
      };

  String _title() {
    switch (item.entry.kind) {
      case ItineraryEntryKind.spot:
        return item.spot?.name ?? '（スポット）';
      case ItineraryEntryKind.transport:
        final t = item.transport;
        if (t == null) return '交通（削除済み）';
        return '${t.direction.label} ${t.methodDisplay}'.trim();
      case ItineraryEntryKind.lodging:
        final l = item.lodging;
        if (l == null) return '宿泊（削除済み）';
        return l.name ?? '宿泊先';
      case ItineraryEntryKind.note:
        return item.entry.titleOverride ?? 'メモ';
    }
  }

  String? _subtitle() {
    switch (item.entry.kind) {
      case ItineraryEntryKind.spot:
        return item.spot?.address;
      case ItineraryEntryKind.transport:
        final t = item.transport;
        if (t == null) return null;
        return '${t.fromPlace ?? '?'} → ${t.toPlace ?? '?'}';
      case ItineraryEntryKind.lodging:
        return item.lodging?.address;
      case ItineraryEntryKind.note:
        return item.entry.memo;
    }
  }

  String _timeLabel(BuildContext context) {
    // 交通・宿泊は参照元から導出した実効的な日時で表示する（元データの出発
    // 時刻・チェックイン日を更新すると表示にも反映される, §5.3/点4）。
    final start = item.effectiveStartAt;
    final baseDate = item.effectiveLocalDate;
    if (start == null) return '時間未定';
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final end = item.effectiveEndAt;
    if (end == null) return fmt(start);
    final crossesDay = baseDate != null &&
        (end.year != baseDate.year ||
            end.month != baseDate.month ||
            end.day != baseDate.day);
    return '${fmt(start)}–${crossesDay ? '翌日 ' : ''}${fmt(end)}';
  }

  Widget _menu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: '操作',
      onSelected: (v) {
        switch (v) {
          case 'edit':
            _edit(context, ref);
          case 'delete':
            _remove(context, ref);
        }
      },
      itemBuilder: (context) => [
        if (item.entry.kind == ItineraryEntryKind.spot ||
            item.entry.kind == ItineraryEntryKind.note)
          const PopupMenuItem(value: 'edit', child: Text('編集…')),
        const PopupMenuItem(value: 'delete', child: Text('旅程から削除…')),
      ],
    );
  }

  void _edit(BuildContext context, WidgetRef ref) {
    if (item.entry.kind == ItineraryEntryKind.spot && item.spot != null) {
      showItinerarySpotEditor(
        context,
        ref,
        planId: aggregate.plan.id,
        ownerId: aggregate.plan.ownerId,
        existing: SpotEditTarget(
          spot: item.spot!,
          entry: item.entry,
          links: aggregate.linksOf(item.spot!.id),
        ),
      );
    } else if (item.entry.kind == ItineraryEntryKind.note) {
      showItineraryNoteEditor(
        context,
        ref,
        planId: aggregate.plan.id,
        ownerId: aggregate.plan.ownerId,
        existing: item.entry,
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDangerAction(
      context,
      title: '旅程から削除',
      message: '「${_title()}」を旅程から削除します。'
          '${item.entry.kind == ItineraryEntryKind.spot ? 'スポット情報も削除されます。' : '元の交通・宿泊データは削除されません。'}',
    );
    if (!ok || !context.mounted) return;
    final Failure? failure;
    if (item.entry.kind == ItineraryEntryKind.spot && item.spot != null) {
      failure = await _controller(ref).deleteSpot(item.spot!);
    } else {
      failure = await _controller(ref).deleteEntry(item.entry.id);
    }
    if (context.mounted && failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _convertToNote(BuildContext context, WidgetRef ref) async {
    final now = ref.read(clockProvider).now().toUtc();
    final converted = item.entry.copyWith(
      kind: ItineraryEntryKind.note,
      transportId: null,
      lodgingId: null,
      spotId: null,
      titleOverride: item.entry.titleOverride ??
          (item.entry.kind == ItineraryEntryKind.transport
              ? '交通（手動）'
              : '宿泊（手動）'),
      updatedAt: now,
    );
    final failure = await _controller(ref).upsertEntry(converted);
    if (context.mounted && failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int from,
    int to,
  ) async {
    final next = [...dayOrder];
    final moved = next.removeAt(from);
    next.insert(to, moved);
    // 時刻順と矛盾する（時刻付き項目が昇順でなくなる）なら確認する。
    if (_conflictsWithTime(next)) {
      final ok = await confirmAction(
        context,
        title: '時刻順と入れ替わります',
        message: 'この並びは開始時刻の順序と矛盾します。手動の並びを優先して保存しますか？',
        confirmLabel: '保存する',
      );
      if (!ok || !context.mounted) return;
    }
    final failure = await _controller(ref).reorderEntries(
      planId: next.first.planId,
      orderedEntryIds: [for (final e in next) e.id],
    );
    if (context.mounted && failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  bool _conflictsWithTime(List<ItineraryEntry> order) {
    DateTime? prev;
    for (final e in order) {
      // メモは時刻整合の判定対象外（Phase 2追補 点6）。
      if (e.kind == ItineraryEntryKind.note) continue;
      final at = e.startAt;
      if (at == null) continue;
      if (prev != null && at.isBefore(prev)) return true;
      prev = at;
    }
    return false;
  }
}

class _MissingRefBanner extends StatelessWidget {
  const _MissingRefBanner({required this.onConvert, required this.onRemove});
  final VoidCallback onConvert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.xs),
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '元の交通／宿泊が削除されました',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
          ),
          Row(
            children: [
              TextButton(onPressed: onConvert, child: const Text('手動メモへ変換')),
              TextButton(onPressed: onRemove, child: const Text('旅程から削除')),
            ],
          ),
        ],
      ),
    );
  }
}

/// スポット追加画面を、訪問日・開始時刻の初期値を解決したうえで開く
/// （Phase 2追補 点4/点5 の優先順位を実画面へ接続する）。
///
/// [contextDate] は「現在操作・選択している日」。日別セクションの「この日に追加」
/// から呼ぶときはその日を渡す（優先順位1）。グローバル追加（右下＋）では null を
/// 渡し、現場開催日→旅程開始日をフォールバックにする（優先順位3/4）。いずれの
/// 経路でも端末の本日は初期値に使わない。直前予定の終了時刻も、解決した日付内の
/// 予定（メモを除く実予定）から取得する（点5）。
Future<void> openSpotEditorWithDefaults(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String ownerId,
  required GenbaAggregate genbaAggregate,
  required ItineraryPlanAggregate? plan,
  DateTime? contextDate,
}) async {
  final initialDate = resolveInitialVisitDate(
    currentDay: contextDate,
    genbaEventDate: genbaAggregate.genba.eventDate,
    planStartDate: plan?.plan.startDate,
  );
  DateTime? initialStart;
  if (initialDate != null && plan != null) {
    final timeline = buildItineraryTimeline(
      aggregate: plan,
      genba: genbaAggregate.genba,
      transports: genbaAggregate.transports,
      lodgings: genbaAggregate.lodgings,
    );
    final day = timeline.days.firstWhereOrNull((d) => d.date == initialDate);
    if (day != null) {
      initialStart = resolveInitialStartFromPrevious(day.entries);
    }
  }
  if (!context.mounted) return;
  await showItinerarySpotEditor(
    context,
    ref,
    planId: planId,
    ownerId: ownerId,
    initialDate: initialDate,
    initialStart: initialStart,
  );
}

/// 移動区間の端点候補を作る（メモ(note)は前後接続対象にしないため除外し、
/// 各項目の実効表示日を持たせて日付導出に使う, Phase 2追補 点3/点6）。
List<ItineraryEntryOption> buildLegEntryOptions({
  required ItineraryPlanAggregate aggregate,
  required GenbaAggregate genbaAggregate,
  required String Function(ItineraryEntry) labelOf,
}) {
  final timeline = buildItineraryTimeline(
    aggregate: aggregate,
    genba: genbaAggregate.genba,
    transports: genbaAggregate.transports,
    lodgings: genbaAggregate.lodgings,
  );
  final items = <ItineraryTimelineEntry>[
    for (final d in timeline.days) ...d.entries,
    ...timeline.candidates,
  ];
  return [
    for (final it in items)
      if (it.entry.kind != ItineraryEntryKind.note)
        ItineraryEntryOption(
          id: it.entry.id,
          label: labelOf(it.entry),
          date: it.effectiveLocalDate,
        ),
  ];
}

/// 追加メニュー（スポット／メモ／交通・宿泊の取り込み／移動区間）。
class _AddMenu extends ConsumerWidget {
  const _AddMenu({required this.genbaAggregate, required this.plan});

  final GenbaAggregate genbaAggregate;
  final ItineraryPlanAggregate? plan;

  Future<String?> _ensurePlanId(BuildContext context, WidgetRef ref) async {
    if (plan != null) return plan!.plan.id;
    final result = await ref
        .read(
          itineraryActionsControllerProvider(genbaAggregate.genba.id).notifier,
        )
        .ensurePlan(genbaAggregate.genba);
    return result.when(
      ok: (id) => id,
      err: (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = genbaAggregate.genba.ownerId;
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: const Text('追加'),
      onPressed: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: const Text('スポットを追加（自分で入力）'),
                  onTap: () => Navigator.of(context).pop('spot'),
                ),
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: const Text('メモ・集合予定を追加'),
                  onTap: () => Navigator.of(context).pop('note'),
                ),
                ListTile(
                  leading: const Icon(Icons.directions_transit),
                  title: const Text('登録済みの交通を追加'),
                  onTap: () => Navigator.of(context).pop('transport'),
                ),
                ListTile(
                  leading: const Icon(Icons.hotel_outlined),
                  title: const Text('登録済みの宿泊を追加'),
                  onTap: () => Navigator.of(context).pop('lodging'),
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: const Text('移動区間を追加'),
                  onTap: () => Navigator.of(context).pop('leg'),
                ),
              ],
            ),
          ),
        );
        if (choice == null || !context.mounted) return;
        final planId = await _ensurePlanId(context, ref);
        if (planId == null || !context.mounted) return;
        final entries = plan?.entries ?? const <ItineraryEntry>[];
        switch (choice) {
          case 'spot':
            // グローバル追加（右下＋）。現在操作中の日(contextDate)は無いので、
            // 現場開催日→旅程開始日をフォールバックにする（本日は使わない, 点4）。
            await openSpotEditorWithDefaults(
              context,
              ref,
              planId: planId,
              ownerId: owner,
              genbaAggregate: genbaAggregate,
              plan: plan,
              contextDate: null,
            );
          case 'note':
            await showItineraryNoteEditor(
              context,
              ref,
              planId: planId,
              ownerId: owner,
            );
          case 'transport':
            await showTransportImportSheet(
              context,
              ref,
              planId: planId,
              ownerId: owner,
              transports: genbaAggregate.transports,
              entries: entries,
            );
          case 'lodging':
            await showLodgingImportSheet(
              context,
              ref,
              planId: planId,
              ownerId: owner,
              lodgings: genbaAggregate.lodgings,
              entries: entries,
            );
          case 'leg':
            final planAgg = plan;
            final options = planAgg == null
                ? const <ItineraryEntryOption>[]
                : buildLegEntryOptions(
                    aggregate: planAgg,
                    genbaAggregate: genbaAggregate,
                    labelOf: _entryLabel,
                  );
            // メモは端点にできないため、実予定が2つ以上必要。
            if (options.length < 2) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('移動区間には2つ以上の予定（メモを除く）が必要です'),
                  ),
                );
              }
              return;
            }
            await showItineraryLegEditor(
              context,
              ref,
              planId: planId,
              ownerId: owner,
              options: options,
            );
        }
      },
    );
  }

  String _entryLabel(ItineraryEntry e) {
    final plan0 = plan;
    if (plan0 != null && e.kind == ItineraryEntryKind.spot) {
      final spot = plan0.spots.firstWhereOrNull((s) => s.id == e.spotId);
      if (spot != null) return spot.name;
    }
    return e.titleOverride ?? e.kind.name;
  }
}
