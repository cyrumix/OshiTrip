import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';

/// 共有現場の editor 書き込み境界（追加要件 §2/§3, D-241）。
///
/// **必ず `apply_shared_mutation` RPC 経由**で書く（直接テーブル更新はしない）。
/// RPC が owner/editor 判定・owner_id の現場owner正規化・対象現場帰属・版CAS・
/// 冪等台帳を担う。genbas 本体・genba_shares・招待は RPC の allowlist 外のため
/// editor から書けない（現場削除・オーナー変更・メンバー管理は owner 専用の従来経路）。
abstract interface class SharedMutationClient {
  Future<Result<void>> apply({
    required String genbaId,
    required String entityTable,
    required String entityId,
    required String opType, // 'upsert' | 'delete'
    Map<String, dynamic> payload = const {},
    int? baseVersion,
  });
}

/// `apply_shared_mutation` の戻り値 `{status: 'applied'|'conflict', version}` を
/// 型付き結果へ変換する純粋関数。
///
/// - `applied`: 成功。
/// - `conflict`: 他メンバーが先に更新（版CAS不一致）→ [ConflictFailure]。
/// - それ以外/未知/欠落: 成功扱いにせず失敗（結果を確認できない）。
Result<void> parseSharedMutationResult(Object? res) {
  final status = res is Map ? res['status'] as String? : null;
  switch (status) {
    case 'applied':
      return const Ok(null);
    case 'conflict':
      return const Err(
        ConflictFailure(
          message: '他のメンバーが先に更新しました。画面を再読み込みしてください',
        ),
      );
    default:
      return const Err(
        NetworkFailure(message: '更新結果を確認できませんでした。再読み込みしてください'),
      );
  }
}

class SupabaseSharedMutationClient implements SharedMutationClient {
  SupabaseSharedMutationClient(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  @override
  Future<Result<void>> apply({
    required String genbaId,
    required String entityTable,
    required String entityId,
    required String opType,
    Map<String, dynamic> payload = const {},
    int? baseVersion,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'apply_shared_mutation',
        params: {
          'p_mutation_id': _uuid.v4(),
          'p_entity_table': entityTable,
          'p_entity_id': entityId,
          'p_op_type': opType,
          'p_payload': payload,
          'p_base_version': baseVersion,
          'p_genba': genbaId,
        },
      ).withRemoteTimeout();
      // status を必ず解析する（例外が無くても conflict/未知は成功扱いにしない）。
      return parseSharedMutationResult(res);
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } on PostgrestException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('not an editor') || m.contains('not editable')) {
        return const Err(PermissionFailure(message: 'この現場を編集する権限がありません'));
      }
      return Err(NetworkFailure(cause: e.message));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }
}

/// 未接続/デモ・viewer 向け no-op（書き込み不可）。
class UnavailableSharedMutationClient implements SharedMutationClient {
  const UnavailableSharedMutationClient();
  @override
  Future<Result<void>> apply({
    required String genbaId,
    required String entityTable,
    required String entityId,
    required String opType,
    Map<String, dynamic> payload = const {},
    int? baseVersion,
  }) async =>
      const Err(UnavailableFailure());
}
