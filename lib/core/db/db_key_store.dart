import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 端末DB暗号鍵の保管境界（H-03）。
///
/// 鍵は OS Keychain(iOS)/Keystore(Android) に保存し、ログ・dart-define・ソースへ
/// 置かない。初回は暗号学的乱数で生成し、以降は同じ鍵を返す。
abstract interface class DbKeyStore {
  /// 既存の鍵を返す。無ければ生成して保存してから返す。
  Future<String> getOrCreateKey();
}

/// 256bit 乱数鍵を hex で生成・保管する共通ロジック。
///
/// 実際の永続化は [readRaw]/[writeRaw]（サブクラスが OS セキュアストレージへ）。
/// 乱数は [Random.secure]（独自暗号を実装しない・固定鍵にしない）。
abstract class RandomKeyDbKeyStore implements DbKeyStore {
  const RandomKeyDbKeyStore();

  Future<String?> readRaw();
  Future<void> writeRaw(String value);

  @override
  Future<String> getOrCreateKey() async {
    final existing = await readRaw();
    if (existing != null && existing.isNotEmpty) return existing;
    final key = _generateKey();
    await writeRaw(key);
    return key;
  }

  String _generateKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes);
  }
}

/// flutter_secure_storage（OS Keychain/Keystore）実装。
class SecureDbKeyStore extends RandomKeyDbKeyStore {
  SecureDbKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _keyName = 'oshitrip_db_key_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRaw() => _storage.read(key: _keyName);

  @override
  Future<void> writeRaw(String value) =>
      _storage.write(key: _keyName, value: value);
}
