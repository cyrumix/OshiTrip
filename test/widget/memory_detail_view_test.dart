import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/design_system/design_system.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/memory/domain/memory.dart';
import 'package:oshi_trip/features/memory/presentation/memory_detail_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';
import '../helpers/test_db.dart';

/// 思い出詳細（design-spec §9）: カルーセル 1/N・お気に入り・閲覧タブ・
/// 写真なし縮退。
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'md-1';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  MemoryPhoto makePhoto(String id, {int sortOrder = 0}) => MemoryPhoto(
        id: id,
        genbaId: genbaId,
        ownerId: ownerId,
        sortOrder: sortOrder,
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      );

  testWidgets('写真カルーセルに 1/N が出て、感想・セトリが縦1本で並ぶ（タブ廃止, §9）', (tester) async {
    // カルーセル(4:3)の下の感想カードまで1画面に収める縦長ビューポート
    // （他の画面テストと同じ実機相当サイズ。遅延ビルドの sliver が
    // ビューポート外で未構築になり誤って0件になるのを避ける）。
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
      child: const MemoryDetailScreen(genbaId: genbaId),
    );

    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '思い出の公演',
            eventDate: DateTime(2026, 6, 1),
            venue: 'Zepp',
          ),
        );
    final memoryRepo = container.read(memoryRepositoryProvider);
    await memoryRepo.addPhoto(makePhoto('p-1'));
    await memoryRepo.addPhoto(makePhoto('p-2', sortOrder: 1));
    await memoryRepo.upsertEntry(
      MemoryEntry(
        id: 'e-1',
        genbaId: genbaId,
        ownerId: ownerId,
        impression: '声出しできて最高だった',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await memoryRepo.upsertSetlistItem(
      SetlistItem(
        id: 's-1',
        genbaId: genbaId,
        ownerId: ownerId,
        position: 1,
        songTitle: 'オープニング曲',
        createdAt: fixedCreatedAt,
        updatedAt: fixedCreatedAt,
      ),
    );
    await tester.pumpAndSettle();

    // カルーセルの現在位置 1/N（§9）。
    expect(find.text('1/2'), findsOneWidget);
    // アップロード未完了は「端末に保存済み」を出し、成功と誤認させない（§12.1）。
    expect(find.text('端末に保存済み'), findsOneWidget);

    // タブ廃止（§9）: 感想もセトリも縦に積んで一度に見返せる（切替不要）。
    expect(find.byType(SegmentTabs), findsNothing);
    expect(find.text('感想'), findsOneWidget);
    expect(find.text('セトリ'), findsOneWidget);
    expect(find.text('声出しできて最高だった'), findsOneWidget);
    expect(find.text('オープニング曲'), findsOneWidget);

    // 編集入口（FAB, 閲覧と分離, §9）。
    expect(find.text('記録する'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('お気に入り操作が実データへ反映される（§9/§12.1）', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '思い出の公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    // 写真なしでも感想を主役に成立する（§9）。
    await container.read(memoryRepositoryProvider).upsertEntry(
          MemoryEntry(
            id: 'e-1',
            genbaId: genbaId,
            ownerId: ownerId,
            impression: '写真はないけど最高',
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('写真はないけど最高'), findsOneWidget);
    // 縦1本のストーリー（タブは無い, §9）。
    expect(find.byType(SegmentTabs), findsNothing);

    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();
    final bundle = await container
        .read(memoryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(bundle.entry?.isFavorite, isTrue);
    await unmountApp(tester);
  });

  testWidgets('記録ゼロは「まだ記録がありません」へ縮退する', (tester) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    final container = await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '記録なしの公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('まだ記録がありません'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('写真だけの思い出は「まだ記録がありません」にならない（レビュー是正/§9）', (tester) async {
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
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '写真だけの公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    // 写真だけを登録（感想・セトリ等は無し）。
    await container
        .read(memoryRepositoryProvider)
        .addPhoto(makePhoto('p-only'));
    await tester.pumpAndSettle();

    // 写真が主役として表示され（1/N）、空状態は出ない。
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('まだ記録がありません'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('現場に登録済みの交通・宿泊・座席が思い出へ自動で引き継がれる（§9 本質）', (tester) async {
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
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    final genbaRepo = container.read(genbaRepositoryProvider);
    await genbaRepo.upsertGenba(
      makeGenba(
        id: genbaId,
        ownerId: ownerId,
        title: '遠征した公演',
        eventDate: DateTime(2026, 6, 1),
        venue: '大阪城ホール',
      ),
    );
    // 現場側に登録済みのチケット座席・交通・宿泊（思い出では再入力しない）。
    await genbaRepo.upsertTicket(
      makeTicket(
        id: 't-seat',
        genbaId: genbaId,
        ownerId: ownerId,
        seat: '1階A-12',
      ),
    );
    await genbaRepo.upsertTransport(
      makeTransportRef(
        id: 'tr-1',
        genbaId: genbaId,
        ownerId: ownerId,
        method: TransportMethod.shinkansen,
        fromPlace: '東京',
        toPlace: '新大阪',
      ),
    );
    await genbaRepo.upsertLodging(
      makeLodgingRef(
        id: 'lg-1',
        genbaId: genbaId,
        ownerId: ownerId,
        name: '大阪のホテル',
      ),
    );
    await tester.pumpAndSettle();

    // 遠征の記録セクション＋「現場から自動」バッジ。
    expect(find.text('遠征の記録'), findsOneWidget);
    expect(find.text('現場から自動'), findsOneWidget);
    // 交通・宿泊が読み取り専用で再掲される。
    expect(find.textContaining('新大阪'), findsOneWidget);
    expect(find.textContaining('大阪のホテル'), findsOneWidget);
    // その日の記録に、チケットの座席が自動で引き継がれる。
    expect(find.text('その日の記録'), findsOneWidget);
    expect(find.textContaining('1階A-12'), findsOneWidget);

    // 空セクション（感想・セトリ）は出さない（§9）。
    expect(find.text('感想'), findsNothing);
    expect(find.text('セトリ'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('感想セクションの「編集」でそのセクションだけのシートが開き自動保存される（§9/M3）', (tester) async {
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
      child: const MemoryDetailScreen(genbaId: genbaId),
    );
    await container.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
            id: genbaId,
            ownerId: ownerId,
            title: '編集シート公演',
            eventDate: DateTime(2026, 6, 1),
          ),
        );
    await container.read(memoryRepositoryProvider).upsertEntry(
          MemoryEntry(
            id: 'e-1',
            genbaId: genbaId,
            ownerId: ownerId,
            impression: '初稿の感想',
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          ),
        );
    await tester.pumpAndSettle();

    // 感想セクションの「編集」→ 感想だけのボトムシート（巨大フォームではない）。
    await tester.tap(find.text('編集').first);
    await tester.pumpAndSettle();
    final field = find.widgetWithText(
      TextField,
      '感想（短いひとことでOK・あとから加筆できます）',
    );
    expect(field, findsOneWidget);
    // セトリ等 他セクションの入力欄はシートに無い（そのセクションだけ）。
    expect(find.widgetWithText(TextField, '座席・見え方'), findsNothing);

    await tester.enterText(field, '加筆した感想');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final bundle = await container
        .read(memoryRepositoryProvider)
        .watchByGenbaId(genbaId)
        .first;
    expect(bundle.entry?.impression, '加筆した感想');
    await unmountApp(tester);
  });
}
