import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_validation.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';

import '../helpers/fixtures.dart';

/// 旅程ドメインの不変条件（純粋関数）の境界値テスト（itinerary-plan-spec.md §4/§6）。
void main() {
  group('緯度・経度は両方nullか両方有効値', () {
    test('両方null は許可', () {
      expect(validateItineraryCoordinates(null, null), isNull);
    });
    test('片方だけは拒否', () {
      expect(
        validateItineraryCoordinates(35.0, null),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryCoordinates(null, 139.0),
        isA<ValidationFailure>(),
      );
    });
    test('境界値 -90/90, -180/180 は許可', () {
      expect(validateItineraryCoordinates(-90, -180), isNull);
      expect(validateItineraryCoordinates(90, 180), isNull);
    });
    test('範囲外は拒否', () {
      expect(
        validateItineraryCoordinates(90.0001, 0),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryCoordinates(0, 180.0001),
        isA<ValidationFailure>(),
      );
      expect(validateItineraryCoordinates(-90.1, 0), isA<ValidationFailure>());
      expect(validateItineraryCoordinates(0, -180.1), isA<ValidationFailure>());
    });
    test('NaN / Infinity は範囲比較をすり抜けず拒否される', () {
      expect(
        validateItineraryCoordinates(double.nan, 0),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryCoordinates(0, double.nan),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryCoordinates(double.infinity, 0),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryCoordinates(0, double.negativeInfinity),
        isA<ValidationFailure>(),
      );
    });
  });

  group('終了は開始以後（日跨ぎ可）', () {
    test('null を含む場合は常に許可', () {
      expect(validateItineraryTimeRange(null, null), isNull);
      expect(
        validateItineraryTimeRange(DateTime.utc(2026), null),
        isNull,
      );
      expect(
        validateItineraryTimeRange(null, DateTime.utc(2026)),
        isNull,
      );
    });
    test('同一時刻は許可（>=）', () {
      final t = DateTime.utc(2026, 8, 1, 20);
      expect(validateItineraryTimeRange(t, t), isNull);
    });
    test('日跨ぎ（翌日）は許可', () {
      expect(
        validateItineraryTimeRange(
          DateTime.utc(2026, 8, 1, 23),
          DateTime.utc(2026, 8, 2, 1),
        ),
        isNull,
      );
    });
    test('終了が開始より前は拒否', () {
      expect(
        validateItineraryTimeRange(
          DateTime.utc(2026, 8, 1, 20),
          DateTime.utc(2026, 8, 1, 19, 59),
        ),
        isA<ValidationFailure>(),
      );
    });
  });

  group('余裕・所要時間は0以上・24時間以内', () {
    test('0 は許可', () {
      expect(validateItineraryMinutes(0, label: 'x'), isNull);
    });
    test('上限1440は許可、1441は拒否', () {
      expect(validateItineraryMinutes(1440, label: 'x'), isNull);
      expect(validateItineraryMinutes(1441, label: 'x'), isA<Failure>());
    });
    test('負値は拒否', () {
      expect(validateItineraryMinutes(-1, label: 'x'), isA<Failure>());
    });
  });

  group('URLは許可スキームのみ', () {
    test('http/https は許可', () {
      expect(validateItineraryUrl('http://example.com'), isNull);
      expect(validateItineraryUrl('https://example.com/path?q=1'), isNull);
      expect(validateItineraryUrl('  https://example.com  '), isNull);
    });
    test('危険・非対応スキームは拒否', () {
      expect(
        validateItineraryUrl('javascript:alert(1)'),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryUrl('file:///etc/passwd'),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryUrl('ftp://example.com'),
        isA<ValidationFailure>(),
      );
      expect(validateItineraryUrl('example.com'), isA<ValidationFailure>());
      expect(validateItineraryUrl(''), isA<ValidationFailure>());
    });
    test('scheme はあっても host が無いURLは拒否（scheme偽装対策）', () {
      expect(validateItineraryUrl('https://'), isA<ValidationFailure>());
      expect(validateItineraryUrl('https:///path'), isA<ValidationFailure>());
      expect(validateItineraryUrl('http:foo'), isA<ValidationFailure>());
      expect(validateItineraryUrl('https://example.com'), isNull);
    });
  });

  group('タイムゾーンID', () {
    test('IANA形式・UTCは許可', () {
      expect(validateItineraryTimeZoneId('Asia/Tokyo'), isNull);
      expect(validateItineraryTimeZoneId('UTC'), isNull);
      expect(
        validateItineraryTimeZoneId('America/Argentina/Buenos_Aires'),
        isNull,
      );
    });
    test('空・不正な形は拒否', () {
      expect(validateItineraryTimeZoneId(''), isA<ValidationFailure>());
      expect(validateItineraryTimeZoneId('  '), isA<ValidationFailure>());
      expect(
        validateItineraryTimeZoneId('Asia Tokyo!'),
        isA<ValidationFailure>(),
      );
    });
  });

  group('運賃は金額と通貨を組で扱う', () {
    test('両方null または 両方あり は許可', () {
      expect(validateItineraryFare(null, null), isNull);
      expect(validateItineraryFare(1200, 'JPY'), isNull);
      expect(validateItineraryFare(0, 'JPY'), isNull);
    });
    test('片方だけは拒否', () {
      expect(validateItineraryFare(1200, null), isA<ValidationFailure>());
      expect(validateItineraryFare(null, 'JPY'), isA<ValidationFailure>());
    });
    test('負の金額・空通貨は拒否', () {
      expect(validateItineraryFare(-1, 'JPY'), isA<ValidationFailure>());
      expect(validateItineraryFare(100, '  '), isA<ValidationFailure>());
    });
  });

  group('entry kind に対応する参照IDだけを許可', () {
    test('spot は spotId のみ', () {
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(kind: ItineraryEntryKind.spot, spotId: 's1'),
        ),
        isNull,
      );
      // spot なのに transportId も持つ → 拒否。
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(
            kind: ItineraryEntryKind.spot,
            spotId: 's1',
            transportId: 't1',
          ),
        ),
        isA<ValidationFailure>(),
      );
      // spot なのに spotId が無い → 拒否。
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(kind: ItineraryEntryKind.spot),
        ),
        isA<ValidationFailure>(),
      );
    });
    test('transport は transportId のみ', () {
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(
            kind: ItineraryEntryKind.transport,
            transportId: 't1',
          ),
        ),
        isNull,
      );
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(kind: ItineraryEntryKind.transport),
        ),
        isA<ValidationFailure>(),
      );
    });
    test('lodging は lodgingId のみ', () {
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(
            kind: ItineraryEntryKind.lodging,
            lodgingId: 'l1',
          ),
        ),
        isNull,
      );
    });
    test('note は参照IDを持てない', () {
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(kind: ItineraryEntryKind.note),
        ),
        isNull,
      );
      expect(
        validateItineraryEntryReference(
          makeItineraryEntry(kind: ItineraryEntryKind.note, spotId: 's1'),
        ),
        isA<ValidationFailure>(),
      );
    });
  });

  group('leg の origin と destination は同一不可', () {
    test('別項目は許可', () {
      expect(
        validateItineraryLegEndpoints(
          makeItineraryLeg(originEntryId: 'e1', destinationEntryId: 'e2'),
        ),
        isNull,
      );
    });
    test('同一項目は拒否', () {
      expect(
        validateItineraryLegEndpoints(
          makeItineraryLeg(originEntryId: 'e1', destinationEntryId: 'e1'),
        ),
        isA<ValidationFailure>(),
      );
    });
  });

  group('集約バリデータ', () {
    test('validateItineraryPlan: タイトル空は拒否、正常は許可', () {
      expect(
        validateItineraryPlan(makeItineraryPlan(title: '  ')),
        isA<ValidationFailure>(),
      );
      expect(validateItineraryPlan(makeItineraryPlan()), isNull);
    });
    test('validateItinerarySpot: 名前空・座標不整合は拒否', () {
      expect(
        validateItinerarySpot(makeItinerarySpot(name: ' ')),
        isA<ValidationFailure>(),
      );
      expect(
        validateItinerarySpot(makeItinerarySpot(latitude: 10)),
        isA<ValidationFailure>(),
      );
      expect(
        validateItinerarySpot(
          makeItinerarySpot(latitude: 35.0, longitude: 139.0),
        ),
        isNull,
      );
    });
    test('validateItineraryLeg: 運賃ペア不整合は拒否', () {
      expect(
        validateItineraryLeg(
          makeItineraryLeg(fareAmountMinor: 500),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryLeg(
          makeItineraryLeg(fareAmountMinor: 500, fareCurrency: 'JPY'),
        ),
        isNull,
      );
    });
    test('validateItinerarySpot: websiteUrl / googleMapsUrl の危険スキームを拒否', () {
      expect(
        validateItinerarySpot(
          makeItinerarySpot().copyWith(websiteUrl: 'javascript:alert(1)'),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItinerarySpot(
          makeItinerarySpot().copyWith(googleMapsUrl: 'file:///etc/passwd'),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItinerarySpot(
          makeItinerarySpot().copyWith(
            websiteUrl: 'https://example.com',
            googleMapsUrl: 'https://maps.google.com/?cid=1',
          ),
        ),
        isNull,
      );
    });
    test('validateItineraryLeg: googleMapsUrl の危険スキームを拒否', () {
      expect(
        validateItineraryLeg(
          makeItineraryLeg().copyWith(googleMapsUrl: 'javascript:void(0)'),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryLeg(
          makeItineraryLeg().copyWith(googleMapsUrl: 'https://maps.google.com'),
        ),
        isNull,
      );
    });
  });

  group('出典と権利根拠', () {
    test('userProvided は rightsBasis 省略可', () {
      expect(
        validateItineraryRightsBasis(ItineraryValueOrigin.userProvided, null),
        isNull,
      );
      expect(
        validateItineraryRightsBasis(ItineraryValueOrigin.userProvided, '  '),
        isNull,
      );
    });
    test('facility/open/licensed は空の rightsBasis を拒否', () {
      for (final origin in [
        ItineraryValueOrigin.facilityProvided,
        ItineraryValueOrigin.openData,
        ItineraryValueOrigin.licensed,
      ]) {
        expect(
          validateItineraryRightsBasis(origin, null),
          isA<ValidationFailure>(),
          reason: '$origin + null',
        );
        expect(
          validateItineraryRightsBasis(origin, '   '),
          isA<ValidationFailure>(),
          reason: '$origin + blank',
        );
        expect(
          validateItineraryRightsBasis(origin, '市の許諾ID:1'),
          isNull,
          reason: '$origin + 有効',
        );
      }
    });
    test('validateItinerarySpot / validateItineraryLeg にも波及する', () {
      expect(
        validateItinerarySpot(
          makeItinerarySpot(
            dataOrigin: ItineraryValueOrigin.facilityProvided,
          ),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItinerarySpot(
          makeItinerarySpot(
            dataOrigin: ItineraryValueOrigin.facilityProvided,
            rightsBasis: '施設提供の許諾',
          ),
        ),
        isNull,
      );
      expect(
        validateItineraryLeg(
          makeItineraryLeg(valueOrigin: ItineraryValueOrigin.licensed),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryLeg(
          makeItineraryLeg(
            valueOrigin: ItineraryValueOrigin.licensed,
            rightsBasis: '契約書#42',
          ),
        ),
        isNull,
      );
    });
  });

  group('Phase 1 は Google Routes のライブ応答を永続化しない', () {
    test('source=googleRoutes は拒否、manual は許可', () {
      expect(
        validateItineraryLegPhase1Persistable(
          makeItineraryLeg(source: ItineraryLegSource.googleRoutes),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryLegPhase1Persistable(
          makeItineraryLeg(source: ItineraryLegSource.manual),
        ),
        isNull,
      );
    });
    test('Google応答予約フィールド（fetchedAt/cacheKey/encodedPolyline）も拒否', () {
      expect(
        validateItineraryLegPhase1Persistable(
          makeItineraryLeg().copyWith(fetchedAt: DateTime.utc(2026, 7, 6)),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryLegPhase1Persistable(
          makeItineraryLeg().copyWith(cacheKey: 'k1'),
        ),
        isA<ValidationFailure>(),
      );
      expect(
        validateItineraryLegPhase1Persistable(
          makeItineraryLeg().copyWith(encodedPolyline: 'abc'),
        ),
        isA<ValidationFailure>(),
      );
    });
  });
}
