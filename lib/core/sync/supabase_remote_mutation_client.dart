import 'dart:async';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../error/failure.dart';
import '../error/result.dart';
import '../network/network_timeout.dart';
import 'mutation_transport.dart';
import 'outbox_operation.dart';
import 'remote_mutation_client.dart';

/// Supabase への Outbox 適用実装（H-02）。
///
/// - 冪等性・原子性: サーバー側 `apply_mutation` RPC が「実データ変更＋ledger
///   記録」を1トランザクションで行うため、変更成功後・ledger記録前に落ちても
///   二重適用しない。
/// - 競合: 端末時計ではなくサーバー `version` の CAS で判定する（clock skew に
///   強い）。既知の版（base_version）をローカルキャッシュ [RemoteVersions] から
///   添え、RPC が食い違いを検出したら [ConflictFailure]。
/// - 版キャッシュ: 適用成功時に返却された版を保存し、次回送信の base_version に
///   使う。delete 成功時はキャッシュを削除する。
class SupabaseRemoteMutationClient implements RemoteMutationClient {
  SupabaseRemoteMutationClient(this._transport, this._db);

  final MutationTransport _transport;
  final AppDatabase _db;

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    final baseVersion = await _knownVersion(op);
    final result = await _transport.apply(op, baseVersion: baseVersion);
    return result.when(
      ok: (outcome) async {
        switch (outcome.status) {
          case MutationStatus.conflict:
            return const Err(ConflictFailure());
          case MutationStatus.applied:
            await _rememberVersion(op, outcome.version);
            return const Ok(null);
        }
      },
      err: Err.new,
    );
  }

  Future<int?> _knownVersion(OutboxOperation op) async {
    final row = await (_db.select(_db.remoteVersions)
          ..where(
            (t) =>
                t.ownerId.equals(op.ownerId) &
                t.entityTable.equals(op.entityTable) &
                t.entityId.equals(op.entityId),
          ))
        .getSingleOrNull();
    return row?.version;
  }

  Future<void> _rememberVersion(OutboxOperation op, int? version) async {
    if (op.opType == OutboxOpType.delete) {
      await (_db.delete(_db.remoteVersions)
            ..where(
              (t) =>
                  t.ownerId.equals(op.ownerId) &
                  t.entityTable.equals(op.entityTable) &
                  t.entityId.equals(op.entityId),
            ))
          .go();
      return;
    }
    if (version == null) return;
    await _db.into(_db.remoteVersions).insertOnConflictUpdate(
          RemoteVersionsCompanion.insert(
            ownerId: op.ownerId,
            entityTable: op.entityTable,
            entityId: op.entityId,
            version: version,
          ),
        );
  }
}

/// `apply_mutation` RPC を呼ぶ Supabase トランスポート実装。
class SupabaseMutationTransport implements MutationTransport {
  SupabaseMutationTransport(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<MutationOutcome>> apply(
    OutboxOperation op, {
    required int? baseVersion,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'apply_mutation',
        params: {
          'p_mutation_id': op.mutationId,
          'p_entity_table': op.entityTable,
          'p_entity_id': op.entityId,
          'p_op_type': op.opType.name,
          'p_payload': op.payload,
          'p_base_version': baseVersion,
        },
      ).withRemoteTimeout();
      final map = (res as Map).cast<String, dynamic>();
      final status = map['status'] == 'conflict'
          ? MutationStatus.conflict
          : MutationStatus.applied;
      final version = (map['version'] as num?)?.toInt();
      return Ok(MutationOutcome(status: status, version: version));
    } on TimeoutException catch (e) {
      // ハングは NetworkFailure として pending に戻し、バックオフ再送する。
      return Err(NetworkFailure(cause: e));
    } on AuthException catch (e) {
      return Err(AuthFailure(cause: e));
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'PGRST301' || e.code == '28000') {
        return Err(PermissionFailure(cause: e));
      }
      return Err(UnknownFailure(cause: e));
    } on http.ClientException catch (e) {
      return Err(NetworkFailure(cause: e));
    } catch (e) {
      final text = e.toString();
      if (text.contains('SocketException') ||
          text.contains('Connection') ||
          text.contains('TimeoutException')) {
        return Err(NetworkFailure(cause: e));
      }
      return Err(UnknownFailure(cause: e));
    }
  }
}
