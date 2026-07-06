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
  IntColumn get doorTimeMinutes => integer().nullable()();
  IntColumn get startTimeMinutes => integer().nullable()();
  IntColumn get endTimeMinutes => integer().nullable()();
  TextColumn get performanceType => text().nullable()();
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
  TextColumn get method => text().nullable()();
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
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {genbaId, category},
      ];
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
    SetlistItems,
    GoodsItems,
    VisitedPlaces,
    OshiGroups,
    OshiMembers,
    OshiAnniversaries,
    TodoTemplates,
    TodoTemplateItems,
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
  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createOwnerIndices(m);
          await _createCoverUniqueIndex(m);
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
          await _createOwnerIndices(m);
          await _createCoverUniqueIndex(m);
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
