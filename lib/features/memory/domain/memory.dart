// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';

part 'memory.freezed.dart';
part 'memory.g.dart';

/// 思い出の記録本体（1現場につき1件、現場と同一IDの世界で genbaId で紐づく）。
///
/// すべて任意入力。未入力はエラーではない（§8.2）。
/// 短い感想は独立フィールドにせず [impression]（感想本文）の初期入力として扱う。
@freezed
abstract class MemoryEntry with _$MemoryEntry {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoryEntry({
    required String id,
    required String genbaId,
    required String ownerId,

    /// 感想本文（終演直後は短い感想として書き始め、後から加筆する）。
    @Default('') String impression,

    /// 特によかった曲・点（終演直後）。
    @Default('') String bestMoment,

    /// MC・当日メモ（翌日）。
    @Default('') String mcNotes,

    /// 座席・見え方（翌日）。
    @Default('') String seatView,

    /// 写真整理用のタグ・表情タグ（後日）。
    @Default(<String>[]) List<String> tags,

    /// 「今回は入力しない」を選んだ項目名（通知抑制の境界データ、§8.3）。
    @Default(<String>[]) List<String> declinedFields,

    /// 思い出単位のお気に入り（§8/design-spec §8/§12.1）。一覧・詳細から変更可能。
    @Default(false) bool isFavorite,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _MemoryEntry;

  factory MemoryEntry.fromJson(Map<String, dynamic> json) =>
      _$MemoryEntryFromJson(json);
}

/// 写真アップロード状態。ローカル参照とリモート保存を型で区別する。
enum PhotoUploadStatus {
  @JsonValue('local_only')
  localOnly,
  @JsonValue('queued')
  queued,
  @JsonValue('uploaded')
  uploaded,
  @JsonValue('failed')
  failed,
}

/// 思い出写真。[localPath]（端末参照）と [storagePath]（Supabase Storage）を
/// 別フィールドで持ち、仮の単一文字列で済ませない。
@freezed
abstract class MemoryPhoto with _$MemoryPhoto {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoryPhoto({
    required String id,
    required String genbaId,
    required String ownerId,
    String? localPath,
    String? storagePath,
    @Default(PhotoUploadStatus.localOnly) PhotoUploadStatus uploadStatus,
    String? caption,
    @Default(false) bool isCover,
    @Default(0) int sortOrder,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _MemoryPhoto;

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) =>
      _$MemoryPhotoFromJson(json);
}

@freezed
abstract class SetlistItem with _$SetlistItem {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory SetlistItem({
    required String id,
    required String genbaId,
    required String ownerId,
    required int position,
    required String songTitle,
    String? note,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _SetlistItem;

  factory SetlistItem.fromJson(Map<String, dynamic> json) =>
      _$SetlistItemFromJson(json);
}

@freezed
abstract class GoodsItem with _$GoodsItem {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory GoodsItem({
    required String id,
    required String genbaId,
    required String ownerId,
    required String name,
    int? price,
    @Default(1) int quantity,
    String? memo,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _GoodsItem;

  factory GoodsItem.fromJson(Map<String, dynamic> json) =>
      _$GoodsItemFromJson(json);
}

@freezed
abstract class VisitedPlace with _$VisitedPlace {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory VisitedPlace({
    required String id,
    required String genbaId,
    required String ownerId,
    required String name,

    /// food（食べたもの） / spot（行った場所）。
    @Default('spot') String category,
    String? memo,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _VisitedPlace;

  factory VisitedPlace.fromJson(Map<String, dynamic> json) =>
      _$VisitedPlaceFromJson(json);
}

/// 思い出詳細をまとめた集約ビュー。
@freezed
abstract class MemoryBundle with _$MemoryBundle {
  const MemoryBundle._();

  const factory MemoryBundle({
    required String genbaId,
    MemoryEntry? entry,
    @Default(<MemoryPhoto>[]) List<MemoryPhoto> photos,
    @Default(<SetlistItem>[]) List<SetlistItem> setlist,
    @Default(<GoodsItem>[]) List<GoodsItem> goods,
    @Default(<VisitedPlace>[]) List<VisitedPlace> places,
  }) = _MemoryBundle;

  bool get hasAnyContent =>
      (entry != null &&
          (entry!.impression.isNotEmpty ||
              entry!.bestMoment.isNotEmpty ||
              entry!.mcNotes.isNotEmpty ||
              entry!.seatView.isNotEmpty)) ||
      photos.isNotEmpty ||
      setlist.isNotEmpty ||
      goods.isNotEmpty ||
      places.isNotEmpty;
}
