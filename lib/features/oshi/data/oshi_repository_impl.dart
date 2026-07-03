import 'package:drift/drift.dart';
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
import '../domain/oshi.dart';
import '../domain/oshi_repository.dart';

class OshiRepositoryImpl implements OshiRepository {
  OshiRepositoryImpl({
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
  Stream<List<OshiGroupWithMembers>> watchAll() async* {
    final owner = _ownerId();
    if (owner == null) {
      yield const [];
      return;
    }
    yield await _queryAll(owner);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.oshiGroups, _db.oshiMembers]),
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

  @override
  Stream<List<OshiAnniversary>> watchAnniversaries() async* {
    final owner = _ownerId();
    if (owner == null) {
      yield const [];
      return;
    }
    yield await _queryAnniversaries(owner);
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.oshiAnniversaries]),
    );
    await for (final _ in updates) {
      final current = _ownerId();
      if (current == null) {
        yield const [];
        continue;
      }
      yield await _queryAnniversaries(current);
    }
  }

  Future<List<OshiAnniversary>> _queryAnniversaries(String owner) async {
    final rows = await (_db.select(_db.oshiAnniversaries)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    return rows.map(_anniversaryFromRow).toList();
  }

  Future<List<OshiGroupWithMembers>> _queryAll(String owner) async {
    final groups = await (_db.select(_db.oshiGroups)
          ..where((t) => t.ownerId.equals(owner))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final members = await (_db.select(_db.oshiMembers)
          ..where((t) => t.ownerId.equals(owner))
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
  Future<Result<void>> upsertGroup(OshiGroup group) {
    final stamped = group.copyWith(updatedAt: _now);
    // 端末内のグループ画像参照は同期しない（サーバー列にも存在しない, H-04）。
    final payload = stamped.toJson()..remove('image_local_path');
    return _localWrite(
      (owner) => _db
          .into(_db.oshiGroups)
          .insertOnConflictUpdate(_groupToCompanion(stamped)),
      entityTable: SyncEntity.oshiGroups,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
    );
  }

  @override
  Future<Result<void>> deleteGroup(String id) => _localWrite(
        (owner) async {
          // グループ削除でメンバー・記念日も端末から削除する
          // （Supabase の ON DELETE CASCADE と同じ結果, R6独立レビュー#2）。
          await (_db.delete(_db.oshiAnniversaries)
                ..where(
                  (t) => t.groupId.equals(id) & t.ownerId.equals(owner),
                ))
              .go();
          await (_db.delete(_db.oshiMembers)
                ..where(
                  (t) => t.groupId.equals(id) & t.ownerId.equals(owner),
                ))
              .go();
          await (_db.delete(_db.oshiGroups)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
              .go();
        },
        entityTable: SyncEntity.oshiGroups,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertMember(OshiMember member) {
    final stamped = member.copyWith(updatedAt: _now);
    // 端末内の推し画像参照は同期しない（サーバー列にも存在しない, H-04）。
    final payload = stamped.toJson()..remove('image_local_path');
    return _localWrite(
      (owner) => _db
          .into(_db.oshiMembers)
          .insertOnConflictUpdate(_memberToCompanion(stamped)),
      entityTable: SyncEntity.oshiMembers,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: payload,
      parentTable: SyncEntity.oshiGroups,
      parentId: stamped.groupId,
    );
  }

  @override
  Future<Result<void>> deleteMember(String id) => _localWrite(
        (owner) async {
          // メンバー削除時、そのメンバーに紐づく記念日の member_id を null へ
          // 更新する（Supabase の ON DELETE SET NULL と同じ結果, R6独立レビュー#2）。
          // 記念日レコード自体は残す（グループ全体の記念日として維持）。
          await (_db.update(_db.oshiAnniversaries)
                ..where(
                  (t) => t.memberId.equals(id) & t.ownerId.equals(owner),
                ))
              .write(const OshiAnniversariesCompanion(memberId: Value(null)));
          await (_db.delete(_db.oshiMembers)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
              .go();
        },
        entityTable: SyncEntity.oshiMembers,
        entityId: id,
        opType: OutboxOpType.delete,
      );

  @override
  Future<Result<void>> upsertAnniversary(OshiAnniversary anniversary) {
    final stamped = anniversary.copyWith(updatedAt: _now);
    return _localWrite(
      (owner) async {
        // member_id を指定する場合、そのメンバーが現在owner・かつ groupId の
        // グループに所属することを同一 transaction 内で検証する
        // （R6独立レビュー#2。存在しない/別owner/別グループを型付き失敗で拒否）。
        final memberId = stamped.memberId;
        if (memberId != null &&
            !await _db.memberInGroupOfOwner(memberId, stamped.groupId, owner)) {
          throw ParentOwnershipException(SyncEntity.oshiMembers, memberId);
        }
        await _db
            .into(_db.oshiAnniversaries)
            .insertOnConflictUpdate(_anniversaryToCompanion(stamped));
      },
      entityTable: SyncEntity.oshiAnniversaries,
      entityId: stamped.id,
      opType: OutboxOpType.upsert,
      payload: stamped.toJson(),
      // 親グループが現在ownerに属することを検証する（C-01）。
      parentTable: SyncEntity.oshiGroups,
      parentId: stamped.groupId,
    );
  }

  @override
  Future<Result<void>> deleteAnniversary(String id) => _localWrite(
        (owner) => (_db.delete(_db.oshiAnniversaries)
              ..where((t) => t.id.equals(id) & t.ownerId.equals(owner)))
            .go(),
        entityTable: SyncEntity.oshiAnniversaries,
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
          tableName: SyncEntity.oshiGroups,
          rows: await client.from(SyncEntity.oshiGroups).select(),
          // 端末内のグループ画像参照はサーバーに無い。pull で null 上書きしない。
          toCompanion: (json) => _groupToCompanion(
            OshiGroup.fromJson(json),
            preserveLocalImage: true,
          ),
          table: _db.oshiGroups,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.oshiMembers,
          rows: await client.from(SyncEntity.oshiMembers).select(),
          // 端末内の推し画像参照はサーバーに無い。pull で null 上書きしない。
          toCompanion: (json) => _memberToCompanion(
            OshiMember.fromJson(json),
            preserveLocalImage: true,
          ),
          table: _db.oshiMembers,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
        await applyPulledRowsInto(
          db: _db,
          outbox: _outbox,
          owner: owner,
          tableName: SyncEntity.oshiAnniversaries,
          rows: await client.from(SyncEntity.oshiAnniversaries).select(),
          toCompanion: (json) =>
              _anniversaryToCompanion(OshiAnniversary.fromJson(json)),
          table: _db.oshiAnniversaries,
          idColumn: (t) => t.id,
          ownerColumn: (t) => t.ownerId,
          idOf: (r) => r.id,
          isStale: isStale,
        );
      },
      onError: (e, _) => NetworkFailure(cause: e),
    );
  }

  OshiGroup _groupFromRow(OshiGroupRow row) => OshiGroup(
        id: row.id,
        ownerId: row.ownerId,
        name: row.name,
        kind: row.kind,
        color: row.color,
        memo: row.memo,
        imageLocalPath: row.imageLocalPath,
        imageAltText: row.imageAltText,
        isFavorite: row.isFavorite,
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );

  /// [preserveLocalImage] が true のとき image_local_path を companion に
  /// 含めない（`Value.absent`）。リモート pull はサーバーに存在しないこの端末内
  /// 参照を null で上書きしてはならないため（H-04）。ローカル書き込みでは false。
  OshiGroupsCompanion _groupToCompanion(
    OshiGroup g, {
    bool preserveLocalImage = false,
  }) =>
      OshiGroupsCompanion.insert(
        id: g.id,
        ownerId: g.ownerId,
        name: g.name,
        kind: Value(g.kind),
        color: Value(g.color),
        memo: Value(g.memo),
        imageLocalPath:
            preserveLocalImage ? const Value.absent() : Value(g.imageLocalPath),
        imageAltText: Value(g.imageAltText),
        isFavorite: Value(g.isFavorite),
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
        imageLocalPath: row.imageLocalPath,
        imageAltText: row.imageAltText,
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );

  /// [preserveLocalImage] が true のとき image_local_path を companion に
  /// 含めない（`Value.absent`）。リモート pull はサーバーに存在しないこの端末内
  /// 参照を null で上書きしてはならないため（H-04）。ローカル書き込みでは false。
  OshiMembersCompanion _memberToCompanion(
    OshiMember m, {
    bool preserveLocalImage = false,
  }) =>
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
        imageLocalPath:
            preserveLocalImage ? const Value.absent() : Value(m.imageLocalPath),
        imageAltText: Value(m.imageAltText),
        createdAt: m.createdAt.toUtc().toIso8601String(),
        updatedAt: m.updatedAt.toUtc().toIso8601String(),
      );

  OshiAnniversary _anniversaryFromRow(OshiAnniversaryRow row) =>
      OshiAnniversary(
        id: row.id,
        ownerId: row.ownerId,
        groupId: row.groupId,
        memberId: row.memberId,
        label: row.label,
        date: DateTime.parse(row.date),
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );

  OshiAnniversariesCompanion _anniversaryToCompanion(OshiAnniversary a) =>
      OshiAnniversariesCompanion.insert(
        id: a.id,
        ownerId: a.ownerId,
        groupId: a.groupId,
        memberId: Value(a.memberId),
        label: a.label,
        date: _dateText(a.date),
        createdAt: a.createdAt.toUtc().toIso8601String(),
        updatedAt: a.updatedAt.toUtc().toIso8601String(),
      );

  String _dateText(DateTime d) {
    final mo = d.month.toString().padLeft(2, '0');
    final da = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mo-$da';
  }
}
