import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/db/local_data_purge.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// C-01 必須テスト: アカウント削除後のローカル消去。
///
/// [purgeLocalDataForOwner] が対象ownerの行だけを全テーブルから物理削除し、
/// 他ownerの行には一切触れないことを検証する。
void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
  });

  GenbaRepositoryImpl genbaRepoFor(String owner) {
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
      ownerIdResolver: () => owner,
      remoteResolver: () => null,
    );
  }

  OshiRepositoryImpl oshiRepoFor(String owner) {
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    return OshiRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => owner,
    );
  }

  test('対象ownerの現場・Todo・Outboxが物理削除され、別ownerは影響を受けない', () async {
    final repoA = genbaRepoFor('user-A');
    final repoB = genbaRepoFor('user-B');

    await repoA.upsertGenba(
      makeGenba(
        id: 'genba-a',
        ownerId: 'user-A',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    await repoA.upsertTodo(
      makeTodo(id: 'todo-a', genbaId: 'genba-a', ownerId: 'user-A'),
    );
    await repoB.upsertGenba(
      makeGenba(
        id: 'genba-b',
        ownerId: 'user-B',
        eventDate: DateTime(2026, 8, 2),
      ),
    );

    // 版キャッシュも owner ごとに用意しておく。
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-A',
            entityTable: 'genbas',
            entityId: 'genba-a',
            version: 3,
          ),
        );
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-B',
            entityTable: 'genbas',
            entityId: 'genba-b',
            version: 7,
          ),
        );

    await purgeLocalDataForOwner(db, 'user-A');

    final remainingGenbas = await db.select(db.genbas).get();
    expect(remainingGenbas.map((g) => g.id), ['genba-b']);
    final remainingTodos = await db.select(db.todos).get();
    expect(remainingTodos, isEmpty);

    final outboxRows = await db.select(db.outboxOps).get();
    expect(outboxRows.every((o) => o.ownerId == 'user-B'), isTrue);
    expect(outboxRows, isNotEmpty); // user-B の Outbox は残っている

    // remote_versions も対象ownerだけ削除され、他ownerは残る。
    final versions = await db.select(db.remoteVersions).get();
    expect(versions.map((v) => v.ownerId), ['user-B']);
  });

  test('対象ownerの推し・下書きも削除され、別ownerは残る', () async {
    final oshiA = oshiRepoFor('user-A');
    final oshiB = oshiRepoFor('user-B');
    final now = fixedCreatedAt;

    await oshiA.upsertGroup(
      OshiGroup(
        id: 'group-a',
        ownerId: 'user-A',
        name: 'グループA',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await oshiB.upsertGroup(
      OshiGroup(
        id: 'group-b',
        ownerId: 'user-B',
        name: 'グループB',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.formDrafts).insertOnConflictUpdate(
          FormDraftsCompanion.insert(
            ownerId: 'user-A',
            key: 'genba_form_new',
            payload: '{}',
            updatedAt: '2026-07-02T00:00:00Z',
          ),
        );
    await db.into(db.formDrafts).insertOnConflictUpdate(
          FormDraftsCompanion.insert(
            ownerId: 'user-B',
            key: 'genba_form_new',
            payload: '{}',
            updatedAt: '2026-07-02T00:00:00Z',
          ),
        );

    await purgeLocalDataForOwner(db, 'user-A');

    final groups = await db.select(db.oshiGroups).get();
    expect(groups.map((g) => g.id), ['group-b']);
    final drafts = await db.select(db.formDrafts).get();
    expect(drafts.map((d) => d.ownerId), ['user-B']);
  });
}
