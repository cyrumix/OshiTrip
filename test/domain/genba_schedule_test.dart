import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/domain/genba_schedule.dart';

import '../helpers/fixtures.dart';

void main() {
  final eventDate = DateTime(2026, 7, 10);

  group('通常公演（18:00開演 / 21:00終演）', () {
    final genba = makeGenba(
      eventDate: eventDate,
      doorTimeMinutes: 17 * 60,
      startTimeMinutes: 18 * 60,
      endTimeMinutes: 21 * 60,
    );

    test('8日以上前は「予定」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 2, 12)),
        GenbaStatus.scheduled,
      );
    });

    test('7日前から「準備中」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 3, 0, 0)),
        GenbaStatus.preparing,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 9, 23, 59)),
        GenbaStatus.preparing,
      );
    });

    test('公演日は0:00から「本日」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 0, 0)),
        GenbaStatus.today,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 20, 59)),
        GenbaStatus.today,
      );
    });

    test('終演予定後は「余韻中」、翌日0:00から「思い出」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 21, 0)),
        GenbaStatus.afterglow,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 23, 59)),
        GenbaStatus.afterglow,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 11, 0, 0)),
        GenbaStatus.memory,
      );
    });
  });

  group('深夜公演（23:30開演 / 翌1:30終演 = 1530分）', () {
    final genba = makeGenba(
      eventDate: eventDate,
      startTimeMinutes: 23 * 60 + 30,
      endTimeMinutes: 25 * 60 + 30,
    );

    test('日を跨いでも終演までは「本日」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 11, 1, 0)),
        GenbaStatus.today,
      );
    });

    test('翌日1:30以降はその日の終わりまで「余韻中」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 11, 1, 30)),
        GenbaStatus.afterglow,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 11, 23, 0)),
        GenbaStatus.afterglow,
      );
    });

    test('終演日の翌日から「思い出」', () {
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 12, 0, 0)),
        GenbaStatus.memory,
      );
    });

    test('終演が開演より前の入力は翌日終演として補正される', () {
      final wrapped = makeGenba(
        eventDate: eventDate,
        startTimeMinutes: 23 * 60 + 30,
        endTimeMinutes: 90, // 1:30 と入力された
      );
      expect(
        GenbaSchedule(wrapped).effectiveEndAt,
        DateTime(2026, 7, 11, 1, 30),
      );
    });
  });

  group('終演予定なし', () {
    test('開演ありなら開演+4時間を終演見込みとする', () {
      final genba = makeGenba(
        eventDate: eventDate,
        startTimeMinutes: 18 * 60,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 21, 59)),
        GenbaStatus.today,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 22, 0)),
        GenbaStatus.afterglow,
      );
    });

    test('時刻未入力なら公演日いっぱいが「本日」、翌日から「思い出」', () {
      final genba = makeGenba(eventDate: eventDate);
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 23, 59)),
        GenbaStatus.today,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 11, 0, 0)),
        GenbaStatus.memory,
      );
    });
  });

  group('中止・手動終演・日程変更', () {
    test('中止は常に「中止」', () {
      final genba = makeGenba(eventDate: eventDate, isCanceled: true);
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 1)),
        GenbaStatus.canceled,
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 19)),
        GenbaStatus.canceled,
      );
    });

    test(
        '中止現場は公演日を過ぎるまで現場一覧に残り（消えない）、'
        '過ぎると思い出に移る（H-07）', () {
      final genba = makeGenba(eventDate: eventDate, isCanceled: true);
      // 中止操作の直後（公演日より前）は現場一覧に残り、思い出には出ない。
      // ここが消えると確認・編集・日程変更・中止取消・削除ができなくなる
      // （H-07の欠陥そのもの）。
      expect(isUpcoming(genba, DateTime(2026, 7, 1)), isTrue);
      expect(isMemory(genba, DateTime(2026, 7, 1)), isFalse);
      expect(isMemory(genba, DateTime(2026, 7, 9)), isFalse);
      // 公演日を過ぎたら思い出に記録として残る。
      expect(isMemory(genba, DateTime(2026, 7, 11, 0, 1)), isTrue);
      expect(isUpcoming(genba, DateTime(2026, 7, 11, 0, 1)), isFalse);
    });

    test('現場一覧と思い出は常に排他的（どちらにも出ない・両方に出るがない）', () {
      final canceled = makeGenba(eventDate: eventDate, isCanceled: true);
      final scheduled = makeGenba(eventDate: eventDate);
      for (final now in [
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 10, 12),
        DateTime(2026, 7, 11, 0, 1),
      ]) {
        for (final g in [canceled, scheduled]) {
          expect(
            isUpcoming(g, now) != isMemory(g, now),
            isTrue,
            reason:
                'isUpcoming/isMemory は $now 時点で排他的であるべき（isCanceled=${g.isCanceled}）',
          );
        }
      }
    });

    test('「終演した」操作で予定より早く余韻中になる', () {
      final genba = makeGenba(
        eventDate: eventDate,
        startTimeMinutes: 18 * 60,
        endTimeMinutes: 21 * 60,
        manualEndedAt: DateTime(2026, 7, 10, 20, 15).toUtc(),
      );
      expect(
        deriveGenbaStatus(genba, DateTime(2026, 7, 10, 20, 30)),
        GenbaStatus.afterglow,
      );
    });

    test('日程変更（過去→未来）で思い出から現場へ戻る', () {
      final past = makeGenba(eventDate: DateTime(2026, 6, 1));
      final now = DateTime(2026, 7, 2);
      expect(isMemory(past, now), isTrue);

      final rescheduled = past.copyWith(eventDate: DateTime(2026, 7, 20));
      expect(isMemory(rescheduled, now), isFalse);
      expect(isUpcoming(rescheduled, now), isTrue);
      expect(deriveGenbaStatus(rescheduled, now), GenbaStatus.scheduled);
    });
  });

  test('残日数は暦日ベース', () {
    final genba = makeGenba(eventDate: eventDate);
    expect(daysUntil(genba, DateTime(2026, 7, 8, 23, 59)), 2);
    expect(daysUntil(genba, DateTime(2026, 7, 10, 0, 1)), 0);
    expect(daysUntil(genba, DateTime(2026, 7, 12)), -2);
  });

  test('分数表記は24時間超を 25:30 形式にする', () {
    expect(formatMinutes(18 * 60), '18:00');
    expect(formatMinutes(25 * 60 + 30), '25:30');
  });
}
