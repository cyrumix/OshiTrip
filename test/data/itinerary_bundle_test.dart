import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_mappers.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_repository_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// Phase 2レビュー: 複合保存(saveSpotBundle)の原子性・並び替え(reorderEntries)の
/// 一括ロールバック・交通/宿泊の重複防止（アプリ判定＋DB部分ユニーク索引）を検証。
void main() {
  late AppDatabase db;
  late OutboxStore outbox;
  late SyncEngine engine;
  final clock = FixedClock(DateTime(2026, 7, 6, 12));

  GenbaRepositoryImpl genbaRepoFor(String? owner) => GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      );

  ItineraryRepositoryImpl repoFor(String? owner) => ItineraryRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      );

  setUp(() {
    db = createTestDb();
    addTearDown(db.close);
    outbox = OutboxStore(db, clock);
    engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
  });

  Future<void> seedGenba(String owner, {String id = 'genba-1'}) async {
    final result = await genbaRepoFor(owner).upsertGenba(
      makeGenba(id: id, ownerId: owner, eventDate: DateTime(2026, 8, 1)),
    );
    expect(result.isOk, isTrue);
  }

  Future<ItineraryRepositoryImpl> seedPlan(String owner) async {
    await seedGenba(owner);
    final repo = repoFor(owner);
    expect(
      (await repo.upsertPlan(makeItineraryPlan(ownerId: owner))).isOk,
      true,
    );
    return repo;
  }

  Future<int> spotCount() async =>
      (await db.select(db.itinerarySpots).get()).length;
  Future<int> entryCount() async =>
      (await db.select(db.itineraryEntries).get()).length;
  Future<int> linkCount() async =>
      (await db.select(db.itinerarySpotLinks).get()).length;

  group('saveSpotBundle: 原子的な複合保存', () {
    test('正常系: スポット＋訪問項目＋URLリンクが1件ずつ保存され Outbox も3種積まれる', () async {
      final repo = await seedPlan('user-1');
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(name: '海遊館'),
        entry: makeItineraryEntry(
          id: 'entry-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: [makeItinerarySpotLink(url: 'https://kaiyukan.com')],
      );
      expect(res.isOk, isTrue);
      expect(await spotCount(), 1);
      expect(await entryCount(), 1);
      expect(await linkCount(), 1);

      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where((o) => o.entityTable == SyncEntity.itinerarySpots),
        hasLength(1),
      );
      expect(
        ops.where((o) => o.entityTable == SyncEntity.itinerarySpotLinks),
        hasLength(1),
      );
      expect(
        ops.where((o) => o.entityTable == SyncEntity.itineraryEntries),
        hasLength(1),
      );
      // 端末内画像参照は spot payload に載せない。
      final spotOp =
          ops.firstWhere((o) => o.entityTable == SyncEntity.itinerarySpots);
      expect(spotOp.payload.containsKey('user_image_local_path'), isFalse);
    });

    test('spot段で失敗すると全ロールバック（spotも残さない）', () async {
      final repo = await seedPlan('user-1');
      repo.debugBeforeBundleStage = (stage) {
        if (stage == 'spot') throw StateError('boom-spot');
      };
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(),
        entry: makeItineraryEntry(
          id: 'entry-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: [makeItinerarySpotLink()],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<StorageFailure>());
      expect(await spotCount(), 0);
      expect(await entryCount(), 0);
      expect(await linkCount(), 0);
      // 束の Outbox（spot/link/entry）は積まれない（seed の genba/plan は別）。
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where(
          (o) =>
              o.entityTable == SyncEntity.itinerarySpots ||
              o.entityTable == SyncEntity.itinerarySpotLinks ||
              o.entityTable == SyncEntity.itineraryEntries,
        ),
        isEmpty,
      );
    });

    test('link段で失敗すると spot も含めて全ロールバック', () async {
      final repo = await seedPlan('user-1');
      repo.debugBeforeBundleStage = (stage) {
        if (stage == 'link') throw StateError('boom-link');
      };
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(),
        entry: makeItineraryEntry(
          id: 'entry-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: [makeItinerarySpotLink()],
      );
      expect(res.isOk, isFalse);
      expect(await spotCount(), 0);
      expect(await entryCount(), 0);
      expect(await linkCount(), 0);
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where(
          (o) =>
              o.entityTable == SyncEntity.itinerarySpots ||
              o.entityTable == SyncEntity.itinerarySpotLinks ||
              o.entityTable == SyncEntity.itineraryEntries,
        ),
        isEmpty,
      );
    });

    test('entry段で失敗すると spot・link も全ロールバック', () async {
      final repo = await seedPlan('user-1');
      repo.debugBeforeBundleStage = (stage) {
        if (stage == 'entry') throw StateError('boom-entry');
      };
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(),
        entry: makeItineraryEntry(
          id: 'entry-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: [makeItinerarySpotLink()],
      );
      expect(res.isOk, isFalse);
      expect(await spotCount(), 0);
      expect(await entryCount(), 0);
      expect(await linkCount(), 0);
    });

    test('編集の失敗時は既存データが元の状態のまま保持される', () async {
      final repo = await seedPlan('user-1');
      // 初回保存（成功）。
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(name: '元の名前'),
          entry: makeItineraryEntry(
            id: 'entry-spot',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-1',
          ),
          links: [makeItinerarySpotLink(url: 'https://original.example')],
        ))
            .isOk,
        isTrue,
      );

      // 編集を試みるが entry 段で失敗。
      repo.debugBeforeBundleStage = (stage) {
        if (stage == 'entry') throw StateError('boom-edit');
      };
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(name: '変更後の名前'),
        entry: makeItineraryEntry(
          id: 'entry-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: [
          makeItinerarySpotLink(url: 'https://changed.example'),
        ],
      );
      expect(res.isOk, isFalse);

      // 元の名前・元のリンクが保持される。
      final spot = (await db.select(db.itinerarySpots).get()).single;
      expect(spot.name, '元の名前');
      final link = (await db.select(db.itinerarySpotLinks).get()).single;
      expect(link.url, 'https://original.example');
    });

    test('削除リンクは反映され、失敗時はその削除も含めてロールバックされる', () async {
      final repo = await seedPlan('user-1');
      // link-1, link-2 を持つ状態を作る。
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(),
          entry: makeItineraryEntry(
            id: 'entry-spot',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-1',
          ),
          links: [
            makeItinerarySpotLink(id: 'link-1'),
            makeItinerarySpotLink(id: 'link-2', url: 'https://two.example'),
          ],
        ))
            .isOk,
        isTrue,
      );
      expect(await linkCount(), 2);

      // 成功: link-2 を削除。
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(),
          entry: makeItineraryEntry(
            id: 'entry-spot',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-1',
          ),
          links: [makeItinerarySpotLink(id: 'link-1')],
          removedLinkIds: ['link-2'],
        ))
            .isOk,
        isTrue,
      );
      expect(await linkCount(), 1);

      // 失敗: link-1 も削除しようとするが entry 段で失敗 → 削除がロールバックされ残る。
      repo.debugBeforeBundleStage = (stage) {
        if (stage == 'entry') throw StateError('boom');
      };
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(),
        entry: makeItineraryEntry(
          id: 'entry-spot',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: const [],
        removedLinkIds: ['link-1'],
      );
      expect(res.isOk, isFalse);
      expect(await linkCount(), 1); // link-1 は削除されず残る
    });

    test('別スポットのリンクIDを removedLinkIds に混ぜると拒否し全ロールバック', () async {
      final repo = await seedPlan('user-1');
      // spot-1 とそのリンク link-1、spot-2 とそのリンク link-2 を用意する。
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(id: 'spot-1'),
          entry: makeItineraryEntry(
            id: 'entry-1',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-1',
          ),
          links: [makeItinerarySpotLink(id: 'link-1', spotId: 'spot-1')],
        ))
            .isOk,
        isTrue,
      );
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(id: 'spot-2'),
          entry: makeItineraryEntry(
            id: 'entry-2',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-2',
          ),
          links: [
            makeItinerarySpotLink(
              id: 'link-2',
              spotId: 'spot-2',
              url: 'https://two.example',
            ),
          ],
        ))
            .isOk,
        isTrue,
      );
      expect(await linkCount(), 2);

      // spot-1 の保存で、spot-2 のリンク link-2 を削除しようとする → 拒否。
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(id: 'spot-1', name: '改名しようとする'),
        entry: makeItineraryEntry(
          id: 'entry-1',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: const [],
        removedLinkIds: ['link-2'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
      // 別スポットのリンクは消えず、spot-1 の改名も rollback される。
      expect(await linkCount(), 2);
      final spot1 = (await db.select(db.itinerarySpots).get())
          .firstWhere((s) => s.id == 'spot-1');
      expect(spot1.name, isNot('改名しようとする'));
    });

    test('存在しないリンクIDを removedLinkIds に指定すると拒否し全ロールバック', () async {
      final repo = await seedPlan('user-1');
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(id: 'spot-1'),
          entry: makeItineraryEntry(
            id: 'entry-1',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-1',
          ),
          links: [makeItinerarySpotLink(id: 'link-1', spotId: 'spot-1')],
        ))
            .isOk,
        isTrue,
      );
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(id: 'spot-1'),
        entry: makeItineraryEntry(
          id: 'entry-1',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: const [],
        removedLinkIds: ['ghost-link'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
      expect(await linkCount(), 1); // link-1 は残る
    });

    test('別ownerのリンクIDを removedLinkIds に指定すると拒否する', () async {
      final repo = await seedPlan('user-1');
      expect(
        (await repo.saveSpotBundle(
          spot: makeItinerarySpot(id: 'spot-1'),
          entry: makeItineraryEntry(
            id: 'entry-1',
            kind: ItineraryEntryKind.spot,
            spotId: 'spot-1',
          ),
          links: [makeItinerarySpotLink(id: 'link-1', spotId: 'spot-1')],
        ))
            .isOk,
        isTrue,
      );
      // 別ownerのスポットとリンクを直接挿入する（同期由来を模す）。
      await db.into(db.itinerarySpots).insert(
            spotToCompanion(
              makeItinerarySpot(
                id: 'spot-b',
                planId: 'plan-b',
                ownerId: 'user-2',
              ),
            ),
          );
      await db.into(db.itinerarySpotLinks).insert(
            spotLinkToCompanion(
              makeItinerarySpotLink(
                id: 'link-b',
                spotId: 'spot-b',
                ownerId: 'user-2',
              ),
            ),
          );
      final res = await repo.saveSpotBundle(
        spot: makeItinerarySpot(id: 'spot-1'),
        entry: makeItineraryEntry(
          id: 'entry-1',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
        links: const [],
        removedLinkIds: ['link-b'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
      // 別ownerのリンクは消えない。
      final remaining = await db.select(db.itinerarySpotLinks).get();
      expect(remaining.where((l) => l.id == 'link-b'), hasLength(1));
    });
  });

  group('reorderEntries: 一括トランザクション', () {
    Future<ItineraryRepositoryImpl> seedThreeNotes() async {
      final repo = await seedPlan('user-1');
      for (var i = 0; i < 3; i++) {
        expect(
          (await repo.upsertEntry(
            makeItineraryEntry(
              id: 'e$i',
              kind: ItineraryEntryKind.note,
              sortOrder: i,
            ),
          ))
              .isOk,
          isTrue,
        );
      }
      return repo;
    }

    Future<Map<String, int>> sortOrders() async {
      final rows = await db.select(db.itineraryEntries).get();
      return {for (final r in rows) r.id: r.sortOrder};
    }

    test('正常系: 指定順に sortOrder が振り直される', () async {
      final repo = await seedThreeNotes();
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['e2', 'e1', 'e0'],
      );
      expect(res.isOk, isTrue);
      final orders = await sortOrders();
      expect(orders['e2'], 0);
      expect(orders['e1'], 1);
      expect(orders['e0'], 2);
    });

    test('順序だけ変更し、項目の中身（名称・参照）は upsert しない', () async {
      final repo = await seedPlan('user-1');
      // メモ本文つきの項目を作る。
      expect(
        (await repo.upsertEntry(
          makeItineraryEntry(
            id: 'e0',
            kind: ItineraryEntryKind.note,
            sortOrder: 0,
            memo: '元のメモ',
          ),
        ))
            .isOk,
        isTrue,
      );
      expect(
        (await repo.upsertEntry(
          makeItineraryEntry(id: 'e1', kind: ItineraryEntryKind.note),
        ))
            .isOk,
        isTrue,
      );
      // 中身が変わったコピーを渡そうとしても、reorder は ID しか受け取らない。
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['e1', 'e0'],
      );
      expect(res.isOk, isTrue);
      final row = (await db.select(db.itineraryEntries).get())
          .firstWhere((r) => r.id == 'e0');
      expect(row.sortOrder, 1);
      expect(row.memo, '元のメモ'); // 中身は保持される。
    });

    test('途中失敗で全件ロールバック（先に書いた1件も戻る）', () async {
      final repo = await seedThreeNotes();
      repo.debugBeforeReorderWrite = (i) {
        if (i == 1) throw StateError('boom-reorder');
      };
      // e1→0(書込), e2→1(ここで失敗), e0→2 の順。
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['e1', 'e2', 'e0'],
      );
      expect(res.isOk, isFalse);
      // 元の 0/1/2 のまま。
      final orders = await sortOrders();
      expect(orders['e0'], 0);
      expect(orders['e1'], 1);
      expect(orders['e2'], 2);
      // Outbox にも並び替えの upsert は残らない（全件 rollback）。
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where(
          (o) =>
              o.entityTable == SyncEntity.itineraryEntries &&
              o.entityId != 'e0' &&
              o.entityId != 'e1' &&
              o.entityId != 'e2',
        ),
        isEmpty,
      );
    });

    test('存在しないIDを含むと ValidationFailure で拒否し、何も変更しない', () async {
      final repo = await seedThreeNotes();
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['e2', 'missing', 'e0'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
      final orders = await sortOrders();
      expect(orders['e0'], 0);
      expect(orders['e1'], 1);
      expect(orders['e2'], 2);
    });

    test('別ownerの項目IDは AuthFailure で拒否する', () async {
      final repo = await seedThreeNotes();
      // 別ownerの計画と項目を用意する。
      await seedGenba('user-2', id: 'genba-2');
      final repo2 = repoFor('user-2');
      expect(
        (await repo2.upsertPlan(
          makeItineraryPlan(
            id: 'plan-2',
            genbaId: 'genba-2',
            ownerId: 'user-2',
          ),
        ))
            .isOk,
        isTrue,
      );
      expect(
        (await repo2.upsertEntry(
          makeItineraryEntry(
            id: 'other-owner-entry',
            planId: 'plan-2',
            ownerId: 'user-2',
            kind: ItineraryEntryKind.note,
          ),
        ))
            .isOk,
        isTrue,
      );
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['e0', 'other-owner-entry'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<AuthFailure>());
    });

    test('別計画の項目IDは拒否する', () async {
      final repo = await seedThreeNotes();
      // 同一ownerの別計画と項目。
      final repoSame = repoFor('user-1');
      expect(
        (await repoSame.upsertPlan(
          makeItineraryPlan(
            id: 'plan-x',
            genbaId: 'genba-1',
            ownerId: 'user-1',
          ),
        ))
            .isOk,
        isTrue,
      );
      expect(
        (await repoSame.upsertEntry(
          makeItineraryEntry(
            id: 'entry-x',
            planId: 'plan-x',
            kind: ItineraryEntryKind.note,
          ),
        ))
            .isOk,
        isTrue,
      );
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['e0', 'entry-x'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
    });

    test('別日の項目をまとめて並び替えようとすると拒否する', () async {
      final repo = await seedPlan('user-1');
      expect(
        (await repo.upsertEntry(
          makeItineraryEntry(
            id: 'd1',
            kind: ItineraryEntryKind.note,
            localDate: DateTime(2026, 8, 1),
          ),
        ))
            .isOk,
        isTrue,
      );
      expect(
        (await repo.upsertEntry(
          makeItineraryEntry(
            id: 'd2',
            kind: ItineraryEntryKind.note,
            localDate: DateTime(2026, 8, 2),
          ),
        ))
            .isOk,
        isTrue,
      );
      final res = await repo.reorderEntries(
        planId: 'plan-1',
        orderedEntryIds: ['d2', 'd1'],
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('交通/宿泊の重複防止（同一計画）', () {
    Future<ItineraryRepositoryImpl> seedWithTransport() async {
      final repo = await seedPlan('user-1');
      expect(
        (await genbaRepoFor('user-1').upsertTransport(
          makeTransportRef(id: 'tr-1', genbaId: 'genba-1', ownerId: 'user-1'),
        ))
            .isOk,
        isTrue,
      );
      return repo;
    }

    test('同一交通を2回追加すると2件目は ConflictFailure（アプリ判定）', () async {
      final repo = await seedWithTransport();
      expect(
        (await repo.upsertEntry(
          makeItineraryEntry(
            id: 'e-t1',
            kind: ItineraryEntryKind.transport,
            transportId: 'tr-1',
          ),
        ))
            .isOk,
        isTrue,
      );
      final res = await repo.upsertEntry(
        makeItineraryEntry(
          id: 'e-t2',
          kind: ItineraryEntryKind.transport,
          transportId: 'tr-1',
        ),
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ConflictFailure>());
      expect(await entryCount(), 1);
    });

    test('DB部分ユニーク索引が存在し、直接の重複INSERTを弾く（競合の最終防波堤）', () async {
      final repo = await seedWithTransport();
      expect(
        (await repo.upsertEntry(
          makeItineraryEntry(
            id: 'e-t1',
            kind: ItineraryEntryKind.transport,
            transportId: 'tr-1',
          ),
        ))
            .isOk,
        isTrue,
      );

      // ローカルDBに部分ユニーク索引が定義されている。
      final idx = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' "
            "AND name='idx_itinerary_entries_plan_transport'",
          )
          .get();
      expect(idx, isNotEmpty);

      // アプリ判定を経ずに同じ (plan_id, transport_id) を直接INSERT → 索引が弾く。
      final dup = makeItineraryEntry(
        id: 'e-t-dup',
        kind: ItineraryEntryKind.transport,
        transportId: 'tr-1',
      );
      await expectLater(
        db.into(db.itineraryEntries).insert(entryToCompanion(dup)),
        throwsA(anything),
      );
      expect(await entryCount(), 1);
    });

    test('宿泊も同様に部分ユニーク索引が存在する', () async {
      await seedPlan('user-1');
      final idx = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' "
            "AND name='idx_itinerary_entries_plan_lodging'",
          )
          .get();
      expect(idx, isNotEmpty);
    });
  });
}
