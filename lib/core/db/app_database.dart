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
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {mutationId};
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
@DataClassName('FormDraftRow')
class FormDrafts extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
