// flavor構成（Android Gradle / iOS Xcode scheme・xcconfig・pbxproj）が
// core/config/flavor_guard.dart の許可リスト（唯一の真実）と一致し、
// development/staging/production の各flavorで
// Debug/Profile/Release configuration・bundle ID・APP_DISPLAY_NAME・
// FLUTTER_TARGET が過不足なく揃っていることを静的に検証する（H-01/M-02, R4）。
//
// Android SDK / Xcode が無くても実行できる、ファイル内容のみを見る静的検証。
// 実際に `flutter build`/Gradle/Xcode でビルドが通ることの代わりにはならない
// （それらは別途、実機/実環境で確認すること）。
//
// 実行: dart run tool/verify_flavor_config.dart
// CI:   .github/workflows/ci.yml の windows ジョブから呼ばれる。

import 'dart:io';

import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/config/flavor_guard.dart';

const _flavors = ['development', 'staging', 'production'];

const _flavorByName = {
  'development': Flavor.development,
  'staging': Flavor.staging,
  'production': Flavor.production,
};

/// iOS の xcconfig ファイル名（flavor名の先頭大文字）。
String _xcconfigName(String flavor) =>
    '${flavor[0].toUpperCase()}${flavor.substring(1)}.xcconfig';

void main() {
  final errors = <String>[];

  _checkAndroidGradle(errors);
  _checkAndroidStrings(errors);
  _checkIosXcconfig(errors);
  _checkIosSchemes(errors);
  _checkIosPbxproj(errors);
  _checkEntryPoints(errors);

  if (errors.isNotEmpty) {
    stderr.writeln(
      'flavor構成の静的検証に失敗しました（${errors.length}件）:',
    );
    for (final e in errors) {
      stderr.writeln('  - $e');
    }
    exit(1);
  }
  stdout.writeln(
    'flavor構成の静的検証: OK '
    '(${_flavors.length} flavors x Android/iOS, スキーム/xcconfig/pbxproj整合)',
  );
}

String _readOrError(String path, List<String> errors) {
  final f = File(path);
  if (!f.existsSync()) {
    errors.add('ファイルが存在しません: $path');
    return '';
  }
  return f.readAsStringSync();
}

// ---------------------------------------------------------------------------
// Android: build.gradle.kts の productFlavors + applicationId が
// flavor_guard.dart の許可リストと一致するか。
// ---------------------------------------------------------------------------
void _checkAndroidGradle(List<String> errors) {
  const path = 'android/app/build.gradle.kts';
  final text = _readOrError(path, errors);
  if (text.isEmpty) return;

  final baseIdMatch = RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(text);
  if (baseIdMatch == null) {
    errors.add('$path: applicationId の定義が見つかりません');
    return;
  }
  final baseId = baseIdMatch.group(1)!;

  for (final flavor in _flavors) {
    final blockMatch = RegExp(
      'create\\("$flavor"\\)\\s*\\{([\\s\\S]*?)\\n\\s{8}\\}',
    ).firstMatch(text);
    if (blockMatch == null) {
      errors.add('$path: productFlavors に "$flavor" のブロックが見つかりません');
      continue;
    }
    final block = blockMatch.group(1)!;
    final suffixMatch =
        RegExp(r'applicationIdSuffix\s*=\s*"([^"]+)"').firstMatch(block);
    final nativeId =
        suffixMatch == null ? baseId : '$baseId${suffixMatch.group(1)}';

    final flavorEnum = _flavorByName[flavor]!;
    if (!matchesFlavor(flavorEnum, nativeId)) {
      errors.add(
        '$path: flavor "$flavor" の applicationId "$nativeId" が '
        'flavor_guard.dart の許可リストに無い',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Android: 各flavorのアプリ表示名リソースが存在するか。
// ---------------------------------------------------------------------------
void _checkAndroidStrings(List<String> errors) {
  for (final flavor in _flavors) {
    final path = 'android/app/src/$flavor/res/values/strings.xml';
    final text = _readOrError(path, errors);
    if (text.isEmpty) continue;
    if (!RegExp(
      r'<string\s+name="app_name">[^<]+</string>',
    ).hasMatch(text)) {
      errors.add('$path: <string name="app_name"> が見つからないか空です');
    }
  }
}

// ---------------------------------------------------------------------------
// iOS: 各flavorのxcconfigが PRODUCT_BUNDLE_IDENTIFIER・APP_DISPLAY_NAME・
// FLUTTER_TARGET を過不足なく持つか。
// ---------------------------------------------------------------------------
void _checkIosXcconfig(List<String> errors) {
  for (final flavor in _flavors) {
    final path = 'ios/Flutter/${_xcconfigName(flavor)}';
    final text = _readOrError(path, errors);
    if (text.isEmpty) continue;

    final bundleIdMatch =
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+)\s*$', multiLine: true)
            .firstMatch(text);
    if (bundleIdMatch == null) {
      errors.add('$path: PRODUCT_BUNDLE_IDENTIFIER が見つかりません');
    } else {
      final bundleId = bundleIdMatch.group(1)!;
      final flavorEnum = _flavorByName[flavor]!;
      if (!matchesFlavor(flavorEnum, bundleId)) {
        errors.add(
          '$path: PRODUCT_BUNDLE_IDENTIFIER "$bundleId" が '
          'flavor_guard.dart の許可リストに無い',
        );
      }
    }

    final displayNameMatch =
        RegExp(r'APP_DISPLAY_NAME\s*=\s*(.+)$', multiLine: true)
            .firstMatch(text);
    if (displayNameMatch == null || displayNameMatch.group(1)!.trim().isEmpty) {
      errors.add('$path: APP_DISPLAY_NAME が見つからないか空です');
    }

    final expectedTarget = 'lib/main_$flavor.dart';
    final targetMatch =
        RegExp(r'FLUTTER_TARGET\s*=\s*(\S+)\s*$', multiLine: true)
            .firstMatch(text);
    if (targetMatch == null) {
      errors.add(
        '$path: FLUTTER_TARGET が見つかりません（Xcode から直接 Run/Archive '
        'すると lib/main.dart にフォールバックする）',
      );
    } else if (targetMatch.group(1) != expectedTarget) {
      errors.add(
        '$path: FLUTTER_TARGET が "${targetMatch.group(1)}" だが '
        '"$expectedTarget" である必要があります',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// iOS: 各flavorの共有Schemeが、対応する Debug-<flavor>/Profile-<flavor>/
// Release-<flavor> configuration を参照しているか。
// ---------------------------------------------------------------------------
void _checkIosSchemes(List<String> errors) {
  for (final flavor in _flavors) {
    final path = 'ios/Runner.xcodeproj/xcshareddata/xcschemes/$flavor.xcscheme';
    final text = _readOrError(path, errors);
    if (text.isEmpty) continue;

    void checkAction(String tag, String expectedConfig) {
      final tagMatch = RegExp('<$tag\\b([^>]*)>').firstMatch(text);
      if (tagMatch == null) {
        errors.add('$path: <$tag> が見つかりません');
        return;
      }
      final attrs = tagMatch.group(1)!;
      final confMatch =
          RegExp(r'buildConfiguration\s*=\s*"([^"]*)"').firstMatch(attrs);
      if (confMatch == null) {
        errors.add('$path: <$tag> に buildConfiguration が指定されていません');
        return;
      }
      if (confMatch.group(1) != expectedConfig) {
        errors.add(
          '$path: <$tag> の buildConfiguration が "${confMatch.group(1)}" '
          'だが "$expectedConfig" である必要があります',
        );
      }
    }

    checkAction('TestAction', 'Debug-$flavor');
    checkAction('LaunchAction', 'Debug-$flavor');
    checkAction('AnalyzeAction', 'Debug-$flavor');
    checkAction('ProfileAction', 'Profile-$flavor');
    checkAction('ArchiveAction', 'Release-$flavor');
  }
}

// ---------------------------------------------------------------------------
// iOS: project.pbxproj に9つの Debug/Release/Profile-<flavor> configuration
// （PBXProjectレベル + Runnerターゲットレベルの計2件ずつ）が存在し、
// Runnerターゲット側は正しいflavor xcconfigを baseConfigurationReference で
// 参照しているか。また、Runnerターゲット側に PRODUCT_BUNDLE_IDENTIFIER が
// ハードコードされていない（xcconfig側のみが真実である）ことを確認する。
// ---------------------------------------------------------------------------
void _checkIosPbxproj(List<String> errors) {
  const path = 'ios/Runner.xcodeproj/project.pbxproj';
  final text = _readOrError(path, errors);
  if (text.isEmpty) return;

  const buildTypes = ['Debug', 'Release', 'Profile'];
  for (final buildType in buildTypes) {
    for (final flavor in _flavors) {
      final name = '$buildType-$flavor';
      final startPattern = RegExp('/\\* ${RegExp.escape(name)} \\*/ = \\{');
      final starts = startPattern.allMatches(text).toList();
      if (starts.length != 2) {
        errors.add(
          '$path: configuration "$name" は PBXProject/Runnerターゲット双方に '
          '1件ずつ（計2件）必要ですが ${starts.length}件見つかりました',
        );
        continue;
      }

      final expectedXcconfig = _xcconfigName(flavor);
      var foundCorrectBaseConfig = false;
      for (final start in starts) {
        final closeIdx = text.indexOf('\n\t\t};', start.end);
        if (closeIdx == -1) {
          errors.add('$path: configuration "$name" の終端が見つかりません');
          continue;
        }
        final block = text.substring(start.end, closeIdx);
        final baseConfigMatch = RegExp(
          r'baseConfigurationReference = \S+ /\* (\S+) \*/;',
        ).firstMatch(block);
        if (baseConfigMatch != null) {
          if (baseConfigMatch.group(1) == expectedXcconfig) {
            foundCorrectBaseConfig = true;
          } else {
            errors.add(
              '$path: configuration "$name" の baseConfigurationReference が '
              '"${baseConfigMatch.group(1)}" だが "$expectedXcconfig" '
              'である必要があります',
            );
          }
        }
        // Runner ターゲット側（baseConfigurationReference を持つ方）に
        // PRODUCT_BUNDLE_IDENTIFIER がハードコードされていないこと
        // （xcconfig 側のみを真実にする, decisions.md D-100）。
        if (baseConfigMatch != null &&
            block.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
          errors.add(
            '$path: configuration "$name" に PRODUCT_BUNDLE_IDENTIFIER が '
            'ハードコードされています（xcconfig側のみを真実にすること）',
          );
        }
      }
      if (!foundCorrectBaseConfig) {
        errors.add(
          '$path: configuration "$name" のいずれのブロックにも '
          'baseConfigurationReference = ".../$expectedXcconfig" が '
          '見つかりません',
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Dart entry: main_<flavor>.dart が存在し、対応する Flavor を bootstrap する
// こと。汎用 lib/main.dart は development 専用として固定されていること
// （main_development.dart と同一内容）。
// ---------------------------------------------------------------------------
void _checkEntryPoints(List<String> errors) {
  for (final flavor in _flavors) {
    final path = 'lib/main_$flavor.dart';
    final text = _readOrError(path, errors);
    if (text.isEmpty) continue;
    if (!text.contains('bootstrap(Flavor.$flavor)')) {
      errors.add('$path: bootstrap(Flavor.$flavor) の呼び出しが見つかりません');
    }
  }

  const mainPath = 'lib/main.dart';
  final mainText = _readOrError(mainPath, errors);
  if (mainText.isNotEmpty &&
      !mainText.contains('bootstrap(Flavor.development)')) {
    errors.add(
      '$mainPath: development 専用の汎用エントリである必要があります '
      '（bootstrap(Flavor.development) が見つかりません）',
    );
  }
}
