import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 選択中を菫のピルで示すタブ（design-spec §4/§8 / デザイン刷新）。
///
/// 選択状態は色だけでなく塗り・太字・Semantics(selected) でも示す（§14）。
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
            Padding(
              padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 8),
              child: _SegmentTab(
                label: tabs[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
                fillColor: scheme.primary,
                onFillColor: scheme.onPrimary,
                unselectedColor: tokens.textSecondary,
              ),
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
    required this.fillColor,
    required this.onFillColor,
    required this.unselectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color fillColor;
  final Color onFillColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ラベルは子の Text がそのまま読み上げに使われる（二重付与しない）。
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? fillColor : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            // 主要タップ領域 48dp 以上を保つ（§3）。
            constraints: const BoxConstraints(minHeight: 48, minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.sm,
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected ? onFillColor : unselectedColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
