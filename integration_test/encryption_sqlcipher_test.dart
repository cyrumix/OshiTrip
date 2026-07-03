import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oshi_trip/core/db/db_key_store.dart';
import 'package:oshi_trip/core/db/encrypted_database.dart';
import 'package:oshi_trip/core/db/encrypted_db_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// 実端末での SQLCipher 検証（H-03 item3）。
///
/// ホスト(Windows/CI 上の flutter test)の winsqlite3 は PRAGMA key を持たず
/// SQLCipher を検証できないため、これは device / emulator でのみ実行する:
///
///   flutter test integration_test/encryption_sqlcipher_test.dart -d `device`
///
/// 検証内容:
///   1. 暗号化DBはファイルを直接開いても平文検索できない。
///   2. 正しい鍵で再オープンでき、書いたデータを読める。
///   3. 誤った鍵ではオープンに失敗する。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    await prepareSqlCipher();
    final docs = await getApplicationDocumentsDirectory();
    dir = Directory(
      p.join(docs.path, 'enc_it_${DateTime.now().microsecondsSinceEpoch}'),
    );
    await dir.create(recursive: true);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  testWidgets('暗号化DBは平文検索できず、正鍵で開け、誤鍵で失敗する', (tester) async {
    const secret = 'SUPER-SECRET-SEAT-A12';
    final key = await InMemoryTestKeyStore().getOrCreateKey();
    final encrypted = File(p.join(dir.path, 'app.enc.sqlite'));

    // --- 暗号化DBを作成し、機密文字列を書き込む ---
    {
      final db = sqlite3.open(encrypted.path);
      db.execute("PRAGMA key = '$key';");
      db.execute('CREATE TABLE t(v TEXT);');
      db.execute("INSERT INTO t(v) VALUES ('$secret');");
      db.dispose();
    }

    // (1) ファイルの生バイトに機密文字列が平文で現れない。
    final rawBytes = await encrypted.readAsBytes();
    final rawString = String.fromCharCodes(rawBytes);
    expect(
      rawString.contains(secret),
      isFalse,
      reason: '暗号化DBのファイルに平文が漏れている',
    );
    // SQLCipher の暗号化DBは "SQLite format 3" ヘッダも平文では持たない。
    expect(rawString.startsWith('SQLite format 3'), isFalse);

    // (2) 正しい鍵で verify・再オープンでき、データを読める。
    expect(await sqlCipherVerify(encrypted, key), isTrue);
    {
      final db = sqlite3.open(encrypted.path);
      db.execute("PRAGMA key = '$key';");
      final rows = db.select('SELECT v FROM t;');
      expect(rows.single['v'], secret);
      db.dispose();
    }

    // (3) 誤った鍵では verify が false（オープン失敗）。
    expect(await sqlCipherVerify(encrypted, 'WRONG-KEY-$key'), isFalse);
  });

  testWidgets('EncryptedDbResolver: 平文→暗号化移行後に暗号化DBを正鍵で開ける', (tester) async {
    const secret = 'MIGRATED-SECRET-9931';
    final plaintext = File(p.join(dir.path, 'app.sqlite'));
    final encrypted = File(p.join(dir.path, 'app.enc.sqlite'));

    // 既存の平文DBを用意する。
    {
      final db = sqlite3.open(plaintext.path);
      db.execute('CREATE TABLE t(v TEXT);');
      db.execute("INSERT INTO t(v) VALUES ('$secret');");
      db.dispose();
    }

    final keyStore = InMemoryTestKeyStore();
    final resolver = EncryptedDbResolver(
      readExistingKey: keyStore.readRaw,
      getOrCreateKey: keyStore.getOrCreateKey,
      export: sqlCipherExport,
      verify: sqlCipherVerify,
    );

    final res =
        await resolver.resolve(plaintext: plaintext, encrypted: encrypted);

    // 移行完了: 平文は消え、暗号化DBが残る。
    expect(await plaintext.exists(), isFalse);
    expect(await encrypted.exists(), isTrue);

    // 平文検索できない。
    final rawString = String.fromCharCodes(await encrypted.readAsBytes());
    expect(rawString.contains(secret), isFalse);

    // 返された鍵で開いてデータを読める。
    final db = sqlite3.open(res.encrypted.path);
    db.execute("PRAGMA key = '${res.key}';");
    expect(db.select('SELECT v FROM t;').single['v'], secret);
    db.dispose();
  });
}

/// device テスト用のメモリ鍵ストア（flutter_secure_storage を使わず 256bit 乱数）。
class InMemoryTestKeyStore extends RandomKeyDbKeyStore {
  String? _value;

  @override
  Future<String?> readRaw() async => _value;

  @override
  Future<void> writeRaw(String value) async => _value = value;
}
