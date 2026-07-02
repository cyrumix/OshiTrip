# 開発環境セットアップ

対象: iOS／Android（Flutter / Dart）。主開発環境: Windows。バックエンド: Supabase。
関連: [architecture.md](architecture.md) / [ADR](adr/) / [CI](../.github/workflows/ci.yml)

> **Phase 0 ブロッカー**: 現在この開発マシンには **Flutter SDK / Dart SDK / Android SDK が未導入**です（Git・Java 24 は導入済み）。
> そのため Phase 0 完了条件のうち「Windowsでの依存解決・静的解析・テスト・Androidデバッグビルド」および「macOS CIでのiOSビルド／テスト」は**未実行**です。
> 本手順に沿ってツールチェーンを導入後に実行し、[implementation-status.md](implementation-status.md) を更新してください。

---

## 1. 前提ツール（Windows）

| ツール | 用途 | 状態 |
|---|---|---|
| Git | バージョン管理 | ✅ 導入済み（2.50） |
| JDK 17（推奨） | Androidビルド（Gradle） | ⚠️ 現在 Java 24。**Android Gradle Plugin は JDK 17 を推奨**。JDK 17 を用意し `flutter config --jdk-dir` で指定推奨 |
| Flutter SDK（stable） | Flutter/Dart | ❌ 未導入 |
| Android Studio + Android SDK（cmdline-tools, platform-tools, platform 35, build-tools） | Androidビルド/エミュレータ | ❌ 未導入 |
| Supabase CLI | ローカルDB/マイグレーション/pgTAP | ❌ 未導入 |
| （任意）Docker Desktop | `supabase start` のローカルスタック | ❌ 未導入 |

## 2. Flutter / Android の導入

```powershell
# 1) Flutter SDK（stable）を導入し PATH を通す（例: C:\src\flutter\bin）
#    公式手順に従うのが確実: https://docs.flutter.dev/get-started/install/windows
#    winget 例:
winget install --id Google.Flutter -e        # 環境により提供状況が異なる場合あり

# 2) Android Studio（Android SDK 同梱）を導入
winget install --id Google.AndroidStudio -e

# 3) Android ライセンス同意
flutter doctor --android-licenses

# 4) 診断（すべて ✓ を目標）
flutter doctor -v
```

導入後、本リポジトリの Flutter プロジェクトを生成する（[implementation-status.md](implementation-status.md) の「Phase 0 残タスク」参照。scaffold 定義は [scaffold.md](scaffold.md)）。

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

## 5. よく使うコマンド（プロジェクト生成後）

```powershell
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test                          # 単体 + Widget
flutter build apk --flavor development --debug --dart-define-from-file=.env.development.json
```

## 6. iOS（macOS 必須工程 §16.2）

Windows では iOS 最終ビルド・署名・提出は不可。**Mac 実機または macOS CI** を使用する。

```bash
# macOS 上
flutter build ios --flavor development --no-codesign \
  --dart-define-from-file=.env.development.json
```

CI では GitHub Actions の `macos-latest` ランナーで無署名 iOS ビルド＋テストを実行する（[ci.yml](../.github/workflows/ci.yml)）。
**利用可能な macOS 実行環境（GitHub Actions macOS ランナー or Mac 実機）が確保できるまで、Phase 0 の iOS ビルド完了条件はブロッカー**として残す。

## 7. Phase 0 完了条件と現状

| 完了条件 | 現状 |
|---|---|
| Windowsで依存解決・静的解析・テスト・Androidデバッグビルド成功 | ⛔ 未実行（Flutter/Android SDK 未導入） |
| macOS CI で無署名iOSビルド＋テスト成功 | ⛔ 未実行（macOS 実行環境が必要 = ブロッカー） |
| 技術選定・データ保護境界のADR記録 | ✅ 完了（[adr/](adr/)） |
| 全要件のPhase/非MVP割当（未割当0） | ✅ 完了（[requirements-traceability.md](requirements-traceability.md)） |
| 認可ポリシーの自動テスト基盤が動作 | 🟡 設計・枠組み定義済み。実行はSupabase CLI+Flutter導入後 |
