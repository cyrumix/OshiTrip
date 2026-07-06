import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/images/image_upload_status.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_plan.dart';
import '../domain/itinerary_spot.dart';
import '../domain/itinerary_spot_link.dart';
import '../domain/itinerary_value_origin.dart';

/// Drift 行 ⇄ 旅程ドメインエンティティのマッピング。
///
/// enum は DB にも JSON（Outbox payload / サーバー行）にも同じ snake_case
/// 文字列で保持する（`@JsonValue` と `_snake(enum.name)` が一致する前提。
/// enum round-trip テストで担保する）。JSON とのマッピングはエンティティ側の
/// `fromJson/toJson` が担う。

// ---------------------------------------------------------------------------
// ItineraryPlan
// ---------------------------------------------------------------------------
ItineraryPlan planFromRow(ItineraryPlanRow row) => ItineraryPlan(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      title: row.title,
      memo: row.memo,
      startDate: row.startDate == null ? null : DateTime.parse(row.startDate!),
      endDate: row.endDate == null ? null : DateTime.parse(row.endDate!),
      timeZoneId: row.timeZoneId,
      coverImageLocalPath: row.coverImageLocalPath,
      coverImageStoragePath: row.coverImageStoragePath,
      coverImageUploadStatus:
          ImageUploadStatusJson.fromWire(row.coverImageUploadStatus),
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

/// [preserveLocalImage] が true のとき cover_image_local_path を companion に
/// 含めない（`Value.absent`）。リモート pull はサーバーに存在しないこの端末内
/// 参照を null で上書きしてはならない（H-04）。ローカル書き込みでは false。
ItineraryPlansCompanion planToCompanion(
  ItineraryPlan p, {
  bool preserveLocalImage = false,
}) =>
    ItineraryPlansCompanion.insert(
      id: p.id,
      genbaId: p.genbaId,
      ownerId: p.ownerId,
      title: p.title,
      memo: Value(p.memo),
      startDate: Value(p.startDate == null ? null : _date(p.startDate!)),
      endDate: Value(p.endDate == null ? null : _date(p.endDate!)),
      timeZoneId: p.timeZoneId,
      coverImageLocalPath: preserveLocalImage
          ? const Value.absent()
          : Value(p.coverImageLocalPath),
      coverImageStoragePath: Value(p.coverImageStoragePath),
      coverImageUploadStatus: Value(p.coverImageUploadStatus.wire),
      sortOrder: Value(p.sortOrder),
      createdAt: _ts(p.createdAt),
      updatedAt: _ts(p.updatedAt),
    );

// ---------------------------------------------------------------------------
// ItinerarySpot
// ---------------------------------------------------------------------------
ItinerarySpot spotFromRow(ItinerarySpotRow row) => ItinerarySpot(
      id: row.id,
      planId: row.planId,
      ownerId: row.ownerId,
      source: _enumFromJson(
        ItinerarySpotSource.values,
        row.source,
        ItinerarySpotSource.manual,
      ),
      googlePlaceId: row.googlePlaceId,
      name: row.name,
      category: _enumFromJson(
        ItinerarySpotCategory.values,
        row.category,
        ItinerarySpotCategory.other,
      ),
      address: row.address,
      dataOrigin: _enumFromJson(
        ItineraryValueOrigin.values,
        row.dataOrigin,
        ItineraryValueOrigin.userProvided,
      ),
      rightsBasis: row.rightsBasis,
      latitude: row.latitude,
      longitude: row.longitude,
      phoneNumber: row.phoneNumber,
      websiteUrl: row.websiteUrl,
      openingHoursText: row.openingHoursText,
      googleMapsUrl: row.googleMapsUrl,
      googleFetchedAt: row.googleFetchedAt == null
          ? null
          : DateTime.parse(row.googleFetchedAt!),
      googlePhotoName: row.googlePhotoName,
      googlePhotoAttribution: row.googlePhotoAttribution,
      userImageLocalPath: row.userImageLocalPath,
      userImageStoragePath: row.userImageStoragePath,
      userImageUploadStatus:
          ImageUploadStatusJson.fromWire(row.userImageUploadStatus),
      userImageAltText: row.userImageAltText,
      memo: row.memo,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

/// [preserveLocalImage] が true のとき user_image_local_path を companion に
/// 含めない（`Value.absent`）。リモート pull はサーバーに存在しないこの端末内
/// 参照を null で上書きしてはならない（H-04）。ローカル書き込みでは false。
ItinerarySpotsCompanion spotToCompanion(
  ItinerarySpot s, {
  bool preserveLocalImage = false,
}) =>
    ItinerarySpotsCompanion.insert(
      id: s.id,
      planId: s.planId,
      ownerId: s.ownerId,
      source: Value(_snake(s.source.name)),
      googlePlaceId: Value(s.googlePlaceId),
      name: s.name,
      category: _snake(s.category.name),
      address: Value(s.address),
      dataOrigin: Value(_snake(s.dataOrigin.name)),
      rightsBasis: Value(s.rightsBasis),
      latitude: Value(s.latitude),
      longitude: Value(s.longitude),
      phoneNumber: Value(s.phoneNumber),
      websiteUrl: Value(s.websiteUrl),
      openingHoursText: Value(s.openingHoursText),
      googleMapsUrl: Value(s.googleMapsUrl),
      googleFetchedAt: Value(s.googleFetchedAt?.toUtc().toIso8601String()),
      googlePhotoName: Value(s.googlePhotoName),
      googlePhotoAttribution: Value(s.googlePhotoAttribution),
      userImageLocalPath: preserveLocalImage
          ? const Value.absent()
          : Value(s.userImageLocalPath),
      userImageStoragePath: Value(s.userImageStoragePath),
      userImageUploadStatus: Value(s.userImageUploadStatus.wire),
      userImageAltText: Value(s.userImageAltText),
      memo: Value(s.memo),
      createdAt: _ts(s.createdAt),
      updatedAt: _ts(s.updatedAt),
    );

// ---------------------------------------------------------------------------
// ItinerarySpotLink
// ---------------------------------------------------------------------------
ItinerarySpotLink spotLinkFromRow(ItinerarySpotLinkRow row) =>
    ItinerarySpotLink(
      id: row.id,
      spotId: row.spotId,
      ownerId: row.ownerId,
      kind: _enumFromJson(
        ItinerarySpotLinkKind.values,
        row.kind,
        ItinerarySpotLinkKind.other,
      ),
      url: row.url,
      label: row.label,
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

ItinerarySpotLinksCompanion spotLinkToCompanion(ItinerarySpotLink l) =>
    ItinerarySpotLinksCompanion.insert(
      id: l.id,
      spotId: l.spotId,
      ownerId: l.ownerId,
      kind: _snake(l.kind.name),
      url: l.url,
      label: Value(l.label),
      sortOrder: Value(l.sortOrder),
      createdAt: _ts(l.createdAt),
      updatedAt: _ts(l.updatedAt),
    );

// ---------------------------------------------------------------------------
// ItineraryEntry
// ---------------------------------------------------------------------------
ItineraryEntry entryFromRow(ItineraryEntryRow row) => ItineraryEntry(
      id: row.id,
      planId: row.planId,
      ownerId: row.ownerId,
      kind: _enumFromJson(
        ItineraryEntryKind.values,
        row.kind,
        ItineraryEntryKind.note,
      ),
      spotId: row.spotId,
      transportId: row.transportId,
      lodgingId: row.lodgingId,
      titleOverride: row.titleOverride,
      startAt: row.startAt == null ? null : DateTime.parse(row.startAt!),
      endAt: row.endAt == null ? null : DateTime.parse(row.endAt!),
      localDate: row.localDate == null ? null : DateTime.parse(row.localDate!),
      timeZoneId: row.timeZoneId,
      bufferBeforeMinutes: row.bufferBeforeMinutes,
      bufferAfterMinutes: row.bufferAfterMinutes,
      memo: row.memo,
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

ItineraryEntriesCompanion entryToCompanion(ItineraryEntry e) =>
    ItineraryEntriesCompanion.insert(
      id: e.id,
      planId: e.planId,
      ownerId: e.ownerId,
      kind: _snake(e.kind.name),
      spotId: Value(e.spotId),
      transportId: Value(e.transportId),
      lodgingId: Value(e.lodgingId),
      titleOverride: Value(e.titleOverride),
      startAt: Value(e.startAt?.toUtc().toIso8601String()),
      endAt: Value(e.endAt?.toUtc().toIso8601String()),
      localDate: Value(e.localDate == null ? null : _date(e.localDate!)),
      timeZoneId: Value(e.timeZoneId),
      bufferBeforeMinutes: Value(e.bufferBeforeMinutes),
      bufferAfterMinutes: Value(e.bufferAfterMinutes),
      memo: Value(e.memo),
      sortOrder: Value(e.sortOrder),
      createdAt: _ts(e.createdAt),
      updatedAt: _ts(e.updatedAt),
    );

// ---------------------------------------------------------------------------
// ItineraryLeg
// ---------------------------------------------------------------------------
ItineraryLeg legFromRow(ItineraryLegRow row) => ItineraryLeg(
      id: row.id,
      planId: row.planId,
      ownerId: row.ownerId,
      originEntryId: row.originEntryId,
      destinationEntryId: row.destinationEntryId,
      source: _enumFromJson(
        ItineraryLegSource.values,
        row.source,
        ItineraryLegSource.manual,
      ),
      travelMode: _enumFromJson(
        ItineraryTravelMode.values,
        row.travelMode,
        ItineraryTravelMode.other,
      ),
      departureAt:
          row.departureAt == null ? null : DateTime.parse(row.departureAt!),
      arrivalAt: row.arrivalAt == null ? null : DateTime.parse(row.arrivalAt!),
      durationMinutes: row.durationMinutes,
      distanceMeters: row.distanceMeters,
      fareAmountMinor: row.fareAmountMinor,
      fareCurrency: row.fareCurrency,
      valueOrigin: _enumFromJson(
        ItineraryValueOrigin.values,
        row.valueOrigin,
        ItineraryValueOrigin.userProvided,
      ),
      rightsBasis: row.rightsBasis,
      representativeTimeBucket: row.representativeTimeBucket,
      lastVerifiedAt: row.lastVerifiedAt == null
          ? null
          : DateTime.parse(row.lastVerifiedAt!),
      routeSummary: row.routeSummary,
      transitStepsJson: row.transitStepsJson,
      encodedPolyline: row.encodedPolyline,
      googleMapsUrl: row.googleMapsUrl,
      fetchedAt: row.fetchedAt == null ? null : DateTime.parse(row.fetchedAt!),
      cacheKey: row.cacheKey,
      isStale: row.isStale,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

ItineraryLegsCompanion legToCompanion(ItineraryLeg l) =>
    ItineraryLegsCompanion.insert(
      id: l.id,
      planId: l.planId,
      ownerId: l.ownerId,
      originEntryId: l.originEntryId,
      destinationEntryId: l.destinationEntryId,
      source: Value(_snake(l.source.name)),
      travelMode: Value(_snake(l.travelMode.name)),
      departureAt: Value(l.departureAt?.toUtc().toIso8601String()),
      arrivalAt: Value(l.arrivalAt?.toUtc().toIso8601String()),
      durationMinutes: Value(l.durationMinutes),
      distanceMeters: Value(l.distanceMeters),
      fareAmountMinor: Value(l.fareAmountMinor),
      fareCurrency: Value(l.fareCurrency),
      valueOrigin: Value(_snake(l.valueOrigin.name)),
      rightsBasis: Value(l.rightsBasis),
      representativeTimeBucket: Value(l.representativeTimeBucket),
      lastVerifiedAt: Value(l.lastVerifiedAt?.toUtc().toIso8601String()),
      routeSummary: Value(l.routeSummary),
      transitStepsJson: Value(l.transitStepsJson),
      encodedPolyline: Value(l.encodedPolyline),
      googleMapsUrl: Value(l.googleMapsUrl),
      fetchedAt: Value(l.fetchedAt?.toUtc().toIso8601String()),
      cacheKey: Value(l.cacheKey),
      isStale: Value(l.isStale),
      createdAt: _ts(l.createdAt),
      updatedAt: _ts(l.updatedAt),
    );

// ---------------------------------------------------------------------------
// 共通ヘルパ（genba_mappers と同型。DB は snake_case wire を保持する）
// ---------------------------------------------------------------------------
String _date(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String _ts(DateTime d) => d.toUtc().toIso8601String();

/// snake_case 文字列から enum を復元（不明値は既定値でフォールバック）。
T _enumFromJson<T extends Enum>(List<T> values, String raw, T fallback) {
  final camel = _camel(raw);
  for (final v in values) {
    if (v.name == camel || v.name == raw) return v;
  }
  return fallback;
}

String _camel(String snake) {
  final parts = snake.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
          .join();
}

String _snake(String camel) => camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
