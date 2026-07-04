import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../app/theme/app_theme.dart';
import '../application/settings_controller.dart';

/// テーマ設定（design-spec §11）。
///
/// ライト／ダークのプレビューカードを並べ、選択リングとチェックで
/// 選択状態を示す（色だけに依存しない）。変更は即時保存・即時反映。
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    Future<void> select(ThemeMode mode) =>
        ref.read(themeModeProvider.notifier).setMode(mode);

    return AppScaffold(
      title: 'テーマ設定',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _ThemePreviewCard(
                  label: 'ライト',
                  theme: AppTheme.light(),
                  selected: themeMode == ThemeMode.light,
                  onTap: () => select(ThemeMode.light),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _ThemePreviewCard(
                  label: 'ダーク',
                  theme: AppTheme.dark(),
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => select(ThemeMode.dark),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (v) {
              if (v != null) select(v);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('端末の設定に合わせる'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('ライト'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('ダーク'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ミニプレビュー: 実テーマの配色でヒーロー/カード/文字の階層を再現する。
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.label,
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ThemeData theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = Theme.of(context);
    final tokens = theme.extension<AppTokens>() ?? AppTokens.light;
    return Semantics(
      button: true,
      selected: selected,
      label: '$labelテーマ${selected ? '（選択中）' : ''}',
      // プレビュー内部の装飾・ラベル文字をマージさせず、カード1枚=1ノード
      // として状態つきで読み上げる（§11/§14）。
      container: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected
                  ? current.colorScheme.primary
                  : current.colorScheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  padding: const EdgeInsets.all(AppSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              tokens.heroGradientStart,
                              tokens.heroGradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tokens.divider),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Container(
                        height: 8,
                        width: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: current.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: current.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
