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
import 'package:oshi_trip/features/itinerary/data/itinerary_repository_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// [ItineraryRepositoryImpl] の統合テスト（ローカル先行・Outbox・owner分離・
/// 親所有権・cascade・オフライン永続）。
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

  /// owner の genba を1件用意する（計画の親所有権検証を通すため）。
  Future<void> seedGenba(String owner, {String id = 'genba-1'}) async {
    final result = await genbaRepoFor(owner).upsertGenba(
      makeGenba(id: id, ownerId: owner, eventDate: DateTime(2026, 8, 1)),
    );
    expect(result.isOk, isTrue);
  }

  /// 計画・スポット・リンク・spot項目・note項目・移動区間を一式作る。
  Future<void> seedFullPlan(ItineraryRepositoryImpl repo, String owner) async {
    expect(
      (await repo.upsertPlan(makeItineraryPlan(ownerId: owner))).isOk,
      isTrue,
    );
    expect(
      (await repo.upsertSpot(makeItinerarySpot(ownerId: owner))).isOk,
      isTrue,
    );
    expect(
      (await repo.upsertSpotLink(makeItinerarySpotLink(ownerId: owner))).isOk,
      isTrue,
    );
    expect(
      (await repo.upsertEntry(
        makeItineraryEntry(
          id: 'entry-spot',
          ownerId: owner,
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-1',
        ),
      ))
          .isOk,
      isTrue,
    );
    expect(
      (await repo.upsertEntry(
        makeItineraryEntry(
          id: 'entry-note',
          ownerId: owner,
          kind: ItineraryEntryKind.note,
        ),
      ))
          .isOk,
      isTrue,
    );
    expect(
      (await repo.upsertLeg(
        makeItineraryLeg(
          ownerId: owner,
          originEntryId: 'entry-spot',
          destinationEntryId: 'entry-note',
        ),
      ))
          .isOk,
      isTrue,
    );
  }

  test('計画作成: ローカル即時反映 + Outbox 追加（親genbaが必要）', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    final result = await repo.upsertPlan(makeItineraryPlan());
    expect(result.isOk, isTrue);

    final plans = await repo.watchByGenbaId('genba-1').first;
    expect(plans, hasLength(1));
    expect(plans.single.plan.title, '遠征プラン');

    final ops = await outbox.pendingOps(ownerId: 'user-1');
    final planOps =
        ops.where((o) => o.entityTable == SyncEntity.itineraryPlans).toList();
    expect(planOps, hasLength(1));
    expect(planOps.single.opType, OutboxOpType.upsert);
    // 端末内カバー画像参照は payload に載せない。
    expect(planOps.single.payload.containsKey('cover_image_local_path'), false);
  });

  test('親genbaが存在しない/別owner の計画upsertは拒否（ValidationFailure）', () async {
    await seedGenba('user-1');
    // user-2 が user-1 の genba にぶら下げる計画を作ろうとする。
    final repoB = repoFor('user-2');
    final res = await repoB.upsertPlan(
      makeItineraryPlan(ownerId: 'user-2', genbaId: 'genba-1'),
    );
    expect(res.isOk, isFalse);
    expect(res.failureOrNull?.message, contains('アクセス権'));
    // Outbox にも積まれない。
    final ops = await outbox.pendingOps(ownerId: 'user-2');
    expect(
      ops.where((o) => o.entityTable == SyncEntity.itineraryPlans),
      isEmpty,
    );
  });

  test('スポットの親plan所有権検証: 別ownerのplan配下へは作れない', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await repo.upsertPlan(makeItineraryPlan());

    // user-2 が user-1 の plan にスポットをぶら下げようとする。
    final repoB = repoFor('user-2');
    final res = await repoB.upsertSpot(
      makeItinerarySpot(ownerId: 'user-2', planId: 'plan-1'),
    );
    expect(res.isOk, isFalse);
    expect(res.failureOrNull?.message, contains('アクセス権'));
  });

  test('座標の不整合（緯度だけ）はValidationFailureで、行もOutboxも作られない（原子性）', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await repo.upsertPlan(makeItineraryPlan());

    final res = await repo.upsertSpot(
      makeItinerarySpot(latitude: 35.0), // longitude が無い
    );
    expect(res.isOk, isFalse);
    expect(await db.select(db.itinerarySpots).get(), isEmpty);
    final ops = await outbox.pendingOps(ownerId: 'user-1');
    expect(
      ops.where((o) => o.entityTable == SyncEntity.itinerarySpots),
      isEmpty,
    );
  });

  test('owner分離: 別ownerは計画を watch できない（C-01）', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await repo.upsertPlan(makeItineraryPlan());

    final repoB = repoFor('user-2');
    expect(await repoB.watchByGenbaId('genba-1').first, isEmpty);
    expect(await repoB.watchPlan('plan-1').first, isNull);
  });

  test('別ownerの計画削除はAuthFailureで拒否、原本保持・delete Outbox無し', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await repo.upsertPlan(makeItineraryPlan());

    final repoB = repoFor('user-2');
    final res = await repoB.deletePlan('plan-1');
    expect(res.isOk, isFalse);
    expect(res.failureOrNull?.message, contains('別ユーザー'));

    // user-1 の計画は残る。
    expect(await repo.watchPlan('plan-1').first, isNotNull);
    // user-2 側に delete Outbox は積まれない。
    final ops = await outbox.pendingOps(ownerId: 'user-2');
    expect(
      ops.where(
        (o) =>
            o.entityTable == SyncEntity.itineraryPlans &&
            o.opType == OutboxOpType.delete,
      ),
      isEmpty,
    );
  });

  test('計画削除で配下（spot/link/entry/leg）がすべて cascade する', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await seedFullPlan(repo, 'user-1');

    // 事前確認。
    final before = await repo.watchPlan('plan-1').first;
    expect(before!.spots, hasLength(1));
    expect(before.spotLinks, hasLength(1));
    expect(before.entries, hasLength(2));
    expect(before.legs, hasLength(1));

    final res = await repo.deletePlan('plan-1');
    expect(res.isOk, isTrue);

    expect(await repo.watchPlan('plan-1').first, isNull);
    expect(await db.select(db.itinerarySpots).get(), isEmpty);
    expect(await db.select(db.itinerarySpotLinks).get(), isEmpty);
    expect(await db.select(db.itineraryEntries).get(), isEmpty);
    expect(await db.select(db.itineraryLegs).get(), isEmpty);

    // plan の delete Outbox が1件（子はサーバー cascade に委ねる）。
    final ops = await outbox.pendingOps(ownerId: 'user-1');
    expect(
      ops.where(
        (o) =>
            o.entityTable == SyncEntity.itineraryPlans &&
            o.opType == OutboxOpType.delete,
      ),
      hasLength(1),
    );
  });

  test('スポット削除で link・訪問entry・その leg が cascade（他項目は残る）', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await seedFullPlan(repo, 'user-1');

    final res = await repo.deleteSpot('spot-1');
    expect(res.isOk, isTrue);

    final after = await repo.watchPlan('plan-1').first;
    expect(after!.spots, isEmpty);
    expect(after.spotLinks, isEmpty); // spot の link
    // spot を参照する entry-spot は消え、note は残る。
    expect(after.entries.map((e) => e.id), ['entry-note']);
    // entry-spot を端点にしていた leg も消える。
    expect(after.legs, isEmpty);
  });

  test('旅程項目削除で、その項目を端点とする移動区間も削除される', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await seedFullPlan(repo, 'user-1');

    final res = await repo.deleteEntry('entry-note');
    expect(res.isOk, isTrue);

    final after = await repo.watchPlan('plan-1').first;
    expect(after!.entries.map((e) => e.id), ['entry-spot']);
    expect(after.legs, isEmpty); // note を端点にしていた leg も消える
  });

  test('未認証では watch は空・upsert は AuthFailure', () async {
    final repo = repoFor(null);
    expect(await repo.watchByGenbaId('genba-1').first, isEmpty);
    final res = await repo.upsertPlan(makeItineraryPlan());
    expect(res.isOk, isFalse);
    expect(res.failureOrNull?.message, contains('ログイン'));
  });

  test('オフライン→再起動相当（同一DBの別repo）で計画・スポットが維持され、Outboxに未同期が残る', () async {
    await seedGenba('user-1');
    final repo1 = repoFor('user-1');
    await repo1.upsertPlan(makeItineraryPlan(title: '永続確認'));
    await repo1.upsertSpot(makeItinerarySpot(name: '再開後も残る'));

    // 未同期（pending）op が残っている（接続復旧で同期される状態）。
    final pending = await outbox.pendingOps(ownerId: 'user-1');
    expect(
      pending.where(
        (o) =>
            o.entityTable == SyncEntity.itineraryPlans ||
            o.entityTable == SyncEntity.itinerarySpots,
      ),
      hasLength(2),
    );

    // アプリ再起動相当: 同じDBを使う新しいrepoインスタンス。
    final repo2 = repoFor('user-1');
    final plans = await repo2.watchByGenbaId('genba-1').first;
    expect(plans, hasLength(1));
    expect(plans.single.plan.title, '永続確認');
    expect(plans.single.spots.single.name, '再開後も残る');
  });

  test('URLスキーム検証: 危険スキームのリンクは拒否される', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await repo.upsertPlan(makeItineraryPlan());
    await repo.upsertSpot(makeItinerarySpot());

    final res = await repo.upsertSpotLink(
      makeItinerarySpotLink(url: 'javascript:alert(1)'),
    );
    expect(res.isOk, isFalse);
    expect(await db.select(db.itinerarySpotLinks).get(), isEmpty);
  });

  group('参照整合性（entryの参照先・legの両端が同一owner・同一計画/現場）', () {
    test('存在しないspotを参照するentryは拒否され、行もOutboxも作られない', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan());

      final res = await repo.upsertEntry(
        makeItineraryEntry(
          id: 'entry-bad',
          kind: ItineraryEntryKind.spot,
          spotId: 'does-not-exist',
        ),
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull?.message, contains('参照先'));
      expect(await db.select(db.itineraryEntries).get(), isEmpty);
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where((o) => o.entityTable == SyncEntity.itineraryEntries),
        isEmpty,
      );
    });

    test('別計画のspotを参照するentryは拒否される', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan(id: 'plan-1'));
      await repo.upsertPlan(makeItineraryPlan(id: 'plan-2'));
      // spot は plan-2 に属する。
      await repo.upsertSpot(makeItinerarySpot(id: 'spot-x', planId: 'plan-2'));

      // plan-1 の entry が plan-2 の spot を参照 → 拒否。
      final res = await repo.upsertEntry(
        makeItineraryEntry(
          id: 'entry-x',
          planId: 'plan-1',
          kind: ItineraryEntryKind.spot,
          spotId: 'spot-x',
        ),
      );
      expect(res.isOk, isFalse);
      expect(await db.select(db.itineraryEntries).get(), isEmpty);
    });

    test('この現場に登録済みの交通を参照するentryは許可される', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan());
      // genba-1 に交通を登録する。
      final t = await genbaRepoFor('user-1').upsertTransport(
        makeTransportRef(id: 'tr-1', genbaId: 'genba-1', ownerId: 'user-1'),
      );
      expect(t.isOk, isTrue);

      final res = await repo.upsertEntry(
        makeItineraryEntry(
          id: 'entry-tr',
          kind: ItineraryEntryKind.transport,
          transportId: 'tr-1',
        ),
      );
      expect(res.isOk, isTrue);
    });

    test('別現場の交通を参照するentryは拒否される', () async {
      await seedGenba('user-1', id: 'genba-1');
      await seedGenba('user-1', id: 'genba-2');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan(genbaId: 'genba-1'));
      // 交通は genba-2 に登録（計画は genba-1）。
      await genbaRepoFor('user-1').upsertTransport(
        makeTransportRef(id: 'tr-2', genbaId: 'genba-2', ownerId: 'user-1'),
      );

      final res = await repo.upsertEntry(
        makeItineraryEntry(
          id: 'entry-tr2',
          kind: ItineraryEntryKind.transport,
          transportId: 'tr-2',
        ),
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull?.message, contains('参照先'));
      expect(await db.select(db.itineraryEntries).get(), isEmpty);
    });

    test('別計画の項目を端点にするlegは拒否される', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan(id: 'plan-1'));
      await repo.upsertPlan(makeItineraryPlan(id: 'plan-2'));
      await repo.upsertEntry(
        makeItineraryEntry(id: 'e-p1', planId: 'plan-1'),
      );
      await repo.upsertEntry(
        makeItineraryEntry(id: 'e-p2', planId: 'plan-2'),
      );

      // plan-1 の leg が plan-2 の項目を端点にする → 拒否。
      final res = await repo.upsertLeg(
        makeItineraryLeg(
          planId: 'plan-1',
          originEntryId: 'e-p1',
          destinationEntryId: 'e-p2',
        ),
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull?.message, contains('参照先'));
      expect(await db.select(db.itineraryLegs).get(), isEmpty);
    });
  });

  group('owner分離: 全5エンティティを別ownerがread/upsert/deleteできない（C-01）', () {
    test('全5エンティティの分離を一括検証する', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await seedFullPlan(repo, 'user-1');
      final repoB = repoFor('user-2');

      // read: 別ownerには一切見えない（集約経由で子も不可視）。
      expect(await repoB.watchByGenbaId('genba-1').first, isEmpty);
      expect(await repoB.watchPlan('plan-1').first, isNull);

      // upsert（既存IDの乗っ取り）: 全5エンティティで AuthFailure。
      final hijacks = <String, Future<Object?> Function()>{
        'plan': () async => repoB
            .upsertPlan(makeItineraryPlan(ownerId: 'user-2'))
            .then((r) => r.failureOrNull),
        'spot': () async => repoB
            .upsertSpot(makeItinerarySpot(ownerId: 'user-2'))
            .then((r) => r.failureOrNull),
        'link': () async => repoB
            .upsertSpotLink(makeItinerarySpotLink(ownerId: 'user-2'))
            .then((r) => r.failureOrNull),
        'entry': () async => repoB
            .upsertEntry(
              makeItineraryEntry(
                id: 'entry-note',
                ownerId: 'user-2',
                kind: ItineraryEntryKind.note,
              ),
            )
            .then((r) => r.failureOrNull),
        'leg': () async => repoB
            .upsertLeg(
              makeItineraryLeg(
                ownerId: 'user-2',
                originEntryId: 'entry-spot',
                destinationEntryId: 'entry-note',
              ),
            )
            .then((r) => r.failureOrNull),
      };
      for (final entry in hijacks.entries) {
        expect(
          await entry.value(),
          isNotNull,
          reason: '${entry.key} upsert 乗っ取り',
        );
      }

      // delete: 全5エンティティで AuthFailure、かつ user-1 のデータは無傷。
      expect((await repoB.deletePlan('plan-1')).isOk, isFalse);
      expect((await repoB.deleteSpot('spot-1')).isOk, isFalse);
      expect((await repoB.deleteSpotLink('link-1')).isOk, isFalse);
      expect((await repoB.deleteEntry('entry-spot')).isOk, isFalse);
      expect((await repoB.deleteLeg('leg-1')).isOk, isFalse);

      final after = await repo.watchPlan('plan-1').first;
      expect(after!.spots, hasLength(1));
      expect(after.spotLinks, hasLength(1));
      expect(after.entries, hasLength(2));
      expect(after.legs, hasLength(1));

      // user-2 側に Outbox は1件も積まれない。
      expect(await outbox.pendingOps(ownerId: 'user-2'), isEmpty);
    });
  });

  test('URLはscheme無し・host無しでも拒否される（host必須）', () async {
    await seedGenba('user-1');
    final repo = repoFor('user-1');
    await repo.upsertPlan(makeItineraryPlan());
    await repo.upsertSpot(makeItinerarySpot());

    // scheme はあるが host が無い。
    final res = await repo.upsertSpotLink(
      makeItinerarySpotLink(url: 'https:///path'),
    );
    expect(res.isOk, isFalse);
    // host無し（スキームのみ）も拒否。
    final res2 = await repo.upsertSpotLink(
      makeItinerarySpotLink(id: 'link-2', url: 'https://'),
    );
    expect(res2.isOk, isFalse);
    expect(await db.select(db.itinerarySpotLinks).get(), isEmpty);
  });

  group('Phase 1: Google Routes のライブ応答は永続化しない（Repository境界で強制）', () {
    Future<ItineraryRepositoryImpl> seedForLeg() async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan());
      await repo.upsertEntry(
        makeItineraryEntry(id: 'e1', kind: ItineraryEntryKind.note),
      );
      await repo.upsertEntry(
        makeItineraryEntry(id: 'e2', kind: ItineraryEntryKind.note),
      );
      return repo;
    }

    test('source=googleRoutes のlegは拒否、行もOutboxも作らない', () async {
      final repo = await seedForLeg();
      final res = await repo.upsertLeg(
        makeItineraryLeg(
          source: ItineraryLegSource.googleRoutes,
          originEntryId: 'e1',
          destinationEntryId: 'e2',
        ),
      );
      expect(res.isOk, isFalse);
      expect(res.failureOrNull, isA<ValidationFailure>());
      expect(await db.select(db.itineraryLegs).get(), isEmpty);
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where((o) => o.entityTable == SyncEntity.itineraryLegs),
        isEmpty,
      );
    });

    test('Google応答予約フィールド（fetchedAt等）を持つlegも拒否', () async {
      final repo = await seedForLeg();
      final res = await repo.upsertLeg(
        makeItineraryLeg(originEntryId: 'e1', destinationEntryId: 'e2')
            .copyWith(cacheKey: 'k1', encodedPolyline: 'abc'),
      );
      expect(res.isOk, isFalse);
      expect(await db.select(db.itineraryLegs).get(), isEmpty);
    });

    test('manual のlegは通る（弱体化していないことの確認）', () async {
      final repo = await seedForLeg();
      final res = await repo.upsertLeg(
        makeItineraryLeg(originEntryId: 'e1', destinationEntryId: 'e2'),
      );
      expect(res.isOk, isTrue);
    });
  });

  group('出典と権利根拠: 空のrights_basisは行もOutboxも作らない', () {
    test('spot.dataOrigin=facilityProvided で rightsBasis 空は拒否', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan());

      final res = await repo.upsertSpot(
        makeItinerarySpot(dataOrigin: ItineraryValueOrigin.facilityProvided),
      );
      expect(res.isOk, isFalse);
      expect(await db.select(db.itinerarySpots).get(), isEmpty);
      final ops = await outbox.pendingOps(ownerId: 'user-1');
      expect(
        ops.where((o) => o.entityTable == SyncEntity.itinerarySpots),
        isEmpty,
      );

      // 権利根拠を入れれば通る。
      final ok = await repo.upsertSpot(
        makeItinerarySpot(
          dataOrigin: ItineraryValueOrigin.facilityProvided,
          rightsBasis: '施設提供の許諾',
        ),
      );
      expect(ok.isOk, isTrue);
    });

    test('leg.valueOrigin=openData で rightsBasis 空は拒否', () async {
      await seedGenba('user-1');
      final repo = repoFor('user-1');
      await repo.upsertPlan(makeItineraryPlan());
      await repo.upsertEntry(
        makeItineraryEntry(id: 'e1', kind: ItineraryEntryKind.note),
      );
      await repo.upsertEntry(
        makeItineraryEntry(id: 'e2', kind: ItineraryEntryKind.note),
      );

      final res = await repo.upsertLeg(
        makeItineraryLeg(
          originEntryId: 'e1',
          destinationEntryId: 'e2',
          valueOrigin: ItineraryValueOrigin.openData,
        ),
      );
      expect(res.isOk, isFalse);
      expect(await db.select(db.itineraryLegs).get(), isEmpty);
    });
  });
}
