import 'package:collection/collection.dart';
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
import 'route_live_panel.dart';

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
            title: Text('${t.direction.label} ${t.methodDisplay}'.trim()),
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
    this.startAt,
    this.endAt,
    this.spotId,
    this.googlePlaceId,
    this.address,
    this.latitude,
    this.longitude,
  });
  final String id;
  final String label;
  final DateTime? date;

  /// この項目の実効開始/終了時刻（移動区間の時刻初期値に使う, item 2）。
  /// 到着時刻の初期値＝到着先の開始時刻、出発時刻の初期値＝出発元の終了時刻。
  final DateTime? startAt;
  final DateTime? endAt;

  /// スポット訪問項目のときだけ非null（Google Routesの経路取得はスポット↔スポット
  /// のみ対象。transport/lodging端点では null）。[address]/[latitude]/[longitude] は
  /// 「経路を確認」URLのフォールバックに使う（item 5）。
  final String? spotId;
  final String? googlePlaceId;
  final String? address;
  final double? latitude;
  final double? longitude;
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
  late final TextEditingController _distance;
  late final TextEditingController _fare;

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
    _distance =
        TextEditingController(text: l?.distanceMeters?.toString() ?? '');
    // 金額は日本円前提。fareAmountMinor（JPYは補助単位=円）をそのまま円で扱う。
    _fare = TextEditingController(text: l?.fareAmountMinor?.toString() ?? '');
  }

  /// 時刻だけを選ばせる（日付は前後予定から内部決定するため入力させない, 点3）。
  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) => showTimePicker(
        context: context,
        initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
      );

  ItineraryEntryOption? _optionOf(String? entryId) {
    if (entryId == null) return null;
    return widget.options.firstWhereOrNull((o) => o.id == entryId);
  }

  DateTime? _dateOf(String? entryId) => _optionOf(entryId)?.date;

  /// 出発時刻の初期値: 移動元の終了時刻 → 開始時刻（item 2）。
  /// 到着時刻の初期値: 移動先の開始時刻 → 終了時刻（item 2）。
  /// ユーザーが未入力（null）のときだけ補完し、入力済みは尊重する。
  void _applyEndpointTimeDefaults() {
    final origin = _optionOf(_origin);
    if (_departureTime == null && origin != null) {
      final src = origin.endAt ?? origin.startAt;
      if (src != null) _departureTime = TimeOfDay.fromDateTime(src.toLocal());
    }
    final dest = _optionOf(_destination);
    if (_arrivalTime == null && dest != null) {
      final src = dest.startAt ?? dest.endAt;
      if (src != null) _arrivalTime = TimeOfDay.fromDateTime(src.toLocal());
    }
  }

  /// 出発・到着時刻から所要（分）を求める（両方あるときだけ。日跨ぎ考慮）。item 3。
  int? _computedDurationMinutes() {
    final dep = _departureTime;
    final arr = _arrivalTime;
    if (dep == null || arr == null) return null;
    final depMin = dep.hour * 60 + dep.minute;
    var arrMin = arr.hour * 60 + arr.minute;
    if (arrMin < depMin) arrMin += 24 * 60; // 日跨ぎ
    return arrMin - depMin;
  }

  /// 保存時の departureAt/arrivalAt を決める（High是正）。
  ///
  /// - 端点・時刻を一切変更していない編集は、既存の完全な日時をそのまま保持する
  ///   （運賃・所要時間・メモだけの編集で日時が変化しない）。
  /// - 端点の日付を取得できるときは前後予定から自動合成する（日跨ぎ考慮, 点3）。
  /// - 端点の日付を取得できないまま時刻を「変更」した場合は、既存日時を黙って
  ///   削除せず保存を止め、[block] に日本語の案内を返す。
  /// - ユーザーが時刻をクリアした場合だけ null にできる。
  /// - 新規作成と既存編集を区別する。
  /// 保存時の departureAt/arrivalAt を決める。TZ依存の時刻復元・変更判定だけを
  /// ここで行い、判定ロジックは純粋関数 [resolveLegTimestampsForSave] へ委譲する。
  ({DateTime? departure, DateTime? arrival, String? block}) _resolveForSave() {
    final existing = widget.existing;
    final isNew = existing == null;

    bool sameTime(TimeOfDay? a, TimeOfDay? b) =>
        (a == null && b == null) ||
        (a != null && b != null && a.hour == b.hour && a.minute == b.minute);

    ItineraryClockTime? toClock(TimeOfDay? t) =>
        t == null ? null : (hour: t.hour, minute: t.minute);

    final origDepTime = (isNew || existing.departureAt == null)
        ? null
        : TimeOfDay.fromDateTime(existing.departureAt!.toLocal());
    final origArrTime = (isNew || existing.arrivalAt == null)
        ? null
        : TimeOfDay.fromDateTime(existing.arrivalAt!.toLocal());

    return resolveLegTimestampsForSave(
      isNew: isNew,
      originChanged: isNew || _origin != existing.originEntryId,
      destinationChanged: isNew || _destination != existing.destinationEntryId,
      departureTimeChanged: !sameTime(_departureTime, origDepTime),
      arrivalTimeChanged: !sameTime(_arrivalTime, origArrTime),
      originDate: _dateOf(_origin),
      destinationDate: _dateOf(_destination),
      departureTime: toClock(_departureTime),
      arrivalTime: toClock(_arrivalTime),
      existingDeparture: existing?.departureAt,
      existingArrival: existing?.arrivalAt,
    );
  }

  @override
  void dispose() {
    _distance.dispose();
    _fare.dispose();
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
    final resolved = _resolveForSave();
    // 前後予定の日付が取れないまま時刻を変更した場合は、既存日時を消さず保存を止める。
    if (resolved.block != null) {
      _snack(context, resolved.block!);
      return;
    }
    final departureAt = resolved.departure;
    final arrivalAt = resolved.arrival;
    if (departureAt != null &&
        arrivalAt != null &&
        arrivalAt.isBefore(departureAt)) {
      _snack(context, '到着は出発より後の時刻にしてください');
      return;
    }
    // 所要は出発/到着時刻から自動計算する（手入力しない, item 3）。両方あるときは
    // 計算値、片方でも欠ければ既存値を保持（黙って消さない）。
    final autoDuration = (departureAt != null && arrivalAt != null)
        ? arrivalAt.difference(departureAt).inMinutes
        : widget.existing?.durationMinutes;
    // 金額は日本円前提（JPY固定）。通貨欄はUIに出さない（item 4）。
    final fareText = _fare.text.trim();
    final fareAmount = fareText.isEmpty ? null : int.tryParse(fareText);
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
      durationMinutes: autoDuration,
      distanceMeters: int.tryParse(_distance.text.trim()),
      fareAmountMinor: fareAmount,
      fareCurrency: fareAmount == null ? null : 'JPY',
      // 経路概要・手動MapsURLは通常UIから外した。既存値は破棄せず保持する。
      routeSummary: widget.existing?.routeSummary,
      googleMapsUrl: widget.existing?.googleMapsUrl,
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
    final duration = _computedDurationMinutes();
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
          onChanged: (v) => setState(() {
            _origin = v;
            _applyEndpointTimeDefaults();
          }),
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
          onChanged: (v) => setState(() {
            _destination = v;
            _applyEndpointTimeDefaults();
          }),
        ),
        ItineraryEnumChips<ItineraryTravelMode>(
          label: '移動手段',
          values: ItineraryTravelMode.values,
          selected: _mode,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _mode = v),
        ),
        const SizedBox(height: 12),
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
        // 所要は自動計算の読み取り表示（手入力しない, item 3）。
        ListTile(
          key: const Key('leg_duration_display'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('所要'),
          trailing: Text(
            duration != null ? '約$duration分' : '未設定',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _distance,
                decoration: const InputDecoration(labelText: '距離（m）'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('leg_fare_field'),
                controller: _fare,
                decoration: const InputDecoration(
                  labelText: '金額（円）',
                  prefixText: '¥ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 経路確認（アプリ内取得）/最新の経路/Google Mapsで開く＋乗換タイムライン。
        // 保存済みの区間を編集中は「この経路を保存」も出せる（planId を渡す）。
        RouteLivePanel(
          origin: widget.options.firstWhereOrNull((o) => o.id == _origin),
          destination:
              widget.options.firstWhereOrNull((o) => o.id == _destination),
          travelMode: _mode,
          existingLeg: widget.existing,
          planId: widget.planId,
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
