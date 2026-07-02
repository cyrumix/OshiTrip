// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'performance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Performance _$PerformanceFromJson(Map<String, dynamic> json) {
  return _Performance.fromJson(json);
}

/// @nodoc
mixin _$Performance {
  String get id => throw _privateConstructorUsedError;
  String get groupName => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get venue => throw _privateConstructorUsedError;
  @DateOnlyConverter()
  DateTime get eventDate => throw _privateConstructorUsedError;
  int? get startTimeMinutes => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Performance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Performance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PerformanceCopyWith<Performance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PerformanceCopyWith<$Res> {
  factory $PerformanceCopyWith(
          Performance value, $Res Function(Performance) then) =
      _$PerformanceCopyWithImpl<$Res, Performance>;
  @useResult
  $Res call(
      {String id,
      String groupName,
      String title,
      String venue,
      @DateOnlyConverter() DateTime eventDate,
      int? startTimeMinutes,
      String? createdBy,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$PerformanceCopyWithImpl<$Res, $Val extends Performance>
    implements $PerformanceCopyWith<$Res> {
  _$PerformanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Performance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupName = null,
    Object? title = null,
    Object? venue = null,
    Object? eventDate = null,
    Object? startTimeMinutes = freezed,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      venue: null == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      startTimeMinutes: freezed == startTimeMinutes
          ? _value.startTimeMinutes
          : startTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
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
abstract class _$$PerformanceImplCopyWith<$Res>
    implements $PerformanceCopyWith<$Res> {
  factory _$$PerformanceImplCopyWith(
          _$PerformanceImpl value, $Res Function(_$PerformanceImpl) then) =
      __$$PerformanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupName,
      String title,
      String venue,
      @DateOnlyConverter() DateTime eventDate,
      int? startTimeMinutes,
      String? createdBy,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$PerformanceImplCopyWithImpl<$Res>
    extends _$PerformanceCopyWithImpl<$Res, _$PerformanceImpl>
    implements _$$PerformanceImplCopyWith<$Res> {
  __$$PerformanceImplCopyWithImpl(
      _$PerformanceImpl _value, $Res Function(_$PerformanceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Performance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupName = null,
    Object? title = null,
    Object? venue = null,
    Object? eventDate = null,
    Object? startTimeMinutes = freezed,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$PerformanceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: null == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      venue: null == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      startTimeMinutes: freezed == startTimeMinutes
          ? _value.startTimeMinutes
          : startTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
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
class _$PerformanceImpl implements _Performance {
  const _$PerformanceImpl(
      {required this.id,
      required this.groupName,
      required this.title,
      required this.venue,
      @DateOnlyConverter() required this.eventDate,
      this.startTimeMinutes,
      this.createdBy,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$PerformanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$PerformanceImplFromJson(json);

  @override
  final String id;
  @override
  final String groupName;
  @override
  final String title;
  @override
  final String venue;
  @override
  @DateOnlyConverter()
  final DateTime eventDate;
  @override
  final int? startTimeMinutes;
  @override
  final String? createdBy;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Performance(id: $id, groupName: $groupName, title: $title, venue: $venue, eventDate: $eventDate, startTimeMinutes: $startTimeMinutes, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PerformanceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.startTimeMinutes, startTimeMinutes) ||
                other.startTimeMinutes == startTimeMinutes) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupName, title, venue,
      eventDate, startTimeMinutes, createdBy, createdAt, updatedAt);

  /// Create a copy of Performance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PerformanceImplCopyWith<_$PerformanceImpl> get copyWith =>
      __$$PerformanceImplCopyWithImpl<_$PerformanceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PerformanceImplToJson(
      this,
    );
  }
}

abstract class _Performance implements Performance {
  const factory _Performance(
          {required final String id,
          required final String groupName,
          required final String title,
          required final String venue,
          @DateOnlyConverter() required final DateTime eventDate,
          final int? startTimeMinutes,
          final String? createdBy,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$PerformanceImpl;

  factory _Performance.fromJson(Map<String, dynamic> json) =
      _$PerformanceImpl.fromJson;

  @override
  String get id;
  @override
  String get groupName;
  @override
  String get title;
  @override
  String get venue;
  @override
  @DateOnlyConverter()
  DateTime get eventDate;
  @override
  int? get startTimeMinutes;
  @override
  String? get createdBy;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of Performance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PerformanceImplCopyWith<_$PerformanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
