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
    required this.heroGradientMid,
    required this.heroGradientEnd,
    required this.heroOverlay,
    required this.favorite,
    required this.dawn,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.todayGradientStart,
    required this.todayGradientMid,
    required this.todayGradientEnd,
  });

  /// 補足・日付・メタ情報のテキスト色（Text Secondary）。
  final Color textSecondary;

  /// 区切り・未選択タブ・カード境界（Divider）。
  final Color divider;

  /// ヒーローカード・選択背景などの淡い紫（Primary Light）。
  final Color primarySoft;

  /// 写真なしヒーローの「夜明け前の空」グラデーション（藍→菫→明るい菫）。
  final Color heroGradientStart;
  final Color heroGradientMid;
  final Color heroGradientEnd;

  /// 写真上の文字可読性を保つ暗めのオーバーレイ色（design-spec §12）。
  /// 黒ではなく夜空の藍＝世界観の統一。
  final Color heroOverlay;

  /// お気に入り（ハート）のアクセント。Error と分離する。
  final Color favorite;

  /// 暁（dawn）。ヒーロー底辺のヘアライン・残7日以下の温度表現・
  /// FABの縁光に使う「夜明けの光」。本文テキストには使わない。
  final Color dawn;

  /// 画面背景の縦グラデーション（上に菫の靄／夜空、下へ静かに晴れる）。
  final Color backgroundTop;
  final Color backgroundBottom;

  /// 当日ヒーローの「明けた空」グラデーション（菫→薔薇→暁）。
  final Color todayGradientStart;
  final Color todayGradientMid;
  final Color todayGradientEnd;

  /// ライトテーマ（デザイン刷新: 明るいラベンダーの面に白カードを浮かべる）。
  ///
  /// textSecondary は白面で AA（4.5:1）以上を維持する値に調整している。
  static const light = AppTokens(
    textSecondary: Color(0xFF716B8A),
    divider: Color(0xFFEDEAF6),
    primarySoft: Color(0xFFEFEBFD),
    heroGradientStart: Color(0xFF9180F0),
    heroGradientMid: Color(0xFF7A64E6),
    heroGradientEnd: Color(0xFF5F49D2),
    heroOverlay: Color(0x8A241C4E),
    favorite: Color(0xFFE85A8A),
    dawn: Color(0xFFF2A98F),
    backgroundTop: Color(0xFFF3F0FB),
    backgroundBottom: Color(0xFFFAF9FE),
    todayGradientStart: Color(0xFF7A5FE0),
    todayGradientMid: Color(0xFFC078AB),
    todayGradientEnd: Color(0xFFE59A7F),
  );

  /// ダークテーマ。色反転ではなく、同じ情報階層を暗色面へ変換する。
  static const dark = AppTokens(
    textSecondary: Color(0xFF9B94B8),
    divider: Color(0xFF322B47),
    primarySoft: Color(0xFF372D5C),
    heroGradientStart: Color(0xFF7C68E4),
    heroGradientMid: Color(0xFF5F49D2),
    heroGradientEnd: Color(0xFF453494),
    heroOverlay: Color(0x99120D2A),
    favorite: Color(0xFFFF8AB0),
    dawn: Color(0xFFE88FA0),
    backgroundTop: Color(0xFF17122A),
    backgroundBottom: Color(0xFF121022),
    todayGradientStart: Color(0xFF6A50D0),
    todayGradientMid: Color(0xFFB06E9E),
    todayGradientEnd: Color(0xFFD98F76),
  );

  @override
  AppTokens copyWith({
    Color? textSecondary,
    Color? divider,
    Color? primarySoft,
    Color? heroGradientStart,
    Color? heroGradientMid,
    Color? heroGradientEnd,
    Color? heroOverlay,
    Color? favorite,
    Color? dawn,
    Color? backgroundTop,
    Color? backgroundBottom,
    Color? todayGradientStart,
    Color? todayGradientMid,
    Color? todayGradientEnd,
  }) {
    return AppTokens(
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      primarySoft: primarySoft ?? this.primarySoft,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientMid: heroGradientMid ?? this.heroGradientMid,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
      heroOverlay: heroOverlay ?? this.heroOverlay,
      favorite: favorite ?? this.favorite,
      dawn: dawn ?? this.dawn,
      backgroundTop: backgroundTop ?? this.backgroundTop,
      backgroundBottom: backgroundBottom ?? this.backgroundBottom,
      todayGradientStart: todayGradientStart ?? this.todayGradientStart,
      todayGradientMid: todayGradientMid ?? this.todayGradientMid,
      todayGradientEnd: todayGradientEnd ?? this.todayGradientEnd,
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
      heroGradientMid: Color.lerp(heroGradientMid, other.heroGradientMid, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
      heroOverlay: Color.lerp(heroOverlay, other.heroOverlay, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      dawn: Color.lerp(dawn, other.dawn, t)!,
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      backgroundBottom:
          Color.lerp(backgroundBottom, other.backgroundBottom, t)!,
      todayGradientStart:
          Color.lerp(todayGradientStart, other.todayGradientStart, t)!,
      todayGradientMid:
          Color.lerp(todayGradientMid, other.todayGradientMid, t)!,
      todayGradientEnd:
          Color.lerp(todayGradientEnd, other.todayGradientEnd, t)!,
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

/// カード角丸の基準（カード18dp・ヒーロー24dp・チップ12dp）。
abstract final class AppRadius {
  static const double card = 18;
  static const double hero = 24;
  static const double chip = 12;
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
