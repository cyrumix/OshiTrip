import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/place_attribution.dart';

/// 旅程Phase 3 / 帰属の構造化・安全変換（Google Place Details New attributions[]）。
/// provider は表示必須、providerUri は有効な https のみ（不正は null）。
void main() {
  group('parsePlaceAttribution（1件）', () {
    test('provider＋有効な https の providerUri を保持', () {
      final a = parsePlaceAttribution({
        'provider': 'データ提供元',
        'providerUri': 'https://example.com/info',
      });
      expect(a, isNotNull);
      expect(a!.provider, 'データ提供元');
      expect(a.providerUri.toString(), 'https://example.com/info');
    });

    test('provider の前後空白は除去', () {
      final a = parsePlaceAttribution({'provider': '  提供元  '});
      expect(a!.provider, '提供元');
      expect(a.providerUri, isNull);
    });

    test('不正スキームの providerUri は null（http/javascript/data）', () {
      for (final u in [
        'http://example.com',
        'javascript:alert(1)',
        'data:text/html,<script>',
        'ftp://example.com',
      ]) {
        final a = parsePlaceAttribution({'provider': 'p', 'providerUri': u});
        expect(a!.providerUri, isNull, reason: u);
      }
    });

    test('巨大な providerUri は null', () {
      final huge = 'https://example.com/${'a' * 2100}';
      final a = parsePlaceAttribution({'provider': 'p', 'providerUri': huge});
      expect(a!.providerUri, isNull);
    });

    test('host 無し https は null', () {
      final a =
          parsePlaceAttribution({'provider': 'p', 'providerUri': 'https://'});
      expect(a!.providerUri, isNull);
    });

    test('provider 欠落・空・巨大・非文字列は除外（null）', () {
      expect(parsePlaceAttribution({'providerUri': 'https://x.com'}), isNull);
      expect(parsePlaceAttribution({'provider': '   '}), isNull);
      expect(parsePlaceAttribution({'provider': 'a' * 201}), isNull);
      expect(parsePlaceAttribution({'provider': 123}), isNull);
    });

    test('後方互換: 文字列は provider として扱い uri は null', () {
      final a = parsePlaceAttribution('提供元だけ');
      expect(a!.provider, '提供元だけ');
      expect(a.providerUri, isNull);
    });

    test('想定外オブジェクト（数値等）は除外', () {
      expect(parsePlaceAttribution(42), isNull);
      expect(parsePlaceAttribution(null), isNull);
    });
  });

  group('parsePlaceAttributions（配列）', () {
    test('有効なものだけ順序維持で残す', () {
      final list = parsePlaceAttributions([
        {'provider': 'A', 'providerUri': 'https://a.com'},
        {'provider': '', 'providerUri': 'https://x.com'}, // 除外
        'B', // 文字列 → provider B
        {'providerUri': 'https://c.com'}, // provider 欠落 → 除外
        {'provider': 'D', 'providerUri': 'http://d.com'}, // uri は null
      ]);
      expect(list.map((a) => a.provider), ['A', 'B', 'D']);
      expect(list[0].providerUri.toString(), 'https://a.com');
      expect(list[1].providerUri, isNull);
      expect(list[2].providerUri, isNull);
    });

    test('List 以外は空', () {
      expect(parsePlaceAttributions(null), isEmpty);
      expect(parsePlaceAttributions('x'), isEmpty);
      expect(parsePlaceAttributions(const {}), isEmpty);
    });
  });
}
