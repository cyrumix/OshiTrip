import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/presentation/memory_edit_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';

/// 思い出記録画面の段階名（§8.2）: 「翌日」→「終演後」へ変更され、
/// 「終演後」に MC・当日メモ / 座席・見え方 / セトリ が置かれる。
/// これは表示段階名の変更であり、思い出移行の日時判定ではない。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'mem-stage-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  testWidgets('記録画面の段階名が 終演直後 / 終演後 / 後日 になっている（翌日は無い）', (tester) async {
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
      child: const MemoryEditScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '段階テスト公演',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    await tester.pumpAndSettle();

    // 段階名: 終演直後 / 終演後 / 後日。旧「翌日」は存在しない。
    expect(find.text('終演直後'), findsOneWidget);
    expect(find.text('終演後'), findsOneWidget);
    expect(find.text('後日'), findsOneWidget);
    expect(find.text('翌日'), findsNothing);

    // 「終演後」に MC・当日メモ / 座席・見え方 / セトリ が置かれている。
    expect(find.widgetWithText(TextField, 'MC・当日メモ'), findsOneWidget);
    expect(find.widgetWithText(TextField, '座席・見え方'), findsOneWidget);
    expect(find.text('セトリ'), findsOneWidget);
  });

  testWidgets('行った場所と食べたものが別セクションに分かれ、種別ごとに表示される（§8.4）', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryEditScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '場所と食べもの分岐',
            eventDate: DateTime(2026, 8, 1),
          ),
        );
    final repo = container.read(memoryRepositoryProvider);
    await repo.upsertVisitedPlace(
      VisitedPlace(
        id: 'pl-spot',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '東京タワー',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await repo.upsertVisitedPlace(
      VisitedPlace(
        id: 'pl-food',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '老舗ラーメン',
        category: 'food',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await tester.pumpAndSettle();

    // 2つの独立セクション見出しが出る（旧「行った場所・食べたもの」統合欄は無い）。
    expect(find.text('行った場所'), findsOneWidget);
    expect(find.text('食べたもの'), findsOneWidget);
    expect(find.text('行った場所・食べたもの'), findsNothing);

    // それぞれの種別の項目が表示される。
    expect(find.text('東京タワー'), findsOneWidget);
    expect(find.text('老舗ラーメン'), findsOneWidget);
  });
}
