import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/owner_guard.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/images/image_store.dart';
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
    ImageStore? Function()? imageStoreResolver,
  })  : _db = db,
        _outbox = outbox,
        _syncEngine = syncEngine,
        _clock = clock,
        _ownerId = ownerIdResolver,
        _remote = remoteResolver ?? (() => null),
        _imageStore = imageStoreResolver ?? (() => null);

  final AppDatabase _db;
  final OutboxStore _outbox;
  final SyncEngine _syncEngine;
  final Clock _clock;
  final String? Function() _ownerId;
  final SupabaseClient? Function() _remote;
  final ImageStore? Function() _imageStore;

  /// テスト用の失敗注入（Issue1 のロールバック検証）。指定ステージ到達時に
  /// 例外を投げ、原子的削除が全て巻き戻ることを確認する。ステージ名:
  /// `photo:N`（N枚目の写真削除後） / `subject`（項目削除後） /
  /// `outbox`（Outbox 登録時）。本番経路では常に null。
  String? deleteFailStage;

  /// 画像削除キューの flush 実行中フラグ（多重実行・二重削除を防ぐ）。
  bool _flushingImages = false;

  /// 自動再試行の上限。これ以上失敗した行は自動処理せず残す（短時間の無限
  /// 再試行を避ける）。
  static const _maxImageDeletionAttempts = 8;

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
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    // 分類と関連項目の不変条件を強制する（§8.4）。形状（純粋関数）＋実在・
    // owner/genba 一致・対象 category（spot/food）照合。Supabase 側でも同一条件を
    // トリガで強制する（apply_mutation/直接INSERT/UPDATE を含む）。
    final invalid = await _validatePhoto(owner, stamped);
    if (invalid != null) return Err(invalid);
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

  @override
  Future<Result<void>> deleteSubjectWithPhotos({
    required MemorySubjectType subjectType,
    required String subjectId,
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final now = _now;
    try {
      await _db.transaction(() async {
        // 1) 項目の存在・所有を確認（別owner/存在しない項目は拒否）。
        if (!await _subjectRowExists(owner, subjectType, subjectId)) {
          throw const _SubjectMissing();
        }
        // 2) 紐づく写真（owner スコープ）を取得。ファイル参照を控える。
        final photos = await (_db.select(_db.memoryPhotos)
              ..where(
                (t) => t.subjectId.equals(subjectId) & t.ownerId.equals(owner),
              ))
            .get();
        // 3) 写真メタデータを1件ずつ削除し、各削除を Outbox へ積む。
        var deleted = 0;
        for (final ph in photos) {
          await (_db.delete(_db.memoryPhotos)
                ..where((t) => t.id.equals(ph.id) & t.ownerId.equals(owner)))
              .go();
          deleted++;
          _maybeFail('photo:$deleted');
          await _enqueueInTxDelete(
            owner: owner,
            table: SyncEntity.memoryPhotos,
            id: ph.id,
            now: now,
          );
        }
        // 4) 項目行を削除。
        await _deleteSubjectRow(owner, subjectType, subjectId);
        _maybeFail('subject');
        // 5) 項目削除を Outbox へ積む。
        _maybeFail('outbox');
        await _enqueueInTxDelete(
          owner: owner,
          table: subjectType == MemorySubjectType.goods
              ? SyncEntity.goodsItems
              : SyncEntity.visitedPlaces,
          id: subjectId,
          now: now,
        );
        // 6) 画像ファイル削除キューへ積む（DB と同一トランザクション）。
        for (final ph in photos) {
          final ref = ph.localPath;
          if (ref != null && ref.isNotEmpty) {
            await _db.into(_db.pendingImageDeletions).insert(
                  PendingImageDeletionsCompanion.insert(
                    id: _uuid.v4(),
                    ownerId: owner,
                    ref: ref,
                    createdAt: now.toIso8601String(),
                    updatedAt: now.toIso8601String(),
                  ),
                );
          }
        }
      });
    } on _SubjectMissing {
      return const Err(ValidationFailure('対象の項目が見つかりません'));
    } catch (e) {
      // 途中失敗は DB を全てロールバック済み。成功扱いにしない。
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    // DB は確定済み。ファイル削除は分離して実行し、失敗は再試行キューに残す。
    await flushPendingImageDeletions(owner);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteSubjectDetachingPhotos({
    required MemorySubjectType subjectType,
    required String subjectId,
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final now = _now;
    try {
      await _db.transaction(() async {
        if (!await _subjectRowExists(owner, subjectType, subjectId)) {
          throw const _SubjectMissing();
        }
        // 写真もファイルも消さない。関連（subject）だけ解除し、album_category は
        // 元分類を維持する（アルバムから引き続き確認できる, §8.4）。
        final photos = await (_db.select(_db.memoryPhotos)
              ..where(
                (t) => t.subjectId.equals(subjectId) & t.ownerId.equals(owner),
              ))
            .get();
        for (final ph in photos) {
          final detached = photoFromRow(ph).copyWith(
            subjectId: null,
            subjectType: null,
            updatedAt: now,
          );
          await _db.into(_db.memoryPhotos).insertOnConflictUpdate(
                photoToCompanion(detached, preserveLocalImage: true),
              );
          final payload = detached.toJson()..remove('local_path');
          await _outbox.enqueue(
            OutboxOperation(
              mutationId: _uuid.v4(),
              ownerId: owner,
              entityTable: SyncEntity.memoryPhotos,
              entityId: detached.id,
              opType: OutboxOpType.upsert,
              payload: payload,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
        await _deleteSubjectRow(owner, subjectType, subjectId);
        await _enqueueInTxDelete(
          owner: owner,
          table: subjectType == MemorySubjectType.goods
              ? SyncEntity.goodsItems
              : SyncEntity.visitedPlaces,
          id: subjectId,
          now: now,
        );
      });
    } on _SubjectMissing {
      return const Err(ValidationFailure('対象の項目が見つかりません'));
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    return const Ok(null);
  }

  /// 画像削除キューを処理する。成功した行は除去し、失敗した行は試行回数と理由を
  /// 記録して残す（再試行対象, Issue1）。owner スコープで別ユーザーのファイルには
  /// 触れない。1件の失敗で他の処理を止めない。多重実行は [_flushingImages] で防ぐ
  /// （二重削除を避ける）。[deleteRefStrict] は対象が無ければ成功扱い（冪等）。
  /// 試行回数が [_maxImageDeletionAttempts] 以上の行は自動再試行しない
  /// （短時間の無限再試行を避ける。行自体は残す）。[ImageStore] 未設定時は何も
  /// しない（後続の起動などで再試行される）。
  @override
  Future<void> flushPendingImageDeletions(String owner) async {
    final store = _imageStore();
    if (store == null) return;
    if (_flushingImages) return; // 多重実行防止
    _flushingImages = true;
    try {
      final rows = await (_db.select(_db.pendingImageDeletions)
            ..where(
              (t) =>
                  t.ownerId.equals(owner) &
                  t.attempts.isSmallerThanValue(_maxImageDeletionAttempts),
            ))
          .get();
      for (final r in rows) {
        try {
          await store.deleteRefStrict(owner, r.ref);
          await (_db.delete(_db.pendingImageDeletions)
                ..where((t) => t.id.equals(r.id)))
              .go();
        } catch (e) {
          // 1件の失敗で他を止めない。試行回数と理由を記録して残す。
          await (_db.update(_db.pendingImageDeletions)
                ..where((t) => t.id.equals(r.id)))
              .write(
            PendingImageDeletionsCompanion(
              attempts: Value(r.attempts + 1),
              lastError: Value(e.toString()),
              updatedAt: Value(_now.toIso8601String()),
            ),
          );
        }
      }
    } finally {
      _flushingImages = false;
    }
  }

  void _maybeFail(String stage) {
    if (deleteFailStage == stage) {
      throw StateError('test failpoint: $stage');
    }
  }

  Future<bool> _subjectRowExists(
    String owner,
    MemorySubjectType type,
    String id,
  ) async {
    switch (type) {
      case MemorySubjectType.goods:
        final r = await (_db.select(_db.goodsItems)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .getSingleOrNull();
        return r != null;
      case MemorySubjectType.visitedPlace:
        final r = await (_db.select(_db.visitedPlaces)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .getSingleOrNull();
        return r != null;
    }
  }

  Future<void> _deleteSubjectRow(
    String owner,
    MemorySubjectType type,
    String id,
  ) async {
    switch (type) {
      case MemorySubjectType.goods:
        await (_db.delete(_db.goodsItems)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go();
      case MemorySubjectType.visitedPlace:
        await (_db.delete(_db.visitedPlaces)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go();
    }
  }

  Future<void> _enqueueInTxDelete({
    required String owner,
    required String table,
    required String id,
    required DateTime now,
  }) {
    return _outbox.enqueue(
      OutboxOperation(
        mutationId: _uuid.v4(),
        ownerId: owner,
        entityTable: table,
        entityId: id,
        opType: OutboxOpType.delete,
        payload: const {},
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// 写真の分類・関連項目の不変条件（§8.4）を検証する。問題があれば型付き
  /// [Failure]、無ければ null。形状（純粋関数）→実在・owner/genba 一致→
  /// 対象 category（visited_place=spot / food=food）照合の順で確認する。
  Future<Failure?> _validatePhoto(String owner, MemoryPhoto p) async {
    final shape = memoryPhotoShapeError(p);
    if (shape != null) return ValidationFailure(shape);
    // event または関連解除済み（両方 null）は関連先の照合を要しない。
    if (!memoryPhotoLinksSubject(p)) return null;
    switch (p.subjectType!) {
      case MemorySubjectType.goods:
        final row = await (_db.select(_db.goodsItems)
              ..where(
                (t) =>
                    t.id.equals(p.subjectId!) &
                    t.genbaId.equals(p.genbaId) &
                    t.ownerId.equals(owner),
              ))
            .getSingleOrNull();
        if (row == null) {
          return const ValidationFailure('関連するグッズが見つかりません');
        }
        return null;
      case MemorySubjectType.visitedPlace:
        final row = await (_db.select(_db.visitedPlaces)
              ..where(
                (t) =>
                    t.id.equals(p.subjectId!) &
                    t.genbaId.equals(p.genbaId) &
                    t.ownerId.equals(owner),
              ))
            .getSingleOrNull();
        if (row == null) {
          return const ValidationFailure('関連する場所が見つかりません');
        }
        // 食べたものは food、行った場所は spot の visited_place を指す。
        final expected =
            p.albumCategory == MemoryAlbumCategory.food ? 'food' : 'spot';
        if (row.category != expected) {
          return const ValidationFailure('関連項目の種別が一致しません');
        }
        return null;
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

/// 関連項目の原子的削除で「対象の項目が存在しない/別owner」を通知する番兵例外
/// （transaction をロールバックさせ、外側で [ValidationFailure] へ変換）。
class _SubjectMissing implements Exception {
  const _SubjectMissing();
}
