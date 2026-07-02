// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PerformanceImpl _$$PerformanceImplFromJson(Map<String, dynamic> json) =>
    _$PerformanceImpl(
      id: json['id'] as String,
      groupName: json['group_name'] as String,
      title: json['title'] as String,
      venue: json['venue'] as String,
      eventDate:
          const DateOnlyConverter().fromJson(json['event_date'] as String),
      startTimeMinutes: (json['start_time_minutes'] as num?)?.toInt(),
      createdBy: json['created_by'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$PerformanceImplToJson(_$PerformanceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_name': instance.groupName,
      'title': instance.title,
      'venue': instance.venue,
      'event_date': const DateOnlyConverter().toJson(instance.eventDate),
      'start_time_minutes': instance.startTimeMinutes,
      'created_by': instance.createdBy,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };
