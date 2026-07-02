import 'dart:developer' as developer;

/// ログレベル。
enum LogLevel { debug, info, warn, error }

/// センシティブ情報をマスクするロガー（§15.2 / ADR-0008）。
///
/// チケット画像・座席・整理番号・予約番号・住所・交通/宿泊詳細などは
/// キー名ベースでマスクし、値を出力しない。
/// 構造化コンテキストは必ず [log] の `context` に渡すこと
/// （メッセージ文字列へ値を埋め込むと検査できない）。
class AppLogger {
  AppLogger({
    this.minLevel = LogLevel.info,
    void Function(String line)? output,
  }) : _output = output;

  final LogLevel minLevel;
  final void Function(String line)? _output;

  /// マスク対象キー（部分一致・小文字比較）。
  static const List<String> sensitiveKeyPatterns = [
    'seat', '座席',
    'entry_number', 'entrynumber', '整理番号',
    'reservation', '予約番号',
    'address', '住所',
    'image', '画像',
    'password', 'token', 'secret', 'key', 'authorization',
    'depart', 'arrive', 'from_place', 'to_place', // 交通詳細
    'checkin', 'checkout', 'lodging_name', '宿泊',
    'email', 'phone',
    'url',
  ];

  static const String maskText = '***';

  static LogLevel levelFromName(String name) => switch (name.toLowerCase()) {
        'debug' => LogLevel.debug,
        'info' => LogLevel.info,
        'warn' || 'warning' => LogLevel.warn,
        'error' => LogLevel.error,
        _ => LogLevel.info,
      };

  static bool isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return sensitiveKeyPatterns.any(lower.contains);
  }

  /// [context] のセンシティブ値をマスクした安全なマップを返す。
  /// ネストした Map / List も再帰的に処理する。
  static Map<String, Object?> maskContext(Map<String, Object?> context) {
    Object? maskValue(String key, Object? value) {
      if (isSensitiveKey(key)) return maskText;
      return switch (value) {
        final Map<String, Object?> m => maskContext(m),
        final List<Object?> l =>
          l.map((e) => e is Map<String, Object?> ? maskContext(e) : e).toList(),
        _ => value,
      };
    }

    return {
      for (final entry in context.entries)
        entry.key: maskValue(entry.key, entry.value),
    };
  }

  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
  }) {
    if (level.index < minLevel.index) return;
    final masked = maskContext(context);
    final line = '[${level.name}] $message'
        '${masked.isEmpty ? '' : ' $masked'}'
        '${error == null ? '' : ' error=${error.runtimeType}'}';
    if (_output != null) {
      _output(line);
    } else {
      developer.log(line, name: 'oshi', level: _developerLevel(level));
    }
  }

  void debug(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.debug, message, context: context);

  void info(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.info, message, context: context);

  void warn(
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
  }) =>
      log(LogLevel.warn, message, context: context, error: error);

  void error(
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
  }) =>
      log(LogLevel.error, message, context: context, error: error);

  int _developerLevel(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      };
}
