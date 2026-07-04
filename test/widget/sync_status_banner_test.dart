import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/widgets/sync_status_banner.dart';

import '../helpers/fixtures.dart';

/// 同期状態バナー（R7 / design-spec §4・§13）:
/// オフライン・競合・失敗・同期待ち・デモを区別し、「同期済み」と
/// 誤認させない。値はすべて Outbox/Connectivity 由来（固定ダミー禁止）。
///
/// バナーは AppShell（主要6領域すべての上部）に置かれる共通部品であり、
/// ここでの検証が全画面の通信状態表示を担保する（シェルへの実装込みの
/// 検証は app_shell_navigation_test.dart 側）。
void main() {
  /// Supabase 設定済み（= 非デモ）の環境。バナーの分岐にのみ使い、
  /// 実接続は行わない（outbox/isOnline は override 注入）。
  const connectedEnv = AppEnv(
    flavor: Flavor.production,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'test-anon-key',
    logLevelName: 'error',
  );

  Future<void> pumpBanner(
    WidgetTester tester, {
    required AppEnv env,
    Map<OutboxStatus, int> counts = const {},
    bool online = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(env),
          outboxStatusProvider.overrideWith((ref) => Stream.value(counts)),
          isOnlineProvider.overrideWith((ref) => Stream.value(online)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [SyncStatusBanner()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('オフライン: 未同期件数と「端末のデータは利用できます」を表示する', (tester) async {
    await pumpBanner(
      tester,
      env: connectedEnv,
      online: false,
      counts: const {
        OutboxStatus.pending: 2,
        OutboxStatus.failed: 1,
      },
    );
    expect(
      find.text('オフライン・未同期3件（端末のデータは利用できます）'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('オフライン'), findsOneWidget);
  });

  testWidgets('オフラインで未同期0件でもオフラインを明示する', (tester) async {
    await pumpBanner(tester, env: connectedEnv, online: false);
    expect(find.text('オフライン（端末のデータは利用できます）'), findsOneWidget);
  });

  testWidgets('競合は失敗と区別して表示する', (tester) async {
    await pumpBanner(
      tester,
      env: connectedEnv,
      counts: const {OutboxStatus.conflict: 1},
    );
    expect(find.text('他の端末の変更と競合した項目が1件あります'), findsOneWidget);
    expect(find.bySemanticsLabel('同期の競合'), findsOneWidget);
  });

  testWidgets('同期失敗は再試行導線つきで表示する', (tester) async {
    await pumpBanner(
      tester,
      env: connectedEnv,
      counts: const {OutboxStatus.failed: 2},
    );
    expect(find.text('同期できていない変更が2件あります'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });

  testWidgets('同期待ちは「端末保存済み」を明示する（同期済みと誤認させない）', (tester) async {
    await pumpBanner(
      tester,
      env: connectedEnv,
      counts: const {OutboxStatus.pending: 3},
    );
    expect(find.text('端末保存済み・同期待ち 3件'), findsOneWidget);
  });

  testWidgets('すべて同期済み・オンラインでは何も表示しない（必要時だけ表示, §4）', (tester) async {
    await pumpBanner(tester, env: connectedEnv);
    expect(find.textContaining('同期'), findsNothing);
    expect(find.textContaining('オフライン'), findsNothing);
    expect(find.textContaining('デモモード'), findsNothing);
  });

  testWidgets('デモモードは常に「端末内のみ保存」を明示する', (tester) async {
    await pumpBanner(tester, env: demoEnv);
    expect(find.text('デモモード（端末内のみ保存）'), findsOneWidget);
  });
}
