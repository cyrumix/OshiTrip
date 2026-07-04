import 'package:flutter/material.dart';

/// 「夜明け前の遠征ノート」の意味ベースDesign Token（design-spec §2/§3）。
///
/// 色は [AppTokens]（ThemeExtension）経由で参照し、画面内へ色コードを
/// 直書きしない。余白・角丸・時間は定数クラスで統一する。
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.textSecondary,
    required this.divider,
    required this.primarySoft,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.heroOverlay,
    required this.favorite,
  });

  /// 補足・日付・メタ情報のテキスト色（Text Secondary）。
  final Color textSecondary;

  /// 区切り・未選択タブ・カード境界（Divider）。
  final Color divider;

  /// ヒーローカード・選択背景などの淡い紫（Primary Light）。
  final Color primarySoft;

  /// 写真なしヒーローのグラデーション（Primary → Primary Light 方向）。
  final Color heroGradientStart;
  final Color heroGradientEnd;

  /// 写真上の文字可読性を保つ暗めのオーバーレイ色（design-spec §12）。
  final Color heroOverlay;

  /// お気に入り（ハート）のアクセント。Error と分離する。
  final Color favorite;

  /// ライトテーマの基準値（design-spec §2 の表）。
  ///
  /// textSecondary は基準 #7D7788 だと白面で 4.32:1 と WCAG AA（4.5:1）を
  /// 満たさないため、同系色のまま #746D80 へ微調整している（§2 の
  /// 「AA相当の文字コントラストを維持」が優先）。
  static const light = AppTokens(
    textSecondary: Color(0xFF746D80),
    divider: Color(0xFFE9E5F0),
    primarySoft: Color(0xFFEEE9FF),
    heroGradientStart: Color(0xFF7B5CFF),
    heroGradientEnd: Color(0xFFA98FFF),
    heroOverlay: Color(0x8A241B38),
    favorite: Color(0xFFE85A8A),
  );

  /// ダークテーマ。色反転ではなく同じ情報階層を暗色面へ変換する（§2）。
  static const dark = AppTokens(
    textSecondary: Color(0xFFA9A1B8),
    divider: Color(0xFF39323F),
    primarySoft: Color(0xFF352B52),
    heroGradientStart: Color(0xFF4A3A8C),
    heroGradientEnd: Color(0xFF6D57C4),
    heroOverlay: Color(0x99120D1F),
    favorite: Color(0xFFFF8AB0),
  );

  @override
  AppTokens copyWith({
    Color? textSecondary,
    Color? divider,
    Color? primarySoft,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    Color? heroOverlay,
    Color? favorite,
  }) {
    return AppTokens(
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      primarySoft: primarySoft ?? this.primarySoft,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      heroOverlay: heroOverlay ?? this.heroOverlay,
      favorite: favorite ?? this.favorite,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      heroGradientStart:
          Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      heroOverlay: Color.lerp(heroOverlay, other.heroOverlay, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
    );
  }

  /// 現在のテーマからトークンを取得する（未登録時はライト基準）。
  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ?? light;
}

/// 4dpグリッドの標準余白（design-spec §3）。
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// カード角丸の基準（design-spec §3: カード12〜16dp、ヒーロー16〜20dp）。
abstract final class AppRadius {
  static const double card = 14;
  static const double hero = 18;
  static const double chip = 8;
}

/// モーションの基準（design-spec §13: 150〜250ms・控えめ）。
abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
}

/// Reduce Motion（OSのアニメーション無効設定）を尊重するヘルパー（§13/§14）。
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// 推しカラーのプリセット（設定 §11: 8色以上 + カスタム）。
/// 値は #RRGGBB。名称はアクセシビリティ用ラベル（色だけに依存しない）。
const oshiColorPresets = <({String name, String hex})>[
  (name: 'ピンク', hex: '#FF5CA8'),
  (name: 'レッド', hex: '#F0426B'),
  (name: 'オレンジ', hex: '#FF7A3C'),
  (name: 'イエロー', hex: '#F5A800'),
  (name: 'グリーン', hex: '#2FA95C'),
  (name: 'エメラルド', hex: '#00B8A9'),
  (name: 'スカイ', hex: '#00A3D9'),
  (name: 'ブルー', hex: '#3D6DFF'),
  (name: 'パープル', hex: '#9B5CFF'),
  (name: 'ホワイト', hex: '#E8E6F0'),
];
