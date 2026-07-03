import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_mappers.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// 端末内画像参照（hero/oshi）が同期対象外であること、DB に永続化されて
/// 再起動後も残ること、pull で null 上書きされないことの検証（H-04 item6/7）。
void main() {
  late AppDatabase db;
  late OutboxStore outbox;
  late SyncEngine engine;
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  SyncEngine makeEngine() => SyncEngine(
        store: outbox,
        snapshotResolver: () => null,
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      );

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    outbox = OutboxStore(db, clock);
    engine = makeEngine();
    addTearDown(engine.dispose);
  });

  GenbaRepositoryImpl genbaRepo() => GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-1',
        remoteResolver: () => null,
      );

  OshiRepositoryImpl oshiRepo() => OshiRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-1',
        remoteResolver: () => null,
      );

  test('genba: ヒーロー画像参照は Outbox payload に載らず、DB には永続化される', () async {
    final repo = genbaRepo();
    final genba = makeGenba(eventDate: DateTime(2026, 8, 1)).copyWith(
      heroImageLocalPath: 'images/user-1/hero/hero-1.jpg',
    );
    final result = await repo.upsertGenba(genba);
    expect(result.isOk, isTrue);

    // 同期 payload には端末内参照を含めない（サーバーへ送らない）。
    final ops = await outbox.pendingOps(ownerId: 'user-1');
    expect(ops, hasLength(1));
    expect(ops.first.payload.containsKey('hero_image_local_path'), isFalse);

    // DB には保存され、再取得（＝再起動相当）で参照が残る。
    final loaded = await repo.watchAll().first;
    expect(
      loaded.first.genba.heroImageLocalPath,
      'images/user-1/hero/hero-1.jpg',
    );
  });

  test('genba: pull は preserveLocalImage でヒーロー参照を null 上書きしない', () async {
    // ローカルに hero 付きで保存済み。
    await db.into(db.genbas).insertOnConflictUpdate(
          genbaToCompanion(
            makeGenba(eventDate: DateTime(2026, 8, 1)).copyWith(
              heroImageLocalPath: 'images/user-1/hero/keep.jpg',
            ),
          ),
        );

    // サーバー行には hero 列が無い（Genba.fromJson で null になる）。
    final serverGenba = makeGenba(eventDate: DateTime(2026, 8, 1))
        .copyWith(title: 'from-server');

    // preserve=true（pull 相当）: hero は保持される。
    await db.into(db.genbas).insertOnConflictUpdate(
          genbaToCompanion(serverGenba, preserveLocalImage: true),
        );
    var row = await (db.select(db.genbas)..where((t) => t.id.equals('genba-1')))
        .getSingle();
    expect(row.title, 'from-server'); // 他の列は反映
    expect(row.heroImageLocalPath, 'images/user-1/hero/keep.jpg'); // 保持

    // 対照: preserve=false ならローカル参照は上書き（null 化）される。
    await db.into(db.genbas).insertOnConflictUpdate(
          genbaToCompanion(serverGenba),
        );
    row = await (db.select(db.genbas)..where((t) => t.id.equals('genba-1')))
        .getSingle();
    expect(row.heroImageLocalPath, isNull);
  });

  test('oshi: 推し画像参照は Outbox payload に載らず、再起動後も残る', () async {
    // グループ（親）→ メンバー（画像付き）を保存。
    await oshiRepo().upsertGroup(
      OshiGroup(
        id: 'grp-1',
        ownerId: 'user-1',
        name: 'グループ',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    final member = OshiMember(
      id: 'mem-1',
      groupId: 'grp-1',
      ownerId: 'user-1',
      name: '推しメンバー',
      imageLocalPath: 'images/user-1/oshi/oshi-1.jpg',
      createdAt: fixedCreatedAt,
      updatedAt: fixedCreatedAt,
    );
    final result = await oshiRepo().upsertMember(member);
    expect(result.isOk, isTrue);

    final ops = await outbox.pendingOps(ownerId: 'user-1');
    final memberOp = ops.firstWhere((o) => o.entityId == 'mem-1');
    expect(memberOp.payload.containsKey('image_local_path'), isFalse);

    // 別のリポジトリインスタンス（＝アプリ再起動相当）で読み直しても残る。
    final reloaded = await oshiRepo().watchAll().first;
    final loadedMember =
        reloaded.expand((g) => g.members).firstWhere((m) => m.id == 'mem-1');
    expect(loadedMember.imageLocalPath, 'images/user-1/oshi/oshi-1.jpg');
  });
}
