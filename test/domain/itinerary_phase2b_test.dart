import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/features/itinerary/application/itinerary_timeline.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_schedule.dart';

import '../helpers/fixtures.dart';

/// Phase 2追補（計画機能の仕様変更）の純粋関数テスト:
/// 訪問日の初期値（点4）／新規予定の開始時刻の初期値（点5）／メモの警告除外
/// （点6）／移動区間の日付を前後予定から決定（点3・日跨ぎ）。
void main() {
  // 実予定（spot）を1件、指定時刻で作るヘルパー（tight判定・start初期値用）。
  ItineraryTimelineEntry spot(
    String id, {
    DateTime? start,
    DateTime? end,
    int bufferAfter = 0,
    int bufferBefore = 0,
  }) =>
      resolveItineraryEntry(
        makeItineraryEntry(
          id: id,
          kind: ItineraryEntryKind.spot,
          spotId: id,
          bufferAfterMinutes: bufferAfter,
          bufferBeforeMinutes: bufferBefore,
        ).copyWith(startAt: start, endAt: end),
        spots: const [],
        transports: const [],
        lodgings: const [],
      );

  ItineraryTimelineEntry note(String id, {DateTime? start, DateTime? end}) =>
      resolveItineraryEntry(
        makeItineraryEntry(id: id, kind: ItineraryEntryKind.note)
            .copyWith(startAt: start, endAt: end),
        spots: const [],
        transports: const [],
        lodgings: const [],
      );

  group('点4: 訪問日の初期値（本日を使わない・優先順位）', () {
    test('現在表示日 > 前後予定日 > 現場開催日 > 旅程開始日 の順で選ぶ', () {
      expect(
        resolveInitialVisitDate(
          currentDay: DateTime(2026, 8, 3),
          adjacentDate: DateTime(2026, 8, 4),
          genbaEventDate: DateTime(2026, 8, 1),
          planStartDate: DateTime(2026, 7, 30),
        ),
        DateTime(2026, 8, 3),
      );
    });

    test('現在表示日が無ければ前後予定日', () {
      expect(
        resolveInitialVisitDate(
          adjacentDate: DateTime(2026, 8, 4),
          genbaEventDate: DateTime(2026, 8, 1),
        ),
        DateTime(2026, 8, 4),
      );
    });

    test('予定日が無ければ現場開催日（本日ではない）', () {
      expect(
        resolveInitialVisitDate(genbaEventDate: DateTime(2026, 8, 1)),
        DateTime(2026, 8, 1),
      );
    });

    test('どれも無ければ null（未設定＝候補。本日を入れない）', () {
      expect(resolveInitialVisitDate(), isNull);
    });

    test('日付のみへ正規化する（時刻を持ち込まない）', () {
      expect(
        resolveInitialVisitDate(currentDay: DateTime(2026, 8, 3, 15, 30)),
        DateTime(2026, 8, 3),
      );
    });
  });

  group('点5/点6: 新規予定の開始時刻の初期値（直前実予定の終了時刻）', () {
    test('直前の実予定に終了時刻があればそれを初期値にする', () {
      final entries = [
        spot(
          'a',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
        ),
      ];
      expect(
        resolveInitialStartFromPrevious(entries),
        DateTime.utc(2026, 8, 1, 11),
      );
    });

    test('直前がメモなら読み飛ばし、その前の実予定の終了時刻を使う（点6）', () {
      final entries = [
        spot(
          'a',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
        ),
        note('n', start: DateTime.utc(2026, 8, 1, 11, 30)),
      ];
      expect(
        resolveInitialStartFromPrevious(entries),
        DateTime.utc(2026, 8, 1, 11),
      );
    });

    test('前の予定が無ければ未設定（null）', () {
      expect(resolveInitialStartFromPrevious(const []), isNull);
    });

    test('直前の実予定が開始のみ（終了なし）なら流用せず null', () {
      final entries = [spot('a', start: DateTime.utc(2026, 8, 1, 10))];
      expect(resolveInitialStartFromPrevious(entries), isNull);
    });

    test('メモしか無ければ null（メモは対象外）', () {
      final entries = [
        note(
          'n',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
        ),
      ];
      expect(resolveInitialStartFromPrevious(entries), isNull);
    });
  });

  group('点3: 移動区間の日付を前後予定から決定（日付入力なし）', () {
    test('出発日=出発元の日、到着日=到着先の日', () {
      final r = deriveLegTimestamps(
        originDate: DateTime(2026, 8, 1),
        destinationDate: DateTime(2026, 8, 2),
        departureTime: (hour: 23, minute: 0),
        arrivalTime: (hour: 1, minute: 0),
      );
      expect(r.departure, DateTime(2026, 8, 1, 23, 0));
      expect(r.arrival, DateTime(2026, 8, 2, 1, 0));
    });

    test('同日で到着<出発なら日跨ぎとして到着を翌日にする', () {
      final r = deriveLegTimestamps(
        originDate: DateTime(2026, 8, 1),
        destinationDate: DateTime(2026, 8, 1),
        departureTime: (hour: 23, minute: 30),
        arrivalTime: (hour: 0, minute: 30),
      );
      expect(r.departure, DateTime(2026, 8, 1, 23, 30));
      expect(r.arrival, DateTime(2026, 8, 2, 0, 30)); // 翌日
    });

    test('同日で到着>出発なら同日のまま', () {
      final r = deriveLegTimestamps(
        originDate: DateTime(2026, 8, 1),
        destinationDate: DateTime(2026, 8, 1),
        departureTime: (hour: 9, minute: 0),
        arrivalTime: (hour: 10, minute: 0),
      );
      expect(r.arrival, DateTime(2026, 8, 1, 10, 0));
    });

    test('端点の日付が取れなければその日時は null（本日を入れない）', () {
      final r = deriveLegTimestamps(
        originDate: null,
        destinationDate: null,
        departureTime: (hour: 9, minute: 0),
        arrivalTime: (hour: 10, minute: 0),
      );
      expect(r.departure, isNull);
      expect(r.arrival, isNull);
    });

    test('時刻未入力なら日時も null（所要時間などは別途保存できる想定）', () {
      final r = deriveLegTimestamps(
        originDate: DateTime(2026, 8, 1),
        destinationDate: DateTime(2026, 8, 1),
        departureTime: null,
        arrivalTime: null,
      );
      expect(r.departure, isNull);
      expect(r.arrival, isNull);
    });
  });

  group('点6: メモは時間警告の対象外', () {
    test('メモと実予定が時間的に重なっても警告されない', () {
      final entries = [
        spot(
          'a',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 12),
        ),
        note(
          'n',
          start: DateTime.utc(2026, 8, 1, 10, 30),
          end: DateTime.utc(2026, 8, 1, 11),
        ),
      ];
      expect(
        itineraryTightConnections(dayEntries: entries, legs: const []),
        isEmpty,
      );
    });

    test('メモが後続でも移動時間不足の警告を出さない', () {
      final entries = [
        spot(
          'a',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
          bufferAfter: 60,
        ),
        note('n', start: DateTime.utc(2026, 8, 1, 11, 5)),
      ];
      expect(
        itineraryTightConnections(dayEntries: entries, legs: const []),
        isEmpty,
      );
    });

    test('予定A→メモ→予定B では、メモを除外して A と B を判定する（点6の例）', () {
      final entries = [
        spot(
          'A',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
          bufferAfter: 15,
        ),
        note(
          'N',
          start: DateTime.utc(2026, 8, 1, 11, 5),
          end: DateTime.utc(2026, 8, 1, 11, 20),
        ),
        spot('B', start: DateTime.utc(2026, 8, 1, 11, 10)),
      ];
      // A終了11:00 + 余裕15 = 11:15 > B開始11:10 → B を警告（メモは無視）。
      expect(
        itineraryTightConnections(dayEntries: entries, legs: const []),
        {'B'},
      );
    });

    test('実予定どうしの移動時間不足は引き続き警告する（点6: 実予定は維持）', () {
      final entries = [
        spot(
          'A',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
          bufferAfter: 15,
        ),
        spot('B', start: DateTime.utc(2026, 8, 1, 11, 10)),
      ];
      expect(
        itineraryTightConnections(dayEntries: entries, legs: const []),
        {'B'},
      );
    });

    test('実予定どうしで余裕が十分なら警告しない', () {
      final entries = [
        spot(
          'A',
          start: DateTime.utc(2026, 8, 1, 10),
          end: DateTime.utc(2026, 8, 1, 11),
        ),
        spot('B', start: DateTime.utc(2026, 8, 1, 13)),
      ];
      expect(
        itineraryTightConnections(dayEntries: entries, legs: const []),
        isEmpty,
      );
    });
  });
}
