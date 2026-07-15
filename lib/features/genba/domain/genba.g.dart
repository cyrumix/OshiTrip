// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genba.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GenbaHeroImageImpl _$$GenbaHeroImageImplFromJson(Map<String, dynamic> json) =>
    _$GenbaHeroImageImpl(
      localPath: json['localPath'] as String?,
      storagePath: json['storagePath'] as String?,
      uploadStatus: $enumDecodeNullable(
              _$ImageUploadStatusEnumMap, json['uploadStatus']) ??
          ImageUploadStatus.localOnly,
      altText: json['altText'] as String?,
    );

Map<String, dynamic> _$$GenbaHeroImageImplToJson(
        _$GenbaHeroImageImpl instance) =>
    <String, dynamic>{
      'localPath': instance.localPath,
      'storagePath': instance.storagePath,
      'uploadStatus': _$ImageUploadStatusEnumMap[instance.uploadStatus]!,
      'altText': instance.altText,
    };

const _$ImageUploadStatusEnumMap = {
  ImageUploadStatus.localOnly: 'local_only',
  ImageUploadStatus.queued: 'queued',
  ImageUploadStatus.uploaded: 'uploaded',
  ImageUploadStatus.failed: 'failed',
};

_$GenbaImpl _$$GenbaImplFromJson(Map<String, dynamic> json) => _$GenbaImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      artistName: json['artist_name'] as String,
      title: json['title'] as String,
      eventDate:
          const DateOnlyConverter().fromJson(json['event_date'] as String),
      oshiGroupId: json['oshi_group_id'] as String?,
      oshiMemberIds: (json['oshi_member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      venue: json['venue'] as String?,
      venueAddress: json['venue_address'] as String?,
      venueGooglePlaceId: json['venue_google_place_id'] as String?,
      doorTimeMinutes: (json['door_time_minutes'] as num?)?.toInt(),
      startTimeMinutes: (json['start_time_minutes'] as num?)?.toInt(),
      endTimeMinutes: (json['end_time_minutes'] as num?)?.toInt(),
      performanceType: $enumDecodeNullable(
          _$PerformanceTypeEnumMap, json['performance_type']),
      performanceTypeOther: json['performance_type_other'] as String?,
      performanceId: json['performance_id'] as String?,
      isExpedition: json['is_expedition'] as bool?,
      transportRequirement: $enumDecodeNullable(
              _$RequirementStatusEnumMap, json['transport_requirement']) ??
          RequirementStatus.unknown,
      lodgingRequirement: $enumDecodeNullable(
              _$RequirementStatusEnumMap, json['lodging_requirement']) ??
          RequirementStatus.unknown,
      isCanceled: json['is_canceled'] as bool? ?? false,
      attendanceStatus: $enumDecodeNullable(
              _$AttendanceStatusEnumMap, json['attendance_status']) ??
          AttendanceStatus.planned,
      heroImageLocalPath: json['hero_image_local_path'] as String?,
      heroImageStoragePath: json['hero_image_storage_path'] as String?,
      heroImageUploadStatus: $enumDecodeNullable(
              _$ImageUploadStatusEnumMap, json['hero_image_upload_status']) ??
          ImageUploadStatus.localOnly,
      heroImageAltText: json['hero_image_alt_text'] as String?,
      manualEndedAt: const NullableUtcDateTimeConverter()
          .fromJson(json['manual_ended_at'] as String?),
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$GenbaImplToJson(_$GenbaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'artist_name': instance.artistName,
      'title': instance.title,
      'event_date': const DateOnlyConverter().toJson(instance.eventDate),
      'oshi_group_id': instance.oshiGroupId,
      'oshi_member_ids': instance.oshiMemberIds,
      'venue': instance.venue,
      'venue_address': instance.venueAddress,
      'venue_google_place_id': instance.venueGooglePlaceId,
      'door_time_minutes': instance.doorTimeMinutes,
      'start_time_minutes': instance.startTimeMinutes,
      'end_time_minutes': instance.endTimeMinutes,
      'performance_type': _$PerformanceTypeEnumMap[instance.performanceType],
      'performance_type_other': instance.performanceTypeOther,
      'performance_id': instance.performanceId,
      'is_expedition': instance.isExpedition,
      'transport_requirement':
          _$RequirementStatusEnumMap[instance.transportRequirement]!,
      'lodging_requirement':
          _$RequirementStatusEnumMap[instance.lodgingRequirement]!,
      'is_canceled': instance.isCanceled,
      'attendance_status':
          _$AttendanceStatusEnumMap[instance.attendanceStatus]!,
      'hero_image_local_path': instance.heroImageLocalPath,
      'hero_image_storage_path': instance.heroImageStoragePath,
      'hero_image_upload_status':
          _$ImageUploadStatusEnumMap[instance.heroImageUploadStatus]!,
      'hero_image_alt_text': instance.heroImageAltText,
      'manual_ended_at':
          const NullableUtcDateTimeConverter().toJson(instance.manualEndedAt),
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$PerformanceTypeEnumMap = {
  PerformanceType.liveConcert: 'live_concert',
  PerformanceType.festival: 'festival',
  PerformanceType.releaseEvent: 'release_event',
  PerformanceType.meetGreet: 'meet_greet',
  PerformanceType.fanMeeting: 'fan_meeting',
  PerformanceType.talkEvent: 'talk_event',
  PerformanceType.stageMusical: 'stage_musical',
  PerformanceType.exhibition: 'exhibition',
  PerformanceType.sports: 'sports',
  PerformanceType.online: 'online',
  PerformanceType.other: 'other',
};

const _$RequirementStatusEnumMap = {
  RequirementStatus.unknown: 'unknown',
  RequirementStatus.required: 'required',
  RequirementStatus.notRequired: 'not_required',
};

const _$AttendanceStatusEnumMap = {
  AttendanceStatus.planned: 'planned',
  AttendanceStatus.attended: 'attended',
  AttendanceStatus.notAttended: 'not_attended',
  AttendanceStatus.canceled: 'canceled',
};

_$TicketImpl _$$TicketImplFromJson(Map<String, dynamic> json) => _$TicketImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      acquisitionStatus: $enumDecodeNullable(
              _$TicketAcquisitionEnumMap, json['acquisition_status']) ??
          TicketAcquisition.notApplied,
      paymentStatus:
          $enumDecodeNullable(_$TicketPaymentEnumMap, json['payment_status']) ??
              TicketPayment.unpaid,
      issuanceStatus: $enumDecodeNullable(
              _$TicketIssuanceEnumMap, json['issuance_status']) ??
          TicketIssuance.notIssued,
      seat: json['seat'] as String?,
      entryNumber: json['entry_number'] as String?,
      gate: json['gate'] as String?,
      url: json['url'] as String?,
      imagePath: json['image_path'] as String?,
      imageLocalPath: json['image_local_path'] as String?,
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TicketImplToJson(_$TicketImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'acquisition_status':
          _$TicketAcquisitionEnumMap[instance.acquisitionStatus]!,
      'payment_status': _$TicketPaymentEnumMap[instance.paymentStatus]!,
      'issuance_status': _$TicketIssuanceEnumMap[instance.issuanceStatus]!,
      'seat': instance.seat,
      'entry_number': instance.entryNumber,
      'gate': instance.gate,
      'url': instance.url,
      'image_path': instance.imagePath,
      'image_local_path': instance.imageLocalPath,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$TicketAcquisitionEnumMap = {
  TicketAcquisition.notApplied: 'not_applied',
  TicketAcquisition.applied: 'applied',
  TicketAcquisition.won: 'won',
  TicketAcquisition.lost: 'lost',
  TicketAcquisition.acquired: 'acquired',
};

const _$TicketPaymentEnumMap = {
  TicketPayment.unpaid: 'unpaid',
  TicketPayment.paid: 'paid',
  TicketPayment.notRequired: 'not_required',
};

const _$TicketIssuanceEnumMap = {
  TicketIssuance.notIssued: 'not_issued',
  TicketIssuance.issued: 'issued',
  TicketIssuance.digital: 'digital',
};

_$TransportImpl _$$TransportImplFromJson(Map<String, dynamic> json) =>
    _$TransportImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      direction:
          $enumDecodeNullable(_$TransportDirectionEnumMap, json['direction']) ??
              TransportDirection.outbound,
      method: $enumDecodeNullable(_$TransportMethodEnumMap, json['method']),
      methodOther: json['method_other'] as String?,
      fromPlace: json['from_place'] as String?,
      toPlace: json['to_place'] as String?,
      departAt: const NullableUtcDateTimeConverter()
          .fromJson(json['depart_at'] as String?),
      arriveAt: const NullableUtcDateTimeConverter()
          .fromJson(json['arrive_at'] as String?),
      reservationNumber: json['reservation_number'] as String?,
      url: json['url'] as String?,
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$TransportImplToJson(_$TransportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'direction': _$TransportDirectionEnumMap[instance.direction]!,
      'method': _$TransportMethodEnumMap[instance.method],
      'method_other': instance.methodOther,
      'from_place': instance.fromPlace,
      'to_place': instance.toPlace,
      'depart_at':
          const NullableUtcDateTimeConverter().toJson(instance.departAt),
      'arrive_at':
          const NullableUtcDateTimeConverter().toJson(instance.arriveAt),
      'reservation_number': instance.reservationNumber,
      'url': instance.url,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$TransportDirectionEnumMap = {
  TransportDirection.outbound: 'outbound',
  TransportDirection.inbound: 'inbound',
};

const _$TransportMethodEnumMap = {
  TransportMethod.shinkansen: 'shinkansen',
  TransportMethod.train: 'train',
  TransportMethod.airplane: 'airplane',
  TransportMethod.highwayBus: 'highway_bus',
  TransportMethod.localBus: 'local_bus',
  TransportMethod.privateCar: 'private_car',
  TransportMethod.rentalCar: 'rental_car',
  TransportMethod.ferry: 'ferry',
  TransportMethod.taxi: 'taxi',
  TransportMethod.walkBicycle: 'walk_bicycle',
  TransportMethod.other: 'other',
};

_$LodgingImpl _$$LodgingImplFromJson(Map<String, dynamic> json) =>
    _$LodgingImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String?,
      checkinDate: const NullableDateOnlyConverter()
          .fromJson(json['checkin_date'] as String?),
      checkoutDate: const NullableDateOnlyConverter()
          .fromJson(json['checkout_date'] as String?),
      address: json['address'] as String?,
      reservationNumber: json['reservation_number'] as String?,
      url: json['url'] as String?,
      memo: json['memo'] as String?,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$LodgingImplToJson(_$LodgingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'checkin_date':
          const NullableDateOnlyConverter().toJson(instance.checkinDate),
      'checkout_date':
          const NullableDateOnlyConverter().toJson(instance.checkoutDate),
      'address': instance.address,
      'reservation_number': instance.reservationNumber,
      'url': instance.url,
      'memo': instance.memo,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

_$GenbaTodoImpl _$$GenbaTodoImplFromJson(Map<String, dynamic> json) =>
    _$GenbaTodoImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      type: $enumDecodeNullable(_$TodoItemTypeEnumMap, json['type']) ??
          TodoItemType.todo,
      dueDate: const NullableDateOnlyConverter()
          .fromJson(json['due_date'] as String?),
      isDone: json['is_done'] as bool? ?? false,
      assignee: json['assignee'] as String?,
      priority: $enumDecodeNullable(_$TodoPriorityEnumMap, json['priority']) ??
          TodoPriority.normal,
      memo: json['memo'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$GenbaTodoImplToJson(_$GenbaTodoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'name': instance.name,
      'type': _$TodoItemTypeEnumMap[instance.type]!,
      'due_date': const NullableDateOnlyConverter().toJson(instance.dueDate),
      'is_done': instance.isDone,
      'assignee': instance.assignee,
      'priority': _$TodoPriorityEnumMap[instance.priority]!,
      'memo': instance.memo,
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$TodoItemTypeEnumMap = {
  TodoItemType.todo: 'todo',
  TodoItemType.belonging: 'belonging',
};

const _$TodoPriorityEnumMap = {
  TodoPriority.low: 'low',
  TodoPriority.normal: 'normal',
  TodoPriority.high: 'high',
};

_$GenbaMemoImpl _$$GenbaMemoImplFromJson(Map<String, dynamic> json) =>
    _$GenbaMemoImpl(
      id: json['id'] as String,
      genbaId: json['genba_id'] as String,
      ownerId: json['owner_id'] as String,
      category: $enumDecodeNullable(_$MemoCategoryEnumMap, json['category']) ??
          MemoCategory.other,
      kind:
          $enumDecodeNullable(_$MemoKindEnumMap, json['kind']) ?? MemoKind.free,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      content: json['content'] == null
          ? null
          : MemoContent.fromJson(json['content'] as Map<String, dynamic>),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt:
          const UtcDateTimeConverter().fromJson(json['created_at'] as String),
      updatedAt:
          const UtcDateTimeConverter().fromJson(json['updated_at'] as String),
    );

Map<String, dynamic> _$$GenbaMemoImplToJson(_$GenbaMemoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genba_id': instance.genbaId,
      'owner_id': instance.ownerId,
      'category': _$MemoCategoryEnumMap[instance.category]!,
      'kind': _$MemoKindEnumMap[instance.kind]!,
      'title': instance.title,
      'body': instance.body,
      'content': instance.content?.toJson(),
      'sort_order': instance.sortOrder,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };

const _$MemoCategoryEnumMap = {
  MemoCategory.free: 'free',
  MemoCategory.goods: 'goods',
  MemoCategory.meetup: 'meetup',
  MemoCategory.around: 'around',
  MemoCategory.notice: 'notice',
  MemoCategory.other: 'other',
};

const _$MemoKindEnumMap = {
  MemoKind.free: 'free',
  MemoKind.checklist: 'checklist',
  MemoKind.bingo: 'bingo',
  MemoKind.vote: 'vote',
};
