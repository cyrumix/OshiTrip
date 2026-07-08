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
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';

/// Phase 2 統合テスト: 現場（seed）→計画タブ→手動スポット追加→登録済み交通・
/// 宿泊の参照追加→移動区間(leg)追加→**アプリの実再起動**で復元、をGoogle API
/// 無しで通す。
///
/// 「実再起動」を本物にするため、DB は**ファイル実体**を使い、1回目の
/// [AppDatabase]・[ProviderContainer] を完全に dispose/close してから、
/// **同じファイル**を新しい [AppDatabase] で開き直して復元を検証する
/// （Phase 2レビュー点7）。in-memory の再pumpでは「別プロセス起動」を
/// 模倣できないため採用しない。
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
  const genbaId = 'itin-flow-genba';

  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }

  Future<void> seedSignedIn(AppDatabase db) async {
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': ownerId, 'email': 'demo@example.com'}),
    );
  }

  testWidgets(
    '現場→計画→手動スポット→交通宿泊参照→移動区間→実再起動で復元（Google API無し）',
    (tester) async {
      // DBはファイル実体（再起動＝同一ファイルを新DBで開き直し）。
      final dbFile = File(
        p.join(
          Directory.systemTemp.createTempSync('itin_flow').path,
          'oshi_trip_itin_flow.sqlite',
        ),
      );
      if (dbFile.existsSync()) dbFile.deleteSync();
      addTearDown(() {
        if (dbFile.existsSync()) dbFile.deleteSync();
      });

      AppDatabase openDb() => AppDatabase(NativeDatabase(dbFile));

      Future<ProviderContainer> pumpApp(AppDatabase db) async {
        final container = ProviderContainer(
          overrides: [
            envProvider.overrideWithValue(env),
            databaseProvider.overrideWithValue(db),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const OshiExpeditionApp(),
          ),
        );
        await tester.pumpAndSettle();
        return container;
      }

      Future<void> openPlanTab() async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('現場'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('旅程フロー公演').first);
        await tester.pumpAndSettle();
        final planTab = find.descendant(
          of: find.byType(TabBar),
          matching: find.text('計画'),
        );
        await tester.ensureVisible(planTab);
        await tester.pumpAndSettle();
        await tester.tap(planTab);
        await tester.pumpAndSettle();
      }

      // ---- セッション1: 作成 ----
      final db1 = openDb();
      await seedSignedIn(db1);
      var container = await pumpApp(db1);

      // 現場・交通・宿泊を用意（現場作成UIは app_flow_test で検証済みのため、
      // ここでは前提データを repository で用意し、計画タブの手動導線をUIで通す）。
      final genbaRepo = container.read(genbaRepositoryProvider);
      final now = DateTime.now().toUtc();
      await genbaRepo.upsertGenba(
        Genba(
          id: genbaId,
          ownerId: ownerId,
          artistName: 'アーティスト',
          title: '旅程フロー公演',
          eventDate: DateTime(2026, 8, 1),
          venue: '大阪城ホール',
          startTimeMinutes: 18 * 60,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await genbaRepo.upsertTransport(
        Transport(
          id: 'itin-tr-1',
          genbaId: genbaId,
          ownerId: ownerId,
          method: TransportMethod.shinkansen,
          fromPlace: '東京',
          toPlace: '大阪',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await genbaRepo.upsertLodging(
        Lodging(
          id: 'itin-lo-1',
          genbaId: genbaId,
          ownerId: ownerId,
          name: '大阪ホテル',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpAndSettle();

      await openPlanTab();

      Future<void> addMenu(String label) async {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      // 手動スポットを追加（UIから）。
      await addMenu('スポットを追加（自分で入力）');
      await tester.enterText(find.byType(TextField).first, '海遊館');
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();
      expect(find.text('海遊館'), findsOneWidget);

      // 登録済みの交通・宿泊を参照追加（UIから）。
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await addMenu('登録済みの交通を追加');
      await tester.tap(find.widgetWithText(TextButton, '追加'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await addMenu('登録済みの宿泊を追加');
      await tester.tap(find.widgetWithText(TextButton, '追加'));
      await tester.pumpAndSettle();

      // 移動区間(leg)を追加（UIから。出発=海遊館、到着=交通項目）。
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await addMenu('移動区間を追加');
      await tester.tap(find.byKey(const Key('leg_origin')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('海遊館').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('leg_destination')));
      await tester.pumpAndSettle();
      // 交通項目のラベル（spot以外は kind 名）。重複回避で最後の候補を選ぶ。
      await tester.tap(find.text('transport').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();

      // DBに反映（複製せず参照。leg も1件）。
      final plans1 = await container
          .read(itineraryRepositoryProvider)
          .watchByGenbaId(genbaId)
          .first;
      expect(plans1.single.spots.single.name, '海遊館');
      final kinds1 = plans1.single.entries.map((e) => e.kind).toSet();
      expect(kinds1.contains(ItineraryEntryKind.transport), isTrue);
      expect(kinds1.contains(ItineraryEntryKind.lodging), isTrue);
      expect(plans1.single.legs.length, 1);

      // ---- セッション1を完全終了（container/DBを閉じる）----
      container.dispose();
      await db1.close();

      // ---- セッション2: 同一ファイルを新DBで開き直し → 復元 ----
      final db2 = openDb();
      addTearDown(db2.close);
      container = await pumpApp(db2);
      addTearDown(container.dispose);

      // 復元をDBで検証（スポット・交通・宿泊・移動区間）。
      final plans2 = await container
          .read(itineraryRepositoryProvider)
          .watchByGenbaId(genbaId)
          .first;
      expect(plans2.single.spots.single.name, '海遊館');
      final kinds2 = plans2.single.entries.map((e) => e.kind).toSet();
      expect(kinds2.contains(ItineraryEntryKind.transport), isTrue);
      expect(kinds2.contains(ItineraryEntryKind.lodging), isTrue);
      expect(plans2.single.legs.length, 1);

      // 画面にも復元表示される。
      await openPlanTab();
      expect(find.text('海遊館'), findsOneWidget);
      expect(find.text('会場 大阪城ホール'), findsOneWidget);
    },
  );
}
