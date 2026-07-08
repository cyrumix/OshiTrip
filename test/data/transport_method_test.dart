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

/// 交通手段を選択式の安定コードへ移行（§7.5 / Phase 3前調整 点3）:
/// enum の code/label 往復・旧自由入力の変換・保存/復元・v10→v11 移行を検証。
void main() {
  group('TransportMethod: code/label と旧自由入力の変換', () {
    test('全値が code 往復し、日本語ラベルを持つ', () {
      for (final m in TransportMethod.values) {
        expect(transportMethodFromCode(m.code), m);
        expect(m.label.isNotEmpty, isTrue);
      }
      expect(transportMethodFromCode('unknown'), isNull);
      expect(TransportMethod.shinkansen.code, 'shinkansen');
      expect(TransportMethod.shinkansen.label, '新幹線');
    });

    test('旧自由入力を既知コードへ安全に変換し、不能は null（→ other 扱い）', () {
      expect(transportMethodFromLegacy('新幹線のぞみ'), TransportMethod.shinkansen);
      expect(transportMethodFromLegacy('JR在来線'), TransportMethod.train);
      expect(transportMethodFromLegacy('夜行バス'), TransportMethod.highwayBus);
      expect(transportMethodFromLegacy('路線バス'), TransportMethod.localBus);
      expect(transportMethodFromLegacy('ANAで飛行機'), TransportMethod.airplane);
      expect(transportMethodFromLegacy('レンタカー'), TransportMethod.rentalCar);
      expect(transportMethodFromLegacy('タクシー'), TransportMethod.taxi);
      expect(transportMethodFromLegacy('徒歩'), TransportMethod.walkBicycle);
      // 「バス」単体は路線バス。
      expect(transportMethodFromLegacy('バス'), TransportMethod.localBus);
      // 変換できない自由入力は null（呼び出し側で other + 元文字列保持）。
      expect(transportMethodFromLegacy('謎の乗り物'), isNull);
      expect(transportMethodFromLegacy(''), isNull);
    });

    test('methodDisplay: other は補足自由入力・未設定は空文字', () {
      final base = makeTransportRef(id: 't');
      expect(
        base.copyWith(method: TransportMethod.shinkansen).methodDisplay,
        '新幹線',
      );
      expect(
        base
            .copyWith(method: TransportMethod.other, methodOther: '相乗り')
            .methodDisplay,
        '相乗り',
      );
      expect(base.copyWith().methodDisplay, '');
    });
  });

  group('保存/復元（Repository 往復）', () {
    test('選択した交通手段が安定コードで保存され、復元される', () async {
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
      await repo.upsertGenba(
        makeGenba(
          id: 'g-1',
          ownerId: 'user-1',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      final res = await repo.upsertTransport(
        makeTransportRef(id: 't-1', genbaId: 'g-1', ownerId: 'user-1')
            .copyWith(method: TransportMethod.airplane),
      );
      expect(res.isOk, isTrue);

      final restored = (await db.select(db.transports).get()).single;
      expect(restored.method, 'airplane'); // 安定コードで保存
      final bundle = await repo.watchById('g-1').first;
      expect(bundle!.transports.single.method, TransportMethod.airplane);
    });
  });

  group('v10→v11 マイグレーション（自由入力→コード・元文字列保持）', () {
    test('既知は変換、変換不能は other + method_other へ元文字列を保持', () async {
      final dir = Directory.systemTemp.createTempSync('oshitrip_tm_mig');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'app.sqlite'));

      // --- v10 相当（method_other 列なし・自由入力） ---
      {
        final db = openFileTestDb(file);
        await db.customStatement('SELECT 1');
        await db.customStatement(
          'ALTER TABLE transports DROP COLUMN method_other',
        );
        // 親 genba（FK は無いが整合のため）。
        await db.customStatement(
          'INSERT INTO genbas (id, owner_id, artist_name, title, event_date, '
          "created_at, updated_at) VALUES ('g','u','a','t','2026-08-01',"
          "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
        );
        Future<void> ins(String id, String method) => db.customStatement(
              'INSERT INTO transports (id, genba_id, owner_id, direction, '
              'method, created_at, updated_at) VALUES '
              "('$id','g','u','outbound','$method',"
              "'2026-01-01T00:00:00.000Z','2026-01-01T00:00:00.000Z')",
            );
        await ins('t-known', '新幹線');
        await ins('t-bus', '夜行バス');
        await ins('t-unknown', '謎の乗り物');
        await db.customStatement('PRAGMA user_version = 10');
        await db.close();
      }

      // --- 再open → onUpgrade(10,11) ---
      final db = openFileTestDb(file);
      addTearDown(db.close);
      await db.customStatement('SELECT 1');

      final rows = await db.select(db.transports).get();
      final byId = {for (final r in rows) r.id: r};
      expect(byId['t-known']!.method, 'shinkansen');
      expect(byId['t-known']!.methodOther, isNull);
      expect(byId['t-bus']!.method, 'highway_bus');
      expect(byId['t-unknown']!.method, 'other');
      expect(byId['t-unknown']!.methodOther, '謎の乗り物');
    });
  });
}
