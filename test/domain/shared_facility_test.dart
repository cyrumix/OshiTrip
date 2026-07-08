import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';
import 'package:oshi_trip/features/itinerary/domain/shared_facility.dart';

/// 旅程Phase 3 / 共有施設基盤（itinerary-plan-spec §4.3・ADR-0010 §7・0022）:
/// data_origin は4種のみ（型で Google 由来を排除）、承認には rights_basis 必須。
void main() {
  group('FacilityModerationStatus', () {
    test('コード⇄enum とラベル的性質', () {
      expect(FacilityModerationStatus.draft.code, 'draft');
      expect(FacilityModerationStatus.approved.code, 'approved');
      expect(
        facilityModerationStatusFromCode('pending'),
        FacilityModerationStatus.pending,
      );
      // 不明値は draft へフォールバック。
      expect(
        facilityModerationStatusFromCode(null),
        FacilityModerationStatus.draft,
      );
      expect(
        facilityModerationStatusFromCode('???'),
        FacilityModerationStatus.draft,
      );
      expect(FacilityModerationStatus.approved.isShared, isTrue);
      expect(FacilityModerationStatus.pending.isShared, isFalse);
    });
  });

  group('sharedFacilityInvariantError（0022 と一致）', () {
    test('data_origin は権利根拠を説明できる4種のみ（型で Google 由来を排除）', () {
      // enum の全値が「共有候補になれる出典」。Google を表す値は存在しない。
      expect(ItineraryValueOrigin.values, hasLength(4));
      for (final origin in ItineraryValueOrigin.values) {
        expect(
          sharedFacilityInvariantError(
            dataOrigin: origin,
            rightsBasis: '根拠あり',
            status: FacilityModerationStatus.draft,
          ),
          isNull,
        );
      }
    });

    test('下書き/pending は rights_basis 未設定でも可', () {
      for (final s in [
        FacilityModerationStatus.draft,
        FacilityModerationStatus.pending,
      ]) {
        expect(
          sharedFacilityInvariantError(
            dataOrigin: ItineraryValueOrigin.userProvided,
            rightsBasis: null,
            status: s,
          ),
          isNull,
        );
      }
    });

    test('承認（共有）には rights_basis が必須', () {
      expect(
        sharedFacilityInvariantError(
          dataOrigin: ItineraryValueOrigin.userProvided,
          rightsBasis: null,
          status: FacilityModerationStatus.approved,
        ),
        isNotNull,
      );
      expect(
        sharedFacilityInvariantError(
          dataOrigin: ItineraryValueOrigin.facilityProvided,
          rightsBasis: '   ',
          status: FacilityModerationStatus.approved,
        ),
        isNotNull,
      );
      // rights_basis があれば承認可。
      expect(
        sharedFacilityInvariantError(
          dataOrigin: ItineraryValueOrigin.openData,
          rightsBasis: 'オープンデータ○○より',
          status: FacilityModerationStatus.approved,
        ),
        isNull,
      );
    });
  });
}
