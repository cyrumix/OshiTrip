import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// アプリテーマ「夜明け前の遠征ノート」（design-spec §1/§2）。
///
/// - Primary #7B5CFF は主要操作・選択状態・残日数・現在地の強調に限定する。
/// - 推しカラーはアクセント（罫線・リング・小面積装飾）に限定し、
///   本文文字のコントラストを壊さない（§2/§15.4）。
/// - ダークは色反転ではなく、同じ情報階層を暗色面へ変換する（§2）。
/// - タップ領域は Material 既定の 48dp を最低として維持する（§3）。
class AppTheme {
  /// Primary（design-spec §2）。
  static const primary = Color(0xFF7B5CFF);

  /// ライトテーマの画面背景（Background）。
  static const lightBackground = Color(0xFFF8F6FC);

  /// 見出し・本文の主テキスト（Text Primary）。
  static const lightTextPrimary = Color(0xFF29212E);

  static ThemeData light() {
    const tokens = AppTokens.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: tokens.primarySoft,
      onPrimaryContainer: const Color(0xFF31207A),
      surface: Colors.white,
      onSurface: lightTextPrimary,
      onSurfaceVariant: tokens.textSecondary,
      outlineVariant: tokens.divider,
      surfaceContainerHighest: const Color(0xFFF1EEF7),
      surfaceContainerHigh: const Color(0xFFF4F1FA),
      surfaceContainerLow: const Color(0xFFFBFAFE),
    );
    return _base(scheme, tokens, scaffoldBackground: lightBackground);
  }

  static ThemeData dark() {
    const tokens = AppTokens.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(
      // ダーク面ではやや明るい紫にして文字コントラストを確保する（§2 AA）。
      primary: const Color(0xFFB7A4FF),
      onPrimary: const Color(0xFF2A1A66),
      primaryContainer: tokens.primarySoft,
      onPrimaryContainer: const Color(0xFFE6DEFF),
      surface: const Color(0xFF1D1824),
      onSurface: const Color(0xFFEDE9F4),
      onSurfaceVariant: tokens.textSecondary,
      outlineVariant: tokens.divider,
      surfaceContainerHighest: const Color(0xFF2E2839),
      surfaceContainerHigh: const Color(0xFF282232),
      surfaceContainerLow: const Color(0xFF211B2B),
    );
    return _base(scheme, tokens, scaffoldBackground: const Color(0xFF141019));
  }

  static ThemeData _base(
    ColorScheme scheme,
    AppTokens tokens, {
    required Color scaffoldBackground,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      extensions: [tokens],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: tokens.primarySoft,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: false,
      ),
      // 影は控えめにし、境界は背景差＋1px相当の境界で表現する（§4）。
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: scheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.divider),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(color: tokens.divider),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  /// 推しカラー（#RRGGBB 文字列）をアクセント用に解決する。
  /// 解析できない場合はテーマのプライマリを返す。
  static Color accentFromHex(String? hex, ColorScheme scheme) {
    final parsed = tryParseHexColor(hex);
    return parsed ?? scheme.primary;
  }

  /// #RRGGBB を [Color] へ解析する（不正なら null）。
  static Color? tryParseHexColor(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
