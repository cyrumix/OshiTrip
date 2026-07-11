import 'package:collection/collection.dart';

import '../../genba/domain/genba.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/itinerary_schedule.dart';
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

/// 会場情報（[Genba] から導出。時刻を持たない固定ヘッダ, §5.1）。
class ItineraryVenue {
  const ItineraryVenue({required this.name, this.address});
  final String name;
  final String? address;

  @override
  bool operator ==(Object other) =>
      other is ItineraryVenue && other.name == name && other.address == address;

  @override
  int get hashCode => Object.hash(name, address);
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
///
/// 交通・宿泊は参照元（[transport] / [lodging]）を複製せず参照するため、表示日・
/// 開始/終了時刻は参照元から導出した**実効値**（[effectiveLocalDate] /
/// [effectiveStartAt] / [effectiveEndAt]）を使う。これにより元データの日付・
/// 出発時刻・チェックイン日を更新すると、名称だけでなく表示日・並び順にも
/// 反映される（§5.3 / Phase 2レビュー点4）。ユーザーが旅程側で独自の日時を
/// 指定した場合はその上書きを尊重する（[localDateFollowsSource] 参照）。
class ItineraryTimelineEntry {
  ItineraryTimelineEntry({
    required this.entry,
    this.spot,
    this.transport,
    this.lodging,
    required this.referenceStatus,
  }) : _schedule = effectiveItinerarySchedule(
          entry,
          transportDepartAt: transport?.departAt,
          transportArriveAt: transport?.arriveAt,
          lodgingCheckinDate: lodging?.checkinDate,
        );

  final ItineraryEntry entry;

  /// [ItineraryEntryKind.spot] のとき解決したスポット（見つからなければ null）。
  final ItinerarySpot? spot;

  /// [ItineraryEntryKind.transport] のとき解決した交通（参照切れなら null）。
  final Transport? transport;

  /// [ItineraryEntryKind.lodging] のとき解決した宿泊（参照切れなら null）。
  final Lodging? lodging;

  final ItineraryReferenceStatus referenceStatus;

  final EffectiveItinerarySchedule _schedule;

  /// 表示日バケットに使う実効的な暦日（参照元から導出／上書き）。
  DateTime? get effectiveLocalDate => _schedule.localDate;

  /// 日内の時刻順・時刻表示に使う実効的な開始時刻。
  DateTime? get effectiveStartAt => _schedule.startAt;

  /// 実効的な終了時刻。
  DateTime? get effectiveEndAt => _schedule.endAt;

  /// 表示日が参照元（交通・宿泊）に追従しているか（上書きしていないか）。
  bool get localDateFollowsSource => _schedule.localDateFollowsSource;

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

/// タイムライン項目のユーザー向け日本語表示名（単一の生成元）。
///
/// 計画タブの一覧・移動区間の出発/到着ラベル・移動区間編集の端点候補など、
/// 「その予定を人が読んで分かる名前」が要るすべての箇所でこの関数を使う。
/// 内部の種別コード（`spot`/`transport`/`lodging`/`note` などの enum 名）や
/// ID を決してそのまま画面へ出さない。参照先が削除済みのときは日本語で
/// 「削除済みの…」と示す。
String itineraryTimelineEntryLabel(ItineraryTimelineEntry item) {
  switch (item.entry.kind) {
    case ItineraryEntryKind.spot:
      final name = item.spot?.name.trim();
      if (name != null && name.isNotEmpty) return name;
      return '削除済みのスポット';
    case ItineraryEntryKind.transport:
      final t = item.transport;
      if (t == null) return '削除済みの交通';
      final head = '${t.direction.label} ${t.methodDisplay}'.trim();
      return head.isEmpty ? '交通' : head;
    case ItineraryEntryKind.lodging:
      final l = item.lodging;
      if (l == null) return '削除済みの宿泊';
      final name = l.name?.trim();
      return (name != null && name.isNotEmpty) ? name : '宿泊先';
    case ItineraryEntryKind.note:
      final title = item.entry.titleOverride?.trim();
      return (title != null && title.isNotEmpty) ? title : 'メモ';
  }
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
///
/// [startAtOf] は比較に使う開始時刻を返す（既定は entry 自身の startAt。
/// タイムライン組み立てでは交通・宿泊の**実効的**な開始時刻を渡す, §5.3/点4）。
int compareItineraryEntriesInDay(
  ItineraryEntry a,
  ItineraryEntry b, {
  DateTime? Function(ItineraryEntry)? startAtOf,
}) {
  final resolve = startAtOf ?? (e) => e.startAt;
  final aAt = resolve(a);
  final bAt = resolve(b);
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

/// タイムライン項目（参照解決済み）の同一日内比較。交通・宿泊は参照元から
/// 導出した実効的な開始時刻で並べる。
int compareTimelineEntriesInDay(
  ItineraryTimelineEntry a,
  ItineraryTimelineEntry b,
) =>
    compareItineraryEntriesInDay(
      a.entry,
      b.entry,
      startAtOf: (e) => identical(e, a.entry)
          ? a.effectiveStartAt
          : identical(e, b.entry)
              ? b.effectiveStartAt
              : e.startAt,
    );

/// 日内の隣接する時刻付き項目間で「間に合わない可能性」がある後続項目の
/// entryId を返す（§5.4）。前項目の終了(なければ開始)＋出発後余裕＋（区間が
/// あればその所要分）＋次項目の到着前余裕 が 次項目の開始 を超える場合に警告。
Set<String> itineraryTightConnections({
  required List<ItineraryTimelineEntry> dayEntries,
  required List<ItineraryLeg> legs,
}) {
  // メモ(note)は実際に訪問・移動する予定ではないため、間に合い判定から完全に
  // 除外する。メモを読み飛ばして残った実予定どうしで判定するので、
  // 「予定A → メモ → 予定B」では A と B の間を判定する（Phase 2追補 点6）。
  final realEntries =
      dayEntries.where((e) => e.entry.kind != ItineraryEntryKind.note).toList();
  final warned = <String>{};
  for (var i = 0; i + 1 < realEntries.length; i++) {
    final a = realEntries[i];
    final b = realEntries[i + 1];
    // 交通・宿泊は参照元から導出した実効時刻で間に合い判定する（§5.3/点4）。
    final aEnd = a.effectiveEndAt ?? a.effectiveStartAt;
    final bStart = b.effectiveStartAt;
    if (aEnd == null || bStart == null) continue;
    final leg = legs.firstWhereOrNull(
      (l) =>
          l.originEntryId == a.entry.id && l.destinationEntryId == b.entry.id,
    );
    final travel = leg?.durationMinutes ?? 0;
    final needed = aEnd.add(
      Duration(
        minutes:
            a.entry.bufferAfterMinutes + travel + b.entry.bufferBeforeMinutes,
      ),
    );
    if (needed.isAfter(bStart)) warned.add(b.entry.id);
  }
  return warned;
}

/// 新規予定を追加するときの開始時刻の初期値（Phase 2追補 点5/点6）。
///
/// [dayEntriesSorted] はその日の [compareTimelineEntriesInDay] 済みの並び。
/// 末尾から見て、メモ(note)と「時刻を持たない項目」を読み飛ばし、直前にある
/// **時刻付きの実予定**の**終了時刻**を返す。終了時刻が無ければ（開始のみ・
/// 前予定なし）null を返す（開始時刻を安易に流用しない、現在時刻も入れない）。
DateTime? resolveInitialStartFromPrevious(
  List<ItineraryTimelineEntry> dayEntriesSorted,
) {
  for (final e in dayEntriesSorted.reversed) {
    if (e.entry.kind == ItineraryEntryKind.note) continue; // メモは対象外
    if (e.effectiveStartAt == null) continue; // 時刻を持たない実予定は読み飛ばす
    return e.effectiveEndAt; // 終了があればそれ。無ければ null（開始は流用しない）。
  }
  return null;
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

  // 候補（表示日未設定）: sortOrder→createdAt→id（id を最終 tie-breaker）。
  // 交通・宿泊は参照元から導出した実効日で判定する（参照切れ・元データ未設定で
  // 実効日が無いものだけ候補へ, §5.3/点4）。
  final candidates =
      resolved.where((r) => r.effectiveLocalDate == null).toList()
        ..sort((a, b) {
          final byOrder = a.entry.sortOrder.compareTo(b.entry.sortOrder);
          if (byOrder != 0) return byOrder;
          final byCreated = a.entry.createdAt.compareTo(b.entry.createdAt);
          if (byCreated != 0) return byCreated;
          return a.entry.id.compareTo(b.entry.id);
        });

  // 日別バケット。日付は項目の実効日とアンカーの日から集める。
  final anchors = deriveItineraryAnchors(genba);
  final entriesByDate = <DateTime, List<ItineraryTimelineEntry>>{};
  for (final r in resolved) {
    final ld = r.effectiveLocalDate;
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
        entries: (entriesByDate[date] ?? [])..sort(compareTimelineEntriesInDay),
      ),
  ];

  return ItineraryTimeline(days: days, candidates: candidates);
}

// ---------------------------------------------------------------------------
// 融合タイムライン（§5.1: 会場・アンカー・項目を1本の時刻順の列にまとめる）
// ---------------------------------------------------------------------------

/// 融合タイムラインの1行（会場ヘッダ／公演アンカー／旅程項目）。
/// 単一TZ前提の国内MVPでは entry の startAt（UTCで保持した現地壁時計）と
/// アンカーの会場現地 minuteOfDay を同一軸で比較する（§2.6 注記）。
sealed class ItineraryRow {
  const ItineraryRow();
}

/// 会場ヘッダ（その日の先頭に固定表示。時刻を持たない）。
class ItineraryVenueRow extends ItineraryRow {
  const ItineraryVenueRow(this.venue);
  final ItineraryVenue venue;
}

/// 公演アンカー行（開場・開演・終演）。
class ItineraryAnchorRow extends ItineraryRow {
  const ItineraryAnchorRow(this.anchor);
  final ItineraryAnchor anchor;
}

/// 旅程項目行（スポット・交通・宿泊・メモ）。
class ItineraryEntryRow extends ItineraryRow {
  const ItineraryEntryRow(this.item, {required this.timeUndetermined});
  final ItineraryTimelineEntry item;

  /// 時刻未定（startAt=null）でその日の末尾へ置かれた項目か。
  final bool timeUndetermined;
}

/// 1日の会場・アンカー・項目を時刻順に融合した行列を作る（§5.1/§5.2）。
/// - [venue] が非nullなら先頭に会場ヘッダを置く（公演日のみ）。
/// - 時刻付き（アンカー／startAtあり）は分で昇順、同分はアンカー→項目の順。
/// - 時刻未定の項目は末尾（day.entries の決定的順序を保つ）。
/// - 日跨ぎ（アンカーの date で既に翌日へ振り分け済み）はそのまま尊重する。
List<ItineraryRow> buildItineraryDayRows(
  ItineraryTimelineDay day, {
  ItineraryVenue? venue,
}) {
  final rows = <ItineraryRow>[];
  if (venue != null) rows.add(ItineraryVenueRow(venue));

  final timed = <({int minute, int tiebreak, ItineraryRow row})>[];
  final untimed = <ItineraryRow>[];

  for (final a in day.anchors) {
    timed.add((minute: a.minuteOfDay, tiebreak: 0, row: ItineraryAnchorRow(a)));
  }
  for (final e in day.entries) {
    // 交通・宿泊は参照元から導出した実効的な開始時刻で融合位置を決める。
    final at = e.effectiveStartAt;
    if (at != null) {
      timed.add(
        (
          minute: at.hour * 60 + at.minute,
          tiebreak: 1,
          row: ItineraryEntryRow(e, timeUndetermined: false),
        ),
      );
    } else {
      untimed.add(ItineraryEntryRow(e, timeUndetermined: true));
    }
  }

  // 安定ソート: 分昇順 → 同分はアンカー(0)を項目(1)より前。入力順は既に決定的
  // （anchors: minuteOfDay 昇順 / entries: compareItineraryEntriesInDay）なので
  // mergeSort（安定）で崩さない。
  mergeSort<({int minute, int tiebreak, ItineraryRow row})>(
    timed,
    compare: (a, b) {
      final byMin = a.minute.compareTo(b.minute);
      if (byMin != 0) return byMin;
      return a.tiebreak.compareTo(b.tiebreak);
    },
  );

  rows.addAll(timed.map((t) => t.row));
  rows.addAll(untimed);
  return rows;
}

/// 移動区間の表示配置（§6.2 / Phase 2レビュー点3）。
class ItineraryLegPlacement {
  const ItineraryLegPlacement({
    required this.leg,
    required this.adjacent,
    required this.originLabel,
    required this.destinationLabel,
    this.afterEntryId,
  });

  final ItineraryLeg leg;

  /// 出発項目と到着項目が表示順で隣接しているか。
  final bool adjacent;

  /// [adjacent] のとき、この entryId の直後に区間を表示する。
  final String? afterEntryId;

  /// 端点が見つからない場合も分かる文言に落とす（参照切れ／別日など）。
  final String originLabel;
  final String destinationLabel;
}

/// 全日通しの表示順（[orderedEntries]）に対して各 leg の配置を決める。
/// 端点が隣接していれば出発項目の直後に差し込み、そうでなければ
/// （別日・順序が離れている・端点削除）落とさずに孤立区間として返す（点3）。
List<ItineraryLegPlacement> placeItineraryLegs({
  required List<ItineraryTimelineEntry> orderedEntries,
  required List<ItineraryLeg> legs,
  required String Function(ItineraryTimelineEntry) labelOf,
}) {
  // メモ(note)は移動の前後接続対象にしない。隣接判定用の連番からメモを除くので、
  // 「実予定A → メモ → 実予定B」でも A と B は隣接扱いになり、区間が A の直後へ
  // 差し込まれる（Phase 2追補 点6）。ラベルは全項目分を用意する。
  final indexById = <String, int>{};
  final labelById = <String, String>{};
  var realIndex = 0;
  for (final e in orderedEntries) {
    labelById[e.entry.id] = labelOf(e);
    if (e.entry.kind == ItineraryEntryKind.note) continue;
    indexById[e.entry.id] = realIndex++;
  }
  return [
    for (final leg in legs)
      ItineraryLegPlacement(
        leg: leg,
        adjacent: indexById[leg.originEntryId] != null &&
            indexById[leg.destinationEntryId] != null &&
            indexById[leg.destinationEntryId] ==
                indexById[leg.originEntryId]! + 1,
        afterEntryId: (indexById[leg.originEntryId] != null &&
                indexById[leg.destinationEntryId] ==
                    (indexById[leg.originEntryId] ?? -2) + 1)
            ? leg.originEntryId
            : null,
        originLabel: labelById[leg.originEntryId] ?? '不明な項目',
        destinationLabel: labelById[leg.destinationEntryId] ?? '不明な項目',
      ),
  ];
}
