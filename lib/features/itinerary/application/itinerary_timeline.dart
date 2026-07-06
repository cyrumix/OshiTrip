import 'package:collection/collection.dart';

import '../../genba/domain/genba.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/itinerary_spot.dart';

/// 旅程タイムラインを組み立てる純粋関数群（itinerary-plan-spec.md §5）。
///
/// 副作用・I/Oを持たず、[ItineraryPlanAggregate] と現場（[Genba]）・その
/// 交通/宿泊から、日別のタイムラインを決定的に構築する。設計上の要点:
///
/// - 並び順は localDate → startAt → sortOrder → createdAt の決定的順序。
/// - 日付未定（localDate=null）は候補（[ItineraryTimeline.candidates]）へ、
///   時刻未定（startAt=null）は各日の末尾へ置き、勝手に補完しない（§5.2）。
/// - 公演会場・開場・開演・終演は [Genba] から導出する固定アンカーであり、
///   DBへ重複保存しない。日跨ぎ（分>1440）も暦日を補正して扱う（§3.1/§5.1）。
/// - 交通・宿泊は既存IDを参照するだけで複製しない。参照先が削除されていれば
///   [ItineraryReferenceStatus.missing] として状態を返す（§5.3）。
///
/// タイムゾーン注記: entry の day バケットは保存済みの localDate をそのまま
/// 使い（UTC からの再計算をしない）、日内順は UTC の startAt で比較する
/// （UTC は単調なので同一日内の時系列は正しく並ぶ）。アンカーは会場現地の
/// 暦日・時刻で保持する。アンカーと entry を時刻で1本の列へ融合する表示は
/// タイムゾーン変換を要するため Phase 2 の表示層で扱う（本関数は日別の
/// アンカー群と順序付き entry 群を分けて返す）。

/// 公演アンカーの種別（§5.1）。
enum ItineraryAnchorKind { doorOpen, showStart, showEnd }

extension ItineraryAnchorKindLabel on ItineraryAnchorKind {
  String get label => switch (this) {
        ItineraryAnchorKind.doorOpen => '開場',
        ItineraryAnchorKind.showStart => '開演',
        ItineraryAnchorKind.showEnd => '終演',
      };
}

/// 交通・宿泊など外部参照の解決状態（§5.3/§13）。
enum ItineraryReferenceStatus {
  /// 参照が解決できた、または参照を持たない（note / spot 実在）。
  resolved,

  /// 参照先（交通・宿泊・スポット）が見つからない（参照切れ）。
  missing,
}

/// 公演アンカー（[Genba] から導出。DBには保存しない）。
class ItineraryAnchor {
  const ItineraryAnchor({
    required this.kind,
    required this.date,
    required this.minuteOfDay,
  });

  final ItineraryAnchorKind kind;

  /// 会場現地の暦日（日跨ぎ補正済み）。
  final DateTime date;

  /// 会場現地 0:00 からの分（0〜1439）。
  final int minuteOfDay;

  @override
  bool operator ==(Object other) =>
      other is ItineraryAnchor &&
      other.kind == kind &&
      other.date == date &&
      other.minuteOfDay == minuteOfDay;

  @override
  int get hashCode => Object.hash(kind, date, minuteOfDay);
}

/// タイムラインの1項目（旅程項目＋解決済み参照）。
class ItineraryTimelineEntry {
  const ItineraryTimelineEntry({
    required this.entry,
    this.spot,
    this.transport,
    this.lodging,
    required this.referenceStatus,
  });

  final ItineraryEntry entry;

  /// [ItineraryEntryKind.spot] のとき解決したスポット（見つからなければ null）。
  final ItinerarySpot? spot;

  /// [ItineraryEntryKind.transport] のとき解決した交通（参照切れなら null）。
  final Transport? transport;

  /// [ItineraryEntryKind.lodging] のとき解決した宿泊（参照切れなら null）。
  final Lodging? lodging;

  final ItineraryReferenceStatus referenceStatus;

  bool get isReferenceMissing =>
      referenceStatus == ItineraryReferenceStatus.missing;

  @override
  bool operator ==(Object other) =>
      other is ItineraryTimelineEntry &&
      other.entry == entry &&
      other.spot == spot &&
      other.transport == transport &&
      other.lodging == lodging &&
      other.referenceStatus == referenceStatus;

  @override
  int get hashCode =>
      Object.hash(entry, spot, transport, lodging, referenceStatus);
}

/// 日別セクション（§5.2）。
class ItineraryTimelineDay {
  const ItineraryTimelineDay({
    required this.date,
    required this.anchors,
    required this.entries,
  });

  /// この日の暦日（時刻情報なし）。
  final DateTime date;

  /// この日に置かれる公演アンカー（会場現地時刻の昇順）。
  final List<ItineraryAnchor> anchors;

  /// この日の旅程項目（localDate→startAt→sortOrder→createdAt の決定的順序）。
  final List<ItineraryTimelineEntry> entries;
}

/// タイムライン全体。
class ItineraryTimeline {
  const ItineraryTimeline({required this.days, required this.candidates});

  /// 日付の昇順に並んだ日別セクション。
  final List<ItineraryTimelineDay> days;

  /// 日付未設定の旅程項目（候補リスト。sortOrder→createdAt の順）。
  final List<ItineraryTimelineEntry> candidates;
}

/// [Genba] から公演アンカーを導出する（DBへ保存しない, §3.1）。
/// door/start/end のうち設定されている分だけを返す。日跨ぎ（分>=1440）は
/// 暦日を進めて扱う。
List<ItineraryAnchor> deriveItineraryAnchors(Genba genba) {
  final base = DateTime(
    genba.eventDate.year,
    genba.eventDate.month,
    genba.eventDate.day,
  );
  ItineraryAnchor? anchor(ItineraryAnchorKind kind, int? minutes) {
    if (minutes == null) return null;
    final normalized = minutes < 0 ? 0 : minutes;
    return ItineraryAnchor(
      kind: kind,
      date: base.add(Duration(days: normalized ~/ 1440)),
      minuteOfDay: normalized % 1440,
    );
  }

  return [
    anchor(ItineraryAnchorKind.doorOpen, genba.doorTimeMinutes),
    anchor(ItineraryAnchorKind.showStart, genba.startTimeMinutes),
    anchor(ItineraryAnchorKind.showEnd, genba.endTimeMinutes),
  ].whereType<ItineraryAnchor>().toList();
}

/// 旅程項目1件の外部参照を解決する（複製せずID参照で引き当てる, §5.3）。
ItineraryTimelineEntry resolveItineraryEntry(
  ItineraryEntry entry, {
  required List<ItinerarySpot> spots,
  required List<Transport> transports,
  required List<Lodging> lodgings,
}) {
  switch (entry.kind) {
    case ItineraryEntryKind.spot:
      final spot = spots.firstWhereOrNull((s) => s.id == entry.spotId);
      return ItineraryTimelineEntry(
        entry: entry,
        spot: spot,
        referenceStatus: spot == null
            ? ItineraryReferenceStatus.missing
            : ItineraryReferenceStatus.resolved,
      );
    case ItineraryEntryKind.transport:
      final transport =
          transports.firstWhereOrNull((t) => t.id == entry.transportId);
      return ItineraryTimelineEntry(
        entry: entry,
        transport: transport,
        referenceStatus: transport == null
            ? ItineraryReferenceStatus.missing
            : ItineraryReferenceStatus.resolved,
      );
    case ItineraryEntryKind.lodging:
      final lodging = lodgings.firstWhereOrNull((l) => l.id == entry.lodgingId);
      return ItineraryTimelineEntry(
        entry: entry,
        lodging: lodging,
        referenceStatus: lodging == null
            ? ItineraryReferenceStatus.missing
            : ItineraryReferenceStatus.resolved,
      );
    case ItineraryEntryKind.note:
      return ItineraryTimelineEntry(
        entry: entry,
        referenceStatus: ItineraryReferenceStatus.resolved,
      );
  }
}

/// 同一日内の旅程項目の決定的比較（startAt→sortOrder→createdAt→id。時刻未定は
/// 末尾）。localDate は既に日バケットで分離済みのため比較には使わない。
/// 全ソートキーが同値でも id を最終 tie-breaker にして順序を完全決定的にする。
int compareItineraryEntriesInDay(ItineraryEntry a, ItineraryEntry b) {
  final aAt = a.startAt;
  final bAt = b.startAt;
  if (aAt != null && bAt != null) {
    final byTime = aAt.compareTo(bAt);
    if (byTime != 0) return byTime;
  } else if (aAt != null) {
    return -1; // 時刻ありは時刻未定より前。
  } else if (bAt != null) {
    return 1;
  }
  final byOrder = a.sortOrder.compareTo(b.sortOrder);
  if (byOrder != 0) return byOrder;
  final byCreated = a.createdAt.compareTo(b.createdAt);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}

DateTime _dateKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// タイムライン全体を組み立てる（§5.2）。
ItineraryTimeline buildItineraryTimeline({
  required ItineraryPlanAggregate aggregate,
  required Genba genba,
  required List<Transport> transports,
  required List<Lodging> lodgings,
}) {
  final resolved = [
    for (final entry in aggregate.entries)
      resolveItineraryEntry(
        entry,
        spots: aggregate.spots,
        transports: transports,
        lodgings: lodgings,
      ),
  ];

  // 候補（日付未設定）: sortOrder→createdAt→id（id を最終 tie-breaker）。
  final candidates = resolved.where((r) => r.entry.localDate == null).toList()
    ..sort((a, b) {
      final byOrder = a.entry.sortOrder.compareTo(b.entry.sortOrder);
      if (byOrder != 0) return byOrder;
      final byCreated = a.entry.createdAt.compareTo(b.entry.createdAt);
      if (byCreated != 0) return byCreated;
      return a.entry.id.compareTo(b.entry.id);
    });

  // 日別バケット。日付は entry の localDate とアンカーの日から集める。
  final anchors = deriveItineraryAnchors(genba);
  final entriesByDate = <DateTime, List<ItineraryTimelineEntry>>{};
  for (final r in resolved) {
    final ld = r.entry.localDate;
    if (ld == null) continue;
    entriesByDate.putIfAbsent(_dateKey(ld), () => []).add(r);
  }
  final anchorsByDate = <DateTime, List<ItineraryAnchor>>{};
  for (final a in anchors) {
    anchorsByDate.putIfAbsent(_dateKey(a.date), () => []).add(a);
  }

  final allDates =
      <DateTime>{...entriesByDate.keys, ...anchorsByDate.keys}.toList()..sort();

  final days = [
    for (final date in allDates)
      ItineraryTimelineDay(
        date: date,
        anchors: (anchorsByDate[date] ?? [])
          ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay)),
        entries: (entriesByDate[date] ?? [])
          ..sort((a, b) => compareItineraryEntriesInDay(a.entry, b.entry)),
      ),
  ];

  return ItineraryTimeline(days: days, candidates: candidates);
}
