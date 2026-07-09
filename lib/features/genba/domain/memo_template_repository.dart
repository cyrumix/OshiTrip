import '../../../core/error/result.dart';
import 'memo_template.dart';

/// メモテンプレートのリポジトリ抽象（owner スコープ・単一行・Outbox 同期）。
/// Todo テンプレートと同思想だが、雛形は content(JSON) に持つため子テーブルは無い。
abstract interface class MemoTemplateRepository {
  Stream<List<MemoTemplate>> watchAll();

  Future<Result<void>> upsertTemplate(MemoTemplate template);

  Future<Result<void>> deleteTemplate(String id);

  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}
