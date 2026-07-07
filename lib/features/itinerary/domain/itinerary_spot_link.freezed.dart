// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_spot_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItinerarySpotLink _$ItinerarySpotLinkFromJson(Map<String, dynamic> json) {
  return _ItinerarySpotLink.fromJson(json);
}

/// @nodoc
mixin _$ItinerarySpotLink {
  String get id => throw _privateConstructorUsedError;
  String get spotId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  ItinerarySpotLinkKind get kind => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ItinerarySpotLink to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItinerarySpotLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItinerarySpotLinkCopyWith<ItinerarySpotLink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItinerarySpotLinkCopyWith<$Res> {
  factory $ItinerarySpotLinkCopyWith(
          ItinerarySpotLink value, $Res Function(ItinerarySpotLink) then) =
      _$ItinerarySpotLinkCopyWithImpl<$Res, ItinerarySpotLink>;
  @useResult
  $Res call(
      {String id,
      String spotId,
      String ownerId,
      ItinerarySpotLinkKind kind,
      String url,
      String? label,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$ItinerarySpotLinkCopyWithImpl<$Res, $Val extends ItinerarySpotLink>
    implements $ItinerarySpotLinkCopyWith<$Res> {
  _$ItinerarySpotLinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItinerarySpotLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? spotId = null,
    Object? ownerId = null,
    Object? kind = null,
    Object? url = null,
    Object? label = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      spotId: null == spotId
          ? _value.spotId
          : spotId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ItinerarySpotLinkKind,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ItinerarySpotLinkImplCopyWith<$Res>
    implements $ItinerarySpotLinkCopyWith<$Res> {
  factory _$$ItinerarySpotLinkImplCopyWith(_$ItinerarySpotLinkImpl value,
          $Res Function(_$ItinerarySpotLinkImpl) then) =
      __$$ItinerarySpotLinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String spotId,
      String ownerId,
      ItinerarySpotLinkKind kind,
      String url,
      String? label,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$ItinerarySpotLinkImplCopyWithImpl<$Res>
    extends _$ItinerarySpotLinkCopyWithImpl<$Res, _$ItinerarySpotLinkImpl>
    implements _$$ItinerarySpotLinkImplCopyWith<$Res> {
  __$$ItinerarySpotLinkImplCopyWithImpl(_$ItinerarySpotLinkImpl _value,
      $Res Function(_$ItinerarySpotLinkImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItinerarySpotLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? spotId = null,
    Object? ownerId = null,
    Object? kind = null,
    Object? url = null,
    Object? label = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ItinerarySpotLinkImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      spotId: null == spotId
          ? _value.spotId
          : spotId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as ItinerarySpotLinkKind,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
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
class _$ItinerarySpotLinkImpl implements _ItinerarySpotLink {
  const _$ItinerarySpotLinkImpl(
      {required this.id,
      required this.spotId,
      required this.ownerId,
      required this.kind,
      required this.url,
      this.label,
      this.sortOrder = 0,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$ItinerarySpotLinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItinerarySpotLinkImplFromJson(json);

  @override
  final String id;
  @override
  final String spotId;
  @override
  final String ownerId;
  @override
  final ItinerarySpotLinkKind kind;
  @override
  final String url;
  @override
  final String? label;
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
    return 'ItinerarySpotLink(id: $id, spotId: $spotId, ownerId: $ownerId, kind: $kind, url: $url, label: $label, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItinerarySpotLinkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.spotId, spotId) || other.spotId == spotId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, spotId, ownerId, kind, url,
      label, sortOrder, createdAt, updatedAt);

  /// Create a copy of ItinerarySpotLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItinerarySpotLinkImplCopyWith<_$ItinerarySpotLinkImpl> get copyWith =>
      __$$ItinerarySpotLinkImplCopyWithImpl<_$ItinerarySpotLinkImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItinerarySpotLinkImplToJson(
      this,
    );
  }
}

abstract class _ItinerarySpotLink implements ItinerarySpotLink {
  const factory _ItinerarySpotLink(
          {required final String id,
          required final String spotId,
          required final String ownerId,
          required final ItinerarySpotLinkKind kind,
          required final String url,
          final String? label,
          final int sortOrder,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$ItinerarySpotLinkImpl;

  factory _ItinerarySpotLink.fromJson(Map<String, dynamic> json) =
      _$ItinerarySpotLinkImpl.fromJson;

  @override
  String get id;
  @override
  String get spotId;
  @override
  String get ownerId;
  @override
  ItinerarySpotLinkKind get kind;
  @override
  String get url;
  @override
  String? get label;
  @override
  int get sortOrder;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of ItinerarySpotLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItinerarySpotLinkImplCopyWith<_$ItinerarySpotLinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
