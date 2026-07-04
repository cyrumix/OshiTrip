import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 選択中を紫の文字と下線で示すタブ（design-spec §4/§8）。
///
/// 選択状態は色だけでなく下線・太字・Semantics(selected) でも示す（§14）。
/// タブが収まらない幅では横スクロールする。
class SegmentTabs extends StatelessWidget {
  const SegmentTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            _SegmentTab(
              label: tabs[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
              selectedColor: scheme.primary,
              unselectedColor: tokens.textSecondary,
              dividerColor: tokens.divider,
            ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.dividerColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ラベルは子の Text がそのまま読み上げに使われる（二重付与しない）。
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // 主要タップ領域 48dp 以上（§3）。
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? selectedColor : dividerColor,
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? selectedColor : unselectedColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
