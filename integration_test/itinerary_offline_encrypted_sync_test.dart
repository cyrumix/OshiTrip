import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oshi_trip/core/db/encrypted_database.dart';
import 'package:oshi_trip/core/db/open_verified_database.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';
import 'package:oshi_trip/core/network/connectivity.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/sync/outbox_store.dart';
import 'package:oshi_trip/core/sync/remote_mutation_client.dart';
import 'package:oshi_trip/core/sync/sync_engine.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/data/genba_repository_impl.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/itinerary/data/itinerary_repository_impl.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 統合テスト（実端末/エミュレータ）: 端末暗号化DB(SQLCipher)を**本番と同じ
/// オープン処理**で開き、オフライン編集 → Outbox 保存 → DB完全close → 再open →
/// SyncEngine 送信で pending 解消・リモート反映までを、file-backed な暗号化DBの
/// close/reopen を跨いで検証する（Phase 2レビュー点5）。
///
/// 実行:
///   flutter test integration_test/itinerary_offline_encrypted_sync_test.dart \
///     --flavor development -d `device`
///
/// なぜ integration_test なのか:
///   [openEncryptedExecutor] は SQLCipher の `PRAGMA key` を使う。ホスト
///   (Windows/CI の `flutter test`) の winsqlite3 は PRAGMA key を持たず暗号化を
///   検証できないため、暗号化の実効性を含むこの経路は device/emulator でのみ
///   実行する（encryption_sqlcipher_test.dart と同方針）。
///
/// リモート反映について:
///   実 Supabase を要さず決定的に検証するため、擬似リモート [_CapturingRemote]
///   が「サーバーが受理・記録した」状態を代替する。実バックエンドへの反映は CI の
///   `supabase db reset` + pgTAP と、手動E2Eで別途確認する。
///
/// Windows ホストの非ASCII TEMP 問題（手順書）:
///   本テストは device の `getApplicationDocumentsDirectory()`（ASCIIパス）に
///   DBを作るため影響を受けない。一方、ホスト側で `flutter test` を回すと、
///   sqlite3/drift のテンポラリが `%TEMP%` 配下に作られ、ユーザー名や
///   `OneDrive\ドキュメント` など**非ASCIIを含む TEMP パス**でネイティブDLLの
///   ロード・一時ファイル生成が失敗することがある。回避策:
///     1) リポジトリを ASCII パス（例 `C:\src\OshiTrip`）へ置く。
///     2) 実行前に TEMP/TMP を ASCII ディレクトリへ向ける:
///        PowerShell: `$env:TEMP='C:\tmp'; $env:TMP='C:\tmp'`（事前に `mkdir C:\tmp`）。
///     3) integration_test は実機/エミュレータで走らせる（ホスト TEMP を使わない）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const owner = '11111111-1111-1111-1111-111111111111';
  // SQLCipher の鍵（テスト固定）。本番は SecureDbKeyStore が端末鍵を管理する。
  const dbKey = 'integration-sqlcipher-key-0123456789abcdef';
  const clock = SystemClock();

  late Directory dir;
  late File dbFile;

  setUp(() async {
    await prepareSqlCipher();
    final docs = await getApplicationDocumentsDirectory();
    dir = Directory(
      p.join(
        docs.path,
        'offline_sync_it_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await dir.create(recursive: true);
    dbFile = File(p.join(dir.path, 'oshitrip.enc.sqlite'));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  testWidgets('オフライン編集→暗号化DBを閉じて再オープン→同期で pending 解消・リモート反映', (tester) async {
    // ---- 1. 本番と同じ暗号化オープンでDBを開き、オフライン編集する ----
    final db1 =
        await openVerifiedDatabase(openEncryptedExecutor(dbFile, dbKey));
    final outbox1 = OutboxStore(db1, clock);
    // オフライン: 送信スナップショット null（SyncEngine は何も送らない）。
    final engine1 = SyncEngine(
      store: outbox1,
      snapshotResolver: () => null,
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      clock: clock,
    );
    final genbaRepo1 = GenbaRepositoryImpl(
      db: db1,
      outbox: outbox1,
      syncEngine: engine1,
      clock: clock,
      ownerIdResolver: () => owner,
      remoteResolver: () => null,
    );
    final itineraryRepo1 = ItineraryRepositoryImpl(
      db: db1,
      outbox: outbox1,
      syncEngine: engine1,
      clock: clock,
      ownerIdResolver: () => owner,
      remoteResolver: () => null,
    );

    final now = clock.now().toUtc();
    final genba = Genba(
      id: 'genba-it-1',
      ownerId: owner,
      artistName: 'アーティスト',
      title: 'オフライン編集の公演',
      eventDate: DateTime(2026, 8, 1),
      createdAt: now,
      updatedAt: now,
    );
    expect((await genbaRepo1.upsertGenba(genba)).isOk, isTrue);
    // 旅程（計画）もオフラインで1件保存する。
    final plan = ItineraryPlan(
      id: 'plan-it-1',
      genbaId: 'genba-it-1',
      ownerId: owner,
      title: '計画',
      timeZoneId: 'Asia/Tokyo',
      createdAt: now,
      updatedAt: now,
    );
    expect((await itineraryRepo1.upsertPlan(plan)).isOk, isTrue);

    // オフラインなので未送信の Outbox が積まれている。
    final pendingBefore = await outbox1.pendingOps(ownerId: owner);
    expect(
      pendingBefore.where((o) => o.entityTable == SyncEntity.genbas),
      isNotEmpty,
    );
    expect(
      pendingBefore.where((o) => o.entityTable == SyncEntity.itineraryPlans),
      isNotEmpty,
    );

    // ---- 2. DBを完全に閉じ、暗号化DBを正鍵で再オープンする ----
    engine1.dispose();
    await db1.close();

    final db2 =
        await openVerifiedDatabase(openEncryptedExecutor(dbFile, dbKey));
    addTearDown(db2.close);
    final outbox2 = OutboxStore(db2, clock);

    // 暗号化DBから復号してデータが復元される。
    expect(
      (await db2.select(db2.genbas).get()).map((g) => g.id),
      contains('genba-it-1'),
    );
    expect(
      (await db2.select(db2.itineraryPlans).get()).map((r) => r.id),
      contains('plan-it-1'),
    );
    // 未送信 Outbox も再起動後に残っている（内容を失わない）。
    final pendingAfterReopen = await outbox2.pendingOps(ownerId: owner);
    expect(pendingAfterReopen, isNotEmpty);

    // ---- 3. オンライン化して SyncEngine で送信する ----
    final remote = _CapturingRemote();
    final engine2 = SyncEngine(
      store: outbox2,
      snapshotResolver: () => SyncAuthSnapshot(ownerId: owner, remote: remote),
      connectivity: const AlwaysOnlineConnectivity(),
      logger: AppLogger(minLevel: LogLevel.error, output: (_) {}),
      clock: clock,
    );
    addTearDown(engine2.dispose);
    await engine2.drain();

    // pending が解消し、擬似リモート（＝サーバー反映）へ全件届いた。
    final pendingAfterSync = await outbox2.pendingOps(ownerId: owner);
    expect(pendingAfterSync, isEmpty);
    expect(
      remote.applied.where(
        (o) => o.entityTable == SyncEntity.genbas && o.entityId == 'genba-it-1',
      ),
      isNotEmpty,
    );
    expect(
      remote.applied.where(
        (o) =>
            o.entityTable == SyncEntity.itineraryPlans &&
            o.entityId == 'plan-it-1',
      ),
      isNotEmpty,
    );
  });
}

/// 擬似リモート: 適用された操作を記録し常に成功を返す（sync_engine_test と同型）。
class _CapturingRemote implements RemoteMutationClient {
  final List<OutboxOperation> applied = [];

  @override
  Future<Result<void>> apply(OutboxOperation op) async {
    applied.add(op);
    return const Ok(null);
  }
}
