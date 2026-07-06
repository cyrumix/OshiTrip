import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../../genba/domain/genba.dart';
import '../application/itinerary_actions_controller.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import 'itinerary_sheet_scaffold.dart';

const _uuid = Uuid();

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// 登録済みの交通を計画へ参照追加する（複製しない・重複防止, §5.3）。
Future<void> showTransportImportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String ownerId,
  required List<Transport> transports,
  required List<ItineraryEntry> entries,
}) =>
    showItinerarySheet(
      context,
      _TransportImportSheet(
        planId: planId,
        ownerId: ownerId,
        transports: transports,
        entries: entries,
      ),
    );

class _TransportImportSheet extends ConsumerStatefulWidget {
  const _TransportImportSheet({
    required this.planId,
    required this.ownerId,
    required this.transports,
    required this.entries,
  });
  final String planId;
  final String ownerId;
  final List<Transport> transports;
  final List<ItineraryEntry> entries;

  @override
  ConsumerState<_TransportImportSheet> createState() =>
      _TransportImportSheetState();
}

class _TransportImportSheetState extends ConsumerState<_TransportImportSheet> {
  // 追加処理中は全ての追加ボタンを無効化する（二重タップ防止, §5.3）。
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final addedIds = widget.entries
        .where((e) => e.kind == ItineraryEntryKind.transport)
        .map((e) => e.transportId)
        .toSet();
    Future<void> add(Transport t) async {
      if (_busy) return;
      setState(() => _busy = true);
      final now = ref.read(clockProvider).now().toUtc();
      final date = t.departAt;
      final entry = ItineraryEntry(
        id: _uuid.v4(),
        planId: widget.planId,
        ownerId: widget.ownerId,
        kind: ItineraryEntryKind.transport,
        transportId: t.id,
        localDate:
            date == null ? null : DateTime(date.year, date.month, date.day),
        sortOrder: widget.entries.length,
        createdAt: now,
        updatedAt: now,
      );
      final failure = await ref
          .read(itineraryActionsControllerProvider(widget.planId).notifier)
          .upsertEntry(entry);
      if (!context.mounted) return;
      if (failure == null) {
        Navigator.of(context).pop();
        _snack(context, '交通を計画に追加しました');
      } else {
        setState(() => _busy = false);
        _snack(context, failure.message);
      }
    }

    return _ImportScaffold(
      title: '登録済みの交通を追加',
      empty: widget.transports.isEmpty ? 'この現場に交通が登録されていません' : null,
      children: [
        for (final t in widget.transports)
          ListTile(
            leading: Icon(
              t.direction == TransportDirection.outbound
                  ? Icons.arrow_circle_right_outlined
                  : Icons.arrow_circle_left_outlined,
            ),
            title: Text('${t.direction.label} ${t.method ?? ''}'.trim()),
            subtitle: (t.fromPlace != null || t.toPlace != null)
                ? Text('${t.fromPlace ?? '?'} → ${t.toPlace ?? '?'}')
                : null,
            trailing: addedIds.contains(t.id)
                ? const Chip(label: Text('追加済み'))
                : TextButton(
                    onPressed: _busy ? null : () => add(t),
                    child: const Text('追加'),
                  ),
            enabled: !addedIds.contains(t.id) && !_busy,
          ),
      ],
    );
  }
}

/// 登録済みの宿泊を計画へ参照追加する。
Future<void> showLodgingImportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String ownerId,
  required List<Lodging> lodgings,
  required List<ItineraryEntry> entries,
}) =>
    showItinerarySheet(
      context,
      _LodgingImportSheet(
        planId: planId,
        ownerId: ownerId,
        lodgings: lodgings,
        entries: entries,
      ),
    );

class _LodgingImportSheet extends ConsumerStatefulWidget {
  const _LodgingImportSheet({
    required this.planId,
    required this.ownerId,
    required this.lodgings,
    required this.entries,
  });
  final String planId;
  final String ownerId;
  final List<Lodging> lodgings;
  final List<ItineraryEntry> entries;

  @override
  ConsumerState<_LodgingImportSheet> createState() =>
      _LodgingImportSheetState();
}

class _LodgingImportSheetState extends ConsumerState<_LodgingImportSheet> {
  // 追加処理中は全ての追加ボタンを無効化する（二重タップ防止, §5.3）。
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final addedIds = widget.entries
        .where((e) => e.kind == ItineraryEntryKind.lodging)
        .map((e) => e.lodgingId)
        .toSet();
    Future<void> add(Lodging l) async {
      if (_busy) return;
      setState(() => _busy = true);
      final now = ref.read(clockProvider).now().toUtc();
      final date = l.checkinDate;
      final entry = ItineraryEntry(
        id: _uuid.v4(),
        planId: widget.planId,
        ownerId: widget.ownerId,
        kind: ItineraryEntryKind.lodging,
        lodgingId: l.id,
        localDate:
            date == null ? null : DateTime(date.year, date.month, date.day),
        sortOrder: widget.entries.length,
        createdAt: now,
        updatedAt: now,
      );
      final failure = await ref
          .read(itineraryActionsControllerProvider(widget.planId).notifier)
          .upsertEntry(entry);
      if (!context.mounted) return;
      if (failure == null) {
        Navigator.of(context).pop();
        _snack(context, '宿泊を計画に追加しました');
      } else {
        setState(() => _busy = false);
        _snack(context, failure.message);
      }
    }

    return _ImportScaffold(
      title: '登録済みの宿泊を追加',
      empty: widget.lodgings.isEmpty ? 'この現場に宿泊が登録されていません' : null,
      children: [
        for (final l in widget.lodgings)
          ListTile(
            leading: const Icon(Icons.hotel_outlined),
            title: Text(l.name ?? '宿泊先'),
            subtitle: l.checkinDate != null
                ? Text('${formatDateOnly(l.checkinDate!)} チェックイン')
                : null,
            trailing: addedIds.contains(l.id)
                ? const Chip(label: Text('追加済み'))
                : TextButton(
                    onPressed: _busy ? null : () => add(l),
                    child: const Text('追加'),
                  ),
            enabled: !addedIds.contains(l.id) && !_busy,
          ),
      ],
    );
  }
}

class _ImportScaffold extends StatelessWidget {
  const _ImportScaffold({
    required this.title,
    required this.children,
    this.empty,
  });
  final String title;
  final List<Widget> children;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                if (empty != null) Text(empty!),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 手動移動区間（leg）
// ---------------------------------------------------------------------------

/// タイムライン項目の選択肢（leg の端点選択に使う）。
class ItineraryEntryOption {
  const ItineraryEntryOption({required this.id, required this.label});
  final String id;
  final String label;
}

Future<void> showItineraryLegEditor(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required String ownerId,
  required List<ItineraryEntryOption> options,
  ItineraryLeg? existing,
}) =>
    showItinerarySheet(
      context,
      _LegEditor(
        planId: planId,
        ownerId: ownerId,
        options: options,
        existing: existing,
      ),
    );

class _LegEditor extends ConsumerStatefulWidget {
  const _LegEditor({
    required this.planId,
    required this.ownerId,
    required this.options,
    this.existing,
  });
  final String planId;
  final String ownerId;
  final List<ItineraryEntryOption> options;
  final ItineraryLeg? existing;

  @override
  ConsumerState<_LegEditor> createState() => _LegEditorState();
}

class _LegEditorState extends ConsumerState<_LegEditor> {
  String? _origin;
  String? _destination;
  ItineraryTravelMode _mode = ItineraryTravelMode.walking;
  DateTime? _departureAt;
  DateTime? _arrivalAt;
  late final TextEditingController _duration;
  late final TextEditingController _distance;
  late final TextEditingController _fare;
  late final TextEditingController _currency;
  late final TextEditingController _summary;
  late final TextEditingController _mapsUrl;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    _origin = l?.originEntryId;
    _destination = l?.destinationEntryId;
    _mode = l?.travelMode ?? ItineraryTravelMode.walking;
    _departureAt = l?.departureAt?.toLocal();
    _arrivalAt = l?.arrivalAt?.toLocal();
    _duration =
        TextEditingController(text: l?.durationMinutes?.toString() ?? '');
    _distance =
        TextEditingController(text: l?.distanceMeters?.toString() ?? '');
    _fare = TextEditingController(text: l?.fareAmountMinor?.toString() ?? '');
    _currency = TextEditingController(text: l?.fareCurrency ?? '');
    _summary = TextEditingController(text: l?.routeSummary ?? '');
    _mapsUrl = TextEditingController(text: l?.googleMapsUrl ?? '');
  }

  /// 日付＋時刻を選ばせて DateTime（ローカル）を返す。どちらか未選択なら null。
  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final base = initial ?? DateTime(2020);
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(base.year, base.month, base.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime(2020, 1, 1, 9)),
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  @override
  void dispose() {
    _duration.dispose();
    _distance.dispose();
    _fare.dispose();
    _currency.dispose();
    _summary.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_origin == null || _destination == null) {
      _snack(context, '出発と到着の項目を選んでください');
      return;
    }
    if (_origin == _destination) {
      _snack(context, '出発と到着に同じ項目は選べません');
      return;
    }
    final fareText = _fare.text.trim();
    final currencyText = _currency.text.trim();
    if (fareText.isEmpty != currencyText.isEmpty) {
      _snack(context, '運賃は金額と通貨をどちらも入力するか、どちらも空にしてください');
      return;
    }
    if (_departureAt != null &&
        _arrivalAt != null &&
        _arrivalAt!.isBefore(_departureAt!)) {
      _snack(context, '到着は出発より後の時刻にしてください');
      return;
    }
    final now = ref.read(clockProvider).now().toUtc();
    final leg = ItineraryLeg(
      id: widget.existing?.id ?? _uuid.v4(),
      planId: widget.planId,
      ownerId: widget.ownerId,
      originEntryId: _origin!,
      destinationEntryId: _destination!,
      travelMode: _mode,
      departureAt: _departureAt?.toUtc(),
      arrivalAt: _arrivalAt?.toUtc(),
      durationMinutes: int.tryParse(_duration.text.trim()),
      distanceMeters: int.tryParse(_distance.text.trim()),
      fareAmountMinor: fareText.isEmpty ? null : int.tryParse(fareText),
      fareCurrency: currencyText.isEmpty ? null : currencyText,
      routeSummary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
      googleMapsUrl: _mapsUrl.text.trim().isEmpty ? null : _mapsUrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final failure = await ref
        .read(itineraryActionsControllerProvider(widget.planId).notifier)
        .upsertLeg(leg);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      _snack(context, '移動区間を保存しました');
    } else {
      _snack(context, failure.message);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final failure = await ref
        .read(itineraryActionsControllerProvider(widget.planId).notifier)
        .deleteLeg(existing.id);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      _snack(context, '移動区間を削除しました');
    } else {
      _snack(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return ItinerarySheetScaffold(
      title: isEdit ? '移動区間を編集' : '移動区間を追加',
      onSave: _save,
      onDelete: isEdit ? _delete : null,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('leg_origin'),
          initialValue: _origin,
          decoration: const InputDecoration(labelText: '出発'),
          items: [
            for (final o in widget.options)
              DropdownMenuItem(value: o.id, child: Text(o.label)),
          ],
          onChanged: (v) => setState(() => _origin = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('leg_destination'),
          initialValue: _destination,
          decoration: const InputDecoration(labelText: '到着'),
          items: [
            for (final o in widget.options)
              DropdownMenuItem(value: o.id, child: Text(o.label)),
          ],
          onChanged: (v) => setState(() => _destination = v),
        ),
        ItineraryEnumChips<ItineraryTravelMode>(
          label: '移動手段',
          values: ItineraryTravelMode.values,
          selected: _mode,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _mode = v),
        ),
        const SizedBox(height: 12),
        _DateTimeField(
          label: '出発時刻',
          value: _departureAt,
          onPick: () async {
            final picked = await _pickDateTime(_departureAt);
            if (picked != null) setState(() => _departureAt = picked);
          },
          onClear: () => setState(() => _departureAt = null),
        ),
        const SizedBox(height: 12),
        _DateTimeField(
          label: '到着時刻',
          value: _arrivalAt,
          onPick: () async {
            final picked = await _pickDateTime(_arrivalAt);
            if (picked != null) setState(() => _arrivalAt = picked);
          },
          onClear: () => setState(() => _arrivalAt = null),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _duration,
                decoration: const InputDecoration(labelText: '所要（分）'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _distance,
                decoration: const InputDecoration(labelText: '距離（m）'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fare,
                decoration: const InputDecoration(labelText: '運賃'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _currency,
                decoration: const InputDecoration(labelText: '通貨（例: JPY）'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _summary,
          decoration: const InputDecoration(labelText: '経路概要'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mapsUrl,
          decoration: const InputDecoration(
            labelText: 'Google Mapsで開くURL（任意）',
            helperText: 'https のみ。外部遷移前にドメインを確認します',
          ),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

/// 日付＋時刻を選ぶ簡易フィールド（未設定可、クリアボタン付き）。
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final DateTime? value;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  String _format(DateTime v) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${v.year}/${two(v.month)}/${two(v.day)} '
        '${two(v.hour)}:${two(v.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(v == null ? '未設定' : _format(v)),
          ),
          if (v != null)
            IconButton(
              tooltip: '$labelをクリア',
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.schedule),
            label: const Text('選択'),
          ),
        ],
      ),
    );
  }
}
