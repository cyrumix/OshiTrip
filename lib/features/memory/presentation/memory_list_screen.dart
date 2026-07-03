import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';

/// 思い出一覧（§8）。終了した現場が同一IDのまま表示区分だけ変わる。
class MemoryListScreen extends ConsumerWidget {
  const MemoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoryGenbasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('思い出')),
      body: AsyncValueView<List<GenbaAggregate>>(
        value: memories,
        isEmpty: (list) => list.isEmpty,
        emptyView: const EmptyView(
          icon: Icons.photo_album_outlined,
          message: 'まだ思い出がありません',
          description: '現場が終わると、ここに思い出として表示されます。',
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final aggregate in list) _MemoryCard(aggregate: aggregate),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final genba = aggregate.genba;
    final bundle = ref.watch(memoryBundleProvider(genba.id)).valueOrNull;
    final cover = _coverPhoto(bundle);
    final impression = bundle?.entry?.impression ?? '';
    final coverFile = cover?.localPath == null
        ? null
        : ref
            .read(imageStoreProvider)
            .tryResolveOwned(cover!.ownerId, cover.localPath!);

    return Card(
      child: InkWell(
        onTap: () => context.push('/memories/${genba.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverFile != null)
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.file(
                  coverFile,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}'
                    '${genba.isCanceled ? '（中止）' : ''}',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(genba.title, style: theme.textTheme.titleMedium),
                  Text(genba.artistName, style: theme.textTheme.bodyMedium),
                  if (impression.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      impression,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((bundle?.photos ?? []).isNotEmpty) ...[
                        const Icon(Icons.photo_outlined, size: 16),
                        Text(' ${bundle!.photos.length}'),
                        const SizedBox(width: 12),
                      ],
                      if ((bundle?.setlist ?? []).isNotEmpty) ...[
                        const Icon(Icons.queue_music, size: 16),
                        Text(' ${bundle!.setlist.length}曲'),
                      ],
                      const Spacer(),
                      if (bundle != null && !bundle.hasAnyContent)
                        TextButton(
                          onPressed: () =>
                              context.push('/memories/${genba.id}/edit'),
                          child: const Text('記録を残す'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  MemoryPhoto? _coverPhoto(MemoryBundle? bundle) {
    if (bundle == null || bundle.photos.isEmpty) return null;
    for (final photo in bundle.photos) {
      if (photo.isCover) return photo;
    }
    return bundle.photos.first;
  }
}
