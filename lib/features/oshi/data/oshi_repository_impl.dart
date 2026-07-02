import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/sync/outbox_operation.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/time/clock.dart';
import '../domain/oshi.dart';
import '../domain/oshi_repository.dart';

class OshiRepositoryImpl implements OshiRepository {
  OshiRepositoryImpl({
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
  Stream<List<OshiGroupWithMembers>> watchAll() async* {
    yield await _queryAll();
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.oshiGroups, _db.oshiMembers]),
    );
    await for (final _ in updates) {
      yield await _queryAll();
    }
  }

  Future<List<OshiGroupWithMembers>> _queryAll() async {
    final groups = await (_db.select(_db.oshiGroups)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final members = await (_db.select(_db.oshiMembers)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return groups.map((g) {
      return OshiGroupWithMembers(
        group: _groupFromRow(g),
        members: members
            .where((m) => m.groupId == g.id)
            .map(_memberFromRow)
            .toList(),
      );
    }).toList();
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
  Future<Result<void>> upsertGroup(OshiGroup group) {
    final stamped = group.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db
          .into(_db.oshiGroups)
          .insertOnConflictUpdate(_groupToCompanion(stamped)),
      entityTable: SyncEntity.oshiGroups,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteGroup(String id) => _localWrite(
        () async {
          await (_db.delete(_db.oshiMembers)
                ..where((t) => t.groupId.equals(id)))
              .go();
          await (_db.delete(_db.oshiGroups)..where((t) => t.id.equals(id)))
              .go();
        },
        entityTable: SyncEntity.oshiGroups,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertMember(OshiMember member) {
    final stamped = member.copyWith(updatedAt: _now);
    return _localWrite(
      () => _db
          .into(_db.oshiMembers)
          .insertOnConflictUpdate(_memberToCompanion(stamped)),
      entityTable: SyncEntity.oshiMembers,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
    );
  }

  @override
  Future<Result<void>> deleteMember(String id) => _localWrite(
        () => (_db.delete(_db.oshiMembers)..where((t) => t.id.equals(id))).go(),
        entityTable: SyncEntity.oshiMembers,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  OshiGroup _groupFromRow(OshiGroupRow row) => OshiGroup(
        id: row.id,
        ownerId: row.ownerId,
        name: row.name,
        kind: row.kind,
        color: row.color,
        memo: row.memo,
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );

  OshiGroupsCompanion _groupToCompanion(OshiGroup g) =>
      OshiGroupsCompanion.insert(
        id: g.id,
        ownerId: g.ownerId,
        name: g.name,
        kind: Value(g.kind),
        color: Value(g.color),
        memo: Value(g.memo),
        createdAt: g.createdAt.toUtc().toIso8601String(),
        updatedAt: g.updatedAt.toUtc().toIso8601String(),
      );

  OshiMember _memberFromRow(OshiMemberRow row) => OshiMember(
        id: row.id,
        groupId: row.groupId,
        ownerId: row.ownerId,
        name: row.name,
        rank: switch (row.rank) {
          'saioshi' => OshiRank.saioshi,
          'yuruoshi' => OshiRank.yuruoshi,
          'hakooshi' => OshiRank.hakooshi,
          'curious' => OshiRank.curious,
          _ => OshiRank.oshi,
        },
        color: row.color,
        oshiSince:
            row.oshiSince == null ? null : DateTime.parse(row.oshiSince!),
        birthday: row.birthday == null ? null : DateTime.parse(row.birthday!),
        memo: row.memo,
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );

  OshiMembersCompanion _memberToCompanion(OshiMember m) =>
      OshiMembersCompanion.insert(
        id: m.id,
        groupId: m.groupId,
        ownerId: m.ownerId,
        name: m.name,
        rank: Value(m.rank.name),
        color: Value(m.color),
        oshiSince: Value(
          m.oshiSince == null ? null : _dateText(m.oshiSince!),
        ),
        birthday: Value(m.birthday == null ? null : _dateText(m.birthday!)),
        memo: Value(m.memo),
        createdAt: m.createdAt.toUtc().toIso8601String(),
        updatedAt: m.updatedAt.toUtc().toIso8601String(),
      );

  String _dateText(DateTime d) {
    final mo = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mo-$da';
  }
}
