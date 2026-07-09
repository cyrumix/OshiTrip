import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_db.dart';

/// v15→v16 マイグレーション（旅程Phase 4）: routes_entitlements テーブルを
/// 新規追加する。既存データには一切触れない（新規テーブル追加のみ）。
void main() {
  test('v15→v16: routes_entitlements が新規作成され、既存データは無傷', () async {
    final dir = Directory.systemTemp.createTempSync('oshitrip_routes16');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'app.sqlite'));

    // --- v15 相当（routes_entitlements 無し） ---
    {
      final db = openFileTestDb(file);
      await db.customStatement('SELECT 1');
      await db.customStatement('DROP TABLE IF EXISTS routes_entitlements');
      await db.customStatement(
        'INSERT INTO genba_memos '
        '(id, genba_id, owner_id, category, title, body, sort_order, '
        'kind, created_at, updated_at) '
        "VALUES ('mm','g','u','other','既存メモ','本文',0,'free',"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
      );
      await db.customStatement('PRAGMA user_version = 15');
      await db.close();
    }

    // --- 再open → onUpgrade(15,16) ---
    final db = openFileTestDb(file);
    addTearDown(db.close);
    await db.customStatement('SELECT 1');

    // 既存メモは無傷。
    final memos = await db.select(db.genbaMemos).get();
    expect(memos, hasLength(1));
    expect(memos.single.title, '既存メモ');

    // routes_entitlements が作成され、挿入・既定値検証ができる。
    await db.into(db.routesEntitlements).insert(
          RoutesEntitlementsCompanion.insert(
            ownerId: 'u',
            updatedAt: '2026-01-02T00:00:00.000Z',
          ),
        );
    final rows = await db.select(db.routesEntitlements).get();
    expect(rows.single.ownerId, 'u');
    expect(rows.single.premiumRoutesLive, isFalse); // 既定は非プレミアム

    // 明示指定も可能。
    await db.into(db.routesEntitlements).insertOnConflictUpdate(
          RoutesEntitlementsCompanion.insert(
            ownerId: 'u',
            premiumRoutesLive: const Value(true),
            updatedAt: '2026-01-03T00:00:00.000Z',
          ),
        );
    final updated = await db.select(db.routesEntitlements).get();
    expect(updated.single.premiumRoutesLive, isTrue);
  });
}
