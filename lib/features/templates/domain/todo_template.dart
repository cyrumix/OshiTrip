// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';
import '../../genba/domain/genba.dart';

part 'todo_template.freezed.dart';
part 'todo_template.g.dart';

/// Todo・持ち物のテンプレート（owner 単位でローカル保存・リモート同期）。
///
/// 1つのテンプレートは [itemType]（Todo または 持ち物）で種別が固定され、
/// テンプレート内に両種別を混在させない。種別・重要度の enum は現場の
/// [TodoItemType] / [TodoPriority] を再利用する（同じ意味を二重定義しない）。
@freezed
abstract class TodoTemplate with _$TodoTemplate {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory TodoTemplate({
    required String id,
    required String ownerId,
    required String name,

    /// このテンプレートが扱う種別（todo / belonging）。テンプレート内の
    /// 全項目がこの種別として適用される。
    required TodoItemType itemType,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _TodoTemplate;

  factory TodoTemplate.fromJson(Map<String, dynamic> json) =>
      _$TodoTemplateFromJson(json);
}

/// テンプレートに含まれる項目。適用時に現場の Todo/持ち物へ複製される。
///
/// テンプレートには「現場固有情報」（期限・担当者・完了状態）を保存しない。
/// Todo 種別のみ [priority] を保持し、持ち物種別では null（持ち物は重要度を
/// 持たない）。
@freezed
abstract class TodoTemplateItem with _$TodoTemplateItem {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory TodoTemplateItem({
    required String id,
    required String templateId,
    required String ownerId,
    required String name,

    /// 重要度（Todo テンプレートのみ。持ち物では null）。
    TodoPriority? priority,
    String? memo,
    @Default(0) int sortOrder,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _TodoTemplateItem;

  factory TodoTemplateItem.fromJson(Map<String, dynamic> json) =>
      _$TodoTemplateItemFromJson(json);
}

/// テンプレートと項目の集約ビュー。
@freezed
abstract class TodoTemplateWithItems with _$TodoTemplateWithItems {
  const TodoTemplateWithItems._();

  const factory TodoTemplateWithItems({
    required TodoTemplate template,
    @Default(<TodoTemplateItem>[]) List<TodoTemplateItem> items,
  }) = _TodoTemplateWithItems;

  /// sortOrder 昇順（同値は createdAt 昇順）で並べた項目。
  List<TodoTemplateItem> get sortedItems {
    final list = [...items];
    list.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }
}
