/// 公共交通のリクエスト条件として使う代表時刻帯を決める純粋関数
/// （旅程Phase 4, itinerary-plan-spec §6.2/§8.3）。
///
/// Google Routes の transit 対応範囲は現在時刻から**過去7日〜未来100日**
/// （確認: developers.google.com/maps/documentation/routes/transit-route,
/// 2026-07-09）。範囲外は明示的に拒否し理由を示す。同ページは「時刻表は
/// 頻繁に変わり、先の予測の一貫性は保証されない」と明記しており、対応範囲内
/// でも遠い未来は「最新ではない可能性」を表示する（[isFarFuture]）。
library;

/// 過去側の対応日数（transit リクエストの下限）。
const int kRoutesMinPastDays = 7;

/// 未来側の対応日数（transit リクエストの上限）。
const int kRoutesMaxFutureDays = 100;

/// この日数を超えたら「遠い未来」として時刻表変動の注意書きを出す閾値。
const int kRoutesFarFutureDays = 30;

/// 代表時刻帯の解決結果。
class RepresentativeRequestTime {
  const RepresentativeRequestTime({
    required this.bucketLabel,
    required this.requestUtc,
    required this.isOutOfSupportedRange,
    required this.isFarFuture,
  });

  /// 代表時刻帯ラベル（例: 平日朝／平日昼／平日夕／平日夜／休日朝／休日昼／休日夕／休日夜）。
  final String bucketLabel;

  /// Google へ送る代表出発日時（UTC）。[isOutOfSupportedRange] のときは
  /// 呼び出し側が送信を止めること（値自体は算出済み）。
  final DateTime requestUtc;

  /// Google Routes transit の対応範囲（過去7日〜未来100日）外か。
  final bool isOutOfSupportedRange;

  /// 対応範囲内だが、時刻表変動により予測の一貫性が保証されない遠い未来
  /// （既定30日超）か。
  final bool isFarFuture;
}

/// [effectiveDepartureUtc] と現在時刻 [nowUtc] から代表時刻帯を解決する。
RepresentativeRequestTime resolveRepresentativeRequestTime(
  DateTime effectiveDepartureUtc,
  DateTime nowUtc,
) {
  final diffDays = effectiveDepartureUtc.difference(nowUtc).inHours / 24;
  final outOfRange =
      diffDays < -kRoutesMinPastDays || diffDays > kRoutesMaxFutureDays;
  final farFuture = !outOfRange && diffDays > kRoutesFarFutureDays;
  return RepresentativeRequestTime(
    bucketLabel: _bucketLabelFor(effectiveDepartureUtc),
    requestUtc: effectiveDepartureUtc,
    isOutOfSupportedRange: outOfRange,
    isFarFuture: farFuture,
  );
}

String _bucketLabelFor(DateTime utc) {
  final local = utc.toLocal();
  final isWeekend =
      local.weekday == DateTime.saturday || local.weekday == DateTime.sunday;
  final dayPart = isWeekend ? '休日' : '平日';
  final hour = local.hour;
  final String timePart;
  if (hour >= 5 && hour < 10) {
    timePart = '朝';
  } else if (hour >= 10 && hour < 15) {
    timePart = '昼';
  } else if (hour >= 15 && hour < 19) {
    timePart = '夕';
  } else {
    timePart = '夜';
  }
  return '$dayPart$timePart';
}
