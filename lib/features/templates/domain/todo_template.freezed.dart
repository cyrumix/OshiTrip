// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TodoTemplate _$TodoTemplateFromJson(Map<String, dynamic> json) {
  return _TodoTemplate.fromJson(json);
}

/// @nodoc
mixin _$TodoTemplate {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// このテンプレートが扱う種別（todo / belonging）。テンプレート内の
  /// 全項目がこの種別として適用される。
  TodoItemType get itemType => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TodoTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoTemplateCopyWith<TodoTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoTemplateCopyWith<$Res> {
  factory $TodoTemplateCopyWith(
          TodoTemplate value, $Res Function(TodoTemplate) then) =
      _$TodoTemplateCopyWithImpl<$Res, TodoTemplate>;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      TodoItemType itemType,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$TodoTemplateCopyWithImpl<$Res, $Val extends TodoTemplate>
    implements $TodoTemplateCopyWith<$Res> {
  _$TodoTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? itemType = null,
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
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as TodoItemType,
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
abstract class _$$TodoTemplateImplCopyWith<$Res>
    implements $TodoTemplateCopyWith<$Res> {
  factory _$$TodoTemplateImplCopyWith(
          _$TodoTemplateImpl value, $Res Function(_$TodoTemplateImpl) then) =
      __$$TodoTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      TodoItemType itemType,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$TodoTemplateImplCopyWithImpl<$Res>
    extends _$TodoTemplateCopyWithImpl<$Res, _$TodoTemplateImpl>
    implements _$$TodoTemplateImplCopyWith<$Res> {
  __$$TodoTemplateImplCopyWithImpl(
      _$TodoTemplateImpl _value, $Res Function(_$TodoTemplateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TodoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? itemType = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TodoTemplateImpl(
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
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as TodoItemType,
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
class _$TodoTemplateImpl implements _TodoTemplate {
  const _$TodoTemplateImpl(
      {required this.id,
      required this.ownerId,
      required this.name,
      required this.itemType,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$TodoTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String name;

  /// このテンプレートが扱う種別（todo / belonging）。テンプレート内の
  /// 全項目がこの種別として適用される。
  @override
  final TodoItemType itemType;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TodoTemplate(id: $id, ownerId: $ownerId, name: $name, itemType: $itemType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, ownerId, name, itemType, createdAt, updatedAt);

  /// Create a copy of TodoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoTemplateImplCopyWith<_$TodoTemplateImpl> get copyWith =>
      __$$TodoTemplateImplCopyWithImpl<_$TodoTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoTemplateImplToJson(
      this,
    );
  }
}

abstract class _TodoTemplate implements TodoTemplate {
  const factory _TodoTemplate(
          {required final String id,
          required final String ownerId,
          required final String name,
          required final TodoItemType itemType,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$TodoTemplateImpl;

  factory _TodoTemplate.fromJson(Map<String, dynamic> json) =
      _$TodoTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get name;

  /// このテンプレートが扱う種別（todo / belonging）。テンプレート内の
  /// 全項目がこの種別として適用される。
  @override
  TodoItemType get itemType;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of TodoTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoTemplateImplCopyWith<_$TodoTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TodoTemplateItem _$TodoTemplateItemFromJson(Map<String, dynamic> json) {
  return _TodoTemplateItem.fromJson(json);
}

/// @nodoc
mixin _$TodoTemplateItem {
  String get id => throw _privateConstructorUsedError;
  String get templateId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// 重要度（Todo テンプレートのみ。持ち物では null）。
  TodoPriority? get priority => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TodoTemplateItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoTemplateItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoTemplateItemCopyWith<TodoTemplateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoTemplateItemCopyWith<$Res> {
  factory $TodoTemplateItemCopyWith(
          TodoTemplateItem value, $Res Function(TodoTemplateItem) then) =
      _$TodoTemplateItemCopyWithImpl<$Res, TodoTemplateItem>;
  @useResult
  $Res call(
      {String id,
      String templateId,
      String ownerId,
      String name,
      TodoPriority? priority,
      String? memo,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$TodoTemplateItemCopyWithImpl<$Res, $Val extends TodoTemplateItem>
    implements $TodoTemplateItemCopyWith<$Res> {
  _$TodoTemplateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoTemplateItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? priority = freezed,
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
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TodoPriority?,
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
abstract class _$$TodoTemplateItemImplCopyWith<$Res>
    implements $TodoTemplateItemCopyWith<$Res> {
  factory _$$TodoTemplateItemImplCopyWith(_$TodoTemplateItemImpl value,
          $Res Function(_$TodoTemplateItemImpl) then) =
      __$$TodoTemplateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String templateId,
      String ownerId,
      String name,
      TodoPriority? priority,
      String? memo,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$TodoTemplateItemImplCopyWithImpl<$Res>
    extends _$TodoTemplateItemCopyWithImpl<$Res, _$TodoTemplateItemImpl>
    implements _$$TodoTemplateItemImplCopyWith<$Res> {
  __$$TodoTemplateItemImplCopyWithImpl(_$TodoTemplateItemImpl _value,
      $Res Function(_$TodoTemplateItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of TodoTemplateItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? priority = freezed,
    Object? memo = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TodoTemplateItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      priority: freezed == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TodoPriority?,
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
class _$TodoTemplateItemImpl implements _TodoTemplateItem {
  const _$TodoTemplateItemImpl(
      {required this.id,
      required this.templateId,
      required this.ownerId,
      required this.name,
      this.priority,
      this.memo,
      this.sortOrder = 0,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$TodoTemplateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoTemplateItemImplFromJson(json);

  @override
  final String id;
  @override
  final String templateId;
  @override
  final String ownerId;
  @override
  final String name;

  /// 重要度（Todo テンプレートのみ。持ち物では null）。
  @override
  final TodoPriority? priority;
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
    return 'TodoTemplateItem(id: $id, templateId: $templateId, ownerId: $ownerId, name: $name, priority: $priority, memo: $memo, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoTemplateItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
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
  int get hashCode => Object.hash(runtimeType, id, templateId, ownerId, name,
      priority, memo, sortOrder, createdAt, updatedAt);

  /// Create a copy of TodoTemplateItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoTemplateItemImplCopyWith<_$TodoTemplateItemImpl> get copyWith =>
      __$$TodoTemplateItemImplCopyWithImpl<_$TodoTemplateItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoTemplateItemImplToJson(
      this,
    );
  }
}

abstract class _TodoTemplateItem implements TodoTemplateItem {
  const factory _TodoTemplateItem(
          {required final String id,
          required final String templateId,
          required final String ownerId,
          required final String name,
          final TodoPriority? priority,
          final String? memo,
          final int sortOrder,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$TodoTemplateItemImpl;

  factory _TodoTemplateItem.fromJson(Map<String, dynamic> json) =
      _$TodoTemplateItemImpl.fromJson;

  @override
  String get id;
  @override
  String get templateId;
  @override
  String get ownerId;
  @override
  String get name;

  /// 重要度（Todo テンプレートのみ。持ち物では null）。
  @override
  TodoPriority? get priority;
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

  /// Create a copy of TodoTemplateItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoTemplateItemImplCopyWith<_$TodoTemplateItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TodoTemplateWithItems {
  TodoTemplate get template => throw _privateConstructorUsedError;
  List<TodoTemplateItem> get items => throw _privateConstructorUsedError;

  /// Create a copy of TodoTemplateWithItems
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoTemplateWithItemsCopyWith<TodoTemplateWithItems> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoTemplateWithItemsCopyWith<$Res> {
  factory $TodoTemplateWithItemsCopyWith(TodoTemplateWithItems value,
          $Res Function(TodoTemplateWithItems) then) =
      _$TodoTemplateWithItemsCopyWithImpl<$Res, TodoTemplateWithItems>;
  @useResult
  $Res call({TodoTemplate template, List<TodoTemplateItem> items});

  $TodoTemplateCopyWith<$Res> get template;
}

/// @nodoc
class _$TodoTemplateWithItemsCopyWithImpl<$Res,
        $Val extends TodoTemplateWithItems>
    implements $TodoTemplateWithItemsCopyWith<$Res> {
  _$TodoTemplateWithItemsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoTemplateWithItems
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? template = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as TodoTemplate,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TodoTemplateItem>,
    ) as $Val);
  }

  /// Create a copy of TodoTemplateWithItems
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TodoTemplateCopyWith<$Res> get template {
    return $TodoTemplateCopyWith<$Res>(_value.template, (value) {
      return _then(_value.copyWith(template: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TodoTemplateWithItemsImplCopyWith<$Res>
    implements $TodoTemplateWithItemsCopyWith<$Res> {
  factory _$$TodoTemplateWithItemsImplCopyWith(
          _$TodoTemplateWithItemsImpl value,
          $Res Function(_$TodoTemplateWithItemsImpl) then) =
      __$$TodoTemplateWithItemsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TodoTemplate template, List<TodoTemplateItem> items});

  @override
  $TodoTemplateCopyWith<$Res> get template;
}

/// @nodoc
class __$$TodoTemplateWithItemsImplCopyWithImpl<$Res>
    extends _$TodoTemplateWithItemsCopyWithImpl<$Res,
        _$TodoTemplateWithItemsImpl>
    implements _$$TodoTemplateWithItemsImplCopyWith<$Res> {
  __$$TodoTemplateWithItemsImplCopyWithImpl(_$TodoTemplateWithItemsImpl _value,
      $Res Function(_$TodoTemplateWithItemsImpl) _then)
      : super(_value, _then);

  /// Create a copy of TodoTemplateWithItems
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? template = null,
    Object? items = null,
  }) {
    return _then(_$TodoTemplateWithItemsImpl(
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as TodoTemplate,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TodoTemplateItem>,
    ));
  }
}

/// @nodoc

class _$TodoTemplateWithItemsImpl extends _TodoTemplateWithItems {
  const _$TodoTemplateWithItemsImpl(
      {required this.template,
      final List<TodoTemplateItem> items = const <TodoTemplateItem>[]})
      : _items = items,
        super._();

  @override
  final TodoTemplate template;
  final List<TodoTemplateItem> _items;
  @override
  @JsonKey()
  List<TodoTemplateItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'TodoTemplateWithItems(template: $template, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoTemplateWithItemsImpl &&
            (identical(other.template, template) ||
                other.template == template) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, template, const DeepCollectionEquality().hash(_items));

  /// Create a copy of TodoTemplateWithItems
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoTemplateWithItemsImplCopyWith<_$TodoTemplateWithItemsImpl>
      get copyWith => __$$TodoTemplateWithItemsImplCopyWithImpl<
          _$TodoTemplateWithItemsImpl>(this, _$identity);
}

abstract class _TodoTemplateWithItems extends TodoTemplateWithItems {
  const factory _TodoTemplateWithItems(
      {required final TodoTemplate template,
      final List<TodoTemplateItem> items}) = _$TodoTemplateWithItemsImpl;
  const _TodoTemplateWithItems._() : super._();

  @override
  TodoTemplate get template;
  @override
  List<TodoTemplateItem> get items;

  /// Create a copy of TodoTemplateWithItems
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoTemplateWithItemsImplCopyWith<_$TodoTemplateWithItemsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
