import 'itinerary_entry.dart';

/// 旅程項目の「表示・並び順に使う実効日時」を決める純粋関数群
/// （itinerary-plan-spec.md §5.3 / Phase 2レビュー点4）。
///
/// 設計方針（参照は複製しない, §5.3）:
/// - 交通・宿泊項目は既存の交通(`transport`)・宿泊(`lodging`)を**参照するだけ**で
///   日時をスナップショットしない。表示日・開始/終了時刻は毎回**参照元から導出**
///   する。これにより元データ（出発時刻・チェックイン日など）を更新すると、
///   名称だけでなく表示日・並び順にも即座に反映される。
/// - ただしユーザーが旅程側で独自の日時を指定した場合は、その値を**明示的な
///   上書き**として尊重する。上書きの有無は「entry 側の該当フィールドが
///   非null か」でモデル化する（null = 参照元に追従, 非null = 上書き）。
/// - スポット・メモ（source を持たない種別）は従来どおり entry 自身の値を使う。
///
/// タイムゾーン注記（国内単一TZ MVP, §2.6）: 日時は「現地壁時計を UTC フラグで
/// 保持」する規約のため、暦日は UTC 変換せず Y/M/D をそのまま用いる（既存の
/// タイムライン `_dateKey` / インポート実装と一致）。

/// 参照元から導出（または上書き）した実効的な日時。
class EffectiveItinerarySchedule {
  const EffectiveItinerarySchedule({
    required this.localDate,
    required this.startAt,
    required this.endAt,
    required this.localDateFollowsSource,
  });

  /// 表示日バケットに使う暦日（未定なら null → 候補リストへ）。
  final DateTime? localDate;

  /// 日内の時刻順・融合表示に使う開始時刻（未定なら null）。
  final DateTime? startAt;

  /// 終了時刻（未定なら null）。
  final DateTime? endAt;

  /// 表示日が参照元（交通・宿泊）に追従しているか（true = 上書きしていない）。
  /// spot/note では常に false（追従元が無い）。
  final bool localDateFollowsSource;
}

/// [DateTime] を暦日（時刻を落とした Y/M/D）へ正規化する。null は素通し。
DateTime? itineraryDateOnly(DateTime? dt) =>
    dt == null ? null : DateTime(dt.year, dt.month, dt.day);

/// [entry] の実効日時を、参照元（交通・宿泊）の日時を織り込んで求める。
///
/// [transportDepartAt] / [transportArriveAt] は交通項目の参照元 `transports`
/// の出発・到着時刻、[lodgingCheckinDate] は宿泊項目の参照元 `lodgings` の
/// チェックイン日。参照切れ（見つからない）ときは null を渡すこと。
EffectiveItinerarySchedule effectiveItinerarySchedule(
  ItineraryEntry entry, {
  DateTime? transportDepartAt,
  DateTime? transportArriveAt,
  DateTime? lodgingCheckinDate,
}) {
  switch (entry.kind) {
    case ItineraryEntryKind.transport:
      return EffectiveItinerarySchedule(
        localDate: entry.localDate ?? itineraryDateOnly(transportDepartAt),
        startAt: entry.startAt ?? transportDepartAt,
        endAt: entry.endAt ?? transportArriveAt,
        localDateFollowsSource: entry.localDate == null,
      );
    case ItineraryEntryKind.lodging:
      return EffectiveItinerarySchedule(
        localDate: entry.localDate ?? itineraryDateOnly(lodgingCheckinDate),
        startAt: entry.startAt,
        endAt: entry.endAt,
        localDateFollowsSource: entry.localDate == null,
      );
    case ItineraryEntryKind.spot:
    case ItineraryEntryKind.note:
      return EffectiveItinerarySchedule(
        localDate: entry.localDate,
        startAt: entry.startAt,
        endAt: entry.endAt,
        localDateFollowsSource: false,
      );
  }
}

/// スポット訪問を**新規追加**するときの訪問日の初期値を優先順位で決める
/// （itinerary-plan-spec.md §5.5 / Phase 2追補 点4）。
///
/// 優先順位: 現在表示・選択中の日 → 挿入位置前後の予定日 → 現場開催日 →
/// 旅程開始日。いずれも取得できないときは null（未設定＝候補リスト）を返し、
/// **端末の本日を初期値に使わない**。返す値は時刻を落とした暦日に正規化する
/// （日付のみの値とタイムゾーン付き日時を混同しない）。
DateTime? resolveInitialVisitDate({
  DateTime? currentDay,
  DateTime? adjacentDate,
  DateTime? genbaEventDate,
  DateTime? planStartDate,
}) {
  final d = currentDay ?? adjacentDate ?? genbaEventDate ?? planStartDate;
  return itineraryDateOnly(d);
}

/// 時刻（時・分）だけを表す軽量な値（domain を Flutter 非依存に保つため
/// TimeOfDay を使わない）。
typedef ItineraryClockTime = ({int hour, int minute});

DateTime? _combineDateTime(DateTime? date, ItineraryClockTime? t) =>
    (date == null || t == null)
        ? null
        : DateTime(date.year, date.month, date.day, t.hour, t.minute);

/// 移動区間(leg)の出発/到着日時を、端点の予定日と入力時刻から内部決定する
/// （Phase 2追補 点3）。日付は入力させず前後予定から決める:
/// - 出発日 = 出発元(origin)の予定日、到着日 = 到着先(destination)の予定日。
/// - 同日で到着時刻が出発時刻より前なら、日跨ぎとして到着日を翌日にする。
/// - 端点の予定日が取得できなければその日時は null（本日を勝手に入れない）。
///
/// 返す [DateTime] は現地壁時計（UTCフラグ無しのローカル値）で、保存時に
/// 呼び出し側が `toUtc()` する（既存 departureAt/arrivalAt の保持形式に合わせる）。
({DateTime? departure, DateTime? arrival}) deriveLegTimestamps({
  DateTime? originDate,
  DateTime? destinationDate,
  ItineraryClockTime? departureTime,
  ItineraryClockTime? arrivalTime,
}) {
  final departure = _combineDateTime(originDate, departureTime);
  var arrivalDate = destinationDate;
  if (originDate != null &&
      destinationDate != null &&
      departureTime != null &&
      arrivalTime != null &&
      originDate.year == destinationDate.year &&
      originDate.month == destinationDate.month &&
      originDate.day == destinationDate.day) {
    final depMin = departureTime.hour * 60 + departureTime.minute;
    final arrMin = arrivalTime.hour * 60 + arrivalTime.minute;
    if (arrMin < depMin) {
      arrivalDate = destinationDate.add(const Duration(days: 1));
    }
  }
  final arrival = _combineDateTime(arrivalDate, arrivalTime);
  return (departure: departure, arrival: arrival);
}

/// 実効的な表示日だけが必要な場合の軽量版（並び替えの同一日検証などで使う）。
DateTime? effectiveItineraryLocalDate(
  ItineraryEntry entry, {
  DateTime? transportDepartAt,
  DateTime? lodgingCheckinDate,
}) =>
    effectiveItinerarySchedule(
      entry,
      transportDepartAt: transportDepartAt,
      lodgingCheckinDate: lodgingCheckinDate,
    ).localDate;
