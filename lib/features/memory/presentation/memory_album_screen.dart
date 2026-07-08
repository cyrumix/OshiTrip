import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';

/// 端末ギャラリーから画像を選び、そのパスを返す（キャンセルは null）。
Future<String?> _pickGalleryImagePath() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  return picked?.path;
}

/// 思い出アルバム（§8.4）。写真の保存元は [MemoryPhoto] に一本化し、
/// 分類（すべて/当日の写真/グッズ/行った場所/食べたもの）で絞り込む。
/// 各写真から関連元（グッズ・場所）へ辿れる。
class MemoryAlbumScreen extends ConsumerStatefulWidget {
  const MemoryAlbumScreen({
    super.key,
    required this.genbaId,
    this.pickImagePath = _pickGalleryImagePath,
  });

  final String genbaId;

  /// 画像選択の注入点（テスト用）。既定は端末ギャラリー。
  final Future<String?> Function() pickImagePath;

  @override
  ConsumerState<MemoryAlbumScreen> createState() => _MemoryAlbumScreenState();
}

class _MemoryAlbumScreenState extends ConsumerState<MemoryAlbumScreen> {
  /// null は「すべて」。
  MemoryAlbumCategory? _selected;

  /// 写真追加の多重起動を防ぐ（二重タップ対策, Issue2）。
  bool _adding = false;

  /// アルバムから当日の写真を直接追加する（albumCategory=event, subject なし）。
  /// キャンセル時は何も保存しない。取り込み・DB保存失敗の後始末は controller が
  /// 担う（コピー済みファイルの掃除・成功していない処理を成功表示しない）。
  Future<void> _addEventPhoto() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final path = await widget.pickImagePath();
      if (path == null) return; // キャンセル → 何も保存しない
      final controller =
          ref.read(memoryEditControllerProvider(widget.genbaId).notifier);
      // 既定で albumCategory=event / subjectType=null / subjectId=null。
      final Failure? failure = await controller.addPhoto(path);
      if (failure != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 追加操作で使う controller を生存させる（autoDispose の途中破棄を防ぐ）。
    ref.watch(memoryEditControllerProvider(widget.genbaId));
    final bundleAsync = ref.watch(memoryBundleProvider(widget.genbaId));
    return Scaffold(
      appBar: AppBar(title: const Text('思い出アルバム')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'album_add_photo_fab',
        // 取り込み中は onPressed を無効化して多重起動を防ぐ（二重タップ対策）。
        onPressed: _adding ? null : _addEventPhoto,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('写真を追加'),
        tooltip: '当日の写真を追加',
      ),
      body: AsyncValueView<MemoryBundle>(
        value: bundleAsync,
        data: (bundle) {
          final photos = bundle.photosInAlbum(_selected);
          return Column(
            children: [
              _CategoryChips(
                selected: _selected,
                counts: {
                  null: bundle.photos.length,
                  for (final c in MemoryAlbumCategory.values)
                    c: bundle.photosInAlbum(c).length,
                },
                onSelect: (c) => setState(() => _selected = c),
              ),
              Expanded(
                child: photos.isEmpty
                    ? _EmptyState(category: _selected)
                    : _PhotoGrid(
                        bundle: bundle,
                        photos: photos,
                        genbaId: widget.genbaId,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final MemoryAlbumCategory? selected;
  final Map<MemoryAlbumCategory?, int> counts;
  final void Function(MemoryAlbumCategory? category) onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = <(MemoryAlbumCategory?, String)>[
      (null, 'すべて'),
      for (final c in MemoryAlbumCategory.values) (c, c.label),
    ];
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final (category, label) in entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$label（${counts[category] ?? 0}）'),
                selected: selected == category,
                onSelected: (_) => onSelect(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid({
    required this.bundle,
    required this.photos,
    required this.genbaId,
  });

  final MemoryBundle bundle;
  final List<MemoryPhoto> photos;
  final String genbaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(imageStoreProvider);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final photo = photos[i];
        final file = photo.localPath == null
            ? null
            : store.tryResolveOwned(photo.ownerId, photo.localPath!);
        return GestureDetector(
          onTap: () => _showPhotoSheet(context, bundle, photo, file, genbaId),
          child: _AlbumTile(file: file, isCover: photo.isCover),
        );
      },
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.file, required this.isCover});

  final File? file;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          file != null
              ? Image.file(
                  file!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image),
                  ),
                )
              : const ColoredBox(
                  color: Colors.black12,
                  child: Icon(Icons.image_outlined),
                ),
          if (isCover)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '表紙',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  semanticsLabel: '表紙',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 写真の拡大＋関連元（グッズ・場所）への導線を出すボトムシート。
void _showPhotoSheet(
  BuildContext context,
  MemoryBundle bundle,
  MemoryPhoto photo,
  File? file,
  String genbaId,
) {
  final subjectName = _subjectNameOf(bundle, photo);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: file != null
                    ? Image.file(file, fit: BoxFit.contain)
                    : const SizedBox(
                        height: 160,
                        child: Center(child: Icon(Icons.image_outlined)),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text(photo.albumCategory.label)),
                const SizedBox(width: 8),
                if (subjectName != null)
                  Expanded(
                    child: Text(
                      subjectName,
                      style: Theme.of(ctx).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (photo.subjectId != null) ...[
              const SizedBox(height: 8),
              // 関連元は同じ思い出の編集画面（グッズ・場所の入力欄）で確認できる。
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ctx.push('/memories/$genbaId/edit');
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('関連元を見る'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// 写真の関連項目名（グッズ名・場所名）。見つからなければ null。
String? _subjectNameOf(MemoryBundle bundle, MemoryPhoto photo) {
  final id = photo.subjectId;
  if (id == null) return null;
  switch (photo.subjectType) {
    case MemorySubjectType.goods:
      for (final g in bundle.goods) {
        if (g.id == id) return g.name;
      }
      return null;
    case MemorySubjectType.visitedPlace:
      for (final pl in bundle.places) {
        if (pl.id == id) return pl.name;
      }
      return null;
    case null:
      return null;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.category});

  final MemoryAlbumCategory? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = category?.label ?? 'アルバム';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              category == null
                  ? '写真はまだありません。思い出の記録から追加できます。'
                  : '「$label」の写真はまだありません。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
