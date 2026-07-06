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
import '../domain/template_repository.dart';
import '../domain/todo_template.dart';
import 'template_mappers.dart';

/// テンプレートリポジトリ実装（owner スコープのローカルCRUD + Outbox + 同期）。
///
/// マイ推し（[OshiRepositoryImpl]）と同型で、テンプレート→項目の親子構造を
/// グループ→メンバーと同じく owner 単位・親所有権検証つきで扱う。
class TemplateRepositoryImpl implements TemplateRepository {
  TemplateRepositoryImpl({
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
  Stream<List<TodoTemplateWithItems>> watchAll() async* {
    final owner = _ownerId();
    if (owner == null) {
      yield const [];
      return;
    }
    yield await _queryAll(owner);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.todoTemplates, _db.todoTemplateItems]),
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

  Future<List<TodoTemplateWithItems>> _queryAll(String owner) async {
    final templates = await (_db.select(_db.todoTemplates)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final items = await (_db.select(_db.todoTemplateItems)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return templates.map((tpl) {
      return TodoTemplateWithItems(
        template: templateFromRow(tpl),
        items: items
            .where((i) => i.templateId == tpl.id)
            .map(templateItemFromRow)
            .toList(),
      );
    }).toList();
  }

  /// oshi/genba と同じ owner ガードつき単一書き込みヘルパー（C-01）。
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
        ValidationFailure('親テンプレートが存在しないか、アクセス権がありません'),
      );
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    return const Ok(null);
  }

  @override
  Future<Result<void>> upsertTemplate(TodoTemplate template) {
    final stamped = template.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.todoTemplates)
          .insertOnConflictUpdate(templateToCompanion(stamped)),
      entityTable: SyncEntity.todoTemplates,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteTemplate(String id) => _localWrite(
        (owner) async {
          // テンプレート削除で項目も端末から削除する
          // （Supabase の ON DELETE CASCADE と同じ結果）。
          await (_db.delete(_db.todoTemplateItems)
                ..where(
                  (t) => t.templateId.equals(id) & t.ownerId.equals(owner),
                ))
              .go();
          await (_db.delete(_db.todoTemplates)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
              .go();
        },
        entityTable: SyncEntity.todoTemplates,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertItem(TodoTemplateItem item) {
    final stamped = item.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.todoTemplateItems)
          .insertOnConflictUpdate(templateItemToCompanion(stamped)),
      entityTable: SyncEntity.todoTemplateItems,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      // 親テンプレートが現在ownerに属することを検証する（C-01）。
      parentTable: SyncEntity.todoTemplates,
      parentId: stamped.templateId,
    );
  }

  @override
  Future<Result<void>> deleteItem(String id) => _localWrite(
        (owner) => (_db.delete(_db.todoTemplateItems)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.todoTemplateItems,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> saveTemplateWithItems({
    required TodoTemplate template,
    required List<TodoTemplateItem> items,
    bool replaceItems = true,
  }) async {
    // テンプレート本体を先に保存する（項目の親所有権検証が通るように）。
    final templateResult = await upsertTemplate(template);
    if (!templateResult.isOk) return templateResult;

    if (replaceItems) {
      final owner = _ownerId();
      if (owner != null) {
        final keepIds = items.map((i) => i.id).toSet();
        final existing = await (_db.select(_db.todoTemplateItems)
              ..where(
                (t) =>
                    t.templateId.equals(template.id) & t.ownerId.equals(owner),
              ))
            .get();
        for (final row in existing) {
          if (!keepIds.contains(row.id)) {
            final del = await deleteItem(row.id);
            if (!del.isOk) return del;
          }
        }
      }
    }

    for (final item in items) {
      final res = await upsertItem(item);
      if (!res.isOk) return res;
    }
    return const Ok(null);
  }

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
          tableName: SyncEntity.todoTemplates,
          rows: await client
              .from(SyncEntity.todoTemplates)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) =>
              templateToCompanion(TodoTemplate.fromJson(json)),
          table: _db.todoTemplates,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.todoTemplateItems,
          rows: await client
              .from(SyncEntity.todoTemplateItems)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) =>
              templateItemToCompanion(TodoTemplateItem.fromJson(json)),
          table: _db.todoTemplateItems,
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
        switch (entityTable) {
          case SyncEntity.todoTemplates:
            await _adoptOne(
              client,
              owner,
              SyncEntity.todoTemplates,
              entityId,
              (json) => templateToCompanion(TodoTemplate.fromJson(json)),
              _db.todoTemplates,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.todoTemplateItems:
            await _adoptOne(
              client,
              owner,
              SyncEntity.todoTemplateItems,
              entityId,
              (json) =>
                  templateItemToCompanion(TodoTemplateItem.fromJson(json)),
              _db.todoTemplateItems,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          default:
            throw ArgumentError('template repo は $entityTable を所有しません');
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
