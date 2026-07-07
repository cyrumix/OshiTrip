import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/images/image_status_provider.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../../genba/domain/genba_preparation.dart';
import '../../genba/domain/genba_schedule.dart';
import '../../genba/presentation/widgets/genba_event_list_card.dart';
import '../../oshi/application/oshi_providers.dart';
import 'widgets/today_card.dart';

/// ホーム（design-spec §6）。
///
/// 最も近い未来の現場をヒーローカードで最上位に置き、続けて「今後の現場」。
/// 当日は当日重要情報カード（[TodayCard]）を最上位へ切り替える（§6.2）。
/// 通知は未実装のため、押せない通知入口は表示しない（§6.1）。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingGenbasProvider);
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();

    return AppScaffold(
      // ホームはロゴ・タイトルを掲げず、次の現場のヒーローから始める
      // （デザイン刷新: コンテンツが主役）。
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(genbaRepositoryProvider).refreshFromRemote();
          ref.read(syncEngineProvider).poke();
        },
        child: AsyncValueView<List<GenbaAggregate>>(
          value: upcoming,
          isEmpty: (list) => list.isEmpty,
          loadingView: const LoadingSkeleton.hero(),
          emptyView: EmptyView(
            icon: Icons.event_note,
            message: '予定している現場がありません',
            description: '最初の現場を登録すると、残り日数とやることが自動で整理されます。',
            actionLabel: '現場を登録する',
            onAction: () => context.push('/genba/new'),
          ),
          data: (list) {
            // 当日（本日/余韻中）の現場は開始時刻順に最上部へ（§6.2）。
            final todayItems = list.where((a) {
              final s = deriveGenbaStatus(a.genba, now);
              return s == GenbaStatus.today || s == GenbaStatus.afterglow;
            }).toList()
              ..sort(
                (a, b) => (a.genba.startTimeMinutes ?? 0)
                    .compareTo(b.genba.startTimeMinutes ?? 0),
              );
            final rest = list.where((a) => !todayItems.contains(a)).toList();
            // 当日が無いときだけ、最も近い現場をヒーローで見せる。
            final hero =
                todayItems.isEmpty && rest.isNotEmpty ? rest.first : null;
            final upcomingRest = hero == null ? rest : rest.skip(1).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              children: [
                for (final today in todayItems)
                  TodayCard(aggregate: today, now: now),
                if (hero != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.sm,
                      AppSpace.lg,
                      0,
                    ),
                    child: _NextGenbaHero(aggregate: hero, now: now),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.md,
                      AppSpace.lg,
                      0,
                    ),
                    child: _QuickStatusRow(aggregate: hero),
                  ),
                ],
                if (upcomingRest.isNotEmpty) ...[
                  const SectionHeader(title: '今後の現場'),
                  for (final aggregate in upcomingRest)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: 6,
                      ),
                      child: GenbaEventListCard(
                        aggregate: aggregate,
                        now: now,
                        minimal: true,
                      ),
                    ),
                ],
                // FAB が最終カードを覆わない余白（§5）。
                const SizedBox(height: 96),
              ],
            );
          },
        ),
      ),
      floatingActionButton: AppFab(
        heroTag: 'home_fab',
        onPressed: () => context.push('/genba/new'),
        tooltip: '現場を登録',
      ),
    );
  }
}

/// 次の現場ヒーロー（§6.2）。写真 or 紫グラデーション + 残日数 +
/// Todo/交通/宿泊/チケットの4分割状態ショートカット。
class _NextGenbaHero extends ConsumerWidget {
  const _NextGenbaHero({required this.aggregate, required this.now});

  final GenbaAggregate aggregate;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    // 設定済みヒーロー画像の状態（present/missing/inaccessible）を確認し、
    // 表示できない場合は fallback だけで隠さず理由を明示する（§12）。
    final localRef = genba.heroImageLocalPath;
    final status = localRef == null
        ? null
        : ref.watch(
            imageAssetStatusProvider((ownerId: genba.ownerId, ref: localRef)),
          );
    final file = status == ImageAssetStatus.present
        ? ref.read(imageStoreProvider).tryResolveOwned(genba.ownerId, localRef!)
        : null;
    final unavailableNote = switch (status) {
      ImageAssetStatus.missing => '設定した画像が端末にありません',
      ImageAssetStatus.inaccessible => '画像を読み込めません（権限・ロック）',
      _ => null,
    };
    final days = daysUntil(genba, now);
    // 推しカラーを「暁光」としてヒーローへ写す（本文には使わない）。
    final accent = resolveOshiAccent(
      ref,
      Theme.of(context).colorScheme,
      oshiGroupId: genba.oshiGroupId,
    );

    return HeroEventCard(
      title: genba.title,
      artistName: genba.artistName,
      accentColor: accent,
      dateLabel: formatEventDate(genba.eventDate),
      timeLabel: [
        if (genba.doorTimeMinutes != null)
          '開場 ${formatMinutes(genba.doorTimeMinutes!)}',
        if (genba.startTimeMinutes != null)
          '開演 ${formatMinutes(genba.startTimeMinutes!)}',
      ].join(' / ').isEmpty
          ? null
          : [
              if (genba.doorTimeMinutes != null)
                '開場 ${formatMinutes(genba.doorTimeMinutes!)}',
              if (genba.startTimeMinutes != null)
                '開演 ${formatMinutes(genba.startTimeMinutes!)}',
            ].join(' / '),
      venue: genba.venue,
      daysUntil: days < 0 ? 0 : days,
      imageFile: file,
      imageAltText: genba.heroImageAltText,
      imageUnavailableNote: unavailableNote,
      onTap: () => context.push('/genba/${genba.id}'),
    );
  }
}

/// ヒーロー直下の準備状況タイル（モックアップ準拠の白タイル5分割）。
/// タップで現場詳細へ移動する。状態は色だけでなく文言でも示す（§14）。
class _QuickStatusRow extends StatelessWidget {
  const _QuickStatusRow({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final prep = GenbaPreparation.of(aggregate);
    final genbaId = aggregate.genba.id;
    void open() => context.push('/genba/$genbaId');
    return PrepStatusRow(
      tiles: [
        PrepStatusTile(
          icon: Icons.check_box_outlined,
          label: 'Todo',
          value: aggregate.incompleteTodoCount == 0
              ? '完了'
              : '残り${aggregate.incompleteTodoCount}',
          attention: aggregate.incompleteTodoCount > 0,
          onTap: open,
        ),
        // 持ち物はTodoとは別集計（対応状況）で表示する（§持ち物の準備ステータス）。
        PrepStatusTile(
          icon: Icons.backpack_outlined,
          label: '持ち物',
          value: prep.belonging.label,
          attention: prep.belonging.needsAttention,
          onTap: open,
        ),
        PrepStatusTile(
          icon: Icons.train_outlined,
          label: '交通',
          value: prep.transport.label,
          attention: prep.transport.needsAttention,
          onTap: open,
        ),
        PrepStatusTile(
          icon: Icons.hotel_outlined,
          label: '宿泊',
          value: prep.lodging.label,
          attention: prep.lodging == CategoryPrepState.notRegistered,
          onTap: open,
        ),
        PrepStatusTile(
          icon: Icons.confirmation_number_outlined,
          label: 'チケット',
          value: prep.ticket.label,
          attention: prep.ticket.needsAttention,
          onTap: open,
        ),
      ],
    );
  }
}
