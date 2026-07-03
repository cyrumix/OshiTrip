import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// schema v1 → v2 の実マイグレーション検証（C-01 / M-04）。
///
/// 実際に user_version=1 の SQLite ファイルを作り、AppDatabase(v2) で開いて
/// onUpgrade を走らせ、次を確認する:
/// - 既存の genba / 子データ / memory / oshi / Outbox を失わない
/// - owner 情報を持たない旧 form_drafts だけが安全に破棄される
/// - owner 複合キーの form_drafts と必要な index が作られる
/// - マイグレーション失敗を成功扱いにしない
void main() {
  DynamicLibrary openOnWindows() {
    try {
      return DynamicLibrary.open('sqlite3.dll');
    } catch (_) {
      return DynamicLibrary.open('winsqlite3.dll');
    }
  }

  setUp(() {
    if (Platform.isWindows) {
      open.overrideFor(OperatingSystem.windows, openOnWindows);
    }
  });

  /// v1 の全テーブル DDL（form_drafts は owner_id を持たない旧形。index なし）。
  /// [includeTickets] を false にすると tickets を作らず、onUpgrade の
  /// index 作成を失敗させて「失敗が握り潰されない」ことを検証できる。
  List<String> v1Ddl({bool includeTickets = true}) => [
        '''CREATE TABLE genbas (
          id TEXT NOT NULL PRIMARY KEY, owner_id TEXT NOT NULL,
          artist_name TEXT NOT NULL, title TEXT NOT NULL, event_date TEXT NOT NULL,
          oshi_group_id TEXT, oshi_member_ids TEXT NOT NULL DEFAULT '[]',
          venue TEXT, door_time_minutes INTEGER, start_time_minutes INTEGER,
          end_time_minutes INTEGER, performance_type TEXT, performance_id TEXT,
          is_expedition INTEGER, transport_requirement TEXT NOT NULL DEFAULT 'unknown',
          lodging_requirement TEXT NOT NULL DEFAULT 'unknown',
          is_canceled INTEGER NOT NULL DEFAULT 0, manual_ended_at TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        if (includeTickets)
          '''CREATE TABLE tickets (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          acquisition_status TEXT NOT NULL DEFAULT 'not_applied',
          payment_status TEXT NOT NULL DEFAULT 'unpaid',
          issuance_status TEXT NOT NULL DEFAULT 'not_issued',
          seat TEXT, entry_number TEXT, gate TEXT, url TEXT, image_path TEXT,
          image_local_path TEXT, memo TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE transports (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          direction TEXT NOT NULL DEFAULT 'outbound', method TEXT, from_place TEXT,
          to_place TEXT, depart_at TEXT, arrive_at TEXT, reservation_number TEXT,
          url TEXT, memo TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE lodgings (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          name TEXT, checkin_date TEXT, checkout_date TEXT, address TEXT,
          reservation_number TEXT, url TEXT, memo TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE todos (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          name TEXT NOT NULL, due_date TEXT, is_done INTEGER NOT NULL DEFAULT 0,
          assignee TEXT, priority TEXT NOT NULL DEFAULT 'normal', memo TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE genba_memos (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          category TEXT NOT NULL, body TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
          UNIQUE (genba_id, category))''',
        '''CREATE TABLE memory_entries (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL UNIQUE, owner_id TEXT NOT NULL,
          impression TEXT NOT NULL DEFAULT '', best_moment TEXT NOT NULL DEFAULT '',
          mc_notes TEXT NOT NULL DEFAULT '', seat_view TEXT NOT NULL DEFAULT '',
          tags TEXT NOT NULL DEFAULT '[]', declined_fields TEXT NOT NULL DEFAULT '[]',
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE memory_photos (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          local_path TEXT, storage_path TEXT,
          upload_status TEXT NOT NULL DEFAULT 'local_only', caption TEXT,
          is_cover INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE setlist_items (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          position INTEGER NOT NULL, song_title TEXT NOT NULL, note TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE goods_items (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          name TEXT NOT NULL, price INTEGER, quantity INTEGER NOT NULL DEFAULT 1,
          memo TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE visited_places (
          id TEXT NOT NULL PRIMARY KEY, genba_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          name TEXT NOT NULL, category TEXT NOT NULL DEFAULT 'spot', memo TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE oshi_groups (
          id TEXT NOT NULL PRIMARY KEY, owner_id TEXT NOT NULL, name TEXT NOT NULL,
          kind TEXT, color TEXT, memo TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE oshi_members (
          id TEXT NOT NULL PRIMARY KEY, group_id TEXT NOT NULL, owner_id TEXT NOT NULL,
          name TEXT NOT NULL, rank TEXT NOT NULL DEFAULT 'oshi', color TEXT,
          oshi_since TEXT, birthday TEXT, memo TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE outbox_ops (
          mutation_id TEXT NOT NULL PRIMARY KEY, owner_id TEXT NOT NULL,
          entity_table TEXT NOT NULL, entity_id TEXT NOT NULL, op_type TEXT NOT NULL,
          payload TEXT NOT NULL DEFAULT '{}', status TEXT NOT NULL DEFAULT 'pending',
          attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
        '''CREATE TABLE app_kvs (
          key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)''',
        // v1 の form_drafts は owner_id を持たず PK は key のみ。
        '''CREATE TABLE form_drafts (
          key TEXT NOT NULL PRIMARY KEY, payload TEXT NOT NULL, updated_at TEXT NOT NULL)''',
      ];

  const seed = [
    "INSERT INTO genbas (id, owner_id, artist_name, title, event_date, "
        "oshi_member_ids, transport_requirement, lodging_requirement, "
        "is_canceled, created_at, updated_at) VALUES "
        "('g-1','user-1','A','T','2026-08-01','[]','unknown','unknown',0,"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
    "INSERT INTO todos (id, genba_id, owner_id, name, is_done, priority, "
        "sort_order, created_at, updated_at) VALUES "
        "('td-1','g-1','user-1','買い出し',0,'normal',0,"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
    "INSERT INTO memory_entries (id, genba_id, owner_id, impression, "
        "best_moment, mc_notes, seat_view, tags, declined_fields, "
        "created_at, updated_at) VALUES "
        "('me-1','g-1','user-1','最高だった','','','','[]','[]',"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
    "INSERT INTO oshi_groups (id, owner_id, name, created_at, updated_at) "
        "VALUES ('og-1','user-1','推しグループ',"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
    "INSERT INTO outbox_ops (mutation_id, owner_id, entity_table, entity_id, "
        "op_type, payload, status, attempts, created_at, updated_at) VALUES "
        "('op-1','user-1','genbas','g-1','upsert','{}','pending',0,"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
    // owner 情報を持たない旧下書き（移行時に破棄されるべき）。
    "INSERT INTO form_drafts (key, payload, updated_at) VALUES "
        "('genba_form_new','{\"title\":\"旧下書き\"}','2026-01-01T00:00:00.000Z')",
  ];

  void writeV1Db(String path, {bool includeTickets = true}) {
    final raw = sqlite.sqlite3.open(path);
    for (final ddl in v1Ddl(includeTickets: includeTickets)) {
      raw.execute(ddl);
    }
    for (final sql in seed) {
      raw.execute(sql);
    }
    raw.execute('PRAGMA user_version = 1;');
    raw.dispose();
  }

  /// v2 スキーマ DDL（v1 と同じだが form_drafts は owner 複合キー。
  /// next_retry_at / remote_versions はまだ無い）。
  List<String> v2Ddl() {
    final tables = v1Ddl().toList();
    // v1 の form_drafts（最後の要素）を v2 形へ差し替える。
    tables.removeLast();
    tables.add('''CREATE TABLE form_drafts (
      owner_id TEXT NOT NULL, key TEXT NOT NULL, payload TEXT NOT NULL,
      updated_at TEXT NOT NULL, PRIMARY KEY (owner_id, key))''');
    return tables;
  }

  void writeV2Db(String path) {
    final raw = sqlite.sqlite3.open(path);
    for (final ddl in v2Ddl()) {
      raw.execute(ddl);
    }
    // form_drafts 以外の seed を投入（最後の要素は v1 form_drafts なので除く）。
    for (final sql in seed.sublist(0, seed.length - 1)) {
      raw.execute(sql);
    }
    // v2 の owner 付き下書き（v2→v3 では保持されるべき）。
    raw.execute(
      "INSERT INTO form_drafts (owner_id, key, payload, updated_at) VALUES "
      "('user-1','genba_form_new','{}','2026-01-01T00:00:00.000Z')",
    );
    raw.execute('PRAGMA user_version = 2;');
    raw.dispose();
  }

  Future<void> expectV3Artifacts(AppDatabase db) async {
    // remote_versions テーブルが作られ使える。
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-1',
            entityTable: 'genbas',
            entityId: 'g-1',
            version: 5,
          ),
        );
    final rv = await db.select(db.remoteVersions).get();
    expect(rv.single.version, 5);

    // outbox_ops.next_retry_at 列が使える（既存行に設定・読み出しできる）。
    await db.customStatement(
      "UPDATE outbox_ops SET next_retry_at = '2026-07-02T13:00:00.000Z' "
      "WHERE mutation_id = 'op-1'",
    );
    final op = await (db.select(db.outboxOps)
          ..where((t) => t.mutationId.equals('op-1')))
        .getSingle();
    expect(op.nextRetryAt, '2026-07-02T13:00:00.000Z');

    // v3 の index が作られている。
    final indexNames = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(indexNames, contains('idx_outbox_ops_owner_retry'));
    expect(indexNames, contains('idx_remote_versions_owner'));
  }

  test('v1→v3: 既存データ保持・owner無し旧下書き破棄・index・v3成果物', () async {
    final dir = Directory.systemTemp.createTempSync('oshi_mig_v1');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'v1.sqlite');
    writeV1Db(path);

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    // 最初のクエリで onUpgrade が走る。既存データが保持されている。
    expect((await db.select(db.genbas).get()).map((g) => g.id), ['g-1']);
    expect((await db.select(db.todos).get()).map((t) => t.id), ['td-1']);
    final mem1 = (await db.select(db.memoryEntries).get()).single;
    expect(mem1.impression, '最高だった');
    expect((await db.select(db.oshiGroups).get()).map((g) => g.id), ['og-1']);
    final ob1 = (await db.select(db.outboxOps).get()).map((o) => o.mutationId);
    expect(ob1, ['op-1']);

    // owner 情報を持たない旧下書きは安全に破棄されている。
    expect(await db.select(db.formDrafts).get(), isEmpty);

    // owner 複合キーの form_drafts として使える。
    await db.into(db.formDrafts).insertOnConflictUpdate(
          FormDraftsCompanion.insert(
            ownerId: 'user-1',
            key: 'genba_form_new',
            payload: '{}',
            updatedAt: '2026-07-02T00:00:00.000Z',
          ),
        );
    expect((await db.select(db.formDrafts).get()).length, 1);

    final indexNames = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(indexNames, contains('idx_genbas_owner_date'));
    expect(indexNames, contains('idx_oshi_members_group'));

    await expectV3Artifacts(db);
  });

  test('v2→v3: owner付き下書きと既存Outboxを保持し、v3成果物を作る', () async {
    final dir = Directory.systemTemp.createTempSync('oshi_mig_v2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'v2.sqlite');
    writeV2Db(path);

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    // v2→v3 では form_drafts は作り直さない（owner 付き下書きは保持される）。
    final drafts = await db.select(db.formDrafts).get();
    expect(drafts.map((d) => d.ownerId), ['user-1']);
    // 既存 Outbox を失わない。
    final ob = (await db.select(db.outboxOps).get()).map((o) => o.mutationId);
    expect(ob, ['op-1']);
    // 既存の genba/memory/oshi も保持。
    expect((await db.select(db.genbas).get()).map((g) => g.id), ['g-1']);
    final mem = (await db.select(db.memoryEntries).get()).single;
    expect(mem.impression, '最高だった');

    await expectV3Artifacts(db);
  });

  test('マイグレーション失敗は握り潰さず例外として伝播する', () async {
    final dir = Directory.systemTemp.createTempSync('oshi_mig_fail');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 'v1_broken.sqlite');
    // tickets を欠いた壊れた v1。onUpgrade の index 作成が失敗するはず。
    writeV1Db(path, includeTickets: false);

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    // 最初のDB利用で onUpgrade が走り、tickets index 作成で失敗する。
    await expectLater(
      db.select(db.genbas).get(),
      throwsA(anything),
    );
  });
}
