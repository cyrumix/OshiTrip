import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';
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

/// ファイルバック（永続）のテスト用DB。close→reopen による本物の
/// マイグレーション経路（user_version 比較で onUpgrade が走る）を検証したい
/// ときに使う。Windows では winsqlite3.dll へフォールバックする。
AppDatabase openFileTestDb(File file) {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, _openOnWindows);
  }
  return AppDatabase(NativeDatabase(file));
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
