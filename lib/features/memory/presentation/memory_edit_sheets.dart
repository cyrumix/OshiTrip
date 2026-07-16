import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../application/memory_actions_controller.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';
import 'memory_edit_widgets.dart';

/// 記録するセクション（design-spec §9・記録UX分解 D-252/M3）。
///
/// 巨大な1枚フォームをやめ、詳細（その日のページ）の各セクションから、
/// そのセクションだけをボトムシートで編集できるようにする。写真の込み入った
/// 物品編集（グッズ/場所/食べもの）はフル記録画面へ委譲する。
enum MemorySection { impression, setlist, dayRecord, tags, photos }

extension MemorySectionLabel on MemorySection {
  String get title => switch (this) {
        MemorySection.impression => '感想',
        MemorySection.setlist => 'セトリ',
        MemorySection.dayRecord => '座席・メモ',
        MemorySection.tags => 'タグ',
        MemorySection.photos => '写真',
      };

  IconData get icon => switch (this) {
        MemorySection.impression => Icons.edit_note_outlined,
        MemorySection.setlist => Icons.queue_music,
        MemorySection.dayRecord => Icons.event_seat_outlined,
        MemorySection.tags => Icons.sell_outlined,
        MemorySection.photos => Icons.photo_library_outlined,
      };
}

/// セクション別の記録シートを開く。
Future<void> showMemorySectionSheet(
  BuildContext context, {
  required String genbaId,
  required MemorySection section,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SectionSheet(genbaId: genbaId, section: section),
  );
}

/// 「記録する」の入口メニュー（FAB）。どのセクションを記録するか選ばせ、
/// 込み入った物品編集はフル記録画面へ誘導する。
Future<void> showMemoryRecordMenu(
  BuildContext context, {
  required String genbaId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final section in MemorySection.values)
            ListTile(
              leading: Icon(section.icon),
              title: Text('${section.title}を記録'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                // 親 context が破棄されていない場合のみ次のシートを開く。
                if (context.mounted) {
                  showMemorySectionSheet(
                    context,
                    genbaId: genbaId,
                    section: section,
                  );
                }
              },
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('グッズ・行った場所・食べたものを記録'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              if (context.mounted) context.push('/memories/$genbaId/edit');
            },
          ),
        ],
      ),
    ),
  );
}

class _SectionSheet extends ConsumerStatefulWidget {
  const _SectionSheet({required this.genbaId, required this.section});

  final String genbaId;
  final MemorySection section;

  @override
  ConsumerState<_SectionSheet> createState() => _SectionSheetState();
}

class _SectionSheetState extends ConsumerState<_SectionSheet> {
  TextEditingController? _impression;
  TextEditingController? _bestMoment;
  TextEditingController? _seatView;
  TextEditingController? _mcNotes;
  final _songInput = TextEditingController();
  final _tagInput = TextEditingController();

  @override
  void dispose() {
    _impression?.dispose();
    _bestMoment?.dispose();
    _seatView?.dispose();
    _mcNotes?.dispose();
    _songInput.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  MemoryEditController get _controller =>
      ref.read(memoryEditControllerProvider(widget.genbaId).notifier);

  void _ensureControllers(MemoryEntry? entry) {
    if (_impression != null) return;
    _impression = TextEditingController(text: entry?.impression ?? '');
    _bestMoment = TextEditingController(text: entry?.bestMoment ?? '');
    _seatView = TextEditingController(text: entry?.seatView ?? '');
    _mcNotes = TextEditingController(text: entry?.mcNotes ?? '');
  }

  void _showFailure(Object? failure) {
    if (failure == null || !mounted) return;
    final message = failure is Failure ? failure.message : '操作に失敗しました';
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // 自動保存を有効化するため controller を購読しておく。
    ref.watch(memoryEditControllerProvider(widget.genbaId));
    final bundleAsync = ref.watch(memoryBundleProvider(widget.genbaId));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: AsyncValueView<MemoryBundle>(
          value: bundleAsync,
          data: (bundle) {
            _ensureControllers(bundle.entry);
            return SingleChildScrollView(
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
                      Icon(
                        widget.section.icon,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        widget.section.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text('自動保存', style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  _body(bundle),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(MemoryBundle bundle) {
    return switch (widget.section) {
      MemorySection.impression => _impressionBody(),
      MemorySection.setlist => _setlistBody(bundle),
      MemorySection.dayRecord => _dayRecordBody(),
      MemorySection.tags => _tagsBody(bundle),
      MemorySection.photos => _photosBody(bundle),
    };
  }

  Widget _impressionBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _impression,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '感想（短いひとことでOK・あとから加筆できます）',
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          minLines: 4,
          onChanged: (v) =>
              _controller.updateEntry((e) => e.copyWith(impression: v)),
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _bestMoment,
          decoration: const InputDecoration(labelText: '特によかった曲・瞬間'),
          onChanged: (v) =>
              _controller.updateEntry((e) => e.copyWith(bestMoment: v)),
        ),
      ],
    );
  }

  Widget _setlistBody(MemoryBundle bundle) {
    return ListEditor(
      title: 'セトリ',
      icon: Icons.queue_music,
      inputController: _songInput,
      inputHint: '曲名を追加',
      items: [
        for (final item in bundle.setlist)
          (id: item.id, label: '${item.position}. ${item.songTitle}'),
      ],
      // 追加の成否は ListEditor 側で扱う（成功時のみクリア・失敗は表示）。
      onAdd: (text) => _controller.addSetlistItem(text),
      onDelete: (id) => _controller.deleteSetlistItem(id).then(_showFailure),
    );
  }

  Widget _dayRecordBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _seatView,
          decoration: const InputDecoration(labelText: '座席・見え方'),
          onChanged: (v) =>
              _controller.updateEntry((e) => e.copyWith(seatView: v)),
        ),
        const SizedBox(height: AppSpace.md),
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
        const SizedBox(height: AppSpace.md),
        ActualEndTimeCard(genbaId: widget.genbaId),
      ],
    );
  }

  Widget _tagsBody(MemoryBundle bundle) {
    return TagEditor(
      tags: bundle.entry?.tags ?? const [],
      inputController: _tagInput,
      onChanged: (tags) =>
          _controller.updateEntry((e) => e.copyWith(tags: tags)),
    );
  }

  Widget _photosBody(MemoryBundle bundle) {
    final store = ref.read(imageStoreProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _addPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('写真を追加（複数選択できます）'),
        ),
        if (bundle.photos.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final photo in bundle.photos)
                _PhotoTile(
                  photo: photo,
                  file: photo.localPath == null
                      ? null
                      : store.tryResolveOwned(photo.ownerId, photo.localPath!),
                  onDelete: () =>
                      _controller.deletePhoto(photo.id).then(_showFailure),
                  onSetCover: photo.isCover
                      ? null
                      : () => ref
                          .read(
                            memoryActionsControllerProvider(widget.genbaId)
                                .notifier,
                          )
                          .setCoverPhoto(photo.id)
                          .then(_showFailure),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _addPhotos() async {
    // 例外安全な共通ヘルパーで複数選択（権限・OS例外を捕捉, §15, レビュー是正）。
    final result = await pickPhotoPaths();
    // 選択中にシートが閉じられた場合、破棄済み State から ref.read しない。
    if (!mounted) return;
    if (result.outcome == PhotoPickOutcome.canceled) return;
    if (result.outcome == PhotoPickOutcome.failed) {
      _showMessage('写真を選択できませんでした');
      return;
    }
    for (final path in result.paths) {
      if (!mounted) return;
      final failure = await _controller.addPhoto(path);
      if (!mounted) return;
      if (failure != null) {
        _showFailure(failure);
        return;
      }
    }
  }
}

/// 写真タイル（表紙指定・削除）。表紙は常に最大1件（§12.1）。
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.file,
    required this.onDelete,
    required this.onSetCover,
  });

  final MemoryPhoto photo;
  final File? file;
  final VoidCallback onDelete;
  final VoidCallback? onSetCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        PhotoThumb(file: file, size: 96, onDelete: onDelete),
        Positioned(
          bottom: 0,
          left: 0,
          child: photo.isCover
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '表紙',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
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
                  onPressed: onSetCover,
                ),
        ),
      ],
    );
  }
}
