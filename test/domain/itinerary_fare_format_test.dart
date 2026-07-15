import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';

/// 金額（円）の表示整形（item 4。通貨は日本円前提、3桁区切り）。
void main() {
  test('3桁区切りで「N円」に整形する', () {
    expect(formatJpyYen(500), '500円');
    expect(formatJpyYen(1200), '1,200円');
    expect(formatJpyYen(1234567), '1,234,567円');
    expect(formatJpyYen(0), '0円');
  });
}
