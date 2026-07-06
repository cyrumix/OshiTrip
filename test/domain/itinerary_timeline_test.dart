import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/application/itinerary_timeline.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan_aggregate.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot.dart';

import '../helpers/fixtures.dart';

/// 旅程タイムライン組み立て（純粋関数）のテスト（itinerary-plan-spec.md §5）。
void main() {
  ItineraryPlanAggregate aggregateOf(
    List<ItineraryEntry> entries, {
    List<ItinerarySpot> spots = const [],
  }) {
    return ItineraryPlanAggregate(
      plan: makeItineraryPlan(),
      spots: spots,
      entries: entries,
    );
  }

  group('公演アンカーを Genba から導出（DBへ保存しない）', () {
    test('door/open/end が設定分だけ、会場現地時刻で出る', () {
      final genba = makeGenba(
        eventDate: DateTime(2026, 8, 1),
        doorTimeMinutes: 17 * 60, // 17:00
        startTimeMinutes: 18 * 60, // 18:00
        endTimeMinutes: 20 * 60 + 30, // 20:30
      );
      final anchors = deriveItineraryAnchors(genba);
      expect(anchors.map((a) => a.kind), [
        ItineraryAnchorKind.doorOpen,
        ItineraryAnchorKind.showStart,
        ItineraryAnchorKind.showEnd,
      ]);
      expect(anchors[0].date, DateTime(2026, 8, 1));
      expect(anchors[0].minuteOfDay, 17 * 60);
      expect(anchors[2].minuteOfDay, 20 * 60 + 30);
    });

    test('未設定の時刻はアンカーを作らない', () {
      final genba = makeGenba(
        eventDate: DateTime(2026, 8, 1),
        startTimeMinutes: 18 * 60,
      );
      final anchors = deriveItineraryAnchors(genba);
      expect(anchors.map((a) => a.kind), [ItineraryAnchorKind.showStart]);
    });

    test('日跨ぎ（分>=1440）は翌日の暦日へ補正される', () {
      final genba = makeGenba(
        eventDate: DateTime(2026, 8, 1),
        startTimeMinutes: 23 * 60, // 23:00 当日
        endTimeMinutes: 25 * 60, // 翌 1:00
      );
      final anchors = deriveItineraryAnchors(genba);
      final end =
          anchors.firstWhere((a) => a.kind == ItineraryAnchorKind.showEnd);
      expect(end.date, DateTime(2026, 8, 2));
      expect(end.minuteOfDay, 60); // 1:00
    });
  });

  group('日別の決定的順序（localDate→startAt→sortOrder→createdAt）', () {
    test('時刻ありは時刻順、時刻未定は各日の末尾', () {
      final day = DateTime(2026, 8, 1);
      final entries = [
        makeItineraryEntry(id: 'late', localDate: day, sortOrder: 0)
            .copyWith(startAt: DateTime.utc(2026, 8, 1, 20)),
        makeItineraryEntry(id: 'undated-time', localDate: day, sortOrder: 5),
        makeItineraryEntry(id: 'early', localDate: day, sortOrder: 9)
            .copyWith(startAt: DateTime.utc(2026, 8, 1, 9)),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(eventDate: day),
        transports: const [],
        lodgings: const [],
      );
      expect(timeline.days, hasLength(1));
      expect(
        timeline.days.single.entries.map((e) => e.entry.id),
        ['early', 'late', 'undated-time'],
      );
    });

    test('時刻同着は sortOrder→createdAt で決定的', () {
      final day = DateTime(2026, 8, 1);
      final at = DateTime.utc(2026, 8, 1, 10);
      final entries = [
        makeItineraryEntry(id: 'b', localDate: day, sortOrder: 2)
            .copyWith(startAt: at),
        makeItineraryEntry(id: 'a', localDate: day, sortOrder: 1)
            .copyWith(startAt: at),
        makeItineraryEntry(
          id: 'a2',
          localDate: day,
          sortOrder: 1,
          createdAt: DateTime.utc(2026, 1, 2),
        ).copyWith(startAt: at),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(eventDate: day),
        transports: const [],
        lodgings: const [],
      );
      // sortOrder 1 が先（同 sortOrder は createdAt 昇順で a → a2）、次に 2。
      expect(
        timeline.days.single.entries.map((e) => e.entry.id),
        ['a', 'a2', 'b'],
      );
    });

    test('全ソートキーが同値でも id で完全に決定的に並ぶ（日内）', () {
      final day = DateTime(2026, 8, 1);
      final at = DateTime.utc(2026, 8, 1, 10);
      // localDate・startAt・sortOrder・createdAt すべて同一。id だけ異なる。
      final entries = [
        for (final id in ['e-c', 'e-a', 'e-b'])
          makeItineraryEntry(id: id, localDate: day, sortOrder: 0)
              .copyWith(startAt: at),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(eventDate: day),
        transports: const [],
        lodgings: const [],
      );
      expect(
        timeline.days.single.entries.map((e) => e.entry.id),
        ['e-a', 'e-b', 'e-c'],
      );
    });

    test('候補も全ソートキー同値なら id で決定的に並ぶ', () {
      final entries = [
        for (final id in ['c-z', 'c-a', 'c-m'])
          makeItineraryEntry(id: id, sortOrder: 0),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(eventDate: DateTime(2026, 8, 1)),
        transports: const [],
        lodgings: const [],
      );
      expect(
        timeline.candidates.map((e) => e.entry.id),
        ['c-a', 'c-m', 'c-z'],
      );
    });

    test('複数日は日付昇順、各日にアンカーが割り当たる', () {
      final entries = [
        makeItineraryEntry(id: 'd2', localDate: DateTime(2026, 8, 2)),
        makeItineraryEntry(id: 'd1', localDate: DateTime(2026, 8, 1)),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(
          eventDate: DateTime(2026, 8, 1),
          startTimeMinutes: 18 * 60,
        ),
        transports: const [],
        lodgings: const [],
      );
      expect(
        timeline.days.map((d) => d.date),
        [DateTime(2026, 8, 1), DateTime(2026, 8, 2)],
      );
      // 開演アンカーは 8/1 の日に置かれる。
      expect(
        timeline.days.first.anchors.map((a) => a.kind),
        [ItineraryAnchorKind.showStart],
      );
      expect(timeline.days.last.anchors, isEmpty);
    });
  });

  group('日付未定は候補、日付未定・時刻未定を失わない', () {
    test('localDate=null は candidates（sortOrder→createdAt）へ', () {
      final entries = [
        makeItineraryEntry(id: 'c2', sortOrder: 2),
        makeItineraryEntry(id: 'c1', sortOrder: 1),
        makeItineraryEntry(id: 'dated', localDate: DateTime(2026, 8, 1)),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(eventDate: DateTime(2026, 8, 1)),
        transports: const [],
        lodgings: const [],
      );
      expect(timeline.candidates.map((e) => e.entry.id), ['c1', 'c2']);
      expect(
        timeline.days.single.entries.map((e) => e.entry.id),
        ['dated'],
      );
    });
  });

  group('交通・宿泊は参照解決し、複製しない。参照切れを状態で返す', () {
    test('存在する交通・宿泊・スポットは resolved', () {
      final spot = makeItinerarySpot(id: 's1');
      final transport = makeTransportRef(id: 't1');
      final lodging = makeLodgingRef(id: 'l1');
      final entries = [
        makeItineraryEntry(
          id: 'e-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 's1',
          localDate: DateTime(2026, 8, 1),
        ),
        makeItineraryEntry(
          id: 'e-tra',
          kind: ItineraryEntryKind.transport,
          transportId: 't1',
          localDate: DateTime(2026, 8, 1),
          sortOrder: 1,
        ),
        makeItineraryEntry(
          id: 'e-lod',
          kind: ItineraryEntryKind.lodging,
          lodgingId: 'l1',
          localDate: DateTime(2026, 8, 1),
          sortOrder: 2,
        ),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries, spots: [spot]),
        genba: makeGenba(eventDate: DateTime(2026, 8, 1)),
        transports: [transport],
        lodgings: [lodging],
      );
      final items = timeline.days.single.entries;
      expect(items.every((i) => !i.isReferenceMissing), isTrue);
      expect(items.firstWhere((i) => i.entry.id == 'e-spot').spot, spot);
      expect(
        items.firstWhere((i) => i.entry.id == 'e-tra').transport,
        transport,
      );
      expect(items.firstWhere((i) => i.entry.id == 'e-lod').lodging, lodging);
    });

    test('参照先が無い交通・宿泊・スポットは missing（項目自体は残る）', () {
      final entries = [
        makeItineraryEntry(
          id: 'e-tra',
          kind: ItineraryEntryKind.transport,
          transportId: 'gone',
          localDate: DateTime(2026, 8, 1),
        ),
        makeItineraryEntry(
          id: 'e-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'gone',
          localDate: DateTime(2026, 8, 1),
          sortOrder: 1,
        ),
      ];
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf(entries),
        genba: makeGenba(eventDate: DateTime(2026, 8, 1)),
        transports: const [],
        lodgings: const [],
      );
      final items = timeline.days.single.entries;
      expect(items, hasLength(2)); // 参照切れでも項目は消えない
      expect(
        items.firstWhere((i) => i.entry.id == 'e-tra').isReferenceMissing,
        isTrue,
      );
      expect(
        items.firstWhere((i) => i.entry.id == 'e-tra').transport,
        isNull,
      );
      expect(
        items.firstWhere((i) => i.entry.id == 'e-spot').isReferenceMissing,
        isTrue,
      );
    });

    test('note は参照を持たず resolved 扱い', () {
      final timeline = buildItineraryTimeline(
        aggregate: aggregateOf([
          makeItineraryEntry(
            id: 'note',
            kind: ItineraryEntryKind.note,
            localDate: DateTime(2026, 8, 1),
          ),
        ]),
        genba: makeGenba(eventDate: DateTime(2026, 8, 1)),
        transports: const [],
        lodgings: const [],
      );
      expect(timeline.days.single.entries.single.isReferenceMissing, isFalse);
    });
  });

  group('間に合わない可能性（余裕不足）の判定', () {
    ItineraryTimelineEntry noteAt(
      String id,
      DateTime start,
      DateTime end, {
      int bufferAfter = 0,
      int bufferBefore = 0,
    }) {
      return resolveItineraryEntry(
        makeItineraryEntry(
          id: id,
          kind: ItineraryEntryKind.note,
          localDate: DateTime(start.year, start.month, start.day),
          bufferAfterMinutes: bufferAfter,
          bufferBeforeMinutes: bufferBefore,
        ).copyWith(startAt: start, endAt: end),
        spots: const [],
        transports: const [],
        lodgings: const [],
      );
    }

    test('前の終了＋余裕＋（区間の所要）が次の開始を超えると次項目を警告', () {
      final a = noteAt(
        'a',
        DateTime.utc(2026, 8, 1, 10),
        DateTime.utc(2026, 8, 1, 11),
        bufferAfter: 15,
      );
      final b = noteAt(
        'b',
        DateTime.utc(2026, 8, 1, 11, 10),
        DateTime.utc(2026, 8, 1, 12),
        bufferBefore: 0,
      );
      // 11:00 + 15分 = 11:15 > 11:10 → b は間に合わない可能性。
      final warned = itineraryTightConnections(
        dayEntries: [a, b],
        legs: const [],
      );
      expect(warned, {'b'});
    });

    test('十分な余裕があれば警告しない', () {
      final a = noteAt(
        'a',
        DateTime.utc(2026, 8, 1, 10),
        DateTime.utc(2026, 8, 1, 11),
      );
      final b = noteAt(
        'b',
        DateTime.utc(2026, 8, 1, 13),
        DateTime.utc(2026, 8, 1, 14),
      );
      expect(
        itineraryTightConnections(dayEntries: [a, b], legs: const []),
        isEmpty,
      );
    });

    test('区間の所要時間も考慮する', () {
      final a = noteAt(
        'a',
        DateTime.utc(2026, 8, 1, 10),
        DateTime.utc(2026, 8, 1, 11),
      );
      final b = noteAt(
        'b',
        DateTime.utc(2026, 8, 1, 11, 20),
        DateTime.utc(2026, 8, 1, 12),
      );
      // 余裕0でも 11:00→11:20 は20分空きだが、移動30分の区間があると足りない。
      final leg = makeItineraryLeg(
        originEntryId: 'a',
        destinationEntryId: 'b',
        durationMinutes: 30,
      );
      expect(
        itineraryTightConnections(dayEntries: [a, b], legs: [leg]),
        {'b'},
      );
    });
  });
}
