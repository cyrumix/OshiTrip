import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
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
      final second = c.markEnded(genba); // 進行中なので実行されないはず

      final results = await Future.wait([first, second]);
      expect(fakeRepo.upsertGenbaCallCount, 1);
      // 1回目は実際に実行され成功（null）。2回目は実行されず、成功とは
      // 区別できる OperationInProgressFailure を返す（「成功」と「未実行」を
      // null 同士で混同しない: レビュー指摘の回帰）。
      expect(results[0], isNull);
      expect(results[1], isA<OperationInProgressFailure>());
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

  test('markEnded 後、予定より遅い時刻へ correctEndedAt でき、予定へ丸められない', () async {
    final genba = await seedGenba(
      makeGenba(
        id: 'g8',
        ownerId: ownerId,
        eventDate: DateTime(2026, 7, 10),
        startTimeMinutes: 18 * 60,
        endTimeMinutes: 21 * 60, // 予定終演 21:00
      ),
    );
    final c = controller('g8');
    expect(await c.markEnded(genba), isNull);
    final ended = (await fakeRepo.watchById('g8').first)!.genba;
    expect(ended.manualEndedAt, isNotNull);

    // 予定(21:00)より遅い 22:30 へ訂正。
    final later = DateTime(2026, 7, 10, 22, 30);
    expect(await c.correctEndedAt(ended, later), isNull);
    final corrected = (await fakeRepo.watchById('g8').first)!.genba;
    expect(corrected.manualEndedAt, later.toUtc());
  });

  group('同一現場の異なるフィールドを並行・連続更新しても変更が失われない（read-latest-merge）', () {
    test('並行: 交通要否と宿泊要否を同一スナップショットから同時更新しても両方保持', () async {
      // 交通・宿泊とも unknown で seed。UI は同じ aggregate.genba スナップショット
      // を両操作へ渡すため、古い値でのフル上書きだと後勝ちで片方が消える。
      final genba = await seedGenba(
        makeGenba(
          id: 'g-merge-1',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      expect(genba.transportRequirement, RequirementStatus.unknown);
      expect(genba.lodgingRequirement, RequirementStatus.unknown);

      // 1回目がまだ進行中の window を作って確実に重ねる。
      fakeRepo.upsertGenbaDelay = const Duration(milliseconds: 50);
      final c = controller('g-merge-1');
      final f1 = c.setTransportRequirement(genba, RequirementStatus.required);
      final f2 = c.setLodgingRequirement(genba, RequirementStatus.notRequired);
      final results = await Future.wait([f1, f2]);
      expect(results, [null, null]);

      final reloaded = (await fakeRepo.watchById('g-merge-1').first)!.genba;
      // 旧実装（フル上書き）なら後勝ちでどちらかが unknown へ戻る。merge なら両方保持。
      expect(reloaded.transportRequirement, RequirementStatus.required);
      expect(reloaded.lodgingRequirement, RequirementStatus.notRequired);
    });

    test('連続: 古いスナップショットで続けて別フィールドを更新しても直前の変更を消さない', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g-merge-2',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final c = controller('g-merge-2');

      // 交通要否を先に更新。
      expect(
        await c.setTransportRequirement(genba, RequirementStatus.required),
        isNull,
      );
      // ここで UI が持っている `genba` はまだ古い（transport=unknown のまま）。
      // その古いスナップショットで中止操作を行っても、交通要否を巻き戻さない。
      expect(await c.cancel(genba), isNull);

      final reloaded = (await fakeRepo.watchById('g-merge-2').first)!.genba;
      expect(reloaded.isCanceled, isTrue);
      expect(reloaded.transportRequirement, RequirementStatus.required);
    });
  });

  group('Todo・持ち物削除をapplication層へ集約する', () {
    Future<void> seedTodo(GenbaTodo todo) async {
      final result = await fakeRepo.upsertTodo(todo);
      expect(result.isOk, isTrue);
    }

    test('Todo削除が成功するとRepositoryから消える', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g-del-1',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final todo = makeTodo(
        id: 't-del-1',
        genbaId: genba.id,
        ownerId: ownerId,
        type: TodoItemType.todo,
      );
      await seedTodo(todo);

      final failure = await controller(genba.id).deleteTodo(todo);
      expect(failure, isNull);

      final aggregate = await fakeRepo.watchById(genba.id).first;
      expect(aggregate!.todos, isEmpty);
    });

    test('持ち物削除が成功するとRepositoryから消える', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g-del-2',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final belonging = makeTodo(
        id: 't-del-2',
        genbaId: genba.id,
        ownerId: ownerId,
        type: TodoItemType.belonging,
      );
      await seedTodo(belonging);

      final failure = await controller(genba.id).deleteTodo(belonging);
      expect(failure, isNull);

      final aggregate = await fakeRepo.watchById(genba.id).first;
      expect(aggregate!.todos, isEmpty);
    });

    test('削除失敗ではFailureが返り、データは残る（成功表示しない）', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g-del-3',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final todo = makeTodo(id: 't-del-3', genbaId: genba.id, ownerId: ownerId);
      await seedTodo(todo);
      fakeRepo.failNextDeleteTodo = true;

      final failure = await controller(genba.id).deleteTodo(todo);
      expect(failure, isNotNull);

      final aggregate = await fakeRepo.watchById(genba.id).first;
      expect(aggregate!.todos, hasLength(1));
      expect(aggregate.todos.single.id, 't-del-3');
    });

    test('同一Todoの削除を同時に呼ぶと、1回目だけ実行され2回目は処理中のFailureになる', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g-del-4',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final todo = makeTodo(id: 't-del-4', genbaId: genba.id, ownerId: ownerId);
      await seedTodo(todo);

      // 1回目の削除がまだ進行中である window を、実時間 delay ではなく
      // Completer ゲートで安定して作る。
      final gate = Completer<Result<void>>();
      fakeRepo.nextDeleteTodoGate = gate;

      final c = controller(genba.id);
      final first = c.deleteTodo(todo); // 進行中（ゲート待ち）
      final second = c.deleteTodo(todo); // 同一キーが処理中のため実行されない

      // 2回目は成功(null)ではなく、未実行であることを示すFailureになる
      // （レビュー指摘: 「成功」と「未実行」をnull同士で混同しない）。
      expect(await second, isA<OperationInProgressFailure>());
      gate.complete(const Ok(null));
      // 1回目は実際に実行され、正常終了する。
      expect(await first, isNull);

      // Repositoryの実削除は1回だけ呼ばれる（2回目は届いていない）。
      expect(fakeRepo.deleteTodoCallCount, 1);
      final aggregate = await fakeRepo.watchById(genba.id).first;
      expect(aggregate!.todos, isEmpty);
    });

    test('toggleTodo実行中に同じTodoをdeleteTodoすると、削除は実行されず処理中のFailureになる', () async {
      final genba = await seedGenba(
        makeGenba(
          id: 'g-del-5',
          ownerId: ownerId,
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final todo = makeTodo(id: 't-del-5', genbaId: genba.id, ownerId: ownerId);
      await seedTodo(todo);

      // toggleTodo は upsertTodo 経由なので、そのゲートで進行中を作る。
      final gate = Completer<Result<void>>();
      fakeRepo.nextUpsertTodoGate = gate;

      final c = controller(genba.id);
      final toggle = c.toggleTodo(todo, true); // 進行中（ゲート待ち）
      final delete = c.deleteTodo(todo); // 同一キーが処理中のため実行されない

      // 削除は実行されず、処理中のFailureになる（削除成功として扱われない）。
      expect(await delete, isA<OperationInProgressFailure>());
      expect(fakeRepo.deleteTodoCallCount, 0);
      gate.complete(const Ok(null));
      expect(await toggle, isNull);

      // 削除は未実行のためTodoは残り、完了切替だけが反映される。
      final aggregate = await fakeRepo.watchById(genba.id).first;
      expect(aggregate!.todos, hasLength(1));
      expect(aggregate.todos.single.isDone, isTrue);
    });
  });
}
