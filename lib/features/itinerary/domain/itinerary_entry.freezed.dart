// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItineraryEntry _$ItineraryEntryFromJson(Map<String, dynamic> json) {
  return _ItineraryEntry.fromJson(json);
}

/// @nodoc
mixin _$ItineraryEntry {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  ItineraryEntryKind get kind => throw _privateConstructorUsedError;
  String? get spotId => throw _privateConstructorUsedError;
  String? get transportId => throw _privateConstructorUsedError;
  String? get lodgingId => throw _privateConstructorUsedError;

  /// 表示名の上書き（主に [ItineraryEntryKind.note] で使用）。
  String? get titleOverride => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get startAt => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get endAt => throw _privateConstructorUsedError;

  /// 日付未定なら null（候補リストへ置く判定に使う, §5.2）。
  @NullableDateOnlyConverter()
  DateTime? get localDate => throw _privateConstructorUsedError;

  /// 本項目のタイムゾーン（null は計画のタイムゾーンに従うことを表す）。
  String? get timeZoneId => throw _privateConstructorUsedError;
  int get bufferBeforeMinutes => throw _privateConstructorUsedError;
  int get bufferAfterMinutes => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ItineraryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryEntryCopyWith<ItineraryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryEntryCopyWith<$Res> {
  factory $ItineraryEntryCopyWith(
          ItineraryEntry value, $Res Function(ItineraryEntry) then) =
      _$ItineraryEntryCopyWithImpl<$Res, ItineraryEntry>;
  @useResult
  $Res call(
      {String id,
      String planId,
      String ownerId,
      ItineraryEntryKind kind,
      String? spotId,
      String? transportId,
      String? lodgingId,
      String? titleOverride,
      @NullableUtcDateTimeConverter() DateTime? startAt,
      @NullableUtcDateTimeConverter() DateTime? endAt,
      @NullableDateOnlyConverter() DateTime? localDate,
      String? timeZoneId,
      int bufferBeforeMinutes,
      int bufferAfterMinutes,
      String? memo,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$ItineraryEntryCopyWithImpl<$Res, $Val extends ItineraryEntry>
    implements $ItineraryEntryCopyWith<$Res> {
  _$ItineraryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? ownerId = null,
    Object? kind = null,
    Object? spotId = freezed,
    Object? transportId = freezed,
    Object? lodgingId = freezed,
    Object? titleOverride = freezed,
    Object? startAt = freezed,
    Object? endAt = freezed,
    Object? localDate = freezed,
    Object? timeZoneId = freezed,
    Object? bufferBeforeMinutes = null,
    Object? bufferAfterMinutes = null,
    Object? memo = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ItineraryEntryKind,
      spotId: freezed == spotId
          ? _value.spotId
          : spotId // ignore: cast_nullable_to_non_nullable
              as String?,
      transportId: freezed == transportId
          ? _value.transportId
          : transportId // ignore: cast_nullable_to_non_nullable
              as String?,
      lodgingId: freezed == lodgingId
          ? _value.lodgingId
          : lodgingId // ignore: cast_nullable_to_non_nullable
              as String?,
      titleOverride: freezed == titleOverride
          ? _value.titleOverride
          : titleOverride // ignore: cast_nullable_to_non_nullable
              as String?,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endAt: freezed == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localDate: freezed == localDate
          ? _value.localDate
          : localDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeZoneId: freezed == timeZoneId
          ? _value.timeZoneId
          : timeZoneId // ignore: cast_nullable_to_non_nullable
              as String?,
      bufferBeforeMinutes: null == bufferBeforeMinutes
          ? _value.bufferBeforeMinutes
          : bufferBeforeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      bufferAfterMinutes: null == bufferAfterMinutes
          ? _value.bufferAfterMinutes
          : bufferAfterMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$ItineraryEntryImplCopyWith<$Res>
    implements $ItineraryEntryCopyWith<$Res> {
  factory _$$ItineraryEntryImplCopyWith(_$ItineraryEntryImpl value,
          $Res Function(_$ItineraryEntryImpl) then) =
      __$$ItineraryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      String ownerId,
      ItineraryEntryKind kind,
      String? spotId,
      String? transportId,
      String? lodgingId,
      String? titleOverride,
      @NullableUtcDateTimeConverter() DateTime? startAt,
      @NullableUtcDateTimeConverter() DateTime? endAt,
      @NullableDateOnlyConverter() DateTime? localDate,
      String? timeZoneId,
      int bufferBeforeMinutes,
      int bufferAfterMinutes,
      String? memo,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$ItineraryEntryImplCopyWithImpl<$Res>
    extends _$ItineraryEntryCopyWithImpl<$Res, _$ItineraryEntryImpl>
    implements _$$ItineraryEntryImplCopyWith<$Res> {
  __$$ItineraryEntryImplCopyWithImpl(
      _$ItineraryEntryImpl _value, $Res Function(_$ItineraryEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItineraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? ownerId = null,
    Object? kind = null,
    Object? spotId = freezed,
    Object? transportId = freezed,
    Object? lodgingId = freezed,
    Object? titleOverride = freezed,
    Object? startAt = freezed,
    Object? endAt = freezed,
    Object? localDate = freezed,
    Object? timeZoneId = freezed,
    Object? bufferBeforeMinutes = null,
    Object? bufferAfterMinutes = null,
    Object? memo = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ItineraryEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ItineraryEntryKind,
      spotId: freezed == spotId
          ? _value.spotId
          : spotId // ignore: cast_nullable_to_non_nullable
              as String?,
      transportId: freezed == transportId
          ? _value.transportId
          : transportId // ignore: cast_nullable_to_non_nullable
              as String?,
      lodgingId: freezed == lodgingId
          ? _value.lodgingId
          : lodgingId // ignore: cast_nullable_to_non_nullable
              as String?,
      titleOverride: freezed == titleOverride
          ? _value.titleOverride
          : titleOverride // ignore: cast_nullable_to_non_nullable
              as String?,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endAt: freezed == endAt
          ? _value.endAt
          : endAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      localDate: freezed == localDate
          ? _value.localDate
          : localDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      timeZoneId: freezed == timeZoneId
          ? _value.timeZoneId
          : timeZoneId // ignore: cast_nullable_to_non_nullable
              as String?,
      bufferBeforeMinutes: null == bufferBeforeMinutes
          ? _value.bufferBeforeMinutes
          : bufferBeforeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      bufferAfterMinutes: null == bufferAfterMinutes
          ? _value.bufferAfterMinutes
          : bufferAfterMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      memo: freezed == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$ItineraryEntryImpl implements _ItineraryEntry {
  const _$ItineraryEntryImpl(
      {required this.id,
      required this.planId,
      required this.ownerId,
      required this.kind,
      this.spotId,
      this.transportId,
      this.lodgingId,
      this.titleOverride,
      @NullableUtcDateTimeConverter() this.startAt,
      @NullableUtcDateTimeConverter() this.endAt,
      @NullableDateOnlyConverter() this.localDate,
      this.timeZoneId,
      this.bufferBeforeMinutes = 0,
      this.bufferAfterMinutes = 0,
      this.memo,
      this.sortOrder = 0,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$ItineraryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String planId;
  @override
  final String ownerId;
  @override
  final ItineraryEntryKind kind;
  @override
  final String? spotId;
  @override
  final String? transportId;
  @override
  final String? lodgingId;

  /// 表示名の上書き（主に [ItineraryEntryKind.note] で使用）。
  @override
  final String? titleOverride;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? startAt;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? endAt;

  /// 日付未定なら null（候補リストへ置く判定に使う, §5.2）。
  @override
  @NullableDateOnlyConverter()
  final DateTime? localDate;

  /// 本項目のタイムゾーン（null は計画のタイムゾーンに従うことを表す）。
  @override
  final String? timeZoneId;
  @override
  @JsonKey()
  final int bufferBeforeMinutes;
  @override
  @JsonKey()
  final int bufferAfterMinutes;
  @override
  final String? memo;
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
    return 'ItineraryEntry(id: $id, planId: $planId, ownerId: $ownerId, kind: $kind, spotId: $spotId, transportId: $transportId, lodgingId: $lodgingId, titleOverride: $titleOverride, startAt: $startAt, endAt: $endAt, localDate: $localDate, timeZoneId: $timeZoneId, bufferBeforeMinutes: $bufferBeforeMinutes, bufferAfterMinutes: $bufferAfterMinutes, memo: $memo, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.spotId, spotId) || other.spotId == spotId) &&
            (identical(other.transportId, transportId) ||
                other.transportId == transportId) &&
            (identical(other.lodgingId, lodgingId) ||
                other.lodgingId == lodgingId) &&
            (identical(other.titleOverride, titleOverride) ||
                other.titleOverride == titleOverride) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.endAt, endAt) || other.endAt == endAt) &&
            (identical(other.localDate, localDate) ||
                other.localDate == localDate) &&
            (identical(other.timeZoneId, timeZoneId) ||
                other.timeZoneId == timeZoneId) &&
            (identical(other.bufferBeforeMinutes, bufferBeforeMinutes) ||
                other.bufferBeforeMinutes == bufferBeforeMinutes) &&
            (identical(other.bufferAfterMinutes, bufferAfterMinutes) ||
                other.bufferAfterMinutes == bufferAfterMinutes) &&
            (identical(other.memo, memo) || other.memo == memo) &&
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
      planId,
      ownerId,
      kind,
      spotId,
      transportId,
      lodgingId,
      titleOverride,
      startAt,
      endAt,
      localDate,
      timeZoneId,
      bufferBeforeMinutes,
      bufferAfterMinutes,
      memo,
      sortOrder,
      createdAt,
      updatedAt);

  /// Create a copy of ItineraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryEntryImplCopyWith<_$ItineraryEntryImpl> get copyWith =>
      __$$ItineraryEntryImplCopyWithImpl<_$ItineraryEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryEntryImplToJson(
      this,
    );
  }
}

abstract class _ItineraryEntry implements ItineraryEntry {
  const factory _ItineraryEntry(
          {required final String id,
          required final String planId,
          required final String ownerId,
          required final ItineraryEntryKind kind,
          final String? spotId,
          final String? transportId,
          final String? lodgingId,
          final String? titleOverride,
          @NullableUtcDateTimeConverter() final DateTime? startAt,
          @NullableUtcDateTimeConverter() final DateTime? endAt,
          @NullableDateOnlyConverter() final DateTime? localDate,
          final String? timeZoneId,
          final int bufferBeforeMinutes,
          final int bufferAfterMinutes,
          final String? memo,
          final int sortOrder,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$ItineraryEntryImpl;

  factory _ItineraryEntry.fromJson(Map<String, dynamic> json) =
      _$ItineraryEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get planId;
  @override
  String get ownerId;
  @override
  ItineraryEntryKind get kind;
  @override
  String? get spotId;
  @override
  String? get transportId;
  @override
  String? get lodgingId;

  /// 表示名の上書き（主に [ItineraryEntryKind.note] で使用）。
  @override
  String? get titleOverride;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get startAt;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get endAt;

  /// 日付未定なら null（候補リストへ置く判定に使う, §5.2）。
  @override
  @NullableDateOnlyConverter()
  DateTime? get localDate;

  /// 本項目のタイムゾーン（null は計画のタイムゾーンに従うことを表す）。
  @override
  String? get timeZoneId;
  @override
  int get bufferBeforeMinutes;
  @override
  int get bufferAfterMinutes;
  @override
  String? get memo;
  @override
  int get sortOrder;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of ItineraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryEntryImplCopyWith<_$ItineraryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
