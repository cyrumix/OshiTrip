import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/app.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';

import '../helpers/fake_genba_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// R5再レビュー #2「保存失敗時に成功表示されず、楽観表示が元へ戻る」の回帰。
///
/// integration_test は実配線のRepository（Drift＋SyncEngine、Supabase無し）を
/// 使うため、任意のタイミングで書込みだけを失敗させる注入点が無い
/// （実際のDrift/SQLiteは通常失敗しないため、失敗を人為的に起こすには
/// リポジトリ自体を差し替えるしかない）。差し替えは
/// `ProviderScope`/`UncontrolledProviderScope` の override というテスト専用の
/// 仕組みであり、実行環境（実機/CI）を問わず integration_test の範囲では
/// 使えない。そのため、ここでは本物の `GenbaDetailScreen`（presentation層は
/// integration_test と全く同じ実装）に対して `genbaRepositoryProvider` だけを
/// 失敗注入可能な [FakeGenbaRepository] へ差し替えて検証する。presentation→
/// application(`GenbaActionsController`/`_TodoSectionState`)→data の経路は
/// integration_test と同一であり、差し替えたのは経路の末端（実データ保存）
/// だけである。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<AppDatabase> signedInDb() async {
    final db = createTestDb();
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': ownerId, 'email': 'demo@example.com'}),
    );
    return db;
  }

  testWidgets('Todo完了の保存に失敗すると成功表示されず、チェックが元に戻る', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);

    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 実配線と全く同じ GenbaRepositoryImpl を FakeGenbaRepository で包み、
    // 失敗注入だけを可能にする（成功パスは実装への完全な委譲）。
    late FakeGenbaRepository fakeRepo;
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        nowProvider.overrideWith((ref) => Stream.value(clock.now())),
        genbaRepositoryProvider.overrideWith((ref) {
          final real = GenbaRepositoryImpl(
            db: db,
            outbox: ref.watch(outboxStoreProvider),
            syncEngine: ref.watch(syncEngineProvider),
            clock: clock,
            ownerIdResolver: () => ownerId,
            remoteResolver: () => null,
          );
          fakeRepo = FakeGenbaRepository(real);
          return fakeRepo;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-failtest',
            ownerId: ownerId,
            title: '失敗ロールバック検証現場',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await container.read(genbaRepositoryProvider).upsertTodo(
          makeTodo(
            id: 'todo-failtest',
            genbaId: 'g-failtest',
            ownerId: ownerId,
            name: '銀テを持参する',
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const OshiExpeditionApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('現場'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('失敗ロールバック検証現場'));
    await tester.pumpAndSettle();

    // 保存前: 未完了。
    final checkbox = find.widgetWithText(CheckboxListTile, '銀テを持参する');
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);

    // 次回の Todo 保存を失敗させておき、チェックをタップする。
    fakeRepo.failNextUpsertTodo = true;
    await tester.tap(checkbox);
    // タップ直後（保存完了前）は楽観更新で即座にチェック済み表示になる。
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);

    // 保存の失敗が返り、成功表示されず、楽観表示が元（未完了）へ戻る。
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
    expect(find.text('テスト用のTodo保存失敗'), findsOneWidget);

    // 実データも変更されていない（本当にロールバックされている）ことを確認。
    final reloaded = await container
        .read(genbaRepositoryProvider)
        .watchById('g-failtest')
        .first;
    expect(reloaded!.todos.single.isDone, isFalse);

    await unmountApp(tester);
  });
}
