// ignore_for_file: invalid_annotation_target

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/images/image_upload_status.dart';
import '../../../core/time/date_only.dart';

part 'genba.freezed.dart';
part 'genba.g.dart';

/// 現場の状態（§7.1）。日時と明示操作から純粋ロジックで導出する。
enum GenbaStatus { scheduled, preparing, today, afterglow, memory, canceled }

/// 明示的な参加状態（§7.2 / design-spec §12.1）。
///
/// 日時から自動的に [attended] にはしない。ユーザーが明示的に「参戦済み」と
/// した場合のみ [attended]。統計の「参戦数」は [attended] だけを数える。
/// [canceled] は現場中止（[Genba.isCanceled]）と一致させる（[normalizeAttendance]）。
enum AttendanceStatus {
  @JsonValue('planned')
  planned,
  @JsonValue('attended')
  attended,
  @JsonValue('not_attended')
  notAttended,
  @JsonValue('canceled')
  canceled,
}

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.planned => '予定',
        AttendanceStatus.attended => '参戦済み',
        AttendanceStatus.notAttended => '不参加',
        AttendanceStatus.canceled => '中止',
      };
}

/// 現場ヒーロー画像（design-spec §7.1/§12.1）。
///
/// チケット画像（[Ticket.imagePath] / [Ticket.imageLocalPath]）とは
/// **完全に別用途・別型**。ユーザーが明示的に選んだ公演用画像を表す。
/// [localPath] は端末内相対参照（同期対象外, H-04）、[storagePath] は
/// Supabase Storage パス（境界）、[uploadStatus] はアップロード状態、
/// [altText] は読み上げ用代替説明（§14, 同期対象）。
@freezed
abstract class GenbaHeroImage with _$GenbaHeroImage {
  const factory GenbaHeroImage({
    String? localPath,
    String? storagePath,
    @Default(ImageUploadStatus.localOnly) ImageUploadStatus uploadStatus,
    String? altText,
  }) = _GenbaHeroImage;

  factory GenbaHeroImage.fromJson(Map<String, dynamic> json) =>
      _$GenbaHeroImageFromJson(json);
}

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
  const Genba._();

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

    /// 明示的な参加状態（§7.2 / design-spec §12.1）。日時から自動導出しない。
    /// [isCanceled] とは [normalizeAttendance] で整合させる。
    @Default(AttendanceStatus.planned) AttendanceStatus attendanceStatus,

    /// 現場ヒーロー画像の端末内参照（`images/<owner>/hero/...`）。
    /// 同期対象外（Outbox/Supabase へ送らない, H-04）。他端末では表示されない。
    String? heroImageLocalPath,

    /// 現場ヒーロー画像の Storage パス（境界・同期対象）。
    String? heroImageStoragePath,

    /// 現場ヒーロー画像のアップロード状態（同期対象）。
    @Default(ImageUploadStatus.localOnly)
    ImageUploadStatus heroImageUploadStatus,

    /// 現場ヒーロー画像の代替説明（読み上げ用, §14・同期対象）。
    String? heroImageAltText,

    /// ユーザーが明示的に「終演した」とした時刻（余韻中への手動遷移）。
    @NullableUtcDateTimeConverter() DateTime? manualEndedAt,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Genba;

  factory Genba.fromJson(Map<String, dynamic> json) => _$GenbaFromJson(json);

  /// 現場ヒーロー画像を「明確な型」でまとめて取得する（design-spec §12.1）。
  /// 参照が一切無ければ null（画像なしで各画面が縮退できるようにする）。
  GenbaHeroImage? get heroImage {
    if (heroImageLocalPath == null &&
        heroImageStoragePath == null &&
        heroImageAltText == null) {
      return null;
    }
    return GenbaHeroImage(
      localPath: heroImageLocalPath,
      storagePath: heroImageStoragePath,
      uploadStatus: heroImageUploadStatus,
      altText: heroImageAltText,
    );
  }
}

/// 中止フラグ [Genba.isCanceled] と [Genba.attendanceStatus] を整合させる
/// （design-spec §12.1 の整合規則）。
///
/// 不変条件（一方向）: **中止された現場は必ず参加状態も canceled**。
/// - 中止なのに参加状態が canceled でなければ canceled へ矯正する。
/// - 参加状態を明示的に変える操作（cancel/uncancel/setAttendance）は
///   isCanceled も合わせて設定するため、ここでは「中止 ⟹ canceled」だけを
///   守る（attended を勝手に消さない）。
Genba normalizeAttendance(Genba g) {
  if (g.isCanceled && g.attendanceStatus != AttendanceStatus.canceled) {
    return g.copyWith(attendanceStatus: AttendanceStatus.canceled);
  }
  return g;
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
