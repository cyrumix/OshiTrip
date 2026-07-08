import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/itinerary/application/itinerary_timeline.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';

import '../helpers/fixtures.dart';

/// Phase 2レビュー点5/点3: 会場・アンカー・項目を時刻順に1本化する融合表示と、
/// 移動区間(leg)の配置（隣接／孤立）を検証する純粋関数テスト。
void main() {
  ItineraryTimelineEntry tl(ItineraryEntry e) => ItineraryTimelineEntry(
        entry: e,
        referenceStatus: ItineraryReferenceStatus.resolved,
      );

  final date = DateTime(2026, 8, 1);

  group('buildItineraryDayRows: 会場＋アンカー＋項目を時刻順に融合', () {
    test('会場を先頭に、時刻付きは分昇順で融合、時刻未定は末尾', () {
      final e9 = tl(
        makeItineraryEntry(
          id: 'e9',
          kind: ItineraryEntryKind.note,
          localDate: date,
          startAt: DateTime.utc(2026, 8, 1, 9),
        ),
      );
      final e11 = tl(
        makeItineraryEntry(
          id: 'e11',
          kind: ItineraryEntryKind.note,
          localDate: date,
          startAt: DateTime.utc(2026, 8, 1, 11),
        ),
      );
      final eNull = tl(
        makeItineraryEntry(
          id: 'eNull',
          kind: ItineraryEntryKind.note,
          localDate: date,
        ),
      );
      final anchor = ItineraryAnchor(
        kind: ItineraryAnchorKind.doorOpen,
        date: date,
        minuteOfDay: 10 * 60,
      );
      final day = ItineraryTimelineDay(
        date: date,
        anchors: [anchor],
        entries: [e9, e11, eNull], // compareItineraryEntriesInDay 済み想定
      );

      final rows = buildItineraryDayRows(
        day,
        venue: const ItineraryVenue(name: '大阪城ホール', address: '大阪市'),
      );

      expect(rows[0], isA<ItineraryVenueRow>());
      expect((rows[0] as ItineraryVenueRow).venue.name, '大阪城ホール');
      // 9:00 entry → 10:00 anchor → 11:00 entry → 時刻未定 entry。
      expect((rows[1] as ItineraryEntryRow).item.entry.id, 'e9');
      expect(
        (rows[2] as ItineraryAnchorRow).anchor.kind,
        ItineraryAnchorKind.doorOpen,
      );
      expect((rows[3] as ItineraryEntryRow).item.entry.id, 'e11');
      final last = rows[4] as ItineraryEntryRow;
      expect(last.item.entry.id, 'eNull');
      expect(last.timeUndetermined, isTrue);
    });

    test('会場を渡さない日は会場ヘッダが出ない', () {
      final day = ItineraryTimelineDay(
        date: date,
        anchors: const [],
        entries: [
          tl(
            makeItineraryEntry(
              id: 'x',
              kind: ItineraryEntryKind.note,
              localDate: date,
            ),
          ),
        ],
      );
      final rows = buildItineraryDayRows(day);
      expect(rows.whereType<ItineraryVenueRow>(), isEmpty);
    });

    test('同分ではアンカーが項目より前に来る', () {
      final e10 = tl(
        makeItineraryEntry(
          id: 'e10',
          kind: ItineraryEntryKind.note,
          localDate: date,
          startAt: DateTime.utc(2026, 8, 1, 10),
        ),
      );
      final anchor = ItineraryAnchor(
        kind: ItineraryAnchorKind.showStart,
        date: date,
        minuteOfDay: 10 * 60,
      );
      final rows = buildItineraryDayRows(
        ItineraryTimelineDay(date: date, anchors: [anchor], entries: [e10]),
      );
      expect(rows[0], isA<ItineraryAnchorRow>());
      expect(rows[1], isA<ItineraryEntryRow>());
    });
  });

  group('placeItineraryLegs: 隣接／孤立の判定（点3: 落とさない）', () {
    test('隣接する端点は adjacent=true・afterEntryId=出発、離れていれば孤立', () {
      // メモは移動の端点にしないため、実予定(spot)で隣接判定を検証する（点6）。
      final e0 = tl(
        makeItineraryEntry(
          id: 'e0',
          kind: ItineraryEntryKind.spot,
          spotId: 'e0',
        ),
      );
      final e1 = tl(
        makeItineraryEntry(
          id: 'e1',
          kind: ItineraryEntryKind.spot,
          spotId: 'e1',
        ),
      );
      final e2 = tl(
        makeItineraryEntry(
          id: 'e2',
          kind: ItineraryEntryKind.spot,
          spotId: 'e2',
        ),
      );

      final legAdjacent = makeItineraryLeg(
        id: 'l-adj',
        originEntryId: 'e0',
        destinationEntryId: 'e1',
      );
      final legFar = makeItineraryLeg(
        id: 'l-far',
        originEntryId: 'e0',
        destinationEntryId: 'e2',
      );
      final legBroken = makeItineraryLeg(
        id: 'l-broken',
        originEntryId: 'missing',
        destinationEntryId: 'e1',
      );

      final placements = placeItineraryLegs(
        orderedEntries: [e0, e1, e2],
        legs: [legAdjacent, legFar, legBroken],
        labelOf: (e) => e.entry.id,
      );

      final adj = placements.firstWhere((p) => p.leg.id == 'l-adj');
      expect(adj.adjacent, isTrue);
      expect(adj.afterEntryId, 'e0');
      expect(adj.originLabel, 'e0');
      expect(adj.destinationLabel, 'e1');

      final far = placements.firstWhere((p) => p.leg.id == 'l-far');
      expect(far.adjacent, isFalse);
      expect(far.afterEntryId, isNull);

      final broken = placements.firstWhere((p) => p.leg.id == 'l-broken');
      expect(broken.adjacent, isFalse);
      expect(broken.originLabel, '不明な項目'); // 端点削除でも落とさずラベル化
    });
  });

  group('参照解決: 元データ変更の反映と参照切れ', () {
    test('交通名の変更が解決結果へ即反映（複製せずID参照）', () {
      final entry = makeItineraryEntry(
        id: 'e-t',
        kind: ItineraryEntryKind.transport,
        transportId: 'tr-1',
      );
      final resolved = resolveItineraryEntry(
        entry,
        spots: const [],
        transports: [
          makeTransportRef(id: 'tr-1', genbaId: 'genba-1', ownerId: 'user-1')
              .copyWith(method: TransportMethod.airplane),
        ],
        lodgings: const [],
      );
      expect(resolved.transport?.method, TransportMethod.airplane);
      expect(resolved.isReferenceMissing, isFalse);
    });

    test('参照先が消えた交通は missing 状態になる', () {
      final entry = makeItineraryEntry(
        id: 'e-t',
        kind: ItineraryEntryKind.transport,
        transportId: 'gone',
      );
      final resolved = resolveItineraryEntry(
        entry,
        spots: const [],
        transports: const [],
        lodgings: const [],
      );
      expect(resolved.transport, isNull);
      expect(resolved.isReferenceMissing, isTrue);
    });
  });
}
