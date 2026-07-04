import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/failure.dart';
import '../../../core/images/image_status_provider.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../../genba/presentation/widgets/action_feedback.dart';
import '../../oshi/application/oshi_providers.dart';
import '../application/memory_actions_controller.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';

/// 思い出一覧の絞り込み（design-spec §8）。
///
/// 「参戦済み」は [AttendanceStatus.attended] を明示した現場のみ。
/// 公演DBの登録などと混同しない（§8/§12.1）。
enum MemoryFilter { all, attended, favorite }

extension MemoryFilterLabel on MemoryFilter {
  String get label => switch (this) {
        MemoryFilter.all => 'すべて',
        MemoryFilter.attended => '参戦済み',
        MemoryFilter.favorite => 'お気に入り',
      };
}

/// タブ切替後も絞り込み状態を保持する（§5）。
final memoryFilterProvider =
    StateProvider<MemoryFilter>((ref) => MemoryFilter.all);

/// 思い出一覧（design-spec §8）。終了した現場が同一IDのまま表示区分だけ変わる。
///
/// 追加入口は各思い出（現場）に紐づく記録編集のみ。現場と無関係な
/// 孤立レコードは作らない（§8）。
class MemoryListScreen extends ConsumerWidget {
  const MemoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoryGenbasProvider);
    final filter = ref.watch(memoryFilterProvider);

    return AppScaffold(
      title: '思い出',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentTabs(
                tabs: [for (final f in MemoryFilter.values) f.label],
                selectedIndex: filter.index,
                onSelected: (i) => ref
                    .read(memoryFilterProvider.notifier)
                    .state = MemoryFilter.values[i],
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView<List<GenbaAggregate>>(
              value: memories,
              isEmpty: (list) => list.isEmpty,
              loadingView: const LoadingSkeleton.list(),
              emptyView: const EmptyView(
                icon: Icons.photo_album_outlined,
                message: 'まだ思い出がありません',
                description: '現場が終わると、ここに思い出として表示されます。',
              ),
              data: (list) => _FilteredMemoryList(list: list, filter: filter),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredMemoryList extends ConsumerWidget {
  const _FilteredMemoryList({required this.list, required this.filter});

  final List<GenbaAggregate> list;
  final MemoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // お気に入りフィルタは各現場の記録（bundle）に依存する。読み込み中・
    // 失敗を「0件」として扱わない（loading/error を正しく伝播する, §15）。
    if (filter == MemoryFilter.favorite) {
      final bundleStates = [
        for (final a in list) ref.watch(memoryBundleProvider(a.genba.id)),
      ];
      if (bundleStates.any((s) => s.isLoading && !s.hasValue)) {
        return const LoadingSkeleton.list();
      }
      final firstError =
          bundleStates.where((s) => s.hasError && !s.hasValue).firstOrNull;
      if (firstError != null) {
        return ErrorView(
          error: firstError.error!,
          onRetry: () {
            for (final a in list) {
              ref.invalidate(memoryBundleProvider(a.genba.id));
            }
          },
        );
      }
    }
    final filtered = switch (filter) {
      MemoryFilter.all => list,
      // 「参戦済み」= 明示的に attended とした現場のみ（§12.1）。
      MemoryFilter.attended => list
          .where(
            (a) => a.genba.attendanceStatus == AttendanceStatus.attended,
          )
          .toList(),
      // お気に入り = 思い出単位の isFavorite（§8）。ここに到達した時点で
      // 全 bundle が data であることは上で確認済み。
      MemoryFilter.favorite => list.where((a) {
          final bundle =
              ref.watch(memoryBundleProvider(a.genba.id)).valueOrNull;
          return bundle?.entry?.isFavorite ?? false;
        }).toList(),
    };

    if (filtered.isEmpty) {
      return switch (filter) {
        MemoryFilter.all => const EmptyView(
            icon: Icons.photo_album_outlined,
            message: 'まだ思い出がありません',
            description: '現場が終わると、ここに思い出として表示されます。',
          ),
        MemoryFilter.attended => const EmptyView(
            icon: Icons.emoji_events_outlined,
            message: '参戦済みの思い出がありません',
            description: '現場詳細の「参加状態」で参戦済みにすると、ここに表示されます。',
          ),
        MemoryFilter.favorite => const EmptyView(
            icon: Icons.favorite_outline,
            message: 'お気に入りの思い出がありません',
            description: '思い出カードのハートを押すと、ここに集まります。',
          ),
      };
    }

    return ListView(
      key: const PageStorageKey('memory_list'),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      children: [
        for (final aggregate in filtered)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: 6,
            ),
            child: _MemoryCard(aggregate: aggregate),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genba = aggregate.genba;
    final scheme = Theme.of(context).colorScheme;
    final bundleAsync = ref.watch(memoryBundleProvider(genba.id));
    final accent =
        resolveOshiAccent(ref, scheme, oshiGroupId: genba.oshiGroupId);

    // 記録の読み込み中・失敗を「写真0枚・記録なし」と誤認させない（§15）。
    // 再読込中に前回値がある場合はそのまま表示を維持する。
    if (bundleAsync.isLoading && !bundleAsync.hasValue) {
      return const AppCard(
        child: SizedBox(
          height: 96,
          child: Center(
            child: CircularProgressIndicator(semanticsLabel: '記録を読み込み中'),
          ),
        ),
      );
    }
    if (bundleAsync.hasError && !bundleAsync.hasValue) {
      final error = bundleAsync.error;
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(genba.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.sm),
            Text(
              error is Failure ? error.message : '記録を読み込めませんでした',
              style: TextStyle(color: scheme.error),
            ),
            TextButton(
              onPressed: () => ref.invalidate(memoryBundleProvider(genba.id)),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }
    final bundle = bundleAsync.valueOrNull;
    final cover = _coverPhoto(bundle);
    // 表紙の実体状態を確認し、「写真なし」と「表示できない」を区別する（§12）。
    final coverRef = cover?.localPath;
    final coverStatus = coverRef == null
        ? null
        : ref.watch(
            imageAssetStatusProvider(
              (ownerId: cover!.ownerId, ref: coverRef),
            ),
          );
    final coverFile = coverStatus == ImageAssetStatus.present
        ? ref
            .read(imageStoreProvider)
            .tryResolveOwned(cover!.ownerId, coverRef!)
        : null;
    final coverUnavailableNote = switch (coverStatus) {
      ImageAssetStatus.missing => '表紙の写真が端末にありません',
      ImageAssetStatus.inaccessible => '表紙を読み込めません（権限・ロック）',
      _ => cover != null && coverRef == null && cover.storagePath != null
          ? 'この端末に写真の実体がありません'
          : null,
    };
    final isFavorite = bundle?.entry?.isFavorite ?? false;
    final favoriteBusy = ref
        .watch(memoryActionsControllerProvider(genba.id))
        .contains(MemoryActionsController.favoriteKey);

    Future<void> toggleFavorite() async {
      final failure = await ref
          .read(memoryActionsControllerProvider(genba.id).notifier)
          .setFavorite(isFavorite: !isFavorite);
      if (context.mounted) handleActionResult(context, failure);
    }

    return PhotoMemoryCard(
      title: genba.title,
      subtitle: genba.artistName,
      dateLabel:
          '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}'
          '${genba.isCanceled ? '（中止）' : ''}',
      venue: genba.venue,
      coverFile: coverFile,
      coverAltText: cover?.caption,
      coverUnavailableNote: coverUnavailableNote,
      photoCount: bundle?.photos.length ?? 0,
      setlistCount: bundle?.setlist.length ?? 0,
      hasImpression: bundle?.entry?.impression.isNotEmpty ?? false,
      attendedLabel: genba.attendanceStatus == AttendanceStatus.attended
          ? AttendanceStatus.attended.label
          : null,
      isFavorite: isFavorite,
      onFavoriteToggle: favoriteBusy ? null : toggleFavorite,
      accentColor: accent,
      emptyHint: bundle != null && !bundle.hasAnyContent
          ? TextButton(
              onPressed: () => context.push('/memories/${genba.id}/edit'),
              child: const Text('記録を残す'),
            )
          : null,
      onTap: () => context.push('/memories/${genba.id}'),
    );
  }

  /// 表紙: isCover 優先、未指定時は安全な規則で最初の写真（§12.1）。
  MemoryPhoto? _coverPhoto(MemoryBundle? bundle) {
    if (bundle == null || bundle.photos.isEmpty) return null;
    for (final photo in bundle.photos) {
      if (photo.isCover) return photo;
    }
    return bundle.photos.first;
  }
}
