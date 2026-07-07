import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_mappers.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:path/path.dart' as p;

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// v8→v9 マイグレーション（交通・宿泊の部分ユニーク索引を版付きで作成）の検証。
///
/// レビュー点1の要求どおり「v8ファイルDBを作成→v9で再open→インデックス存在→
/// 重複拒否」を、**ファイルバックの実 close→reopen** で検証する。
/// あわせて「既存重複がある状態でのマイグレーション方針」（決定的な1件保持と、
/// 関連 leg・未送信 Outbox の掃除）も検証する。
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('oshitrip_v9_mig');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('v8ファイルDB→v9再openで索引が作られ、既存重複は決定的に整理され、重複INSERTが弾かれる', () async {
    final file = File(p.join(tempDir.path, 'app_v8.sqlite'));

    // --- 1. v8 相当のファイルDBを用意する ---
    // 最新コード(onCreate=v9)で作られるので、v9の索引を落とし user_version=8 に
    // 戻して「索引が無く重複を持つ v8 DB」を再現する。
    {
      final db = openFileTestDb(file);
      await db.customStatement('SELECT 1'); // onCreate を強制実行する。
      await db.customStatement(
        'DROP INDEX IF EXISTS idx_itinerary_entries_plan_transport',
      );
      await db.customStatement(
        'DROP INDEX IF EXISTS idx_itinerary_entries_plan_lodging',
      );

      // 親（genba / plan）と、同一計画に同じ交通を参照する重複項目2件、
      // 負け側を端点とする leg、双方の未送信 Outbox を入れる。
      await db.into(db.genbas).insert(
            GenbasCompanion.insert(
              id: 'genba-1',
              ownerId: 'user-1',
              artistName: 'アーティスト',
              title: '公演',
              eventDate: '2026-08-01',
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-01T00:00:00.000Z',
            ),
          );
      await db.into(db.itineraryPlans).insert(
            ItineraryPlansCompanion.insert(
              id: 'plan-1',
              genbaId: 'genba-1',
              ownerId: 'user-1',
              title: '計画',
              timeZoneId: 'Asia/Tokyo',
              createdAt: '2026-01-01T00:00:00.000Z',
              updatedAt: '2026-01-01T00:00:00.000Z',
            ),
          );
      // 勝ち: sort_order=0（決定的保持規則で最小）。負け: sort_order=1。
      await db.into(db.itineraryEntries).insert(
            entryToCompanion(
              makeItineraryEntry(
                id: 'entry-win',
                kind: ItineraryEntryKind.transport,
                transportId: 'tr-1',
                sortOrder: 0,
                createdAt: DateTime.utc(2026, 1, 1),
              ),
            ),
          );
      await db.into(db.itineraryEntries).insert(
            entryToCompanion(
              makeItineraryEntry(
                id: 'entry-lose',
                kind: ItineraryEntryKind.transport,
                transportId: 'tr-1',
                sortOrder: 1,
                createdAt: DateTime.utc(2026, 1, 2),
              ),
            ),
          );
      // 別種別（note）や別交通は重複ではないので残るべき対照。
      await db.into(db.itineraryEntries).insert(
            entryToCompanion(
              makeItineraryEntry(
                id: 'entry-note',
                kind: ItineraryEntryKind.note,
              ),
            ),
          );
      // 負け側を端点とする leg（掃除対象）。
      await db.into(db.itineraryLegs).insert(
            legToCompanion(
              makeItineraryLeg(
                id: 'leg-1',
                originEntryId: 'entry-note',
                destinationEntryId: 'entry-lose',
              ),
            ),
          );
      // 未送信 Outbox（負け項目と leg）。掃除されるべき。
      await db.customStatement(
        "INSERT INTO outbox_ops (mutation_id, owner_id, entity_table, "
        "entity_id, op_type, created_at, updated_at) VALUES "
        "('m1','user-1','itinerary_entries','entry-lose','upsert',"
        "'2026-01-02T00:00:00.000Z','2026-01-02T00:00:00.000Z')",
      );
      await db.customStatement(
        "INSERT INTO outbox_ops (mutation_id, owner_id, entity_table, "
        "entity_id, op_type, created_at, updated_at) VALUES "
        "('m2','user-1','itinerary_legs','leg-1','upsert',"
        "'2026-01-02T00:00:00.000Z','2026-01-02T00:00:00.000Z')",
      );

      // v8 に戻して close。
      await db.customStatement('PRAGMA user_version = 8');
      await db.close();
    }

    // --- 2. 同じファイルを再open → 本物の onUpgrade(8,9) が走る ---
    final db = openFileTestDb(file);
    addTearDown(db.close);
    await db.customStatement('SELECT 1'); // マイグレーションを強制実行する。

    // (a) 部分ユニーク索引が両方作られている。
    final idx = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' AND name IN "
          "('idx_itinerary_entries_plan_transport',"
          "'idx_itinerary_entries_plan_lodging')",
        )
        .get();
    expect(idx, hasLength(2));

    // (b) 重複は決定的に1件へ整理された（勝ち残り＝sort_order最小の entry-win）。
    final entries = await db.select(db.itineraryEntries).get();
    final ids = entries.map((e) => e.id).toSet();
    expect(ids.contains('entry-win'), isTrue);
    expect(ids.contains('entry-lose'), isFalse);
    expect(ids.contains('entry-note'), isTrue); // 対照は残る

    // (c) 負け側を端点とする leg と、両者の未送信 Outbox が掃除された。
    expect(await db.select(db.itineraryLegs).get(), isEmpty);
    final ops = await db
        .customSelect(
          "SELECT mutation_id FROM outbox_ops WHERE entity_id "
          "IN ('entry-lose','leg-1')",
        )
        .get();
    expect(ops, isEmpty);

    // (d) 索引が有効: 同じ (plan_id, transport_id) の直接INSERTは弾かれる。
    await expectLater(
      db.into(db.itineraryEntries).insert(
            entryToCompanion(
              makeItineraryEntry(
                id: 'entry-dup',
                kind: ItineraryEntryKind.transport,
                transportId: 'tr-1',
              ),
            ),
          ),
      throwsA(anything),
    );
  });
}
