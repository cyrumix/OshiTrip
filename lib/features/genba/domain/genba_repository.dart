import '../../../core/error/result.dart';
import 'genba.dart';

/// 現場集約のリポジトリ抽象（domain層・実装は data 層）。
///
/// 読み取りはローカルキャッシュ由来の Stream を返し、
/// 書き込みは「ローカル反映 → Outbox → リモート同期」で行う（§15.3）。
abstract interface class GenbaRepository {
  /// すべての現場（子データ込み）。UI 側で未来/思い出に振り分ける。
  Stream<List<GenbaAggregate>> watchAll();

  Stream<GenbaAggregate?> watchById(String id);

  Future<Result<void>> upsertGenba(Genba genba);

  /// 現場の一部フィールドだけを、DB内の最新値へ適用して更新する。
  ///
  /// [update] は「同一transaction内で読み直した最新の [Genba]」を受け取り、
  /// 変更後の [Genba] を返す。画面が保持していた古いスナップショット全体を
  /// 上書きしないため、同一現場への別フィールド更新（交通要否・宿泊要否・
  /// 中止・終演・ヒーロー画像など）が並行・連続しても互いの変更を失わない。
  /// Outbox へ送る payload も merge 後の最終状態から生成する。
  ///
  /// 成功時は「更新前」の [Genba]（画像の後始末等で旧参照が必要な呼び出し向け）
  /// を返す。対象が存在しない（別owner含む）場合は [NotFoundFailure]。
  Future<Result<Genba>> mutateGenba(
    String genbaId,
    Genba Function(Genba current) update,
  );

  /// 現場と子データを削除する（確認ダイアログ必須の危険操作）。
  Future<Result<void>> deleteGenba(String id);

  Future<Result<void>> upsertTicket(Ticket ticket);
  Future<Result<void>> deleteTicket(String id);

  Future<Result<void>> upsertTransport(Transport transport);
  Future<Result<void>> deleteTransport(String id);

  Future<Result<void>> upsertLodging(Lodging lodging);
  Future<Result<void>> deleteLodging(String id);

  Future<Result<void>> upsertTodo(GenbaTodo todo);
  Future<Result<void>> deleteTodo(String id);

  Future<Result<void>> upsertMemo(GenbaMemo memo);
  Future<Result<void>> deleteMemo(String id);

  /// リモートの最新状態をローカルへ取り込む（キャッシュ先行表示の裏側で実行）。
  ///
  /// [isStale] は認証切替検出用（H-02）。各リモート取得後・ローカル適用直前に
  /// 呼ばれ、true なら以降のローカル書き込みを中断する。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  /// 競合解決「サーバーを採用」用（R8-A 再レビュー）: [entityTable] の
  /// [entityId] 1件だけ、サーバーの最新内容を取得してローカルへ強制適用する
  /// （競合opが残っていても上書きし、サーバーに無ければローカル行を削除する）。
  ///
  /// このリポジトリが所有しないテーブルが渡された場合は失敗を返す。通信・保存に
  /// 失敗したら [Result] の [Err]（NetworkFailure 等）を返し、ローカルは変更しない。
  /// 呼び出し側は成功を確認してから競合opを削除する（失敗安全）。
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}
