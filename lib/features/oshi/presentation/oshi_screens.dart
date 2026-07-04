import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba_schedule.dart';
import '../../genba/presentation/widgets/action_feedback.dart';
import '../../settings/application/oshi_color_controller.dart';
import '../application/oshi_actions_controller.dart';
import '../application/oshi_providers.dart';
import '../domain/oshi.dart';
import '../domain/oshi_stats.dart';
import 'oshi_editors.dart';

/// マイ推し（design-spec §10）。
///
/// グループごとのプロフィールカード（画像/イニシャル・推しカラーリング・
/// お気に入り）、横スクロールのメンバー、導出統計3件、次の現場、
/// 誕生日・記念日を表示する。統計は保存済みデータからの導出値のみ
/// （登録数を「参戦数」と表示しない, §10/§12.1）。
class OshiListScreen extends ConsumerWidget {
  const OshiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(oshiGroupsProvider);
    return AppScaffold(
      title: 'マイ推し',
      body: AsyncValueView<List<OshiGroupWithMembers>>(
        value: groupsAsync,
        isEmpty: (list) => list.isEmpty,
        loadingView: const LoadingSkeleton.list(cardCount: 2),
        emptyView: EmptyView(
          icon: Icons.favorite_outline,
          message: 'まだ推しが登録されていません',
          description: 'グループやアーティストを登録すると、現場作成時に選べるようになります。',
          actionLabel: '推しを登録する',
          onAction: () => showGroupEditor(context, ref),
        ),
        data: (groups) => ListView(
          key: const PageStorageKey('oshi_list'),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          children: [
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: 6,
                ),
                child: _GroupCard(item: g),
              ),
            const SizedBox(height: 96),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'oshi_fab',
        onPressed: () => showGroupEditor(context, ref),
        tooltip: '推しグループを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.item});

  final OshiGroupWithMembers item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final group = item.group;
    // 推しカラーの優先順位: グループ固有カラー → ユーザー設定 → Primary
    // （design-spec §2 / decisions.md R7）。
    final accent = AppTheme.tryParseHexColor(group.color) ??
        resolveUserAccent(ref, theme.colorScheme);
    final groupImage = group.imageLocalPath == null
        ? null
        : ref
            .read(imageStoreProvider)
            .tryResolveOwned(group.ownerId, group.imageLocalPath!);
    final saioshi = item.members
        .where((m) => m.rank == OshiRank.saioshi)
        .map((m) => m.name)
        .toList();
    final favoriteBusy = ref
        .watch(oshiActionsControllerProvider)
        .contains(OshiActionsController.groupFavoriteKey(group.id));

    Future<void> toggleFavorite() async {
      final failure = await ref
          .read(oshiActionsControllerProvider.notifier)
          .setGroupFavorite(groupId: group.id, isFavorite: !group.isFavorite);
      if (context.mounted) handleActionResult(context, failure);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プロフィール行: 画像/initial + 推しカラーring + 名前/種別 + お気に入り。
          Row(
            children: [
              OshiAvatar(
                name: group.name,
                imageFile: groupImage,
                ringColor: accent,
                size: 56,
                altText: group.imageAltText ?? '${group.name}の画像',
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (group.kind != null)
                      Text(
                        group.kind!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    if (saioshi.isNotEmpty)
                      Text(
                        '最推し: ${saioshi.join('、')}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              FavoriteButton(
                isFavorite: group.isFavorite,
                onPressed: favoriteBusy ? null : toggleFavorite,
                subjectLabel: group.name,
              ),
              _GroupMenu(item: item),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          // メンバー: 横スクロールのアバター列（§10）。最推しはリング強調。
          _MemberRow(item: item),
          const SizedBox(height: AppSpace.md),
          // 導出統計3件（§10/§12.1）。
          _StatsRow(groupId: group.id),
          // 次の現場（淡紫カード・残日数強調, §10）。
          _NextGenbaCard(groupId: group.id),
          // 誕生日・記念日（近い順, §10）。
          _AnniversarySection(item: item),
        ],
      ),
    );
  }
}

class _GroupMenu extends ConsumerWidget {
  const _GroupMenu({required this.item});

  final OshiGroupWithMembers item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'グループの操作',
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await showGroupEditor(context, ref, existing: item.group);
          case 'delete':
            final ok = await confirmDangerAction(
              context,
              title: 'グループを削除',
              message: '「${item.group.name}」とメンバーを削除します。既存の現場は削除されません。',
            );
            if (!ok) return;
            // 書き込みと画像掃除は application 層（R7）。失敗は必ず表示する。
            final failure = await ref
                .read(oshiActionsControllerProvider.notifier)
                .deleteGroup(item);
            if (context.mounted) handleActionResult(context, failure);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('グループを編集')),
        PopupMenuItem(value: 'delete', child: Text('グループを削除…')),
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.item});

  final OshiGroupWithMembers item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final member in item.members)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () => showMemberEditor(
                  context,
                  ref,
                  groupId: item.group.id,
                  existing: member,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OshiAvatar(
                      name: member.name,
                      imageFile: member.imageLocalPath == null
                          ? null
                          : ref.read(imageStoreProvider).tryResolveOwned(
                                member.ownerId,
                                member.imageLocalPath!,
                              ),
                      // リング色: メンバーカラー → グループカラー →
                      // ユーザー推しカラー → Primary（§2/§11）。
                      ringColor: AppTheme.tryParseHexColor(member.color) ??
                          AppTheme.tryParseHexColor(item.group.color) ??
                          resolveUserAccent(ref, scheme),
                      selected: member.rank == OshiRank.saioshi,
                      altText: member.imageAltText ??
                          '${member.name}（${member.rank.label}）',
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 64,
                      child: Text(
                        member.name,
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      member.rank.label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: tokens.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          // メンバー追加（48dp タップ領域, §3）。
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => showMemberEditor(context, ref, groupId: item.group.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.divider, width: 1.5),
                  ),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 2),
                Text('追加', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 現場数・思い出数・参戦数の3分割（§10）。「参戦数」は attended のみ。
class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(oshiStatsProvider(groupId));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTokens.of(context).divider),
          bottom: BorderSide(color: AppTokens.of(context).divider),
        ),
      ),
      // 統計の読み込み中・失敗を非表示（SizedBox.shrink）へ変換しない（§15）。
      child: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: LinearProgressIndicator(semanticsLabel: '統計を読み込み中'),
        ),
        error: (error, _) => Text(
          error is Failure ? error.message : '統計を読み込めませんでした',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.error),
        ),
        data: (stats) => Row(
          children: [
            Expanded(
              child: CountStat(value: stats.genbaCount, label: '現場数'),
            ),
            Expanded(
              child: CountStat(value: stats.memoryCount, label: '思い出数'),
            ),
            Expanded(
              child: CountStat(
                value: stats.attendedCount,
                label: '参戦数',
                semanticsLabel: '参戦数 ${stats.attendedCount}件（参加を明示した現場のみ）',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 次の現場（淡紫カード・残日数を強調, §10）。
class _NextGenbaCard extends ConsumerWidget {
  const _NextGenbaCard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final statsAsync = ref.watch(oshiStatsProvider(groupId));
    // 読み込み中は _StatsRow がインジケーターを出すためここでは重ねない。
    // 失敗は非表示にせず理由を示す（§15）。「次の現場が無い」（data で
    // nextGenba == null）だけを正当な空として非表示にする。
    if (statsAsync.hasError && !statsAsync.hasValue) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.md),
        child: Text(
          '次の現場を読み込めませんでした',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.error),
        ),
      );
    }
    final next = statsAsync.valueOrNull?.nextGenba;
    if (next == null) return const SizedBox.shrink();
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.read(clockProvider).now();
    final days = daysUntil(next, now);
    final daysText = days == 0 ? '本日' : 'あと$days日';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: AppCard(
        color: tokens.primarySoft,
        onTap: () => context.push('/genba/${next.id}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '次の現場',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${next.eventDate.year}/${next.eventDate.month}/${next.eventDate.day}'
                    '${next.venue != null ? '・${next.venue}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              daysText,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
              semanticsLabel: days == 0 ? '公演は本日です' : '公演まであと$days日',
            ),
          ],
        ),
      ),
    );
  }
}

/// 誕生日・記念日（近い順, §10）。エラーは隠さず表示する。
class _AnniversarySection extends ConsumerWidget {
  const _AnniversarySection({required this.item});

  final OshiGroupWithMembers item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final upcomingAsync =
        ref.watch(oshiUpcomingAnniversariesProvider(item.group.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '誕生日・記念日',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () => showAnniversaryEditor(
                  context,
                  ref,
                  group: item.group,
                  members: item.members,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('追加'),
              ),
            ],
          ),
        ),
        switch (upcomingAsync) {
          AsyncData(value: final list) when list.isEmpty => Text(
              'まだ記念日がありません。メンバーの誕生日や推し始めた日も、ここに表示されます。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: tokens.textSecondary),
            ),
          AsyncData(value: final list) => Column(
              children: [
                for (final a in list.take(5))
                  _AnniversaryTile(item: item, anniversary: a),
              ],
            ),
          AsyncError() => Text(
              '記念日を読み込めませんでした',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(AppSpace.sm),
              child: LinearProgressIndicator(semanticsLabel: '記念日を読み込み中'),
            ),
        },
      ],
    );
  }
}

class _AnniversaryTile extends ConsumerWidget {
  const _AnniversaryTile({required this.item, required this.anniversary});

  final OshiGroupWithMembers item;
  final UpcomingAnniversary anniversary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final a = anniversary;
    final icon = switch (a.kind) {
      AnniversaryKind.birthday => Icons.cake_outlined,
      AnniversaryKind.oshiSince => Icons.favorite_outline,
      AnniversaryKind.custom => Icons.celebration_outlined,
    };
    final daysText = a.daysUntil == 0 ? '本日' : 'あと${a.daysUntil}日';

    Future<void> editCustom() async {
      final sourceId = a.sourceId;
      if (sourceId == null) return;
      final source = ref
          .read(oshiAnniversariesProvider)
          .valueOrNull
          ?.where((x) => x.id == sourceId)
          .firstOrNull;
      if (source == null || !context.mounted) return;
      await showAnniversaryEditor(
        context,
        ref,
        group: item.group,
        members: item.members,
        existing: source,
      );
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(a.label),
      subtitle: Text(formatDateOnly(a.nextOccurrence)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            daysText,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            semanticsLabel: a.daysUntil == 0
                ? '${a.label}は本日です'
                : '${a.label}まであと${a.daysUntil}日',
          ),
          if (a.kind == AnniversaryKind.custom) ...[
            IconButton(
              tooltip: '記念日を削除',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () async {
                final sourceId = a.sourceId;
                if (sourceId == null) return;
                final ok = await confirmDangerAction(
                  context,
                  title: '記念日を削除',
                  message: '「${a.label}」を削除します。',
                );
                if (!ok) return;
                final failure = await ref
                    .read(oshiActionsControllerProvider.notifier)
                    .deleteAnniversary(sourceId);
                if (context.mounted) handleActionResult(context, failure);
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.sm),
              child: Text(
                'メンバー編集から変更',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textSecondary, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: a.kind == AnniversaryKind.custom ? editCustom : null,
    );
  }
}
