import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/features/genba/data/genba_mappers.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/test_db.dart';

/// v5→v6マイグレーション（todos.type 追加）で、既存Todoを失わず、
/// 種別なしの既存データが安全に「Todo」として扱われることを検証する。
///
/// [createTestDb] は最新スキーマ（onCreate）で作られるため、v5相当の
/// todos テーブル（type列なし）を明示的に再現してから、本番と同じ
/// [AppDatabase.migration] の onUpgrade(5, 6) を実行する
/// （cover_dedupe_migration_test.dart と同じ「実migrationの手順を再現する」方針）。
void main() {
  test('v5→v6マイグレーション後も既存Todoが保持され、種別は既定のtodoになる', () async {
    final db = createTestDb();
    addTearDown(db.close);

    // v5相当（type列がない）を再現する。
    await db.customStatement('DROP TABLE todos');
    await db.customStatement('''
      CREATE TABLE todos (
        id TEXT NOT NULL,
        genba_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        name TEXT NOT NULL,
        due_date TEXT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        assignee TEXT NULL,
        priority TEXT NOT NULL DEFAULT 'normal',
        memo TEXT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await db.customStatement('''
      INSERT INTO todos
        (id, genba_id, owner_id, name, is_done, priority, sort_order,
         created_at, updated_at)
      VALUES
        ('todo-legacy', 'genba-1', 'user-1', '既存のTodo', 0, 'normal', 0,
         '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z')
    ''');

    // 実 migration と同じコードパス（v5→v6）を実行する。
    await db.migration.onUpgrade(Migrator(db), 5, 6);

    final rows = await db.select(db.todos).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'todo-legacy');
    expect(rows.single.name, '既存のTodo');
    // 既定値 'todo' が既存行に自動で入る（後方互換）。
    expect(rows.single.type, 'todo');

    final todo = todoFromRow(rows.single);
    expect(todo.type, TodoItemType.todo);
  });
}
