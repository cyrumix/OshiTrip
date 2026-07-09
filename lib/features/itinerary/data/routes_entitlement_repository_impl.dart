import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/routes_entitlement.dart';

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
    required SupabaseClient? Function() remoteResolver,
  })  : _db = db,
        _ownerId = ownerIdResolver,
        _remote = remoteResolver;

  final AppDatabase _db;
  final String? Function() _ownerId;
  final SupabaseClient? Function() _remote;

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
  Future<Result<void>> refreshFromRemote() async {
    final owner = _ownerId();
    final client = _remote();
    if (owner == null || client == null) return const Ok(null); // デモ/未ログイン

    try {
      final row = await client
          .from('user_entitlements')
          .select('premium_routes_live, updated_at')
          .eq('owner_id', owner)
          .maybeSingle();
      final isPremium = row?['premium_routes_live'] as bool? ?? false;
      final updatedAt = row?['updated_at'] as String? ??
          DateTime.now().toUtc().toIso8601String();
      await _db.into(_db.routesEntitlements).insertOnConflictUpdate(
            RoutesEntitlementsCompanion.insert(
              ownerId: owner,
              premiumRoutesLive: Value(isPremium),
              updatedAt: updatedAt,
            ),
          );
      return const Ok(null);
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }
}
