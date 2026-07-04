import '../db/app_database.dart';
import '../error/failure.dart';
import '../error/result.dart';
import 'outbox_operation.dart';
import 'outbox_store.dart';
import 'remote_pull.dart';

/// 同期対象テーブルのサーバー行を取得する seam（keep-local の版整合用）。
///
/// 本番は Supabase の `client.from(table).select()`。テストでは注入した
/// fake が固定行を返す。owner 限定は RLS（本番）と呼び出し側の再検証で担保。
typedef RemoteRowsFetcher = Future<List<Map<String, dynamic>>> Function(
  String tableName,
);

/// 対象エンティティ1件だけサーバー最新内容を取得・強制適用する seam
/// （「サーバーを採用」用）。本番は該当リポジトリの `adoptServerEntity`。
/// 通信・保存失敗は [Result] の [Err] として返す（成功扱いにしない）。
typedef ServerEntityAdopter = Future<Result<void>> Function(
  String entityTable,
  String entityId,
);

/// 競合(conflict)状態の Outbox 操作をユーザー選択で解決する（E-1 / R8-A）。
///
/// 競合は「サーバーが自分の base_version より先行している（他端末で更新された）」
/// ときに記録される。放置すると当該エンティティは pull でも上書きされず永久に
/// ローカルとサーバーが乖離する。本クラスは2つの明示的な解決手段を提供する:
///
/// - [useServer]（サーバーを採用・この端末の変更を破棄）: 競合opを残したまま
///   対象エンティティのサーバー最新内容を取得・強制適用し、成功を確認してから
///   競合opを削除する（失敗安全）。通信・保存失敗時は [Err] を返し、競合opと
///   再試行経路を維持する。
/// - [keepLocal]（この端末の変更で再送）: サーバーの現在版を版キャッシュへ整合
///   させてから競合opを pending へ戻し、drain で再送する。版CASが成立し、
///   サーバーがこの端末の内容で更新される。reconcile 後もサーバーが更に進んで
///   いれば再び conflict に戻る（無条件上書きはしない）。
///
/// いずれも「競合を黙って捨てる／自動で上書きする」ことはせず、ユーザーが選んだ
/// ときだけ実行する。owner分離を保ち、別ownerの競合は解決できない。
class ConflictResolver {
  ConflictResolver({
    required OutboxStore store,
    required AppDatabase db,
    required RemoteRowsFetcher fetchRemoteRows,
    required ServerEntityAdopter adoptServerEntity,
    required Future<void> Function() drain,
  })  : _store = store,
        _db = db,
        _fetchRemoteRows = fetchRemoteRows,
        _adoptServerEntity = adoptServerEntity,
        _drain = drain;

  final OutboxStore _store;
  final AppDatabase _db;
  final RemoteRowsFetcher _fetchRemoteRows;
  final ServerEntityAdopter _adoptServerEntity;
  final Future<void> Function() _drain;

  /// [ownerId] の競合一覧（解決UI用）。
  Future<List<OutboxOperation>> conflicts({required String ownerId}) =>
      _store.conflictOps(ownerId: ownerId);

  /// サーバーの内容を採用し、この端末の競合中の変更を破棄する（失敗安全）。
  ///
  /// 手順（R8-A 再レビュー）:
  /// 1. **先に** サーバーの最新内容を取得して当該エンティティへ強制適用する
  ///    （競合opは残したまま）。通信・保存に失敗したら [Err] を返し、競合を
  ///    未解決のまま維持する（版キャッシュ・Outbox・別owner行に触れない）。
  /// 2. 適用に**成功してから初めて**競合opを削除する。
  ///
  /// これにより「競合表示だけ消えて古いローカルデータが残る／通信失敗を成功と
  /// 誤表示する」不具合を防ぐ。通信成功前にローカル変更を不可逆に消さない。
  Future<Result<ConflictResolutionResult>> useServer(
    String mutationId, {
    required String ownerId,
  }) async {
    final op = await _store.conflictById(mutationId, ownerId: ownerId);
    if (op == null) return const Ok(ConflictResolutionResult.notFound);
    // 1. サーバー内容を取得・適用（競合opは残す）。失敗なら競合は未解決のまま。
    final adopt = await _adoptServerEntity(op.entityTable, op.entityId);
    if (adopt is Err<void>) return Err(adopt.failure);
    // 2. 適用成功を確認してから競合opを削除する（失敗安全）。
    await _store.discardConflict(mutationId, ownerId: ownerId);
    return const Ok(ConflictResolutionResult.resolved);
  }

  /// この端末の変更でサーバーを上書きする（競合中のローカル編集を採用）。
  ///
  /// 手順: サーバー現在版を取得（失敗なら競合を維持し [Err]）→ 版キャッシュへ
  /// 整合（reconcile、ローカル行は保持）→ 競合op を pending へ戻す → drain で
  /// 再送。版CASが成立すればサーバーがこの端末の内容で更新される。reconcile 後に
  /// サーバーが更に進んでいれば再び conflict（[stillConflicting]）。drain が
  /// オフライン等で完了しなければ [Err] を返し「解決済み」とは扱わない。
  Future<Result<ConflictResolutionResult>> keepLocal(
    String mutationId, {
    required String ownerId,
  }) async {
    final op = await _store.conflictById(mutationId, ownerId: ownerId);
    if (op == null) return const Ok(ConflictResolutionResult.notFound);
    // サーバーの現在版を取得（通信失敗なら競合を維持したまま Err）。
    final List<Map<String, dynamic>> rows;
    try {
      rows = await _fetchRemoteRows(op.entityTable);
    } on Failure catch (f) {
      return Err(f);
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
    await reconcileServerVersionInto(
      db: _db,
      owner: ownerId,
      tableName: op.entityTable,
      entityId: op.entityId,
      rows: rows,
    );
    final reopened = await _store.reopenConflict(mutationId, ownerId: ownerId);
    if (!reopened) return const Ok(ConflictResolutionResult.notFound);
    await _drain();
    // drain 後の状態で判定する。
    final after = await _store.opById(mutationId, ownerId: ownerId);
    if (after == null) return const Ok(ConflictResolutionResult.resolved);
    if (after.status == OutboxStatus.conflict) {
      return const Ok(ConflictResolutionResult.stillConflicting);
    }
    // pending/syncing/failed: 再送が確定していない（オフライン等）。「解決済み」に
    // せず、通信/保存失敗として返す（opは通常の再送キューに残り自動再送される）。
    return Err(
      after.status == OutboxStatus.failed
          ? const StorageFailure(message: '再送に失敗しました。時間をおいて再試行してください')
          : const NetworkFailure(message: '同期を完了できませんでした。接続を確認して再試行してください'),
    );
  }
}

/// 競合解決の結果。
enum ConflictResolutionResult {
  /// 解決した（サーバー採用でローカル上書き、または再送成功）。
  resolved,

  /// 対象が見つからない（既に解決済み・別owner・競合以外）。
  notFound,

  /// 再送したが依然として競合（サーバーが更に進んでいた）。もう一度
  /// 解決操作を選び直せる。
  stillConflicting,
}
