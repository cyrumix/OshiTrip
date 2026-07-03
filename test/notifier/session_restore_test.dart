import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/features/auth/domain/auth_repository.dart';
import 'package:oshi_trip/features/genba/domain/genba_repository.dart';
import 'package:oshi_trip/features/memory/domain/memory_repository.dart';
import 'package:oshi_trip/features/oshi/domain/oshi_repository.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

class _RecordingGenbaRepo implements GenbaRepository {
  final List<String> calls = [];
  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    calls.add('genba');
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _RecordingMemoryRepo implements MemoryRepository {
  int refreshes = 0;
  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async {
    refreshes++;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _RecordingOshiRepo implements OshiRepository {
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
  test('セッション復元(currentUser Loading→Authenticated)で背景pullが走る', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final genba = _RecordingGenbaRepo();
    final memory = _RecordingMemoryRepo();
    final oshi = _RecordingOshiRepo();
    final authController = StreamController<AppUser?>();
    addTearDown(authController.close);

    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        genbaRepositoryProvider.overrideWithValue(genba),
        memoryRepositoryProvider.overrideWithValue(memory),
        oshiRepositoryProvider.overrideWithValue(oshi),
        // 認証状態を「復元中(Loading)」から始め、後で確定させる。
        currentUserProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(container.dispose);

    // sessionSync を有効化（app が行うのと同じ）。この時点では Loading。
    container.read(sessionSyncProvider);
    await pumpEventQueue();
    expect(genba.calls, isEmpty); // 復元中は pull しない

    // セッション復元完了（Authenticated へ）。
    authController.add(const AppUser(id: 'user-A', email: 'a@example.com'));
    await pumpEventQueue();

    expect(genba.calls, ['genba']); // genba を先に pull
    expect(memory.refreshes, 1);
    expect(oshi.refreshes, 1);
  });

  test('同一ownerの再通知では重複pullしない。ログアウト→再ログインで再pull', () async {
    final db = createTestDb();
    addTearDown(db.close);
    final genba = _RecordingGenbaRepo();
    final memory = _RecordingMemoryRepo();
    final oshi = _RecordingOshiRepo();
    final authController = StreamController<AppUser?>();
    addTearDown(authController.close);

    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        genbaRepositoryProvider.overrideWithValue(genba),
        memoryRepositoryProvider.overrideWithValue(memory),
        oshiRepositoryProvider.overrideWithValue(oshi),
        currentUserProvider.overrideWith((ref) => authController.stream),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionSyncProvider);

    authController.add(const AppUser(id: 'user-A', email: 'a@example.com'));
    await pumpEventQueue();
    expect(genba.calls.length, 1);

    // 同一 owner の再通知（例: provider 再評価）では pull しない。
    authController.add(const AppUser(id: 'user-A', email: 'a@example.com'));
    await pumpEventQueue();
    expect(genba.calls.length, 1); // 重複しない

    // ログアウト（未認証確定）→ 再ログインで再 pull。
    // ログアウトと再ログインはユーザー操作として別イベントに分ける。
    authController.add(null);
    await pumpEventQueue();
    authController.add(const AppUser(id: 'user-A', email: 'a@example.com'));
    await pumpEventQueue();
    expect(genba.calls.length, 2); // 再ログインで再 pull
  });
}
