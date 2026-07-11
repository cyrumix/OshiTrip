import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../app/theme/app_theme.dart';
import '../application/oshi_color_controller.dart';

/// 推しカラー設定（design-spec §11）。
///
/// プリセット（8色以上）とカスタム（#RRGGBB）を扱う。選択は色だけに
/// 依存せずリングとチェックで示し、選択色は現場カードの罫線・
/// アバターリングのプレビューへ即時反映する。変更は自動保存。
class OshiColorSettingsScreen extends ConsumerWidget {
  const OshiColorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final currentHex = ref.watch(oshiColorProvider).valueOrNull;
    final isCustom =
        currentHex != null && !oshiColorPresets.any((p) => p.hex == currentHex);

    Future<void> select(String hex) async {
      final ok = await ref.read(oshiColorProvider.notifier).setHex(hex);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カラーコードは #RRGGBB 形式で入力してください')),
        );
      }
    }

    return AppScaffold(
      title: '推しカラー設定',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Text(
            '現場カードの罫線やアバターリングなど、アクセントに使う色です。'
            'グループに推しカラーが設定されている場合はそちらを優先します。',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              for (final preset in oshiColorPresets)
                _ColorSwatch(
                  name: preset.name,
                  color: AppTheme.tryParseHexColor(preset.hex)!,
                  selected: currentHex == preset.hex,
                  onTap: () => select(preset.hex),
                ),
              _CustomSwatch(
                selected: isCustom,
                currentHex: isCustom ? currentHex : null,
                onSubmit: select,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          const SectionHeader(
            title: 'プレビュー',
            padding: EdgeInsets.only(bottom: AppSpace.sm),
          ),
          _AccentPreview(hex: currentHex),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '推しカラー: $name${selected ? '（選択中）' : ''}',
      // ラベルへ状態まで含めているため、子のテキストをマージさせず
      // 1スウォッチ=1ノードとして読み上げる（§11/§14）。
      container: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                // 選択リング（色だけに依存しない, §11/§14）。
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check,
                      color: ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    )
                  : null,
            ),
            const SizedBox(height: 2),
            Text(name, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _CustomSwatch extends ConsumerWidget {
  const _CustomSwatch({
    required this.selected,
    required this.currentHex,
    required this.onSubmit,
  });

  final bool selected;
  final String? currentHex;
  final Future<void> Function(String hex) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppTheme.tryParseHexColor(currentHex);
    return Semantics(
      button: true,
      selected: selected,
      label: '推しカラー: カスタム${selected ? '（選択中）' : ''}',
      container: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: () async {
          final hex = await showTextPromptDialog(
            context,
            title: 'カスタムカラー',
            labelText: 'カラーコード（#RRGGBB）',
            hintText: '#7B5CFF',
            initialText: currentHex ?? '#',
            confirmLabel: '決定',
          );
          if (hex != null && hex.isNotEmpty) await onSubmit(hex);
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: color == null
                  ? const Icon(Icons.colorize_outlined)
                  : (selected ? const Icon(Icons.check) : null),
            ),
            const SizedBox(height: 2),
            Text('カスタム', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// 選択色の即時反映プレビュー（§11）: 現場カードの罫線とアバターリング。
class _AccentPreview extends ConsumerWidget {
  const _AccentPreview({required this.hex});

  final String? hex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppTheme.accentFromHex(hex, scheme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventListCard(
          title: 'プレビューの現場',
          subtitle: '推しグループ',
          dateLabel: '2026/8/1',
          venue: 'プレビューホール',
          daysUntil: 12,
          accentColor: accent,
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            OshiAvatar(name: '推', ringColor: accent, selected: true),
            const SizedBox(width: AppSpace.md),
            OshiAvatar(name: 'し', ringColor: accent),
          ],
        ),
      ],
    );
  }
}
