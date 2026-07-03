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

/// H-07 回帰: 未来の中止現場が一覧から消えないこと、「終演した」の確認と
/// 取消が実際のUI操作で機能することを確認する。
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
    // 現場詳細は縦に長い（ヒーロー画像+状態操作+チケット等）。既定のテスト
    // ビューポートだと状態チップ等が画面外(offstage)になり find.text で
    // 見つからないため、十分縦長のビューポートにしてスクロール不要にする。
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

  Future<void> goToGenbaTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('現場'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未来の中止現場は現場一覧から消えず「中止」と分かる状態で残り、取消できる（H-07）', (tester) async {
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final db = await prepareSignedInDb();
    addTearDown(db.close);
    final container = await pumpApp(tester, db, clock);

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'future-1',
        ownerId: 'demo-user-1',
        title: '未来の単独公演',
        eventDate: DateTime(2026, 8, 1), // 現在(7/2)より未来
      ),
    );
    await tester.pumpAndSettle();

    await goToGenbaTab(tester);
    expect(find.text('未来の単独公演'), findsOneWidget);

    // 詳細を開いて中止にする。
    await tester.tap(find.text('未来の単独公演'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('その他の操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中止にする'));
    await tester.pumpAndSettle();
    // 確認ダイアログ。
    expect(find.text('現場を中止にする'), findsOneWidget);
    await tester.tap(find.text('中止にする').last);
    await tester.pumpAndSettle();

    // 詳細画面に「中止」ステータスが出る。
    expect(find.text('中止'), findsWidgets);

    // 現場一覧へ戻っても消えていない（H-07 の核心）。
    await goToGenbaTab(tester);
    expect(find.text('未来の単独公演'), findsOneWidget);
    expect(find.text('中止'), findsWidgets);

    // 再度開いて中止を取り消せる。
    await tester.tap(find.text('未来の単独公演'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('その他の操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中止を取り消す'));
    await tester.pumpAndSettle();

    expect(find.text('中止'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('「終演した」は確認ダイアログを経て反映され、取り消すと元に戻る', (tester) async {
    // 18:00開演 / 21:00終演の現場に対し、現在は公演当日18:30（まだ終演前）。
    final clock = FixedClock(DateTime(2026, 7, 2, 18, 30));
    final db = await prepareSignedInDb();
    addTearDown(db.close);
    final container = await pumpApp(tester, db, clock);

    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(
        id: 'today-1',
        ownerId: 'demo-user-1',
        title: '当日公演',
        eventDate: DateTime(2026, 7, 2),
        startTimeMinutes: 18 * 60,
        endTimeMinutes: 21 * 60,
      ),
    );
    await tester.pumpAndSettle();

    await goToGenbaTab(tester);
    await tester.tap(find.text('当日公演'));
    await tester.pumpAndSettle();

    expect(find.text('終演した（余韻中にする）'), findsOneWidget);
    await tester.tap(find.text('終演した（余韻中にする）'));
    await tester.pumpAndSettle();

    // 確認ダイアログが出て、まだ反映されていない。
    expect(find.text('終演した'), findsWidgets);
    await tester.tap(find.text('終演した').last);
    await tester.pumpAndSettle();

    // 余韻中に切り替わり、手動終演の表示と取消ボタンが出る。
    expect(find.text('余韻中'), findsOneWidget);
    expect(find.textContaining('手動で終演済みにしています'), findsOneWidget);
    expect(find.text('取り消す'), findsOneWidget);

    // 取消 → 確認 → 元の「本日」に戻る。
    await tester.tap(find.text('取り消す'));
    await tester.pumpAndSettle();
    expect(find.text('終演の取消'), findsOneWidget);
    await tester.tap(find.text('取り消す').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('手動で終演済みにしています'), findsNothing);
    expect(find.text('終演した（余韻中にする）'), findsOneWidget);
    await unmountApp(tester);
  });
}
