import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/oshi/application/oshi_providers.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fake_oshi_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// R6独立レビュー#4: `oshiUpcomingAnniversariesProvider` が記念日ストリームの
/// loading/error を握りつぶさず伝播することを検証する。
void main() {
  final clock = FixedClock(DateTime(2026, 7, 10, 12));
  const groupId = 'grp1';
  const owner = 'user-1';

  ({ProviderContainer container, FakeOshiRepository fake}) setUp() {
    final db = createTestDb();
    addTearDown(db.close);
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    final inner = OshiRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => owner,
    );
    final fake = FakeOshiRepository(inner);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        oshiRepositoryProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, fake: fake);
  }

  test('正常系: グループ・記念日が揃うと導出結果を data で返す', () async {
    final s = setUp();
    await s.fake.upsertGroup(
      OshiGroup(
        id: groupId,
        ownerId: owner,
        name: 'グループ',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await s.fake.upsertAnniversary(
      OshiAnniversary(
        id: 'a1',
        ownerId: owner,
        groupId: groupId,
        label: '結成記念日',
        date: DateTime(2020, 4, 1),
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    // 両ストリームが最初の値を出すのを待つ。
    await s.container.read(oshiGroupsProvider.future);
    await s.container.read(oshiAnniversariesProvider.future);

    final result = s.container.read(oshiUpcomingAnniversariesProvider(groupId));
    expect(result.hasValue, isTrue);
    expect(result.value!.map((a) => a.label), contains('結成記念日'));
  });

  test('空: データが無ければ data で空リスト', () async {
    final s = setUp();
    await s.container.read(oshiGroupsProvider.future);
    await s.container.read(oshiAnniversariesProvider.future);

    final result = s.container.read(oshiUpcomingAnniversariesProvider(groupId));
    expect(result.hasValue, isTrue);
    expect(result.value, isEmpty);
  });

  test('読み込み中: 記念日ストリームが未確定なら loading（空へ変換しない）', () async {
    final s = setUp();
    // 記念日は永遠に emit しない（loading のまま）。
    final hang = StreamController<List<OshiAnniversary>>();
    addTearDown(hang.close);
    s.fake.watchAnniversariesOverride = hang.stream;

    // グループは data になるが、記念日が loading のため全体は loading。
    await s.container.read(oshiGroupsProvider.future);

    final result = s.container.read(oshiUpcomingAnniversariesProvider(groupId));
    expect(result.isLoading, isTrue);
    expect(result.hasValue, isFalse);
  });

  test('失敗: 記念日ストリームが error なら error（空へ変換しない）', () async {
    final s = setUp();
    s.fake.watchAnniversariesError = Exception('記念日の読み込み失敗（テスト注入）');

    await s.container.read(oshiGroupsProvider.future);
    // 記念日ストリームがエラーで確定するのを待つ。
    await expectLater(
      s.container.read(oshiAnniversariesProvider.future),
      throwsA(isA<Exception>()),
    );

    final result = s.container.read(oshiUpcomingAnniversariesProvider(groupId));
    expect(result.hasError, isTrue);
    expect(result.hasValue, isFalse);
  });
}
