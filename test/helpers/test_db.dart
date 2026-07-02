import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_expedition/core/db/app_database.dart';
import 'package:sqlite3/open.dart';

/// テスト用のインメモリDB。
///
/// Windows ホストでは sqlite3.dll が PATH にない場合があるため、
/// OS 同梱の winsqlite3.dll へフォールバックする。
AppDatabase createTestDb() {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, _openOnWindows);
  }
  return AppDatabase(NativeDatabase.memory());
}

DynamicLibrary _openOnWindows() {
  try {
    return DynamicLibrary.open('sqlite3.dll');
  } catch (_) {
    return DynamicLibrary.open('winsqlite3.dll');
  }
}

/// Widgetテストの最後に呼び、ツリーを破棄して drift のストリーム後始末
/// タイマー（StreamQueryStore.markAsClosed の Duration.zero タイマー）を
/// 発火させる。呼ばないと `!timersPending` でテストが失敗する。
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Duration.zero のタイマーは fake clock を進めないと発火しない。
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}
