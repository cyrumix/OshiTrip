import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/auth/domain/auth_repository.dart';
import 'package:oshi_trip/features/memory/data/memory_repository_impl.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// Issue2 テスト1: 認証確定（起動・セッション復元・ユーザー切替）で、残存する
/// 画像削除キューがバックグラウンドで自動再試行され、成功した行が消える。
void main() {
  test('認証確定時に残存キューを自動処理して成功行が消える', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    final imageStore =
        ImageStore(Directory.systemTemp.createTempSync('oshi_img_startup'));
    final memoryRepo = MemoryRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-A',
      imageStoreResolver: () => imageStore,
    );

    // 前回失敗して残った削除予定（有効な owner 参照。実ファイルは存在せず
    // 冪等に成功する）。
    await db.into(db.pendingImageDeletions).insert(
          PendingImageDeletionsCompanion.insert(
            id: 'q1',
            ownerId: 'user-A',
            ref: 'images/user-A/memory_photo/a.jpg',
            createdAt: fixedCreatedAt.toIso8601String(),
            updatedAt: fixedCreatedAt.toIso8601String(),
          ),
        );

    final authController = StreamController<AppUser?>();
    addTearDown(authController.close);
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        imageStoreProvider.overrideWithValue(imageStore),
        memoryRepositoryProvider.overrideWithValue(memoryRepo),
        currentUserProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(container.dispose);

    // app と同じく sessionSync を有効化（この時点では未認証）。
    container.read(sessionSyncProvider);
    await pumpEventQueue();
    // 未認証ではキューは残る。
    expect(
      await db.select(db.pendingImageDeletions).get(),
      hasLength(1),
    );

    // 認証確定 → バックグラウンド再試行が走る（fire-and-forget）。
    authController.add(const AppUser(id: 'user-A', email: 'a@example.com'));
    await pumpEventQueue();
    // 実ファイル I/O の完了を待つ（背景 flush は await されないため）。
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await pumpEventQueue();

    // 成功した行はキューから消える。
    expect(await db.select(db.pendingImageDeletions).get(), isEmpty);
  });
}
