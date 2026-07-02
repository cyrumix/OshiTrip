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
  Future<Result<void>> refreshFromRemote();
}
