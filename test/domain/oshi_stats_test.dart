import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';
import 'package:oshi_trip/features/oshi/domain/oshi_stats.dart';

import '../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 7, 10, 12);

  GenbaAggregate agg(Genba g) => GenbaAggregate(genba: g);

  Genba linked(
    String id,
    DateTime date, {
    String group = 'g1',
    AttendanceStatus attendance = AttendanceStatus.planned,
    bool canceled = false,
  }) =>
      makeGenba(id: id, eventDate: date).copyWith(
        oshiGroupId: group,
        attendanceStatus: attendance,
        isCanceled: canceled,
      );

  group('deriveOshiStats', () {
    test('現場数・思い出数・参戦数・次の現場を保存データから導出する', () {
      final genbas = [
        agg(linked('a', DateTime(2026, 8, 1))), // 未来 planned
        agg(
          linked(
            'b',
            DateTime(2026, 6, 1),
            attendance: AttendanceStatus.attended,
          ),
        ), // 過去 attended → 思い出 & 参戦
        agg(linked('c', DateTime(2026, 5, 1))), // 過去 planned → 思い出のみ
        agg(linked('d', DateTime(2026, 9, 1), group: 'g2')), // 別グループ
      ];

      final stats = deriveOshiStats(groupId: 'g1', genbas: genbas, now: now);
      expect(stats.genbaCount, 3);
      expect(stats.memoryCount, 2);
      expect(stats.attendedCount, 1);
      expect(stats.nextGenba?.id, 'a');
    });

    test('参戦数は attendanceStatus == attended だけを数える（日時から推測しない）', () {
      final genbas = [
        // 過去だが未参加のまま（自動で attended にしない）
        agg(linked('past-planned', DateTime(2026, 5, 1))),
        // 過去で明示不参加
        agg(
          linked(
            'past-not',
            DateTime(2026, 5, 2),
            attendance: AttendanceStatus.notAttended,
          ),
        ),
      ];
      final stats = deriveOshiStats(groupId: 'g1', genbas: genbas, now: now);
      expect(stats.attendedCount, 0);
    });

    test('次の現場は中止を除いた最も近い未来の1件', () {
      final genbas = [
        agg(linked('cancel', DateTime(2026, 7, 20), canceled: true)),
        agg(linked('near', DateTime(2026, 7, 25))),
        agg(linked('far', DateTime(2026, 9, 1))),
      ];
      final stats = deriveOshiStats(groupId: 'g1', genbas: genbas, now: now);
      expect(stats.nextGenba?.id, 'near');
    });

    test('紐づく現場が無ければ 0 件・次の現場なしで正常に縮退する', () {
      final stats = deriveOshiStats(groupId: 'g1', genbas: const [], now: now);
      expect(stats.genbaCount, 0);
      expect(stats.memoryCount, 0);
      expect(stats.attendedCount, 0);
      expect(stats.nextGenba, isNull);
    });
  });

  group('deriveUpcomingAnniversaries', () {
    OshiMember member({DateTime? birthday, DateTime? oshiSince}) => OshiMember(
          id: 'm1',
          groupId: 'g1',
          ownerId: 'user-1',
          name: 'メンバーA',
          birthday: birthday,
          oshiSince: oshiSince,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );

    OshiAnniversary anniv(String id, DateTime date) => OshiAnniversary(
          id: id,
          ownerId: 'user-1',
          groupId: 'g1',
          label: '記念日$id',
          date: date,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );

    test('誕生日・推し始めた日・ユーザー記念日を次回発生の近い順に並べる', () {
      final result = deriveUpcomingAnniversaries(
        members: [
          member(
            birthday: DateTime(1995, 3, 15),
            oshiSince: DateTime(2020, 4, 1),
          ),
        ],
        anniversaries: [anniv('x', DateTime(2019, 12, 1))],
        now: now, // 2026-07-10
      );

      expect(result, hasLength(3));
      // custom(12/1)=2026-12-01, birthday(3/15)=2027-03-15, since(4/1)=2027-04-01
      expect(result[0].kind, AnniversaryKind.custom);
      expect(result[0].nextOccurrence, DateTime(2026, 12, 1));
      expect(result[1].kind, AnniversaryKind.birthday);
      expect(result[1].nextOccurrence, DateTime(2027, 3, 15));
      expect(result[2].kind, AnniversaryKind.oshiSince);
      expect(result[2].nextOccurrence, DateTime(2027, 4, 1));
    });

    test('本日の記念日は daysUntil 0（今年の発生日が今日以降なら今年）', () {
      final result = deriveUpcomingAnniversaries(
        members: const [],
        anniversaries: [anniv('today', DateTime(2020, 7, 10))],
        now: now,
      );
      expect(result.single.nextOccurrence, DateTime(2026, 7, 10));
      expect(result.single.daysUntil, 0);
    });

    test('データが無ければ空リストで縮退する', () {
      final result = deriveUpcomingAnniversaries(
        members: const [],
        anniversaries: const [],
        now: now,
      );
      expect(result, isEmpty);
    });
  });
}
