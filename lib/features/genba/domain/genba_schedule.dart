import '../../../core/time/date_only.dart';
import 'genba.dart';

/// 現場の日時スケジュールを解決する純粋ロジック。
///
/// 時刻はすべて「公演日 0:00 からの分数」で保持し、深夜公演
/// （終演が翌日にまたがる場合は 1440 を超える分数）を表現する。
/// 終演予定が未入力の場合の保守的な仮定:
///  - 開演あり → 開演 + 4時間を終演見込みとする
///  - 開演なし → 公演日の終わり（翌日 0:00）を終演見込みとする
class GenbaSchedule {
  GenbaSchedule(this.genba);

  final Genba genba;

  static const Duration _defaultShowLength = Duration(hours: 4);

  DateTime get eventDayStart => dateOnly(genba.eventDate);

  DateTime? get doorAt => _atMinutes(genba.doorTimeMinutes);

  DateTime? get startAt => _atMinutes(genba.startTimeMinutes);

  DateTime? get scheduledEndAt {
    final end = _atMinutes(_normalizedEndMinutes);
    return end;
  }

  /// 状態判定に使う「終演見込み」時刻。
  ///
  /// ユーザーが明示的に「終演した」とした [Genba.manualEndedAt] があれば、
  /// それを実際の終演時刻として無条件に優先する。予定より早い終演も、
  /// 予定より遅い終演（例: 押して延びた・アンコールが長引いた）への訂正も
  /// そのまま反映する。手動終演が無い場合のみ、予定終演または保守的な
  /// 見込み（開演+4時間／時刻未入力なら公演日の終わり）を用いる。
  DateTime get effectiveEndAt {
    final manual = genba.manualEndedAt;
    if (manual != null) return manual.toLocal();
    return scheduledEndAt ??
        (startAt != null
            ? startAt!.add(_defaultShowLength)
            : startOfNextDay(eventDayStart));
  }

  /// 思い出への移行時刻（終演見込み日の翌日 0:00）。
  /// 深夜公演で終演が翌日 1:30 の場合、その翌日から思い出になる。
  /// 終演見込みがちょうど 0:00（時刻未入力=公演日の終わり）の場合は
  /// その瞬間から思い出（余韻中の区間なし）。
  DateTime get memoryStartAt {
    final end = effectiveEndAt;
    return end == dateOnly(end) ? end : startOfNextDay(end);
  }

  /// 終演分数。開演より前の値が入力された場合は翌日終演とみなして補正する。
  int? get _normalizedEndMinutes {
    final end = genba.endTimeMinutes;
    if (end == null) return null;
    final start = genba.startTimeMinutes;
    if (start != null && end <= start) return end + 24 * 60;
    return end;
  }

  DateTime? _atMinutes(int? minutes) =>
      minutes == null ? null : eventDayStart.add(Duration(minutes: minutes));
}

/// 現場状態を導出する（§7.1）。
///
/// - 中止操作が最優先
/// - 公演日 0:00 〜 終演見込み: 本日
/// - 終演見込み 〜 その日の終わり: 余韻中
/// - 翌日 0:00 以降: 思い出
/// - 公演日の [preparingWindow] 日前から: 準備中
/// - それ以前: 予定
GenbaStatus deriveGenbaStatus(
  Genba genba,
  DateTime now, {
  int preparingWindowDays = 7,
}) {
  if (genba.isCanceled) return GenbaStatus.canceled;

  final schedule = GenbaSchedule(genba);
  final dayStart = schedule.eventDayStart;
  final end = schedule.effectiveEndAt;
  final memoryStart = schedule.memoryStartAt;

  if (!now.isBefore(memoryStart)) return GenbaStatus.memory;
  if (!now.isBefore(end)) return GenbaStatus.afterglow;
  if (!now.isBefore(dayStart)) return GenbaStatus.today;

  final preparingStart = dayStart.subtract(Duration(days: preparingWindowDays));
  if (!now.isBefore(preparingStart)) return GenbaStatus.preparing;
  return GenbaStatus.scheduled;
}

/// 「思い出」タブに表示すべきか。中止した現場も記録として思い出に残す。
///
/// 終演済み（余韻中=afterglow）になった瞬間から思い出にも表示する（当日中は
/// 現場一覧・ホームにも残るので両方に出る）。翌日以降は memory になり思い出のみ
/// になる。中止現場は公演日を過ぎたら思い出側に表示する。
bool isMemory(Genba genba, DateTime now) {
  final status = deriveGenbaStatus(genba, now);
  if (status == GenbaStatus.canceled) {
    // 中止現場は公演日を過ぎたら思い出側に表示する（それまでは現場一覧に残す。
    // 中止操作の直後に一覧から消えて確認・編集・取消ができなくなることを
    // 防ぐ, H-07）。
    return !now.isBefore(GenbaSchedule(genba).memoryStartAt);
  }
  // memory（翌日以降）に加え、afterglow（終演済み・当日）も思い出に含める。
  return status == GenbaStatus.memory || status == GenbaStatus.afterglow;
}

/// 「現場」タブ・通常ホームに表示すべきか（未来・当日・余韻中＝終演済み当日を含む）。
///
/// 終演済み当日は現場一覧・ホームにも残す（[isMemory] とは排他ではなく、当日は
/// 両方に出る）。memory（翌日以降）だけ現場一覧から外す。中止は従来どおり公演日
/// までは一覧に残し、翌日以降は思い出のみ。
bool isUpcoming(Genba genba, DateTime now) {
  final status = deriveGenbaStatus(genba, now);
  if (status == GenbaStatus.canceled) {
    return now.isBefore(GenbaSchedule(genba).memoryStartAt);
  }
  return status != GenbaStatus.memory;
}

/// 公演日までの残日数（暦日ベース）。過去は負値。
int daysUntil(Genba genba, DateTime now) =>
    dateOnly(genba.eventDate).difference(dateOnly(now)).inDays;

/// 分数 → 「HH:MM」表示（24時間超は 25:30 のような表記）。
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// 曜日ラベル（月=1 … 日=7 に対応, [DateTime.weekday]）。
const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

/// 公演日 → 「YYYY.MM.DD (曜)」表示（例: 2026.06.15 (土)）。
///
/// アプリ全体で日付表示を統一する（ヒーロー・一覧カード等）。祝日マーカー
/// （例: 月・祝）は祝日カレンダーが必要なため現時点では付与しない。
String formatEventDate(DateTime date) {
  final d = dateOnly(date);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}.$mm.$dd (${_weekdayLabels[d.weekday - 1]})';
}
