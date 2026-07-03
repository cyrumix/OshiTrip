import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../../genba/domain/genba_schedule.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';

/// 思い出詳細（§8.4）。現場情報と記録内容を一体で閲覧できる。
class MemoryDetailScreen extends ConsumerWidget {
  const MemoryDetailScreen({super.key, required this.genbaId});

  final String genbaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregateAsync = ref.watch(genbaByIdProvider(genbaId));
    final bundleAsync = ref.watch(memoryBundleProvider(genbaId));

    return Scaffold(
      body: AsyncValueView<GenbaAggregate?>(
        value: aggregateAsync,
        isEmpty: (a) => a == null,
        emptyView: const EmptyView(message: '思い出が見つかりませんでした'),
        data: (aggregate) {
          final genba = aggregate!.genba;
          final bundle =
              bundleAsync.valueOrNull ?? MemoryBundle(genbaId: genbaId);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(genba.title, overflow: TextOverflow.ellipsis),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}'
                        '　${genba.artistName}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (genba.venue != null) Text('会場: ${genba.venue}'),
                      if (genba.startTimeMinutes != null)
                        Text('開演 ${formatMinutes(genba.startTimeMinutes!)}'),
                    ],
                  ),
                ),
              ),
              SliverList.list(
                children: [
                  if (bundle.photos.isNotEmpty)
                    _Section(
                      title: '写真',
                      child: SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: bundle.photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) =>
                              _PhotoThumb(photo: bundle.photos[index]),
                        ),
                      ),
                    ),
                  if (bundle.entry?.impression.isNotEmpty ?? false)
                    _TextSection(title: '感想', body: bundle.entry!.impression),
                  if (bundle.entry?.bestMoment.isNotEmpty ?? false)
                    _TextSection(
                      title: '特によかった曲・瞬間',
                      body: bundle.entry!.bestMoment,
                    ),
                  if (bundle.setlist.isNotEmpty)
                    _Section(
                      title: 'セトリ',
                      child: Column(
                        children: [
                          for (final item in bundle.setlist)
                            ListTile(
                              dense: true,
                              leading: Text('${item.position}'),
                              title: Text(item.songTitle),
                              subtitle:
                                  item.note == null ? null : Text(item.note!),
                            ),
                        ],
                      ),
                    ),
                  if (bundle.entry?.mcNotes.isNotEmpty ?? false)
                    _TextSection(
                      title: 'MC・当日メモ',
                      body: bundle.entry!.mcNotes,
                    ),
                  if (bundle.entry?.seatView.isNotEmpty ?? false)
                    _TextSection(
                      title: '座席・見え方',
                      body: bundle.entry!.seatView,
                    ),
                  if (bundle.goods.isNotEmpty)
                    _Section(
                      title: 'グッズ・戦利品',
                      child: Column(
                        children: [
                          for (final item in bundle.goods)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.shopping_bag_outlined),
                              title: Text(item.name),
                              subtitle: item.price == null
                                  ? null
                                  : Text('¥${item.price} × ${item.quantity}'),
                            ),
                        ],
                      ),
                    ),
                  if (bundle.places.isNotEmpty)
                    _Section(
                      title: '行った場所・食べたもの',
                      child: Column(
                        children: [
                          for (final place in bundle.places)
                            ListTile(
                              dense: true,
                              leading: Icon(
                                place.category == 'food'
                                    ? Icons.restaurant_outlined
                                    : Icons.place_outlined,
                              ),
                              title: Text(place.name),
                              subtitle:
                                  place.memo == null ? null : Text(place.memo!),
                            ),
                        ],
                      ),
                    ),
                  if ((bundle.entry?.tags ?? []).isNotEmpty)
                    _Section(
                      title: 'タグ',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in bundle.entry!.tags)
                              Chip(label: Text(tag)),
                          ],
                        ),
                      ),
                    ),
                  if (!bundle.hasAnyContent)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyView(
                        icon: Icons.auto_awesome,
                        message: 'まだ記録がありません',
                        description: '写真やひとことから、気軽に残しはじめられます。',
                      ),
                    ),
                  const SizedBox(height: 96),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'memory_fab',
        onPressed: () => context.push('/memories/$genbaId/edit'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('記録する'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        child,
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(body),
      ),
    );
  }
}

class _PhotoThumb extends ConsumerWidget {
  const _PhotoThumb({required this.photo});

  final MemoryPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = photo.localPath;
    final file = local == null
        ? null
        : ref.read(imageStoreProvider).tryResolveOwned(photo.ownerId, local);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 110,
        height: 110,
        child: file != null
            ? Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
              )
            : const _PhotoPlaceholder(),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_outlined),
    );
  }
}
