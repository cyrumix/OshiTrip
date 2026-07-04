import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';
import 'package:oshi_trip/features/oshi/presentation/oshi_screens.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// マイ推し（design-spec §10）: 導出統計3件・次の現場・誕生日/記念日。
/// 統計は保存済みデータからの導出で、登録数を参戦数と表示しない（§12.1）。
void main() {
  const ownerId = 'demo-user-1';
  const groupId = 'og-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<void> seed(WidgetTester tester, ProviderContainer container) async {
    final oshiRepo = container.read(oshiRepositoryProvider);
    await oshiRepo.upsertGroup(
      OshiGroup(
        id: groupId,
        ownerId: ownerId,
        name: '推しグループ',
        kind: 'アイドル',
        color: '#FF5CA8',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await oshiRepo.upsertMember(
      OshiMember(
        id: 'om-1',
        groupId: groupId,
        ownerId: ownerId,
        name: '推しメン',
        rank: OshiRank.saioshi,
        birthday: DateTime(2000, 8, 15),
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    final genbaRepo = container.read(genbaRepositoryProvider);
    // 現場3件: 未来1・過去(参戦済み)1・過去(参加状態は予定のまま)1。
    await genbaRepo.upsertGenba(
      makeGenba(
        id: 'g-future',
        ownerId: ownerId,
        title: '次のワンマン',
        eventDate: DateTime(2026, 7, 20),
        oshiGroupId: groupId,
      ),
    );
    await genbaRepo.upsertGenba(
      makeGenba(
        id: 'g-past-attended',
        ownerId: ownerId,
        title: '参戦済み公演',
        eventDate: DateTime(2026, 6, 1),
        oshiGroupId: groupId,
        attendanceStatus: AttendanceStatus.attended,
      ),
    );
    await genbaRepo.upsertGenba(
      makeGenba(
        id: 'g-past-planned',
        ownerId: ownerId,
        title: '行けなかった公演',
        eventDate: DateTime(2026, 6, 15),
        oshiGroupId: groupId,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('統計3件が導出値で表示される（参戦数=attendedのみ）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const OshiListScreen(),
    );
    await seed(tester, container);

    // グループプロフィール（イニシャルフォールバック + 最推し表示）。
    expect(find.text('推しグループ'), findsOneWidget);
    expect(find.text('最推し: 推しメン'), findsOneWidget);

    // 統計: 現場数3 / 思い出数2 / 参戦数1（過去でも自動計上しない）。
    expect(find.bySemanticsLabel('現場数 3件'), findsOneWidget);
    expect(find.bySemanticsLabel('思い出数 2件'), findsOneWidget);
    expect(
      find.bySemanticsLabel('参戦数 1件（参加を明示した現場のみ）'),
      findsOneWidget,
    );

    // 次の現場（残日数を強調, §10）。
    expect(find.text('次の現場'), findsOneWidget);
    expect(find.text('次のワンマン'), findsOneWidget);
    expect(find.text('あと18日'), findsOneWidget);

    // 誕生日（導出記念日）。
    expect(find.text('推しメンの誕生日'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('ユーザー定義記念日を追加でき、近い順の一覧に出る（§10/§12.1）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const OshiListScreen(),
    );
    await seed(tester, container);

    // データ層経由で記念日を登録（UIのダイアログ経由はDatePicker依存のため
    // repo で登録し、一覧への反映=実データ接続を検証する）。
    final oshiRepo = container.read(oshiRepositoryProvider);
    await oshiRepo.upsertAnniversary(
      OshiAnniversary(
        id: 'a-1',
        ownerId: ownerId,
        groupId: groupId,
        label: 'メジャーデビュー日',
        date: DateTime(2020, 7, 10),
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('メジャーデビュー日'), findsOneWidget);
    // 7/10 は 8/15 の誕生日より近い → 先に表示される（近い順）。
    final debutOffset = tester.getTopLeft(find.text('メジャーデビュー日'));
    final birthdayOffset = tester.getTopLeft(find.text('推しメンの誕生日'));
    expect(debutOffset.dy, lessThan(birthdayOffset.dy));
    await unmountApp(tester);
  });
}
