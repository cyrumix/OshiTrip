// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'genba.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Genba _$GenbaFromJson(Map<String, dynamic> json) {
  return _Genba.fromJson(json);
}

/// @nodoc
mixin _$Genba {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get artistName => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @DateOnlyConverter()
  DateTime get eventDate => throw _privateConstructorUsedError;
  String? get oshiGroupId => throw _privateConstructorUsedError;
  List<String> get oshiMemberIds => throw _privateConstructorUsedError;
  String? get venue => throw _privateConstructorUsedError;

  /// 開場/開演/終演予定。公演日 0:00 からの分数（深夜公演は 1440 超を許容）。
  int? get doorTimeMinutes => throw _privateConstructorUsedError;
  int? get startTimeMinutes => throw _privateConstructorUsedError;
  int? get endTimeMinutes => throw _privateConstructorUsedError;
  String? get performanceType => throw _privateConstructorUsedError;

  /// ユーザー投稿型公演マスタとの紐づけ（今回は境界のみ）。
  String? get performanceId => throw _privateConstructorUsedError;

  /// 遠征の有無（null = 未回答）。
  bool? get isExpedition => throw _privateConstructorUsedError;
  RequirementStatus get transportRequirement =>
      throw _privateConstructorUsedError;
  RequirementStatus get lodgingRequirement =>
      throw _privateConstructorUsedError;
  bool get isCanceled => throw _privateConstructorUsedError;

  /// 現場ヒーロー画像の端末内参照（`images/<owner>/hero/...`）。
  /// 同期対象外（Outbox/Supabase へ送らない, H-04）。他端末では表示されない。
  String? get heroImageLocalPath => throw _privateConstructorUsedError;

  /// ユーザーが明示的に「終演した」とした時刻（余韻中への手動遷移）。
  @NullableUtcDateTimeConverter()
  DateTime? get manualEndedAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Genba to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Genba
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenbaCopyWith<Genba> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenbaCopyWith<$Res> {
  factory $GenbaCopyWith(Genba value, $Res Function(Genba) then) =
      _$GenbaCopyWithImpl<$Res, Genba>;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String artistName,
      String title,
      @DateOnlyConverter() DateTime eventDate,
      String? oshiGroupId,
      List<String> oshiMemberIds,
      String? venue,
      int? doorTimeMinutes,
      int? startTimeMinutes,
      int? endTimeMinutes,
      String? performanceType,
      String? performanceId,
      bool? isExpedition,
      RequirementStatus transportRequirement,
      RequirementStatus lodgingRequirement,
      bool isCanceled,
      String? heroImageLocalPath,
      @NullableUtcDateTimeConverter() DateTime? manualEndedAt,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$GenbaCopyWithImpl<$Res, $Val extends Genba>
    implements $GenbaCopyWith<$Res> {
  _$GenbaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Genba
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? artistName = null,
    Object? title = null,
    Object? eventDate = null,
    Object? oshiGroupId = freezed,
    Object? oshiMemberIds = null,
    Object? venue = freezed,
    Object? doorTimeMinutes = freezed,
    Object? startTimeMinutes = freezed,
    Object? endTimeMinutes = freezed,
    Object? performanceType = freezed,
    Object? performanceId = freezed,
    Object? isExpedition = freezed,
    Object? transportRequirement = null,
    Object? lodgingRequirement = null,
    Object? isCanceled = null,
    Object? heroImageLocalPath = freezed,
    Object? manualEndedAt = freezed,
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
      artistName: null == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      oshiGroupId: freezed == oshiGroupId
          ? _value.oshiGroupId
          : oshiGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      oshiMemberIds: null == oshiMemberIds
          ? _value.oshiMemberIds
          : oshiMemberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String?,
      doorTimeMinutes: freezed == doorTimeMinutes
          ? _value.doorTimeMinutes
          : doorTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      startTimeMinutes: freezed == startTimeMinutes
          ? _value.startTimeMinutes
          : startTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      endTimeMinutes: freezed == endTimeMinutes
          ? _value.endTimeMinutes
          : endTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      performanceType: freezed == performanceType
          ? _value.performanceType
          : performanceType // ignore: cast_nullable_to_non_nullable
              as String?,
      performanceId: freezed == performanceId
          ? _value.performanceId
          : performanceId // ignore: cast_nullable_to_non_nullable
              as String?,
      isExpedition: freezed == isExpedition
          ? _value.isExpedition
          : isExpedition // ignore: cast_nullable_to_non_nullable
              as bool?,
      transportRequirement: null == transportRequirement
          ? _value.transportRequirement
          : transportRequirement // ignore: cast_nullable_to_non_nullable
              as RequirementStatus,
      lodgingRequirement: null == lodgingRequirement
          ? _value.lodgingRequirement
          : lodgingRequirement // ignore: cast_nullable_to_non_nullable
              as RequirementStatus,
      isCanceled: null == isCanceled
          ? _value.isCanceled
          : isCanceled // ignore: cast_nullable_to_non_nullable
              as bool,
      heroImageLocalPath: freezed == heroImageLocalPath
          ? _value.heroImageLocalPath
          : heroImageLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      manualEndedAt: freezed == manualEndedAt
          ? _value.manualEndedAt
          : manualEndedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
abstract class _$$GenbaImplCopyWith<$Res> implements $GenbaCopyWith<$Res> {
  factory _$$GenbaImplCopyWith(
          _$GenbaImpl value, $Res Function(_$GenbaImpl) then) =
      __$$GenbaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String artistName,
      String title,
      @DateOnlyConverter() DateTime eventDate,
      String? oshiGroupId,
      List<String> oshiMemberIds,
      String? venue,
      int? doorTimeMinutes,
      int? startTimeMinutes,
      int? endTimeMinutes,
      String? performanceType,
      String? performanceId,
      bool? isExpedition,
      RequirementStatus transportRequirement,
      RequirementStatus lodgingRequirement,
      bool isCanceled,
      String? heroImageLocalPath,
      @NullableUtcDateTimeConverter() DateTime? manualEndedAt,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$GenbaImplCopyWithImpl<$Res>
    extends _$GenbaCopyWithImpl<$Res, _$GenbaImpl>
    implements _$$GenbaImplCopyWith<$Res> {
  __$$GenbaImplCopyWithImpl(
      _$GenbaImpl _value, $Res Function(_$GenbaImpl) _then)
      : super(_value, _then);

  /// Create a copy of Genba
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? artistName = null,
    Object? title = null,
    Object? eventDate = null,
    Object? oshiGroupId = freezed,
    Object? oshiMemberIds = null,
    Object? venue = freezed,
    Object? doorTimeMinutes = freezed,
    Object? startTimeMinutes = freezed,
    Object? endTimeMinutes = freezed,
    Object? performanceType = freezed,
    Object? performanceId = freezed,
    Object? isExpedition = freezed,
    Object? transportRequirement = null,
    Object? lodgingRequirement = null,
    Object? isCanceled = null,
    Object? heroImageLocalPath = freezed,
    Object? manualEndedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$GenbaImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      artistName: null == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      oshiGroupId: freezed == oshiGroupId
          ? _value.oshiGroupId
          : oshiGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      oshiMemberIds: null == oshiMemberIds
          ? _value._oshiMemberIds
          : oshiMemberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      venue: freezed == venue
          ? _value.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String?,
      doorTimeMinutes: freezed == doorTimeMinutes
          ? _value.doorTimeMinutes
          : doorTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      startTimeMinutes: freezed == startTimeMinutes
          ? _value.startTimeMinutes
          : startTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      endTimeMinutes: freezed == endTimeMinutes
          ? _value.endTimeMinutes
          : endTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      performanceType: freezed == performanceType
          ? _value.performanceType
          : performanceType // ignore: cast_nullable_to_non_nullable
              as String?,
      performanceId: freezed == performanceId
          ? _value.performanceId
          : performanceId // ignore: cast_nullable_to_non_nullable
              as String?,
      isExpedition: freezed == isExpedition
          ? _value.isExpedition
          : isExpedition // ignore: cast_nullable_to_non_nullable
              as bool?,
      transportRequirement: null == transportRequirement
          ? _value.transportRequirement
          : transportRequirement // ignore: cast_nullable_to_non_nullable
              as RequirementStatus,
      lodgingRequirement: null == lodgingRequirement
          ? _value.lodgingRequirement
          : lodgingRequirement // ignore: cast_nullable_to_non_nullable
              as RequirementStatus,
      isCanceled: null == isCanceled
          ? _value.isCanceled
          : isCanceled // ignore: cast_nullable_to_non_nullable
              as bool,
      heroImageLocalPath: freezed == heroImageLocalPath
          ? _value.heroImageLocalPath
          : heroImageLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      manualEndedAt: freezed == manualEndedAt
          ? _value.manualEndedAt
          : manualEndedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
class _$GenbaImpl implements _Genba {
  const _$GenbaImpl(
      {required this.id,
      required this.ownerId,
      required this.artistName,
      required this.title,
      @DateOnlyConverter() required this.eventDate,
      this.oshiGroupId,
      final List<String> oshiMemberIds = const <String>[],
      this.venue,
      this.doorTimeMinutes,
      this.startTimeMinutes,
      this.endTimeMinutes,
      this.performanceType,
      this.performanceId,
      this.isExpedition,
      this.transportRequirement = RequirementStatus.unknown,
      this.lodgingRequirement = RequirementStatus.unknown,
      this.isCanceled = false,
      this.heroImageLocalPath,
      @NullableUtcDateTimeConverter() this.manualEndedAt,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt})
      : _oshiMemberIds = oshiMemberIds;

  factory _$GenbaImpl.fromJson(Map<String, dynamic> json) =>
      _$$GenbaImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String artistName;
  @override
  final String title;
  @override
  @DateOnlyConverter()
  final DateTime eventDate;
  @override
  final String? oshiGroupId;
  final List<String> _oshiMemberIds;
  @override
  @JsonKey()
  List<String> get oshiMemberIds {
    if (_oshiMemberIds is EqualUnmodifiableListView) return _oshiMemberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_oshiMemberIds);
  }

  @override
  final String? venue;

  /// 開場/開演/終演予定。公演日 0:00 からの分数（深夜公演は 1440 超を許容）。
  @override
  final int? doorTimeMinutes;
  @override
  final int? startTimeMinutes;
  @override
  final int? endTimeMinutes;
  @override
  final String? performanceType;

  /// ユーザー投稿型公演マスタとの紐づけ（今回は境界のみ）。
  @override
  final String? performanceId;

  /// 遠征の有無（null = 未回答）。
  @override
  final bool? isExpedition;
  @override
  @JsonKey()
  final RequirementStatus transportRequirement;
  @override
  @JsonKey()
  final RequirementStatus lodgingRequirement;
  @override
  @JsonKey()
  final bool isCanceled;

  /// 現場ヒーロー画像の端末内参照（`images/<owner>/hero/...`）。
  /// 同期対象外（Outbox/Supabase へ送らない, H-04）。他端末では表示されない。
  @override
  final String? heroImageLocalPath;

  /// ユーザーが明示的に「終演した」とした時刻（余韻中への手動遷移）。
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? manualEndedAt;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Genba(id: $id, ownerId: $ownerId, artistName: $artistName, title: $title, eventDate: $eventDate, oshiGroupId: $oshiGroupId, oshiMemberIds: $oshiMemberIds, venue: $venue, doorTimeMinutes: $doorTimeMinutes, startTimeMinutes: $startTimeMinutes, endTimeMinutes: $endTimeMinutes, performanceType: $performanceType, performanceId: $performanceId, isExpedition: $isExpedition, transportRequirement: $transportRequirement, lodgingRequirement: $lodgingRequirement, isCanceled: $isCanceled, heroImageLocalPath: $heroImageLocalPath, manualEndedAt: $manualEndedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenbaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.artistName, artistName) ||
                other.artistName == artistName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.oshiGroupId, oshiGroupId) ||
                other.oshiGroupId == oshiGroupId) &&
            const DeepCollectionEquality()
                .equals(other._oshiMemberIds, _oshiMemberIds) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            (identical(other.doorTimeMinutes, doorTimeMinutes) ||
                other.doorTimeMinutes == doorTimeMinutes) &&
            (identical(other.startTimeMinutes, startTimeMinutes) ||
                other.startTimeMinutes == startTimeMinutes) &&
            (identical(other.endTimeMinutes, endTimeMinutes) ||
                other.endTimeMinutes == endTimeMinutes) &&
            (identical(other.performanceType, performanceType) ||
                other.performanceType == performanceType) &&
            (identical(other.performanceId, performanceId) ||
                other.performanceId == performanceId) &&
            (identical(other.isExpedition, isExpedition) ||
                other.isExpedition == isExpedition) &&
            (identical(other.transportRequirement, transportRequirement) ||
                other.transportRequirement == transportRequirement) &&
            (identical(other.lodgingRequirement, lodgingRequirement) ||
                other.lodgingRequirement == lodgingRequirement) &&
            (identical(other.isCanceled, isCanceled) ||
                other.isCanceled == isCanceled) &&
            (identical(other.heroImageLocalPath, heroImageLocalPath) ||
                other.heroImageLocalPath == heroImageLocalPath) &&
            (identical(other.manualEndedAt, manualEndedAt) ||
                other.manualEndedAt == manualEndedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        ownerId,
        artistName,
        title,
        eventDate,
        oshiGroupId,
        const DeepCollectionEquality().hash(_oshiMemberIds),
        venue,
        doorTimeMinutes,
        startTimeMinutes,
        endTimeMinutes,
        performanceType,
        performanceId,
        isExpedition,
        transportRequirement,
        lodgingRequirement,
        isCanceled,
        heroImageLocalPath,
        manualEndedAt,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Genba
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenbaImplCopyWith<_$GenbaImpl> get copyWith =>
      __$$GenbaImplCopyWithImpl<_$GenbaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GenbaImplToJson(
      this,
    );
  }
}

abstract class _Genba implements Genba {
  const factory _Genba(
      {required final String id,
      required final String ownerId,
      required final String artistName,
      required final String title,
      @DateOnlyConverter() required final DateTime eventDate,
      final String? oshiGroupId,
      final List<String> oshiMemberIds,
      final String? venue,
      final int? doorTimeMinutes,
      final int? startTimeMinutes,
      final int? endTimeMinutes,
      final String? performanceType,
      final String? performanceId,
      final bool? isExpedition,
      final RequirementStatus transportRequirement,
      final RequirementStatus lodgingRequirement,
      final bool isCanceled,
      final String? heroImageLocalPath,
      @NullableUtcDateTimeConverter() final DateTime? manualEndedAt,
      @UtcDateTimeConverter() required final DateTime createdAt,
      @UtcDateTimeConverter() required final DateTime updatedAt}) = _$GenbaImpl;

  factory _Genba.fromJson(Map<String, dynamic> json) = _$GenbaImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get artistName;
  @override
  String get title;
  @override
  @DateOnlyConverter()
  DateTime get eventDate;
  @override
  String? get oshiGroupId;
  @override
  List<String> get oshiMemberIds;
  @override
  String? get venue;

  /// 開場/開演/終演予定。公演日 0:00 からの分数（深夜公演は 1440 超を許容）。
  @override
  int? get doorTimeMinutes;
  @override
  int? get startTimeMinutes;
  @override
  int? get endTimeMinutes;
  @override
  String? get performanceType;

  /// ユーザー投稿型公演マスタとの紐づけ（今回は境界のみ）。
  @override
  String? get performanceId;

  /// 遠征の有無（null = 未回答）。
  @override
  bool? get isExpedition;
  @override
  RequirementStatus get transportRequirement;
  @override
  RequirementStatus get lodgingRequirement;
  @override
  bool get isCanceled;

  /// 現場ヒーロー画像の端末内参照（`images/<owner>/hero/...`）。
  /// 同期対象外（Outbox/Supabase へ送らない, H-04）。他端末では表示されない。
  @override
  String? get heroImageLocalPath;

  /// ユーザーが明示的に「終演した」とした時刻（余韻中への手動遷移）。
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get manualEndedAt;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of Genba
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenbaImplCopyWith<_$GenbaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Ticket _$TicketFromJson(Map<String, dynamic> json) {
  return _Ticket.fromJson(json);
}

/// @nodoc
mixin _$Ticket {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  TicketAcquisition get acquisitionStatus => throw _privateConstructorUsedError;
  TicketPayment get paymentStatus => throw _privateConstructorUsedError;
  TicketIssuance get issuanceStatus => throw _privateConstructorUsedError;
  String? get seat => throw _privateConstructorUsedError;
  String? get entryNumber => throw _privateConstructorUsedError;
  String? get gate => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;

  /// Supabase Storage 上のオブジェクトパス（署名URLで認可付き取得する）。
  String? get imagePath => throw _privateConstructorUsedError;

  /// 端末内のチケット画像参照（同期対象外。アップロードは後続範囲）。
  String? get imageLocalPath => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Ticket to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TicketCopyWith<Ticket> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TicketCopyWith<$Res> {
  factory $TicketCopyWith(Ticket value, $Res Function(Ticket) then) =
      _$TicketCopyWithImpl<$Res, Ticket>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      TicketAcquisition acquisitionStatus,
      TicketPayment paymentStatus,
      TicketIssuance issuanceStatus,
      String? seat,
      String? entryNumber,
      String? gate,
      String? url,
      String? imagePath,
      String? imageLocalPath,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$TicketCopyWithImpl<$Res, $Val extends Ticket>
    implements $TicketCopyWith<$Res> {
  _$TicketCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? acquisitionStatus = null,
    Object? paymentStatus = null,
    Object? issuanceStatus = null,
    Object? seat = freezed,
    Object? entryNumber = freezed,
    Object? gate = freezed,
    Object? url = freezed,
    Object? imagePath = freezed,
    Object? imageLocalPath = freezed,
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
      acquisitionStatus: null == acquisitionStatus
          ? _value.acquisitionStatus
          : acquisitionStatus // ignore: cast_nullable_to_non_nullable
              as TicketAcquisition,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as TicketPayment,
      issuanceStatus: null == issuanceStatus
          ? _value.issuanceStatus
          : issuanceStatus // ignore: cast_nullable_to_non_nullable
              as TicketIssuance,
      seat: freezed == seat
          ? _value.seat
          : seat // ignore: cast_nullable_to_non_nullable
              as String?,
      entryNumber: freezed == entryNumber
          ? _value.entryNumber
          : entryNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      gate: freezed == gate
          ? _value.gate
          : gate // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      imageLocalPath: freezed == imageLocalPath
          ? _value.imageLocalPath
          : imageLocalPath // ignore: cast_nullable_to_non_nullable
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
abstract class _$$TicketImplCopyWith<$Res> implements $TicketCopyWith<$Res> {
  factory _$$TicketImplCopyWith(
          _$TicketImpl value, $Res Function(_$TicketImpl) then) =
      __$$TicketImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      TicketAcquisition acquisitionStatus,
      TicketPayment paymentStatus,
      TicketIssuance issuanceStatus,
      String? seat,
      String? entryNumber,
      String? gate,
      String? url,
      String? imagePath,
      String? imageLocalPath,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$TicketImplCopyWithImpl<$Res>
    extends _$TicketCopyWithImpl<$Res, _$TicketImpl>
    implements _$$TicketImplCopyWith<$Res> {
  __$$TicketImplCopyWithImpl(
      _$TicketImpl _value, $Res Function(_$TicketImpl) _then)
      : super(_value, _then);

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? acquisitionStatus = null,
    Object? paymentStatus = null,
    Object? issuanceStatus = null,
    Object? seat = freezed,
    Object? entryNumber = freezed,
    Object? gate = freezed,
    Object? url = freezed,
    Object? imagePath = freezed,
    Object? imageLocalPath = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TicketImpl(
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
      acquisitionStatus: null == acquisitionStatus
          ? _value.acquisitionStatus
          : acquisitionStatus // ignore: cast_nullable_to_non_nullable
              as TicketAcquisition,
      paymentStatus: null == paymentStatus
          ? _value.paymentStatus
          : paymentStatus // ignore: cast_nullable_to_non_nullable
              as TicketPayment,
      issuanceStatus: null == issuanceStatus
          ? _value.issuanceStatus
          : issuanceStatus // ignore: cast_nullable_to_non_nullable
              as TicketIssuance,
      seat: freezed == seat
          ? _value.seat
          : seat // ignore: cast_nullable_to_non_nullable
              as String?,
      entryNumber: freezed == entryNumber
          ? _value.entryNumber
          : entryNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      gate: freezed == gate
          ? _value.gate
          : gate // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      imageLocalPath: freezed == imageLocalPath
          ? _value.imageLocalPath
          : imageLocalPath // ignore: cast_nullable_to_non_nullable
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
class _$TicketImpl implements _Ticket {
  const _$TicketImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.acquisitionStatus = TicketAcquisition.notApplied,
      this.paymentStatus = TicketPayment.unpaid,
      this.issuanceStatus = TicketIssuance.notIssued,
      this.seat,
      this.entryNumber,
      this.gate,
      this.url,
      this.imagePath,
      this.imageLocalPath,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$TicketImpl.fromJson(Map<String, dynamic> json) =>
      _$$TicketImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  @JsonKey()
  final TicketAcquisition acquisitionStatus;
  @override
  @JsonKey()
  final TicketPayment paymentStatus;
  @override
  @JsonKey()
  final TicketIssuance issuanceStatus;
  @override
  final String? seat;
  @override
  final String? entryNumber;
  @override
  final String? gate;
  @override
  final String? url;

  /// Supabase Storage 上のオブジェクトパス（署名URLで認可付き取得する）。
  @override
  final String? imagePath;

  /// 端末内のチケット画像参照（同期対象外。アップロードは後続範囲）。
  @override
  final String? imageLocalPath;
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
    return 'Ticket(id: $id, genbaId: $genbaId, ownerId: $ownerId, acquisitionStatus: $acquisitionStatus, paymentStatus: $paymentStatus, issuanceStatus: $issuanceStatus, seat: $seat, entryNumber: $entryNumber, gate: $gate, url: $url, imagePath: $imagePath, imageLocalPath: $imageLocalPath, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TicketImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.acquisitionStatus, acquisitionStatus) ||
                other.acquisitionStatus == acquisitionStatus) &&
            (identical(other.paymentStatus, paymentStatus) ||
                other.paymentStatus == paymentStatus) &&
            (identical(other.issuanceStatus, issuanceStatus) ||
                other.issuanceStatus == issuanceStatus) &&
            (identical(other.seat, seat) || other.seat == seat) &&
            (identical(other.entryNumber, entryNumber) ||
                other.entryNumber == entryNumber) &&
            (identical(other.gate, gate) || other.gate == gate) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.imageLocalPath, imageLocalPath) ||
                other.imageLocalPath == imageLocalPath) &&
            (identical(other.memo, memo) || other.memo == memo) &&
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
      acquisitionStatus,
      paymentStatus,
      issuanceStatus,
      seat,
      entryNumber,
      gate,
      url,
      imagePath,
      imageLocalPath,
      memo,
      createdAt,
      updatedAt);

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      __$$TicketImplCopyWithImpl<_$TicketImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TicketImplToJson(
      this,
    );
  }
}

abstract class _Ticket implements Ticket {
  const factory _Ticket(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          final TicketAcquisition acquisitionStatus,
          final TicketPayment paymentStatus,
          final TicketIssuance issuanceStatus,
          final String? seat,
          final String? entryNumber,
          final String? gate,
          final String? url,
          final String? imagePath,
          final String? imageLocalPath,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$TicketImpl;

  factory _Ticket.fromJson(Map<String, dynamic> json) = _$TicketImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  TicketAcquisition get acquisitionStatus;
  @override
  TicketPayment get paymentStatus;
  @override
  TicketIssuance get issuanceStatus;
  @override
  String? get seat;
  @override
  String? get entryNumber;
  @override
  String? get gate;
  @override
  String? get url;

  /// Supabase Storage 上のオブジェクトパス（署名URLで認可付き取得する）。
  @override
  String? get imagePath;

  /// 端末内のチケット画像参照（同期対象外。アップロードは後続範囲）。
  @override
  String? get imageLocalPath;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of Ticket
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TicketImplCopyWith<_$TicketImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Transport _$TransportFromJson(Map<String, dynamic> json) {
  return _Transport.fromJson(json);
}

/// @nodoc
mixin _$Transport {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  TransportDirection get direction => throw _privateConstructorUsedError;
  String? get method => throw _privateConstructorUsedError;
  String? get fromPlace => throw _privateConstructorUsedError;
  String? get toPlace => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get departAt => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get arriveAt => throw _privateConstructorUsedError;
  String? get reservationNumber => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Transport to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransportCopyWith<Transport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransportCopyWith<$Res> {
  factory $TransportCopyWith(Transport value, $Res Function(Transport) then) =
      _$TransportCopyWithImpl<$Res, Transport>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      TransportDirection direction,
      String? method,
      String? fromPlace,
      String? toPlace,
      @NullableUtcDateTimeConverter() DateTime? departAt,
      @NullableUtcDateTimeConverter() DateTime? arriveAt,
      String? reservationNumber,
      String? url,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$TransportCopyWithImpl<$Res, $Val extends Transport>
    implements $TransportCopyWith<$Res> {
  _$TransportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? direction = null,
    Object? method = freezed,
    Object? fromPlace = freezed,
    Object? toPlace = freezed,
    Object? departAt = freezed,
    Object? arriveAt = freezed,
    Object? reservationNumber = freezed,
    Object? url = freezed,
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
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as TransportDirection,
      method: freezed == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String?,
      fromPlace: freezed == fromPlace
          ? _value.fromPlace
          : fromPlace // ignore: cast_nullable_to_non_nullable
              as String?,
      toPlace: freezed == toPlace
          ? _value.toPlace
          : toPlace // ignore: cast_nullable_to_non_nullable
              as String?,
      departAt: freezed == departAt
          ? _value.departAt
          : departAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      arriveAt: freezed == arriveAt
          ? _value.arriveAt
          : arriveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reservationNumber: freezed == reservationNumber
          ? _value.reservationNumber
          : reservationNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
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
abstract class _$$TransportImplCopyWith<$Res>
    implements $TransportCopyWith<$Res> {
  factory _$$TransportImplCopyWith(
          _$TransportImpl value, $Res Function(_$TransportImpl) then) =
      __$$TransportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      TransportDirection direction,
      String? method,
      String? fromPlace,
      String? toPlace,
      @NullableUtcDateTimeConverter() DateTime? departAt,
      @NullableUtcDateTimeConverter() DateTime? arriveAt,
      String? reservationNumber,
      String? url,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$TransportImplCopyWithImpl<$Res>
    extends _$TransportCopyWithImpl<$Res, _$TransportImpl>
    implements _$$TransportImplCopyWith<$Res> {
  __$$TransportImplCopyWithImpl(
      _$TransportImpl _value, $Res Function(_$TransportImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? direction = null,
    Object? method = freezed,
    Object? fromPlace = freezed,
    Object? toPlace = freezed,
    Object? departAt = freezed,
    Object? arriveAt = freezed,
    Object? reservationNumber = freezed,
    Object? url = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$TransportImpl(
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
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as TransportDirection,
      method: freezed == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String?,
      fromPlace: freezed == fromPlace
          ? _value.fromPlace
          : fromPlace // ignore: cast_nullable_to_non_nullable
              as String?,
      toPlace: freezed == toPlace
          ? _value.toPlace
          : toPlace // ignore: cast_nullable_to_non_nullable
              as String?,
      departAt: freezed == departAt
          ? _value.departAt
          : departAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      arriveAt: freezed == arriveAt
          ? _value.arriveAt
          : arriveAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reservationNumber: freezed == reservationNumber
          ? _value.reservationNumber
          : reservationNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
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
class _$TransportImpl implements _Transport {
  const _$TransportImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.direction = TransportDirection.outbound,
      this.method,
      this.fromPlace,
      this.toPlace,
      @NullableUtcDateTimeConverter() this.departAt,
      @NullableUtcDateTimeConverter() this.arriveAt,
      this.reservationNumber,
      this.url,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$TransportImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransportImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  @JsonKey()
  final TransportDirection direction;
  @override
  final String? method;
  @override
  final String? fromPlace;
  @override
  final String? toPlace;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? departAt;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? arriveAt;
  @override
  final String? reservationNumber;
  @override
  final String? url;
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
    return 'Transport(id: $id, genbaId: $genbaId, ownerId: $ownerId, direction: $direction, method: $method, fromPlace: $fromPlace, toPlace: $toPlace, departAt: $departAt, arriveAt: $arriveAt, reservationNumber: $reservationNumber, url: $url, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransportImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.fromPlace, fromPlace) ||
                other.fromPlace == fromPlace) &&
            (identical(other.toPlace, toPlace) || other.toPlace == toPlace) &&
            (identical(other.departAt, departAt) ||
                other.departAt == departAt) &&
            (identical(other.arriveAt, arriveAt) ||
                other.arriveAt == arriveAt) &&
            (identical(other.reservationNumber, reservationNumber) ||
                other.reservationNumber == reservationNumber) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.memo, memo) || other.memo == memo) &&
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
      direction,
      method,
      fromPlace,
      toPlace,
      departAt,
      arriveAt,
      reservationNumber,
      url,
      memo,
      createdAt,
      updatedAt);

  /// Create a copy of Transport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransportImplCopyWith<_$TransportImpl> get copyWith =>
      __$$TransportImplCopyWithImpl<_$TransportImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransportImplToJson(
      this,
    );
  }
}

abstract class _Transport implements Transport {
  const factory _Transport(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          final TransportDirection direction,
          final String? method,
          final String? fromPlace,
          final String? toPlace,
          @NullableUtcDateTimeConverter() final DateTime? departAt,
          @NullableUtcDateTimeConverter() final DateTime? arriveAt,
          final String? reservationNumber,
          final String? url,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$TransportImpl;

  factory _Transport.fromJson(Map<String, dynamic> json) =
      _$TransportImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  TransportDirection get direction;
  @override
  String? get method;
  @override
  String? get fromPlace;
  @override
  String? get toPlace;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get departAt;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get arriveAt;
  @override
  String? get reservationNumber;
  @override
  String? get url;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of Transport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransportImplCopyWith<_$TransportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Lodging _$LodgingFromJson(Map<String, dynamic> json) {
  return _Lodging.fromJson(json);
}

/// @nodoc
mixin _$Lodging {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  @NullableDateOnlyConverter()
  DateTime? get checkinDate => throw _privateConstructorUsedError;
  @NullableDateOnlyConverter()
  DateTime? get checkoutDate => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get reservationNumber => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Lodging to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LodgingCopyWith<Lodging> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LodgingCopyWith<$Res> {
  factory $LodgingCopyWith(Lodging value, $Res Function(Lodging) then) =
      _$LodgingCopyWithImpl<$Res, Lodging>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String? name,
      @NullableDateOnlyConverter() DateTime? checkinDate,
      @NullableDateOnlyConverter() DateTime? checkoutDate,
      String? address,
      String? reservationNumber,
      String? url,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$LodgingCopyWithImpl<$Res, $Val extends Lodging>
    implements $LodgingCopyWith<$Res> {
  _$LodgingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = freezed,
    Object? checkinDate = freezed,
    Object? checkoutDate = freezed,
    Object? address = freezed,
    Object? reservationNumber = freezed,
    Object? url = freezed,
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
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      checkinDate: freezed == checkinDate
          ? _value.checkinDate
          : checkinDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkoutDate: freezed == checkoutDate
          ? _value.checkoutDate
          : checkoutDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationNumber: freezed == reservationNumber
          ? _value.reservationNumber
          : reservationNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
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
abstract class _$$LodgingImplCopyWith<$Res> implements $LodgingCopyWith<$Res> {
  factory _$$LodgingImplCopyWith(
          _$LodgingImpl value, $Res Function(_$LodgingImpl) then) =
      __$$LodgingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String? name,
      @NullableDateOnlyConverter() DateTime? checkinDate,
      @NullableDateOnlyConverter() DateTime? checkoutDate,
      String? address,
      String? reservationNumber,
      String? url,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$LodgingImplCopyWithImpl<$Res>
    extends _$LodgingCopyWithImpl<$Res, _$LodgingImpl>
    implements _$$LodgingImplCopyWith<$Res> {
  __$$LodgingImplCopyWithImpl(
      _$LodgingImpl _value, $Res Function(_$LodgingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = freezed,
    Object? checkinDate = freezed,
    Object? checkoutDate = freezed,
    Object? address = freezed,
    Object? reservationNumber = freezed,
    Object? url = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$LodgingImpl(
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
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      checkinDate: freezed == checkinDate
          ? _value.checkinDate
          : checkinDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkoutDate: freezed == checkoutDate
          ? _value.checkoutDate
          : checkoutDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationNumber: freezed == reservationNumber
          ? _value.reservationNumber
          : reservationNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
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
class _$LodgingImpl implements _Lodging {
  const _$LodgingImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.name,
      @NullableDateOnlyConverter() this.checkinDate,
      @NullableDateOnlyConverter() this.checkoutDate,
      this.address,
      this.reservationNumber,
      this.url,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$LodgingImpl.fromJson(Map<String, dynamic> json) =>
      _$$LodgingImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final String? name;
  @override
  @NullableDateOnlyConverter()
  final DateTime? checkinDate;
  @override
  @NullableDateOnlyConverter()
  final DateTime? checkoutDate;
  @override
  final String? address;
  @override
  final String? reservationNumber;
  @override
  final String? url;
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
    return 'Lodging(id: $id, genbaId: $genbaId, ownerId: $ownerId, name: $name, checkinDate: $checkinDate, checkoutDate: $checkoutDate, address: $address, reservationNumber: $reservationNumber, url: $url, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LodgingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.checkinDate, checkinDate) ||
                other.checkinDate == checkinDate) &&
            (identical(other.checkoutDate, checkoutDate) ||
                other.checkoutDate == checkoutDate) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.reservationNumber, reservationNumber) ||
                other.reservationNumber == reservationNumber) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.memo, memo) || other.memo == memo) &&
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
      name,
      checkinDate,
      checkoutDate,
      address,
      reservationNumber,
      url,
      memo,
      createdAt,
      updatedAt);

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LodgingImplCopyWith<_$LodgingImpl> get copyWith =>
      __$$LodgingImplCopyWithImpl<_$LodgingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LodgingImplToJson(
      this,
    );
  }
}

abstract class _Lodging implements Lodging {
  const factory _Lodging(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          final String? name,
          @NullableDateOnlyConverter() final DateTime? checkinDate,
          @NullableDateOnlyConverter() final DateTime? checkoutDate,
          final String? address,
          final String? reservationNumber,
          final String? url,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$LodgingImpl;

  factory _Lodging.fromJson(Map<String, dynamic> json) = _$LodgingImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  String? get name;
  @override
  @NullableDateOnlyConverter()
  DateTime? get checkinDate;
  @override
  @NullableDateOnlyConverter()
  DateTime? get checkoutDate;
  @override
  String? get address;
  @override
  String? get reservationNumber;
  @override
  String? get url;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LodgingImplCopyWith<_$LodgingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GenbaTodo _$GenbaTodoFromJson(Map<String, dynamic> json) {
  return _GenbaTodo.fromJson(json);
}

/// @nodoc
mixin _$GenbaTodo {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @NullableDateOnlyConverter()
  DateTime? get dueDate => throw _privateConstructorUsedError;
  bool get isDone => throw _privateConstructorUsedError;
  String? get assignee => throw _privateConstructorUsedError;
  TodoPriority get priority => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GenbaTodo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GenbaTodo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenbaTodoCopyWith<GenbaTodo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenbaTodoCopyWith<$Res> {
  factory $GenbaTodoCopyWith(GenbaTodo value, $Res Function(GenbaTodo) then) =
      _$GenbaTodoCopyWithImpl<$Res, GenbaTodo>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String name,
      @NullableDateOnlyConverter() DateTime? dueDate,
      bool isDone,
      String? assignee,
      TodoPriority priority,
      String? memo,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$GenbaTodoCopyWithImpl<$Res, $Val extends GenbaTodo>
    implements $GenbaTodoCopyWith<$Res> {
  _$GenbaTodoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GenbaTodo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? dueDate = freezed,
    Object? isDone = null,
    Object? assignee = freezed,
    Object? priority = null,
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
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDone: null == isDone
          ? _value.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
      assignee: freezed == assignee
          ? _value.assignee
          : assignee // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TodoPriority,
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
abstract class _$$GenbaTodoImplCopyWith<$Res>
    implements $GenbaTodoCopyWith<$Res> {
  factory _$$GenbaTodoImplCopyWith(
          _$GenbaTodoImpl value, $Res Function(_$GenbaTodoImpl) then) =
      __$$GenbaTodoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      String name,
      @NullableDateOnlyConverter() DateTime? dueDate,
      bool isDone,
      String? assignee,
      TodoPriority priority,
      String? memo,
      int sortOrder,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$GenbaTodoImplCopyWithImpl<$Res>
    extends _$GenbaTodoCopyWithImpl<$Res, _$GenbaTodoImpl>
    implements _$$GenbaTodoImplCopyWith<$Res> {
  __$$GenbaTodoImplCopyWithImpl(
      _$GenbaTodoImpl _value, $Res Function(_$GenbaTodoImpl) _then)
      : super(_value, _then);

  /// Create a copy of GenbaTodo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? name = null,
    Object? dueDate = freezed,
    Object? isDone = null,
    Object? assignee = freezed,
    Object? priority = null,
    Object? memo = freezed,
    Object? sortOrder = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$GenbaTodoImpl(
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
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isDone: null == isDone
          ? _value.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
      assignee: freezed == assignee
          ? _value.assignee
          : assignee // ignore: cast_nullable_to_non_nullable
              as String?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as TodoPriority,
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
class _$GenbaTodoImpl implements _GenbaTodo {
  const _$GenbaTodoImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.name,
      @NullableDateOnlyConverter() this.dueDate,
      this.isDone = false,
      this.assignee,
      this.priority = TodoPriority.normal,
      this.memo,
      this.sortOrder = 0,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$GenbaTodoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GenbaTodoImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  @NullableDateOnlyConverter()
  final DateTime? dueDate;
  @override
  @JsonKey()
  final bool isDone;
  @override
  final String? assignee;
  @override
  @JsonKey()
  final TodoPriority priority;
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
    return 'GenbaTodo(id: $id, genbaId: $genbaId, ownerId: $ownerId, name: $name, dueDate: $dueDate, isDone: $isDone, assignee: $assignee, priority: $priority, memo: $memo, sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenbaTodoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.isDone, isDone) || other.isDone == isDone) &&
            (identical(other.assignee, assignee) ||
                other.assignee == assignee) &&
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
  int get hashCode => Object.hash(
      runtimeType,
      id,
      genbaId,
      ownerId,
      name,
      dueDate,
      isDone,
      assignee,
      priority,
      memo,
      sortOrder,
      createdAt,
      updatedAt);

  /// Create a copy of GenbaTodo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenbaTodoImplCopyWith<_$GenbaTodoImpl> get copyWith =>
      __$$GenbaTodoImplCopyWithImpl<_$GenbaTodoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GenbaTodoImplToJson(
      this,
    );
  }
}

abstract class _GenbaTodo implements GenbaTodo {
  const factory _GenbaTodo(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          required final String name,
          @NullableDateOnlyConverter() final DateTime? dueDate,
          final bool isDone,
          final String? assignee,
          final TodoPriority priority,
          final String? memo,
          final int sortOrder,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$GenbaTodoImpl;

  factory _GenbaTodo.fromJson(Map<String, dynamic> json) =
      _$GenbaTodoImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  @NullableDateOnlyConverter()
  DateTime? get dueDate;
  @override
  bool get isDone;
  @override
  String? get assignee;
  @override
  TodoPriority get priority;
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

  /// Create a copy of GenbaTodo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenbaTodoImplCopyWith<_$GenbaTodoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GenbaMemo _$GenbaMemoFromJson(Map<String, dynamic> json) {
  return _GenbaMemo.fromJson(json);
}

/// @nodoc
mixin _$GenbaMemo {
  String get id => throw _privateConstructorUsedError;
  String get genbaId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  MemoCategory get category => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GenbaMemo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GenbaMemo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenbaMemoCopyWith<GenbaMemo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenbaMemoCopyWith<$Res> {
  factory $GenbaMemoCopyWith(GenbaMemo value, $Res Function(GenbaMemo) then) =
      _$GenbaMemoCopyWithImpl<$Res, GenbaMemo>;
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      MemoCategory category,
      String body,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$GenbaMemoCopyWithImpl<$Res, $Val extends GenbaMemo>
    implements $GenbaMemoCopyWith<$Res> {
  _$GenbaMemoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GenbaMemo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? category = null,
    Object? body = null,
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
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as MemoCategory,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$GenbaMemoImplCopyWith<$Res>
    implements $GenbaMemoCopyWith<$Res> {
  factory _$$GenbaMemoImplCopyWith(
          _$GenbaMemoImpl value, $Res Function(_$GenbaMemoImpl) then) =
      __$$GenbaMemoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String genbaId,
      String ownerId,
      MemoCategory category,
      String body,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$GenbaMemoImplCopyWithImpl<$Res>
    extends _$GenbaMemoCopyWithImpl<$Res, _$GenbaMemoImpl>
    implements _$$GenbaMemoImplCopyWith<$Res> {
  __$$GenbaMemoImplCopyWithImpl(
      _$GenbaMemoImpl _value, $Res Function(_$GenbaMemoImpl) _then)
      : super(_value, _then);

  /// Create a copy of GenbaMemo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? genbaId = null,
    Object? ownerId = null,
    Object? category = null,
    Object? body = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$GenbaMemoImpl(
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
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as MemoCategory,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
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
class _$GenbaMemoImpl implements _GenbaMemo {
  const _$GenbaMemoImpl(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.category,
      this.body = '',
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$GenbaMemoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GenbaMemoImplFromJson(json);

  @override
  final String id;
  @override
  final String genbaId;
  @override
  final String ownerId;
  @override
  final MemoCategory category;
  @override
  @JsonKey()
  final String body;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'GenbaMemo(id: $id, genbaId: $genbaId, ownerId: $ownerId, category: $category, body: $body, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenbaMemoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.genbaId, genbaId) || other.genbaId == genbaId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, genbaId, ownerId, category, body, createdAt, updatedAt);

  /// Create a copy of GenbaMemo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenbaMemoImplCopyWith<_$GenbaMemoImpl> get copyWith =>
      __$$GenbaMemoImplCopyWithImpl<_$GenbaMemoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GenbaMemoImplToJson(
      this,
    );
  }
}

abstract class _GenbaMemo implements GenbaMemo {
  const factory _GenbaMemo(
          {required final String id,
          required final String genbaId,
          required final String ownerId,
          required final MemoCategory category,
          final String body,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$GenbaMemoImpl;

  factory _GenbaMemo.fromJson(Map<String, dynamic> json) =
      _$GenbaMemoImpl.fromJson;

  @override
  String get id;
  @override
  String get genbaId;
  @override
  String get ownerId;
  @override
  MemoCategory get category;
  @override
  String get body;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of GenbaMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenbaMemoImplCopyWith<_$GenbaMemoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GenbaAggregate {
  Genba get genba => throw _privateConstructorUsedError;
  List<Ticket> get tickets => throw _privateConstructorUsedError;
  List<Transport> get transports => throw _privateConstructorUsedError;
  List<Lodging> get lodgings => throw _privateConstructorUsedError;
  List<GenbaTodo> get todos => throw _privateConstructorUsedError;
  List<GenbaMemo> get memos => throw _privateConstructorUsedError;

  /// Create a copy of GenbaAggregate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GenbaAggregateCopyWith<GenbaAggregate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenbaAggregateCopyWith<$Res> {
  factory $GenbaAggregateCopyWith(
          GenbaAggregate value, $Res Function(GenbaAggregate) then) =
      _$GenbaAggregateCopyWithImpl<$Res, GenbaAggregate>;
  @useResult
  $Res call(
      {Genba genba,
      List<Ticket> tickets,
      List<Transport> transports,
      List<Lodging> lodgings,
      List<GenbaTodo> todos,
      List<GenbaMemo> memos});

  $GenbaCopyWith<$Res> get genba;
}

/// @nodoc
class _$GenbaAggregateCopyWithImpl<$Res, $Val extends GenbaAggregate>
    implements $GenbaAggregateCopyWith<$Res> {
  _$GenbaAggregateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GenbaAggregate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? genba = null,
    Object? tickets = null,
    Object? transports = null,
    Object? lodgings = null,
    Object? todos = null,
    Object? memos = null,
  }) {
    return _then(_value.copyWith(
      genba: null == genba
          ? _value.genba
          : genba // ignore: cast_nullable_to_non_nullable
              as Genba,
      tickets: null == tickets
          ? _value.tickets
          : tickets // ignore: cast_nullable_to_non_nullable
              as List<Ticket>,
      transports: null == transports
          ? _value.transports
          : transports // ignore: cast_nullable_to_non_nullable
              as List<Transport>,
      lodgings: null == lodgings
          ? _value.lodgings
          : lodgings // ignore: cast_nullable_to_non_nullable
              as List<Lodging>,
      todos: null == todos
          ? _value.todos
          : todos // ignore: cast_nullable_to_non_nullable
              as List<GenbaTodo>,
      memos: null == memos
          ? _value.memos
          : memos // ignore: cast_nullable_to_non_nullable
              as List<GenbaMemo>,
    ) as $Val);
  }

  /// Create a copy of GenbaAggregate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GenbaCopyWith<$Res> get genba {
    return $GenbaCopyWith<$Res>(_value.genba, (value) {
      return _then(_value.copyWith(genba: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GenbaAggregateImplCopyWith<$Res>
    implements $GenbaAggregateCopyWith<$Res> {
  factory _$$GenbaAggregateImplCopyWith(_$GenbaAggregateImpl value,
          $Res Function(_$GenbaAggregateImpl) then) =
      __$$GenbaAggregateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Genba genba,
      List<Ticket> tickets,
      List<Transport> transports,
      List<Lodging> lodgings,
      List<GenbaTodo> todos,
      List<GenbaMemo> memos});

  @override
  $GenbaCopyWith<$Res> get genba;
}

/// @nodoc
class __$$GenbaAggregateImplCopyWithImpl<$Res>
    extends _$GenbaAggregateCopyWithImpl<$Res, _$GenbaAggregateImpl>
    implements _$$GenbaAggregateImplCopyWith<$Res> {
  __$$GenbaAggregateImplCopyWithImpl(
      _$GenbaAggregateImpl _value, $Res Function(_$GenbaAggregateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GenbaAggregate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? genba = null,
    Object? tickets = null,
    Object? transports = null,
    Object? lodgings = null,
    Object? todos = null,
    Object? memos = null,
  }) {
    return _then(_$GenbaAggregateImpl(
      genba: null == genba
          ? _value.genba
          : genba // ignore: cast_nullable_to_non_nullable
              as Genba,
      tickets: null == tickets
          ? _value._tickets
          : tickets // ignore: cast_nullable_to_non_nullable
              as List<Ticket>,
      transports: null == transports
          ? _value._transports
          : transports // ignore: cast_nullable_to_non_nullable
              as List<Transport>,
      lodgings: null == lodgings
          ? _value._lodgings
          : lodgings // ignore: cast_nullable_to_non_nullable
              as List<Lodging>,
      todos: null == todos
          ? _value._todos
          : todos // ignore: cast_nullable_to_non_nullable
              as List<GenbaTodo>,
      memos: null == memos
          ? _value._memos
          : memos // ignore: cast_nullable_to_non_nullable
              as List<GenbaMemo>,
    ));
  }
}

/// @nodoc

class _$GenbaAggregateImpl extends _GenbaAggregate {
  const _$GenbaAggregateImpl(
      {required this.genba,
      final List<Ticket> tickets = const <Ticket>[],
      final List<Transport> transports = const <Transport>[],
      final List<Lodging> lodgings = const <Lodging>[],
      final List<GenbaTodo> todos = const <GenbaTodo>[],
      final List<GenbaMemo> memos = const <GenbaMemo>[]})
      : _tickets = tickets,
        _transports = transports,
        _lodgings = lodgings,
        _todos = todos,
        _memos = memos,
        super._();

  @override
  final Genba genba;
  final List<Ticket> _tickets;
  @override
  @JsonKey()
  List<Ticket> get tickets {
    if (_tickets is EqualUnmodifiableListView) return _tickets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tickets);
  }

  final List<Transport> _transports;
  @override
  @JsonKey()
  List<Transport> get transports {
    if (_transports is EqualUnmodifiableListView) return _transports;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transports);
  }

  final List<Lodging> _lodgings;
  @override
  @JsonKey()
  List<Lodging> get lodgings {
    if (_lodgings is EqualUnmodifiableListView) return _lodgings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lodgings);
  }

  final List<GenbaTodo> _todos;
  @override
  @JsonKey()
  List<GenbaTodo> get todos {
    if (_todos is EqualUnmodifiableListView) return _todos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_todos);
  }

  final List<GenbaMemo> _memos;
  @override
  @JsonKey()
  List<GenbaMemo> get memos {
    if (_memos is EqualUnmodifiableListView) return _memos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memos);
  }

  @override
  String toString() {
    return 'GenbaAggregate(genba: $genba, tickets: $tickets, transports: $transports, lodgings: $lodgings, todos: $todos, memos: $memos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenbaAggregateImpl &&
            (identical(other.genba, genba) || other.genba == genba) &&
            const DeepCollectionEquality().equals(other._tickets, _tickets) &&
            const DeepCollectionEquality()
                .equals(other._transports, _transports) &&
            const DeepCollectionEquality().equals(other._lodgings, _lodgings) &&
            const DeepCollectionEquality().equals(other._todos, _todos) &&
            const DeepCollectionEquality().equals(other._memos, _memos));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      genba,
      const DeepCollectionEquality().hash(_tickets),
      const DeepCollectionEquality().hash(_transports),
      const DeepCollectionEquality().hash(_lodgings),
      const DeepCollectionEquality().hash(_todos),
      const DeepCollectionEquality().hash(_memos));

  /// Create a copy of GenbaAggregate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GenbaAggregateImplCopyWith<_$GenbaAggregateImpl> get copyWith =>
      __$$GenbaAggregateImplCopyWithImpl<_$GenbaAggregateImpl>(
          this, _$identity);
}

abstract class _GenbaAggregate extends GenbaAggregate {
  const factory _GenbaAggregate(
      {required final Genba genba,
      final List<Ticket> tickets,
      final List<Transport> transports,
      final List<Lodging> lodgings,
      final List<GenbaTodo> todos,
      final List<GenbaMemo> memos}) = _$GenbaAggregateImpl;
  const _GenbaAggregate._() : super._();

  @override
  Genba get genba;
  @override
  List<Ticket> get tickets;
  @override
  List<Transport> get transports;
  @override
  List<Lodging> get lodgings;
  @override
  List<GenbaTodo> get todos;
  @override
  List<GenbaMemo> get memos;

  /// Create a copy of GenbaAggregate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GenbaAggregateImplCopyWith<_$GenbaAggregateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
