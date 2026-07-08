import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:path/path.dart' as p;

import '../helpers/test_db.dart';

/// 思い出アルバム（§8.4）: 写真の分類・関連項目・表紙のドメイン整理と、
/// v12→v13 マイグレーション（既存写真を event へ移行し消さない）を検証する。
void main() {
  MemoryPhoto photo(
    String id, {
    MemoryAlbumCategory category = MemoryAlbumCategory.event,
    String? subjectId,
    MemorySubjectType? subjectType,
    bool cover = false,
    int sortOrder = 0,
    int day = 1,
  }) =>
      MemoryPhoto(
        id: id,
        genbaId: 'g',
        ownerId: 'u',
        albumCategory: category,
        subjectId: subjectId,
        subjectType: subjectType,
        isCover: cover,
        sortOrder: sortOrder,
        createdAt: DateTime.utc(2026, 1, day),
        updatedAt: DateTime.utc(2026, 1, day),
      );

  group('memoryPhotoShapeError（分類と関連の形状不変条件, §8.4/Issue3）', () {
    MemoryPhoto p({
      required MemoryAlbumCategory album,
      MemorySubjectType? type,
      String? subjectId,
    }) =>
        MemoryPhoto(
          id: 'x',
          genbaId: 'g',
          ownerId: 'u',
          albumCategory: album,
          subjectType: type,
          subjectId: subjectId,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        );

    test('許可: event(subject無) / goods・場所・食べもの(正しい関連) / 関連解除(両方null)', () {
      expect(
        memoryPhotoShapeError(p(album: MemoryAlbumCategory.event)),
        isNull,
      );
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.goods,
            type: MemorySubjectType.goods,
            subjectId: 'g1',
          ),
        ),
        isNull,
      );
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.visitedPlace,
            type: MemorySubjectType.visitedPlace,
            subjectId: 'v1',
          ),
        ),
        isNull,
      );
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.food,
            type: MemorySubjectType.visitedPlace,
            subjectId: 'v1',
          ),
        ),
        isNull,
      );
      // 関連解除済み（アルバムに残す）: 分類は維持、両方 null。
      expect(
        memoryPhotoShapeError(p(album: MemoryAlbumCategory.goods)),
        isNull,
      );
      expect(
        memoryPhotoShapeError(p(album: MemoryAlbumCategory.food)),
        isNull,
      );
    });

    test('拒否: event+subject / 片方だけ / 種別不一致', () {
      // event に subject を設定。
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.event,
            type: MemorySubjectType.goods,
          ),
        ),
        isNotNull,
      );
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.event,
            subjectId: 'g1',
          ),
        ),
        isNotNull,
      );
      // subjectType だけ（id 無し）。
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.goods,
            type: MemorySubjectType.goods,
          ),
        ),
        isNotNull,
      );
      // subjectId だけ（type 無し）。
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.goods,
            subjectId: 'g1',
          ),
        ),
        isNotNull,
      );
      // goods から visited_place を参照（種別不一致）。
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.goods,
            type: MemorySubjectType.visitedPlace,
            subjectId: 'v1',
          ),
        ),
        isNotNull,
      );
      // food から goods 種別を参照（種別不一致）。
      expect(
        memoryPhotoShapeError(
          p(
            album: MemoryAlbumCategory.food,
            type: MemorySubjectType.goods,
            subjectId: 'g1',
          ),
        ),
        isNotNull,
      );
    });
  });

  group('MemoryBundle アルバム整理', () {
    final bundle = MemoryBundle(
      genbaId: 'g',
      photos: [
        photo('p-food', category: MemoryAlbumCategory.food, sortOrder: 2),
        photo(
          'p-goods',
          category: MemoryAlbumCategory.goods,
          subjectId: 'goods-1',
          subjectType: MemorySubjectType.goods,
          sortOrder: 1,
        ),
        photo('p-event', cover: true, sortOrder: 0),
      ],
    );

    test('分類フィルタ: null は全件、指定分類はその分類のみ', () {
      // sort_order 昇順。
      expect(
        bundle.photosInAlbum(null).map((p) => p.id),
        ['p-event', 'p-goods', 'p-food'],
      );
      expect(
        bundle.photosInAlbum(MemoryAlbumCategory.goods).map((p) => p.id),
        ['p-goods'],
      );
      expect(bundle.photosInAlbum(MemoryAlbumCategory.visitedPlace), isEmpty);
    });

    test('関連項目フィルタ: subject_id 一致の写真だけ返す', () {
      expect(bundle.photosForSubject('goods-1').map((p) => p.id), ['p-goods']);
      expect(bundle.photosForSubject('missing'), isEmpty);
    });

    test('表紙: is_cover 優先、無ければ先頭', () {
      expect(bundle.coverPhoto?.id, 'p-event');
      final noCover = MemoryBundle(
        genbaId: 'g',
        photos: [photo('a', sortOrder: 5), photo('b', sortOrder: 1)],
      );
      expect(noCover.coverPhoto?.id, 'b'); // sort_order 最小
      expect(const MemoryBundle(genbaId: 'g').coverPhoto, isNull);
    });
  });

  test('v12→v13 マイグレーション: 既存写真が event へ移行し、新列が付く', () async {
    final dir = Directory.systemTemp.createTempSync('oshitrip_album_mig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'app.sqlite'));

    // --- v12 相当（album_category/subject_type/subject_id 無し） ---
    {
      final db = openFileTestDb(file);
      await db.customStatement('SELECT 1');
      await db.customStatement('DROP TABLE memory_photos');
      await db.customStatement(
        'CREATE TABLE memory_photos ('
        'id TEXT NOT NULL PRIMARY KEY, '
        'genba_id TEXT NOT NULL, '
        'owner_id TEXT NOT NULL, '
        'local_path TEXT, '
        'storage_path TEXT, '
        "upload_status TEXT NOT NULL DEFAULT 'local_only', "
        'caption TEXT, '
        'is_cover INTEGER NOT NULL DEFAULT 0, '
        'sort_order INTEGER NOT NULL DEFAULT 0, '
        'created_at TEXT NOT NULL, '
        'updated_at TEXT NOT NULL)',
      );
      await db.customStatement(
        'INSERT INTO memory_photos (id, genba_id, owner_id, is_cover, '
        "sort_order, created_at, updated_at) VALUES ('ph','g','u',0,0,"
        "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
      );
      await db.customStatement('PRAGMA user_version = 12');
      await db.close();
    }

    // --- 再open → onUpgrade(12,13) ---
    final db = openFileTestDb(file);
    addTearDown(db.close);
    await db.customStatement('SELECT 1');

    // 既存写真は消えず、当日の写真(event)へ移行、subject は null。
    final rows = await db.select(db.memoryPhotos).get();
    expect(rows, hasLength(1));
    expect(rows.single.albumCategory, 'event');
    expect(rows.single.subjectType, isNull);
    expect(rows.single.subjectId, isNull);

    // 新列を使ったグッズ写真の追加ができる。
    await db.into(db.memoryPhotos).insert(
          MemoryPhotosCompanion.insert(
            id: 'ph2',
            genbaId: 'g',
            ownerId: 'u',
            albumCategory: const Value('goods'),
            subjectType: const Value('goods'),
            subjectId: const Value('goods-1'),
            createdAt: '2026-01-02T00:00:00.000Z',
            updatedAt: '2026-01-02T00:00:00.000Z',
          ),
        );
    final goodsRows = await (db.select(db.memoryPhotos)
          ..where((t) => t.albumCategory.equals('goods')))
        .get();
    expect(goodsRows.single.subjectId, 'goods-1');
  });
}
