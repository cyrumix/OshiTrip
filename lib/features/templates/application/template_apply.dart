import '../../genba/domain/genba.dart';
import '../domain/template_presets.dart';
import '../domain/todo_template.dart';

/// テンプレート適用の結果（追加する項目と、重複でスキップした件数）。
class TemplateApplyPlan {
  const TemplateApplyPlan({required this.toAdd, required this.skipped});

  /// 実際に現場へ追加する Todo/持ち物。
  final List<GenbaTodo> toAdd;

  /// 同種別・同名で既に登録済みのため追加しなかった件数。
  final int skipped;
}

/// 選択された [TemplateOptionItem] を現場へ追加するための [GenbaTodo] 一覧を
/// 組み立てる（純粋関数）。
///
/// - 同じ種別かつ同じ名前の項目が既に現場にある場合は重複登録せずスキップし、
///   件数を [TemplateApplyPlan.skipped] に数える。
/// - 選択リスト内の重複（同名）も1件だけ追加する。
/// - 名前は前後空白を無視して比較する。
/// - 期限・担当・完了状態はテンプレートに無いため設定しない（未完了で追加）。
/// - 持ち物は重要度を持たない（priority は無視して normal 相当の既定）。
/// - 新規項目の sortOrder は、既存の同種別項目の最大 sortOrder の後ろへ、
///   テンプレートの並び順を保って割り当てる。
TemplateApplyPlan planTemplateApply({
  required String genbaId,
  required String ownerId,
  required TodoItemType itemType,
  required List<TemplateOptionItem> selected,
  required List<GenbaTodo> existing,
  required DateTime now,
  required String Function() newId,
}) {
  final sameType = existing.where((t) => t.type == itemType).toList();
  final seen = <String>{
    for (final t in sameType) t.name.trim(),
  };
  final baseOrder = sameType.isEmpty
      ? 0
      : sameType.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

  final toAdd = <GenbaTodo>[];
  var skipped = 0;
  for (final item in selected) {
    final name = item.name.trim();
    if (name.isEmpty) continue;
    if (seen.contains(name)) {
      skipped++;
      continue;
    }
    seen.add(name);
    final ts = now.toUtc();
    toAdd.add(
      GenbaTodo(
        id: newId(),
        genbaId: genbaId,
        ownerId: ownerId,
        name: name,
        type: itemType,
        // 持ち物は重要度を持たない。Todo はテンプレートの重要度を引き継ぐ。
        priority: itemType == TodoItemType.belonging
            ? TodoPriority.normal
            : (item.priority ?? TodoPriority.normal),
        memo: item.memo,
        isDone: false,
        sortOrder: baseOrder + toAdd.length,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
  }
  return TemplateApplyPlan(toAdd: toAdd, skipped: skipped);
}

/// 現場の現在の [GenbaTodo] からテンプレート項目を組み立てる（純粋関数）。
///
/// - 完了状態・期限・担当者はテンプレートへ引き継がない。
/// - Todo テンプレートは重要度を保存し、持ち物テンプレートは priority=null。
/// - sortOrder は渡された順序を保つ（0 始まりの連番）。
List<TodoTemplateItem> buildTemplateItemsFromTodos({
  required String templateId,
  required String ownerId,
  required TodoItemType itemType,
  required List<GenbaTodo> todos,
  required DateTime now,
  required String Function() newId,
}) {
  final ts = now.toUtc();
  final items = <TodoTemplateItem>[];
  for (var i = 0; i < todos.length; i++) {
    final todo = todos[i];
    items.add(
      TodoTemplateItem(
        id: newId(),
        templateId: templateId,
        ownerId: ownerId,
        name: todo.name.trim(),
        // 持ち物は重要度を持たない。Todo のみ重要度を保存する。
        priority: itemType == TodoItemType.belonging ? null : todo.priority,
        memo: todo.memo,
        sortOrder: i,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
  }
  return items;
}
