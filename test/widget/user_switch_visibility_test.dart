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

/// C-01 必須テスト: ログアウト中の不可視性とユーザー復帰。
///
/// 同一端末（同一SQLiteファイル）を複数の認証主体が使っても、
/// - ログアウト中は前ユーザーのデータが一切見えない
/// - 別ユーザーへ切り替えても前ユーザーのデータが見えない
/// - 同じユーザーへ戻れば（= 同じ owner_id でセッション復元されれば）
///   データは失われずに再表示される
/// ことを検証する。
void main() {
  Future<void> prepareDb(AppDatabase db, {required String ownerId}) async {
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': ownerId, 'email': '$ownerId@example.com'}),
    );
  }

  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    AppDatabase db,
    FixedClock clock,
  ) async {
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

  testWidgets('別ユーザーへ切り替えると前ユーザーの現場は一切見えない', (tester) async {
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final db = createTestDb();
    addTearDown(db.close);
    await prepareDb(db, ownerId: 'user-A');

    final containerA = await pumpApp(tester, db, clock);
    await containerA.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'genba-a',
            ownerId: 'user-A',
            title: 'Aだけの現場',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await goToGenbaTab(tester);
    expect(find.text('Aだけの現場'), findsOneWidget);
    await unmountApp(tester);

    // 同一DBのまま、別ownerとしてアプリを起動し直す（ユーザー切替相当）。
    await prepareDb(db, ownerId: 'user-B');
    final containerB = await pumpApp(tester, db, clock);
    await goToGenbaTab(tester);
    // Aの現場はどこにも表示されない。
    expect(find.text('Aだけの現場'), findsNothing);
    expect(find.text('これからの現場がありません'), findsOneWidget);
    // Bのリポジトリ経由でも直接確認する。
    final bAll =
        await containerB.read(genbaRepositoryProvider).watchAll().first;
    expect(bAll, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('ログアウト中はユーザー固有ストリームが空になる', (tester) async {
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final db = createTestDb();
    addTearDown(db.close);
    await prepareDb(db, ownerId: 'user-A');

    final container = await pumpApp(tester, db, clock);
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'genba-a',
            ownerId: 'user-A',
            title: 'Aだけの現場',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();

    // 設定タブからログアウトする。
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

    // ログイン画面へ戻り、Repository は空を返す（前ユーザーの値を保持しない）。
    expect(find.widgetWithText(AppBar, 'ログイン'), findsOneWidget);
    final afterLogout =
        await container.read(genbaRepositoryProvider).watchAll().first;
    expect(afterLogout, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('同じownerでセッション復元されればデータは失われず再表示される', (tester) async {
    final clock = FixedClock(DateTime(2026, 7, 2, 12));
    final db = createTestDb();
    addTearDown(db.close);
    await prepareDb(db, ownerId: 'user-A');

    final containerFirst = await pumpApp(tester, db, clock);
    await containerFirst.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: 'genba-a',
            ownerId: 'user-A',
            title: 'Aの現場（再起動後も残る）',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();
    await unmountApp(tester);

    // アプリ再起動（同一DB・同一owner でセッションが復元された想定）。
    await prepareDb(db, ownerId: 'user-A');
    final containerSecond = await pumpApp(tester, db, clock);
    await goToGenbaTab(tester);
    expect(find.text('Aの現場（再起動後も残る）'), findsOneWidget);
    final restored =
        await containerSecond.read(genbaRepositoryProvider).watchAll().first;
    expect(restored.map((a) => a.genba.id), ['genba-a']);
    await unmountApp(tester);
  });
}
