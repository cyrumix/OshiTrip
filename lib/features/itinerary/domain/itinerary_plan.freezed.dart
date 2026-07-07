// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItineraryPlan _$ItineraryPlanFromJson(Map<String, dynamic> json) {
  return _ItineraryPlan.fromJson(json);
}

/// @nodoc
mixin _$ItineraryPlan {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;

  /// 旅程の日付範囲（任意）。未設定は「期間未定」を表す。
  @NullableDateOnlyConverter()
  DateTime? get startDate => throw _privateConstructorUsedError;
  @NullableDateOnlyConverter()
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// 旅程の基準タイムゾーン（IANA形式、既定は端末タイムゾーンだが domain
  /// 自体は端末設定に依存しない。§2.6）。
  String get timeZoneId => throw _privateConstructorUsedError;
  String? get coverImageLocalPath => throw _privateConstructorUsedError;
  String? get coverImageStoragePath => throw _privateConstructorUsedError;
  ImageUploadStatus get coverImageUploadStatus =>
      throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ItineraryPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryPlanCopyWith<ItineraryPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryPlanCopyWith<$Res> {
  factory $ItineraryPlanCopyWith(
          ItineraryPlan value, $Res Function(ItineraryPlan) then) =
      _$ItineraryPlanCopyWithImpl<$Res, ItineraryPlan>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String title,
      String? memo,
      @NullableDateOnlyConverter() DateTime? startDate,
      @NullableDateOnlyConverter() DateTime? endDate,
      String timeZoneId,
      String? coverImageLocalPath,
      String? coverImageStoragePath,
      ImageUploadStatus coverImageUploadStatus,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$ItineraryPlanCopyWithImpl<$Res, $Val extends ItineraryPlan>
    implements $ItineraryPlanCopyWith<$Res> {
  _$ItineraryPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? title = null,
    Object? memo = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? timeZoneId = null,
    Object? coverImageLocalPath = freezed,
    Object? coverImageStoragePath = freezed,
    Object? coverImageUploadStatus = null,
    Object? sortOrder = null,
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeZoneId: null == timeZoneId
          ? _value.timeZoneId
          : timeZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      coverImageLocalPath: freezed == coverImageLocalPath
          ? _value.coverImageLocalPath
          : coverImageLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      coverImageStoragePath: freezed == coverImageStoragePath
          ? _value.coverImageStoragePath
          : coverImageStoragePath // ignore: cast_nullable_to_non_nullable
              as String?,
      coverImageUploadStatus: null == coverImageUploadStatus
          ? _value.coverImageUploadStatus
          : coverImageUploadStatus // ignore: cast_nullable_to_non_nullable
              as ImageUploadStatus,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
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
abstract class _$$ItineraryPlanImplCopyWith<$Res>
    implements $ItineraryPlanCopyWith<$Res> {
  factory _$$ItineraryPlanImplCopyWith(
          _$ItineraryPlanImpl value, $Res Function(_$ItineraryPlanImpl) then) =
      __$$ItineraryPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String title,
      String? memo,
      @NullableDateOnlyConverter() DateTime? startDate,
      @NullableDateOnlyConverter() DateTime? endDate,
      String timeZoneId,
      String? coverImageLocalPath,
      String? coverImageStoragePath,
      ImageUploadStatus coverImageUploadStatus,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$ItineraryPlanImplCopyWithImpl<$Res>
    extends _$ItineraryPlanCopyWithImpl<$Res, _$ItineraryPlanImpl>
    implements _$$ItineraryPlanImplCopyWith<$Res> {
  __$$ItineraryPlanImplCopyWithImpl(
      _$ItineraryPlanImpl _value, $Res Function(_$ItineraryPlanImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItineraryPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? title = null,
    Object? memo = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? timeZoneId = null,
    Object? coverImageLocalPath = freezed,
    Object? coverImageStoragePath = freezed,
    Object? coverImageUploadStatus = null,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ItineraryPlanImpl(
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
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeZoneId: null == timeZoneId
          ? _value.timeZoneId
          : timeZoneId // ignore: cast_nullable_to_non_nullable
              as String,
      coverImageLocalPath: freezed == coverImageLocalPath
          ? _value.coverImageLocalPath
          : coverImageLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      coverImageStoragePath: freezed == coverImageStoragePath
          ? _value.coverImageStoragePath
          : coverImageStoragePath // ignore: cast_nullable_to_non_nullable
              as String?,
      coverImageUploadStatus: null == coverImageUploadStatus
          ? _value.coverImageUploadStatus
          : coverImageUploadStatus // ignore: cast_nullable_to_non_nullable
              as ImageUploadStatus,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
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
class _$ItineraryPlanImpl implements _ItineraryPlan {
  const _$ItineraryPlanImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.title,
      this.memo,
      @NullableDateOnlyConverter() this.startDate,
      @NullableDateOnlyConverter() this.endDate,
      required this.timeZoneId,
      this.coverImageLocalPath,
      this.coverImageStoragePath,
      this.coverImageUploadStatus = ImageUploadStatus.localOnly,
      this.sortOrder = 0,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$ItineraryPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final String title;
  @override
  final String? memo;

  /// 旅程の日付範囲（任意）。未設定は「期間未定」を表す。
  @override
  @NullableDateOnlyConverter()
  final DateTime? startDate;
  @override
  @NullableDateOnlyConverter()
  final DateTime? endDate;

  /// 旅程の基準タイムゾーン（IANA形式、既定は端末タイムゾーンだが domain
  /// 自体は端末設定に依存しない。§2.6）。
  @override
  final String timeZoneId;
  @override
  final String? coverImageLocalPath;
  @override
  final String? coverImageStoragePath;
  @override
  @JsonKey()
  final ImageUploadStatus coverImageUploadStatus;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ItineraryPlan(id: $id, genbaId: $genbaId, ownerId: $ownerId, title: $title, memo: $memo, startDate: $startDate, endDate: $endDate, timeZoneId: $timeZoneId, coverImageLocalPath: $coverImageLocalPath, coverImageStoragePath: $coverImageStoragePath, coverImageUploadStatus: $coverImageUploadStatus, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.timeZoneId, timeZoneId) ||
                other.timeZoneId == timeZoneId) &&
            (identical(other.coverImageLocalPath, coverImageLocalPath) ||
                other.coverImageLocalPath == coverImageLocalPath) &&
            (identical(other.coverImageStoragePath, coverImageStoragePath) ||
                other.coverImageStoragePath == coverImageStoragePath) &&
            (identical(other.coverImageUploadStatus, coverImageUploadStatus) ||
                other.coverImageUploadStatus == coverImageUploadStatus) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
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
      title,
      memo,
      startDate,
      endDate,
      timeZoneId,
      coverImageLocalPath,
      coverImageStoragePath,
      coverImageUploadStatus,
      sortOrder,
      createdAt,
      updatedAt);

  /// Create a copy of ItineraryPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryPlanImplCopyWith<_$ItineraryPlanImpl> get copyWith =>
      __$$ItineraryPlanImplCopyWithImpl<_$ItineraryPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryPlanImplToJson(
      this,
    );
  }
}

abstract class _ItineraryPlan implements ItineraryPlan {
  const factory _ItineraryPlan(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          required final String title,
          final String? memo,
          @NullableDateOnlyConverter() final DateTime? startDate,
          @NullableDateOnlyConverter() final DateTime? endDate,
          required final String timeZoneId,
          final String? coverImageLocalPath,
          final String? coverImageStoragePath,
          final ImageUploadStatus coverImageUploadStatus,
          final int sortOrder,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$ItineraryPlanImpl;

  factory _ItineraryPlan.fromJson(Map<String, dynamic> json) =
      _$ItineraryPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  String get title;
  @override
  String? get memo;

  /// 旅程の日付範囲（任意）。未設定は「期間未定」を表す。
  @override
  @NullableDateOnlyConverter()
  DateTime? get startDate;
  @override
  @NullableDateOnlyConverter()
  DateTime? get endDate;

  /// 旅程の基準タイムゾーン（IANA形式、既定は端末タイムゾーンだが domain
  /// 自体は端末設定に依存しない。§2.6）。
  @override
  String get timeZoneId;
  @override
  String? get coverImageLocalPath;
  @override
  String? get coverImageStoragePath;
  @override
  ImageUploadStatus get coverImageUploadStatus;
  @override
  int get sortOrder;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of ItineraryPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryPlanImplCopyWith<_$ItineraryPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
