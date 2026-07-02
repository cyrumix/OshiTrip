import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/db/app_database.dart';
import 'core/logging/app_logger.dart';
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
      );
    } else {
      logger.info('demo mode: Supabase未設定のためローカルのみで起動します');
    }

    final database = AppDatabase(await _openExecutor(env));

    runApp(
      ProviderScope(
        overrides: [
          envProvider.overrideWithValue(env),
          databaseProvider.overrideWithValue(database),
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

Future<QueryExecutor> _openExecutor(AppEnv env) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'oshi_${env.flavor.name}.sqlite'));
  return NativeDatabase.createInBackground(file);
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
