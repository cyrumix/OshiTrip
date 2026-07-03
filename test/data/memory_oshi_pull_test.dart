import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_pull.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/memory/data/memory_mappers.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// memory/oshi の owner 限定 pull（共通ヘルパ applyPulledRowsInto）の検証（H-02）。
void main() {
  late AppDatabase db;
  late OutboxStore outbox;
  final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    outbox = OutboxStore(db, clock);
  });

  MemoryEntry entry(String id, String owner, String impression) => MemoryEntry(
        id: id,
        genbaId: 'g-$id',
        ownerId: owner,
        impression: impression,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  Future<void> insertEntry(MemoryEntry e) =>
      db.into(db.memoryEntries).insertOnConflictUpdate(entryToCompanion(e));

  test('memory pull: 別ownerの行を消さず、現在ownerの欠落行だけ削除する', () async {
    // user-1 のローカル: e1(同期済), e2(同期済). user-2: e9.
    await insertEntry(entry('e1', 'user-1', 'A'));
    await insertEntry(entry('e2', 'user-1', 'B'));
    await insertEntry(entry('e9', 'user-2', 'other'));

    // リモート（user-1）には e1 のみ存在（e2 は削除済み想定）。
    final remoteRows = [entry('e1', 'user-1', 'A-remote').toJson()];

    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.memoryEntries,
      rows: remoteRows,
      toCompanion: (json) => entryToCompanion(MemoryEntry.fromJson(json)),
      table: db.memoryEntries,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );

    final ids =
        (await db.select(db.memoryEntries).get()).map((r) => r.id).toSet();
    expect(ids, {'e1', 'e9'}); // e2 は削除、e9(別owner) は保持
    final e1 = await (db.select(db.memoryEntries)
          ..where((t) => t.id.equals('e1')))
        .getSingle();
    expect(e1.impression, 'A-remote'); // 取り込み反映
  });

  test('memory pull: 未同期(pending)のローカル行はリモートで上書きしない', () async {
    await insertEntry(entry('e1', 'user-1', 'local-unsynced'));
    // e1 に未同期 Outbox がある。
    await outbox.enqueue(
      OutboxOperation(
        mutationId: 'm-e1',
        ownerId: 'user-1',
        entityTable: SyncEntity.memoryEntries,
        entityId: 'e1',
        opType: OutboxOpType.upsert,
        payload: const {'id': 'e1'},
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );

    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.memoryEntries,
      rows: [entry('e1', 'user-1', 'server-value').toJson()],
      toCompanion: (json) => entryToCompanion(MemoryEntry.fromJson(json)),
      table: db.memoryEntries,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );

    final e1 = await (db.select(db.memoryEntries)
          ..where((t) => t.id.equals('e1')))
        .getSingle();
    expect(e1.impression, 'local-unsynced'); // 上書きされない
  });

  test('pull: 取り込んだ行の version を remote_versions へ保存する', () async {
    final row = entry('e1', 'user-1', 'A').toJson()..['version'] = 7;
    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.memoryEntries,
      rows: [row],
      toCompanion: (json) => entryToCompanion(MemoryEntry.fromJson(json)),
      table: db.memoryEntries,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );

    final rv = await (db.select(db.remoteVersions)
          ..where((t) => t.entityId.equals('e1')))
        .getSingle();
    expect(rv.version, 7);
    expect(rv.ownerId, 'user-1');
    expect(rv.entityTable, SyncEntity.memoryEntries);
  });

  test('pull: 未同期(pending)行は取り込まず版キャッシュも進めない', () async {
    await insertEntry(entry('e1', 'user-1', 'local'));
    await outbox.enqueue(
      OutboxOperation(
        mutationId: 'm-e1',
        ownerId: 'user-1',
        entityTable: SyncEntity.memoryEntries,
        entityId: 'e1',
        opType: OutboxOpType.upsert,
        payload: const {'id': 'e1'},
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
    final row = entry('e1', 'user-1', 'server').toJson()..['version'] = 9;
    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.memoryEntries,
      rows: [row],
      toCompanion: (json) => entryToCompanion(MemoryEntry.fromJson(json)),
      table: db.memoryEntries,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );
    // 版キャッシュは作られない（未同期を上書きしないため）。
    expect(await db.select(db.remoteVersions).get(), isEmpty);
  });

  test('pull: リモート削除を取り込むと版キャッシュも削除する', () async {
    await insertEntry(entry('e1', 'user-1', 'A'));
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-1',
            entityTable: SyncEntity.memoryEntries,
            entityId: 'e1',
            version: 3,
          ),
        );
    // リモートに e1 が無い（削除済み）。
    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.memoryEntries,
      rows: const [],
      toCompanion: (json) => entryToCompanion(MemoryEntry.fromJson(json)),
      table: db.memoryEntries,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );
    expect(await db.select(db.memoryEntries).get(), isEmpty);
    expect(await db.select(db.remoteVersions).get(), isEmpty);
  });

  test('oshi pull: 別ownerのグループを消さない', () async {
    OshiGroupsCompanion group(String id, String owner, String name) =>
        OshiGroupsCompanion.insert(
          id: id,
          ownerId: owner,
          name: name,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        );
    await db
        .into(db.oshiGroups)
        .insertOnConflictUpdate(group('g1', 'user-1', 'A'));
    await db
        .into(db.oshiGroups)
        .insertOnConflictUpdate(group('g9', 'user-2', 'X'));

    // user-1 のリモートは空（g1 は削除済み想定）。
    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.oshiGroups,
      rows: const [],
      toCompanion: (json) => group(
        json['id'] as String,
        json['owner_id'] as String,
        json['name'] as String,
      ),
      table: db.oshiGroups,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
    );

    final ids = (await db.select(db.oshiGroups).get()).map((r) => r.id).toSet();
    expect(ids, {'g9'}); // user-1 の g1 は削除、user-2 の g9 は保持
  });
}
