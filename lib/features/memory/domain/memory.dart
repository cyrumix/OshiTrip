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

    /// MC・当日メモ（終演後）。
    @Default('') String mcNotes,

    /// 座席・見え方（終演後）。
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

/// 思い出アルバムの分類（§8.4）。写真の保存元は [MemoryPhoto] に一本化し、
/// 画面ごとに複製しない。分類は写真がどの入力から追加されたかを表す。
enum MemoryAlbumCategory {
  /// 当日の写真（思い出記録画面・アルバムから直接追加した通常写真）。
  @JsonValue('event')
  event,

  /// グッズ・戦利品から追加した写真。
  @JsonValue('goods')
  goods,

  /// 行った場所から追加した写真。
  @JsonValue('visited_place')
  visitedPlace,

  /// 食べたものから追加した写真。
  @JsonValue('food')
  food,
}

extension MemoryAlbumCategoryLabel on MemoryAlbumCategory {
  String get label => switch (this) {
        MemoryAlbumCategory.event => '当日の写真',
        MemoryAlbumCategory.goods => 'グッズ・戦利品',
        MemoryAlbumCategory.visitedPlace => '行った場所',
        MemoryAlbumCategory.food => '食べたもの',
      };
}

/// 写真の関連項目の種別（[MemoryPhoto.subjectId] が指す先）。
/// 食べたもの・行った場所はどちらも [visitedPlace]（[VisitedPlace] を指す。
/// アルバム分類は [MemoryAlbumCategory] で区別する）。
enum MemorySubjectType {
  @JsonValue('goods')
  goods,
  @JsonValue('visited_place')
  visitedPlace,
}

/// [MemoryPhoto] の分類と関連項目の**形状不変条件**（§8.4）。DB に依存しない
/// フィールドの組み合わせのみを検証する純粋関数。実在・owner/genba 一致・
/// 対象 category（spot/food）の照合は Repository と Supabase トリガで担保する。
///
/// 許可する形状:
/// - event: subjectType==null かつ subjectId==null
/// - goods: (subjectType==goods かつ subjectId 非空) または 両方 null（関連解除済み）
/// - visitedPlace/food: (subjectType==visitedPlace かつ subjectId 非空) または 両方 null
///
/// 「両方 null」は、関連項目（グッズ/場所）の削除時に写真をアルバムへ残しつつ
/// 関連を解除した状態（albumCategory は元分類を維持）を表す。
///
/// 問題があれば理由文字列、無ければ null を返す。
String? memoryPhotoShapeError(MemoryPhoto p) {
  final hasType = p.subjectType != null;
  final hasId = p.subjectId != null && p.subjectId!.isNotEmpty;
  switch (p.albumCategory) {
    case MemoryAlbumCategory.event:
      if (hasType || hasId) {
        return '当日の写真に関連項目は設定できません';
      }
      return null;
    case MemoryAlbumCategory.goods:
      if (!hasType && !hasId) return null; // 関連解除済み（アルバムに残す）
      if (p.subjectType != MemorySubjectType.goods) {
        return 'グッズ写真の関連種別が不正です';
      }
      if (!hasId) return 'グッズ写真には関連項目IDが必要です';
      return null;
    case MemoryAlbumCategory.visitedPlace:
    case MemoryAlbumCategory.food:
      if (!hasType && !hasId) return null; // 関連解除済み（アルバムに残す）
      if (p.subjectType != MemorySubjectType.visitedPlace) {
        return '場所・食べもの写真の関連種別が不正です';
      }
      if (!hasId) return '場所・食べもの写真には関連項目IDが必要です';
      return null;
  }
}

/// [memoryPhotoShapeError] が指す、写真が関連項目を「参照している」状態か。
/// （両方設定済み＝実在・category 照合が必要な状態）。
bool memoryPhotoLinksSubject(MemoryPhoto p) =>
    p.subjectType != null && p.subjectId != null && p.subjectId!.isNotEmpty;

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

    /// アルバム分類（§8.4）。既定は当日の写真。
    @Default(MemoryAlbumCategory.event) MemoryAlbumCategory albumCategory,

    /// 関連項目の種別（グッズ/行った場所）。当日の写真では null。
    MemorySubjectType? subjectType,

    /// 関連項目のID（[GoodsItem.id] または [VisitedPlace.id]）。
    /// 項目を削除しても写真はアルバムへ残す（既定, §8.4）。参照は緩く保つ。
    String? subjectId,
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

  /// sortOrder→createdAt→id で安定ソートした全写真。
  List<MemoryPhoto> get sortedPhotos {
    final list = [...photos];
    list.sort((a, b) {
      final s = a.sortOrder.compareTo(b.sortOrder);
      if (s != 0) return s;
      final c = a.createdAt.compareTo(b.createdAt);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  /// アルバム分類でフィルタした写真（null なら全件, §8.4）。
  List<MemoryPhoto> photosInAlbum(MemoryAlbumCategory? category) =>
      category == null
          ? sortedPhotos
          : sortedPhotos.where((p) => p.albumCategory == category).toList();

  /// 特定の関連項目（グッズ/行った場所）に紐づく写真。
  List<MemoryPhoto> photosForSubject(String subjectId) =>
      sortedPhotos.where((p) => p.subjectId == subjectId).toList();

  /// アルバム表紙（isCover 優先, なければ先頭）。
  MemoryPhoto? get coverPhoto {
    final sorted = sortedPhotos;
    for (final p in sorted) {
      if (p.isCover) return p;
    }
    return sorted.isEmpty ? null : sorted.first;
  }
}
