import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/owner_guard.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/remote_pull.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../domain/genba.dart';
import '../domain/genba_repository.dart';
import 'genba_mappers.dart';

/// 現場リポジトリ実装（ローカル先行 + Outbox + リモート同期）。
///
/// [ownerIdResolver] が返す owner（未認証時は null）ですべてのローカル
/// 読み書きを絞る（C-01）。このインスタンスは呼び出し元（Provider層）が
/// 認証スコープの変化ごとに作り直す前提で、内部に owner の状態は持たない。
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
    final owner = _ownerId();
    if (owner == null) {
      // 未認証: クエリを一切発行せず空を返す（C-01）。
      yield const [];
      return;
    }
    yield await _queryAll(owner);
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
      // 購読中に owner が変わった（ログアウト等）場合は前ownerの値を返さない。
      // 実際には Provider 層が scope 変化ごとに本インスタンスごと作り直すため
      // このパスへは到達しない想定だが、防御的に再チェックする。
      final current = _ownerId();
      if (current == null) {
        yield const [];
        continue;
      }
      yield await _queryAll(current);
    }
  }

  @override
  Stream<GenbaAggregate?> watchById(String id) =>
      watchAll().map((list) => list.where((a) => a.genba.id == id).firstOrNull);

  Future<List<GenbaAggregate>> _queryAll(String owner) async {
    final genbas = await (_db.select(_db.genbas)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([(t) => OrderingTerm.asc(t.eventDate)]))
        .get();
    final tickets = await (_db.select(_db.tickets)
          ..where((t) => t.ownerId.equals(owner)))
        .get();
    final transports = await (_db.select(_db.transports)
          ..where((t) => t.ownerId.equals(owner)))
        .get();
    final lodgings = await (_db.select(_db.lodgings)
          ..where((t) => t.ownerId.equals(owner)))
        .get();
    final todos = await (_db.select(_db.todos)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    final memos = await (_db.select(_db.genbaMemos)
          ..where((t) => t.ownerId.equals(owner)))
        .get();

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

  /// [write] には解決済みの owner を渡す。書き込み対象の payload に
  /// `owner_id` が含まれる場合は現在ownerと一致することを確認し、
  /// 別ownerとして偽装した書き込みを拒否する（C-01）。
  ///
  /// upsert では、`id` が主キーのため `insertOnConflictUpdate` は owner を
  /// 見ずに既存行を更新してしまう。別ownerが同一ID（推測ID含む）で upsert
  /// できないよう、書き込み前に「同一IDで別ownerの行が既に存在しないか」を
  /// 確認して拒否する。
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
        // 親owner整合を同一transaction内で検証する（存在しない・別owner・
        // 推測IDへの追加を拒否）。
        if (parentTable != null && parentId != null) {
          final ok =
              await _db.parentBelongsToOwner(parentTable, parentId, owner);
          if (!ok) throw ParentOwnershipException(parentTable, parentId);
        }
        await write(owner);
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

  DateTime get _now => _clock.now().toUtc();

  @override
  Future<Result<void>> upsertGenba(Genba genba) {
    final stamped = genba.copyWith(updatedAt: _now);
    // 端末内のヒーロー画像参照は同期しない（サーバー列にも存在しない, H-04）。
    final payload = stamped.toJson()..remove('hero_image_local_path');
    return _localWrite(
      (owner) => _db.into(_db.genbas).insertOnConflictUpdate(
            genbaToCompanion(stamped),
          ),
      entityTable: SyncEntity.genbas,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
    );
  }

  @override
  Future<Result<Genba>> mutateGenba(
    String genbaId,
    Genba Function(Genba current) update,
  ) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    Genba? previous;
    try {
      final applied = await _db.transaction(() async {
        // 同一transaction内で最新行を読み直してから merge する。Drift は
        // 単一コネクション上で transaction を直列化するため、同一現場への
        // 並行 mutate は互いに最新値を観測でき、変更を取りこぼさない。
        final row = await (_db.select(_db.genbas)
              ..where(
                (t) => t.id.equals(genbaId) & t.ownerId.equals(owner),
              ))
            .getSingleOrNull();
        if (row == null) return false;
        final current = genbaFromRow(row);
        previous = current;
        final next = update(current).copyWith(updatedAt: _now);
        await _db
            .into(_db.genbas)
            .insertOnConflictUpdate(genbaToCompanion(next));
        // 端末内のヒーロー画像参照は同期しない（サーバー列にも無い, H-04）。
        final payload = next.toJson()..remove('hero_image_local_path');
        final now = _clock.now().toUtc();
        await _outbox.enqueue(
          OutboxOperation(
            mutationId: _uuid.v4(),
            ownerId: owner,
            entityTable: SyncEntity.genbas,
            entityId: next.id,
            opType: OutboxOpType.upsert,
            payload: payload,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return true;
      });
      if (!applied) {
        return const Err(NotFoundFailure(message: '現場が見つかりません'));
      }
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    return Ok(previous!);
  }

  @override
  Future<Result<void>> deleteGenba(String id) {
    return _localWrite(
      (owner) async {
        Future<void> deleteChildOf<T extends Table, R>(
          TableInfo<T, R> table,
          TextColumn Function(T t) genbaIdColumn,
          TextColumn Function(T t) ownerColumn,
        ) =>
            (_db.delete(table)
                  ..where(
                    (t) =>
                        genbaIdColumn(t).equals(id) &
                        ownerColumn(t).equals(owner),
                  ))
                .go();

        await deleteChildOf(_db.tickets, (t) => t.genbaId, (t) => t.ownerId);
        await deleteChildOf(
          _db.transports,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await deleteChildOf(_db.lodgings, (t) => t.genbaId, (t) => t.ownerId);
        await deleteChildOf(_db.todos, (t) => t.genbaId, (t) => t.ownerId);
        await deleteChildOf(
          _db.genbaMemos,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await deleteChildOf(
          _db.memoryEntries,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await deleteChildOf(
          _db.memoryPhotos,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await deleteChildOf(
          _db.setlistItems,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await deleteChildOf(
          _db.goodsItems,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await deleteChildOf(
          _db.visitedPlaces,
          (t) => t.genbaId,
          (t) => t.ownerId,
        );
        await (_db.delete(_db.genbas)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go();
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
      (owner) => _db.into(_db.tickets).insertOnConflictUpdate(
            ticketToCompanion(stamped),
          ),
      entityTable: SyncEntity.tickets,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteTicket(String id) => _localWrite(
        (owner) => (_db.delete(_db.tickets)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.tickets,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertTransport(Transport transport) {
    final stamped = transport.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db.into(_db.transports).insertOnConflictUpdate(
            transportToCompanion(stamped),
          ),
      entityTable: SyncEntity.transports,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteTransport(String id) => _localWrite(
        (owner) => (_db.delete(_db.transports)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.transports,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertLodging(Lodging lodging) {
    final stamped = lodging.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db.into(_db.lodgings).insertOnConflictUpdate(
            lodgingToCompanion(stamped),
          ),
      entityTable: SyncEntity.lodgings,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteLodging(String id) => _localWrite(
        (owner) => (_db.delete(_db.lodgings)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.lodgings,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertTodo(GenbaTodo todo) {
    final stamped = todo.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db.into(_db.todos).insertOnConflictUpdate(
            todoToCompanion(stamped),
          ),
      entityTable: SyncEntity.todos,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteTodo(String id) => _localWrite(
        (owner) => (_db.delete(_db.todos)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.todos,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertMemo(GenbaMemo memo) {
    final stamped = memo.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) async {
        // 区分ごとに1件（genba_id + category でユニーク）。
        await (_db.delete(_db.genbaMemos)
              ..where(
                (t) =>
                    t.genbaId.equals(stamped.genbaId) &
                    t.category.equals(stamped.category.name) &
                    t.id.isNotValue(stamped.id) &
                    t.ownerId.equals(owner),
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
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deleteMemo(String id) => _localWrite(
        (owner) => (_db.delete(_db.genbaMemos)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.genbaMemos,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- リモート取り込み（キャッシュ先行 → バックグラウンド更新） --------

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    final client = _remote();
    if (client == null) return const Ok(null); // デモモード: ローカルのみ
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    _refreshIsStale = isStale;

    return guardResult(
      () async {
        await _pullTable(
          client,
          owner,
          SyncEntity.genbas,
          // 端末内ヒーロー画像参照はサーバーに無い。pull で null 上書きしない。
          (json) => genbaToCompanion(
            Genba.fromJson(json),
            preserveLocalImage: true,
          ),
          _db.genbas,
          (t) => t.id,
          (t) => t.ownerId,
          (r) => r.id,
        );
        await _pullTable(
          client,
          owner,
          SyncEntity.tickets,
          (json) => ticketToCompanion(Ticket.fromJson(json)),
          _db.tickets,
          (t) => t.id,
          (t) => t.ownerId,
          (r) => r.id,
        );
        await _pullTable(
          client,
          owner,
          SyncEntity.transports,
          (json) => transportToCompanion(Transport.fromJson(json)),
          _db.transports,
          (t) => t.id,
          (t) => t.ownerId,
          (r) => r.id,
        );
        await _pullTable(
          client,
          owner,
          SyncEntity.lodgings,
          (json) => lodgingToCompanion(Lodging.fromJson(json)),
          _db.lodgings,
          (t) => t.id,
          (t) => t.ownerId,
          (r) => r.id,
        );
        await _pullTable(
          client,
          owner,
          SyncEntity.todos,
          (json) => todoToCompanion(GenbaTodo.fromJson(json)),
          _db.todos,
          (t) => t.id,
          (t) => t.ownerId,
          (r) => r.id,
        );
        await _pullTable(
          client,
          owner,
          SyncEntity.genbaMemos,
          (json) => memoToCompanion(GenbaMemo.fromJson(json)),
          _db.genbaMemos,
          (t) => t.id,
          (t) => t.ownerId,
          (r) => r.id,
        );
      },
      onError: (e, _) => NetworkFailure(cause: e),
    );
  }

  /// [owner] に限定してリモートと差分同期する（Supabaseから行を取得する薄い層）。
  /// 実際の取り込み・差分削除ロジックは [applyPulledRows] に分離してある
  /// （Supabaseへ接続しない単体テストから直接検証できるようにするため）。
  /// 直近の refreshFromRemote に渡された認証切替検出フック（H-02）。
  bool Function()? _refreshIsStale;

  Future<void> _pullTable<T extends Table, R>(
    SupabaseClient client,
    String owner,
    String tableName,
    Insertable<R> Function(Map<String, dynamic> json) toCompanion,
    TableInfo<T, R> table,
    TextColumn Function(T table) idColumn,
    TextColumn Function(T table) ownerColumn,
    String Function(R row) idOf,
  ) async {
    final rows = await client.from(tableName).select();
    // 各リモート取得後の認証切替チェック（別owner/世代になったら適用しない）。
    if (_refreshIsStale?.call() ?? false) return;
    await applyPulledRows(
      owner,
      tableName,
      rows,
      toCompanion,
      table,
      idColumn,
      ownerColumn,
      idOf,
    );
  }

  /// リモートから取得した行 [rows] を [owner] に限定してローカルへ差分適用する。
  ///
  /// - 取り込み対象は [rows] のうち `owner_id == owner` のものだけ
  ///   （RLSにより通常はそれ以外返らないが、防御的に再検証する）。
  /// - 差分削除の比較対象となるローカル行も `owner_id == owner` に限定して
  ///   問い合わせる。他ownerの行は読み込み・比較・削除のいずれも行わない（C-01）。
  ///
  /// `@visibleForTesting`: Supabase への実接続なしに pull の差分削除ロジックを
  /// 単体テストするための公開。プロダクションコードからは [_pullTable] 経由で
  /// のみ呼ばれる。
  @visibleForTesting
  Future<void> applyPulledRows<T extends Table, R>(
    String owner,
    String tableName,
    List<Map<String, dynamic>> rows,
    Insertable<R> Function(Map<String, dynamic> json) toCompanion,
    TableInfo<T, R> table,
    TextColumn Function(T table) idColumn,
    TextColumn Function(T table) ownerColumn,
    String Function(R row) idOf,
  ) =>
      applyPulledRowsInto(
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
        isStale: _refreshIsStale,
      );
}
