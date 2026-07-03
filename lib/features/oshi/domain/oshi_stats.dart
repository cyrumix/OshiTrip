import '../../../core/time/date_only.dart';
import '../../genba/domain/genba.dart';
import '../../genba/domain/genba_schedule.dart';
import 'oshi.dart';

/// 推し単位の活動統計（design-spec §10/§12.1）。
///
/// すべて保存済みデータから導出し、固定値として保持しない。「参戦数」は
/// [AttendanceStatus.attended] だけを数え、登録数や日時からの推測では数えない。
class OshiStats {
  const OshiStats({
    required this.genbaCount,
    required this.memoryCount,
    required this.attendedCount,
    required this.nextGenba,
  });

  /// 現場数: この推しグループに紐づく現場の総数。
  final int genbaCount;

  /// 思い出数: 思い出タブへ移った（過去・中止済み）現場の数。
  final int memoryCount;

  /// 参戦数: 参加状態が attended の現場の数（明示参加のみ）。
  final int attendedCount;

  /// 次の現場: この推しに紐づく未来（当日・余韻中を含む・中止を除く）の
  /// 現場のうち最も近い1件。無ければ null。
  final Genba? nextGenba;
}

/// owner 限定で取得済みの [genbas]（`GenbaRepository.watchAll` の結果）から、
/// [groupId] に紐づく統計を導出する純関数。owner 分離は呼び出し側の
/// owner 限定クエリに委ねる（入力が既に owner 限定であること）。
OshiStats deriveOshiStats({
  required String groupId,
  required List<GenbaAggregate> genbas,
  required DateTime now,
}) {
  final linked = genbas
      .map((a) => a.genba)
      .where((g) => g.oshiGroupId == groupId)
      .toList();

  final upcoming = linked
      .where((g) => !g.isCanceled && isUpcoming(g, now))
      .toList()
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  return OshiStats(
    genbaCount: linked.length,
    memoryCount: linked.where((g) => isMemory(g, now)).length,
    attendedCount: linked
        .where((g) => g.attendanceStatus == AttendanceStatus.attended)
        .length,
    nextGenba: upcoming.isEmpty ? null : upcoming.first,
  );
}

/// 記念日の種別。
enum AnniversaryKind { birthday, oshiSince, custom }

/// 次回発生日つきの記念日（design-spec §10 の「誕生日・記念日を近い順に」）。
class UpcomingAnniversary {
  const UpcomingAnniversary({
    required this.kind,
    required this.label,
    required this.date,
    required this.nextOccurrence,
    required this.daysUntil,
    this.memberId,
  });

  final AnniversaryKind kind;
  final String label;

  /// 元の日付（誕生日・推し始めた日・記念日）。
  final DateTime date;

  /// 今日以降で最も近い発生日（毎年の記念日として月日で導出）。
  final DateTime nextOccurrence;

  /// 今日から次回発生までの日数（0 = 本日）。
  final int daysUntil;

  /// 紐づくメンバー（null = グループ全体）。
  final String? memberId;
}

/// メンバーの誕生日・推し始めた日と、ユーザー定義記念日 [anniversaries] から、
/// 次回発生が近い順の記念日一覧を導出する純関数。
List<UpcomingAnniversary> deriveUpcomingAnniversaries({
  required List<OshiMember> members,
  required List<OshiAnniversary> anniversaries,
  required DateTime now,
}) {
  final today = dateOnly(now);

  DateTime nextOccurrence(DateTime source) {
    final src = dateOnly(source);
    var occ = DateTime(today.year, src.month, src.day);
    if (occ.isBefore(today)) {
      occ = DateTime(today.year + 1, src.month, src.day);
    }
    return occ;
  }

  UpcomingAnniversary build(
    AnniversaryKind kind,
    String label,
    DateTime date, {
    String? memberId,
  }) {
    final occ = nextOccurrence(date);
    return UpcomingAnniversary(
      kind: kind,
      label: label,
      date: date,
      nextOccurrence: occ,
      daysUntil: occ.difference(today).inDays,
      memberId: memberId,
    );
  }

  final result = <UpcomingAnniversary>[];
  for (final m in members) {
    final birthday = m.birthday;
    if (birthday != null) {
      result.add(
        build(
          AnniversaryKind.birthday,
          '${m.name}の誕生日',
          birthday,
          memberId: m.id,
        ),
      );
    }
    final since = m.oshiSince;
    if (since != null) {
      result.add(
        build(
          AnniversaryKind.oshiSince,
          '${m.name}を推し始めた日',
          since,
          memberId: m.id,
        ),
      );
    }
  }
  for (final a in anniversaries) {
    result.add(
      build(AnniversaryKind.custom, a.label, a.date, memberId: a.memberId),
    );
  }
  result.sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
  return result;
}
