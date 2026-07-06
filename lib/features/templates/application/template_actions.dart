import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../../genba/domain/genba.dart';
import '../domain/template_presets.dart';
import '../domain/todo_template.dart';
import 'template_apply.dart';

/// テンプレート適用件数の結果（追加した件数・重複でスキップした件数）。
typedef TemplateApplyOutcome = ({int added, int skipped});

/// テンプレート機能のアプリケーション操作（純粋関数 [template_apply] と
/// リポジトリの橋渡し）。UIはこの provider を通じて適用・保存を行う。
final templateActionsProvider = Provider<TemplateActions>(
  TemplateActions.new,
);

class TemplateActions {
  TemplateActions(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  String? get _ownerId => _ref.read(authRepositoryProvider).currentUser?.id;
  DateTime get _now => _ref.read(clockProvider).now().toUtc();

  /// 選択したテンプレート項目を現場へ追加する。同種別・同名の重複は追加しない。
  ///
  /// [existing] は現在の現場の Todo/持ち物（重複判定と sortOrder 算出に使う）。
  /// 成功時は追加件数とスキップ件数を返す。1件でも保存に失敗したら、その時点の
  /// [Failure] を返す（一部は既に追加済みでも、通常のTodo追加と同じ扱い）。
  Future<Result<TemplateApplyOutcome>> applyTemplate({
    required String genbaId,
    required TodoItemType itemType,
    required List<TemplateOptionItem> selected,
    required List<GenbaTodo> existing,
  }) async {
    final owner = _ownerId;
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final plan = planTemplateApply(
      genbaId: genbaId,
      ownerId: owner,
      itemType: itemType,
      selected: selected,
      existing: existing,
      now: _now,
      newId: _uuid.v4,
    );
    final repo = _ref.read(genbaRepositoryProvider);
    for (final todo in plan.toAdd) {
      final res = await repo.upsertTodo(todo);
      if (!res.isOk) return Err(res.failureOrNull!);
    }
    return Ok((added: plan.toAdd.length, skipped: plan.skipped));
  }

  /// 現場の現在の項目から、名前付きのユーザーテンプレートを新規保存する。
  ///
  /// 完了状態・期限・担当者は保存しない（[buildTemplateItemsFromTodos]）。
  Future<Result<void>> saveCurrentAsTemplate({
    required String name,
    required TodoItemType itemType,
    required List<GenbaTodo> todos,
  }) async {
    final owner = _ownerId;
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('テンプレート名を入力してください'));
    }
    final now = _now;
    final template = TodoTemplate(
      id: _uuid.v4(),
      ownerId: owner,
      name: trimmed,
      itemType: itemType,
      createdAt: now,
      updatedAt: now,
    );
    final items = buildTemplateItemsFromTodos(
      templateId: template.id,
      ownerId: owner,
      itemType: itemType,
      todos: todos,
      now: now,
      newId: _uuid.v4,
    );
    return _ref.read(templateRepositoryProvider).saveTemplateWithItems(
          template: template,
          items: items,
          // 新規テンプレートなので既存項目の削除は不要。
          replaceItems: false,
        );
  }
}
