import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../features/auth/data/demo_auth_repository.dart';
import '../features/auth/data/supabase_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/genba/data/genba_repository_impl.dart';
import '../features/genba/domain/genba_repository.dart';
import '../features/memory/data/memory_repository_impl.dart';
import '../features/memory/data/supabase_photo_uploader.dart';
import '../features/memory/domain/memory_repository.dart';
import '../features/oshi/data/oshi_repository_impl.dart';
import '../features/oshi/domain/oshi_repository.dart';
import '../features/settings/data/supabase_account_repository.dart';
import '../features/settings/domain/account_repository.dart';
import 'config/env.dart';
import 'db/app_database.dart';
import 'logging/app_logger.dart';
import 'network/connectivity.dart';
import 'storage/kv_store.dart';
import 'sync/outbox_operation.dart';
import 'sync/outbox_store.dart';
import 'sync/remote_mutation_client.dart';
import 'sync/supabase_remote_mutation_client.dart';
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

final connectivityProvider =
    Provider<ConnectivityObserver>((_) => const AlwaysOnlineConnectivity());

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
  return SupabaseRemoteMutationClient(client);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    store: ref.watch(outboxStoreProvider),
    remoteResolver: () => ref.read(remoteMutationClientProvider),
    connectivity: ref.watch(connectivityProvider),
    logger: ref.watch(loggerProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// 同期状態サマリ（バナー表示用）。
final outboxStatusProvider = StreamProvider<Map<OutboxStatus, int>>(
  (ref) => ref.watch(outboxStoreProvider).watchStatusCounts(),
);

String? _ownerId(Ref ref) {
  final user = ref.read(authRepositoryProvider).currentUser;
  return user?.id;
}

final genbaRepositoryProvider = Provider<GenbaRepository>((ref) {
  return GenbaRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => _ownerId(ref),
    remoteResolver: () {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null || user.isDemo) return null;
      return ref.read(supabaseClientProvider);
    },
  );
});

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => _ownerId(ref),
  );
});

final oshiRepositoryProvider = Provider<OshiRepository>((ref) {
  return OshiRepositoryImpl(
    db: ref.watch(databaseProvider),
    outbox: ref.watch(outboxStoreProvider),
    syncEngine: ref.watch(syncEngineProvider),
    clock: ref.watch(clockProvider),
    ownerIdResolver: () => _ownerId(ref),
  );
});

/// 写真アップロード境界（デモモードでは null = アップロード不可）。
final photoUploaderProvider = Provider<MemoryPhotoUploader?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabasePhotoUploader(client, ref.watch(clockProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const DemoAccountRepository();
  return SupabaseAccountRepository(client);
});
