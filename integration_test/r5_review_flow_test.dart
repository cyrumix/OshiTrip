import 'dart:convert';
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
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';
import 'package:sqlite3/open.dart';

/// R5再レビュー統合テスト補完（R1の中心フロー`app_flow_test.dart`は変更せず
/// 維持し、このファイルで以下を独立して検証する）。
///
/// - 未来の中止現場が現場一覧から消えず、取消できる
/// - 手動終演後に取消・時刻訂正ができる
/// - 同一操作（Todo保存）を連打しても保存が一度だけ行われる
/// - 推しグループ・推しメンを選択し、保存・アプリ再起動後も復元される
/// - 交通要否・宿泊要否を並行更新しても両方保持される（read-latest-merge）
///
/// 保存失敗時のロールバック（integration testでは実データ書込みを狙って
/// 失敗させる注入点が無いため）は `test/widget/genba_todo_failure_rollback_test.dart`
/// で検証する（理由は docs/decisions.md に記録）。
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
  const ownerId = 'demo-user-1';

  AppDatabase createDb() {
    if (Platform.isWindows) {
      open.overrideFor(
        OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'),
      );
    }
    return AppDatabase(NativeDatabase.memory());
  }

  Future<void> seedSignedIn(AppDatabase db) async {
    // チュートリアル・ログインUIは app_flow_test.dart で既に検証済みのため、
    // ここでは既ログイン状態から開始し、対象の操作検証に集中する。
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': ownerId, 'email': 'demo@example.com'}),
    );
  }

  testWidgets(
    '中止取消・終演取消/訂正・二重タップ・推し選択復元・要否並行更新（R5再レビュー）',
    (tester) async {
      final db = createDb();
      addTearDown(db.close);
      await seedSignedIn(db);

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

      Future<void> goToGenbaTab() async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('現場'),
          ),
        );
        await tester.pumpAndSettle();
      }

      Finder chipIn(Finder sectionTitle, String label) {
        final card =
            find.ancestor(of: sectionTitle, matching: find.byType(Card));
        return find.descendant(of: card, matching: find.text(label));
      }

      Future<void> tapAddIn(Finder sectionTitle) async {
        final card =
            find.ancestor(of: sectionTitle, matching: find.byType(Card));
        await tester.tap(find.descendant(of: card, matching: find.text('追加')));
        await tester.pumpAndSettle();
      }

      var container = await pumpApp();
      // 事前セットアップ済みKVによりチュートリアル・ログインは表示されず、
      // 直接5タブ画面から開始する。
      expect(find.byType(NavigationBar), findsOneWidget);

      // ---- 事前データ: 推しグループ・メンバーを用意する（#5 の前提） ----
      final now = DateTime.now().toUtc();
      final oshi = container.read(oshiRepositoryProvider);
      await oshi.upsertGroup(
        OshiGroup(
          id: 'r5-grp-1',
          ownerId: ownerId,
          name: 'R5レビューグループ',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await oshi.upsertMember(
        OshiMember(
          id: 'r5-mem-1',
          groupId: 'r5-grp-1',
          ownerId: ownerId,
          name: 'メンバーX',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // ---- 現場を登録する（推しグループ・メンバー選択を含む, #5） ----
      await goToGenbaTab();
      expect(find.text('予定している現場がありません'), findsOneWidget);
      await tester.tap(find.text('現場を登録'));
      await tester.pumpAndSettle();

      // 推しグループのチップが実データから出る → 選択するとアーティスト名が
      // 自動入力される（グループ／アーティスト名フィールドへの手動入力は不要）。
      await tester.tap(find.widgetWithText(ChoiceChip, 'R5レビューグループ'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'メンバーX'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, '公演名 *'),
        'R5レビュー統合テスト公演',
      );
      await tester.tap(find.text('日付 *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // DatePicker: 初期値 = 本日
      await tester.pumpAndSettle();
      await tester.tap(find.text('登録する'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'R5レビュー統合テスト公演'), findsOneWidget);
      final genbaId =
          (await container.read(genbaRepositoryProvider).watchAll().first)
              .firstWhere((a) => a.genba.title == 'R5レビュー統合テスト公演')
              .genba
              .id;

      // ---- #1 未来の中止現場が現場一覧から消えず、取消できる ----
      const futureGenbaId = 'r5-future-cancel';
      await container.read(genbaRepositoryProvider).upsertGenba(
            Genba(
              id: futureGenbaId,
              ownerId: ownerId,
              artistName: '未来グループ',
              title: '未来の単独公演',
              eventDate: DateTime.now().add(const Duration(days: 60)),
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      await tester.pumpAndSettle();

      await goToGenbaTab();
      expect(find.text('未来の単独公演'), findsOneWidget);

      await tester.tap(find.text('未来の単独公演'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('その他の操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中止にする'));
      await tester.pumpAndSettle();
      expect(find.text('現場を中止にする'), findsOneWidget); // 確認ダイアログ
      await tester.tap(find.text('中止にする').last);
      await tester.pumpAndSettle();
      expect(find.text('中止'), findsWidgets);

      await goToGenbaTab();
      // 一覧から消えていない（H-07 の核心）。
      expect(find.text('未来の単独公演'), findsOneWidget);
      expect(find.text('中止'), findsWidgets);

      await tester.tap(find.text('未来の単独公演'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('その他の操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中止を取り消す'));
      await tester.pumpAndSettle();
      expect(find.text('中止'), findsNothing);

      // メインの現場（R5レビュー統合テスト公演）へ戻る。
      await goToGenbaTab();
      await tester.tap(find.text('R5レビュー統合テスト公演'));
      await tester.pumpAndSettle();

      // ---- #6 交通要否と宿泊要否を並行更新しても両方保持される ----
      // 2つのタップの間に pumpAndSettle を挟まない = 両方が同一の古い
      // Genbaスナップショットから発火する「並行更新」を模す
      // （read-latest-merge 前は片方が失われ得た）。
      await tester.tap(chipIn(find.text('交通'), '必要'));
      await tester.tap(chipIn(find.text('宿泊'), '宿泊なし'));
      await tester.pumpAndSettle();

      final afterRequirements = await container
          .read(genbaRepositoryProvider)
          .watchById(genbaId)
          .first;
      expect(afterRequirements!.genba.transportRequirement.name, 'required');
      expect(afterRequirements.genba.lodgingRequirement.name, 'notRequired');

      // ---- #3 同一操作（Todo保存）を連打しても保存が一度だけ行われる ----
      await tapAddIn(find.textContaining('Todo（残り'));
      expect(find.text('Todoを追加'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Todo名 *'),
        '二重タップ検証Todo',
      );
      // pump/settle を挟まず「保存する」を2回連続でタップする（連打を模す）。
      // _EditorScaffoldState._handleSave は同期的な _saving ガードを持つため、
      // 2回目は再入として無視され、Todoは1件しか作られない（D-115）。
      await tester.tap(find.text('保存する'));
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();

      final afterTodoAdd = await container
          .read(genbaRepositoryProvider)
          .watchById(genbaId)
          .first;
      expect(
        afterTodoAdd!.todos.where((t) => t.name == '二重タップ検証Todo'),
        hasLength(1),
      );

      // ---- #2 手動終演後の取消・時刻訂正 ----
      expect(find.text('終演した（余韻中にする）'), findsOneWidget);
      await tester.tap(find.text('終演した（余韻中にする）'));
      await tester.pumpAndSettle();
      expect(find.text('終演した'), findsWidgets); // 確認ダイアログ
      await tester.tap(find.text('終演した').last);
      await tester.pumpAndSettle();
      expect(find.text('余韻中'), findsOneWidget);
      expect(find.textContaining('手動で終演済みにしています'), findsOneWidget);

      // 取消 → 確認 → 「本日」に戻り、「終演した」操作が再び案内される。
      await tester.tap(find.text('取り消す'));
      await tester.pumpAndSettle();
      expect(find.text('終演の取消'), findsOneWidget);
      await tester.tap(find.text('取り消す').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('手動で終演済みにしています'), findsNothing);
      expect(find.text('終演した（余韻中にする）'), findsOneWidget);

      final afterUndo = await container
          .read(genbaRepositoryProvider)
          .watchById(genbaId)
          .first;
      expect(afterUndo!.genba.manualEndedAt, isNull);

      // 再度「終演した」→ 今度は「時刻を訂正」でダイアログ経由の訂正を行う。
      // 正確な訂正後時刻の値そのもの（予定より早い/遅い等）は
      // test/notifier/genba_actions_controller_test.dart で決定的に検証済み
      // のため、ここではUIの導線（ボタン→日付・時刻ダイアログ→確定）が
      // クラッシュせず完了し、失敗表示にならないことを確認する。
      await tester.tap(find.text('終演した（余韻中にする）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('終演した').last);
      await tester.pumpAndSettle();
      expect(find.text('余韻中'), findsOneWidget);

      await tester.tap(find.text('時刻を訂正'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // DatePicker: 当日のまま確定
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // TimePicker: 既定時刻のまま確定
      await tester.pumpAndSettle();
      expect(find.textContaining('手動で終演済みにしています'), findsOneWidget);

      final afterCorrect = await container
          .read(genbaRepositoryProvider)
          .watchById(genbaId)
          .first;
      expect(afterCorrect!.genba.manualEndedAt, isNotNull);

      // ---- アプリ再起動後も上記すべてが復元される ----
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      container = await pumpApp();
      expect(find.byType(NavigationBar), findsOneWidget);

      final restored = await container
          .read(genbaRepositoryProvider)
          .watchById(genbaId)
          .first;
      // #5 推しグループ・推しメン選択が復元される。
      expect(restored!.genba.oshiGroupId, 'r5-grp-1');
      expect(restored.genba.oshiMemberIds, contains('r5-mem-1'));
      // #6 並行更新した両方の要否が復元される。
      expect(restored.genba.transportRequirement.name, 'required');
      expect(restored.genba.lodgingRequirement.name, 'notRequired');
      // #2 手動終演（訂正後）が復元される。
      expect(restored.genba.manualEndedAt, isNotNull);
      // #3 連打しても1件のまま。
      expect(
        restored.todos.where((t) => t.name == '二重タップ検証Todo'),
        hasLength(1),
      );

      final restoredFuture = await container
          .read(genbaRepositoryProvider)
          .watchById(futureGenbaId)
          .first;
      // #1 中止取消が復元される（誤って中止のまま残っていない）。
      expect(restoredFuture!.genba.isCanceled, isFalse);
    },
  );
}
