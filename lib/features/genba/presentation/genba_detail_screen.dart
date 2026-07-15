import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/images/image_status_provider.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../itinerary/presentation/plan_tab.dart';
import '../application/genba_actions_controller.dart';
import '../application/genba_providers.dart';
import '../domain/genba.dart';
import '../domain/genba_schedule.dart';
import 'widgets/action_feedback.dart';
import 'widgets/genba_child_sections.dart';
import 'widgets/genba_overview_tab.dart';

/// 現場詳細（design-spec §7）。
///
/// 上部に公演写真または紫系フォールバックのヒーロー、その下に
/// 「概要 / Todo / チケット / 交通 / 宿泊 / メモ」の横スクロールタブ。
/// 既存のCRUDとResult状態を各タブへ接続し、巨大フォームにしない。
class GenbaDetailScreen extends ConsumerWidget {
  const GenbaDetailScreen({super.key, required this.genbaId});

  final String genbaId;

  static const _tabs = ['概要', 'Todo・持ち物', 'チケット', '交通', '宿泊', '計画', 'メモ'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregateAsync = ref.watch(genbaByIdProvider(genbaId));
    final now =
        ref.watch(nowProvider).valueOrNull ?? ref.watch(clockProvider).now();

    return Scaffold(
      body: AsyncValueView<GenbaAggregate?>(
        value: aggregateAsync,
        isEmpty: (a) => a == null,
        loadingView: const LoadingSkeleton.hero(cardCount: 3),
        emptyView: const EmptyView(message: '現場が見つかりませんでした'),
        data: (aggregate) {
          final a = aggregate!;
          final genba = a.genba;
          final topInset = MediaQuery.paddingOf(context).top;
          return DefaultTabController(
            length: _tabs.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  // ヒーロー＋準備サマリ帯（item 1）を収める高さ。
                  expandedHeight: 384,
                  // グローバルテーマは AppBarTheme.backgroundColor を
                  // transparent にしている（AppScaffold の背景グラデーションを
                  // 透過させるため）。だがこの画面は pinned な SliverAppBar が
                  // スクロール中の本文を隠す必要があるため、ここだけ画面背景色で
                  // 不透明にする（透明のままだと本文がタブ行に透けて重なる）。
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  // 画面名は固定し、公演名はヒーローカード側が担う
                  // （モックアップ準拠。二重表示にしない）。
                  title: const Text('現場詳細'),
                  actions: [
                    IconButton(
                      tooltip: 'メンバー・共有',
                      icon: const Icon(Icons.group_outlined),
                      onPressed: () => context.push('/genba/$genbaId/members'),
                    ),
                    IconButton(
                      tooltip: '現場を編集',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/genba/$genbaId/edit'),
                    ),
                    _MoreMenu(
                      aggregate: a,
                      status: deriveGenbaStatus(genba, now),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    // ヒーローは端まで貼らず、余白を持つ浮かぶカードにする。
                    // 折りたたみ中の高さ不足はクリップで吸収する
                    // （Column のオーバーフローを出さない）。
                    background: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpace.lg,
                            topInset + kToolbarHeight + AppSpace.xs,
                            AppSpace.lg,
                            AppSpace.md,
                          ),
                          // ヒーローカードの下・タブの上に準備サマリを置く
                          // （item 1）。
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _GenbaHeroHeader(genba: genba, now: now),
                              const SizedBox(height: AppSpace.sm),
                              GenbaPrepSummaryBar(aggregate: a),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Padding(
                      // ヒーロー・カード類と同じ左右余白に揃える（§3のリズム統一）。
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        0,
                        AppSpace.lg,
                        AppSpace.sm,
                      ),
                      // 6タブは端末幅によって収まらないことがあるため
                      // isScrollable は維持しつつ、収まる幅では中央寄せにして
                      // 左詰め・右側の余白だけが目立つ見た目を避ける
                      // （収まらない幅では自動的に横スクロールへ切り替わる）。
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        tabs: [
                          for (final t in _tabs)
                            Tab(
                              height: 40,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(t),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  GenbaOverviewTab(aggregate: a, now: now),
                  TodoTab(aggregate: a),
                  TicketTab(aggregate: a),
                  TransportTab(aggregate: a),
                  LodgingTab(aggregate: a),
                  PlanTab(genbaAggregate: a),
                  MemoTab(aggregate: a),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ヒーロー領域（§7.1）。公演写真または紫系フォールバック背景に、
/// 公演名・日付・開場/開演・会場・残日数をグラデーションオーバーレイ上へ重ねる。
class _GenbaHeroHeader extends ConsumerWidget {
  const _GenbaHeroHeader({required this.genba, required this.now});

  final Genba genba;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 設定済みヒーロー画像の状態を確認し、表示できない場合は fallback だけで
    // 隠さず理由を明示する（§12）。再選択は概要タブのヒーロー画像管理から。
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
      ImageAssetStatus.missing => '設定した画像が端末にありません（概要タブから選び直せます）',
      ImageAssetStatus.inaccessible => '画像を読み込めません（権限・ロック）',
      _ => null,
    };
    final days = daysUntil(genba, now);

    return HeroEventCard(
      title: genba.title,
      artistName: genba.artistName,
      dateLabel:
          '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}',
      timeLabel: [
        if (genba.doorTimeMinutes != null)
          '開場 ${formatMinutes(genba.doorTimeMinutes!)}',
        if (genba.startTimeMinutes != null)
          '開演 ${formatMinutes(genba.startTimeMinutes!)}',
      ].isEmpty
          ? null
          : [
              if (genba.doorTimeMinutes != null)
                '開場 ${formatMinutes(genba.doorTimeMinutes!)}',
              if (genba.startTimeMinutes != null)
                '開演 ${formatMinutes(genba.startTimeMinutes!)}',
            ].join(' / '),
      venue: genba.venue,
      daysUntil: days,
      // 残日数はバッジが担うためリードは出さない（モックアップ準拠）。
      leadLabel: '',
      imageFile: file,
      imageAltText: genba.heroImageAltText,
      imageUnavailableNote: unavailableNote,
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.aggregate, required this.status});

  final GenbaAggregate aggregate;
  final GenbaStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    // このメニューは現場全体に対する操作（中止/削除）なので、他の子データ
    // 操作が進行中でも独立して押せてよいが、cancel/uncancel/delete同士の
    // 二重タップは防ぐ（それぞれ専用キーで個別にガードされる）。ここでは
    // メニュー自体を「何かが進行中なら開かない」簡易ガードとして扱う。
    final busy = ref.watch(genbaActionsControllerProvider(genba.id)).isNotEmpty;
    GenbaActionsController controller() =>
        ref.read(genbaActionsControllerProvider(genba.id).notifier);

    Future<void> cancel() async {
      final confirmed = await confirmDangerAction(
        context,
        title: '現場を中止にする',
        message: '「${genba.title}」を中止にします。現場一覧には「中止」として残り、'
            '公演日を過ぎると思い出に記録として残ります。あとで取り消せます。',
        confirmLabel: '中止にする',
      );
      if (!confirmed || !context.mounted) return;
      final failure = await controller().cancel(genba);
      if (context.mounted) handleActionResult(context, failure);
    }

    Future<void> uncancel() async {
      final failure = await controller().uncancel(genba);
      if (context.mounted) handleActionResult(context, failure);
    }

    Future<void> delete() async {
      final confirmed = await confirmDangerAction(
        context,
        title: '現場を削除',
        message:
            '「${genba.title}」とチケット・交通・宿泊・Todo・メモ・思い出の記録をすべて削除します。この操作は取り消せません。',
      );
      if (!confirmed || !context.mounted) return;
      // 削除前に紐づく画像参照を収集する（削除後は取得できないため）。
      final imageRefs = <String>[
        if (genba.heroImageLocalPath != null) genba.heroImageLocalPath!,
        for (final t in aggregate.tickets)
          if (t.imageLocalPath != null) t.imageLocalPath!,
      ];
      final failure = await controller().deleteGenba(
        genba: genba,
        imageRefs: imageRefs,
        collectMemoryPhotoRefs: () async {
          final bundle = await ref
              .read(memoryRepositoryProvider)
              .watchByGenbaId(genba.id)
              .first;
          return [
            for (final ph in bundle.photos)
              if (ph.localPath != null) ph.localPath!,
          ];
        },
      );
      if (!context.mounted) return;
      if (failure == null) {
        context.go('/genba');
      } else {
        handleActionResult(context, failure);
      }
    }

    return PopupMenuButton<String>(
      tooltip: 'その他の操作',
      enabled: !busy,
      onSelected: (value) {
        switch (value) {
          case 'cancel':
            cancel();
          case 'uncancel':
            uncancel();
          case 'delete':
            delete();
        }
      },
      itemBuilder: (context) => [
        if (!genba.isCanceled)
          const PopupMenuItem(value: 'cancel', child: Text('中止にする'))
        else
          const PopupMenuItem(value: 'uncancel', child: Text('中止を取り消す')),
        const PopupMenuItem(value: 'delete', child: Text('現場を削除…')),
      ],
    );
  }
}
