import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/failure.dart';
import '../../genba/application/genba_actions_controller.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';

/// 思い出記録で共有する編集ウィジェット群（§8.2/§8.4）。
///
/// フル記録画面（[MemoryEditScreen]）とセクション別ボトムシート
/// （[showMemorySectionSheet]）の双方で使い回し、実装の二重化を避ける（D-252/M3）。

/// 画像ピッカーの選択結果（キャンセル／選択／失敗を区別する, §12/§15）。
enum PhotoPickOutcome { canceled, picked, failed }

/// 複数写真を選び、そのパス一覧を返す共有ヘルパー（3画面で重複させない, M3/レビュー是正）。
///
/// - `outcome == canceled`: ユーザーが選択をやめた（エラー表示しない）。
/// - `outcome == picked`: `paths` に1件以上。
/// - `outcome == failed`: 権限拒否・OS/プラグイン例外（呼び出し側でエラー表示する）。
class PhotoPickResult {
  const PhotoPickResult(this.outcome, this.paths);
  final PhotoPickOutcome outcome;
  final List<String> paths;
}

/// [ImagePicker.pickMultiImage] を例外安全に呼ぶ。実機の権限・プラグイン例外で
/// 画面が壊れないよう捕捉する（成功していない選択を成功扱いにしない, §15）。
Future<PhotoPickResult> pickPhotoPaths() async {
  try {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) {
      return const PhotoPickResult(PhotoPickOutcome.canceled, []);
    }
    return PhotoPickResult(
      PhotoPickOutcome.picked,
      [for (final image in picked) image.path],
    );
  } on PlatformException {
    return const PhotoPickResult(PhotoPickOutcome.failed, []);
  } on Exception {
    return const PhotoPickResult(PhotoPickOutcome.failed, []);
  }
}

/// 「実際の終演時間」の記録カード。最初に登録する終演時間は予想値。
/// 実際に終わった時刻を記録すると、確認のうえ現場の終演時間（予定・状態導出の
/// 両方）を上書きし、概要・当日・計画など終演時間を参照する箇所に反映する。
class ActualEndTimeCard extends ConsumerWidget {
  const ActualEndTimeCard({super.key, required this.genbaId});
  final String genbaId;

  static String _hhmm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // loading/error/データなしを「非表示」に潰さず区別する（§15・レビュー是正）。
    return ref.watch(genbaByIdProvider(genbaId)).when(
          loading: () => const Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('実際の終演時間'),
              subtitle: Text('読み込み中…'),
            ),
          ),
          error: (_, __) => Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('実際の終演時間'),
              subtitle: const Text('現場を読み込めませんでした'),
              trailing: const Icon(Icons.refresh),
              onTap: () => ref.invalidate(genbaByIdProvider(genbaId)),
            ),
          ),
          data: (aggregate) {
            final genba = aggregate?.genba;
            if (genba == null) {
              return const Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.nightlife_outlined),
                  title: Text('実際の終演時間'),
                  subtitle: Text('現場が見つかりませんでした'),
                ),
              );
            }
            return _content(context, ref, genba);
          },
        );
  }

  Widget _content(BuildContext context, WidgetRef ref, Genba genba) {
    final eventDay = DateTime(
      genba.eventDate.year,
      genba.eventDate.month,
      genba.eventDate.day,
    );
    final manual = genba.manualEndedAt?.toLocal();
    final isActual = manual != null;
    final current = manual ??
        (genba.endTimeMinutes != null
            ? eventDay.add(Duration(minutes: genba.endTimeMinutes!))
            : null);
    final subtitle = current == null
        ? '終演時間が未登録です。タップして実際の終演時間を記録できます。'
        : '${isActual ? '実際' : '予想'}: ${_hhmm(current.hour, current.minute)}'
            '（タップして実際の終演時間を記録・更新）';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: const Key('actual_end_time_tile'),
        leading: const Icon(Icons.nightlife_outlined),
        title: const Text('実際の終演時間'),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _pickAndSave(context, ref, genba, eventDay, current),
      ),
    );
  }

  Future<void> _pickAndSave(
    BuildContext context,
    WidgetRef ref,
    Genba genba,
    DateTime eventDay,
    DateTime? current,
  ) async {
    final seed = current != null
        ? TimeOfDay(hour: current.hour, minute: current.minute)
        : const TimeOfDay(hour: 21, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: seed,
      helpText: '実際の終演時間',
    );
    if (picked == null || !context.mounted) return;
    final startMin = genba.startTimeMinutes ?? 0;
    final pickedMin = picked.hour * 60 + picked.minute;
    var endedAt = DateTime(
      eventDay.year,
      eventDay.month,
      eventDay.day,
      picked.hour,
      picked.minute,
    );
    // 開演より前の時刻は深夜終演（日跨ぎ）とみなし翌日にする。
    if (startMin > 0 && pickedMin <= startMin) {
      endedAt = endedAt.add(const Duration(days: 1));
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('終演時間の更新'),
        content: Text(
          '現場の終演時間を ${_hhmm(picked.hour, picked.minute)} に更新しますか？\n'
          '概要・当日・計画など終演時間を参照する箇所に反映されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('更新する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await ref
        .read(genbaActionsControllerProvider(genba.id).notifier)
        .setActualEndTime(genba, endedAt);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null ? '終演時間を更新しました' : failure.message),
      ),
    );
  }
}

/// 名前＋写真を持つ項目（グッズ・行った場所・食べもの）の編集（§8.4）。
/// 各項目に写真を紐づけ・削除でき、項目削除時は呼び出し側が
/// 「アルバムに残す／写真も削除」を確認する。
class ItemsWithPhotosEditor extends StatelessWidget {
  const ItemsWithPhotosEditor({
    super.key,
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
                      itemBuilder: (context, i) => PhotoThumb(
                        file: item.photos[i].file,
                        size: 72,
                        onDelete: () => onDeletePhoto(item.photos[i].id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        _AddRow(
          controller: inputController,
          hint: inputHint,
          onAdd: onAdd,
        ),
      ],
    );
  }
}

/// 「入力＋追加」行。追加中はボタンを無効化して二重送信を防ぎ、追加が成功した
/// ときだけ入力を消す（失敗時は入力を残す, レビュー是正）。[onAdd] は失敗
/// （[Failure] 等・null=成功）を返す。
class _AddRow extends StatefulWidget {
  const _AddRow({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String hint;
  final Future<Object?> Function(String text) onAdd;

  @override
  State<_AddRow> createState() => _AddRowState();
}

class _AddRowState extends State<_AddRow> {
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onAdd(text);
      if (!mounted) return;
      if (result == null) {
        // 成功時のみクリア（失敗時は入力を残す）。
        widget.controller.clear();
      } else {
        _showMessage(result is Failure ? result.message : '追加できませんでした');
      }
    } on Object catch (_) {
      // 例外時も入力を残し、busy を戻して固まらないようにする（レビュー是正）。
      _showMessage('追加できませんでした');
    } finally {
      // 成功・失敗・例外・途中破棄いずれでも busy を必ず戻す。
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            enabled: !_busy,
            decoration: InputDecoration(hintText: widget.hint, isDense: true),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(
          tooltip: '追加',
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_circle_outline),
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// 正方形の写真サムネイル（角丸・任意で削除ボタン）。§8.4/§9 の統一サムネイル。
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.file,
    required this.size,
    this.onDelete,
  });

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

/// 単純な名前リストの追加・削除エディタ（セトリ等）。
class ListEditor extends StatelessWidget {
  const ListEditor({
    super.key,
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
        _AddRow(
          controller: inputController,
          hint: inputHint,
          onAdd: onAdd,
        ),
      ],
    );
  }
}

/// タグ（写真整理・表情など）の編集。
class TagEditor extends StatelessWidget {
  const TagEditor({
    super.key,
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
