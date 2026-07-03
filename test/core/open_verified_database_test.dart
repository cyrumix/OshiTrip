import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/encrypted_db_resolver.dart';
import 'package:oshi_trip/core/db/open_verified_database.dart';
import 'package:sqlite3/open.dart';

/// DB の強制 open 検証（H-03 item5）。open に失敗したら接続を閉じて
/// EncryptionSetupException('open') を投げることを確認する。
void main() {
  setUpAll(() {
    if (Platform.isWindows) {
      open.overrideFor(OperatingSystem.windows, () {
        try {
          return DynamicLibrary.open('sqlite3.dll');
        } catch (_) {
          return DynamicLibrary.open('winsqlite3.dll');
        }
      });
    }
  });

  test('open 成功: SELECT 1 が通り、DB を返す', () async {
    final db = await openVerifiedDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final rows = await db.customSelect('SELECT 1 AS v').get();
    expect(rows.single.read<int>('v'), 1);
  });

  test('open 失敗（executor が open で例外）: 接続を閉じて open ステージで停止', () async {
    // LazyDatabase は最初のクエリで opener を呼ぶ。opener が投げると open 失敗。
    final executor = LazyDatabase(
      () async => throw const FileSystemException('cannot open db'),
    );
    await expectLater(
      openVerifiedDatabase(executor),
      throwsA(
        isA<EncryptionSetupException>().having((e) => e.stage, 'stage', 'open'),
      ),
    );
  });
}
