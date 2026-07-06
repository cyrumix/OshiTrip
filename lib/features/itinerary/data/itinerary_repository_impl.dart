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
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_plan.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/itinerary_repository.dart';
import '../domain/itinerary_spot.dart';
import '../domain/itinerary_spot_link.dart';
import '../domain/itinerary_validation.dart';
import 'itinerary_mappers.dart';

/// 旅程リポジトリ実装（owner スコープのローカル先行CRUD + Outbox + 同期）。
///
/// 現場（[GenbaRepositoryImpl]）と同じ「ローカル反映 → Outbox → poke」方式。
/// 計画→スポット→リンク、計画→項目→区間 の親子階層を owner 単位・親所有権
/// 検証つきで扱う（C-01）。削除は親から子へ owner スコープで cascade し、
/// サーバー側の ON DELETE CASCADE と同じ結果をローカルでも作る。
/// 交通・宿泊は参照するだけで複製せず、削除時も本体には触れない（§5.3）。
class ItineraryRepositoryImpl implements ItineraryRepository {
  ItineraryRepositoryImpl({
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

  // ---- 監視 -----------------------------------------------------------------

  @override
  Stream<List<ItineraryPlanAggregate>> watchByGenbaId(String genbaId) async* {
    final owner = _ownerId();
    if (owner == null) {
      yield const [];
      return;
    }
    yield await _queryByGenba(owner, genbaId);
    await for (final _ in _itineraryUpdates()) {
      final current = _ownerId();
      if (current == null) {
        yield const [];
        continue;
      }
      yield await _queryByGenba(current, genbaId);
    }
  }

  @override
  Stream<ItineraryPlanAggregate?> watchPlan(String planId) async* {
    final owner = _ownerId();
    if (owner == null) {
      yield null;
      return;
    }
    yield await _queryPlan(owner, planId);
    await for (final _ in _itineraryUpdates()) {
      final current = _ownerId();
      if (current == null) {
        yield null;
        continue;
      }
      yield await _queryPlan(current, planId);
    }
  }

  Stream<void> _itineraryUpdates() => _db.tableUpdates(
        TableUpdateQuery.onAllTables([
          _db.itineraryPlans,
          _db.itinerarySpots,
          _db.itinerarySpotLinks,
          _db.itineraryEntries,
          _db.itineraryLegs,
        ]),
      );

  Future<List<ItineraryPlanAggregate>> _queryByGenba(
    String owner,
    String genbaId,
  ) async {
    final plans = await (_db.select(_db.itineraryPlans)
          ..where((t) => t.ownerId.equals(owner) & t.genbaId.equals(genbaId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return _assembleAggregates(owner, plans);
  }

  Future<ItineraryPlanAggregate?> _queryPlan(
    String owner,
    String planId,
  ) async {
    final plan = await (_db.select(_db.itineraryPlans)
          ..where((t) => t.ownerId.equals(owner) & t.id.equals(planId)))
        .getSingleOrNull();
    if (plan == null) return null;
    final aggregates = await _assembleAggregates(owner, [plan]);
    return aggregates.isEmpty ? null : aggregates.first;
  }

  Future<List<ItineraryPlanAggregate>> _assembleAggregates(
    String owner,
    List<ItineraryPlanRow> plans,
  ) async {
    if (plans.isEmpty) return const [];
    final planIds = plans.map((p) => p.id).toList();

    final spots = await (_db.select(_db.itinerarySpots)
          ..where((t) => t.ownerId.equals(owner) & t.planId.isIn(planIds)))
        .get();
    final spotIds = spots.map((s) => s.id).toList();
    final links = spotIds.isEmpty
        ? <ItinerarySpotLinkRow>[]
        : await (_db.select(_db.itinerarySpotLinks)
              ..where(
                (t) => t.ownerId.equals(owner) & t.spotId.isIn(spotIds),
              ))
            .get();
    final entries = await (_db.select(_db.itineraryEntries)
          ..where((t) => t.ownerId.equals(owner) & t.planId.isIn(planIds)))
        .get();
    final legs = await (_db.select(_db.itineraryLegs)
          ..where((t) => t.ownerId.equals(owner) & t.planId.isIn(planIds)))
        .get();

    final spotDomains = spots.map(spotFromRow).toList();
    final linkDomains = links.map(spotLinkFromRow).toList();
    final entryDomains = entries.map(entryFromRow).toList();
    final legDomains = legs.map(legFromRow).toList();

    return plans.map((planRow) {
      final planSpotIds =
          spotDomains.where((s) => s.planId == planRow.id).map((s) => s.id);
      return ItineraryPlanAggregate(
        plan: planFromRow(planRow),
        spots: spotDomains.where((s) => s.planId == planRow.id).toList(),
        spotLinks:
            linkDomains.where((l) => planSpotIds.contains(l.spotId)).toList(),
        entries: entryDomains.where((e) => e.planId == planRow.id).toList(),
        legs: legDomains.where((l) => l.planId == planRow.id).toList(),
      );
    }).toList();
  }

  // ---- 書き込み共通（owner ガード + 親所有権 + 原子的 Outbox）------------------

  /// genba/oshi/template と同型の owner ガードつき単一書き込みヘルパー（C-01）。
  ///
  /// upsert では別owner の既存行の乗っ取りを、delete では別owner 行に対する
  /// 「削除0件でも成功扱い＋不要な delete Outbox」を、いずれも事前チェックで
  /// 型付き [AuthFailure] にして拒否する（ローカル行にも Outbox にも触れない）。
  /// ローカルにその id 自体が存在しない delete は冪等削除として成立させ、
  /// 同期用の delete Outbox を積む。
  /// [validateReferences] は書き込みと同一 transaction 内で「参照先が同一
  /// owner・同一計画/現場に属するか」を検証する（entry の spot/transport/
  /// lodging、leg の origin/destination）。非nullの [Failure] を返すと全体を
  /// ロールバックして返す（ローカル行にも Outbox にも触れない, C-01）。
  Future<Result<void>> _localWrite(
    Future<void> Function(String owner) write, {
    required String entityTable,
    required String entityId,
    required OutboxOpType opType,
    Map<String, dynamic> payload = const {},
    String? parentTable,
    String? parentId,
    Future<Failure?> Function(String owner)? validateReferences,
  }) async {
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    if (payload.containsKey('owner_id') && payload['owner_id'] != owner) {
      return const Err(AuthFailure(message: '所有者が一致しません'));
    }
    if ((opType == OutboxOpType.upsert || opType == OutboxOpType.delete) &&
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
        if (validateReferences != null) {
          final refFailure = await validateReferences(owner);
          if (refFailure != null) {
            throw _ReferenceValidationException(refFailure);
          }
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
    } on _ReferenceValidationException catch (e) {
      return Err(e.failure);
    } catch (e) {
      return Err(StorageFailure(cause: e));
    }
    _syncEngine.poke();
    return const Ok(null);
  }

  /// 参照整合性エラーは常に同一の型付き [ValidationFailure] へ正規化する。
  /// 「存在しない」と「別owner/別計画/別現場に属する」を区別できる文言にすると
  /// ID推測で他ユーザーの行の存在有無を探れてしまうため、どちらも同一メッセージ
  /// にする（C-01 / 情報漏えい防止）。
  static const Failure _referenceFailure =
      ValidationFailure('参照先が見つからないか、この計画では利用できません');

  /// [ItineraryEntry] の参照先（kind別）が同一owner・同一計画/現場に属するか。
  Future<Failure?> _validateEntryReferences(
    ItineraryEntry entry,
    String owner,
  ) async {
    switch (entry.kind) {
      case ItineraryEntryKind.spot:
        final ok = await _existsForOwner(
          _db.itinerarySpots,
          (t) =>
              t.id.equals(entry.spotId!) &
              t.ownerId.equals(owner) &
              t.planId.equals(entry.planId),
        );
        return ok ? null : _referenceFailure;
      case ItineraryEntryKind.transport:
        // 交通は「この計画の現場」に登録済みのものだけ参照できる（§5.3）。
        final genbaId = await _planGenbaId(entry.planId, owner);
        if (genbaId == null) return _referenceFailure;
        final ok = await _existsForOwner(
          _db.transports,
          (t) =>
              t.id.equals(entry.transportId!) &
              t.ownerId.equals(owner) &
              t.genbaId.equals(genbaId),
        );
        return ok ? null : _referenceFailure;
      case ItineraryEntryKind.lodging:
        final genbaId = await _planGenbaId(entry.planId, owner);
        if (genbaId == null) return _referenceFailure;
        final ok = await _existsForOwner(
          _db.lodgings,
          (t) =>
              t.id.equals(entry.lodgingId!) &
              t.ownerId.equals(owner) &
              t.genbaId.equals(genbaId),
        );
        return ok ? null : _referenceFailure;
      case ItineraryEntryKind.note:
        return null;
    }
  }

  /// [ItineraryLeg] の origin/destination が同一owner・同一計画の項目か。
  Future<Failure?> _validateLegReferences(
    ItineraryLeg leg,
    String owner,
  ) async {
    Future<bool> entryInPlan(String entryId) => _existsForOwner(
          _db.itineraryEntries,
          (t) =>
              t.id.equals(entryId) &
              t.ownerId.equals(owner) &
              t.planId.equals(leg.planId),
        );
    if (!await entryInPlan(leg.originEntryId)) return _referenceFailure;
    if (!await entryInPlan(leg.destinationEntryId)) return _referenceFailure;
    return null;
  }

  Future<bool> _existsForOwner<T extends Table, R>(
    TableInfo<T, R> table,
    Expression<bool> Function(T tbl) filter,
  ) async {
    final row = await (_db.select(table)..where(filter)).getSingleOrNull();
    return row != null;
  }

  Future<String?> _planGenbaId(String planId, String owner) async {
    final row = await (_db.select(_db.itineraryPlans)
          ..where((t) => t.id.equals(planId) & t.ownerId.equals(owner)))
        .getSingleOrNull();
    return row?.genbaId;
  }

  // ---- 計画 -----------------------------------------------------------------

  @override
  Future<Result<void>> upsertPlan(ItineraryPlan plan) {
    final invalid = validateItineraryPlan(plan);
    if (invalid != null) return Future.value(Err(invalid));
    final stamped = plan.copyWith(updatedAt: _now);
    // 端末内カバー画像参照はサーバー列に存在しない。Outbox payload へ載せない。
    final payload = stamped.toJson()..remove('cover_image_local_path');
    return _localWrite(
      (owner) => _db
          .into(_db.itineraryPlans)
          .insertOnConflictUpdate(planToCompanion(stamped)),
      entityTable: SyncEntity.itineraryPlans,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
      parentTable: SyncEntity.genbas,
      parentId: stamped.genbaId,
    );
  }

  @override
  Future<Result<void>> deletePlan(String id) => _localWrite(
        (owner) async {
          // 配下のスポットIDを収集（リンクの cascade 用）。
          final spots = await (_db.select(_db.itinerarySpots)
                ..where((t) => t.planId.equals(id) & t.ownerId.equals(owner)))
              .get();
          final spotIds = spots.map((s) => s.id).toList();
          // legs → entries → spot_links → spots → plan の順に owner スコープ削除。
          await (_db.delete(_db.itineraryLegs)
                ..where((t) => t.planId.equals(id) & t.ownerId.equals(owner)))
              .go();
          await (_db.delete(_db.itineraryEntries)
                ..where((t) => t.planId.equals(id) & t.ownerId.equals(owner)))
              .go();
          if (spotIds.isNotEmpty) {
            await (_db.delete(_db.itinerarySpotLinks)
                  ..where(
                    (t) => t.spotId.isIn(spotIds) & t.ownerId.equals(owner),
                  ))
                .go();
          }
          await (_db.delete(_db.itinerarySpots)
                ..where((t) => t.planId.equals(id) & t.ownerId.equals(owner)))
              .go();
          await (_db.delete(_db.itineraryPlans)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
              .go();
        },
        entityTable: SyncEntity.itineraryPlans,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- スポット ---------------------------------------------------------------

  @override
  Future<Result<void>> upsertSpot(ItinerarySpot spot) {
    final invalid = validateItinerarySpot(spot);
    if (invalid != null) return Future.value(Err(invalid));
    final stamped = spot.copyWith(updatedAt: _now);
    // 端末内ユーザー画像参照はサーバー列に存在しない。Outbox payload へ載せない。
    final payload = stamped.toJson()..remove('user_image_local_path');
    return _localWrite(
      (owner) => _db.into(_db.itinerarySpots).insertOnConflictUpdate(
            spotToCompanion(stamped),
          ),
      entityTable: SyncEntity.itinerarySpots,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
      parentTable: SyncEntity.itineraryPlans,
      parentId: stamped.planId,
    );
  }

  @override
  Future<Result<void>> deleteSpot(String id) => _localWrite(
        (owner) async {
          // このスポットを参照する訪問項目IDを収集（leg の cascade 用）。
          final entries = await (_db.select(_db.itineraryEntries)
                ..where((t) => t.spotId.equals(id) & t.ownerId.equals(owner)))
              .get();
          final entryIds = entries.map((e) => e.id).toList();
          if (entryIds.isNotEmpty) {
            await (_db.delete(_db.itineraryLegs)
                  ..where(
                    (t) =>
                        (t.originEntryId.isIn(entryIds) |
                            t.destinationEntryId.isIn(entryIds)) &
                        t.ownerId.equals(owner),
                  ))
                .go();
          }
          await (_db.delete(_db.itineraryEntries)
                ..where((t) => t.spotId.equals(id) & t.ownerId.equals(owner)))
              .go();
          await (_db.delete(_db.itinerarySpotLinks)
                ..where((t) => t.spotId.equals(id) & t.ownerId.equals(owner)))
              .go();
          await (_db.delete(_db.itinerarySpots)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
              .go();
        },
        entityTable: SyncEntity.itinerarySpots,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- スポットのリンク ---------------------------------------------------------

  @override
  Future<Result<void>> upsertSpotLink(ItinerarySpotLink link) {
    final invalid = validateItinerarySpotLink(link);
    if (invalid != null) return Future.value(Err(invalid));
    final stamped = link.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db.into(_db.itinerarySpotLinks).insertOnConflictUpdate(
            spotLinkToCompanion(stamped),
          ),
      entityTable: SyncEntity.itinerarySpotLinks,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.itinerarySpots,
      parentId: stamped.spotId,
    );
  }

  @override
  Future<Result<void>> deleteSpotLink(String id) => _localWrite(
        (owner) => (_db.delete(_db.itinerarySpotLinks)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.itinerarySpotLinks,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- 旅程項目 ---------------------------------------------------------------

  @override
  Future<Result<void>> upsertEntry(ItineraryEntry entry) {
    final invalid = validateItineraryEntry(entry);
    if (invalid != null) return Future.value(Err(invalid));
    final stamped = entry.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db.into(_db.itineraryEntries).insertOnConflictUpdate(
            entryToCompanion(stamped),
          ),
      entityTable: SyncEntity.itineraryEntries,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.itineraryPlans,
      parentId: stamped.planId,
      validateReferences: (owner) => _validateEntryReferences(stamped, owner),
    );
  }

  @override
  Future<Result<void>> deleteEntry(String id) => _localWrite(
        (owner) async {
          // この項目を始点/終点とする移動区間も削除する（サーバー FK と同じ）。
          await (_db.delete(_db.itineraryLegs)
                ..where(
                  (t) =>
                      (t.originEntryId.equals(id) |
                          t.destinationEntryId.equals(id)) &
                      t.ownerId.equals(owner),
                ))
              .go();
          await (_db.delete(_db.itineraryEntries)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
              .go();
        },
        entityTable: SyncEntity.itineraryEntries,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- 移動区間 ---------------------------------------------------------------

  @override
  Future<Result<void>> upsertLeg(ItineraryLeg leg) {
    final invalid = validateItineraryLeg(leg);
    if (invalid != null) return Future.value(Err(invalid));
    // Phase 1 では Google Routes のライブ応答を永続化しない（Repository境界で
    // 強制。行も Outbox も作らない, §12.5/D-180）。
    final googleLive = validateItineraryLegPhase1Persistable(leg);
    if (googleLive != null) return Future.value(Err(googleLive));
    final stamped = leg.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) => _db.into(_db.itineraryLegs).insertOnConflictUpdate(
            legToCompanion(stamped),
          ),
      entityTable: SyncEntity.itineraryLegs,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      parentTable: SyncEntity.itineraryPlans,
      parentId: stamped.planId,
      validateReferences: (owner) => _validateLegReferences(stamped, owner),
    );
  }

  @override
  Future<Result<void>> deleteLeg(String id) => _localWrite(
        (owner) => (_db.delete(_db.itineraryLegs)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.itineraryLegs,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  // ---- リモート同期 -----------------------------------------------------------

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    final client = _remote();
    if (client == null) return const Ok(null); // デモ・未ログイン: ローカルのみ
    final owner = _ownerId();
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    return guardResult(
      () async {
        // 親→子の順に取り込む（plans → spots → links → entries → legs）。
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.itineraryPlans,
          rows: await client
              .from(SyncEntity.itineraryPlans)
              .select()
              .withRemoteTimeout(),
          // 端末内カバー画像参照はサーバーに無い。pull で null 上書きしない。
          toCompanion: (json) => planToCompanion(
            ItineraryPlan.fromJson(json),
            preserveLocalImage: true,
          ),
          table: _db.itineraryPlans,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.itinerarySpots,
          rows: await client
              .from(SyncEntity.itinerarySpots)
              .select()
              .withRemoteTimeout(),
          // 端末内ユーザー画像参照はサーバーに無い。pull で null 上書きしない。
          toCompanion: (json) => spotToCompanion(
            ItinerarySpot.fromJson(json),
            preserveLocalImage: true,
          ),
          table: _db.itinerarySpots,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.itinerarySpotLinks,
          rows: await client
              .from(SyncEntity.itinerarySpotLinks)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) =>
              spotLinkToCompanion(ItinerarySpotLink.fromJson(json)),
          table: _db.itinerarySpotLinks,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.itineraryEntries,
          rows: await client
              .from(SyncEntity.itineraryEntries)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) =>
              entryToCompanion(ItineraryEntry.fromJson(json)),
          table: _db.itineraryEntries,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.itineraryLegs,
          rows: await client
              .from(SyncEntity.itineraryLegs)
              .select()
              .withRemoteTimeout(),
          toCompanion: (json) => legToCompanion(ItineraryLeg.fromJson(json)),
          table: _db.itineraryLegs,
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
          case SyncEntity.itineraryPlans:
            await _adoptOne(
              client,
              owner,
              SyncEntity.itineraryPlans,
              entityId,
              // 通常pullと同じく、サーバーに無い端末内カバー画像参照を
              // null で上書きしない（H-04）。
              (json) => planToCompanion(
                ItineraryPlan.fromJson(json),
                preserveLocalImage: true,
              ),
              _db.itineraryPlans,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.itinerarySpots:
            await _adoptOne(
              client,
              owner,
              SyncEntity.itinerarySpots,
              entityId,
              // 端末内ユーザー画像参照を null で上書きしない（H-04）。
              (json) => spotToCompanion(
                ItinerarySpot.fromJson(json),
                preserveLocalImage: true,
              ),
              _db.itinerarySpots,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.itinerarySpotLinks:
            await _adoptOne(
              client,
              owner,
              SyncEntity.itinerarySpotLinks,
              entityId,
              (json) => spotLinkToCompanion(ItinerarySpotLink.fromJson(json)),
              _db.itinerarySpotLinks,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.itineraryEntries:
            await _adoptOne(
              client,
              owner,
              SyncEntity.itineraryEntries,
              entityId,
              (json) => entryToCompanion(ItineraryEntry.fromJson(json)),
              _db.itineraryEntries,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          case SyncEntity.itineraryLegs:
            await _adoptOne(
              client,
              owner,
              SyncEntity.itineraryLegs,
              entityId,
              (json) => legToCompanion(ItineraryLeg.fromJson(json)),
              _db.itineraryLegs,
              (t) => t.id,
              (t) => t.ownerId,
              (r) => r.id,
            );
          default:
            throw ArgumentError('itinerary repo は $entityTable を所有しません');
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

/// 参照整合性（entry の kind別参照・leg の両端）検証に失敗したときに投げる
/// 番兵例外。Drift の transaction をロールバックさせ、呼び出し側で保持している
/// 型付き [Failure] へ変換する。
class _ReferenceValidationException implements Exception {
  const _ReferenceValidationException(this.failure);

  final Failure failure;
}
