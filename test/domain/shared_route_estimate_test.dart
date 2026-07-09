import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';
import 'package:oshi_trip/features/itinerary/domain/shared_facility.dart';
import 'package:oshi_trip/features/itinerary/domain/shared_route_estimate.dart';

/// 旅程Phase 4 残タスク: 共有概算経路(`shared_route_estimates`)の**再利用**を
/// 安全に閉じ込める純粋層。approved のみ・data_origin/rights_basis を守る・
/// Google応答を再利用元にしない、を型と防御的パースで担保する。
void main() {
  group('sharedRouteEstimateReuseError（再利用可否）', () {
    test('approved かつ rights_basis ありなら再利用可（null）', () {
      expect(
        sharedRouteEstimateReuseError(
          status: FacilityModerationStatus.approved,
          rightsBasis: 'ユーザー入力の実測値',
        ),
        isNull,
      );
    });

    test('approved 以外は再利用不可', () {
      for (final s in [
        FacilityModerationStatus.draft,
        FacilityModerationStatus.pending,
        FacilityModerationStatus.rejected,
      ]) {
        expect(
          sharedRouteEstimateReuseError(status: s, rightsBasis: '根拠あり'),
          isNotNull,
          reason: '$s は再利用不可',
        );
      }
    });

    test('approved でも rights_basis が空なら再利用不可', () {
      expect(
        sharedRouteEstimateReuseError(
          status: FacilityModerationStatus.approved,
          rightsBasis: '   ',
        ),
        isNotNull,
      );
      expect(
        sharedRouteEstimateReuseError(
          status: FacilityModerationStatus.approved,
          rightsBasis: null,
        ),
        isNotNull,
      );
    });
  });

  group('parseSharedRouteEstimate（防御的パース）', () {
    Map<String, dynamic> row({
      String moderation = 'approved',
      String dataOrigin = 'user_provided',
      String travelMode = 'transit',
      String? rightsBasis = 'ユーザー入力の実測値',
      String id = 're-1',
    }) =>
        {
          'id': id,
          'origin_facility_id': 'fac-a',
          'destination_facility_id': 'fac-b',
          'travel_mode': travelMode,
          'representative_time_bucket': '平日朝',
          'distance_meters': 3000,
          'duration_minutes': 20,
          'route_summary': 'A→B',
          'fare_amount_minor': 210,
          'fare_currency': 'JPY',
          'data_origin': dataOrigin,
          'rights_basis': rightsBasis,
          'moderation_status': moderation,
        };

    test('承認済み・権利根拠あり・4種origin・対応modeなら採用する', () {
      final e = parseSharedRouteEstimate(row())!;
      expect(e.id, 're-1');
      expect(e.travelMode, ItineraryTravelMode.transit);
      expect(e.dataOrigin, ItineraryValueOrigin.userProvided);
      expect(e.rightsBasis, 'ユーザー入力の実測値');
      expect(e.durationMinutes, 20);
      expect(e.fareAmountMinor, 210);
    });

    test('未承認（pending/draft/rejected）は採用しない（null）', () {
      for (final m in ['pending', 'draft', 'rejected']) {
        expect(parseSharedRouteEstimate(row(moderation: m)), isNull);
      }
    });

    test('rights_basis が無ければ採用しない', () {
      expect(parseSharedRouteEstimate(row(rightsBasis: null)), isNull);
      expect(parseSharedRouteEstimate(row(rightsBasis: '  ')), isNull);
    });

    test('data_origin が google/未知なら採用しない（Google応答を再利用元にしない）', () {
      expect(parseSharedRouteEstimate(row(dataOrigin: 'google')), isNull);
      expect(parseSharedRouteEstimate(row(dataOrigin: 'scraped')), isNull);
    });

    test('権利根拠のある4種の data_origin は採用できる', () {
      for (final o in [
        'user_provided',
        'facility_provided',
        'open_data',
        'licensed',
      ]) {
        expect(parseSharedRouteEstimate(row(dataOrigin: o)), isNotNull);
      }
    });

    test('Routes非対応の travel_mode は採用しない', () {
      for (final m in ['taxi', 'flight', 'other', 'bogus']) {
        expect(parseSharedRouteEstimate(row(travelMode: m)), isNull);
      }
    });

    test('id 欠損・型不正でも採用せずクラッシュしない', () {
      expect(parseSharedRouteEstimate({}), isNull);
      expect(parseSharedRouteEstimate({'id': 42}), isNull);
      expect(parseSharedRouteEstimate(row(id: '')), isNull);
    });
  });
}
