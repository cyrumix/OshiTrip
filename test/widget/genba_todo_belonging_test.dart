import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';

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
}
