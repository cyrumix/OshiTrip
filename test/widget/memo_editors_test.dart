import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/widgets/memo_editors.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';

/// メモ種類（§7.7 改訂）の UI 相互作用: 種類選択・チェックリスト追加保存・
/// BINGO 判定・投票（重複可否）。現場詳細の NestedScrollView を避け、最小ホスト
/// から追加フローを起動して検証する。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'g1';
  final clock = FixedClock(DateTime(2026, 7, 9, 12));

  Future<ProviderContainer> pumpHost(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: Consumer(
        builder: (context, ref, _) {
          // デモ認証（KV由来）を購読して owner を確定させる。未購読だと
          // showAddMemoFlow が捕捉する currentUser が null になり保存が弾かれる。
          ref.watch(currentUserProvider);
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddMemoFlow(
                  context,
                  ref,
                  genbaId: genbaId,
                  initialSortOrder: 0,
                ),
                child: const Text('add-memo'),
              ),
            ),
          );
        },
      ),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openEditor(WidgetTester tester, String kindKey) async {
    await tester.tap(find.text('add-memo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('memo_kind_$kindKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memo_template_none')));
    await tester.pumpAndSettle();
  }

  testWidgets('種類選択シートに4種と説明が出る', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.text('add-memo'));
    await tester.pumpAndSettle();

    expect(find.text('自由メモ'), findsOneWidget);
    expect(find.text('チェックリスト'), findsOneWidget);
    expect(find.text('BINGO'), findsOneWidget);
    expect(find.text('投票'), findsOneWidget);
    expect(find.text('セトリ予想やファンサBINGOを作成'), findsOneWidget);
    expect(find.text('複数候補から投票で決める'), findsOneWidget);
  });

  testWidgets('チェックリスト: 項目追加してタイトルで保存でき、実データへ入る', (tester) async {
    final container = await pumpHost(tester);
    await openEditor(tester, 'checklist');

    await tester.enterText(find.byKey(const Key('memo_title')), '持ち物');
    await tester.tap(find.byKey(const Key('checklist_add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ペンライト');

    await tester.tap(find.byKey(const Key('memo_save')));
    await tester.pumpAndSettle();

    // 実データ（Drift 行）を直接読み、保存内容を検証する。
    final db = container.read(databaseProvider);
    final rows = await db.select(db.genbaMemos).get();
    final row = rows.singleWhere((GenbaMemoRow r) => r.genbaId == genbaId);
    expect(row.kind, 'checklist');
    expect(row.title, '持ち物');
    expect(row.content, contains('ペンライト'));
  });

  testWidgets('BINGO: プレイモードで1列そろえると BINGO 表示', (tester) async {
    await pumpHost(tester);
    await openEditor(tester, 'bingo');

    // 3×3 が既定（9マス）。
    expect(find.byKey(const Key('bingo_cell_8')), findsOneWidget);
    expect(find.byKey(const Key('bingo_cell_9')), findsNothing);

    // プレイモードへ切り替え。
    await tester.tap(find.text('プレイ'));
    await tester.pumpAndSettle();

    // 横1列（0,1,2）を選択 → BINGO 表示。
    for (final i in [0, 1, 2]) {
      await tester.tap(find.byKey(Key('bingo_cell_$i')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('bingo_result')), findsOneWidget);
    expect(find.textContaining('BINGO! ×1'), findsOneWidget);

    // 1マス解除で BINGO が戻る。
    await tester.tap(find.byKey(const Key('bingo_cell_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bingo_result')), findsNothing);
  });

  testWidgets('投票: 選択肢へ投票でき、重複OFFでは1票に切り替わる', (tester) async {
    await pumpHost(tester);
    await openEditor(tester, 'vote');

    // 選択肢を2つ追加。
    await tester.tap(find.byKey(const Key('vote_add_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vote_add_option')));
    await tester.pumpAndSettle();
    final optionFields = find.byType(TextField);
    // [0]=タイトル, [1]=説明, [2]=選択肢A, [3]=選択肢B
    await tester.enterText(optionFields.at(2), 'A');
    await tester.enterText(optionFields.at(3), 'B');
    await tester.pumpAndSettle();

    // A へ投票 → 総数1。
    final voteButtons = find.byWidgetPredicate(
      (w) => w is InkWell && w.borderRadius == BorderRadius.circular(999),
    );
    await tester.tap(voteButtons.at(0));
    await tester.pumpAndSettle();
    expect(find.text('投票総数: 1'), findsOneWidget);

    // 重複OFF（既定）で B へ投票 → A から切り替わり総数は1のまま。
    await tester.tap(voteButtons.at(1));
    await tester.pumpAndSettle();
    expect(find.text('投票総数: 1'), findsOneWidget);
  });

  testWidgets('投票: 重複ONでは同じ人が複数選択肢へ投票できる', (tester) async {
    await pumpHost(tester);
    await openEditor(tester, 'vote');

    await tester.tap(find.byKey(const Key('vote_add_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vote_add_option')));
    await tester.pumpAndSettle();
    final optionFields = find.byType(TextField);
    await tester.enterText(optionFields.at(2), 'A');
    await tester.enterText(optionFields.at(3), 'B');
    await tester.pumpAndSettle();

    // 重複投票を許可へ切り替え。
    await tester.tap(find.byKey(const Key('vote_allow_duplicate')));
    await tester.pumpAndSettle();

    final voteButtons = find.byWidgetPredicate(
      (w) => w is InkWell && w.borderRadius == BorderRadius.circular(999),
    );
    // A・B の両方へ投票 → 総数2。
    await tester.tap(voteButtons.at(0));
    await tester.pumpAndSettle();
    await tester.tap(voteButtons.at(1));
    await tester.pumpAndSettle();
    expect(find.text('投票総数: 2'), findsOneWidget);
  });
}
