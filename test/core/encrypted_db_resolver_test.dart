import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/encrypted_db_resolver.dart';
import 'package:path/path.dart' as p;

/// 暗号化を模した fake: 平文を `ENC:key:data` で書き出す。verify は同じ鍵で
/// 書かれているかを確認する（誤鍵は検出、正鍵のみ true）。
Future<void> fakeExport(File src, File target, String key) async {
  target.writeAsStringSync('ENC:$key:${src.readAsStringSync()}');
}

Future<bool> fakeVerify(File f, String key) async {
  if (!f.existsSync()) return false;
  return f.readAsStringSync().startsWith('ENC:$key:');
}

class FakeKeyStore {
  FakeKeyStore({this.stored});
  String? stored;
  int generated = 0;
  int readCount = 0;

  Future<String?> readRaw() async {
    readCount++;
    return stored;
  }

  Future<String> getOrCreateKey() async {
    if (stored == null) {
      generated++;
      stored = 'KEY$generated';
    }
    return stored!;
  }
}

void main() {
  late Directory dir;
  late File plaintext;
  late File encrypted;
  late File migrating;
  late File backup;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('oshi_enc_resolver');
    plaintext = File(p.join(dir.path, 'db.sqlite'));
    encrypted = File(p.join(dir.path, 'db.enc.sqlite'));
    migrating = File('${encrypted.path}.migrating');
    backup = File('${plaintext.path}.premigration.bak');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  EncryptedDbResolver makeResolver(FakeKeyStore ks) => EncryptedDbResolver(
        readExistingKey: ks.readRaw,
        getOrCreateKey: ks.getOrCreateKey,
        export: fakeExport,
        verify: fakeVerify,
      );

  test('新規インストール: 鍵を生成し、空の暗号化DBパスを返す', () async {
    final ks = FakeKeyStore();
    final res = await makeResolver(ks).resolve(
      plaintext: plaintext,
      encrypted: encrypted,
    );
    expect(res.encrypted.path, encrypted.path);
    expect(res.key, 'KEY1');
    expect(ks.generated, 1);
    expect(encrypted.existsSync(), isFalse); // open 時に作成される
  });

  test('平文→暗号化への一度きり移行: 暗号化DB確定・平文と backup を削除', () async {
    plaintext.writeAsStringSync('PLAIN-DATA');
    final ks = FakeKeyStore();
    final res = await makeResolver(ks).resolve(
      plaintext: plaintext,
      encrypted: encrypted,
    );
    expect(res.key, 'KEY1');
    expect(encrypted.existsSync(), isTrue);
    expect(encrypted.readAsStringSync(), 'ENC:KEY1:PLAIN-DATA');
    expect(plaintext.existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
    expect(migrating.existsSync(), isFalse);
  });

  test('既存暗号化DB + 正しい鍵: verify して使い、残存平文/backup を掃除', () async {
    encrypted.writeAsStringSync('ENC:KEYX:DATA');
    plaintext.writeAsStringSync('LEFTOVER'); // 確定直後の電源断で残存
    backup.writeAsStringSync('ENC-ERA-BACKUP');
    final ks = FakeKeyStore(stored: 'KEYX');
    final res = await makeResolver(ks).resolve(
      plaintext: plaintext,
      encrypted: encrypted,
    );
    expect(res.key, 'KEYX');
    expect(res.encrypted.path, encrypted.path);
    // 暗号化DBが真実になったので残存は安全に掃除される。
    expect(plaintext.existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
    // 鍵は再生成されない。
    expect(ks.generated, 0);
  });

  test('鍵消失(既存暗号化DBあり): 鍵を再生成せず key-missing で停止、平文温存', () async {
    encrypted.writeAsStringSync('ENC:KEYX:DATA');
    plaintext.writeAsStringSync('PLAIN-STILL-HERE');
    final ks = FakeKeyStore(stored: null); // 鍵が失われた
    await expectLater(
      makeResolver(ks).resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'key-missing'),
      ),
    );
    // 鍵を再生成・上書きしない。未検証平文を消さない。
    expect(ks.generated, 0);
    expect(encrypted.existsSync(), isTrue);
    expect(plaintext.existsSync(), isTrue);
    expect(plaintext.readAsStringSync(), 'PLAIN-STILL-HERE');
  });

  test('誤鍵(既存暗号化DB verify 失敗): 上書きせず verify-failed で停止', () async {
    encrypted.writeAsStringSync('ENC:REAL-KEY:DATA');
    final ks = FakeKeyStore(stored: 'WRONG-KEY'); // 鍵が合わない
    await expectLater(
      makeResolver(ks).resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'verify-failed'),
      ),
    );
    // 既存暗号化DBを上書き・削除しない。
    expect(encrypted.readAsStringSync(), 'ENC:REAL-KEY:DATA');
    expect(ks.generated, 0);
  });

  test('確定直後の電源断(暗号化DB + 平文 + backup): 暗号化DB検証後に安全掃除', () async {
    // 移行完了で暗号化DBは確定済み。平文/backup が残ったまま電源断した状態。
    encrypted.writeAsStringSync('ENC:KEYX:DATA');
    plaintext.writeAsStringSync('OLD-PLAIN');
    backup.writeAsStringSync('OLD-BACKUP');
    final ks = FakeKeyStore(stored: 'KEYX');
    final res = await makeResolver(ks).resolve(
      plaintext: plaintext,
      encrypted: encrypted,
    );
    expect(res.encrypted.path, encrypted.path);
    expect(plaintext.existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
  });

  test('backup だけ残る異常(暗号化DBも平文も無い): backup から復元し移行し直す', () async {
    // 平文→backup へ rename 後、暗号化DBが失われ backup だけ残った異常状態。
    backup.writeAsStringSync('RECOVER-ME');
    final ks = FakeKeyStore();
    await makeResolver(ks).resolve(
      plaintext: plaintext,
      encrypted: encrypted,
    );
    // backup から平文を復元し、暗号化DBへ移行する。
    expect(encrypted.existsSync(), isTrue);
    expect(encrypted.readAsStringSync(), 'ENC:KEY1:RECOVER-ME');
    expect(plaintext.existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
  });

  test('中断した .migrating は常に破棄する', () async {
    migrating.writeAsStringSync('PARTIAL-GARBAGE');
    plaintext.writeAsStringSync('PLAIN');
    final ks = FakeKeyStore();
    final res = await makeResolver(ks).resolve(
      plaintext: plaintext,
      encrypted: encrypted,
    );
    // 部分成果物は破棄され、正しく作り直される。
    expect(res.encrypted.readAsStringSync(), 'ENC:KEY1:PLAIN');
    expect(migrating.existsSync(), isFalse);
  });

  test('export 失敗: 平文を温存し export ステージで停止', () async {
    plaintext.writeAsStringSync('PLAIN');
    final ks = FakeKeyStore();
    final resolver = EncryptedDbResolver(
      readExistingKey: ks.readRaw,
      getOrCreateKey: ks.getOrCreateKey,
      export: (src, target, key) async => throw const FileSystemException('io'),
      verify: fakeVerify,
    );
    await expectLater(
      resolver.resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'export'),
      ),
    );
    // 平文は温存、暗号化DB・migrating は残さない。
    expect(plaintext.existsSync(), isTrue);
    expect(plaintext.readAsStringSync(), 'PLAIN');
    expect(encrypted.existsSync(), isFalse);
    expect(migrating.existsSync(), isFalse);
  });

  test('移行後の verify 失敗: 平文を温存し verify ステージで停止', () async {
    plaintext.writeAsStringSync('PLAIN');
    final ks = FakeKeyStore();
    final resolver = EncryptedDbResolver(
      readExistingKey: ks.readRaw,
      getOrCreateKey: ks.getOrCreateKey,
      export: fakeExport,
      verify: (f, key) async => false, // 常に失敗
    );
    await expectLater(
      resolver.resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'verify'),
      ),
    );
    expect(plaintext.existsSync(), isTrue);
    expect(encrypted.existsSync(), isFalse);
    expect(migrating.existsSync(), isFalse);
  });

  test('Keychain 読み取り例外は key-read へ変換（鍵消失 null とは区別）', () async {
    encrypted.writeAsStringSync('ENC:KEYX:DATA');
    final resolver = EncryptedDbResolver(
      readExistingKey: () async => throw const _KeychainException(),
      getOrCreateKey: () async => 'SHOULD-NOT-BE-CALLED',
      export: fakeExport,
      verify: fakeVerify,
    );
    await expectLater(
      resolver.resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'key-read'),
      ),
    );
    // 既存暗号化DBは温存（上書き・削除しない）。
    expect(encrypted.existsSync(), isTrue);
  });

  test('Keychain 書き込み/生成例外は key-create へ変換', () async {
    plaintext.writeAsStringSync('PLAIN');
    final resolver = EncryptedDbResolver(
      readExistingKey: () async => null,
      getOrCreateKey: () async => throw const _KeychainException(),
      export: fakeExport,
      verify: fakeVerify,
    );
    await expectLater(
      resolver.resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'key-create'),
      ),
    );
    // 平文は温存。
    expect(plaintext.existsSync(), isTrue);
  });

  test('確定 rename が失敗すると finalize ステージで停止（平文温存）', () async {
    plaintext.writeAsStringSync('PLAIN');
    // encrypted.path にディレクトリを置き、migrating→encrypted の rename を失敗させる。
    Directory(encrypted.path).createSync(recursive: true);
    final ks = FakeKeyStore();
    await expectLater(
      makeResolver(ks).resolve(plaintext: plaintext, encrypted: encrypted),
      throwsA(
        isA<EncryptionSetupException>()
            .having((e) => e.stage, 'stage', 'finalize'),
      ),
    );
    // 平文は温存される（確定できていない）。
    expect(plaintext.existsSync(), isTrue);
  });
}

class _KeychainException implements Exception {
  const _KeychainException();
}
