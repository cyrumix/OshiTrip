import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/sharing/data/shared_mutation_client.dart';

/// `apply_shared_mutation` の戻り値解析（最優先修正1）。
void main() {
  group('parseSharedMutationResult', () {
    test('status=applied は成功（Ok）', () {
      final r = parseSharedMutationResult({'status': 'applied', 'version': 2});
      expect(r.isOk, isTrue);
    });

    test('status=conflict は ConflictFailure（成功扱いにしない）', () {
      final r = parseSharedMutationResult({'status': 'conflict', 'version': 9});
      expect(r.isOk, isFalse);
      expect(r.failureOrNull, isA<ConflictFailure>());
    });

    test('未知 status / null / 非Map は失敗扱い（成功にしない）', () {
      for (final res in [
        {'status': 'weird'},
        {'version': 1}, // status 欠落
        null,
        'not-a-map',
        <String, dynamic>{},
      ]) {
        final r = parseSharedMutationResult(res);
        expect(r.isOk, isFalse, reason: 'res=$res は成功扱いにしない');
        expect(r.failureOrNull, isNot(isA<ConflictFailure>()));
      }
    });
  });
}
