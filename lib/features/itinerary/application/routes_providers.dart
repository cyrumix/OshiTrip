import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/routes_gateway.dart';
import 'route_recalculation_controller.dart';

/// 経路取得ゲートウェイ（ADR-0010 §1、旅程Phase 4）。Google Routes が利用可能で
/// ない限り [UnavailableRoutesGateway] を返し、呼び出し側を手動フォールバックへ
/// 縮退させる。実 HTTP 実装（Edge Function 経由）は Routes 有効時にのみ差し込む
/// （`placesGatewayProvider` と同じ段階実装方針の後続増分）。既定（デモ・
/// 未設定・無効）では常に [UnavailableRoutesGateway]（Phase 1〜3を壊さない）。
final routesGatewayProvider = Provider<RoutesGateway>((ref) {
  final env = ref.watch(envProvider);
  if (!env.googleRoutesAvailable) {
    return const UnavailableRoutesGateway();
  }
  // Routes 有効時の実ゲートウェイは後続増分で接続する。未接続の間は安全側
  // （利用不可）へ倒し、勝手に課金APIを呼ばない。
  return const UnavailableRoutesGateway();
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
