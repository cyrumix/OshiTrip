import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/network/connectivity.dart';

void main() {
  test('probe 成功/失敗で isOnline が更新され、遷移時に onlineChanges が通知する', () async {
    var reachable = true;
    final c = ReachabilityConnectivity(
      probe: () async => reachable,
      initialOnline: true,
    );
    addTearDown(c.dispose);

    final events = <bool>[];
    final sub = c.onlineChanges.listen(events.add);

    // オフラインへ遷移。
    reachable = false;
    await c.refresh();
    expect(await c.isOnline, isFalse);

    // オンラインへ復帰。
    reachable = true;
    await c.refresh();
    expect(await c.isOnline, isTrue);

    await Future<void>.delayed(Duration.zero);
    expect(events, [false, true]); // 遷移時のみ通知
    await sub.cancel();
  });

  test('状態が変わらない refresh は通知しない', () async {
    final c = ReachabilityConnectivity(probe: () async => true);
    addTearDown(c.dispose);
    final events = <bool>[];
    final sub = c.onlineChanges.listen(events.add);

    await c.refresh(); // true のまま
    await c.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);
    await sub.cancel();
  });

  test('probe が例外を投げたらオフライン扱い', () async {
    var throwErr = false;
    final c = ReachabilityConnectivity(
      probe: () async {
        if (throwErr) throw Exception('boom');
        return true;
      },
    );
    addTearDown(c.dispose);
    throwErr = true;
    await c.refresh();
    expect(await c.isOnline, isFalse);
  });
}
