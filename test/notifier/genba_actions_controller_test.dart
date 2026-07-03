import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_actions_controller.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fake_genba_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// [GenbaActionsController] の回帰テスト（H-07/M-01）:
/// - 保存失敗時に成功表示せず、ローカル状態もロールバックされている
///   （実際には反映されていない = 変更前のまま）こと。
/// - 同一操作の二重タップで多重送信されないこと（キー単位のガード）。
/// - 手動終演（markEnded）→ 取消（undoMarkEnded）が正しく反映されること。
void main() {
  late FakeGenbaRepository fakeRepo;
  late ProviderContainer container;
  final clock = FixedClock(DateTime(2026, 7, 10, 12));
  const ownerId = 'user-1';

  setUp(() {
    final db = createTestDb();
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    final realRepo = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => ownerId,
      remoteResolver: () => null,
    );
    fakeRepo = FakeGenbaRepository(realRepo);
    final imageStore = ImageStore(Directory.systemTemp.createTempSync('img'));

    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        genbaRepositoryProvider.overrideWithValue(fakeRepo),
        imageStoreProvider.overrideWithValue(imageStore),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    addTearDown(engine.dispose);
  });

  // autoDispose の provider は購読者が居ないと即座に破棄されうる。
  // container.read だけで保持せず、テスト中は listen して破棄を防ぐ
  // （でないと state への書き込みが disposed 後の element に対して行われ、
  // 二重タップ防止用の state が反映されないことがある）。
  GenbaActionsController controller(String genbaId) {
    final provider = genbaActionsControllerProvider(genbaId);
    container.listen(provider, (_, __) {});
    return container.read(provider.notifier);
  }

  Future<Genba> seedGenba(Genba genba) async {
    final result = await fakeRepo.upsertGenba(genba);
    expect(result.isOk, isTrue);
    return genba;
  }

  group('保存失敗ロールバック: 成功表示しない・ローカル状態を変更しない', () {
    test('cancel が失敗したら isCanceled は変わらない', () async {
      final genba = await seedGenba(
        makeGenba(id: 'g1', ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
      );
      fakeRepo.failNextUpsertGenba = true;

      final failure = await controller('g1').cancel(genba);
      expect(failure, isNotNull); // 失敗を成功表示しない。

      final reloaded = await fakeRepo.watchById('g1').first;
      expect(reloaded!.genba.isCanceled, isFalse); // ロールバック（変更されていない）。
    });

    test('markEnded が失敗したら manualEndedAt は変わらない', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g2',
          ownerId: ownerId,
          eventDate: DateTime(2026, 7, 10),
          startTimeMinutes: 10 * 60,
          endTimeMinutes: 11 * 60,
        ),
      );
      fakeRepo.failNextUpsertGenba = true;

      final failure = await controller('g2').markEnded(genba);
      expect(failure, isNotNull);

      final reloaded = await fakeRepo.watchById('g2').first;
      expect(reloaded!.genba.manualEndedAt, isNull);
    });
  });

  group('二重タップ防止: 同一操作の再入は無視され、多重送信しない', () {
    test('markEnded を待たずに連打しても upsertGenba は1回しか呼ばれない', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g3',
          ownerId: ownerId,
          eventDate: DateTime(2026, 7, 10),
          startTimeMinutes: 10 * 60,
          endTimeMinutes: 11 * 60,
        ),
      );
      // 1回目の書き込みがまだ進行中である window を安定して作る。
      fakeRepo.upsertGenbaDelay = const Duration(milliseconds: 100);
      fakeRepo.upsertGenbaCallCount = 0; // seedGenba分のカウントを除外する。

      final c = controller('g3');
      final first = c.markEnded(genba); // await しない = 連打を模す
      final second = c.markEnded(genba); // 進行中なので無視されるはず

      final results = await Future.wait([first, second]);
      expect(fakeRepo.upsertGenbaCallCount, 1);
      // 2回目は「二重タップで無視」= null を返す（失敗ではない）。
      expect(results.where((f) => f == null).length, 2);
    });

    test('二重タップ防止は操作キー単位: 別の現場・別操作は同時に進められる', () async {
      final genba4 = await seedGenba(
        makeGenba(
          id: 'g4',
          ownerId: ownerId,
          eventDate: DateTime(2026, 7, 10),
          startTimeMinutes: 10 * 60,
          endTimeMinutes: 11 * 60,
        ),
      );
      final genba5 = await seedGenba(
        makeGenba(
          id: 'g5',
          ownerId: ownerId,
          eventDate: DateTime(2026, 7, 10),
          startTimeMinutes: 10 * 60,
          endTimeMinutes: 11 * 60,
        ),
      );
      fakeRepo.upsertGenbaDelay = const Duration(milliseconds: 100);
      fakeRepo.upsertGenbaCallCount = 0; // seedGenba分のカウントを除外する。

      // g4 の markEnded が進行中でも、g5 の markEnded は別キー（別genbaIdの
      // controllerインスタンス）なのでブロックされない。
      final f1 = controller('g4').markEnded(genba4);
      final f2 = controller('g5').markEnded(genba5);
      final results = await Future.wait([f1, f2]);

      expect(fakeRepo.upsertGenbaCallCount, 2);
      expect(results, [null, null]); // どちらも成功（失敗なし）。
    });
  });

  test('markEnded → undoMarkEnded で手動終演が解除される（誤操作からの復旧）', () async {
    final genba = await seedGenba(
      makeGenba(
        id: 'g6',
        ownerId: ownerId,
        eventDate: DateTime(2026, 7, 10),
        startTimeMinutes: 10 * 60,
        endTimeMinutes: 11 * 60,
      ),
    );

    final c = controller('g6');
    final f1 = await c.markEnded(genba);
    expect(f1, isNull);
    final afterEnded = (await fakeRepo.watchById('g6').first)!.genba;
    expect(afterEnded.manualEndedAt, isNotNull);

    final f2 = await c.undoMarkEnded(afterEnded);
    expect(f2, isNull);
    final afterUndo = (await fakeRepo.watchById('g6').first)!.genba;
    expect(afterUndo.manualEndedAt, isNull);
  });

  test('correctEndedAt で手動終演時刻を訂正できる', () async {
    final genba = await seedGenba(
      makeGenba(
        id: 'g7',
        ownerId: ownerId,
        eventDate: DateTime(2026, 7, 10),
        startTimeMinutes: 10 * 60,
        endTimeMinutes: 11 * 60,
        manualEndedAt: DateTime(2026, 7, 10, 10, 30).toUtc(),
      ),
    );
    final corrected = DateTime(2026, 7, 10, 10, 45);
    final failure = await controller('g7').correctEndedAt(genba, corrected);
    expect(failure, isNull);

    final reloaded = (await fakeRepo.watchById('g7').first)!.genba;
    expect(reloaded.manualEndedAt, corrected.toUtc());
  });
}
