import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/db/local_data_purge.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_mutation_client.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/auth/domain/auth_repository.dart';
import 'package:oshi_trip/features/genba/data/genba_mappers.dart';
import 'package:oshi_trip/features/settings/application/account_controller.dart';
import 'package:oshi_trip/features/settings/domain/account_repository.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// 呼び出し結果を固定で返す擬似 [AccountRepository]。呼ばれたかを記録する。
class _FakeAccountRepo implements AccountRepository {
  _FakeAccountRepo(this.result, {this.onCall});
  final Result<void> result;
  final void Function()? onCall;
  bool called = false;

  @override
  Future<Result<void>> deleteAccount() async {
    called = true;
    onCall?.call();
    return result;
  }
}

/// apply が [gate] 完了までブロックする擬似リモート。
class _GatedRemote implements RemoteMutationClient {
  _GatedRemote(this.gate);
  final Future<void> gate;
  final List<OutboxOperation> applied = [];
  final Completer<void> _started = Completer<void>();
  Future<void> get started => _started.future;

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    if (!_started.isCompleted) _started.complete();
    await gate;
    applied.add(op);
    return const Ok(null);
  }
}

/// 即時成功する擬似リモート。
class _InstantRemote implements RemoteMutationClient {
  final List<OutboxOperation> applied = [];

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    applied.add(op);
    return const Ok(null);
  }
}

void main() {
  late AppDatabase db;
  late Directory imgDir;
  final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));

  OutboxOperation opFor(String owner, String id) => OutboxOperation(
        mutationId: id,
        ownerId: owner,
        entityTable: SyncEntity.genbas,
        entityId: 'entity-$id',
        opType: OutboxOpType.upsert,
        payload: {'id': 'entity-$id'},
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<void> seedGenba(String id, String owner) => db
      .into(db.genbas)
      .insertOnConflictUpdate(
        genbaToCompanion(
          makeGenba(id: id, ownerId: owner, eventDate: DateTime(2026, 8, 1)),
        ),
      );

  Future<ProviderContainer> containerFor({
    required Result<void> serverResult,
    required String ownerId,
    SyncEngine? syncEngine,
    void Function()? onServerCall,
  }) async {
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        accountRepositoryProvider.overrideWithValue(
          _FakeAccountRepo(serverResult, onCall: onServerCall),
        ),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(
            AppUser(id: ownerId, email: '$ownerId@example.com', isDemo: true),
          ),
        ),
        imageStoreProvider.overrideWithValue(ImageStore(imgDir)),
        if (syncEngine != null)
          syncEngineProvider.overrideWithValue(syncEngine),
      ],
    );
    addTearDown(container.dispose);
    // 認証状態を解決してから（localDataScope が owner を確定してから）使う。
    await container.read(currentUserProvider.future);
    return container;
  }

  /// engine が paused でない（新規 drain が走る）ことを、op を1件流して確認する。
  Future<bool> engineCanDrain(
    SyncEngine engine,
    OutboxStore store,
    _InstantRemote remote,
  ) async {
    await store.enqueue(opFor('user-A', 'probe-${remote.applied.length}'));
    await engine.drain();
    return remote.applied.isNotEmpty;
  }

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    imgDir = Directory.systemTemp.createTempSync('oshi_acct_img');
    addTearDown(() {
      if (imgDir.existsSync()) imgDir.deleteSync(recursive: true);
    });
  });

  test('サーバー削除失敗時はローカルデータを削除せず、マーカーも残さない', () async {
    await seedGenba('g-a', 'user-A');
    final container = await containerFor(
      serverResult: const Err(NetworkFailure()),
      ownerId: 'user-A',
    );

    final failure = await container
        .read(accountControllerProvider.notifier)
        .deleteAccount();

    expect(failure, isA<NetworkFailure>());
    // ローカルは無傷。
    expect(await db.select(db.genbas).get(), hasLength(1));
    // 未完了マーカーも書かれていない。
    final marker = await DriftKvStore(db).get(KvKeys.pendingAccountPurge);
    expect(marker, isNull);
    // AsyncLoading のまま固まらない。
    expect(container.read(accountControllerProvider).isLoading, isFalse);
  });

  test('サーバー削除成功時は対象ownerのみ削除し、他ownerは残す。マーカーも消える', () async {
    await seedGenba('g-a', 'user-A');
    await seedGenba('g-b', 'user-B');
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-A',
            entityTable: 'genbas',
            entityId: 'g-a',
            version: 2,
          ),
        );
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-B',
            entityTable: 'genbas',
            entityId: 'g-b',
            version: 4,
          ),
        );
    final container = await containerFor(
      serverResult: const Ok(null),
      ownerId: 'user-A',
    );

    final failure = await container
        .read(accountControllerProvider.notifier)
        .deleteAccount();

    expect(failure, isNull);
    final remaining = await db.select(db.genbas).get();
    expect(remaining.map((g) => g.id), ['g-b']); // user-B は残る
    // 版キャッシュも対象ownerだけ削除。
    final versions = await db.select(db.remoteVersions).get();
    expect(versions.map((v) => v.ownerId), ['user-B']);
    // 完了したのでマーカーは消えている。
    final marker = await DriftKvStore(db).get(KvKeys.pendingAccountPurge);
    expect(marker, isNull);
    expect(container.read(accountControllerProvider).isLoading, isFalse);
  });

  test('ローカルpurge失敗時: 失敗を返し、AsyncLoadingで固まらず、再試行用マーカーを残す', () async {
    await seedGenba('g-a', 'user-A');
    await seedGenba('g-b', 'user-B');
    final container = await containerFor(
      serverResult: const Ok(null),
      ownerId: 'user-A',
    );

    // purge は form_drafts の削除で終わる。テーブルを落として purge を失敗
    // させる（サーバー削除は成功済みの状態を再現）。
    await db.customStatement('DROP TABLE form_drafts');

    final failure = await container
        .read(accountControllerProvider.notifier)
        .deleteAccount();

    // 失敗として通知され、成功扱いにならない。
    expect(failure, isNotNull);
    // AsyncLoading のまま残らない。
    expect(container.read(accountControllerProvider).isLoading, isFalse);
    // サーバー削除済み・ローカル未完了を示すマーカーが残る（次回起動で再試行）。
    final marker = await DriftKvStore(db).get(KvKeys.pendingAccountPurge);
    expect(marker, 'user-A');
    // 他 owner のデータは変更されない。
    final bRows = await (db.select(db.genbas)
          ..where((t) => t.ownerId.equals('user-B')))
        .get();
    expect(bRows, hasLength(1));
  });

  test('次回起動の再試行: resumePendingAccountPurgeが対象ownerのみ消しマーカーを消す', () async {
    await seedGenba('g-a', 'user-A');
    await seedGenba('g-b', 'user-B');
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-A',
            entityTable: 'genbas',
            entityId: 'g-a',
            version: 1,
          ),
        );
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-B',
            entityTable: 'genbas',
            entityId: 'g-b',
            version: 1,
          ),
        );
    await DriftKvStore(db).put(KvKeys.pendingAccountPurge, 'user-A');

    await resumePendingAccountPurge(db);

    final remaining = await db.select(db.genbas).get();
    expect(remaining.map((g) => g.id), ['g-b']); // user-A のみ削除
    // 版キャッシュも起動時 purge 再試行で対象ownerだけ消える。
    final versions = await db.select(db.remoteVersions).get();
    expect(versions.map((v) => v.ownerId), ['user-B']);
    final marker = await DriftKvStore(db).get(KvKeys.pendingAccountPurge);
    expect(marker, isNull); // 完了してマーカーは消える
  });

  test('マーカー未設定なら resumePendingAccountPurge は何もしない', () async {
    await seedGenba('g-a', 'user-A');
    await resumePendingAccountPurge(db);
    expect(await db.select(db.genbas).get(), hasLength(1));
  });

  test('実行中のOutbox drain完了までサーバー削除を開始しない（C-01: 削除も認証切替）', () async {
    await seedGenba('g-a', 'user-A');
    final store = OutboxStore(db, clock);
    await store.enqueue(opFor('user-A', 'inflight-1'));

    final gate = Completer<void>();
    final gated = _GatedRemote(gate.future);
    final engine = SyncEngine(
      store: store,
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-A', remote: gated),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);

    final container = await containerFor(
      serverResult: const Ok(null),
      ownerId: 'user-A',
      syncEngine: engine,
    );
    final repo = container.read(accountRepositoryProvider) as _FakeAccountRepo;

    // drain を in-flight にする（apply が gate 待ちで止まる）。
    final draining = engine.drain();
    await gated.started;

    // 削除を開始する。pause により in-flight drain の完了まで待つはず。
    final deleting =
        container.read(accountControllerProvider.notifier).deleteAccount();

    // drain がまだ終わっていないので、サーバー削除は開始されていない。
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.called, isFalse);

    // drain を完了させると、サーバー削除が進む。
    gate.complete();
    await draining;
    final failure = await deleting;

    expect(failure, isNull);
    expect(gated.applied, hasLength(1)); // drain は削除前に完了している
    expect(repo.called, isTrue);
    // ローカルも削除済み。
    expect(await db.select(db.genbas).get(), isEmpty);
  });

  test('サーバー削除失敗でも SyncEngine は paused のまま残らない', () async {
    await seedGenba('g-a', 'user-A');
    final store = OutboxStore(db, clock);
    final remote = _InstantRemote();
    final engine = SyncEngine(
      store: store,
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-A', remote: remote),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);

    final container = await containerFor(
      serverResult: const Err(NetworkFailure()),
      ownerId: 'user-A',
      syncEngine: engine,
    );

    final failure = await container
        .read(accountControllerProvider.notifier)
        .deleteAccount();
    expect(failure, isA<NetworkFailure>());

    // paused のまま残っていないこと（新規 drain が走る）を確認する。
    expect(await engineCanDrain(engine, store, remote), isTrue);
  });

  test('ローカルpurge失敗でも SyncEngine は paused のまま残らない', () async {
    await seedGenba('g-a', 'user-A');
    final store = OutboxStore(db, clock);
    final remote = _InstantRemote();
    final engine = SyncEngine(
      store: store,
      snapshotResolver: () =>
          SyncAuthSnapshot(ownerId: 'user-A', remote: remote),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);

    final container = await containerFor(
      serverResult: const Ok(null),
      ownerId: 'user-A',
      syncEngine: engine,
    );

    // purge を失敗させる（form_drafts を落とす）。
    await db.customStatement('DROP TABLE form_drafts');

    final failure = await container
        .read(accountControllerProvider.notifier)
        .deleteAccount();
    expect(failure, isNotNull);
    expect(container.read(accountControllerProvider).isLoading, isFalse);

    // paused のまま残っていないこと（新規 drain が走る）を確認する。
    expect(await engineCanDrain(engine, store, remote), isTrue);
  });

  test('二重タップ: 連打してもサーバー削除RPCは1回だけ実行される（E-2 / R8-C）', () async {
    await seedGenba('g-a', 'user-A');
    var serverCalls = 0;
    // サーバー削除の最中に、2回目の deleteAccount を割り込ませて連打を再現する。
    late final ProviderContainer container;
    late final Future<Failure?> secondTap;
    container = await containerFor(
      serverResult: const Ok(null),
      ownerId: 'user-A',
      onServerCall: () {
        serverCalls++;
        // 1回目の削除がまだ進行中のうちに2回目を呼ぶ（並行タップ相当）。
        secondTap =
            container.read(accountControllerProvider.notifier).deleteAccount();
      },
    );

    final firstTap = await container
        .read(accountControllerProvider.notifier)
        .deleteAccount();
    final second = await secondTap;

    // 実サーバーRPCは1回だけ（2回目は進行中ガードで無視され null を返す）。
    expect(serverCalls, 1);
    expect(firstTap, isNull);
    expect(second, isNull);
    expect(container.read(accountControllerProvider).isLoading, isFalse);
  });
}
