// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoTemplateImpl _$$TodoTemplateImplFromJson(Map<String, dynamic> json) =>
    _$TodoTemplateImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      itemType: $enumDecode(_$TodoItemTypeEnumMap, json['item_type']),
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TodoTemplateImplToJson(_$TodoTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'item_type': _$TodoItemTypeEnumMap[instance.itemType]!,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$TodoItemTypeEnumMap = {
  TodoItemType.todo: 'todo',
  TodoItemType.belonging: 'belonging',
};

_$TodoTemplateItemImpl _$$TodoTemplateItemImplFromJson(
        Map<String, dynamic> json) =>
    _$TodoTemplateItemImpl(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      priority: $enumDecodeNullable(_$TodoPriorityEnumMap, json['priority']),
      memo: json['memo'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TodoTemplateItemImplToJson(
        _$TodoTemplateItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'template_id': instance.templateId,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'priority': _$TodoPriorityEnumMap[instance.priority],
      'memo': instance.memo,
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$TodoPriorityEnumMap = {
  TodoPriority.low: 'low',
  TodoPriority.normal: 'normal',
  TodoPriority.high: 'high',
};
