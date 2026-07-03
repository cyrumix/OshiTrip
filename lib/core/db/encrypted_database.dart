import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLCipher（端末DB暗号化, H-03）の device 結線。
///
/// このファイルは実端末（bootstrap）からのみ import する。host の単体テストは
/// 平文の in-memory DB を使うため、ここは通らない。
///
/// 暗号化の実効性（DBを直接開いても平文検索できない等）は device / CI でのみ
/// 検証可能。

/// SQLCipher を使う準備（Android の古い端末対策 + open override）。
Future<void> prepareSqlCipher() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
}

String _keyPragma(String key) {
  final escaped = key.replaceAll("'", "''");
  return "PRAGMA key = '$escaped';";
}

/// 暗号化DBを開く QueryExecutor。開いた直後に鍵で復号できるか検証する
/// （誤鍵なら sqlite_master 読み取りで例外＝open失敗）。
QueryExecutor openEncryptedExecutor(File file, String key) {
  return NativeDatabase(
    file,
    setup: (raw) {
      raw.execute(_keyPragma(key));
      // 鍵検証（既存DBなら誤鍵で失敗、新規DBなら成功）。
      raw.execute('SELECT count(*) FROM sqlite_master;');
    },
  );
}

/// 平文DB [plaintext] を鍵付き暗号化DB [target] へ書き出す（SQLCipher export）。
Future<void> sqlCipherExport(File plaintext, File target, String key) async {
  final db = sqlite3.open(plaintext.path); // 平文（鍵なし）で開く
  try {
    final escKey = key.replaceAll("'", "''");
    final escPath = target.path.replaceAll("'", "''");
    db.execute("ATTACH DATABASE '$escPath' AS enc KEY '$escKey';");
    db.execute("SELECT sqlcipher_export('enc');");
    db.execute('DETACH DATABASE enc;');
  } finally {
    db.dispose();
  }
}

/// 暗号化DB [encrypted] が [key] で開けるか検証する。
Future<bool> sqlCipherVerify(File encrypted, String key) async {
  try {
    final db = sqlite3.open(encrypted.path);
    try {
      db.execute(_keyPragma(key));
      db.execute('SELECT count(*) FROM sqlite_master;');
      return true;
    } finally {
      db.dispose();
    }
  } catch (_) {
    return false;
  }
}
