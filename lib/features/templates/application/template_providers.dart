import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../genba/domain/genba.dart';
import '../domain/template_presets.dart';
import '../domain/todo_template.dart';

/// 現在 owner のユーザーテンプレート（項目込み）。標準プリセットは含まない。
final userTemplatesProvider = StreamProvider<List<TodoTemplateWithItems>>(
  (ref) => ref.watch(templateRepositoryProvider).watchAll(),
);

/// 指定種別の「選択候補」（標準プリセット + ユーザーテンプレート）を、UIで
/// 同一に扱える [TemplateOption] のリストで返す。プリセットを先頭に並べる。
///
/// ユーザーテンプレートが loading の間はプリセットのみを返す（標準プリセットは
/// 常に各種別1件表示されるべきなので、ネットワーク/DB読み込みに依存させない）。
final templateOptionsProvider =
    Provider.family<List<TemplateOption>, TodoItemType>((ref, itemType) {
  final presets = [
    for (final p in presetsOfType(itemType)) TemplateOption.fromPreset(p),
  ];
  final userTemplates =
      ref.watch(userTemplatesProvider).valueOrNull ?? const [];
  final userOptions = [
    for (final t in userTemplates)
      if (t.template.itemType == itemType) TemplateOption.fromUserTemplate(t),
  ];
  return [...presets, ...userOptions];
});
