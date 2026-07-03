import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/sync/mutation_transport.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/supabase_remote_mutation_client.dart';

import '../helpers/test_db.dart';

/// サーバー `apply_mutation` を模した擬似トランスポート。
/// version の CAS と mutation_id 冪等台帳をメモリで再現する。端末時計
/// （payload の updated_at）には一切依存しない。
class _FakeTransport implements MutationTransport {
  final Map<String, int> versions = {}; // entityId -> version
  final Set<String> ledger = {}; // 適用済み mutationId
  Failure? nextError;
  int? lastBaseVersion; // 直近に受け取った base_version
  bool baseVersionSeen = false;

  @override
  Future<Result<MutationOutcome>> apply(
    OutboxOperation op, {
    required int? baseVersion,
  }) async {
    lastBaseVersion = baseVersion;
    baseVersionSeen = true;
    final err = nextError;
    if (err != null) {
      nextError = null;
      return Err(err);
    }
    // 冪等: 既に適用済みなら現在版で applied を返す（再適用しない）。
    if (ledger.contains(op.mutationId)) {
      return Ok(
        MutationOutcome(
          status: MutationStatus.applied,
          version: versions[op.entityId],
        ),
      );
    }
    if (op.opType == OutboxOpType.delete) {
      versions.remove(op.entityId);
      ledger.add(op.mutationId);
      return const Ok(MutationOutcome(status: MutationStatus.applied));
    }
    final current = versions[op.entityId];
    // 実RPCと同じ: 既存行に対し base_version が null または不一致なら競合。
    if (current != null && (baseVersion == null || current != baseVersion)) {
      return Ok(
        MutationOutcome(status: MutationStatus.conflict, version: current),
      );
    }
    final newVersion = (current ?? 0) + 1;
    versions[op.entityId] = newVersion;
    ledger.add(op.mutationId);
    return Ok(
      MutationOutcome(status: MutationStatus.applied, version: newVersion),
    );
  }
}

OutboxOperation _upsert(String mutationId, String entityId) => OutboxOperation(
      mutationId: mutationId,
      ownerId: 'user-1',
      entityTable: SyncEntity.genbas,
      entityId: entityId,
      opType: OutboxOpType.upsert,
      // わざと大きくずれた updated_at。version 判定に使われないことを示す。
      payload: {'id': entityId, 'updated_at': '2000-01-01T00:00:00.000Z'},
      createdAt: DateTime.utc(2026, 7, 2, 12),
      updatedAt: DateTime.utc(2026, 7, 2, 12),
    );

void main() {
  late AppDatabase db;
  late _FakeTransport transport;
  late SupabaseRemoteMutationClient client;

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    transport = _FakeTransport();
    client = SupabaseRemoteMutationClient(transport, db);
  });

  Future<int?> cachedVersion(String entityId) async {
    final row = await (db.select(db.remoteVersions)
          ..where(
            (t) =>
                t.ownerId.equals('user-1') &
                t.entityTable.equals(SyncEntity.genbas) &
                t.entityId.equals(entityId),
          ))
        .getSingleOrNull();
    return row?.version;
  }

  test('初回 upsert は成功し、返却版をローカルにキャッシュする', () async {
    final r = await client.apply(_upsert('m1', 'g1'));
    expect(r.isOk, isTrue);
    expect(await cachedVersion('g1'), 1);
  });

  test('同一 mutationId の再送は冪等（サーバー版を進めない）', () async {
    await client.apply(_upsert('m1', 'g1'));
    final r = await client.apply(_upsert('m1', 'g1')); // 同じ mutationId
    expect(r.isOk, isTrue);
    expect(transport.versions['g1'], 1); // 版は増えない
  });

  test('端末時計がずれていても、サーバー版の不一致で競合になる', () async {
    // 初回で version=1 をキャッシュ。
    await client.apply(_upsert('m1', 'g1'));
    // 別端末がサーバー版を 2 へ進めた状況を再現。
    transport.versions['g1'] = 2;

    // クライアントは base_version=1（キャッシュ）で送る → 現在版2と不一致 → 競合。
    // payload の updated_at は 2000 年（大きくずれ）だが判定に使われない。
    final r = await client.apply(_upsert('m2', 'g1'));
    expect(r.failureOrNull, isA<ConflictFailure>());
    // 競合時はキャッシュを進めない。
    expect(await cachedVersion('g1'), 1);
  });

  test('正しい版での更新は成功し、キャッシュ版が進む', () async {
    await client.apply(_upsert('m1', 'g1')); // v1
    final r = await client.apply(_upsert('m2', 'g1')); // base=1, current=1 → v2
    expect(r.isOk, isTrue);
    expect(await cachedVersion('g1'), 2);
  });

  test('delete 成功で版キャッシュを削除する', () async {
    await client.apply(_upsert('m1', 'g1'));
    expect(await cachedVersion('g1'), 1);
    final del = OutboxOperation(
      mutationId: 'm2',
      ownerId: 'user-1',
      entityTable: SyncEntity.genbas,
      entityId: 'g1',
      opType: OutboxOpType.delete,
      payload: const {},
      createdAt: DateTime.utc(2026, 7, 2, 12),
      updatedAt: DateTime.utc(2026, 7, 2, 12),
    );
    final r = await client.apply(del);
    expect(r.isOk, isTrue);
    expect(await cachedVersion('g1'), isNull);
  });

  test('通信失敗はそのまま Err として返し、キャッシュを変えない', () async {
    transport.nextError = const NetworkFailure();
    final r = await client.apply(_upsert('m1', 'g1'));
    expect(r.failureOrNull, isA<NetworkFailure>());
    expect(await cachedVersion('g1'), isNull);
  });

  test('空キャッシュへ version=5 を pull 後、更新は base_version=5 で送られる', () async {
    // pull で得た版をキャッシュ（新規端末が version=5 の行を取り込んだ状況）。
    await db.into(db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: 'user-1',
            entityTable: SyncEntity.genbas,
            entityId: 'g1',
            version: 5,
          ),
        );
    // サーバー側も version=5 の状態。
    transport.versions['g1'] = 5;

    final r = await client.apply(_upsert('m1', 'g1'));
    expect(r.isOk, isTrue);
    // クライアントはキャッシュ版 5 を base_version として送っている。
    expect(transport.lastBaseVersion, 5);
    // 適用後は返却版 6 をキャッシュへ反映。
    expect(await cachedVersion('g1'), 6);
  });

  test('キャッシュが無い既存サーバー行への更新は base=null 送信→競合（blind禁止）', () async {
    // サーバーには既に version=3 の行があるが、クライアントは未 pull（キャッシュ無し）。
    transport.versions['g1'] = 3;
    final r = await client.apply(_upsert('m1', 'g1'));
    // base_version=null で送られ、サーバーは既存行に対して競合を返す。
    expect(transport.lastBaseVersion, isNull);
    expect(r.failureOrNull, isA<ConflictFailure>());
    expect(await cachedVersion('g1'), isNull); // 競合ではキャッシュしない
  });
}
