import '../error/result.dart';
import 'outbox_operation.dart';

/// サーバー適用の結果種別（apply_mutation RPC の status に対応）。
enum MutationStatus { applied, conflict }

/// サーバー適用の結果。[version] は適用後のサーバー版（delete 時は null）。
class MutationOutcome {
  const MutationOutcome({required this.status, this.version});

  final MutationStatus status;
  final int? version;
}

/// サーバーへの mutation 適用トランスポート（H-02）。
///
/// `apply_mutation` RPC の呼び出しを抽象化し、[SupabaseRemoteMutationClient]
/// から版・冪等の解釈ロジックを分離する。これにより Supabase 実接続なしに
/// クライアントの競合/冪等ハンドリングを単体テストできる。
///
/// 戻り値は [Result]:
/// - Ok(MutationOutcome): サーバーが応答した（applied / conflict）。
/// - Err(Failure): 通信・認可などの失敗（呼び出し側が pending/failed を判断）。
abstract interface class MutationTransport {
  Future<Result<MutationOutcome>> apply(
    OutboxOperation op, {
    required int? baseVersion,
  });
}
