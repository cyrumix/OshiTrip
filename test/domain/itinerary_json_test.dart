import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot_link.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';

import '../helpers/fixtures.dart';

/// 旅程エンティティ・全enumの JSON round-trip（snake_case wire を往復して
/// 値が失われないこと）。Outbox payload・サーバー行はこの JSON を使う。
void main() {
  group('enum JSON round-trip（全値）', () {
    test('ItinerarySpotSource', () {
      for (final v in ItinerarySpotSource.values) {
        final spot = makeItinerarySpot(source: v);
        expect(ItinerarySpot.fromJson(spot.toJson()).source, v);
      }
    });
    test('ItinerarySpotCategory（15種・聖地を含む）', () {
      for (final v in ItinerarySpotCategory.values) {
        final spot = makeItinerarySpot(category: v);
        expect(ItinerarySpot.fromJson(spot.toJson()).category, v);
      }
      // 聖地は独立カテゴリで wire 値は 'sacred_place'、ラベルは「聖地」。
      final sacred =
          makeItinerarySpot(category: ItinerarySpotCategory.sacredPlace);
      expect(sacred.toJson()['category'], 'sacred_place');
      expect(
        ItinerarySpot.fromJson(sacred.toJson()).category,
        ItinerarySpotCategory.sacredPlace,
      );
      expect(ItinerarySpotCategory.sacredPlace.label, '聖地');
      // 既存の「神社・寺院」「観光地」とは別値。
      expect(
        ItinerarySpotCategory.sacredPlace,
        isNot(ItinerarySpotCategory.shrineTemple),
      );
      expect(
        ItinerarySpotCategory.sacredPlace,
        isNot(ItinerarySpotCategory.sightseeing),
      );
    });
    test('ItinerarySpotCategory.wireValue は @JsonValue と一致する（drift防止）', () {
      // 共有現場のカテゴリ選択UIは wireValue を単一の情報源にするため、
      // 実際の JSON シリアライズ結果と全カテゴリで一致していなければならない。
      for (final v in ItinerarySpotCategory.values) {
        final wire = makeItinerarySpot(category: v).toJson()['category'];
        expect(v.wireValue, wire, reason: '$v の wireValue が JSON 値と不一致');
      }
    });
    test('ItinerarySpotLinkKind（7種）', () {
      for (final v in ItinerarySpotLinkKind.values) {
        final link = makeItinerarySpotLink(kind: v);
        expect(ItinerarySpotLink.fromJson(link.toJson()).kind, v);
      }
    });
    test('ItineraryEntryKind（4種）', () {
      for (final v in ItineraryEntryKind.values) {
        // kind に応じた参照を持たせて整合させる（round-trip は kind のみ確認）。
        final entry = makeItineraryEntry(
          kind: v,
          spotId: v == ItineraryEntryKind.spot ? 's1' : null,
          transportId: v == ItineraryEntryKind.transport ? 't1' : null,
          lodgingId: v == ItineraryEntryKind.lodging ? 'l1' : null,
        );
        expect(ItineraryEntry.fromJson(entry.toJson()).kind, v);
      }
    });
    test('ItineraryLegSource', () {
      for (final v in ItineraryLegSource.values) {
        final leg = makeItineraryLeg(source: v);
        expect(ItineraryLeg.fromJson(leg.toJson()).source, v);
      }
    });
    test('ItineraryTravelMode（7種）', () {
      for (final v in ItineraryTravelMode.values) {
        final leg = makeItineraryLeg(travelMode: v);
        expect(ItineraryLeg.fromJson(leg.toJson()).travelMode, v);
      }
    });
    test('ItineraryValueOrigin（4種、spot.dataOrigin / leg.valueOrigin）', () {
      for (final v in ItineraryValueOrigin.values) {
        final spot = makeItinerarySpot().copyWith(dataOrigin: v);
        expect(ItinerarySpot.fromJson(spot.toJson()).dataOrigin, v);
        final leg = makeItineraryLeg().copyWith(valueOrigin: v);
        expect(ItineraryLeg.fromJson(leg.toJson()).valueOrigin, v);
      }
    });
  });

  group('エンティティ JSON round-trip（全フィールド）', () {
    test('ItineraryPlan', () {
      final plan = makeItineraryPlan(
        memo: '旅のメモ',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
        coverImageLocalPath: 'covers/a.jpg',
        sortOrder: 2,
      );
      expect(ItineraryPlan.fromJson(plan.toJson()), plan);
    });
    test('ItinerarySpot（Google由来フィールド含む）', () {
      final spot = makeItinerarySpot(
        source: ItinerarySpotSource.googlePlaces,
        category: ItinerarySpotCategory.shrineTemple,
        address: '東京都...',
        latitude: 35.658,
        longitude: 139.745,
        userImageLocalPath: 'spots/a.jpg',
        memo: '予約番号XYZ',
      ).copyWith(
        googlePlaceId: 'ChIJ_xxx',
        dataOrigin: ItineraryValueOrigin.facilityProvided,
        rightsBasis: '施設提供（許諾ID:123）',
        phoneNumber: '03-xxxx',
        websiteUrl: 'https://example.com',
        openingHoursText: '9:00-17:00',
        googleMapsUrl: 'https://maps.google.com/?cid=1',
        googleFetchedAt: DateTime.utc(2026, 7, 6, 12),
        googlePhotoName: 'places/x/photos/y',
        googlePhotoAttribution: '© 撮影者',
        userImageAltText: '展望台の写真',
      );
      expect(ItinerarySpot.fromJson(spot.toJson()), spot);
    });
    test('ItinerarySpotLink', () {
      final link = makeItinerarySpotLink(
        kind: ItinerarySpotLinkKind.reservation,
        url: 'https://reserve.example.com',
        label: '予約サイト',
        sortOrder: 1,
      );
      expect(ItinerarySpotLink.fromJson(link.toJson()), link);
    });
    test('ItineraryEntry（時刻・日付・余裕時間）', () {
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
      expect(ItineraryEntry.fromJson(entry.toJson()), entry);
    });
    test('ItineraryLeg（運賃・距離・経路メタ）', () {
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
        rightsBasis: 'オープンデータ（出典:市交通局）',
        representativeTimeBucket: '平日朝',
        lastVerifiedAt: DateTime.utc(2026, 7, 5, 8),
        routeSummary: 'JR＋徒歩',
        transitStepsJson: '[{"line":"山手線"}]',
        encodedPolyline: 'abc',
        googleMapsUrl: 'https://maps.google.com/dir',
        fetchedAt: DateTime.utc(2026, 7, 6, 9),
        cacheKey: 'k1',
        isStale: true,
      );
      expect(ItineraryLeg.fromJson(leg.toJson()), leg);
    });
  });
}
