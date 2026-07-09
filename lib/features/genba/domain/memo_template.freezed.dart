// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MemoTemplate _$MemoTemplateFromJson(Map<String, dynamic> json) {
  return _MemoTemplate.fromJson(json);
}

/// @nodoc
mixin _$MemoTemplate {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MemoKind get kind => throw _privateConstructorUsedError;

  /// 既定テンプレートの区分（today_card の集合メモ等の識別に使う）。
  MemoCategory get category => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;

  /// 雛形の構造化コンテンツ（自由メモは null）。投票の票([MemoVote.votes])は
  /// 雛形には保存せず、適用時に空から始める。
  MemoContent? get content => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MemoTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoTemplateCopyWith<MemoTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoTemplateCopyWith<$Res> {
  factory $MemoTemplateCopyWith(
          MemoTemplate value, $Res Function(MemoTemplate) then) =
      _$MemoTemplateCopyWithImpl<$Res, MemoTemplate>;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      MemoKind kind,
      MemoCategory category,
      String title,
      String body,
      MemoContent? content,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});

  $MemoContentCopyWith<$Res>? get content;
}

/// @nodoc
class _$MemoTemplateCopyWithImpl<$Res, $Val extends MemoTemplate>
    implements $MemoTemplateCopyWith<$Res> {
  _$MemoTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? kind = null,
    Object? category = null,
    Object? title = null,
    Object? body = null,
    Object? content = freezed,
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MemoKind,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as MemoCategory,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as MemoContent?,
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

  /// Create a copy of MemoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemoContentCopyWith<$Res>? get content {
    if (_value.content == null) {
      return null;
    }

    return $MemoContentCopyWith<$Res>(_value.content!, (value) {
      return _then(_value.copyWith(content: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemoTemplateImplCopyWith<$Res>
    implements $MemoTemplateCopyWith<$Res> {
  factory _$$MemoTemplateImplCopyWith(
          _$MemoTemplateImpl value, $Res Function(_$MemoTemplateImpl) then) =
      __$$MemoTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      MemoKind kind,
      MemoCategory category,
      String title,
      String body,
      MemoContent? content,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});

  @override
  $MemoContentCopyWith<$Res>? get content;
}

/// @nodoc
class __$$MemoTemplateImplCopyWithImpl<$Res>
    extends _$MemoTemplateCopyWithImpl<$Res, _$MemoTemplateImpl>
    implements _$$MemoTemplateImplCopyWith<$Res> {
  __$$MemoTemplateImplCopyWithImpl(
      _$MemoTemplateImpl _value, $Res Function(_$MemoTemplateImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? kind = null,
    Object? category = null,
    Object? title = null,
    Object? body = null,
    Object? content = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$MemoTemplateImpl(
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
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MemoKind,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as MemoCategory,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as MemoContent?,
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
class _$MemoTemplateImpl implements _MemoTemplate {
  const _$MemoTemplateImpl(
      {required this.id,
      required this.ownerId,
      required this.name,
      this.kind = MemoKind.free,
      this.category = MemoCategory.other,
      this.title = '',
      this.body = '',
      this.content,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$MemoTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  @JsonKey()
  final MemoKind kind;

  /// 既定テンプレートの区分（today_card の集合メモ等の識別に使う）。
  @override
  @JsonKey()
  final MemoCategory category;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String body;

  /// 雛形の構造化コンテンツ（自由メモは null）。投票の票([MemoVote.votes])は
  /// 雛形には保存せず、適用時に空から始める。
  @override
  final MemoContent? content;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'MemoTemplate(id: $id, ownerId: $ownerId, name: $name, kind: $kind, category: $category, title: $title, body: $body, content: $content, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, ownerId, name, kind,
      category, title, body, content, createdAt, updatedAt);

  /// Create a copy of MemoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoTemplateImplCopyWith<_$MemoTemplateImpl> get copyWith =>
      __$$MemoTemplateImplCopyWithImpl<_$MemoTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoTemplateImplToJson(
      this,
    );
  }
}

abstract class _MemoTemplate implements MemoTemplate {
  const factory _MemoTemplate(
          {required final String id,
          required final String ownerId,
          required final String name,
          final MemoKind kind,
          final MemoCategory category,
          final String title,
          final String body,
          final MemoContent? content,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$MemoTemplateImpl;

  factory _MemoTemplate.fromJson(Map<String, dynamic> json) =
      _$MemoTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  MemoKind get kind;

  /// 既定テンプレートの区分（today_card の集合メモ等の識別に使う）。
  @override
  MemoCategory get category;
  @override
  String get title;
  @override
  String get body;

  /// 雛形の構造化コンテンツ（自由メモは null）。投票の票([MemoVote.votes])は
  /// 雛形には保存せず、適用時に空から始める。
  @override
  MemoContent? get content;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of MemoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoTemplateImplCopyWith<_$MemoTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
