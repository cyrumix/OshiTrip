// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_spot_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItinerarySpotLinkImpl _$$ItinerarySpotLinkImplFromJson(
        Map<String, dynamic> json) =>
    _$ItinerarySpotLinkImpl(
      id: json['id'] as String,
      spotId: json['spot_id'] as String,
      ownerId: json['owner_id'] as String,
      kind: $enumDecode(_$ItinerarySpotLinkKindEnumMap, json['kind']),
      url: json['url'] as String,
      label: json['label'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ItinerarySpotLinkImplToJson(
        _$ItinerarySpotLinkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'spot_id': instance.spotId,
      'owner_id': instance.ownerId,
      'kind': _$ItinerarySpotLinkKindEnumMap[instance.kind]!,
      'url': instance.url,
      'label': instance.label,
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$ItinerarySpotLinkKindEnumMap = {
  ItinerarySpotLinkKind.reference: 'reference',
  ItinerarySpotLinkKind.reservation: 'reservation',
  ItinerarySpotLinkKind.googleMaps: 'google_maps',
  ItinerarySpotLinkKind.social: 'social',
  ItinerarySpotLinkKind.ticket: 'ticket',
  ItinerarySpotLinkKind.official: 'official',
  ItinerarySpotLinkKind.other: 'other',
};
