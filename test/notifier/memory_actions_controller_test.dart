import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/memory/application/memory_actions_controller.dart';
import 'package:oshi_trip/features/memory/data/memory_repository_impl.dart';

import '../helpers/fake_memory_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// [MemoryActionsController]（R7）の回帰テスト:
/// - お気に入り保存の失敗が [Failure] として返り、ローカル状態
///   （実DB）が変わらないこと（成功表示しない・自然なロールバック）。
/// - 同一操作の二重タップで多重送信されないこと（キー単位のガード）。
void main() {
  late FakeMemoryRepository fakeRepo;
  late ProviderContainer container;
  final clock = FixedClock(DateTime(2026, 7, 10, 12));
  const genbaId = 'g-1';

  setUp(() async {
    final db = createTestDb();
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    final realRepo = MemoryRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    // 思い出 entry の作成には現在 owner の親現場が必要（D-51）。
    final genbaRepo = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    final seeded = await genbaRepo.upsertGenba(
      makeGenba(
        id: genbaId,
        ownerId: 'user-1',
        eventDate: DateTime(2026, 6, 1),
      ),
    );
    expect(seeded.isOk, isTrue);
    fakeRepo = FakeMemoryRepository(realRepo);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        memoryRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    addTearDown(engine.dispose);
  });

  MemoryActionsController controller() {
    final provider = memoryActionsControllerProvider(genbaId);
    // autoDispose provider の破棄を防ぐため listen で保持する。
    container.listen(provider, (_, __) {});
    return container.read(provider.notifier);
  }

  test('お気に入り保存の失敗は Failure として返り、実データは変わらない', () async {
    fakeRepo.failNextSetFavorite = true;
    final failure = await controller().setFavorite(isFavorite: true);
    expect(failure, isNotNull);
    final bundle = await fakeRepo.watchByGenbaId(genbaId).first;
    expect(bundle.entry?.isFavorite ?? false, isFalse);

    // 失敗後は再試行でき、成功すれば実データへ反映される。
    final retry = await controller().setFavorite(isFavorite: true);
    expect(retry, isNull);
    final after = await fakeRepo.watchByGenbaId(genbaId).first;
    expect(after.entry?.isFavorite, isTrue);
  });

  test('お気に入りの二重タップでも保存は1回だけ実行される', () async {
    fakeRepo.setFavoriteDelay = const Duration(milliseconds: 30);
    final c = controller();
    final first = c.setFavorite(isFavorite: true);
    final second = c.setFavorite(isFavorite: true); // 進行中の再入 → 無視
    await Future.wait([first, second]);
    expect(fakeRepo.setFavoriteCallCount, 1);
    final bundle = await fakeRepo.watchByGenbaId(genbaId).first;
    expect(bundle.entry?.isFavorite, isTrue);
  });
}
