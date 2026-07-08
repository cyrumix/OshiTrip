import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/owner_guard.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/remote_pull.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../domain/memory.dart';
import '../domain/memory_repository.dart';
import 'memory_mappers.dart';

/// [ownerIdResolver] が返す owner（未認証時は null）ですべてのローカル
/// 読み書きを絞る（C-01）。
class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl({
    required AppDatabase db,
    required OutboxStore outbox,
    required SyncEngine syncEngine,
    required Clock clock,
    required String? Function() ownerIdResolver,
    SupabaseClient? Function()? remoteResolver,
  })  : _db = db,
        _outbox = outbox,
        _syncEngine = syncEngine,
        _clock = clock,
        _ownerId = ownerIdResolver,
        _remote = remoteResolver ?? (() => null);

  final AppDatabase _db;
  final OutboxStore _outbox;
  final SyncEngine _syncEngine;
  final Clock _clock;
  final String? Function() _ownerId;
  final SupabaseClient? Function() _remote;

  static const _uuid = Uuid();

  DateTime get _now => _clock.now().toUtc();

  @override
  Stream<MemoryBundle> watchByGenbaId(String genbaId) async* {
    final owner = _ownerId();
    if (owner == null) {
      yield MemoryBundle(genbaId: genbaId);
      return;
    }
    yield await _query(genbaId, owner);
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
      final current = _ownerId();
      if (current == null) {
        yield MemoryBundle(genbaId: genbaId);
        continue;
      }
      yield await _query(genbaId, current);
    }
  }

  Future<MemoryBundle> _query(String genbaId, String owner) async {
    final entry = await (_db.select(_db.memoryEntries)
          ..where(
            (t) => t.genbaId.equals(genbaId) & t.ownerId.equals(owner),
          ))
        .getSingleOrNull();
    final photos = await (_db.select(_db.memoryPhotos)
          ..where(
            (t) => t.genbaId.equals(genbaId) & t.ownerId.equals(owner),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final setlist = await (_db.select(_db.setlistItems)
          ..where(
            (t) => t.genbaId.equals(genbaId) & t.ownerId.equals(owner),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    final goods = await (_db.select(_db.goodsItems)
          ..where(
            (t) => t.genbaId.equals(genbaId) & t.ownerId.equals(owner),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final places = await (_db.select(_db.visitedPlaces)
          ..where(
            (t) => t.genbaId.equals(genbaId) & t.ownerId.equals(owner),
          )
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

  /// [parentTable]/[parentId] を指定すると、書き込みと同一 transaction 内で
  /// 「親が現在ownerに属する」ことを検証し、満たさない場合は型付き
  /// [ValidationFailure] で拒否してローカル行も Outbox も作成しない（C-01）。
  Future<Result<void>> _localWrite(
    Future<void> Function(String owner) write, {
    required String entityTable,
    required String entityId,
    required OutboxOpType opType,
    Map<String, dynamic> payload = const {},
    String? parentTable,
    String? parentId,
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    if (payload.containsKey('owner_id') && payload['owner_id'] != owner) {
      return const Err(AuthFailure(message: '所有者が一致しません'));
    }
    if (opType == OutboxOpType.upsert &&
        await _db.existsForOtherOwner(entityTable, entityId, owner)) {
      return const Err(AuthFailure(message: '既存の別ユーザーのデータは操作できません'));
    }
    try {
      await _db.transaction(() async {
        if (parentTable != null && parentId != null) {
          final ok =
              await _db.parentBelongsToOwner(parentTable, parentId, owner);
          if (!ok) throw ParentOwnershipException(parentTable, parentId);
        }
        await write(owner);
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
    } on ParentOwnershipException {
      return const Err(
        ValidationFailure('親データが存在しないか、アクセス権がありません'),
      );
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    return const Ok(null);
  }

  @override
  Future<Result<void>> upsertEntry(MemoryEntry entry) {
    final stamped = entry.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) async {
        // genba_id 単位で1件（既存の別IDエントリは置き換え）。
        await (_db.delete(_db.memoryEntries)
              ..where(
                (t) =>
                    t.genbaId.equals(stamped.genbaId) &
                    t.id.isNotValue(stamped.id) &
                    t.ownerId.equals(owner),
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
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> setEntryFavorite({
    required String genbaId,
    required bool isFavorite,
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final bundle = await watchByGenbaId(genbaId).first;
    final existing = bundle.entry;
    final now = _now;
    final entry = existing?.copyWith(isFavorite: isFavorite) ??
        MemoryEntry(
          id: _uuid.v4(),
          genbaId: genbaId,
          ownerId: owner,
          isFavorite: isFavorite,
          createdAt: now,
          updatedAt: now,
        );
    return upsertEntry(entry);
  }

  @override
  Future<Result<void>> setCoverPhoto({
    required String genbaId,
    required String photoId,
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    var changed = false;
    try {
      // 旧表紙解除・新表紙設定・Outbox登録をすべて同一 transaction 内で行う。
      // 途中で失敗すれば全て巻き戻り、古い表紙が維持される（R6独立レビュー#1）。
      await _db.transaction(() async {
        // 現在owner・同一genbaの写真のみを対象にする（別ownerに触れない）。
        final rows = await (_db.select(_db.memoryPhotos)
              ..where(
                (t) => t.genbaId.equals(genbaId) & t.ownerId.equals(owner),
              ))
            .get();
        final target = rows.firstWhereOrNull((r) => r.id == photoId);
        if (target == null) {
          throw const _CoverNotFound();
        }
        final now = _now;
        // 旧表紙を先に外す（部分ユニーク索引違反を避けるため set より前に clear）。
        for (final r in rows) {
          if (r.id != photoId && r.isCover) {
            final off =
                photoFromRow(r).copyWith(isCover: false, updatedAt: now);
            await _db
                .into(_db.memoryPhotos)
                .insertOnConflictUpdate(photoToCompanion(off));
            await _enqueuePhotoUpsert(off, owner, now);
            changed = true;
          }
        }
        if (!target.isCover) {
          final on =
              photoFromRow(target).copyWith(isCover: true, updatedAt: now);
          await _db
              .into(_db.memoryPhotos)
              .insertOnConflictUpdate(photoToCompanion(on));
          await _enqueuePhotoUpsert(on, owner, now);
          changed = true;
        }
      });
    } on _CoverNotFound {
      return const Err(NotFoundFailure(message: '対象の写真が見つかりません'));
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    if (changed) _syncEngine.poke();
    return const Ok(null);
  }

  /// 写真の upsert 操作を Outbox へ積む（[setCoverPhoto] の transaction 内から
  /// 呼ぶ）。写真バイナリ（local_path）は同期対象外なので payload から除く。
  Future<void> _enqueuePhotoUpsert(
    MemoryPhoto photo,
    String owner,
    DateTime now,
  ) async {
    final payload = photo.toJson()..remove('local_path');
    await _outbox.enqueue(
      OutboxOperation(
        mutationId: _uuid.v4(),
        ownerId: owner,
        entityTable: SyncEntity.memoryPhotos,
        entityId: photo.id,
        opType: OutboxOpType.upsert,
        payload: payload,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<Result<void>> addPhoto(MemoryPhoto photo) => updatePhoto(photo);

  @override
  Future<Result<void>> updatePhoto(MemoryPhoto photo) async {
    final stamped = photo.copyWith(updatedAt: _now);
    // 関連項目（グッズ/行った場所）に紐づく写真は、同一 owner+genba の項目が
    // 実在することを検証する（§8.4。孤立した subject_id を作らない）。
    if (stamped.subjectId != null && stamped.subjectType != null) {
      final owner = _ownerId();
      if (owner == null) {
        return const Err(AuthFailure(message: 'ログインが必要です'));
      }
      final exists = await _subjectExists(
        owner: owner,
        genbaId: stamped.genbaId,
        subjectType: stamped.subjectType!,
        subjectId: stamped.subjectId!,
      );
      if (!exists) {
        return const Err(ValidationFailure('関連する項目が見つかりません'));
      }
    }
    // 写真バイナリはOutboxに載せない（メタデータのみ同期。画像本体の
    // アップロードは MemoryPhotoUploader の境界で扱う）。
    final payload = stamped.toJson()..remove('local_path');
    return _localWrite(
      (owner) => _db
          .into(_db.memoryPhotos)
          .insertOnConflictUpdate(photoToCompanion(stamped)),
      entityTable: SyncEntity.memoryPhotos,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deletePhoto(String id) => _localWrite(
        (owner) => (_db.delete(_db.memoryPhotos)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.memoryPhotos,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  /// 関連項目（グッズ/行った場所）が同一 owner+genba に実在するか（§8.4）。
  /// 写真の subject_id が孤立しないよう upsert 前に検証する。
  Future<bool> _subjectExists({
    required String owner,
    required String genbaId,
    required MemorySubjectType subjectType,
    required String subjectId,
  }) async {
    switch (subjectType) {
      case MemorySubjectType.goods:
        final row = await (_db.select(_db.goodsItems)
              ..where(
                (t) =>
                    t.id.equals(subjectId) &
                    t.genbaId.equals(genbaId) &
                    t.ownerId.equals(owner),
              ))
            .getSingleOrNull();
        return row != null;
      case MemorySubjectType.visitedPlace:
        final row = await (_db.select(_db.visitedPlaces)
              ..where(
                (t) =>
                    t.id.equals(subjectId) &
                    t.genbaId.equals(genbaId) &
                    t.ownerId.equals(owner),
              ))
            .getSingleOrNull();
        return row != null;
    }
  }

  @override
  Future<Result<void>> upsertSetlistItem(SetlistItem item) {
    final stamped = item.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.setlistItems)
          .insertOnConflictUpdate(setlistToCompanion(stamped)),
      entityTable: SyncEntity.setlistItems,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteSetlistItem(String id) => _localWrite(
        (owner) => (_db.delete(_db.setlistItems)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.setlistItems,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertGoodsItem(GoodsItem item) {
    final stamped = item.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.goodsItems)
          .insertOnConflictUpdate(goodsToCompanion(stamped)),
      entityTable: SyncEntity.goodsItems,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteGoodsItem(String id) => _localWrite(
        (owner) => (_db.delete(_db.goodsItems)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.goodsItems,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertVisitedPlace(VisitedPlace place) {
    final stamped = place.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.visitedPlaces)
          .insertOnConflictUpdate(placeToCompanion(stamped)),
      entityTable: SyncEntity.visitedPlaces,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteVisitedPlace(String id) => _localWrite(
        (owner) => (_db.delete(_db.visitedPlaces)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.visitedPlaces,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    final client = _remote();
    if (client == null) return const Ok(null); // デモ・未ログインは何もしない
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    return guardResult(
      () async {
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.memoryEntries,
          rows: await client
              .from(SyncEntity.memoryEntries)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) => entryToCompanion(MemoryEntry.fromJson(json)),
          table: _db.memoryEntries,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.memoryPhotos,
          rows: await client
              .from(SyncEntity.memoryPhotos)
              .select()
              .withRemoteTimeout(),
          // 端末内の写真参照(local_path)はサーバーに無い。pull で null 上書き
          // しない（R6独立レビュー#3。hero/oshi 画像と同じ方針, H-04）。
          toCompanion: (json) => photoToCompanion(
            MemoryPhoto.fromJson(json),
            preserveLocalImage: true,
          ),
          table: _db.memoryPhotos,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.setlistItems,
          rows: await client
              .from(SyncEntity.setlistItems)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) => setlistToCompanion(SetlistItem.fromJson(json)),
          table: _db.setlistItems,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.goodsItems,
          rows: await client
              .from(SyncEntity.goodsItems)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) => goodsToCompanion(GoodsItem.fromJson(json)),
          table: _db.goodsItems,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.visitedPlaces,
          rows: await client
              .from(SyncEntity.visitedPlaces)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) => placeToCompanion(VisitedPlace.fromJson(json)),
          table: _db.visitedPlaces,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
      },
      onError: (e, _) => NetworkFailure(cause: e),
    );
  }

  // ---- 競合解決「サーバーを採用」（R8-A 再レビュー）------------------------

  @override
  Future<Result<void>> adoptServerEntity(
    String entityTable,
    String entityId,
  ) async {
    final client = _remote();
    if (client == null) return const Ok(null);
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    return guardResult(
      () async {
        switch (entityTable) {
          case SyncEntity.memoryEntries:
            await _adoptOne(
              client,
              owner,
              SyncEntity.memoryEntries,
              entityId,
              (json) => entryToCompanion(MemoryEntry.fromJson(json)),
              _db.memoryEntries,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.memoryPhotos:
            await _adoptOne(
              client,
              owner,
              SyncEntity.memoryPhotos,
              entityId,
              (json) => photoToCompanion(
                MemoryPhoto.fromJson(json),
                preserveLocalImage: true,
              ),
              _db.memoryPhotos,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.setlistItems:
            await _adoptOne(
              client,
              owner,
              SyncEntity.setlistItems,
              entityId,
              (json) => setlistToCompanion(SetlistItem.fromJson(json)),
              _db.setlistItems,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.goodsItems:
            await _adoptOne(
              client,
              owner,
              SyncEntity.goodsItems,
              entityId,
              (json) => goodsToCompanion(GoodsItem.fromJson(json)),
              _db.goodsItems,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.visitedPlaces:
            await _adoptOne(
              client,
              owner,
              SyncEntity.visitedPlaces,
              entityId,
              (json) => placeToCompanion(VisitedPlace.fromJson(json)),
              _db.visitedPlaces,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          default:
            throw ArgumentError('memory repo は $entityTable を所有しません');
        }
      },
      onError: (e, _) => e is ArgumentError
          ? UnknownFailure(cause: e)
          : NetworkFailure(cause: e),
    );
  }

  Future<void> _adoptOne<T extends Table, R>(
    SupabaseClient client,
    String owner,
    String tableName,
    String entityId,
    Insertable<R> Function(Map<String, dynamic> json) toCompanion,
    TableInfo<T, R> table,
    TextColumn Function(T table) idColumn,
    TextColumn Function(T table) ownerColumn,
    String Function(R row) idOf,
  ) async {
    final rows = await client.from(tableName).select().withRemoteTimeout();
    await applyPulledRowsInto(
      db: _db,
      outbox: _outbox,
      owner: owner,
      tableName: tableName,
      rows: rows,
      toCompanion: toCompanion,
      table: table,
      idColumn: idColumn,
      ownerColumn: ownerColumn,
      idOf: idOf,
      forceEntityIds: {entityId},
    );
  }
}

/// [MemoryRepositoryImpl.setCoverPhoto] の transaction 内で「対象写真なし」を
/// 通知する番兵例外（transaction をロールバックさせ、外側で NotFoundFailure へ変換）。
class _CoverNotFound implements Exception {
  const _CoverNotFound();
}
