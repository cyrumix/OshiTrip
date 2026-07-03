import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/db/db_key_store.dart';

/// OS セキュアストレージの代わりにメモリで永続化する fake（テスト用）。
/// 実運用は [SecureDbKeyStore]（flutter_secure_storage）。
class _InMemoryKeyStore extends RandomKeyDbKeyStore {
  String? _value;
  int writes = 0;

  @override
  Future<String?> readRaw() async => _value;

  @override
  Future<void> writeRaw(String value) async {
    _value = value;
    writes++;
  }
}

void main() {
  test('初回は鍵を生成して保存し、2回目は同じ鍵を返す（生成は1回）', () async {
    final store = _InMemoryKeyStore();
    final k1 = await store.getOrCreateKey();
    final k2 = await store.getOrCreateKey();

    expect(k1, isNotEmpty);
    expect(k1, k2); // 同じ鍵
    expect(store.writes, 1); // 生成・保存は初回のみ
  });

  test('生成鍵は十分な長さ（256bit相当）で毎回異なる', () async {
    final a = _InMemoryKeyStore();
    final b = _InMemoryKeyStore();
    final ka = await a.getOrCreateKey();
    final kb = await b.getOrCreateKey();

    // base64url(32 bytes) は 43 文字程度。固定鍵でないこと。
    expect(ka.length, greaterThanOrEqualTo(40));
    expect(ka, isNot(kb));
  });

  test('既存鍵があればそれを返す（再生成しない）', () async {
    final store = _InMemoryKeyStore().._value = 'preexisting-key-value';
    final k = await store.getOrCreateKey();
    expect(k, 'preexisting-key-value');
    expect(store.writes, 0);
  });
}
