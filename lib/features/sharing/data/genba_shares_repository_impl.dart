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
import '../domain/share.dart';
import 'share_mappers.dart';

/// 現場共有リポジトリ実装（owner スコープの共有 CRUD + Outbox + 同期）。
///
/// owner（現場の所有者）が自分の現場の共有行を作成・変更・削除する。
/// 親現場が現在 owner に属すること（＝他人の現場を共有できないこと）を
/// `parentBelongsToOwner`（ローカル）で検証し、サーバー側は子owner トリガ
/// （`enforce_genba_child_owner`）で二重に強制する（C-01）。
///
/// grantee 側の「共有された現場を読む」ロール別 read RLS・項目マスキングは
/// 次増分（decisions.md D-226）。本ローカル表には owner が共有した行
/// （owner_id = 自分）だけが入る（`applyPulledRowsInto` の owner フィルタ）。
class GenbaSharesRepositoryImpl implements ShareRepository {
  GenbaSharesRepositoryImpl({
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
  Stream<List<GenbaShare>> watchShares(String genbaId) async* {
    final owner = _ownerId();
    if (owner == null) {
      yield const [];
      return;
    }
    yield await _queryForGenba(owner, genbaId);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.genbaShares]),
    );
    await for (final _ in updates) {
      final current = _ownerId();
      if (current == null) {
        yield const [];
        continue;
      }
      yield await _queryForGenba(current, genbaId);
    }
  }

  Future<List<GenbaShare>> _queryForGenba(String owner, String genbaId) async {
    final rows = await (_db.select(_db.genbaShares)
          ..where((t) => t.ownerId.equals(owner) & t.genbaId.equals(genbaId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(shareFromRow).toList();
  }

  @override
  Future<Result<void>> upsertShare(GenbaShare share) {
    final invariant = shareInvariantError(
      ownerId: share.ownerId,
      granteeId: share.granteeId,
      role: share.role,
    );
    if (invariant != null) {
      return Future.value(Err(ValidationFailure(invariant)));
    }
    final stamped = share.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db
          .into(_db.genbaShares)
          .insertOnConflictUpdate(shareToCompanion(stamped)),
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: shareToJson(stamped),
      // 親現場が現在ownerに属すること＝他人の現場を共有できないこと（C-01）。
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> removeShare(String shareId) => _localWrite(
        (owner) => (_db.delete(_db.genbaShares)
              ..where((t) => t.id.equals(shareId) & t.ownerId.equals(owner)))
            .go(),
        entityId: shareId,
        opType: OutboxOpType.delete,
      );

  /// owner ガード＋親現場所有権検証つきの単一書き込みヘルパー（C-01）。
  Future<Result<void>> _localWrite(
    Future<void> Function(String owner) write, {
    required String entityId,
    required OutboxOpType opType,
    Map<String, dynamic> payload = const {},
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
        await _db.existsForOtherOwner(
          SyncEntity.genbaShares,
          entityId,
          owner,
        )) {
      return const Err(AuthFailure(message: '既存の別ユーザーのデータは操作できません'));
    }
    try {
      await _db.transaction(() async {
        if (parentId != null) {
          final ok = await _db.parentBelongsToOwner(
            SyncEntity.genbas,
            parentId,
            owner,
          );
          if (!ok) throw ParentOwnershipException(SyncEntity.genbas, parentId);
        }
        await write(owner);
        final now = _now;
        await _outbox.enqueue(
          OutboxOperation(
            mutationId: _uuid.v4(),
            ownerId: owner,
            entityTable: SyncEntity.genbaShares,
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
        ValidationFailure('共有できるのは自分が所有する現場だけです'),
      );
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
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
          tableName: SyncEntity.genbaShares,
          rows: await client
              .from(SyncEntity.genbaShares)
              .select()
              .withRemoteTimeout(),
          toCompanion: shareJsonToCompanion,
          table: _db.genbaShares,
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
        if (entityTable != SyncEntity.genbaShares) {
          throw ArgumentError('genba shares repo は $entityTable を所有しません');
        }
        final rows = await client
            .from(SyncEntity.genbaShares)
            .select()
            .withRemoteTimeout();
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.genbaShares,
          rows: rows,
          toCompanion: shareJsonToCompanion,
          table: _db.genbaShares,
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
