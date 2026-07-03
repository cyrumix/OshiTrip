import 'package:drift/drift.dart';

import 'app_database.dart';
import 'encrypted_db_resolver.dart';

/// [executor] で [AppDatabase] を開き、`SELECT 1` を実行して実際に接続を
/// 確立できることを強制確認する（H-03 item5）。
///
/// NativeDatabase は遅延 open のため、生成しただけでは鍵不一致・破損・IO 失敗を
/// 検出できない。ここで軽いクエリを走らせて open を強制し、失敗したら接続を
/// 確実に閉じてから [EncryptionSetupException]('open') を投げる（成功扱いにしない）。
Future<AppDatabase> openVerifiedDatabase(QueryExecutor executor) async {
  final db = AppDatabase(executor);
  try {
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (e) {
    // 開けなかった接続を残さない。close 自体の失敗は握りつぶし、
    // 元の open 失敗を EncryptionSetupException('open') として伝える。
    try {
      await db.close();
    } catch (_) {}
    throw EncryptionSetupException('open', e);
  }
}
