import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_mappers.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// pull（リモート→ローカル）の差分削除ロジックが owner をまたいで
/// 他ユーザーのローカル行を読み取り・変更・削除しないことを検証する回帰テスト
/// （C-01, R1必須テスト）。
///
/// [GenbaRepositoryImpl.applyPulledRows] は Supabase 接続を必要としない形へ
/// 分離してあるため、擬似的なリモート行（`List<Map<String, dynamic>>`）を
/// 直接渡して決定的に検証できる（docs/decisions.md D-48）。
void main() {
  late AppDatabase db;
  late GenbaRepositoryImpl repo;
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    repo = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
  });

  test('pull差分削除は現在ownerのローカル行だけを対象にし、別ownerの行は消さない', () async {
    // user-1（現在owner）の2件と、user-2（別owner, 同一DB内）の1件を、
    // 既に同期済み（Outboxに未同期変更なし）の状態として直接DBへ用意する。
    // Outboxのpending経由だと「未同期変更は上書きしない」ガードにより
    // どちらも削除対象から除外され、本テストの意図（差分削除そのものの
    // owner境界）を検証できないため。
    await db.into(db.genbas).insertOnConflictUpdate(
          genbaToCompanion(
            makeGenba(
              id: 'g-1',
              ownerId: 'user-1',
              eventDate: DateTime(2026, 8, 1),
            ),
          ),
        );
    await db.into(db.genbas).insertOnConflictUpdate(
          genbaToCompanion(
            makeGenba(
              id: 'g-2',
              ownerId: 'user-1',
              eventDate: DateTime(2026, 8, 2),
            ),
          ),
        );
    await db.into(db.genbas).insertOnConflictUpdate(
          genbaToCompanion(
            makeGenba(
              id: 'g-other',
              ownerId: 'user-2',
              eventDate: DateTime(2026, 8, 3),
            ),
          ),
        );
    final repoB = GenbaRepositoryImpl(
      db: db,
      outbox: OutboxStore(db, clock),
      syncEngine: SyncEngine(
        store: OutboxStore(db, clock),
        snapshotResolver: () => null,
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      ),
      clock: clock,
      ownerIdResolver: () => 'user-2',
      remoteResolver: () => null,
    );

    // サーバー側では g-1 のみ残っている（g-2 はリモートで削除された想定）。
    final remoteRows = [
      makeGenba(id: 'g-1', ownerId: 'user-1', eventDate: DateTime(2026, 8, 1))
          .toJson(),
    ];

    await repo.applyPulledRows(
      'user-1',
      SyncEntity.genbas,
      remoteRows,
      (json) => genbaToCompanion(Genba.fromJson(json)),
      db.genbas,
      (t) => t.id,
      (t) => t.ownerId,
      (r) => r.id,
    );

    final userOneIds =
        (await repo.watchAll().first).map((a) => a.genba.id).toSet();
    expect(userOneIds, {'g-1'}); // g-2 はリモートに存在しないため削除された

    // user-2 の行は一切読まれず・変更されず・削除されない。
    final userTwoIds =
        (await repoB.watchAll().first).map((a) => a.genba.id).toSet();
    expect(userTwoIds, {'g-other'});
  });

  test('pullの取り込みは別ownerとして届いた行を取り込まない（防御的検証）', () async {
    // RLSが正しく機能していれば通常発生しないが、万一 owner_id が
    // 異なる行が rows に混入しても取り込まないことを確認する。
    final foreignRow = makeGenba(
      id: 'g-foreign',
      ownerId: 'user-9',
      eventDate: DateTime(2026, 8, 1),
    ).toJson();

    await repo.applyPulledRows(
      'user-1',
      SyncEntity.genbas,
      [foreignRow],
      (json) => genbaToCompanion(Genba.fromJson(json)),
      db.genbas,
      (t) => t.id,
      (t) => t.ownerId,
      (r) => r.id,
    );

    final ids = (await repo.watchAll().first).map((a) => a.genba.id).toSet();
    expect(ids, isEmpty);
  });

  test('未同期のローカル変更が残る行はpullで上書きされない', () async {
    await repo.upsertGenba(
      makeGenba(id: 'g-1', ownerId: 'user-1', eventDate: DateTime(2026, 8, 1)),
    );
    // g-1 は Outbox に pending として残ったまま（refreshFromRemote を呼んでいない）。
    final remoteRows = [
      makeGenba(
        id: 'g-1',
        ownerId: 'user-1',
        artistName: 'サーバー側の値',
        eventDate: DateTime(2026, 8, 1),
      ).toJson(),
    ];

    await repo.applyPulledRows(
      'user-1',
      SyncEntity.genbas,
      remoteRows,
      (json) => genbaToCompanion(Genba.fromJson(json)),
      db.genbas,
      (t) => t.id,
      (t) => t.ownerId,
      (r) => r.id,
    );

    final aggregate = await repo.watchById('g-1').first;
    // ローカルの自動保存（Outbox pending）が優先され、上書きされない。
    expect(aggregate!.genba.artistName, isNot('サーバー側の値'));
  });
}
