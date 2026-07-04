import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/config/flavor_guard.dart';
import 'core/db/app_database.dart';
import 'core/db/db_key_store.dart';
import 'core/db/encrypted_database.dart';
import 'core/db/encrypted_db_resolver.dart';
import 'core/db/local_data_purge.dart';
import 'core/db/open_verified_database.dart';
import 'core/images/image_store.dart';
import 'core/logging/app_logger.dart';
import 'core/network/network_timeout.dart';
import 'core/providers.dart';

/// 共通起動処理（flavor別エントリポイントから呼ばれる）。
///
/// - Supabase 初期化（development で未設定なら明示的なデモモード）
/// - production / staging で環境値が欠けている場合は起動を失敗させる
///   （デモモードへの暗黙フォールバック禁止）
/// - グローバルエラーハンドリング（センシティブ情報はログへ出さない）
Future<void> bootstrap(Flavor flavor) async {
  final env = AppEnv.fromDartDefine(flavor);
  final logger = AppLogger(
    minLevel: AppLogger.levelFromName(env.logLevelName),
  );

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      logger.error(
        'flutter error',
        context: {'exception': details.exception.runtimeType.toString()},
        error: details.exception,
      );
      if (kDebugMode) FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error(
        'uncaught error',
        context: {'exception': error.runtimeType.toString()},
        error: error,
      );
      return true;
    };

    // Dart entry（main_<flavor>.dart）由来の flavor と、実行中バイナリの実際の
    // applicationId(Android)/bundle id(iOS) が一致するか検証する（H-01）。
    // 「production の applicationId + development entry」等の取り違えビルドを
    // Supabase 初期化・デモモードへ進む前に必ず拒否する（起動時ガード）。
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final nativeId = (await PackageInfo.fromPlatform()).packageName;
      try {
        assertFlavorMatchesNativeId(env.flavor, nativeId);
      } on FlavorMismatchException catch (e) {
        logger.error(
          'flavor/native id mismatch',
          context: {'flavor': env.flavor.name, 'nativeId': e.nativeId},
        );
        runApp(_FlavorMismatchErrorApp(flavor: env.flavor, nativeId: nativeId));
        return;
      }
    }

    if (!env.hasSupabaseConfig && env.flavor != Flavor.development) {
      // 本番/stagingでのデモフォールバックは禁止。設定不備を明示して停止する。
      runApp(_ConfigErrorApp(flavor: env.flavor));
      return;
    }

    if (env.hasSupabaseConfig) {
      await Supabase.initialize(
        url: env.supabaseUrl,
        // 旧形式の anon key を引き続き受け付ける（新 publishable key も同引数で動作）。
        // ignore: deprecated_member_use
        anonKey: env.supabaseAnonKey,
        // 全通信（Auth/PostgREST/Storage/Realtime）にリクエスト単位の共通
        // タイムアウトを課す。無期限ハングで同期・アカウント削除が固まるのを
        // 防ぐ多層防御（R8-C / H-A）。個々の呼び出しにも .withRemoteTimeout()
        // を付けているが、付け忘れてもここで必ず効く。
        httpClient: TimeoutHttpClient(http.Client()),
      );
    } else {
      logger.info('demo mode: Supabase未設定のためローカルのみで起動します');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final imageStore = ImageStore(
      docsDir,
      backupExcluder: (path) => _excludeFromBackup(path, logger),
    );

    // 端末DB暗号化（H-03）: 既存暗号化DBは起動時に鍵で verify し、鍵消失・誤鍵は
    // 鍵を再生成せず明示エラー画面で停止する（平文は温存され再試行できる）。
    final AppDatabase database;
    try {
      database = await _openEncryptedDatabase(env, docsDir);
    } on EncryptionSetupException catch (e) {
      logger.error(
        'db encryption setup failed',
        context: {'stage': e.stage},
        error: e.cause,
      );
      runApp(const _EncryptionErrorApp());
      return;
    }

    // 前回のアカウント削除でローカル purge が未完了なら、ここで完了させる
    // （C-01: サーバー削除済みのユーザーデータ・画像を端末に残さない）。
    await resumePendingAccountPurge(database, imageStore: imageStore);

    runApp(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(env),
          databaseProvider.overrideWithValue(database),
          imageStoreProvider.overrideWithValue(imageStore),
        ],
        child: const OshiExpeditionApp(),
      ),
    );
  }, (error, stack) {
    logger.error(
      'zone error',
      context: {'exception': error.runtimeType.toString()},
      error: error,
    );
  });
}

/// 暗号化DBを解決して開く。既存DBは verify し、初回は平文があれば一度だけ
/// 暗号化DBへ移行する。あらゆる失敗（SQLCipher準備・鍵取得・IO・open）は
/// [EncryptionSetupException] へ変換し、必ずエラー画面に到達させる（成功扱い禁止）。
Future<AppDatabase> _openEncryptedDatabase(AppEnv env, Directory dir) async {
  // SQLCipher の準備（open override 等）。失敗も型付きで停止する。
  try {
    await prepareSqlCipher();
  } catch (e) {
    throw EncryptionSetupException('prepare', e);
  }

  final keyStore = SecureDbKeyStore();
  final resolver = EncryptedDbResolver(
    readExistingKey: keyStore.readRaw,
    getOrCreateKey: keyStore.getOrCreateKey,
    export: sqlCipherExport,
    verify: sqlCipherVerify,
  );

  final EncryptedDbResolution resolution;
  try {
    resolution = await resolver.resolve(
      plaintext: File(p.join(dir.path, 'oshitrip_${env.flavor.name}.sqlite')),
      encrypted:
          File(p.join(dir.path, 'oshitrip_${env.flavor.name}.enc.sqlite')),
    );
  } on EncryptionSetupException {
    rethrow; // resolver が段階付きで投げたものはそのまま。
  } catch (e) {
    // 想定外（型付けされていない）失敗も成功扱いにしない。
    throw EncryptionSetupException('resolve', e);
  }

  // 実際に open して SELECT 1 を走らせ、鍵で復号可能なことを強制確認する
  // （失敗時は接続を閉じて EncryptionSetupException('open') を投げる, item5）。
  return openVerifiedDatabase(
    openEncryptedExecutor(resolution.encrypted, resolution.key),
  );
}

/// 機密ファイルを OS バックアップから除外する（iOS: NSURLIsExcludedFromBackupKey
/// 相当を MethodChannel 経由で設定, H-04）。Android は allowBackup=false を採用
/// するためここでは何もしない。
///
/// iOS/macOS で除外に失敗した場合は例外を伝播させる（成功扱いにしない）。
/// 呼び出し元の [ImageStore.import] がこれを受けて生成ファイルを削除し、
/// UI へ StorageFailure を返す。
const MethodChannel _secureFilesChannel =
    MethodChannel('oshitrip/secure_files');

Future<void> _excludeFromBackup(String path, AppLogger logger) async {
  // Android は allowBackup=false を採用するためここでは何もしない。
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }
  try {
    await _secureFilesChannel.invokeMethod<void>(
      'excludeFromBackup',
      {'path': path},
    );
  } catch (e) {
    logger.warn(
      'backup exclusion failed',
      context: {'exception': e.runtimeType.toString()},
    );
    rethrow; // 失敗を握りつぶさない（機密画像の流出を防ぐ）。
  }
}

/// 端末DB暗号化のセットアップ失敗時の明示的なエラー画面（H-03）。
/// 平文データは温存されており、原因解消後の再起動でやり直せる。
class _EncryptionErrorApp extends StatelessWidget {
  const _EncryptionErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'データ保護の初期化に失敗しました\n\n'
              '端末の暗号鍵の取得またはデータ暗号化に失敗しました。'
              'データは削除されていません。'
              'アプリを再起動してもこの表示が続く場合は、'
              '端末の空き容量やロック解除状態をご確認ください。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// ビルド構成の取り違え（flavor と applicationId/bundle id の不一致）を
/// 検知した場合の明示的なエラー画面（H-01）。デモモードやSupabase初期化へは
/// 進まない。
class _FlavorMismatchErrorApp extends StatelessWidget {
  const _FlavorMismatchErrorApp({required this.flavor, required this.nativeId});

  final Flavor flavor;
  final String nativeId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'ビルド構成エラー\n\n'
              'このアプリは ${flavor.name} 環境向けにビルドされていますが、'
              '実行中のアプリID「$nativeId」と一致しません。\n'
              '正しい組合せ（--flavor ${flavor.name} '
              '-t lib/main_${flavor.name}.dart）で再ビルドしてください。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// 環境値不備で起動できない場合の明示的なエラー画面。
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.flavor});

  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '環境設定エラー\n\n'
              '${flavor.name} 環境の SUPABASE_URL / SUPABASE_ANON_KEY が未設定です。\n'
              '--dart-define-from-file=.env.${flavor.name}.json を指定してビルドしてください。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
