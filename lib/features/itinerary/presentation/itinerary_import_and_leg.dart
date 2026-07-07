import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../../genba/domain/genba.dart';
import '../application/itinerary_actions_controller.dart';
import '../domain/itinerary_entry.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_schedule.dart';
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
      // 交通は参照元(transports)を複製せず参照する。表示日・出発時刻は毎回
      // 参照元から導出するため、ここで日時をスナップショットしない（localDate
      // は null=参照元に追従。ユーザーが後から旅程側で日付を上書きした場合のみ
      // 非nullになる, §5.3/点4）。
      final entry = ItineraryEntry(
        id: _uuid.v4(),
        planId: widget.planId,
        ownerId: widget.ownerId,
        kind: ItineraryEntryKind.transport,
        transportId: t.id,
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
      // 宿泊も参照元(lodgings)を参照するだけで日付をスナップショットしない。
      // 表示日はチェックイン日から毎回導出する（localDate=null で参照元に追従,
      // §5.3/点4）。
      final entry = ItineraryEntry(
        id: _uuid.v4(),
        planId: widget.planId,
        ownerId: widget.ownerId,
        kind: ItineraryEntryKind.lodging,
        lodgingId: l.id,
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
///
/// [date] はその項目の実効表示日（交通・宿泊は参照元から導出済み）。移動区間の
/// 出発日・到着日はこの端点の日付から内部決定するため保持する（点3）。
class ItineraryEntryOption {
  const ItineraryEntryOption({
    required this.id,
    required this.label,
    this.date,
  });
  final String id;
  final String label;
  final DateTime? date;
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
  // 移動区間は前後予定を結ぶものなので、日付は入力させず前後予定から内部決定する。
  // ここでは時刻だけを持つ（点3）。既存データの departureAt/arrivalAt からは
  // 時刻部分を復元する（互換維持）。
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;
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
    _departureTime = l?.departureAt == null
        ? null
        : TimeOfDay.fromDateTime(l!.departureAt!.toLocal());
    _arrivalTime = l?.arrivalAt == null
        ? null
        : TimeOfDay.fromDateTime(l!.arrivalAt!.toLocal());
    _duration =
        TextEditingController(text: l?.durationMinutes?.toString() ?? '');
    _distance =
        TextEditingController(text: l?.distanceMeters?.toString() ?? '');
    _fare = TextEditingController(text: l?.fareAmountMinor?.toString() ?? '');
    _currency = TextEditingController(text: l?.fareCurrency ?? '');
    _summary = TextEditingController(text: l?.routeSummary ?? '');
    _mapsUrl = TextEditingController(text: l?.googleMapsUrl ?? '');
  }

  /// 時刻だけを選ばせる（日付は前後予定から内部決定するため入力させない, 点3）。
  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) => showTimePicker(
        context: context,
        initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
      );

  DateTime? _dateOf(String? entryId) {
    if (entryId == null) return null;
    for (final o in widget.options) {
      if (o.id == entryId) return o.date;
    }
    return null;
  }

  /// 端点の日付と入力時刻から departureAt/arrivalAt を内部決定する（点3）。
  /// 純粋関数 [deriveLegTimestamps] へ委譲する（本日を勝手に入れない・日跨ぎ考慮）。
  ({DateTime? departure, DateTime? arrival}) _deriveTimestamps() =>
      deriveLegTimestamps(
        originDate: _dateOf(_origin),
        destinationDate: _dateOf(_destination),
        departureTime: _departureTime == null
            ? null
            : (hour: _departureTime!.hour, minute: _departureTime!.minute),
        arrivalTime: _arrivalTime == null
            ? null
            : (hour: _arrivalTime!.hour, minute: _arrivalTime!.minute),
      );

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
    final derived = _deriveTimestamps();
    final departureAt = derived.departure;
    final arrivalAt = derived.arrival;
    if (departureAt != null &&
        arrivalAt != null &&
        arrivalAt.isBefore(departureAt)) {
      _snack(context, '到着は出発より後の時刻にしてください');
      return;
    }
    // 時刻を入力したのに前後予定の日付が取れず日時を確定できない場合は、日本語で
    // 案内する（所要時間など日付を要しない内容は保存できる, 点3）。
    if ((_departureTime != null && departureAt == null) ||
        (_arrivalTime != null && arrivalAt == null)) {
      _snack(
        context,
        '前後の予定の日付が未定のため時刻は保存できません。'
        '所要時間などは保存できます。予定日を設定すると時刻も反映されます。',
      );
    }
    final now = ref.read(clockProvider).now().toUtc();
    final leg = ItineraryLeg(
      id: widget.existing?.id ?? _uuid.v4(),
      planId: widget.planId,
      ownerId: widget.ownerId,
      originEntryId: _origin!,
      destinationEntryId: _destination!,
      travelMode: _mode,
      departureAt: departureAt?.toUtc(),
      arrivalAt: arrivalAt?.toUtc(),
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
        const SizedBox(height: 8),
        Text(
          '日付は出発元・到着先の予定日から自動で決まります（時刻だけ入力）。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _TimeField(
          label: '出発時刻',
          value: _departureTime,
          onPick: () async {
            final picked = await _pickTime(_departureTime);
            if (picked != null) setState(() => _departureTime = picked);
          },
          onClear: () => setState(() => _departureTime = null),
        ),
        const SizedBox(height: 12),
        _TimeField(
          label: '到着時刻',
          value: _arrivalTime,
          onPick: () async {
            final picked = await _pickTime(_arrivalTime);
            if (picked != null) setState(() => _arrivalTime = picked);
          },
          onClear: () => setState(() => _arrivalTime = null),
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

/// 時刻だけを選ぶ簡易フィールド（未設定可、クリアボタン付き）。日付は前後予定
/// から内部決定するため入力させない（点3）。
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final TimeOfDay? value;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(v == null ? '未設定' : v.format(context)),
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
