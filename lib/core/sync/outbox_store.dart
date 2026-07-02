import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../time/clock.dart';
import 'outbox_operation.dart';

/// Outbox の永続化（Drift 実装）。
class OutboxStore {
  OutboxStore(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  String get _nowIso => _clock.now().toUtc().toIso8601String();

  Future<void> enqueue(OutboxOperation op) async {
    await _db.into(_db.outboxOps).insertOnConflictUpdate(
          OutboxOpsCompanion.insert(
            mutationId: op.mutationId,
            ownerId: op.ownerId,
            entityTable: op.entityTable,
            entityId: op.entityId,
            opType: op.opType.name,
            payload: Value(jsonEncode(op.payload)),
            status: Value(op.status.name),
            attempts: Value(op.attempts),
            createdAt: _nowIso,
            updatedAt: _nowIso,
          ),
        );
  }

  Future<List<OutboxOperation>> pendingOps({int limit = 100}) async {
    final rows = await (_db.select(_db.outboxOps)
          ..where((t) => t.status.isIn(const ['pending', 'syncing']))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_toOp).toList();
  }

  Future<void> updateStatus(
    String mutationId,
    OutboxStatus status, {
    String? error,
    bool incrementAttempts = false,
  }) async {
    final current = await (_db.select(_db.outboxOps)
          ..where((t) => t.mutationId.equals(mutationId)))
        .getSingleOrNull();
    if (current == null) return;
    await (_db.update(_db.outboxOps)
          ..where((t) => t.mutationId.equals(mutationId)))
        .write(
      OutboxOpsCompanion(
        status: Value(status.name),
        lastError: Value(error),
        attempts: incrementAttempts
            ? Value(current.attempts + 1)
            : const Value.absent(),
        updatedAt: Value(_nowIso),
      ),
    );
  }

  /// 成功済みopの後片付け。
  Future<void> deleteSynced() =>
      (_db.delete(_db.outboxOps)..where((t) => t.status.equals('synced'))).go();

  /// 失敗した op を再送対象へ戻す（内容は失わない）。
  Future<void> retryFailed() =>
      (_db.update(_db.outboxOps)..where((t) => t.status.equals('failed')))
          .write(
        OutboxOpsCompanion(
          status: const Value('pending'),
          updatedAt: Value(_nowIso),
        ),
      );

  /// 対象エンティティに未同期変更が残っているか（pull時の上書き防止用）。
  Future<bool> hasPendingFor(String entityTable, String entityId) async {
    final row = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.entityTable.equals(entityTable) &
                t.entityId.equals(entityId) &
                t.status.isNotIn(const ['synced']),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// 同期状態サマリの監視（UIバナー用）。
  Stream<Map<OutboxStatus, int>> watchStatusCounts() {
    return _db.select(_db.outboxOps).watch().map((rows) {
      final counts = <OutboxStatus, int>{};
      for (final row in rows) {
        final status = OutboxStatus.values.byName(row.status);
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }

  OutboxOperation _toOp(OutboxOpRow row) => OutboxOperation(
        mutationId: row.mutationId,
        ownerId: row.ownerId,
        entityTable: row.entityTable,
        entityId: row.entityId,
        opType: OutboxOpType.values.byName(row.opType),
        payload: jsonDecode(row.payload) as Map<String, dynamic>,
        status: OutboxStatus.values.byName(row.status),
        attempts: row.attempts,
        lastError: row.lastError,
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );
}
