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

/// 主要フロー: 現場作成 → ホーム表示 → 当日表示 → 余韻中 → 思い出表示。
void main() {
  Future<AppDatabase> prepareSignedInDb() async {
    final db = createTestDb();
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': 'demo-user-1', 'email': 'demo@example.com'}),
    );
    return db;
  }

  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    AppDatabase db,
    FixedClock clock,
  ) async {
    // 現場登録フォームは推しグループ・推しメン選択セクションを含み縦に長い。
    // 既定のテストビューポートだと「登録する」等が画面外(offstage)になり
    // tap がヒットテストで失敗するため、十分縦長のビューポートにする
    // （genba_status_actions_test.dart 等と同じ対処）。
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        nowProvider.overrideWith((ref) => Stream.value(clock.now())),
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

  testWidgets('現場作成フォームから登録し、ホームに当日カードが出る', (tester) async {
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final db = await prepareSignedInDb();
    addTearDown(db.close);
    await pumpApp(tester, db, clock);

    // 空状態には説明と次の1アクションがある
    expect(find.text('予定している現場がありません'), findsOneWidget);

    // FAB（アイコンのみ・ツールチップで識別）から現場登録フォームへ
    await tester.tap(find.byTooltip('現場を登録'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '現場を登録'), findsOneWidget);

    // 必須項目のみ入力（段階的開示: 詳細は閉じたまま）
    await tester.enterText(
      find.widgetWithText(TextField, 'グループ／アーティスト名 *'),
      '推しグループ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '公演名 *'),
      '全国ツアー東京公演',
    );
    await tester.tap(find.text('日付 *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // DatePicker: 初期値 = clock.now() 当日
    await tester.pumpAndSettle();

    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    // 詳細画面へ遷移している（R7: AppBarタイトルに加えヒーロー領域にも
    // 公演名が表示されるため、タイトルの存在とタブ構成で判定する）
    expect(find.text('全国ツアー東京公演'), findsWidgets);
    expect(find.text('概要'), findsOneWidget);

    // ホームへ戻ると当日モードのカードが最上部に出る
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('ホーム'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('本日の現場'), findsOneWidget);
    expect(find.text('全国ツアー東京公演'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('過去の現場は思い出一覧に表示され、記録画面で感想を書ける', (tester) async {
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final db = await prepareSignedInDb();
    addTearDown(db.close);
    final container = await pumpApp(tester, db, clock);

    // 先月の現場を作成（データ層経由）→ 思い出として表示される
    final repo = container.read(genbaRepositoryProvider);
    final result = await repo.upsertGenba(
      makeGenba(
        id: 'past-1',
        ownerId: 'demo-user-1',
        title: '春の単独公演',
        eventDate: DateTime(2026, 6, 1),
      ),
    );
    expect(result.isOk, isTrue);
    await tester.pumpAndSettle();

    // ホームには出ない（未来の現場のみ）
    expect(find.text('春の単独公演'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('思い出'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('春の単独公演'), findsOneWidget);

    // 詳細 → 記録画面
    await tester.tap(find.text('春の単独公演'));
    await tester.pumpAndSettle();
    expect(find.text('まだ記録がありません'), findsOneWidget);

    await tester.tap(find.text('記録する'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(
        TextField,
        '感想（短いひとことでOK・あとから加筆できます）',
      ),
      '最高の現場だった',
    );
    // 自動保存のデバウンスを経過させる
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 戻ると詳細に感想が表示される（ja ロケールのため BackButton を直接タップ）
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('最高の現場だった'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('終演予定後は余韻中カードから感想入力へ誘導される', (tester) async {
    // 18:00開演 / 21:00終演の現場に対し、現在 21:30
    final clock = FixedClock(DateTime(2026, 7, 2, 21, 30));
    final db = await prepareSignedInDb();
    addTearDown(db.close);
    final container = await pumpApp(tester, db, clock);

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'today-1',
        ownerId: 'demo-user-1',
        title: '夜公演',
        eventDate: DateTime(2026, 7, 2),
        startTimeMinutes: 18 * 60,
        endTimeMinutes: 21 * 60,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('余韻中'), findsOneWidget);
    expect(find.text('短い感想を書く'), findsOneWidget);

    await tester.tap(find.text('短い感想を書く'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '思い出を記録'), findsOneWidget);
    await unmountApp(tester);
  });
}
