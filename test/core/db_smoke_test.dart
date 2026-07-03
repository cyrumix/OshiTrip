import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/app_database.dart';

import '../helpers/test_db.dart';

void main() {
  test('ローカルDBを作成して読み書きできる', () async {
    final db = createTestDb();
    addTearDown(db.close);

    await db.into(db.appKvs).insertOnConflictUpdate(
          AppKvsCompanion.insert(key: 'k', value: 'v'),
        );
    final row = await (db.select(db.appKvs)..where((t) => t.key.equals('k')))
        .getSingle();
    expect(row.value, 'v');
  });
}
