// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MemoChecklistItem _$MemoChecklistItemFromJson(Map<String, dynamic> json) {
  return _MemoChecklistItem.fromJson(json);
}

/// @nodoc
mixin _$MemoChecklistItem {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  bool get checked => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this MemoChecklistItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoChecklistItemCopyWith<MemoChecklistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoChecklistItemCopyWith<$Res> {
  factory $MemoChecklistItemCopyWith(
          MemoChecklistItem value, $Res Function(MemoChecklistItem) then) =
      _$MemoChecklistItemCopyWithImpl<$Res, MemoChecklistItem>;
  @useResult
  $Res call({String id, String text, bool checked, int sortOrder});
}

/// @nodoc
class _$MemoChecklistItemCopyWithImpl<$Res, $Val extends MemoChecklistItem>
    implements $MemoChecklistItemCopyWith<$Res> {
  _$MemoChecklistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? checked = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoChecklistItemImplCopyWith<$Res>
    implements $MemoChecklistItemCopyWith<$Res> {
  factory _$$MemoChecklistItemImplCopyWith(_$MemoChecklistItemImpl value,
          $Res Function(_$MemoChecklistItemImpl) then) =
      __$$MemoChecklistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String text, bool checked, int sortOrder});
}

/// @nodoc
class __$$MemoChecklistItemImplCopyWithImpl<$Res>
    extends _$MemoChecklistItemCopyWithImpl<$Res, _$MemoChecklistItemImpl>
    implements _$$MemoChecklistItemImplCopyWith<$Res> {
  __$$MemoChecklistItemImplCopyWithImpl(_$MemoChecklistItemImpl _value,
      $Res Function(_$MemoChecklistItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? checked = null,
    Object? sortOrder = null,
  }) {
    return _then(_$MemoChecklistItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoChecklistItemImpl implements _MemoChecklistItem {
  const _$MemoChecklistItemImpl(
      {required this.id,
      this.text = '',
      this.checked = false,
      this.sortOrder = 0});

  factory _$MemoChecklistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoChecklistItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String text;
  @override
  @JsonKey()
  final bool checked;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'MemoChecklistItem(id: $id, text: $text, checked: $checked, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoChecklistItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, text, checked, sortOrder);

  /// Create a copy of MemoChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoChecklistItemImplCopyWith<_$MemoChecklistItemImpl> get copyWith =>
      __$$MemoChecklistItemImplCopyWithImpl<_$MemoChecklistItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoChecklistItemImplToJson(
      this,
    );
  }
}

abstract class _MemoChecklistItem implements MemoChecklistItem {
  const factory _MemoChecklistItem(
      {required final String id,
      final String text,
      final bool checked,
      final int sortOrder}) = _$MemoChecklistItemImpl;

  factory _MemoChecklistItem.fromJson(Map<String, dynamic> json) =
      _$MemoChecklistItemImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  bool get checked;
  @override
  int get sortOrder;

  /// Create a copy of MemoChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoChecklistItemImplCopyWith<_$MemoChecklistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoBingo _$MemoBingoFromJson(Map<String, dynamic> json) {
  return _MemoBingo.fromJson(json);
}

/// @nodoc
mixin _$MemoBingo {
  int get size => throw _privateConstructorUsedError;
  List<String> get cells => throw _privateConstructorUsedError;
  List<int> get selected => throw _privateConstructorUsedError;

  /// Serializes this MemoBingo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoBingo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoBingoCopyWith<MemoBingo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoBingoCopyWith<$Res> {
  factory $MemoBingoCopyWith(MemoBingo value, $Res Function(MemoBingo) then) =
      _$MemoBingoCopyWithImpl<$Res, MemoBingo>;
  @useResult
  $Res call({int size, List<String> cells, List<int> selected});
}

/// @nodoc
class _$MemoBingoCopyWithImpl<$Res, $Val extends MemoBingo>
    implements $MemoBingoCopyWith<$Res> {
  _$MemoBingoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoBingo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? size = null,
    Object? cells = null,
    Object? selected = null,
  }) {
    return _then(_value.copyWith(
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      cells: null == cells
          ? _value.cells
          : cells // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoBingoImplCopyWith<$Res>
    implements $MemoBingoCopyWith<$Res> {
  factory _$$MemoBingoImplCopyWith(
          _$MemoBingoImpl value, $Res Function(_$MemoBingoImpl) then) =
      __$$MemoBingoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int size, List<String> cells, List<int> selected});
}

/// @nodoc
class __$$MemoBingoImplCopyWithImpl<$Res>
    extends _$MemoBingoCopyWithImpl<$Res, _$MemoBingoImpl>
    implements _$$MemoBingoImplCopyWith<$Res> {
  __$$MemoBingoImplCopyWithImpl(
      _$MemoBingoImpl _value, $Res Function(_$MemoBingoImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoBingo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? size = null,
    Object? cells = null,
    Object? selected = null,
  }) {
    return _then(_$MemoBingoImpl(
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      cells: null == cells
          ? _value._cells
          : cells // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selected: null == selected
          ? _value._selected
          : selected // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoBingoImpl extends _MemoBingo {
  const _$MemoBingoImpl(
      {this.size = 3,
      final List<String> cells = const <String>[],
      final List<int> selected = const <int>[]})
      : _cells = cells,
        _selected = selected,
        super._();

  factory _$MemoBingoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoBingoImplFromJson(json);

  @override
  @JsonKey()
  final int size;
  final List<String> _cells;
  @override
  @JsonKey()
  List<String> get cells {
    if (_cells is EqualUnmodifiableListView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cells);
  }

  final List<int> _selected;
  @override
  @JsonKey()
  List<int> get selected {
    if (_selected is EqualUnmodifiableListView) return _selected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selected);
  }

  @override
  String toString() {
    return 'MemoBingo(size: $size, cells: $cells, selected: $selected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoBingoImpl &&
            (identical(other.size, size) || other.size == size) &&
            const DeepCollectionEquality().equals(other._cells, _cells) &&
            const DeepCollectionEquality().equals(other._selected, _selected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      size,
      const DeepCollectionEquality().hash(_cells),
      const DeepCollectionEquality().hash(_selected));

  /// Create a copy of MemoBingo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoBingoImplCopyWith<_$MemoBingoImpl> get copyWith =>
      __$$MemoBingoImplCopyWithImpl<_$MemoBingoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoBingoImplToJson(
      this,
    );
  }
}

abstract class _MemoBingo extends MemoBingo {
  const factory _MemoBingo(
      {final int size,
      final List<String> cells,
      final List<int> selected}) = _$MemoBingoImpl;
  const _MemoBingo._() : super._();

  factory _MemoBingo.fromJson(Map<String, dynamic> json) =
      _$MemoBingoImpl.fromJson;

  @override
  int get size;
  @override
  List<String> get cells;
  @override
  List<int> get selected;

  /// Create a copy of MemoBingo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoBingoImplCopyWith<_$MemoBingoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoVoteOption _$MemoVoteOptionFromJson(Map<String, dynamic> json) {
  return _MemoVoteOption.fromJson(json);
}

/// @nodoc
mixin _$MemoVoteOption {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this MemoVoteOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoVoteOptionCopyWith<MemoVoteOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoVoteOptionCopyWith<$Res> {
  factory $MemoVoteOptionCopyWith(
          MemoVoteOption value, $Res Function(MemoVoteOption) then) =
      _$MemoVoteOptionCopyWithImpl<$Res, MemoVoteOption>;
  @useResult
  $Res call({String id, String text, int sortOrder});
}

/// @nodoc
class _$MemoVoteOptionCopyWithImpl<$Res, $Val extends MemoVoteOption>
    implements $MemoVoteOptionCopyWith<$Res> {
  _$MemoVoteOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoVoteOptionImplCopyWith<$Res>
    implements $MemoVoteOptionCopyWith<$Res> {
  factory _$$MemoVoteOptionImplCopyWith(_$MemoVoteOptionImpl value,
          $Res Function(_$MemoVoteOptionImpl) then) =
      __$$MemoVoteOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String text, int sortOrder});
}

/// @nodoc
class __$$MemoVoteOptionImplCopyWithImpl<$Res>
    extends _$MemoVoteOptionCopyWithImpl<$Res, _$MemoVoteOptionImpl>
    implements _$$MemoVoteOptionImplCopyWith<$Res> {
  __$$MemoVoteOptionImplCopyWithImpl(
      _$MemoVoteOptionImpl _value, $Res Function(_$MemoVoteOptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? sortOrder = null,
  }) {
    return _then(_$MemoVoteOptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoVoteOptionImpl implements _MemoVoteOption {
  const _$MemoVoteOptionImpl(
      {required this.id, this.text = '', this.sortOrder = 0});

  factory _$MemoVoteOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoVoteOptionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String text;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'MemoVoteOption(id: $id, text: $text, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoVoteOptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, text, sortOrder);

  /// Create a copy of MemoVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoVoteOptionImplCopyWith<_$MemoVoteOptionImpl> get copyWith =>
      __$$MemoVoteOptionImplCopyWithImpl<_$MemoVoteOptionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoVoteOptionImplToJson(
      this,
    );
  }
}

abstract class _MemoVoteOption implements MemoVoteOption {
  const factory _MemoVoteOption(
      {required final String id,
      final String text,
      final int sortOrder}) = _$MemoVoteOptionImpl;

  factory _MemoVoteOption.fromJson(Map<String, dynamic> json) =
      _$MemoVoteOptionImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  int get sortOrder;

  /// Create a copy of MemoVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoVoteOptionImplCopyWith<_$MemoVoteOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoVoteRecord _$MemoVoteRecordFromJson(Map<String, dynamic> json) {
  return _MemoVoteRecord.fromJson(json);
}

/// @nodoc
mixin _$MemoVoteRecord {
  String get voterId => throw _privateConstructorUsedError;
  String get optionId => throw _privateConstructorUsedError;

  /// Serializes this MemoVoteRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoVoteRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoVoteRecordCopyWith<MemoVoteRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoVoteRecordCopyWith<$Res> {
  factory $MemoVoteRecordCopyWith(
          MemoVoteRecord value, $Res Function(MemoVoteRecord) then) =
      _$MemoVoteRecordCopyWithImpl<$Res, MemoVoteRecord>;
  @useResult
  $Res call({String voterId, String optionId});
}

/// @nodoc
class _$MemoVoteRecordCopyWithImpl<$Res, $Val extends MemoVoteRecord>
    implements $MemoVoteRecordCopyWith<$Res> {
  _$MemoVoteRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoVoteRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voterId = null,
    Object? optionId = null,
  }) {
    return _then(_value.copyWith(
      voterId: null == voterId
          ? _value.voterId
          : voterId // ignore: cast_nullable_to_non_nullable
              as String,
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoVoteRecordImplCopyWith<$Res>
    implements $MemoVoteRecordCopyWith<$Res> {
  factory _$$MemoVoteRecordImplCopyWith(_$MemoVoteRecordImpl value,
          $Res Function(_$MemoVoteRecordImpl) then) =
      __$$MemoVoteRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String voterId, String optionId});
}

/// @nodoc
class __$$MemoVoteRecordImplCopyWithImpl<$Res>
    extends _$MemoVoteRecordCopyWithImpl<$Res, _$MemoVoteRecordImpl>
    implements _$$MemoVoteRecordImplCopyWith<$Res> {
  __$$MemoVoteRecordImplCopyWithImpl(
      _$MemoVoteRecordImpl _value, $Res Function(_$MemoVoteRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoVoteRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? voterId = null,
    Object? optionId = null,
  }) {
    return _then(_$MemoVoteRecordImpl(
      voterId: null == voterId
          ? _value.voterId
          : voterId // ignore: cast_nullable_to_non_nullable
              as String,
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoVoteRecordImpl implements _MemoVoteRecord {
  const _$MemoVoteRecordImpl({required this.voterId, required this.optionId});

  factory _$MemoVoteRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoVoteRecordImplFromJson(json);

  @override
  final String voterId;
  @override
  final String optionId;

  @override
  String toString() {
    return 'MemoVoteRecord(voterId: $voterId, optionId: $optionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoVoteRecordImpl &&
            (identical(other.voterId, voterId) || other.voterId == voterId) &&
            (identical(other.optionId, optionId) ||
                other.optionId == optionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, voterId, optionId);

  /// Create a copy of MemoVoteRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoVoteRecordImplCopyWith<_$MemoVoteRecordImpl> get copyWith =>
      __$$MemoVoteRecordImplCopyWithImpl<_$MemoVoteRecordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoVoteRecordImplToJson(
      this,
    );
  }
}

abstract class _MemoVoteRecord implements MemoVoteRecord {
  const factory _MemoVoteRecord(
      {required final String voterId,
      required final String optionId}) = _$MemoVoteRecordImpl;

  factory _MemoVoteRecord.fromJson(Map<String, dynamic> json) =
      _$MemoVoteRecordImpl.fromJson;

  @override
  String get voterId;
  @override
  String get optionId;

  /// Create a copy of MemoVoteRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoVoteRecordImplCopyWith<_$MemoVoteRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoVote _$MemoVoteFromJson(Map<String, dynamic> json) {
  return _MemoVote.fromJson(json);
}

/// @nodoc
mixin _$MemoVote {
  String get description => throw _privateConstructorUsedError;
  List<MemoVoteOption> get options => throw _privateConstructorUsedError;
  List<MemoVoteRecord> get votes => throw _privateConstructorUsedError;

  /// 重複投票の可否。false=1人1票、true=同じ人が複数選択肢へ投票可。
  bool get allowDuplicate => throw _privateConstructorUsedError;

  /// Serializes this MemoVote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoVote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoVoteCopyWith<MemoVote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoVoteCopyWith<$Res> {
  factory $MemoVoteCopyWith(MemoVote value, $Res Function(MemoVote) then) =
      _$MemoVoteCopyWithImpl<$Res, MemoVote>;
  @useResult
  $Res call(
      {String description,
      List<MemoVoteOption> options,
      List<MemoVoteRecord> votes,
      bool allowDuplicate});
}

/// @nodoc
class _$MemoVoteCopyWithImpl<$Res, $Val extends MemoVote>
    implements $MemoVoteCopyWith<$Res> {
  _$MemoVoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoVote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? options = null,
    Object? votes = null,
    Object? allowDuplicate = null,
  }) {
    return _then(_value.copyWith(
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<MemoVoteOption>,
      votes: null == votes
          ? _value.votes
          : votes // ignore: cast_nullable_to_non_nullable
              as List<MemoVoteRecord>,
      allowDuplicate: null == allowDuplicate
          ? _value.allowDuplicate
          : allowDuplicate // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoVoteImplCopyWith<$Res>
    implements $MemoVoteCopyWith<$Res> {
  factory _$$MemoVoteImplCopyWith(
          _$MemoVoteImpl value, $Res Function(_$MemoVoteImpl) then) =
      __$$MemoVoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String description,
      List<MemoVoteOption> options,
      List<MemoVoteRecord> votes,
      bool allowDuplicate});
}

/// @nodoc
class __$$MemoVoteImplCopyWithImpl<$Res>
    extends _$MemoVoteCopyWithImpl<$Res, _$MemoVoteImpl>
    implements _$$MemoVoteImplCopyWith<$Res> {
  __$$MemoVoteImplCopyWithImpl(
      _$MemoVoteImpl _value, $Res Function(_$MemoVoteImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoVote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? options = null,
    Object? votes = null,
    Object? allowDuplicate = null,
  }) {
    return _then(_$MemoVoteImpl(
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<MemoVoteOption>,
      votes: null == votes
          ? _value._votes
          : votes // ignore: cast_nullable_to_non_nullable
              as List<MemoVoteRecord>,
      allowDuplicate: null == allowDuplicate
          ? _value.allowDuplicate
          : allowDuplicate // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoVoteImpl extends _MemoVote {
  const _$MemoVoteImpl(
      {this.description = '',
      final List<MemoVoteOption> options = const <MemoVoteOption>[],
      final List<MemoVoteRecord> votes = const <MemoVoteRecord>[],
      this.allowDuplicate = false})
      : _options = options,
        _votes = votes,
        super._();

  factory _$MemoVoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoVoteImplFromJson(json);

  @override
  @JsonKey()
  final String description;
  final List<MemoVoteOption> _options;
  @override
  @JsonKey()
  List<MemoVoteOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  final List<MemoVoteRecord> _votes;
  @override
  @JsonKey()
  List<MemoVoteRecord> get votes {
    if (_votes is EqualUnmodifiableListView) return _votes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_votes);
  }

  /// 重複投票の可否。false=1人1票、true=同じ人が複数選択肢へ投票可。
  @override
  @JsonKey()
  final bool allowDuplicate;

  @override
  String toString() {
    return 'MemoVote(description: $description, options: $options, votes: $votes, allowDuplicate: $allowDuplicate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoVoteImpl &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality().equals(other._votes, _votes) &&
            (identical(other.allowDuplicate, allowDuplicate) ||
                other.allowDuplicate == allowDuplicate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      description,
      const DeepCollectionEquality().hash(_options),
      const DeepCollectionEquality().hash(_votes),
      allowDuplicate);

  /// Create a copy of MemoVote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoVoteImplCopyWith<_$MemoVoteImpl> get copyWith =>
      __$$MemoVoteImplCopyWithImpl<_$MemoVoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoVoteImplToJson(
      this,
    );
  }
}

abstract class _MemoVote extends MemoVote {
  const factory _MemoVote(
      {final String description,
      final List<MemoVoteOption> options,
      final List<MemoVoteRecord> votes,
      final bool allowDuplicate}) = _$MemoVoteImpl;
  const _MemoVote._() : super._();

  factory _MemoVote.fromJson(Map<String, dynamic> json) =
      _$MemoVoteImpl.fromJson;

  @override
  String get description;
  @override
  List<MemoVoteOption> get options;
  @override
  List<MemoVoteRecord> get votes;

  /// 重複投票の可否。false=1人1票、true=同じ人が複数選択肢へ投票可。
  @override
  bool get allowDuplicate;

  /// Create a copy of MemoVote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoVoteImplCopyWith<_$MemoVoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoContent _$MemoContentFromJson(Map<String, dynamic> json) {
  return _MemoContent.fromJson(json);
}

/// @nodoc
mixin _$MemoContent {
  List<MemoChecklistItem> get checklist => throw _privateConstructorUsedError;
  MemoBingo? get bingo => throw _privateConstructorUsedError;
  MemoVote? get vote => throw _privateConstructorUsedError;

  /// Serializes this MemoContent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoContentCopyWith<MemoContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoContentCopyWith<$Res> {
  factory $MemoContentCopyWith(
          MemoContent value, $Res Function(MemoContent) then) =
      _$MemoContentCopyWithImpl<$Res, MemoContent>;
  @useResult
  $Res call(
      {List<MemoChecklistItem> checklist, MemoBingo? bingo, MemoVote? vote});

  $MemoBingoCopyWith<$Res>? get bingo;
  $MemoVoteCopyWith<$Res>? get vote;
}

/// @nodoc
class _$MemoContentCopyWithImpl<$Res, $Val extends MemoContent>
    implements $MemoContentCopyWith<$Res> {
  _$MemoContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checklist = null,
    Object? bingo = freezed,
    Object? vote = freezed,
  }) {
    return _then(_value.copyWith(
      checklist: null == checklist
          ? _value.checklist
          : checklist // ignore: cast_nullable_to_non_nullable
              as List<MemoChecklistItem>,
      bingo: freezed == bingo
          ? _value.bingo
          : bingo // ignore: cast_nullable_to_non_nullable
              as MemoBingo?,
      vote: freezed == vote
          ? _value.vote
          : vote // ignore: cast_nullable_to_non_nullable
              as MemoVote?,
    ) as $Val);
  }

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemoBingoCopyWith<$Res>? get bingo {
    if (_value.bingo == null) {
      return null;
    }

    return $MemoBingoCopyWith<$Res>(_value.bingo!, (value) {
      return _then(_value.copyWith(bingo: value) as $Val);
    });
  }

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemoVoteCopyWith<$Res>? get vote {
    if (_value.vote == null) {
      return null;
    }

    return $MemoVoteCopyWith<$Res>(_value.vote!, (value) {
      return _then(_value.copyWith(vote: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemoContentImplCopyWith<$Res>
    implements $MemoContentCopyWith<$Res> {
  factory _$$MemoContentImplCopyWith(
          _$MemoContentImpl value, $Res Function(_$MemoContentImpl) then) =
      __$$MemoContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<MemoChecklistItem> checklist, MemoBingo? bingo, MemoVote? vote});

  @override
  $MemoBingoCopyWith<$Res>? get bingo;
  @override
  $MemoVoteCopyWith<$Res>? get vote;
}

/// @nodoc
class __$$MemoContentImplCopyWithImpl<$Res>
    extends _$MemoContentCopyWithImpl<$Res, _$MemoContentImpl>
    implements _$$MemoContentImplCopyWith<$Res> {
  __$$MemoContentImplCopyWithImpl(
      _$MemoContentImpl _value, $Res Function(_$MemoContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? checklist = null,
    Object? bingo = freezed,
    Object? vote = freezed,
  }) {
    return _then(_$MemoContentImpl(
      checklist: null == checklist
          ? _value._checklist
          : checklist // ignore: cast_nullable_to_non_nullable
              as List<MemoChecklistItem>,
      bingo: freezed == bingo
          ? _value.bingo
          : bingo // ignore: cast_nullable_to_non_nullable
              as MemoBingo?,
      vote: freezed == vote
          ? _value.vote
          : vote // ignore: cast_nullable_to_non_nullable
              as MemoVote?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$MemoContentImpl implements _MemoContent {
  const _$MemoContentImpl(
      {final List<MemoChecklistItem> checklist = const <MemoChecklistItem>[],
      this.bingo,
      this.vote})
      : _checklist = checklist;

  factory _$MemoContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoContentImplFromJson(json);

  final List<MemoChecklistItem> _checklist;
  @override
  @JsonKey()
  List<MemoChecklistItem> get checklist {
    if (_checklist is EqualUnmodifiableListView) return _checklist;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checklist);
  }

  @override
  final MemoBingo? bingo;
  @override
  final MemoVote? vote;

  @override
  String toString() {
    return 'MemoContent(checklist: $checklist, bingo: $bingo, vote: $vote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoContentImpl &&
            const DeepCollectionEquality()
                .equals(other._checklist, _checklist) &&
            (identical(other.bingo, bingo) || other.bingo == bingo) &&
            (identical(other.vote, vote) || other.vote == vote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_checklist), bingo, vote);

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoContentImplCopyWith<_$MemoContentImpl> get copyWith =>
      __$$MemoContentImplCopyWithImpl<_$MemoContentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoContentImplToJson(
      this,
    );
  }
}

abstract class _MemoContent implements MemoContent {
  const factory _MemoContent(
      {final List<MemoChecklistItem> checklist,
      final MemoBingo? bingo,
      final MemoVote? vote}) = _$MemoContentImpl;

  factory _MemoContent.fromJson(Map<String, dynamic> json) =
      _$MemoContentImpl.fromJson;

  @override
  List<MemoChecklistItem> get checklist;
  @override
  MemoBingo? get bingo;
  @override
  MemoVote? get vote;

  /// Create a copy of MemoContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoContentImplCopyWith<_$MemoContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
