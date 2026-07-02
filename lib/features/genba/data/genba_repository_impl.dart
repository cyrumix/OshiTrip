import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../domain/genba.dart';
import '../domain/genba_repository.dart';
import 'genba_mappers.dart';

/// 現場リポジトリ実装（ローカル先行 + Outbox + リモート同期）。
class GenbaRepositoryImpl implements GenbaRepository {
  GenbaRepositoryImpl({
    required AppDatabase db,
    required OutboxStore outbox,
    required SyncEngine syncEngine,
    required Clock clock,
    required String? Function() ownerIdResolver,
    required SupabaseClient? Function() remoteResolver,
  })  : _db = db,
        _outbox = outbox,
        _syncEngine = syncEngine,
        _clock = clock,
        _ownerId = ownerIdResolver,
        _remote = remoteResolver;

  final AppDatabase _db;
  final OutboxStore _outbox;
  final SyncEngine _syncEngine;
  final Clock _clock;
  final String? Function() _ownerId;
  final SupabaseClient? Function() _remote;

  static const _uuid = Uuid();

  @override
  Stream<List<GenbaAggregate>> watchAll() async* {
    yield await _queryAll();
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.genbas,
        _db.tickets,
        _db.transports,
        _db.lodgings,
        _db.todos,
        _db.genbaMemos,
      ]),
    );
    await for (final _ in updates) {
      yield await _queryAll();
    }
  }

  @override
  Stream<GenbaAggregate?> watchById(String id) =>
      watchAll().map((list) => list.where((a) => a.genba.id == id).firstOrNull);

  Future<List<GenbaAggregate>> _queryAll() async {
    final genbas = await (_db.select(_db.genbas)
          ..orderBy([(t) => OrderingTerm.asc(t.eventDate)]))
        .get();
    final tickets = await _db.select(_db.tickets).get();
    final transports = await _db.select(_db.transports).get();
    final lodgings = await _db.select(_db.lodgings).get();
    final todos = await (_db.select(_db.todos)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    final memos = await _db.select(_db.genbaMemos).get();

    return genbas.map((g) {
      return GenbaAggregate(
        genba: genbaFromRow(g),
        tickets:
            tickets.where((r) => r.genbaId == g.id).map(ticketFromRow).toList(),
        transports: transports
            .where((r) => r.genbaId == g.id)
            .map(transportFromRow)
            .toList(),
        lodgings: lodgings
            .where((r) => r.genbaId == g.id)
            .map(lodgingFromRow)
            .toList(),
        todos: todos.where((r) => r.genbaId == g.id).map(todoFromRow).toList(),
        memos: memos.where((r) => r.genbaId == g.id).map(memoFromRow).toList(),
      );
    }).toList();
  }

  // ---- 書き込み（ローカル反映 → Outbox → poke） -------------------------

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
          final now = _clock.now().toUtc();
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

  DateTime get _now => _clock.now().toUtc();

  @override
  Future<Result<void>> upsertGenba(Genba genba) {
    final stamped = genba.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db.into(_db.genbas).insertOnConflictUpdate(
            genbaToCompanion(stamped),
          ),
      entityTable: SyncEntity.genbas,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteGenba(String id) {
    return _localWrite(
      () async {
        await (_db.delete(_db.tickets)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.transports)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.lodgings)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.todos)..where((t) => t.genbaId.equals(id))).go();
        await (_db.delete(_db.genbaMemos)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.memoryEntries)
              ..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.memoryPhotos)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.setlistItems)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.goodsItems)..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.visitedPlaces)
              ..where((t) => t.genbaId.equals(id)))
            .go();
        await (_db.delete(_db.genbas)..where((t) => t.id.equals(id))).go();
      },
      entityTable: SyncEntity.genbas,
      entityId: id,
      opType: OutboxOpType.delete,
    );
  }

  @override
  Future<Result<void>> upsertTicket(Ticket ticket) {
    final stamped = ticket.copyWith(updatedAt: _now);
    // 端末内の画像参照は同期しない（サーバー列にも存在しない）。
    final payload = stamped.toJson()..remove('image_local_path');
    return _localWrite(
      () => _db.into(_db.tickets).insertOnConflictUpdate(
            ticketToCompanion(stamped),
          ),
      entityTable: SyncEntity.tickets,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
    );
  }

  @override
  Future<Result<void>> deleteTicket(String id) => _localWrite(
        () => (_db.delete(_db.tickets)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.tickets,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertTransport(Transport transport) {
    final stamped = transport.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db.into(_db.transports).insertOnConflictUpdate(
            transportToCompanion(stamped),
          ),
      entityTable: SyncEntity.transports,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteTransport(String id) => _localWrite(
        () => (_db.delete(_db.transports)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.transports,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertLodging(Lodging lodging) {
    final stamped = lodging.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db.into(_db.lodgings).insertOnConflictUpdate(
            lodgingToCompanion(stamped),
          ),
      entityTable: SyncEntity.lodgings,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteLodging(String id) => _localWrite(
        () => (_db.delete(_db.lodgings)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.lodgings,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertTodo(GenbaTodo todo) {
    final stamped = todo.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db.into(_db.todos).insertOnConflictUpdate(
            todoToCompanion(stamped),
          ),
      entityTable: SyncEntity.todos,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteTodo(String id) => _localWrite(
        () => (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.todos,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertMemo(GenbaMemo memo) {
    final stamped = memo.copyWith(updatedAt: _now);
    return _localWrite(
      () async {
        // 区分ごとに1件（genba_id + category でユニーク）。
        await (_db.delete(_db.genbaMemos)
              ..where(
                (t) =>
                    t.genbaId.equals(stamped.genbaId) &
                    t.category.equals(stamped.category.name) &
                    t.id.isNotValue(stamped.id),
              ))
            .go();
        await _db
            .into(_db.genbaMemos)
            .insertOnConflictUpdate(memoToCompanion(stamped));
      },
      entityTable: SyncEntity.genbaMemos,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteMemo(String id) => _localWrite(
        () => (_db.delete(_db.genbaMemos)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.genbaMemos,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- リモート取り込み（キャッシュ先行 → バックグラウンド更新） --------

  @override
  Future<Result<void>> refreshFromRemote() async {
    final client = _remote();
    if (client == null) return const Ok(null); // デモモード: ローカルのみ

    return guardResult(
      () async {
        await _pullTable(
          client,
          SyncEntity.genbas,
          (json) => genbaToCompanion(Genba.fromJson(json)),
          _db.genbas,
          (t) => t.id,
          (r) => r.id,
        );
        await _pullTable(
          client,
          SyncEntity.tickets,
          (json) => ticketToCompanion(Ticket.fromJson(json)),
          _db.tickets,
          (t) => t.id,
          (r) => r.id,
        );
        await _pullTable(
          client,
          SyncEntity.transports,
          (json) => transportToCompanion(Transport.fromJson(json)),
          _db.transports,
          (t) => t.id,
          (r) => r.id,
        );
        await _pullTable(
          client,
          SyncEntity.lodgings,
          (json) => lodgingToCompanion(Lodging.fromJson(json)),
          _db.lodgings,
          (t) => t.id,
          (r) => r.id,
        );
        await _pullTable(
          client,
          SyncEntity.todos,
          (json) => todoToCompanion(GenbaTodo.fromJson(json)),
          _db.todos,
          (t) => t.id,
          (r) => r.id,
        );
        await _pullTable(
          client,
          SyncEntity.genbaMemos,
          (json) => memoToCompanion(GenbaMemo.fromJson(json)),
          _db.genbaMemos,
          (t) => t.id,
          (r) => r.id,
        );
      },
      onError: (e, _) => NetworkFailure(cause: e),
    );
  }

  Future<void> _pullTable<T extends Table, R>(
    SupabaseClient client,
    String tableName,
    Insertable<R> Function(Map<String, dynamic> json) toCompanion,
    TableInfo<T, R> table,
    TextColumn Function(T table) idColumn,
    String Function(R row) idOf,
  ) async {
    final rows = await client.from(tableName).select();
    final remoteIds = <String>{};
    for (final row in rows) {
      final id = row['id'] as String;
      remoteIds.add(id);
      // ローカルに未同期変更が残っている行は上書きしない。
      if (await _outbox.hasPendingFor(tableName, id)) continue;
      await _db.into(table).insertOnConflictUpdate(toCompanion(row));
    }
    // リモートに存在しないローカル行（未同期変更なし）は削除された行とみなす。
    final localRows = await _db.select(table).get();
    for (final localRow in localRows) {
      final localId = idOf(localRow);
      if (remoteIds.contains(localId)) continue;
      if (await _outbox.hasPendingFor(tableName, localId)) continue;
      await (_db.delete(table)..where((t) => idColumn(t).equals(localId))).go();
    }
  }
}
