import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/representative_time_bucket.dart';

/// 旅程Phase 4: 公共交通のリクエスト条件（代表時刻帯）解決（itinerary-plan-spec
/// §6.2/§8.3）。Google Routes transit の対応範囲は過去7日〜未来100日
/// （developers.google.com/maps/documentation/routes/transit-route, 2026-07-09確認）。
void main() {
  final now = DateTime.utc(2026, 7, 9, 12); // 木曜 21:00 JST 相当（UTC+9換算は表示のみ）

  test('現在時刻は範囲内・遠い未来ではない', () {
    final r = resolveRepresentativeRequestTime(now, now);
    expect(r.isOutOfSupportedRange, isFalse);
    expect(r.isFarFuture, isFalse);
  });

  test('未来100日ちょうどは範囲内', () {
    final t = now.add(const Duration(days: 100));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.isOutOfSupportedRange, isFalse);
  });

  test('未来101日は範囲外', () {
    final t = now.add(const Duration(days: 101));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.isOutOfSupportedRange, isTrue);
  });

  test('過去7日ちょうどは範囲内', () {
    final t = now.subtract(const Duration(days: 7));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.isOutOfSupportedRange, isFalse);
  });

  test('過去8日は範囲外', () {
    final t = now.subtract(const Duration(days: 8));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.isOutOfSupportedRange, isTrue);
  });

  test('31日後は範囲内だが遠い未来（時刻表変動の注意）', () {
    final t = now.add(const Duration(days: 31));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.isOutOfSupportedRange, isFalse);
    expect(r.isFarFuture, isTrue);
  });

  test('30日後ちょうどは遠い未来ではない', () {
    final t = now.add(const Duration(days: 30));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.isFarFuture, isFalse);
  });

  test('requestUtcは範囲外でも算出される（送信は呼び出し側が止める）', () {
    final t = now.add(const Duration(days: 200));
    final r = resolveRepresentativeRequestTime(t, now);
    expect(r.requestUtc, t);
    expect(r.isOutOfSupportedRange, isTrue);
  });

  test('平日/休日・時間帯でラベルが変わる', () {
    // ラベルは現地壁時計（.toLocal()）で決まるため、実行ホストのタイムゾーンに
    // 依存させないよう UTC 変換ではなくローカル DateTime を直接指定する
    // （.toLocal() はローカル値に対して恒等になる）。
    // 2026-07-09 は木曜（平日）、2026-07-11 は土曜（休日）。
    final weekdayMorning = DateTime(2026, 7, 9, 9); // 平日 朝
    final r1 = resolveRepresentativeRequestTime(weekdayMorning, now);
    expect(r1.bucketLabel, '平日朝');

    final weekend = DateTime(2026, 7, 11, 12); // 休日 昼
    final r2 = resolveRepresentativeRequestTime(weekend, now);
    expect(r2.bucketLabel, '休日昼');

    final weekdayNight = DateTime(2026, 7, 9, 22); // 平日 夜
    final r3 = resolveRepresentativeRequestTime(weekdayNight, now);
    expect(r3.bucketLabel, '平日夜');

    final weekdayEvening = DateTime(2026, 7, 9, 17); // 平日 夕
    final r4 = resolveRepresentativeRequestTime(weekdayEvening, now);
    expect(r4.bucketLabel, '平日夕');
  });
}
