# 開発環境セットアップ

対象: iOS／Android（Flutter / Dart）。主開発環境: Windows。バックエンド: Supabase。
関連: [architecture.md](architecture.md) / [ADR](adr/) / [CI](../.github/workflows/ci.yml)

> **現在のツール状態（2026-07-02, `flutter doctor -v` で確認）**: Flutter SDK
> （stable 3.44.4）/ Dart SDK（3.12.2）は `C:\src\flutter` に導入済みで、
> `flutter pub get` / `dart format` / `dart analyze` / `flutter test` /
> `dart run` は**利用可能**（非ASCIIパス環境では `flutter analyze` ではなく
> `dart analyze` を使う。下の注記）。**Android SDK は未導入**（`flutter doctor`
> が `Unable to locate Android SDK` を報告）で、実機/エミュレータ向け
> Android ビルドは本マシンでは未確認。**macOS/iOS のビルド環境（Xcode）は
> 本マシン（Windows）には無く未確認**。どちらも下記の手順で導入・確認し、
> [implementation-status.md](implementation-status.md) を更新すること。
> flavor設定自体の静的検証（ビルド不要）は
> `dart run tool/verify_flavor_config.dart` で実行できる（§5）。

---

## 1. 前提ツール（Windows）

| ツール | 用途 | 状態 |
|---|---|---|
| Git | バージョン管理 | ✅ 導入済み |
| Flutter SDK（stable） | Flutter/Dart | ✅ 導入済み（`C:\src\flutter`, 3.44.4） |
| Dart SDK | pub get/format/analyze/test/run | ✅ 利用可能（Flutter SDK 同梱, 3.12.2） |
| JDK 17（推奨） | Androidビルド（Gradle） | ⚠️ 未確認。**Android Gradle Plugin は JDK 17 を推奨**。導入後 `flutter config --jdk-dir` で指定推奨 |
| Android Studio + Android SDK（cmdline-tools, platform-tools, platform 35, build-tools） | Androidビルド/エミュレータ | ❌ 未導入（`flutter doctor` で `Unable to locate Android SDK` を確認済み） |
| Xcode（macOS必須） | iOSビルド・署名・提出 | ❓ 未確認（本マシンはWindowsのため導入不可。macOS実機/CIが必要, §6） |
| Supabase CLI | ローカルDB/マイグレーション/pgTAP | ❌ 未導入 |
| （任意）Docker Desktop | `supabase start` のローカルスタック | ❌ 未導入 |

## 2. Flutter / Android の導入

Flutter/Dart SDK は導入済み（`C:\src\flutter`）。**Android SDK が未導入**の
環境で Android ビルド/エミュレータを使うには以下を実施する:

```powershell
# 1) Android Studio（Android SDK 同梱）を導入
winget install --id Google.AndroidStudio -e

# 2) Android ライセンス同意
flutter doctor --android-licenses

# 3) 診断（Android toolchain が ✓ になることを確認）
flutter doctor -v
```

Flutter SDK 自体を新規に導入する場合は公式手順に従う
（https://docs.flutter.dev/get-started/install/windows。winget例:
`winget install --id Google.Flutter -e`）。

## 3. 環境変数 / 秘密情報

- [.env.example](../.env.example) を `.env.development` 等へコピーして値を設定（gitignore 済み）。
- Flutter へは `--dart-define-from-file=.env.<flavor>.json` で注入。
- `google-services.json` / `GoogleService-Info.plist` はコミットしない（[.gitignore](../.gitignore)）。
- **service_role キーやサーバー秘密はアプリ／リポジトリに置かない**（§15.2）。

## 4. Supabase（ローカル & 認可テスト）

```powershell
# Supabase CLI 導入
winget install --id Supabase.CLI -e   # または scoop / 公式バイナリ

# ローカルスタック起動（要 Docker）→ マイグレーション適用 → pgTAP
supabase start
supabase db reset                     # supabase/migrations を適用
supabase test db                      # supabase/tests の pgTAP（RLS/認可）を実行
```

RLS/認可テスト基盤（[ADR-0008](adr/0008-authorization-and-data-protection.md)）は Phase 2 以降でテーブルと同時に拡充する。Phase 0 では枠組み（`supabase/migrations/`, `supabase/tests/` とCI連携）を用意する。

## 5. よく使うコマンド

```powershell
flutter pub get
dart format --set-exit-if-changed .
dart analyze                          # 非ASCIIパス環境では flutter analyze の代わりにこちら（§1注記）
flutter test                          # 単体 + Widget（利用可能・Android/iOS SDK不要）
dart run tool/verify_flavor_config.dart   # flavor設定の静的検証（ビルド不要, H-01/M-02, §7参照）
flutter build apk --flavor development --debug -t lib/main_development.dart --dart-define-from-file=.env.development.json  # Android SDKが必要
```

> `--flavor <name>` と `-t lib/main_<name>.dart` は必ず組で指定する
> （development/staging/production, H-01）。組合せが崩れたビルドは
> `core/config/flavor_guard.dart` の起動時ガードが拒否する
> （README.md「flavor（環境）とビルドコマンドの対応」参照）。
> `tool/verify_flavor_config.dart` は Android/iOS のビルドを行わず、
> Gradle・xcconfig・Xcode Scheme・pbxproj・Dart entryの静的な整合性
> （bundle ID・APP_DISPLAY_NAME・FLUTTER_TARGET・configuration名）だけを
> 検証する。CIの `windows` ジョブで実行される。

## 6. iOS（macOS 必須工程 §16.2）

Windows では iOS 最終ビルド・署名・提出は不可。**Mac 実機または macOS CI** を使用する。
development/staging/production 用の共有 Xcode Scheme と xcconfig は
`ios/Runner.xcodeproj/xcshareddata/xcschemes/` / `ios/Flutter/` に用意済み
（H-01/M-02, decisions.md）。iOS 最低バージョンは 15.0（ADR-0006）。

```bash
# macOS 上
flutter build ios --flavor development --no-codesign \
  -t lib/main_development.dart \
  --dart-define-from-file=.env.development.json
```

CI では GitHub Actions の `macos-latest` ランナーで無署名 iOS ビルド＋テストを実行する（[ci.yml](../.github/workflows/ci.yml)）。
**利用可能な macOS 実行環境（GitHub Actions macOS ランナー or Mac 実機）が確保できるまで、Phase 0 の iOS ビルド完了条件はブロッカー**として残す。

## 7. Phase 0 完了条件と現状

| 完了条件 | 現状 |
|---|---|
| Windowsで依存解決・静的解析・テスト成功 | ✅ 完了（`flutter pub get` / `dart format` / `dart analyze` / `flutter test`） |
| flavor設定（Android/iOS 3flavor）の静的検証成功 | ✅ 完了（`dart run tool/verify_flavor_config.dart`, ビルド不要） |
| Androidデバッグビルド成功 | ⛔ 未実行（Android SDK 未導入。§2参照） |
| macOS CI で無署名iOSビルド＋テスト成功 | ⛔ 未実行（macOS 実行環境が必要 = ブロッカー。§6参照） |
| 技術選定・データ保護境界のADR記録 | ✅ 完了（[adr/](adr/)） |
| 全要件のPhase/非MVP割当（未割当0） | ✅ 完了（[requirements-traceability.md](requirements-traceability.md)） |
| 認可ポリシーの自動テスト基盤が動作 | 🟡 設計・枠組み定義済み。実行はSupabase CLI導入後 |
