// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItineraryPlanImpl _$$ItineraryPlanImplFromJson(Map<String, dynamic> json) =>
    _$ItineraryPlanImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      startDate: const NullableDateOnlyConverter()
          .fromJson(json['start_date'] as String?),
      endDate: const NullableDateOnlyConverter()
          .fromJson(json['end_date'] as String?),
      timeZoneId: json['time_zone_id'] as String,
      coverImageLocalPath: json['cover_image_local_path'] as String?,
      coverImageStoragePath: json['cover_image_storage_path'] as String?,
      coverImageUploadStatus: $enumDecodeNullable(
              _$ImageUploadStatusEnumMap, json['cover_image_upload_status']) ??
          ImageUploadStatus.localOnly,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ItineraryPlanImplToJson(_$ItineraryPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'title': instance.title,
      'memo': instance.memo,
      'start_date':
          const NullableDateOnlyConverter().toJson(instance.startDate),
      'end_date': const NullableDateOnlyConverter().toJson(instance.endDate),
      'time_zone_id': instance.timeZoneId,
      'cover_image_local_path': instance.coverImageLocalPath,
      'cover_image_storage_path': instance.coverImageStoragePath,
      'cover_image_upload_status':
          _$ImageUploadStatusEnumMap[instance.coverImageUploadStatus]!,
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$ImageUploadStatusEnumMap = {
  ImageUploadStatus.localOnly: 'local_only',
  ImageUploadStatus.queued: 'queued',
  ImageUploadStatus.uploaded: 'uploaded',
  ImageUploadStatus.failed: 'failed',
};
