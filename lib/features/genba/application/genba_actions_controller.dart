import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../domain/genba.dart';

/// 現場詳細の主要操作（中止/終演/要否/子データ削除）を一箇所へ集約する
/// application 層（H-07/M-01）。
///
/// - state は「進行中の操作キー集合」。各操作は固有キー（例: `todo:<id>`）で
///   二重タップを防ぐ。キーは操作ごとに分けているため、あるTodoの完了操作の
///   実行中に別のTodoやチケット削除など「別の操作」まで巻き添えでブロックする
///   ことはない（同一キーの再入だけを弾く）。
/// - 成功していない操作を成功表示しない: 各メソッドは [Failure]（null=成功）を
///   返し、呼び出し側（presentation）が必ず結果を見てユーザーへ伝える。
///   同一キーが処理中で今回の呼び出しを実行しなかった場合も、成功を表す
///   null ではなく [OperationInProgressFailure] を返す（「成功」と「未実行」を
///   混同しない。呼び出し側で成功表示・楽観更新の確定をしてしまうのを防ぐ）。
/// - 画像を伴う削除（チケット/ヒーロー）は、レコード削除成功後にのみ
///   owner スコープでファイルを掃除する（他ユーザーのファイルには触れない, H-04）。
/// - 現場フィールドの更新（中止/終演/要否/ヒーロー画像）は [Genba] 全体を
///   上書きする `upsertGenba` ではなく [GenbaRepository.mutateGenba] を使う。
///   画面が保持していた古いスナップショットで他フィールドを巻き戻さないよう、
///   DB内の最新値へ差分適用する（同一現場の並行・連続更新でも変更を失わない）。
class GenbaActionsController
    extends AutoDisposeFamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String genbaId) => const {};

  /// [key] の操作が進行中か（二重タップ防止のUI表示に使う）。
  bool isBusy(String key) => state.contains(key);

  /// 何らかの操作が進行中か（全体を一時的に止めたいUI向け）。
  bool get isAnyBusy => state.isNotEmpty;

  Future<Failure?> _run(
    String key,
    Future<Failure?> Function() action,
  ) async {
    // 二重タップ: 同一操作の再入は実行しない。ただし「実行して成功した」
    // (null) と区別できないと、呼び出し側が未実行を成功と誤認しうるため、
    // 専用の Failure を返す（実際に action() が走った場合のみ null=成功）。
    if (state.contains(key)) return const OperationInProgressFailure();
    state = {...state, key};
    try {
      return await action();
    } finally {
      state = {...state}..remove(key);
    }
  }

  /// 現場フィールドの差分更新（read-latest-merge）。[genbaId] の最新行へ
  /// [update] を適用する。戻り値は Failure（null=成功）。
  Future<Failure?> _mutate(
    String genbaId,
    Genba Function(Genba current) update,
  ) async {
    final result =
        await ref.read(genbaRepositoryProvider).mutateGenba(genbaId, update);
    return result.failureOrNull;
  }

  // ---- 中止 ---------------------------------------------------------------

  Future<Failure?> cancel(Genba genba) => _run(
        'cancel',
        () => _mutate(
          genba.id,
          (c) => c.copyWith(
            isCanceled: true,
            attendanceStatus: AttendanceStatus.canceled,
          ),
        ),
      );

  Future<Failure?> uncancel(Genba genba) => _run(
        'uncancel',
        // 中止取消は参加状態も canceled から planned へ戻す（stale を残さない）。
        () => _mutate(
          genba.id,
          (c) => c.copyWith(
            isCanceled: false,
            attendanceStatus: c.attendanceStatus == AttendanceStatus.canceled
                ? AttendanceStatus.planned
                : c.attendanceStatus,
          ),
        ),
      );

  // ---- 参加状態（明示・design-spec §12.1）--------------------------------------

  static const attendanceKey = 'attendance';

  /// 参加状態を明示的に設定する。日時からは自動導出しない。canceled との
  /// 整合のため isCanceled も合わせて設定する（attended 等は中止解除になる）。
  Future<Failure?> setAttendanceStatus(Genba genba, AttendanceStatus status) =>
      _run(
        attendanceKey,
        () => _mutate(
          genba.id,
          (c) => c.copyWith(
            attendanceStatus: status,
            isCanceled: status == AttendanceStatus.canceled,
          ),
        ),
      );

  // ---- 終演（手動）----------------------------------------------------------

  static const endedKey = 'ended';

  /// 「終演した」。呼び出し前に presentation 側で確認ダイアログを表示すること。
  Future<Failure?> markEnded(Genba genba) => _run(endedKey, () {
        final now = ref.read(clockProvider).now().toUtc();
        return _mutate(genba.id, (c) => c.copyWith(manualEndedAt: now));
      });

  /// 誤操作からの復旧: 手動終演を取り消し、日時からの自動導出に戻す。
  Future<Failure?> undoMarkEnded(Genba genba) => _run(
        endedKey,
        () => _mutate(genba.id, (c) => c.copyWith(manualEndedAt: null)),
      );

  /// 終演時刻の訂正（取り消さず、正しい時刻へ直接修正する）。
  Future<Failure?> correctEndedAt(Genba genba, DateTime endedAt) => _run(
        endedKey,
        () => _mutate(
          genba.id,
          (c) => c.copyWith(manualEndedAt: endedAt.toUtc()),
        ),
      );

  /// 「実際の終演時間」を記録し、現場の終演時間を上書きする（item 10）。
  ///
  /// 最初の終演時間は予想値（`endTimeMinutes`）。余韻・思い出入力で実際の終演
  /// 時刻を入れたら、状態導出に使う `manualEndedAt` に加え、表示に使う
  /// `endTimeMinutes`（開催日0:00からの分・日跨ぎは1440超）も更新して、概要・
  /// 当日・計画など終演時間を参照する箇所すべてに反映させる。[endedAt] は現地の
  /// 壁時計 DateTime（呼び出し側でイベント日の時刻から合成）。
  Future<Failure?> setActualEndTime(Genba genba, DateTime endedAt) => _run(
        endedKey,
        () {
          final eventDay = DateTime(
            genba.eventDate.year,
            genba.eventDate.month,
            genba.eventDate.day,
          );
          final minutes = endedAt.difference(eventDay).inMinutes;
          return _mutate(
            genba.id,
            (c) => c.copyWith(
              manualEndedAt: endedAt.toUtc(),
              endTimeMinutes: minutes,
            ),
          );
        },
      );

  // ---- 交通・宿泊の要否 -------------------------------------------------------

  Future<Failure?> setTransportRequirement(
    Genba genba,
    RequirementStatus value,
  ) =>
      _run(
        'transportRequirement',
        () => _mutate(genba.id, (c) => c.copyWith(transportRequirement: value)),
      );

  Future<Failure?> setLodgingRequirement(
    Genba genba,
    RequirementStatus value,
  ) =>
      _run(
        'lodgingRequirement',
        () => _mutate(genba.id, (c) => c.copyWith(lodgingRequirement: value)),
      );

  // ---- Todo -----------------------------------------------------------------

  String todoKey(String todoId) => 'todo:$todoId';

  Future<Failure?> toggleTodo(GenbaTodo todo, bool done) =>
      _run(todoKey(todo.id), () async {
        final result = await ref
            .read(genbaRepositoryProvider)
            .upsertTodo(todo.copyWith(isDone: done));
        return result.failureOrNull;
      });

  /// Todo/持ち物の削除。呼び出し前に presentation 側で確認ダイアログを表示すること。
  /// [toggleTodo] と同じ [todoKey] を使うため、同一項目の完了切替・削除・
  /// 連続削除が同時実行されることはない（キー単位の二重タップ防止）。
  /// owner認可・Outboxへの積み込みは [GenbaRepository.deleteTodo] へ委譲する。
  Future<Failure?> deleteTodo(GenbaTodo todo) =>
      _run(todoKey(todo.id), () async {
        final result =
            await ref.read(genbaRepositoryProvider).deleteTodo(todo.id);
        return result.failureOrNull;
      });

  // ---- 子データ削除（画像を伴うものは owner スコープで後始末する） --------------------

  String ticketKey(String ticketId) => 'ticket:$ticketId';
  String transportKey(String transportId) => 'transport:$transportId';
  String lodgingKey(String lodgingId) => 'lodging:$lodgingId';

  Future<Failure?> deleteTicket(Ticket ticket) =>
      _run(ticketKey(ticket.id), () async {
        final result =
            await ref.read(genbaRepositoryProvider).deleteTicket(ticket.id);
        final imageRef = ticket.imageLocalPath;
        if (result.isOk && imageRef != null) {
          await ref
              .read(imageStoreProvider)
              .deleteRef(ticket.ownerId, imageRef);
        }
        return result.failureOrNull;
      });

  Future<Failure?> deleteTransport(Transport transport) =>
      _run(transportKey(transport.id), () async {
        final result = await ref
            .read(genbaRepositoryProvider)
            .deleteTransport(transport.id);
        return result.failureOrNull;
      });

  Future<Failure?> deleteLodging(Lodging lodging) =>
      _run(lodgingKey(lodging.id), () async {
        final result =
            await ref.read(genbaRepositoryProvider).deleteLodging(lodging.id);
        return result.failureOrNull;
      });

  Future<Failure?> deleteMemo(GenbaMemo memo) =>
      _run('memo:${memo.id}', () async {
        final result =
            await ref.read(genbaRepositoryProvider).deleteMemo(memo.id);
        return result.failureOrNull;
      });

  /// メモの並び替え（現場内）。[orderedIds] の順に sort_order を振り直す。
  Future<Failure?> reorderMemos(String genbaId, List<String> orderedIds) =>
      _run('reorderMemos', () async {
        final result = await ref
            .read(genbaRepositoryProvider)
            .reorderMemos(genbaId: genbaId, orderedIds: orderedIds);
        return result.failureOrNull;
      });

  // ---- ヒーロー画像 -----------------------------------------------------------

  static const heroImageKey = 'heroImage';

  Future<Failure?> setHeroImage(Genba genba, String storedRef) =>
      _run(heroImageKey, () async {
        final owner = genba.ownerId;
        final result = await ref.read(genbaRepositoryProvider).mutateGenba(
              genba.id,
              (c) => c.copyWith(heroImageLocalPath: storedRef),
            );
        final store = ref.read(imageStoreProvider);
        switch (result) {
          case Ok(value: final previous):
            // 差替え成功: DB内の実際の旧画像を掃除する（画面が保持していた
            // 古い参照ではなく最新値の旧参照を使う）。新規保存で使う画像は残す。
            final old = previous.heroImageLocalPath;
            if (old != null && old != storedRef && owner.isNotEmpty) {
              await store.deleteRef(owner, old);
            }
            return null;
          case Err(failure: final f):
            // 保存失敗: 取り込んだファイルは孤立するので削除する。
            if (owner.isNotEmpty) await store.deleteRef(owner, storedRef);
            return f;
        }
      });

  Future<Failure?> removeHeroImage(Genba genba) => _run(heroImageKey, () async {
        final owner = genba.ownerId;
        final result = await ref.read(genbaRepositoryProvider).mutateGenba(
              genba.id,
              (c) => c.copyWith(heroImageLocalPath: null),
            );
        switch (result) {
          case Ok(value: final previous):
            final old = previous.heroImageLocalPath;
            if (old != null && owner.isNotEmpty) {
              await ref.read(imageStoreProvider).deleteRef(owner, old);
            }
            return null;
          case Err(failure: final f):
            return f;
        }
      });

  // ---- 現場削除（子データ・画像の孤立を残さない） -------------------------------------

  static const deleteGenbaKey = 'deleteGenba';

  /// 現場と子データを削除する。呼び出し前に presentation 側で確認ダイアログを
  /// 表示すること。成功時のみ画像を owner スコープで掃除する。
  ///
  /// [collectMemoryPhotoRefs] は思い出写真の画像参照一覧を返す（削除後は
  /// 取得できなくなるため、削除前に呼び出し側で収集させる）。収集に失敗しても
  /// 削除自体は妨げない（掃除は後続の cleanupOrphans/account 削除でも回収可能）。
  Future<Failure?> deleteGenba({
    required Genba genba,
    required List<String> imageRefs,
    Future<List<String>> Function()? collectMemoryPhotoRefs,
  }) =>
      _run(deleteGenbaKey, () async {
        final owner = genba.ownerId;
        final refs = <String>[...imageRefs];
        if (collectMemoryPhotoRefs != null) {
          try {
            refs.addAll(await collectMemoryPhotoRefs());
          } catch (_) {
            // 画像参照の収集失敗は削除自体を妨げない。
          }
        }
        final result =
            await ref.read(genbaRepositoryProvider).deleteGenba(genba.id);
        if (result.isOk && owner.isNotEmpty) {
          // レコード削除成功後に owner スコープでファイルを掃除する
          // （他ユーザーのファイルには決して触れない）。
          final store = ref.read(imageStoreProvider);
          for (final r in refs) {
            await store.deleteRef(owner, r);
          }
        }
        return result.failureOrNull;
      });
}

final genbaActionsControllerProvider = NotifierProvider.autoDispose
    .family<GenbaActionsController, Set<String>, String>(
  GenbaActionsController.new,
);
