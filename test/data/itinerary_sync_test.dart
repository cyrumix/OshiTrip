import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_mutation_client.dart';
import 'package:oshi_trip/core/sync/remote_pull.dart';
import 'package:oshi_trip/core/sync/retry_policy.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_mappers.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_repository_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan.dart';
import 'package:sqlite3/open.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// スクリプト可能な擬似リモート（sync_engine_test と同型）。
class _FakeRemote implements RemoteMutationClient {
  final List<OutboxOperation> applied = [];

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    applied.add(op);
    return const Ok(null);
  }
}

/// enqueue が必ず失敗する Outbox（原子性テスト用の失敗注入）。
class _ThrowingOutboxStore extends OutboxStore {
  _ThrowingOutboxStore(super.db, super.clock);

  @override
  Future<void> enqueue(OutboxOperation op) async {
    throw Exception('injected enqueue failure');
  }
}

/// file-backed な AppDatabase を開く（本当の close/reopen 検証用）。
/// Windows では sqlite3.dll が PATH に無い場合があるため winsqlite3.dll へ
/// フォールバックする（test_db.dart と同じ方針）。
AppDatabase openFileDb(File file) {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () {
      try {
        return DynamicLibrary.open('sqlite3.dll');
      } catch (_) {
        return DynamicLibrary.open('winsqlite3.dll');
      }
    });
  }
  return AppDatabase(NativeDatabase(file));
}

void main() {
  final clock = FixedClock(DateTime(2026, 7, 6, 12));

  GenbaRepositoryImpl genbaRepo(
    AppDatabase db,
    OutboxStore outbox,
    SyncEngine engine,
    String owner,
  ) =>
      GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      );

  ItineraryRepositoryImpl itinRepo(
    AppDatabase db,
    OutboxStore outbox,
    SyncEngine engine,
    String owner,
  ) =>
      ItineraryRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      );

  SyncEngine offlineEngine(OutboxStore outbox) => SyncEngine(
        store: outbox,
        snapshotResolver: () => null, // オフライン: 送信先なし
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
        clock: clock,
      );

  test('Outbox enqueue が失敗すると、ローカル行もOutboxも両方ロールバックされる（原子性）', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final normal = OutboxStore(db, clock);
    final engine = offlineEngine(normal);
    addTearDown(engine.dispose);

    // 現場は通常の Outbox で用意する（親所有権検証を通すため）。
    await genbaRepo(db, normal, engine, 'user-1').upsertGenba(
      makeGenba(
        id: 'genba-1',
        ownerId: 'user-1',
        eventDate: DateTime(2026, 8, 1),
      ),
    );

    // enqueue が必ず失敗する Outbox を使う itinerary repo。
    final throwing = _ThrowingOutboxStore(db, clock);
    final repo = itinRepo(db, throwing, engine, 'user-1');
    final res = await repo.upsertPlan(makeItineraryPlan());
    expect(res.isOk, isFalse);
    expect(res.failureOrNull, isA<StorageFailure>());

    // 行は書かれず、Outbox（itinerary_plans）も積まれない（transaction rollback）。
    expect(await db.select(db.itineraryPlans).get(), isEmpty);
    final ops = await OutboxStore(db, clock).pendingOps(ownerId: 'user-1');
    expect(
      ops.where((o) => o.entityTable == SyncEntity.itineraryPlans),
      isEmpty,
    );
  });

  test('本当の再起動同期: file-backed DBへオフライン保存→完全close→再open→drainで送信', () async {
    // 一時ディレクトリ + DBファイルを用意（テスト後に削除する）。
    final dir = Directory.systemTemp.createTempSync('itinerary_sync');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final dbFile = File('${dir.path}/oshi_itinerary_test.sqlite');

    // --- 1) file-backed DB へオフライン保存する（送信先なし=pendingに積む）----
    final db1 = openFileDb(dbFile);
    final outbox1 = OutboxStore(db1, clock);
    final engine1 = offlineEngine(outbox1);
    await genbaRepo(db1, outbox1, engine1, 'user-1').upsertGenba(
      makeGenba(
        id: 'genba-1',
        ownerId: 'user-1',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    final repo1 = itinRepo(db1, outbox1, engine1, 'user-1');
    expect(
      (await repo1.upsertPlan(makeItineraryPlan(title: '未同期プラン'))).isOk,
      isTrue,
    );
    expect(
      (await repo1.upsertSpot(makeItinerarySpot(name: '未同期スポット'))).isOk,
      isTrue,
    );
    final pendingBefore = await outbox1.pendingOps(ownerId: 'user-1');
    expect(
      pendingBefore.where(
        (o) =>
            o.entityTable == SyncEntity.itineraryPlans ||
            o.entityTable == SyncEntity.itinerarySpots,
      ),
      hasLength(2),
    );

    // --- 2) DB・SyncEngine を完全に close/dispose する（アプリ終了相当）--------
    engine1.dispose();
    await db1.close();

    // --- 3) 同じDBファイルを再open する（アプリ再起動相当）--------------------
    final db2 = openFileDb(dbFile);
    final outbox2 = OutboxStore(db2, clock);
    // 保存内容はファイルから復元される。
    final repo2 = itinRepo(db2, outbox2, offlineEngine(outbox2), 'user-1');
    final plans = await repo2.watchByGenbaId('genba-1').first;
    expect(plans, hasLength(1));
    expect(plans.single.plan.title, '未同期プラン');
    expect(plans.single.spots.single.name, '未同期スポット');
    // 未同期 op もファイルから復元されている。
    expect(
      (await outbox2.pendingOps(ownerId: 'user-1')).where(
        (o) =>
            o.entityTable == SyncEntity.itineraryPlans ||
            o.entityTable == SyncEntity.itinerarySpots,
      ),
      hasLength(2),
    );

    // --- 4) 新しい OutboxStore/SyncEngine で drain → リモートへ送信 -----------
    final remote = _FakeRemote();
    final online = SyncEngine(
      store: outbox2,
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-1', remote: remote),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      clock: clock,
      retryPolicy: const RetryPolicy(
        base: Duration.zero,
        maxInterval: Duration.zero,
        jitterRatio: 0,
      ),
      randomJitter: () => 0.5,
    );
    await online.drain();

    // --- 5) pending 解消 + FakeRemote へ反映を確認 --------------------------
    expect(await outbox2.pendingOps(ownerId: 'user-1'), isEmpty);
    final appliedTables = remote.applied.map((o) => o.entityTable).toSet();
    expect(
      appliedTables,
      containsAll(<String>[
        SyncEntity.itineraryPlans,
        SyncEntity.itinerarySpots,
      ]),
    );

    online.dispose();
    await db2.close();
  });

  test('サーバー採用（adopt相当）のpullは端末内カバー画像パスを保持する', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final outbox = OutboxStore(db, clock);

    // 端末内カバー画像参照つきで保存済み。
    await db.into(db.itineraryPlans).insertOnConflictUpdate(
          planToCompanion(
            makeItineraryPlan(coverImageLocalPath: 'covers/a.jpg'),
          ),
        );

    // サーバー行（cover_image_local_path 列を持たない）を、adoptServerEntity と
    // 同じ preserveLocalImage: true + forceEntityIds で強制適用する。
    final serverRow = makeItineraryPlan(title: 'サーバー採用版').toJson()
      ..remove('cover_image_local_path');
    serverRow['version'] = 5;
    await applyPulledRowsInto(
      db: db,
      outbox: outbox,
      owner: 'user-1',
      tableName: SyncEntity.itineraryPlans,
      rows: [serverRow],
      toCompanion: (json) => planToCompanion(
        ItineraryPlan.fromJson(json),
        preserveLocalImage: true,
      ),
      table: db.itineraryPlans,
      idColumn: (t) => t.id,
      ownerColumn: (t) => t.ownerId,
      idOf: (r) => r.id,
      forceEntityIds: {'plan-1'},
    );

    final row = await (db.select(db.itineraryPlans)
          ..where((t) => t.id.equals('plan-1')))
        .getSingle();
    expect(row.title, 'サーバー採用版'); // サーバー列は更新される
    expect(row.coverImageLocalPath, 'covers/a.jpg'); // 端末内pathは保持
  });
}
