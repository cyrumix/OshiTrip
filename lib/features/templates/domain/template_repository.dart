import '../../../core/error/result.dart';
import 'todo_template.dart';

/// Todo・持ち物テンプレートのリポジトリ抽象（owner 単位のローカルCRUD + 同期）。
///
/// テンプレートは現場に属さず owner に属する（マイ推しと同じ owner スコープ）。
abstract interface class TemplateRepository {
  /// 現在 owner のユーザーテンプレート（項目込み）を監視する。
  /// 標準プリセットはここには含めない（アプリ内定数として別管理）。
  Stream<List<TodoTemplateWithItems>> watchAll();

  Future<Result<void>> upsertTemplate(TodoTemplate template);

  /// テンプレートを削除する（項目も同時に削除。標準プリセットは削除不可 =
  /// そもそもDBに存在しないため呼ばれない）。
  Future<Result<void>> deleteTemplate(String id);

  Future<Result<void>> upsertItem(TodoTemplateItem item);
  Future<Result<void>> deleteItem(String id);

  /// テンプレート本体と項目一式を1トランザクションで置き換える（「現在の内容を
  /// テンプレートに保存」用）。[replaceItems] が true のとき、既存項目のうち
  /// [items] に含まれない id を削除する（管理画面の並び替え・一括更新でも使う）。
  Future<Result<void>> saveTemplateWithItems({
    required TodoTemplate template,
    required List<TodoTemplateItem> items,
    bool replaceItems = true,
  });

  /// リモートのテンプレート／項目を現在 owner 限定でローカルへ取り込む。
  /// ローカル未同期変更は上書きしない。デモ・未ログインでは何もしない。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  /// 競合解決「サーバーを採用」用。所有しないテーブルは失敗を返す。
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}
