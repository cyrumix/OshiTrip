import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// 同一 genba に複数の表紙（is_cover=true）が存在する場合に、決定的に1件だけ
/// 残して他を false へ落とす dedup 文（cover 一意インデックス作成前に実行する,
/// R6独立レビュー#5）。
///
/// 保持する1件の選択規則: `sort_order` 昇順 → `created_at` 昇順 →
/// `id` 昇順 で最小のもの（ウィンドウ関数に依存しない相関サブクエリで、
/// より小さい他の cover が存在する行だけを false にする）。この規則は
/// docs/decisions.md D-141 に記録。
const String dedupeMemoryCoversSql = '''
UPDATE memory_photos SET is_cover = 0
WHERE is_cover = 1 AND EXISTS (
  SELECT 1 FROM memory_photos other
  WHERE other.genba_id = memory_photos.genba_id
    AND other.is_cover = 1
    AND (
      other.sort_order < memory_photos.sort_order
      OR (other.sort_order = memory_photos.sort_order
          AND other.created_at < memory_photos.created_at)
      OR (other.sort_order = memory_photos.sort_order
          AND other.created_at = memory_photos.created_at
          AND other.id < memory_photos.id)
    )
)''';

/// 旧・自由入力の `performance_type` を安定コードへ変換する CASE 式
/// （schema v10 / Supabase 0016 と同一ロジック）。既にコードなら素通しし、
/// 既知の語を含む値を対応コードへ、変換できない値は 'other' にする。
/// SQLite・Postgres 双方で動く（LIKE / lower / trim のみ使用）。
const String performanceTypeCodeCaseSql = '''
CASE
  WHEN performance_type IN ('live_concert','festival','release_event',
    'meet_greet','fan_meeting','talk_event','stage_musical','exhibition',
    'sports','online','other') THEN performance_type
  WHEN performance_type LIKE '%ライブ%' OR performance_type LIKE '%コンサート%'
    OR performance_type LIKE '%ワンマン%' OR lower(performance_type) LIKE '%live%'
    THEN 'live_concert'
  WHEN performance_type LIKE '%フェス%' OR lower(performance_type) LIKE '%festival%'
    THEN 'festival'
  WHEN performance_type LIKE '%リリイベ%' OR performance_type LIKE '%リリース%'
    THEN 'release_event'
  WHEN performance_type LIKE '%特典会%' OR performance_type LIKE '%撮影会%'
    OR performance_type LIKE '%チェキ%' THEN 'meet_greet'
  WHEN performance_type LIKE '%ファンミ%' THEN 'fan_meeting'
  WHEN performance_type LIKE '%トーク%' THEN 'talk_event'
  WHEN performance_type LIKE '%舞台%' OR performance_type LIKE '%ミュージカル%'
    OR performance_type LIKE '%演劇%' THEN 'stage_musical'
  WHEN performance_type LIKE '%展示%' OR performance_type LIKE '%展覧%'
    THEN 'exhibition'
  WHEN performance_type LIKE '%スポーツ%' OR performance_type LIKE '%観戦%'
    OR performance_type LIKE '%試合%' THEN 'sports'
  WHEN performance_type LIKE '%オンライン%' OR performance_type LIKE '%配信%'
    OR lower(performance_type) LIKE '%online%' THEN 'online'
  ELSE 'other'
END''';

/// 既知の公演種別コード（移行で「既にコードか」を判定する）。
const String performanceTypeKnownCodesInList =
    "('live_concert','festival','release_event','meet_greet','fan_meeting',"
    "'talk_event','stage_musical','exhibition','sports','online','other')";

/// 旧・自由入力の transports.method を安定コードへ変換する CASE 式
/// （schema v11 / Supabase 0017 と同一ロジック）。既にコードなら素通し。
const String transportMethodCodeCaseSql = '''
CASE
  WHEN method IN ('shinkansen','train','airplane','highway_bus','local_bus',
    'private_car','rental_car','ferry','taxi','walk_bicycle','other')
    THEN method
  WHEN method LIKE '%新幹線%' THEN 'shinkansen'
  WHEN method LIKE '%夜行バス%' OR method LIKE '%高速バス%' THEN 'highway_bus'
  WHEN method LIKE '%路線バス%' THEN 'local_bus'
  WHEN method LIKE '%レンタカー%' OR lower(method) LIKE '%rental%'
    THEN 'rental_car'
  WHEN method LIKE '%自家用%' OR method LIKE '%マイカー%' THEN 'private_car'
  WHEN method LIKE '%タクシー%' OR lower(method) LIKE '%taxi%' THEN 'taxi'
  WHEN method LIKE '%フェリー%' OR method LIKE '%船%' OR lower(method) LIKE '%ferry%'
    THEN 'ferry'
  WHEN method LIKE '%徒歩%' OR method LIKE '%自転車%' OR method LIKE '%チャリ%'
    OR lower(method) LIKE '%walk%' OR lower(method) LIKE '%bicycle%'
    THEN 'walk_bicycle'
  WHEN method LIKE '%飛行機%' OR method LIKE '%空路%' OR lower(method) LIKE '%ana%'
    OR lower(method) LIKE '%jal%' OR lower(method) LIKE '%plane%'
    OR lower(method) LIKE '%flight%' THEN 'airplane'
  WHEN method LIKE '%バス%' OR lower(method) LIKE '%bus%' THEN 'local_bus'
  WHEN method LIKE '%電車%' OR method LIKE '%在来線%' OR lower(method) LIKE '%jr%'
    OR method LIKE '%私鉄%' OR method LIKE '%地下鉄%' OR method LIKE '%鉄道%'
    OR lower(method) LIKE '%train%' THEN 'train'
  ELSE 'other'
END''';

/// 既知の交通手段コード（移行で「既にコードか」を判定する）。
const String transportMethodKnownCodesInList =
    "('shinkansen','train','airplane','highway_bus','local_bus','private_car',"
    "'rental_car','ferry','taxi','walk_bicycle','other')";

/// メモ複数化（v12 / Supabase 0018）で、既存メモの title 初期値を種類名にする
/// CASE 式（category コード→日本語ラベル）。SQLite・Postgres 双方で動く。
const String memoTitleFromCategoryCaseSql = '''
CASE category
  WHEN 'free' THEN '自由メモ'
  WHEN 'goods' THEN '物販'
  WHEN 'meetup' THEN '集合場所'
  WHEN 'around' THEN '周辺施設'
  WHEN 'notice' THEN '注意事項'
  ELSE 'メモ'
END''';

/// 同一計画に同じ交通(transport_id)／宿泊(lodging_id)を参照する重複した旅程
/// 項目を、決定的に1件だけ残して他を選び出す相関サブクエリ（部分ユニーク
/// インデックス作成前に重複を除去する, schema v9 / Phase 2レビュー点1）。
///
/// 保持する1件の選択規則は cover dedup と同じ: `sort_order` 昇順 →
/// `created_at` 昇順 → `id` 昇順 で最小のもの。それより小さい重複が存在する
/// 行（＝負け側）の id を返す。transport/lodging それぞれで判定して UNION する。
const String _itineraryEntryReferenceLoserIdsSql = '''
SELECT e.id FROM itinerary_entries e
WHERE e.transport_id IS NOT NULL AND EXISTS (
  SELECT 1 FROM itinerary_entries o
  WHERE o.plan_id = e.plan_id AND o.transport_id = e.transport_id
    AND o.id <> e.id
    AND (o.sort_order < e.sort_order
      OR (o.sort_order = e.sort_order AND o.created_at < e.created_at)
      OR (o.sort_order = e.sort_order AND o.created_at = e.created_at
          AND o.id < e.id)))
UNION
SELECT e.id FROM itinerary_entries e
WHERE e.lodging_id IS NOT NULL AND EXISTS (
  SELECT 1 FROM itinerary_entries o
  WHERE o.plan_id = e.plan_id AND o.lodging_id = e.lodging_id
    AND o.id <> e.id
    AND (o.sort_order < e.sort_order
      OR (o.sort_order = e.sort_order AND o.created_at < e.created_at)
      OR (o.sort_order = e.sort_order AND o.created_at = e.created_at
          AND o.id < e.id)))''';

/// ローカルDB（Drift / SQLite, ADR-0005）。
///
/// 役割: 画面用キャッシュ・下書き・Outbox。サーバー（Supabase）のスキーマと
/// 列名の意味を一致させ、日付は `yyyy-MM-dd`、タイムスタンプは UTC ISO8601 の
/// TEXT で保持する（タイムゾーン事故を避けるため数値epochを使わない）。
@DataClassName('GenbaRow')
class Genbas extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get artistName => text()();
  TextColumn get title => text()();
  TextColumn get eventDate => text()();
  TextColumn get oshiGroupId => text().nullable()();
  TextColumn get oshiMemberIds => text().withDefault(const Constant('[]'))();
  TextColumn get venue => text().nullable()();

  /// 会場の住所・Google Place ID（会場のGoogle連携, schema v18）。座標は
  /// Places の Field Mask 対象外のため保存しない。
  TextColumn get venueAddress => text().nullable()();
  TextColumn get venueGooglePlaceId => text().nullable()();
  IntColumn get doorTimeMinutes => integer().nullable()();
  IntColumn get startTimeMinutes => integer().nullable()();
  IntColumn get endTimeMinutes => integer().nullable()();

  /// 公演種別の安定コード（選択式, schema v10）。旧・自由入力は v10 で変換。
  TextColumn get performanceType => text().nullable()();

  /// [PerformanceType.other] の補足自由入力・変換不能な旧自由入力の保持（v10）。
  TextColumn get performanceTypeOther => text().nullable()();
  TextColumn get performanceId => text().nullable()();
  BoolColumn get isExpedition => boolean().nullable()();
  TextColumn get transportRequirement =>
      text().withDefault(const Constant('unknown'))();
  TextColumn get lodgingRequirement =>
      text().withDefault(const Constant('unknown'))();
  BoolColumn get isCanceled => boolean().withDefault(const Constant(false))();

  /// 明示参加状態（planned/attended/not_attended/canceled, schema v5）。
  /// 日時から自動導出しない。is_canceled と整合させる（normalizeAttendance）。
  TextColumn get attendanceStatus =>
      text().withDefault(const Constant('planned'))();
  TextColumn get manualEndedAt => text().nullable()();

  /// ヒーロー画像の端末内相対参照（同期対象外, H-04, schema v4）。
  TextColumn get heroImageLocalPath => text().nullable()();

  /// ヒーロー画像の Storage パス・アップロード状態・代替説明（同期対象, v5）。
  TextColumn get heroImageStoragePath => text().nullable()();
  TextColumn get heroImageUploadStatus =>
      text().withDefault(const Constant('local_only'))();
  TextColumn get heroImageAltText => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TicketRow')
class Tickets extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get acquisitionStatus =>
      text().withDefault(const Constant('not_applied'))();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('unpaid'))();
  TextColumn get issuanceStatus =>
      text().withDefault(const Constant('not_issued'))();
  TextColumn get seat => text().nullable()();
  TextColumn get entryNumber => text().nullable()();
  TextColumn get gate => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get imageLocalPath => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransportRow')
class Transports extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get direction => text().withDefault(const Constant('outbound'))();

  /// 交通手段の安定コード（選択式, schema v11）。旧・自由入力は v11 で変換。
  TextColumn get method => text().nullable()();

  /// [TransportMethod.other] の補足自由入力・変換不能な旧自由入力の保持（v11）。
  TextColumn get methodOther => text().nullable()();
  TextColumn get fromPlace => text().nullable()();
  TextColumn get toPlace => text().nullable()();
  TextColumn get departAt => text().nullable()();
  TextColumn get arriveAt => text().nullable()();
  TextColumn get reservationNumber => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LodgingRow')
class Lodgings extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text().nullable()();
  TextColumn get checkinDate => text().nullable()();
  TextColumn get checkoutDate => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get reservationNumber => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TodoRow')
class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();

  /// 項目種別（'todo'/'belonging', schema v6）。既存データは 'todo' 扱い。
  TextColumn get type => text().withDefault(const Constant('todo'))();
  TextColumn get dueDate => text().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  TextColumn get assignee => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get memo => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GenbaMemoRow')
class GenbaMemos extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get category => text()();

  /// メモ種類（§7.7 改訂, schema v15）: free/checklist/bingo/vote。既存は free。
  TextColumn get kind => text().withDefault(const Constant('free'))();

  /// メモのタイトル（複数メモ化, schema v12）。既存行は種類名を初期値に移行。
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();

  /// 種類別の構造化コンテンツ（JSON, schema v15）。自由メモは NULL。
  TextColumn get content => text().nullable()();

  /// 現場内の並び順（v12）。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  // v12 で「現場×種類ごと1件」のユニーク制約を撤廃し、同一種類の複数メモを許容。
}

/// プレミアムentitlement（旅程Phase 4 / schema v16）。サーバー（Supabase
/// `user_entitlements`）が管理する値の**読み取り専用レプリカ**。クライアントは
/// このテーブルへ一切書き込まない（Outbox対象外）。行が無い owner は非プレミアム
/// として扱う（itinerary-plan-spec §14.4、D-214）。
@DataClassName('RoutesEntitlementRow')
class RoutesEntitlements extends Table {
  TextColumn get ownerId => text()();
  BoolColumn get premiumRoutesLive =>
      boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId};
}

/// 現場共有（Phase 5 前提基盤 / schema v17）。owner（現場の所有者）が現場を
/// editor/viewer へ共有する行。owner スコープで保存・同期し、grantee はサーバー
/// RLS で「自分に共有された行」を読めるが、この**ローカル表には owner（自分が
/// 共有した行）だけ**が入る（`applyPulledRowsInto` の owner フィルタ）。項目単位の
/// 共有可否は grant* で保持（安全側＝既定 false, §7.8 / ADR-0008）。
@DataClassName('GenbaShareRow')
class GenbaShares extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get genbaId => text()();
  TextColumn get granteeId => text()();
  TextColumn get role => text()();
  BoolColumn get grantTicketImage =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get grantReservation =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get grantAddress => boolean().withDefault(const Constant(false))();
  BoolColumn get grantImpression =>
      boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// メモテンプレート（§7.7 改訂 / schema v15）。Todo テンプレートと同様に owner
/// スコープで保存・同期する。雛形の構造化データは content(JSON) に持つ（単一行）。
@DataClassName('MemoTemplateRow')
class MemoTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get kind => text().withDefault(const Constant('free'))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get content => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MemoryEntryRow')
class MemoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text().unique()();
  TextColumn get ownerId => text()();
  TextColumn get impression => text().withDefault(const Constant(''))();
  TextColumn get bestMoment => text().withDefault(const Constant(''))();
  TextColumn get mcNotes => text().withDefault(const Constant(''))();
  TextColumn get seatView => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get declinedFields => text().withDefault(const Constant('[]'))();

  /// 思い出単位のお気に入り（同期対象, schema v5）。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MemoryPhotoRow')
class MemoryPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get storagePath => text().nullable()();
  TextColumn get uploadStatus =>
      text().withDefault(const Constant('local_only'))();
  TextColumn get caption => text().nullable()();
  BoolColumn get isCover => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// アルバム分類（§8.4）: event / goods / visited_place / food。
  TextColumn get albumCategory => text().withDefault(const Constant('event'))();

  /// 関連項目の種別（goods / visited_place）。当日の写真では null。
  TextColumn get subjectType => text().nullable()();

  /// 関連項目のID（緩い参照。項目削除後も写真はアルバムへ残す, §8.4）。
  TextColumn get subjectId => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 画像ファイル削除の再試行キュー（§8.4 / Issue1）。写真メタデータの削除は
/// DB トランザクションで原子的に確定し、端末内の画像ファイル削除は分離して
/// このキュー経由で行う。DB 削除後にファイル削除が失敗しても無視せず、この
/// テーブルに残して再試行対象とする（成功時のみ行を除去する）。
/// 端末ローカルのみで同期対象外。
@DataClassName('PendingImageDeletionRow')
class PendingImageDeletions extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();

  /// 削除対象の画像参照（[ImageStore] の owner スコープ相対参照）。
  TextColumn get ref => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SetlistItemRow')
class SetlistItems extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  IntColumn get position => integer()();
  TextColumn get songTitle => text()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoodsItemRow')
class GoodsItems extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  IntColumn get price => integer().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get memo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VisitedPlaceRow')
class VisitedPlaces extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('spot'))();
  TextColumn get memo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OshiGroupRow')
class OshiGroups extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get kind => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get memo => text().nullable()();

  /// グループ画像の端末内相対参照（同期対象外, H-04, schema v5）。
  TextColumn get imageLocalPath => text().nullable()();

  /// グループ画像の代替説明（同期対象, v5）。
  TextColumn get imageAltText => text().nullable()();

  /// グループ単位のお気に入り（同期対象, v5）。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OshiMemberRow')
class OshiMembers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get rank => text().withDefault(const Constant('oshi'))();
  TextColumn get color => text().nullable()();
  TextColumn get oshiSince => text().nullable()();
  TextColumn get birthday => text().nullable()();
  TextColumn get memo => text().nullable()();

  /// 推し画像の端末内相対参照（同期対象外, H-04, schema v4）。
  TextColumn get imageLocalPath => text().nullable()();

  /// 推し画像の代替説明（同期対象, v5）。
  TextColumn get imageAltText => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Todo・持ち物のテンプレート（owner 単位, schema v7）。マイ推しと同じく
/// 現場に属さず owner に属する。item_type で Todo/持ち物の種別が固定される。
@DataClassName('TodoTemplateRow')
class TodoTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();

  /// 種別（'todo'/'belonging'）。テンプレート内の全項目がこの種別。
  TextColumn get itemType => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// テンプレートに含まれる項目（schema v7）。適用時に現場の Todo/持ち物へ複製。
/// priority は Todo テンプレートのみ（持ち物は null）。期限・担当・完了状態は
/// 現場固有情報なので保存しない。
@DataClassName('TodoTemplateItemRow')
class TodoTemplateItems extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get priority => text().nullable()();
  TextColumn get memo => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// ユーザー定義の記念日（design-spec §10/§12.1, schema v5）。グループに属し、
/// 任意でメンバーへ紐づく。誕生日・推し始めた日とは別に自由登録する。
@DataClassName('OshiAnniversaryRow')
class OshiAnniversaries extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get groupId => text()();
  TextColumn get memberId => text().nullable()();
  TextColumn get label => text()();
  TextColumn get date => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 現場の計画（旅程）。1現場につき既定で1件だが、DBは将来の複数旅程に
/// 備えて1対多を許容する（schema v8, itinerary-plan-spec.md §12.1）。
@DataClassName('ItineraryPlanRow')
class ItineraryPlans extends Table {
  TextColumn get id => text()();
  TextColumn get genbaId => text()();
  TextColumn get ownerId => text()();
  TextColumn get title => text()();
  TextColumn get memo => text().nullable()();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get timeZoneId => text()();
  TextColumn get coverImageLocalPath => text().nullable()();
  TextColumn get coverImageStoragePath => text().nullable()();
  TextColumn get coverImageUploadStatus =>
      text().withDefault(const Constant('local_only'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 計画に登録するスポット（施設・訪問先）。訪問予定（[ItineraryEntries]）とは
/// 分離し、同じスポットを複数回予定できる（schema v8, §12.2）。
@DataClassName('ItinerarySpotRow')
class ItinerarySpots extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get ownerId => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get googlePlaceId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get address => text().nullable()();

  /// 永続する名称・住所の出典・権利根拠（既定はユーザー入力, §12.2）。
  TextColumn get dataOrigin =>
      text().withDefault(const Constant('user_provided'))();
  TextColumn get rightsBasis => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get websiteUrl => text().nullable()();
  TextColumn get openingHoursText => text().nullable()();
  TextColumn get googleMapsUrl => text().nullable()();
  TextColumn get googleFetchedAt => text().nullable()();
  TextColumn get googlePhotoName => text().nullable()();
  TextColumn get googlePhotoAttribution => text().nullable()();
  TextColumn get userImageLocalPath => text().nullable()();
  TextColumn get userImageStoragePath => text().nullable()();
  TextColumn get userImageUploadStatus =>
      text().withDefault(const Constant('local_only'))();
  TextColumn get userImageAltText => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// スポットに複数保持できる種別つきURL（schema v8, §12.3/§4.5）。
@DataClassName('ItinerarySpotLinkRow')
class ItinerarySpotLinks extends Table {
  TextColumn get id => text()();
  TextColumn get spotId => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  TextColumn get url => text()();
  TextColumn get label => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 旅程タイムラインの1項目（schema v8, §12.4）。kind に応じて spot_id /
/// transport_id / lodging_id のうち1つだけを持つ（ドメイン層で検証）。
/// transport_id / lodging_id は他機能（genba）のテーブルを参照するだけで
/// FK を張らない（参照元削除時に勝手に消さず「参照切れ」として検出する
/// 設計のため。§5.3）。
@DataClassName('ItineraryEntryRow')
class ItineraryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  TextColumn get spotId => text().nullable()();
  TextColumn get transportId => text().nullable()();
  TextColumn get lodgingId => text().nullable()();
  TextColumn get titleOverride => text().nullable()();
  TextColumn get startAt => text().nullable()();
  TextColumn get endAt => text().nullable()();
  TextColumn get localDate => text().nullable()();
  TextColumn get timeZoneId => text().nullable()();
  IntColumn get bufferBeforeMinutes =>
      integer().withDefault(const Constant(0))();
  IntColumn get bufferAfterMinutes =>
      integer().withDefault(const Constant(0))();
  TextColumn get memo => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// スポット間の移動区間（schema v8, §12.5/§6.2）。
@DataClassName('ItineraryLegRow')
class ItineraryLegs extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  TextColumn get ownerId => text()();
  TextColumn get originEntryId => text()();
  TextColumn get destinationEntryId => text()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get travelMode => text().withDefault(const Constant('other'))();
  TextColumn get departureAt => text().nullable()();
  TextColumn get arrivalAt => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  IntColumn get distanceMeters => integer().nullable()();
  IntColumn get fareAmountMinor => integer().nullable()();
  TextColumn get fareCurrency => text().nullable()();

  /// 永続する概算経路値の出典・権利根拠・代表時刻帯・最終確認（§12.5）。
  TextColumn get valueOrigin =>
      text().withDefault(const Constant('user_provided'))();
  TextColumn get rightsBasis => text().nullable()();
  TextColumn get representativeTimeBucket => text().nullable()();
  TextColumn get lastVerifiedAt => text().nullable()();
  TextColumn get routeSummary => text().nullable()();
  TextColumn get transitStepsJson => text().nullable()();
  TextColumn get encodedPolyline => text().nullable()();
  TextColumn get googleMapsUrl => text().nullable()();
  TextColumn get fetchedAt => text().nullable()();
  TextColumn get cacheKey => text().nullable()();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Outbox（未同期変更キュー）。
@DataClassName('OutboxOpRow')
class OutboxOps extends Table {
  TextColumn get mutationId => text()();
  TextColumn get ownerId => text()();
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  TextColumn get opType => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// 次に再送してよい時刻（UTC ISO8601）。バックオフ待機中はこの時刻まで
  /// 送信対象にしない（H-02）。再起動後もこの値で待機を復元する。null は即送信可。
  TextColumn get nextRetryAt => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {mutationId};
}

/// 各エンティティのサーバー既知バージョン（H-02 の競合制御）。
///
/// サーバー側 `version`（書き込みごとに単調増加）を owner/table/id 単位で
/// キャッシュし、upsert 送信時に「自分が把握している版（base_version）」として
/// 添える。サーバー RPC がこの版と現在版を比較し、食い違えば競合とする。
/// これにより競合判定を端末時計に依存させない。
@DataClassName('RemoteVersionRow')
class RemoteVersions extends Table {
  TextColumn get ownerId => text()();
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId, entityTable, entityId};
}

/// 端末ローカル設定（チュートリアル完了、テーマ、デモユーザー等）。
@DataClassName('AppKvRow')
class AppKvs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// フォーム下書き（自動保存・再開、§2.1）。
///
/// owner_id を主キーへ含める（C-01）。下書きは端末内のみで完結し
/// サーバーへ同期しないため、同一端末で複数ユーザーが使っても
/// 「genba_form_new」等の下書きキーが owner をまたいで衝突しないようにする。
@DataClassName('FormDraftRow')
class FormDrafts extends Table {
  TextColumn get ownerId => text()();
  TextColumn get key => text()();
  TextColumn get payload => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId, key};
}

@DriftDatabase(
  tables: [
    Genbas,
    Tickets,
    Transports,
    Lodgings,
    Todos,
    GenbaMemos,
    MemoryEntries,
    MemoryPhotos,
    PendingImageDeletions,
    SetlistItems,
    GoodsItems,
    VisitedPlaces,
    OshiGroups,
    OshiMembers,
    OshiAnniversaries,
    TodoTemplates,
    TodoTemplateItems,
    MemoTemplates,
    RoutesEntitlements,
    GenbaShares,
    ItineraryPlans,
    ItinerarySpots,
    ItinerarySpotLinks,
    ItineraryEntries,
    ItineraryLegs,
    OutboxOps,
    AppKvs,
    FormDrafts,
    RemoteVersions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// v2（C-01）: owner 絞り込み索引 + form_drafts の owner 複合キー。
  /// v3（H-02）: outbox_ops.next_retry_at（バックオフ復元）+ remote_versions
  /// テーブル（サーバー版キャッシュによる競合制御）。
  /// v4（H-04）: genbas.hero_image_local_path / oshi_members.image_local_path
  /// （端末内画像の相対参照。同期対象外の nullable 列を安全に追加）。
  /// v5（H-05）: 画像基調UIのデータ契約。参加状態・hero画像storage/upload/alt・
  /// 思い出isFavorite・推しグループ画像/alt/favorite・推しメンalt・
  /// 記念日テーブル・cover一意インデックス。既存データは安全な既定値へ移行し、
  /// is_canceled=true は attendance_status=canceled へ明示移行する。
  /// v6: todos.type（Todo/持ち物の種別）。既存行は既定値 'todo' のまま扱う
  /// （後方互換, nullable にせず安全な既定値を持つ列として追加）。
  /// v7: todo_templates / todo_template_items（Todo・持ち物のテンプレート）。
  /// 新規テーブルの追加のみで、既存データには一切触れない。
  /// v8: itinerary_plans / itinerary_spots / itinerary_spot_links /
  /// itinerary_entries / itinerary_legs（現場詳細「計画」タブの旅程基盤,
  /// itinerary-plan-spec.md）。新規テーブルの追加のみで、既存データには
  /// 一切触れない。
  /// v9: 同一計画に同じ交通/宿泊を二重参照する項目を禁じる部分ユニーク索引を
  /// 版付きで必ず作成する（Phase 2レビュー点1）。作成前に既存重複を決定的に
  /// 1件へ整理し、削除する重複を端点とする移動区間・未送信 Outbox も併せて
  /// 掃除して参照整合を保つ（v8で `_createOwnerIndices` に紛れていた索引作成を、
  /// cover 索引と同じ「dedup→版付き作成」方式へ格上げする）。
  /// v10: genbas.performance_type を選択式の安定コードへ移行し、変換不能な
  /// 旧・自由入力を失わないための genbas.performance_type_other を追加する。
  /// v11: transports.method を選択式の安定コードへ移行し、変換不能な旧・自由入力
  /// を失わないための transports.method_other を追加する（§7.5）。
  /// v12: genba_memos を「現場×種類ごと1件」から複数可へ変更。title/sort_order を
  /// 追加し、{genba_id, category} のユニーク制約を撤廃する（§7.7）。既存メモは
  /// 消さず、title は種類名を初期値に移行する。
  ///
  /// v13: memory_photos にアルバム分類 album_category / 関連項目 subject_type /
  /// subject_id を追加（§8.4）。既存写真は album_category='event' へ移行し消さない。
  /// 写真の保存元は memory_photos に一本化し、画面ごとに複製しない。
  ///
  /// v14: pending_image_deletions（画像ファイル削除の再試行キュー, Issue1）を
  /// 追加。写真メタデータ削除は DB トランザクションで確定し、ファイル削除失敗は
  /// このキューへ残す。新規テーブルの追加のみで既存データには触れない。
  ///
  /// v15: メモ種類（§7.7 改訂）。genba_memos に kind/content を追加（既存メモは
  /// kind='free'・content=NULL の自由メモ扱い、消さない）。memo_templates
  /// テーブルを新規追加（Todo テンプレートと同思想の保存・再利用）。
  ///
  /// v16: 旅程Phase 4（Google Routes連携）。routes_entitlements（プレミアム
  /// entitlementの読み取り専用レプリカ、クライアントは書き込まない）を新規
  /// 追加。新規テーブルの追加のみで既存データには一切触れない。
  ///
  /// v17: Phase 5 前提基盤（現場共有データ基盤）。genba_shares（owner が現場を
  /// editor/viewer へ共有する行・項目単位grant）を新規追加。新規テーブルの追加
  /// のみで既存データには一切触れない。
  ///
  /// v18: 会場のGoogle連携。genbas へ venue_address / venue_google_place_id の
  /// nullable 列を追加（既存データは null のまま）。
  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createOwnerIndices(m);
          await _createCoverUniqueIndex(m);
          await _createItineraryReferenceUniqueIndices(m);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // 下書きは owner 情報を持たない旧スキーマのため、推測して
            // 割り当てず安全側に倒して破棄する（新スキーマで作り直す）。
            await m.deleteTable('form_drafts');
            await m.createTable(formDrafts);
          }
          if (from < 3) {
            await m.addColumn(outboxOps, outboxOps.nextRetryAt);
            await m.createTable(remoteVersions);
          }
          if (from < 4) {
            // 既存データを保持したまま nullable 列を追加する（既存行は null）。
            await m.addColumn(genbas, genbas.heroImageLocalPath);
            await m.addColumn(oshiMembers, oshiMembers.imageLocalPath);
          }
          if (from < 5) {
            await m.addColumn(genbas, genbas.attendanceStatus);
            await m.addColumn(genbas, genbas.heroImageStoragePath);
            await m.addColumn(genbas, genbas.heroImageUploadStatus);
            await m.addColumn(genbas, genbas.heroImageAltText);
            await m.addColumn(memoryEntries, memoryEntries.isFavorite);
            await m.addColumn(oshiGroups, oshiGroups.imageLocalPath);
            await m.addColumn(oshiGroups, oshiGroups.imageAltText);
            await m.addColumn(oshiGroups, oshiGroups.isFavorite);
            await m.addColumn(oshiMembers, oshiMembers.imageAltText);
            await m.createTable(oshiAnniversaries);
            // 既存の中止済み現場を参加状態 canceled へ明示移行する。
            // 過去公演を勝手に attended へ推測しない（既定は planned のまま）。
            await m.database.customStatement(
              "UPDATE genbas SET attendance_status = 'canceled' "
              'WHERE is_canceled = 1',
            );
            // cover 一意インデックス作成前に、既存データの重複 cover を
            // 決定的に1件へ整理する（複数 cover でも migration が失敗しない,
            // R6独立レビュー#5）。既存写真は削除せず is_cover のみ修正する。
            await m.database.customStatement(dedupeMemoryCoversSql);
          }
          if (from < 6) {
            // 既存Todoはすべて 'todo' 種別として扱う（後方互換）。
            await m.addColumn(todos, todos.type);
          }
          if (from < 7) {
            // 新規テーブルの追加のみ（既存データには触れない）。
            await m.createTable(todoTemplates);
            await m.createTable(todoTemplateItems);
          }
          if (from < 8) {
            // 新規テーブルの追加のみ（既存データには触れない）。
            await m.createTable(itineraryPlans);
            await m.createTable(itinerarySpots);
            await m.createTable(itinerarySpotLinks);
            await m.createTable(itineraryEntries);
            await m.createTable(itineraryLegs);
          }
          if (from < 9) {
            // 交通/宿泊の部分ユニーク索引を張る前に、同一計画に同じ交通/宿泊を
            // 二重参照する既存項目を決定的に1件へ整理する（既存重複があっても
            // 索引作成が失敗しない, Phase 2レビュー点1）。cover 索引と同じ
            // 「dedup→版付き作成」方式（下の _createItineraryReferenceUniqueIndices）。
            await _dedupeItineraryEntryReferences(m);
          }
          if (from < 10) {
            // 公演種別を選択式の安定コードへ移行する（自由入力廃止, §7.1）。
            // addColumn は列が未存在のときだけ行う（冪等。テストで最新スキーマから
            // user_version だけ戻して onUpgrade を走らせても二重追加で失敗しない）。
            if (!await _hasColumn(m, 'genbas', 'performance_type_other')) {
              await m.addColumn(genbas, genbas.performanceTypeOther);
            }
            // 変換不能な旧・自由入力を失わないよう、コード以外の値を other 領域へ
            // 退避してから変換し、既知コードへ変換できた行の退避は消す。
            await m.database.customStatement(
              'UPDATE genbas SET performance_type_other = performance_type '
              "WHERE performance_type IS NOT NULL AND trim(performance_type) <> '' "
              'AND performance_type NOT IN $performanceTypeKnownCodesInList',
            );
            await m.database.customStatement(
              'UPDATE genbas SET performance_type = $performanceTypeCodeCaseSql '
              "WHERE performance_type IS NOT NULL AND trim(performance_type) <> ''",
            );
            await m.database.customStatement(
              'UPDATE genbas SET performance_type_other = NULL '
              "WHERE performance_type <> 'other'",
            );
          }
          if (from < 11) {
            // 交通手段を選択式の安定コードへ移行する（自由入力廃止, §7.5）。
            if (!await _hasColumn(m, 'transports', 'method_other')) {
              await m.addColumn(transports, transports.methodOther);
            }
            await m.database.customStatement(
              'UPDATE transports SET method_other = method '
              "WHERE method IS NOT NULL AND trim(method) <> '' "
              'AND method NOT IN $transportMethodKnownCodesInList',
            );
            await m.database.customStatement(
              'UPDATE transports SET method = $transportMethodCodeCaseSql '
              "WHERE method IS NOT NULL AND trim(method) <> ''",
            );
            await m.database.customStatement(
              'UPDATE transports SET method_other = NULL '
              "WHERE method <> 'other'",
            );
          }
          if (from < 12) {
            // メモを複数化する（§7.7）。SQLite はユニーク制約を後から落とせない
            // ため、新テーブルへコピーして差し替える。既存メモは消さず、title は
            // 種類名を初期値にする。sort_order は 0。
            await m.database.customStatement(
              'CREATE TABLE genba_memos_new ('
              'id TEXT NOT NULL PRIMARY KEY, '
              'genba_id TEXT NOT NULL, '
              'owner_id TEXT NOT NULL, '
              'category TEXT NOT NULL, '
              "title TEXT NOT NULL DEFAULT '', "
              "body TEXT NOT NULL DEFAULT '', "
              'sort_order INTEGER NOT NULL DEFAULT 0, '
              'created_at TEXT NOT NULL, '
              'updated_at TEXT NOT NULL)',
            );
            await m.database.customStatement(
              'INSERT INTO genba_memos_new '
              '(id, genba_id, owner_id, category, title, body, sort_order, '
              'created_at, updated_at) '
              'SELECT id, genba_id, owner_id, category, '
              '$memoTitleFromCategoryCaseSql, body, 0, created_at, updated_at '
              'FROM genba_memos',
            );
            await m.database.customStatement('DROP TABLE genba_memos');
            await m.database.customStatement(
              'ALTER TABLE genba_memos_new RENAME TO genba_memos',
            );
          }
          if (from < 13) {
            // 思い出写真へアルバム分類・関連項目を追加する（§8.4）。addColumn は
            // 列が未存在のときだけ行う（冪等。最新スキーマから user_version を
            // 戻して onUpgrade を走らせても二重追加で失敗しない）。既存写真は
            // 消さず、分類は 'event'（当日の写真）へ移行する。
            if (!await _hasColumn(m, 'memory_photos', 'album_category')) {
              await m.addColumn(memoryPhotos, memoryPhotos.albumCategory);
            }
            if (!await _hasColumn(m, 'memory_photos', 'subject_type')) {
              await m.addColumn(memoryPhotos, memoryPhotos.subjectType);
            }
            if (!await _hasColumn(m, 'memory_photos', 'subject_id')) {
              await m.addColumn(memoryPhotos, memoryPhotos.subjectId);
            }
            await m.database.customStatement(
              "UPDATE memory_photos SET album_category = 'event' "
              "WHERE album_category IS NULL OR trim(album_category) = ''",
            );
          }
          if (from < 14) {
            // 画像削除の再試行キュー（新規テーブルの追加のみ）。
            await m.createTable(pendingImageDeletions);
          }
          if (from < 15) {
            // メモ種類（§7.7 改訂）。genba_memos へ kind/content を冪等 addColumn
            // し、既存メモは kind='free'（自由メモ）へ移行して消さない。
            if (!await _hasColumn(m, 'genba_memos', 'kind')) {
              await m.addColumn(genbaMemos, genbaMemos.kind);
            }
            if (!await _hasColumn(m, 'genba_memos', 'content')) {
              await m.addColumn(genbaMemos, genbaMemos.content);
            }
            await m.database.customStatement(
              "UPDATE genba_memos SET kind = 'free' "
              "WHERE kind IS NULL OR trim(kind) = ''",
            );
            // メモテンプレート（新規テーブルの追加のみ）。
            await m.createTable(memoTemplates);
          }
          if (from < 16) {
            // 旅程Phase 4: プレミアムentitlementの読み取り専用レプリカ
            // （新規テーブルの追加のみ、既存データには一切触れない）。
            await m.createTable(routesEntitlements);
          }
          if (from < 17) {
            // Phase 5 前提基盤: 現場共有データ基盤（新規テーブルの追加のみ、
            // 既存データには一切触れない）。
            await m.createTable(genbaShares);
          }
          if (from < 18) {
            // 会場のGoogle連携（住所・Place ID）。既存データを保持したまま
            // nullable 列を追加する（既存行は null）。列が既にある場合は
            // 二重追加しない（テストの部分スキーマにも安全, _hasColumn ガード）。
            if (!await _hasColumn(m, 'genbas', 'venue_address')) {
              await m.addColumn(genbas, genbas.venueAddress);
            }
            if (!await _hasColumn(m, 'genbas', 'venue_google_place_id')) {
              await m.addColumn(genbas, genbas.venueGooglePlaceId);
            }
          }
          await _createOwnerIndices(m);
          await _createCoverUniqueIndex(m);
          await _createItineraryReferenceUniqueIndices(m);
        },
      );

  /// 同一現場に cover 写真は最大1件（design-spec §12.1）。SQLite の部分
  /// ユニークインデックスで DB レベルで担保する。作成前に
  /// [dedupeMemoryCoversSql] で重複 cover を1件へ整理してあるため、既存データに
  /// 複数 cover があっても作成に失敗しない（R6独立レビュー#5）。
  Future<void> _createCoverUniqueIndex(Migrator m) =>
      m.database.customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_memory_photos_cover_unique '
        'ON memory_photos (genba_id) WHERE is_cover',
      );

  /// 指定テーブルに指定列が存在するか（addColumn を冪等にするための判定）。
  Future<bool> _hasColumn(Migrator m, String table, String column) async {
    final rows = await m.database
        .customSelect("SELECT name FROM pragma_table_info('$table')")
        .get();
    return rows.any((r) => r.data['name'] == column);
  }

  /// 同一計画に同じ交通/宿泊を二重追加させない部分ユニーク索引（§5.3 / DB境界,
  /// schema v9）。作成前に [_dedupeItineraryEntryReferences] で重複を1件へ
  /// 整理してあるため、既存データに重複があっても作成に失敗しない
  /// （cover 一意索引と同じ方針）。`IF NOT EXISTS` で onCreate/onUpgrade の
  /// どちらから呼んでも冪等。
  Future<void> _createItineraryReferenceUniqueIndices(Migrator m) async {
    await m.database.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_itinerary_entries_plan_transport '
      'ON itinerary_entries (plan_id, transport_id) '
      'WHERE transport_id IS NOT NULL',
    );
    await m.database.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_itinerary_entries_plan_lodging '
      'ON itinerary_entries (plan_id, lodging_id) '
      'WHERE lodging_id IS NOT NULL',
    );
  }

  /// v8→v9 で部分ユニーク索引を張る前に、同一計画に同じ交通/宿泊を参照する
  /// 重複項目を決定的に1件へ整理する（勝手削除の影響を決定的に処理する,
  /// Phase 2レビュー点1）。負け側（[_itineraryEntryReferenceLoserIdsSql]）を
  /// 選び、それらを端点とする移動区間(legs)と、重複項目・区間の未送信 Outbox も
  /// 併せて削除して参照整合を保つ。負け側の項目本体は最後に削除する
  /// （相関サブクエリの評価対象を保つため順序が重要）。
  Future<void> _dedupeItineraryEntryReferences(Migrator m) async {
    final db = m.database;
    const losers = _itineraryEntryReferenceLoserIdsSql;
    // 1. 削除対象項目を端点とする移動区間の未送信 Outbox を消す。
    await db.customStatement(
      "DELETE FROM outbox_ops WHERE entity_table = 'itinerary_legs' "
      'AND entity_id IN (SELECT id FROM itinerary_legs '
      'WHERE origin_entry_id IN ($losers) '
      'OR destination_entry_id IN ($losers))',
    );
    // 2. 移動区間そのものを削除する。
    await db.customStatement(
      'DELETE FROM itinerary_legs WHERE origin_entry_id IN ($losers) '
      'OR destination_entry_id IN ($losers)',
    );
    // 3. 削除対象項目の未送信 Outbox を消す。
    await db.customStatement(
      "DELETE FROM outbox_ops WHERE entity_table = 'itinerary_entries' "
      'AND entity_id IN ($losers)',
    );
    // 4. 重複項目本体を削除する（負け側だけ）。
    await db.customStatement(
      'DELETE FROM itinerary_entries WHERE id IN ($losers)',
    );
  }

  /// owner 単位の絞り込み・ソートで使う索引（M-04）。
  /// SQLite の `CREATE INDEX IF NOT EXISTS` を使い、onCreate/onUpgrade の
  /// どちらから呼んでも安全に冪等実行できるようにする。
  Future<void> _createOwnerIndices(Migrator m) async {
    Future<void> idx(String name, String sql) =>
        m.database.customStatement('CREATE INDEX IF NOT EXISTS $name $sql');

    await idx(
      'idx_genbas_owner_date',
      'ON genbas (owner_id, event_date)',
    );
    await idx('idx_tickets_genba', 'ON tickets (genba_id)');
    await idx('idx_tickets_owner', 'ON tickets (owner_id)');
    await idx('idx_transports_genba', 'ON transports (genba_id)');
    await idx('idx_transports_owner', 'ON transports (owner_id)');
    await idx('idx_lodgings_genba', 'ON lodgings (genba_id)');
    await idx('idx_lodgings_owner', 'ON lodgings (owner_id)');
    await idx(
      'idx_todos_owner_due',
      'ON todos (owner_id, due_date)',
    );
    await idx('idx_todos_genba', 'ON todos (genba_id)');
    await idx('idx_genba_memos_owner', 'ON genba_memos (owner_id)');
    await idx('idx_genba_memos_genba', 'ON genba_memos (genba_id)');
    await idx('idx_memory_entries_owner', 'ON memory_entries (owner_id)');
    await idx('idx_memory_photos_owner', 'ON memory_photos (owner_id)');
    await idx('idx_memory_photos_genba', 'ON memory_photos (genba_id)');
    await idx('idx_setlist_items_owner', 'ON setlist_items (owner_id)');
    await idx('idx_setlist_items_genba', 'ON setlist_items (genba_id)');
    await idx('idx_goods_items_owner', 'ON goods_items (owner_id)');
    await idx('idx_goods_items_genba', 'ON goods_items (genba_id)');
    await idx('idx_visited_places_owner', 'ON visited_places (owner_id)');
    await idx('idx_visited_places_genba', 'ON visited_places (genba_id)');
    await idx('idx_oshi_groups_owner', 'ON oshi_groups (owner_id)');
    await idx('idx_oshi_members_owner', 'ON oshi_members (owner_id)');
    await idx('idx_oshi_members_group', 'ON oshi_members (group_id)');
    await idx(
      'idx_oshi_anniversaries_owner',
      'ON oshi_anniversaries (owner_id)',
    );
    await idx(
      'idx_oshi_anniversaries_group',
      'ON oshi_anniversaries (group_id)',
    );
    await idx('idx_todo_templates_owner', 'ON todo_templates (owner_id)');
    await idx(
      'idx_todo_template_items_owner',
      'ON todo_template_items (owner_id)',
    );
    await idx(
      'idx_todo_template_items_template',
      'ON todo_template_items (template_id)',
    );
    await idx('idx_memo_templates_owner', 'ON memo_templates (owner_id)');
    await idx('idx_genba_shares_owner', 'ON genba_shares (owner_id)');
    await idx('idx_genba_shares_genba', 'ON genba_shares (genba_id)');
    await idx(
      'idx_genbas_owner_oshi_group',
      'ON genbas (owner_id, oshi_group_id)',
    );
    await idx('idx_itinerary_plans_owner', 'ON itinerary_plans (owner_id)');
    await idx('idx_itinerary_plans_genba', 'ON itinerary_plans (genba_id)');
    await idx('idx_itinerary_spots_owner', 'ON itinerary_spots (owner_id)');
    await idx('idx_itinerary_spots_plan', 'ON itinerary_spots (plan_id)');
    await idx(
      'idx_itinerary_spot_links_owner',
      'ON itinerary_spot_links (owner_id)',
    );
    await idx(
      'idx_itinerary_spot_links_spot',
      'ON itinerary_spot_links (spot_id)',
    );
    await idx(
      'idx_itinerary_entries_owner',
      'ON itinerary_entries (owner_id)',
    );
    await idx('idx_itinerary_entries_plan', 'ON itinerary_entries (plan_id)');
    await idx(
      'idx_itinerary_entries_spot',
      'ON itinerary_entries (spot_id)',
    );
    await idx(
      'idx_itinerary_entries_transport',
      'ON itinerary_entries (transport_id)',
    );
    await idx(
      'idx_itinerary_entries_lodging',
      'ON itinerary_entries (lodging_id)',
    );
    await idx('idx_itinerary_legs_owner', 'ON itinerary_legs (owner_id)');
    await idx('idx_itinerary_legs_plan', 'ON itinerary_legs (plan_id)');
    await idx(
      'idx_itinerary_legs_origin',
      'ON itinerary_legs (origin_entry_id)',
    );
    await idx(
      'idx_itinerary_legs_destination',
      'ON itinerary_legs (destination_entry_id)',
    );
    // 交通/宿泊の二重追加を防ぐ部分ユニーク索引は、重複整理を伴う版付き
    // マイグレーション（schema v9）として [_createItineraryReferenceUniqueIndices]
    // で別建てに作成する（cover 一意索引と同じ方針）。ここでは作らない。
    await idx(
      'idx_outbox_ops_owner_status',
      'ON outbox_ops (owner_id, status)',
    );
    await idx(
      'idx_outbox_ops_entity',
      'ON outbox_ops (entity_table, entity_id, owner_id)',
    );
    await idx(
      'idx_outbox_ops_owner_retry',
      'ON outbox_ops (owner_id, status, next_retry_at)',
    );
    await idx(
      'idx_remote_versions_owner',
      'ON remote_versions (owner_id)',
    );
  }
}
