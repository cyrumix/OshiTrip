import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/app.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// ルートガード（未認証/チュートリアル未完了 redirect）と5タブの検証。
void main() {
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<AppDatabase> prepareDb({
    required bool tutorialDone,
    required bool signedIn,
  }) async {
    final db = createTestDb();
    final kv = DriftKvStore(db);
    if (tutorialDone) {
      await kv.put(KvKeys.tutorialDone, '1');
    }
    if (signedIn) {
      await kv.put(
        KvKeys.demoUser,
        jsonEncode({'id': 'demo-user-1', 'email': 'demo@example.com'}),
      );
    }
    return db;
  }

  Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(demoEnv),
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          nowProvider.overrideWith((ref) => Stream.value(clock.now())),
        ],
        child: const OshiExpeditionApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('チュートリアル未完了ならオンボーディングへリダイレクト', (tester) async {
    final db = await prepareDb(tutorialDone: false, signedIn: false);
    addTearDown(db.close);
    await pumpApp(tester, db);

    expect(find.text('現場を、ひとつにまとめる'), findsOneWidget);
    expect(find.bySemanticsLabel('チュートリアルをスキップ'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('チュートリアル完了・未認証ならログインへリダイレクト', (tester) async {
    final db = await prepareDb(tutorialDone: true, signedIn: false);
    addTearDown(db.close);
    await pumpApp(tester, db);

    expect(find.widgetWithText(AppBar, 'ログイン'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('認証済みならホーム（5タブ）が表示される', (tester) async {
    final db = await prepareDb(tutorialDone: true, signedIn: true);
    addTearDown(db.close);
    await pumpApp(tester, db);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['ホーム', '現場', '思い出', 'マイ推し', '設定']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    // デモモードはバナーで明示される
    expect(find.textContaining('デモモード'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('5タブを切り替えても各画面が表示される', (tester) async {
    final db = await prepareDb(tutorialDone: true, signedIn: true);
    addTearDown(db.close);
    await pumpApp(tester, db);

    Future<void> tapTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await tapTab('現場');
    expect(find.text('これからの現場がありません'), findsOneWidget);

    await tapTab('思い出');
    expect(find.text('まだ思い出がありません'), findsOneWidget);

    await tapTab('マイ推し');
    expect(find.text('まだ推しが登録されていません'), findsOneWidget);

    await tapTab('設定');
    expect(find.text('チュートリアルをもう一度見る'), findsOneWidget);

    await tapTab('ホーム');
    expect(find.text('予定している現場がありません'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('ログアウトするとログイン画面へ戻る', (tester) async {
    final db = await prepareDb(tutorialDone: true, signedIn: true);
    addTearDown(db.close);
    await pumpApp(tester, db);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('設定'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('ログアウト'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'ログイン'), findsOneWidget);
    await unmountApp(tester);
  });
}
