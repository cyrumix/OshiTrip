import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/theme/app_theme.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';

import 'fixtures.dart';
import 'test_db.dart';

/// デモユーザーでサインイン済みのテストDBを用意する。
Future<AppDatabase> signedInTestDb({String ownerId = 'demo-user-1'}) async {
  final db = createTestDb();
  final kv = DriftKvStore(db);
  await kv.put(KvKeys.tutorialDone, '1');
  await kv.put(
    KvKeys.demoUser,
    jsonEncode({'id': ownerId, 'email': 'demo@example.com'}),
  );
  return db;
}

/// 単一画面を実配線（Drift + 実Repository）で pump する共通ハーネス。
///
/// このWindowsホストでは Material3 既定の InkSparkle が
/// `ink_sparkle.frag`（Vulkan stage のみ）を読めず例外になるため、
/// **テストハーネス側だけ** splashFactory を InkRipple へ差し替える
/// （本番テーマは変更しない。docs/decisions.md の環境注意を参照）。
Future<ProviderContainer> pumpScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required FixedClock clock,
  required Widget child,
  bool dark = false,
  double textScale = 1.0,
  List<Override> extraOverrides = const [],
}) async {
  final container = ProviderContainer(
    overrides: [
      envProvider.overrideWithValue(demoEnv),
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
      nowProvider.overrideWith((ref) => Stream.value(clock.now())),
      imageStoreProvider.overrideWithValue(
        ImageStore(Directory.systemTemp.createTempSync('oshi_test_img')),
      ),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);
  final theme = (dark ? AppTheme.dark() : AppTheme.light())
      .copyWith(splashFactory: InkRipple.splashFactory);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme,
        locale: const Locale('ja'),
        supportedLocales: const [Locale('ja')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: textScale == 1.0
            ? null
            : (context, appChild) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: appChild!,
                ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// DBを使わない純コンポーネントを、指定テーマ・幅・文字倍率で pump する。
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double? logicalWidth,
  double textScale = 1.0,
}) async {
  if (logicalWidth != null) {
    tester.view.physicalSize = Size(logicalWidth * 2, 800 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final theme = (dark ? AppTheme.dark() : AppTheme.light())
      .copyWith(splashFactory: InkRipple.splashFactory);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(logicalWidth ?? 800, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
