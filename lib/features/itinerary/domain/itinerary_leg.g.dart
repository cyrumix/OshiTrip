// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_leg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItineraryLegImpl _$$ItineraryLegImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryLegImpl(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      ownerId: json['owner_id'] as String,
      originEntryId: json['origin_entry_id'] as String,
      destinationEntryId: json['destination_entry_id'] as String,
      source:
          $enumDecodeNullable(_$ItineraryLegSourceEnumMap, json['source']) ??
              ItineraryLegSource.manual,
      travelMode: $enumDecodeNullable(
              _$ItineraryTravelModeEnumMap, json['travel_mode']) ??
          ItineraryTravelMode.other,
      departureAt: const NullableUtcDateTimeConverter()
          .fromJson(json['departure_at'] as String?),
      arrivalAt: const NullableUtcDateTimeConverter()
          .fromJson(json['arrival_at'] as String?),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      fareAmountMinor: (json['fare_amount_minor'] as num?)?.toInt(),
      fareCurrency: json['fare_currency'] as String?,
      routeSummary: json['route_summary'] as String?,
      valueOrigin: $enumDecodeNullable(
              _$ItineraryValueOriginEnumMap, json['value_origin']) ??
          ItineraryValueOrigin.userProvided,
      rightsBasis: json['rights_basis'] as String?,
      representativeTimeBucket: json['representative_time_bucket'] as String?,
      lastVerifiedAt: const NullableUtcDateTimeConverter()
          .fromJson(json['last_verified_at'] as String?),
      transitStepsJson: json['transit_steps_json'] as String?,
      encodedPolyline: json['encoded_polyline'] as String?,
      googleMapsUrl: json['google_maps_url'] as String?,
      fetchedAt: const NullableUtcDateTimeConverter()
          .fromJson(json['fetched_at'] as String?),
      cacheKey: json['cache_key'] as String?,
      isStale: json['is_stale'] as bool? ?? false,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ItineraryLegImplToJson(_$ItineraryLegImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_id': instance.planId,
      'owner_id': instance.ownerId,
      'origin_entry_id': instance.originEntryId,
      'destination_entry_id': instance.destinationEntryId,
      'source': _$ItineraryLegSourceEnumMap[instance.source]!,
      'travel_mode': _$ItineraryTravelModeEnumMap[instance.travelMode]!,
      'departure_at':
          const NullableUtcDateTimeConverter().toJson(instance.departureAt),
      'arrival_at':
          const NullableUtcDateTimeConverter().toJson(instance.arrivalAt),
      'duration_minutes': instance.durationMinutes,
      'distance_meters': instance.distanceMeters,
      'fare_amount_minor': instance.fareAmountMinor,
      'fare_currency': instance.fareCurrency,
      'route_summary': instance.routeSummary,
      'value_origin': _$ItineraryValueOriginEnumMap[instance.valueOrigin]!,
      'rights_basis': instance.rightsBasis,
      'representative_time_bucket': instance.representativeTimeBucket,
      'last_verified_at':
          const NullableUtcDateTimeConverter().toJson(instance.lastVerifiedAt),
      'transit_steps_json': instance.transitStepsJson,
      'encoded_polyline': instance.encodedPolyline,
      'google_maps_url': instance.googleMapsUrl,
      'fetched_at':
          const NullableUtcDateTimeConverter().toJson(instance.fetchedAt),
      'cache_key': instance.cacheKey,
      'is_stale': instance.isStale,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$ItineraryLegSourceEnumMap = {
  ItineraryLegSource.manual: 'manual',
  ItineraryLegSource.googleRoutes: 'google_routes',
};

const _$ItineraryTravelModeEnumMap = {
  ItineraryTravelMode.walking: 'walking',
  ItineraryTravelMode.transit: 'transit',
  ItineraryTravelMode.driving: 'driving',
  ItineraryTravelMode.bicycling: 'bicycling',
  ItineraryTravelMode.taxi: 'taxi',
  ItineraryTravelMode.flight: 'flight',
  ItineraryTravelMode.other: 'other',
};

const _$ItineraryValueOriginEnumMap = {
  ItineraryValueOrigin.userProvided: 'user_provided',
  ItineraryValueOrigin.facilityProvided: 'facility_provided',
  ItineraryValueOrigin.openData: 'open_data',
  ItineraryValueOrigin.licensed: 'licensed',
};
