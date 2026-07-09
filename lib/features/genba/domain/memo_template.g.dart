// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemoTemplateImpl _$$MemoTemplateImplFromJson(Map<String, dynamic> json) =>
    _$MemoTemplateImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      kind:
          $enumDecodeNullable(_$MemoKindEnumMap, json['kind']) ?? MemoKind.free,
      category: $enumDecodeNullable(_$MemoCategoryEnumMap, json['category']) ??
          MemoCategory.other,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      content: json['content'] == null
          ? null
          : MemoContent.fromJson(json['content'] as Map<String, dynamic>),
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$MemoTemplateImplToJson(_$MemoTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'kind': _$MemoKindEnumMap[instance.kind]!,
      'category': _$MemoCategoryEnumMap[instance.category]!,
      'title': instance.title,
      'body': instance.body,
      'content': instance.content?.toJson(),
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$MemoKindEnumMap = {
  MemoKind.free: 'free',
  MemoKind.checklist: 'checklist',
  MemoKind.bingo: 'bingo',
  MemoKind.vote: 'vote',
};

const _$MemoCategoryEnumMap = {
  MemoCategory.free: 'free',
  MemoCategory.goods: 'goods',
  MemoCategory.meetup: 'meetup',
  MemoCategory.around: 'around',
  MemoCategory.notice: 'notice',
  MemoCategory.other: 'other',
};
