import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../application/itinerary_actions_controller.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_spot.dart';
import '../domain/itinerary_spot_link.dart';
import '../domain/itinerary_validation.dart';
import 'itinerary_sheet_scaffold.dart';
import 'itinerary_spot_image.dart';

const _uuid = Uuid();

void _showResult(BuildContext context, Result<void> result, String okMessage) {
  final message = result.when(ok: (_) => okMessage, err: (f) => f.message);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showFailure(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(failure.message)));
}

/// スポット＋その訪問項目＋リンクのまとまり（編集時に渡す）。
class SpotEditTarget {
  const SpotEditTarget({
    required this.spot,
    required this.entry,
    required this.links,
  });
  final ItinerarySpot spot;
  final ItineraryEntry entry;
  final List<ItinerarySpotLink> links;
}

/// スポット（施設・訪問）編集シートを開く。新規では spot と訪問項目(entry)を
/// 同時に作る。Google検索導線はまだ出さない（「自分で入力」のみ, §4.1）。
Future<void> showItinerarySpotEditor(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String ownerId,
  SpotEditTarget? existing,
  DateTime? initialDate,
  DateTime? initialStart,
}) =>
    showItinerarySheet(
      context,
      _SpotEditor(
        planId: planId,
        ownerId: ownerId,
        existing: existing,
        initialDate: initialDate,
        initialStart: initialStart,
      ),
    );

class _SpotEditor extends ConsumerStatefulWidget {
  const _SpotEditor({
    required this.planId,
    required this.ownerId,
    this.existing,
    this.initialDate,
    this.initialStart,
  });
  final String planId;
  final String ownerId;
  final SpotEditTarget? existing;

  /// 新規追加時の訪問日の初期値（現在操作中の予定日など。§5.5 点4）。
  /// 編集時は無視し、保存済みの日付を使う。
  final DateTime? initialDate;

  /// 新規追加時の開始時刻の初期値（直前予定の終了時刻。点5）。編集時は無視。
  final DateTime? initialStart;

  @override
  ConsumerState<_SpotEditor> createState() => _SpotEditorState();
}

class _SpotEditorState extends ConsumerState<_SpotEditor> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _memo;
  late ItinerarySpotCategory _category;
  DateTime? _visitDate;
  TimeOfDay? _start;
  TimeOfDay? _end;
  int _bufferBefore = 0;
  int _bufferAfter = 0;
  String? _imageLocalPath;
  late List<ItinerarySpotLink> _links;

  final List<String> _sessionImports = [];
  String? _sessionOwnerId;

  @override
  void initState() {
    super.initState();
    final s = widget.existing?.spot;
    final e = widget.existing?.entry;
    _name = TextEditingController(text: s?.name ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _memo = TextEditingController(text: s?.memo ?? '');
    _category = s?.category ?? ItinerarySpotCategory.sightseeing;
    // 編集時は保存済みの日付・時刻をそのまま使う。新規時は初期値
    // （現在操作中の予定日／直前予定の終了時刻）を使い、端末の本日は使わない。
    final isNew = widget.existing == null;
    _visitDate = isNew ? widget.initialDate : e?.localDate;
    final initialStart = widget.initialStart;
    _start = e?.startAt != null
        ? TimeOfDay(hour: e!.startAt!.hour, minute: e.startAt!.minute)
        : (isNew && _visitDate != null && initialStart != null
            ? TimeOfDay(hour: initialStart.hour, minute: initialStart.minute)
            : null);
    _end = e?.endAt == null
        ? null
        : TimeOfDay(hour: e!.endAt!.hour, minute: e.endAt!.minute);
    _bufferBefore = e?.bufferBeforeMinutes ?? 0;
    _bufferAfter = e?.bufferAfterMinutes ?? 0;
    _imageLocalPath = s?.userImageLocalPath;
    _links = [...?widget.existing?.links];
  }

  @override
  void dispose() {
    // 未確定 import 画像は掃除する（保存確定時は _sessionImports を空にする）。
    final owner = _sessionOwnerId;
    if (owner != null && _sessionImports.isNotEmpty) {
      final store = ref.read(imageStoreProvider);
      for (final r in List<String>.of(_sessionImports)) {
        unawaited(store.deleteRef(owner, r));
      }
      _sessionImports.clear();
    }
    _name.dispose();
    _address.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final owner = widget.ownerId;
    if (owner.isEmpty) return;
    try {
      final storedRef = await ref.read(imageStoreProvider).import(
            ownerId: owner,
            category: ImageCategory.itinerarySpot,
            source: File(picked.path),
          );
      _sessionOwnerId = owner;
      _sessionImports.add(storedRef);
      if (mounted) setState(() => _imageLocalPath = storedRef);
    } on ImageStorageException catch (e) {
      if (mounted) {
        _showFailure(
          context,
          StorageFailure(message: '画像の保存に失敗しました', cause: e),
        );
      }
    } catch (e) {
      if (mounted) _showFailure(context, StorageFailure(cause: e));
    }
  }

  DateTime? _combine(
    DateTime date,
    TimeOfDay? t, {
    bool endAfterStart = false,
  }) {
    if (t == null) return null;
    var day = DateTime.utc(date.year, date.month, date.day, t.hour, t.minute);
    // 終了が開始より前なら翌日扱い（日跨ぎ）。
    if (endAfterStart && _start != null) {
      final startMin = _start!.hour * 60 + _start!.minute;
      final endMin = t.hour * 60 + t.minute;
      if (endMin < startMin) day = day.add(const Duration(days: 1));
    }
    return day;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('施設名を入力してください')));
      return;
    }
    // 緯度・経度は手動入力画面から廃止した（§4.2）。将来の地図・Google連携用の
    // nullableフィールドは残すが、この画面からは編集しない。既存スポットの座標は
    // 保持し（誤ってnullで上書きしない）、新規手動登録では null とする。
    final lat = widget.existing?.spot.latitude;
    final lng = widget.existing?.spot.longitude;
    final now = ref.read(clockProvider).now().toUtc();
    final controller =
        ref.read(itineraryActionsControllerProvider(_genbaScopeId).notifier);

    final spotId = widget.existing?.spot.id ?? _uuid.v4();
    final spot = ItinerarySpot(
      id: spotId,
      planId: widget.planId,
      ownerId: widget.ownerId,
      name: _name.text.trim(),
      category: _category,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      latitude: lat,
      longitude: lng,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      userImageLocalPath: _imageLocalPath,
      createdAt: widget.existing?.spot.createdAt ?? now,
      updatedAt: now,
    );
    final visitDate = _visitDate;
    final entryId = widget.existing?.entry.id ?? _uuid.v4();
    final entry = ItineraryEntry(
      id: entryId,
      planId: widget.planId,
      ownerId: widget.ownerId,
      kind: ItineraryEntryKind.spot,
      spotId: spotId,
      localDate: visitDate == null
          ? null
          : DateTime(visitDate.year, visitDate.month, visitDate.day),
      startAt: visitDate == null ? null : _combine(visitDate, _start),
      endAt: visitDate == null
          ? null
          : _combine(visitDate, _end, endAfterStart: true),
      bufferBeforeMinutes: _bufferBefore,
      bufferAfterMinutes: _bufferAfter,
      sortOrder: widget.existing?.entry.sortOrder ?? 0,
      createdAt: widget.existing?.entry.createdAt ?? now,
      updatedAt: now,
    );

    // リンクの差分：確定した spotId を新規リンクにも付与してから保存する。
    final links = <ItinerarySpotLink>[
      for (var i = 0; i < _links.length; i++)
        _links[i].copyWith(spotId: spotId, sortOrder: i, updatedAt: now),
    ];
    final keepIds = links.map((l) => l.id).toSet();
    final removedLinkIds = <String>[
      for (final old in widget.existing?.links ?? const <ItinerarySpotLink>[])
        if (!keepIds.contains(old.id)) old.id,
    ];

    // スポット・訪問項目・リンク差分を単一トランザクションで原子的に保存する。
    final failure = await controller.saveSpotBundle(
      spot: spot,
      entry: entry,
      links: links,
      removedLinkIds: removedLinkIds,
    );
    if (failure != null) {
      if (mounted) _showFailure(context, failure);
      return;
    }

    // 画像の掃除（差替え・保存済みは触れない）。
    await _reconcileImages(saved: true);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, const Ok(null), 'スポットを保存しました');
  }

  Future<void> _reconcileImages({required bool saved}) async {
    final owner = widget.ownerId;
    if (owner.isEmpty) return;
    final store = ref.read(imageStoreProvider);
    final original = widget.existing?.spot.userImageLocalPath;
    if (saved) {
      if (original != null && original != _imageLocalPath) {
        await store.deleteRef(owner, original);
      }
      for (final r in _sessionImports) {
        if (r != _imageLocalPath) await store.deleteRef(owner, r);
      }
    }
    _sessionImports.clear();
  }

  Future<void> _delete() async {
    final target = widget.existing;
    if (target == null) return;
    final controller =
        ref.read(itineraryActionsControllerProvider(_genbaScopeId).notifier);
    final failure = await controller.deleteSpot(target.spot);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      _showResult(context, const Ok(null), 'スポットを削除しました');
    } else {
      _showFailure(context, failure);
    }
  }

  // このシートは genbaId を知らないが、Controller は planId 単位でなく genbaId
  // family。scope は planId を鍵として使う（同一planに対する二重タップを弾く）。
  String get _genbaScopeId => widget.planId;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? ref.read(clockProvider).now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (start ? _start : _end) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return ItinerarySheetScaffold(
      title: isEdit ? 'スポットを編集' : 'スポットを追加',
      onSave: _save,
      onDelete: isEdit ? _delete : null,
      children: [
        // 手動入力を主要導線として明示（Google検索はまだ出さない）。
        Text(
          '自分で入力',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: '施設名 *'),
          autofocus: !isEdit,
        ),
        ItineraryEnumChips<ItinerarySpotCategory>(
          label: 'カテゴリ',
          values: ItinerarySpotCategory.values,
          selected: _category,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _category = v),
        ),
        TextField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: '住所',
            helperText: '共有時は既定で非公開として扱われます',
          ),
        ),
        const Divider(height: 32),
        Text('訪問予定', style: Theme.of(context).textTheme.labelLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('訪問日'),
          subtitle: Text(
            _visitDate == null
                ? '未設定（候補リストに入ります）'
                : formatDateOnly(_visitDate!),
          ),
          trailing: _visitDate == null
              ? const Icon(Icons.calendar_month)
              : IconButton(
                  tooltip: '訪問日を消す',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _visitDate = null;
                    _start = null;
                    _end = null;
                  }),
                ),
          onTap: _pickDate,
        ),
        if (_visitDate != null) ...[
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('開始'),
                  subtitle:
                      Text(_start == null ? '時刻未定' : _start!.format(context)),
                  onTap: () => _pickTime(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('終了'),
                  subtitle: Text(_end == null ? '時刻未定' : _end!.format(context)),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          _BufferChips(
            label: '到着前の余裕',
            value: _bufferBefore,
            onChanged: (v) => setState(() => _bufferBefore = v),
          ),
          _BufferChips(
            label: '出発後の余裕',
            value: _bufferAfter,
            onChanged: (v) => setState(() => _bufferAfter = v),
          ),
        ],
        const Divider(height: 32),
        _LinkManager(
          links: _links,
          onChanged: (next) => setState(() => _links = next),
          ownerId: widget.ownerId,
          spotId: widget.existing?.spot.id ?? '',
        ),
        const Divider(height: 32),
        Row(
          children: [
            if (_imageLocalPath != null) ...[
              ItinerarySpotImage(
                ownerId: widget.ownerId,
                imageRef: _imageLocalPath,
                facilityName:
                    _name.text.trim().isEmpty ? 'このスポット' : _name.text.trim(),
                size: 56,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                _imageLocalPath == null ? 'ユーザー画像: 未設定' : 'ユーザー画像: 端末に保存済み',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('画像を選択'),
            ),
            if (_imageLocalPath != null)
              IconButton(
                tooltip: '画像を外す',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _imageLocalPath = null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _memo,
          decoration: const InputDecoration(labelText: 'メモ'),
          maxLines: 2,
        ),
      ],
    );
  }
}

/// 前後の余裕時間チップ（0/15/30/45/60分）。
class _BufferChips extends StatelessWidget {
  const _BufferChips({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Wrap(
            spacing: 6,
            children: [
              for (final m in const [0, 15, 30, 45, 60])
                ChoiceChip(
                  label: Text(m == 0 ? 'なし' : '$m分'),
                  selected: value == m,
                  onSelected: (_) => onChanged(m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// スポットの種別つきURL管理（複数・追加/編集/削除/並び替え・スキーム拒否）。
class _LinkManager extends StatelessWidget {
  const _LinkManager({
    required this.links,
    required this.onChanged,
    required this.ownerId,
    required this.spotId,
  });
  final List<ItinerarySpotLink> links;
  final void Function(List<ItinerarySpotLink>) onChanged;
  final String ownerId;
  final String spotId;

  Future<void> _addOrEdit(
    BuildContext context, {
    ItinerarySpotLink? existing,
  }) async {
    final result = await showDialog<ItinerarySpotLink>(
      context: context,
      builder: (_) => _LinkDialog(
        existing: existing,
        ownerId: ownerId,
        spotId: spotId,
      ),
    );
    if (result == null) return;
    final next = [...links];
    final idx = next.indexWhere((l) => l.id == result.id);
    if (idx >= 0) {
      next[idx] = result;
    } else {
      next.add(result);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('リンク', style: Theme.of(context).textTheme.labelLarge),
            ),
            TextButton.icon(
              onPressed: () => _addOrEdit(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('URLを追加'),
            ),
          ],
        ),
        if (links.isEmpty)
          Text('未登録', style: Theme.of(context).textTheme.bodySmall),
        for (var i = 0; i < links.length; i++)
          ListTile(
            key: ValueKey(links[i].id),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              links[i].label?.isNotEmpty == true
                  ? links[i].label!
                  : links[i].kind.label,
            ),
            subtitle: Text(
              Uri.tryParse(links[i].url)?.host ?? links[i].url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '上へ',
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: i == 0
                      ? null
                      : () {
                          final next = [...links];
                          final tmp = next[i - 1];
                          next[i - 1] = next[i];
                          next[i] = tmp;
                          onChanged(next);
                        },
                ),
                IconButton(
                  tooltip: '編集',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _addOrEdit(context, existing: links[i]),
                ),
                IconButton(
                  tooltip: '削除',
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () {
                    final next = [...links]..removeAt(i);
                    onChanged(next);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({
    required this.ownerId,
    required this.spotId,
    this.existing,
  });
  final String ownerId;
  final String spotId;
  final ItinerarySpotLink? existing;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final TextEditingController _url;
  late final TextEditingController _label;
  late ItinerarySpotLinkKind _kind;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.existing?.url ?? '');
    _label = TextEditingController(text: widget.existing?.label ?? '');
    _kind = widget.existing?.kind ?? ItinerarySpotLinkKind.reference;
  }

  @override
  void dispose() {
    _url.dispose();
    _label.dispose();
    super.dispose();
  }

  void _submit() {
    final failure = validateItineraryUrl(_url.text, label: _kind.label);
    if (failure != null) {
      setState(() => _error = failure.message);
      return;
    }
    final now = DateTime.now().toUtc();
    Navigator.of(context).pop(
      (widget.existing ??
              ItinerarySpotLink(
                id: _uuid.v4(),
                spotId: widget.spotId,
                ownerId: widget.ownerId,
                kind: _kind,
                url: _url.text.trim(),
                createdAt: now,
                updatedAt: now,
              ))
          .copyWith(
        kind: _kind,
        url: _url.text.trim(),
        label: _label.text.trim().isEmpty ? null : _label.text.trim(),
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'URLを追加' : 'URLを編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ItineraryEnumChips<ItinerarySpotLinkKind>(
              label: '種別',
              values: ItinerarySpotLinkKind.values,
              selected: _kind,
              labelOf: (v) => v.label,
              onChanged: (v) => setState(() => _kind = v),
            ),
            TextField(
              controller: _url,
              decoration: InputDecoration(
                labelText: 'URL（https）',
                errorText: _error,
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'ラベル（任意）'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 自由メモ／集合予定（note entry）
// ---------------------------------------------------------------------------

Future<void> showItineraryNoteEditor(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String ownerId,
  ItineraryEntry? existing,
}) =>
    showItinerarySheet(
      context,
      _NoteEditor(planId: planId, ownerId: ownerId, existing: existing),
    );

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({
    required this.planId,
    required this.ownerId,
    this.existing,
  });
  final String planId;
  final String ownerId;
  final ItineraryEntry? existing;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _memo;
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.titleOverride ?? '');
    _memo = TextEditingController(text: widget.existing?.memo ?? '');
    _date = widget.existing?.localDate;
    final at = widget.existing?.startAt;
    _time = at == null ? null : TimeOfDay(hour: at.hour, minute: at.minute);
  }

  @override
  void dispose() {
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _memo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('タイトルかメモを入力してください')));
      return;
    }
    final now = ref.read(clockProvider).now().toUtc();
    final date = _date;
    final entry = ItineraryEntry(
      id: widget.existing?.id ?? _uuid.v4(),
      planId: widget.planId,
      ownerId: widget.ownerId,
      kind: ItineraryEntryKind.note,
      titleOverride: _title.text.trim().isEmpty ? null : _title.text.trim(),
      localDate:
          date == null ? null : DateTime(date.year, date.month, date.day),
      startAt: (date == null || _time == null)
          ? null
          : DateTime.utc(
              date.year,
              date.month,
              date.day,
              _time!.hour,
              _time!.minute,
            ),
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? 0,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final failure = await ref
        .read(itineraryActionsControllerProvider(widget.planId).notifier)
        .upsertEntry(entry);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      _showResult(context, const Ok(null), 'メモを保存しました');
    } else {
      _showFailure(context, failure);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final failure = await ref
        .read(itineraryActionsControllerProvider(widget.planId).notifier)
        .deleteEntry(existing.id);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      _showResult(context, const Ok(null), 'メモを削除しました');
    } else {
      _showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return ItinerarySheetScaffold(
      title: isEdit ? 'メモを編集' : 'メモ・集合予定を追加',
      onSave: _save,
      onDelete: isEdit ? _delete : null,
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'タイトル（集合場所など）'),
          autofocus: !isEdit,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('日付'),
          subtitle: Text(_date == null ? '未設定（候補）' : formatDateOnly(_date!)),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date ?? ref.read(clockProvider).now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        if (_date != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('時刻'),
            subtitle: Text(_time == null ? '時刻未定' : _time!.format(context)),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _memo,
          decoration: const InputDecoration(labelText: 'メモ'),
          maxLines: 3,
        ),
      ],
    );
  }
}
