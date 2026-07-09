import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// メモ種類（§7.7 改訂）: 自由メモ/チェックリスト/BINGO/投票の CRUD と
/// content の DB 往復、既存メモの自由メモ扱いを検証する。
void main() {
  GenbaRepositoryImpl repoFor(AppDatabase db) {
    final clock = FixedClock(DateTime(2026, 7, 9, 12));
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    return GenbaRepositoryImpl(
      db: db,
      outbox: outbox,
      syncEngine: engine,
      clock: clock,
      ownerIdResolver: () => 'user-1',
      remoteResolver: () => null,
    );
  }

  GenbaMemo baseMemo(
    String id, {
    MemoKind kind = MemoKind.free,
    String title = '',
    String body = '',
    MemoContent? content,
  }) =>
      GenbaMemo(
        id: id,
        genbaId: 'genba-1',
        ownerId: 'user-1',
        kind: kind,
        title: title,
        body: body,
        content: content,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  Future<GenbaRepositoryImpl> seeded(AppDatabase db) async {
    final repo = repoFor(db);
    await repo.upsertGenba(
      makeGenba(
        id: 'genba-1',
        ownerId: 'user-1',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    return repo;
  }

  test('自由メモを追加・編集・削除できる', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = await seeded(db);

    await repo.upsertMemo(baseMemo('m1', title: '感想', body: '最高だった'));
    var agg = (await repo.watchAll().first).first;
    expect(agg.memos.single.kind, MemoKind.free);
    expect(agg.memos.single.body, '最高だった');

    await repo.upsertMemo(baseMemo('m1', title: '感想', body: 'やっぱり神'));
    agg = (await repo.watchAll().first).first;
    expect(agg.memos.single.body, 'やっぱり神');

    await repo.deleteMemo('m1');
    agg = (await repo.watchAll().first).first;
    expect(agg.memos, isEmpty);
  });

  test('チェックリストメモの項目・チェック状態が DB を往復する', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = await seeded(db);

    await repo.upsertMemo(
      baseMemo(
        'c1',
        kind: MemoKind.checklist,
        title: '持ち物',
        content: const MemoContent(
          checklist: [
            MemoChecklistItem(id: 'i1', text: 'ペンライト', checked: true),
            MemoChecklistItem(id: 'i2', text: 'タオル', sortOrder: 1),
          ],
        ),
      ),
    );
    final agg = (await repo.watchAll().first).first;
    final memo = agg.memos.single;
    expect(memo.kind, MemoKind.checklist);
    expect(memo.content!.checklist, hasLength(2));
    expect(memo.content!.checklist.first.checked, isTrue);
    expect(memo.content!.checklist.last.text, 'タオル');
  });

  test('BINGO メモが 3×3/4×4/5×5 で保存できる', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = await seeded(db);

    for (final size in [3, 4, 5]) {
      await repo.upsertMemo(
        baseMemo(
          'b$size',
          kind: MemoKind.bingo,
          title: '$size BINGO',
          content: MemoContent(
            bingo: MemoBingo(
              size: size,
              cells: List.filled(size * size, 'x'),
              selected: const [0],
            ),
          ),
        ),
      );
    }
    final agg = (await repo.watchAll().first).first;
    final sizes = agg.memos
        .map((m) => m.content?.bingo?.size)
        .whereType<int>()
        .toList()
      ..sort();
    expect(sizes, [3, 4, 5]);
  });

  test('投票メモの選択肢・票・重複可否が保存できる', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repo = await seeded(db);

    await repo.upsertMemo(
      baseMemo(
        'v1',
        kind: MemoKind.vote,
        title: 'アンコール曲',
        content: const MemoContent(
          vote: MemoVote(
            description: 'どれが来る？',
            options: [
              MemoVoteOption(id: 'o1', text: 'A'),
              MemoVoteOption(id: 'o2', text: 'B'),
              MemoVoteOption(id: 'o3', text: 'C'),
            ],
            votes: [MemoVoteRecord(voterId: 'user-1', optionId: 'o1')],
            allowDuplicate: true,
          ),
        ),
      ),
    );
    final agg = (await repo.watchAll().first).first;
    final vote = agg.memos.single.content!.vote!;
    expect(vote.options, hasLength(3));
    expect(vote.allowDuplicate, isTrue);
    expect(vote.countFor('o1'), 1);
  });

  test('既存メモ（kind/content 無し）は自由メモとして読める', () async {
    final db = createTestDb();
    addTearDown(db.close);
    // 旧形式: category のみ・kind/content を指定せず直接挿入（既定 kind='free'）。
    await db.into(db.genbaMemos).insert(
          GenbaMemosCompanion.insert(
            id: 'old',
            genbaId: 'g',
            ownerId: 'user-1',
            category: 'meetup',
            title: const Value('集合場所'),
            body: const Value('西口'),
            createdAt: '2026-01-01T00:00:00.000Z',
            updatedAt: '2026-01-01T00:00:00.000Z',
          ),
        );
    final row = await (db.select(db.genbaMemos)
          ..where((t) => t.id.equals('old')))
        .getSingle();
    expect(row.kind, 'free');
    expect(row.content, isNull);
  });
}
