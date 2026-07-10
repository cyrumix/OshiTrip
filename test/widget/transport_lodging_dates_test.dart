import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 交通・宿泊の新規登録（§7.4/§7.5）: 交通の出発・到着時刻はユーザーが選ぶまで
/// 未設定のまま（日付/時刻ピッカーの初期日付だけ開催日にする）。宿泊のチェックイン・
/// チェックアウト日は開催日を初期値として実データに入れる。往路を新規保存すると
/// 復路登録の確認ダイアログを出し、承諾時は手段を引き継ぎ出発地/到着地を逆にした
/// 復路（時刻未設定）を追加する。既存交通の編集時にはこの確認を出さない。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'td-gb-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));
  final eventDate = DateTime(2026, 9, 10);

  Future<void> openTab(WidgetTester tester, String label) async {
    final tab =
        find.descendant(of: find.byType(TabBar), matching: find.text(label));
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  Future<void> tapAdd(WidgetTester tester) async {
    final button = find.widgetWithText(TextButton, '追加');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
      '交通を新規追加: 時刻を選ばなければ出発・到着は未設定のまま保存され、'
      '往路保存後に復路確認が出る', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
          makeGenba(id: genbaId, ownerId: ownerId, eventDate: eventDate),
        );
    await tester.pumpAndSettle();
    await openTab(tester, '交通');

    await tapAdd(tester);

    // 新規追加直後は出発時刻・到着時刻とも未設定（実データに開催日0:00を
    // 入れない。ピッカーの初期日付だけ開催日にする）。
    expect(find.text('未設定'), findsNWidgets(2));

    // 交通手段を選び、出発地・到着地を入力する。時刻は選ばない。
    await tester.tap(find.text('新幹線'));
    await tester.pumpAndSettle();
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '東京');
    await tester.enterText(textFields.at(1), '大阪');

    // 保存中はスピナー表示のまま復路確認ダイアログを await するため、
    // pumpAndSettle は使わず明示的に pump してダイアログの出現を待つ。
    await tester.tap(find.text('保存する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 往路の新規保存後、復路確認ダイアログが出る。
    expect(find.text('復路も登録しますか？'), findsOneWidget);
    await tester.tap(find.text('登録する'));
    await tester.pumpAndSettle();

    final aggregate =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(aggregate!.transports, hasLength(2));
    final outbound = aggregate.transports
        .singleWhere((t) => t.direction == TransportDirection.outbound);
    final inbound = aggregate.transports
        .singleWhere((t) => t.direction == TransportDirection.inbound);
    expect(outbound.fromPlace, '東京');
    expect(outbound.toPlace, '大阪');
    // 時刻を選ばずに保存したので往路も departAt/arriveAt は null のまま。
    expect(outbound.departAt, isNull);
    expect(outbound.arriveAt, isNull);
    expect(inbound.method, TransportMethod.shinkansen);
    expect(inbound.fromPlace, '大阪');
    expect(inbound.toPlace, '東京');
    expect(inbound.departAt, isNull);
    expect(inbound.arriveAt, isNull);

    await unmountApp(tester);
  });

  testWidgets('往路を新規追加時に復路登録を断ると復路は作られない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
          makeGenba(id: genbaId, ownerId: ownerId, eventDate: eventDate),
        );
    await tester.pumpAndSettle();
    await openTab(tester, '交通');

    await tapAdd(tester);
    await tester.tap(find.text('新幹線'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('復路も登録しますか？'), findsOneWidget);
    await tester.tap(find.text('登録しない'));
    await tester.pumpAndSettle();

    final aggregate =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(aggregate!.transports, hasLength(1));
    expect(aggregate.transports.single.direction, TransportDirection.outbound);

    await unmountApp(tester);
  });

  testWidgets('既存交通の編集時は復路確認を出さない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
    final repo = container.read(genbaRepositoryProvider);
    await repo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: eventDate),
    );
    await repo.upsertTransport(
      makeTransportRef(
        id: 'tr-existing',
        genbaId: genbaId,
        ownerId: ownerId,
        method: TransportMethod.shinkansen,
        fromPlace: '東京',
        toPlace: '大阪',
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, '交通');

    final existingTile = find.text('往路 新幹線');
    await tester.ensureVisible(existingTile);
    await tester.pumpAndSettle();
    await tester.tap(existingTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('復路も登録しますか？'), findsNothing);
    final aggregate =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(aggregate!.transports, hasLength(1));

    await unmountApp(tester);
  });

  testWidgets('宿泊を新規追加: チェックイン・チェックアウトの初期日付は開催日', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
          makeGenba(id: genbaId, ownerId: ownerId, eventDate: eventDate),
        );
    await tester.pumpAndSettle();
    await openTab(tester, '宿泊');

    await tapAdd(tester);

    expect(find.text('2026-09-10'), findsNWidgets(2));

    await unmountApp(tester);
  });
}
