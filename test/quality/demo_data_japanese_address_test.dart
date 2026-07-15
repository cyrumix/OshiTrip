import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// デモデータ・seed・fixture・サンプル・アセットに、ja/JP対応前の**英語表記の
/// 日本語住所**が紛れ込んでいないことを保証する回帰ガード（住所日本語化方針）。
///
/// 背景: Google Places/Routes は `languageCode: ja` / `regionCode: JP` により
/// 日本語優先で取得する。ja/JP対応前に保存された既存**ユーザー**データは自動
/// 上書きしない（尊重する）が、リポジトリに同梱する**デモ/fixture**は日本語
/// 住所へ揃える。ここでは英語住所らしいパターン（`..., Japan` / 英字の郵便番号 /
/// ローマ字の区名・地名＋カンマ）が同梱データに残っていないことを検査する。
///
/// 実ユーザーデータ（端末ローカルDB）はリポジトリ管理外のため本テストの対象外。
void main() {
  // 英語表記の日本語住所を示す代表パターン（施設名 "Tokyo Dome" や
  // タイムゾーン "Asia/Tokyo" を誤検出しないよう、住所文脈に限定する）。
  final bannedPatterns = <RegExp>[
    RegExp(r',\s*Japan\b'), // 整形済み住所の末尾 "..., Japan"
    RegExp(r'\bTokyo\s+\d{3}-\d{4}\b'), // ローマ字の郵便番号付き住所
    RegExp(
      r'\b(Shibuya|Shinjuku|Minato|Chiyoda|Chuo|Chofu|Setagaya|Taito|Sumida|'
      r'Nakano|Dogenzaka|Roppongi|Harajuku|Ikebukuro|Ueno|Akihabara)\s*,',
    ), // ローマ字の区名・地名＋カンマ（住所文脈）
  ];

  /// 検査対象のルート（リポジトリ同梱のデモ/seed/fixture/サンプル/アセット/E2E）。
  /// 生成物（*.g.dart / *.freezed.dart）は対象外。
  ///
  /// `docs` は**意図的に対象外**にする。仕様書・decisions.md は移行方針の説明として
  /// 英語住所の例（`Dogenzaka, Shibuya, Tokyo 150-0043, Japan` 等）を敢えて記載する
  /// ため、ここでスキャンすると説明文を誤検出してしまう。docs は同梱される実行時
  /// データではないので対象から除く。
  const scanRoots = <String>[
    'lib', // アプリ本体（デモ/seed/onboarding固定データを含む）
    'test', // fixture・サンプル・helper
    'integration_test', // E2E のサンプルデータ
    'assets', // 同梱アセット（JSON等）
  ];

  bool isScannable(String path) {
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return false;
    }
    // 本ガードテスト自身は英語トークンを説明目的で含むため除外する。
    if (path.replaceAll('\\', '/').endsWith(
          'test/quality/demo_data_japanese_address_test.dart',
        )) {
      return false;
    }
    return path.endsWith('.dart') ||
        path.endsWith('.json') ||
        path.endsWith('.yaml') ||
        path.endsWith('.yml');
  }

  test('同梱のデモ/seed/fixture/アセットに英語表記の日本語住所が残っていない', () {
    final offenders = <String>[];

    for (final root in scanRoots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !isScannable(entity.path)) continue;
        final content = entity.readAsStringSync();
        for (final pattern in bannedPatterns) {
          final match = pattern.firstMatch(content);
          if (match != null) {
            offenders.add('${entity.path}: "${match.group(0)}"');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '英語表記の日本語住所が同梱データに残っています。日本語住所へ修正してください:\n'
          '${offenders.join('\n')}',
    );
  });
}
