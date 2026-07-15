import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../../genba/domain/genba.dart';

/// itinerary_legs.travel_mode の安定コード→日本語ラベル（共有UIの選択肢・表示）。
const legTravelModes = <String, String>{
  'walking': '徒歩',
  'transit': '電車・バス',
  'driving': '車',
  'bicycling': '自転車',
  'taxi': 'タクシー',
  'flight': '飛行機',
  'other': 'その他',
};

String legTravelModeLabel(String? code) => legTravelModes[code] ?? '移動';

/// 共有現場の計画スポット（editor 編集の CAS 用に id/planId/version を持つ, D-245）。
class SharedSpot {
  const SharedSpot({
    required this.id,
    required this.planId,
    required this.name,
    required this.category,
    this.version = 1,
  });
  final String id;
  final String planId;
  final String name;
  final String category;
  final int version;
}

/// 共有現場の旅程項目（移動区間の端点=origin/destination として選ばせるための
/// 最小情報, D-246）。表示用ラベルと id のみを持つ。
class SharedEntry {
  const SharedEntry({required this.id, required this.label});
  final String id;
  final String label;
}

/// 共有現場の移動区間（editor が追加/編集/削除できる, D-246）。端点は entries を
/// 参照する（[originEntryId]/[destinationEntryId]）。
class SharedLeg {
  const SharedLeg({
    required this.id,
    required this.planId,
    required this.label,
    required this.originEntryId,
    required this.destinationEntryId,
    required this.travelMode,
    this.durationMinutes,
    this.version = 1,
  });
  final String id;
  final String planId;
  final String label;
  final String originEntryId;
  final String destinationEntryId;

  /// 交通手段の安定コード（walking/transit/driving/... itinerary_legs.travel_mode）。
  final String travelMode;
  final int? durationMinutes;
  final int version;
}

/// 共有現場のチケット（editor 編集用の主要フィールド＋版, D-246）。
class SharedTicket {
  const SharedTicket({
    required this.id,
    this.version = 1,
    this.seat = '',
    this.gate = '',
    this.entryNumber = '',
    this.url = '',
    this.memo = '',
    this.acquisitionStatus = 'not_applied',
    this.paymentStatus = 'unpaid',
    this.issuanceStatus = 'not_issued',
  });
  final String id;
  final int version;
  final String seat;
  final String gate;
  final String entryNumber;
  final String url;
  final String memo;
  final String acquisitionStatus;
  final String paymentStatus;
  final String issuanceStatus;
}

/// 共有現場の交通（editor 編集用, D-246）。
class SharedTransport {
  const SharedTransport({
    required this.id,
    this.version = 1,
    this.direction = 'outbound',
    this.method,
    this.methodOther = '',
    this.fromPlace = '',
    this.toPlace = '',
    this.reservationNumber = '',
    this.url = '',
    this.memo = '',
  });
  final String id;
  final int version;
  final String direction;

  /// 交通手段コード（null=未設定）。
  final String? method;
  final String methodOther;
  final String fromPlace;
  final String toPlace;
  final String reservationNumber;
  final String url;
  final String memo;
}

/// 共有現場の宿泊（editor 編集用, D-246）。
class SharedLodging {
  const SharedLodging({
    required this.id,
    this.version = 1,
    this.name = '',
    this.checkinDate,
    this.checkoutDate,
    this.address = '',
    this.reservationNumber = '',
    this.url = '',
    this.memo = '',
  });
  final String id;
  final int version;
  final String name;

  /// チェックイン/アウト日（date 型・時刻なし）。
  final DateTime? checkinDate;
  final DateTime? checkoutDate;
  final String address;
  final String reservationNumber;
  final String url;
  final String memo;
}

/// 共有現場のグッズ・戦利品（editor 編集用, D-246）。
class SharedGoods {
  const SharedGoods({
    required this.id,
    this.version = 1,
    this.name = '',
    this.price,
    this.quantity = 1,
    this.memo = '',
  });
  final String id;
  final int version;
  final String name;
  final int? price;
  final int quantity;
  final String memo;
}

/// 共有現場の行った場所/食べたもの（visited_places・category=spot/food, D-246）。
class SharedVisitedPlace {
  const SharedVisitedPlace({
    required this.id,
    this.version = 1,
    this.name = '',
    this.category = 'spot',
    this.memo = '',
  });
  final String id;
  final int version;
  final String name;

  /// 'spot'（行った場所）/ 'food'（食べたもの）。
  final String category;
  final String memo;
  bool get isFood => category == 'food';
}

/// 共有現場のセットリスト曲（editor 編集用, D-246）。
class SharedSetlistItem {
  const SharedSetlistItem({
    required this.id,
    this.version = 1,
    this.position = 1,
    this.songTitle = '',
    this.note = '',
  });
  final String id;
  final int version;
  final int position;
  final String songTitle;
  final String note;
}

/// 共有現場の写真（アルバム表示・caption/cover 編集・削除用, D-246）。
/// 画像本体は Supabase Storage（[storagePath]）にあり、メンバー用の Storage
/// 読み書きポリシーは未実装のため、本増分では **メタデータ（caption/cover）編集と
/// 行削除のみ**対応する（画像アップロード/サムネイル表示は次増分）。
class SharedPhoto {
  const SharedPhoto({
    required this.id,
    this.version = 1,
    this.caption = '',
    this.isCover = false,
    this.sortOrder = 0,
    this.uploadStatus = 'local_only',
    this.storagePath,
  });
  final String id;
  final int version;
  final String caption;
  final bool isCover;
  final int sortOrder;
  final String uploadStatus;
  final String? storagePath;
}

/// 共有現場の思い出（感想テキスト）。editor 編集の CAS 用に id/version を持つ。
/// [id] が null の現場はまだ思い出行が無く、追加時に新規作成する。
class SharedMemory {
  const SharedMemory({
    this.id,
    this.version = 1,
    required this.impression,
    required this.bestMoment,
  });
  final String? id;
  final int version;
  final String impression;
  final String bestMoment;
  bool get isEmpty => impression.isEmpty && bestMoment.isEmpty;
}

/// 共有現場の閲覧用データ（サーバー権威で取得, D-241）。
///
/// 概要/準備状況（[aggregate]）に加え、計画（[spots]/[legCount]）、思い出
/// （[memory]/[goods]/[visitedPlaces]/[foods]/[setlist]）、写真件数（[photoCount]）
/// を持つ。editor 編集の CAS 用に Todo の版（[todoVersions]）も保持する。
class SharedGenbaData {
  const SharedGenbaData({
    required this.aggregate,
    this.todoVersions = const {},
    this.memoVersions = const {},
    this.hasPlan = false,
    this.firstPlanId,
    this.spots = const [],
    this.entries = const [],
    this.legs = const [],
    this.tickets = const [],
    this.transports = const [],
    this.lodgings = const [],
    this.memory,
    this.goods = const [],
    this.visitedPlaces = const [],
    this.setlist = const [],
    this.photos = const [],
  });

  final GenbaAggregate aggregate;
  final Map<String, int> todoVersions;

  /// メモの版（editor 編集の CAS 用, D-243）。
  final Map<String, int> memoVersions;
  final bool hasPlan;

  /// スポット/移動区間を追加する先の plan_id（無ければ null＝計画未作成）。
  final String? firstPlanId;
  final List<SharedSpot> spots;

  /// 移動区間の端点候補（旅程項目, D-246）。
  final List<SharedEntry> entries;
  final List<SharedLeg> legs;
  final List<SharedTicket> tickets;
  final List<SharedTransport> transports;
  final List<SharedLodging> lodgings;
  final SharedMemory? memory;
  final List<SharedGoods> goods;

  /// 行った場所（category=spot）＋食べたもの（category=food）を混在で持つ。
  final List<SharedVisitedPlace> visitedPlaces;
  final List<SharedSetlistItem> setlist;
  final List<SharedPhoto> photos;

  /// 行った場所（spot）だけ。
  List<SharedVisitedPlace> get visitedSpots => [
        for (final p in visitedPlaces)
          if (!p.isFood) p,
      ];

  /// 食べたもの（food）だけ。
  List<SharedVisitedPlace> get foods => [
        for (final p in visitedPlaces)
          if (p.isFood) p,
      ];
}

/// 共有現場の本体＋子データをサーバー権威で取得する境界（追加要件 §1/§2, D-240/D-241）。
///
/// 共有現場はローカル owner スコープ store に入れない（C-01 を壊さない）。
/// RLS 0031 で SELECT 可能な前提で Supabase から直接読む。閲覧用途のため、状態が
/// 確定する表示フィールドを優先して写像する。
abstract interface class SharedGenbaFetcher {
  Future<Result<SharedGenbaData?>> fetch(String genbaId);
}

class SupabaseSharedGenbaFetcher implements SharedGenbaFetcher {
  SupabaseSharedGenbaFetcher(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<SharedGenbaData?>> fetch(String genbaId) async {
    try {
      final g = await _client
          .from('genbas')
          .select()
          .eq('id', genbaId)
          .maybeSingle()
          .withRemoteTimeout();
      if (g == null) return const Ok(null);

      final todoRows = await _byGenba('todos', genbaId);
      final memos = await _byGenba('genba_memos', genbaId);
      final tickets = await _byGenba('tickets', genbaId);
      final transports = await _byGenba('transports', genbaId);
      final lodgings = await _byGenba('lodgings', genbaId);

      // 計画: plan → spots / legs。
      final plans = await _client
          .from('itinerary_plans')
          .select('id')
          .eq('genba_id', genbaId)
          .withRemoteTimeout();
      final planIds = [
        for (final p in plans)
          if (p['id'] is String) p['id'] as String,
      ];
      var spots = const <SharedSpot>[];
      var entries = const <SharedEntry>[];
      var legs = const <SharedLeg>[];
      if (planIds.isNotEmpty) {
        final spotRows = await _client
            .from('itinerary_spots')
            .select('id, plan_id, name, category, version')
            .inFilter('plan_id', planIds)
            .withRemoteTimeout();
        spots = [
          for (final s in spotRows)
            SharedSpot(
              id: s['id'] as String,
              planId: s['plan_id'] as String,
              name: (s['name'] as String?) ?? '',
              category: (s['category'] as String?) ?? 'other',
              version: _int(s['version']) ?? 1,
            ),
        ];
        final spotNames = {for (final s in spots) s.id: s.name};
        final entryRows = await _client
            .from('itinerary_entries')
            .select('id, kind, spot_id, title_override, sort_order')
            .inFilter('plan_id', planIds)
            .withRemoteTimeout();
        entries = [
          for (final e in entryRows)
            SharedEntry(
              id: e['id'] as String,
              label: _entryLabel(e, spotNames),
            ),
        ];
        final entryLabels = {for (final e in entries) e.id: e.label};
        final legRows = await _client
            .from('itinerary_legs')
            .select('id, plan_id, origin_entry_id, destination_entry_id, '
                'travel_mode, duration_minutes, version')
            .inFilter('plan_id', planIds)
            .withRemoteTimeout();
        legs = [
          for (final l in legRows)
            SharedLeg(
              id: l['id'] as String,
              planId: l['plan_id'] as String,
              originEntryId: (l['origin_entry_id'] as String?) ?? '',
              destinationEntryId: (l['destination_entry_id'] as String?) ?? '',
              travelMode: (l['travel_mode'] as String?) ?? 'other',
              durationMinutes: _int(l['duration_minutes']),
              label: _legLabel(
                l['travel_mode'] as String?,
                _int(l['duration_minutes']),
                origin: entryLabels[l['origin_entry_id']],
                destination: entryLabels[l['destination_entry_id']],
              ),
              version: _int(l['version']) ?? 1,
            ),
        ];
      }

      // 思い出: 感想・グッズ・行った場所/食べたもの・セットリスト・写真。
      final memoryRow = await _client
          .from('memory_entries')
          .select('id, impression, best_moment, version')
          .eq('genba_id', genbaId)
          .maybeSingle()
          .withRemoteTimeout();
      final goods = await _byGenba('goods_items', genbaId);
      final places = await _byGenba('visited_places', genbaId);
      final setlistRows = await _byGenba('setlist_items', genbaId);
      final photoRows = await _byGenba('memory_photos', genbaId);

      return Ok(
        SharedGenbaData(
          aggregate: GenbaAggregate(
            genba: _genba(g),
            todos: todoRows.map(_todo).toList(),
            memos: memos.map(_memo).toList(),
            tickets: tickets.map(_ticket).toList(),
            transports: transports.map(_transport).toList(),
            lodgings: lodgings.map(_lodging).toList(),
          ),
          todoVersions: {
            for (final r in todoRows)
              if (r['id'] is String) r['id'] as String: _int(r['version']) ?? 1,
          },
          memoVersions: {
            for (final r in memos)
              if (r['id'] is String) r['id'] as String: _int(r['version']) ?? 1,
          },
          hasPlan: planIds.isNotEmpty,
          firstPlanId: planIds.isNotEmpty ? planIds.first : null,
          spots: spots,
          entries: entries,
          legs: legs,
          tickets: tickets.map(_sharedTicket).toList(),
          transports: transports.map(_sharedTransport).toList(),
          lodgings: lodgings.map(_sharedLodging).toList(),
          memory: memoryRow == null
              ? null
              : SharedMemory(
                  id: memoryRow['id'] as String?,
                  version: _int(memoryRow['version']) ?? 1,
                  impression: (memoryRow['impression'] as String?) ?? '',
                  bestMoment: (memoryRow['best_moment'] as String?) ?? '',
                ),
          goods: goods.map(_sharedGoods).toList(),
          visitedPlaces: places.map(_sharedPlace).toList(),
          setlist: setlistRows.map(_sharedSetlist).toList(),
          photos: photoRows.map(_sharedPhoto).toList(),
        ),
      );
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  Future<List<Map<String, dynamic>>> _byGenba(String table, String genbaId) =>
      _client.from(table).select().eq('genba_id', genbaId).withRemoteTimeout();

  static DateTime _time(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : DateTime.now().toUtc();
  static DateTime? _timeOrNull(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : null;
  static int? _int(Object? v) => (v as num?)?.toInt();

  /// date 型（'YYYY-MM-DD'）を local DateTime へ（時刻なし項目用）。
  static DateTime? _dateOrNull(Object? v) {
    if (v is! String || v.isEmpty) return null;
    final d = DateTime.tryParse(v);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static String _str(Object? v) => v is String ? v : '';

  /// 旅程項目（移動区間の端点）の表示ラベル。title_override→スポット名→種別。
  static String _entryLabel(
    Map<String, dynamic> e,
    Map<String, String> spotNames,
  ) {
    final title = _str(e['title_override']);
    if (title.isNotEmpty) return title;
    final spotName = spotNames[e['spot_id']];
    if (spotName != null && spotName.isNotEmpty) return spotName;
    return switch (e['kind'] as String?) {
      'spot' => 'スポット',
      'transport' => '移動',
      'lodging' => '宿泊',
      'note' => 'メモ',
      _ => '項目',
    };
  }

  static Genba _genba(Map<String, dynamic> r) => Genba(
        id: r['id'] as String,
        ownerId: r['owner_id'] as String,
        artistName: (r['artist_name'] as String?) ?? '',
        title: (r['title'] as String?) ?? '',
        eventDate: _time(r['event_date']),
        venue: r['venue'] as String?,
        venueAddress: r['venue_address'] as String?,
        doorTimeMinutes: _int(r['door_time_minutes']),
        startTimeMinutes: _int(r['start_time_minutes']),
        endTimeMinutes: _int(r['end_time_minutes']),
        isCanceled: (r['is_canceled'] as bool?) ?? false,
        manualEndedAt: _timeOrNull(r['manual_ended_at']),
        createdAt: _time(r['created_at']),
        updatedAt: _time(r['updated_at']),
      );

  static GenbaTodo _todo(Map<String, dynamic> r) => GenbaTodo(
        id: r['id'] as String,
        genbaId: r['genba_id'] as String,
        ownerId: r['owner_id'] as String,
        name: (r['name'] as String?) ?? '',
        type: (r['type'] as String?) == 'belonging'
            ? TodoItemType.belonging
            : TodoItemType.todo,
        isDone: (r['is_done'] as bool?) ?? false,
        sortOrder: _int(r['sort_order']) ?? 0,
        createdAt: _time(r['created_at']),
        updatedAt: _time(r['updated_at']),
      );

  // category / kind / content を復元し、構造化メモ（checklist/bingo/vote）も
  // 共有画面で正しく表示・編集できるようにする（D-244）。
  static GenbaMemo _memo(Map<String, dynamic> r) => GenbaMemo(
        id: r['id'] as String,
        genbaId: r['genba_id'] as String,
        ownerId: r['owner_id'] as String,
        category: _enumByName(
          MemoCategory.values,
          r['category'] as String?,
          MemoCategory.other,
        ),
        kind: _enumByName(MemoKind.values, r['kind'] as String?, MemoKind.free),
        title: (r['title'] as String?) ?? '',
        body: (r['body'] as String?) ?? '',
        content: _memoContent(r['content']),
        sortOrder: _int(r['sort_order']) ?? 0,
        createdAt: _time(r['created_at']),
        updatedAt: _time(r['updated_at']),
      );

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// 移動区間の閲覧ラベル（端点名＋交通手段＋所要）。
  static String _legLabel(
    String? travelMode,
    int? durationMinutes, {
    String? origin,
    String? destination,
  }) {
    final mode = legTravelModeLabel(travelMode);
    final endpoints = (origin != null && destination != null)
        ? '$origin → $destination・'
        : '';
    if (durationMinutes != null && durationMinutes > 0) {
      return '$endpoints$mode 約$durationMinutes分';
    }
    return '$endpoints$mode';
  }

  static SharedTicket _sharedTicket(Map<String, dynamic> r) => SharedTicket(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        seat: _str(r['seat']),
        gate: _str(r['gate']),
        entryNumber: _str(r['entry_number']),
        url: _str(r['url']),
        memo: _str(r['memo']),
        acquisitionStatus: _str(r['acquisition_status']).isEmpty
            ? 'not_applied'
            : r['acquisition_status'] as String,
        paymentStatus: _str(r['payment_status']).isEmpty
            ? 'unpaid'
            : r['payment_status'] as String,
        issuanceStatus: _str(r['issuance_status']).isEmpty
            ? 'not_issued'
            : r['issuance_status'] as String,
      );

  static SharedTransport _sharedTransport(Map<String, dynamic> r) =>
      SharedTransport(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        direction: _str(r['direction']).isEmpty
            ? 'outbound'
            : r['direction'] as String,
        method: r['method'] as String?,
        methodOther: _str(r['method_other']),
        fromPlace: _str(r['from_place']),
        toPlace: _str(r['to_place']),
        reservationNumber: _str(r['reservation_number']),
        url: _str(r['url']),
        memo: _str(r['memo']),
      );

  static SharedLodging _sharedLodging(Map<String, dynamic> r) => SharedLodging(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        name: _str(r['name']),
        checkinDate: _dateOrNull(r['checkin_date']),
        checkoutDate: _dateOrNull(r['checkout_date']),
        address: _str(r['address']),
        reservationNumber: _str(r['reservation_number']),
        url: _str(r['url']),
        memo: _str(r['memo']),
      );

  static SharedGoods _sharedGoods(Map<String, dynamic> r) => SharedGoods(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        name: _str(r['name']),
        price: _int(r['price']),
        quantity: _int(r['quantity']) ?? 1,
        memo: _str(r['memo']),
      );

  static SharedVisitedPlace _sharedPlace(Map<String, dynamic> r) =>
      SharedVisitedPlace(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        name: _str(r['name']),
        category:
            _str(r['category']).isEmpty ? 'spot' : r['category'] as String,
        memo: _str(r['memo']),
      );

  static SharedSetlistItem _sharedSetlist(Map<String, dynamic> r) =>
      SharedSetlistItem(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        position: _int(r['position']) ?? 1,
        songTitle: _str(r['song_title']),
        note: _str(r['note']),
      );

  static SharedPhoto _sharedPhoto(Map<String, dynamic> r) => SharedPhoto(
        id: r['id'] as String,
        version: _int(r['version']) ?? 1,
        caption: _str(r['caption']),
        isCover: (r['is_cover'] as bool?) ?? false,
        sortOrder: _int(r['sort_order']) ?? 0,
        uploadStatus: _str(r['upload_status']).isEmpty
            ? 'local_only'
            : r['upload_status'] as String,
        storagePath: r['storage_path'] as String?,
      );

  /// genba_memos.content（Supabase jsonb=Map / まれに JSON文字列）→ [MemoContent]。
  static MemoContent? _memoContent(Object? v) {
    if (v == null) return null;
    if (v is Map) {
      return MemoContent.fromJson(Map<String, dynamic>.from(v));
    }
    if (v is String && v.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) {
          return MemoContent.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // tickets/transports/lodgings は閲覧画面では件数のみ使う。
  static Ticket _ticket(Map<String, dynamic> r) => Ticket(
        id: r['id'] as String,
        genbaId: r['genba_id'] as String,
        ownerId: r['owner_id'] as String,
        createdAt: _time(r['created_at']),
        updatedAt: _time(r['updated_at']),
      );

  static Transport _transport(Map<String, dynamic> r) => Transport(
        id: r['id'] as String,
        genbaId: r['genba_id'] as String,
        ownerId: r['owner_id'] as String,
        createdAt: _time(r['created_at']),
        updatedAt: _time(r['updated_at']),
      );

  static Lodging _lodging(Map<String, dynamic> r) => Lodging(
        id: r['id'] as String,
        genbaId: r['genba_id'] as String,
        ownerId: r['owner_id'] as String,
        createdAt: _time(r['created_at']),
        updatedAt: _time(r['updated_at']),
      );
}

/// 未接続/デモ向け no-op。
class UnavailableSharedGenbaFetcher implements SharedGenbaFetcher {
  const UnavailableSharedGenbaFetcher();
  @override
  Future<Result<SharedGenbaData?>> fetch(String genbaId) async =>
      const Ok(null);
}
