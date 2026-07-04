import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../genba/application/genba_providers.dart';
import '../../settings/application/oshi_color_controller.dart';
import '../domain/oshi.dart';
import '../domain/oshi_stats.dart';

final oshiGroupsProvider = StreamProvider<List<OshiGroupWithMembers>>(
  (ref) => ref.watch(oshiRepositoryProvider).watchAll(),
);

/// ユーザー定義記念日（owner 限定）。
final oshiAnniversariesProvider = StreamProvider<List<OshiAnniversary>>(
  (ref) => ref.watch(oshiRepositoryProvider).watchAnniversaries(),
);

/// 現場のアクセント色を解決する（design-spec §2/§6.3）。
///
/// 紐づく推しグループの推しカラー → ユーザーの推しカラー設定 →
/// テーマPrimary の順でフォールバックする。アクセント（罫線・リング・
/// プレースホルダー）のみに使い、本文の可読性を壊さない。
Color resolveOshiAccent(
  WidgetRef ref,
  ColorScheme scheme, {
  String? oshiGroupId,
}) {
  if (oshiGroupId != null) {
    final groups = ref.watch(oshiGroupsProvider).valueOrNull;
    if (groups != null) {
      for (final g in groups) {
        if (g.group.id == oshiGroupId) {
          final parsed = AppTheme.tryParseHexColor(g.group.color);
          if (parsed != null) return parsed;
          break;
        }
      }
    }
  }
  return resolveUserAccent(ref, scheme);
}

/// 推しグループ単位の活動統計（保存済みデータから導出。固定値ではない）。
/// 入力は owner 限定の [genbaAggregatesProvider] のため owner 分離が保たれる。
final oshiStatsProvider = Provider.family<AsyncValue<OshiStats>, String>(
  (ref, groupId) {
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    return ref.watch(genbaAggregatesProvider).whenData(
          (genbas) => deriveOshiStats(
            groupId: groupId,
            genbas: genbas,
            now: now,
          ),
        );
  },
);

/// 推しグループ単位の記念日一覧（近い順）。メンバーの誕生日・推し始めた日と
/// ユーザー定義記念日から導出する。
///
/// グループ・記念日いずれかが loading なら loading、error なら error を返す。
/// エラーを空一覧へ変換して隠さない（R6独立レビュー#4）。
final oshiUpcomingAnniversariesProvider =
    Provider.family<AsyncValue<List<UpcomingAnniversary>>, String>(
  (ref, groupId) {
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final groupsAsync = ref.watch(oshiGroupsProvider);
    final anniversariesAsync = ref.watch(oshiAnniversariesProvider);
    // どちらかが loading/error ならそれを伝播する（両方 data のときだけ導出）。
    return groupsAsync.when(
      loading: AsyncValue<List<UpcomingAnniversary>>.loading,
      error: AsyncValue<List<UpcomingAnniversary>>.error,
      data: (groups) => anniversariesAsync.whenData((anniversaries) {
        final members = groups
            .where((g) => g.group.id == groupId)
            .expand((g) => g.members)
            .toList();
        final scoped =
            anniversaries.where((a) => a.groupId == groupId).toList();
        return deriveUpcomingAnniversaries(
          members: members,
          anniversaries: scoped,
          now: now,
        );
      }),
    );
  },
);
