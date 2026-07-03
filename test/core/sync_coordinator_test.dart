import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/sync/sync_coordinator.dart';

void main() {
  test('start は初回 drain を1回起動する', () async {
    var drains = 0;
    final c = SyncCoordinator(
      drain: () async => drains++,
      retryInterval: null, // 周期タイマーは作らない（テスト安定化）
    );
    c.start();
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(drains, 1);
  });

  test('start は多重呼び出しでも初回 drain は1回だけ', () async {
    var drains = 0;
    final c = SyncCoordinator(drain: () async => drains++, retryInterval: null);
    c
      ..start()
      ..start();
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(drains, 1);
  });

  test('onAuthenticated / onAppResumed が drain を起動する', () async {
    var drains = 0;
    final c = SyncCoordinator(drain: () async => drains++, retryInterval: null);
    c.start();
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(drains, 1);

    c.onAuthenticated();
    await Future<void>.delayed(Duration.zero);
    expect(drains, 2);

    c.onAppResumed();
    await Future<void>.delayed(Duration.zero);
    expect(drains, 3);
  });
}
