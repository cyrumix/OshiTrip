import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../features/auth/data/demo_auth_repository.dart';
import '../features/auth/data/supabase_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/genba/data/genba_repository_impl.dart';
import '../features/genba/domain/genba_repository.dart';
import '../features/itinerary/data/itinerary_repository_impl.dart';
import '../features/itinerary/domain/itinerary_repository.dart';
import '../features/memory/data/memory_repository_impl.dart';
import '../features/memory/data/supabase_photo_uploader.dart';
import '../features/memory/domain/memory_repository.dart';
import '../features/oshi/data/oshi_repository_impl.dart';
import '../features/oshi/domain/oshi_repository.dart';
import '../features/settings/data/supabase_account_repository.dart';
import '../features/settings/domain/account_repository.dart';
import '../features/templates/data/template_repository_impl.dart';
import '../features/templates/domain/template_repository.dart';
import 'auth/local_data_scope.dart';
import 'config/env.dart';
import 'db/app_database.dart';
import 'error/failure.dart';
import 'error/result.dart';
import 'images/image_store.dart';
import 'logging/app_logger.dart';
import 'network/connectivity.dart';
import 'network/network_timeout.dart';
import 'storage/kv_store.dart';
import 'sync/conflict_resolver.dart';
import 'sync/outbox_operation.dart';
import 'sync/outbox_store.dart';
import 'sync/remote_mutation_client.dart';
import 'sync/session_refresher.dart';
import 'sync/supabase_remote_mutation_client.dart';
import 'sync/sync_coordinator.dart';
import 'sync/sync_engine.dart';
import 'time/clock.dart';

/// DI 配線（手書きProvider）。bootstrap で env / database を override する。
final envProvider = Provider<AppEnv>(
  (ref) => throw StateError('envProvider は bootstrap で override される'),
);

final clockProvider = Provider<Clock>((_) => const SystemClock());

final loggerProvider = Provider<AppLogger>(
  (ref) => AppLogger(
    minLevel: AppLogger.levelFromName(ref.watch(envProvider).logLevelName),
  ),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider は bootstrap で override される'),
);

/// 画像の耐久保存ストア（H-04）。bootstrap で実 baseDir を override する。
final imageStoreProvider = Provider<ImageStore>(
  (ref) => throw StateError('imageStoreProvider は bootstrap で override される'),
);

final kvStoreProvider =
    Provider<KvStore>((ref) => DriftKvStore(ref.watch(databaseProvider)));

final draftStoreProvider = Provider<DraftStore>(
  (ref) => DriftDraftStore(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  ),
);

final outboxStoreProvider = Provider<OutboxStore>(
  (ref) => OutboxStore(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

/// 接続監視（H-02）。デモ・未設定では常時オンライン仮定（プラグイン/通信なし）。
/// 本番/staging では Supabase への軽量到達性チェックを周期実行する。
final connectivityProvider = Provider<ConnectivityObserver>((ref) {
  final env = ref.watch(envProvider);
  if (env.isDemoMode || !env.hasSupabaseConfig) {
    return const AlwaysOnlineConnectivity();
  }
  final healthUri = Uri.parse('${env.supabaseUrl}/auth/v1/health');
  final observer = ReachabilityConnectivity(
    probe: () async {
      try {
        final res =
            await http.get(healthUri).timeout(const Duration(seconds: 5));
        return res.statusCode >= 200 && res.statusCode < 500;
      } catch (_) {
        return false;
      }
    },
  )..start();
  ref.onDispose(observer.dispose);
  return observer;
});

/// デモモードでは null（Supabase 未初期化）。
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final env = ref.watch(envProvider);
  if (env.isDemoMode) return null;
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return DemoAuthRepository(ref.watch(kvStoreProvider));
  }
  return SupabaseAuthRepository(client);
});

/// 認証状態（起動時の復元を含む）。
final currentUserProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// ログイン済みかつ非デモのときのみリモート同期先が存在する。
final remoteMutationClientProvider = Provider<RemoteMutationClient?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (client == null || user == null || user.isDemo) return null;
  return SupabaseRemoteMutationClient(
    SupabaseMutationTransport(client),
    ref.watch(databaseProvider),
  );
});

/// 認証主体ごとのローカルデータ境界（C-01）。[currentUserProvider] から導出し、
/// 未認証・認証復元中はユーザーデータを一切表示しない。
///
/// Repository / Outbox / 下書き等はすべてこの Provider を経由して owner を
/// 解決する。認証状態が変わるたびに新しい scope 値になるため、これを watch
/// している Provider（Repository群）は scope 変化ごとに作り直され、購読中の
/// Stream も再構築される（前ユーザーの値が一瞬でも残らないようにするため）。
final localDataScopeProvider = Provider<LocalDataScope>((ref) {
  final authAsync = ref.watch(currentUserProvider);
  return authAsync.when(
    data: (user) => user == null
        ? const LocalDataScopeUnauthenticated()
        : LocalDataScopeAuthenticated(user.id),
    loading: () => const LocalDataScopeLoading(),
    // authStateChanges 自体のエラーはユーザーデータへの到達性を持たせない。
    error: (_, __) => const LocalDataScopeUnauthenticated(),
  );
});

/// 同期用の認証スナップショット（C-01）。owner と、その owner に対応する
/// [RemoteMutationClient] を「1回の provider 読み取り」で同時に確定する。
///
/// `localDataScopeProvider` と `remoteMutationClientProvider` はどちらも
/// `currentUserProvider` から導出されるため、この provider が両者を同時に
/// watch することで、owner と remote が常に同じ認証状態の組になる
/// （owner=A なのに remote=B、という不整合を構造的に排除する）。
final syncAuthSnapshotProvider = Provider<SyncAuthSnapshot?>((ref) {
  final scope = ref.watch(localDataScopeProvider);
  final remote = ref.watch(remoteMutationClientProvider);
  if (scope is! LocalDataScopeAuthenticated || remote == null) return null;
  return SyncAuthSnapshot(ownerId: scope.ownerId, remote: remote);
});

/// SyncEngine は認証切替をまたいで単一インスタンスとして生き続ける
/// （drain中の破棄競合を避けるため）。drain のたびに
/// [syncAuthSnapshotProvider] で owner と remote を同時に確定し、その owner の
/// op だけをその remote へ送る（C-01: 別ownerの操作をremoteへ渡さない）。
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    store: ref.watch(outboxStoreProvider),
    snapshotResolver: () => ref.read(syncAuthSnapshotProvider),
    connectivity: ref.watch(connectivityProvider),
    logger: ref.watch(loggerProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// 同期状態サマリ（バナー表示用）。現在ownerに限定し、未認証時や前ownerの
/// 残留件数を表示しない。
final outboxStatusProvider = StreamProvider<Map<OutboxStatus, int>>((ref) {
  final scope = ref.watch(localDataScopeProvider);
  if (scope is! LocalDataScopeAuthenticated) return Stream.value(const {});
  return ref.watch(outboxStoreProvider).watchStatusCounts(
        ownerId: scope.ownerId,
      );
});

/// 現在の到達性（オフライン表示用）。既存の [ConnectivityObserver] の判定を
/// そのまま流す（架空の状態・固定ダミーを作らない）。デモ・未設定では
/// [AlwaysOnlineConnectivity] のため常に true（オフライン表示は出ない）。
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  yield await connectivity.isOnline;
  yield* connectivity.onlineChanges;
});

final genbaRepositoryProvider = Provider<GenbaRepository>((ref) {
  // scope を watch し、認証切替のたびに新しいインスタンスへ作り直す。
  // これにより watchAll() の購読も再構築され、前ownerの値が残らない。
  final scope = ref.watch(localDataScopeProvider);
  return GenbaRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => scope.ownerIdOrNull,
    remoteResolver: () {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null || user.isDemo) return null;
      return ref.read(supabaseClientProvider);
    },
  );
});

SupabaseClient? _remoteClientOrNull(Ref ref) {
  final user = ref.read(currentUserProvider).valueOrNull;
  if (user == null || user.isDemo) return null;
  return ref.read(supabaseClientProvider);
}

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final scope = ref.watch(localDataScopeProvider);
  return MemoryRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => scope.ownerIdOrNull,
    remoteResolver: () => _remoteClientOrNull(ref),
    imageStoreResolver: () => ref.watch(imageStoreProvider),
  );
});

final oshiRepositoryProvider = Provider<OshiRepository>((ref) {
  final scope = ref.watch(localDataScopeProvider);
  return OshiRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => scope.ownerIdOrNull,
    remoteResolver: () => _remoteClientOrNull(ref),
  );
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  final scope = ref.watch(localDataScopeProvider);
  return TemplateRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => scope.ownerIdOrNull,
    remoteResolver: () => _remoteClientOrNull(ref),
  );
});

final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final scope = ref.watch(localDataScopeProvider);
  return ItineraryRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => scope.ownerIdOrNull,
    remoteResolver: () => _remoteClientOrNull(ref),
  );
});

/// drain の駆動タイミング調停（H-02）。デモでは周期タイマーを作らない。
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final env = ref.watch(envProvider);
  final coordinator = SyncCoordinator(
    drain: () => ref.read(syncEngineProvider).drain(),
    retryInterval: env.isDemoMode ? null : const Duration(seconds: 60),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// 認証確定時の背景 pull（genba→memory/oshi、owner単位で重複防止, H-02）。
/// 各 refresh へ認証切替検出フック（isStale）を渡す。
final sessionRefresherProvider = Provider<SessionRefresher>((ref) {
  return SessionRefresher(
    refreshGenba: (isStale) =>
        ref.read(genbaRepositoryProvider).refreshFromRemote(isStale: isStale),
    refreshMemory: (isStale) =>
        ref.read(memoryRepositoryProvider).refreshFromRemote(isStale: isStale),
    refreshOshi: (isStale) =>
        ref.read(oshiRepositoryProvider).refreshFromRemote(isStale: isStale),
    refreshTemplate: (isStale) => ref
        .read(templateRepositoryProvider)
        .refreshFromRemote(isStale: isStale),
    refreshItinerary: (isStale) => ref
        .read(itineraryRepositoryProvider)
        .refreshFromRemote(isStale: isStale),
  );
});

/// localDataScope の変化を購読し、認証確定で drain＋背景 pull、ログアウトで
/// pull 重複防止状態をリセットする（H-02）。`ref.listen` を保持するため、
/// 誰か（app 側や tests）がこの provider を read/watch している間だけ有効。
final sessionSyncProvider = Provider<void>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  final refresher = ref.watch(sessionRefresherProvider);
  ref.listen<LocalDataScope>(
    localDataScopeProvider,
    (prev, next) {
      if (next is LocalDataScopeAuthenticated) {
        coordinator.onAuthenticated();
        refresher.onAuthenticated(next.ownerId);
      } else if (next is LocalDataScopeUnauthenticated) {
        refresher.reset();
      }
    },
    fireImmediately: true,
  );
});

/// [entityTable] を所有するリポジトリの `adoptServerEntity` へ委譲する
/// （R8-A 再レビュー: サーバー採用を失敗安全にする seam）。所有リポジトリが
/// なければ通信・保存に触れず [Err] を返す（競合は未解決のまま維持される）。
Future<Result<void>> _adoptServerEntityRouter(
  Ref ref,
  String entityTable,
  String entityId,
) {
  if (_genbaTables.contains(entityTable)) {
    return ref
        .read(genbaRepositoryProvider)
        .adoptServerEntity(entityTable, entityId);
  }
  if (_memoryTables.contains(entityTable)) {
    return ref
        .read(memoryRepositoryProvider)
        .adoptServerEntity(entityTable, entityId);
  }
  if (_oshiTables.contains(entityTable)) {
    return ref
        .read(oshiRepositoryProvider)
        .adoptServerEntity(entityTable, entityId);
  }
  if (_templateTables.contains(entityTable)) {
    return ref
        .read(templateRepositoryProvider)
        .adoptServerEntity(entityTable, entityId);
  }
  if (_itineraryTables.contains(entityTable)) {
    return ref
        .read(itineraryRepositoryProvider)
        .adoptServerEntity(entityTable, entityId);
  }
  return Future.value(
    Err(UnknownFailure(message: '未知のテーブル $entityTable は採用できません')),
  );
}

const _genbaTables = {
  'genbas',
  'tickets',
  'transports',
  'lodgings',
  'todos',
  'genba_memos',
};
const _memoryTables = {
  'memory_entries',
  'memory_photos',
  'setlist_items',
  'goods_items',
  'visited_places',
};
const _oshiTables = {'oshi_groups', 'oshi_members', 'oshi_anniversaries'};
const _templateTables = {'todo_templates', 'todo_template_items'};
const _itineraryTables = {
  'itinerary_plans',
  'itinerary_spots',
  'itinerary_spot_links',
  'itinerary_entries',
  'itinerary_legs',
};

/// 競合(conflict)状態の Outbox 操作をユーザー選択で解決する（E-1 / R8-A）。
///
/// - サーバー採用: **先に**当該エンティティのサーバー最新内容を取得・強制適用し、
///   成功してから競合opを削除する（失敗安全 / R8-A 再レビュー）。
/// - この端末を再送: サーバー現在版を取得して版キャッシュを整合 → op を
///   pending へ戻す → drain。
/// owner分離は OutboxStore の owner 限定メソッドと `_ownerId` で担保する。
final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return ConflictResolver(
    store: ref.watch(outboxStoreProvider),
    db: ref.watch(databaseProvider),
    fetchRemoteRows: (tableName) async {
      final client = _remoteClientOrNull(ref);
      if (client == null) return const [];
      final rows = await client.from(tableName).select().withRemoteTimeout();
      return rows.cast<Map<String, dynamic>>();
    },
    adoptServerEntity: (entityTable, entityId) =>
        _adoptServerEntityRouter(ref, entityTable, entityId),
    drain: () => ref.read(syncEngineProvider).drain(),
  );
});

/// 現在ownerの競合一覧（解決UI用）。未認証時は空。
final conflictsProvider = FutureProvider<List<OutboxOperation>>((ref) async {
  // Outbox の変化に追随して競合一覧を再取得する（解決後に消えるように）。
  final counts = ref.watch(outboxStatusProvider).valueOrNull ?? const {};
  final scope = ref.watch(localDataScopeProvider);
  if (scope is! LocalDataScopeAuthenticated) return const [];
  if ((counts[OutboxStatus.conflict] ?? 0) == 0) return const [];
  return ref.read(conflictResolverProvider).conflicts(ownerId: scope.ownerId);
});

/// 写真アップロード境界（デモモードでは null = アップロード不可）。
final photoUploaderProvider = Provider<MemoryPhotoUploader?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabasePhotoUploader(
    client,
    ref.watch(clockProvider),
    ref.watch(imageStoreProvider),
  );
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const DemoAccountRepository();
  return SupabaseAccountRepository(client);
});
