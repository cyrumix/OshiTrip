import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failure.dart';
import '../error/result.dart';
import 'outbox_operation.dart';
import 'remote_mutation_client.dart';

/// Supabase への Outbox 適用実装。
///
/// - 冪等性: サーバー側 `outbox_operations` に mutationId を記録し、
///   記録済みなら再適用しない（二重送信防止, §15.3）。
/// - 競合: リモート `updated_at` が payload より新しい場合は
///   [ConflictFailure]（last-write-wins の既定、競合は記録に残る）。
class SupabaseRemoteMutationClient implements RemoteMutationClient {
  SupabaseRemoteMutationClient(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    try {
      final applied = await _client
          .from('outbox_operations')
          .select('id')
          .eq('id', op.mutationId)
          .maybeSingle();
      if (applied != null) return const Ok(null);

      switch (op.opType) {
        case OutboxOpType.upsert:
          final remote = await _client
              .from(op.entityTable)
              .select('updated_at')
              .eq('id', op.entityId)
              .maybeSingle();
          if (remote != null) {
            final remoteUpdated =
                DateTime.parse(remote['updated_at'] as String);
            final localUpdated =
                DateTime.parse(op.payload['updated_at'] as String);
            if (remoteUpdated.isAfter(localUpdated)) {
              return const Err(ConflictFailure());
            }
          }
          await _client.from(op.entityTable).upsert(op.payload);
        case OutboxOpType.delete:
          await _client.from(op.entityTable).delete().eq('id', op.entityId);
      }

      await _client.from('outbox_operations').upsert(
        {
          'id': op.mutationId,
          'owner_id': op.ownerId,
          'entity_table': op.entityTable,
          'entity_id': op.entityId,
          'op_type': op.opType.name,
        },
        ignoreDuplicates: true,
      );
      return const Ok(null);
    } on AuthException catch (e) {
      return Err(AuthFailure(cause: e));
    } on PostgrestException catch (e) {
      if (e.code == '42501' || e.code == 'PGRST301') {
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
