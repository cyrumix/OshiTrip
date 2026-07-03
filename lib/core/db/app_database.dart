import 'package:drift/drift.dart';

part 'app_database.g.dart';

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
  TextColumn get manualEndedAt => text().nullable()();

  /// ヒーロー画像の端末内相対参照（同期対象外, H-04, schema v4）。
  TextColumn get heroImageLocalPath => text().nullable()();
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
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createOwnerIndices(m);
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
          await _createOwnerIndices(m);
        },
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
