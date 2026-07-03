import 'dart:math';

/// Outbox 再送のバックオフ方針（H-02）。
///
/// 純粋関数として実装し、乱数源（ジッター）は注入する（テストで決定的に
/// 再現できるようにするため）。次回再送時刻の計算のみを担い、時刻の取得や
/// DB 更新は呼び出し側（[SyncEngine]/[OutboxStore]）が行う。
class RetryPolicy {
  const RetryPolicy({
    this.base = const Duration(seconds: 2),
    this.maxInterval = const Duration(minutes: 30),
    this.jitterRatio = 0.2,
  }) : assert(jitterRatio >= 0 && jitterRatio <= 1);

  /// 1回目失敗後の基準待機（attempt=1 の指数の底）。
  final Duration base;

  /// 上限待機。指数増加はこれで頭打ちにする。
  final Duration maxInterval;

  /// ジッターの割合（0〜1）。待機を ±jitterRatio の範囲でランダムに揺らす。
  final double jitterRatio;

  /// [attempts] 回失敗した操作の、[from] からの次回再送時刻を返す。
  ///
  /// - [attempts] は「今回の失敗を含めた累計失敗回数」（1 以上）。
  /// - 待機 = min(base * 2^(attempts-1), maxInterval) にジッターを適用。
  /// - [random01] は 0.0〜1.0 の乱数（テストで固定値を注入）。省略時は乱数生成。
  DateTime nextRetryAt(
    DateTime from,
    int attempts, {
    double? random01,
  }) {
    final delay = backoffFor(attempts, random01: random01);
    return from.add(delay);
  }

  /// [attempts] 回失敗時の待機時間（ジッター込み）。
  Duration backoffFor(int attempts, {double? random01}) {
    final n = attempts < 1 ? 1 : attempts;
    // 指数計算はミリ秒で行い、オーバーフローを避けるため上限で早期に丸める。
    final maxMs = maxInterval.inMilliseconds;
    final baseMs = base.inMilliseconds;
    // 2^(n-1) を掛ける。n が大きくてもオーバーフローしないよう上限で打ち切る。
    var expMs = baseMs;
    for (var i = 1; i < n; i++) {
      expMs *= 2;
      if (expMs >= maxMs) {
        expMs = maxMs;
        break;
      }
    }
    final cappedMs = expMs > maxMs ? maxMs : expMs;
    // ジッター: cappedMs を [1-jitterRatio, 1+jitterRatio] 倍に揺らす。
    final r = random01 ?? Random().nextDouble();
    final factor = 1 + jitterRatio * (2 * r - 1);
    final jitteredMs = (cappedMs * factor).round();
    return Duration(milliseconds: jitteredMs < 0 ? 0 : jitteredMs);
  }
}
