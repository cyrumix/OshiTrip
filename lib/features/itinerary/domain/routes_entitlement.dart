import '../../../core/error/result.dart';

/// プレミアムentitlement（Google Routesライブ取得の可否）の読み取り専用境界
/// （旅程Phase 4, itinerary-plan-spec §14.4）。
///
/// 課金・購入フローはこのPhaseでも実装しない（spec §14.4「現時点では課金制御を
/// 実装せず」）。ここは「サーバー側で強制する」ためのゲート機構であり、実際の
/// 判定は Edge Function + `has_premium_routes_entitlement` RPC が行う
/// （クライアントはこの値を UX ヒント——更新ボタンの活性・案内文言——にのみ使い、
/// 強制はしない）。クライアントはこの値へ一切書き込めない。
abstract interface class RoutesEntitlementRepository {
  /// 現在ownerのプレミアム状態を監視する。未認証・行が無ければ false。
  Stream<bool> watchIsPremium();

  /// リモート（Supabase `user_entitlements`）から現在値を取り込む。
  /// デモ・未ログインでは何もしない。
  Future<Result<void>> refreshFromRemote();
}
