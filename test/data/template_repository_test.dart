import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/templates/data/template_repository_impl.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late OutboxStore outbox;
  late SyncEngine engine;
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  TemplateRepositoryImpl repoFor(String? owner) => TemplateRepositoryImpl(
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

  test('現在の項目からテンプレートを保存し、項目込みで読み出せる', () async {
    final repo = repoFor('user-1');
    final template = makeTemplate(id: 'tpl-a', name: '基本Todo');
    final items = [
      makeTemplateItem(id: 'i1', templateId: 'tpl-a', name: 'A', sortOrder: 0),
      makeTemplateItem(id: 'i2', templateId: 'tpl-a', name: 'B', sortOrder: 1),
    ];
    final result = await repo.saveTemplateWithItems(
      template: template,
      items: items,
    );
    expect(result.isOk, isTrue);

    final all = await repo.watchAll().first;
    expect(all, hasLength(1));
    expect(all.single.template.name, '基本Todo');
    expect(all.single.sortedItems.map((i) => i.name), ['A', 'B']);

    // 同期のため Outbox にテンプレート本体＋各項目の op が積まれる。
    final ops = await outbox.pendingOps(ownerId: 'user-1');
    expect(
      ops.where((o) => o.entityTable == SyncEntity.todoTemplates),
      hasLength(1),
    );
    expect(
      ops.where((o) => o.entityTable == SyncEntity.todoTemplateItems),
      hasLength(2),
    );
  });

  test('Todoテンプレートと持ち物テンプレートは混在せず種別ごとに保持される', () async {
    final repo = repoFor('user-1');
    await repo.upsertTemplate(
      makeTemplate(id: 'tpl-todo', name: 'Todo用', itemType: TodoItemType.todo),
    );
    await repo.upsertTemplate(
      makeTemplate(
        id: 'tpl-belong',
        name: '持ち物用',
        itemType: TodoItemType.belonging,
      ),
    );
    final all = await repo.watchAll().first;
    final byType = {for (final t in all) t.template.id: t.template.itemType};
    expect(byType['tpl-todo'], TodoItemType.todo);
    expect(byType['tpl-belong'], TodoItemType.belonging);
  });

  test('項目の編集・削除、テンプレート削除（項目もカスケード）ができる', () async {
    final repo = repoFor('user-1');
    await repo.upsertTemplate(makeTemplate(id: 'tpl-a'));
    await repo.upsertItem(
      makeTemplateItem(id: 'i1', templateId: 'tpl-a', name: '旧名'),
    );
    // 編集（rename）。
    await repo.upsertItem(
      makeTemplateItem(id: 'i1', templateId: 'tpl-a', name: '新名'),
    );
    var all = await repo.watchAll().first;
    expect(all.single.items.single.name, '新名');

    // 項目削除。
    await repo.deleteItem('i1');
    all = await repo.watchAll().first;
    expect(all.single.items, isEmpty);

    // テンプレート削除で項目もカスケード削除（残さない）。
    await repo.upsertItem(
      makeTemplateItem(id: 'i2', templateId: 'tpl-a', name: '残る?'),
    );
    await repo.deleteTemplate('tpl-a');
    all = await repo.watchAll().first;
    expect(all, isEmpty);
    final remainingItems = await db.select(db.todoTemplateItems).get();
    expect(remainingItems, isEmpty);
  });

  test('別ownerのテンプレートは読み書きできない（C-01）', () async {
    final repoA = repoFor('user-1');
    await repoA.saveTemplateWithItems(
      template: makeTemplate(id: 'tpl-a', ownerId: 'user-1'),
      items: [
        makeTemplateItem(id: 'i1', templateId: 'tpl-a', ownerId: 'user-1')
      ],
    );

    // owner B からは見えない。
    final repoB = repoFor('user-2');
    expect(await repoB.watchAll().first, isEmpty);

    // owner B が同じ id を奪おうとする upsert は AuthFailure で拒否される。
    final hijack = await repoB.upsertTemplate(
      makeTemplate(id: 'tpl-a', ownerId: 'user-2'),
    );
    expect(hijack.failureOrNull, isNotNull);

    // owner B の delete は自分の行のみ対象で、A の行は消えない。
    await repoB.deleteTemplate('tpl-a');
    final stillThere = await repoA.watchAll().first;
    expect(stillThere, hasLength(1));
  });

  test('未認証では読み書きできない（owner未解決）', () async {
    final repo = repoFor(null);
    expect(await repo.watchAll().first, isEmpty);
    final res = await repo.upsertTemplate(makeTemplate());
    expect(res.failureOrNull, isNotNull);
  });

  test('再起動相当（同一DBの別リポジトリ）でもユーザーテンプレートが維持される', () async {
    final repo1 = repoFor('user-1');
    await repo1.saveTemplateWithItems(
      template: makeTemplate(id: 'tpl-a', name: '永続確認'),
      items: [
        makeTemplateItem(id: 'i1', templateId: 'tpl-a', name: 'X'),
        makeTemplateItem(id: 'i2', templateId: 'tpl-a', name: 'Y'),
      ],
    );
    // 同じローカルDBを使う新しいリポジトリインスタンス（アプリ再起動相当）。
    final repo2 = repoFor('user-1');
    final all = await repo2.watchAll().first;
    expect(all, hasLength(1));
    expect(all.single.template.name, '永続確認');
    expect(all.single.sortedItems.map((i) => i.name), ['X', 'Y']);
  });
}
