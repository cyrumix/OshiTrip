// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_spot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItinerarySpot _$ItinerarySpotFromJson(Map<String, dynamic> json) {
  return _ItinerarySpot.fromJson(json);
}

/// @nodoc
mixin _$ItinerarySpot {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  ItinerarySpotSource get source => throw _privateConstructorUsedError;

  /// 永続保存できる唯一の Google 識別子（重複候補の照合キー。§4.3/§12.2）。
  String? get googlePlaceId => throw _privateConstructorUsedError;

  /// 施設名（必須、前後空白除去・空文字不可は入力側/バリデーションで保証）。
  String get name => throw _privateConstructorUsedError;
  ItinerarySpotCategory get category => throw _privateConstructorUsedError;

  /// 住所（任意、センシティブ情報として扱う。§4.2）。
  String? get address => throw _privateConstructorUsedError;

  /// 永続する名称・住所の出典・権利根拠（既定はユーザー入力, §12.2）。
  ItineraryValueOrigin get dataOrigin => throw _privateConstructorUsedError;
  String? get rightsBasis => throw _privateConstructorUsedError;

  /// 緯度・経度は両方揃ったときだけ座標として有効（§4.2）。手動入力のみ。
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude =>
      throw _privateConstructorUsedError; // ---- 予約領域（MVPでは Google 応答の保存に使わない, §12.2）----------------
  String? get phoneNumber => throw _privateConstructorUsedError;
  String? get websiteUrl => throw _privateConstructorUsedError;
  String? get openingHoursText => throw _privateConstructorUsedError;
  String? get googleMapsUrl => throw _privateConstructorUsedError;
  @NullableUtcDateTimeConverter()
  DateTime? get googleFetchedAt => throw _privateConstructorUsedError;
  String? get googlePhotoName => throw _privateConstructorUsedError;
  String? get googlePhotoAttribution => throw _privateConstructorUsedError;

  /// ユーザー所有画像（既存 ImageStore/Storage 契約と同じ形。§7.1）。
  String? get userImageLocalPath => throw _privateConstructorUsedError;
  String? get userImageStoragePath => throw _privateConstructorUsedError;
  ImageUploadStatus get userImageUploadStatus =>
      throw _privateConstructorUsedError;
  String? get userImageAltText => throw _privateConstructorUsedError;
  String? get memo => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ItinerarySpot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItinerarySpot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItinerarySpotCopyWith<ItinerarySpot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItinerarySpotCopyWith<$Res> {
  factory $ItinerarySpotCopyWith(
          ItinerarySpot value, $Res Function(ItinerarySpot) then) =
      _$ItinerarySpotCopyWithImpl<$Res, ItinerarySpot>;
  @useResult
  $Res call(
      {String id,
      String planId,
      String ownerId,
      ItinerarySpotSource source,
      String? googlePlaceId,
      String name,
      ItinerarySpotCategory category,
      String? address,
      ItineraryValueOrigin dataOrigin,
      String? rightsBasis,
      double? latitude,
      double? longitude,
      String? phoneNumber,
      String? websiteUrl,
      String? openingHoursText,
      String? googleMapsUrl,
      @NullableUtcDateTimeConverter() DateTime? googleFetchedAt,
      String? googlePhotoName,
      String? googlePhotoAttribution,
      String? userImageLocalPath,
      String? userImageStoragePath,
      ImageUploadStatus userImageUploadStatus,
      String? userImageAltText,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$ItinerarySpotCopyWithImpl<$Res, $Val extends ItinerarySpot>
    implements $ItinerarySpotCopyWith<$Res> {
  _$ItinerarySpotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItinerarySpot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? ownerId = null,
    Object? source = null,
    Object? googlePlaceId = freezed,
    Object? name = null,
    Object? category = null,
    Object? address = freezed,
    Object? dataOrigin = null,
    Object? rightsBasis = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? phoneNumber = freezed,
    Object? websiteUrl = freezed,
    Object? openingHoursText = freezed,
    Object? googleMapsUrl = freezed,
    Object? googleFetchedAt = freezed,
    Object? googlePhotoName = freezed,
    Object? googlePhotoAttribution = freezed,
    Object? userImageLocalPath = freezed,
    Object? userImageStoragePath = freezed,
    Object? userImageUploadStatus = null,
    Object? userImageAltText = freezed,
    Object? memo = freezed,
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
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ItinerarySpotSource,
      googlePlaceId: freezed == googlePlaceId
          ? _value.googlePlaceId
          : googlePlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ItinerarySpotCategory,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      dataOrigin: null == dataOrigin
          ? _value.dataOrigin
          : dataOrigin // ignore: cast_nullable_to_non_nullable
              as ItineraryValueOrigin,
      rightsBasis: freezed == rightsBasis
          ? _value.rightsBasis
          : rightsBasis // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrl: freezed == websiteUrl
          ? _value.websiteUrl
          : websiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      openingHoursText: freezed == openingHoursText
          ? _value.openingHoursText
          : openingHoursText // ignore: cast_nullable_to_non_nullable
              as String?,
      googleMapsUrl: freezed == googleMapsUrl
          ? _value.googleMapsUrl
          : googleMapsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      googleFetchedAt: freezed == googleFetchedAt
          ? _value.googleFetchedAt
          : googleFetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      googlePhotoName: freezed == googlePhotoName
          ? _value.googlePhotoName
          : googlePhotoName // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePhotoAttribution: freezed == googlePhotoAttribution
          ? _value.googlePhotoAttribution
          : googlePhotoAttribution // ignore: cast_nullable_to_non_nullable
              as String?,
      userImageLocalPath: freezed == userImageLocalPath
          ? _value.userImageLocalPath
          : userImageLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      userImageStoragePath: freezed == userImageStoragePath
          ? _value.userImageStoragePath
          : userImageStoragePath // ignore: cast_nullable_to_non_nullable
              as String?,
      userImageUploadStatus: null == userImageUploadStatus
          ? _value.userImageUploadStatus
          : userImageUploadStatus // ignore: cast_nullable_to_non_nullable
              as ImageUploadStatus,
      userImageAltText: freezed == userImageAltText
          ? _value.userImageAltText
          : userImageAltText // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ItinerarySpotImplCopyWith<$Res>
    implements $ItinerarySpotCopyWith<$Res> {
  factory _$$ItinerarySpotImplCopyWith(
          _$ItinerarySpotImpl value, $Res Function(_$ItinerarySpotImpl) then) =
      __$$ItinerarySpotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      String ownerId,
      ItinerarySpotSource source,
      String? googlePlaceId,
      String name,
      ItinerarySpotCategory category,
      String? address,
      ItineraryValueOrigin dataOrigin,
      String? rightsBasis,
      double? latitude,
      double? longitude,
      String? phoneNumber,
      String? websiteUrl,
      String? openingHoursText,
      String? googleMapsUrl,
      @NullableUtcDateTimeConverter() DateTime? googleFetchedAt,
      String? googlePhotoName,
      String? googlePhotoAttribution,
      String? userImageLocalPath,
      String? userImageStoragePath,
      ImageUploadStatus userImageUploadStatus,
      String? userImageAltText,
      String? memo,
      @UtcDateTimeConverter() DateTime createdAt,
      @UtcDateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$$ItinerarySpotImplCopyWithImpl<$Res>
    extends _$ItinerarySpotCopyWithImpl<$Res, _$ItinerarySpotImpl>
    implements _$$ItinerarySpotImplCopyWith<$Res> {
  __$$ItinerarySpotImplCopyWithImpl(
      _$ItinerarySpotImpl _value, $Res Function(_$ItinerarySpotImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItinerarySpot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? ownerId = null,
    Object? source = null,
    Object? googlePlaceId = freezed,
    Object? name = null,
    Object? category = null,
    Object? address = freezed,
    Object? dataOrigin = null,
    Object? rightsBasis = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? phoneNumber = freezed,
    Object? websiteUrl = freezed,
    Object? openingHoursText = freezed,
    Object? googleMapsUrl = freezed,
    Object? googleFetchedAt = freezed,
    Object? googlePhotoName = freezed,
    Object? googlePhotoAttribution = freezed,
    Object? userImageLocalPath = freezed,
    Object? userImageStoragePath = freezed,
    Object? userImageUploadStatus = null,
    Object? userImageAltText = freezed,
    Object? memo = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ItinerarySpotImpl(
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
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ItinerarySpotSource,
      googlePlaceId: freezed == googlePlaceId
          ? _value.googlePlaceId
          : googlePlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ItinerarySpotCategory,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      dataOrigin: null == dataOrigin
          ? _value.dataOrigin
          : dataOrigin // ignore: cast_nullable_to_non_nullable
              as ItineraryValueOrigin,
      rightsBasis: freezed == rightsBasis
          ? _value.rightsBasis
          : rightsBasis // ignore: cast_nullable_to_non_nullable
              as String?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrl: freezed == websiteUrl
          ? _value.websiteUrl
          : websiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      openingHoursText: freezed == openingHoursText
          ? _value.openingHoursText
          : openingHoursText // ignore: cast_nullable_to_non_nullable
              as String?,
      googleMapsUrl: freezed == googleMapsUrl
          ? _value.googleMapsUrl
          : googleMapsUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      googleFetchedAt: freezed == googleFetchedAt
          ? _value.googleFetchedAt
          : googleFetchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      googlePhotoName: freezed == googlePhotoName
          ? _value.googlePhotoName
          : googlePhotoName // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePhotoAttribution: freezed == googlePhotoAttribution
          ? _value.googlePhotoAttribution
          : googlePhotoAttribution // ignore: cast_nullable_to_non_nullable
              as String?,
      userImageLocalPath: freezed == userImageLocalPath
          ? _value.userImageLocalPath
          : userImageLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      userImageStoragePath: freezed == userImageStoragePath
          ? _value.userImageStoragePath
          : userImageStoragePath // ignore: cast_nullable_to_non_nullable
              as String?,
      userImageUploadStatus: null == userImageUploadStatus
          ? _value.userImageUploadStatus
          : userImageUploadStatus // ignore: cast_nullable_to_non_nullable
              as ImageUploadStatus,
      userImageAltText: freezed == userImageAltText
          ? _value.userImageAltText
          : userImageAltText // ignore: cast_nullable_to_non_nullable
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
class _$ItinerarySpotImpl implements _ItinerarySpot {
  const _$ItinerarySpotImpl(
      {required this.id,
      required this.planId,
      required this.ownerId,
      this.source = ItinerarySpotSource.manual,
      this.googlePlaceId,
      required this.name,
      required this.category,
      this.address,
      this.dataOrigin = ItineraryValueOrigin.userProvided,
      this.rightsBasis,
      this.latitude,
      this.longitude,
      this.phoneNumber,
      this.websiteUrl,
      this.openingHoursText,
      this.googleMapsUrl,
      @NullableUtcDateTimeConverter() this.googleFetchedAt,
      this.googlePhotoName,
      this.googlePhotoAttribution,
      this.userImageLocalPath,
      this.userImageStoragePath,
      this.userImageUploadStatus = ImageUploadStatus.localOnly,
      this.userImageAltText,
      this.memo,
      @UtcDateTimeConverter() required this.createdAt,
      @UtcDateTimeConverter() required this.updatedAt});

  factory _$ItinerarySpotImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItinerarySpotImplFromJson(json);

  @override
  final String id;
  @override
  final String planId;
  @override
  final String ownerId;
  @override
  @JsonKey()
  final ItinerarySpotSource source;

  /// 永続保存できる唯一の Google 識別子（重複候補の照合キー。§4.3/§12.2）。
  @override
  final String? googlePlaceId;

  /// 施設名（必須、前後空白除去・空文字不可は入力側/バリデーションで保証）。
  @override
  final String name;
  @override
  final ItinerarySpotCategory category;

  /// 住所（任意、センシティブ情報として扱う。§4.2）。
  @override
  final String? address;

  /// 永続する名称・住所の出典・権利根拠（既定はユーザー入力, §12.2）。
  @override
  @JsonKey()
  final ItineraryValueOrigin dataOrigin;
  @override
  final String? rightsBasis;

  /// 緯度・経度は両方揃ったときだけ座標として有効（§4.2）。手動入力のみ。
  @override
  final double? latitude;
  @override
  final double? longitude;
// ---- 予約領域（MVPでは Google 応答の保存に使わない, §12.2）----------------
  @override
  final String? phoneNumber;
  @override
  final String? websiteUrl;
  @override
  final String? openingHoursText;
  @override
  final String? googleMapsUrl;
  @override
  @NullableUtcDateTimeConverter()
  final DateTime? googleFetchedAt;
  @override
  final String? googlePhotoName;
  @override
  final String? googlePhotoAttribution;

  /// ユーザー所有画像（既存 ImageStore/Storage 契約と同じ形。§7.1）。
  @override
  final String? userImageLocalPath;
  @override
  final String? userImageStoragePath;
  @override
  @JsonKey()
  final ImageUploadStatus userImageUploadStatus;
  @override
  final String? userImageAltText;
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
    return 'ItinerarySpot(id: $id, planId: $planId, ownerId: $ownerId, source: $source, googlePlaceId: $googlePlaceId, name: $name, category: $category, address: $address, dataOrigin: $dataOrigin, rightsBasis: $rightsBasis, latitude: $latitude, longitude: $longitude, phoneNumber: $phoneNumber, websiteUrl: $websiteUrl, openingHoursText: $openingHoursText, googleMapsUrl: $googleMapsUrl, googleFetchedAt: $googleFetchedAt, googlePhotoName: $googlePhotoName, googlePhotoAttribution: $googlePhotoAttribution, userImageLocalPath: $userImageLocalPath, userImageStoragePath: $userImageStoragePath, userImageUploadStatus: $userImageUploadStatus, userImageAltText: $userImageAltText, memo: $memo, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItinerarySpotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.googlePlaceId, googlePlaceId) ||
                other.googlePlaceId == googlePlaceId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.dataOrigin, dataOrigin) ||
                other.dataOrigin == dataOrigin) &&
            (identical(other.rightsBasis, rightsBasis) ||
                other.rightsBasis == rightsBasis) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.websiteUrl, websiteUrl) ||
                other.websiteUrl == websiteUrl) &&
            (identical(other.openingHoursText, openingHoursText) ||
                other.openingHoursText == openingHoursText) &&
            (identical(other.googleMapsUrl, googleMapsUrl) ||
                other.googleMapsUrl == googleMapsUrl) &&
            (identical(other.googleFetchedAt, googleFetchedAt) ||
                other.googleFetchedAt == googleFetchedAt) &&
            (identical(other.googlePhotoName, googlePhotoName) ||
                other.googlePhotoName == googlePhotoName) &&
            (identical(other.googlePhotoAttribution, googlePhotoAttribution) ||
                other.googlePhotoAttribution == googlePhotoAttribution) &&
            (identical(other.userImageLocalPath, userImageLocalPath) ||
                other.userImageLocalPath == userImageLocalPath) &&
            (identical(other.userImageStoragePath, userImageStoragePath) ||
                other.userImageStoragePath == userImageStoragePath) &&
            (identical(other.userImageUploadStatus, userImageUploadStatus) ||
                other.userImageUploadStatus == userImageUploadStatus) &&
            (identical(other.userImageAltText, userImageAltText) ||
                other.userImageAltText == userImageAltText) &&
            (identical(other.memo, memo) || other.memo == memo) &&
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
        source,
        googlePlaceId,
        name,
        category,
        address,
        dataOrigin,
        rightsBasis,
        latitude,
        longitude,
        phoneNumber,
        websiteUrl,
        openingHoursText,
        googleMapsUrl,
        googleFetchedAt,
        googlePhotoName,
        googlePhotoAttribution,
        userImageLocalPath,
        userImageStoragePath,
        userImageUploadStatus,
        userImageAltText,
        memo,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of ItinerarySpot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItinerarySpotImplCopyWith<_$ItinerarySpotImpl> get copyWith =>
      __$$ItinerarySpotImplCopyWithImpl<_$ItinerarySpotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItinerarySpotImplToJson(
      this,
    );
  }
}

abstract class _ItinerarySpot implements ItinerarySpot {
  const factory _ItinerarySpot(
          {required final String id,
          required final String planId,
          required final String ownerId,
          final ItinerarySpotSource source,
          final String? googlePlaceId,
          required final String name,
          required final ItinerarySpotCategory category,
          final String? address,
          final ItineraryValueOrigin dataOrigin,
          final String? rightsBasis,
          final double? latitude,
          final double? longitude,
          final String? phoneNumber,
          final String? websiteUrl,
          final String? openingHoursText,
          final String? googleMapsUrl,
          @NullableUtcDateTimeConverter() final DateTime? googleFetchedAt,
          final String? googlePhotoName,
          final String? googlePhotoAttribution,
          final String? userImageLocalPath,
          final String? userImageStoragePath,
          final ImageUploadStatus userImageUploadStatus,
          final String? userImageAltText,
          final String? memo,
          @UtcDateTimeConverter() required final DateTime createdAt,
          @UtcDateTimeConverter() required final DateTime updatedAt}) =
      _$ItinerarySpotImpl;

  factory _ItinerarySpot.fromJson(Map<String, dynamic> json) =
      _$ItinerarySpotImpl.fromJson;

  @override
  String get id;
  @override
  String get planId;
  @override
  String get ownerId;
  @override
  ItinerarySpotSource get source;

  /// 永続保存できる唯一の Google 識別子（重複候補の照合キー。§4.3/§12.2）。
  @override
  String? get googlePlaceId;

  /// 施設名（必須、前後空白除去・空文字不可は入力側/バリデーションで保証）。
  @override
  String get name;
  @override
  ItinerarySpotCategory get category;

  /// 住所（任意、センシティブ情報として扱う。§4.2）。
  @override
  String? get address;

  /// 永続する名称・住所の出典・権利根拠（既定はユーザー入力, §12.2）。
  @override
  ItineraryValueOrigin get dataOrigin;
  @override
  String? get rightsBasis;

  /// 緯度・経度は両方揃ったときだけ座標として有効（§4.2）。手動入力のみ。
  @override
  double? get latitude;
  @override
  double?
      get longitude; // ---- 予約領域（MVPでは Google 応答の保存に使わない, §12.2）----------------
  @override
  String? get phoneNumber;
  @override
  String? get websiteUrl;
  @override
  String? get openingHoursText;
  @override
  String? get googleMapsUrl;
  @override
  @NullableUtcDateTimeConverter()
  DateTime? get googleFetchedAt;
  @override
  String? get googlePhotoName;
  @override
  String? get googlePhotoAttribution;

  /// ユーザー所有画像（既存 ImageStore/Storage 契約と同じ形。§7.1）。
  @override
  String? get userImageLocalPath;
  @override
  String? get userImageStoragePath;
  @override
  ImageUploadStatus get userImageUploadStatus;
  @override
  String? get userImageAltText;
  @override
  String? get memo;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAt;
  @override
  @UtcDateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of ItinerarySpot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItinerarySpotImplCopyWith<_$ItinerarySpotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
