import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';
import 'package:oshi_trip/features/templates/presentation/template_manage_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 現場詳細の Todo・持ち物タブに、テンプレート操作の入口が表示され、
/// 「テンプレートから追加」で標準プリセットが選択できることを確認する。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'gb-tpl-ui';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<void> openTodoTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Todo・持ち物'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('テンプレート操作の入口が表示され、プリセットを選択できる', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    // 入口: 管理ボタン1つ、テンプレートから追加は Todo/持ち物 の2セクション分。
    expect(find.text('テンプレートを管理'), findsOneWidget);
    expect(find.text('テンプレートから追加'), findsNWidgets(2));

    // 持ち物セクション側（末尾）の「テンプレートから追加」を開く。
    await tester.tap(find.text('テンプレートから追加').last);
    await tester.pumpAndSettle();

    // 標準プリセット（持ち物）が選択肢に出る。
    expect(find.text('ライブ・イベントの基本持ち物'), findsOneWidget);
    expect(find.text('標準'), findsWidgets);

    // プリセットを選ぶと項目チェックリストと追加ボタンが出る。
    await tester.tap(find.text('ライブ・イベントの基本持ち物'));
    await tester.pumpAndSettle();
    expect(find.text('チケット'), findsWidgets);
    expect(find.textContaining('件を追加'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('テンプレートを管理から新規作成の入口が開ける', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await openTodoTab(tester);

    await tester.tap(find.text('テンプレートを管理'));
    await tester.pumpAndSettle();

    // 管理画面: 標準プリセット2件が読み取り専用で並ぶ。
    expect(find.byType(TemplateManageScreen), findsOneWidget);
    expect(find.text('ライブ・イベントの基本準備'), findsOneWidget);
    expect(find.text('ライブ・イベントの基本持ち物'), findsOneWidget);
    expect(find.text('マイテンプレート'), findsOneWidget);

    await unmountApp(tester);
  });
}
