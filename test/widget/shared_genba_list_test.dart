import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/presentation/genba_list_screen.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';
import 'package:oshi_trip/features/sharing/domain/shared_genba_summary.dart';
import 'package:oshi_trip/features/social/application/member_providers.dart';

import '../helpers/pump_screen.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 7, 11, 12));

  Future<void> pump(
    WidgetTester tester, {
    List<GenbaAggregate> owned = const [],
    List<SharedGenbaSummary> shared = const [],
  }) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaListScreen(),
      extraOverrides: [
        upcomingGenbasProvider.overrideWithValue(AsyncData(owned)),
        sharedGenbaSummariesProvider.overrideWith((ref) async => shared),
      ],
    );
  }

  testWidgets('共有された現場が一覧に「共有」バッジ・権限つきで表示される', (tester) async {
    await pump(
      tester,
      shared: [
        SharedGenbaSummary(
          genbaId: 'g1',
          title: '共有ドーム',
          artistName: 'ARASHI',
          eventDate: DateTime.utc(2026, 8, 1),
          role: ShareRole.editor,
        ),
        const SharedGenbaSummary(
          genbaId: 'g2',
          title: '閲覧ライブ',
          role: ShareRole.viewer,
        ),
      ],
    );

    expect(
      find.textContaining('共有された現場', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('共有ドーム'), findsOneWidget);
    expect(find.text('閲覧ライブ'), findsOneWidget);
    expect(find.text('共有'), findsWidgets);
    expect(find.text('編集可'), findsOneWidget);
    expect(find.text('閲覧のみ'), findsOneWidget);
  });

  testWidgets('owned が空でも共有現場があれば空状態にしない', (tester) async {
    await pump(
      tester,
      shared: const [
        SharedGenbaSummary(
          genbaId: 'g1',
          title: '共有現場',
          role: ShareRole.viewer,
        ),
      ],
    );
    expect(find.text('これからの現場がありません'), findsNothing);
    expect(find.text('共有現場'), findsOneWidget);
  });

  testWidgets('共有現場も owned も無ければ空状態を表示する', (tester) async {
    await pump(tester);
    expect(find.text('これからの現場がありません'), findsOneWidget);
    expect(find.text('共有された現場'), findsNothing);
  });
}
