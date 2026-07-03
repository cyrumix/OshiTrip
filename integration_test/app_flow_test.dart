import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oshi_trip/app/app.dart';
import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:sqlite3/open.dart';

/// 統合テスト: 初回起動 → チュートリアル → ログイン（デモ） → 現場登録 →
/// 準備情報（チケット/交通/宿泊/Todo） → 当日 → 終演 → 思い出記録 →
/// アプリ再起動後のデータ復元（R5 / H-07）。
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

  testWidgets('初回起動→ログイン→現場登録→準備情報→当日→終演→思い出→再起動復元までの中心フロー', (tester) async {
    final db = createDb();
    addTearDown(db.close);

    Future<ProviderContainer> pumpApp() async {
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(env),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const OshiExpeditionApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> tapAddIn(Finder sectionTitle) async {
      final card = find.ancestor(
        of: sectionTitle,
        matching: find.byType(Card),
      );
      await tester.tap(find.descendant(of: card, matching: find.text('追加')));
      await tester.pumpAndSettle();
    }

    Future<void> selectRequirement(Finder sectionTitle, String label) async {
      final card = find.ancestor(
        of: sectionTitle,
        matching: find.byType(Card),
      );
      await tester.tap(find.descendant(of: card, matching: find.text(label)));
      await tester.pumpAndSettle();
    }

    var container = await pumpApp();

    // 1. 初回起動: チュートリアル（スキップ可能）
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

    // 3. ホーム（空状態）→ 現場登録（公演日=本日）
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
    await tester.tap(find.text('OK')); // DatePicker: 初期値 = 本日
    await tester.pumpAndSettle();
    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    // 4. 詳細画面（本日公演なので「終演した」操作が案内される）
    expect(find.widgetWithText(AppBar, '統合テスト公演'), findsOneWidget);

    final genbaId =
        (await container.read(genbaRepositoryProvider).watchAll().first)
            .single
            .genba
            .id;

    // 5. 準備情報: チケットを追加（フィールドは任意、既定値のまま保存できる）
    await tapAddIn(find.text('チケット'));
    expect(find.text('チケットを追加'), findsOneWidget);
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 6. 交通は「必要」にして1件追加する
    await selectRequirement(find.text('交通'), '必要');
    await tapAddIn(find.text('交通'));
    expect(find.text('交通を追加'), findsOneWidget);
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 7. 宿泊は「不要」（＝未登録とは区別される明示的な不要）
    await selectRequirement(find.text('宿泊'), '宿泊なし');

    // 8. Todoを1件追加する
    await tapAddIn(find.textContaining('Todo（残り'));
    expect(find.text('Todoを追加'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Todo名 *'),
      '銀テを持参する',
    );
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();
    expect(find.text('銀テを持参する'), findsOneWidget);

    // ここまでの書込みがすべて反映されていることを確認する
    // （型付きFailureを無視して成功表示しない設計の裏取り）。
    final afterPrep =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(afterPrep!.tickets, hasLength(1));
    expect(afterPrep.transports, hasLength(1));
    expect(afterPrep.genba.transportRequirement.name, 'required');
    expect(afterPrep.genba.lodgingRequirement.name, 'notRequired');
    expect(afterPrep.todos, hasLength(1));

    // 9. 当日: 「終演した」操作 → 確認ダイアログ → 余韻中へ
    expect(find.text('終演した（余韻中にする）'), findsOneWidget);
    await tester.tap(find.text('終演した（余韻中にする）'));
    await tester.pumpAndSettle();
    expect(find.text('終演した'), findsWidgets); // 確認ダイアログ
    await tester.tap(find.text('終演した').last);
    await tester.pumpAndSettle();
    expect(find.text('余韻中'), findsOneWidget);
    expect(find.text('思い出を記録する'), findsOneWidget);

    // 10. 思い出を記録する
    await tester.tap(find.text('思い出を記録する'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '思い出を記録'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(
        TextField,
        '感想（短いひとことでOK・あとから加筆できます）',
      ),
      '楽しい統合テストだった',
    );
    // 自動保存のデバウンスを経過させる
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final memoryAfterEdit = await container
        .read(memoryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(memoryAfterEdit.entry?.impression, '楽しい統合テストだった');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // KVにチュートリアル完了が保存されている（再表示されない）
    final kv = DriftKvStore(db);
    expect(await kv.get(KvKeys.tutorialDone), '1');

    // 11. アプリ再起動（同一DB=端末内保存を想定）してもデータが失われない
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));

    container = await pumpApp();
    // チュートリアル・ログインは再表示されず、直接5タブ画面へ復元される。
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('現場'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('統合テスト公演'), findsOneWidget);
    expect(find.text('余韻中'), findsWidgets);

    final restored =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(restored!.genba.title, '統合テスト公演');
    expect(restored.tickets, hasLength(1));
    expect(restored.transports, hasLength(1));
    expect(restored.todos, hasLength(1));
    expect(restored.genba.manualEndedAt, isNotNull);

    final restoredMemory = await container
        .read(memoryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(restoredMemory.entry?.impression, '楽しい統合テストだった');
  });
}
