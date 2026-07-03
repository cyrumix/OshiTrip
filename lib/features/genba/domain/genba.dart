// ignore_for_file: invalid_annotation_target

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';

part 'genba.freezed.dart';
part 'genba.g.dart';

/// 現場の状態（§7.1）。日時と明示操作から純粋ロジックで導出する。
enum GenbaStatus { scheduled, preparing, today, afterglow, memory, canceled }

extension GenbaStatusLabel on GenbaStatus {
  String get label => switch (this) {
        GenbaStatus.scheduled => '予定',
        GenbaStatus.preparing => '準備中',
        GenbaStatus.today => '本日',
        GenbaStatus.afterglow => '余韻中',
        GenbaStatus.memory => '思い出',
        GenbaStatus.canceled => '中止',
      };
}

/// 「不要」と「未登録」を区別するための要否ステータス（§7.4/§7.5）。
enum RequirementStatus {
  @JsonValue('unknown')
  unknown,
  @JsonValue('required')
  required,
  @JsonValue('not_required')
  notRequired,
}

extension RequirementStatusLabel on RequirementStatus {
  String get label => switch (this) {
        RequirementStatus.unknown => '未設定',
        RequirementStatus.required => '必要',
        RequirementStatus.notRequired => '不要',
      };
}

/// 現場（1公演参加）の集約ルート。
@freezed
abstract class Genba with _$Genba {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Genba({
    required String id,
    required String ownerId,
    required String artistName,
    required String title,
    @DateOnlyConverter() required DateTime eventDate,
    String? oshiGroupId,
    @Default(<String>[]) List<String> oshiMemberIds,
    String? venue,

    /// 開場/開演/終演予定。公演日 0:00 からの分数（深夜公演は 1440 超を許容）。
    int? doorTimeMinutes,
    int? startTimeMinutes,
    int? endTimeMinutes,
    String? performanceType,

    /// ユーザー投稿型公演マスタとの紐づけ（今回は境界のみ）。
    String? performanceId,

    /// 遠征の有無（null = 未回答）。
    bool? isExpedition,
    @Default(RequirementStatus.unknown) RequirementStatus transportRequirement,
    @Default(RequirementStatus.unknown) RequirementStatus lodgingRequirement,
    @Default(false) bool isCanceled,

    /// 現場ヒーロー画像の端末内参照（`images/<owner>/hero/...`）。
    /// 同期対象外（Outbox/Supabase へ送らない, H-04）。他端末では表示されない。
    String? heroImageLocalPath,

    /// ユーザーが明示的に「終演した」とした時刻（余韻中への手動遷移）。
    @NullableUtcDateTimeConverter() DateTime? manualEndedAt,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Genba;

  factory Genba.fromJson(Map<String, dynamic> json) => _$GenbaFromJson(json);
}

/// チケット取得状況（§7.3）。
enum TicketAcquisition {
  @JsonValue('not_applied')
  notApplied,
  @JsonValue('applied')
  applied,
  @JsonValue('won')
  won,
  @JsonValue('lost')
  lost,
  @JsonValue('acquired')
  acquired,
}

extension TicketAcquisitionLabel on TicketAcquisition {
  String get label => switch (this) {
        TicketAcquisition.notApplied => '未申込',
        TicketAcquisition.applied => '申込中',
        TicketAcquisition.won => '当選',
        TicketAcquisition.lost => '落選',
        TicketAcquisition.acquired => '取得済',
      };
}

enum TicketPayment {
  @JsonValue('unpaid')
  unpaid,
  @JsonValue('paid')
  paid,
  @JsonValue('not_required')
  notRequired,
}

extension TicketPaymentLabel on TicketPayment {
  String get label => switch (this) {
        TicketPayment.unpaid => '未払い',
        TicketPayment.paid => '支払済',
        TicketPayment.notRequired => '支払不要',
      };
}

enum TicketIssuance {
  @JsonValue('not_issued')
  notIssued,
  @JsonValue('issued')
  issued,
  @JsonValue('digital')
  digital,
}

extension TicketIssuanceLabel on TicketIssuance {
  String get label => switch (this) {
        TicketIssuance.notIssued => '未発券',
        TicketIssuance.issued => '発券済',
        TicketIssuance.digital => '電子チケット',
      };
}

/// チケット。外部URL（[url]）と保存画像（[imagePath]）はデータ上も別項目（§6.2）。
@freezed
abstract class Ticket with _$Ticket {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Ticket({
    required String id,
    required String genbaId,
    required String ownerId,
    @Default(TicketAcquisition.notApplied) TicketAcquisition acquisitionStatus,
    @Default(TicketPayment.unpaid) TicketPayment paymentStatus,
    @Default(TicketIssuance.notIssued) TicketIssuance issuanceStatus,
    String? seat,
    String? entryNumber,
    String? gate,
    String? url,

    /// Supabase Storage 上のオブジェクトパス（署名URLで認可付き取得する）。
    String? imagePath,

    /// 端末内のチケット画像参照（同期対象外。アップロードは後続範囲）。
    String? imageLocalPath,
    String? memo,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}

enum TransportDirection {
  @JsonValue('outbound')
  outbound,
  @JsonValue('inbound')
  inbound,
}

extension TransportDirectionLabel on TransportDirection {
  String get label => this == TransportDirection.outbound ? '往路' : '復路';
}

@freezed
abstract class Transport with _$Transport {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Transport({
    required String id,
    required String genbaId,
    required String ownerId,
    @Default(TransportDirection.outbound) TransportDirection direction,
    String? method,
    String? fromPlace,
    String? toPlace,
    @NullableUtcDateTimeConverter() DateTime? departAt,
    @NullableUtcDateTimeConverter() DateTime? arriveAt,
    String? reservationNumber,
    String? url,
    String? memo,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Transport;

  factory Transport.fromJson(Map<String, dynamic> json) =>
      _$TransportFromJson(json);
}

@freezed
abstract class Lodging with _$Lodging {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Lodging({
    required String id,
    required String genbaId,
    required String ownerId,
    String? name,
    @NullableDateOnlyConverter() DateTime? checkinDate,
    @NullableDateOnlyConverter() DateTime? checkoutDate,
    String? address,
    String? reservationNumber,
    String? url,
    String? memo,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Lodging;

  factory Lodging.fromJson(Map<String, dynamic> json) =>
      _$LodgingFromJson(json);
}

enum TodoPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
}

extension TodoPriorityLabel on TodoPriority {
  String get label => switch (this) {
        TodoPriority.low => '低',
        TodoPriority.normal => '中',
        TodoPriority.high => '重要',
      };
}

@freezed
abstract class GenbaTodo with _$GenbaTodo {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory GenbaTodo({
    required String id,
    required String genbaId,
    required String ownerId,
    required String name,
    @NullableDateOnlyConverter() DateTime? dueDate,
    @Default(false) bool isDone,
    String? assignee,
    @Default(TodoPriority.normal) TodoPriority priority,
    String? memo,
    @Default(0) int sortOrder,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _GenbaTodo;

  factory GenbaTodo.fromJson(Map<String, dynamic> json) =>
      _$GenbaTodoFromJson(json);
}

/// メモ区分（§7.7）。区分ごとに1件を upsert する。
enum MemoCategory {
  @JsonValue('free')
  free,
  @JsonValue('goods')
  goods,
  @JsonValue('meetup')
  meetup,
  @JsonValue('around')
  around,
  @JsonValue('notice')
  notice,
}

extension MemoCategoryLabel on MemoCategory {
  String get label => switch (this) {
        MemoCategory.free => '自由メモ',
        MemoCategory.goods => '物販',
        MemoCategory.meetup => '集合場所',
        MemoCategory.around => '周辺施設',
        MemoCategory.notice => '注意事項',
      };
}

@freezed
abstract class GenbaMemo with _$GenbaMemo {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory GenbaMemo({
    required String id,
    required String genbaId,
    required String ownerId,
    required MemoCategory category,
    @Default('') String body,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _GenbaMemo;

  factory GenbaMemo.fromJson(Map<String, dynamic> json) =>
      _$GenbaMemoFromJson(json);
}

/// 現場と子データをまとめた集約ビュー。
@freezed
abstract class GenbaAggregate with _$GenbaAggregate {
  const GenbaAggregate._();

  const factory GenbaAggregate({
    required Genba genba,
    @Default(<Ticket>[]) List<Ticket> tickets,
    @Default(<Transport>[]) List<Transport> transports,
    @Default(<Lodging>[]) List<Lodging> lodgings,
    @Default(<GenbaTodo>[]) List<GenbaTodo> todos,
    @Default(<GenbaMemo>[]) List<GenbaMemo> memos,
  }) = _GenbaAggregate;

  int get incompleteTodoCount => todos.where((t) => !t.isDone).length;

  GenbaMemo? memoOf(MemoCategory category) =>
      memos.where((m) => m.category == category).firstOrNull;
}
