import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../domain/memory.dart';
import '../domain/memory_repository.dart';
import 'memory_mappers.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl({
    required AppDatabase db,
    required OutboxStore outbox,
    required SyncEngine syncEngine,
    required Clock clock,
    required String? Function() ownerIdResolver,
  })  : _db = db,
        _outbox = outbox,
        _syncEngine = syncEngine,
        _clock = clock,
        _ownerId = ownerIdResolver;

  final AppDatabase _db;
  final OutboxStore _outbox;
  final SyncEngine _syncEngine;
  final Clock _clock;
  final String? Function() _ownerId;

  static const _uuid = Uuid();

  DateTime get _now => _clock.now().toUtc();

  @override
  Stream<MemoryBundle> watchByGenbaId(String genbaId) async* {
    yield await _query(genbaId);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.memoryEntries,
        _db.memoryPhotos,
        _db.setlistItems,
        _db.goodsItems,
        _db.visitedPlaces,
      ]),
    );
    await for (final _ in updates) {
      yield await _query(genbaId);
    }
  }

  Future<MemoryBundle> _query(String genbaId) async {
    final entry = await (_db.select(_db.memoryEntries)
          ..where((t) => t.genbaId.equals(genbaId)))
        .getSingleOrNull();
    final photos = await (_db.select(_db.memoryPhotos)
          ..where((t) => t.genbaId.equals(genbaId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final setlist = await (_db.select(_db.setlistItems)
          ..where((t) => t.genbaId.equals(genbaId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    final goods = await (_db.select(_db.goodsItems)
          ..where((t) => t.genbaId.equals(genbaId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final places = await (_db.select(_db.visitedPlaces)
          ..where((t) => t.genbaId.equals(genbaId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return MemoryBundle(
      genbaId: genbaId,
      entry: entry == null ? null : entryFromRow(entry),
      photos: photos.map(photoFromRow).toList(),
      setlist: setlist.map(setlistFromRow).toList(),
      goods: goods.map(goodsFromRow).toList(),
      places: places.map(placeFromRow).toList(),
    );
  }

  Future<Result<void>> _localWrite(
    Future<void> Function() write, {
    required String entityTable,
    required String entityId,
    required OutboxOpType opType,
    Map<String, dynamic> payload = const {},
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final result = await guardResult(
      () async {
        await _db.transaction(() async {
          await write();
          final now = _now;
          await _outbox.enqueue(
            OutboxOperation(
              mutationId: _uuid.v4(),
              ownerId: owner,
              entityTable: entityTable,
              entityId: entityId,
              opType: opType,
              payload: payload,
              createdAt: now,
              updatedAt: now,
            ),
          );
        });
      },
      onError: (e, _) => StorageFailure(cause: e),
    );
    if (result.isOk) _syncEngine.poke();
    return result;
  }

  @override
  Future<Result<void>> upsertEntry(MemoryEntry entry) {
    final stamped = entry.copyWith(updatedAt: _now);
    return _localWrite(
      () async {
        // genba_id 単位で1件（既存の別IDエントリは置き換え）。
        await (_db.delete(_db.memoryEntries)
              ..where(
                (t) =>
                    t.genbaId.equals(stamped.genbaId) &
                    t.id.isNotValue(stamped.id),
              ))
            .go();
        await _db
            .into(_db.memoryEntries)
            .insertOnConflictUpdate(entryToCompanion(stamped));
      },
      entityTable: SyncEntity.memoryEntries,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> addPhoto(MemoryPhoto photo) => updatePhoto(photo);

  @override
  Future<Result<void>> updatePhoto(MemoryPhoto photo) {
    final stamped = photo.copyWith(updatedAt: _now);
    // 写真バイナリはOutboxに載せない（メタデータのみ同期。画像本体の
    // アップロードは MemoryPhotoUploader の境界で扱う）。
    final payload = stamped.toJson()..remove('local_path');
    return _localWrite(
      () => _db
          .into(_db.memoryPhotos)
          .insertOnConflictUpdate(photoToCompanion(stamped)),
      entityTable: SyncEntity.memoryPhotos,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
    );
  }

  @override
  Future<Result<void>> deletePhoto(String id) => _localWrite(
        () =>
            (_db.delete(_db.memoryPhotos)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.memoryPhotos,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertSetlistItem(SetlistItem item) {
    final stamped = item.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db
          .into(_db.setlistItems)
          .insertOnConflictUpdate(setlistToCompanion(stamped)),
      entityTable: SyncEntity.setlistItems,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteSetlistItem(String id) => _localWrite(
        () =>
            (_db.delete(_db.setlistItems)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.setlistItems,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertGoodsItem(GoodsItem item) {
    final stamped = item.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db
          .into(_db.goodsItems)
          .insertOnConflictUpdate(goodsToCompanion(stamped)),
      entityTable: SyncEntity.goodsItems,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteGoodsItem(String id) => _localWrite(
        () => (_db.delete(_db.goodsItems)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.goodsItems,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertVisitedPlace(VisitedPlace place) {
    final stamped = place.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db
          .into(_db.visitedPlaces)
          .insertOnConflictUpdate(placeToCompanion(stamped)),
      entityTable: SyncEntity.visitedPlaces,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteVisitedPlace(String id) => _localWrite(
        () =>
            (_db.delete(_db.visitedPlaces)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.visitedPlaces,
        entityId: id,
        opType: OutboxOpType.delete,
      );
}
