import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/features/auth/application/auth_controller.dart';
import 'package:oshi_trip/features/genba/domain/genba_repository.dart';
import 'package:oshi_trip/features/memory/domain/memory_repository.dart';
import 'package:oshi_trip/features/oshi/domain/oshi_repository.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// refreshFromRemote 呼び出し回数だけ記録する擬似リポジトリ群。
class _FakeGenbaRepo implements GenbaRepository {
  int refreshes = 0;
  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    refreshes++;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeMemoryRepo implements MemoryRepository {
  int refreshes = 0;
  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    refreshes++;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeOshiRepo implements OshiRepository {
  int refreshes = 0;
  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    refreshes++;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('ログイン（セッション確定）で genba/memory/oshi の背景 pull が走る', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final genba = _FakeGenbaRepo();
    final memory = _FakeMemoryRepo();
    final oshi = _FakeOshiRepo();

    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        genbaRepositoryProvider.overrideWithValue(genba),
        memoryRepositoryProvider.overrideWithValue(memory),
        oshiRepositoryProvider.overrideWithValue(oshi),
      ],
    );
    addTearDown(container.dispose);

    final failure = await container
        .read(authControllerProvider.notifier)
        .signIn('demo@example.com', 'demo-pass');
    expect(failure, isNull);

    // _afterSignIn がバックグラウンド pull を起動する（キャッシュ先行の裏側）。
    await Future<void>.delayed(Duration.zero);
    expect(genba.refreshes, 1);
    expect(memory.refreshes, 1);
    expect(oshi.refreshes, 1);
  });
}
