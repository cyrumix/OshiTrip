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
    // 別 owner が発行済みの mutationId を横取り（上書き）できないよう検証する
    // （C-01 防御強化）。UUIDv4 の衝突は現実的に起きないが、多層防御として
    // 既存行の owner 不一致を明示的に拒否する。
    final existing = await (_db.select(_db.outboxOps)
          ..where((t) => t.mutationId.equals(op.mutationId))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null && existing.ownerId != op.ownerId) {
      throw StateError(
        'Outbox mutationId が別ownerに属します（owner不一致のenqueueを拒否）',
      );
    }
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

  /// [ownerId] の pending/syncing 操作のみを返す（C-01: 別ownerの操作を
  /// remoteへ渡さないための境界）。バックオフ待機は考慮しない（状態確認用）。
  Future<List<OutboxOperation>> pendingOps({
    required String ownerId,
    int limit = 100,
  }) async {
    final rows = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.status.isIn(const ['pending', 'syncing']) &
                t.ownerId.equals(ownerId),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (_) => OrderingTerm.asc(_rowid),
          ])
          ..limit(limit))
        .get();
    return rows.map(_toOp).toList();
  }

  /// [ownerId] の「今すぐ送ってよい」操作を返す（H-02）。
  ///
  /// バックオフ待機中（next_retry_at が [now] より未来）の op は除外する。
  /// next_retry_at が null の op は即送信可。作成順で返す（順序保持）。
  /// created_at が同値のとき（固定Clockのテスト等）も挿入順を保つため、
  /// 第二キーに rowid（挿入順）を用いる。
  Future<List<OutboxOperation>> dueOps({
    required String ownerId,
    required DateTime now,
    int limit = 100,
  }) async {
    final nowIso = now.toUtc().toIso8601String();
    final rows = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.status.isIn(const ['pending', 'syncing']) &
                t.ownerId.equals(ownerId) &
                (t.nextRetryAt.isNull() |
                    t.nextRetryAt.isSmallerOrEqualValue(nowIso)),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (_) => OrderingTerm.asc(_rowid),
          ])
          ..limit(limit))
        .get();
    return rows.map(_toOp).toList();
  }

  /// 実行順の安定化に使う暗黙 rowid（挿入順）。
  static const Expression<int> _rowid = CustomExpression<int>('rowid');

  /// [ownerId] に「まだ送っていない（pending/syncing）」op が残っているか。
  /// バックオフ待機中を含む（UI/coordinator の判断用）。
  Future<bool> hasUnsent({required String ownerId}) async {
    final row = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.status.isIn(const ['pending', 'syncing']) &
                t.ownerId.equals(ownerId),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// [mutationId] の状態を更新する。[ownerId] を必須にし、別ownerの操作を
  /// 変更できないようにする（C-01 防御強化）。owner が一致する行のみ更新する。
  ///
  /// [nextRetryAt] を渡すとバックオフ待機時刻を保存する（H-02）。null を明示
  /// したい場合は [clearNextRetryAt] を true にする（成功・即送信可へ戻す時）。
  Future<void> updateStatus(
    String mutationId,
    OutboxStatus status, {
    required String ownerId,
    String? error,
    bool incrementAttempts = false,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
  }) async {
    final current = await (_db.select(_db.outboxOps)
          ..where(
            (t) => t.mutationId.equals(mutationId) & t.ownerId.equals(ownerId),
          ))
        .getSingleOrNull();
    // 存在しない、または別ownerの mutationId は変更しない。
    if (current == null) return;
    await (_db.update(_db.outboxOps)
          ..where(
            (t) => t.mutationId.equals(mutationId) & t.ownerId.equals(ownerId),
          ))
        .write(
      OutboxOpsCompanion(
        status: Value(status.name),
        lastError: Value(error),
        attempts: incrementAttempts
            ? Value(current.attempts + 1)
            : const Value.absent(),
        nextRetryAt: clearNextRetryAt
            ? const Value(null)
            : (nextRetryAt == null
                ? const Value.absent()
                : Value(nextRetryAt.toUtc().toIso8601String())),
        updatedAt: Value(_nowIso),
      ),
    );
  }

  /// [ownerId] の成功済みopの後片付け。他ownerの行には触れない。
  Future<void> deleteSynced({required String ownerId}) =>
      (_db.delete(_db.outboxOps)
            ..where(
              (t) => t.status.equals('synced') & t.ownerId.equals(ownerId),
            ))
          .go();

  /// [ownerId] の失敗した op を再送対象へ戻す（内容は失わない）。
  /// 手動再試行なのでバックオフ待機（next_retry_at）も解除して即送信可にする。
  Future<void> retryFailed({required String ownerId}) =>
      (_db.update(_db.outboxOps)
            ..where(
              (t) => t.status.equals('failed') & t.ownerId.equals(ownerId),
            ))
          .write(
        OutboxOpsCompanion(
          status: const Value('pending'),
          nextRetryAt: const Value(null),
          updatedAt: Value(_nowIso),
        ),
      );

  /// [ownerId] の競合(conflict)状態の操作を作成順で返す（解決UI用）。
  /// 別ownerの競合は返さない（C-01）。
  Future<List<OutboxOperation>> conflictOps({required String ownerId}) async {
    final rows = await (_db.select(_db.outboxOps)
          ..where(
            (t) => t.status.equals('conflict') & t.ownerId.equals(ownerId),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (_) => OrderingTerm.asc(_rowid),
          ]))
        .get();
    return rows.map(_toOp).toList();
  }

  /// [mutationId] の操作を状態不問で返す（owner一致のみ）。競合解決後の
  /// 状態確認（drain 後に synced=削除／conflict／pending 等を判別）に使う。
  Future<OutboxOperation?> opById(
    String mutationId, {
    required String ownerId,
  }) async {
    final row = await (_db.select(_db.outboxOps)
          ..where(
            (t) => t.mutationId.equals(mutationId) & t.ownerId.equals(ownerId),
          ))
        .getSingleOrNull();
    return row == null ? null : _toOp(row);
  }

  /// [mutationId] の競合操作を返す（owner一致かつ status==conflict のときのみ）。
  /// 解決処理が対象エンティティ（table/id）を知るために使う。
  Future<OutboxOperation?> conflictById(
    String mutationId, {
    required String ownerId,
  }) async {
    final row = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.mutationId.equals(mutationId) &
                t.ownerId.equals(ownerId) &
                t.status.equals('conflict'),
          ))
        .getSingleOrNull();
    return row == null ? null : _toOp(row);
  }

  /// 競合操作を破棄する（「サーバーの内容を採用」= この端末の変更を捨てる）。
  ///
  /// owner一致かつ status==conflict の行のみ削除する（別ownerの競合や、
  /// 競合以外の状態の行は変更しない）。削除できたら true。
  /// 上書き競合を黙って pending/failed へ戻すのではなく、ユーザーが明示的に
  /// 「破棄」を選んだときだけ削除する（conflictの黙殺をしない）。
  Future<bool> discardConflict(
    String mutationId, {
    required String ownerId,
  }) async {
    final deleted = await (_db.delete(_db.outboxOps)
          ..where(
            (t) =>
                t.mutationId.equals(mutationId) &
                t.ownerId.equals(ownerId) &
                t.status.equals('conflict'),
          ))
        .go();
    return deleted > 0;
  }

  /// 競合操作を pending へ戻して再送対象にする（「この端末の変更で再送」）。
  ///
  /// owner一致かつ status==conflict の行のみ対象。バックオフ待機も解除する。
  /// **base_version は変えない**ため、サーバーが依然として先行していれば
  /// 再び conflict に戻る（上書き競合を隠さず、安全に再判定される）。
  /// 「この端末の変更を実際にサーバーへ反映させる」には、呼び出し側が事前に
  /// 版キャッシュをサーバーの現在版へ整合させておく必要がある
  /// （[reconcileServerVersionInto] 参照）。戻せたら true。
  Future<bool> reopenConflict(
    String mutationId, {
    required String ownerId,
  }) async {
    final current = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.mutationId.equals(mutationId) &
                t.ownerId.equals(ownerId) &
                t.status.equals('conflict'),
          ))
        .getSingleOrNull();
    if (current == null) return false;
    await (_db.update(_db.outboxOps)
          ..where(
            (t) =>
                t.mutationId.equals(mutationId) &
                t.ownerId.equals(ownerId) &
                t.status.equals('conflict'),
          ))
        .write(
      OutboxOpsCompanion(
        status: const Value('pending'),
        nextRetryAt: const Value(null),
        updatedAt: Value(_nowIso),
      ),
    );
    return true;
  }

  /// 対象エンティティ（[ownerId] 限定）に未同期変更が残っているか
  /// （pull時の上書き防止用）。別ownerの同一IDは対象にしない。
  Future<bool> hasPendingFor(
    String entityTable,
    String entityId,
    String ownerId,
  ) async {
    final row = await (_db.select(_db.outboxOps)
          ..where(
            (t) =>
                t.entityTable.equals(entityTable) &
                t.entityId.equals(entityId) &
                t.ownerId.equals(ownerId) &
                t.status.isNotIn(const ['synced']),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// [ownerId] の同期状態サマリの監視（UIバナー用）。前ownerの残留件数を
  /// 引き継いで表示しない。
  Stream<Map<OutboxStatus, int>> watchStatusCounts({required String ownerId}) {
    return (_db.select(_db.outboxOps)..where((t) => t.ownerId.equals(ownerId)))
        .watch()
        .map((rows) {
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
        nextRetryAt:
            row.nextRetryAt == null ? null : DateTime.parse(row.nextRetryAt!),
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );
}
