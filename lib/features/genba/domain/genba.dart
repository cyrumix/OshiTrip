// ignore_for_file: invalid_annotation_target

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

/// 公演種別（§7.1）。自由入力を廃止し選択式にする。内部値は安定したコード
/// （日本語文字列を保存しない）。既知の選択肢へ変換できない既存の自由入力値は
/// [other] とし、元の文字列は [Genba.performanceTypeOther] に保持して失わない。
enum PerformanceType {
  @JsonValue('live_concert')
  liveConcert,
  @JsonValue('festival')
  festival,
  @JsonValue('release_event')
  releaseEvent,
  @JsonValue('meet_greet')
  meetGreet,
  @JsonValue('fan_meeting')
  fanMeeting,
  @JsonValue('talk_event')
  talkEvent,
  @JsonValue('stage_musical')
  stageMusical,
  @JsonValue('exhibition')
  exhibition,
  @JsonValue('sports')
  sports,
  @JsonValue('online')
  online,
  @JsonValue('other')
  other,
}

extension PerformanceTypeX on PerformanceType {
  /// 安定したコード（DB/JSON/同期で使う。日本語を保存しない）。
  String get code => switch (this) {
        PerformanceType.liveConcert => 'live_concert',
        PerformanceType.festival => 'festival',
        PerformanceType.releaseEvent => 'release_event',
        PerformanceType.meetGreet => 'meet_greet',
        PerformanceType.fanMeeting => 'fan_meeting',
        PerformanceType.talkEvent => 'talk_event',
        PerformanceType.stageMusical => 'stage_musical',
        PerformanceType.exhibition => 'exhibition',
        PerformanceType.sports => 'sports',
        PerformanceType.online => 'online',
        PerformanceType.other => 'other',
      };

  /// 一覧・詳細で表示する日本語ラベル。
  String get label => switch (this) {
        PerformanceType.liveConcert => 'ライブ・コンサート',
        PerformanceType.festival => 'フェス',
        PerformanceType.releaseEvent => 'リリースイベント',
        PerformanceType.meetGreet => '特典会・撮影会',
        PerformanceType.fanMeeting => 'ファンミーティング',
        PerformanceType.talkEvent => 'トークイベント',
        PerformanceType.stageMusical => '舞台・ミュージカル',
        PerformanceType.exhibition => '展示会',
        PerformanceType.sports => 'スポーツ観戦',
        PerformanceType.online => 'オンライン配信',
        PerformanceType.other => 'その他',
      };
}

/// コード文字列から [PerformanceType] を復元する（不明・null は null）。
PerformanceType? performanceTypeFromCode(String? code) {
  if (code == null) return null;
  for (final v in PerformanceType.values) {
    if (v.code == code) return v;
  }
  return null;
}

/// 旧・自由入力の文字列を既知コードへ安全に変換する（変換不能は null → 呼び出し側で
/// [PerformanceType.other] 扱いにし、元文字列を保持する）。移行と入力補助で共有する。
PerformanceType? performanceTypeFromLegacy(String? raw) {
  final t = raw?.trim().toLowerCase();
  if (t == null || t.isEmpty) return null;
  bool has(String s) => t.contains(s);
  if (has('ライブ') || has('コンサート') || has('live') || has('ワンマン')) {
    return PerformanceType.liveConcert;
  }
  if (has('フェス') || has('festival')) return PerformanceType.festival;
  if (has('リリイベ') || has('リリース')) return PerformanceType.releaseEvent;
  if (has('特典会') || has('撮影会') || has('チェキ')) {
    return PerformanceType.meetGreet;
  }
  if (has('ファンミ')) return PerformanceType.fanMeeting;
  if (has('トーク')) return PerformanceType.talkEvent;
  if (has('舞台') || has('ミュージカル') || has('演劇')) {
    return PerformanceType.stageMusical;
  }
  if (has('展示') || has('展覧')) return PerformanceType.exhibition;
  if (has('スポーツ') || has('観戦') || has('試合')) {
    return PerformanceType.sports;
  }
  if (has('オンライン') || has('配信') || has('online')) {
    return PerformanceType.online;
  }
  return null;
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

    /// 公演種別（選択式・安定コード, §7.1）。既存自由入力は移行で変換する。
    PerformanceType? performanceType,

    /// [PerformanceType.other] のときの補足自由入力、および変換不能な旧自由入力の
    /// 保持先（移行時に元文字列を失わないための領域）。
    String? performanceTypeOther,

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

/// 遠征の交通手段（§7.5）。自由入力を廃止し選択式にする。内部値は安定コード。
/// 変換できない既存の自由入力値は [other] とし、元の文字列は
/// [Transport.methodOther] に保持して失わない。
enum TransportMethod {
  @JsonValue('shinkansen')
  shinkansen,
  @JsonValue('train')
  train,
  @JsonValue('airplane')
  airplane,
  @JsonValue('highway_bus')
  highwayBus,
  @JsonValue('local_bus')
  localBus,
  @JsonValue('private_car')
  privateCar,
  @JsonValue('rental_car')
  rentalCar,
  @JsonValue('ferry')
  ferry,
  @JsonValue('taxi')
  taxi,
  @JsonValue('walk_bicycle')
  walkBicycle,
  @JsonValue('other')
  other,
}

extension TransportMethodX on TransportMethod {
  /// 安定コード（DB/JSON/同期で使う）。
  String get code => switch (this) {
        TransportMethod.shinkansen => 'shinkansen',
        TransportMethod.train => 'train',
        TransportMethod.airplane => 'airplane',
        TransportMethod.highwayBus => 'highway_bus',
        TransportMethod.localBus => 'local_bus',
        TransportMethod.privateCar => 'private_car',
        TransportMethod.rentalCar => 'rental_car',
        TransportMethod.ferry => 'ferry',
        TransportMethod.taxi => 'taxi',
        TransportMethod.walkBicycle => 'walk_bicycle',
        TransportMethod.other => 'other',
      };

  /// 一覧・詳細・計画取り込みで表示する日本語ラベル。
  String get label => switch (this) {
        TransportMethod.shinkansen => '新幹線',
        TransportMethod.train => '在来線・電車',
        TransportMethod.airplane => '飛行機',
        TransportMethod.highwayBus => '高速バス・夜行バス',
        TransportMethod.localBus => '路線バス',
        TransportMethod.privateCar => '自家用車',
        TransportMethod.rentalCar => 'レンタカー',
        TransportMethod.ferry => 'フェリー',
        TransportMethod.taxi => 'タクシー',
        TransportMethod.walkBicycle => '徒歩・自転車',
        TransportMethod.other => 'その他',
      };
}

/// コード文字列から [TransportMethod] を復元する（不明・null は null）。
TransportMethod? transportMethodFromCode(String? code) {
  if (code == null) return null;
  for (final v in TransportMethod.values) {
    if (v.code == code) return v;
  }
  return null;
}

/// 旧・自由入力の文字列を既知コードへ安全に変換する（変換不能は null →
/// 呼び出し側で [TransportMethod.other] 扱いにし、元文字列を保持する）。
TransportMethod? transportMethodFromLegacy(String? raw) {
  final t = raw?.trim().toLowerCase();
  if (t == null || t.isEmpty) return null;
  bool has(String s) => t.contains(s);
  if (has('新幹線')) return TransportMethod.shinkansen;
  if (has('夜行バス') || has('高速バス')) return TransportMethod.highwayBus;
  if (has('路線バス')) return TransportMethod.localBus;
  if (has('レンタカー') || has('rental')) return TransportMethod.rentalCar;
  if (has('自家用') || has('マイカー') || has('自分の車')) {
    return TransportMethod.privateCar;
  }
  if (has('タクシー') || has('taxi')) return TransportMethod.taxi;
  if (has('フェリー') || has('ferry') || has('船')) return TransportMethod.ferry;
  if (has('徒歩') ||
      has('歩き') ||
      has('自転車') ||
      has('チャリ') ||
      has('walk') ||
      has('bicycle')) {
    return TransportMethod.walkBicycle;
  }
  if (has('飛行機') ||
      has('空路') ||
      has('ana') ||
      has('jal') ||
      has('plane') ||
      has('flight')) {
    return TransportMethod.airplane;
  }
  // 「バス」単体は路線バス扱い（高速/夜行は上で分岐済み）。
  if (has('バス') || has('bus')) return TransportMethod.localBus;
  // 電車系（新幹線は上で分岐済み）。JR/私鉄/地下鉄/在来線 など。
  if (has('電車') ||
      has('在来線') ||
      has('jr') ||
      has('私鉄') ||
      has('地下鉄') ||
      has('train') ||
      has('鉄道')) {
    return TransportMethod.train;
  }
  return null;
}

@freezed
abstract class Transport with _$Transport {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Transport({
    required String id,
    required String genbaId,
    required String ownerId,
    @Default(TransportDirection.outbound) TransportDirection direction,

    /// 交通手段（選択式・安定コード, §7.5）。既存自由入力は移行で変換する。
    TransportMethod? method,

    /// [TransportMethod.other] の補足自由入力・変換不能な旧自由入力の保持先。
    String? methodOther,
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

extension TransportMethodDisplay on Transport {
  /// 表示用の交通手段ラベル。[TransportMethod.other] で補足自由入力があれば
  /// それを、未設定は空文字を返す（一覧・詳細・計画取り込みで共有）。
  String get methodDisplay {
    final m = method;
    if (m == null) return '';
    if (m == TransportMethod.other &&
        (methodOther?.trim().isNotEmpty ?? false)) {
      return methodOther!.trim();
    }
    return m.label;
  }
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

/// やることリスト項目の種別（Todo/持ち物）。
///
/// 任意文字列のタグではなく型安全な分類として扱う。DB上の値（JSON値）は
/// 'todo'/'belonging' で安定させ、既存データ（種別列なし）は 'todo' として
/// 扱う（後方互換, ローカルDB・Supabase双方でデフォルト値を設定）。
enum TodoItemType {
  @JsonValue('todo')
  todo,
  @JsonValue('belonging')
  belonging,
}

extension TodoItemTypeLabel on TodoItemType {
  String get label => switch (this) {
        TodoItemType.todo => 'Todo',
        TodoItemType.belonging => '持ち物',
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
    @Default(TodoItemType.todo) TodoItemType type,
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

/// メモの種類＝作成時に選べるテンプレート（§7.7）。現場ごとに同じ種類のメモを
/// 複数作成できる。[other] は「テンプレートを使わず自由に追加」を表す。
/// テンプレートは入力欄の初期値・入力例の補助であり、保存データとして強制しない。
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
  @JsonValue('other')
  other,
}

extension MemoCategoryLabel on MemoCategory {
  /// 種類のラベル。新規メモの初期タイトルにも使う。
  String get label => switch (this) {
        MemoCategory.free => '自由メモ',
        MemoCategory.goods => '物販',
        MemoCategory.meetup => '集合場所',
        MemoCategory.around => '周辺施設',
        MemoCategory.notice => '注意事項',
        MemoCategory.other => 'メモ',
      };

  /// 作成メニューでの選択肢ラベル（[other] は「テンプレートなし」を明示）。
  String get templateChoiceLabel =>
      this == MemoCategory.other ? 'テンプレートなし' : label;

  /// 種類選択で提示する順序（テンプレート5種→テンプレートなし）。
  static List<MemoCategory> get templateChoices => const [
        MemoCategory.free,
        MemoCategory.goods,
        MemoCategory.meetup,
        MemoCategory.around,
        MemoCategory.notice,
        MemoCategory.other,
      ];
}

/// 現場のメモ（§7.7）。同じ種類([category])のメモを複数持てる。ID単位で
/// 作成・編集・削除・並び替え・同期する。タイトルと本文の両方が空のメモは
/// 保存しない（呼び出し側で担保）。
@freezed
abstract class GenbaMemo with _$GenbaMemo {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory GenbaMemo({
    required String id,
    required String genbaId,
    required String ownerId,

    /// 種類（テンプレート由来。同一種類の複数作成を許容する）。
    required MemoCategory category,

    /// メモのタイトル（新規時は種類名を初期値にする）。
    @Default('') String title,
    @Default('') String body,

    /// 現場内での並び順（小さいほど上）。
    @Default(0) int sortOrder,
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

  /// 未完了のTodo件数（種別=Todoのみ。持ち物は含めない）。
  int get incompleteTodoCount =>
      todos.where((t) => t.type == TodoItemType.todo && !t.isDone).length;

  /// 未完了の持ち物件数（種別=持ち物のみ）。
  int get incompleteBelongingCount =>
      todos.where((t) => t.type == TodoItemType.belonging && !t.isDone).length;

  /// 指定種類の先頭メモ（並び順で最初）。無ければ null。
  GenbaMemo? firstMemoOf(MemoCategory category) {
    for (final m in sortedMemos) {
      if (m.category == category) return m;
    }
    return null;
  }

  /// 並び順（sortOrder→createdAt→id）で決定的に並べたメモ一覧。
  List<GenbaMemo> get sortedMemos {
    final list = [...memos];
    list.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      final byCreated = a.createdAt.compareTo(b.createdAt);
      if (byCreated != 0) return byCreated;
      return a.id.compareTo(b.id);
    });
    return list;
  }
}
