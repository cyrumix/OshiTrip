import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/itinerary_plan_aggregate.dart';

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
