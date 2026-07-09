import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_repository_impl.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// §7.7 改訂: メモは時間・移動予定とは独立した記録要素であり、メモ追加で
/// 時間重複エラーや移動時間エラーを起こさない（旅程＝itinerary とは別テーブル）。
void main() {
  test('メモを複数追加しても旅程（itinerary）は空のまま＝時間/移動エラーの対象にならない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final clock = FixedClock(DateTime(2026, 7, 9, 12));
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    final genba = GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
    final itinerary = ItineraryRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );

    await genba.upsertGenba(
      makeGenba(id: 'g1', ownerId: 'user-1', eventDate: DateTime(2026, 8, 1)),
    );

    GenbaMemo memo(String id, MemoKind kind) => GenbaMemo(
          id: id,
          genbaId: 'g1',
          ownerId: 'user-1',
          kind: kind,
          title: id,
          body: '本文',
          content: kind == MemoKind.bingo
              ? const MemoContent(bingo: MemoBingo(size: 3))
              : null,
          createdAt: fixedCreatedAt,
          updatedAt: fixedCreatedAt,
        );

    await genba.upsertMemo(memo('m1', MemoKind.free));
    await genba.upsertMemo(memo('m2', MemoKind.checklist));
    await genba.upsertMemo(memo('m3', MemoKind.bingo));
    await genba.upsertMemo(memo('m4', MemoKind.vote));

    // メモは genba 集約に入る。
    final agg = (await genba.watchAll().first).first;
    expect(agg.memos, hasLength(4));

    // 一方、旅程（itinerary_plans / entries / legs）は一切作られていない
    // → 時間重複・移動時間の検証対象が存在しない。
    final plans = await itinerary.watchByGenbaId('g1').first;
    expect(plans, isEmpty);
  });
}
