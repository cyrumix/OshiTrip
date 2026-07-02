import 'package:json_annotation/json_annotation.dart';

/// 日付のみ（時刻情報なし）を扱うユーティリティ。
///
/// 現場の「公演日」は会場現地の暦日として扱い、タイムゾーン変換を行わない。
/// JSON / DB 上は `yyyy-MM-dd` 文字列で表現する。
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime startOfNextDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day + 1);

String formatDateOnly(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

DateTime parseDateOnly(String value) {
  final parsed = DateTime.parse(value);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// 日付のみを `yyyy-MM-dd` で直列化する JSON コンバータ。
class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const DateOnlyConverter();

  @override
  DateTime fromJson(String json) => parseDateOnly(json);

  @override
  String toJson(DateTime object) => formatDateOnly(object);
}

class NullableDateOnlyConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateOnlyConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null || json.isEmpty ? null : parseDateOnly(json);

  @override
  String? toJson(DateTime? object) =>
      object == null ? null : formatDateOnly(object);
}

/// タイムスタンプ（UTC ISO8601）用コンバータ。
class UtcDateTimeConverter implements JsonConverter<DateTime, String> {
  const UtcDateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toUtc();

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

class NullableUtcDateTimeConverter
    implements JsonConverter<DateTime?, String?> {
  const NullableUtcDateTimeConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null || json.isEmpty ? null : DateTime.parse(json).toUtc();

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}
