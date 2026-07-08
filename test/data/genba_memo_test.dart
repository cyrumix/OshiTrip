import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:path/path.dart' as p;

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// メモの複数登録化（§7.7 / Phase 3前調整 点1）:
/// 同一種類の複数保持・並び替え・v11→v12 移行（title=種類名・ユニーク撤廃）。
void main() {
  GenbaRepositoryImpl repoFor(AppDatabase db, Clock clock) {
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    return GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
  }

  GenbaMemo memo(
    String id, {
    MemoCategory category = MemoCategory.free,
    int sortOrder = 0,
    String title = 'メモ',
  }) =>
      GenbaMemo(
        id: id,
        genbaId: 'genba-1',
        ownerId: 'user-1',
        category: category,
        title: title,
        body: '本文$id',
        sortOrder: sortOrder,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  test('reorderMemos: 指定順に sort_order が振り直され、中身は変わらない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = repoFor(db, FixedClock(DateTime(2026, 7, 6, 12)));
    await repo.upsertGenba(
      makeGenba(
        id: 'genba-1',
        ownerId: 'user-1',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    await repo.upsertMemo(memo('a', sortOrder: 0));
    await repo.upsertMemo(memo('b', sortOrder: 1));
    await repo.upsertMemo(memo('c', sortOrder: 2));

    final res = await repo
        .reorderMemos(genbaId: 'genba-1', orderedIds: ['c', 'a', 'b']);
    expect(res.isOk, isTrue);

    final rows = await db.select(db.genbaMemos).get();
    final byId = {for (final r in rows) r.id: r};
    expect(byId['c']!.sortOrder, 0);
    expect(byId['a']!.sortOrder, 1);
    expect(byId['b']!.sortOrder, 2);
    // 本文は不変。
    expect(byId['a']!.body, '本文a');
  });

  test('同一種類の複数メモを保持し、sortedMemos で並ぶ', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = repoFor(db, FixedClock(DateTime(2026, 7, 6, 12)));
    await repo.upsertGenba(
      makeGenba(
        id: 'genba-1',
        ownerId: 'user-1',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    await repo
        .upsertMemo(memo('m1', category: MemoCategory.goods, sortOrder: 1));
    await repo
        .upsertMemo(memo('m2', category: MemoCategory.goods, sortOrder: 0));

    final aggregate = (await repo.watchAll().first).first;
    expect(
      aggregate.memos.where((m) => m.category == MemoCategory.goods),
      hasLength(2),
    );
    expect(aggregate.sortedMemos.map((m) => m.id), ['m2', 'm1']);
  });

  test('v11→v12 マイグレーション: 既存メモの title が種類名になり、同一種類の複数追加が可能', () async {
    final dir = Directory.systemTemp.createTempSync('oshitrip_memo_mig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'app.sqlite'));

    // --- v11 相当（title/sort_order 無し・{genba_id,category} ユニーク） ---
    {
      final db = openFileTestDb(file);
      await db.customStatement('SELECT 1');
      await db.customStatement('DROP TABLE genba_memos');
      await db.customStatement(
        'CREATE TABLE genba_memos ('
        'id TEXT NOT NULL PRIMARY KEY, '
        'genba_id TEXT NOT NULL, '
        'owner_id TEXT NOT NULL, '
        'category TEXT NOT NULL, '
        "body TEXT NOT NULL DEFAULT '', "
        'created_at TEXT NOT NULL, '
        'updated_at TEXT NOT NULL, '
        'UNIQUE (genba_id, category))',
      );
      await db.customStatement(
        'INSERT INTO genba_memos (id, genba_id, owner_id, category, body, '
        "created_at, updated_at) VALUES ('mm','g','u','meetup','西口集合',"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
      );
      await db.customStatement('PRAGMA user_version = 11');
      await db.close();
    }

    // --- 再open → onUpgrade(11,12) ---
    final db = openFileTestDb(file);
    addTearDown(db.close);
    await db.customStatement('SELECT 1');

    // 既存メモは消えず、title は種類名（集合場所）に。
    final rows = await db.select(db.genbaMemos).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, '集合場所');
    expect(rows.single.body, '西口集合');
    expect(rows.single.sortOrder, 0);

    // ユニーク制約が外れ、同一種類の2件目を追加できる。
    await db.into(db.genbaMemos).insert(
          GenbaMemosCompanion.insert(
            id: 'mm2',
            genbaId: 'g',
            ownerId: 'u',
            category: 'meetup',
            title: const Value('二次会'),
            createdAt: '2026-01-02T00:00:00.000Z',
            updatedAt: '2026-01-02T00:00:00.000Z',
          ),
        );
    expect(await db.select(db.genbaMemos).get(), hasLength(2));
  });
}
