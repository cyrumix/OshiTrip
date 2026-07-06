// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_leg.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItineraryLeg _$ItineraryLegFromJson(Map<String, dynamic> json) {
  return _ItineraryLeg.fromJson(json);
}

/// @nodoc
mixin _$ItineraryLeg {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get originEntryId => throw _privateConstructorUsedError;
  String get destinationEntryId => throw _privateConstructorUsedError;
  ItineraryLegSource get source => throw _privateConstructorUsedError;
  ItineraryTravelMode get travelMode => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get departureAt => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get arrivalAt => throw _privateConstructorUsedError;
  int? get durationMinutes => throw _privateConstructorUsedError;
  int? get distanceMeters => throw _privateConstructorUsedError;
  int? get fareAmountMinor => throw _privateConstructorUsedError;
  String? get fareCurrency => throw _privateConstructorUsedError;
  String? get routeSummary => throw _privateConstructorUsedError;

  /// 永続する概算経路値（所要時間・距離・運賃・経路概要）の出典・権利根拠。
  /// 既定はユーザー入力。Google 応答の無許可キャッシュではなく、手動または
  /// 保存権限を持つ情報源の概算値であることを表す（§12.5, D-180）。
  ItineraryValueOrigin get valueOrigin => throw _privateConstructorUsedError;
  String? get rightsBasis => throw _privateConstructorUsedError;

  /// 概算経路の代表時刻帯（例: 平日朝ラッシュ）と最終確認日時（§12.5）。
  String? get representativeTimeBucket => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get lastVerifiedAt => throw _privateConstructorUsedError;

  /// 公共交通の路線・停留所・乗換ステップ（Phase 1では不透明なJSON文字列
  /// として保持し、構造化パースは後続Phaseで扱う）。
  String? get transitStepsJson => throw _privateConstructorUsedError;
  String? get encodedPolyline => throw _privateConstructorUsedError;
  String? get googleMapsUrl => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get fetchedAt => throw _privateConstructorUsedError;
  String? get cacheKey => throw _privateConstructorUsedError;
  bool get isStale => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ItineraryLeg to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryLeg
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryLegCopyWith<ItineraryLeg> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryLegCopyWith<$Res> {
  factory $ItineraryLegCopyWith(
          ItineraryLeg value, $Res Function(ItineraryLeg) then) =
      _$ItineraryLegCopyWithImpl<$Res, ItineraryLeg>;
  @useResult
  $Res call(
      {String id,
      String planId,
      String ownerId,
      String originEntryId,
      String destinationEntryId,
      ItineraryLegSource source,
      ItineraryTravelMode travelMode,
      @NullableUtcDateTimeConverter() DateTime? departureAt,
      @NullableUtcDateTimeConverter() DateTime? arrivalAt,
      int? durationMinutes,
      int? distanceMeters,
      int? fareAmountMinor,
      String? fareCurrency,
      String? routeSummary,
      ItineraryValueOrigin valueOrigin,
      String? rightsBasis,
      String? representativeTimeBucket,
      @NullableUtcDateTimeConverter() DateTime? lastVerifiedAt,
      String? transitStepsJson,
      String? encodedPolyline,
      String? googleMapsUrl,
      @NullableUtcDateTimeConverter() DateTime? fetchedAt,
      String? cacheKey,
      bool isStale,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$ItineraryLegCopyWithImpl<$Res, $Val extends ItineraryLeg>
    implements $ItineraryLegCopyWith<$Res> {
  _$ItineraryLegCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryLeg
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? ownerId = null,
    Object? originEntryId = null,
    Object? destinationEntryId = null,
    Object? source = null,
    Object? travelMode = null,
    Object? departureAt = freezed,
    Object? arrivalAt = freezed,
    Object? durationMinutes = freezed,
    Object? distanceMeters = freezed,
    Object? fareAmountMinor = freezed,
    Object? fareCurrency = freezed,
    Object? routeSummary = freezed,
    Object? valueOrigin = null,
    Object? rightsBasis = freezed,
    Object? representativeTimeBucket = freezed,
    Object? lastVerifiedAt = freezed,
    Object? transitStepsJson = freezed,
    Object? encodedPolyline = freezed,
    Object? googleMapsUrl = freezed,
    Object? fetchedAt = freezed,
    Object? cacheKey = freezed,
    Object? isStale = null,
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
      originEntryId: null == originEntryId
          ? _value.originEntryId
          : originEntryId // ignore: cast_nullable_to_non_nullable
              as String,
      destinationEntryId: null == destinationEntryId
          ? _value.destinationEntryId
          : destinationEntryId // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ItineraryLegSource,
      travelMode: null == travelMode
          ? _value.travelMode
          : travelMode // ignore: cast_nullable_to_non_nullable
              as ItineraryTravelMode,
      departureAt: freezed == departureAt
          ? _value.departureAt
          : departureAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      arrivalAt: freezed == arrivalAt
          ? _value.arrivalAt
          : arrivalAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationMinutes: freezed == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      distanceMeters: freezed == distanceMeters
          ? _value.distanceMeters
          : distanceMeters // ignore: cast_nullable_to_non_nullable
              as int?,
      fareAmountMinor: freezed == fareAmountMinor
          ? _value.fareAmountMinor
          : fareAmountMinor // ignore: cast_nullable_to_non_nullable
              as int?,
      fareCurrency: freezed == fareCurrency
          ? _value.fareCurrency
          : fareCurrency // ignore: cast_nullable_to_non_nullable
              as String?,
      routeSummary: freezed == routeSummary
          ? _value.routeSummary
          : routeSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      valueOrigin: null == valueOrigin
          ? _value.valueOrigin
          : valueOrigin // ignore: cast_nullable_to_non_nullable
              as ItineraryValueOrigin,
      rightsBasis: freezed == rightsBasis
          ? _value.rightsBasis
          : rightsBasis // ignore: cast_nullable_to_non_nullable
              as String?,
      representativeTimeBucket: freezed == representativeTimeBucket
          ? _value.representativeTimeBucket
          : representativeTimeBucket // ignore: cast_nullable_to_non_nullable
              as String?,
      lastVerifiedAt: freezed == lastVerifiedAt
          ? _value.lastVerifiedAt
          : lastVerifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      transitStepsJson: freezed == transitStepsJson
          ? _value.transitStepsJson
          : transitStepsJson // ignore: cast_nullable_to_non_nullable
              as String?,
      encodedPolyline: freezed == encodedPolyline
          ? _value.encodedPolyline
          : encodedPolyline // ignore: cast_nullable_to_non_nullable
              as String?,
      googleMapsUrl: freezed == googleMapsUrl
          ? _value.googleMapsUrl
          : googleMapsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fetchedAt: freezed == fetchedAt
          ? _value.fetchedAt
          : fetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cacheKey: freezed == cacheKey
          ? _value.cacheKey
          : cacheKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isStale: null == isStale
          ? _value.isStale
          : isStale // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ItineraryLegImplCopyWith<$Res>
    implements $ItineraryLegCopyWith<$Res> {
  factory _$$ItineraryLegImplCopyWith(
          _$ItineraryLegImpl value, $Res Function(_$ItineraryLegImpl) then) =
      __$$ItineraryLegImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      String ownerId,
      String originEntryId,
      String destinationEntryId,
      ItineraryLegSource source,
      ItineraryTravelMode travelMode,
      @NullableUtcDateTimeConverter() DateTime? departureAt,
      @NullableUtcDateTimeConverter() DateTime? arrivalAt,
      int? durationMinutes,
      int? distanceMeters,
      int? fareAmountMinor,
      String? fareCurrency,
      String? routeSummary,
      ItineraryValueOrigin valueOrigin,
      String? rightsBasis,
      String? representativeTimeBucket,
      @NullableUtcDateTimeConverter() DateTime? lastVerifiedAt,
      String? transitStepsJson,
      String? encodedPolyline,
      String? googleMapsUrl,
      @NullableUtcDateTimeConverter() DateTime? fetchedAt,
      String? cacheKey,
      bool isStale,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$ItineraryLegImplCopyWithImpl<$Res>
    extends _$ItineraryLegCopyWithImpl<$Res, _$ItineraryLegImpl>
    implements _$$ItineraryLegImplCopyWith<$Res> {
  __$$ItineraryLegImplCopyWithImpl(
      _$ItineraryLegImpl _value, $Res Function(_$ItineraryLegImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItineraryLeg
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? ownerId = null,
    Object? originEntryId = null,
    Object? destinationEntryId = null,
    Object? source = null,
    Object? travelMode = null,
    Object? departureAt = freezed,
    Object? arrivalAt = freezed,
    Object? durationMinutes = freezed,
    Object? distanceMeters = freezed,
    Object? fareAmountMinor = freezed,
    Object? fareCurrency = freezed,
    Object? routeSummary = freezed,
    Object? valueOrigin = null,
    Object? rightsBasis = freezed,
    Object? representativeTimeBucket = freezed,
    Object? lastVerifiedAt = freezed,
    Object? transitStepsJson = freezed,
    Object? encodedPolyline = freezed,
    Object? googleMapsUrl = freezed,
    Object? fetchedAt = freezed,
    Object? cacheKey = freezed,
    Object? isStale = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ItineraryLegImpl(
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
      originEntryId: null == originEntryId
          ? _value.originEntryId
          : originEntryId // ignore: cast_nullable_to_non_nullable
              as String,
      destinationEntryId: null == destinationEntryId
          ? _value.destinationEntryId
          : destinationEntryId // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ItineraryLegSource,
      travelMode: null == travelMode
          ? _value.travelMode
          : travelMode // ignore: cast_nullable_to_non_nullable
              as ItineraryTravelMode,
      departureAt: freezed == departureAt
          ? _value.departureAt
          : departureAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      arrivalAt: freezed == arrivalAt
          ? _value.arrivalAt
          : arrivalAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationMinutes: freezed == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      distanceMeters: freezed == distanceMeters
          ? _value.distanceMeters
          : distanceMeters // ignore: cast_nullable_to_non_nullable
              as int?,
      fareAmountMinor: freezed == fareAmountMinor
          ? _value.fareAmountMinor
          : fareAmountMinor // ignore: cast_nullable_to_non_nullable
              as int?,
      fareCurrency: freezed == fareCurrency
          ? _value.fareCurrency
          : fareCurrency // ignore: cast_nullable_to_non_nullable
              as String?,
      routeSummary: freezed == routeSummary
          ? _value.routeSummary
          : routeSummary // ignore: cast_nullable_to_non_nullable
              as String?,
      valueOrigin: null == valueOrigin
          ? _value.valueOrigin
          : valueOrigin // ignore: cast_nullable_to_non_nullable
              as ItineraryValueOrigin,
      rightsBasis: freezed == rightsBasis
          ? _value.rightsBasis
          : rightsBasis // ignore: cast_nullable_to_non_nullable
              as String?,
      representativeTimeBucket: freezed == representativeTimeBucket
          ? _value.representativeTimeBucket
          : representativeTimeBucket // ignore: cast_nullable_to_non_nullable
              as String?,
      lastVerifiedAt: freezed == lastVerifiedAt
          ? _value.lastVerifiedAt
          : lastVerifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      transitStepsJson: freezed == transitStepsJson
          ? _value.transitStepsJson
          : transitStepsJson // ignore: cast_nullable_to_non_nullable
              as String?,
      encodedPolyline: freezed == encodedPolyline
          ? _value.encodedPolyline
          : encodedPolyline // ignore: cast_nullable_to_non_nullable
              as String?,
      googleMapsUrl: freezed == googleMapsUrl
          ? _value.googleMapsUrl
          : googleMapsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      fetchedAt: freezed == fetchedAt
          ? _value.fetchedAt
          : fetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      cacheKey: freezed == cacheKey
          ? _value.cacheKey
          : cacheKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isStale: null == isStale
          ? _value.isStale
          : isStale // ignore: cast_nullable_to_non_nullable
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
class _$ItineraryLegImpl implements _ItineraryLeg {
  const _$ItineraryLegImpl(
      {required this.id,
      required this.planId,
      required this.ownerId,
      required this.originEntryId,
      required this.destinationEntryId,
      this.source = ItineraryLegSource.manual,
      this.travelMode = ItineraryTravelMode.other,
      @NullableUtcDateTimeConverter() this.departureAt,
      @NullableUtcDateTimeConverter() this.arrivalAt,
      this.durationMinutes,
      this.distanceMeters,
      this.fareAmountMinor,
      this.fareCurrency,
      this.routeSummary,
      this.valueOrigin = ItineraryValueOrigin.userProvided,
      this.rightsBasis,
      this.representativeTimeBucket,
      @NullableUtcDateTimeConverter() this.lastVerifiedAt,
      this.transitStepsJson,
      this.encodedPolyline,
      this.googleMapsUrl,
      @NullableUtcDateTimeConverter() this.fetchedAt,
      this.cacheKey,
      this.isStale = false,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$ItineraryLegImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryLegImplFromJson(json);

  @override
  final String id;
  @override
  final String planId;
  @override
  final String ownerId;
  @override
  final String originEntryId;
  @override
  final String destinationEntryId;
  @override
  @JsonKey()
  final ItineraryLegSource source;
  @override
  @JsonKey()
  final ItineraryTravelMode travelMode;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? departureAt;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? arrivalAt;
  @override
  final int? durationMinutes;
  @override
  final int? distanceMeters;
  @override
  final int? fareAmountMinor;
  @override
  final String? fareCurrency;
  @override
  final String? routeSummary;

  /// 永続する概算経路値（所要時間・距離・運賃・経路概要）の出典・権利根拠。
  /// 既定はユーザー入力。Google 応答の無許可キャッシュではなく、手動または
  /// 保存権限を持つ情報源の概算値であることを表す（§12.5, D-180）。
  @override
  @JsonKey()
  final ItineraryValueOrigin valueOrigin;
  @override
  final String? rightsBasis;

  /// 概算経路の代表時刻帯（例: 平日朝ラッシュ）と最終確認日時（§12.5）。
  @override
  final String? representativeTimeBucket;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? lastVerifiedAt;

  /// 公共交通の路線・停留所・乗換ステップ（Phase 1では不透明なJSON文字列
  /// として保持し、構造化パースは後続Phaseで扱う）。
  @override
  final String? transitStepsJson;
  @override
  final String? encodedPolyline;
  @override
  final String? googleMapsUrl;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? fetchedAt;
  @override
  final String? cacheKey;
  @override
  @JsonKey()
  final bool isStale;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAt;
  @override
  @UtcDateTimeConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ItineraryLeg(id: $id, planId: $planId, ownerId: $ownerId, originEntryId: $originEntryId, destinationEntryId: $destinationEntryId, source: $source, travelMode: $travelMode, departureAt: $departureAt, arrivalAt: $arrivalAt, durationMinutes: $durationMinutes, distanceMeters: $distanceMeters, fareAmountMinor: $fareAmountMinor, fareCurrency: $fareCurrency, routeSummary: $routeSummary, valueOrigin: $valueOrigin, rightsBasis: $rightsBasis, representativeTimeBucket: $representativeTimeBucket, lastVerifiedAt: $lastVerifiedAt, transitStepsJson: $transitStepsJson, encodedPolyline: $encodedPolyline, googleMapsUrl: $googleMapsUrl, fetchedAt: $fetchedAt, cacheKey: $cacheKey, isStale: $isStale, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryLegImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.originEntryId, originEntryId) ||
                other.originEntryId == originEntryId) &&
            (identical(other.destinationEntryId, destinationEntryId) ||
                other.destinationEntryId == destinationEntryId) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.travelMode, travelMode) ||
                other.travelMode == travelMode) &&
            (identical(other.departureAt, departureAt) ||
                other.departureAt == departureAt) &&
            (identical(other.arrivalAt, arrivalAt) ||
                other.arrivalAt == arrivalAt) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.distanceMeters, distanceMeters) ||
                other.distanceMeters == distanceMeters) &&
            (identical(other.fareAmountMinor, fareAmountMinor) ||
                other.fareAmountMinor == fareAmountMinor) &&
            (identical(other.fareCurrency, fareCurrency) ||
                other.fareCurrency == fareCurrency) &&
            (identical(other.routeSummary, routeSummary) ||
                other.routeSummary == routeSummary) &&
            (identical(other.valueOrigin, valueOrigin) ||
                other.valueOrigin == valueOrigin) &&
            (identical(other.rightsBasis, rightsBasis) ||
                other.rightsBasis == rightsBasis) &&
            (identical(
                    other.representativeTimeBucket, representativeTimeBucket) ||
                other.representativeTimeBucket == representativeTimeBucket) &&
            (identical(other.lastVerifiedAt, lastVerifiedAt) ||
                other.lastVerifiedAt == lastVerifiedAt) &&
            (identical(other.transitStepsJson, transitStepsJson) ||
                other.transitStepsJson == transitStepsJson) &&
            (identical(other.encodedPolyline, encodedPolyline) ||
                other.encodedPolyline == encodedPolyline) &&
            (identical(other.googleMapsUrl, googleMapsUrl) ||
                other.googleMapsUrl == googleMapsUrl) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt) &&
            (identical(other.cacheKey, cacheKey) ||
                other.cacheKey == cacheKey) &&
            (identical(other.isStale, isStale) || other.isStale == isStale) &&
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
        planId,
        ownerId,
        originEntryId,
        destinationEntryId,
        source,
        travelMode,
        departureAt,
        arrivalAt,
        durationMinutes,
        distanceMeters,
        fareAmountMinor,
        fareCurrency,
        routeSummary,
        valueOrigin,
        rightsBasis,
        representativeTimeBucket,
        lastVerifiedAt,
        transitStepsJson,
        encodedPolyline,
        googleMapsUrl,
        fetchedAt,
        cacheKey,
        isStale,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of ItineraryLeg
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryLegImplCopyWith<_$ItineraryLegImpl> get copyWith =>
      __$$ItineraryLegImplCopyWithImpl<_$ItineraryLegImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryLegImplToJson(
      this,
    );
  }
}

abstract class _ItineraryLeg implements ItineraryLeg {
  const factory _ItineraryLeg(
          {required final String id,
          required final String planId,
          required final String ownerId,
          required final String originEntryId,
          required final String destinationEntryId,
          final ItineraryLegSource source,
          final ItineraryTravelMode travelMode,
          @NullableUtcDateTimeConverter() final DateTime? departureAt,
          @NullableUtcDateTimeConverter() final DateTime? arrivalAt,
          final int? durationMinutes,
          final int? distanceMeters,
          final int? fareAmountMinor,
          final String? fareCurrency,
          final String? routeSummary,
          final ItineraryValueOrigin valueOrigin,
          final String? rightsBasis,
          final String? representativeTimeBucket,
          @NullableUtcDateTimeConverter() final DateTime? lastVerifiedAt,
          final String? transitStepsJson,
          final String? encodedPolyline,
          final String? googleMapsUrl,
          @NullableUtcDateTimeConverter() final DateTime? fetchedAt,
          final String? cacheKey,
          final bool isStale,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$ItineraryLegImpl;

  factory _ItineraryLeg.fromJson(Map<String, dynamic> json) =
      _$ItineraryLegImpl.fromJson;

  @override
  String get id;
  @override
  String get planId;
  @override
  String get ownerId;
  @override
  String get originEntryId;
  @override
  String get destinationEntryId;
  @override
  ItineraryLegSource get source;
  @override
  ItineraryTravelMode get travelMode;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get departureAt;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get arrivalAt;
  @override
  int? get durationMinutes;
  @override
  int? get distanceMeters;
  @override
  int? get fareAmountMinor;
  @override
  String? get fareCurrency;
  @override
  String? get routeSummary;

  /// 永続する概算経路値（所要時間・距離・運賃・経路概要）の出典・権利根拠。
  /// 既定はユーザー入力。Google 応答の無許可キャッシュではなく、手動または
  /// 保存権限を持つ情報源の概算値であることを表す（§12.5, D-180）。
  @override
  ItineraryValueOrigin get valueOrigin;
  @override
  String? get rightsBasis;

  /// 概算経路の代表時刻帯（例: 平日朝ラッシュ）と最終確認日時（§12.5）。
  @override
  String? get representativeTimeBucket;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get lastVerifiedAt;

  /// 公共交通の路線・停留所・乗換ステップ（Phase 1では不透明なJSON文字列
  /// として保持し、構造化パースは後続Phaseで扱う）。
  @override
  String? get transitStepsJson;
  @override
  String? get encodedPolyline;
  @override
  String? get googleMapsUrl;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get fetchedAt;
  @override
  String? get cacheKey;
  @override
  bool get isStale;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of ItineraryLeg
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryLegImplCopyWith<_$ItineraryLegImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
