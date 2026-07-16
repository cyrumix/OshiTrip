import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/memory/presentation/memory_edit_widgets.dart';

/// 追加入力行（[ListEditor] 内の共有 `_AddRow`）の失敗・例外時の復帰（レビュー是正）。
void main() {
  Future<TextEditingController> pumpEditor(
    WidgetTester tester, {
    required Future<Object?> Function(String) onAdd,
  }) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListEditor(
            title: 'セトリ',
            icon: Icons.queue_music,
            inputController: controller,
            inputHint: '曲名を追加',
            items: const [],
            onAdd: onAdd,
            onDelete: (id) async => null,
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('onAdd が例外を throw しても入力が残り、追加ボタンが復帰する', (tester) async {
    final controller = await pumpEditor(
      tester,
      onAdd: (_) async => throw Exception('boom'),
    );

    await tester.enterText(find.byType(TextField), 'テスト曲');
    await tester.tap(find.byTooltip('追加'));
    await tester.pump(); // busy=true（送信開始）
    await tester.pump(); // await 完了→catch/finally

    // 入力は消えない（成功していないため）。
    expect(controller.text, 'テスト曲');
    // ボタンは復帰（進行中スピナーが消える＝再度押せる）。
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // 失敗が伝わる。
    expect(find.text('追加できませんでした'), findsOneWidget);
  });

  testWidgets('onAdd が Failure を返しても入力が残り、ボタンが復帰する', (tester) async {
    final controller = await pumpEditor(
      tester,
      onAdd: (_) async => const UnavailableFailure(),
    );

    await tester.enterText(find.byType(TextField), '未保存曲');
    await tester.tap(find.byTooltip('追加'));
    await tester.pump();
    await tester.pump();

    expect(controller.text, '未保存曲');
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('onAdd 成功時は入力がクリアされる', (tester) async {
    final controller = await pumpEditor(
      tester,
      onAdd: (_) async => null,
    );

    await tester.enterText(find.byType(TextField), '成功曲');
    await tester.tap(find.byTooltip('追加'));
    await tester.pump();
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
