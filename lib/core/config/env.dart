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
    this.googleMapsEnabled = false,
    this.googleMapsApiKey = '',
  });

  final Flavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String logLevelName;

  /// 地図/検索連携の機能フラグ（既定 false）。ADR-0010: 未設定でも手動旅程が
  /// 使えるよう、既定で無効。環境（flavor）ごとに dart-define で切り替える。
  final bool googleMapsEnabled;

  /// **地図SDK（クライアント）用**のAPIキー。環境別・iOS bundle ID/対象API制限
  /// 前提（ADR-0010 §4）。**Web Service 用キーはここへ入れない**（Places/Routes は
  /// 認証済み Edge Function 経由・アプリにキーを埋め込まない, §3）。
  final String googleMapsApiKey;

  /// Supabase 環境値が揃っているか。
  bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project-ref') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon');

  /// デモモード（development かつ Supabase 未設定のときのみ許可）。
  bool get isDemoMode => flavor == Flavor.development && !hasSupabaseConfig;

  /// Places（Autocomplete/Details）が利用可能か。地図/検索の有効化に加え、
  /// Edge Function 経由呼び出しに必要な Supabase 認証基盤が前提（ADR-0010 §3）。
  /// デモ・未設定・無効では false → 呼び出し側は [UnavailableFailure] で手動へ縮退。
  bool get googlePlacesAvailable => googleMapsEnabled && hasSupabaseConfig;

  static AppEnv fromDartDefine(Flavor flavor) {
    return AppEnv(
      flavor: flavor,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      logLevelName:
          const String.fromEnvironment('LOG_LEVEL', defaultValue: 'info'),
      googleMapsEnabled: const bool.fromEnvironment(
        'GOOGLE_MAPS_ENABLED',
        defaultValue: false,
      ),
      googleMapsApiKey: const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    );
  }

  String get appTitle => switch (flavor) {
        Flavor.development => 'OshiTrip Dev',
        Flavor.staging => 'OshiTrip Staging',
        Flavor.production => 'OshiTrip',
      };
}
