// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'oshi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OshiGroup _$OshiGroupFromJson(Map<String, dynamic> json) {
  return _OshiGroup.fromJson(json);
}

/// @nodoc
mixin _$OshiGroup {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get kind => throw _privateConstructorUsedError;

  /// 推しカラー（#RRGGBB）。アクセントのみに使用しコントラストを壊さない。
  String? get color => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OshiGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OshiGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OshiGroupCopyWith<OshiGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OshiGroupCopyWith<$Res> {
  factory $OshiGroupCopyWith(OshiGroup value, $Res Function(OshiGroup) then) =
      _$OshiGroupCopyWithImpl<$Res, OshiGroup>;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      String? kind,
      String? color,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$OshiGroupCopyWithImpl<$Res, $Val extends OshiGroup>
    implements $OshiGroupCopyWith<$Res> {
  _$OshiGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OshiGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? kind = freezed,
    Object? color = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: freezed == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$OshiGroupImplCopyWith<$Res>
    implements $OshiGroupCopyWith<$Res> {
  factory _$$OshiGroupImplCopyWith(
          _$OshiGroupImpl value, $Res Function(_$OshiGroupImpl) then) =
      __$$OshiGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      String? kind,
      String? color,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$OshiGroupImplCopyWithImpl<$Res>
    extends _$OshiGroupCopyWithImpl<$Res, _$OshiGroupImpl>
    implements _$$OshiGroupImplCopyWith<$Res> {
  __$$OshiGroupImplCopyWithImpl(
      _$OshiGroupImpl _value, $Res Function(_$OshiGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of OshiGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? kind = freezed,
    Object? color = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$OshiGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: freezed == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$OshiGroupImpl implements _OshiGroup {
  const _$OshiGroupImpl(
      {required this.id,
      required this.ownerId,
      required this.name,
      this.kind,
      this.color,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$OshiGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$OshiGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  final String? kind;

  /// 推しカラー（#RRGGBB）。アクセントのみに使用しコントラストを壊さない。
  @override
  final String? color;
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
    return 'OshiGroup(id: $id, ownerId: $ownerId, name: $name, kind: $kind, color: $color, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OshiGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, ownerId, name, kind, color, memo, createdAt, updatedAt);

  /// Create a copy of OshiGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OshiGroupImplCopyWith<_$OshiGroupImpl> get copyWith =>
      __$$OshiGroupImplCopyWithImpl<_$OshiGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OshiGroupImplToJson(
      this,
    );
  }
}

abstract class _OshiGroup implements OshiGroup {
  const factory _OshiGroup(
          {required final String id,
          required final String ownerId,
          required final String name,
          final String? kind,
          final String? color,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$OshiGroupImpl;

  factory _OshiGroup.fromJson(Map<String, dynamic> json) =
      _$OshiGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  String? get kind;

  /// 推しカラー（#RRGGBB）。アクセントのみに使用しコントラストを壊さない。
  @override
  String? get color;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of OshiGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OshiGroupImplCopyWith<_$OshiGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OshiMember _$OshiMemberFromJson(Map<String, dynamic> json) {
  return _OshiMember.fromJson(json);
}

/// @nodoc
mixin _$OshiMember {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  OshiRank get rank => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  @NullableDateOnlyConverter()
  DateTime? get oshiSince => throw _privateConstructorUsedError;
  @NullableDateOnlyConverter()
  DateTime? get birthday => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OshiMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OshiMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OshiMemberCopyWith<OshiMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OshiMemberCopyWith<$Res> {
  factory $OshiMemberCopyWith(
          OshiMember value, $Res Function(OshiMember) then) =
      _$OshiMemberCopyWithImpl<$Res, OshiMember>;
  @useResult
  $Res call(
      {String id,
      String groupId,
      String ownerId,
      String name,
      OshiRank rank,
      String? color,
      @NullableDateOnlyConverter() DateTime? oshiSince,
      @NullableDateOnlyConverter() DateTime? birthday,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$OshiMemberCopyWithImpl<$Res, $Val extends OshiMember>
    implements $OshiMemberCopyWith<$Res> {
  _$OshiMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OshiMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? rank = null,
    Object? color = freezed,
    Object? oshiSince = freezed,
    Object? birthday = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as OshiRank,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      oshiSince: freezed == oshiSince
          ? _value.oshiSince
          : oshiSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      birthday: freezed == birthday
          ? _value.birthday
          : birthday // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
abstract class _$$OshiMemberImplCopyWith<$Res>
    implements $OshiMemberCopyWith<$Res> {
  factory _$$OshiMemberImplCopyWith(
          _$OshiMemberImpl value, $Res Function(_$OshiMemberImpl) then) =
      __$$OshiMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String groupId,
      String ownerId,
      String name,
      OshiRank rank,
      String? color,
      @NullableDateOnlyConverter() DateTime? oshiSince,
      @NullableDateOnlyConverter() DateTime? birthday,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$OshiMemberImplCopyWithImpl<$Res>
    extends _$OshiMemberCopyWithImpl<$Res, _$OshiMemberImpl>
    implements _$$OshiMemberImplCopyWith<$Res> {
  __$$OshiMemberImplCopyWithImpl(
      _$OshiMemberImpl _value, $Res Function(_$OshiMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of OshiMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? rank = null,
    Object? color = freezed,
    Object? oshiSince = freezed,
    Object? birthday = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$OshiMemberImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: null == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as OshiRank,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      oshiSince: freezed == oshiSince
          ? _value.oshiSince
          : oshiSince // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      birthday: freezed == birthday
          ? _value.birthday
          : birthday // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
class _$OshiMemberImpl implements _OshiMember {
  const _$OshiMemberImpl(
      {required this.id,
      required this.groupId,
      required this.ownerId,
      required this.name,
      this.rank = OshiRank.oshi,
      this.color,
      @NullableDateOnlyConverter() this.oshiSince,
      @NullableDateOnlyConverter() this.birthday,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$OshiMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$OshiMemberImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  @JsonKey()
  final OshiRank rank;
  @override
  final String? color;
  @override
  @NullableDateOnlyConverter()
  final DateTime? oshiSince;
  @override
  @NullableDateOnlyConverter()
  final DateTime? birthday;
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
    return 'OshiMember(id: $id, groupId: $groupId, ownerId: $ownerId, name: $name, rank: $rank, color: $color, oshiSince: $oshiSince, birthday: $birthday, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OshiMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.oshiSince, oshiSince) ||
                other.oshiSince == oshiSince) &&
            (identical(other.birthday, birthday) ||
                other.birthday == birthday) &&
            (identical(other.memo, memo) || other.memo == memo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, groupId, ownerId, name, rank,
      color, oshiSince, birthday, memo, createdAt, updatedAt);

  /// Create a copy of OshiMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OshiMemberImplCopyWith<_$OshiMemberImpl> get copyWith =>
      __$$OshiMemberImplCopyWithImpl<_$OshiMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OshiMemberImplToJson(
      this,
    );
  }
}

abstract class _OshiMember implements OshiMember {
  const factory _OshiMember(
          {required final String id,
          required final String groupId,
          required final String ownerId,
          required final String name,
          final OshiRank rank,
          final String? color,
          @NullableDateOnlyConverter() final DateTime? oshiSince,
          @NullableDateOnlyConverter() final DateTime? birthday,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$OshiMemberImpl;

  factory _OshiMember.fromJson(Map<String, dynamic> json) =
      _$OshiMemberImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  OshiRank get rank;
  @override
  String? get color;
  @override
  @NullableDateOnlyConverter()
  DateTime? get oshiSince;
  @override
  @NullableDateOnlyConverter()
  DateTime? get birthday;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of OshiMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OshiMemberImplCopyWith<_$OshiMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$OshiGroupWithMembers {
  OshiGroup get group => throw _privateConstructorUsedError;
  List<OshiMember> get members => throw _privateConstructorUsedError;

  /// Create a copy of OshiGroupWithMembers
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OshiGroupWithMembersCopyWith<OshiGroupWithMembers> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OshiGroupWithMembersCopyWith<$Res> {
  factory $OshiGroupWithMembersCopyWith(OshiGroupWithMembers value,
          $Res Function(OshiGroupWithMembers) then) =
      _$OshiGroupWithMembersCopyWithImpl<$Res, OshiGroupWithMembers>;
  @useResult
  $Res call({OshiGroup group, List<OshiMember> members});

  $OshiGroupCopyWith<$Res> get group;
}

/// @nodoc
class _$OshiGroupWithMembersCopyWithImpl<$Res,
        $Val extends OshiGroupWithMembers>
    implements $OshiGroupWithMembersCopyWith<$Res> {
  _$OshiGroupWithMembersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OshiGroupWithMembers
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? group = null,
    Object? members = null,
  }) {
    return _then(_value.copyWith(
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as OshiGroup,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<OshiMember>,
    ) as $Val);
  }

  /// Create a copy of OshiGroupWithMembers
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OshiGroupCopyWith<$Res> get group {
    return $OshiGroupCopyWith<$Res>(_value.group, (value) {
      return _then(_value.copyWith(group: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OshiGroupWithMembersImplCopyWith<$Res>
    implements $OshiGroupWithMembersCopyWith<$Res> {
  factory _$$OshiGroupWithMembersImplCopyWith(_$OshiGroupWithMembersImpl value,
          $Res Function(_$OshiGroupWithMembersImpl) then) =
      __$$OshiGroupWithMembersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({OshiGroup group, List<OshiMember> members});

  @override
  $OshiGroupCopyWith<$Res> get group;
}

/// @nodoc
class __$$OshiGroupWithMembersImplCopyWithImpl<$Res>
    extends _$OshiGroupWithMembersCopyWithImpl<$Res, _$OshiGroupWithMembersImpl>
    implements _$$OshiGroupWithMembersImplCopyWith<$Res> {
  __$$OshiGroupWithMembersImplCopyWithImpl(_$OshiGroupWithMembersImpl _value,
      $Res Function(_$OshiGroupWithMembersImpl) _then)
      : super(_value, _then);

  /// Create a copy of OshiGroupWithMembers
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? group = null,
    Object? members = null,
  }) {
    return _then(_$OshiGroupWithMembersImpl(
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as OshiGroup,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<OshiMember>,
    ));
  }
}

/// @nodoc

class _$OshiGroupWithMembersImpl implements _OshiGroupWithMembers {
  const _$OshiGroupWithMembersImpl(
      {required this.group,
      final List<OshiMember> members = const <OshiMember>[]})
      : _members = members;

  @override
  final OshiGroup group;
  final List<OshiMember> _members;
  @override
  @JsonKey()
  List<OshiMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'OshiGroupWithMembers(group: $group, members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OshiGroupWithMembersImpl &&
            (identical(other.group, group) || other.group == group) &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, group, const DeepCollectionEquality().hash(_members));

  /// Create a copy of OshiGroupWithMembers
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OshiGroupWithMembersImplCopyWith<_$OshiGroupWithMembersImpl>
      get copyWith =>
          __$$OshiGroupWithMembersImplCopyWithImpl<_$OshiGroupWithMembersImpl>(
              this, _$identity);
}

abstract class _OshiGroupWithMembers implements OshiGroupWithMembers {
  const factory _OshiGroupWithMembers(
      {required final OshiGroup group,
      final List<OshiMember> members}) = _$OshiGroupWithMembersImpl;

  @override
  OshiGroup get group;
  @override
  List<OshiMember> get members;

  /// Create a copy of OshiGroupWithMembers
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OshiGroupWithMembersImplCopyWith<_$OshiGroupWithMembersImpl>
      get copyWith => throw _privateConstructorUsedError;
}
