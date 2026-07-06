import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/templates/application/template_apply.dart';
import 'package:oshi_trip/features/templates/domain/template_presets.dart';

import '../helpers/fixtures.dart';

/// テンプレート適用・保存の純関数（重複除外・引き継ぎ規則）を検証する。
void main() {
  final now = DateTime.utc(2026, 7, 1);

  // 連番IDジェネレータ（テストの決定性のため）。
  String Function() seqId() {
    var n = 0;
    return () => 'new-${n++}';
  }

  TemplateOptionItem opt(String name, {TodoPriority? priority, String? memo}) =>
      TemplateOptionItem(name: name, priority: priority, memo: memo);

  group('planTemplateApply（テンプレートから追加）', () {
    test('選択した項目だけが追加される', () {
      final plan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        selected: [opt('A'), opt('B')],
        existing: const [],
        now: now,
        newId: seqId(),
      );
      expect(plan.toAdd.map((t) => t.name), ['A', 'B']);
      expect(plan.skipped, 0);
      expect(plan.toAdd.every((t) => t.type == TodoItemType.todo), isTrue);
      expect(plan.toAdd.every((t) => !t.isDone), isTrue);
    });

    test('同種別・同名が既にあれば追加せずスキップ件数に数える', () {
      final plan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        selected: [opt('A'), opt('B'), opt('C')],
        existing: [
          makeTodo(id: 'e1', name: 'A', type: TodoItemType.todo),
          makeTodo(id: 'e2', name: 'C', type: TodoItemType.todo),
        ],
        now: now,
        newId: seqId(),
      );
      expect(plan.toAdd.map((t) => t.name), ['B']);
      expect(plan.skipped, 2);
    });

    test('種別が違えば同名でも重複扱いにしない（Todoと持ち物は独立）', () {
      final plan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.belonging,
        selected: [opt('タオル')],
        // 同名の Todo が存在しても、持ち物としては別物なので追加される。
        existing: [makeTodo(id: 'e1', name: 'タオル', type: TodoItemType.todo)],
        now: now,
        newId: seqId(),
      );
      expect(plan.toAdd.map((t) => t.name), ['タオル']);
      expect(plan.skipped, 0);
      expect(plan.toAdd.single.type, TodoItemType.belonging);
    });

    test('選択リスト内の同名重複は1件だけ追加する', () {
      final plan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        selected: [opt('X'), opt('X')],
        existing: const [],
        now: now,
        newId: seqId(),
      );
      expect(plan.toAdd, hasLength(1));
      expect(plan.skipped, 1);
    });

    test('Todoの重要度は引き継がれ、持ち物には重要度がつかない', () {
      final todoPlan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        selected: [opt('重要Todo', priority: TodoPriority.high)],
        existing: const [],
        now: now,
        newId: seqId(),
      );
      expect(todoPlan.toAdd.single.priority, TodoPriority.high);

      final belongingPlan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.belonging,
        // 万一 priority が付いていても持ち物では normal に落とす。
        selected: [opt('ペンライト', priority: TodoPriority.high)],
        existing: const [],
        now: now,
        newId: seqId(),
      );
      final added = belongingPlan.toAdd.single;
      expect(added.priority, TodoPriority.normal);
      expect(added.dueDate, isNull);
    });

    test('新規項目の sortOrder は既存の最大の後ろへ並べる', () {
      final plan = planTemplateApply(
        genbaId: 'g1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        selected: [opt('A'), opt('B')],
        existing: [
          makeTodo(id: 'e1', name: '既存', type: TodoItemType.todo, sortOrder: 5),
        ],
        now: now,
        newId: seqId(),
      );
      expect(plan.toAdd.map((t) => t.sortOrder), [6, 7]);
    });
  });

  group('buildTemplateItemsFromTodos（現在の内容を保存）', () {
    test('完了状態・期限・担当者は引き継がず、Todoの重要度は保存する', () {
      final items = buildTemplateItemsFromTodos(
        templateId: 'tpl-1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        todos: [
          makeTodo(
            id: 't1',
            name: 'うちわ作成',
            type: TodoItemType.todo,
            isDone: true,
            dueDate: DateTime.utc(2026, 7, 5),
            assignee: '自分',
            memo: 'A4サイズ',
            priority: TodoPriority.high,
          ),
        ],
        now: now,
        newId: seqId(),
      );
      final item = items.single;
      expect(item.name, 'うちわ作成');
      expect(item.priority, TodoPriority.high); // 重要度は保存
      expect(item.memo, 'A4サイズ'); // メモは保存
      // 期限・担当・完了は TodoTemplateItem に存在しない（引き継がれない）。
      expect(item.sortOrder, 0);
    });

    test('持ち物テンプレートは重要度を保存しない（priority=null）', () {
      final items = buildTemplateItemsFromTodos(
        templateId: 'tpl-1',
        ownerId: 'user-1',
        itemType: TodoItemType.belonging,
        todos: [
          makeTodo(
            id: 'b1',
            name: 'モバイルバッテリー',
            type: TodoItemType.belonging,
            priority: TodoPriority.high, // 持ち物に混入していても
          ),
        ],
        now: now,
        newId: seqId(),
      );
      expect(items.single.priority, isNull);
    });

    test('渡した順に sortOrder が 0 始まりで振られる', () {
      final items = buildTemplateItemsFromTodos(
        templateId: 'tpl-1',
        ownerId: 'user-1',
        itemType: TodoItemType.todo,
        todos: [
          makeTodo(id: 't1', name: 'A'),
          makeTodo(id: 't2', name: 'B'),
          makeTodo(id: 't3', name: 'C'),
        ],
        now: now,
        newId: seqId(),
      );
      expect(items.map((i) => i.sortOrder), [0, 1, 2]);
      expect(items.map((i) => i.name), ['A', 'B', 'C']);
    });
  });
}
