import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_db.dart';

/// v14→v15 マイグレーション（§7.7 改訂）: genba_memos に kind/content を追加し、
/// 既存メモを自由メモ扱い（kind='free'・content=NULL）へ移行して消さない。
/// memo_templates テーブルを新規作成する。
void main() {
  test('v14→v15: kind/content 追加・既存メモは自由メモ・memo_templates 作成', () async {
    final dir = Directory.systemTemp.createTempSync('oshitrip_memo15');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'app.sqlite'));

    // --- v14 相当（kind/content 無し・memo_templates 無し） ---
    {
      final db = openFileTestDb(file);
      await db.customStatement('SELECT 1');
      await db.customStatement('DROP TABLE genba_memos');
      await db.customStatement('DROP TABLE IF EXISTS memo_templates');
      await db.customStatement(
        'CREATE TABLE genba_memos ('
        'id TEXT NOT NULL PRIMARY KEY, '
        'genba_id TEXT NOT NULL, '
        'owner_id TEXT NOT NULL, '
        'category TEXT NOT NULL, '
        "title TEXT NOT NULL DEFAULT '', "
        "body TEXT NOT NULL DEFAULT '', "
        'sort_order INTEGER NOT NULL DEFAULT 0, '
        'created_at TEXT NOT NULL, '
        'updated_at TEXT NOT NULL)',
      );
      await db.customStatement(
        'INSERT INTO genba_memos '
        '(id, genba_id, owner_id, category, title, body, sort_order, '
        'created_at, updated_at) '
        "VALUES ('mm','g','u','meetup','集合場所','西口',0,"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
      );
      await db.customStatement('PRAGMA user_version = 14');
      await db.close();
    }

    // --- 再open → onUpgrade(14,15) ---
    final db = openFileTestDb(file);
    addTearDown(db.close);
    await db.customStatement('SELECT 1');

    // 既存メモは消えず、kind='free'・content=NULL へ移行。
    final rows = await db.select(db.genbaMemos).get();
    expect(rows, hasLength(1));
    expect(rows.single.kind, 'free');
    expect(rows.single.content, isNull);
    expect(rows.single.title, '集合場所');
    expect(rows.single.body, '西口');

    // memo_templates が作成され、挿入できる。
    await db.into(db.memoTemplates).insert(
          MemoTemplatesCompanion.insert(
            id: 't1',
            ownerId: 'u',
            name: 'マイテンプレ',
            kind: const Value('bingo'),
            createdAt: '2026-01-02T00:00:00.000Z',
            updatedAt: '2026-01-02T00:00:00.000Z',
          ),
        );
    final templates = await db.select(db.memoTemplates).get();
    expect(templates.single.kind, 'bingo');
  });
}
