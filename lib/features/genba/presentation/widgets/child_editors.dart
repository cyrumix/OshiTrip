import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/images/image_store.dart';
import '../../../../core/providers.dart';
import '../../../../core/time/date_only.dart';
import '../../../../core/widgets/async_view.dart';
import '../../application/genba_actions_controller.dart';
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
  required DateTime eventDate,
  Transport? existing,
}) =>
    _showEditorSheet(
      context,
      _TransportEditor(
        genbaId: genbaId,
        eventDate: eventDate,
        existing: existing,
      ),
    );

Future<void> showLodgingEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  required DateTime eventDate,
  Lodging? existing,
}) =>
    _showEditorSheet(
      context,
      _LodgingEditor(
        genbaId: genbaId,
        eventDate: eventDate,
        existing: existing,
      ),
    );

Future<void> showTodoEditor(
  BuildContext context,
  WidgetRef ref, {
  required String genbaId,
  GenbaTodo? existing,
  // 新規登録時の初期種別（省略時はTodo）。既存編集時は existing.type を使う。
  TodoItemType initialType = TodoItemType.todo,
}) =>
    _showEditorSheet(
      context,
      _TodoEditor(
        genbaId: genbaId,
        existing: existing,
        initialType: initialType,
      ),
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

  /// この編集セッションで import した参照。保存確定時に、最終的に参照されない
  /// もの（差替えで捨てた画像・保存失敗した画像）を孤立させず削除する。
  /// 保存されずに閉じられた場合は dispose で全て削除する（未確定のため）。
  final List<String> _sessionImports = [];

  /// import 実行時の owner（dispose 時の owner スコープ削除に使う）。
  String? _sessionOwnerId;

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
    // 保存されずに閉じられた場合（戻る・シートを閉じる・破棄）、この編集で
    // import した未確定画像を owner スコープで削除する。保存確定時は
    // _reconcileImageFiles が _sessionImports を空にするため、ここでは
    // 保存済み画像（widget.existing?.imageLocalPath）に触れることはない。
    final owner = _sessionOwnerId;
    if (owner != null && _sessionImports.isNotEmpty) {
      final store = ref.read(imageStoreProvider);
      final refs = List<String>.of(_sessionImports);
      _sessionImports.clear();
      for (final r in refs) {
        unawaited(store.deleteRef(owner, r));
      }
    }
    _seat.dispose();
    _entryNumber.dispose();
    _gate.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return;
    try {
      // チケット画像は最も機密度の高い区分としてアプリ管理領域へ耐久保存する
      // （一時パスに依存しない, H-04）。相対参照を DB へ保存する。
      // バックアップ除外に失敗した場合は import が例外を投げ、生成ファイルは
      // 削除済み（確定保存されない）。
      final storedRef = await ref.read(imageStoreProvider).import(
            ownerId: owner,
            category: ImageCategory.ticket,
            source: File(picked.path),
          );
      _sessionOwnerId = owner;
      _sessionImports.add(storedRef);
      if (mounted) setState(() => _imageLocalPath = storedRef);
    } on ImageStorageException catch (e) {
      if (mounted) {
        _showResult(
          context,
          Err(StorageFailure(message: 'チケット画像の保存に失敗しました', cause: e)),
          '',
        );
      }
    } catch (e) {
      if (mounted) {
        _showResult(context, Err(StorageFailure(cause: e)), '');
      }
    }
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
    await _reconcileImageFiles(
      ownerId: ticket.ownerId,
      saved: result.failureOrNull == null,
      keptRef: _imageLocalPath,
      originalRef: widget.existing?.imageLocalPath,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, 'チケットを保存しました');
  }

  /// 保存後に孤立画像を掃除する（差替え・クリア・保存失敗いずれも対象）。
  /// owner スコープの [ImageStore.deleteRef] を使うため他ユーザーのファイルには
  /// 決して触れない。
  Future<void> _reconcileImageFiles({
    required String ownerId,
    required bool saved,
    required String? keptRef,
    required String? originalRef,
  }) async {
    if (ownerId.isEmpty) return;
    final store = ref.read(imageStoreProvider);
    if (saved) {
      // 保存確定: 元画像が差し替え/クリアされたら削除。
      if (originalRef != null && originalRef != keptRef) {
        await store.deleteRef(ownerId, originalRef);
      }
      // 今回 import したが最終的に採用されなかった中間画像を削除。
      for (final r in _sessionImports) {
        if (r != keptRef) await store.deleteRef(ownerId, r);
      }
    } else {
      // 保存失敗: DB は更新されていないので今回の import は全て孤立。
      for (final r in _sessionImports) {
        await store.deleteRef(ownerId, r);
      }
    }
    _sessionImports.clear();
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
  const _TransportEditor({
    required this.genbaId,
    required this.eventDate,
    this.existing,
  });

  final String genbaId;
  final DateTime eventDate;
  final Transport? existing;

  @override
  ConsumerState<_TransportEditor> createState() => _TransportEditorState();
}

class _TransportEditorState extends ConsumerState<_TransportEditor> {
  late TransportDirection _direction;
  TransportMethod? _method;
  late final TextEditingController _methodOther;
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
    _method = t?.method;
    _methodOther = TextEditingController(text: t?.methodOther ?? '');
    _from = TextEditingController(text: t?.fromPlace ?? '');
    _to = TextEditingController(text: t?.toPlace ?? '');
    _reservation = TextEditingController(text: t?.reservationNumber ?? '');
    _url = TextEditingController(text: t?.url ?? '');
    _memo = TextEditingController(text: t?.memo ?? '');
    final defaultDate = DateTime(
      widget.eventDate.year,
      widget.eventDate.month,
      widget.eventDate.day,
    );
    _departAt = t?.departAt?.toLocal() ?? defaultDate;
    _arriveAt = t?.arriveAt?.toLocal() ?? defaultDate;
  }

  @override
  void dispose() {
    _methodOther.dispose();
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
    final isNewOutbound =
        widget.existing == null && _direction == TransportDirection.outbound;
    final transport = Transport(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      direction: _direction,
      method: _method,
      methodOther: _method == TransportMethod.other &&
              _methodOther.text.trim().isNotEmpty
          ? _methodOther.text.trim()
          : null,
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
    if (result.isOk && isNewOutbound && _method != null) {
      final addReturn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('復路も登録しますか？'),
          content:
              const Text('同様の経路で、出発地と到着地を逆にした復路を追加できます。出発時刻・到着時刻は空のまま登録します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('登録しない'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('登録する'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (addReturn == true) {
        final returnTransport = Transport(
          id: const Uuid().v4(),
          genbaId: widget.genbaId,
          ownerId: widget.existing?.ownerId ?? owner,
          direction: TransportDirection.inbound,
          method: _method,
          methodOther: _method == TransportMethod.other &&
                  _methodOther.text.trim().isNotEmpty
              ? _methodOther.text.trim()
              : null,
          fromPlace: _to.text.trim().isEmpty ? null : _to.text.trim(),
          toPlace: _from.text.trim().isEmpty ? null : _from.text.trim(),
          departAt: null,
          arriveAt: null,
          reservationNumber: null,
          url: null,
          memo: null,
          createdAt: now,
          updatedAt: now,
        );
        final returnResult = await ref
            .read(genbaRepositoryProvider)
            .upsertTransport(returnTransport);
        if (!mounted) return;
        if (returnResult.failureOrNull != null) {
          _showResult(context, returnResult, '復路を登録できませんでした');
          return;
        }
      }
    }
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '交通手段',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final method in TransportMethod.values)
              ChoiceChip(
                label: Text(method.label),
                selected: _method == method,
                onSelected: (isSelected) => setState(
                  () => _method = isSelected ? method : null,
                ),
              ),
          ],
        ),
        if (_method == TransportMethod.other) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _methodOther,
            decoration: const InputDecoration(
              labelText: '交通手段（自由入力・任意）',
            ),
          ),
        ],
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
  const _LodgingEditor({
    required this.genbaId,
    required this.eventDate,
    this.existing,
  });

  final String genbaId;
  final DateTime eventDate;
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
    final defaultDate = DateTime(
      widget.eventDate.year,
      widget.eventDate.month,
      widget.eventDate.day,
    );
    _checkin = l?.checkinDate ?? defaultDate;
    _checkout = l?.checkoutDate ?? defaultDate;
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
      initialDate: current ??
          DateTime(
            widget.eventDate.year,
            widget.eventDate.month,
            widget.eventDate.day,
          ),
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
  const _TodoEditor({
    required this.genbaId,
    this.existing,
    this.initialType = TodoItemType.todo,
  });

  final String genbaId;
  final GenbaTodo? existing;
  final TodoItemType initialType;

  @override
  ConsumerState<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends ConsumerState<_TodoEditor> {
  late final TextEditingController _name;
  late final TextEditingController _assignee;
  late final TextEditingController _memo;
  late TodoItemType _type;
  late TodoPriority _priority;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name ?? '');
    _assignee = TextEditingController(text: t?.assignee ?? '');
    _memo = TextEditingController(text: t?.memo ?? '');
    _type = t?.type ?? widget.initialType;
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
          .showSnackBar(const SnackBar(content: Text('名前を入力してください')));
      return;
    }
    final now = ref.read(clockProvider).now().toUtc();
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    // 持ち物は期限・重要度を使わない（§持ち物の入力仕様）。UI側で切替時に
    // リセットしているが、保存時にも二重に防御し、古い値を残さない。
    final isBelonging = _type == TodoItemType.belonging;
    final todo = GenbaTodo(
      id: widget.existing?.id ?? const Uuid().v4(),
      genbaId: widget.genbaId,
      ownerId: widget.existing?.ownerId ?? owner,
      name: _name.text.trim(),
      type: _type,
      dueDate: isBelonging ? null : _due,
      isDone: widget.existing?.isDone ?? false,
      assignee: _assignee.text.trim().isEmpty ? null : _assignee.text.trim(),
      priority: isBelonging ? TodoPriority.normal : _priority,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? 0,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(genbaRepositoryProvider).upsertTodo(todo);
    if (!mounted) return;
    Navigator.of(context).pop();
    _showResult(context, result, '${_type.label}を保存しました');
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    // 種別ラベルは保存中の編集で切り替わっていても、削除対象は既存項目そのもの
    // なので existing.type のラベルで確認する。
    final label = existing.type.label;
    final confirmed = await confirmDangerAction(
      context,
      title: '$labelを削除',
      message: '「${existing.name}」を削除します。この操作は取り消せません。',
    );
    if (!confirmed || !mounted) return;
    // 削除は application 層（GenbaActionsController）へ集約する。完了切替
    // （toggleTodo）と同じ todoKey を使うため、同一項目の完了切替・削除の
    // 連続/競合実行は二重タップ防止で直列化される。
    final failure = await ref
        .read(genbaActionsControllerProvider(widget.genbaId).notifier)
        .deleteTodo(existing);
    if (!mounted) return;
    if (failure == null) {
      // 成功時のみシートを閉じる。失敗時は開いたまま再試行・キャンセルできる
      // ようにし、成功したような表示はしない。
      Navigator.of(context).pop();
      _showResult(context, const Ok(null), '$labelを削除しました');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return _EditorScaffold(
      title: isEdit ? '${_type.label}を編集' : '${_type.label}を追加',
      onSave: _save,
      // 既存項目の編集時のみ削除ボタンを出す（新規追加時は出さない）。
      onDelete: isEdit ? _delete : null,
      children: [
        // 種別（Todo/持ち物）。入力項目・保存処理は種別によらず共通で、
        // ここで選んだ値がそのまま GenbaTodo.type に入るだけ（別実装にしない）。
        _EnumSelector<TodoItemType>(
          label: '種別',
          values: TodoItemType.values,
          selected: _type,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            _type = v;
            // Todo→持ち物では期限・重要度を使わないため、切替時にリセットし
            // 古い値を表示・保存に残さない（§持ち物の入力仕様）。
            if (v == TodoItemType.belonging) {
              _due = null;
              _priority = TodoPriority.normal;
            }
          }),
        ),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: '名前 *'),
          autofocus: widget.existing == null,
        ),
        // 持ち物では期限・重要度の入力欄を出さない（§持ち物の入力仕様）。
        if (_type == TodoItemType.todo) ...[
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
        ],
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
// 共通部品
// ---------------------------------------------------------------------------

/// 子データ編集シートの共通枠。保存ボタンは二重タップで多重送信しないよう、
/// 保存処理中は無効化しローディングを示す（H-07/M-01）。
///
/// [onDelete] を渡すと、ヘッダに削除ボタンを表示する（既存項目の編集時のみ）。
/// 削除中は保存・削除とも無効化して二重実行を防ぐ。
class _EditorScaffold extends StatefulWidget {
  const _EditorScaffold({
    required this.title,
    required this.onSave,
    required this.children,
    this.onDelete,
  });

  final String title;
  final Future<void> Function() onSave;
  final List<Widget> children;

  /// 非null のとき、ヘッダに削除ボタンを表示する。
  final Future<void> Function()? onDelete;

  @override
  State<_EditorScaffold> createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<_EditorScaffold> {
  bool _saving = false;
  bool _deleting = false;

  bool get _busy => _saving || _deleting;

  Future<void> _handleSave() async {
    if (_busy) return; // 二重タップ / 削除中は保存を無視する。
    setState(() => _saving = true);
    try {
      await widget.onSave();
    } finally {
      // onSave が正常終了すると大抵はシート自体が pop されているため、
      // まだ mounted の場合のみ解除する（保存失敗時など、シートが残る場合に
      // ボタンを再度押せるようにする）。
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_busy || widget.onDelete == null) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete!();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // _busy 中はシートを閉じさせない。PopScope はシステム戻る操作／バリア
    // （シート外）タップを止める（どちらも Navigator.maybePop 経由）。一方、
    // DraggableScrollableSheet を最小サイズまでドラッグして閉じる操作は
    // Navigator.pop を直接呼ぶため PopScope では止まらず、ここでは
    // NotificationListener で DraggableScrollableNotification 自体を
    // 握りつぶして親（BottomSheetの自動クローズ処理）へ伝播させない。
    return PopScope(
      canPop: !_busy,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) => _busy,
        child: DraggableScrollableSheet(
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
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (widget.onDelete != null)
                      // 削除は確認ダイアログ→即時削除で完結するため、進行中は
                      // ボタンを無効化するだけにする（確認中に回るスピナーは出さない）。
                      IconButton(
                        onPressed: _busy ? null : _handleDelete,
                        tooltip: '削除',
                        color: Theme.of(context).colorScheme.error,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
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
                  children: widget.children,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: '保存中',
                              ),
                            )
                          : const Text('保存する'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
