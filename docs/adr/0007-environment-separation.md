# ADR-0007: 環境分離（development / staging / production）

- 状態: 承認済み
- 日付: 2026-07-01
- 関連要件: §15.2, §16

## 背景 / 課題

開発・検証・本番でデータとキーを分離し、秘密情報をリポジトリに置かない構成が必要。

## 決定

3環境（**development / staging / production**）を Flutter flavor で分離する。

- エントリ: `main_development.dart` / `main_staging.dart` / `main_production.dart` が共通 `bootstrap()` を呼ぶ。
- 環境値はビルド時に `--flavor <name> --dart-define-from-file=.env.<name>.json` で注入し、`core/config` が解決。
- **環境ごとに独立したSupabaseプロジェクト**（URL/anon key/Storageバケット）を割り当て、本番と開発データを混在させない。
- FCMも環境別プロジェクト/送信元を分離。
- 秘密情報はリポジトリ非格納。ローカルは `.env.<flavor>`（gitignore）、CIはシークレット注入。テンプレートは [.env.example](../../.env.example)。

## 影響

- Android: `productFlavors { development, staging, production }`、アプリID接尾辞で共存インストール可。
- iOS: Scheme/Config を flavor 対応（SDK導入時に設定）。
- リリースは production flavor のみ。

## 検証方法

- 各flavorでビルドが成功し、誤った環境のキーが混入しないこと（CIのビルドマトリクスで確認、ツールチェーン導入後）。
- リポジトリに秘密情報が含まれないことを `.gitignore` とシークレットスキャンで担保。
