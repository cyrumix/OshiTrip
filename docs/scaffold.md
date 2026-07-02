# プロジェクトscaffold定義（Phase 0）

Flutter SDK 導入後に、本定義どおりプロジェクトを生成する。ツールチェーン未導入のため Phase 0 では**定義のみ**を確定し、生成・lock固定は導入後に行う（[setup.md](setup.md) 参照）。

## 1. 生成コマンド

```powershell
# リポジトリ直下（oshi-expedition-app/）で実行。既存 docs/.github/.gitignore は保持。
flutter create --org jp.co.gaxi.oshi --project-name oshi_expedition `
  --platforms=android,ios --description "推し活遠征管理アプリ" .

# flavor 別エントリと bootstrap は本定義（下記 3, 4）に従い追加する。
```

## 2. pubspec.yaml（依存の意図。バージョンは導入時に `flutter pub add` で解決・lock固定）

```yaml
name: oshi_expedition
description: "推し活遠征管理アプリ"
publish_to: none
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # 状態管理 (ADR-0003)
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  # ルーティング (ADR-0004)
  go_router: ^14.0.0
  # バックエンド (ADR-0002)
  supabase_flutter: ^2.5.0
  # ローカル永続化/オフライン (ADR-0005)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  # Push (ADR-0009)
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0
  # 値オブジェクト/モデル
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  # 画像・ユーティリティ
  image_picker: ^1.1.0
  intl: ^0.19.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.18.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  generate: true   # l10n（日本語基準）
```

> バージョンは目安。導入時に `flutter pub get` で解決し **pubspec.lock をコミット**する（[.gitignore](../.gitignore) は lock を除外しない）。プラグインの最低OS要求が [ADR-0006](adr/0006-minimum-os-versions.md)（iOS15 / Android API26）を上回る場合はADRを改訂。

## 3. ディレクトリ構成

[architecture.md §3](architecture.md) の構成に一致させる（`lib/core`, `lib/app`, `lib/features/*`, `supabase/{migrations,tests,functions}`, `test/`, `integration_test/`）。

## 4. flavor / エントリポイント

- `lib/bootstrap.dart`: 共通初期化（Supabase init、エラーハンドラ、DI）。
- `lib/main_development.dart` / `main_staging.dart` / `main_production.dart`: 各flavorのエントリ。`--dart-define-from-file=.env.<flavor>.json` を前提に `core/config` で env を解決。
- Android: `android/app/build.gradle` に `flavorDimensions` + `productFlavors { development, staging, production }`、`minSdk 26`、`applicationIdSuffix`。
- iOS: Xcode Scheme/Config を flavor 対応（macOS工程、[setup.md](setup.md)）。

## 5. Phase 0 で用意する最小プレースホルダー

- 起動確認用の1画面（アプリ名 + 現在flavor表示）。プロダクト機能は作り込まない（Phase 0 指示）。
- `test/` に最小の単体テスト1件、Widgetテスト1件（CIの緑化確認用）。
- `supabase/migrations/0001_init.sql`（拡張有効化 + `profiles` 雛形 + RLS 有効化のひな型）と `supabase/tests/0001_rls_smoke.sql`（pgTAP スモーク）。

## 6. Analysis options

`analysis_options.yaml` に `flutter_lints` を導入し、`prefer_const`, `require_trailing_commas` などを有効化。センシティブ情報のログ出力を避けるため、独自の禁止フィールド検査は `core/logging` のテストで担保（[ADR-0008](adr/0008-authorization-and-data-protection.md)）。
