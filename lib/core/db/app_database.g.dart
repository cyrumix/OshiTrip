// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GenbasTable extends Genbas with TableInfo<$GenbasTable, GenbaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenbasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistNameMeta =
      const VerificationMeta('artistName');
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
      'artist_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventDateMeta =
      const VerificationMeta('eventDate');
  @override
  late final GeneratedColumn<String> eventDate = GeneratedColumn<String>(
      'event_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _oshiGroupIdMeta =
      const VerificationMeta('oshiGroupId');
  @override
  late final GeneratedColumn<String> oshiGroupId = GeneratedColumn<String>(
      'oshi_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _oshiMemberIdsMeta =
      const VerificationMeta('oshiMemberIds');
  @override
  late final GeneratedColumn<String> oshiMemberIds = GeneratedColumn<String>(
      'oshi_member_ids', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  @override
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
      'venue', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _doorTimeMinutesMeta =
      const VerificationMeta('doorTimeMinutes');
  @override
  late final GeneratedColumn<int> doorTimeMinutes = GeneratedColumn<int>(
      'door_time_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMinutesMeta =
      const VerificationMeta('startTimeMinutes');
  @override
  late final GeneratedColumn<int> startTimeMinutes = GeneratedColumn<int>(
      'start_time_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMinutesMeta =
      const VerificationMeta('endTimeMinutes');
  @override
  late final GeneratedColumn<int> endTimeMinutes = GeneratedColumn<int>(
      'end_time_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _performanceTypeMeta =
      const VerificationMeta('performanceType');
  @override
  late final GeneratedColumn<String> performanceType = GeneratedColumn<String>(
      'performance_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _performanceIdMeta =
      const VerificationMeta('performanceId');
  @override
  late final GeneratedColumn<String> performanceId = GeneratedColumn<String>(
      'performance_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isExpeditionMeta =
      const VerificationMeta('isExpedition');
  @override
  late final GeneratedColumn<bool> isExpedition = GeneratedColumn<bool>(
      'is_expedition', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_expedition" IN (0, 1))'));
  static const VerificationMeta _transportRequirementMeta =
      const VerificationMeta('transportRequirement');
  @override
  late final GeneratedColumn<String> transportRequirement =
      GeneratedColumn<String>('transport_requirement', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('unknown'));
  static const VerificationMeta _lodgingRequirementMeta =
      const VerificationMeta('lodgingRequirement');
  @override
  late final GeneratedColumn<String> lodgingRequirement =
      GeneratedColumn<String>('lodging_requirement', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('unknown'));
  static const VerificationMeta _isCanceledMeta =
      const VerificationMeta('isCanceled');
  @override
  late final GeneratedColumn<bool> isCanceled = GeneratedColumn<bool>(
      'is_canceled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_canceled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _attendanceStatusMeta =
      const VerificationMeta('attendanceStatus');
  @override
  late final GeneratedColumn<String> attendanceStatus = GeneratedColumn<String>(
      'attendance_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('planned'));
  static const VerificationMeta _manualEndedAtMeta =
      const VerificationMeta('manualEndedAt');
  @override
  late final GeneratedColumn<String> manualEndedAt = GeneratedColumn<String>(
      'manual_ended_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heroImageLocalPathMeta =
      const VerificationMeta('heroImageLocalPath');
  @override
  late final GeneratedColumn<String> heroImageLocalPath =
      GeneratedColumn<String>('hero_image_local_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heroImageStoragePathMeta =
      const VerificationMeta('heroImageStoragePath');
  @override
  late final GeneratedColumn<String> heroImageStoragePath =
      GeneratedColumn<String>('hero_image_storage_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _heroImageUploadStatusMeta =
      const VerificationMeta('heroImageUploadStatus');
  @override
  late final GeneratedColumn<String> heroImageUploadStatus =
      GeneratedColumn<String>('hero_image_upload_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('local_only'));
  static const VerificationMeta _heroImageAltTextMeta =
      const VerificationMeta('heroImageAltText');
  @override
  late final GeneratedColumn<String> heroImageAltText = GeneratedColumn<String>(
      'hero_image_alt_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ownerId,
        artistName,
        title,
        eventDate,
        oshiGroupId,
        oshiMemberIds,
        venue,
        doorTimeMinutes,
        startTimeMinutes,
        endTimeMinutes,
        performanceType,
        performanceId,
        isExpedition,
        transportRequirement,
        lodgingRequirement,
        isCanceled,
        attendanceStatus,
        manualEndedAt,
        heroImageLocalPath,
        heroImageStoragePath,
        heroImageUploadStatus,
        heroImageAltText,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genbas';
  @override
  VerificationContext validateIntegrity(Insertable<GenbaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
          _artistNameMeta,
          artistName.isAcceptableOrUnknown(
              data['artist_name']!, _artistNameMeta));
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(_eventDateMeta,
          eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta));
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('oshi_group_id')) {
      context.handle(
          _oshiGroupIdMeta,
          oshiGroupId.isAcceptableOrUnknown(
              data['oshi_group_id']!, _oshiGroupIdMeta));
    }
    if (data.containsKey('oshi_member_ids')) {
      context.handle(
          _oshiMemberIdsMeta,
          oshiMemberIds.isAcceptableOrUnknown(
              data['oshi_member_ids']!, _oshiMemberIdsMeta));
    }
    if (data.containsKey('venue')) {
      context.handle(
          _venueMeta, venue.isAcceptableOrUnknown(data['venue']!, _venueMeta));
    }
    if (data.containsKey('door_time_minutes')) {
      context.handle(
          _doorTimeMinutesMeta,
          doorTimeMinutes.isAcceptableOrUnknown(
              data['door_time_minutes']!, _doorTimeMinutesMeta));
    }
    if (data.containsKey('start_time_minutes')) {
      context.handle(
          _startTimeMinutesMeta,
          startTimeMinutes.isAcceptableOrUnknown(
              data['start_time_minutes']!, _startTimeMinutesMeta));
    }
    if (data.containsKey('end_time_minutes')) {
      context.handle(
          _endTimeMinutesMeta,
          endTimeMinutes.isAcceptableOrUnknown(
              data['end_time_minutes']!, _endTimeMinutesMeta));
    }
    if (data.containsKey('performance_type')) {
      context.handle(
          _performanceTypeMeta,
          performanceType.isAcceptableOrUnknown(
              data['performance_type']!, _performanceTypeMeta));
    }
    if (data.containsKey('performance_id')) {
      context.handle(
          _performanceIdMeta,
          performanceId.isAcceptableOrUnknown(
              data['performance_id']!, _performanceIdMeta));
    }
    if (data.containsKey('is_expedition')) {
      context.handle(
          _isExpeditionMeta,
          isExpedition.isAcceptableOrUnknown(
              data['is_expedition']!, _isExpeditionMeta));
    }
    if (data.containsKey('transport_requirement')) {
      context.handle(
          _transportRequirementMeta,
          transportRequirement.isAcceptableOrUnknown(
              data['transport_requirement']!, _transportRequirementMeta));
    }
    if (data.containsKey('lodging_requirement')) {
      context.handle(
          _lodgingRequirementMeta,
          lodgingRequirement.isAcceptableOrUnknown(
              data['lodging_requirement']!, _lodgingRequirementMeta));
    }
    if (data.containsKey('is_canceled')) {
      context.handle(
          _isCanceledMeta,
          isCanceled.isAcceptableOrUnknown(
              data['is_canceled']!, _isCanceledMeta));
    }
    if (data.containsKey('attendance_status')) {
      context.handle(
          _attendanceStatusMeta,
          attendanceStatus.isAcceptableOrUnknown(
              data['attendance_status']!, _attendanceStatusMeta));
    }
    if (data.containsKey('manual_ended_at')) {
      context.handle(
          _manualEndedAtMeta,
          manualEndedAt.isAcceptableOrUnknown(
              data['manual_ended_at']!, _manualEndedAtMeta));
    }
    if (data.containsKey('hero_image_local_path')) {
      context.handle(
          _heroImageLocalPathMeta,
          heroImageLocalPath.isAcceptableOrUnknown(
              data['hero_image_local_path']!, _heroImageLocalPathMeta));
    }
    if (data.containsKey('hero_image_storage_path')) {
      context.handle(
          _heroImageStoragePathMeta,
          heroImageStoragePath.isAcceptableOrUnknown(
              data['hero_image_storage_path']!, _heroImageStoragePathMeta));
    }
    if (data.containsKey('hero_image_upload_status')) {
      context.handle(
          _heroImageUploadStatusMeta,
          heroImageUploadStatus.isAcceptableOrUnknown(
              data['hero_image_upload_status']!, _heroImageUploadStatusMeta));
    }
    if (data.containsKey('hero_image_alt_text')) {
      context.handle(
          _heroImageAltTextMeta,
          heroImageAltText.isAcceptableOrUnknown(
              data['hero_image_alt_text']!, _heroImageAltTextMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GenbaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenbaRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      artistName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_name'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      eventDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_date'])!,
      oshiGroupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}oshi_group_id']),
      oshiMemberIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}oshi_member_ids'])!,
      venue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue']),
      doorTimeMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}door_time_minutes']),
      startTimeMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time_minutes']),
      endTimeMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time_minutes']),
      performanceType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}performance_type']),
      performanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}performance_id']),
      isExpedition: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_expedition']),
      transportRequirement: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}transport_requirement'])!,
      lodgingRequirement: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}lodging_requirement'])!,
      isCanceled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_canceled'])!,
      attendanceStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attendance_status'])!,
      manualEndedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manual_ended_at']),
      heroImageLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hero_image_local_path']),
      heroImageStoragePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hero_image_storage_path']),
      heroImageUploadStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hero_image_upload_status'])!,
      heroImageAltText: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}hero_image_alt_text']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GenbasTable createAlias(String alias) {
    return $GenbasTable(attachedDatabase, alias);
  }
}

class GenbaRow extends DataClass implements Insertable<GenbaRow> {
  final String id;
  final String ownerId;
  final String artistName;
  final String title;
  final String eventDate;
  final String? oshiGroupId;
  final String oshiMemberIds;
  final String? venue;
  final int? doorTimeMinutes;
  final int? startTimeMinutes;
  final int? endTimeMinutes;
  final String? performanceType;
  final String? performanceId;
  final bool? isExpedition;
  final String transportRequirement;
  final String lodgingRequirement;
  final bool isCanceled;

  /// 明示参加状態（planned/attended/not_attended/canceled, schema v5）。
  /// 日時から自動導出しない。is_canceled と整合させる（normalizeAttendance）。
  final String attendanceStatus;
  final String? manualEndedAt;

  /// ヒーロー画像の端末内相対参照（同期対象外, H-04, schema v4）。
  final String? heroImageLocalPath;

  /// ヒーロー画像の Storage パス・アップロード状態・代替説明（同期対象, v5）。
  final String? heroImageStoragePath;
  final String heroImageUploadStatus;
  final String? heroImageAltText;
  final String createdAt;
  final String updatedAt;
  const GenbaRow(
      {required this.id,
      required this.ownerId,
      required this.artistName,
      required this.title,
      required this.eventDate,
      this.oshiGroupId,
      required this.oshiMemberIds,
      this.venue,
      this.doorTimeMinutes,
      this.startTimeMinutes,
      this.endTimeMinutes,
      this.performanceType,
      this.performanceId,
      this.isExpedition,
      required this.transportRequirement,
      required this.lodgingRequirement,
      required this.isCanceled,
      required this.attendanceStatus,
      this.manualEndedAt,
      this.heroImageLocalPath,
      this.heroImageStoragePath,
      required this.heroImageUploadStatus,
      this.heroImageAltText,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['artist_name'] = Variable<String>(artistName);
    map['title'] = Variable<String>(title);
    map['event_date'] = Variable<String>(eventDate);
    if (!nullToAbsent || oshiGroupId != null) {
      map['oshi_group_id'] = Variable<String>(oshiGroupId);
    }
    map['oshi_member_ids'] = Variable<String>(oshiMemberIds);
    if (!nullToAbsent || venue != null) {
      map['venue'] = Variable<String>(venue);
    }
    if (!nullToAbsent || doorTimeMinutes != null) {
      map['door_time_minutes'] = Variable<int>(doorTimeMinutes);
    }
    if (!nullToAbsent || startTimeMinutes != null) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes);
    }
    if (!nullToAbsent || endTimeMinutes != null) {
      map['end_time_minutes'] = Variable<int>(endTimeMinutes);
    }
    if (!nullToAbsent || performanceType != null) {
      map['performance_type'] = Variable<String>(performanceType);
    }
    if (!nullToAbsent || performanceId != null) {
      map['performance_id'] = Variable<String>(performanceId);
    }
    if (!nullToAbsent || isExpedition != null) {
      map['is_expedition'] = Variable<bool>(isExpedition);
    }
    map['transport_requirement'] = Variable<String>(transportRequirement);
    map['lodging_requirement'] = Variable<String>(lodgingRequirement);
    map['is_canceled'] = Variable<bool>(isCanceled);
    map['attendance_status'] = Variable<String>(attendanceStatus);
    if (!nullToAbsent || manualEndedAt != null) {
      map['manual_ended_at'] = Variable<String>(manualEndedAt);
    }
    if (!nullToAbsent || heroImageLocalPath != null) {
      map['hero_image_local_path'] = Variable<String>(heroImageLocalPath);
    }
    if (!nullToAbsent || heroImageStoragePath != null) {
      map['hero_image_storage_path'] = Variable<String>(heroImageStoragePath);
    }
    map['hero_image_upload_status'] = Variable<String>(heroImageUploadStatus);
    if (!nullToAbsent || heroImageAltText != null) {
      map['hero_image_alt_text'] = Variable<String>(heroImageAltText);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  GenbasCompanion toCompanion(bool nullToAbsent) {
    return GenbasCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      artistName: Value(artistName),
      title: Value(title),
      eventDate: Value(eventDate),
      oshiGroupId: oshiGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(oshiGroupId),
      oshiMemberIds: Value(oshiMemberIds),
      venue:
          venue == null && nullToAbsent ? const Value.absent() : Value(venue),
      doorTimeMinutes: doorTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(doorTimeMinutes),
      startTimeMinutes: startTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(startTimeMinutes),
      endTimeMinutes: endTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimeMinutes),
      performanceType: performanceType == null && nullToAbsent
          ? const Value.absent()
          : Value(performanceType),
      performanceId: performanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(performanceId),
      isExpedition: isExpedition == null && nullToAbsent
          ? const Value.absent()
          : Value(isExpedition),
      transportRequirement: Value(transportRequirement),
      lodgingRequirement: Value(lodgingRequirement),
      isCanceled: Value(isCanceled),
      attendanceStatus: Value(attendanceStatus),
      manualEndedAt: manualEndedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(manualEndedAt),
      heroImageLocalPath: heroImageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(heroImageLocalPath),
      heroImageStoragePath: heroImageStoragePath == null && nullToAbsent
          ? const Value.absent()
          : Value(heroImageStoragePath),
      heroImageUploadStatus: Value(heroImageUploadStatus),
      heroImageAltText: heroImageAltText == null && nullToAbsent
          ? const Value.absent()
          : Value(heroImageAltText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GenbaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenbaRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      artistName: serializer.fromJson<String>(json['artistName']),
      title: serializer.fromJson<String>(json['title']),
      eventDate: serializer.fromJson<String>(json['eventDate']),
      oshiGroupId: serializer.fromJson<String?>(json['oshiGroupId']),
      oshiMemberIds: serializer.fromJson<String>(json['oshiMemberIds']),
      venue: serializer.fromJson<String?>(json['venue']),
      doorTimeMinutes: serializer.fromJson<int?>(json['doorTimeMinutes']),
      startTimeMinutes: serializer.fromJson<int?>(json['startTimeMinutes']),
      endTimeMinutes: serializer.fromJson<int?>(json['endTimeMinutes']),
      performanceType: serializer.fromJson<String?>(json['performanceType']),
      performanceId: serializer.fromJson<String?>(json['performanceId']),
      isExpedition: serializer.fromJson<bool?>(json['isExpedition']),
      transportRequirement:
          serializer.fromJson<String>(json['transportRequirement']),
      lodgingRequirement:
          serializer.fromJson<String>(json['lodgingRequirement']),
      isCanceled: serializer.fromJson<bool>(json['isCanceled']),
      attendanceStatus: serializer.fromJson<String>(json['attendanceStatus']),
      manualEndedAt: serializer.fromJson<String?>(json['manualEndedAt']),
      heroImageLocalPath:
          serializer.fromJson<String?>(json['heroImageLocalPath']),
      heroImageStoragePath:
          serializer.fromJson<String?>(json['heroImageStoragePath']),
      heroImageUploadStatus:
          serializer.fromJson<String>(json['heroImageUploadStatus']),
      heroImageAltText: serializer.fromJson<String?>(json['heroImageAltText']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'artistName': serializer.toJson<String>(artistName),
      'title': serializer.toJson<String>(title),
      'eventDate': serializer.toJson<String>(eventDate),
      'oshiGroupId': serializer.toJson<String?>(oshiGroupId),
      'oshiMemberIds': serializer.toJson<String>(oshiMemberIds),
      'venue': serializer.toJson<String?>(venue),
      'doorTimeMinutes': serializer.toJson<int?>(doorTimeMinutes),
      'startTimeMinutes': serializer.toJson<int?>(startTimeMinutes),
      'endTimeMinutes': serializer.toJson<int?>(endTimeMinutes),
      'performanceType': serializer.toJson<String?>(performanceType),
      'performanceId': serializer.toJson<String?>(performanceId),
      'isExpedition': serializer.toJson<bool?>(isExpedition),
      'transportRequirement': serializer.toJson<String>(transportRequirement),
      'lodgingRequirement': serializer.toJson<String>(lodgingRequirement),
      'isCanceled': serializer.toJson<bool>(isCanceled),
      'attendanceStatus': serializer.toJson<String>(attendanceStatus),
      'manualEndedAt': serializer.toJson<String?>(manualEndedAt),
      'heroImageLocalPath': serializer.toJson<String?>(heroImageLocalPath),
      'heroImageStoragePath': serializer.toJson<String?>(heroImageStoragePath),
      'heroImageUploadStatus': serializer.toJson<String>(heroImageUploadStatus),
      'heroImageAltText': serializer.toJson<String?>(heroImageAltText),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  GenbaRow copyWith(
          {String? id,
          String? ownerId,
          String? artistName,
          String? title,
          String? eventDate,
          Value<String?> oshiGroupId = const Value.absent(),
          String? oshiMemberIds,
          Value<String?> venue = const Value.absent(),
          Value<int?> doorTimeMinutes = const Value.absent(),
          Value<int?> startTimeMinutes = const Value.absent(),
          Value<int?> endTimeMinutes = const Value.absent(),
          Value<String?> performanceType = const Value.absent(),
          Value<String?> performanceId = const Value.absent(),
          Value<bool?> isExpedition = const Value.absent(),
          String? transportRequirement,
          String? lodgingRequirement,
          bool? isCanceled,
          String? attendanceStatus,
          Value<String?> manualEndedAt = const Value.absent(),
          Value<String?> heroImageLocalPath = const Value.absent(),
          Value<String?> heroImageStoragePath = const Value.absent(),
          String? heroImageUploadStatus,
          Value<String?> heroImageAltText = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      GenbaRow(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        artistName: artistName ?? this.artistName,
        title: title ?? this.title,
        eventDate: eventDate ?? this.eventDate,
        oshiGroupId: oshiGroupId.present ? oshiGroupId.value : this.oshiGroupId,
        oshiMemberIds: oshiMemberIds ?? this.oshiMemberIds,
        venue: venue.present ? venue.value : this.venue,
        doorTimeMinutes: doorTimeMinutes.present
            ? doorTimeMinutes.value
            : this.doorTimeMinutes,
        startTimeMinutes: startTimeMinutes.present
            ? startTimeMinutes.value
            : this.startTimeMinutes,
        endTimeMinutes:
            endTimeMinutes.present ? endTimeMinutes.value : this.endTimeMinutes,
        performanceType: performanceType.present
            ? performanceType.value
            : this.performanceType,
        performanceId:
            performanceId.present ? performanceId.value : this.performanceId,
        isExpedition:
            isExpedition.present ? isExpedition.value : this.isExpedition,
        transportRequirement: transportRequirement ?? this.transportRequirement,
        lodgingRequirement: lodgingRequirement ?? this.lodgingRequirement,
        isCanceled: isCanceled ?? this.isCanceled,
        attendanceStatus: attendanceStatus ?? this.attendanceStatus,
        manualEndedAt:
            manualEndedAt.present ? manualEndedAt.value : this.manualEndedAt,
        heroImageLocalPath: heroImageLocalPath.present
            ? heroImageLocalPath.value
            : this.heroImageLocalPath,
        heroImageStoragePath: heroImageStoragePath.present
            ? heroImageStoragePath.value
            : this.heroImageStoragePath,
        heroImageUploadStatus:
            heroImageUploadStatus ?? this.heroImageUploadStatus,
        heroImageAltText: heroImageAltText.present
            ? heroImageAltText.value
            : this.heroImageAltText,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GenbaRow copyWithCompanion(GenbasCompanion data) {
    return GenbaRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      artistName:
          data.artistName.present ? data.artistName.value : this.artistName,
      title: data.title.present ? data.title.value : this.title,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      oshiGroupId:
          data.oshiGroupId.present ? data.oshiGroupId.value : this.oshiGroupId,
      oshiMemberIds: data.oshiMemberIds.present
          ? data.oshiMemberIds.value
          : this.oshiMemberIds,
      venue: data.venue.present ? data.venue.value : this.venue,
      doorTimeMinutes: data.doorTimeMinutes.present
          ? data.doorTimeMinutes.value
          : this.doorTimeMinutes,
      startTimeMinutes: data.startTimeMinutes.present
          ? data.startTimeMinutes.value
          : this.startTimeMinutes,
      endTimeMinutes: data.endTimeMinutes.present
          ? data.endTimeMinutes.value
          : this.endTimeMinutes,
      performanceType: data.performanceType.present
          ? data.performanceType.value
          : this.performanceType,
      performanceId: data.performanceId.present
          ? data.performanceId.value
          : this.performanceId,
      isExpedition: data.isExpedition.present
          ? data.isExpedition.value
          : this.isExpedition,
      transportRequirement: data.transportRequirement.present
          ? data.transportRequirement.value
          : this.transportRequirement,
      lodgingRequirement: data.lodgingRequirement.present
          ? data.lodgingRequirement.value
          : this.lodgingRequirement,
      isCanceled:
          data.isCanceled.present ? data.isCanceled.value : this.isCanceled,
      attendanceStatus: data.attendanceStatus.present
          ? data.attendanceStatus.value
          : this.attendanceStatus,
      manualEndedAt: data.manualEndedAt.present
          ? data.manualEndedAt.value
          : this.manualEndedAt,
      heroImageLocalPath: data.heroImageLocalPath.present
          ? data.heroImageLocalPath.value
          : this.heroImageLocalPath,
      heroImageStoragePath: data.heroImageStoragePath.present
          ? data.heroImageStoragePath.value
          : this.heroImageStoragePath,
      heroImageUploadStatus: data.heroImageUploadStatus.present
          ? data.heroImageUploadStatus.value
          : this.heroImageUploadStatus,
      heroImageAltText: data.heroImageAltText.present
          ? data.heroImageAltText.value
          : this.heroImageAltText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenbaRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('artistName: $artistName, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('oshiGroupId: $oshiGroupId, ')
          ..write('oshiMemberIds: $oshiMemberIds, ')
          ..write('venue: $venue, ')
          ..write('doorTimeMinutes: $doorTimeMinutes, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('endTimeMinutes: $endTimeMinutes, ')
          ..write('performanceType: $performanceType, ')
          ..write('performanceId: $performanceId, ')
          ..write('isExpedition: $isExpedition, ')
          ..write('transportRequirement: $transportRequirement, ')
          ..write('lodgingRequirement: $lodgingRequirement, ')
          ..write('isCanceled: $isCanceled, ')
          ..write('attendanceStatus: $attendanceStatus, ')
          ..write('manualEndedAt: $manualEndedAt, ')
          ..write('heroImageLocalPath: $heroImageLocalPath, ')
          ..write('heroImageStoragePath: $heroImageStoragePath, ')
          ..write('heroImageUploadStatus: $heroImageUploadStatus, ')
          ..write('heroImageAltText: $heroImageAltText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        ownerId,
        artistName,
        title,
        eventDate,
        oshiGroupId,
        oshiMemberIds,
        venue,
        doorTimeMinutes,
        startTimeMinutes,
        endTimeMinutes,
        performanceType,
        performanceId,
        isExpedition,
        transportRequirement,
        lodgingRequirement,
        isCanceled,
        attendanceStatus,
        manualEndedAt,
        heroImageLocalPath,
        heroImageStoragePath,
        heroImageUploadStatus,
        heroImageAltText,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenbaRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.artistName == this.artistName &&
          other.title == this.title &&
          other.eventDate == this.eventDate &&
          other.oshiGroupId == this.oshiGroupId &&
          other.oshiMemberIds == this.oshiMemberIds &&
          other.venue == this.venue &&
          other.doorTimeMinutes == this.doorTimeMinutes &&
          other.startTimeMinutes == this.startTimeMinutes &&
          other.endTimeMinutes == this.endTimeMinutes &&
          other.performanceType == this.performanceType &&
          other.performanceId == this.performanceId &&
          other.isExpedition == this.isExpedition &&
          other.transportRequirement == this.transportRequirement &&
          other.lodgingRequirement == this.lodgingRequirement &&
          other.isCanceled == this.isCanceled &&
          other.attendanceStatus == this.attendanceStatus &&
          other.manualEndedAt == this.manualEndedAt &&
          other.heroImageLocalPath == this.heroImageLocalPath &&
          other.heroImageStoragePath == this.heroImageStoragePath &&
          other.heroImageUploadStatus == this.heroImageUploadStatus &&
          other.heroImageAltText == this.heroImageAltText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GenbasCompanion extends UpdateCompanion<GenbaRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> artistName;
  final Value<String> title;
  final Value<String> eventDate;
  final Value<String?> oshiGroupId;
  final Value<String> oshiMemberIds;
  final Value<String?> venue;
  final Value<int?> doorTimeMinutes;
  final Value<int?> startTimeMinutes;
  final Value<int?> endTimeMinutes;
  final Value<String?> performanceType;
  final Value<String?> performanceId;
  final Value<bool?> isExpedition;
  final Value<String> transportRequirement;
  final Value<String> lodgingRequirement;
  final Value<bool> isCanceled;
  final Value<String> attendanceStatus;
  final Value<String?> manualEndedAt;
  final Value<String?> heroImageLocalPath;
  final Value<String?> heroImageStoragePath;
  final Value<String> heroImageUploadStatus;
  final Value<String?> heroImageAltText;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const GenbasCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.artistName = const Value.absent(),
    this.title = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.oshiGroupId = const Value.absent(),
    this.oshiMemberIds = const Value.absent(),
    this.venue = const Value.absent(),
    this.doorTimeMinutes = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.endTimeMinutes = const Value.absent(),
    this.performanceType = const Value.absent(),
    this.performanceId = const Value.absent(),
    this.isExpedition = const Value.absent(),
    this.transportRequirement = const Value.absent(),
    this.lodgingRequirement = const Value.absent(),
    this.isCanceled = const Value.absent(),
    this.attendanceStatus = const Value.absent(),
    this.manualEndedAt = const Value.absent(),
    this.heroImageLocalPath = const Value.absent(),
    this.heroImageStoragePath = const Value.absent(),
    this.heroImageUploadStatus = const Value.absent(),
    this.heroImageAltText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenbasCompanion.insert({
    required String id,
    required String ownerId,
    required String artistName,
    required String title,
    required String eventDate,
    this.oshiGroupId = const Value.absent(),
    this.oshiMemberIds = const Value.absent(),
    this.venue = const Value.absent(),
    this.doorTimeMinutes = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.endTimeMinutes = const Value.absent(),
    this.performanceType = const Value.absent(),
    this.performanceId = const Value.absent(),
    this.isExpedition = const Value.absent(),
    this.transportRequirement = const Value.absent(),
    this.lodgingRequirement = const Value.absent(),
    this.isCanceled = const Value.absent(),
    this.attendanceStatus = const Value.absent(),
    this.manualEndedAt = const Value.absent(),
    this.heroImageLocalPath = const Value.absent(),
    this.heroImageStoragePath = const Value.absent(),
    this.heroImageUploadStatus = const Value.absent(),
    this.heroImageAltText = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ownerId = Value(ownerId),
        artistName = Value(artistName),
        title = Value(title),
        eventDate = Value(eventDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<GenbaRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? artistName,
    Expression<String>? title,
    Expression<String>? eventDate,
    Expression<String>? oshiGroupId,
    Expression<String>? oshiMemberIds,
    Expression<String>? venue,
    Expression<int>? doorTimeMinutes,
    Expression<int>? startTimeMinutes,
    Expression<int>? endTimeMinutes,
    Expression<String>? performanceType,
    Expression<String>? performanceId,
    Expression<bool>? isExpedition,
    Expression<String>? transportRequirement,
    Expression<String>? lodgingRequirement,
    Expression<bool>? isCanceled,
    Expression<String>? attendanceStatus,
    Expression<String>? manualEndedAt,
    Expression<String>? heroImageLocalPath,
    Expression<String>? heroImageStoragePath,
    Expression<String>? heroImageUploadStatus,
    Expression<String>? heroImageAltText,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (artistName != null) 'artist_name': artistName,
      if (title != null) 'title': title,
      if (eventDate != null) 'event_date': eventDate,
      if (oshiGroupId != null) 'oshi_group_id': oshiGroupId,
      if (oshiMemberIds != null) 'oshi_member_ids': oshiMemberIds,
      if (venue != null) 'venue': venue,
      if (doorTimeMinutes != null) 'door_time_minutes': doorTimeMinutes,
      if (startTimeMinutes != null) 'start_time_minutes': startTimeMinutes,
      if (endTimeMinutes != null) 'end_time_minutes': endTimeMinutes,
      if (performanceType != null) 'performance_type': performanceType,
      if (performanceId != null) 'performance_id': performanceId,
      if (isExpedition != null) 'is_expedition': isExpedition,
      if (transportRequirement != null)
        'transport_requirement': transportRequirement,
      if (lodgingRequirement != null) 'lodging_requirement': lodgingRequirement,
      if (isCanceled != null) 'is_canceled': isCanceled,
      if (attendanceStatus != null) 'attendance_status': attendanceStatus,
      if (manualEndedAt != null) 'manual_ended_at': manualEndedAt,
      if (heroImageLocalPath != null)
        'hero_image_local_path': heroImageLocalPath,
      if (heroImageStoragePath != null)
        'hero_image_storage_path': heroImageStoragePath,
      if (heroImageUploadStatus != null)
        'hero_image_upload_status': heroImageUploadStatus,
      if (heroImageAltText != null) 'hero_image_alt_text': heroImageAltText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenbasCompanion copyWith(
      {Value<String>? id,
      Value<String>? ownerId,
      Value<String>? artistName,
      Value<String>? title,
      Value<String>? eventDate,
      Value<String?>? oshiGroupId,
      Value<String>? oshiMemberIds,
      Value<String?>? venue,
      Value<int?>? doorTimeMinutes,
      Value<int?>? startTimeMinutes,
      Value<int?>? endTimeMinutes,
      Value<String?>? performanceType,
      Value<String?>? performanceId,
      Value<bool?>? isExpedition,
      Value<String>? transportRequirement,
      Value<String>? lodgingRequirement,
      Value<bool>? isCanceled,
      Value<String>? attendanceStatus,
      Value<String?>? manualEndedAt,
      Value<String?>? heroImageLocalPath,
      Value<String?>? heroImageStoragePath,
      Value<String>? heroImageUploadStatus,
      Value<String?>? heroImageAltText,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return GenbasCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      artistName: artistName ?? this.artistName,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      oshiGroupId: oshiGroupId ?? this.oshiGroupId,
      oshiMemberIds: oshiMemberIds ?? this.oshiMemberIds,
      venue: venue ?? this.venue,
      doorTimeMinutes: doorTimeMinutes ?? this.doorTimeMinutes,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      endTimeMinutes: endTimeMinutes ?? this.endTimeMinutes,
      performanceType: performanceType ?? this.performanceType,
      performanceId: performanceId ?? this.performanceId,
      isExpedition: isExpedition ?? this.isExpedition,
      transportRequirement: transportRequirement ?? this.transportRequirement,
      lodgingRequirement: lodgingRequirement ?? this.lodgingRequirement,
      isCanceled: isCanceled ?? this.isCanceled,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      manualEndedAt: manualEndedAt ?? this.manualEndedAt,
      heroImageLocalPath: heroImageLocalPath ?? this.heroImageLocalPath,
      heroImageStoragePath: heroImageStoragePath ?? this.heroImageStoragePath,
      heroImageUploadStatus:
          heroImageUploadStatus ?? this.heroImageUploadStatus,
      heroImageAltText: heroImageAltText ?? this.heroImageAltText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<String>(eventDate.value);
    }
    if (oshiGroupId.present) {
      map['oshi_group_id'] = Variable<String>(oshiGroupId.value);
    }
    if (oshiMemberIds.present) {
      map['oshi_member_ids'] = Variable<String>(oshiMemberIds.value);
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (doorTimeMinutes.present) {
      map['door_time_minutes'] = Variable<int>(doorTimeMinutes.value);
    }
    if (startTimeMinutes.present) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes.value);
    }
    if (endTimeMinutes.present) {
      map['end_time_minutes'] = Variable<int>(endTimeMinutes.value);
    }
    if (performanceType.present) {
      map['performance_type'] = Variable<String>(performanceType.value);
    }
    if (performanceId.present) {
      map['performance_id'] = Variable<String>(performanceId.value);
    }
    if (isExpedition.present) {
      map['is_expedition'] = Variable<bool>(isExpedition.value);
    }
    if (transportRequirement.present) {
      map['transport_requirement'] =
          Variable<String>(transportRequirement.value);
    }
    if (lodgingRequirement.present) {
      map['lodging_requirement'] = Variable<String>(lodgingRequirement.value);
    }
    if (isCanceled.present) {
      map['is_canceled'] = Variable<bool>(isCanceled.value);
    }
    if (attendanceStatus.present) {
      map['attendance_status'] = Variable<String>(attendanceStatus.value);
    }
    if (manualEndedAt.present) {
      map['manual_ended_at'] = Variable<String>(manualEndedAt.value);
    }
    if (heroImageLocalPath.present) {
      map['hero_image_local_path'] = Variable<String>(heroImageLocalPath.value);
    }
    if (heroImageStoragePath.present) {
      map['hero_image_storage_path'] =
          Variable<String>(heroImageStoragePath.value);
    }
    if (heroImageUploadStatus.present) {
      map['hero_image_upload_status'] =
          Variable<String>(heroImageUploadStatus.value);
    }
    if (heroImageAltText.present) {
      map['hero_image_alt_text'] = Variable<String>(heroImageAltText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenbasCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('artistName: $artistName, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('oshiGroupId: $oshiGroupId, ')
          ..write('oshiMemberIds: $oshiMemberIds, ')
          ..write('venue: $venue, ')
          ..write('doorTimeMinutes: $doorTimeMinutes, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('endTimeMinutes: $endTimeMinutes, ')
          ..write('performanceType: $performanceType, ')
          ..write('performanceId: $performanceId, ')
          ..write('isExpedition: $isExpedition, ')
          ..write('transportRequirement: $transportRequirement, ')
          ..write('lodgingRequirement: $lodgingRequirement, ')
          ..write('isCanceled: $isCanceled, ')
          ..write('attendanceStatus: $attendanceStatus, ')
          ..write('manualEndedAt: $manualEndedAt, ')
          ..write('heroImageLocalPath: $heroImageLocalPath, ')
          ..write('heroImageStoragePath: $heroImageStoragePath, ')
          ..write('heroImageUploadStatus: $heroImageUploadStatus, ')
          ..write('heroImageAltText: $heroImageAltText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TicketsTable extends Tickets with TableInfo<$TicketsTable, TicketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _acquisitionStatusMeta =
      const VerificationMeta('acquisitionStatus');
  @override
  late final GeneratedColumn<String> acquisitionStatus =
      GeneratedColumn<String>('acquisition_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('not_applied'));
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unpaid'));
  static const VerificationMeta _issuanceStatusMeta =
      const VerificationMeta('issuanceStatus');
  @override
  late final GeneratedColumn<String> issuanceStatus = GeneratedColumn<String>(
      'issuance_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('not_issued'));
  static const VerificationMeta _seatMeta = const VerificationMeta('seat');
  @override
  late final GeneratedColumn<String> seat = GeneratedColumn<String>(
      'seat', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entryNumberMeta =
      const VerificationMeta('entryNumber');
  @override
  late final GeneratedColumn<String> entryNumber = GeneratedColumn<String>(
      'entry_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gateMeta = const VerificationMeta('gate');
  @override
  late final GeneratedColumn<String> gate = GeneratedColumn<String>(
      'gate', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageLocalPathMeta =
      const VerificationMeta('imageLocalPath');
  @override
  late final GeneratedColumn<String> imageLocalPath = GeneratedColumn<String>(
      'image_local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        genbaId,
        ownerId,
        acquisitionStatus,
        paymentStatus,
        issuanceStatus,
        seat,
        entryNumber,
        gate,
        url,
        imagePath,
        imageLocalPath,
        memo,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tickets';
  @override
  VerificationContext validateIntegrity(Insertable<TicketRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('acquisition_status')) {
      context.handle(
          _acquisitionStatusMeta,
          acquisitionStatus.isAcceptableOrUnknown(
              data['acquisition_status']!, _acquisitionStatusMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('issuance_status')) {
      context.handle(
          _issuanceStatusMeta,
          issuanceStatus.isAcceptableOrUnknown(
              data['issuance_status']!, _issuanceStatusMeta));
    }
    if (data.containsKey('seat')) {
      context.handle(
          _seatMeta, seat.isAcceptableOrUnknown(data['seat']!, _seatMeta));
    }
    if (data.containsKey('entry_number')) {
      context.handle(
          _entryNumberMeta,
          entryNumber.isAcceptableOrUnknown(
              data['entry_number']!, _entryNumberMeta));
    }
    if (data.containsKey('gate')) {
      context.handle(
          _gateMeta, gate.isAcceptableOrUnknown(data['gate']!, _gateMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('image_local_path')) {
      context.handle(
          _imageLocalPathMeta,
          imageLocalPath.isAcceptableOrUnknown(
              data['image_local_path']!, _imageLocalPathMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TicketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TicketRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      acquisitionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}acquisition_status'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      issuanceStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}issuance_status'])!,
      seat: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seat']),
      entryNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_number']),
      gate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gate']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      imageLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_local_path']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TicketsTable createAlias(String alias) {
    return $TicketsTable(attachedDatabase, alias);
  }
}

class TicketRow extends DataClass implements Insertable<TicketRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String acquisitionStatus;
  final String paymentStatus;
  final String issuanceStatus;
  final String? seat;
  final String? entryNumber;
  final String? gate;
  final String? url;
  final String? imagePath;
  final String? imageLocalPath;
  final String? memo;
  final String createdAt;
  final String updatedAt;
  const TicketRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.acquisitionStatus,
      required this.paymentStatus,
      required this.issuanceStatus,
      this.seat,
      this.entryNumber,
      this.gate,
      this.url,
      this.imagePath,
      this.imageLocalPath,
      this.memo,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['acquisition_status'] = Variable<String>(acquisitionStatus);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['issuance_status'] = Variable<String>(issuanceStatus);
    if (!nullToAbsent || seat != null) {
      map['seat'] = Variable<String>(seat);
    }
    if (!nullToAbsent || entryNumber != null) {
      map['entry_number'] = Variable<String>(entryNumber);
    }
    if (!nullToAbsent || gate != null) {
      map['gate'] = Variable<String>(gate);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || imageLocalPath != null) {
      map['image_local_path'] = Variable<String>(imageLocalPath);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TicketsCompanion toCompanion(bool nullToAbsent) {
    return TicketsCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      acquisitionStatus: Value(acquisitionStatus),
      paymentStatus: Value(paymentStatus),
      issuanceStatus: Value(issuanceStatus),
      seat: seat == null && nullToAbsent ? const Value.absent() : Value(seat),
      entryNumber: entryNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(entryNumber),
      gate: gate == null && nullToAbsent ? const Value.absent() : Value(gate),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      imageLocalPath: imageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageLocalPath),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TicketRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TicketRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      acquisitionStatus: serializer.fromJson<String>(json['acquisitionStatus']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      issuanceStatus: serializer.fromJson<String>(json['issuanceStatus']),
      seat: serializer.fromJson<String?>(json['seat']),
      entryNumber: serializer.fromJson<String?>(json['entryNumber']),
      gate: serializer.fromJson<String?>(json['gate']),
      url: serializer.fromJson<String?>(json['url']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      imageLocalPath: serializer.fromJson<String?>(json['imageLocalPath']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'acquisitionStatus': serializer.toJson<String>(acquisitionStatus),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'issuanceStatus': serializer.toJson<String>(issuanceStatus),
      'seat': serializer.toJson<String?>(seat),
      'entryNumber': serializer.toJson<String?>(entryNumber),
      'gate': serializer.toJson<String?>(gate),
      'url': serializer.toJson<String?>(url),
      'imagePath': serializer.toJson<String?>(imagePath),
      'imageLocalPath': serializer.toJson<String?>(imageLocalPath),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TicketRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? acquisitionStatus,
          String? paymentStatus,
          String? issuanceStatus,
          Value<String?> seat = const Value.absent(),
          Value<String?> entryNumber = const Value.absent(),
          Value<String?> gate = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          Value<String?> imageLocalPath = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      TicketRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        acquisitionStatus: acquisitionStatus ?? this.acquisitionStatus,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        issuanceStatus: issuanceStatus ?? this.issuanceStatus,
        seat: seat.present ? seat.value : this.seat,
        entryNumber: entryNumber.present ? entryNumber.value : this.entryNumber,
        gate: gate.present ? gate.value : this.gate,
        url: url.present ? url.value : this.url,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        imageLocalPath:
            imageLocalPath.present ? imageLocalPath.value : this.imageLocalPath,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TicketRow copyWithCompanion(TicketsCompanion data) {
    return TicketRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      acquisitionStatus: data.acquisitionStatus.present
          ? data.acquisitionStatus.value
          : this.acquisitionStatus,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      issuanceStatus: data.issuanceStatus.present
          ? data.issuanceStatus.value
          : this.issuanceStatus,
      seat: data.seat.present ? data.seat.value : this.seat,
      entryNumber:
          data.entryNumber.present ? data.entryNumber.value : this.entryNumber,
      gate: data.gate.present ? data.gate.value : this.gate,
      url: data.url.present ? data.url.value : this.url,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imageLocalPath: data.imageLocalPath.present
          ? data.imageLocalPath.value
          : this.imageLocalPath,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TicketRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('acquisitionStatus: $acquisitionStatus, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('issuanceStatus: $issuanceStatus, ')
          ..write('seat: $seat, ')
          ..write('entryNumber: $entryNumber, ')
          ..write('gate: $gate, ')
          ..write('url: $url, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      genbaId,
      ownerId,
      acquisitionStatus,
      paymentStatus,
      issuanceStatus,
      seat,
      entryNumber,
      gate,
      url,
      imagePath,
      imageLocalPath,
      memo,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.acquisitionStatus == this.acquisitionStatus &&
          other.paymentStatus == this.paymentStatus &&
          other.issuanceStatus == this.issuanceStatus &&
          other.seat == this.seat &&
          other.entryNumber == this.entryNumber &&
          other.gate == this.gate &&
          other.url == this.url &&
          other.imagePath == this.imagePath &&
          other.imageLocalPath == this.imageLocalPath &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TicketsCompanion extends UpdateCompanion<TicketRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> acquisitionStatus;
  final Value<String> paymentStatus;
  final Value<String> issuanceStatus;
  final Value<String?> seat;
  final Value<String?> entryNumber;
  final Value<String?> gate;
  final Value<String?> url;
  final Value<String?> imagePath;
  final Value<String?> imageLocalPath;
  final Value<String?> memo;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TicketsCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.acquisitionStatus = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.issuanceStatus = const Value.absent(),
    this.seat = const Value.absent(),
    this.entryNumber = const Value.absent(),
    this.gate = const Value.absent(),
    this.url = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TicketsCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    this.acquisitionStatus = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.issuanceStatus = const Value.absent(),
    this.seat = const Value.absent(),
    this.entryNumber = const Value.absent(),
    this.gate = const Value.absent(),
    this.url = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.memo = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TicketRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? acquisitionStatus,
    Expression<String>? paymentStatus,
    Expression<String>? issuanceStatus,
    Expression<String>? seat,
    Expression<String>? entryNumber,
    Expression<String>? gate,
    Expression<String>? url,
    Expression<String>? imagePath,
    Expression<String>? imageLocalPath,
    Expression<String>? memo,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (acquisitionStatus != null) 'acquisition_status': acquisitionStatus,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (issuanceStatus != null) 'issuance_status': issuanceStatus,
      if (seat != null) 'seat': seat,
      if (entryNumber != null) 'entry_number': entryNumber,
      if (gate != null) 'gate': gate,
      if (url != null) 'url': url,
      if (imagePath != null) 'image_path': imagePath,
      if (imageLocalPath != null) 'image_local_path': imageLocalPath,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TicketsCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? acquisitionStatus,
      Value<String>? paymentStatus,
      Value<String>? issuanceStatus,
      Value<String?>? seat,
      Value<String?>? entryNumber,
      Value<String?>? gate,
      Value<String?>? url,
      Value<String?>? imagePath,
      Value<String?>? imageLocalPath,
      Value<String?>? memo,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return TicketsCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      acquisitionStatus: acquisitionStatus ?? this.acquisitionStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      issuanceStatus: issuanceStatus ?? this.issuanceStatus,
      seat: seat ?? this.seat,
      entryNumber: entryNumber ?? this.entryNumber,
      gate: gate ?? this.gate,
      url: url ?? this.url,
      imagePath: imagePath ?? this.imagePath,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (acquisitionStatus.present) {
      map['acquisition_status'] = Variable<String>(acquisitionStatus.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (issuanceStatus.present) {
      map['issuance_status'] = Variable<String>(issuanceStatus.value);
    }
    if (seat.present) {
      map['seat'] = Variable<String>(seat.value);
    }
    if (entryNumber.present) {
      map['entry_number'] = Variable<String>(entryNumber.value);
    }
    if (gate.present) {
      map['gate'] = Variable<String>(gate.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imageLocalPath.present) {
      map['image_local_path'] = Variable<String>(imageLocalPath.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketsCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('acquisitionStatus: $acquisitionStatus, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('issuanceStatus: $issuanceStatus, ')
          ..write('seat: $seat, ')
          ..write('entryNumber: $entryNumber, ')
          ..write('gate: $gate, ')
          ..write('url: $url, ')
          ..write('imagePath: $imagePath, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransportsTable extends Transports
    with TableInfo<$TransportsTable, TransportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('outbound'));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fromPlaceMeta =
      const VerificationMeta('fromPlace');
  @override
  late final GeneratedColumn<String> fromPlace = GeneratedColumn<String>(
      'from_place', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toPlaceMeta =
      const VerificationMeta('toPlace');
  @override
  late final GeneratedColumn<String> toPlace = GeneratedColumn<String>(
      'to_place', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _departAtMeta =
      const VerificationMeta('departAt');
  @override
  late final GeneratedColumn<String> departAt = GeneratedColumn<String>(
      'depart_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _arriveAtMeta =
      const VerificationMeta('arriveAt');
  @override
  late final GeneratedColumn<String> arriveAt = GeneratedColumn<String>(
      'arrive_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reservationNumberMeta =
      const VerificationMeta('reservationNumber');
  @override
  late final GeneratedColumn<String> reservationNumber =
      GeneratedColumn<String>('reservation_number', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        genbaId,
        ownerId,
        direction,
        method,
        fromPlace,
        toPlace,
        departAt,
        arriveAt,
        reservationNumber,
        url,
        memo,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transports';
  @override
  VerificationContext validateIntegrity(Insertable<TransportRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    }
    if (data.containsKey('from_place')) {
      context.handle(_fromPlaceMeta,
          fromPlace.isAcceptableOrUnknown(data['from_place']!, _fromPlaceMeta));
    }
    if (data.containsKey('to_place')) {
      context.handle(_toPlaceMeta,
          toPlace.isAcceptableOrUnknown(data['to_place']!, _toPlaceMeta));
    }
    if (data.containsKey('depart_at')) {
      context.handle(_departAtMeta,
          departAt.isAcceptableOrUnknown(data['depart_at']!, _departAtMeta));
    }
    if (data.containsKey('arrive_at')) {
      context.handle(_arriveAtMeta,
          arriveAt.isAcceptableOrUnknown(data['arrive_at']!, _arriveAtMeta));
    }
    if (data.containsKey('reservation_number')) {
      context.handle(
          _reservationNumberMeta,
          reservationNumber.isAcceptableOrUnknown(
              data['reservation_number']!, _reservationNumberMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransportRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method']),
      fromPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_place']),
      toPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_place']),
      departAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}depart_at']),
      arriveAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arrive_at']),
      reservationNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reservation_number']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TransportsTable createAlias(String alias) {
    return $TransportsTable(attachedDatabase, alias);
  }
}

class TransportRow extends DataClass implements Insertable<TransportRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String direction;
  final String? method;
  final String? fromPlace;
  final String? toPlace;
  final String? departAt;
  final String? arriveAt;
  final String? reservationNumber;
  final String? url;
  final String? memo;
  final String createdAt;
  final String updatedAt;
  const TransportRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.direction,
      this.method,
      this.fromPlace,
      this.toPlace,
      this.departAt,
      this.arriveAt,
      this.reservationNumber,
      this.url,
      this.memo,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || method != null) {
      map['method'] = Variable<String>(method);
    }
    if (!nullToAbsent || fromPlace != null) {
      map['from_place'] = Variable<String>(fromPlace);
    }
    if (!nullToAbsent || toPlace != null) {
      map['to_place'] = Variable<String>(toPlace);
    }
    if (!nullToAbsent || departAt != null) {
      map['depart_at'] = Variable<String>(departAt);
    }
    if (!nullToAbsent || arriveAt != null) {
      map['arrive_at'] = Variable<String>(arriveAt);
    }
    if (!nullToAbsent || reservationNumber != null) {
      map['reservation_number'] = Variable<String>(reservationNumber);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TransportsCompanion toCompanion(bool nullToAbsent) {
    return TransportsCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      direction: Value(direction),
      method:
          method == null && nullToAbsent ? const Value.absent() : Value(method),
      fromPlace: fromPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(fromPlace),
      toPlace: toPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(toPlace),
      departAt: departAt == null && nullToAbsent
          ? const Value.absent()
          : Value(departAt),
      arriveAt: arriveAt == null && nullToAbsent
          ? const Value.absent()
          : Value(arriveAt),
      reservationNumber: reservationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(reservationNumber),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransportRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransportRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      direction: serializer.fromJson<String>(json['direction']),
      method: serializer.fromJson<String?>(json['method']),
      fromPlace: serializer.fromJson<String?>(json['fromPlace']),
      toPlace: serializer.fromJson<String?>(json['toPlace']),
      departAt: serializer.fromJson<String?>(json['departAt']),
      arriveAt: serializer.fromJson<String?>(json['arriveAt']),
      reservationNumber:
          serializer.fromJson<String?>(json['reservationNumber']),
      url: serializer.fromJson<String?>(json['url']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'direction': serializer.toJson<String>(direction),
      'method': serializer.toJson<String?>(method),
      'fromPlace': serializer.toJson<String?>(fromPlace),
      'toPlace': serializer.toJson<String?>(toPlace),
      'departAt': serializer.toJson<String?>(departAt),
      'arriveAt': serializer.toJson<String?>(arriveAt),
      'reservationNumber': serializer.toJson<String?>(reservationNumber),
      'url': serializer.toJson<String?>(url),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TransportRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? direction,
          Value<String?> method = const Value.absent(),
          Value<String?> fromPlace = const Value.absent(),
          Value<String?> toPlace = const Value.absent(),
          Value<String?> departAt = const Value.absent(),
          Value<String?> arriveAt = const Value.absent(),
          Value<String?> reservationNumber = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      TransportRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        direction: direction ?? this.direction,
        method: method.present ? method.value : this.method,
        fromPlace: fromPlace.present ? fromPlace.value : this.fromPlace,
        toPlace: toPlace.present ? toPlace.value : this.toPlace,
        departAt: departAt.present ? departAt.value : this.departAt,
        arriveAt: arriveAt.present ? arriveAt.value : this.arriveAt,
        reservationNumber: reservationNumber.present
            ? reservationNumber.value
            : this.reservationNumber,
        url: url.present ? url.value : this.url,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TransportRow copyWithCompanion(TransportsCompanion data) {
    return TransportRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      direction: data.direction.present ? data.direction.value : this.direction,
      method: data.method.present ? data.method.value : this.method,
      fromPlace: data.fromPlace.present ? data.fromPlace.value : this.fromPlace,
      toPlace: data.toPlace.present ? data.toPlace.value : this.toPlace,
      departAt: data.departAt.present ? data.departAt.value : this.departAt,
      arriveAt: data.arriveAt.present ? data.arriveAt.value : this.arriveAt,
      reservationNumber: data.reservationNumber.present
          ? data.reservationNumber.value
          : this.reservationNumber,
      url: data.url.present ? data.url.value : this.url,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransportRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('direction: $direction, ')
          ..write('method: $method, ')
          ..write('fromPlace: $fromPlace, ')
          ..write('toPlace: $toPlace, ')
          ..write('departAt: $departAt, ')
          ..write('arriveAt: $arriveAt, ')
          ..write('reservationNumber: $reservationNumber, ')
          ..write('url: $url, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      genbaId,
      ownerId,
      direction,
      method,
      fromPlace,
      toPlace,
      departAt,
      arriveAt,
      reservationNumber,
      url,
      memo,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransportRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.direction == this.direction &&
          other.method == this.method &&
          other.fromPlace == this.fromPlace &&
          other.toPlace == this.toPlace &&
          other.departAt == this.departAt &&
          other.arriveAt == this.arriveAt &&
          other.reservationNumber == this.reservationNumber &&
          other.url == this.url &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransportsCompanion extends UpdateCompanion<TransportRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> direction;
  final Value<String?> method;
  final Value<String?> fromPlace;
  final Value<String?> toPlace;
  final Value<String?> departAt;
  final Value<String?> arriveAt;
  final Value<String?> reservationNumber;
  final Value<String?> url;
  final Value<String?> memo;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TransportsCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.direction = const Value.absent(),
    this.method = const Value.absent(),
    this.fromPlace = const Value.absent(),
    this.toPlace = const Value.absent(),
    this.departAt = const Value.absent(),
    this.arriveAt = const Value.absent(),
    this.reservationNumber = const Value.absent(),
    this.url = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransportsCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    this.direction = const Value.absent(),
    this.method = const Value.absent(),
    this.fromPlace = const Value.absent(),
    this.toPlace = const Value.absent(),
    this.departAt = const Value.absent(),
    this.arriveAt = const Value.absent(),
    this.reservationNumber = const Value.absent(),
    this.url = const Value.absent(),
    this.memo = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TransportRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? direction,
    Expression<String>? method,
    Expression<String>? fromPlace,
    Expression<String>? toPlace,
    Expression<String>? departAt,
    Expression<String>? arriveAt,
    Expression<String>? reservationNumber,
    Expression<String>? url,
    Expression<String>? memo,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (direction != null) 'direction': direction,
      if (method != null) 'method': method,
      if (fromPlace != null) 'from_place': fromPlace,
      if (toPlace != null) 'to_place': toPlace,
      if (departAt != null) 'depart_at': departAt,
      if (arriveAt != null) 'arrive_at': arriveAt,
      if (reservationNumber != null) 'reservation_number': reservationNumber,
      if (url != null) 'url': url,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransportsCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? direction,
      Value<String?>? method,
      Value<String?>? fromPlace,
      Value<String?>? toPlace,
      Value<String?>? departAt,
      Value<String?>? arriveAt,
      Value<String?>? reservationNumber,
      Value<String?>? url,
      Value<String?>? memo,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return TransportsCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      direction: direction ?? this.direction,
      method: method ?? this.method,
      fromPlace: fromPlace ?? this.fromPlace,
      toPlace: toPlace ?? this.toPlace,
      departAt: departAt ?? this.departAt,
      arriveAt: arriveAt ?? this.arriveAt,
      reservationNumber: reservationNumber ?? this.reservationNumber,
      url: url ?? this.url,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (fromPlace.present) {
      map['from_place'] = Variable<String>(fromPlace.value);
    }
    if (toPlace.present) {
      map['to_place'] = Variable<String>(toPlace.value);
    }
    if (departAt.present) {
      map['depart_at'] = Variable<String>(departAt.value);
    }
    if (arriveAt.present) {
      map['arrive_at'] = Variable<String>(arriveAt.value);
    }
    if (reservationNumber.present) {
      map['reservation_number'] = Variable<String>(reservationNumber.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransportsCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('direction: $direction, ')
          ..write('method: $method, ')
          ..write('fromPlace: $fromPlace, ')
          ..write('toPlace: $toPlace, ')
          ..write('departAt: $departAt, ')
          ..write('arriveAt: $arriveAt, ')
          ..write('reservationNumber: $reservationNumber, ')
          ..write('url: $url, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LodgingsTable extends Lodgings
    with TableInfo<$LodgingsTable, LodgingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LodgingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkinDateMeta =
      const VerificationMeta('checkinDate');
  @override
  late final GeneratedColumn<String> checkinDate = GeneratedColumn<String>(
      'checkin_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checkoutDateMeta =
      const VerificationMeta('checkoutDate');
  @override
  late final GeneratedColumn<String> checkoutDate = GeneratedColumn<String>(
      'checkout_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reservationNumberMeta =
      const VerificationMeta('reservationNumber');
  @override
  late final GeneratedColumn<String> reservationNumber =
      GeneratedColumn<String>('reservation_number', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        genbaId,
        ownerId,
        name,
        checkinDate,
        checkoutDate,
        address,
        reservationNumber,
        url,
        memo,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lodgings';
  @override
  VerificationContext validateIntegrity(Insertable<LodgingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('checkin_date')) {
      context.handle(
          _checkinDateMeta,
          checkinDate.isAcceptableOrUnknown(
              data['checkin_date']!, _checkinDateMeta));
    }
    if (data.containsKey('checkout_date')) {
      context.handle(
          _checkoutDateMeta,
          checkoutDate.isAcceptableOrUnknown(
              data['checkout_date']!, _checkoutDateMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('reservation_number')) {
      context.handle(
          _reservationNumberMeta,
          reservationNumber.isAcceptableOrUnknown(
              data['reservation_number']!, _reservationNumberMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LodgingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LodgingRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      checkinDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checkin_date']),
      checkoutDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checkout_date']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      reservationNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reservation_number']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LodgingsTable createAlias(String alias) {
    return $LodgingsTable(attachedDatabase, alias);
  }
}

class LodgingRow extends DataClass implements Insertable<LodgingRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String? name;
  final String? checkinDate;
  final String? checkoutDate;
  final String? address;
  final String? reservationNumber;
  final String? url;
  final String? memo;
  final String createdAt;
  final String updatedAt;
  const LodgingRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.name,
      this.checkinDate,
      this.checkoutDate,
      this.address,
      this.reservationNumber,
      this.url,
      this.memo,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || checkinDate != null) {
      map['checkin_date'] = Variable<String>(checkinDate);
    }
    if (!nullToAbsent || checkoutDate != null) {
      map['checkout_date'] = Variable<String>(checkoutDate);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || reservationNumber != null) {
      map['reservation_number'] = Variable<String>(reservationNumber);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LodgingsCompanion toCompanion(bool nullToAbsent) {
    return LodgingsCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      checkinDate: checkinDate == null && nullToAbsent
          ? const Value.absent()
          : Value(checkinDate),
      checkoutDate: checkoutDate == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutDate),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      reservationNumber: reservationNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(reservationNumber),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LodgingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LodgingRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String?>(json['name']),
      checkinDate: serializer.fromJson<String?>(json['checkinDate']),
      checkoutDate: serializer.fromJson<String?>(json['checkoutDate']),
      address: serializer.fromJson<String?>(json['address']),
      reservationNumber:
          serializer.fromJson<String?>(json['reservationNumber']),
      url: serializer.fromJson<String?>(json['url']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String?>(name),
      'checkinDate': serializer.toJson<String?>(checkinDate),
      'checkoutDate': serializer.toJson<String?>(checkoutDate),
      'address': serializer.toJson<String?>(address),
      'reservationNumber': serializer.toJson<String?>(reservationNumber),
      'url': serializer.toJson<String?>(url),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LodgingRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          Value<String?> name = const Value.absent(),
          Value<String?> checkinDate = const Value.absent(),
          Value<String?> checkoutDate = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> reservationNumber = const Value.absent(),
          Value<String?> url = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      LodgingRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        name: name.present ? name.value : this.name,
        checkinDate: checkinDate.present ? checkinDate.value : this.checkinDate,
        checkoutDate:
            checkoutDate.present ? checkoutDate.value : this.checkoutDate,
        address: address.present ? address.value : this.address,
        reservationNumber: reservationNumber.present
            ? reservationNumber.value
            : this.reservationNumber,
        url: url.present ? url.value : this.url,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LodgingRow copyWithCompanion(LodgingsCompanion data) {
    return LodgingRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      checkinDate:
          data.checkinDate.present ? data.checkinDate.value : this.checkinDate,
      checkoutDate: data.checkoutDate.present
          ? data.checkoutDate.value
          : this.checkoutDate,
      address: data.address.present ? data.address.value : this.address,
      reservationNumber: data.reservationNumber.present
          ? data.reservationNumber.value
          : this.reservationNumber,
      url: data.url.present ? data.url.value : this.url,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LodgingRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('checkinDate: $checkinDate, ')
          ..write('checkoutDate: $checkoutDate, ')
          ..write('address: $address, ')
          ..write('reservationNumber: $reservationNumber, ')
          ..write('url: $url, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      genbaId,
      ownerId,
      name,
      checkinDate,
      checkoutDate,
      address,
      reservationNumber,
      url,
      memo,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LodgingRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.checkinDate == this.checkinDate &&
          other.checkoutDate == this.checkoutDate &&
          other.address == this.address &&
          other.reservationNumber == this.reservationNumber &&
          other.url == this.url &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LodgingsCompanion extends UpdateCompanion<LodgingRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String?> name;
  final Value<String?> checkinDate;
  final Value<String?> checkoutDate;
  final Value<String?> address;
  final Value<String?> reservationNumber;
  final Value<String?> url;
  final Value<String?> memo;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LodgingsCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.checkinDate = const Value.absent(),
    this.checkoutDate = const Value.absent(),
    this.address = const Value.absent(),
    this.reservationNumber = const Value.absent(),
    this.url = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LodgingsCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    this.name = const Value.absent(),
    this.checkinDate = const Value.absent(),
    this.checkoutDate = const Value.absent(),
    this.address = const Value.absent(),
    this.reservationNumber = const Value.absent(),
    this.url = const Value.absent(),
    this.memo = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LodgingRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? checkinDate,
    Expression<String>? checkoutDate,
    Expression<String>? address,
    Expression<String>? reservationNumber,
    Expression<String>? url,
    Expression<String>? memo,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (checkinDate != null) 'checkin_date': checkinDate,
      if (checkoutDate != null) 'checkout_date': checkoutDate,
      if (address != null) 'address': address,
      if (reservationNumber != null) 'reservation_number': reservationNumber,
      if (url != null) 'url': url,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LodgingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String?>? name,
      Value<String?>? checkinDate,
      Value<String?>? checkoutDate,
      Value<String?>? address,
      Value<String?>? reservationNumber,
      Value<String?>? url,
      Value<String?>? memo,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return LodgingsCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      checkinDate: checkinDate ?? this.checkinDate,
      checkoutDate: checkoutDate ?? this.checkoutDate,
      address: address ?? this.address,
      reservationNumber: reservationNumber ?? this.reservationNumber,
      url: url ?? this.url,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (checkinDate.present) {
      map['checkin_date'] = Variable<String>(checkinDate.value);
    }
    if (checkoutDate.present) {
      map['checkout_date'] = Variable<String>(checkoutDate.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (reservationNumber.present) {
      map['reservation_number'] = Variable<String>(reservationNumber.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LodgingsCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('checkinDate: $checkinDate, ')
          ..write('checkoutDate: $checkoutDate, ')
          ..write('address: $address, ')
          ..write('reservationNumber: $reservationNumber, ')
          ..write('url: $url, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TodosTable extends Todos with TableInfo<$TodosTable, TodoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
      'due_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _assigneeMeta =
      const VerificationMeta('assignee');
  @override
  late final GeneratedColumn<String> assignee = GeneratedColumn<String>(
      'assignee', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        genbaId,
        ownerId,
        name,
        dueDate,
        isDone,
        assignee,
        priority,
        memo,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(Insertable<TodoRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    }
    if (data.containsKey('assignee')) {
      context.handle(_assigneeMeta,
          assignee.isAcceptableOrUnknown(data['assignee']!, _assigneeMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}due_date']),
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      assignee: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assignee']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class TodoRow extends DataClass implements Insertable<TodoRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String name;
  final String? dueDate;
  final bool isDone;
  final String? assignee;
  final String priority;
  final String? memo;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;
  const TodoRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.name,
      this.dueDate,
      required this.isDone,
      this.assignee,
      required this.priority,
      this.memo,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || assignee != null) {
      map['assignee'] = Variable<String>(assignee);
    }
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      name: Value(name),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isDone: Value(isDone),
      assignee: assignee == null && nullToAbsent
          ? const Value.absent()
          : Value(assignee),
      priority: Value(priority),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TodoRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      assignee: serializer.fromJson<String?>(json['assignee']),
      priority: serializer.fromJson<String>(json['priority']),
      memo: serializer.fromJson<String?>(json['memo']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'dueDate': serializer.toJson<String?>(dueDate),
      'isDone': serializer.toJson<bool>(isDone),
      'assignee': serializer.toJson<String?>(assignee),
      'priority': serializer.toJson<String>(priority),
      'memo': serializer.toJson<String?>(memo),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TodoRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? name,
          Value<String?> dueDate = const Value.absent(),
          bool? isDone,
          Value<String?> assignee = const Value.absent(),
          String? priority,
          Value<String?> memo = const Value.absent(),
          int? sortOrder,
          String? createdAt,
          String? updatedAt}) =>
      TodoRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        isDone: isDone ?? this.isDone,
        assignee: assignee.present ? assignee.value : this.assignee,
        priority: priority ?? this.priority,
        memo: memo.present ? memo.value : this.memo,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TodoRow copyWithCompanion(TodosCompanion data) {
    return TodoRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      assignee: data.assignee.present ? data.assignee.value : this.assignee,
      priority: data.priority.present ? data.priority.value : this.priority,
      memo: data.memo.present ? data.memo.value : this.memo,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('dueDate: $dueDate, ')
          ..write('isDone: $isDone, ')
          ..write('assignee: $assignee, ')
          ..write('priority: $priority, ')
          ..write('memo: $memo, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, genbaId, ownerId, name, dueDate, isDone,
      assignee, priority, memo, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.dueDate == this.dueDate &&
          other.isDone == this.isDone &&
          other.assignee == this.assignee &&
          other.priority == this.priority &&
          other.memo == this.memo &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TodosCompanion extends UpdateCompanion<TodoRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String?> dueDate;
  final Value<bool> isDone;
  final Value<String?> assignee;
  final Value<String> priority;
  final Value<String?> memo;
  final Value<int> sortOrder;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isDone = const Value.absent(),
    this.assignee = const Value.absent(),
    this.priority = const Value.absent(),
    this.memo = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TodosCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    required String name,
    this.dueDate = const Value.absent(),
    this.isDone = const Value.absent(),
    this.assignee = const Value.absent(),
    this.priority = const Value.absent(),
    this.memo = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TodoRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? dueDate,
    Expression<bool>? isDone,
    Expression<String>? assignee,
    Expression<String>? priority,
    Expression<String>? memo,
    Expression<int>? sortOrder,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (dueDate != null) 'due_date': dueDate,
      if (isDone != null) 'is_done': isDone,
      if (assignee != null) 'assignee': assignee,
      if (priority != null) 'priority': priority,
      if (memo != null) 'memo': memo,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TodosCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? name,
      Value<String?>? dueDate,
      Value<bool>? isDone,
      Value<String?>? assignee,
      Value<String>? priority,
      Value<String?>? memo,
      Value<int>? sortOrder,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return TodosCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      assignee: assignee ?? this.assignee,
      priority: priority ?? this.priority,
      memo: memo ?? this.memo,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (assignee.present) {
      map['assignee'] = Variable<String>(assignee.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('dueDate: $dueDate, ')
          ..write('isDone: $isDone, ')
          ..write('assignee: $assignee, ')
          ..write('priority: $priority, ')
          ..write('memo: $memo, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenbaMemosTable extends GenbaMemos
    with TableInfo<$GenbaMemosTable, GenbaMemoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenbaMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, genbaId, ownerId, category, body, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genba_memos';
  @override
  VerificationContext validateIntegrity(Insertable<GenbaMemoRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {genbaId, category},
      ];
  @override
  GenbaMemoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenbaMemoRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GenbaMemosTable createAlias(String alias) {
    return $GenbaMemosTable(attachedDatabase, alias);
  }
}

class GenbaMemoRow extends DataClass implements Insertable<GenbaMemoRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String category;
  final String body;
  final String createdAt;
  final String updatedAt;
  const GenbaMemoRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.category,
      required this.body,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['category'] = Variable<String>(category);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  GenbaMemosCompanion toCompanion(bool nullToAbsent) {
    return GenbaMemosCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      category: Value(category),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GenbaMemoRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenbaMemoRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      category: serializer.fromJson<String>(json['category']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'category': serializer.toJson<String>(category),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  GenbaMemoRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? category,
          String? body,
          String? createdAt,
          String? updatedAt}) =>
      GenbaMemoRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        category: category ?? this.category,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GenbaMemoRow copyWithCompanion(GenbaMemosCompanion data) {
    return GenbaMemoRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      category: data.category.present ? data.category.value : this.category,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenbaMemoRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, genbaId, ownerId, category, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenbaMemoRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.category == this.category &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GenbaMemosCompanion extends UpdateCompanion<GenbaMemoRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> category;
  final Value<String> body;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const GenbaMemosCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.category = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenbaMemosCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    required String category,
    this.body = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        category = Value(category),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<GenbaMemoRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? category,
    Expression<String>? body,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (category != null) 'category': category,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenbaMemosCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? category,
      Value<String>? body,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return GenbaMemosCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? this.category,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenbaMemosCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('category: $category, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryEntriesTable extends MemoryEntries
    with TableInfo<$MemoryEntriesTable, MemoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _impressionMeta =
      const VerificationMeta('impression');
  @override
  late final GeneratedColumn<String> impression = GeneratedColumn<String>(
      'impression', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bestMomentMeta =
      const VerificationMeta('bestMoment');
  @override
  late final GeneratedColumn<String> bestMoment = GeneratedColumn<String>(
      'best_moment', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _mcNotesMeta =
      const VerificationMeta('mcNotes');
  @override
  late final GeneratedColumn<String> mcNotes = GeneratedColumn<String>(
      'mc_notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _seatViewMeta =
      const VerificationMeta('seatView');
  @override
  late final GeneratedColumn<String> seatView = GeneratedColumn<String>(
      'seat_view', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _declinedFieldsMeta =
      const VerificationMeta('declinedFields');
  @override
  late final GeneratedColumn<String> declinedFields = GeneratedColumn<String>(
      'declined_fields', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        genbaId,
        ownerId,
        impression,
        bestMoment,
        mcNotes,
        seatView,
        tags,
        declinedFields,
        isFavorite,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_entries';
  @override
  VerificationContext validateIntegrity(Insertable<MemoryEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('impression')) {
      context.handle(
          _impressionMeta,
          impression.isAcceptableOrUnknown(
              data['impression']!, _impressionMeta));
    }
    if (data.containsKey('best_moment')) {
      context.handle(
          _bestMomentMeta,
          bestMoment.isAcceptableOrUnknown(
              data['best_moment']!, _bestMomentMeta));
    }
    if (data.containsKey('mc_notes')) {
      context.handle(_mcNotesMeta,
          mcNotes.isAcceptableOrUnknown(data['mc_notes']!, _mcNotesMeta));
    }
    if (data.containsKey('seat_view')) {
      context.handle(_seatViewMeta,
          seatView.isAcceptableOrUnknown(data['seat_view']!, _seatViewMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('declined_fields')) {
      context.handle(
          _declinedFieldsMeta,
          declinedFields.isAcceptableOrUnknown(
              data['declined_fields']!, _declinedFieldsMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      impression: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}impression'])!,
      bestMoment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}best_moment'])!,
      mcNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mc_notes'])!,
      seatView: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seat_view'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      declinedFields: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}declined_fields'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MemoryEntriesTable createAlias(String alias) {
    return $MemoryEntriesTable(attachedDatabase, alias);
  }
}

class MemoryEntryRow extends DataClass implements Insertable<MemoryEntryRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String impression;
  final String bestMoment;
  final String mcNotes;
  final String seatView;
  final String tags;
  final String declinedFields;

  /// 思い出単位のお気に入り（同期対象, schema v5）。
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;
  const MemoryEntryRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.impression,
      required this.bestMoment,
      required this.mcNotes,
      required this.seatView,
      required this.tags,
      required this.declinedFields,
      required this.isFavorite,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['impression'] = Variable<String>(impression);
    map['best_moment'] = Variable<String>(bestMoment);
    map['mc_notes'] = Variable<String>(mcNotes);
    map['seat_view'] = Variable<String>(seatView);
    map['tags'] = Variable<String>(tags);
    map['declined_fields'] = Variable<String>(declinedFields);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  MemoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return MemoryEntriesCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      impression: Value(impression),
      bestMoment: Value(bestMoment),
      mcNotes: Value(mcNotes),
      seatView: Value(seatView),
      tags: Value(tags),
      declinedFields: Value(declinedFields),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MemoryEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      impression: serializer.fromJson<String>(json['impression']),
      bestMoment: serializer.fromJson<String>(json['bestMoment']),
      mcNotes: serializer.fromJson<String>(json['mcNotes']),
      seatView: serializer.fromJson<String>(json['seatView']),
      tags: serializer.fromJson<String>(json['tags']),
      declinedFields: serializer.fromJson<String>(json['declinedFields']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'impression': serializer.toJson<String>(impression),
      'bestMoment': serializer.toJson<String>(bestMoment),
      'mcNotes': serializer.toJson<String>(mcNotes),
      'seatView': serializer.toJson<String>(seatView),
      'tags': serializer.toJson<String>(tags),
      'declinedFields': serializer.toJson<String>(declinedFields),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  MemoryEntryRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? impression,
          String? bestMoment,
          String? mcNotes,
          String? seatView,
          String? tags,
          String? declinedFields,
          bool? isFavorite,
          String? createdAt,
          String? updatedAt}) =>
      MemoryEntryRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        impression: impression ?? this.impression,
        bestMoment: bestMoment ?? this.bestMoment,
        mcNotes: mcNotes ?? this.mcNotes,
        seatView: seatView ?? this.seatView,
        tags: tags ?? this.tags,
        declinedFields: declinedFields ?? this.declinedFields,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MemoryEntryRow copyWithCompanion(MemoryEntriesCompanion data) {
    return MemoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      impression:
          data.impression.present ? data.impression.value : this.impression,
      bestMoment:
          data.bestMoment.present ? data.bestMoment.value : this.bestMoment,
      mcNotes: data.mcNotes.present ? data.mcNotes.value : this.mcNotes,
      seatView: data.seatView.present ? data.seatView.value : this.seatView,
      tags: data.tags.present ? data.tags.value : this.tags,
      declinedFields: data.declinedFields.present
          ? data.declinedFields.value
          : this.declinedFields,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryEntryRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('impression: $impression, ')
          ..write('bestMoment: $bestMoment, ')
          ..write('mcNotes: $mcNotes, ')
          ..write('seatView: $seatView, ')
          ..write('tags: $tags, ')
          ..write('declinedFields: $declinedFields, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      genbaId,
      ownerId,
      impression,
      bestMoment,
      mcNotes,
      seatView,
      tags,
      declinedFields,
      isFavorite,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryEntryRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.impression == this.impression &&
          other.bestMoment == this.bestMoment &&
          other.mcNotes == this.mcNotes &&
          other.seatView == this.seatView &&
          other.tags == this.tags &&
          other.declinedFields == this.declinedFields &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MemoryEntriesCompanion extends UpdateCompanion<MemoryEntryRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> impression;
  final Value<String> bestMoment;
  final Value<String> mcNotes;
  final Value<String> seatView;
  final Value<String> tags;
  final Value<String> declinedFields;
  final Value<bool> isFavorite;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const MemoryEntriesCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.impression = const Value.absent(),
    this.bestMoment = const Value.absent(),
    this.mcNotes = const Value.absent(),
    this.seatView = const Value.absent(),
    this.tags = const Value.absent(),
    this.declinedFields = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryEntriesCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    this.impression = const Value.absent(),
    this.bestMoment = const Value.absent(),
    this.mcNotes = const Value.absent(),
    this.seatView = const Value.absent(),
    this.tags = const Value.absent(),
    this.declinedFields = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MemoryEntryRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? impression,
    Expression<String>? bestMoment,
    Expression<String>? mcNotes,
    Expression<String>? seatView,
    Expression<String>? tags,
    Expression<String>? declinedFields,
    Expression<bool>? isFavorite,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (impression != null) 'impression': impression,
      if (bestMoment != null) 'best_moment': bestMoment,
      if (mcNotes != null) 'mc_notes': mcNotes,
      if (seatView != null) 'seat_view': seatView,
      if (tags != null) 'tags': tags,
      if (declinedFields != null) 'declined_fields': declinedFields,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? impression,
      Value<String>? bestMoment,
      Value<String>? mcNotes,
      Value<String>? seatView,
      Value<String>? tags,
      Value<String>? declinedFields,
      Value<bool>? isFavorite,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return MemoryEntriesCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      impression: impression ?? this.impression,
      bestMoment: bestMoment ?? this.bestMoment,
      mcNotes: mcNotes ?? this.mcNotes,
      seatView: seatView ?? this.seatView,
      tags: tags ?? this.tags,
      declinedFields: declinedFields ?? this.declinedFields,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (impression.present) {
      map['impression'] = Variable<String>(impression.value);
    }
    if (bestMoment.present) {
      map['best_moment'] = Variable<String>(bestMoment.value);
    }
    if (mcNotes.present) {
      map['mc_notes'] = Variable<String>(mcNotes.value);
    }
    if (seatView.present) {
      map['seat_view'] = Variable<String>(seatView.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (declinedFields.present) {
      map['declined_fields'] = Variable<String>(declinedFields.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('impression: $impression, ')
          ..write('bestMoment: $bestMoment, ')
          ..write('mcNotes: $mcNotes, ')
          ..write('seatView: $seatView, ')
          ..write('tags: $tags, ')
          ..write('declinedFields: $declinedFields, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryPhotosTable extends MemoryPhotos
    with TableInfo<$MemoryPhotosTable, MemoryPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storagePathMeta =
      const VerificationMeta('storagePath');
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
      'storage_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _uploadStatusMeta =
      const VerificationMeta('uploadStatus');
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
      'upload_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local_only'));
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCoverMeta =
      const VerificationMeta('isCover');
  @override
  late final GeneratedColumn<bool> isCover = GeneratedColumn<bool>(
      'is_cover', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_cover" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        genbaId,
        ownerId,
        localPath,
        storagePath,
        uploadStatus,
        caption,
        isCover,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_photos';
  @override
  VerificationContext validateIntegrity(Insertable<MemoryPhotoRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('storage_path')) {
      context.handle(
          _storagePathMeta,
          storagePath.isAcceptableOrUnknown(
              data['storage_path']!, _storagePathMeta));
    }
    if (data.containsKey('upload_status')) {
      context.handle(
          _uploadStatusMeta,
          uploadStatus.isAcceptableOrUnknown(
              data['upload_status']!, _uploadStatusMeta));
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('is_cover')) {
      context.handle(_isCoverMeta,
          isCover.isAcceptableOrUnknown(data['is_cover']!, _isCoverMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryPhotoRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      storagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_path']),
      uploadStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_status'])!,
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
      isCover: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cover'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MemoryPhotosTable createAlias(String alias) {
    return $MemoryPhotosTable(attachedDatabase, alias);
  }
}

class MemoryPhotoRow extends DataClass implements Insertable<MemoryPhotoRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String? localPath;
  final String? storagePath;
  final String uploadStatus;
  final String? caption;
  final bool isCover;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;
  const MemoryPhotoRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      this.localPath,
      this.storagePath,
      required this.uploadStatus,
      this.caption,
      required this.isCover,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    map['upload_status'] = Variable<String>(uploadStatus);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['is_cover'] = Variable<bool>(isCover);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  MemoryPhotosCompanion toCompanion(bool nullToAbsent) {
    return MemoryPhotosCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
      uploadStatus: Value(uploadStatus),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      isCover: Value(isCover),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MemoryPhotoRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryPhotoRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      caption: serializer.fromJson<String?>(json['caption']),
      isCover: serializer.fromJson<bool>(json['isCover']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'localPath': serializer.toJson<String?>(localPath),
      'storagePath': serializer.toJson<String?>(storagePath),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'caption': serializer.toJson<String?>(caption),
      'isCover': serializer.toJson<bool>(isCover),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  MemoryPhotoRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          Value<String?> localPath = const Value.absent(),
          Value<String?> storagePath = const Value.absent(),
          String? uploadStatus,
          Value<String?> caption = const Value.absent(),
          bool? isCover,
          int? sortOrder,
          String? createdAt,
          String? updatedAt}) =>
      MemoryPhotoRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        localPath: localPath.present ? localPath.value : this.localPath,
        storagePath: storagePath.present ? storagePath.value : this.storagePath,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        caption: caption.present ? caption.value : this.caption,
        isCover: isCover ?? this.isCover,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MemoryPhotoRow copyWithCompanion(MemoryPhotosCompanion data) {
    return MemoryPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      caption: data.caption.present ? data.caption.value : this.caption,
      isCover: data.isCover.present ? data.isCover.value : this.isCover,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryPhotoRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('localPath: $localPath, ')
          ..write('storagePath: $storagePath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('caption: $caption, ')
          ..write('isCover: $isCover, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, genbaId, ownerId, localPath, storagePath,
      uploadStatus, caption, isCover, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryPhotoRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.localPath == this.localPath &&
          other.storagePath == this.storagePath &&
          other.uploadStatus == this.uploadStatus &&
          other.caption == this.caption &&
          other.isCover == this.isCover &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MemoryPhotosCompanion extends UpdateCompanion<MemoryPhotoRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String?> localPath;
  final Value<String?> storagePath;
  final Value<String> uploadStatus;
  final Value<String?> caption;
  final Value<bool> isCover;
  final Value<int> sortOrder;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const MemoryPhotosCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.caption = const Value.absent(),
    this.isCover = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryPhotosCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    this.localPath = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.caption = const Value.absent(),
    this.isCover = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MemoryPhotoRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? localPath,
    Expression<String>? storagePath,
    Expression<String>? uploadStatus,
    Expression<String>? caption,
    Expression<bool>? isCover,
    Expression<int>? sortOrder,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (localPath != null) 'local_path': localPath,
      if (storagePath != null) 'storage_path': storagePath,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (caption != null) 'caption': caption,
      if (isCover != null) 'is_cover': isCover,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryPhotosCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String?>? localPath,
      Value<String?>? storagePath,
      Value<String>? uploadStatus,
      Value<String?>? caption,
      Value<bool>? isCover,
      Value<int>? sortOrder,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return MemoryPhotosCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      localPath: localPath ?? this.localPath,
      storagePath: storagePath ?? this.storagePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      caption: caption ?? this.caption,
      isCover: isCover ?? this.isCover,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (isCover.present) {
      map['is_cover'] = Variable<bool>(isCover.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryPhotosCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('localPath: $localPath, ')
          ..write('storagePath: $storagePath, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('caption: $caption, ')
          ..write('isCover: $isCover, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistItemsTable extends SetlistItems
    with TableInfo<$SetlistItemsTable, SetlistItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _songTitleMeta =
      const VerificationMeta('songTitle');
  @override
  late final GeneratedColumn<String> songTitle = GeneratedColumn<String>(
      'song_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, genbaId, ownerId, position, songTitle, note, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlist_items';
  @override
  VerificationContext validateIntegrity(Insertable<SetlistItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('song_title')) {
      context.handle(_songTitleMeta,
          songTitle.isAcceptableOrUnknown(data['song_title']!, _songTitleMeta));
    } else if (isInserting) {
      context.missing(_songTitleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetlistItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      songTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_title'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SetlistItemsTable createAlias(String alias) {
    return $SetlistItemsTable(attachedDatabase, alias);
  }
}

class SetlistItemRow extends DataClass implements Insertable<SetlistItemRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final int position;
  final String songTitle;
  final String? note;
  final String createdAt;
  final String updatedAt;
  const SetlistItemRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.position,
      required this.songTitle,
      this.note,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['position'] = Variable<int>(position);
    map['song_title'] = Variable<String>(songTitle);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SetlistItemsCompanion toCompanion(bool nullToAbsent) {
    return SetlistItemsCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      position: Value(position),
      songTitle: Value(songTitle),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SetlistItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistItemRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      position: serializer.fromJson<int>(json['position']),
      songTitle: serializer.fromJson<String>(json['songTitle']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'position': serializer.toJson<int>(position),
      'songTitle': serializer.toJson<String>(songTitle),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SetlistItemRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          int? position,
          String? songTitle,
          Value<String?> note = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      SetlistItemRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        position: position ?? this.position,
        songTitle: songTitle ?? this.songTitle,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SetlistItemRow copyWithCompanion(SetlistItemsCompanion data) {
    return SetlistItemRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      position: data.position.present ? data.position.value : this.position,
      songTitle: data.songTitle.present ? data.songTitle.value : this.songTitle,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistItemRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('position: $position, ')
          ..write('songTitle: $songTitle, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, genbaId, ownerId, position, songTitle, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistItemRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.position == this.position &&
          other.songTitle == this.songTitle &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SetlistItemsCompanion extends UpdateCompanion<SetlistItemRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<int> position;
  final Value<String> songTitle;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SetlistItemsCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.position = const Value.absent(),
    this.songTitle = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistItemsCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    required int position,
    required String songTitle,
    this.note = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        position = Value(position),
        songTitle = Value(songTitle),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SetlistItemRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<int>? position,
    Expression<String>? songTitle,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (position != null) 'position': position,
      if (songTitle != null) 'song_title': songTitle,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<int>? position,
      Value<String>? songTitle,
      Value<String?>? note,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return SetlistItemsCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      position: position ?? this.position,
      songTitle: songTitle ?? this.songTitle,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (songTitle.present) {
      map['song_title'] = Variable<String>(songTitle.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistItemsCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('position: $position, ')
          ..write('songTitle: $songTitle, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoodsItemsTable extends GoodsItems
    with TableInfo<$GoodsItemsTable, GoodsItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoodsItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, genbaId, ownerId, name, price, quantity, memo, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goods_items';
  @override
  VerificationContext validateIntegrity(Insertable<GoodsItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoodsItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoodsItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price']),
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GoodsItemsTable createAlias(String alias) {
    return $GoodsItemsTable(attachedDatabase, alias);
  }
}

class GoodsItemRow extends DataClass implements Insertable<GoodsItemRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String name;
  final int? price;
  final int quantity;
  final String? memo;
  final String createdAt;
  final String updatedAt;
  const GoodsItemRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.name,
      this.price,
      required this.quantity,
      this.memo,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<int>(price);
    }
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  GoodsItemsCompanion toCompanion(bool nullToAbsent) {
    return GoodsItemsCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      name: Value(name),
      price:
          price == null && nullToAbsent ? const Value.absent() : Value(price),
      quantity: Value(quantity),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GoodsItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoodsItemRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int?>(json['price']),
      quantity: serializer.fromJson<int>(json['quantity']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int?>(price),
      'quantity': serializer.toJson<int>(quantity),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  GoodsItemRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? name,
          Value<int?> price = const Value.absent(),
          int? quantity,
          Value<String?> memo = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      GoodsItemRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        price: price.present ? price.value : this.price,
        quantity: quantity ?? this.quantity,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GoodsItemRow copyWithCompanion(GoodsItemsCompanion data) {
    return GoodsItemRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoodsItemRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, genbaId, ownerId, name, price, quantity, memo, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoodsItemRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.price == this.price &&
          other.quantity == this.quantity &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoodsItemsCompanion extends UpdateCompanion<GoodsItemRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<int?> price;
  final Value<int> quantity;
  final Value<String?> memo;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const GoodsItemsCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoodsItemsCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    required String name,
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.memo = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<GoodsItemRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<int>? price,
    Expression<int>? quantity,
    Expression<String>? memo,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoodsItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? name,
      Value<int?>? price,
      Value<int>? quantity,
      Value<String?>? memo,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return GoodsItemsCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoodsItemsCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitedPlacesTable extends VisitedPlaces
    with TableInfo<$VisitedPlacesTable, VisitedPlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitedPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genbaIdMeta =
      const VerificationMeta('genbaId');
  @override
  late final GeneratedColumn<String> genbaId = GeneratedColumn<String>(
      'genba_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('spot'));
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, genbaId, ownerId, name, category, memo, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visited_places';
  @override
  VerificationContext validateIntegrity(Insertable<VisitedPlaceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('genba_id')) {
      context.handle(_genbaIdMeta,
          genbaId.isAcceptableOrUnknown(data['genba_id']!, _genbaIdMeta));
    } else if (isInserting) {
      context.missing(_genbaIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitedPlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitedPlaceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      genbaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genba_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VisitedPlacesTable createAlias(String alias) {
    return $VisitedPlacesTable(attachedDatabase, alias);
  }
}

class VisitedPlaceRow extends DataClass implements Insertable<VisitedPlaceRow> {
  final String id;
  final String genbaId;
  final String ownerId;
  final String name;
  final String category;
  final String? memo;
  final String createdAt;
  final String updatedAt;
  const VisitedPlaceRow(
      {required this.id,
      required this.genbaId,
      required this.ownerId,
      required this.name,
      required this.category,
      this.memo,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['genba_id'] = Variable<String>(genbaId);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  VisitedPlacesCompanion toCompanion(bool nullToAbsent) {
    return VisitedPlacesCompanion(
      id: Value(id),
      genbaId: Value(genbaId),
      ownerId: Value(ownerId),
      name: Value(name),
      category: Value(category),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VisitedPlaceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitedPlaceRow(
      id: serializer.fromJson<String>(json['id']),
      genbaId: serializer.fromJson<String>(json['genbaId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'genbaId': serializer.toJson<String>(genbaId),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  VisitedPlaceRow copyWith(
          {String? id,
          String? genbaId,
          String? ownerId,
          String? name,
          String? category,
          Value<String?> memo = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      VisitedPlaceRow(
        id: id ?? this.id,
        genbaId: genbaId ?? this.genbaId,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        category: category ?? this.category,
        memo: memo.present ? memo.value : this.memo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  VisitedPlaceRow copyWithCompanion(VisitedPlacesCompanion data) {
    return VisitedPlaceRow(
      id: data.id.present ? data.id.value : this.id,
      genbaId: data.genbaId.present ? data.genbaId.value : this.genbaId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitedPlaceRow(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, genbaId, ownerId, name, category, memo, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitedPlaceRow &&
          other.id == this.id &&
          other.genbaId == this.genbaId &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.category == this.category &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VisitedPlacesCompanion extends UpdateCompanion<VisitedPlaceRow> {
  final Value<String> id;
  final Value<String> genbaId;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String> category;
  final Value<String?> memo;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const VisitedPlacesCompanion({
    this.id = const Value.absent(),
    this.genbaId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitedPlacesCompanion.insert({
    required String id,
    required String genbaId,
    required String ownerId,
    required String name,
    this.category = const Value.absent(),
    this.memo = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        genbaId = Value(genbaId),
        ownerId = Value(ownerId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<VisitedPlaceRow> custom({
    Expression<String>? id,
    Expression<String>? genbaId,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? memo,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genbaId != null) 'genba_id': genbaId,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitedPlacesCompanion copyWith(
      {Value<String>? id,
      Value<String>? genbaId,
      Value<String>? ownerId,
      Value<String>? name,
      Value<String>? category,
      Value<String?>? memo,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return VisitedPlacesCompanion(
      id: id ?? this.id,
      genbaId: genbaId ?? this.genbaId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (genbaId.present) {
      map['genba_id'] = Variable<String>(genbaId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitedPlacesCompanion(')
          ..write('id: $id, ')
          ..write('genbaId: $genbaId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OshiGroupsTable extends OshiGroups
    with TableInfo<$OshiGroupsTable, OshiGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OshiGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageLocalPathMeta =
      const VerificationMeta('imageLocalPath');
  @override
  late final GeneratedColumn<String> imageLocalPath = GeneratedColumn<String>(
      'image_local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageAltTextMeta =
      const VerificationMeta('imageAltText');
  @override
  late final GeneratedColumn<String> imageAltText = GeneratedColumn<String>(
      'image_alt_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ownerId,
        name,
        kind,
        color,
        memo,
        imageLocalPath,
        imageAltText,
        isFavorite,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oshi_groups';
  @override
  VerificationContext validateIntegrity(Insertable<OshiGroupRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('image_local_path')) {
      context.handle(
          _imageLocalPathMeta,
          imageLocalPath.isAcceptableOrUnknown(
              data['image_local_path']!, _imageLocalPathMeta));
    }
    if (data.containsKey('image_alt_text')) {
      context.handle(
          _imageAltTextMeta,
          imageAltText.isAcceptableOrUnknown(
              data['image_alt_text']!, _imageAltTextMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OshiGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OshiGroupRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      imageLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_local_path']),
      imageAltText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_alt_text']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OshiGroupsTable createAlias(String alias) {
    return $OshiGroupsTable(attachedDatabase, alias);
  }
}

class OshiGroupRow extends DataClass implements Insertable<OshiGroupRow> {
  final String id;
  final String ownerId;
  final String name;
  final String? kind;
  final String? color;
  final String? memo;

  /// グループ画像の端末内相対参照（同期対象外, H-04, schema v5）。
  final String? imageLocalPath;

  /// グループ画像の代替説明（同期対象, v5）。
  final String? imageAltText;

  /// グループ単位のお気に入り（同期対象, v5）。
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;
  const OshiGroupRow(
      {required this.id,
      required this.ownerId,
      required this.name,
      this.kind,
      this.color,
      this.memo,
      this.imageLocalPath,
      this.imageAltText,
      required this.isFavorite,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || imageLocalPath != null) {
      map['image_local_path'] = Variable<String>(imageLocalPath);
    }
    if (!nullToAbsent || imageAltText != null) {
      map['image_alt_text'] = Variable<String>(imageAltText);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  OshiGroupsCompanion toCompanion(bool nullToAbsent) {
    return OshiGroupsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      name: Value(name),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      imageLocalPath: imageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageLocalPath),
      imageAltText: imageAltText == null && nullToAbsent
          ? const Value.absent()
          : Value(imageAltText),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OshiGroupRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OshiGroupRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String?>(json['kind']),
      color: serializer.fromJson<String?>(json['color']),
      memo: serializer.fromJson<String?>(json['memo']),
      imageLocalPath: serializer.fromJson<String?>(json['imageLocalPath']),
      imageAltText: serializer.fromJson<String?>(json['imageAltText']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String?>(kind),
      'color': serializer.toJson<String?>(color),
      'memo': serializer.toJson<String?>(memo),
      'imageLocalPath': serializer.toJson<String?>(imageLocalPath),
      'imageAltText': serializer.toJson<String?>(imageAltText),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  OshiGroupRow copyWith(
          {String? id,
          String? ownerId,
          String? name,
          Value<String?> kind = const Value.absent(),
          Value<String?> color = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          Value<String?> imageLocalPath = const Value.absent(),
          Value<String?> imageAltText = const Value.absent(),
          bool? isFavorite,
          String? createdAt,
          String? updatedAt}) =>
      OshiGroupRow(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        kind: kind.present ? kind.value : this.kind,
        color: color.present ? color.value : this.color,
        memo: memo.present ? memo.value : this.memo,
        imageLocalPath:
            imageLocalPath.present ? imageLocalPath.value : this.imageLocalPath,
        imageAltText:
            imageAltText.present ? imageAltText.value : this.imageAltText,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OshiGroupRow copyWithCompanion(OshiGroupsCompanion data) {
    return OshiGroupRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      color: data.color.present ? data.color.value : this.color,
      memo: data.memo.present ? data.memo.value : this.memo,
      imageLocalPath: data.imageLocalPath.present
          ? data.imageLocalPath.value
          : this.imageLocalPath,
      imageAltText: data.imageAltText.present
          ? data.imageAltText.value
          : this.imageAltText,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OshiGroupRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('color: $color, ')
          ..write('memo: $memo, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('imageAltText: $imageAltText, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerId, name, kind, color, memo,
      imageLocalPath, imageAltText, isFavorite, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OshiGroupRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.color == this.color &&
          other.memo == this.memo &&
          other.imageLocalPath == this.imageLocalPath &&
          other.imageAltText == this.imageAltText &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OshiGroupsCompanion extends UpdateCompanion<OshiGroupRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String?> kind;
  final Value<String?> color;
  final Value<String?> memo;
  final Value<String?> imageLocalPath;
  final Value<String?> imageAltText;
  final Value<bool> isFavorite;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const OshiGroupsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.color = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.imageAltText = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OshiGroupsCompanion.insert({
    required String id,
    required String ownerId,
    required String name,
    this.kind = const Value.absent(),
    this.color = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.imageAltText = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ownerId = Value(ownerId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OshiGroupRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? color,
    Expression<String>? memo,
    Expression<String>? imageLocalPath,
    Expression<String>? imageAltText,
    Expression<bool>? isFavorite,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (color != null) 'color': color,
      if (memo != null) 'memo': memo,
      if (imageLocalPath != null) 'image_local_path': imageLocalPath,
      if (imageAltText != null) 'image_alt_text': imageAltText,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OshiGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? ownerId,
      Value<String>? name,
      Value<String?>? kind,
      Value<String?>? color,
      Value<String?>? memo,
      Value<String?>? imageLocalPath,
      Value<String?>? imageAltText,
      Value<bool>? isFavorite,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return OshiGroupsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      color: color ?? this.color,
      memo: memo ?? this.memo,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      imageAltText: imageAltText ?? this.imageAltText,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (imageLocalPath.present) {
      map['image_local_path'] = Variable<String>(imageLocalPath.value);
    }
    if (imageAltText.present) {
      map['image_alt_text'] = Variable<String>(imageAltText.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OshiGroupsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('color: $color, ')
          ..write('memo: $memo, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('imageAltText: $imageAltText, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OshiMembersTable extends OshiMembers
    with TableInfo<$OshiMembersTable, OshiMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OshiMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<String> rank = GeneratedColumn<String>(
      'rank', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('oshi'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _oshiSinceMeta =
      const VerificationMeta('oshiSince');
  @override
  late final GeneratedColumn<String> oshiSince = GeneratedColumn<String>(
      'oshi_since', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _birthdayMeta =
      const VerificationMeta('birthday');
  @override
  late final GeneratedColumn<String> birthday = GeneratedColumn<String>(
      'birthday', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageLocalPathMeta =
      const VerificationMeta('imageLocalPath');
  @override
  late final GeneratedColumn<String> imageLocalPath = GeneratedColumn<String>(
      'image_local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageAltTextMeta =
      const VerificationMeta('imageAltText');
  @override
  late final GeneratedColumn<String> imageAltText = GeneratedColumn<String>(
      'image_alt_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        groupId,
        ownerId,
        name,
        rank,
        color,
        oshiSince,
        birthday,
        memo,
        imageLocalPath,
        imageAltText,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oshi_members';
  @override
  VerificationContext validateIntegrity(Insertable<OshiMemberRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
          _rankMeta, rank.isAcceptableOrUnknown(data['rank']!, _rankMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('oshi_since')) {
      context.handle(_oshiSinceMeta,
          oshiSince.isAcceptableOrUnknown(data['oshi_since']!, _oshiSinceMeta));
    }
    if (data.containsKey('birthday')) {
      context.handle(_birthdayMeta,
          birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('image_local_path')) {
      context.handle(
          _imageLocalPathMeta,
          imageLocalPath.isAcceptableOrUnknown(
              data['image_local_path']!, _imageLocalPathMeta));
    }
    if (data.containsKey('image_alt_text')) {
      context.handle(
          _imageAltTextMeta,
          imageAltText.isAcceptableOrUnknown(
              data['image_alt_text']!, _imageAltTextMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OshiMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OshiMemberRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      rank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rank'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      oshiSince: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}oshi_since']),
      birthday: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}birthday']),
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo']),
      imageLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_local_path']),
      imageAltText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_alt_text']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OshiMembersTable createAlias(String alias) {
    return $OshiMembersTable(attachedDatabase, alias);
  }
}

class OshiMemberRow extends DataClass implements Insertable<OshiMemberRow> {
  final String id;
  final String groupId;
  final String ownerId;
  final String name;
  final String rank;
  final String? color;
  final String? oshiSince;
  final String? birthday;
  final String? memo;

  /// 推し画像の端末内相対参照（同期対象外, H-04, schema v4）。
  final String? imageLocalPath;

  /// 推し画像の代替説明（同期対象, v5）。
  final String? imageAltText;
  final String createdAt;
  final String updatedAt;
  const OshiMemberRow(
      {required this.id,
      required this.groupId,
      required this.ownerId,
      required this.name,
      required this.rank,
      this.color,
      this.oshiSince,
      this.birthday,
      this.memo,
      this.imageLocalPath,
      this.imageAltText,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    map['rank'] = Variable<String>(rank);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || oshiSince != null) {
      map['oshi_since'] = Variable<String>(oshiSince);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<String>(birthday);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || imageLocalPath != null) {
      map['image_local_path'] = Variable<String>(imageLocalPath);
    }
    if (!nullToAbsent || imageAltText != null) {
      map['image_alt_text'] = Variable<String>(imageAltText);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  OshiMembersCompanion toCompanion(bool nullToAbsent) {
    return OshiMembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      ownerId: Value(ownerId),
      name: Value(name),
      rank: Value(rank),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      oshiSince: oshiSince == null && nullToAbsent
          ? const Value.absent()
          : Value(oshiSince),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      imageLocalPath: imageLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(imageLocalPath),
      imageAltText: imageAltText == null && nullToAbsent
          ? const Value.absent()
          : Value(imageAltText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OshiMemberRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OshiMemberRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      rank: serializer.fromJson<String>(json['rank']),
      color: serializer.fromJson<String?>(json['color']),
      oshiSince: serializer.fromJson<String?>(json['oshiSince']),
      birthday: serializer.fromJson<String?>(json['birthday']),
      memo: serializer.fromJson<String?>(json['memo']),
      imageLocalPath: serializer.fromJson<String?>(json['imageLocalPath']),
      imageAltText: serializer.fromJson<String?>(json['imageAltText']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'rank': serializer.toJson<String>(rank),
      'color': serializer.toJson<String?>(color),
      'oshiSince': serializer.toJson<String?>(oshiSince),
      'birthday': serializer.toJson<String?>(birthday),
      'memo': serializer.toJson<String?>(memo),
      'imageLocalPath': serializer.toJson<String?>(imageLocalPath),
      'imageAltText': serializer.toJson<String?>(imageAltText),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  OshiMemberRow copyWith(
          {String? id,
          String? groupId,
          String? ownerId,
          String? name,
          String? rank,
          Value<String?> color = const Value.absent(),
          Value<String?> oshiSince = const Value.absent(),
          Value<String?> birthday = const Value.absent(),
          Value<String?> memo = const Value.absent(),
          Value<String?> imageLocalPath = const Value.absent(),
          Value<String?> imageAltText = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      OshiMemberRow(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        rank: rank ?? this.rank,
        color: color.present ? color.value : this.color,
        oshiSince: oshiSince.present ? oshiSince.value : this.oshiSince,
        birthday: birthday.present ? birthday.value : this.birthday,
        memo: memo.present ? memo.value : this.memo,
        imageLocalPath:
            imageLocalPath.present ? imageLocalPath.value : this.imageLocalPath,
        imageAltText:
            imageAltText.present ? imageAltText.value : this.imageAltText,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OshiMemberRow copyWithCompanion(OshiMembersCompanion data) {
    return OshiMemberRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      rank: data.rank.present ? data.rank.value : this.rank,
      color: data.color.present ? data.color.value : this.color,
      oshiSince: data.oshiSince.present ? data.oshiSince.value : this.oshiSince,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      memo: data.memo.present ? data.memo.value : this.memo,
      imageLocalPath: data.imageLocalPath.present
          ? data.imageLocalPath.value
          : this.imageLocalPath,
      imageAltText: data.imageAltText.present
          ? data.imageAltText.value
          : this.imageAltText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OshiMemberRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('rank: $rank, ')
          ..write('color: $color, ')
          ..write('oshiSince: $oshiSince, ')
          ..write('birthday: $birthday, ')
          ..write('memo: $memo, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('imageAltText: $imageAltText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      ownerId,
      name,
      rank,
      color,
      oshiSince,
      birthday,
      memo,
      imageLocalPath,
      imageAltText,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OshiMemberRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.rank == this.rank &&
          other.color == this.color &&
          other.oshiSince == this.oshiSince &&
          other.birthday == this.birthday &&
          other.memo == this.memo &&
          other.imageLocalPath == this.imageLocalPath &&
          other.imageAltText == this.imageAltText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OshiMembersCompanion extends UpdateCompanion<OshiMemberRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String> rank;
  final Value<String?> color;
  final Value<String?> oshiSince;
  final Value<String?> birthday;
  final Value<String?> memo;
  final Value<String?> imageLocalPath;
  final Value<String?> imageAltText;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const OshiMembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.rank = const Value.absent(),
    this.color = const Value.absent(),
    this.oshiSince = const Value.absent(),
    this.birthday = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.imageAltText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OshiMembersCompanion.insert({
    required String id,
    required String groupId,
    required String ownerId,
    required String name,
    this.rank = const Value.absent(),
    this.color = const Value.absent(),
    this.oshiSince = const Value.absent(),
    this.birthday = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageLocalPath = const Value.absent(),
    this.imageAltText = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        groupId = Value(groupId),
        ownerId = Value(ownerId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OshiMemberRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? rank,
    Expression<String>? color,
    Expression<String>? oshiSince,
    Expression<String>? birthday,
    Expression<String>? memo,
    Expression<String>? imageLocalPath,
    Expression<String>? imageAltText,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (rank != null) 'rank': rank,
      if (color != null) 'color': color,
      if (oshiSince != null) 'oshi_since': oshiSince,
      if (birthday != null) 'birthday': birthday,
      if (memo != null) 'memo': memo,
      if (imageLocalPath != null) 'image_local_path': imageLocalPath,
      if (imageAltText != null) 'image_alt_text': imageAltText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OshiMembersCompanion copyWith(
      {Value<String>? id,
      Value<String>? groupId,
      Value<String>? ownerId,
      Value<String>? name,
      Value<String>? rank,
      Value<String?>? color,
      Value<String?>? oshiSince,
      Value<String?>? birthday,
      Value<String?>? memo,
      Value<String?>? imageLocalPath,
      Value<String?>? imageAltText,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return OshiMembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      color: color ?? this.color,
      oshiSince: oshiSince ?? this.oshiSince,
      birthday: birthday ?? this.birthday,
      memo: memo ?? this.memo,
      imageLocalPath: imageLocalPath ?? this.imageLocalPath,
      imageAltText: imageAltText ?? this.imageAltText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(rank.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (oshiSince.present) {
      map['oshi_since'] = Variable<String>(oshiSince.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<String>(birthday.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (imageLocalPath.present) {
      map['image_local_path'] = Variable<String>(imageLocalPath.value);
    }
    if (imageAltText.present) {
      map['image_alt_text'] = Variable<String>(imageAltText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OshiMembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('rank: $rank, ')
          ..write('color: $color, ')
          ..write('oshiSince: $oshiSince, ')
          ..write('birthday: $birthday, ')
          ..write('memo: $memo, ')
          ..write('imageLocalPath: $imageLocalPath, ')
          ..write('imageAltText: $imageAltText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OshiAnniversariesTable extends OshiAnniversaries
    with TableInfo<$OshiAnniversariesTable, OshiAnniversaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OshiAnniversariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdMeta =
      const VerificationMeta('memberId');
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
      'member_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ownerId, groupId, memberId, label, date, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oshi_anniversaries';
  @override
  VerificationContext validateIntegrity(Insertable<OshiAnniversaryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(_memberIdMeta,
          memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OshiAnniversaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OshiAnniversaryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      memberId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_id']),
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OshiAnniversariesTable createAlias(String alias) {
    return $OshiAnniversariesTable(attachedDatabase, alias);
  }
}

class OshiAnniversaryRow extends DataClass
    implements Insertable<OshiAnniversaryRow> {
  final String id;
  final String ownerId;
  final String groupId;
  final String? memberId;
  final String label;
  final String date;
  final String createdAt;
  final String updatedAt;
  const OshiAnniversaryRow(
      {required this.id,
      required this.ownerId,
      required this.groupId,
      this.memberId,
      required this.label,
      required this.date,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['label'] = Variable<String>(label);
    map['date'] = Variable<String>(date);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  OshiAnniversariesCompanion toCompanion(bool nullToAbsent) {
    return OshiAnniversariesCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      groupId: Value(groupId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      label: Value(label),
      date: Value(date),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OshiAnniversaryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OshiAnniversaryRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      label: serializer.fromJson<String>(json['label']),
      date: serializer.fromJson<String>(json['date']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'groupId': serializer.toJson<String>(groupId),
      'memberId': serializer.toJson<String?>(memberId),
      'label': serializer.toJson<String>(label),
      'date': serializer.toJson<String>(date),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  OshiAnniversaryRow copyWith(
          {String? id,
          String? ownerId,
          String? groupId,
          Value<String?> memberId = const Value.absent(),
          String? label,
          String? date,
          String? createdAt,
          String? updatedAt}) =>
      OshiAnniversaryRow(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        groupId: groupId ?? this.groupId,
        memberId: memberId.present ? memberId.value : this.memberId,
        label: label ?? this.label,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OshiAnniversaryRow copyWithCompanion(OshiAnniversariesCompanion data) {
    return OshiAnniversaryRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      label: data.label.present ? data.label.value : this.label,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OshiAnniversaryRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('label: $label, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, ownerId, groupId, memberId, label, date, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OshiAnniversaryRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.groupId == this.groupId &&
          other.memberId == this.memberId &&
          other.label == this.label &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OshiAnniversariesCompanion extends UpdateCompanion<OshiAnniversaryRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> groupId;
  final Value<String?> memberId;
  final Value<String> label;
  final Value<String> date;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const OshiAnniversariesCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.label = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OshiAnniversariesCompanion.insert({
    required String id,
    required String ownerId,
    required String groupId,
    this.memberId = const Value.absent(),
    required String label,
    required String date,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ownerId = Value(ownerId),
        groupId = Value(groupId),
        label = Value(label),
        date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OshiAnniversaryRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? groupId,
    Expression<String>? memberId,
    Expression<String>? label,
    Expression<String>? date,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (groupId != null) 'group_id': groupId,
      if (memberId != null) 'member_id': memberId,
      if (label != null) 'label': label,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OshiAnniversariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? ownerId,
      Value<String>? groupId,
      Value<String?>? memberId,
      Value<String>? label,
      Value<String>? date,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return OshiAnniversariesCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      label: label ?? this.label,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OshiAnniversariesCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('label: $label, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxOpsTable extends OutboxOps
    with TableInfo<$OutboxOpsTable, OutboxOpRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mutationIdMeta =
      const VerificationMeta('mutationId');
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
      'mutation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
      'op_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<String> nextRetryAt = GeneratedColumn<String>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        mutationId,
        ownerId,
        entityTable,
        entityId,
        opType,
        payload,
        status,
        attempts,
        lastError,
        nextRetryAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_ops';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxOpRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mutation_id')) {
      context.handle(
          _mutationIdMeta,
          mutationId.isAcceptableOrUnknown(
              data['mutation_id']!, _mutationIdMeta));
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(_opTypeMeta,
          opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta));
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mutationId};
  @override
  OutboxOpRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxOpRow(
      mutationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mutation_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      opType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_type'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_retry_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $OutboxOpsTable createAlias(String alias) {
    return $OutboxOpsTable(attachedDatabase, alias);
  }
}

class OutboxOpRow extends DataClass implements Insertable<OutboxOpRow> {
  final String mutationId;
  final String ownerId;
  final String entityTable;
  final String entityId;
  final String opType;
  final String payload;
  final String status;
  final int attempts;
  final String? lastError;

  /// 次に再送してよい時刻（UTC ISO8601）。バックオフ待機中はこの時刻まで
  /// 送信対象にしない（H-02）。再起動後もこの値で待機を復元する。null は即送信可。
  final String? nextRetryAt;
  final String createdAt;
  final String updatedAt;
  const OutboxOpRow(
      {required this.mutationId,
      required this.ownerId,
      required this.entityTable,
      required this.entityId,
      required this.opType,
      required this.payload,
      required this.status,
      required this.attempts,
      this.lastError,
      this.nextRetryAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mutation_id'] = Variable<String>(mutationId);
    map['owner_id'] = Variable<String>(ownerId);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['op_type'] = Variable<String>(opType);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<String>(nextRetryAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  OutboxOpsCompanion toCompanion(bool nullToAbsent) {
    return OutboxOpsCompanion(
      mutationId: Value(mutationId),
      ownerId: Value(ownerId),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      opType: Value(opType),
      payload: Value(payload),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboxOpRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxOpRow(
      mutationId: serializer.fromJson<String>(json['mutationId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<String>(json['entityId']),
      opType: serializer.fromJson<String>(json['opType']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextRetryAt: serializer.fromJson<String?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mutationId': serializer.toJson<String>(mutationId),
      'ownerId': serializer.toJson<String>(ownerId),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<String>(entityId),
      'opType': serializer.toJson<String>(opType),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextRetryAt': serializer.toJson<String?>(nextRetryAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  OutboxOpRow copyWith(
          {String? mutationId,
          String? ownerId,
          String? entityTable,
          String? entityId,
          String? opType,
          String? payload,
          String? status,
          int? attempts,
          Value<String?> lastError = const Value.absent(),
          Value<String?> nextRetryAt = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      OutboxOpRow(
        mutationId: mutationId ?? this.mutationId,
        ownerId: ownerId ?? this.ownerId,
        entityTable: entityTable ?? this.entityTable,
        entityId: entityId ?? this.entityId,
        opType: opType ?? this.opType,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  OutboxOpRow copyWithCompanion(OutboxOpsCompanion data) {
    return OutboxOpRow(
      mutationId:
          data.mutationId.present ? data.mutationId.value : this.mutationId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      opType: data.opType.present ? data.opType.value : this.opType,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOpRow(')
          ..write('mutationId: $mutationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('opType: $opType, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      mutationId,
      ownerId,
      entityTable,
      entityId,
      opType,
      payload,
      status,
      attempts,
      lastError,
      nextRetryAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxOpRow &&
          other.mutationId == this.mutationId &&
          other.ownerId == this.ownerId &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.opType == this.opType &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OutboxOpsCompanion extends UpdateCompanion<OutboxOpRow> {
  final Value<String> mutationId;
  final Value<String> ownerId;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<String> opType;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<String?> nextRetryAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const OutboxOpsCompanion({
    this.mutationId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.opType = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxOpsCompanion.insert({
    required String mutationId,
    required String ownerId,
    required String entityTable,
    required String entityId,
    required String opType,
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : mutationId = Value(mutationId),
        ownerId = Value(ownerId),
        entityTable = Value(entityTable),
        entityId = Value(entityId),
        opType = Value(opType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<OutboxOpRow> custom({
    Expression<String>? mutationId,
    Expression<String>? ownerId,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<String>? opType,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? nextRetryAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mutationId != null) 'mutation_id': mutationId,
      if (ownerId != null) 'owner_id': ownerId,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (opType != null) 'op_type': opType,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxOpsCompanion copyWith(
      {Value<String>? mutationId,
      Value<String>? ownerId,
      Value<String>? entityTable,
      Value<String>? entityId,
      Value<String>? opType,
      Value<String>? payload,
      Value<String>? status,
      Value<int>? attempts,
      Value<String?>? lastError,
      Value<String?>? nextRetryAt,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return OutboxOpsCompanion(
      mutationId: mutationId ?? this.mutationId,
      ownerId: ownerId ?? this.ownerId,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      opType: opType ?? this.opType,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<String>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxOpsCompanion(')
          ..write('mutationId: $mutationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('opType: $opType, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppKvsTable extends AppKvs with TableInfo<$AppKvsTable, AppKvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppKvsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_kvs';
  @override
  VerificationContext validateIntegrity(Insertable<AppKvRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppKvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppKvRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppKvsTable createAlias(String alias) {
    return $AppKvsTable(attachedDatabase, alias);
  }
}

class AppKvRow extends DataClass implements Insertable<AppKvRow> {
  final String key;
  final String value;
  const AppKvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppKvsCompanion toCompanion(bool nullToAbsent) {
    return AppKvsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppKvRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppKvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppKvRow copyWith({String? key, String? value}) => AppKvRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppKvRow copyWithCompanion(AppKvsCompanion data) {
    return AppKvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppKvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppKvRow && other.key == this.key && other.value == this.value);
}

class AppKvsCompanion extends UpdateCompanion<AppKvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppKvsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppKvsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppKvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppKvsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppKvsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppKvsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FormDraftsTable extends FormDrafts
    with TableInfo<$FormDraftsTable, FormDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [ownerId, key, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'form_drafts';
  @override
  VerificationContext validateIntegrity(Insertable<FormDraftRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, key};
  @override
  FormDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormDraftRow(
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FormDraftsTable createAlias(String alias) {
    return $FormDraftsTable(attachedDatabase, alias);
  }
}

class FormDraftRow extends DataClass implements Insertable<FormDraftRow> {
  final String ownerId;
  final String key;
  final String payload;
  final String updatedAt;
  const FormDraftRow(
      {required this.ownerId,
      required this.key,
      required this.payload,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['key'] = Variable<String>(key);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  FormDraftsCompanion toCompanion(bool nullToAbsent) {
    return FormDraftsCompanion(
      ownerId: Value(ownerId),
      key: Value(key),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory FormDraftRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormDraftRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      key: serializer.fromJson<String>(json['key']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'key': serializer.toJson<String>(key),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  FormDraftRow copyWith(
          {String? ownerId, String? key, String? payload, String? updatedAt}) =>
      FormDraftRow(
        ownerId: ownerId ?? this.ownerId,
        key: key ?? this.key,
        payload: payload ?? this.payload,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FormDraftRow copyWithCompanion(FormDraftsCompanion data) {
    return FormDraftRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      key: data.key.present ? data.key.value : this.key,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormDraftRow(')
          ..write('ownerId: $ownerId, ')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, key, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormDraftRow &&
          other.ownerId == this.ownerId &&
          other.key == this.key &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class FormDraftsCompanion extends UpdateCompanion<FormDraftRow> {
  final Value<String> ownerId;
  final Value<String> key;
  final Value<String> payload;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const FormDraftsCompanion({
    this.ownerId = const Value.absent(),
    this.key = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FormDraftsCompanion.insert({
    required String ownerId,
    required String key,
    required String payload,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : ownerId = Value(ownerId),
        key = Value(key),
        payload = Value(payload),
        updatedAt = Value(updatedAt);
  static Insertable<FormDraftRow> custom({
    Expression<String>? ownerId,
    Expression<String>? key,
    Expression<String>? payload,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (key != null) 'key': key,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FormDraftsCompanion copyWith(
      {Value<String>? ownerId,
      Value<String>? key,
      Value<String>? payload,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return FormDraftsCompanion(
      ownerId: ownerId ?? this.ownerId,
      key: key ?? this.key,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormDraftsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('key: $key, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteVersionsTable extends RemoteVersions
    with TableInfo<$RemoteVersionsTable, RemoteVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [ownerId, entityTable, entityId, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_versions';
  @override
  VerificationContext validateIntegrity(Insertable<RemoteVersionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, entityTable, entityId};
  @override
  RemoteVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteVersionRow(
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  $RemoteVersionsTable createAlias(String alias) {
    return $RemoteVersionsTable(attachedDatabase, alias);
  }
}

class RemoteVersionRow extends DataClass
    implements Insertable<RemoteVersionRow> {
  final String ownerId;
  final String entityTable;
  final String entityId;
  final int version;
  const RemoteVersionRow(
      {required this.ownerId,
      required this.entityTable,
      required this.entityId,
      required this.version});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['version'] = Variable<int>(version);
    return map;
  }

  RemoteVersionsCompanion toCompanion(bool nullToAbsent) {
    return RemoteVersionsCompanion(
      ownerId: Value(ownerId),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      version: Value(version),
    );
  }

  factory RemoteVersionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteVersionRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<String>(json['entityId']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<String>(entityId),
      'version': serializer.toJson<int>(version),
    };
  }

  RemoteVersionRow copyWith(
          {String? ownerId,
          String? entityTable,
          String? entityId,
          int? version}) =>
      RemoteVersionRow(
        ownerId: ownerId ?? this.ownerId,
        entityTable: entityTable ?? this.entityTable,
        entityId: entityId ?? this.entityId,
        version: version ?? this.version,
      );
  RemoteVersionRow copyWithCompanion(RemoteVersionsCompanion data) {
    return RemoteVersionRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteVersionRow(')
          ..write('ownerId: $ownerId, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, entityTable, entityId, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteVersionRow &&
          other.ownerId == this.ownerId &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.version == this.version);
}

class RemoteVersionsCompanion extends UpdateCompanion<RemoteVersionRow> {
  final Value<String> ownerId;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<int> version;
  final Value<int> rowid;
  const RemoteVersionsCompanion({
    this.ownerId = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteVersionsCompanion.insert({
    required String ownerId,
    required String entityTable,
    required String entityId,
    required int version,
    this.rowid = const Value.absent(),
  })  : ownerId = Value(ownerId),
        entityTable = Value(entityTable),
        entityId = Value(entityId),
        version = Value(version);
  static Insertable<RemoteVersionRow> custom({
    Expression<String>? ownerId,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteVersionsCompanion copyWith(
      {Value<String>? ownerId,
      Value<String>? entityTable,
      Value<String>? entityId,
      Value<int>? version,
      Value<int>? rowid}) {
    return RemoteVersionsCompanion(
      ownerId: ownerId ?? this.ownerId,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteVersionsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GenbasTable genbas = $GenbasTable(this);
  late final $TicketsTable tickets = $TicketsTable(this);
  late final $TransportsTable transports = $TransportsTable(this);
  late final $LodgingsTable lodgings = $LodgingsTable(this);
  late final $TodosTable todos = $TodosTable(this);
  late final $GenbaMemosTable genbaMemos = $GenbaMemosTable(this);
  late final $MemoryEntriesTable memoryEntries = $MemoryEntriesTable(this);
  late final $MemoryPhotosTable memoryPhotos = $MemoryPhotosTable(this);
  late final $SetlistItemsTable setlistItems = $SetlistItemsTable(this);
  late final $GoodsItemsTable goodsItems = $GoodsItemsTable(this);
  late final $VisitedPlacesTable visitedPlaces = $VisitedPlacesTable(this);
  late final $OshiGroupsTable oshiGroups = $OshiGroupsTable(this);
  late final $OshiMembersTable oshiMembers = $OshiMembersTable(this);
  late final $OshiAnniversariesTable oshiAnniversaries =
      $OshiAnniversariesTable(this);
  late final $OutboxOpsTable outboxOps = $OutboxOpsTable(this);
  late final $AppKvsTable appKvs = $AppKvsTable(this);
  late final $FormDraftsTable formDrafts = $FormDraftsTable(this);
  late final $RemoteVersionsTable remoteVersions = $RemoteVersionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        genbas,
        tickets,
        transports,
        lodgings,
        todos,
        genbaMemos,
        memoryEntries,
        memoryPhotos,
        setlistItems,
        goodsItems,
        visitedPlaces,
        oshiGroups,
        oshiMembers,
        oshiAnniversaries,
        outboxOps,
        appKvs,
        formDrafts,
        remoteVersions
      ];
}

typedef $$GenbasTableCreateCompanionBuilder = GenbasCompanion Function({
  required String id,
  required String ownerId,
  required String artistName,
  required String title,
  required String eventDate,
  Value<String?> oshiGroupId,
  Value<String> oshiMemberIds,
  Value<String?> venue,
  Value<int?> doorTimeMinutes,
  Value<int?> startTimeMinutes,
  Value<int?> endTimeMinutes,
  Value<String?> performanceType,
  Value<String?> performanceId,
  Value<bool?> isExpedition,
  Value<String> transportRequirement,
  Value<String> lodgingRequirement,
  Value<bool> isCanceled,
  Value<String> attendanceStatus,
  Value<String?> manualEndedAt,
  Value<String?> heroImageLocalPath,
  Value<String?> heroImageStoragePath,
  Value<String> heroImageUploadStatus,
  Value<String?> heroImageAltText,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$GenbasTableUpdateCompanionBuilder = GenbasCompanion Function({
  Value<String> id,
  Value<String> ownerId,
  Value<String> artistName,
  Value<String> title,
  Value<String> eventDate,
  Value<String?> oshiGroupId,
  Value<String> oshiMemberIds,
  Value<String?> venue,
  Value<int?> doorTimeMinutes,
  Value<int?> startTimeMinutes,
  Value<int?> endTimeMinutes,
  Value<String?> performanceType,
  Value<String?> performanceId,
  Value<bool?> isExpedition,
  Value<String> transportRequirement,
  Value<String> lodgingRequirement,
  Value<bool> isCanceled,
  Value<String> attendanceStatus,
  Value<String?> manualEndedAt,
  Value<String?> heroImageLocalPath,
  Value<String?> heroImageStoragePath,
  Value<String> heroImageUploadStatus,
  Value<String?> heroImageAltText,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$GenbasTableFilterComposer
    extends Composer<_$AppDatabase, $GenbasTable> {
  $$GenbasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventDate => $composableBuilder(
      column: $table.eventDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oshiGroupId => $composableBuilder(
      column: $table.oshiGroupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oshiMemberIds => $composableBuilder(
      column: $table.oshiMemberIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venue => $composableBuilder(
      column: $table.venue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get doorTimeMinutes => $composableBuilder(
      column: $table.doorTimeMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTimeMinutes => $composableBuilder(
      column: $table.startTimeMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTimeMinutes => $composableBuilder(
      column: $table.endTimeMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get performanceType => $composableBuilder(
      column: $table.performanceType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get performanceId => $composableBuilder(
      column: $table.performanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isExpedition => $composableBuilder(
      column: $table.isExpedition, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transportRequirement => $composableBuilder(
      column: $table.transportRequirement,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lodgingRequirement => $composableBuilder(
      column: $table.lodgingRequirement,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCanceled => $composableBuilder(
      column: $table.isCanceled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attendanceStatus => $composableBuilder(
      column: $table.attendanceStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manualEndedAt => $composableBuilder(
      column: $table.manualEndedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heroImageLocalPath => $composableBuilder(
      column: $table.heroImageLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heroImageStoragePath => $composableBuilder(
      column: $table.heroImageStoragePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heroImageUploadStatus => $composableBuilder(
      column: $table.heroImageUploadStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heroImageAltText => $composableBuilder(
      column: $table.heroImageAltText,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GenbasTableOrderingComposer
    extends Composer<_$AppDatabase, $GenbasTable> {
  $$GenbasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventDate => $composableBuilder(
      column: $table.eventDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oshiGroupId => $composableBuilder(
      column: $table.oshiGroupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oshiMemberIds => $composableBuilder(
      column: $table.oshiMemberIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venue => $composableBuilder(
      column: $table.venue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get doorTimeMinutes => $composableBuilder(
      column: $table.doorTimeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTimeMinutes => $composableBuilder(
      column: $table.startTimeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTimeMinutes => $composableBuilder(
      column: $table.endTimeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get performanceType => $composableBuilder(
      column: $table.performanceType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get performanceId => $composableBuilder(
      column: $table.performanceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isExpedition => $composableBuilder(
      column: $table.isExpedition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transportRequirement => $composableBuilder(
      column: $table.transportRequirement,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lodgingRequirement => $composableBuilder(
      column: $table.lodgingRequirement,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCanceled => $composableBuilder(
      column: $table.isCanceled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attendanceStatus => $composableBuilder(
      column: $table.attendanceStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manualEndedAt => $composableBuilder(
      column: $table.manualEndedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heroImageLocalPath => $composableBuilder(
      column: $table.heroImageLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heroImageStoragePath => $composableBuilder(
      column: $table.heroImageStoragePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heroImageUploadStatus => $composableBuilder(
      column: $table.heroImageUploadStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heroImageAltText => $composableBuilder(
      column: $table.heroImageAltText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GenbasTableAnnotationComposer
    extends Composer<_$AppDatabase, $GenbasTable> {
  $$GenbasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get oshiGroupId => $composableBuilder(
      column: $table.oshiGroupId, builder: (column) => column);

  GeneratedColumn<String> get oshiMemberIds => $composableBuilder(
      column: $table.oshiMemberIds, builder: (column) => column);

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<int> get doorTimeMinutes => $composableBuilder(
      column: $table.doorTimeMinutes, builder: (column) => column);

  GeneratedColumn<int> get startTimeMinutes => $composableBuilder(
      column: $table.startTimeMinutes, builder: (column) => column);

  GeneratedColumn<int> get endTimeMinutes => $composableBuilder(
      column: $table.endTimeMinutes, builder: (column) => column);

  GeneratedColumn<String> get performanceType => $composableBuilder(
      column: $table.performanceType, builder: (column) => column);

  GeneratedColumn<String> get performanceId => $composableBuilder(
      column: $table.performanceId, builder: (column) => column);

  GeneratedColumn<bool> get isExpedition => $composableBuilder(
      column: $table.isExpedition, builder: (column) => column);

  GeneratedColumn<String> get transportRequirement => $composableBuilder(
      column: $table.transportRequirement, builder: (column) => column);

  GeneratedColumn<String> get lodgingRequirement => $composableBuilder(
      column: $table.lodgingRequirement, builder: (column) => column);

  GeneratedColumn<bool> get isCanceled => $composableBuilder(
      column: $table.isCanceled, builder: (column) => column);

  GeneratedColumn<String> get attendanceStatus => $composableBuilder(
      column: $table.attendanceStatus, builder: (column) => column);

  GeneratedColumn<String> get manualEndedAt => $composableBuilder(
      column: $table.manualEndedAt, builder: (column) => column);

  GeneratedColumn<String> get heroImageLocalPath => $composableBuilder(
      column: $table.heroImageLocalPath, builder: (column) => column);

  GeneratedColumn<String> get heroImageStoragePath => $composableBuilder(
      column: $table.heroImageStoragePath, builder: (column) => column);

  GeneratedColumn<String> get heroImageUploadStatus => $composableBuilder(
      column: $table.heroImageUploadStatus, builder: (column) => column);

  GeneratedColumn<String> get heroImageAltText => $composableBuilder(
      column: $table.heroImageAltText, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GenbasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GenbasTable,
    GenbaRow,
    $$GenbasTableFilterComposer,
    $$GenbasTableOrderingComposer,
    $$GenbasTableAnnotationComposer,
    $$GenbasTableCreateCompanionBuilder,
    $$GenbasTableUpdateCompanionBuilder,
    (GenbaRow, BaseReferences<_$AppDatabase, $GenbasTable, GenbaRow>),
    GenbaRow,
    PrefetchHooks Function()> {
  $$GenbasTableTableManager(_$AppDatabase db, $GenbasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenbasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenbasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenbasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> artistName = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> eventDate = const Value.absent(),
            Value<String?> oshiGroupId = const Value.absent(),
            Value<String> oshiMemberIds = const Value.absent(),
            Value<String?> venue = const Value.absent(),
            Value<int?> doorTimeMinutes = const Value.absent(),
            Value<int?> startTimeMinutes = const Value.absent(),
            Value<int?> endTimeMinutes = const Value.absent(),
            Value<String?> performanceType = const Value.absent(),
            Value<String?> performanceId = const Value.absent(),
            Value<bool?> isExpedition = const Value.absent(),
            Value<String> transportRequirement = const Value.absent(),
            Value<String> lodgingRequirement = const Value.absent(),
            Value<bool> isCanceled = const Value.absent(),
            Value<String> attendanceStatus = const Value.absent(),
            Value<String?> manualEndedAt = const Value.absent(),
            Value<String?> heroImageLocalPath = const Value.absent(),
            Value<String?> heroImageStoragePath = const Value.absent(),
            Value<String> heroImageUploadStatus = const Value.absent(),
            Value<String?> heroImageAltText = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GenbasCompanion(
            id: id,
            ownerId: ownerId,
            artistName: artistName,
            title: title,
            eventDate: eventDate,
            oshiGroupId: oshiGroupId,
            oshiMemberIds: oshiMemberIds,
            venue: venue,
            doorTimeMinutes: doorTimeMinutes,
            startTimeMinutes: startTimeMinutes,
            endTimeMinutes: endTimeMinutes,
            performanceType: performanceType,
            performanceId: performanceId,
            isExpedition: isExpedition,
            transportRequirement: transportRequirement,
            lodgingRequirement: lodgingRequirement,
            isCanceled: isCanceled,
            attendanceStatus: attendanceStatus,
            manualEndedAt: manualEndedAt,
            heroImageLocalPath: heroImageLocalPath,
            heroImageStoragePath: heroImageStoragePath,
            heroImageUploadStatus: heroImageUploadStatus,
            heroImageAltText: heroImageAltText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String ownerId,
            required String artistName,
            required String title,
            required String eventDate,
            Value<String?> oshiGroupId = const Value.absent(),
            Value<String> oshiMemberIds = const Value.absent(),
            Value<String?> venue = const Value.absent(),
            Value<int?> doorTimeMinutes = const Value.absent(),
            Value<int?> startTimeMinutes = const Value.absent(),
            Value<int?> endTimeMinutes = const Value.absent(),
            Value<String?> performanceType = const Value.absent(),
            Value<String?> performanceId = const Value.absent(),
            Value<bool?> isExpedition = const Value.absent(),
            Value<String> transportRequirement = const Value.absent(),
            Value<String> lodgingRequirement = const Value.absent(),
            Value<bool> isCanceled = const Value.absent(),
            Value<String> attendanceStatus = const Value.absent(),
            Value<String?> manualEndedAt = const Value.absent(),
            Value<String?> heroImageLocalPath = const Value.absent(),
            Value<String?> heroImageStoragePath = const Value.absent(),
            Value<String> heroImageUploadStatus = const Value.absent(),
            Value<String?> heroImageAltText = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GenbasCompanion.insert(
            id: id,
            ownerId: ownerId,
            artistName: artistName,
            title: title,
            eventDate: eventDate,
            oshiGroupId: oshiGroupId,
            oshiMemberIds: oshiMemberIds,
            venue: venue,
            doorTimeMinutes: doorTimeMinutes,
            startTimeMinutes: startTimeMinutes,
            endTimeMinutes: endTimeMinutes,
            performanceType: performanceType,
            performanceId: performanceId,
            isExpedition: isExpedition,
            transportRequirement: transportRequirement,
            lodgingRequirement: lodgingRequirement,
            isCanceled: isCanceled,
            attendanceStatus: attendanceStatus,
            manualEndedAt: manualEndedAt,
            heroImageLocalPath: heroImageLocalPath,
            heroImageStoragePath: heroImageStoragePath,
            heroImageUploadStatus: heroImageUploadStatus,
            heroImageAltText: heroImageAltText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GenbasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GenbasTable,
    GenbaRow,
    $$GenbasTableFilterComposer,
    $$GenbasTableOrderingComposer,
    $$GenbasTableAnnotationComposer,
    $$GenbasTableCreateCompanionBuilder,
    $$GenbasTableUpdateCompanionBuilder,
    (GenbaRow, BaseReferences<_$AppDatabase, $GenbasTable, GenbaRow>),
    GenbaRow,
    PrefetchHooks Function()>;
typedef $$TicketsTableCreateCompanionBuilder = TicketsCompanion Function({
  required String id,
  required String genbaId,
  required String ownerId,
  Value<String> acquisitionStatus,
  Value<String> paymentStatus,
  Value<String> issuanceStatus,
  Value<String?> seat,
  Value<String?> entryNumber,
  Value<String?> gate,
  Value<String?> url,
  Value<String?> imagePath,
  Value<String?> imageLocalPath,
  Value<String?> memo,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$TicketsTableUpdateCompanionBuilder = TicketsCompanion Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> acquisitionStatus,
  Value<String> paymentStatus,
  Value<String> issuanceStatus,
  Value<String?> seat,
  Value<String?> entryNumber,
  Value<String?> gate,
  Value<String?> url,
  Value<String?> imagePath,
  Value<String?> imageLocalPath,
  Value<String?> memo,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$TicketsTableFilterComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acquisitionStatus => $composableBuilder(
      column: $table.acquisitionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issuanceStatus => $composableBuilder(
      column: $table.issuanceStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seat => $composableBuilder(
      column: $table.seat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryNumber => $composableBuilder(
      column: $table.entryNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gate => $composableBuilder(
      column: $table.gate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acquisitionStatus => $composableBuilder(
      column: $table.acquisitionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issuanceStatus => $composableBuilder(
      column: $table.issuanceStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seat => $composableBuilder(
      column: $table.seat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryNumber => $composableBuilder(
      column: $table.entryNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gate => $composableBuilder(
      column: $table.gate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TicketsTable> {
  $$TicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get acquisitionStatus => $composableBuilder(
      column: $table.acquisitionStatus, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<String> get issuanceStatus => $composableBuilder(
      column: $table.issuanceStatus, builder: (column) => column);

  GeneratedColumn<String> get seat =>
      $composableBuilder(column: $table.seat, builder: (column) => column);

  GeneratedColumn<String> get entryNumber => $composableBuilder(
      column: $table.entryNumber, builder: (column) => column);

  GeneratedColumn<String> get gate =>
      $composableBuilder(column: $table.gate, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TicketsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TicketsTable,
    TicketRow,
    $$TicketsTableFilterComposer,
    $$TicketsTableOrderingComposer,
    $$TicketsTableAnnotationComposer,
    $$TicketsTableCreateCompanionBuilder,
    $$TicketsTableUpdateCompanionBuilder,
    (TicketRow, BaseReferences<_$AppDatabase, $TicketsTable, TicketRow>),
    TicketRow,
    PrefetchHooks Function()> {
  $$TicketsTableTableManager(_$AppDatabase db, $TicketsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> acquisitionStatus = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String> issuanceStatus = const Value.absent(),
            Value<String?> seat = const Value.absent(),
            Value<String?> entryNumber = const Value.absent(),
            Value<String?> gate = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> imageLocalPath = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TicketsCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            acquisitionStatus: acquisitionStatus,
            paymentStatus: paymentStatus,
            issuanceStatus: issuanceStatus,
            seat: seat,
            entryNumber: entryNumber,
            gate: gate,
            url: url,
            imagePath: imagePath,
            imageLocalPath: imageLocalPath,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            Value<String> acquisitionStatus = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String> issuanceStatus = const Value.absent(),
            Value<String?> seat = const Value.absent(),
            Value<String?> entryNumber = const Value.absent(),
            Value<String?> gate = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<String?> imageLocalPath = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TicketsCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            acquisitionStatus: acquisitionStatus,
            paymentStatus: paymentStatus,
            issuanceStatus: issuanceStatus,
            seat: seat,
            entryNumber: entryNumber,
            gate: gate,
            url: url,
            imagePath: imagePath,
            imageLocalPath: imageLocalPath,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TicketsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TicketsTable,
    TicketRow,
    $$TicketsTableFilterComposer,
    $$TicketsTableOrderingComposer,
    $$TicketsTableAnnotationComposer,
    $$TicketsTableCreateCompanionBuilder,
    $$TicketsTableUpdateCompanionBuilder,
    (TicketRow, BaseReferences<_$AppDatabase, $TicketsTable, TicketRow>),
    TicketRow,
    PrefetchHooks Function()>;
typedef $$TransportsTableCreateCompanionBuilder = TransportsCompanion Function({
  required String id,
  required String genbaId,
  required String ownerId,
  Value<String> direction,
  Value<String?> method,
  Value<String?> fromPlace,
  Value<String?> toPlace,
  Value<String?> departAt,
  Value<String?> arriveAt,
  Value<String?> reservationNumber,
  Value<String?> url,
  Value<String?> memo,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$TransportsTableUpdateCompanionBuilder = TransportsCompanion Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> direction,
  Value<String?> method,
  Value<String?> fromPlace,
  Value<String?> toPlace,
  Value<String?> departAt,
  Value<String?> arriveAt,
  Value<String?> reservationNumber,
  Value<String?> url,
  Value<String?> memo,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$TransportsTableFilterComposer
    extends Composer<_$AppDatabase, $TransportsTable> {
  $$TransportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromPlace => $composableBuilder(
      column: $table.fromPlace, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toPlace => $composableBuilder(
      column: $table.toPlace, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get departAt => $composableBuilder(
      column: $table.departAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arriveAt => $composableBuilder(
      column: $table.arriveAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reservationNumber => $composableBuilder(
      column: $table.reservationNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TransportsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransportsTable> {
  $$TransportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromPlace => $composableBuilder(
      column: $table.fromPlace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toPlace => $composableBuilder(
      column: $table.toPlace, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get departAt => $composableBuilder(
      column: $table.departAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arriveAt => $composableBuilder(
      column: $table.arriveAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reservationNumber => $composableBuilder(
      column: $table.reservationNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TransportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransportsTable> {
  $$TransportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get fromPlace =>
      $composableBuilder(column: $table.fromPlace, builder: (column) => column);

  GeneratedColumn<String> get toPlace =>
      $composableBuilder(column: $table.toPlace, builder: (column) => column);

  GeneratedColumn<String> get departAt =>
      $composableBuilder(column: $table.departAt, builder: (column) => column);

  GeneratedColumn<String> get arriveAt =>
      $composableBuilder(column: $table.arriveAt, builder: (column) => column);

  GeneratedColumn<String> get reservationNumber => $composableBuilder(
      column: $table.reservationNumber, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransportsTable,
    TransportRow,
    $$TransportsTableFilterComposer,
    $$TransportsTableOrderingComposer,
    $$TransportsTableAnnotationComposer,
    $$TransportsTableCreateCompanionBuilder,
    $$TransportsTableUpdateCompanionBuilder,
    (
      TransportRow,
      BaseReferences<_$AppDatabase, $TransportsTable, TransportRow>
    ),
    TransportRow,
    PrefetchHooks Function()> {
  $$TransportsTableTableManager(_$AppDatabase db, $TransportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String?> method = const Value.absent(),
            Value<String?> fromPlace = const Value.absent(),
            Value<String?> toPlace = const Value.absent(),
            Value<String?> departAt = const Value.absent(),
            Value<String?> arriveAt = const Value.absent(),
            Value<String?> reservationNumber = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransportsCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            direction: direction,
            method: method,
            fromPlace: fromPlace,
            toPlace: toPlace,
            departAt: departAt,
            arriveAt: arriveAt,
            reservationNumber: reservationNumber,
            url: url,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            Value<String> direction = const Value.absent(),
            Value<String?> method = const Value.absent(),
            Value<String?> fromPlace = const Value.absent(),
            Value<String?> toPlace = const Value.absent(),
            Value<String?> departAt = const Value.absent(),
            Value<String?> arriveAt = const Value.absent(),
            Value<String?> reservationNumber = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransportsCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            direction: direction,
            method: method,
            fromPlace: fromPlace,
            toPlace: toPlace,
            departAt: departAt,
            arriveAt: arriveAt,
            reservationNumber: reservationNumber,
            url: url,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransportsTable,
    TransportRow,
    $$TransportsTableFilterComposer,
    $$TransportsTableOrderingComposer,
    $$TransportsTableAnnotationComposer,
    $$TransportsTableCreateCompanionBuilder,
    $$TransportsTableUpdateCompanionBuilder,
    (
      TransportRow,
      BaseReferences<_$AppDatabase, $TransportsTable, TransportRow>
    ),
    TransportRow,
    PrefetchHooks Function()>;
typedef $$LodgingsTableCreateCompanionBuilder = LodgingsCompanion Function({
  required String id,
  required String genbaId,
  required String ownerId,
  Value<String?> name,
  Value<String?> checkinDate,
  Value<String?> checkoutDate,
  Value<String?> address,
  Value<String?> reservationNumber,
  Value<String?> url,
  Value<String?> memo,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$LodgingsTableUpdateCompanionBuilder = LodgingsCompanion Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String?> name,
  Value<String?> checkinDate,
  Value<String?> checkoutDate,
  Value<String?> address,
  Value<String?> reservationNumber,
  Value<String?> url,
  Value<String?> memo,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$LodgingsTableFilterComposer
    extends Composer<_$AppDatabase, $LodgingsTable> {
  $$LodgingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkinDate => $composableBuilder(
      column: $table.checkinDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkoutDate => $composableBuilder(
      column: $table.checkoutDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reservationNumber => $composableBuilder(
      column: $table.reservationNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LodgingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LodgingsTable> {
  $$LodgingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkinDate => $composableBuilder(
      column: $table.checkinDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkoutDate => $composableBuilder(
      column: $table.checkoutDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reservationNumber => $composableBuilder(
      column: $table.reservationNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LodgingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LodgingsTable> {
  $$LodgingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get checkinDate => $composableBuilder(
      column: $table.checkinDate, builder: (column) => column);

  GeneratedColumn<String> get checkoutDate => $composableBuilder(
      column: $table.checkoutDate, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get reservationNumber => $composableBuilder(
      column: $table.reservationNumber, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LodgingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LodgingsTable,
    LodgingRow,
    $$LodgingsTableFilterComposer,
    $$LodgingsTableOrderingComposer,
    $$LodgingsTableAnnotationComposer,
    $$LodgingsTableCreateCompanionBuilder,
    $$LodgingsTableUpdateCompanionBuilder,
    (LodgingRow, BaseReferences<_$AppDatabase, $LodgingsTable, LodgingRow>),
    LodgingRow,
    PrefetchHooks Function()> {
  $$LodgingsTableTableManager(_$AppDatabase db, $LodgingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LodgingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LodgingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LodgingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> checkinDate = const Value.absent(),
            Value<String?> checkoutDate = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> reservationNumber = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LodgingsCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            checkinDate: checkinDate,
            checkoutDate: checkoutDate,
            address: address,
            reservationNumber: reservationNumber,
            url: url,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            Value<String?> name = const Value.absent(),
            Value<String?> checkinDate = const Value.absent(),
            Value<String?> checkoutDate = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> reservationNumber = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LodgingsCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            checkinDate: checkinDate,
            checkoutDate: checkoutDate,
            address: address,
            reservationNumber: reservationNumber,
            url: url,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LodgingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LodgingsTable,
    LodgingRow,
    $$LodgingsTableFilterComposer,
    $$LodgingsTableOrderingComposer,
    $$LodgingsTableAnnotationComposer,
    $$LodgingsTableCreateCompanionBuilder,
    $$LodgingsTableUpdateCompanionBuilder,
    (LodgingRow, BaseReferences<_$AppDatabase, $LodgingsTable, LodgingRow>),
    LodgingRow,
    PrefetchHooks Function()>;
typedef $$TodosTableCreateCompanionBuilder = TodosCompanion Function({
  required String id,
  required String genbaId,
  required String ownerId,
  required String name,
  Value<String?> dueDate,
  Value<bool> isDone,
  Value<String?> assignee,
  Value<String> priority,
  Value<String?> memo,
  Value<int> sortOrder,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$TodosTableUpdateCompanionBuilder = TodosCompanion Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> name,
  Value<String?> dueDate,
  Value<bool> isDone,
  Value<String?> assignee,
  Value<String> priority,
  Value<String?> memo,
  Value<int> sortOrder,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignee => $composableBuilder(
      column: $table.assignee, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignee => $composableBuilder(
      column: $table.assignee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<String> get assignee =>
      $composableBuilder(column: $table.assignee, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TodosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TodosTable,
    TodoRow,
    $$TodosTableFilterComposer,
    $$TodosTableOrderingComposer,
    $$TodosTableAnnotationComposer,
    $$TodosTableCreateCompanionBuilder,
    $$TodosTableUpdateCompanionBuilder,
    (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
    TodoRow,
    PrefetchHooks Function()> {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> dueDate = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<String?> assignee = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TodosCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            dueDate: dueDate,
            isDone: isDone,
            assignee: assignee,
            priority: priority,
            memo: memo,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            required String name,
            Value<String?> dueDate = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<String?> assignee = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TodosCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            dueDate: dueDate,
            isDone: isDone,
            assignee: assignee,
            priority: priority,
            memo: memo,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TodosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TodosTable,
    TodoRow,
    $$TodosTableFilterComposer,
    $$TodosTableOrderingComposer,
    $$TodosTableAnnotationComposer,
    $$TodosTableCreateCompanionBuilder,
    $$TodosTableUpdateCompanionBuilder,
    (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
    TodoRow,
    PrefetchHooks Function()>;
typedef $$GenbaMemosTableCreateCompanionBuilder = GenbaMemosCompanion Function({
  required String id,
  required String genbaId,
  required String ownerId,
  required String category,
  Value<String> body,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$GenbaMemosTableUpdateCompanionBuilder = GenbaMemosCompanion Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> category,
  Value<String> body,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$GenbaMemosTableFilterComposer
    extends Composer<_$AppDatabase, $GenbaMemosTable> {
  $$GenbaMemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GenbaMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $GenbaMemosTable> {
  $$GenbaMemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GenbaMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $GenbaMemosTable> {
  $$GenbaMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GenbaMemosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GenbaMemosTable,
    GenbaMemoRow,
    $$GenbaMemosTableFilterComposer,
    $$GenbaMemosTableOrderingComposer,
    $$GenbaMemosTableAnnotationComposer,
    $$GenbaMemosTableCreateCompanionBuilder,
    $$GenbaMemosTableUpdateCompanionBuilder,
    (
      GenbaMemoRow,
      BaseReferences<_$AppDatabase, $GenbaMemosTable, GenbaMemoRow>
    ),
    GenbaMemoRow,
    PrefetchHooks Function()> {
  $$GenbaMemosTableTableManager(_$AppDatabase db, $GenbaMemosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenbaMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenbaMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenbaMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GenbaMemosCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            category: category,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            required String category,
            Value<String> body = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GenbaMemosCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            category: category,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GenbaMemosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GenbaMemosTable,
    GenbaMemoRow,
    $$GenbaMemosTableFilterComposer,
    $$GenbaMemosTableOrderingComposer,
    $$GenbaMemosTableAnnotationComposer,
    $$GenbaMemosTableCreateCompanionBuilder,
    $$GenbaMemosTableUpdateCompanionBuilder,
    (
      GenbaMemoRow,
      BaseReferences<_$AppDatabase, $GenbaMemosTable, GenbaMemoRow>
    ),
    GenbaMemoRow,
    PrefetchHooks Function()>;
typedef $$MemoryEntriesTableCreateCompanionBuilder = MemoryEntriesCompanion
    Function({
  required String id,
  required String genbaId,
  required String ownerId,
  Value<String> impression,
  Value<String> bestMoment,
  Value<String> mcNotes,
  Value<String> seatView,
  Value<String> tags,
  Value<String> declinedFields,
  Value<bool> isFavorite,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$MemoryEntriesTableUpdateCompanionBuilder = MemoryEntriesCompanion
    Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> impression,
  Value<String> bestMoment,
  Value<String> mcNotes,
  Value<String> seatView,
  Value<String> tags,
  Value<String> declinedFields,
  Value<bool> isFavorite,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$MemoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryEntriesTable> {
  $$MemoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get impression => $composableBuilder(
      column: $table.impression, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bestMoment => $composableBuilder(
      column: $table.bestMoment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mcNotes => $composableBuilder(
      column: $table.mcNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seatView => $composableBuilder(
      column: $table.seatView, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get declinedFields => $composableBuilder(
      column: $table.declinedFields,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MemoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryEntriesTable> {
  $$MemoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get impression => $composableBuilder(
      column: $table.impression, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bestMoment => $composableBuilder(
      column: $table.bestMoment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mcNotes => $composableBuilder(
      column: $table.mcNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seatView => $composableBuilder(
      column: $table.seatView, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get declinedFields => $composableBuilder(
      column: $table.declinedFields,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MemoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryEntriesTable> {
  $$MemoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get impression => $composableBuilder(
      column: $table.impression, builder: (column) => column);

  GeneratedColumn<String> get bestMoment => $composableBuilder(
      column: $table.bestMoment, builder: (column) => column);

  GeneratedColumn<String> get mcNotes =>
      $composableBuilder(column: $table.mcNotes, builder: (column) => column);

  GeneratedColumn<String> get seatView =>
      $composableBuilder(column: $table.seatView, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get declinedFields => $composableBuilder(
      column: $table.declinedFields, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MemoryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemoryEntriesTable,
    MemoryEntryRow,
    $$MemoryEntriesTableFilterComposer,
    $$MemoryEntriesTableOrderingComposer,
    $$MemoryEntriesTableAnnotationComposer,
    $$MemoryEntriesTableCreateCompanionBuilder,
    $$MemoryEntriesTableUpdateCompanionBuilder,
    (
      MemoryEntryRow,
      BaseReferences<_$AppDatabase, $MemoryEntriesTable, MemoryEntryRow>
    ),
    MemoryEntryRow,
    PrefetchHooks Function()> {
  $$MemoryEntriesTableTableManager(_$AppDatabase db, $MemoryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> impression = const Value.absent(),
            Value<String> bestMoment = const Value.absent(),
            Value<String> mcNotes = const Value.absent(),
            Value<String> seatView = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> declinedFields = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoryEntriesCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            impression: impression,
            bestMoment: bestMoment,
            mcNotes: mcNotes,
            seatView: seatView,
            tags: tags,
            declinedFields: declinedFields,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            Value<String> impression = const Value.absent(),
            Value<String> bestMoment = const Value.absent(),
            Value<String> mcNotes = const Value.absent(),
            Value<String> seatView = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> declinedFields = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoryEntriesCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            impression: impression,
            bestMoment: bestMoment,
            mcNotes: mcNotes,
            seatView: seatView,
            tags: tags,
            declinedFields: declinedFields,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemoryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemoryEntriesTable,
    MemoryEntryRow,
    $$MemoryEntriesTableFilterComposer,
    $$MemoryEntriesTableOrderingComposer,
    $$MemoryEntriesTableAnnotationComposer,
    $$MemoryEntriesTableCreateCompanionBuilder,
    $$MemoryEntriesTableUpdateCompanionBuilder,
    (
      MemoryEntryRow,
      BaseReferences<_$AppDatabase, $MemoryEntriesTable, MemoryEntryRow>
    ),
    MemoryEntryRow,
    PrefetchHooks Function()>;
typedef $$MemoryPhotosTableCreateCompanionBuilder = MemoryPhotosCompanion
    Function({
  required String id,
  required String genbaId,
  required String ownerId,
  Value<String?> localPath,
  Value<String?> storagePath,
  Value<String> uploadStatus,
  Value<String?> caption,
  Value<bool> isCover,
  Value<int> sortOrder,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$MemoryPhotosTableUpdateCompanionBuilder = MemoryPhotosCompanion
    Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String?> localPath,
  Value<String?> storagePath,
  Value<String> uploadStatus,
  Value<String?> caption,
  Value<bool> isCover,
  Value<int> sortOrder,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$MemoryPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryPhotosTable> {
  $$MemoryPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCover => $composableBuilder(
      column: $table.isCover, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MemoryPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryPhotosTable> {
  $$MemoryPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCover => $composableBuilder(
      column: $table.isCover, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MemoryPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryPhotosTable> {
  $$MemoryPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => column);

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<bool> get isCover =>
      $composableBuilder(column: $table.isCover, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MemoryPhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemoryPhotosTable,
    MemoryPhotoRow,
    $$MemoryPhotosTableFilterComposer,
    $$MemoryPhotosTableOrderingComposer,
    $$MemoryPhotosTableAnnotationComposer,
    $$MemoryPhotosTableCreateCompanionBuilder,
    $$MemoryPhotosTableUpdateCompanionBuilder,
    (
      MemoryPhotoRow,
      BaseReferences<_$AppDatabase, $MemoryPhotosTable, MemoryPhotoRow>
    ),
    MemoryPhotoRow,
    PrefetchHooks Function()> {
  $$MemoryPhotosTableTableManager(_$AppDatabase db, $MemoryPhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<String> uploadStatus = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<bool> isCover = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoryPhotosCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            localPath: localPath,
            storagePath: storagePath,
            uploadStatus: uploadStatus,
            caption: caption,
            isCover: isCover,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            Value<String?> localPath = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<String> uploadStatus = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<bool> isCover = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoryPhotosCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            localPath: localPath,
            storagePath: storagePath,
            uploadStatus: uploadStatus,
            caption: caption,
            isCover: isCover,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemoryPhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemoryPhotosTable,
    MemoryPhotoRow,
    $$MemoryPhotosTableFilterComposer,
    $$MemoryPhotosTableOrderingComposer,
    $$MemoryPhotosTableAnnotationComposer,
    $$MemoryPhotosTableCreateCompanionBuilder,
    $$MemoryPhotosTableUpdateCompanionBuilder,
    (
      MemoryPhotoRow,
      BaseReferences<_$AppDatabase, $MemoryPhotosTable, MemoryPhotoRow>
    ),
    MemoryPhotoRow,
    PrefetchHooks Function()>;
typedef $$SetlistItemsTableCreateCompanionBuilder = SetlistItemsCompanion
    Function({
  required String id,
  required String genbaId,
  required String ownerId,
  required int position,
  required String songTitle,
  Value<String?> note,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$SetlistItemsTableUpdateCompanionBuilder = SetlistItemsCompanion
    Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<int> position,
  Value<String> songTitle,
  Value<String?> note,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$SetlistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SetlistItemsTable> {
  $$SetlistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get songTitle => $composableBuilder(
      column: $table.songTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SetlistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetlistItemsTable> {
  $$SetlistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get songTitle => $composableBuilder(
      column: $table.songTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SetlistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetlistItemsTable> {
  $$SetlistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get songTitle =>
      $composableBuilder(column: $table.songTitle, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SetlistItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetlistItemsTable,
    SetlistItemRow,
    $$SetlistItemsTableFilterComposer,
    $$SetlistItemsTableOrderingComposer,
    $$SetlistItemsTableAnnotationComposer,
    $$SetlistItemsTableCreateCompanionBuilder,
    $$SetlistItemsTableUpdateCompanionBuilder,
    (
      SetlistItemRow,
      BaseReferences<_$AppDatabase, $SetlistItemsTable, SetlistItemRow>
    ),
    SetlistItemRow,
    PrefetchHooks Function()> {
  $$SetlistItemsTableTableManager(_$AppDatabase db, $SetlistItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> songTitle = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetlistItemsCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            position: position,
            songTitle: songTitle,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            required int position,
            required String songTitle,
            Value<String?> note = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SetlistItemsCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            position: position,
            songTitle: songTitle,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SetlistItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetlistItemsTable,
    SetlistItemRow,
    $$SetlistItemsTableFilterComposer,
    $$SetlistItemsTableOrderingComposer,
    $$SetlistItemsTableAnnotationComposer,
    $$SetlistItemsTableCreateCompanionBuilder,
    $$SetlistItemsTableUpdateCompanionBuilder,
    (
      SetlistItemRow,
      BaseReferences<_$AppDatabase, $SetlistItemsTable, SetlistItemRow>
    ),
    SetlistItemRow,
    PrefetchHooks Function()>;
typedef $$GoodsItemsTableCreateCompanionBuilder = GoodsItemsCompanion Function({
  required String id,
  required String genbaId,
  required String ownerId,
  required String name,
  Value<int?> price,
  Value<int> quantity,
  Value<String?> memo,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$GoodsItemsTableUpdateCompanionBuilder = GoodsItemsCompanion Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> name,
  Value<int?> price,
  Value<int> quantity,
  Value<String?> memo,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$GoodsItemsTableFilterComposer
    extends Composer<_$AppDatabase, $GoodsItemsTable> {
  $$GoodsItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$GoodsItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoodsItemsTable> {
  $$GoodsItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$GoodsItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoodsItemsTable> {
  $$GoodsItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoodsItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoodsItemsTable,
    GoodsItemRow,
    $$GoodsItemsTableFilterComposer,
    $$GoodsItemsTableOrderingComposer,
    $$GoodsItemsTableAnnotationComposer,
    $$GoodsItemsTableCreateCompanionBuilder,
    $$GoodsItemsTableUpdateCompanionBuilder,
    (
      GoodsItemRow,
      BaseReferences<_$AppDatabase, $GoodsItemsTable, GoodsItemRow>
    ),
    GoodsItemRow,
    PrefetchHooks Function()> {
  $$GoodsItemsTableTableManager(_$AppDatabase db, $GoodsItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoodsItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoodsItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoodsItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> price = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoodsItemsCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            price: price,
            quantity: quantity,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            required String name,
            Value<int?> price = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoodsItemsCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            price: price,
            quantity: quantity,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GoodsItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoodsItemsTable,
    GoodsItemRow,
    $$GoodsItemsTableFilterComposer,
    $$GoodsItemsTableOrderingComposer,
    $$GoodsItemsTableAnnotationComposer,
    $$GoodsItemsTableCreateCompanionBuilder,
    $$GoodsItemsTableUpdateCompanionBuilder,
    (
      GoodsItemRow,
      BaseReferences<_$AppDatabase, $GoodsItemsTable, GoodsItemRow>
    ),
    GoodsItemRow,
    PrefetchHooks Function()>;
typedef $$VisitedPlacesTableCreateCompanionBuilder = VisitedPlacesCompanion
    Function({
  required String id,
  required String genbaId,
  required String ownerId,
  required String name,
  Value<String> category,
  Value<String?> memo,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$VisitedPlacesTableUpdateCompanionBuilder = VisitedPlacesCompanion
    Function({
  Value<String> id,
  Value<String> genbaId,
  Value<String> ownerId,
  Value<String> name,
  Value<String> category,
  Value<String?> memo,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$VisitedPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $VisitedPlacesTable> {
  $$VisitedPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$VisitedPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitedPlacesTable> {
  $$VisitedPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genbaId => $composableBuilder(
      column: $table.genbaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VisitedPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitedPlacesTable> {
  $$VisitedPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genbaId =>
      $composableBuilder(column: $table.genbaId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VisitedPlacesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VisitedPlacesTable,
    VisitedPlaceRow,
    $$VisitedPlacesTableFilterComposer,
    $$VisitedPlacesTableOrderingComposer,
    $$VisitedPlacesTableAnnotationComposer,
    $$VisitedPlacesTableCreateCompanionBuilder,
    $$VisitedPlacesTableUpdateCompanionBuilder,
    (
      VisitedPlaceRow,
      BaseReferences<_$AppDatabase, $VisitedPlacesTable, VisitedPlaceRow>
    ),
    VisitedPlaceRow,
    PrefetchHooks Function()> {
  $$VisitedPlacesTableTableManager(_$AppDatabase db, $VisitedPlacesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitedPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitedPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitedPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> genbaId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitedPlacesCompanion(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            category: category,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String genbaId,
            required String ownerId,
            required String name,
            Value<String> category = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VisitedPlacesCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: ownerId,
            name: name,
            category: category,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitedPlacesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VisitedPlacesTable,
    VisitedPlaceRow,
    $$VisitedPlacesTableFilterComposer,
    $$VisitedPlacesTableOrderingComposer,
    $$VisitedPlacesTableAnnotationComposer,
    $$VisitedPlacesTableCreateCompanionBuilder,
    $$VisitedPlacesTableUpdateCompanionBuilder,
    (
      VisitedPlaceRow,
      BaseReferences<_$AppDatabase, $VisitedPlacesTable, VisitedPlaceRow>
    ),
    VisitedPlaceRow,
    PrefetchHooks Function()>;
typedef $$OshiGroupsTableCreateCompanionBuilder = OshiGroupsCompanion Function({
  required String id,
  required String ownerId,
  required String name,
  Value<String?> kind,
  Value<String?> color,
  Value<String?> memo,
  Value<String?> imageLocalPath,
  Value<String?> imageAltText,
  Value<bool> isFavorite,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$OshiGroupsTableUpdateCompanionBuilder = OshiGroupsCompanion Function({
  Value<String> id,
  Value<String> ownerId,
  Value<String> name,
  Value<String?> kind,
  Value<String?> color,
  Value<String?> memo,
  Value<String?> imageLocalPath,
  Value<String?> imageAltText,
  Value<bool> isFavorite,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$OshiGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $OshiGroupsTable> {
  $$OshiGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageAltText => $composableBuilder(
      column: $table.imageAltText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OshiGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $OshiGroupsTable> {
  $$OshiGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageAltText => $composableBuilder(
      column: $table.imageAltText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OshiGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OshiGroupsTable> {
  $$OshiGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath, builder: (column) => column);

  GeneratedColumn<String> get imageAltText => $composableBuilder(
      column: $table.imageAltText, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OshiGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OshiGroupsTable,
    OshiGroupRow,
    $$OshiGroupsTableFilterComposer,
    $$OshiGroupsTableOrderingComposer,
    $$OshiGroupsTableAnnotationComposer,
    $$OshiGroupsTableCreateCompanionBuilder,
    $$OshiGroupsTableUpdateCompanionBuilder,
    (
      OshiGroupRow,
      BaseReferences<_$AppDatabase, $OshiGroupsTable, OshiGroupRow>
    ),
    OshiGroupRow,
    PrefetchHooks Function()> {
  $$OshiGroupsTableTableManager(_$AppDatabase db, $OshiGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OshiGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OshiGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OshiGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> kind = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String?> imageLocalPath = const Value.absent(),
            Value<String?> imageAltText = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OshiGroupsCompanion(
            id: id,
            ownerId: ownerId,
            name: name,
            kind: kind,
            color: color,
            memo: memo,
            imageLocalPath: imageLocalPath,
            imageAltText: imageAltText,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String ownerId,
            required String name,
            Value<String?> kind = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String?> imageLocalPath = const Value.absent(),
            Value<String?> imageAltText = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OshiGroupsCompanion.insert(
            id: id,
            ownerId: ownerId,
            name: name,
            kind: kind,
            color: color,
            memo: memo,
            imageLocalPath: imageLocalPath,
            imageAltText: imageAltText,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OshiGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OshiGroupsTable,
    OshiGroupRow,
    $$OshiGroupsTableFilterComposer,
    $$OshiGroupsTableOrderingComposer,
    $$OshiGroupsTableAnnotationComposer,
    $$OshiGroupsTableCreateCompanionBuilder,
    $$OshiGroupsTableUpdateCompanionBuilder,
    (
      OshiGroupRow,
      BaseReferences<_$AppDatabase, $OshiGroupsTable, OshiGroupRow>
    ),
    OshiGroupRow,
    PrefetchHooks Function()>;
typedef $$OshiMembersTableCreateCompanionBuilder = OshiMembersCompanion
    Function({
  required String id,
  required String groupId,
  required String ownerId,
  required String name,
  Value<String> rank,
  Value<String?> color,
  Value<String?> oshiSince,
  Value<String?> birthday,
  Value<String?> memo,
  Value<String?> imageLocalPath,
  Value<String?> imageAltText,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$OshiMembersTableUpdateCompanionBuilder = OshiMembersCompanion
    Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> ownerId,
  Value<String> name,
  Value<String> rank,
  Value<String?> color,
  Value<String?> oshiSince,
  Value<String?> birthday,
  Value<String?> memo,
  Value<String?> imageLocalPath,
  Value<String?> imageAltText,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$OshiMembersTableFilterComposer
    extends Composer<_$AppDatabase, $OshiMembersTable> {
  $$OshiMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oshiSince => $composableBuilder(
      column: $table.oshiSince, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageAltText => $composableBuilder(
      column: $table.imageAltText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OshiMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $OshiMembersTable> {
  $$OshiMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oshiSince => $composableBuilder(
      column: $table.oshiSince, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthday => $composableBuilder(
      column: $table.birthday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageAltText => $composableBuilder(
      column: $table.imageAltText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OshiMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OshiMembersTable> {
  $$OshiMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get oshiSince =>
      $composableBuilder(column: $table.oshiSince, builder: (column) => column);

  GeneratedColumn<String> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get imageLocalPath => $composableBuilder(
      column: $table.imageLocalPath, builder: (column) => column);

  GeneratedColumn<String> get imageAltText => $composableBuilder(
      column: $table.imageAltText, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OshiMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OshiMembersTable,
    OshiMemberRow,
    $$OshiMembersTableFilterComposer,
    $$OshiMembersTableOrderingComposer,
    $$OshiMembersTableAnnotationComposer,
    $$OshiMembersTableCreateCompanionBuilder,
    $$OshiMembersTableUpdateCompanionBuilder,
    (
      OshiMemberRow,
      BaseReferences<_$AppDatabase, $OshiMembersTable, OshiMemberRow>
    ),
    OshiMemberRow,
    PrefetchHooks Function()> {
  $$OshiMembersTableTableManager(_$AppDatabase db, $OshiMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OshiMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OshiMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OshiMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> rank = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> oshiSince = const Value.absent(),
            Value<String?> birthday = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String?> imageLocalPath = const Value.absent(),
            Value<String?> imageAltText = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OshiMembersCompanion(
            id: id,
            groupId: groupId,
            ownerId: ownerId,
            name: name,
            rank: rank,
            color: color,
            oshiSince: oshiSince,
            birthday: birthday,
            memo: memo,
            imageLocalPath: imageLocalPath,
            imageAltText: imageAltText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String groupId,
            required String ownerId,
            required String name,
            Value<String> rank = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> oshiSince = const Value.absent(),
            Value<String?> birthday = const Value.absent(),
            Value<String?> memo = const Value.absent(),
            Value<String?> imageLocalPath = const Value.absent(),
            Value<String?> imageAltText = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OshiMembersCompanion.insert(
            id: id,
            groupId: groupId,
            ownerId: ownerId,
            name: name,
            rank: rank,
            color: color,
            oshiSince: oshiSince,
            birthday: birthday,
            memo: memo,
            imageLocalPath: imageLocalPath,
            imageAltText: imageAltText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OshiMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OshiMembersTable,
    OshiMemberRow,
    $$OshiMembersTableFilterComposer,
    $$OshiMembersTableOrderingComposer,
    $$OshiMembersTableAnnotationComposer,
    $$OshiMembersTableCreateCompanionBuilder,
    $$OshiMembersTableUpdateCompanionBuilder,
    (
      OshiMemberRow,
      BaseReferences<_$AppDatabase, $OshiMembersTable, OshiMemberRow>
    ),
    OshiMemberRow,
    PrefetchHooks Function()>;
typedef $$OshiAnniversariesTableCreateCompanionBuilder
    = OshiAnniversariesCompanion Function({
  required String id,
  required String ownerId,
  required String groupId,
  Value<String?> memberId,
  required String label,
  required String date,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$OshiAnniversariesTableUpdateCompanionBuilder
    = OshiAnniversariesCompanion Function({
  Value<String> id,
  Value<String> ownerId,
  Value<String> groupId,
  Value<String?> memberId,
  Value<String> label,
  Value<String> date,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$OshiAnniversariesTableFilterComposer
    extends Composer<_$AppDatabase, $OshiAnniversariesTable> {
  $$OshiAnniversariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OshiAnniversariesTableOrderingComposer
    extends Composer<_$AppDatabase, $OshiAnniversariesTable> {
  $$OshiAnniversariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberId => $composableBuilder(
      column: $table.memberId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OshiAnniversariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OshiAnniversariesTable> {
  $$OshiAnniversariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OshiAnniversariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OshiAnniversariesTable,
    OshiAnniversaryRow,
    $$OshiAnniversariesTableFilterComposer,
    $$OshiAnniversariesTableOrderingComposer,
    $$OshiAnniversariesTableAnnotationComposer,
    $$OshiAnniversariesTableCreateCompanionBuilder,
    $$OshiAnniversariesTableUpdateCompanionBuilder,
    (
      OshiAnniversaryRow,
      BaseReferences<_$AppDatabase, $OshiAnniversariesTable, OshiAnniversaryRow>
    ),
    OshiAnniversaryRow,
    PrefetchHooks Function()> {
  $$OshiAnniversariesTableTableManager(
      _$AppDatabase db, $OshiAnniversariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OshiAnniversariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OshiAnniversariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OshiAnniversariesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String?> memberId = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OshiAnniversariesCompanion(
            id: id,
            ownerId: ownerId,
            groupId: groupId,
            memberId: memberId,
            label: label,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String ownerId,
            required String groupId,
            Value<String?> memberId = const Value.absent(),
            required String label,
            required String date,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OshiAnniversariesCompanion.insert(
            id: id,
            ownerId: ownerId,
            groupId: groupId,
            memberId: memberId,
            label: label,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OshiAnniversariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OshiAnniversariesTable,
    OshiAnniversaryRow,
    $$OshiAnniversariesTableFilterComposer,
    $$OshiAnniversariesTableOrderingComposer,
    $$OshiAnniversariesTableAnnotationComposer,
    $$OshiAnniversariesTableCreateCompanionBuilder,
    $$OshiAnniversariesTableUpdateCompanionBuilder,
    (
      OshiAnniversaryRow,
      BaseReferences<_$AppDatabase, $OshiAnniversariesTable, OshiAnniversaryRow>
    ),
    OshiAnniversaryRow,
    PrefetchHooks Function()>;
typedef $$OutboxOpsTableCreateCompanionBuilder = OutboxOpsCompanion Function({
  required String mutationId,
  required String ownerId,
  required String entityTable,
  required String entityId,
  required String opType,
  Value<String> payload,
  Value<String> status,
  Value<int> attempts,
  Value<String?> lastError,
  Value<String?> nextRetryAt,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$OutboxOpsTableUpdateCompanionBuilder = OutboxOpsCompanion Function({
  Value<String> mutationId,
  Value<String> ownerId,
  Value<String> entityTable,
  Value<String> entityId,
  Value<String> opType,
  Value<String> payload,
  Value<String> status,
  Value<int> attempts,
  Value<String?> lastError,
  Value<String?> nextRetryAt,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$OutboxOpsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxOpsTable> {
  $$OutboxOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get opType => $composableBuilder(
      column: $table.opType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$OutboxOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxOpsTable> {
  $$OutboxOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get opType => $composableBuilder(
      column: $table.opType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$OutboxOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxOpsTable> {
  $$OutboxOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OutboxOpsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OutboxOpsTable,
    OutboxOpRow,
    $$OutboxOpsTableFilterComposer,
    $$OutboxOpsTableOrderingComposer,
    $$OutboxOpsTableAnnotationComposer,
    $$OutboxOpsTableCreateCompanionBuilder,
    $$OutboxOpsTableUpdateCompanionBuilder,
    (OutboxOpRow, BaseReferences<_$AppDatabase, $OutboxOpsTable, OutboxOpRow>),
    OutboxOpRow,
    PrefetchHooks Function()> {
  $$OutboxOpsTableTableManager(_$AppDatabase db, $OutboxOpsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mutationId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> opType = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> nextRetryAt = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxOpsCompanion(
            mutationId: mutationId,
            ownerId: ownerId,
            entityTable: entityTable,
            entityId: entityId,
            opType: opType,
            payload: payload,
            status: status,
            attempts: attempts,
            lastError: lastError,
            nextRetryAt: nextRetryAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mutationId,
            required String ownerId,
            required String entityTable,
            required String entityId,
            required String opType,
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<String?> nextRetryAt = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxOpsCompanion.insert(
            mutationId: mutationId,
            ownerId: ownerId,
            entityTable: entityTable,
            entityId: entityId,
            opType: opType,
            payload: payload,
            status: status,
            attempts: attempts,
            lastError: lastError,
            nextRetryAt: nextRetryAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxOpsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OutboxOpsTable,
    OutboxOpRow,
    $$OutboxOpsTableFilterComposer,
    $$OutboxOpsTableOrderingComposer,
    $$OutboxOpsTableAnnotationComposer,
    $$OutboxOpsTableCreateCompanionBuilder,
    $$OutboxOpsTableUpdateCompanionBuilder,
    (OutboxOpRow, BaseReferences<_$AppDatabase, $OutboxOpsTable, OutboxOpRow>),
    OutboxOpRow,
    PrefetchHooks Function()>;
typedef $$AppKvsTableCreateCompanionBuilder = AppKvsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppKvsTableUpdateCompanionBuilder = AppKvsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppKvsTableFilterComposer
    extends Composer<_$AppDatabase, $AppKvsTable> {
  $$AppKvsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppKvsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppKvsTable> {
  $$AppKvsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppKvsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppKvsTable> {
  $$AppKvsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppKvsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppKvsTable,
    AppKvRow,
    $$AppKvsTableFilterComposer,
    $$AppKvsTableOrderingComposer,
    $$AppKvsTableAnnotationComposer,
    $$AppKvsTableCreateCompanionBuilder,
    $$AppKvsTableUpdateCompanionBuilder,
    (AppKvRow, BaseReferences<_$AppDatabase, $AppKvsTable, AppKvRow>),
    AppKvRow,
    PrefetchHooks Function()> {
  $$AppKvsTableTableManager(_$AppDatabase db, $AppKvsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppKvsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppKvsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppKvsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppKvsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppKvsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppKvsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppKvsTable,
    AppKvRow,
    $$AppKvsTableFilterComposer,
    $$AppKvsTableOrderingComposer,
    $$AppKvsTableAnnotationComposer,
    $$AppKvsTableCreateCompanionBuilder,
    $$AppKvsTableUpdateCompanionBuilder,
    (AppKvRow, BaseReferences<_$AppDatabase, $AppKvsTable, AppKvRow>),
    AppKvRow,
    PrefetchHooks Function()>;
typedef $$FormDraftsTableCreateCompanionBuilder = FormDraftsCompanion Function({
  required String ownerId,
  required String key,
  required String payload,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$FormDraftsTableUpdateCompanionBuilder = FormDraftsCompanion Function({
  Value<String> ownerId,
  Value<String> key,
  Value<String> payload,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$FormDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $FormDraftsTable> {
  $$FormDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FormDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $FormDraftsTable> {
  $$FormDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FormDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FormDraftsTable> {
  $$FormDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FormDraftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FormDraftsTable,
    FormDraftRow,
    $$FormDraftsTableFilterComposer,
    $$FormDraftsTableOrderingComposer,
    $$FormDraftsTableAnnotationComposer,
    $$FormDraftsTableCreateCompanionBuilder,
    $$FormDraftsTableUpdateCompanionBuilder,
    (
      FormDraftRow,
      BaseReferences<_$AppDatabase, $FormDraftsTable, FormDraftRow>
    ),
    FormDraftRow,
    PrefetchHooks Function()> {
  $$FormDraftsTableTableManager(_$AppDatabase db, $FormDraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ownerId = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FormDraftsCompanion(
            ownerId: ownerId,
            key: key,
            payload: payload,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ownerId,
            required String key,
            required String payload,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FormDraftsCompanion.insert(
            ownerId: ownerId,
            key: key,
            payload: payload,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FormDraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FormDraftsTable,
    FormDraftRow,
    $$FormDraftsTableFilterComposer,
    $$FormDraftsTableOrderingComposer,
    $$FormDraftsTableAnnotationComposer,
    $$FormDraftsTableCreateCompanionBuilder,
    $$FormDraftsTableUpdateCompanionBuilder,
    (
      FormDraftRow,
      BaseReferences<_$AppDatabase, $FormDraftsTable, FormDraftRow>
    ),
    FormDraftRow,
    PrefetchHooks Function()>;
typedef $$RemoteVersionsTableCreateCompanionBuilder = RemoteVersionsCompanion
    Function({
  required String ownerId,
  required String entityTable,
  required String entityId,
  required int version,
  Value<int> rowid,
});
typedef $$RemoteVersionsTableUpdateCompanionBuilder = RemoteVersionsCompanion
    Function({
  Value<String> ownerId,
  Value<String> entityTable,
  Value<String> entityId,
  Value<int> version,
  Value<int> rowid,
});

class $$RemoteVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteVersionsTable> {
  $$RemoteVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));
}

class $$RemoteVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteVersionsTable> {
  $$RemoteVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));
}

class $$RemoteVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteVersionsTable> {
  $$RemoteVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$RemoteVersionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemoteVersionsTable,
    RemoteVersionRow,
    $$RemoteVersionsTableFilterComposer,
    $$RemoteVersionsTableOrderingComposer,
    $$RemoteVersionsTableAnnotationComposer,
    $$RemoteVersionsTableCreateCompanionBuilder,
    $$RemoteVersionsTableUpdateCompanionBuilder,
    (
      RemoteVersionRow,
      BaseReferences<_$AppDatabase, $RemoteVersionsTable, RemoteVersionRow>
    ),
    RemoteVersionRow,
    PrefetchHooks Function()> {
  $$RemoteVersionsTableTableManager(
      _$AppDatabase db, $RemoteVersionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemoteVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemoteVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ownerId = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemoteVersionsCompanion(
            ownerId: ownerId,
            entityTable: entityTable,
            entityId: entityId,
            version: version,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ownerId,
            required String entityTable,
            required String entityId,
            required int version,
            Value<int> rowid = const Value.absent(),
          }) =>
              RemoteVersionsCompanion.insert(
            ownerId: ownerId,
            entityTable: entityTable,
            entityId: entityId,
            version: version,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemoteVersionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemoteVersionsTable,
    RemoteVersionRow,
    $$RemoteVersionsTableFilterComposer,
    $$RemoteVersionsTableOrderingComposer,
    $$RemoteVersionsTableAnnotationComposer,
    $$RemoteVersionsTableCreateCompanionBuilder,
    $$RemoteVersionsTableUpdateCompanionBuilder,
    (
      RemoteVersionRow,
      BaseReferences<_$AppDatabase, $RemoteVersionsTable, RemoteVersionRow>
    ),
    RemoteVersionRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GenbasTableTableManager get genbas =>
      $$GenbasTableTableManager(_db, _db.genbas);
  $$TicketsTableTableManager get tickets =>
      $$TicketsTableTableManager(_db, _db.tickets);
  $$TransportsTableTableManager get transports =>
      $$TransportsTableTableManager(_db, _db.transports);
  $$LodgingsTableTableManager get lodgings =>
      $$LodgingsTableTableManager(_db, _db.lodgings);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
  $$GenbaMemosTableTableManager get genbaMemos =>
      $$GenbaMemosTableTableManager(_db, _db.genbaMemos);
  $$MemoryEntriesTableTableManager get memoryEntries =>
      $$MemoryEntriesTableTableManager(_db, _db.memoryEntries);
  $$MemoryPhotosTableTableManager get memoryPhotos =>
      $$MemoryPhotosTableTableManager(_db, _db.memoryPhotos);
  $$SetlistItemsTableTableManager get setlistItems =>
      $$SetlistItemsTableTableManager(_db, _db.setlistItems);
  $$GoodsItemsTableTableManager get goodsItems =>
      $$GoodsItemsTableTableManager(_db, _db.goodsItems);
  $$VisitedPlacesTableTableManager get visitedPlaces =>
      $$VisitedPlacesTableTableManager(_db, _db.visitedPlaces);
  $$OshiGroupsTableTableManager get oshiGroups =>
      $$OshiGroupsTableTableManager(_db, _db.oshiGroups);
  $$OshiMembersTableTableManager get oshiMembers =>
      $$OshiMembersTableTableManager(_db, _db.oshiMembers);
  $$OshiAnniversariesTableTableManager get oshiAnniversaries =>
      $$OshiAnniversariesTableTableManager(_db, _db.oshiAnniversaries);
  $$OutboxOpsTableTableManager get outboxOps =>
      $$OutboxOpsTableTableManager(_db, _db.outboxOps);
  $$AppKvsTableTableManager get appKvs =>
      $$AppKvsTableTableManager(_db, _db.appKvs);
  $$FormDraftsTableTableManager get formDrafts =>
      $$FormDraftsTableTableManager(_db, _db.formDrafts);
  $$RemoteVersionsTableTableManager get remoteVersions =>
      $$RemoteVersionsTableTableManager(_db, _db.remoteVersions);
}
