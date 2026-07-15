import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_list_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 現場一覧のR7移行（design-spec §6.3 / H-07）:
/// 状態（文字＋アイコン）・準備状態・残日数・中止現場の非消失・empty状態。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  testWidgets('未来の現場が状態チップ・準備チップ・残日数つきで表示され、中止も消えない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaListScreen(),
    );

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'g-scheduled',
        ownerId: ownerId,
        title: '予定の公演',
        eventDate: DateTime(2026, 8, 1),
        venue: '東京ドーム',
        startTimeMinutes: 18 * 60,
      ),
    );
    await repo.upsertGenba(
      makeGenba(
        id: 'g-canceled',
        ownerId: ownerId,
        title: '中止になった公演',
        eventDate: DateTime(2026, 8, 10),
        isCanceled: true,
      ),
    );
    await tester.pumpAndSettle();

    // 予定の公演: 日付・会場・残日数（7/2→8/1 = 30日）・状態チップ。
    expect(find.text('予定の公演'), findsOneWidget);
    expect(find.text('東京ドーム'), findsOneWidget);
    expect(find.text('あと30日'), findsOneWidget);
    expect(find.bySemanticsLabel('状態: 予定'), findsOneWidget);

    // 準備状態は実データから導出（チケット未登録）。半券タイルはアイコン＋
    // ラベル＋状態の縦積みなので、状態は Semantics ラベルで検証する。
    expect(find.bySemanticsLabel('チケット: 未登録'), findsNWidgets(2));
    // 持ち物はTodoとは別に、独立した準備タイルとして一覧にも出る。
    expect(find.bySemanticsLabel('持ち物: 未登録'), findsNWidgets(2));

    // 未来の中止現場は一覧から消えず「中止」と分かる（H-07）。
    expect(find.text('中止になった公演'), findsOneWidget);
    expect(find.bySemanticsLabel('状態: 中止'), findsOneWidget);

    // FAB。
    expect(find.byTooltip('現場を登録'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('現場ゼロは empty 状態（説明と次の1アクション）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaListScreen(),
    );
    expect(find.text('これからの現場がありません'), findsOneWidget);
    expect(find.text('現場を登録する'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('準備チップは Todo→持ち物→チケット→交通→宿泊→次にやる の順で並ぶ', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaListScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-order',
            ownerId: ownerId,
            title: '並び順検証公演',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();

    // Todo は持ち物の左に追加され、固定の並び順で表示される。
    const tileLabels = ['Todo', '持ち物', 'チケット', '交通', '宿泊'];
    const semanticsLabels = [
      'Todo: 未登録',
      '持ち物: 未登録',
      'チケット: 未登録',
      '交通: 未登録',
      '宿泊: 未登録',
    ];
    for (final s in semanticsLabels) {
      expect(find.bySemanticsLabel(s), findsOneWidget, reason: '$s が表示される');
    }

    // 半券タイルは1行に並ぶ（同じ行で左→右）。ラベル文字の中心位置で判定する。
    final centers = [
      for (final l in tileLabels) tester.getCenter(find.text(l)),
    ];
    for (var i = 0; i < centers.length - 1; i++) {
      expect(
        (centers[i].dy - centers[i + 1].dy).abs() < 4,
        isTrue,
        reason: '${tileLabels[i]} と ${tileLabels[i + 1]} は同じ行',
      );
      expect(
        centers[i + 1].dx > centers[i].dx,
        isTrue,
        reason: '${tileLabels[i]} が ${tileLabels[i + 1]} より左',
      );
    }

    // 5タイルは等幅（Expanded）。ラベル中心の間隔がほぼ一定であることで確認する。
    final pitches = [
      for (var i = 0; i < centers.length - 1; i++)
        centers[i + 1].dx - centers[i].dx,
    ];
    for (final p in pitches) {
      expect(
        (p - pitches.first).abs() < 1.5,
        isTrue,
        reason: 'タイル間隔が均等（=等幅）であること: $pitches',
      );
    }

    // 「次にやる」は既存ロジック（deriveNextAction）の表示文字をそのまま使い、
    // タイル列のあと（下）に全幅1行で出る。
    final next = find.text('次にやる: チケット情報を登録する');
    expect(next, findsOneWidget);
    expect(tester.getTopLeft(next).dy, greaterThan(centers.last.dy));
    await unmountApp(tester);
  });

  testWidgets('長い公演名・会場・次アクションでもカードが崩れない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaListScreen(),
    );
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'g-long',
        ownerId: ownerId,
        title: 'とても長い公演名が省略されて欠落しないことを確認するための全国ホールツアー2026 追加公演 スペシャルアンコール',
        eventDate: DateTime(2026, 8, 1),
        venue: 'とても長い会場名の多目的アリーナ特設ステージ さいたま新都心第二会場',
      ),
    );
    // チケットは取得済みにして、「次にやる」を長いTodo名にする。
    await repo.upsertTicket(
      makeTicket(
        id: 'ticket-long',
        genbaId: 'g-long',
        ownerId: ownerId,
        acquisition: TicketAcquisition.acquired,
      ),
    );
    await repo.upsertTodo(
      makeTodo(
        id: 'todo-long',
        genbaId: 'g-long',
        ownerId: ownerId,
        name: 'とても長い名前のやることをここに書いて省略表示を確認する',
        priority: TodoPriority.high,
      ),
    );
    await tester.pumpAndSettle();

    // レイアウト例外（overflow等）が発生しない。
    expect(tester.takeException(), isNull);
    // 次にやるは既存ロジックの文字（Todo名）で1行表示される。
    expect(find.textContaining('次にやる: Todo「'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('狭幅（320）・ダークテーマでも半券タイルが崩れない', (tester) async {
    // 320論理幅（640物理 / 2.0dpr）。5タイル＋次にやるが破綻しないこと。
    tester.view.physicalSize = const Size(640, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      dark: true,
      child: const GenbaListScreen(),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'g-narrow',
            ownerId: ownerId,
            title: '狭幅ダーク検証公演',
            eventDate: DateTime(2026, 8, 1),
            venue: '幕張メッセ',
          ),
        );
    await tester.pumpAndSettle();

    // 例外なし＋5タイルの状態が読み上げ可能（Semantics 維持）。
    expect(tester.takeException(), isNull);
    for (final s in const [
      'Todo: 未登録',
      '持ち物: 未登録',
      'チケット: 未登録',
      '交通: 未登録',
      '宿泊: 未登録',
    ]) {
      expect(find.bySemanticsLabel(s), findsOneWidget, reason: '$s が読み上げ可能');
    }
    await unmountApp(tester);
  });
}
