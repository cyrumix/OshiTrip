# OshiTrip（oshi_trip）

推し活における「現場」（1公演への参加）を中心単位に、予定管理・遠征準備・当日確認・
思い出記録を一体化する iOS / Android アプリ。

```text
初回起動 → ログイン → 現場を登録 → 準備情報を管理
→ 当日に必要情報を即確認 → 終演後に思い出を記録
```

## ドキュメント

- [要件定義書](docs/requirements.md) / [UI・ビジュアルデザイン仕様書](docs/design-spec.md) / [アーキテクチャ設計書](docs/architecture.md) / [ADR](docs/adr/)
- [実装判断の記録](docs/decisions.md) / [実装状況](docs/implementation-status.md) / [後続作業計画](docs/follow-up-work.md)
- [開発環境セットアップ](docs/setup.md) / [要件トレーサビリティ](docs/requirements-traceability.md)

## 技術構成

| 領域 | 採用 |
|---|---|
| クライアント | Flutter（stable 3.44系）/ Dart。iOS 15+ / Android API 26+ |
| 状態管理 | Riverpod（AsyncNotifier / Provider override による DI） |
| ルーティング | go_router（StatefulShellRoute・認証/チュートリアル redirect） |
| バックエンド | Supabase（Auth / Postgres + RLS / Storage） |
| ローカルDB | Drift（SQLite）: キャッシュ・下書き・Outbox |
| モデル | freezed + json_serializable |
| 構成 | feature-first（presentation / application / domain / data + core） |

書き込みは「ローカル反映 → Outbox → リモート同期」（client_mutation_id で冪等・
updated_at による last-write-wins）。認可はサーバー側 RLS が信頼境界
（[ADR-0008](docs/adr/0008-authorization-and-data-protection.md)、pgTAP で自動テスト）。

## 開発ビルドの起動手順

### 1. 前提ツール

- Flutter SDK stable（[setup.md §2](docs/setup.md)。例: `C:\src\flutter`）
- Android Studio + Android SDK（Androidビルド/エミュレータ用）+ JDK 17
- （DB検証用・任意）Supabase CLI + Docker Desktop

> Windows で本リポジトリの絶対パスに非ASCII文字が含まれる場合、`flutter analyze` が
> analysis server のエラーで落ちることがあります。`dart analyze` を使ってください
> （[decisions.md](docs/decisions.md) の開発環境注意を参照）。

### 2. 依存解決とコード生成

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. flavor（環境）とビルドコマンドの対応（固定, H-01）

**development / staging / production の3flavorは必ず、対応する
`--flavor <name>` と `-t lib/main_<name>.dart` を組で指定します。**
この組合せが崩れたビルド（例: production の applicationId に development
entry で起動）は、`core/config/flavor_guard.dart` の起動時ガードにより
拒否されます（実行中バイナリの applicationId/bundle id と Dart entry 由来の
flavor が一致しない場合、Supabase初期化・デモモードへ進まずエラー画面を表示）。

| flavor | Dart entry | Android applicationId | iOS bundle id | Xcode scheme |
|---|---|---|---|---|
| development | `lib/main_development.dart` | `app.oshitrip.mobile.dev` | `app.oshitrip.mobile.dev` | `development` |
| staging | `lib/main_staging.dart` | `app.oshitrip.mobile.stg` | `app.oshitrip.mobile.stg` | `staging` |
| production | `lib/main_production.dart` | `app.oshitrip.mobile`（接尾辞なし） | `app.oshitrip.mobile`（接尾辞なし） | `production` |

```powershell
# Android
flutter build apk --flavor development --debug -t lib/main_development.dart --dart-define-from-file=.env.development.json
flutter build apk --flavor staging     --debug -t lib/main_staging.dart     --dart-define-from-file=.env.staging.json
flutter build appbundle --flavor production --release -t lib/main_production.dart --dart-define-from-file=.env.production.json
```

```bash
# iOS（macOS 上）
flutter build ios --flavor development -t lib/main_development.dart --dart-define-from-file=.env.development.json
flutter build ios --flavor staging     -t lib/main_staging.dart     --dart-define-from-file=.env.staging.json
flutter build ios --flavor production --release -t lib/main_production.dart --dart-define-from-file=.env.production.json
```

`APP_ENV` のような dart-define での環境識別は使いません（Dart entry と
ネイティブ設定という既存の真実に加えてもう一つ値を作ると、食い違っても
検知できない「二重の真実」になるため。詳細は `.env.example` のコメント）。

### 4. 実行（デモモード = Supabase なしで試す）

Supabase 環境値なしの development ビルドは、明示的な「デモモード」
（端末内のみ保存・任意のメールアドレスでログイン可・バナー常時表示）で起動します。
production / staging はデモモードにならず、設定エラーを表示して停止します。

```powershell
flutter run --flavor development -t lib/main_development.dart
```

### 5. 実行（Supabase に接続する）

1. Supabase プロジェクトを作成し、`supabase/migrations/` を適用
   （ローカルなら `supabase start && supabase db reset`）。
2. `.env.example` を参考に `.env.development.json` を作成（gitignore 済み）:

   ```json
   {
     "SUPABASE_URL": "https://xxxx.supabase.co",
     "SUPABASE_ANON_KEY": "xxxx",
     "LOG_LEVEL": "debug"
   }
   ```

3. 起動:

   ```powershell
   flutter run --flavor development -t lib/main_development.dart `
     --dart-define-from-file=.env.development.json
   ```

## テスト・検証コマンド

```powershell
dart format --set-exit-if-changed .
dart analyze
flutter test                                          # 単体 + Widget
flutter test integration_test --flavor development    # 要エミュレータ/実機
supabase test db                                      # pgTAP（要 Supabase CLI + Docker）
flutter build apk --debug --flavor development -t lib/main_development.dart
```

## ディレクトリ

```text
lib/
  bootstrap.dart            # 共通起動（Supabase init / エラーハンドラ / DI override）
  main_{development,staging,production}.dart
  app/                      # MaterialApp.router / go_router / テーマ
  core/                     # config, error(Result/Failure), db(Drift), sync(Outbox),
                            # logging(センシティブ情報マスキング), time(Clock),
                            # storage(KV/下書き), widgets(空/エラー/同期バナー)
  features/
    onboarding/ auth/ home/ genba/ memory/ oshi/ settings/
    performance_db/ sharing/ notifications/   # 境界のみ（follow-up-work.md）
supabase/
  migrations/               # スキーマ + RLS + Storageポリシー + delete_account RPC
  tests/                    # pgTAP（所有権・子テーブル迂回防止・公演マスタ権限）
test/ integration_test/
```

## iOS について

iOS の最終ビルド・署名・提出には macOS + Xcode が必要（[setup.md §6](docs/setup.md)）。
flavor 用の Xcode Scheme/Config は設定済み（development/staging/production の
共有 Scheme が `ios/Runner.xcodeproj/xcshareddata/xcschemes/` にあり、各
`Debug-<flavor>`/`Release-<flavor>`/`Profile-<flavor>` build configuration を
使う。bundle id は `ios/Flutter/{Development,Staging,Production}.xcconfig` で
分離。iOS 最低バージョンは 15.0, ADR-0006）。macOS 実行環境が無いためこの
リポジトリ上では Xcode でのビルド確認・アーカイブ検証は未実施
（follow-up-work.md）。

## Android リリース署名

`android/key.properties`（.gitignore 済み、`storeFile`/`storePassword`/
`keyAlias`/`keyPassword` を記載）が無い場合、release ビルドは development/
staging に限り debug 署名へフォールバックします。**production の
release（`assembleProductionRelease`/`bundleProductionRelease`）は実署名が
無ければビルド時に明示的に失敗します**（`android/app/build.gradle.kts`）。
CI では同名ファイルをシークレットから生成して供給してください。
