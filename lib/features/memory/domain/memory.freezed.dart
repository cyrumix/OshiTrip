// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MemoryEntry _$MemoryEntryFromJson(Map<String, dynamic> json) {
  return _MemoryEntry.fromJson(json);
}

/// @nodoc
mixin _$MemoryEntry {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;

  /// 感想本文（終演直後は短い感想として書き始め、後から加筆する）。
  String get impression => throw _privateConstructorUsedError;

  /// 特によかった曲・点（終演直後）。
  String get bestMoment => throw _privateConstructorUsedError;

  /// MC・当日メモ（終演後）。
  String get mcNotes => throw _privateConstructorUsedError;

  /// 座席・見え方（終演後）。
  String get seatView => throw _privateConstructorUsedError;

  /// 写真整理用のタグ・表情タグ（後日）。
  List<String> get tags => throw _privateConstructorUsedError;

  /// 「今回は入力しない」を選んだ項目名（通知抑制の境界データ、§8.3）。
  List<String> get declinedFields => throw _privateConstructorUsedError;

  /// 思い出単位のお気に入り（§8/design-spec §8/§12.1）。一覧・詳細から変更可能。
  bool get isFavorite => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MemoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoryEntryCopyWith<MemoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryEntryCopyWith<$Res> {
  factory $MemoryEntryCopyWith(
          MemoryEntry value, $Res Function(MemoryEntry) then) =
      _$MemoryEntryCopyWithImpl<$Res, MemoryEntry>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String impression,
      String bestMoment,
      String mcNotes,
      String seatView,
      List<String> tags,
      List<String> declinedFields,
      bool isFavorite,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$MemoryEntryCopyWithImpl<$Res, $Val extends MemoryEntry>
    implements $MemoryEntryCopyWith<$Res> {
  _$MemoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? impression = null,
    Object? bestMoment = null,
    Object? mcNotes = null,
    Object? seatView = null,
    Object? tags = null,
    Object? declinedFields = null,
    Object? isFavorite = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      impression: null == impression
          ? _value.impression
          : impression // ignore: cast_nullable_to_non_nullable
              as String,
      bestMoment: null == bestMoment
          ? _value.bestMoment
          : bestMoment // ignore: cast_nullable_to_non_nullable
              as String,
      mcNotes: null == mcNotes
          ? _value.mcNotes
          : mcNotes // ignore: cast_nullable_to_non_nullable
              as String,
      seatView: null == seatView
          ? _value.seatView
          : seatView // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      declinedFields: null == declinedFields
          ? _value.declinedFields
          : declinedFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryEntryImplCopyWith<$Res>
    implements $MemoryEntryCopyWith<$Res> {
  factory _$$MemoryEntryImplCopyWith(
          _$MemoryEntryImpl value, $Res Function(_$MemoryEntryImpl) then) =
      __$$MemoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String impression,
      String bestMoment,
      String mcNotes,
      String seatView,
      List<String> tags,
      List<String> declinedFields,
      bool isFavorite,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$MemoryEntryImplCopyWithImpl<$Res>
    extends _$MemoryEntryCopyWithImpl<$Res, _$MemoryEntryImpl>
    implements _$$MemoryEntryImplCopyWith<$Res> {
  __$$MemoryEntryImplCopyWithImpl(
      _$MemoryEntryImpl _value, $Res Function(_$MemoryEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? impression = null,
    Object? bestMoment = null,
    Object? mcNotes = null,
    Object? seatView = null,
    Object? tags = null,
    Object? declinedFields = null,
    Object? isFavorite = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$MemoryEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      impression: null == impression
          ? _value.impression
          : impression // ignore: cast_nullable_to_non_nullable
              as String,
      bestMoment: null == bestMoment
          ? _value.bestMoment
          : bestMoment // ignore: cast_nullable_to_non_nullable
              as String,
      mcNotes: null == mcNotes
          ? _value.mcNotes
          : mcNotes // ignore: cast_nullable_to_non_nullable
              as String,
      seatView: null == seatView
          ? _value.seatView
          : seatView // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      declinedFields: null == declinedFields
          ? _value._declinedFields
          : declinedFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoryEntryImpl implements _MemoryEntry {
  const _$MemoryEntryImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.impression = '',
      this.bestMoment = '',
      this.mcNotes = '',
      this.seatView = '',
      final List<String> tags = const <String>[],
      final List<String> declinedFields = const <String>[],
      this.isFavorite = false,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt})
      : _tags = tags,
        _declinedFields = declinedFields;

  factory _$MemoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;

  /// 感想本文（終演直後は短い感想として書き始め、後から加筆する）。
  @override
  @JsonKey()
  final String impression;

  /// 特によかった曲・点（終演直後）。
  @override
  @JsonKey()
  final String bestMoment;

  /// MC・当日メモ（終演後）。
  @override
  @JsonKey()
  final String mcNotes;

  /// 座席・見え方（終演後）。
  @override
  @JsonKey()
  final String seatView;

  /// 写真整理用のタグ・表情タグ（後日）。
  final List<String> _tags;

  /// 写真整理用のタグ・表情タグ（後日）。
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// 「今回は入力しない」を選んだ項目名（通知抑制の境界データ、§8.3）。
  final List<String> _declinedFields;

  /// 「今回は入力しない」を選んだ項目名（通知抑制の境界データ、§8.3）。
  @override
  @JsonKey()
  List<String> get declinedFields {
    if (_declinedFields is EqualUnmodifiableListView) return _declinedFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_declinedFields);
  }

  /// 思い出単位のお気に入り（§8/design-spec §8/§12.1）。一覧・詳細から変更可能。
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MemoryEntry(id: $id, genbaId: $genbaId, ownerId: $ownerId, impression: $impression, bestMoment: $bestMoment, mcNotes: $mcNotes, seatView: $seatView, tags: $tags, declinedFields: $declinedFields, isFavorite: $isFavorite, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.impression, impression) ||
                other.impression == impression) &&
            (identical(other.bestMoment, bestMoment) ||
                other.bestMoment == bestMoment) &&
            (identical(other.mcNotes, mcNotes) || other.mcNotes == mcNotes) &&
            (identical(other.seatView, seatView) ||
                other.seatView == seatView) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._declinedFields, _declinedFields) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      genbaId,
      ownerId,
      impression,
      bestMoment,
      mcNotes,
      seatView,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_declinedFields),
      isFavorite,
      createdAt,
      updatedAt);

  /// Create a copy of MemoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryEntryImplCopyWith<_$MemoryEntryImpl> get copyWith =>
      __$$MemoryEntryImplCopyWithImpl<_$MemoryEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryEntryImplToJson(
      this,
    );
  }
}

abstract class _MemoryEntry implements MemoryEntry {
  const factory _MemoryEntry(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          final String impression,
          final String bestMoment,
          final String mcNotes,
          final String seatView,
          final List<String> tags,
          final List<String> declinedFields,
          final bool isFavorite,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$MemoryEntryImpl;

  factory _MemoryEntry.fromJson(Map<String, dynamic> json) =
      _$MemoryEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;

  /// 感想本文（終演直後は短い感想として書き始め、後から加筆する）。
  @override
  String get impression;

  /// 特によかった曲・点（終演直後）。
  @override
  String get bestMoment;

  /// MC・当日メモ（終演後）。
  @override
  String get mcNotes;

  /// 座席・見え方（終演後）。
  @override
  String get seatView;

  /// 写真整理用のタグ・表情タグ（後日）。
  @override
  List<String> get tags;

  /// 「今回は入力しない」を選んだ項目名（通知抑制の境界データ、§8.3）。
  @override
  List<String> get declinedFields;

  /// 思い出単位のお気に入り（§8/design-spec §8/§12.1）。一覧・詳細から変更可能。
  @override
  bool get isFavorite;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of MemoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoryEntryImplCopyWith<_$MemoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoryPhoto _$MemoryPhotoFromJson(Map<String, dynamic> json) {
  return _MemoryPhoto.fromJson(json);
}

/// @nodoc
mixin _$MemoryPhoto {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String? get localPath => throw _privateConstructorUsedError;
  String? get storagePath => throw _privateConstructorUsedError;
  PhotoUploadStatus get uploadStatus => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;
  bool get isCover => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// アルバム分類（§8.4）。既定は当日の写真。
  MemoryAlbumCategory get albumCategory => throw _privateConstructorUsedError;

  /// 関連項目の種別（グッズ/行った場所）。当日の写真では null。
  MemorySubjectType? get subjectType => throw _privateConstructorUsedError;

  /// 関連項目のID（[GoodsItem.id] または [VisitedPlace.id]）。
  /// 項目を削除しても写真はアルバムへ残す（既定, §8.4）。参照は緩く保つ。
  String? get subjectId => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MemoryPhoto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoryPhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoryPhotoCopyWith<MemoryPhoto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryPhotoCopyWith<$Res> {
  factory $MemoryPhotoCopyWith(
          MemoryPhoto value, $Res Function(MemoryPhoto) then) =
      _$MemoryPhotoCopyWithImpl<$Res, MemoryPhoto>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String? localPath,
      String? storagePath,
      PhotoUploadStatus uploadStatus,
      String? caption,
      bool isCover,
      int sortOrder,
      MemoryAlbumCategory albumCategory,
      MemorySubjectType? subjectType,
      String? subjectId,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$MemoryPhotoCopyWithImpl<$Res, $Val extends MemoryPhoto>
    implements $MemoryPhotoCopyWith<$Res> {
  _$MemoryPhotoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoryPhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? localPath = freezed,
    Object? storagePath = freezed,
    Object? uploadStatus = null,
    Object? caption = freezed,
    Object? isCover = null,
    Object? sortOrder = null,
    Object? albumCategory = null,
    Object? subjectType = freezed,
    Object? subjectId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      storagePath: freezed == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadStatus: null == uploadStatus
          ? _value.uploadStatus
          : uploadStatus // ignore: cast_nullable_to_non_nullable
              as PhotoUploadStatus,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      isCover: null == isCover
          ? _value.isCover
          : isCover // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      albumCategory: null == albumCategory
          ? _value.albumCategory
          : albumCategory // ignore: cast_nullable_to_non_nullable
              as MemoryAlbumCategory,
      subjectType: freezed == subjectType
          ? _value.subjectType
          : subjectType // ignore: cast_nullable_to_non_nullable
              as MemorySubjectType?,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryPhotoImplCopyWith<$Res>
    implements $MemoryPhotoCopyWith<$Res> {
  factory _$$MemoryPhotoImplCopyWith(
          _$MemoryPhotoImpl value, $Res Function(_$MemoryPhotoImpl) then) =
      __$$MemoryPhotoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String? localPath,
      String? storagePath,
      PhotoUploadStatus uploadStatus,
      String? caption,
      bool isCover,
      int sortOrder,
      MemoryAlbumCategory albumCategory,
      MemorySubjectType? subjectType,
      String? subjectId,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$MemoryPhotoImplCopyWithImpl<$Res>
    extends _$MemoryPhotoCopyWithImpl<$Res, _$MemoryPhotoImpl>
    implements _$$MemoryPhotoImplCopyWith<$Res> {
  __$$MemoryPhotoImplCopyWithImpl(
      _$MemoryPhotoImpl _value, $Res Function(_$MemoryPhotoImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoryPhoto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? localPath = freezed,
    Object? storagePath = freezed,
    Object? uploadStatus = null,
    Object? caption = freezed,
    Object? isCover = null,
    Object? sortOrder = null,
    Object? albumCategory = null,
    Object? subjectType = freezed,
    Object? subjectId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$MemoryPhotoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      storagePath: freezed == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      uploadStatus: null == uploadStatus
          ? _value.uploadStatus
          : uploadStatus // ignore: cast_nullable_to_non_nullable
              as PhotoUploadStatus,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      isCover: null == isCover
          ? _value.isCover
          : isCover // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      albumCategory: null == albumCategory
          ? _value.albumCategory
          : albumCategory // ignore: cast_nullable_to_non_nullable
              as MemoryAlbumCategory,
      subjectType: freezed == subjectType
          ? _value.subjectType
          : subjectType // ignore: cast_nullable_to_non_nullable
              as MemorySubjectType?,
      subjectId: freezed == subjectId
          ? _value.subjectId
          : subjectId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoryPhotoImpl implements _MemoryPhoto {
  const _$MemoryPhotoImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.localPath,
      this.storagePath,
      this.uploadStatus = PhotoUploadStatus.localOnly,
      this.caption,
      this.isCover = false,
      this.sortOrder = 0,
      this.albumCategory = MemoryAlbumCategory.event,
      this.subjectType,
      this.subjectId,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$MemoryPhotoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryPhotoImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final String? localPath;
  @override
  final String? storagePath;
  @override
  @JsonKey()
  final PhotoUploadStatus uploadStatus;
  @override
  final String? caption;
  @override
  @JsonKey()
  final bool isCover;
  @override
  @JsonKey()
  final int sortOrder;

  /// アルバム分類（§8.4）。既定は当日の写真。
  @override
  @JsonKey()
  final MemoryAlbumCategory albumCategory;

  /// 関連項目の種別（グッズ/行った場所）。当日の写真では null。
  @override
  final MemorySubjectType? subjectType;

  /// 関連項目のID（[GoodsItem.id] または [VisitedPlace.id]）。
  /// 項目を削除しても写真はアルバムへ残す（既定, §8.4）。参照は緩く保つ。
  @override
  final String? subjectId;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MemoryPhoto(id: $id, genbaId: $genbaId, ownerId: $ownerId, localPath: $localPath, storagePath: $storagePath, uploadStatus: $uploadStatus, caption: $caption, isCover: $isCover, sortOrder: $sortOrder, albumCategory: $albumCategory, subjectType: $subjectType, subjectId: $subjectId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryPhotoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.uploadStatus, uploadStatus) ||
                other.uploadStatus == uploadStatus) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.isCover, isCover) || other.isCover == isCover) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.albumCategory, albumCategory) ||
                other.albumCategory == albumCategory) &&
            (identical(other.subjectType, subjectType) ||
                other.subjectType == subjectType) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      genbaId,
      ownerId,
      localPath,
      storagePath,
      uploadStatus,
      caption,
      isCover,
      sortOrder,
      albumCategory,
      subjectType,
      subjectId,
      createdAt,
      updatedAt);

  /// Create a copy of MemoryPhoto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryPhotoImplCopyWith<_$MemoryPhotoImpl> get copyWith =>
      __$$MemoryPhotoImplCopyWithImpl<_$MemoryPhotoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryPhotoImplToJson(
      this,
    );
  }
}

abstract class _MemoryPhoto implements MemoryPhoto {
  const factory _MemoryPhoto(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          final String? localPath,
          final String? storagePath,
          final PhotoUploadStatus uploadStatus,
          final String? caption,
          final bool isCover,
          final int sortOrder,
          final MemoryAlbumCategory albumCategory,
          final MemorySubjectType? subjectType,
          final String? subjectId,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$MemoryPhotoImpl;

  factory _MemoryPhoto.fromJson(Map<String, dynamic> json) =
      _$MemoryPhotoImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  String? get localPath;
  @override
  String? get storagePath;
  @override
  PhotoUploadStatus get uploadStatus;
  @override
  String? get caption;
  @override
  bool get isCover;
  @override
  int get sortOrder;

  /// アルバム分類（§8.4）。既定は当日の写真。
  @override
  MemoryAlbumCategory get albumCategory;

  /// 関連項目の種別（グッズ/行った場所）。当日の写真では null。
  @override
  MemorySubjectType? get subjectType;

  /// 関連項目のID（[GoodsItem.id] または [VisitedPlace.id]）。
  /// 項目を削除しても写真はアルバムへ残す（既定, §8.4）。参照は緩く保つ。
  @override
  String? get subjectId;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of MemoryPhoto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoryPhotoImplCopyWith<_$MemoryPhotoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SetlistItem _$SetlistItemFromJson(Map<String, dynamic> json) {
  return _SetlistItem.fromJson(json);
}

/// @nodoc
mixin _$SetlistItem {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  String get songTitle => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SetlistItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SetlistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SetlistItemCopyWith<SetlistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetlistItemCopyWith<$Res> {
  factory $SetlistItemCopyWith(
          SetlistItem value, $Res Function(SetlistItem) then) =
      _$SetlistItemCopyWithImpl<$Res, SetlistItem>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      int position,
      String songTitle,
      String? note,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$SetlistItemCopyWithImpl<$Res, $Val extends SetlistItem>
    implements $SetlistItemCopyWith<$Res> {
  _$SetlistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SetlistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? position = null,
    Object? songTitle = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      songTitle: null == songTitle
          ? _value.songTitle
          : songTitle // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SetlistItemImplCopyWith<$Res>
    implements $SetlistItemCopyWith<$Res> {
  factory _$$SetlistItemImplCopyWith(
          _$SetlistItemImpl value, $Res Function(_$SetlistItemImpl) then) =
      __$$SetlistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      int position,
      String songTitle,
      String? note,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$SetlistItemImplCopyWithImpl<$Res>
    extends _$SetlistItemCopyWithImpl<$Res, _$SetlistItemImpl>
    implements _$$SetlistItemImplCopyWith<$Res> {
  __$$SetlistItemImplCopyWithImpl(
      _$SetlistItemImpl _value, $Res Function(_$SetlistItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of SetlistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? position = null,
    Object? songTitle = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$SetlistItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      songTitle: null == songTitle
          ? _value.songTitle
          : songTitle // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$SetlistItemImpl implements _SetlistItem {
  const _$SetlistItemImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.position,
      required this.songTitle,
      this.note,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$SetlistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetlistItemImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final int position;
  @override
  final String songTitle;
  @override
  final String? note;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'SetlistItem(id: $id, genbaId: $genbaId, ownerId: $ownerId, position: $position, songTitle: $songTitle, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetlistItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.songTitle, songTitle) ||
                other.songTitle == songTitle) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, genbaId, ownerId, position,
      songTitle, note, createdAt, updatedAt);

  /// Create a copy of SetlistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetlistItemImplCopyWith<_$SetlistItemImpl> get copyWith =>
      __$$SetlistItemImplCopyWithImpl<_$SetlistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetlistItemImplToJson(
      this,
    );
  }
}

abstract class _SetlistItem implements SetlistItem {
  const factory _SetlistItem(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          required final int position,
          required final String songTitle,
          final String? note,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$SetlistItemImpl;

  factory _SetlistItem.fromJson(Map<String, dynamic> json) =
      _$SetlistItemImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  int get position;
  @override
  String get songTitle;
  @override
  String? get note;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of SetlistItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetlistItemImplCopyWith<_$SetlistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GoodsItem _$GoodsItemFromJson(Map<String, dynamic> json) {
  return _GoodsItem.fromJson(json);
}

/// @nodoc
mixin _$GoodsItem {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int? get price => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GoodsItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoodsItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoodsItemCopyWith<GoodsItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoodsItemCopyWith<$Res> {
  factory $GoodsItemCopyWith(GoodsItem value, $Res Function(GoodsItem) then) =
      _$GoodsItemCopyWithImpl<$Res, GoodsItem>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String name,
      int? price,
      int quantity,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$GoodsItemCopyWithImpl<$Res, $Val extends GoodsItem>
    implements $GoodsItemCopyWith<$Res> {
  _$GoodsItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoodsItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? price = freezed,
    Object? quantity = null,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as int?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoodsItemImplCopyWith<$Res>
    implements $GoodsItemCopyWith<$Res> {
  factory _$$GoodsItemImplCopyWith(
          _$GoodsItemImpl value, $Res Function(_$GoodsItemImpl) then) =
      __$$GoodsItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String name,
      int? price,
      int quantity,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$GoodsItemImplCopyWithImpl<$Res>
    extends _$GoodsItemCopyWithImpl<$Res, _$GoodsItemImpl>
    implements _$$GoodsItemImplCopyWith<$Res> {
  __$$GoodsItemImplCopyWithImpl(
      _$GoodsItemImpl _value, $Res Function(_$GoodsItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of GoodsItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? price = freezed,
    Object? quantity = null,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$GoodsItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as int?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$GoodsItemImpl implements _GoodsItem {
  const _$GoodsItemImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.name,
      this.price,
      this.quantity = 1,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$GoodsItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoodsItemImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  final int? price;
  @override
  @JsonKey()
  final int quantity;
  @override
  final String? memo;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'GoodsItem(id: $id, genbaId: $genbaId, ownerId: $ownerId, name: $name, price: $price, quantity: $quantity, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoodsItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, genbaId, ownerId, name,
      price, quantity, memo, createdAt, updatedAt);

  /// Create a copy of GoodsItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoodsItemImplCopyWith<_$GoodsItemImpl> get copyWith =>
      __$$GoodsItemImplCopyWithImpl<_$GoodsItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoodsItemImplToJson(
      this,
    );
  }
}

abstract class _GoodsItem implements GoodsItem {
  const factory _GoodsItem(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          required final String name,
          final int? price,
          final int quantity,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$GoodsItemImpl;

  factory _GoodsItem.fromJson(Map<String, dynamic> json) =
      _$GoodsItemImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  int? get price;
  @override
  int get quantity;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of GoodsItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoodsItemImplCopyWith<_$GoodsItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisitedPlace _$VisitedPlaceFromJson(Map<String, dynamic> json) {
  return _VisitedPlace.fromJson(json);
}

/// @nodoc
mixin _$VisitedPlace {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// food（食べたもの） / spot（行った場所）。
  String get category => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this VisitedPlace to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisitedPlace
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisitedPlaceCopyWith<VisitedPlace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisitedPlaceCopyWith<$Res> {
  factory $VisitedPlaceCopyWith(
          VisitedPlace value, $Res Function(VisitedPlace) then) =
      _$VisitedPlaceCopyWithImpl<$Res, VisitedPlace>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String name,
      String category,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$VisitedPlaceCopyWithImpl<$Res, $Val extends VisitedPlace>
    implements $VisitedPlaceCopyWith<$Res> {
  _$VisitedPlaceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisitedPlace
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? category = null,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisitedPlaceImplCopyWith<$Res>
    implements $VisitedPlaceCopyWith<$Res> {
  factory _$$VisitedPlaceImplCopyWith(
          _$VisitedPlaceImpl value, $Res Function(_$VisitedPlaceImpl) then) =
      __$$VisitedPlaceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String name,
      String category,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$VisitedPlaceImplCopyWithImpl<$Res>
    extends _$VisitedPlaceCopyWithImpl<$Res, _$VisitedPlaceImpl>
    implements _$$VisitedPlaceImplCopyWith<$Res> {
  __$$VisitedPlaceImplCopyWithImpl(
      _$VisitedPlaceImpl _value, $Res Function(_$VisitedPlaceImpl) _then)
      : super(_value, _then);

  /// Create a copy of VisitedPlace
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? category = null,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$VisitedPlaceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$VisitedPlaceImpl implements _VisitedPlace {
  const _$VisitedPlaceImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.name,
      this.category = 'spot',
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$VisitedPlaceImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisitedPlaceImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final String name;

  /// food（食べたもの） / spot（行った場所）。
  @override
  @JsonKey()
  final String category;
  @override
  final String? memo;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'VisitedPlace(id: $id, genbaId: $genbaId, ownerId: $ownerId, name: $name, category: $category, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisitedPlaceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, genbaId, ownerId, name,
      category, memo, createdAt, updatedAt);

  /// Create a copy of VisitedPlace
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisitedPlaceImplCopyWith<_$VisitedPlaceImpl> get copyWith =>
      __$$VisitedPlaceImplCopyWithImpl<_$VisitedPlaceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisitedPlaceImplToJson(
      this,
    );
  }
}

abstract class _VisitedPlace implements VisitedPlace {
  const factory _VisitedPlace(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          required final String name,
          final String category,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$VisitedPlaceImpl;

  factory _VisitedPlace.fromJson(Map<String, dynamic> json) =
      _$VisitedPlaceImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  String get name;

  /// food（食べたもの） / spot（行った場所）。
  @override
  String get category;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of VisitedPlace
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisitedPlaceImplCopyWith<_$VisitedPlaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MemoryBundle {
  String get genbaId => throw _privateConstructorUsedError;
  MemoryEntry? get entry => throw _privateConstructorUsedError;
  List<MemoryPhoto> get photos => throw _privateConstructorUsedError;
  List<SetlistItem> get setlist => throw _privateConstructorUsedError;
  List<GoodsItem> get goods => throw _privateConstructorUsedError;
  List<VisitedPlace> get places => throw _privateConstructorUsedError;

  /// Create a copy of MemoryBundle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoryBundleCopyWith<MemoryBundle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryBundleCopyWith<$Res> {
  factory $MemoryBundleCopyWith(
          MemoryBundle value, $Res Function(MemoryBundle) then) =
      _$MemoryBundleCopyWithImpl<$Res, MemoryBundle>;
  @useResult
  $Res call(
      {String genbaId,
      MemoryEntry? entry,
      List<MemoryPhoto> photos,
      List<SetlistItem> setlist,
      List<GoodsItem> goods,
      List<VisitedPlace> places});

  $MemoryEntryCopyWith<$Res>? get entry;
}

/// @nodoc
class _$MemoryBundleCopyWithImpl<$Res, $Val extends MemoryBundle>
    implements $MemoryBundleCopyWith<$Res> {
  _$MemoryBundleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoryBundle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? genbaId = null,
    Object? entry = freezed,
    Object? photos = null,
    Object? setlist = null,
    Object? goods = null,
    Object? places = null,
  }) {
    return _then(_value.copyWith(
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      entry: freezed == entry
          ? _value.entry
          : entry // ignore: cast_nullable_to_non_nullable
              as MemoryEntry?,
      photos: null == photos
          ? _value.photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<MemoryPhoto>,
      setlist: null == setlist
          ? _value.setlist
          : setlist // ignore: cast_nullable_to_non_nullable
              as List<SetlistItem>,
      goods: null == goods
          ? _value.goods
          : goods // ignore: cast_nullable_to_non_nullable
              as List<GoodsItem>,
      places: null == places
          ? _value.places
          : places // ignore: cast_nullable_to_non_nullable
              as List<VisitedPlace>,
    ) as $Val);
  }

  /// Create a copy of MemoryBundle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemoryEntryCopyWith<$Res>? get entry {
    if (_value.entry == null) {
      return null;
    }

    return $MemoryEntryCopyWith<$Res>(_value.entry!, (value) {
      return _then(_value.copyWith(entry: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemoryBundleImplCopyWith<$Res>
    implements $MemoryBundleCopyWith<$Res> {
  factory _$$MemoryBundleImplCopyWith(
          _$MemoryBundleImpl value, $Res Function(_$MemoryBundleImpl) then) =
      __$$MemoryBundleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String genbaId,
      MemoryEntry? entry,
      List<MemoryPhoto> photos,
      List<SetlistItem> setlist,
      List<GoodsItem> goods,
      List<VisitedPlace> places});

  @override
  $MemoryEntryCopyWith<$Res>? get entry;
}

/// @nodoc
class __$$MemoryBundleImplCopyWithImpl<$Res>
    extends _$MemoryBundleCopyWithImpl<$Res, _$MemoryBundleImpl>
    implements _$$MemoryBundleImplCopyWith<$Res> {
  __$$MemoryBundleImplCopyWithImpl(
      _$MemoryBundleImpl _value, $Res Function(_$MemoryBundleImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoryBundle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? genbaId = null,
    Object? entry = freezed,
    Object? photos = null,
    Object? setlist = null,
    Object? goods = null,
    Object? places = null,
  }) {
    return _then(_$MemoryBundleImpl(
      genbaId: null == genbaId
          ? _value.genbaId
          : genbaId // ignore: cast_nullable_to_non_nullable
              as String,
      entry: freezed == entry
          ? _value.entry
          : entry // ignore: cast_nullable_to_non_nullable
              as MemoryEntry?,
      photos: null == photos
          ? _value._photos
          : photos // ignore: cast_nullable_to_non_nullable
              as List<MemoryPhoto>,
      setlist: null == setlist
          ? _value._setlist
          : setlist // ignore: cast_nullable_to_non_nullable
              as List<SetlistItem>,
      goods: null == goods
          ? _value._goods
          : goods // ignore: cast_nullable_to_non_nullable
              as List<GoodsItem>,
      places: null == places
          ? _value._places
          : places // ignore: cast_nullable_to_non_nullable
              as List<VisitedPlace>,
    ));
  }
}

/// @nodoc

class _$MemoryBundleImpl extends _MemoryBundle {
  const _$MemoryBundleImpl(
      {required this.genbaId,
      this.entry,
      final List<MemoryPhoto> photos = const <MemoryPhoto>[],
      final List<SetlistItem> setlist = const <SetlistItem>[],
      final List<GoodsItem> goods = const <GoodsItem>[],
      final List<VisitedPlace> places = const <VisitedPlace>[]})
      : _photos = photos,
        _setlist = setlist,
        _goods = goods,
        _places = places,
        super._();

  @override
  final String genbaId;
  @override
  final MemoryEntry? entry;
  final List<MemoryPhoto> _photos;
  @override
  @JsonKey()
  List<MemoryPhoto> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  final List<SetlistItem> _setlist;
  @override
  @JsonKey()
  List<SetlistItem> get setlist {
    if (_setlist is EqualUnmodifiableListView) return _setlist;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_setlist);
  }

  final List<GoodsItem> _goods;
  @override
  @JsonKey()
  List<GoodsItem> get goods {
    if (_goods is EqualUnmodifiableListView) return _goods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goods);
  }

  final List<VisitedPlace> _places;
  @override
  @JsonKey()
  List<VisitedPlace> get places {
    if (_places is EqualUnmodifiableListView) return _places;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_places);
  }

  @override
  String toString() {
    return 'MemoryBundle(genbaId: $genbaId, entry: $entry, photos: $photos, setlist: $setlist, goods: $goods, places: $places)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryBundleImpl &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.entry, entry) || other.entry == entry) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            const DeepCollectionEquality().equals(other._setlist, _setlist) &&
            const DeepCollectionEquality().equals(other._goods, _goods) &&
            const DeepCollectionEquality().equals(other._places, _places));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      genbaId,
      entry,
      const DeepCollectionEquality().hash(_photos),
      const DeepCollectionEquality().hash(_setlist),
      const DeepCollectionEquality().hash(_goods),
      const DeepCollectionEquality().hash(_places));

  /// Create a copy of MemoryBundle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryBundleImplCopyWith<_$MemoryBundleImpl> get copyWith =>
      __$$MemoryBundleImplCopyWithImpl<_$MemoryBundleImpl>(this, _$identity);
}

abstract class _MemoryBundle extends MemoryBundle {
  const factory _MemoryBundle(
      {required final String genbaId,
      final MemoryEntry? entry,
      final List<MemoryPhoto> photos,
      final List<SetlistItem> setlist,
      final List<GoodsItem> goods,
      final List<VisitedPlace> places}) = _$MemoryBundleImpl;
  const _MemoryBundle._() : super._();

  @override
  String get genbaId;
  @override
  MemoryEntry? get entry;
  @override
  List<MemoryPhoto> get photos;
  @override
  List<SetlistItem> get setlist;
  @override
  List<GoodsItem> get goods;
  @override
  List<VisitedPlace> get places;

  /// Create a copy of MemoryBundle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoryBundleImplCopyWith<_$MemoryBundleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
