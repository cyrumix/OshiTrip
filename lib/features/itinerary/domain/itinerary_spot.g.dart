// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItinerarySpotImpl _$$ItinerarySpotImplFromJson(Map<String, dynamic> json) =>
    _$ItinerarySpotImpl(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      ownerId: json['owner_id'] as String,
      source:
          $enumDecodeNullable(_$ItinerarySpotSourceEnumMap, json['source']) ??
              ItinerarySpotSource.manual,
      googlePlaceId: json['google_place_id'] as String?,
      name: json['name'] as String,
      category: $enumDecode(_$ItinerarySpotCategoryEnumMap, json['category']),
      address: json['address'] as String?,
      dataOrigin: $enumDecodeNullable(
              _$ItineraryValueOriginEnumMap, json['data_origin']) ??
          ItineraryValueOrigin.userProvided,
      rightsBasis: json['rights_basis'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
      websiteUrl: json['website_url'] as String?,
      openingHoursText: json['opening_hours_text'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      googleFetchedAt: const NullableUtcDateTimeConverter()
          .fromJson(json['google_fetched_at'] as String?),
      googlePhotoName: json['google_photo_name'] as String?,
      googlePhotoAttribution: json['google_photo_attribution'] as String?,
      userImageLocalPath: json['user_image_local_path'] as String?,
      userImageStoragePath: json['user_image_storage_path'] as String?,
      userImageUploadStatus: $enumDecodeNullable(
              _$ImageUploadStatusEnumMap, json['user_image_upload_status']) ??
          ImageUploadStatus.localOnly,
      userImageAltText: json['user_image_alt_text'] as String?,
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ItinerarySpotImplToJson(_$ItinerarySpotImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_id': instance.planId,
      'owner_id': instance.ownerId,
      'source': _$ItinerarySpotSourceEnumMap[instance.source]!,
      'google_place_id': instance.googlePlaceId,
      'name': instance.name,
      'category': _$ItinerarySpotCategoryEnumMap[instance.category]!,
      'address': instance.address,
      'data_origin': _$ItineraryValueOriginEnumMap[instance.dataOrigin]!,
      'rights_basis': instance.rightsBasis,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'phone_number': instance.phoneNumber,
      'website_url': instance.websiteUrl,
      'opening_hours_text': instance.openingHoursText,
      'google_maps_url': instance.googleMapsUrl,
      'google_fetched_at':
          const NullableUtcDateTimeConverter().toJson(instance.googleFetchedAt),
      'google_photo_name': instance.googlePhotoName,
      'google_photo_attribution': instance.googlePhotoAttribution,
      'user_image_local_path': instance.userImageLocalPath,
      'user_image_storage_path': instance.userImageStoragePath,
      'user_image_upload_status':
          _$ImageUploadStatusEnumMap[instance.userImageUploadStatus]!,
      'user_image_alt_text': instance.userImageAltText,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$ItinerarySpotSourceEnumMap = {
  ItinerarySpotSource.manual: 'manual',
  ItinerarySpotSource.googlePlaces: 'google_places',
};

const _$ItinerarySpotCategoryEnumMap = {
  ItinerarySpotCategory.venue: 'venue',
  ItinerarySpotCategory.sightseeing: 'sightseeing',
  ItinerarySpotCategory.restaurant: 'restaurant',
  ItinerarySpotCategory.cafe: 'cafe',
  ItinerarySpotCategory.lodging: 'lodging',
  ItinerarySpotCategory.station: 'station',
  ItinerarySpotCategory.airport: 'airport',
  ItinerarySpotCategory.shopping: 'shopping',
  ItinerarySpotCategory.shrineTemple: 'shrine_temple',
  ItinerarySpotCategory.museum: 'museum',
  ItinerarySpotCategory.park: 'park',
  ItinerarySpotCategory.photoSpot: 'photo_spot',
  ItinerarySpotCategory.convenience: 'convenience',
  ItinerarySpotCategory.other: 'other',
};

const _$ItineraryValueOriginEnumMap = {
  ItineraryValueOrigin.userProvided: 'user_provided',
  ItineraryValueOrigin.facilityProvided: 'facility_provided',
  ItineraryValueOrigin.openData: 'open_data',
  ItineraryValueOrigin.licensed: 'licensed',
};

const _$ImageUploadStatusEnumMap = {
  ImageUploadStatus.localOnly: 'local_only',
  ImageUploadStatus.queued: 'queued',
  ImageUploadStatus.uploaded: 'uploaded',
  ImageUploadStatus.failed: 'failed',
};
