import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/theme/app_theme.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';
import 'package:oshi_trip/features/templates/application/template_providers.dart';
import 'package:oshi_trip/features/templates/presentation/template_manage_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// テンプレート名変更ダイアログ（_TextPromptDialog）の Controller ライフサイクル
/// を検証する。ダイアログ自身が TextEditingController を所有・破棄するため、
/// 退場アニメーション中の「disposed 後の Controller 使用」例外が起きない。
void main() {
  const ownerId = 'demo-user-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<AppDatabase> signedInDb() async {
    final db = createTestDb();
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': ownerId, 'email': 'demo@example.com'}),
    );
    return db;
  }

  Future<ProviderContainer> seeded(AppDatabase db) async {
    final c = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        nowProvider.overrideWith((ref) => Stream.value(clock.now())),
      ],
    );
    addTearDown(c.dispose);
    await c.read(currentUserProvider.future);
    await c.read(templateRepositoryProvider).upsertTemplate(
          makeTemplate(id: 'tpl-a', ownerId: ownerId, name: '元の名前'),
        );
    // 編集画面が空にならないよう、テンプレートがストリームに載るのを待つ。
    await c.read(userTemplatesProvider.future);
    return c;
  }

  Future<void> pumpEdit(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme:
              AppTheme.light().copyWith(splashFactory: InkRipple.splashFactory),
          locale: const Locale('ja'),
          supportedLocales: const [Locale('ja')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const TemplateEditScreen(templateId: 'tpl-a'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<String?> currentName(ProviderContainer c) async {
    final all = await c.read(templateRepositoryProvider).watchAll().first;
    return all.isEmpty ? null : all.single.template.name;
  }

  testWidgets('名前を変更して閉じても例外が発生しない', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);
    final c = await seeded(db);
    await pumpEdit(tester, c);

    await tester.tap(find.byTooltip('テンプレート名を変更'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '新しい名前');
    await tester.tap(find.text('変更する'));
    await tester.pumpAndSettle();

    // 退場アニメーション完了後も例外なし・ダイアログは閉じ・名称は更新される。
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await currentName(c), '新しい名前');
  });

  testWidgets('キャンセルして閉じても例外が発生しない', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);
    final c = await seeded(db);
    await pumpEdit(tester, c);

    await tester.tap(find.byTooltip('テンプレート名を変更'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '破棄される入力');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    // キャンセルでは名称は変わらない。
    expect(await currentName(c), '元の名前');
  });

  testWidgets('Enter送信でも正しく閉じる（例外なし）', (tester) async {
    final db = await signedInDb();
    addTearDown(db.close);
    final c = await seeded(db);
    await pumpEdit(tester, c);

    await tester.tap(find.byTooltip('テンプレート名を変更'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Enterで確定');
    // キーボードの確定（onSubmitted）で閉じる。
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await currentName(c), 'Enterで確定');
  });
}
