/// アプリの実行環境設定。
///
/// `--dart-define-from-file=.env.<flavor>.json` で注入された値を解決する。
/// Supabase 環境値が未設定の場合、development のみ「デモモード」として
/// ローカル完結で起動できる（本番・stagingでは起動時に明示的に失敗させる）。
enum Flavor { development, staging, production }

class AppEnv {
  const AppEnv({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.logLevelName,
  });

  final Flavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String logLevelName;

  /// Supabase 環境値が揃っているか。
  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project-ref') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon');

  /// デモモード（development かつ Supabase 未設定のときのみ許可）。
  bool get isDemoMode => flavor == Flavor.development && !hasSupabaseConfig;

  static AppEnv fromDartDefine(Flavor flavor) {
    return AppEnv(
      flavor: flavor,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      logLevelName:
          const String.fromEnvironment('LOG_LEVEL', defaultValue: 'info'),
    );
  }

  String get appTitle => switch (flavor) {
        Flavor.development => '推し活遠征管理（dev）',
        Flavor.staging => '推し活遠征管理（stg）',
        Flavor.production => '推し活遠征管理',
      };
}
