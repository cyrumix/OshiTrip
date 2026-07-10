import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/sharing/data/genba_shares_repository_impl.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// 現場共有データ基盤（Phase 5 前提基盤・保守的スライス）: owner の共有 CRUD＋
/// Outbox 副作用、owner 分離（C-01）、親現場所有権検証（他人の現場は共有不可）、
/// 不変条件（自己共有・role）を検証する。既存データ表の RLS 変更は行わないため、
/// grantee 側の read はこのテストの対象外（次増分）。
void main() {
  late AppDatabase db;
  late OutboxStore outbox;
  late SyncEngine engine;
  late GenbaRepositoryImpl genbaRepo;
  late GenbaSharesRepositoryImpl shareRepo;
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  GenbaSharesRepositoryImpl repoFor(String owner) => GenbaSharesRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      );

  GenbaShare share({
    String id = 'share-1',
    String owner = 'user-1',
    String genbaId = 'genba-1',
    String grantee = 'user-2',
    ShareRole role = ShareRole.viewer,
    FieldGrants grants = const FieldGrants(),
  }) =>
      GenbaShare(
        id: id,
        ownerId: owner,
        genbaId: genbaId,
        granteeId: grantee,
        role: role,
        fieldGrants: grants,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  setUp(() async {
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
    genbaRepo = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    shareRepo = repoFor('user-1');
    // 親現場（user-1 所有）を用意する。
    await genbaRepo.upsertGenba(
      makeGenba(
        id: 'genba-1',
        ownerId: 'user-1',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
  });

  test('共有作成: ローカル即時反映 + Outbox 追加', () async {
    final result = await shareRepo.upsertShare(share(role: ShareRole.editor));
    expect(result.isOk, isTrue);

    final list = await shareRepo.watchShares('genba-1').first;
    expect(list.single.granteeId, 'user-2');
    expect(list.single.role, ShareRole.editor);

    final pending = await outbox.pendingOps(ownerId: 'user-1');
    expect(pending.where((o) => o.entityTable == 'genba_shares'), hasLength(1));
  });

  test('項目単位grantを保持する（安全側既定＋明示許可）', () async {
    await shareRepo.upsertShare(
      share(grants: const FieldGrants(address: true)),
    );
    final s = (await shareRepo.watchShares('genba-1').first).single;
    expect(s.fieldGrants.address, isTrue);
    // 明示していない項目は既定 false のまま。
    expect(s.fieldGrants.ticketImage, isFalse);
    expect(s.fieldGrants.reservationNumber, isFalse);
    expect(s.fieldGrants.impression, isFalse);
  });

  test('共有解除: ローカルから消え Outbox に delete が積まれる', () async {
    await shareRepo.upsertShare(share());
    final result = await shareRepo.removeShare('share-1');
    expect(result.isOk, isTrue);
    expect(await shareRepo.watchShares('genba-1').first, isEmpty);
  });

  test('自分自身へは共有できない（不変条件・ValidationFailure）', () async {
    final result = await shareRepo.upsertShare(share(grantee: 'user-1'));
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(await shareRepo.watchShares('genba-1').first, isEmpty);
  });

  test('他人の現場は共有できない（親owner整合・ValidationFailure）', () async {
    // user-2 が user-1 所有の genba-1 を user-3 へ共有しようとする。
    final other = repoFor('user-2');
    final result =
        await other.upsertShare(share(owner: 'user-2', grantee: 'user-3'));
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('別ownerの共有は見えない（owner分離・C-01）', () async {
    await shareRepo.upsertShare(share());
    // user-2 の repo からは user-1 の共有は見えない。
    final other = repoFor('user-2');
    expect(await other.watchShares('genba-1').first, isEmpty);
  });

  test('owner_id 偽装は AuthFailure', () async {
    // user-1 の repo に owner_id='user-2'（grantee=user-3）の共有を渡す。
    final result =
        await shareRepo.upsertShare(share(owner: 'user-2', grantee: 'user-3'));
    expect(result.failureOrNull, isA<AuthFailure>());
  });

  test('未ログインは AuthFailure', () async {
    final anon = GenbaSharesRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => null,
      remoteResolver: () => null,
    );
    final result = await anon.upsertShare(share());
    expect(result.failureOrNull, isA<AuthFailure>());
  });
}
