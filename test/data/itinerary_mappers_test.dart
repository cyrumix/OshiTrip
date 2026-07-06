import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_mappers.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot_link.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// 旅程エンティティの Drift 行 round-trip（toCompanion → insert → fromRow）。
/// 全enum値と全フィールドが DB を往復して失われないことを確認する。
void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
  });

  Future<ItineraryPlan> roundTripPlan(ItineraryPlan p) async {
    await db.into(db.itineraryPlans).insertOnConflictUpdate(planToCompanion(p));
    final row = await (db.select(db.itineraryPlans)
          ..where((t) => t.id.equals(p.id)))
        .getSingle();
    return planFromRow(row);
  }

  Future<ItinerarySpot> roundTripSpot(ItinerarySpot s) async {
    await db.into(db.itinerarySpots).insertOnConflictUpdate(spotToCompanion(s));
    final row = await (db.select(db.itinerarySpots)
          ..where((t) => t.id.equals(s.id)))
        .getSingle();
    return spotFromRow(row);
  }

  Future<ItinerarySpotLink> roundTripLink(ItinerarySpotLink l) async {
    await db
        .into(db.itinerarySpotLinks)
        .insertOnConflictUpdate(spotLinkToCompanion(l));
    final row = await (db.select(db.itinerarySpotLinks)
          ..where((t) => t.id.equals(l.id)))
        .getSingle();
    return spotLinkFromRow(row);
  }

  Future<ItineraryEntry> roundTripEntry(ItineraryEntry e) async {
    await db
        .into(db.itineraryEntries)
        .insertOnConflictUpdate(entryToCompanion(e));
    final row = await (db.select(db.itineraryEntries)
          ..where((t) => t.id.equals(e.id)))
        .getSingle();
    return entryFromRow(row);
  }

  Future<ItineraryLeg> roundTripLeg(ItineraryLeg l) async {
    await db.into(db.itineraryLegs).insertOnConflictUpdate(legToCompanion(l));
    final row = await (db.select(db.itineraryLegs)
          ..where((t) => t.id.equals(l.id)))
        .getSingle();
    return legFromRow(row);
  }

  group('enum DB round-trip（全値）', () {
    test('ItinerarySpotSource / Category', () async {
      for (final v in ItinerarySpotSource.values) {
        final out = await roundTripSpot(makeItinerarySpot(source: v));
        expect(out.source, v);
      }
      for (final v in ItinerarySpotCategory.values) {
        final out = await roundTripSpot(makeItinerarySpot(category: v));
        expect(out.category, v);
      }
    });
    test('ItinerarySpotLinkKind', () async {
      for (final v in ItinerarySpotLinkKind.values) {
        final out = await roundTripLink(makeItinerarySpotLink(kind: v));
        expect(out.kind, v);
      }
    });
    test('ItineraryEntryKind', () async {
      for (final v in ItineraryEntryKind.values) {
        final out = await roundTripEntry(
          makeItineraryEntry(
            kind: v,
            spotId: v == ItineraryEntryKind.spot ? 's1' : null,
            transportId: v == ItineraryEntryKind.transport ? 't1' : null,
            lodgingId: v == ItineraryEntryKind.lodging ? 'l1' : null,
          ),
        );
        expect(out.kind, v);
      }
    });
    test('ItineraryLegSource / TravelMode', () async {
      for (final v in ItineraryLegSource.values) {
        final out = await roundTripLeg(makeItineraryLeg(source: v));
        expect(out.source, v);
      }
      for (final v in ItineraryTravelMode.values) {
        final out = await roundTripLeg(makeItineraryLeg(travelMode: v));
        expect(out.travelMode, v);
      }
    });
    test('ItineraryValueOrigin（spot.dataOrigin / leg.valueOrigin）', () async {
      for (final v in ItineraryValueOrigin.values) {
        final spot =
            await roundTripSpot(makeItinerarySpot().copyWith(dataOrigin: v));
        expect(spot.dataOrigin, v);
        final leg =
            await roundTripLeg(makeItineraryLeg().copyWith(valueOrigin: v));
        expect(leg.valueOrigin, v);
      }
    });
  });

  group('エンティティ DB round-trip（全フィールド）', () {
    test('ItineraryPlan', () async {
      final plan = makeItineraryPlan(
        memo: '旅のメモ',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
        coverImageLocalPath: 'covers/a.jpg',
        sortOrder: 2,
      );
      expect(await roundTripPlan(plan), plan);
    });
    test('ItinerarySpot（座標・Google由来・ユーザー画像）', () async {
      final spot = makeItinerarySpot(
        source: ItinerarySpotSource.googlePlaces,
        category: ItinerarySpotCategory.photoSpot,
        address: '東京都...',
        latitude: 35.658,
        longitude: 139.745,
        userImageLocalPath: 'spots/a.jpg',
        memo: 'メモ',
      ).copyWith(
        googlePlaceId: 'ChIJ',
        dataOrigin: ItineraryValueOrigin.licensed,
        rightsBasis: '契約データ',
        googleMapsUrl: 'https://maps.google.com',
        googleFetchedAt: DateTime.utc(2026, 7, 6, 12),
        userImageAltText: '写真',
      );
      expect(await roundTripSpot(spot), spot);
    });
    test('ItinerarySpotLink', () async {
      final link = makeItinerarySpotLink(
        kind: ItinerarySpotLinkKind.reservation,
        label: '予約',
        sortOrder: 1,
      );
      expect(await roundTripLink(link), link);
    });
    test('ItineraryEntry', () async {
      final entry = makeItineraryEntry(
        kind: ItineraryEntryKind.spot,
        spotId: 's1',
        titleOverride: '集合',
        startAt: DateTime.utc(2026, 8, 1, 10),
        endAt: DateTime.utc(2026, 8, 1, 11),
        localDate: DateTime(2026, 8, 1),
        timeZoneId: 'Asia/Tokyo',
        bufferBeforeMinutes: 30,
        bufferAfterMinutes: 15,
        memo: 'メモ',
        sortOrder: 3,
      );
      expect(await roundTripEntry(entry), entry);
    });
    test('ItineraryLeg', () async {
      final leg = makeItineraryLeg(
        source: ItineraryLegSource.googleRoutes,
        travelMode: ItineraryTravelMode.transit,
        departureAt: DateTime.utc(2026, 8, 1, 12),
        arrivalAt: DateTime.utc(2026, 8, 1, 13),
        durationMinutes: 60,
        distanceMeters: 12000,
        fareAmountMinor: 320,
        fareCurrency: 'JPY',
      ).copyWith(
        valueOrigin: ItineraryValueOrigin.openData,
        rightsBasis: '市交通局オープンデータ',
        representativeTimeBucket: '休日昼',
        lastVerifiedAt: DateTime.utc(2026, 7, 5, 8),
        routeSummary: 'JR＋徒歩',
        isStale: true,
      );
      expect(await roundTripLeg(leg), leg);
    });
  });

  test('カバー画像 preserveLocalImage: pull は端末内参照を上書きしない', () async {
    // ローカルにカバー画像参照ありで保存。
    await roundTripPlan(makeItineraryPlan(coverImageLocalPath: 'covers/a.jpg'));
    // サーバー由来（cover_image_local_path 無し）を preserveLocalImage で適用。
    final serverPlan = makeItineraryPlan(title: 'サーバー更新');
    await db.into(db.itineraryPlans).insertOnConflictUpdate(
          planToCompanion(serverPlan, preserveLocalImage: true),
        );
    final row = await (db.select(db.itineraryPlans)
          ..where((t) => t.id.equals(serverPlan.id)))
        .getSingle();
    expect(row.title, 'サーバー更新'); // 他フィールドは更新される
    expect(row.coverImageLocalPath, 'covers/a.jpg'); // 端末内参照は保持
  });

  test('ユーザー画像 preserveLocalImage: pull は端末内参照を上書きしない', () async {
    await roundTripSpot(makeItinerarySpot(userImageLocalPath: 'spots/a.jpg'));
    final serverSpot = makeItinerarySpot(name: 'サーバー更新');
    await db.into(db.itinerarySpots).insertOnConflictUpdate(
          spotToCompanion(serverSpot, preserveLocalImage: true),
        );
    final row = await (db.select(db.itinerarySpots)
          ..where((t) => t.id.equals(serverSpot.id)))
        .getSingle();
    expect(row.name, 'サーバー更新');
    expect(row.userImageLocalPath, 'spots/a.jpg');
  });
}
