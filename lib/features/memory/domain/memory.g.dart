// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemoryEntryImpl _$$MemoryEntryImplFromJson(Map<String, dynamic> json) =>
    _$MemoryEntryImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      impression: json['impression'] as String? ?? '',
      bestMoment: json['best_moment'] as String? ?? '',
      mcNotes: json['mc_notes'] as String? ?? '',
      seatView: json['seat_view'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      declinedFields: (json['declined_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$MemoryEntryImplToJson(_$MemoryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'impression': instance.impression,
      'best_moment': instance.bestMoment,
      'mc_notes': instance.mcNotes,
      'seat_view': instance.seatView,
      'tags': instance.tags,
      'declined_fields': instance.declinedFields,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

_$MemoryPhotoImpl _$$MemoryPhotoImplFromJson(Map<String, dynamic> json) =>
    _$MemoryPhotoImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      localPath: json['local_path'] as String?,
      storagePath: json['storage_path'] as String?,
      uploadStatus: $enumDecodeNullable(
              _$PhotoUploadStatusEnumMap, json['upload_status']) ??
          PhotoUploadStatus.localOnly,
      caption: json['caption'] as String?,
      isCover: json['is_cover'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$MemoryPhotoImplToJson(_$MemoryPhotoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'local_path': instance.localPath,
      'storage_path': instance.storagePath,
      'upload_status': _$PhotoUploadStatusEnumMap[instance.uploadStatus]!,
      'caption': instance.caption,
      'is_cover': instance.isCover,
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$PhotoUploadStatusEnumMap = {
  PhotoUploadStatus.localOnly: 'local_only',
  PhotoUploadStatus.queued: 'queued',
  PhotoUploadStatus.uploaded: 'uploaded',
  PhotoUploadStatus.failed: 'failed',
};

_$SetlistItemImpl _$$SetlistItemImplFromJson(Map<String, dynamic> json) =>
    _$SetlistItemImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      position: (json['position'] as num).toInt(),
      songTitle: json['song_title'] as String,
      note: json['note'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SetlistItemImplToJson(_$SetlistItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'position': instance.position,
      'song_title': instance.songTitle,
      'note': instance.note,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

_$GoodsItemImpl _$$GoodsItemImplFromJson(Map<String, dynamic> json) =>
    _$GoodsItemImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$GoodsItemImplToJson(_$GoodsItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'price': instance.price,
      'quantity': instance.quantity,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

_$VisitedPlaceImpl _$$VisitedPlaceImplFromJson(Map<String, dynamic> json) =>
    _$VisitedPlaceImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'spot',
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$VisitedPlaceImplToJson(_$VisitedPlaceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'category': instance.category,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };
