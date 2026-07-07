import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../../genba/domain/genba.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_plan.dart';
import '../domain/itinerary_plan_aggregate.dart';
import '../domain/itinerary_spot.dart';
import '../domain/itinerary_spot_link.dart';

/// 計画タブ（旅程）の主要操作を集約する application 層（GenbaActionsController と
/// 同型）。state は「進行中の操作キー集合」で、同一キーの再入（二重タップ）だけを
/// 弾く。各メソッドは型付き [Failure]（null=成功）を返し、presentation が必ず
/// 結果を見てユーザーへ伝える。owner認可・親所有権・参照整合・Outbox は
/// [ItineraryRepository] へ委譲する（C-01）。
///
/// 「実行して成功(null)」と「実行せず無視」を混同しないよう、二重タップ時は
/// [OperationInProgressFailure] を返す。
class ItineraryActionsController
    extends AutoDisposeFamilyNotifier<Set<String>, String> {
  static const _uuid = Uuid();

  @override
  Set<String> build(String genbaId) => const {};

  bool isBusy(String key) => state.contains(key);
  bool get isAnyBusy => state.isNotEmpty;

  Future<Failure?> _run(String key, Future<Failure?> Function() action) async {
    if (state.contains(key)) return const OperationInProgressFailure();
    state = {...state, key};
    try {
      return await action();
    } finally {
      state = {...state}..remove(key);
    }
  }

  DateTime get _now => ref.read(clockProvider).now().toUtc();
  String? get _owner => ref.read(currentUserProvider).valueOrNull?.id;

  // ---- 計画の用意 -----------------------------------------------------------

  static const ensurePlanKey = 'ensurePlan';

  /// 現場に既定の計画が1件あることを保証し、その planId を返す（無ければ作成）。
  /// 1現場につき MVP は1計画（DBは将来の複数計画を許容）。
  Future<Result<String>> ensurePlan(Genba genba) async {
    final owner = _owner;
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    // 進行中なら待たずに軽く弾く（作成の多重を避ける）。
    if (state.contains(ensurePlanKey)) {
      return const Err(OperationInProgressFailure());
    }
    state = {...state, ensurePlanKey};
    try {
      final repo = ref.read(itineraryRepositoryProvider);
      final existing = await repo.watchByGenbaId(genba.id).first;
      if (existing.isNotEmpty) return Ok(existing.first.plan.id);
      final now = _now;
      final plan = ItineraryPlan(
        id: _uuid.v4(),
        genbaId: genba.id,
        ownerId: owner,
        title: '${genba.title}の計画',
        timeZoneId: kDefaultItineraryTimeZone,
        createdAt: now,
        updatedAt: now,
      );
      final result = await repo.upsertPlan(plan);
      return result.when(
        ok: (_) => Ok(plan.id),
        err: Err.new,
      );
    } catch (e) {
      return Err(StorageFailure(cause: e));
    } finally {
      state = {...state}..remove(ensurePlanKey);
    }
  }

  // ---- スポット ---------------------------------------------------------------

  String spotKey(String id) => 'spot:$id';

  Future<Failure?> upsertSpot(ItinerarySpot spot) => _run(
        spotKey(spot.id),
        () async =>
            (await ref.read(itineraryRepositoryProvider).upsertSpot(spot))
                .failureOrNull,
      );

  /// スポット・訪問項目・リンクを1トランザクションで原子的に保存する。
  Future<Failure?> saveSpotBundle({
    required ItinerarySpot spot,
    required ItineraryEntry entry,
    required List<ItinerarySpotLink> links,
    List<String> removedLinkIds = const [],
  }) =>
      _run(
        spotKey(spot.id),
        () async => (await ref.read(itineraryRepositoryProvider).saveSpotBundle(
                  spot: spot,
                  entry: entry,
                  links: links,
                  removedLinkIds: removedLinkIds,
                ))
            .failureOrNull,
      );

  /// スポット削除。関連する訪問項目・リンク・区間は Repository が cascade する。
  /// 端末内ユーザー画像は削除成功後に owner スコープで掃除する（H-04）。
  Future<Failure?> deleteSpot(ItinerarySpot spot) => _run(
        spotKey(spot.id),
        () async {
          final result =
              await ref.read(itineraryRepositoryProvider).deleteSpot(spot.id);
          final imageRef = spot.userImageLocalPath;
          if (result.isOk && imageRef != null && spot.ownerId.isNotEmpty) {
            await ref
                .read(imageStoreProvider)
                .deleteRef(spot.ownerId, imageRef);
          }
          return result.failureOrNull;
        },
      );

  // ---- スポットのリンク ---------------------------------------------------------

  String linkKey(String id) => 'link:$id';

  Future<Failure?> upsertSpotLink(ItinerarySpotLink link) => _run(
        linkKey(link.id),
        () async =>
            (await ref.read(itineraryRepositoryProvider).upsertSpotLink(link))
                .failureOrNull,
      );

  Future<Failure?> deleteSpotLink(String id) => _run(
        linkKey(id),
        () async =>
            (await ref.read(itineraryRepositoryProvider).deleteSpotLink(id))
                .failureOrNull,
      );

  // ---- 旅程項目 ---------------------------------------------------------------

  String entryKey(String id) => 'entry:$id';

  Future<Failure?> upsertEntry(ItineraryEntry entry) => _run(
        entryKey(entry.id),
        () async =>
            (await ref.read(itineraryRepositoryProvider).upsertEntry(entry))
                .failureOrNull,
      );

  Future<Failure?> deleteEntry(String id) => _run(
        entryKey(id),
        () async =>
            (await ref.read(itineraryRepositoryProvider).deleteEntry(id))
                .failureOrNull,
      );

  /// 同一日内の並び替え。[orderedEntryIds] の順に sortOrder を 0 から振り直す
  /// （順序だけを変更し、項目の中身は upsert しない）。保存は Repository の
  /// 単一トランザクション（途中失敗で全件 rollback）。
  Future<Failure?> reorderEntries({
    required String planId,
    required List<String> orderedEntryIds,
  }) =>
      _run(
        'reorder',
        () async => (await ref.read(itineraryRepositoryProvider).reorderEntries(
                  planId: planId,
                  orderedEntryIds: orderedEntryIds,
                ))
            .failureOrNull,
      );

  // ---- 移動区間 ---------------------------------------------------------------

  String legKey(String id) => 'leg:$id';

  Future<Failure?> upsertLeg(ItineraryLeg leg) => _run(
        legKey(leg.id),
        () async => (await ref.read(itineraryRepositoryProvider).upsertLeg(leg))
            .failureOrNull,
      );

  Future<Failure?> deleteLeg(String id) => _run(
        legKey(id),
        () async => (await ref.read(itineraryRepositoryProvider).deleteLeg(id))
            .failureOrNull,
      );

  // ---- 計画削除 -------------------------------------------------------------

  static const deletePlanKey = 'deletePlan';

  /// 計画と配下（スポット・リンク・項目・区間）を削除する。端末内画像
  /// （カバー・各スポットのユーザー画像）は削除成功後に owner スコープで掃除する。
  Future<Failure?> deletePlan(ItineraryPlanAggregate aggregate) =>
      _run(deletePlanKey, () async {
        final plan = aggregate.plan;
        final refs = <String>[
          if (plan.coverImageLocalPath != null) plan.coverImageLocalPath!,
          for (final s in aggregate.spots)
            if (s.userImageLocalPath != null) s.userImageLocalPath!,
        ];
        final result =
            await ref.read(itineraryRepositoryProvider).deletePlan(plan.id);
        if (result.isOk && plan.ownerId.isNotEmpty) {
          final store = ref.read(imageStoreProvider);
          for (final r in refs) {
            await store.deleteRef(plan.ownerId, r);
          }
        }
        return result.failureOrNull;
      });
}

/// 国内MVPの既定タイムゾーン（§2.6）。ユーザーは計画編集で変更できる。
const String kDefaultItineraryTimeZone = 'Asia/Tokyo';

final itineraryActionsControllerProvider = NotifierProvider.autoDispose
    .family<ItineraryActionsController, Set<String>, String>(
  ItineraryActionsController.new,
);
