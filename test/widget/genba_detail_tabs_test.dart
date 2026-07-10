import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_detail_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 現場詳細（design-spec §7）: ヒーロー・横スクロールタブ・参加状態の
/// 明示操作（§12.1: 日時から自動導出しない）。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'gd-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<void> seed(dynamic container, {DateTime? eventDate}) async {
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: 'タブ検証公演',
            eventDate: eventDate ?? DateTime(2026, 6, 1),
            venue: '幕張メッセ',
            startTimeMinutes: 18 * 60,
          ),
        );
  }

  testWidgets('ヒーローに公演情報が重なり、7タブを横断できる（§7.1/§7.2）', (tester) async {
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
    await seed(container);
    await tester.pumpAndSettle();

    // ヒーロー領域: 公演名・会場・開演が重なる（写真なし=紫フォールバック）。
    expect(find.text('タブ検証公演'), findsWidgets);
    expect(find.textContaining('開演 18:00'), findsWidgets);

    // 7タブ（計画タブを含む）。
    for (final label in [
      '概要',
      'Todo・持ち物',
      'チケット',
      '交通',
      '宿泊',
      '計画',
      'メモ',
    ]) {
      expect(
        find.descendant(of: find.byType(TabBar), matching: find.text(label)),
        findsOneWidget,
      );
    }

    // チケットタブへ移動 → 追加ボタンと空状態文言。
    final ticketTab =
        find.descendant(of: find.byType(TabBar), matching: find.text('チケット'));
    await tester.ensureVisible(ticketTab);
    await tester.tap(ticketTab);
    await tester.pumpAndSettle();
    expect(find.textContaining('未登録。取得状況を記録'), findsOneWidget);

    // メモタブ → 区分ごとの行（7タブでスクロール域に入るため可視化してからタップ）。
    final memoTab =
        find.descendant(of: find.byType(TabBar), matching: find.text('メモ'));
    await tester.ensureVisible(memoTab);
    await tester.pumpAndSettle();
    await tester.tap(memoTab);
    await tester.pumpAndSettle();
    // メモ未登録の空状態（複数化UI, §7.7）。
    expect(find.textContaining('メモはまだありません'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('参加状態を「参戦済み」へ明示でき、実データへ保存される（§12.1）', (tester) async {
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
    await seed(container);
    await tester.pumpAndSettle();

    // 過去の現場でも自動で参戦済みにならない（初期値: 予定）。
    expect(find.text('参加状態'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '参戦済み'));
    await tester.pumpAndSettle();

    final aggregate =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(aggregate!.genba.attendanceStatus, AttendanceStatus.attended);
    await unmountApp(tester);
  });

  testWidgets('キーボード表示中でも Todo エディタの保存・キャンセルが利用できる（§14）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaDetailScreen(genbaId: genbaId),
    );
    await seed(container);
    await tester.pumpAndSettle();

    // Todo・持ち物タブ → 「Todoを追加」でエディタ（Bottom Sheet）を開く。
    await tester.tap(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Todo・持ち物'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todoを追加'));
    await tester.pumpAndSettle();

    // キーボード相当の viewInsets（論理 400px）を与える。
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    await tester.pumpAndSettle();

    // 主要操作（保存）がキーボードに隠れず可視・タップ可能（48dp 以上）。
    final save = find.text('保存する');
    expect(save.hitTestable(), findsOneWidget);
    final saveButton = find.ancestor(
      of: save,
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(
      tester.getSize(saveButton).height,
      greaterThanOrEqualTo(48),
    );

    // 実際に入力して保存でき、実データへ反映される。
    await tester.enterText(find.byType(TextField).first, 'ペンライトの電池');
    await tester.tap(save);
    await tester.pumpAndSettle();
    final aggregate =
        await container.read(genbaRepositoryProvider).watchById(genbaId).first;
    expect(aggregate!.todos.map((t) => t.name), contains('ペンライトの電池'));
    await unmountApp(tester);
  });
}
