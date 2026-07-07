import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../genba/domain/genba.dart';
import '../domain/todo_template.dart';

/// Drift 行 ⇄ テンプレートエンティティのマッピング。
///
/// item_type / priority は現場の [TodoItemType] / [TodoPriority] と同じ
/// snake_case 文字列（'todo'/'belonging'、'low'/'normal'/'high'）で保持する。
TodoTemplate templateFromRow(TodoTemplateRow row) => TodoTemplate(
      id: row.id,
      ownerId: row.ownerId,
      name: row.name,
      itemType: _templateType(row.itemType),
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

TodoTemplatesCompanion templateToCompanion(TodoTemplate t) =>
    TodoTemplatesCompanion.insert(
      id: t.id,
      ownerId: t.ownerId,
      name: t.name,
      itemType: t.itemType.name,
      createdAt: t.createdAt.toUtc().toIso8601String(),
      updatedAt: t.updatedAt.toUtc().toIso8601String(),
    );

TodoTemplateItem templateItemFromRow(TodoTemplateItemRow row) =>
    TodoTemplateItem(
      id: row.id,
      templateId: row.templateId,
      ownerId: row.ownerId,
      name: row.name,
      priority: _priority(row.priority),
      memo: row.memo,
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

TodoTemplateItemsCompanion templateItemToCompanion(TodoTemplateItem i) =>
    TodoTemplateItemsCompanion.insert(
      id: i.id,
      templateId: i.templateId,
      ownerId: i.ownerId,
      name: i.name,
      priority: Value(i.priority?.name),
      memo: Value(i.memo),
      sortOrder: Value(i.sortOrder),
      createdAt: i.createdAt.toUtc().toIso8601String(),
      updatedAt: i.updatedAt.toUtc().toIso8601String(),
    );

TodoItemType _templateType(String raw) => TodoItemType.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => TodoItemType.todo,
    );

TodoPriority? _priority(String? raw) {
  if (raw == null) return null;
  for (final v in TodoPriority.values) {
    if (v.name == raw) return v;
  }
  return null;
}
