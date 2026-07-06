// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';

part 'itinerary_entry.freezed.dart';
part 'itinerary_entry.g.dart';

/// タイムライン項目の種別（itinerary-plan-spec.md §5.1）。
///
/// [spot] はスポット訪問、[transport]/[lodging] は既存の交通・宿泊からの
/// 参照取り込み（複製しない, §5.3）、[note] は自由メモ／集合予定を表す。
enum ItineraryEntryKind {
  @JsonValue('spot')
  spot,
  @JsonValue('transport')
  transport,
  @JsonValue('lodging')
  lodging,
  @JsonValue('note')
  note,
}

/// 旅程タイムラインの1項目。[kind] に応じて [spotId] / [transportId] /
/// [lodgingId] のうち1つだけを保持する（[note] はいずれも null）。整合は
/// `itinerary_validation.dart` の純粋関数で検証する。
///
/// 交通・宿泊は既存データを参照するだけで複製しない。参照先が削除された
/// 場合でも本項目は自動削除されない（§5.3, `ItineraryReferenceStatus` 参照）。
@freezed
abstract class ItineraryEntry with _$ItineraryEntry {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ItineraryEntry({
    required String id,
    required String planId,
    required String ownerId,
    required ItineraryEntryKind kind,
    String? spotId,
    String? transportId,
    String? lodgingId,

    /// 表示名の上書き（主に [ItineraryEntryKind.note] で使用）。
    String? titleOverride,
    @NullableUtcDateTimeConverter() DateTime? startAt,
    @NullableUtcDateTimeConverter() DateTime? endAt,

    /// 日付未定なら null（候補リストへ置く判定に使う, §5.2）。
    @NullableDateOnlyConverter() DateTime? localDate,

    /// 本項目のタイムゾーン（null は計画のタイムゾーンに従うことを表す）。
    String? timeZoneId,
    @Default(0) int bufferBeforeMinutes,
    @Default(0) int bufferAfterMinutes,
    String? memo,
    @Default(0) int sortOrder,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _ItineraryEntry;

  factory ItineraryEntry.fromJson(Map<String, dynamic> json) =>
      _$ItineraryEntryFromJson(json);
}
