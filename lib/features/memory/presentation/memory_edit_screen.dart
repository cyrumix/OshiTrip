import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../application/memory_actions_controller.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';

/// 思い出の段階入力（§8.2）。
///
/// 終演直後 / 終演後 / 後日 の3段階を「標準の表示順」として並べる（§8.2）。
/// これは入力画面の段階名・説明であり、思い出へ移行する日時判定ではない。
/// 「終演後」に MC・当日メモ / 座席・見え方 / セトリ を置く。
/// どの段階も先行入力でき、すべて任意。テキストは自動保存される。
class MemoryEditScreen extends ConsumerStatefulWidget {
  const MemoryEditScreen({super.key, required this.genbaId});

  final String genbaId;

  @override
  ConsumerState<MemoryEditScreen> createState() => _MemoryEditScreenState();
}

class _MemoryEditScreenState extends ConsumerState<MemoryEditScreen> {
  TextEditingController? _impression;
  TextEditingController? _bestMoment;
  TextEditingController? _mcNotes;
  TextEditingController? _seatView;
  final _songInput = TextEditingController();
  final _goodsInput = TextEditingController();
  final _placeInput = TextEditingController();
  final _foodInput = TextEditingController();
  final _tagInput = TextEditingController();

  @override
  void dispose() {
    _impression?.dispose();
    _bestMoment?.dispose();
    _mcNotes?.dispose();
    _seatView?.dispose();
    _songInput.dispose();
    _goodsInput.dispose();
    _placeInput.dispose();
    _foodInput.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _ensureControllers(MemoryEntry? entry) {
    if (_impression != null) return;
    _impression = TextEditingController(text: entry?.impression ?? '');
    _bestMoment = TextEditingController(text: entry?.bestMoment ?? '');
    _mcNotes = TextEditingController(text: entry?.mcNotes ?? '');
    _seatView = TextEditingController(text: entry?.seatView ?? '');
  }

  MemoryEditController get _controller =>
      ref.read(memoryEditControllerProvider(widget.genbaId).notifier);

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final failure = await _controller.addPhoto(picked.path);
    _showFailure(failure);
  }

  Future<void> _deletePhoto(String id) async {
    final failure = await _controller.deletePhoto(id);
    _showFailure(failure);
  }

  /// グッズ・行った場所・食べものへ写真を紐づける（§8.4）。保存元は
  /// 思い出写真テーブルに一本化し、画面ごとに画像を複製しない。
  Future<void> _addSubjectPhoto({
    required MemoryAlbumCategory albumCategory,
    required MemorySubjectType subjectType,
    required String subjectId,
  }) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final failure = await _controller.addPhoto(
      picked.path,
      albumCategory: albumCategory,
      subjectType: subjectType,
      subjectId: subjectId,
    );
    _showFailure(failure);
  }

  /// 端末内の写真参照を解決する（存在しなければ null → プレースホルダ表示）。
  List<({String id, File? file})> _resolvePhotos(List<MemoryPhoto> photos) {
    final store = ref.read(imageStoreProvider);
    return [
      for (final p in photos)
        (
          id: p.id,
          file: p.localPath == null
              ? null
              : store.tryResolveOwned(p.ownerId, p.localPath!),
        ),
    ];
  }

  /// 関連項目（グッズ/場所/食べもの）の削除。写真があるときは「アルバムに残す
  /// （既定）／写真も削除」を選ばせる（§8.4）。写真も削除・残すのいずれも
  /// Repository の原子的操作で行い、途中失敗で一部だけ消えることを防ぐ（Issue1）。
  Future<void> _deleteSubjectItem({
    required String id,
    required String label,
    required MemorySubjectType subjectType,
  }) async {
    final bundle = await ref
        .read(memoryRepositoryProvider)
        .watchByGenbaId(widget.genbaId)
        .first;
    final photoCount = bundle.photosForSubject(id).length;
    if (photoCount == 0) {
      // 写真なし → 項目のみ削除（関連解除操作で項目を消す）。
      _showFailure(
        await _controller.deleteSubjectKeepingPhotos(subjectType, id),
      );
      return;
    }
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('「$label」を削除'),
        content: Text('この項目に紐づく写真が$photoCount枚あります。どうしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('写真も削除'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: const Text('アルバムに残す'),
          ),
        ],
      ),
    );
    if (choice == 'keep') {
      _showFailure(
        await _controller.deleteSubjectKeepingPhotos(subjectType, id),
      );
    } else if (choice == 'delete') {
      _showFailure(await _controller.deleteSubjectWithPhotos(subjectType, id));
    }
  }

  /// 表紙を設定する（同一現場で cover は常に最大1件, design-spec §12.1）。
  /// 書き込みは application 層（R7）。二重タップは controller 側で防ぐ。
  Future<void> _setCover(String photoId) async {
    final failure = await ref
        .read(memoryActionsControllerProvider(widget.genbaId).notifier)
        .setCoverPhoto(photoId);
    _showFailure(failure);
  }

  /// 失敗（null以外）だけを SnackBar で示す。成功していない操作を成功表示しない
  /// （H-07/M-01）。
  void _showFailure(Object? failure) {
    if (failure == null || !mounted) return;
    final message = failure is Failure ? failure.message : '操作に失敗しました';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // 自動保存を有効化するため controller を購読しておく。
    ref.watch(memoryEditControllerProvider(widget.genbaId));
    final bundleAsync = ref.watch(memoryBundleProvider(widget.genbaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('思い出を記録'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '自動保存',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
      body: AsyncValueView<MemoryBundle>(
        value: bundleAsync,
        data: (bundle) {
          _ensureControllers(bundle.entry);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _StageHeader(
                icon: Icons.nightlight_round,
                title: '終演直後',
                subtitle: '写真とひとことだけでもOK',
              ),
              OutlinedButton.icon(
                onPressed: _addPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('写真を追加'),
              ),
              if (bundle.photos.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bundle.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final photo = bundle.photos[index];
                      final file = photo.localPath == null
                          ? null
                          : ref
                              .read(imageStoreProvider)
                              .tryResolveOwned(photo.ownerId, photo.localPath!);
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: file != null
                                  ? Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : const Icon(Icons.image_outlined),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              tooltip: '写真を削除',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black45,
                                foregroundColor: Colors.white,
                              ),
                              iconSize: 16,
                              icon: const Icon(Icons.close),
                              onPressed: () => _deletePhoto(photo.id),
                            ),
                          ),
                          // 表紙の指定（isCover は常に最大1件, §12.1）。
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: photo.isCover
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      '表紙',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      semanticsLabel: '表紙に設定済み',
                                    ),
                                  )
                                : IconButton(
                                    tooltip: 'この写真を表紙にする',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black45,
                                      foregroundColor: Colors.white,
                                    ),
                                    iconSize: 16,
                                    icon: const Icon(Icons.star_outline),
                                    onPressed: () => _setCover(photo.id),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _impression,
                decoration: const InputDecoration(
                  labelText: '感想（短いひとことでOK・あとから加筆できます）',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                onChanged: (v) =>
                    _controller.updateEntry((e) => e.copyWith(impression: v)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bestMoment,
                decoration: const InputDecoration(labelText: '特によかった曲・瞬間'),
                onChanged: (v) =>
                    _controller.updateEntry((e) => e.copyWith(bestMoment: v)),
              ),
              const SizedBox(height: 24),
              const _StageHeader(
                icon: Icons.wb_sunny_outlined,
                title: '終演後',
                subtitle: '覚えているうちに残したいこと',
              ),
              TextField(
                controller: _mcNotes,
                decoration: const InputDecoration(
                  labelText: 'MC・当日メモ',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                onChanged: (v) =>
                    _controller.updateEntry((e) => e.copyWith(mcNotes: v)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _seatView,
                decoration: const InputDecoration(labelText: '座席・見え方'),
                onChanged: (v) =>
                    _controller.updateEntry((e) => e.copyWith(seatView: v)),
              ),
              const SizedBox(height: 12),
              _ListEditor(
                title: 'セトリ',
                icon: Icons.queue_music,
                inputController: _songInput,
                inputHint: '曲名を追加',
                items: [
                  for (final item in bundle.setlist)
                    (
                      id: item.id,
                      label: '${item.position}. ${item.songTitle}',
                    ),
                ],
                onAdd: (text) =>
                    _controller.addSetlistItem(text).then(_showFailure),
                onDelete: (id) =>
                    _controller.deleteSetlistItem(id).then(_showFailure),
              ),
              const SizedBox(height: 24),
              const _StageHeader(
                icon: Icons.calendar_month_outlined,
                title: '後日',
                subtitle: '落ち着いてからゆっくり',
              ),
              _TagEditor(
                tags: bundle.entry?.tags ?? const [],
                inputController: _tagInput,
                onChanged: (tags) =>
                    _controller.updateEntry((e) => e.copyWith(tags: tags)),
              ),
              const SizedBox(height: 12),
              _ItemsWithPhotosEditor(
                title: 'グッズ・戦利品',
                icon: Icons.shopping_bag_outlined,
                inputController: _goodsInput,
                inputHint: 'グッズ名を追加',
                emptyHint: 'グッズはまだありません。名前を入れて追加できます。',
                items: [
                  for (final item in bundle.goods)
                    (
                      id: item.id,
                      label: item.name,
                      photos: _resolvePhotos(bundle.photosForSubject(item.id)),
                    ),
                ],
                onAdd: (text) =>
                    _controller.addGoodsItem(text).then(_showFailure),
                onDeleteItem: (id, label) => _deleteSubjectItem(
                  id: id,
                  label: label,
                  subjectType: MemorySubjectType.goods,
                ),
                onAddPhoto: (id) => _addSubjectPhoto(
                  albumCategory: MemoryAlbumCategory.goods,
                  subjectType: MemorySubjectType.goods,
                  subjectId: id,
                ),
                onDeletePhoto: _deletePhoto,
              ),
              const SizedBox(height: 12),
              _ItemsWithPhotosEditor(
                title: '行った場所',
                icon: Icons.place_outlined,
                inputController: _placeInput,
                inputHint: '場所を追加',
                emptyHint: '行った場所はまだありません。',
                items: [
                  for (final place
                      in bundle.places.where((p) => p.category != 'food'))
                    (
                      id: place.id,
                      label: place.name,
                      photos: _resolvePhotos(bundle.photosForSubject(place.id)),
                    ),
                ],
                onAdd: (text) => _controller
                    .addVisitedPlace(text, 'spot')
                    .then(_showFailure),
                onDeleteItem: (id, label) => _deleteSubjectItem(
                  id: id,
                  label: label,
                  subjectType: MemorySubjectType.visitedPlace,
                ),
                onAddPhoto: (id) => _addSubjectPhoto(
                  albumCategory: MemoryAlbumCategory.visitedPlace,
                  subjectType: MemorySubjectType.visitedPlace,
                  subjectId: id,
                ),
                onDeletePhoto: _deletePhoto,
              ),
              const SizedBox(height: 12),
              _ItemsWithPhotosEditor(
                title: '食べたもの',
                icon: Icons.restaurant_outlined,
                inputController: _foodInput,
                inputHint: 'お店・食べたものを追加',
                emptyHint: '食べたものはまだありません。',
                items: [
                  for (final place
                      in bundle.places.where((p) => p.category == 'food'))
                    (
                      id: place.id,
                      label: place.name,
                      photos: _resolvePhotos(bundle.photosForSubject(place.id)),
                    ),
                ],
                onAdd: (text) => _controller
                    .addVisitedPlace(text, 'food')
                    .then(_showFailure),
                onDeleteItem: (id, label) => _deleteSubjectItem(
                  id: id,
                  label: label,
                  subjectType: MemorySubjectType.visitedPlace,
                ),
                onAddPhoto: (id) => _addSubjectPhoto(
                  albumCategory: MemoryAlbumCategory.food,
                  subjectType: MemorySubjectType.visitedPlace,
                  subjectId: id,
                ),
                onDeletePhoto: _deletePhoto,
              ),
              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 名前＋写真を持つ項目（グッズ・行った場所・食べもの）の編集（§8.4）。
/// 各項目に写真を紐づけ・削除でき、項目削除時は呼び出し側が
/// 「アルバムに残す／写真も削除」を確認する。
class _ItemsWithPhotosEditor extends StatelessWidget {
  const _ItemsWithPhotosEditor({
    required this.title,
    required this.icon,
    required this.inputController,
    required this.inputHint,
    required this.emptyHint,
    required this.items,
    required this.onAdd,
    required this.onDeleteItem,
    required this.onAddPhoto,
    required this.onDeletePhoto,
  });

  final String title;
  final IconData icon;
  final TextEditingController inputController;
  final String inputHint;
  final String emptyHint;
  final List<
          ({String id, String label, List<({String id, File? file})> photos})>
      items;
  final Future<Object?> Function(String text) onAdd;
  final void Function(String id, String label) onDeleteItem;
  final void Function(String id) onAddPhoto;
  final Future<void> Function(String photoId) onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              emptyHint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.label)),
                    IconButton(
                      tooltip: '${item.label}に写真を追加',
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                      ),
                      onPressed: () => onAddPhoto(item.id),
                    ),
                    IconButton(
                      tooltip: '${item.label}を削除',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => onDeleteItem(item.id, item.label),
                    ),
                  ],
                ),
                if (item.photos.isNotEmpty)
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, i) => _PhotoThumb(
                        file: item.photos[i].file,
                        size: 72,
                        onDelete: () => onDeletePhoto(item.photos[i].id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(hintText: inputHint, isDense: true),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              tooltip: '追加',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _submit,
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    inputController.clear();
    // 結果はストリーム経由で反映される。
    // ignore: unawaited_futures
    onAdd(text);
  }
}

/// 正方形の写真サムネイル（角丸・任意で削除ボタン）。§8.4/§9 の統一サムネイル。
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, required this.size, this.onDelete});

  final File? file;
  final double size;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: size,
            height: size,
            child: file != null
                ? Image.file(
                    file!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  )
                : const Icon(Icons.image_outlined),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: '写真を削除',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                foregroundColor: Colors.white,
              ),
              iconSize: 14,
              icon: const Icon(Icons.close),
              onPressed: onDelete,
            ),
          ),
      ],
    );
  }
}

class _ListEditor extends StatelessWidget {
  const _ListEditor({
    required this.title,
    required this.icon,
    required this.inputController,
    required this.inputHint,
    required this.items,
    required this.onAdd,
    required this.onDelete,
  });

  final String title;
  final IconData icon;
  final TextEditingController inputController;
  final String inputHint;
  final List<({String id, String label})> items;
  final Future<Object?> Function(String text) onAdd;
  final Future<Object?> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, size: 18),
            title: Text(item.label),
            trailing: IconButton(
              tooltip: '${item.label}を削除',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onDelete(item.id),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(
                  hintText: inputHint,
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              tooltip: '追加',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _submit,
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    inputController.clear();
    // 結果はストリーム経由で反映される。
    // ignore: unawaited_futures
    onAdd(text);
  }
}

class _TagEditor extends StatelessWidget {
  const _TagEditor({
    required this.tags,
    required this.inputController,
    required this.onChanged,
  });

  final List<String> tags;
  final TextEditingController inputController;
  final void Function(List<String> tags) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'タグ（写真整理・表情など）',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final tag in tags)
              InputChip(
                label: Text(tag),
                onDeleted: () => onChanged([...tags]..remove(tag)),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  hintText: 'タグを追加',
                  isDense: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              tooltip: 'タグを追加',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _submit,
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    inputController.clear();
    onChanged([...tags, text]);
  }
}
