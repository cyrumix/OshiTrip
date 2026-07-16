import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../genba/domain/genba.dart';
import '../application/memory_controllers.dart';
import '../application/year_summary.dart';

/// 「◯年のふりかえり」シート（design-spec §8/§9・D-252/M5）。
///
/// その年の参戦数・よく会いに行った推し・よく行った会場・遠征などを、
/// 蓄積が嬉しくなるレイアウトで見せる。写真数はバンドル（記録）依存なので、
/// loading/error を「0枚」に潰さず、集計中／取得失敗を区別する（§15・レビュー是正）。
Future<void> showYearSummarySheet(
  BuildContext context, {
  required int year,
  required List<GenbaAggregate> items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _YearSummarySheet(year: year, items: items),
  );
}

/// 写真数の集計状態（loading/error を 0 に潰さない）。
enum _PhotoStatState { loading, error, ready }

class _YearSummarySheet extends ConsumerWidget {
  const _YearSummarySheet({required this.year, required this.items});

  final int year;
  final List<GenbaAggregate> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    // 写真数だけはバンドル依存。読込中・失敗を区別し、確定分のみ集計に渡す。
    final bundleAsyncs = [
      for (final a in items) ref.watch(memoryBundleProvider(a.genba.id)),
    ];
    final anyLoading = bundleAsyncs.any((b) => b.isLoading && !b.hasValue);
    final anyError = bundleAsyncs.any((b) => b.hasError && !b.hasValue);
    final photoCounts = <String, int>{
      for (var i = 0; i < items.length; i++)
        if (bundleAsyncs[i].hasValue)
          items[i].genba.id: bundleAsyncs[i].value!.photos.length,
    };
    final photoState = anyLoading
        ? _PhotoStatState.loading
        : anyError
            ? _PhotoStatState.error
            : _PhotoStatState.ready;

    // 現場アグリゲートから常に導出できる集計＋（確定した）写真数。
    final summary = computeYearSummary(year, items, photoCounts: photoCounts);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpace.sm),
                Text(
                  '$year年のふりかえり',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: _BigStat(
                    value: '${summary.genbaCount}',
                    unit: '現場',
                    emphasized: true,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _BigStat(
                    value: '${summary.attendedCount}',
                    unit: '参戦',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (summary.topArtist != null)
              _HighlightRow(
                icon: Icons.favorite,
                label: 'よく会いに行った',
                value: summary.topArtist!.name,
                trailing: '${summary.topArtist!.count}回',
              ),
            if (summary.topVenue != null)
              _HighlightRow(
                icon: Icons.place_outlined,
                label: 'よく行った会場',
                value: summary.topVenue!.name,
                trailing: '${summary.topVenue!.count}回',
              ),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                _MiniStat(
                  icon: Icons.stadium_outlined,
                  label: '訪れた会場',
                  value: '${summary.venueCount}',
                ),
                _MiniStat(
                  icon: Icons.directions_transit_outlined,
                  label: '遠征した現場',
                  value: '${summary.expeditionCount}',
                ),
                // 写真数は状態別（集計中／取得失敗／確定）。0 に潰さない。
                ..._photoStat(summary, photoState),
              ],
            ),
            if (summary.genbaCount == 0) ...[
              const SizedBox(height: AppSpace.md),
              Text(
                'この年の思い出はまだありません。',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _photoStat(YearSummary summary, _PhotoStatState state) {
    return switch (state) {
      _PhotoStatState.loading => const [
          _MiniStat(
            icon: Icons.photo_outlined,
            label: '写真',
            value: '集計中…',
          ),
        ],
      _PhotoStatState.error => const [
          _MiniStat(
            icon: Icons.photo_outlined,
            label: '写真',
            value: '取得できませんでした',
          ),
        ],
      _PhotoStatState.ready => summary.photoCount > 0
          ? [
              _MiniStat(
                icon: Icons.photo_outlined,
                label: '写真',
                value: '${summary.photoCount}枚',
              ),
            ]
          : const <Widget>[],
    };
  }
}

/// 主役の大きな数字＋単位。
class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.unit,
    this.emphasized = false,
  });

  final String value;
  final String unit;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? tokens.primarySoft
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: emphasized ? theme.colorScheme.primary : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              unit,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「よく会いに行った / よく行った会場」の目立つ1行。
class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpace.sm),
          Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            trailing,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 補足の小さなスタッツ（アイコン＋値＋ラベル）。
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Semantics(
      label: '$label $value',
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: tokens.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tokens.textSecondary),
            const SizedBox(width: AppSpace.xs),
            Text(
              value,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
