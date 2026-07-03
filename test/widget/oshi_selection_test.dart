import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/auth/local_data_scope.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_form_controller.dart';
import 'package:oshi_trip/features/genba/presentation/genba_form_screen.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fake_oshi_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// R5独立レビュー #3: 現場フォームの推しメン選択が実データで機能し、
/// グループ／メンバー未登録時に登録導線が出ることを Widget レベルで確認する。
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

  OshiGroup group(String id, String name) => OshiGroup(
        id: id,
        ownerId: ownerId,
        name: name,
        createdAt: clock.now().toUtc(),
        updatedAt: clock.now().toUtc(),
      );

  OshiMember member(String id, String groupId, String name) => OshiMember(
        id: id,
        groupId: groupId,
        ownerId: ownerId,
        name: name,
        createdAt: clock.now().toUtc(),
        updatedAt: clock.now().toUtc(),
      );

  Future<ProviderContainer> pumpForm(
    WidgetTester tester,
    AppDatabase db,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    // 認証（デモユーザー）の復元を待つ。
    await container.read(currentUserProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GenbaFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('選択グループのメンバーが FilterChip として出て複数選択できる', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);

    // 事前に推しグループ＋メンバーを用意する。
    final container0 = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
    );
    await container0.read(currentUserProvider.future);
    final oshi = container0.read(oshiRepositoryProvider);
    await oshi.upsertGroup(group('g1', 'グループ1'));
    await oshi.upsertMember(member('m1', 'g1', 'メンバーA'));
    await oshi.upsertMember(member('m2', 'g1', 'メンバーB'));
    container0.dispose();

    final container = await pumpForm(tester, db);

    // グループのチップが実データから出る。
    expect(find.widgetWithText(ChoiceChip, 'グループ1'), findsOneWidget);
    // 未選択のうちはメンバーは出ない。
    expect(find.widgetWithText(FilterChip, 'メンバーA'), findsNothing);

    // グループを選ぶ → メンバーが FilterChip として出る。
    await tester.tap(find.widgetWithText(ChoiceChip, 'グループ1'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'メンバーA'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'メンバーB'), findsOneWidget);

    // メンバーを2人選ぶ。
    await tester.tap(find.widgetWithText(FilterChip, 'メンバーA'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'メンバーB'));
    await tester.pumpAndSettle();

    final state = container.read(genbaFormControllerProvider(null)).value!;
    expect(state.oshiGroupId, 'g1');
    expect(state.oshiMemberIds, containsAll(['m1', 'm2']));

    await unmountApp(tester);
  });

  testWidgets('推しグループ未登録時は「推しを登録」導線が出る', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);
    await pumpForm(tester, db);

    expect(find.widgetWithText(ActionChip, '推しを登録'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('選択グループにメンバーが無いときは「メンバーを登録」導線が出る', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);

    final container0 = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
    );
    await container0.read(currentUserProvider.future);
    await container0.read(oshiRepositoryProvider).upsertGroup(
          group('g-empty', 'メンバー無しグループ'),
        );
    container0.dispose();

    await pumpForm(tester, db);
    await tester.tap(find.widgetWithText(ChoiceChip, 'メンバー無しグループ'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('メンバーはまだ登録されていません'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'メンバーを登録'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('推しデータ取得に失敗すると保存中表示が解除され、失敗理由が表示される（R5再々レビュー）', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);

    // 事前に推しグループを用意し、チップ選択自体は正常に行える状態にする
    // （＝失敗は「選択操作」ではなく「保存直前の実データ照合」で起きる）。
    final container0 = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
    );
    await container0.read(currentUserProvider.future);
    await container0.read(oshiRepositoryProvider).upsertGroup(
          group('g1', 'グループ1'),
        );
    container0.dispose();

    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late FakeOshiRepository fakeOshi;
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        oshiRepositoryProvider.overrideWith((ref) {
          final scope = ref.watch(localDataScopeProvider);
          final real = OshiRepositoryImpl(
            db: ref.watch(databaseProvider),
            outbox: ref.watch(outboxStoreProvider),
            syncEngine: ref.watch(syncEngineProvider),
            clock: ref.watch(clockProvider),
            ownerIdResolver: () => scope.ownerIdOrNull,
          );
          fakeOshi = FakeOshiRepository(real);
          return fakeOshi;
        }),
      ],
    );
    addTearDown(container.dispose);
    // ログイン（scope確定）を待ってから読み、submit() が実際に使う
    // インスタンスと同じ fakeOshi をキャプチャする
    // （先に読むと未認証scope向けの別インスタンスを掴んでしまう）。
    await container.read(currentUserProvider.future);
    container.read(oshiRepositoryProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GenbaFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // グループを選択し、必須項目を入力する（この時点ではまだ失敗を注入しない）。
    await tester.tap(find.widgetWithText(ChoiceChip, 'グループ1'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '公演名 *'),
      '夏ライブ',
    );
    await tester.tap(find.text('日付 *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 保存直前に推しデータの読み込みが失敗する状況を模す。
    fakeOshi.watchAllError = Exception('DB読み込みエラー（テスト注入）');

    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    // 失敗理由がSnackBarで表示される。
    expect(find.text('推しデータの読み込みに失敗しました'), findsOneWidget);

    // 保存中表示が解除され、保存ボタンが再操作可能になっている
    // （画面遷移せず、フォームに留まっていることも合わせて確認する）。
    expect(find.widgetWithText(AppBar, '現場を登録'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '登録する'),
    );
    expect(button.onPressed, isNotNull);

    // 現場は保存されていない。
    final all = await container.read(genbaRepositoryProvider).watchAll().first;
    expect(all, isEmpty);

    await unmountApp(tester);
  });
}
