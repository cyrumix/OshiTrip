import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/auth/local_data_scope.dart';
import 'package:oshi_trip/core/db/local_data_purge.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/settings/application/oshi_color_controller.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// 推しカラー設定の owner 分離（C-01 / design-spec §11・R7）。
///
/// 推しカラーは個人化設定であり owner 単位で保存する。ログアウト・
/// ユーザー切替時に別ユーザーへ色設定が漏れないこと、元ユーザーへ戻れば
/// 設定が失われず復元されることを検証する。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntil(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(condition(), isTrue, reason: '状態変化を待機したが到達しなかった');
  }

  test('推しカラーは owner 単位で保存され、ユーザー切替・ログアウトで漏れない', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final kv = DriftKvStore(db);
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': 'user-a', 'email': 'a@example.com'}),
    );
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 7, 2))),
      ],
    );
    addTearDown(container.dispose);

    // user-a のセッション復元を待つ。
    final sub = container.listen(localDataScopeProvider, (_, __) {});
    addTearDown(sub.close);
    await pumpUntil(
      () => container.read(localDataScopeProvider).ownerIdOrNull == 'user-a',
    );

    // 未設定 → 保存 → owner 付きキーへ書かれる。
    expect(await container.read(oshiColorProvider.future), isNull);
    expect(
      await container.read(oshiColorProvider.notifier).setHex('#FF5CA8'),
      isTrue,
    );
    expect(await kv.get(KvKeys.oshiAccentColorFor('user-a')), '#FF5CA8');

    // ログアウト → 未設定として扱い、保存も拒否する。
    final auth = container.read(authRepositoryProvider);
    await auth.signOut();
    await pumpUntil(
      () => container.read(localDataScopeProvider).ownerIdOrNull == null,
    );
    expect(await container.read(oshiColorProvider.future), isNull);
    expect(
      await container.read(oshiColorProvider.notifier).setHex('#3D6DFF'),
      isFalse,
    );

    // 別ユーザーへ切替 → user-a の色は見えない。user-b は独立に保存できる。
    final signedIn =
        await auth.signIn(email: 'b@example.com', password: 'secret1');
    final userB = signedIn.valueOrNull!.id;
    await pumpUntil(
      () => container.read(localDataScopeProvider).ownerIdOrNull == userB,
    );
    expect(await container.read(oshiColorProvider.future), isNull);
    expect(
      await container.read(oshiColorProvider.notifier).setHex('#2FA95C'),
      isTrue,
    );
    expect(await kv.get(KvKeys.oshiAccentColorFor(userB)), '#2FA95C');
    // user-a の保存値は不変。
    expect(await kv.get(KvKeys.oshiAccentColorFor('user-a')), '#FF5CA8');

    // user-a 相当のセッションへ戻れば色設定は失われず復元される。
    await auth.signOut();
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': 'user-a', 'email': 'a@example.com'}),
    );
    // 復元経路は authStateChanges の restore に依存するため、KV から直接
    // 「owner 付きの値が残っている」ことをここでは確認する（再起動相当の
    // 復元は widget テスト側の中心フローで担保）。
    expect(await kv.get(KvKeys.oshiAccentColorFor('user-a')), '#FF5CA8');
  });

  test('アカウント削除の purge で当該 owner の推しカラーだけが消える', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.oshiAccentColorFor('user-a'), '#FF5CA8');
    await kv.put(KvKeys.oshiAccentColorFor('user-b'), '#3D6DFF');
    await kv.put(KvKeys.themeMode, 'dark');

    await purgeLocalDataForOwner(db, 'user-a');

    expect(await kv.get(KvKeys.oshiAccentColorFor('user-a')), isNull);
    // 他 owner の設定と端末共通設定（テーマ, D-45）には触れない。
    expect(await kv.get(KvKeys.oshiAccentColorFor('user-b')), '#3D6DFF');
    expect(await kv.get(KvKeys.themeMode), 'dark');
  });
}
