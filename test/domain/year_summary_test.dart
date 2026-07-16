import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/application/year_summary.dart';

import '../helpers/fixtures.dart';

/// 1年のふりかえり集計（design-spec §8/§9・M5）は既存データからの純粋導出。
void main() {
  GenbaAggregate agg(
    String id, {
    required String artist,
    String? venue,
    AttendanceStatus attendance = AttendanceStatus.planned,
    bool withTransport = false,
  }) {
    return GenbaAggregate(
      genba: makeGenba(
        id: id,
        ownerId: 'u1',
        title: '$id公演',
        artistName: artist,
        eventDate: DateTime(2026, 6, 1),
        venue: venue,
        attendanceStatus: attendance,
      ),
      transports: withTransport
          ? [makeTransportRef(id: '$id-t', genbaId: id, ownerId: 'u1')]
          : const [],
    );
  }

  test('参戦数・会場数・遠征数・最頻の推し/会場を集計する', () {
    final items = [
      agg(
        'a',
        artist: 'ABC',
        venue: '東京ドーム',
        attendance: AttendanceStatus.attended,
        withTransport: true,
      ),
      agg(
        'b',
        artist: 'ABC',
        venue: '東京ドーム',
        attendance: AttendanceStatus.attended,
      ),
      agg(
        'c',
        artist: 'XYZ',
        venue: '大阪城ホール',
        attendance: AttendanceStatus.notAttended,
        withTransport: true,
      ),
    ];

    final s = computeYearSummary(2026, items, photoCounts: {'a': 5, 'c': 2});

    expect(s.year, 2026);
    expect(s.genbaCount, 3);
    expect(s.attendedCount, 2); // attended のみ
    expect(s.venueCount, 2); // 東京ドーム / 大阪城ホール
    expect(s.expeditionCount, 2); // 交通ありは a, c
    expect(s.photoCount, 7);
    expect(s.topArtist?.name, 'ABC');
    expect(s.topArtist?.count, 2);
    expect(s.topVenue?.name, '東京ドーム');
    expect(s.topVenue?.count, 2);
  });

  test('会場・アーティスト未設定や空リストでも壊れない', () {
    expect(computeYearSummary(2025, const []).genbaCount, 0);

    final s = computeYearSummary(2025, [
      agg('x', artist: 'Solo'),
    ]);
    expect(s.attendedCount, 0);
    expect(s.venueCount, 0); // venue 未設定
    expect(s.topVenue, isNull);
    expect(s.topArtist?.name, 'Solo');
    expect(s.photoCount, 0);
  });

  test('最頻値の同数は先に出現したものを優先する（決定的）', () {
    final s = computeYearSummary(2026, [
      agg('a', artist: 'First'),
      agg('b', artist: 'Second'),
    ]);
    // 1回ずつ → 先に出現した First。
    expect(s.topArtist?.name, 'First');
    expect(s.topArtist?.count, 1);
  });
}
