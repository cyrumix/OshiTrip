import '../../../core/error/result.dart';
import 'itinerary_entry.dart';
import 'itinerary_leg.dart';
import 'itinerary_plan.dart';
import 'itinerary_plan_aggregate.dart';
import 'itinerary_spot.dart';
import 'itinerary_spot_link.dart';

/// 旅程（計画・スポット・リンク・タイムライン項目・移動区間）の
/// リポジトリ抽象（owner 単位のローカルCRUD + Outbox + 同期）。
///
/// 現場（[Genba]）の子集約と同じ設計方針を取るが、計画配下にさらに
/// スポット→リンクの孫階層を持つため、親所有権検証は該当する直接の親
/// テーブルに対して行う（spot_link→spot、spot/entry/leg→plan）。
abstract interface class ItineraryRepository {
  /// 指定した現場に属する計画一覧（スポット・リンク・項目・区間込み）を
  /// 現在ownerに限定して監視する。
  Stream<List<ItineraryPlanAggregate>> watchByGenbaId(String genbaId);

  /// 単一の計画（集約込み）を監視する。存在しない・別ownerなら null。
  Stream<ItineraryPlanAggregate?> watchPlan(String planId);

  Future<Result<void>> upsertPlan(ItineraryPlan plan);

  /// 計画を削除する（配下のスポット・リンク・項目・区間もすべて削除。
  /// 参照しているだけの transport/lodging 本体には触れない）。
  Future<Result<void>> deletePlan(String id);

  Future<Result<void>> upsertSpot(ItinerarySpot spot);

  /// スポットを削除する（配下のリンクと、このスポットを参照する旅程項目・
  /// その項目を始点/終点とする移動区間も削除する）。
  Future<Result<void>> deleteSpot(String id);

  Future<Result<void>> upsertSpotLink(ItinerarySpotLink link);
  Future<Result<void>> deleteSpotLink(String id);

  Future<Result<void>> upsertEntry(ItineraryEntry entry);

  /// 旅程項目を削除する（この項目を始点/終点とする移動区間も削除する）。
  Future<Result<void>> deleteEntry(String id);

  Future<Result<void>> upsertLeg(ItineraryLeg leg);
  Future<Result<void>> deleteLeg(String id);

  /// リモートの旅程データを現在 owner 限定でローカルへ取り込む。
  /// ローカル未同期変更は上書きしない。デモ・未ログインでは何もしない。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  /// 競合解決「サーバーを採用」用。所有しないテーブルは失敗を返す。
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}
