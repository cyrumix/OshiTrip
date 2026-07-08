import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/places_gateway.dart';

/// 施設検索ゲートウェイ（ADR-0010 §1）。Google Places が利用可能でない限り
/// [UnavailablePlacesGateway] を返し、呼び出し側を手動フォールバックへ縮退させる。
/// 実 HTTP 実装（Edge Function 経由）は Places 有効時にのみ差し込む（後続増分）。
/// 既定（デモ・未設定・無効）では常に [UnavailablePlacesGateway]（Phase 2 を壊さない）。
final placesGatewayProvider = Provider<PlacesGateway>((ref) {
  final env = ref.watch(envProvider);
  if (!env.googlePlacesAvailable) {
    return const UnavailablePlacesGateway();
  }
  // Places 有効時の実ゲートウェイは後続増分で接続する。未接続の間は安全側
  // （利用不可）へ倒し、勝手に課金APIを呼ばない。
  return const UnavailablePlacesGateway();
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
