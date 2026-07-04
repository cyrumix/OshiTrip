import '../../../core/error/result.dart';
import 'oshi.dart';

/// マイ推しのリポジトリ抽象（ローカルCRUD + 同期）。
abstract interface class OshiRepository {
  Stream<List<OshiGroupWithMembers>> watchAll();

  /// ユーザー定義記念日を owner 限定で監視する（design-spec §10/§12.1）。
  Stream<List<OshiAnniversary>> watchAnniversaries();

  Future<Result<void>> upsertGroup(OshiGroup group);
  Future<Result<void>> deleteGroup(String id);

  Future<Result<void>> upsertMember(OshiMember member);
  Future<Result<void>> deleteMember(String id);

  Future<Result<void>> upsertAnniversary(OshiAnniversary anniversary);
  Future<Result<void>> deleteAnniversary(String id);

  /// リモートの推しグループ／メンバー／記念日を現在 owner 限定でローカルへ
  /// 取り込む（H-02: キャッシュ先行→背景更新）。ローカル未同期変更は上書き
  /// しない。デモ・未ログインでは何もしない。
  /// [isStale] は認証切替検出用（true で以降のローカル適用を中断）。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  /// 競合解決「サーバーを採用」用（R8-A 再レビュー）: [entityTable] の
  /// [entityId] 1件だけサーバー最新内容を取得しローカルへ強制適用する。
  /// 通信・保存失敗時は [Err] を返しローカルは変更しない（呼び出し側は成功後に
  /// 競合opを削除する = 失敗安全）。所有しないテーブルは失敗を返す。
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}
