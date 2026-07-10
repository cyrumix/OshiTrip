import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/time/clock.dart';
import '../domain/routes_entitlement.dart';

/// 現在ownerの entitlement をリモートから1行取得する関数。
///
/// デモ・未ログイン時は null を返すこと（呼び出し側の refresh を no-op 化する）。
/// 本番実装（providers.dart）は Supabase を `.withRemoteTimeout()` 付きで叩く。
/// この seam により、実 Supabase 接続なしに timeout/成功/失敗の各経路を単体
/// テストできる（`ConflictResolver` の `fetchRemoteRows` と同じ設計）。
typedef EntitlementFetcher = Future<Map<String, dynamic>?> Function(
  String owner,
);

/// [RoutesEntitlementRepository] の実装。`routes_entitlements`（owner単位で1行、
/// クライアントは書き込まない読み取り専用レプリカ）を Drift から監視し、
/// Supabase `user_entitlements` から明示的に取り込む。
///
/// 既存の owner スコープ集約（[GenbaRepositoryImpl]等）が使う ID 差分同期
/// （`_pullTable`/Outbox）は、複数行・ID主キーのテーブルを前提にしており、
/// このテーブル（owner_id 主キー・単一行・クライアント書込み無し）には合わない
/// ため、単純な fetch→upsert に留める。
class RoutesEntitlementRepositoryImpl implements RoutesEntitlementRepository {
  RoutesEntitlementRepositoryImpl({
    required AppDatabase db,
    required String? Function() ownerIdResolver,
    required EntitlementFetcher? Function() fetcherResolver,
    Clock clock = const SystemClock(),
  })  : _db = db,
        _ownerId = ownerIdResolver,
        _fetcherResolver = fetcherResolver,
        _clock = clock;

  final AppDatabase _db;
  final String? Function() _ownerId;
  final Clock _clock;

  /// デモ・未ログイン時は null（refresh を no-op 化）。ログイン時は Supabase を
  /// `.withRemoteTimeout()` 付きで叩く fetcher を返す（providers.dart が供給）。
  final EntitlementFetcher? Function() _fetcherResolver;

  @override
  Stream<bool> watchIsPremium() {
    final owner = _ownerId();
    if (owner == null) return Stream.value(false);
    final query = _db.select(_db.routesEntitlements)
      ..where((t) => t.ownerId.equals(owner));
    return query
        .watchSingleOrNull()
        .map((row) => row?.premiumRoutesLive ?? false);
  }

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    final owner = _ownerId();
    final fetch = _fetcherResolver();
    if (owner == null || fetch == null) return const Ok(null); // デモ/未ログイン

    try {
      // fetcher 側で共通タイムアウト（`.withRemoteTimeout()`）を課す。TimeoutException
      // はここで NetworkFailure へ変換する（R8-C の通信タイムアウト方針）。
      final row = await fetch(owner);
      final isPremium = row?['premium_routes_live'] as bool? ?? false;
      final updatedAt = row?['updated_at'] as String? ??
          _clock.now().toUtc().toIso8601String();
      await applyEntitlement(
        owner: owner,
        isPremium: isPremium,
        updatedAt: updatedAt,
        isStale: isStale,
      );
      return const Ok(null);
    } on TimeoutException catch (e) {
      return Err(NetworkFailure(cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  /// 取得済みの entitlement をローカルへ適用する。書き込み直前に
  /// `isStale() == true`（別owner／世代交代／pause）なら、前owner の値を書かず
  /// 何もしない（C-01 / H-02）。
  ///
  /// `@visibleForTesting`: Supabase への実接続なしに isStale による書き込み抑止を
  /// 単体テストするための公開。プロダクションからは [refreshFromRemote] 経由でのみ
  /// 呼ばれる。
  @visibleForTesting
  Future<void> applyEntitlement({
    required String owner,
    required bool isPremium,
    required String updatedAt,
    bool Function()? isStale,
  }) async {
    if (isStale?.call() ?? false) return; // 認証切替後は前owner値を書かない
    await _db.into(_db.routesEntitlements).insertOnConflictUpdate(
          RoutesEntitlementsCompanion.insert(
            ownerId: owner,
            premiumRoutesLive: Value(isPremium),
            updatedAt: updatedAt,
          ),
        );
  }
}
