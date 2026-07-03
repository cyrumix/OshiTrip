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
  @override
  int get schemaVersion => 5;

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
    await idx(
      'idx_genbas_owner_oshi_group',
      'ON genbas (owner_id, oshi_group_id)',
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
