import 'package:flutter/material.dart';

/// アプリテーマ（ライト/ダーク両対応・アクセシブル）。
///
/// - 推しカラーはアクセント（バッジ・チップ等）に限定し、
///   本文文字のコントラストを壊さない（§15.4）。
/// - タップ領域は Material 既定の 48dp を最低として維持する。
class AppTheme {
  static const seed = Color(0xFFE85A8A); // 推し活らしい落ち着いたピンク

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: false,
      ),
      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 推しカラー（#RRGGBB 文字列）をアクセント用に解決する。
  /// 解析できない場合はテーマのプライマリを返す。
  static Color accentFromHex(String? hex, ColorScheme scheme) {
    if (hex == null) return scheme.primary;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return scheme.primary;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return scheme.primary;
    return Color(0xFF000000 | value);
  }
}
