import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';

import '../helpers/test_db.dart';

/// v7→v8マイグレーション（itinerary_* 5テーブル追加）で、既存データを失わず、
/// 新テーブルが利用可能になることを検証する。
///
/// [createTestDb] は最新スキーマ（v8, onCreate）で作られるため、v7相当の
/// 状態（itinerary_* が無い）を再現してから、本番と同じ
/// [AppDatabase.migration] の onUpgrade(7, 8) を実行する
/// （todo_type_migration_test.dart と同じ「実migrationの手順を再現する」方針）。
void main() {
  test('v7→v8マイグレーション後も既存データが保持され、旅程テーブルが使えるようになる', () async {
    final db = createTestDb();
    addTearDown(db.close);

    // v7相当（itinerary_* テーブルが無い）を再現する。
    await db.customStatement('DROP TABLE itinerary_legs');
    await db.customStatement('DROP TABLE itinerary_entries');
    await db.customStatement('DROP TABLE itinerary_spot_links');
    await db.customStatement('DROP TABLE itinerary_spots');
    await db.customStatement('DROP TABLE itinerary_plans');

    // 既存データ（v7以前に存在する genba）を入れておく。
    await db.into(db.genbas).insert(
          GenbasCompanion.insert(
            id: 'genba-legacy',
            ownerId: 'user-1',
            artistName: 'アーティスト',
            title: '既存公演',
            eventDate: '2026-08-01',
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );

    // 実 migration と同じコードパス（v7→v8）を実行する。
    await db.migration.onUpgrade(Migrator(db), 7, 8);

    // 既存 genba は失われない。
    final genbas = await db.select(db.genbas).get();
    expect(genbas, hasLength(1));
    expect(genbas.single.id, 'genba-legacy');
    expect(genbas.single.title, '既存公演');

    // 旅程テーブルが作成され、書き込み・読み出しできる。
    await db.into(db.itineraryPlans).insert(
          ItineraryPlansCompanion.insert(
            id: 'plan-1',
            genbaId: 'genba-legacy',
            ownerId: 'user-1',
            title: '新規計画',
            timeZoneId: 'Asia/Tokyo',
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );
    final plans = await db.select(db.itineraryPlans).get();
    expect(plans, hasLength(1));
    expect(plans.single.title, '新規計画');

    // 他の旅程テーブルも存在する（select が例外にならない）。
    expect(await db.select(db.itinerarySpots).get(), isEmpty);
    expect(await db.select(db.itinerarySpotLinks).get(), isEmpty);
    expect(await db.select(db.itineraryEntries).get(), isEmpty);
    expect(await db.select(db.itineraryLegs).get(), isEmpty);
  });
}
