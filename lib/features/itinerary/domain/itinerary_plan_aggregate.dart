import 'package:freezed_annotation/freezed_annotation.dart';

import 'itinerary_entry.dart';
import 'itinerary_leg.dart';
import 'itinerary_plan.dart';
import 'itinerary_spot.dart';
import 'itinerary_spot_link.dart';

part 'itinerary_plan_aggregate.freezed.dart';

/// 計画（[ItineraryPlan]）とその子データ一式のローカル集約ビュー。
///
/// [GenbaAggregate] / [TodoTemplateWithItems] と同型で、JSON化・同期は
/// 各子エンティティが個別に担い、この集約自体は画面・純粋関数へ渡すための
/// ローカル読み取り専用ビューに過ぎない。
@freezed
abstract class ItineraryPlanAggregate with _$ItineraryPlanAggregate {
  const ItineraryPlanAggregate._();

  const factory ItineraryPlanAggregate({
    required ItineraryPlan plan,
    @Default(<ItinerarySpot>[]) List<ItinerarySpot> spots,
    @Default(<ItinerarySpotLink>[]) List<ItinerarySpotLink> spotLinks,
    @Default(<ItineraryEntry>[]) List<ItineraryEntry> entries,
    @Default(<ItineraryLeg>[]) List<ItineraryLeg> legs,
  }) = _ItineraryPlanAggregate;

  /// 指定スポットに紐づくリンク（sortOrder→createdAtの決定的順序）。
  List<ItinerarySpotLink> linksOf(String spotId) {
    final list = spotLinks.where((l) => l.spotId == spotId).toList();
    list.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }
}
