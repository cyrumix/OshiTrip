import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/result.dart';
import '../../../../core/providers.dart';
import '../../../../core/time/date_only.dart';
import '../../domain/genba.dart';

/// 現場詳細の子データ編集ボトムシート群（§7.3〜§7.7）。
///
/// 各編集は保存時にローカル反映 → Outbox 同期される。
Future<void> showTicketEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  Ticket? existing,
}) =>
    _showEditorSheet(
      context,
      _TicketEditor(genbaId: genbaId, existing: existing),
    );

Future<void> showTransportEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  Transport? existing,
}) =>
    _showEditorSheet(
      context,
      _TransportEditor(genbaId: genbaId, existing: existing),
    );

Future<void> showLodgingEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  Lodging? existing,
}) =>
    _showEditorSheet(
      context,
      _LodgingEditor(genbaId: genbaId, existing: existing),
    );

Future<void> showTodoEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  GenbaTodo? existing,
}) =>
    _showEditorSheet(
      context,
      _TodoEditor(genbaId: genbaId, existing: existing),
    );

Future<void> showMemoEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  required MemoCategory category,
  GenbaMemo? existing,
}) =>
    _showEditorSheet(
      context,
      _MemoEditor(genbaId: genbaId, category: category, existing: existing),
    );

Future<void> _showEditorSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    ),
  );
}

void _showResult(BuildContext context, Result<void> result, String okMessage) {
  final message = result.when(ok: (_) => okMessage, err: (f) => f.message);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------------------------------------------------------
// チケット（§7.3）
// ---------------------------------------------------------------------------

class _TicketEditor extends ConsumerStatefulWidget {
  const _TicketEditor({required this.genbaId, this.existing});

  final String genbaId;
  final Ticket? existing;

  @override
  ConsumerState<_TicketEditor> createState() => _TicketEditorState();
}

class _TicketEditorState extends ConsumerState<_TicketEditor> {
  late TicketAcquisition _acquisition;
  late TicketPayment _payment;
  late TicketIssuance _issuance;
  late final TextEditingController _seat;
  late final TextEditingController _entryNumber;
  late final TextEditingController _gate;
  late final TextEditingController _url;
  late final TextEditingController _memo;
  String? _imageLocalPath;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _acquisition = t?.acquisitionStatus ?? TicketAcquisition.notApplied;
    _payment = t?.paymentStatus ?? TicketPayment.unpaid;
    _issuance = t?.issuanceStatus ?? TicketIssuance.notIssued;
    _seat = TextEditingController(text: t?.seat ?? '');
    _entryNumber = TextEditingController(text: t?.entryNumber ?? '');
    _gate = TextEditingController(text: t?.gate ?? '');
    _url = TextEditingController(text: t?.url ?? '');
    _memo = TextEditingController(text: t?.memo ?? '');
    _imageLocalPath = t?.imageLocalPath;
  }

  @override
  void dispose() {
    _seat.dispose();
    _entryNumber.dispose();
    _gate.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageLocalPath = picked.path);
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final ticket = Ticket(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      acquisitionStatus: _acquisition,
      paymentStatus: _payment,
      issuanceStatus: _issuance,
      seat: _seat.text.trim().isEmpty ? null : _seat.text.trim(),
      entryNumber:
          _entryNumber.text.trim().isEmpty ? null : _entryNumber.text.trim(),
      gate: _gate.text.trim().isEmpty ? null : _gate.text.trim(),
      url: _url.text.trim().isEmpty ? null : _url.text.trim(),
      imagePath: widget.existing?.imagePath,
      imageLocalPath: _imageLocalPath,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(genbaRepositoryProvider).upsertTicket(ticket);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, 'チケットを保存しました');
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.existing == null ? 'チケットを追加' : 'チケットを編集',
      onSave: _save,
      children: [
        _EnumSelector<TicketAcquisition>(
          label: '取得状況',
          values: TicketAcquisition.values,
          selected: _acquisition,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _acquisition = v),
        ),
        _EnumSelector<TicketPayment>(
          label: '支払状況',
          values: TicketPayment.values,
          selected: _payment,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _payment = v),
        ),
        _EnumSelector<TicketIssuance>(
          label: '発券状況',
          values: TicketIssuance.values,
          selected: _issuance,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _issuance = v),
        ),
        TextField(
          controller: _seat,
          decoration: const InputDecoration(labelText: '座席'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _entryNumber,
          decoration: const InputDecoration(labelText: '整理番号'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gate,
          decoration: const InputDecoration(labelText: '入場口'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
            labelText: 'チケットURL（外部サイト）',
            helperText: '保存画像とは別に、外部チケットサービスへのリンクとして扱われます',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _imageLocalPath == null ? 'チケット画像: 未設定' : 'チケット画像: 端末に保存済み',
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
                onPressed: () => setState(() => _imageLocalPath = null),
                tooltip: 'チケット画像を外す',
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        Text(
          'チケット画像には座席などのセンシティブ情報が含まれる場合があります。共有時は既定で共有されません。',
          style: Theme.of(context).textTheme.bodySmall,
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

// ---------------------------------------------------------------------------
// 交通（§7.4）
// ---------------------------------------------------------------------------

class _TransportEditor extends ConsumerStatefulWidget {
  const _TransportEditor({required this.genbaId, this.existing});

  final String genbaId;
  final Transport? existing;

  @override
  ConsumerState<_TransportEditor> createState() => _TransportEditorState();
}

class _TransportEditorState extends ConsumerState<_TransportEditor> {
  late TransportDirection _direction;
  late final TextEditingController _method;
  late final TextEditingController _from;
  late final TextEditingController _to;
  late final TextEditingController _reservation;
  late final TextEditingController _url;
  late final TextEditingController _memo;
  DateTime? _departAt;
  DateTime? _arriveAt;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _direction = t?.direction ?? TransportDirection.outbound;
    _method = TextEditingController(text: t?.method ?? '');
    _from = TextEditingController(text: t?.fromPlace ?? '');
    _to = TextEditingController(text: t?.toPlace ?? '');
    _reservation = TextEditingController(text: t?.reservationNumber ?? '');
    _url = TextEditingController(text: t?.url ?? '');
    _memo = TextEditingController(text: t?.memo ?? '');
    _departAt = t?.departAt?.toLocal();
    _arriveAt = t?.arriveAt?.toLocal();
  }

  @override
  void dispose() {
    _method.dispose();
    _from.dispose();
    _to.dispose();
    _reservation.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? ref.read(clockProvider).now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return current;
    final time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (time == null) return current;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final transport = Transport(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      direction: _direction,
      method: _method.text.trim().isEmpty ? null : _method.text.trim(),
      fromPlace: _from.text.trim().isEmpty ? null : _from.text.trim(),
      toPlace: _to.text.trim().isEmpty ? null : _to.text.trim(),
      departAt: _departAt,
      arriveAt: _arriveAt,
      reservationNumber:
          _reservation.text.trim().isEmpty ? null : _reservation.text.trim(),
      url: _url.text.trim().isEmpty ? null : _url.text.trim(),
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final result =
        await ref.read(genbaRepositoryProvider).upsertTransport(transport);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, '交通を保存しました');
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.existing == null ? '交通を追加' : '交通を編集',
      onSave: _save,
      children: [
        SegmentedButton<TransportDirection>(
          segments: [
            for (final d in TransportDirection.values)
              ButtonSegment(value: d, label: Text(d.label)),
          ],
          selected: {_direction},
          onSelectionChanged: (s) => setState(() => _direction = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _method,
          decoration: const InputDecoration(labelText: '交通手段（新幹線・飛行機・バス など）'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _from,
                decoration: const InputDecoration(labelText: '出発地'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward),
            ),
            Expanded(
              child: TextField(
                controller: _to,
                decoration: const InputDecoration(labelText: '到着地'),
              ),
            ),
          ],
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('出発時刻'),
          subtitle: Text(_departAt == null ? '未設定' : _formatDt(_departAt!)),
          trailing: const Icon(Icons.schedule),
          onTap: () async {
            final picked = await _pickDateTime(_departAt);
            setState(() => _departAt = picked);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('到着時刻'),
          subtitle: Text(_arriveAt == null ? '未設定' : _formatDt(_arriveAt!)),
          trailing: const Icon(Icons.schedule),
          onTap: () async {
            final picked = await _pickDateTime(_arriveAt);
            setState(() => _arriveAt = picked);
          },
        ),
        TextField(
          controller: _reservation,
          decoration: const InputDecoration(labelText: '予約番号'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          decoration: const InputDecoration(labelText: '予約URL'),
          keyboardType: TextInputType.url,
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

  String _formatDt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// 宿泊（§7.5）
// ---------------------------------------------------------------------------

class _LodgingEditor extends ConsumerStatefulWidget {
  const _LodgingEditor({required this.genbaId, this.existing});

  final String genbaId;
  final Lodging? existing;

  @override
  ConsumerState<_LodgingEditor> createState() => _LodgingEditorState();
}

class _LodgingEditorState extends ConsumerState<_LodgingEditor> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _reservation;
  late final TextEditingController _url;
  late final TextEditingController _memo;
  DateTime? _checkin;
  DateTime? _checkout;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    _name = TextEditingController(text: l?.name ?? '');
    _address = TextEditingController(text: l?.address ?? '');
    _reservation = TextEditingController(text: l?.reservationNumber ?? '');
    _url = TextEditingController(text: l?.url ?? '');
    _memo = TextEditingController(text: l?.memo ?? '');
    _checkin = l?.checkinDate;
    _checkout = l?.checkoutDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _reservation.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final lodging = Lodging(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      name: _name.text.trim().isEmpty ? null : _name.text.trim(),
      checkinDate: _checkin,
      checkoutDate: _checkout,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      reservationNumber:
          _reservation.text.trim().isEmpty ? null : _reservation.text.trim(),
      url: _url.text.trim().isEmpty ? null : _url.text.trim(),
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final result =
        await ref.read(genbaRepositoryProvider).upsertLodging(lodging);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, '宿泊を保存しました');
  }

  Future<void> _pickDate(bool checkin) async {
    final current = checkin ? _checkin : _checkout;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? ref.read(clockProvider).now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (checkin) {
        _checkin = picked;
      } else {
        _checkout = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.existing == null ? '宿泊を追加' : '宿泊を編集',
      onSave: _save,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: '宿泊先名'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('チェックイン'),
          subtitle: Text(_checkin == null ? '未設定' : formatDateOnly(_checkin!)),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('チェックアウト'),
          subtitle:
              Text(_checkout == null ? '未設定' : formatDateOnly(_checkout!)),
          trailing: const Icon(Icons.calendar_month),
          onTap: () => _pickDate(false),
        ),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: '住所'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reservation,
          decoration: const InputDecoration(labelText: '予約番号'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          decoration: const InputDecoration(labelText: '予約URL'),
          keyboardType: TextInputType.url,
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

// ---------------------------------------------------------------------------
// Todo（§7.6）
// ---------------------------------------------------------------------------

class _TodoEditor extends ConsumerStatefulWidget {
  const _TodoEditor({required this.genbaId, this.existing});

  final String genbaId;
  final GenbaTodo? existing;

  @override
  ConsumerState<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends ConsumerState<_TodoEditor> {
  late final TextEditingController _name;
  late final TextEditingController _assignee;
  late final TextEditingController _memo;
  late TodoPriority _priority;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name ?? '');
    _assignee = TextEditingController(text: t?.assignee ?? '');
    _memo = TextEditingController(text: t?.memo ?? '');
    _priority = t?.priority ?? TodoPriority.normal;
    _due = t?.dueDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _assignee.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Todo名を入力してください')));
      return;
    }
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final todo = GenbaTodo(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      name: _name.text.trim(),
      dueDate: _due,
      isDone: widget.existing?.isDone ?? false,
      assignee: _assignee.text.trim().isEmpty ? null : _assignee.text.trim(),
      priority: _priority,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? 0,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(genbaRepositoryProvider).upsertTodo(todo);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, 'Todoを保存しました');
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.existing == null ? 'Todoを追加' : 'Todoを編集',
      onSave: _save,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Todo名 *'),
          autofocus: widget.existing == null,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('期限'),
          subtitle: Text(_due == null ? '未設定' : formatDateOnly(_due!)),
          trailing: const Icon(Icons.calendar_month),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _due ?? ref.read(clockProvider).now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _due = picked);
          },
        ),
        _EnumSelector<TodoPriority>(
          label: '重要度',
          values: TodoPriority.values,
          selected: _priority,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => _priority = v),
        ),
        TextField(
          controller: _assignee,
          decoration: const InputDecoration(labelText: '担当'),
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

// ---------------------------------------------------------------------------
// メモ（§7.7）
// ---------------------------------------------------------------------------

class _MemoEditor extends ConsumerStatefulWidget {
  const _MemoEditor({
    required this.genbaId,
    required this.category,
    this.existing,
  });

  final String genbaId;
  final MemoCategory category;
  final GenbaMemo? existing;

  @override
  ConsumerState<_MemoEditor> createState() => _MemoEditorState();
}

class _MemoEditorState extends ConsumerState<_MemoEditor> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final memo = GenbaMemo(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      category: widget.category,
      body: _body.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(genbaRepositoryProvider).upsertMemo(memo);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, 'メモを保存しました');
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: '${widget.category.label}メモ',
      onSave: _save,
      children: [
        TextField(
          controller: _body,
          decoration: InputDecoration(
            labelText: widget.category.label,
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          autofocus: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 共通部品
// ---------------------------------------------------------------------------

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.onSave,
    required this.children,
  });

  final String title;
  final Future<void> Function() onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
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
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '閉じる',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: children,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSave,
                  child: const Text('保存する'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnumSelector<T> extends StatelessWidget {
  const _EnumSelector({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final void Function(T value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: value == selected,
                  onSelected: (_) => onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
