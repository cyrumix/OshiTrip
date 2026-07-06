import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/sync/session_refresher.dart';

/// gate で停止できる擬似 refresh。owner ごとの呼び出しと、適用フェーズに
/// 到達したか（isStale を通過して「適用」した owner）を記録する。
class _GatedRefreshes {
  final Map<String, Completer<void>> gates = {};
  final List<String> selected = []; // remote 取得に入った owner（呼ばれた順）
  final List<String> applied = []; // isStale を通過して適用した owner

  Completer<void> gateFor(String owner) =>
      gates.putIfAbsent(owner, Completer<void>.new);

  /// genba refresh を owner ごとに束ねる。テストは owner を引数で切替える。
  ScopedRefresh forOwner(String owner) {
    return (isStale) async {
      selected.add(owner);
      await gateFor(owner).future; // remote 取得を gate で停止
      if (isStale()) return const Ok(null); // 認証切替後は適用しない
      applied.add(owner);
      return const Ok(null);
    };
  }
}

void main() {
  test('Aのpull実行中にBへ切替: Aは適用せず、BはA完了後に必ず実行される', () async {
    final g = _GatedRefreshes();
    // 現在 owner を可変にして genba refresh を切り替える。
    var currentOwner = 'A';
    final refresher = SessionRefresher(
      refreshGenba: (isStale) => g.forOwner(currentOwner)(isStale),
      refreshMemory: (_) async => const Ok(null),
      refreshOshi: (_) async => const Ok(null),
      refreshTemplate: (_) async => const Ok(null),
    );

    // A のセッション確定 → A の pull 開始（genba refresh が gate で停止）。
    refresher.onAuthenticated('A');
    await pumpEventQueue();
    expect(g.selected, ['A']); // A の remote 取得に入っている
    expect(g.applied, isEmpty);

    // A の取得中に B が認証される（scope 交代）。
    currentOwner = 'B';
    refresher.onAuthenticated('B');

    // A の gate を開放 → A は isStale を検知して「適用しない」。
    g.gateFor('A').complete();
    await pumpEventQueue();
    expect(g.applied, isEmpty); // A は適用されない（ローカル行を消さない）

    // A 完了後、B の pull が自動実行される。B の gate を開放。
    expect(g.selected, ['A', 'B']); // B の取得に入っている
    g.gateFor('B').complete();
    await pumpEventQueue();
    expect(g.applied, ['B']); // B は適用される（取りこぼさない）
  });

  test('pull途中のlogout(pause)は以降のテーブルを適用しない', () async {
    final memoryGate = Completer<void>();
    var genbaApplied = false;
    var memoryApplied = false;
    final refresher = SessionRefresher(
      refreshGenba: (isStale) async {
        if (!isStale()) genbaApplied = true;
        return const Ok(null);
      },
      refreshMemory: (isStale) async {
        await memoryGate.future;
        if (!isStale()) memoryApplied = true;
        return const Ok(null);
      },
      refreshOshi: (_) async => const Ok(null),
      refreshTemplate: (_) async => const Ok(null),
    );

    refresher.onAuthenticated('A');
    await pumpEventQueue();
    expect(genbaApplied, isTrue); // genba は適用済み

    // memory 取得中に logout 相当の pause。
    final paused = refresher.pauseForAuthTransition();
    memoryGate.complete();
    await paused;
    await pumpEventQueue();
    expect(memoryApplied, isFalse); // pause 後は memory を適用しない
  });

  test('同一ownerの重複pullを防ぎ、logout→再ログインで再pull', () async {
    var genbaPulls = 0;
    final refresher = SessionRefresher(
      refreshGenba: (_) async {
        genbaPulls++;
        return const Ok(null);
      },
      refreshMemory: (_) async => const Ok(null),
      refreshOshi: (_) async => const Ok(null),
      refreshTemplate: (_) async => const Ok(null),
    );

    refresher.onAuthenticated('A');
    await pumpEventQueue();
    expect(genbaPulls, 1);

    refresher.onAuthenticated('A'); // 同一 owner → 重複しない
    await pumpEventQueue();
    expect(genbaPulls, 1);

    refresher.reset(); // logout
    refresher.onAuthenticated('A'); // 再ログイン → 再 pull
    await pumpEventQueue();
    expect(genbaPulls, 2);
  });

  test('pause中のonAuthenticatedはresumeで実行される', () async {
    var pulls = 0;
    final refresher = SessionRefresher(
      refreshGenba: (_) async {
        pulls++;
        return const Ok(null);
      },
      refreshMemory: (_) async => const Ok(null),
      refreshOshi: (_) async => const Ok(null),
      refreshTemplate: (_) async => const Ok(null),
    );

    await refresher.pauseForAuthTransition();
    refresher.onAuthenticated('B'); // pause 中 → pending に積む
    await pumpEventQueue();
    expect(pulls, 0);

    refresher.resumeAfterAuthTransition();
    await pumpEventQueue();
    expect(pulls, 1); // resume で pending B を実行
  });
}
