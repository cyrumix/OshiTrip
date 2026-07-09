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
import '../domain/memo_template.dart';
import '../domain/memo_template_repository.dart';
import 'genba_mappers.dart';

/// メモテンプレートリポジトリ実装（owner スコープの単一行 CRUD + Outbox + 同期）。
/// Todo テンプレートと同型だが、雛形は content(JSON) に持つため子テーブルを持たない。
class MemoTemplateRepositoryImpl implements MemoTemplateRepository {
  MemoTemplateRepositoryImpl({
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
  Stream<List<MemoTemplate>> watchAll() async* {
    final owner = _ownerId();
    if (owner == null) {
      yield const [];
      return;
    }
    yield await _queryAll(owner);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.memoTemplates]),
    );
    await for (final _ in updates) {
      final current = _ownerId();
      if (current == null) {
        yield const [];
        continue;
      }
      yield await _queryAll(current);
    }
  }

  Future<List<MemoTemplate>> _queryAll(String owner) async {
    final rows = await (_db.select(_db.memoTemplates)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(memoTemplateFromRow).toList();
  }

  /// oshi/genba と同じ owner ガードつき単一書き込みヘルパー（C-01）。
  Future<Result<void>> _localWrite(
    Future<void> Function(String owner) write, {
    required String entityId,
    required OutboxOpType opType,
    Map<String, dynamic> payload = const {},
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    if (payload.containsKey('owner_id') && payload['owner_id'] != owner) {
      return const Err(AuthFailure(message: '所有者が一致しません'));
    }
    if (opType == OutboxOpType.upsert &&
        await _db.existsForOtherOwner(
          SyncEntity.memoTemplates,
          entityId,
          owner,
        )) {
      return const Err(AuthFailure(message: '既存の別ユーザーのデータは操作できません'));
    }
    try {
      await _db.transaction(() async {
        await write(owner);
        final now = _now;
        await _outbox.enqueue(
          OutboxOperation(
            mutationId: _uuid.v4(),
            ownerId: owner,
            entityTable: SyncEntity.memoTemplates,
            entityId: entityId,
            opType: opType,
            payload: payload,
            createdAt: now,
            updatedAt: now,
          ),
        );
      });
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    return const Ok(null);
  }

  @override
  Future<Result<void>> upsertTemplate(MemoTemplate template) {
    final stamped = template.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.memoTemplates)
          .insertOnConflictUpdate(memoTemplateToCompanion(stamped)),
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteTemplate(String id) => _localWrite(
        (owner) => (_db.delete(_db.memoTemplates)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    final client = _remote();
    if (client == null) return const Ok(null);
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
          tableName: SyncEntity.memoTemplates,
          rows: await client
              .from(SyncEntity.memoTemplates)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) =>
              memoTemplateToCompanion(MemoTemplate.fromJson(json)),
          table: _db.memoTemplates,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
      },
      onError: (e, _) => NetworkFailure(cause: e),
    );
  }

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
        if (entityTable != SyncEntity.memoTemplates) {
          throw ArgumentError('memo template repo は $entityTable を所有しません');
        }
        final rows = await client
            .from(SyncEntity.memoTemplates)
            .select()
            .withRemoteTimeout();
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.memoTemplates,
          rows: rows,
          toCompanion: (json) =>
              memoTemplateToCompanion(MemoTemplate.fromJson(json)),
          table: _db.memoTemplates,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          forceEntityIds: {entityId},
        );
      },
      onError: (e, _) => e is ArgumentError
          ? UnknownFailure(cause: e)
          : NetworkFailure(cause: e),
    );
  }
}
