import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oshi_expedition/app/app.dart';
import 'package:oshi_expedition/core/config/env.dart';
import 'package:oshi_expedition/core/db/app_database.dart';
import 'package:oshi_expedition/core/providers.dart';
import 'package:oshi_expedition/core/storage/kv_store.dart';
import 'package:sqlite3/open.dart';

/// 統合テスト: 初回起動 → チュートリアル → ログイン（デモ） → 現場登録 → ホーム表示。
///
/// 実行にはエミュレータ/実機が必要:
///   flutter test integration_test --flavor development
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const env = AppEnv(
    flavor: Flavor.development,
    supabaseUrl: '',
    supabaseAnonKey: '',
    logLevelName: 'debug',
  );

  AppDatabase createDb() {
    if (Platform.isWindows) {
      open.overrideFor(
        OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'),
      );
    }
    return AppDatabase(NativeDatabase.memory());
  }

  testWidgets('初回起動から現場登録までの中心フロー', (tester) async {
    final db = createDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(env),
          databaseProvider.overrideWithValue(db),
        ],
        child: const OshiExpeditionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. チュートリアル（スキップ可能）
    expect(find.text('現場を、ひとつにまとめる'), findsOneWidget);
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();

    // 2. ログイン（デモモード）
    expect(find.widgetWithText(AppBar, 'ログイン'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'メールアドレス'),
      'demo@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'パスワード'),
      'demo-pass',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();

    // 3. ホーム（空状態）→ 現場登録
    expect(find.text('予定している現場がありません'), findsOneWidget);
    await tester.tap(find.text('現場を登録'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'グループ／アーティスト名 *'),
      '推しグループ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '公演名 *'),
      '統合テスト公演',
    );
    await tester.tap(find.text('日付 *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    // 4. 詳細画面 → ホームに現場が表示される
    expect(find.widgetWithText(AppBar, '統合テスト公演'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('ホーム'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('統合テスト公演'), findsOneWidget);

    // KVにチュートリアル完了が保存されている（再表示されない）
    final kv = DriftKvStore(db);
    expect(await kv.get(KvKeys.tutorialDone), '1');
  });
}
