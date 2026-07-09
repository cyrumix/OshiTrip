import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/routes_gateway_impl.dart';
import '../domain/routes_gateway.dart';
import 'route_recalculation_controller.dart';

/// routes-proxy Edge Function を呼ぶトランスポート境界（旅程Phase 4 / 修正1）。
///
/// Routes が無効（デモ・未設定・機能フラグOFF）または Supabase クライアントが
/// 無いときは null を返し、[routesGatewayProvider] を [UnavailableRoutesGateway]
/// へ縮退させる。Google API キーはアプリに埋め込まず、routes-proxy（サーバー）
/// が保持する（ADR-0010 §3）。テストではこの provider を差し替えて実 Gateway の
/// payload 送出・エラー変換を検証できる。
final routesProxyTransportProvider = Provider<RoutesProxyTransport?>((ref) {
  final env = ref.watch(envProvider);
  if (!env.googleRoutesAvailable) return null;
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseRoutesProxyTransport(client);
});

/// 経路取得ゲートウェイ（ADR-0010 §1、旅程Phase 4）。
///
/// [routesProxyTransportProvider] が有効（Routes 有効＋Supabase クライアントあり）
/// なら routes-proxy を呼ぶ実 Gateway（[RoutesGatewayImpl]）を、そうでなければ
/// [UnavailableRoutesGateway] を返して手動フォールバックへ縮退させる
/// （デモ・未設定・無効では常に利用不可, Phase 1〜3を壊さない）。
final routesGatewayProvider = Provider<RoutesGateway>((ref) {
  final transport = ref.watch(routesProxyTransportProvider);
  if (transport == null) return const UnavailableRoutesGateway();
  return RoutesGatewayImpl(
    transport: transport,
    clock: ref.watch(clockProvider),
  );
});

/// 「最新ルートを更新」の実行境界（single-flight込み）。アプリ全体で1インスタンス
/// を共有し、同一 fingerprint の同時呼び出しを重複させない。
final routeRecalculationControllerProvider =
    Provider<RouteRecalculationController>((ref) {
  return RouteRecalculationController(
    gateway: ref.watch(routesGatewayProvider),
  );
});

/// 現在ownerのプレミアム状態（更新ボタンの活性・案内文言に使うUXヒント。
/// 実強制はサーバー側entitlement検証）。
final routesIsPremiumProvider = StreamProvider.autoDispose<bool>((ref) {
  return ref.watch(routesEntitlementRepositoryProvider).watchIsPremium();
});
