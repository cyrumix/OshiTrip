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
  /// Primary（HOME刷新: 夜明け前の空の「明るい菫」#6A56D9）。
  static const primary = Color(0xFF6A56D9);

  /// ライトテーマの画面背景（Background = backgroundBottom）。
  static const lightBackground = Color(0xFFF8F6F1);

  /// 見出し・本文の主テキスト（藍墨のインク）。
  static const lightTextPrimary = Color(0xFF251F36);

  static ThemeData light() {
    const tokens = AppTokens.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: tokens.primarySoft,
      onPrimaryContainer: const Color(0xFF2C2070),
      surface: Colors.white,
      onSurface: lightTextPrimary,
      onSurfaceVariant: tokens.textSecondary,
      outlineVariant: tokens.divider,
      surfaceContainerHighest: const Color(0xFFF1EDF7),
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
      // ダーク面ではやや明るい菫にして文字コントラストを確保する（§2 AA）。
      primary: const Color(0xFFB3A5FF),
      onPrimary: const Color(0xFF251A5E),
      primaryContainer: tokens.primarySoft,
      onPrimaryContainer: const Color(0xFFE6DEFF),
      surface: const Color(0xFF1F1B30),
      onSurface: const Color(0xFFECE9F6),
      onSurfaceVariant: tokens.textSecondary,
      outlineVariant: tokens.divider,
      surfaceContainerHighest: const Color(0xFF2C2540),
      surfaceContainerHigh: const Color(0xFF272138),
      surfaceContainerLow: const Color(0xFF211C31),
    );
    return _base(scheme, tokens, scaffoldBackground: const Color(0xFF131020));
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
      // 「叫ばない」タイポグラフィ: 一段小さく・締まった字間で品を出す。
      // 大きさの代わりに太さの差（w700 vs w400）で階層を作る。
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: .1,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: .1,
          height: 1.45,
        ),
        titleSmall: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.6),
        bodyMedium: TextStyle(fontSize: 13.5, height: 1.55),
        bodySmall: TextStyle(fontSize: 12, height: 1.5),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        ),
        labelMedium: TextStyle(fontSize: 11.5, letterSpacing: .2),
        labelSmall: TextStyle(fontSize: 10.5, letterSpacing: .3),
      ),
      appBarTheme: AppBarTheme(
        // AppScaffold の背景グラデーションを透過させる。
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: tokens.primarySoft,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10.5,
            letterSpacing: .2,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : tokens.textSecondary,
          ),
        ),
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
