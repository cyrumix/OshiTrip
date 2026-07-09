import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/data/memo_template_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/domain/memo_template.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// メモテンプレート（§7.7 改訂）: 保存・再利用（watch）・削除・owner 分離と、
/// 「テンプレート編集が作成済みメモに影響しない（別行・コピー方式）」の検証。
void main() {
  final clock = FixedClock(DateTime(2026, 7, 9, 12));

  ({MemoTemplateRepositoryImpl tpl, GenbaRepositoryImpl genba}) reposFor(
    AppDatabase db, {
    String owner = 'user-1',
  }) {
    final outbox = OutboxStore(db, clock);
    final engine = SyncEngine(
      store: outbox,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
    );
    addTearDown(engine.dispose);
    return (
      tpl: MemoTemplateRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
      ),
      genba: GenbaRepositoryImpl(
        db: db,
        outbox: outbox,
        syncEngine: engine,
        clock: clock,
        ownerIdResolver: () => owner,
        remoteResolver: () => null,
      ),
    );
  }

  MemoTemplate template(
    String id, {
    String owner = 'user-1',
    String name = 'マイ持ち物',
    MemoKind kind = MemoKind.checklist,
    MemoContent? content,
  }) =>
      MemoTemplate(
        id: id,
        ownerId: owner,
        name: name,
        kind: kind,
        content: content ??
            const MemoContent(
              checklist: [MemoChecklistItem(id: 'i1', text: 'ペンライト')],
            ),
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  test('テンプレートを保存・一覧・削除できる', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repos = reposFor(db);

    expect((await repos.tpl.upsertTemplate(template('t1'))).isOk, isTrue);
    var list = await repos.tpl.watchAll().first;
    expect(list.single.name, 'マイ持ち物');
    expect(list.single.kind, MemoKind.checklist);

    await repos.tpl.upsertTemplate(
      template('t1').copyWith(name: '改名', updatedAt: clock.now()),
    );
    list = await repos.tpl.watchAll().first;
    expect(list.single.name, '改名');

    await repos.tpl.deleteTemplate('t1');
    expect(await repos.tpl.watchAll().first, isEmpty);
  });

  test('別 owner のテンプレートは見えない（C-01）', () async {
    final db = createTestDb();
    addTearDown(db.close);
    await reposFor(db, owner: 'user-1').tpl.upsertTemplate(template('t1'));

    final other = reposFor(db, owner: 'user-2');
    expect(await other.tpl.watchAll().first, isEmpty);
  });

  test('テンプレートを編集しても作成済みメモは変わらない（別行・コピー方式）', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final repos = reposFor(db);
    await repos.genba.upsertGenba(
      makeGenba(id: 'g1', ownerId: 'user-1', eventDate: DateTime(2026, 8, 1)),
    );

    // テンプレート T（項目=ペンライト）を保存。
    await repos.tpl.upsertTemplate(template('t1'));

    // T を適用したメモ M（内容をコピー）を作成・保存する。
    final memo = GenbaMemo(
      id: 'm1',
      genbaId: 'g1',
      ownerId: 'user-1',
      kind: MemoKind.checklist,
      title: '持ち物',
      content: const MemoContent(
        checklist: [MemoChecklistItem(id: 'i1', text: 'ペンライト')],
      ),
      createdAt: fixedCreatedAt,
      updatedAt: fixedCreatedAt,
    );
    await repos.genba.upsertMemo(memo);

    // T を編集（項目をタオルへ）。
    await repos.tpl.upsertTemplate(
      template('t1').copyWith(
        content: const MemoContent(
          checklist: [MemoChecklistItem(id: 'i9', text: 'タオル')],
        ),
        updatedAt: clock.now(),
      ),
    );

    // M は変わらない。
    final agg = (await repos.genba.watchAll().first).first;
    expect(agg.memos.single.content!.checklist.single.text, 'ペンライト');
  });
}
