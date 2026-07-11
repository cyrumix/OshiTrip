import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/places_gateway_impl.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/places_gateway.dart';

/// places-proxy Edge Function を呼ぶトランスポート境界（旅程Phase 3）。
///
/// Places が無効（デモ・未設定・機能フラグOFF）または Supabase クライアントが
/// 無いときは null を返し、[placesGatewayProvider] を [UnavailablePlacesGateway]
/// へ縮退させる。Google API キーはアプリに埋め込まず、places-proxy（サーバー）が
/// 保持する（ADR-0010 §3）。テストではこの provider を差し替えて実 Gateway の
/// payload 送出・エラー変換を検証できる（routes と同設計）。
final placesProxyTransportProvider = Provider<PlacesProxyTransport?>((ref) {
  final env = ref.watch(envProvider);
  if (!env.googlePlacesAvailable) return null;
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabasePlacesProxyTransport(client);
});

/// 施設検索ゲートウェイ（ADR-0010 §1）。[placesProxyTransportProvider] が有効
/// （Places 有効＋Supabase クライアントあり）なら places-proxy を呼ぶ実 Gateway
/// （[PlacesGatewayImpl]）を、そうでなければ [UnavailablePlacesGateway] を返して
/// 手動フォールバックへ縮退させる（デモ・未設定・無効では常に利用不可・課金APIを
/// 勝手に呼ばない）。
final placesGatewayProvider = Provider<PlacesGateway>((ref) {
  final transport = ref.watch(placesProxyTransportProvider);
  if (transport == null) return const UnavailablePlacesGateway();
  return PlacesGatewayImpl(transport: transport);
});

/// 指定した現場に属する計画（集約込み）を現在owner限定で監視する
/// （後続Phaseの計画タブUIが購読する操作境界）。
///
/// このProviderは読み取り境界のみを提供する。CRUD操作は
/// [itineraryRepositoryProvider] を通じて行う（Phase 2 の Controller が利用）。
final itineraryPlansProvider = StreamProvider.autoDispose
    .family<List<ItineraryPlanAggregate>, String>((ref, genbaId) {
  return ref.watch(itineraryRepositoryProvider).watchByGenbaId(genbaId);
});

/// 単一の計画（集約込み）を監視する。存在しない・別ownerなら null。
final itineraryPlanProvider = StreamProvider.autoDispose
    .family<ItineraryPlanAggregate?, String>((ref, planId) {
  return ref.watch(itineraryRepositoryProvider).watchPlan(planId);
});
