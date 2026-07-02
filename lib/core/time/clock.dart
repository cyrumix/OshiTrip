/// 現在時刻の取得を注入可能にする抽象。
///
/// アプリ内で `DateTime.now()` を直接呼ばず、必ず [Clock] 経由で取得する。
/// タイムゾーンは端末ローカルを明示的に使う（現場の時刻は会場現地＝端末基準で扱う）。
abstract interface class Clock {
  /// 端末ローカルタイムゾーンの現在時刻。
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// テスト用の固定時刻クロック。
class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  set current(DateTime value) => _now = value;

  @override
  DateTime now() => _now;
}
