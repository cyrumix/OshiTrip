import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fixtures.dart';

/// GenbaTodo.type（Todo/持ち物の種別）の後方互換・シリアライズ検証。
void main() {
  group('TodoItemType', () {
    test('種別キーの無いJSON（既存データ相当）はTodo種別として復元される', () {
      final json = {
        'id': 'todo-1',
        'genba_id': 'genba-1',
        'owner_id': 'user-1',
        'name': '既存のTodo',
        // 'type' キーを含めない = 移行前のサーバー/Outbox payload相当。
        'is_done': false,
        'priority': 'normal',
        'sort_order': 0,
        'created_at': fixedCreatedAt.toIso8601String(),
        'updated_at': fixedCreatedAt.toIso8601String(),
      };
      final todo = GenbaTodo.fromJson(json);
      expect(todo.type, TodoItemType.todo);
    });

    test('種別は安定した文字列値でJSONへ往復する（todo/belonging）', () {
      final todo = makeTodo(type: TodoItemType.belonging);
      final json = todo.toJson();
      expect(json['type'], 'belonging');
      expect(GenbaTodo.fromJson(json).type, TodoItemType.belonging);

      final asTodo = makeTodo();
      expect(asTodo.toJson()['type'], 'todo');
    });

    test('デフォルトのファクトリはTodo種別（新規登録時の初期値）', () {
      expect(makeTodo().type, TodoItemType.todo);
    });
  });
}
