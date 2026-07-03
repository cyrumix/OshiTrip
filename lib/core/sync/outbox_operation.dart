/// Outbox（未同期変更キュー）のドメインモデル（ADR-0005 / §15.3）。
///
/// 書き込みは「ローカル反映 → Outbox 追加 → リモート同期」で行い、
/// [mutationId]（client_mutation_id）で冪等に再送する。
enum OutboxStatus { pending, syncing, synced, failed, conflict }

enum OutboxOpType { upsert, delete }

/// 同期対象のエンティティ種別（サーバー側テーブル名と一致させる）。
class SyncEntity {
  static const genbas = 'genbas';
  static const tickets = 'tickets';
  static const transports = 'transports';
  static const lodgings = 'lodgings';
  static const todos = 'todos';
  static const genbaMemos = 'genba_memos';
  static const memoryEntries = 'memory_entries';
  static const memoryPhotos = 'memory_photos';
  static const setlistItems = 'setlist_items';
  static const goodsItems = 'goods_items';
  static const visitedPlaces = 'visited_places';
  static const oshiGroups = 'oshi_groups';
  static const oshiMembers = 'oshi_members';
  static const oshiAnniversaries = 'oshi_anniversaries';

  static const all = [
    genbas,
    tickets,
    transports,
    lodgings,
    todos,
    genbaMemos,
    memoryEntries,
    memoryPhotos,
    setlistItems,
    goodsItems,
    visitedPlaces,
    oshiGroups,
    oshiMembers,
    oshiAnniversaries,
  ];
}

class OutboxOperation {
  const OutboxOperation({
    required this.mutationId,
    required this.ownerId,
    required this.entityTable,
    required this.entityId,
    required this.opType,
    required this.payload,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String mutationId;
  final String ownerId;
  final String entityTable;
  final String entityId;
  final OutboxOpType opType;

  /// upsert 時のエンティティ JSON（snake_case、サーバー行と同形）。
  final Map<String, dynamic> payload;
  final OutboxStatus status;
  final int attempts;
  final String? lastError;

  /// 次に再送してよい時刻（バックオフ待機中は未来。null は即送信可, H-02）。
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OutboxOperation copyWith({
    OutboxStatus? status,
    int? attempts,
    String? lastError,
    DateTime? nextRetryAt,
    DateTime? updatedAt,
  }) {
    return OutboxOperation(
      mutationId: mutationId,
      ownerId: ownerId,
      entityTable: entityTable,
      entityId: entityId,
      opType: opType,
      payload: payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 同期状態のサマリ（UI表示用: 保存中/端末保存済み/同期済み/同期失敗）。
enum SyncSummary { synced, pendingLocal, syncing, failed, conflict, localOnly }

extension SyncSummaryLabel on SyncSummary {
  String get label => switch (this) {
        SyncSummary.synced => '同期済み',
        SyncSummary.pendingLocal => '端末保存済み',
        SyncSummary.syncing => '同期中',
        SyncSummary.failed => '同期失敗',
        SyncSummary.conflict => '競合あり',
        SyncSummary.localOnly => '端末のみ（デモ）',
      };
}
