import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/providers.dart';
import '../application/memo_template_providers.dart';
import '../domain/memo_content.dart';
import '../domain/memo_template.dart';
import '../domain/memo_template_presets.dart';
import 'widgets/memo_kind_icon.dart';

/// メモテンプレートの管理（§7.7 改訂）。標準テンプレートは閲覧・適用のみ、マイ
/// テンプレートは名称変更・削除ができる。テンプレートの内容編集は「メモ編集画面
/// で作った構成をテンプレートに保存」する経路で行う（Todo テンプレートと同思想）。
class MemoTemplateManageScreen extends ConsumerWidget {
  const MemoTemplateManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTemplates = ref.watch(userMemoTemplatesProvider);
    return AppScaffold(
      title: 'メモテンプレート',
      body: ListView(
        children: [
          const SectionHeader(title: '標準テンプレート（適用のみ）'),
          for (final p in kMemoTemplatePresets)
            AppCard(
              margin: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.sm,
              ),
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(memoKindIcon(p.kind)),
                title: Text(p.name),
                subtitle: Text(p.kind.label),
              ),
            ),
          const SectionHeader(title: 'マイテンプレート'),
          userTemplates.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpace.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(AppSpace.lg),
              child: Text('テンプレートを読み込めませんでした'),
            ),
            data: (templates) {
              if (templates.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.lg,
                    0,
                    AppSpace.lg,
                    AppSpace.lg,
                  ),
                  child: Text(
                    'まだありません。メモ編集画面で作った構成を'
                    '「テンプレートとして保存」すると、ここに追加されます。',
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in templates)
                    AppCard(
                      margin: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        0,
                        AppSpace.lg,
                        AppSpace.sm,
                      ),
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(memoKindIcon(t.kind)),
                        title: Text(t.name),
                        subtitle: Text(t.kind.label),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '名称を変更',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _rename(context, ref, t),
                            ),
                            IconButton(
                              tooltip: '削除',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(context, ref, t),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpace.lg),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    MemoTemplate template,
  ) async {
    final name = await showTextPromptDialog(
      context,
      title: 'テンプレート名を変更',
      labelText: 'テンプレート名',
      initialText: template.name,
    );
    if (name == null || name.isEmpty) return;
    await ref
        .read(memoTemplateRepositoryProvider)
        .upsertTemplate(template.copyWith(name: name));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MemoTemplate template,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('テンプレートを削除'),
        content: Text('「${template.name}」を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(memoTemplateRepositoryProvider).deleteTemplate(template.id);
  }
}
