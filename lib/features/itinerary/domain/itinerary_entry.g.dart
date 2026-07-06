// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItineraryEntryImpl _$$ItineraryEntryImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryEntryImpl(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      ownerId: json['owner_id'] as String,
      kind: $enumDecode(_$ItineraryEntryKindEnumMap, json['kind']),
      spotId: json['spot_id'] as String?,
      transportId: json['transport_id'] as String?,
      lodgingId: json['lodging_id'] as String?,
      titleOverride: json['title_override'] as String?,
      startAt: const NullableUtcDateTimeConverter()
          .fromJson(json['start_at'] as String?),
      endAt: const NullableUtcDateTimeConverter()
          .fromJson(json['end_at'] as String?),
      localDate: const NullableDateOnlyConverter()
          .fromJson(json['local_date'] as String?),
      timeZoneId: json['time_zone_id'] as String?,
      bufferBeforeMinutes:
          (json['buffer_before_minutes'] as num?)?.toInt() ?? 0,
      bufferAfterMinutes: (json['buffer_after_minutes'] as num?)?.toInt() ?? 0,
      memo: json['memo'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ItineraryEntryImplToJson(
        _$ItineraryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_id': instance.planId,
      'owner_id': instance.ownerId,
      'kind': _$ItineraryEntryKindEnumMap[instance.kind]!,
      'spot_id': instance.spotId,
      'transport_id': instance.transportId,
      'lodging_id': instance.lodgingId,
      'title_override': instance.titleOverride,
      'start_at': const NullableUtcDateTimeConverter().toJson(instance.startAt),
      'end_at': const NullableUtcDateTimeConverter().toJson(instance.endAt),
      'local_date':
          const NullableDateOnlyConverter().toJson(instance.localDate),
      'time_zone_id': instance.timeZoneId,
      'buffer_before_minutes': instance.bufferBeforeMinutes,
      'buffer_after_minutes': instance.bufferAfterMinutes,
      'memo': instance.memo,
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$ItineraryEntryKindEnumMap = {
  ItineraryEntryKind.spot: 'spot',
  ItineraryEntryKind.transport: 'transport',
  ItineraryEntryKind.lodging: 'lodging',
  ItineraryEntryKind.note: 'note',
};
