import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/features/itinerary/application/itinerary_timeline.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan_aggregate.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_schedule.dart';

import '../helpers/fixtures.dart';

/// Phase 2レビュー点4: 交通・宿泊の元データ更新（名称だけでなく日付・出発時刻・
/// チェックイン日など表示順に関係する値）が、旅程タイムラインへ即時反映される
/// ことを検証する。参照は複製せず、表示日・時刻は毎回参照元から導出する（§5.3）。
void main() {
  group('effectiveItinerarySchedule: 参照元からの導出と上書き', () {
    test('交通は上書きが無ければ出発/到着時刻・日付を参照元から導出する', () {
      final entry = makeItineraryEntry(
        kind: ItineraryEntryKind.transport,
        transportId: 'tr-1',
      );
      final sched = effectiveItinerarySchedule(
        entry,
        transportDepartAt: DateTime.utc(2026, 8, 1, 9, 30),
        transportArriveAt: DateTime.utc(2026, 8, 1, 11),
      );
      expect(sched.localDate, DateTime(2026, 8, 1));
      expect(sched.startAt, DateTime.utc(2026, 8, 1, 9, 30));
      expect(sched.endAt, DateTime.utc(2026, 8, 1, 11));
      expect(sched.localDateFollowsSource, isTrue);
    });

    test('旅程側で日付を上書きしていれば参照元より上書きを優先する', () {
      final entry = makeItineraryEntry(
        kind: ItineraryEntryKind.transport,
        transportId: 'tr-1',
        localDate: DateTime(2026, 8, 3),
        startAt: DateTime.utc(2026, 8, 3, 8),
      );
      final sched = effectiveItinerarySchedule(
        entry,
        transportDepartAt: DateTime.utc(2026, 8, 1, 9, 30),
      );
      expect(sched.localDate, DateTime(2026, 8, 3));
      expect(sched.startAt, DateTime.utc(2026, 8, 3, 8));
      expect(sched.localDateFollowsSource, isFalse);
    });

    test('宿泊は上書きが無ければチェックイン日を表示日にする', () {
      final entry = makeItineraryEntry(
        kind: ItineraryEntryKind.lodging,
        lodgingId: 'lo-1',
      );
      final sched = effectiveItinerarySchedule(
        entry,
        lodgingCheckinDate: DateTime(2026, 8, 2),
      );
      expect(sched.localDate, DateTime(2026, 8, 2));
      expect(sched.localDateFollowsSource, isTrue);
    });

    test('参照切れ（元データ無し・null）なら実効日も null（候補扱い）', () {
      final entry = makeItineraryEntry(
        kind: ItineraryEntryKind.transport,
        transportId: 'tr-1',
      );
      final sched = effectiveItinerarySchedule(entry);
      expect(sched.localDate, isNull);
    });
  });

  group('タイムライン: 元データ変更で表示日が移動する', () {
    ItineraryPlanAggregate aggregateWithTransportEntry() =>
        ItineraryPlanAggregate(
          plan: makeItineraryPlan(),
          entries: [
            makeItineraryEntry(
              id: 'e-transport',
              kind: ItineraryEntryKind.transport,
              transportId: 'tr-1',
              // localDate は付けない（参照元に追従）。
            ),
          ],
        );

    test('交通の出発時刻を別日へ変更すると、項目はその新しい日のバケットへ移動する', () {
      final genba = makeGenba(id: 'genba-1', eventDate: DateTime(2026, 8, 1));
      final aggregate = aggregateWithTransportEntry();

      // 変更前: 8/1 出発 → 8/1 のバケットに入る。
      final before = buildItineraryTimeline(
        aggregate: aggregate,
        genba: genba,
        transports: [
          makeTransportRef(id: 'tr-1')
              .copyWith(departAt: DateTime.utc(2026, 8, 1, 10)),
        ],
        lodgings: const [],
      );
      final aug1 =
          before.days.firstWhere((d) => d.date == DateTime(2026, 8, 1));
      expect(
        aug1.entries.map((e) => e.entry.id),
        contains('e-transport'),
      );

      // 変更後: 元データの departAt を 8/3 へ更新 → 8/3 のバケットへ移動する。
      final after = buildItineraryTimeline(
        aggregate: aggregate,
        genba: genba,
        transports: [
          makeTransportRef(id: 'tr-1')
              .copyWith(departAt: DateTime.utc(2026, 8, 3, 10)),
        ],
        lodgings: const [],
      );
      // 8/1 には交通項目が無い（会場アンカーのみ）。
      final aug1After = after.days.where((d) => d.date == DateTime(2026, 8, 1));
      expect(
        aug1After.expand((d) => d.entries).map((e) => e.entry.id),
        isNot(contains('e-transport')),
      );
      // 8/3 に移動している。
      final aug3 = after.days.firstWhere((d) => d.date == DateTime(2026, 8, 3));
      expect(aug3.entries.map((e) => e.entry.id), contains('e-transport'));
    });

    test('出発時刻の変更で同一日内の並び順（時刻順）も更新される', () {
      final genba = makeGenba(id: 'genba-1', eventDate: DateTime(2026, 8, 1));
      final aggregate = ItineraryPlanAggregate(
        plan: makeItineraryPlan(),
        entries: [
          makeItineraryEntry(
            id: 'e-note',
            kind: ItineraryEntryKind.note,
            localDate: DateTime(2026, 8, 1),
            startAt: DateTime.utc(2026, 8, 1, 12),
          ),
          makeItineraryEntry(
            id: 'e-transport',
            kind: ItineraryEntryKind.transport,
            transportId: 'tr-1',
          ),
        ],
      );

      // 交通が 08:00 出発 → note(12:00) より前に並ぶ。
      final early = buildItineraryTimeline(
        aggregate: aggregate,
        genba: genba,
        transports: [
          makeTransportRef(id: 'tr-1')
              .copyWith(departAt: DateTime.utc(2026, 8, 1, 8)),
        ],
        lodgings: const [],
      );
      expect(
        early.days
            .firstWhere((d) => d.date == DateTime(2026, 8, 1))
            .entries
            .map((e) => e.entry.id),
        ['e-transport', 'e-note'],
      );

      // 交通を 18:00 出発へ変更 → note の後ろへ並び替わる。
      final late = buildItineraryTimeline(
        aggregate: aggregate,
        genba: genba,
        transports: [
          makeTransportRef(id: 'tr-1')
              .copyWith(departAt: DateTime.utc(2026, 8, 1, 18)),
        ],
        lodgings: const [],
      );
      expect(
        late.days
            .firstWhere((d) => d.date == DateTime(2026, 8, 1))
            .entries
            .map((e) => e.entry.id),
        ['e-note', 'e-transport'],
      );
    });
  });
}
