import '../../genba/domain/genba.dart';

/// 1年のふりかえり（design-spec §8/§9・D-252/M5）。
///
/// 既存データ（現場アグリゲート）から導出する純粋な集計。スキーマ変更なし。
/// 「遠征距離」は経路データを保持していないため、代わりに**遠征した現場数**
/// （交通を登録した現場）と**訪れた会場数**を集計する。
class YearSummary {
  const YearSummary({
    required this.year,
    required this.genbaCount,
    required this.attendedCount,
    required this.venueCount,
    required this.expeditionCount,
    required this.photoCount,
    this.topArtist,
    this.topVenue,
  });

  final int year;

  /// その年の思い出（現場）件数。
  final int genbaCount;

  /// 参戦（ユーザーが明示した attended）件数（§12.1）。
  final int attendedCount;

  /// 訪れた会場の種類数（重複を除いた会場名の数）。
  final int venueCount;

  /// 遠征した現場数（交通を登録した現場）。
  final int expeditionCount;

  /// 記録した写真の合計枚数（0 のときは非表示にしてよい）。
  final int photoCount;

  /// 最も多く会いに行ったアーティストと回数（該当なしは null）。
  final ({String name, int count})? topArtist;

  /// 最も多く訪れた会場と回数（該当なしは null）。
  final ({String name, int count})? topVenue;
}

/// その年のアグリゲート一覧から [YearSummary] を計算する（純粋関数）。
///
/// [photoCounts] は genbaId→写真枚数のマップ（省略時は写真合計 0）。
YearSummary computeYearSummary(
  int year,
  List<GenbaAggregate> items, {
  Map<String, int> photoCounts = const {},
}) {
  final venues = <String>[];
  final artists = <String>[];
  var attended = 0;
  var expeditions = 0;
  var photos = 0;

  for (final a in items) {
    final genba = a.genba;
    if (genba.attendanceStatus == AttendanceStatus.attended) attended++;
    if (a.transports.isNotEmpty) expeditions++;
    photos += photoCounts[genba.id] ?? 0;
    final venue = genba.venue?.trim() ?? '';
    if (venue.isNotEmpty) venues.add(venue);
    final artist = genba.artistName.trim();
    if (artist.isNotEmpty) artists.add(artist);
  }

  return YearSummary(
    year: year,
    genbaCount: items.length,
    attendedCount: attended,
    venueCount: venues.toSet().length,
    expeditionCount: expeditions,
    photoCount: photos,
    topArtist: _mode(artists),
    topVenue: _mode(venues),
  );
}

/// 最頻値と回数。同数は先に出現したものを優先（安定・決定的）。
({String name, int count})? _mode(List<String> values) {
  if (values.isEmpty) return null;
  final counts = <String, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  var bestName = values.first;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      bestCount = entry.value;
      bestName = entry.key;
    }
  }
  return (name: bestName, count: bestCount);
}
