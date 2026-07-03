import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/sync/retry_policy.dart';

void main() {
  const policy = RetryPolicy(
    base: Duration(seconds: 2),
    maxInterval: Duration(minutes: 30),
    jitterRatio: 0.2,
  );

  test('ジッター中央値(0.5)では base * 2^(n-1) の指数バックオフ', () {
    // random01=0.5 → factor=1（ジッターなし）。
    expect(policy.backoffFor(1, random01: 0.5), const Duration(seconds: 2));
    expect(policy.backoffFor(2, random01: 0.5), const Duration(seconds: 4));
    expect(policy.backoffFor(3, random01: 0.5), const Duration(seconds: 8));
    expect(policy.backoffFor(4, random01: 0.5), const Duration(seconds: 16));
  });

  test('最大間隔で頭打ちになる', () {
    // 2^20 秒は 30 分を大きく超える → maxInterval で頭打ち。
    expect(policy.backoffFor(20, random01: 0.5), const Duration(minutes: 30));
    expect(policy.backoffFor(50, random01: 0.5), const Duration(minutes: 30));
  });

  test('ジッターは ±jitterRatio の範囲に収まる', () {
    // random01=0.0 → factor=0.8 → 2000*0.8=1600ms。
    // random01=1.0 → factor=1.2 → 2000*1.2=2400ms。
    expect(
      policy.backoffFor(1, random01: 0.0),
      const Duration(milliseconds: 1600),
    );
    expect(
      policy.backoffFor(1, random01: 1.0),
      const Duration(milliseconds: 2400),
    );
  });

  test('attempts<1 は 1 として扱う（防御）', () {
    expect(policy.backoffFor(0, random01: 0.5), const Duration(seconds: 2));
    expect(policy.backoffFor(-3, random01: 0.5), const Duration(seconds: 2));
  });

  test('nextRetryAt は from + backoff', () {
    final from = DateTime.utc(2026, 7, 2, 12);
    expect(
      policy.nextRetryAt(from, 2, random01: 0.5),
      from.add(const Duration(seconds: 4)),
    );
  });

  test('同じ入力（random01固定）なら決定的', () {
    expect(
      policy.backoffFor(3, random01: 0.31),
      policy.backoffFor(3, random01: 0.31),
    );
  });
}
