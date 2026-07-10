import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_db.dart';

/// v16→v17 マイグレーション（Phase 5 前提基盤）: genba_shares テーブルを新規追加
/// する。既存データには一切触れない（新規テーブル追加のみ）。
void main() {
  test('v16→v17: genba_shares が新規作成され、既存データは無傷', () async {
    final dir = Directory.systemTemp.createTempSync('oshitrip_shares17');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'app.sqlite'));

    // --- v16 相当（genba_shares 無し） ---
    {
      final db = openFileTestDb(file);
      await db.customStatement('SELECT 1');
      await db.customStatement('DROP TABLE IF EXISTS genba_shares');
      // 既存メモを1件入れておき、移行で消えないことを確認する。
      await db.customStatement(
        'INSERT INTO genba_memos '
        '(id, genba_id, owner_id, category, title, body, sort_order, '
        'kind, created_at, updated_at) '
        "VALUES ('mm','g','u','other','既存メモ','本文',0,'free',"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
      );
      await db.customStatement('PRAGMA user_version = 16');
      await db.close();
    }

    // --- 再open → onUpgrade(16,17) ---
    final db = openFileTestDb(file);
    addTearDown(db.close);
    await db.customStatement('SELECT 1');

    // 既存メモは無傷。
    final memos = await db.select(db.genbaMemos).get();
    expect(memos, hasLength(1));
    expect(memos.single.title, '既存メモ');

    // genba_shares が作成され、挿入・既定値検証ができる。
    await db.into(db.genbaShares).insert(
          GenbaSharesCompanion.insert(
            id: 's1',
            ownerId: 'u',
            genbaId: 'g',
            granteeId: 'u2',
            role: 'viewer',
            createdAt: '2026-01-02T00:00:00.000Z',
            updatedAt: '2026-01-02T00:00:00.000Z',
          ),
        );
    final rows = await db.select(db.genbaShares).get();
    expect(rows.single.granteeId, 'u2');
    expect(rows.single.role, 'viewer');
    // 項目grant の既定は false（安全側）、version 既定は 1。
    expect(rows.single.grantAddress, isFalse);
    expect(rows.single.grantTicketImage, isFalse);
    expect(rows.single.version, 1);

    // 明示指定も可能。
    await db.into(db.genbaShares).insertOnConflictUpdate(
          GenbaSharesCompanion.insert(
            id: 's1',
            ownerId: 'u',
            genbaId: 'g',
            granteeId: 'u2',
            role: 'editor',
            grantAddress: const Value(true),
            createdAt: '2026-01-02T00:00:00.000Z',
            updatedAt: '2026-01-03T00:00:00.000Z',
          ),
        );
    final updated = await db.select(db.genbaShares).get();
    expect(updated.single.role, 'editor');
    expect(updated.single.grantAddress, isTrue);
  });
}
