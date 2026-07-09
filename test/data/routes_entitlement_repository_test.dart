import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/features/itinerary/data/routes_entitlement_repository_impl.dart';

import '../helpers/test_db.dart';

/// 旅程Phase 4: entitlementの読み取り専用境界。owner分離・行なし時の既定値
/// （非プレミアム）・デモ/未ログイン時のrefreshFromRemote no-opを検証する。
/// 実HTTP（Supabase）呼び出しはこのテストの対象外（remoteResolver: null の
/// no-opパスのみを検証する。実フェッチはEdge Function同様、各実環境で確認）。
void main() {
  test('未認証（owner無し）はfalseを返す', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => null,
      remoteResolver: () => null,
    );
    expect(await repo.watchIsPremium().first, isFalse);
  });

  test('行が無いownerはfalseを返す', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    expect(await repo.watchIsPremium().first, isFalse);
  });

  test('行がありpremium=trueならtrueを返す', () async {
    final db = createTestDb();
    addTearDown(db.close);
    await db.into(db.routesEntitlements).insert(
          RoutesEntitlementsCompanion.insert(
            ownerId: 'user-1',
            premiumRoutesLive: const Value(true),
            updatedAt: '2026-07-09T00:00:00.000Z',
          ),
        );
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    expect(await repo.watchIsPremium().first, isTrue);
  });

  test('別ownerの行は見えない（owner分離）', () async {
    final db = createTestDb();
    addTearDown(db.close);
    await db.into(db.routesEntitlements).insert(
          RoutesEntitlementsCompanion.insert(
            ownerId: 'user-1',
            premiumRoutesLive: const Value(true),
            updatedAt: '2026-07-09T00:00:00.000Z',
          ),
        );
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => 'user-2',
      remoteResolver: () => null,
    );
    expect(await repo.watchIsPremium().first, isFalse);
  });

  test('refreshFromRemote はデモ/未ログイン（remote=null）で何もしない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    final result = await repo.refreshFromRemote();
    expect(result.isOk, isTrue);
    expect(await db.select(db.routesEntitlements).get(), isEmpty);
  });

  test('refreshFromRemote は未認証（owner無し）でも何もしない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => null,
      remoteResolver: () => null,
    );
    final result = await repo.refreshFromRemote();
    expect(result.isOk, isTrue);
    expect(await db.select(db.routesEntitlements).get(), isEmpty);
  });

  group('applyEntitlement の isStale 書き込み抑止（修正3）', () {
    RoutesEntitlementRepositoryImpl repoFor(AppDatabase db) =>
        RoutesEntitlementRepositoryImpl(
          db: db,
          ownerIdResolver: () => 'user-1',
          remoteResolver: () => null,
        );

    test('isStale が true なら取得結果をローカルへ書き込まない', () async {
      final db = createTestDb();
      addTearDown(db.close);
      await repoFor(db).applyEntitlement(
        owner: 'user-1',
        isPremium: true,
        updatedAt: '2026-07-09T00:00:00.000Z',
        isStale: () => true, // 認証切替後
      );
      expect(await db.select(db.routesEntitlements).get(), isEmpty);
    });

    test('isStale が false なら書き込む', () async {
      final db = createTestDb();
      addTearDown(db.close);
      await repoFor(db).applyEntitlement(
        owner: 'user-1',
        isPremium: true,
        updatedAt: '2026-07-09T00:00:00.000Z',
        isStale: () => false,
      );
      final rows = await db.select(db.routesEntitlements).get();
      expect(rows.single.ownerId, 'user-1');
      expect(rows.single.premiumRoutesLive, isTrue);
    });

    test('isStale 未指定でも書き込む（従来動作）', () async {
      final db = createTestDb();
      addTearDown(db.close);
      await repoFor(db).applyEntitlement(
        owner: 'user-1',
        isPremium: false,
        updatedAt: '2026-07-09T00:00:00.000Z',
      );
      expect(await db.select(db.routesEntitlements).get(), hasLength(1));
    });
  });
}
