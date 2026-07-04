import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/network/network_timeout.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_mutation_client.dart';
import 'package:oshi_trip/core/sync/retry_policy.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';

import '../helpers/test_db.dart';

/// send が永久にハングする fake http クライアント。
class _HangingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future; // 永久に完了しない
}

/// apply が「ハングするが共通タイムアウトで NetworkFailure になる」擬似リモート。
/// 実装は SupabaseMutationTransport のタイムアウト方針（withRemoteTimeout →
/// TimeoutException → NetworkFailure）と同型。
class _HangingButTimingOutRemote implements RemoteMutationClient {
  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    try {
      await Completer<void>()
          .future
          .withRemoteTimeout(const Duration(milliseconds: 50));
      return const Ok(null);
    } on TimeoutException catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }
}

void main() {
  group('withRemoteTimeout ヘルパ', () {
    test('完了しない Future はタイムアウトで TimeoutException を投げる', () {
      expect(
        Completer<void>()
            .future
            .withRemoteTimeout(const Duration(milliseconds: 20)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('タイムアウト前に完了する Future はそのまま値を返す', () async {
      final v =
          await Future.value(42).withRemoteTimeout(const Duration(seconds: 5));
      expect(v, 42);
    });
  });

  group('TimeoutHttpClient', () {
    test('内部clientの送信がハングしても共通タイムアウトで中断する', () {
      final client = TimeoutHttpClient(
        _HangingHttpClient(),
        timeout: const Duration(milliseconds: 20),
      );
      addTearDown(client.close);
      final req = http.Request('GET', Uri.parse('https://example.com/x'));
      expect(client.send(req), throwsA(isA<TimeoutException>()));
    });
  });

  group('SyncEngine: リモートのハングでも無期限に固まらない（H-A）', () {
    test('apply がタイムアウトすると op は pending へ戻り、drain は有限時間で完了する', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));
      final store = OutboxStore(db, clock);
      final engine = SyncEngine(
        store: store,
        snapshotResolver: () => SyncAuthSnapshot(
          ownerId: 'user-1',
          remote: _HangingButTimingOutRemote(),
        ),
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
        clock: clock,
        retryPolicy: const RetryPolicy(
          base: Duration.zero,
          maxInterval: Duration.zero,
          jitterRatio: 0,
        ),
        randomJitter: () => 0.5,
      );
      addTearDown(engine.dispose);

      await store.enqueue(
        OutboxOperation(
          mutationId: 'm1',
          ownerId: 'user-1',
          entityTable: SyncEntity.genbas,
          entityId: 'g1',
          opType: OutboxOpType.upsert,
          payload: const {'id': 'g1'},
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

      // ハングする apply でも、タイムアウトで NetworkFailure になり drain は返る。
      await engine.drain().timeout(const Duration(seconds: 5));

      final pending = await store.pendingOps(ownerId: 'user-1');
      expect(pending, hasLength(1));
      expect(pending.first.status, OutboxStatus.pending);
      expect(pending.first.attempts, 1);
    });

    test('in-flight な apply がタイムアウトすれば pauseForAuthTransition も返る', () async {
      final db = createTestDb();
      addTearDown(db.close);
      final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));
      final store = OutboxStore(db, clock);
      final engine = SyncEngine(
        store: store,
        snapshotResolver: () => SyncAuthSnapshot(
          ownerId: 'user-1',
          remote: _HangingButTimingOutRemote(),
        ),
        connectivity: const AlwaysOnlineConnectivity(),
        logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
        clock: clock,
        retryPolicy: const RetryPolicy(
          base: Duration.zero,
          maxInterval: Duration.zero,
          jitterRatio: 0,
        ),
        randomJitter: () => 0.5,
      );
      addTearDown(engine.dispose);

      await store.enqueue(
        OutboxOperation(
          mutationId: 'm1',
          ownerId: 'user-1',
          entityTable: SyncEntity.genbas,
          entityId: 'g1',
          opType: OutboxOpType.upsert,
          payload: const {'id': 'g1'},
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

      // drain 実行中（apply がハング中→タイムアウト）でも pause は有限時間で戻る。
      final draining = engine.drain();
      await engine.pauseForAuthTransition().timeout(const Duration(seconds: 5));
      await draining.timeout(const Duration(seconds: 5));
    });
  });
}
