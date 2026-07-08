import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:path/path.dart' as p;

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// 公演種別を選択式の安定コードへ移行（§7.1 / Phase 3前調整 点2）:
/// enum の code/label 往復・旧自由入力の変換・保存/復元・v9→v10 移行を検証。
void main() {
  group('PerformanceType: code/label と旧自由入力の変換', () {
    test('全値が code 往復し、日本語ラベルを持つ', () {
      for (final t in PerformanceType.values) {
        expect(performanceTypeFromCode(t.code), t);
        expect(t.label.isNotEmpty, isTrue);
      }
      expect(performanceTypeFromCode('unknown_code'), isNull);
      expect(performanceTypeFromCode(null), isNull);
      expect(PerformanceType.liveConcert.code, 'live_concert');
      expect(PerformanceType.liveConcert.label, 'ライブ・コンサート');
    });

    test('旧自由入力を既知コードへ安全に変換し、不能は null（→ other 扱い）', () {
      expect(performanceTypeFromLegacy('ワンマンライブ'), PerformanceType.liveConcert);
      expect(performanceTypeFromLegacy('夏フェス'), PerformanceType.festival);
      expect(performanceTypeFromLegacy('リリイベ'), PerformanceType.releaseEvent);
      expect(performanceTypeFromLegacy('特典会・チェキ'), PerformanceType.meetGreet);
      expect(performanceTypeFromLegacy('舞台'), PerformanceType.stageMusical);
      expect(performanceTypeFromLegacy('オンライン配信'), PerformanceType.online);
      // 変換できない自由入力は null（呼び出し側で other + 元文字列保持）。
      expect(performanceTypeFromLegacy('謎の特殊イベント'), isNull);
      expect(performanceTypeFromLegacy(''), isNull);
      expect(performanceTypeFromLegacy(null), isNull);
    });
  });

  group('保存/復元（Repository 往復）', () {
    test('選択した公演種別が保存され、読み出しで復元される', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final clock = FixedClock(DateTime(2026, 7, 6, 12));
      final outbox = OutboxStore(db, clock);
      final engine = SyncEngine(
        store: outbox,
        snapshotResolver: () => null,
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      );
      addTearDown(engine.dispose);
      final repo = GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => 'user-1',
        remoteResolver: () => null,
      );

      final res = await repo.upsertGenba(
        makeGenba(id: 'g-1', ownerId: 'user-1', eventDate: DateTime(2026, 8, 1))
            .copyWith(performanceType: PerformanceType.stageMusical),
      );
      expect(res.isOk, isTrue);

      final restored = await repo.watchById('g-1').first;
      expect(restored!.genba.performanceType, PerformanceType.stageMusical);
      // DB には安定コードで保存される（日本語文字列を保存しない）。
      final row = (await db.select(db.genbas).get()).single;
      expect(row.performanceType, 'stage_musical');
    });
  });

  group('v9→v10 マイグレーション（自由入力→コード・元文字列保持）', () {
    test('既知は変換、変換不能は other + performance_type_other へ元文字列を保持', () async {
      final dir = Directory.systemTemp.createTempSync('oshitrip_pt_mig');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'app.sqlite'));

      // --- v9 相当のファイルDBを用意（performance_type_other 列なし・自由入力） ---
      {
        final db = openFileTestDb(file);
        await db.customStatement('SELECT 1'); // onCreate(v10)
        await db.customStatement(
          'ALTER TABLE genbas DROP COLUMN performance_type_other',
        );
        Future<void> insert(String id, String type) => db.customStatement(
              'INSERT INTO genbas (id, owner_id, artist_name, title, '
              'event_date, performance_type, created_at, updated_at) VALUES '
              "('$id','u','a','t','2026-08-01','$type',"
              "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
            );
        await insert('g-known', 'ライブ・コンサート');
        await insert('g-fes', '夏フェス2026');
        await insert('g-unknown', '謎の特殊イベント');
        await db.customStatement('PRAGMA user_version = 9');
        await db.close();
      }

      // --- 再open → 本物の onUpgrade(9,10) が走る ---
      final db = openFileTestDb(file);
      addTearDown(db.close);
      await db.customStatement('SELECT 1');

      final rows = await db.select(db.genbas).get();
      final byId = {for (final r in rows) r.id: r};
      // 既知はコードへ、退避は消える。
      expect(byId['g-known']!.performanceType, 'live_concert');
      expect(byId['g-known']!.performanceTypeOther, isNull);
      expect(byId['g-fes']!.performanceType, 'festival');
      expect(byId['g-fes']!.performanceTypeOther, isNull);
      // 変換不能は other、元文字列を失わない。
      expect(byId['g-unknown']!.performanceType, 'other');
      expect(byId['g-unknown']!.performanceTypeOther, '謎の特殊イベント');
    });
  });
}
