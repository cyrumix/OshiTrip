import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/itinerary/domain/itinerary_schedule.dart';

/// 旅程Phase 4: 移動区間(leg)の再計算要否（itinerary-plan-spec §6.3）。
/// 位置・順序・日時・移動手段のいずれかが変われば stale になることを検証する。
void main() {
  bool stale({
    bool adjacent = true,
    bool persistedStale = false,
    String? stored = 'fp-1',
    String current = 'fp-1',
  }) =>
      isLegStale(
        adjacent: adjacent,
        persistedStale: persistedStale,
        storedFingerprint: stored,
        currentFingerprint: current,
      );

  test('全て一致・隣接・非stale永続なら stale ではない', () {
    expect(stale(), isFalse);
  });

  test('順序変更（隣接でなくなる）で stale', () {
    expect(stale(adjacent: false), isTrue);
  });

  test('位置・日時・手段変更（fingerprint不一致）で stale', () {
    expect(stale(current: 'fp-2'), isTrue);
  });

  test('一度も算出していない（cacheKey未設定）なら stale', () {
    expect(stale(stored: null), isTrue);
  });

  test('永続化された明示stale flagは常に尊重される', () {
    expect(
      stale(
        adjacent: true,
        persistedStale: true,
        stored: 'fp-1',
        current: 'fp-1',
      ),
      isTrue,
    );
  });
}
