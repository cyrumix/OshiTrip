import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';

import '../helpers/test_db.dart';

/// R6独立レビュー#5: 既存データに同一 genba の cover が複数あっても、
/// [dedupeMemoryCoversSql] で決定的に1件へ整理してから cover 一意インデックスを
/// 作成すれば migration が失敗しないことを検証する。
///
/// 実 migration（v4→v5）と同じ「dedup → CREATE UNIQUE INDEX」の並びを再現する。
/// 一意インデックスがある状態では複数 cover を投入できないため、テストでは
/// 一旦インデックスを外して重複を作り、dedup 後に再作成する。
void main() {
  Future<void> insertPhoto(
    AppDatabase db, {
    required String id,
    required String genbaId,
    required int sortOrder,
    required bool cover,
    required String createdAt,
  }) {
    return db.into(db.memoryPhotos).insert(
          MemoryPhotosCompanion.insert(
            id: id,
            genbaId: genbaId,
            ownerId: 'user-1',
            isCover: Value(cover),
            sortOrder: Value(sortOrder),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
  }

  Future<int> coverCountFor(AppDatabase db, String genbaId) async {
    final rows = await (db.select(db.memoryPhotos)
          ..where((t) => t.genbaId.equals(genbaId) & t.isCover.equals(true)))
        .get();
    return rows.length;
  }

  test('複数 cover を含む状態から dedup→索引再作成で、決定的に1件だけ残る', () async {
    final db = createTestDb();
    addTearDown(db.close);

    // 一意インデックスを外して重複 cover を投入できる状態にする。
    await db
        .customStatement('DROP INDEX IF EXISTS idx_memory_photos_cover_unique');

    // g1: 3枚すべて cover。保持規則(sort_order→created_at→id 昇順の最小)で
    // p-b（sort_order=0）が残るはず。
    await insertPhoto(
      db,
      id: 'p-a',
      genbaId: 'g1',
      sortOrder: 2,
      cover: true,
      createdAt: '2026-01-03',
    );
    await insertPhoto(
      db,
      id: 'p-b',
      genbaId: 'g1',
      sortOrder: 0,
      cover: true,
      createdAt: '2026-01-02',
    );
    await insertPhoto(
      db,
      id: 'p-c',
      genbaId: 'g1',
      sortOrder: 1,
      cover: true,
      createdAt: '2026-01-01',
    );
    // g2: 別 genba にも重複 cover（genba ごとに独立して1件残る）。
    await insertPhoto(
      db,
      id: 'q-a',
      genbaId: 'g2',
      sortOrder: 5,
      cover: true,
      createdAt: '2026-02-02',
    );
    await insertPhoto(
      db,
      id: 'q-b',
      genbaId: 'g2',
      sortOrder: 5,
      cover: true,
      createdAt: '2026-02-01',
    );

    expect(await coverCountFor(db, 'g1'), 3);
    expect(await coverCountFor(db, 'g2'), 2);

    // 実 migration と同じ手順: dedup → 一意インデックス作成。
    await db.customStatement(dedupeMemoryCoversSql);
    // dedup 後は索引作成が成功する（重複が無いため）。
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_memory_photos_cover_unique '
      'ON memory_photos (genba_id) WHERE is_cover',
    );

    // 各 genba で cover はちょうど1件。
    expect(await coverCountFor(db, 'g1'), 1);
    expect(await coverCountFor(db, 'g2'), 1);

    // 決定的に選ばれた1件を確認する。
    final g1Cover = await (db.select(db.memoryPhotos)
          ..where((t) => t.genbaId.equals('g1') & t.isCover.equals(true)))
        .getSingle();
    expect(g1Cover.id, 'p-b'); // sort_order=0 が最小
    final g2Cover = await (db.select(db.memoryPhotos)
          ..where((t) => t.genbaId.equals('g2') & t.isCover.equals(true)))
        .getSingle();
    expect(g2Cover.id, 'q-b'); // sort_order 同値 → created_at が早い方

    // 索引が有効になっていることも確認する（2件目の cover 投入は失敗する）。
    await expectLater(
      insertPhoto(
        db,
        id: 'p-d',
        genbaId: 'g1',
        sortOrder: 9,
        cover: true,
        createdAt: '2026-01-09',
      ),
      throwsA(anything),
    );
  });
}
