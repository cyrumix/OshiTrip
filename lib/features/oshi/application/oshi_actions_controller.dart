import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../domain/oshi.dart';

/// マイ推しの書き込み操作（グループ／メンバー／記念日の追加・編集・削除、
/// グループお気に入り）を presentation から切り離す application 層
/// （R7 / design-spec §10/§12.1）。
///
/// [GenbaActionsController]（R5, D-111）と同じ per-key 方式で、同一操作の
/// 二重タップだけを弾き、無関係な操作はブロックしない。各メソッドは
/// [Failure]（null=成功）を返し、成功していない操作を成功表示しない。
///
/// 画像ファイルの取り込み（ImagePicker→ImageStore.import）は UI 都合の
/// 前処理として presentation に残すが、レコード書き込みと「削除成功後の
/// owner スコープでの画像掃除」はここへ集約する（H-04）。
class OshiActionsController extends AutoDisposeNotifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isBusy(String key) => state.contains(key);

  static String groupKey(String id) => 'group:$id';
  static String groupFavoriteKey(String id) => 'groupFavorite:$id';
  static String deleteGroupKey(String id) => 'deleteGroup:$id';
  static String memberKey(String id) => 'member:$id';
  static String anniversaryKey(String id) => 'anniversary:$id';
  static String deleteAnniversaryKey(String id) => 'deleteAnniversary:$id';

  Future<Failure?> _run(
    String key,
    Future<Failure?> Function() action,
  ) async {
    if (state.contains(key)) return null; // 同一操作の二重タップを無視。
    state = {...state, key};
    try {
      return await action();
    } finally {
      state = {...state}..remove(key);
    }
  }

  /// グループの保存（フォーム全体の意図した上書き）。
  Future<Failure?> saveGroup(OshiGroup group) =>
      _run(groupKey(group.id), () async {
        final result =
            await ref.read(oshiRepositoryProvider).upsertGroup(group);
        return result.failureOrNull;
      });

  /// グループのお気に入り切替。
  ///
  /// 画面が保持していたスナップショットの [OshiGroup] を丸ごと上書きすると、
  /// 並行する編集（名前・カラー等）を古い値で巻き戻し得るため（D-118 と同じ
  /// 問題クラス）、保存直前に owner 限定ストリームから最新行を読み直し、
  /// isFavorite だけを差し替える。
  Future<Failure?> setGroupFavorite({
    required String groupId,
    required bool isFavorite,
  }) =>
      _run(groupFavoriteKey(groupId), () async {
        final repo = ref.read(oshiRepositoryProvider);
        final List<OshiGroupWithMembers> groups;
        try {
          groups = await repo.watchAll().first;
        } catch (e) {
          return StorageFailure(message: '推しデータの読み込みに失敗しました', cause: e);
        }
        final current =
            groups.map((g) => g.group).firstWhereOrNull((g) => g.id == groupId);
        if (current == null) {
          return const NotFoundFailure(message: '対象のグループが見つかりませんでした');
        }
        final now = ref.read(clockProvider).now().toUtc();
        final result = await repo.upsertGroup(
          current.copyWith(isFavorite: isFavorite, updatedAt: now),
        );
        return result.failureOrNull;
      });

  /// グループ削除（メンバー・記念日はデータ層がカスケード, D-143）。
  /// 削除成功後にのみ、グループ／メンバー画像を owner スコープで掃除する。
  Future<Failure?> deleteGroup(OshiGroupWithMembers item) =>
      _run(deleteGroupKey(item.group.id), () async {
        final owner = item.group.ownerId;
        // 削除前に画像参照を控える（削除後は取得できない）。
        final refs = <String>[
          if (item.group.imageLocalPath != null) item.group.imageLocalPath!,
          for (final m in item.members)
            if (m.imageLocalPath != null) m.imageLocalPath!,
        ];
        final result =
            await ref.read(oshiRepositoryProvider).deleteGroup(item.group.id);
        if (result.isOk && owner.isNotEmpty) {
          final store = ref.read(imageStoreProvider);
          for (final r in refs) {
            await store.deleteRef(owner, r);
          }
        }
        return result.failureOrNull;
      });

  /// メンバーの保存（追加・編集）。
  Future<Failure?> saveMember(OshiMember member) =>
      _run(memberKey(member.id), () async {
        final result =
            await ref.read(oshiRepositoryProvider).upsertMember(member);
        return result.failureOrNull;
      });

  /// ユーザー定義記念日の保存（追加・編集）。
  Future<Failure?> saveAnniversary(OshiAnniversary anniversary) =>
      _run(anniversaryKey(anniversary.id), () async {
        final result = await ref
            .read(oshiRepositoryProvider)
            .upsertAnniversary(anniversary);
        return result.failureOrNull;
      });

  /// ユーザー定義記念日の削除。
  Future<Failure?> deleteAnniversary(String id) =>
      _run(deleteAnniversaryKey(id), () async {
        final result =
            await ref.read(oshiRepositoryProvider).deleteAnniversary(id);
        return result.failureOrNull;
      });
}

final oshiActionsControllerProvider =
    NotifierProvider.autoDispose<OshiActionsController, Set<String>>(
  OshiActionsController.new,
);
