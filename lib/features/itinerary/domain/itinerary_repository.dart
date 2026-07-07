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

  /// スポット・その訪問項目(entry)・リンクの差分を**単一トランザクション**で
  /// 保存する（原子性）。spot upsert・[removedLinkIds] の削除・[links] の upsert・
  /// entry upsert とそれぞれの Outbox enqueue を同一 transaction で行い、
  /// いずれか失敗したら全体を rollback する（spot だけ残す等の部分適用をしない）。
  /// 成功後に一度だけ同期を促す。
  Future<Result<void>> saveSpotBundle({
    required ItinerarySpot spot,
    required ItineraryEntry entry,
    required List<ItinerarySpotLink> links,
    List<String> removedLinkIds = const [],
  });

  /// スポットを削除する（配下のリンクと、このスポットを参照する旅程項目・
  /// その項目を始点/終点とする移動区間も削除する）。
  Future<Result<void>> deleteSpot(String id);

  Future<Result<void>> upsertSpotLink(ItinerarySpotLink link);
  Future<Result<void>> deleteSpotLink(String id);

  Future<Result<void>> upsertEntry(ItineraryEntry entry);

  /// 同一計画・同一日の項目の**並び順だけ**を変更する（Phase 2レビュー点2）。
  ///
  /// [orderedEntryIds] は「その順に並べたい項目IDの一覧」。項目の中身
  /// （名称・日時・参照など）は一切 upsert せず、既存行の `sort_order` を
  /// 一覧の index に、`updated_at` を現在時刻にだけ更新する。
  ///
  /// **単一トランザクション**で以下を検証してから書き込み、いずれか失敗したら
  /// 行にも Outbox にも触れず全件 rollback する:
  /// - すべてのIDが実在し、現在owner・[planId] に属する
  ///   （存在しない／別owner／別計画は型付き [Failure] で拒否）
  /// - すべてが同一の表示日（交通・宿泊は参照元から導出した実効日）に属する
  ///   （別日をまたぐ並び替えは型付き [Failure] で拒否）
  Future<Result<void>> reorderEntries({
    required String planId,
    required List<String> orderedEntryIds,
  });

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
