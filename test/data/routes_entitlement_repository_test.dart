import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/itinerary/data/routes_entitlement_repository_impl.dart';

import '../helpers/test_db.dart';

/// 旅程Phase 4: entitlementの読み取り専用境界。owner分離・行なし時の既定値
/// （非プレミアム）・デモ/未ログイン時のno-op・fetcher seam経由の
/// timeout/成功/失敗/isStale全経路を検証する（実Supabase接続なし）。
void main() {
  test('未認証（owner無し）はfalseを返す', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => null,
      fetcherResolver: () => null,
    );
    expect(await repo.watchIsPremium().first, isFalse);
  });

  test('行が無いownerはfalseを返す', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => 'user-1',
      fetcherResolver: () => null,
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
      fetcherResolver: () => null,
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
      fetcherResolver: () => null,
    );
    expect(await repo.watchIsPremium().first, isFalse);
  });

  test('refreshFromRemote はデモ/未ログイン（fetcher=null）で何もしない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = RoutesEntitlementRepositoryImpl(
      db: db,
      ownerIdResolver: () => 'user-1',
      fetcherResolver: () => null,
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
      fetcherResolver: () => (_) async => {'premium_routes_live': true},
    );
    final result = await repo.refreshFromRemote();
    expect(result.isOk, isTrue);
    expect(await db.select(db.routesEntitlements).get(), isEmpty);
  });

  group('refreshFromRemote の fetcher 経路（回帰）', () {
    RoutesEntitlementRepositoryImpl repoWith(
      AppDatabase db,
      EntitlementFetcher fetcher, {
      String owner = 'user-1',
    }) =>
        RoutesEntitlementRepositoryImpl(
          db: db,
          ownerIdResolver: () => owner,
          fetcherResolver: () => fetcher,
        );

    test('取得成功（premium=true）でローカルへ書き込む', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final repo = repoWith(
        db,
        (_) async => {
          'premium_routes_live': true,
          'updated_at': '2026-07-09T00:00:00.000Z',
        },
      );
      final result = await repo.refreshFromRemote();
      expect(result.isOk, isTrue);
      final rows = await db.select(db.routesEntitlements).get();
      expect(rows.single.premiumRoutesLive, isTrue);
    });

    test('行なし（null）は premium=false として書き込む', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final repo = repoWith(db, (_) async => null);
      await repo.refreshFromRemote();
      final rows = await db.select(db.routesEntitlements).get();
      expect(rows.single.premiumRoutesLive, isFalse);
    });

    test('TimeoutException は NetworkFailure。ローカルへ書き込まない', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final repo = repoWith(db, (_) async => throw TimeoutException('slow'));
      final result = await repo.refreshFromRemote();
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(await db.select(db.routesEntitlements).get(), isEmpty);
    });

    test('通信断（一般例外）も NetworkFailure', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final repo = repoWith(db, (_) async => throw StateError('down'));
      final result = await repo.refreshFromRemote();
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('認証切替（isStale=true）なら取得できても前owner値を書き込まない', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final repo = repoWith(
        db,
        (_) async => {'premium_routes_live': true},
      );
      final result = await repo.refreshFromRemote(isStale: () => true);
      expect(result.isOk, isTrue);
      expect(await db.select(db.routesEntitlements).get(), isEmpty);
    });
  });

  group('applyEntitlement の isStale 書き込み抑止', () {
    RoutesEntitlementRepositoryImpl repoFor(AppDatabase db) =>
        RoutesEntitlementRepositoryImpl(
          db: db,
          ownerIdResolver: () => 'user-1',
          fetcherResolver: () => null,
        );

    test('isStale が true なら取得結果をローカルへ書き込まない', () async {
      final db = createTestDb();
      addTearDown(db.close);
      await repoFor(db).applyEntitlement(
        owner: 'user-1',
        isPremium: true,
        updatedAt: '2026-07-09T00:00:00.000Z',
        isStale: () => true,
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
  });
}
