import 'package:flutter/material.dart';

import '../../../app/design_system/design_system.dart';
import '../../genba/domain/genba.dart';
import '../../sharing/data/shared_genba_fetcher.dart';

/// 共有現場（editor）専用の小さな編集ダイアログ群（D-246）。
///
/// owner 用の詳細編集UI（Google 連携・画像アップロード等）は共有現場で誤爆すると
/// 危険なため流用せず、apply_shared_mutation に渡す主要フィールドだけを手入力する
/// 共有専用の軽量ダイアログとして分離する。各ダイアログは Draft を返し（キャンセルは
/// null）、payload 生成と RPC 呼び出しは呼び出し側（画面）が行う。

// ---- チケット取得/支払/発券ステータスの選択肢（check 制約に一致） ----------
const ticketAcquisitionOptions = <String, String>{
  'not_applied': '未申込',
  'applied': '申込中',
  'won': '当選',
  'lost': '落選',
  'acquired': '取得済',
};
const ticketPaymentOptions = <String, String>{
  'unpaid': '未払い',
  'paid': '支払済',
  'not_required': '支払不要',
};
const ticketIssuanceOptions = <String, String>{
  'not_issued': '未発券',
  'issued': '発券済',
  'digital': '電子チケット',
};

// ===========================================================================
// 移動区間（itinerary_legs）
// ===========================================================================
class LegDraft {
  const LegDraft({
    required this.originEntryId,
    required this.destinationEntryId,
    required this.travelMode,
    this.durationMinutes,
  });
  final String originEntryId;
  final String destinationEntryId;
  final String travelMode;
  final int? durationMinutes;
}

Future<LegDraft?> showLegEditor(
  BuildContext context, {
  required List<SharedEntry> entries,
  SharedLeg? initial,
}) =>
    showDialog<LegDraft>(
      context: context,
      builder: (_) => _LegEditorDialog(entries: entries, initial: initial),
    );

class _LegEditorDialog extends StatefulWidget {
  const _LegEditorDialog({required this.entries, this.initial});
  final List<SharedEntry> entries;
  final SharedLeg? initial;

  @override
  State<_LegEditorDialog> createState() => _LegEditorDialogState();
}

class _LegEditorDialogState extends State<_LegEditorDialog> {
  late String? _origin = widget.initial?.originEntryId;
  late String? _destination = widget.initial?.destinationEntryId;
  late String _mode = widget.initial?.travelMode ?? 'transit';
  late final TextEditingController _duration = TextEditingController(
    text: widget.initial?.durationMinutes?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final entryItems = [
      for (final e in widget.entries)
        DropdownMenuItem(value: e.id, child: Text(e.label)),
    ];
    return AlertDialog(
      title: Text(isEdit ? '移動区間を編集' : '移動区間を追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('leg_origin'),
              initialValue:
                  widget.entries.any((e) => e.id == _origin) ? _origin : null,
              decoration: const InputDecoration(labelText: '出発（旅程項目）'),
              items: entryItems,
              onChanged: (v) => setState(() => _origin = v),
            ),
            const SizedBox(height: AppSpace.sm),
            DropdownButtonFormField<String>(
              key: const Key('leg_destination'),
              initialValue: widget.entries.any((e) => e.id == _destination)
                  ? _destination
                  : null,
              decoration: const InputDecoration(labelText: '到着（旅程項目）'),
              items: entryItems,
              onChanged: (v) => setState(() => _destination = v),
            ),
            const SizedBox(height: AppSpace.sm),
            DropdownButtonFormField<String>(
              key: const Key('leg_mode'),
              initialValue: legTravelModes.containsKey(_mode) ? _mode : 'other',
              decoration: const InputDecoration(labelText: '交通手段'),
              items: [
                for (final e in legTravelModes.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _mode = v ?? _mode),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              key: const Key('leg_duration'),
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '所要（分・任意）',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('leg_save'),
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _submit() {
    if (_origin == null || _destination == null) {
      setState(() => _error = '出発と到着を選んでください');
      return;
    }
    if (_origin == _destination) {
      setState(() => _error = '出発と到着は別の項目にしてください');
      return;
    }
    final dur = int.tryParse(_duration.text.trim());
    Navigator.of(context).pop(
      LegDraft(
        originEntryId: _origin!,
        destinationEntryId: _destination!,
        travelMode: _mode,
        durationMinutes: (dur != null && dur >= 0 && dur <= 1440) ? dur : null,
      ),
    );
  }
}

// ===========================================================================
// チケット（tickets）
// ===========================================================================
class TicketDraft {
  const TicketDraft({
    required this.seat,
    required this.gate,
    required this.entryNumber,
    required this.url,
    required this.memo,
    required this.acquisitionStatus,
    required this.paymentStatus,
    required this.issuanceStatus,
  });
  final String seat;
  final String gate;
  final String entryNumber;
  final String url;
  final String memo;
  final String acquisitionStatus;
  final String paymentStatus;
  final String issuanceStatus;
}

Future<TicketDraft?> showTicketEditor(
  BuildContext context, {
  SharedTicket? initial,
}) =>
    showDialog<TicketDraft>(
      context: context,
      builder: (_) => _TicketEditorDialog(initial: initial),
    );

class _TicketEditorDialog extends StatefulWidget {
  const _TicketEditorDialog({this.initial});
  final SharedTicket? initial;

  @override
  State<_TicketEditorDialog> createState() => _TicketEditorDialogState();
}

class _TicketEditorDialogState extends State<_TicketEditorDialog> {
  late final _seat = TextEditingController(text: widget.initial?.seat ?? '');
  late final _gate = TextEditingController(text: widget.initial?.gate ?? '');
  late final _entry =
      TextEditingController(text: widget.initial?.entryNumber ?? '');
  late final _url = TextEditingController(text: widget.initial?.url ?? '');
  late final _memo = TextEditingController(text: widget.initial?.memo ?? '');
  late String _acq = widget.initial?.acquisitionStatus ?? 'not_applied';
  late String _pay = widget.initial?.paymentStatus ?? 'unpaid';
  late String _iss = widget.initial?.issuanceStatus ?? 'not_issued';

  @override
  void dispose() {
    _seat.dispose();
    _gate.dispose();
    _entry.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? 'チケットを追加' : 'チケットを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusDropdown(
                const Key('ticket_acq'),
                '取得状況',
                ticketAcquisitionOptions,
                _acq,
                (v) => setState(() => _acq = v),
              ),
              const SizedBox(height: AppSpace.sm),
              _statusDropdown(
                const Key('ticket_pay'),
                '支払',
                ticketPaymentOptions,
                _pay,
                (v) => setState(() => _pay = v),
              ),
              const SizedBox(height: AppSpace.sm),
              _statusDropdown(
                const Key('ticket_iss'),
                '発券',
                ticketIssuanceOptions,
                _iss,
                (v) => setState(() => _iss = v),
              ),
              _field(const Key('ticket_seat'), _seat, '座席'),
              _field(const Key('ticket_gate'), _gate, 'ゲート'),
              _field(const Key('ticket_entry'), _entry, '整理番号'),
              _field(const Key('ticket_url'), _url, 'URL'),
              _field(const Key('ticket_memo'), _memo, 'メモ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('ticket_save'),
            onPressed: () => Navigator.of(context).pop(
              TicketDraft(
                seat: _seat.text.trim(),
                gate: _gate.text.trim(),
                entryNumber: _entry.text.trim(),
                url: _url.text.trim(),
                memo: _memo.text.trim(),
                acquisitionStatus: _acq,
                paymentStatus: _pay,
                issuanceStatus: _iss,
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      );
}

// ===========================================================================
// 交通（transports）
// ===========================================================================
class TransportDraft {
  const TransportDraft({
    required this.direction,
    required this.method,
    required this.methodOther,
    required this.fromPlace,
    required this.toPlace,
    required this.reservationNumber,
    required this.url,
    required this.memo,
  });
  final String direction;
  final String? method;
  final String methodOther;
  final String fromPlace;
  final String toPlace;
  final String reservationNumber;
  final String url;
  final String memo;
}

Future<TransportDraft?> showTransportEditor(
  BuildContext context, {
  SharedTransport? initial,
}) =>
    showDialog<TransportDraft>(
      context: context,
      builder: (_) => _TransportEditorDialog(initial: initial),
    );

class _TransportEditorDialog extends StatefulWidget {
  const _TransportEditorDialog({this.initial});
  final SharedTransport? initial;

  @override
  State<_TransportEditorDialog> createState() => _TransportEditorDialogState();
}

class _TransportEditorDialogState extends State<_TransportEditorDialog> {
  late String _direction = widget.initial?.direction ?? 'outbound';
  late String? _method = widget.initial?.method;
  late final _methodOther =
      TextEditingController(text: widget.initial?.methodOther ?? '');
  late final _from =
      TextEditingController(text: widget.initial?.fromPlace ?? '');
  late final _to = TextEditingController(text: widget.initial?.toPlace ?? '');
  late final _reservation =
      TextEditingController(text: widget.initial?.reservationNumber ?? '');
  late final _url = TextEditingController(text: widget.initial?.url ?? '');
  late final _memo = TextEditingController(text: widget.initial?.memo ?? '');

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

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? '交通を追加' : '交通を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusDropdown(
                const Key('transport_direction'),
                '往復',
                const {'outbound': '往路', 'inbound': '復路'},
                _direction,
                (v) => setState(() => _direction = v),
              ),
              const SizedBox(height: AppSpace.sm),
              DropdownButtonFormField<String>(
                key: const Key('transport_method'),
                initialValue: _method,
                decoration: const InputDecoration(labelText: '交通手段'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('未設定')),
                  for (final m in TransportMethod.values)
                    DropdownMenuItem(value: m.code, child: Text(m.label)),
                ],
                onChanged: (v) => setState(() => _method = v),
              ),
              _field(
                const Key('transport_method_other'),
                _methodOther,
                '交通手段の補足（任意）',
              ),
              _field(const Key('transport_from'), _from, '出発地'),
              _field(const Key('transport_to'), _to, '到着地'),
              _field(
                const Key('transport_reservation'),
                _reservation,
                '予約番号',
              ),
              _field(const Key('transport_url'), _url, 'URL'),
              _field(const Key('transport_memo'), _memo, 'メモ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('transport_save'),
            onPressed: () => Navigator.of(context).pop(
              TransportDraft(
                direction: _direction,
                method: _method,
                methodOther: _methodOther.text.trim(),
                fromPlace: _from.text.trim(),
                toPlace: _to.text.trim(),
                reservationNumber: _reservation.text.trim(),
                url: _url.text.trim(),
                memo: _memo.text.trim(),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      );
}

// ===========================================================================
// 宿泊（lodgings）
// ===========================================================================
class LodgingDraft {
  const LodgingDraft({
    required this.name,
    required this.checkinDate,
    required this.checkoutDate,
    required this.address,
    required this.reservationNumber,
    required this.url,
    required this.memo,
  });
  final String name;
  final DateTime? checkinDate;
  final DateTime? checkoutDate;
  final String address;
  final String reservationNumber;
  final String url;
  final String memo;
}

Future<LodgingDraft?> showLodgingEditor(
  BuildContext context, {
  SharedLodging? initial,
}) =>
    showDialog<LodgingDraft>(
      context: context,
      builder: (_) => _LodgingEditorDialog(initial: initial),
    );

class _LodgingEditorDialog extends StatefulWidget {
  const _LodgingEditorDialog({this.initial});
  final SharedLodging? initial;

  @override
  State<_LodgingEditorDialog> createState() => _LodgingEditorDialogState();
}

class _LodgingEditorDialogState extends State<_LodgingEditorDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _address =
      TextEditingController(text: widget.initial?.address ?? '');
  late final _reservation =
      TextEditingController(text: widget.initial?.reservationNumber ?? '');
  late final _url = TextEditingController(text: widget.initial?.url ?? '');
  late final _memo = TextEditingController(text: widget.initial?.memo ?? '');
  late DateTime? _checkin = widget.initial?.checkinDate;
  late DateTime? _checkout = widget.initial?.checkoutDate;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _reservation.dispose();
    _url.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pick(bool checkin) async {
    final base = (checkin ? _checkin : _checkout) ?? DateTime(2026, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
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

  String _fmt(DateTime? d) => d == null
      ? '未設定'
      : '${d.year}.${d.month.toString().padLeft(2, '0')}.'
          '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? '宿泊を追加' : '宿泊を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(const Key('lodging_name'), _name, '宿泊先名'),
              ListTile(
                key: const Key('lodging_checkin'),
                contentPadding: EdgeInsets.zero,
                title: const Text('チェックイン'),
                subtitle: Text(_fmt(_checkin)),
                trailing: const Icon(Icons.event_outlined),
                onTap: () => _pick(true),
              ),
              ListTile(
                key: const Key('lodging_checkout'),
                contentPadding: EdgeInsets.zero,
                title: const Text('チェックアウト'),
                subtitle: Text(_fmt(_checkout)),
                trailing: const Icon(Icons.event_outlined),
                onTap: () => _pick(false),
              ),
              _field(const Key('lodging_address'), _address, '住所'),
              _field(
                const Key('lodging_reservation'),
                _reservation,
                '予約番号',
              ),
              _field(const Key('lodging_url'), _url, 'URL'),
              _field(const Key('lodging_memo'), _memo, 'メモ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('lodging_save'),
            onPressed: () => Navigator.of(context).pop(
              LodgingDraft(
                name: _name.text.trim(),
                checkinDate: _checkin,
                checkoutDate: _checkout,
                address: _address.text.trim(),
                reservationNumber: _reservation.text.trim(),
                url: _url.text.trim(),
                memo: _memo.text.trim(),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      );
}

// ===========================================================================
// グッズ（goods_items）
// ===========================================================================
class GoodsDraft {
  const GoodsDraft({
    required this.name,
    required this.price,
    required this.quantity,
    required this.memo,
  });
  final String name;
  final int? price;
  final int quantity;
  final String memo;
}

Future<GoodsDraft?> showGoodsEditor(
  BuildContext context, {
  SharedGoods? initial,
}) =>
    showDialog<GoodsDraft>(
      context: context,
      builder: (_) => _GoodsEditorDialog(initial: initial),
    );

class _GoodsEditorDialog extends StatefulWidget {
  const _GoodsEditorDialog({this.initial});
  final SharedGoods? initial;

  @override
  State<_GoodsEditorDialog> createState() => _GoodsEditorDialogState();
}

class _GoodsEditorDialogState extends State<_GoodsEditorDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _price = TextEditingController(
    text: widget.initial?.price?.toString() ?? '',
  );
  late final _quantity = TextEditingController(
    text: (widget.initial?.quantity ?? 1).toString(),
  );
  late final _memo = TextEditingController(text: widget.initial?.memo ?? '');

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? 'グッズを追加' : 'グッズを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(const Key('goods_name'), _name, '名前'),
              _field(
                const Key('goods_price'),
                _price,
                '金額（円・任意）',
                number: true,
              ),
              _field(
                const Key('goods_quantity'),
                _quantity,
                '個数',
                number: true,
              ),
              _field(const Key('goods_memo'), _memo, 'メモ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('goods_save'),
            onPressed: () {
              final name = _name.text.trim();
              if (name.isEmpty) return;
              final qty = int.tryParse(_quantity.text.trim());
              Navigator.of(context).pop(
                GoodsDraft(
                  name: name,
                  price: int.tryParse(_price.text.trim()),
                  quantity: (qty != null && qty > 0) ? qty : 1,
                  memo: _memo.text.trim(),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      );
}

// ===========================================================================
// 行った場所 / 食べたもの（visited_places・category は呼び出し側が指定）
// ===========================================================================
class PlaceDraft {
  const PlaceDraft({required this.name, required this.memo});
  final String name;
  final String memo;
}

Future<PlaceDraft?> showPlaceEditor(
  BuildContext context, {
  required bool isFood,
  SharedVisitedPlace? initial,
}) =>
    showDialog<PlaceDraft>(
      context: context,
      builder: (_) => _PlaceEditorDialog(isFood: isFood, initial: initial),
    );

class _PlaceEditorDialog extends StatefulWidget {
  const _PlaceEditorDialog({required this.isFood, this.initial});
  final bool isFood;
  final SharedVisitedPlace? initial;

  @override
  State<_PlaceEditorDialog> createState() => _PlaceEditorDialogState();
}

class _PlaceEditorDialogState extends State<_PlaceEditorDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _memo = TextEditingController(text: widget.initial?.memo ?? '');

  @override
  void dispose() {
    _name.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noun = widget.isFood ? '食べたもの' : '行った場所';
    return AlertDialog(
      title: Text('$noun${widget.initial == null ? 'を追加' : 'を編集'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(const Key('place_name'), _name, '名前'),
            _field(const Key('place_memo'), _memo, 'メモ'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('place_save'),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              PlaceDraft(name: name, memo: _memo.text.trim()),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// ===========================================================================
// セットリスト（setlist_items）
// ===========================================================================
class SetlistDraft {
  const SetlistDraft({required this.songTitle, required this.note});
  final String songTitle;
  final String note;
}

Future<SetlistDraft?> showSetlistEditor(
  BuildContext context, {
  SharedSetlistItem? initial,
}) =>
    showDialog<SetlistDraft>(
      context: context,
      builder: (_) => _SetlistEditorDialog(initial: initial),
    );

class _SetlistEditorDialog extends StatefulWidget {
  const _SetlistEditorDialog({this.initial});
  final SharedSetlistItem? initial;

  @override
  State<_SetlistEditorDialog> createState() => _SetlistEditorDialogState();
}

class _SetlistEditorDialogState extends State<_SetlistEditorDialog> {
  late final _song =
      TextEditingController(text: widget.initial?.songTitle ?? '');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');

  @override
  void dispose() {
    _song.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? '曲を追加' : '曲を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(const Key('setlist_song'), _song, '曲名'),
              _field(const Key('setlist_note'), _note, 'メモ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('setlist_save'),
            onPressed: () {
              final song = _song.text.trim();
              if (song.isEmpty) return;
              Navigator.of(context).pop(
                SetlistDraft(songTitle: song, note: _note.text.trim()),
              );
            },
            child: const Text('保存'),
          ),
        ],
      );
}

// ===========================================================================
// 写真キャプション（memory_photos・メタデータのみ／画像本体は次増分）
// ===========================================================================
class PhotoCaptionDraft {
  const PhotoCaptionDraft({required this.caption, required this.isCover});
  final String caption;
  final bool isCover;
}

Future<PhotoCaptionDraft?> showPhotoCaptionEditor(
  BuildContext context, {
  required SharedPhoto initial,
}) =>
    showDialog<PhotoCaptionDraft>(
      context: context,
      builder: (_) => _PhotoCaptionDialog(initial: initial),
    );

class _PhotoCaptionDialog extends StatefulWidget {
  const _PhotoCaptionDialog({required this.initial});
  final SharedPhoto initial;

  @override
  State<_PhotoCaptionDialog> createState() => _PhotoCaptionDialogState();
}

class _PhotoCaptionDialogState extends State<_PhotoCaptionDialog> {
  late final _caption = TextEditingController(text: widget.initial.caption);
  late bool _isCover = widget.initial.isCover;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('写真の情報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(const Key('photo_caption'), _caption, 'キャプション'),
            SwitchListTile(
              key: const Key('photo_cover'),
              contentPadding: EdgeInsets.zero,
              title: const Text('カバー写真にする'),
              value: _isCover,
              onChanged: (v) => setState(() => _isCover = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('photo_save'),
            onPressed: () => Navigator.of(context).pop(
              PhotoCaptionDraft(
                caption: _caption.text.trim(),
                isCover: _isCover,
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      );
}

// ---- 共通の小物 -----------------------------------------------------------
Widget _field(
  Key key,
  TextEditingController controller,
  String label, {
  bool number = false,
}) =>
    Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label),
      ),
    );

Widget _statusDropdown(
  Key key,
  String label,
  Map<String, String> options,
  String value,
  ValueChanged<String> onChanged,
) =>
    DropdownButtonFormField<String>(
      key: key,
      initialValue: options.containsKey(value) ? value : options.keys.first,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => onChanged(v ?? value),
    );
