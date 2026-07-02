import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/memory.dart';

MemoryEntry entryFromRow(MemoryEntryRow row) => MemoryEntry(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      impression: row.impression,
      bestMoment: row.bestMoment,
      mcNotes: row.mcNotes,
      seatView: row.seatView,
      tags: (jsonDecode(row.tags) as List<dynamic>).cast<String>(),
      declinedFields:
          (jsonDecode(row.declinedFields) as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

MemoryEntriesCompanion entryToCompanion(MemoryEntry e) =>
    MemoryEntriesCompanion.insert(
      id: e.id,
      genbaId: e.genbaId,
      ownerId: e.ownerId,
      impression: Value(e.impression),
      bestMoment: Value(e.bestMoment),
      mcNotes: Value(e.mcNotes),
      seatView: Value(e.seatView),
      tags: Value(jsonEncode(e.tags)),
      declinedFields: Value(jsonEncode(e.declinedFields)),
      createdAt: _ts(e.createdAt),
      updatedAt: _ts(e.updatedAt),
    );

MemoryPhoto photoFromRow(MemoryPhotoRow row) => MemoryPhoto(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      localPath: row.localPath,
      storagePath: row.storagePath,
      uploadStatus: switch (row.uploadStatus) {
        'queued' => PhotoUploadStatus.queued,
        'uploaded' => PhotoUploadStatus.uploaded,
        'failed' => PhotoUploadStatus.failed,
        _ => PhotoUploadStatus.localOnly,
      },
      caption: row.caption,
      isCover: row.isCover,
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

MemoryPhotosCompanion photoToCompanion(MemoryPhoto p) =>
    MemoryPhotosCompanion.insert(
      id: p.id,
      genbaId: p.genbaId,
      ownerId: p.ownerId,
      localPath: Value(p.localPath),
      storagePath: Value(p.storagePath),
      uploadStatus: Value(
        switch (p.uploadStatus) {
          PhotoUploadStatus.localOnly => 'local_only',
          PhotoUploadStatus.queued => 'queued',
          PhotoUploadStatus.uploaded => 'uploaded',
          PhotoUploadStatus.failed => 'failed',
        },
      ),
      caption: Value(p.caption),
      isCover: Value(p.isCover),
      sortOrder: Value(p.sortOrder),
      createdAt: _ts(p.createdAt),
      updatedAt: _ts(p.updatedAt),
    );

SetlistItem setlistFromRow(SetlistItemRow row) => SetlistItem(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      position: row.position,
      songTitle: row.songTitle,
      note: row.note,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

SetlistItemsCompanion setlistToCompanion(SetlistItem s) =>
    SetlistItemsCompanion.insert(
      id: s.id,
      genbaId: s.genbaId,
      ownerId: s.ownerId,
      position: s.position,
      songTitle: s.songTitle,
      note: Value(s.note),
      createdAt: _ts(s.createdAt),
      updatedAt: _ts(s.updatedAt),
    );

GoodsItem goodsFromRow(GoodsItemRow row) => GoodsItem(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      name: row.name,
      price: row.price,
      quantity: row.quantity,
      memo: row.memo,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

GoodsItemsCompanion goodsToCompanion(GoodsItem g) => GoodsItemsCompanion.insert(
      id: g.id,
      genbaId: g.genbaId,
      ownerId: g.ownerId,
      name: g.name,
      price: Value(g.price),
      quantity: Value(g.quantity),
      memo: Value(g.memo),
      createdAt: _ts(g.createdAt),
      updatedAt: _ts(g.updatedAt),
    );

VisitedPlace placeFromRow(VisitedPlaceRow row) => VisitedPlace(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      name: row.name,
      category: row.category,
      memo: row.memo,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

VisitedPlacesCompanion placeToCompanion(VisitedPlace v) =>
    VisitedPlacesCompanion.insert(
      id: v.id,
      genbaId: v.genbaId,
      ownerId: v.ownerId,
      name: v.name,
      category: Value(v.category),
      memo: Value(v.memo),
      createdAt: _ts(v.createdAt),
      updatedAt: _ts(v.updatedAt),
    );

String _ts(DateTime d) => d.toUtc().toIso8601String();
