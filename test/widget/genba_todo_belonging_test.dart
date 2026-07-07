import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/auth/local_data_scope.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';

import '../helpers/fake_genba_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// Todo・持ち物タブ: 同じ仕組み（GenbaTodo + type）でTodoと持ち物を管理し、
/// 画面上はセクションを分けて表示する（各セクション独立の未完了数・空状態）。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'gb-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<void> openTodoTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Todo・持ち物'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openOverviewTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text('概要')),
    );
    await tester.pumpAndSettle();
  }

  /// tooltip 付きの [IconButton] を取得する。[find.byTooltip] は内部の
  /// [Tooltip] を返すため、祖先を辿って [IconButton] 自体を特定する。
  IconButton iconButtonByTooltip(WidgetTester tester, String tooltip) {
    return tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );
  }

  /// 実配線と同じ [GenbaRepositoryImpl] を [FakeGenbaRepository] で包んで
  /// 差し替える（失敗注入・保留ゲートだけをテストから制御するため）。
  /// [onCreated] でテスト側が fake の参照を掴む。
  Future<ProviderContainer> pumpWithFakeRepo(
    WidgetTester tester, {
    required AppDatabase db,
    required void Function(FakeGenbaRepository fake) onCreated,
  }) {
    return pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
      extraOverrides: [
        genbaRepositoryProvider.overrideWith((ref) {
          final scope = ref.watch(localDataScopeProvider);
          final real = GenbaRepositoryImpl(
            db: ref.watch(databaseProvider),
            outbox: ref.watch(outboxStoreProvider),
            syncEngine: ref.watch(syncEngineProvider),
            clock: ref.watch(clockProvider),
            ownerIdResolver: () => scope.ownerIdOrNull,
            remoteResolver: () => null,
          );
          final fake = FakeGenbaRepository(real);
          onCreated(fake);
          return fake;
        }),
      ],
    );
  }

  testWidgets('Todoと持ち物は別セクションに分かれ、各セクションの未完了数が正しい', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-todo-1',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '銀テを拾う',
        type: TodoItemType.todo,
      ),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-todo-2',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '完了済みTodo',
        type: TodoItemType.todo,
        isDone: true,
      ),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-belonging-1',
        genbaId: genbaId,
        ownerId: ownerId,
        name: 'ペンライト',
        type: TodoItemType.belonging,
      ),
    );
    await tester.pumpAndSettle();

    await openTodoTab(tester);

    // 各セクションの見出しに、種別ごとの未完了数だけが出る
    // （完了済みTodoは残数に含まれず、持ち物はTodo残数に混ざらない）。
    expect(find.text('Todo（残り1）'), findsOneWidget);
    expect(find.text('持ち物（残り1）'), findsOneWidget);

    // 項目自体もそれぞれの一覧に出る。
    expect(find.text('銀テを拾う'), findsOneWidget);
    expect(find.text('完了済みTodo'), findsOneWidget);
    expect(find.text('ペンライト'), findsOneWidget);

    // Todoセクションが持ち物セクションより上に描画される
    // （sortOrder順を保ったうえでの種別分割）。
    final todoHeaderY = tester.getTopLeft(find.text('Todo（残り1）')).dy;
    final belongingHeaderY = tester.getTopLeft(find.text('持ち物（残り1）')).dy;
    expect(todoHeaderY, lessThan(belongingHeaderY));

    await unmountApp(tester);
  });

  testWidgets('一方のリストが空でも、そのセクション専用の空状態が出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();

    await openTodoTab(tester);

    expect(find.text('Todo（残り0）'), findsOneWidget);
    expect(find.text('持ち物（残り0）'), findsOneWidget);
    expect(find.textContaining('Todoはまだありません'), findsOneWidget);
    expect(find.textContaining('持ち物はまだありません'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('新規登録時は種別をTodoから選択でき、持ち物として保存できる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    // 「Todoを追加」から開いても、種別は変更できる（新規登録時の初期値はTodo）。
    await tester.tap(find.text('Todoを追加'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todo'))
          .selected,
      isTrue,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '持ち物'));
    await tester.pumpAndSettle();
    // 種別切替でシートタイトルも追従する（種別以外の入力項目は共通のまま）。
    // 画面下にも同名の「持ち物を追加」ボタンがあるため、シート内に絞って確認する。
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('持ち物を追加'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, 'うちわ');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('Todo（残り0）'), findsOneWidget);
    expect(find.text('持ち物（残り1）'), findsOneWidget);
    expect(find.text('うちわ'), findsOneWidget);

    final aggregate =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    final saved = aggregate!.todos.singleWhere((t) => t.name == 'うちわ');
    expect(saved.type, TodoItemType.belonging);

    await unmountApp(tester);
  });

  testWidgets('編集画面で種別を変更すると、表示されるセクションが切り替わる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-switch',
        genbaId: genbaId,
        ownerId: ownerId,
        name: 'ペンライトの電池',
        type: TodoItemType.todo,
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    expect(find.text('Todo（残り1）'), findsOneWidget);
    expect(find.text('持ち物（残り0）'), findsOneWidget);

    // 対象Todoの編集ボタン（ツールチップは現在の種別名で出る）をタップする。
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, 'ペンライトの電池'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todo'))
          .selected,
      isTrue,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '持ち物'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('Todo（残り0）'), findsOneWidget);
    expect(find.text('持ち物（残り1）'), findsOneWidget);

    final aggregate = await repo.watchById(genbaId).first;
    expect(
      aggregate!.todos.singleWhere((t) => t.id == 't-switch').type,
      TodoItemType.belonging,
    );

    await unmountApp(tester);
  });

  testWidgets('持ち物では期限・重要度の入力欄が出ない（Todoでは出る）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(find.text('Todoを追加'));
    await tester.pumpAndSettle();
    // Todoでは期限・重要度が出る。
    expect(find.text('期限'), findsOneWidget);
    expect(find.text('重要度'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '持ち物'));
    await tester.pumpAndSettle();
    // 持ち物へ切り替えると、期限・重要度の入力欄は消える。
    expect(find.text('期限'), findsNothing);
    expect(find.text('重要度'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Todo'));
    await tester.pumpAndSettle();
    // Todoへ戻すと再び出る（種別だけが切替対象で、他の入力項目は共通のまま）。
    expect(find.text('期限'), findsOneWidget);
    expect(find.text('重要度'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('Todoから持ち物へ切り替えて保存すると、期限・重要度は既定値へ戻る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-reset',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '銀テ確保',
        type: TodoItemType.todo,
        priority: TodoPriority.high,
        dueDate: DateTime(2026, 7, 20),
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '銀テ確保'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '持ち物'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    final saved = (await repo.watchById(genbaId).first)!
        .todos
        .singleWhere((t) => t.id == 't-reset');
    expect(saved.type, TodoItemType.belonging);
    // 古い期限・重要度は持ち越さず、既定値へ戻す（§持ち物の入力仕様）。
    expect(saved.dueDate, isNull);
    expect(saved.priority, TodoPriority.normal);

    await unmountApp(tester);
  });

  testWidgets('準備サマリに「持ち物」の対応状況が独立して表示される', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 'b-summary',
        genbaId: genbaId,
        ownerId: ownerId,
        name: 'うちわ',
        type: TodoItemType.belonging,
      ),
    );
    await tester.pumpAndSettle();

    // 概要タブの準備サマリに「持ち物」タイル（対応状況）が独立して出る。
    expect(find.text('持ち物'), findsOneWidget);
    expect(find.bySemanticsLabel('持ち物: 未対応'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('編集シートの削除ボタンでTodoを削除できる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-del',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '削除対象Todo',
        type: TodoItemType.todo,
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);
    expect(find.text('Todo（残り1）'), findsOneWidget);

    // 項目の編集ボタンで編集シートを開く。
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '削除対象Todo'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();

    // 編集シートに削除ボタンがある。
    expect(find.byTooltip('削除'), findsOneWidget);
    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();

    // 危険操作の確認ダイアログ → 削除する。
    expect(find.text('Todoを削除'), findsOneWidget);
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    // 種別に応じた成功メッセージが出て、シートは閉じ、一覧から消え、
    // 残数も0になる。
    expect(find.text('Todoを削除しました'), findsOneWidget);
    expect(find.text('削除対象Todo'), findsNothing);
    expect(find.text('Todo（残り0）'), findsOneWidget);
    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, isEmpty);

    await unmountApp(tester);
  });

  testWidgets('編集シートの削除ボタンで持ち物を削除できる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 'b-del',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '削除対象の持ち物',
        type: TodoItemType.belonging,
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);
    expect(find.text('持ち物（残り1）'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '削除対象の持ち物'),
        matching: find.byTooltip('持ち物を編集'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('削除'), findsOneWidget);
    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    expect(find.text('持ち物を削除'), findsOneWidget);
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.text('持ち物を削除しました'), findsOneWidget);
    expect(find.text('削除対象の持ち物'), findsNothing);
    expect(find.text('持ち物（残り0）'), findsOneWidget);
    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, isEmpty);

    await unmountApp(tester);
  });

  testWidgets('新規追加シートには削除ボタンが出ない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(find.text('Todoを追加'));
    await tester.pumpAndSettle();
    // 新規追加では削除対象が無いため削除ボタンは表示しない。
    expect(find.byTooltip('削除'), findsNothing);
    expect(find.text('保存する'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('削除確認をキャンセルすると、シートは開いたまま項目も残る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-cancel',
        genbaId: genbaId,
        ownerId: ownerId,
        name: 'キャンセル対象',
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, 'キャンセル対象'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    expect(find.text('Todoを削除'), findsOneWidget);
    // 確認ダイアログでキャンセルした場合、Repository/Controllerの削除処理は
    // 一切呼ばれない。
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    // シートは開いたまま（保存ボタンがまだ見える）で、項目も残る
    // （背後の一覧側の CheckboxListTile として存在することを見る。シート内の
    // TextField にも同名が入っているため、リスト側に絞って確認する）。
    expect(find.text('保存する'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'キャンセル対象'), findsOneWidget);
    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, hasLength(1));

    await unmountApp(tester);
  });

  testWidgets('削除失敗時はシートを閉じず、失敗メッセージを表示し、残数・準備状態も変わらない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    late FakeGenbaRepository fakeRepo;
    final container = await pumpWithFakeRepo(
      tester,
      db: db,
      onCreated: (fake) => fakeRepo = fake,
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 'b-fail',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '削除失敗対象の持ち物',
        type: TodoItemType.belonging,
      ),
    );
    await tester.pumpAndSettle();
    // 準備状態タイルは概要タブにあるため、Todoタブへ移る前に基準値を確認する。
    expect(find.bySemanticsLabel('持ち物: 未対応'), findsOneWidget);
    await openTodoTab(tester);
    expect(find.text('持ち物（残り1）'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '削除失敗対象の持ち物'),
        matching: find.byTooltip('持ち物を編集'),
      ),
    );
    await tester.pumpAndSettle();

    fakeRepo.failNextDeleteTodo = true;
    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    // 失敗メッセージが出て、成功したような表示はしない。
    expect(find.text('テスト用のTodo削除失敗'), findsOneWidget);
    expect(find.text('持ち物を削除しました'), findsNothing);
    // シートは閉じず、項目も一覧から消えない。残数も変わらない。
    expect(find.text('保存する'), findsOneWidget);
    expect(
      find.widgetWithText(CheckboxListTile, '削除失敗対象の持ち物'),
      findsOneWidget,
    );
    expect(find.text('持ち物（残り1）'), findsOneWidget);

    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, hasLength(1));

    // 準備状態も変わらない（概要タブへ戻って確認）。まずシートを閉じる。
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    await openOverviewTab(tester);
    expect(find.bySemanticsLabel('持ち物: 未対応'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('削除処理中は保存・削除・閉じるボタンが無効になる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    late FakeGenbaRepository fakeRepo;
    final container = await pumpWithFakeRepo(
      tester,
      db: db,
      onCreated: (fake) => fakeRepo = fake,
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-busy',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '処理中確認対象',
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '処理中確認対象'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();

    // 削除確定後、実削除を意図的に保留にする（実時間 delay に依存しない）。
    final gate = Completer<Result<void>>();
    fakeRepo.nextDeleteTodoGate = gate;
    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    // 確認ダイアログの終了アニメーションを含めて進める。ゲートは未完了の
    // ままなので実削除自体は進行中で止まり続け、pumpAndSettle はハングしない
    // （アニメーションが継続する要素が無いため）。
    await tester.pumpAndSettle();

    // 削除・閉じる・保存の各ボタンが無効化される。
    expect(iconButtonByTooltip(tester, '削除').onPressed, isNull);
    expect(iconButtonByTooltip(tester, '閉じる').onPressed, isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    // 処理完了後は通常どおり閉じられる。
    gate.complete(const Ok(null));
    await tester.pumpAndSettle();
    expect(find.text('Todoを削除しました'), findsOneWidget);
    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, isEmpty);

    await unmountApp(tester);
  });

  testWidgets('削除処理中はシステム戻る操作やシート外タップでシートが閉じない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    late FakeGenbaRepository fakeRepo;
    final container = await pumpWithFakeRepo(
      tester,
      db: db,
      onCreated: (fake) => fakeRepo = fake,
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-pop',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '戻る操作確認対象',
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '戻る操作確認対象'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();

    final gate = Completer<Result<void>>();
    fakeRepo.nextDeleteTodoGate = gate;
    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    // 確認ダイアログの終了アニメーションを含めて進める。ゲートは未完了の
    // ままなので実削除自体は進行中で止まり続け、pumpAndSettle はハングしない。
    await tester.pumpAndSettle();

    // システム戻る相当（Navigator.maybePop）はPopScopeにより拒否される
    // （maybePopの戻り値はpop試行が処理されたかどうかを示すだけなので、
    // ここではシートが実際に閉じていないことで検証する）。
    final navigator =
        Navigator.of(tester.element(find.byType(DraggableScrollableSheet)));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('保存する'), findsOneWidget);

    // シート外（バリア）タップでも閉じない。
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('保存する'), findsOneWidget);

    // 処理完了後は通常どおり閉じられる。
    gate.complete(const Ok(null));
    await tester.pumpAndSettle();
    expect(find.text('戻る操作確認対象'), findsNothing);
    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, isEmpty);

    await unmountApp(tester);
  });

  testWidgets('完了切替が処理中の同じTodoを削除しようとすると、シートは閉じず処理中のメッセージが出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    late FakeGenbaRepository fakeRepo;
    final container = await pumpWithFakeRepo(
      tester,
      db: db,
      onCreated: (fake) => fakeRepo = fake,
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 't-conflict',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '競合確認対象',
      ),
    );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    // 完了切替（toggleTodo）を意図的に保留にする（実時間 delay に依存しない）。
    final gate = Completer<Result<void>>();
    fakeRepo.nextUpsertTodoGate = gate;
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '競合確認対象'),
        matching: find.byType(Checkbox),
      ),
    );
    // ゲート未完了のためpumpAndSettleは使わず、切替開始分だけ進める。
    await tester.pump();

    // 完了切替が進行中の同じTodoを、編集シートから削除しようとする。
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, '競合確認対象'),
        matching: find.byTooltip('Todoを編集'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    // 削除は実行されず、処理中である旨のメッセージが出る。成功表示はしない。
    expect(
      find.text('処理中です。しばらく待ってから再試行してください'),
      findsOneWidget,
    );
    expect(find.text('Todoを削除しました'), findsNothing);
    // シートは閉じず、項目も一覧から消えない。
    expect(find.text('保存する'), findsOneWidget);
    expect(
      find.widgetWithText(CheckboxListTile, '競合確認対象'),
      findsOneWidget,
    );

    // 完了切替自体は完了させ、後片付けする。
    gate.complete(const Ok(null));
    await tester.pumpAndSettle();
    final aggregate = await repo.watchById(genbaId).first;
    expect(aggregate!.todos, hasLength(1));

    await unmountApp(tester);
  });
}
