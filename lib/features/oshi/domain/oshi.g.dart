// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oshi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OshiGroupImpl _$$OshiGroupImplFromJson(Map<String, dynamic> json) =>
    _$OshiGroupImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String?,
      color: json['color'] as String?,
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$OshiGroupImplToJson(_$OshiGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'kind': instance.kind,
      'color': instance.color,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

_$OshiMemberImpl _$$OshiMemberImplFromJson(Map<String, dynamic> json) =>
    _$OshiMemberImpl(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      rank:
          $enumDecodeNullable(_$OshiRankEnumMap, json['rank']) ?? OshiRank.oshi,
      color: json['color'] as String?,
      oshiSince: const NullableDateOnlyConverter()
          .fromJson(json['oshi_since'] as String?),
      birthday: const NullableDateOnlyConverter()
          .fromJson(json['birthday'] as String?),
      memo: json['memo'] as String?,
      imageLocalPath: json['image_local_path'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$OshiMemberImplToJson(_$OshiMemberImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'rank': _$OshiRankEnumMap[instance.rank]!,
      'color': instance.color,
      'oshi_since':
          const NullableDateOnlyConverter().toJson(instance.oshiSince),
      'birthday': const NullableDateOnlyConverter().toJson(instance.birthday),
      'memo': instance.memo,
      'image_local_path': instance.imageLocalPath,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$OshiRankEnumMap = {
  OshiRank.saioshi: 'saioshi',
  OshiRank.oshi: 'oshi',
  OshiRank.yuruoshi: 'yuruoshi',
  OshiRank.hakooshi: 'hakooshi',
  OshiRank.curious: 'curious',
};
