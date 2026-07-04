# 実装状況

基準: [要件定義書](requirements.md) / [トレーサビリティ](requirements-traceability.md) / [実装プロンプト集](implementation-prompts.md)

> **2026-07-04 R8監査での訂正**: 本ファイルは長らく「Flutter SDK未導入」時点（Phase 0）の記述のまま更新されておらず、R1〜R7完了後の実態と大きく乖離していた。以下のPhase 0節の「未実装/ブロッカー」表・テスト結果は**2026-07-02時点の記録として履歴保持**するが、現在は解消済み。最新状態は本ファイル末尾の「R8監査時点の実態（2026-07-04）」を参照すること。

---

## Phase 0: 技術設計と土台 — 状態（2026-07-02時点の記録）: 🟡 部分完了（ビルド系はブロッカーで未達）

実施日: 2026-07-01

### 決定事項（承認済み）

| 項目 | 決定 | ADR |
|---|---|---|
| クライアント | Flutter / Dart | [ADR-0001](adr/0001-flutter-client.md) |
| バックエンド | **Supabase**（ユーザー承認） | [ADR-0002](adr/0002-backend-supabase.md) |
| 状態管理 | Riverpod | [ADR-0003](adr/0003-state-management-riverpod.md) |
| ルーティング | go_router | [ADR-0004](adr/0004-routing-go-router.md) |
| ローカル永続化/オフライン | Drift（SQLite）+ Outbox | [ADR-0005](adr/0005-local-persistence-drift.md) |
| 最低OS | iOS 15.0 / Android API 26（8.0） | [ADR-0006](adr/0006-minimum-os-versions.md) |
| 環境分離 | development / staging / production（flavor + 別Supabaseプロジェクト） | [ADR-0007](adr/0007-environment-separation.md) |
| 認可・データ保護境界 | 所有権 + RLS + 項目単位共有 + Storage認可 + pgTAP検証 | [ADR-0008](adr/0008-authorization-and-data-protection.md) |
| Push | FCM（+ APNs） | [ADR-0009](adr/0009-push-notifications-fcm.md) |

### 実装/作成済み成果物

- Git リポジトリ初期化（`main`）、Flutter向け [.gitignore](../.gitignore)（秘密情報除外含む）
- [architecture.md](architecture.md): レイヤリング、ディレクトリ、状態管理、ルーティング、Repository境界、キャッシュ/オフライン、環境分離、エラー表現、日時処理、認可、テスト戦略
- [ADR 0001–0009](adr/) + [テンプレート](adr/0000-template.md)
- [requirements-traceability.md](requirements-traceability.md): 全節をPhase/非MVPへ割当（**未割当0件**）、非MVPバックログ明示
- [.env.example](../.env.example)（秘密情報なし）＋ [setup.md](setup.md)（導入手順・ブロッカー明記）
- [scaffold.md](scaffold.md): プロジェクト生成定義（pubspec意図・構成・flavor・最小プレースホルダー）
- CI: [.github/workflows/ci.yml](../.github/workflows/ci.yml)（Windows: format/analyze/test/Android build、macOS: 無署名iOSビルド/test、DB: Supabaseマイグレーション+pgTAP）。Flutter/Supabaseプロジェクト生成までは各ジョブを安全にスキップするガード付き。

### 未実装 / ブロッカー

> **重要（Phase 0 完了条件の未達）**: 本開発マシンに **Flutter SDK / Dart SDK / Android SDK が未導入**。加えて **macOS 実行環境（GitHub Actions macOS ランナー or Mac 実機）が未確保**。
> このため以下の完了条件は**未達**であり、Phase 0 を「完了」とはしない。

| 完了条件 | 状態 | 必要アクション |
|---|---|---|
| Windowsで依存解決/静的解析/テスト/Androidデバッグビルド成功 | ⛔ 未達 | [setup.md §2](setup.md) の手順でFlutter+Android SDK導入 → [scaffold.md](scaffold.md) でプロジェクト生成 → CI緑化 |
| macOS CI で無署名iOSビルド＋テスト成功 | ⛔ 未達（ブロッカー） | GitHub Actions macOS ランナー有効化 or Mac実機を用意。確保できるまでブロッカー |
| 技術選定・データ保護境界のADR記録 | ✅ 達成 | — |
| 全要件のPhase/非MVP割当（未割当0） | ✅ 達成 | — |
| 認可ポリシーの自動テスト基盤が動作 | 🟡 枠組み定義済み・未実行 | Supabase CLI導入 → `supabase/tests` pgTAP を実行（[db-authz ジョブ](../.github/workflows/ci.yml)） |

### Phase 0 残タスク（ツールチェーン導入後）

1. Flutter + Android SDK + Supabase CLI 導入（[setup.md](setup.md)）。JDK 17 を Android ビルド用に指定。
2. [scaffold.md](scaffold.md) に従い `flutter create` とflavor/エントリ、最小プレースホルダー画面、最小テストを追加。
3. `supabase/migrations/0001_init.sql` と `supabase/tests/0001_rls_smoke.sql` を追加し pgTAP を実行。
4. Windows CI 一式（format/analyze/test/Android build）を緑化。
5. macOS 実行環境を確保し、無署名 iOS ビルド＋test を実際に成功させる。
6. 本ファイルと [トレーサビリティ](requirements-traceability.md) の §15.1/§16 を「✅ 実行済み」へ更新。

### テスト結果

- 自動テスト: **未実行**（Flutter/Supabase 未導入）。
- 静的解析/フォーマット: **未実行**（同上）。
- 実施できたのはドキュメント/設定の整備のみ。

### 次Phaseへの注意点

- Phase 1 開始の前提として、上記「Phase 0 残タスク」を完了しCIを緑化すること。未導入のまま Phase 1 のコードを書くとローカル検証ができない。
- 認証方式（メール＋パスワード / OAuth / Magic Link）は Phase 1 で ADR 化する（Phase 0 では Supabase Auth 採用のみ確定）。
- センシティブ情報のログ除外（§15.2）は Phase 1 の `core/logging` 実装時にテスト付きで担保する。

---

## 根幹一括実装（2026-07-02） — 状態: ✅ 中心フロー実装・Windows検証済み（一部環境依存の検証は未実行）

「初回起動 → ログイン → 現場登録 → 準備管理 → 当日確認 → 思い出記録」の中心フローを
実行可能な Flutter アプリとして実装した。実装判断は [decisions.md](decisions.md)、
残作業は [follow-up-work.md](follow-up-work.md) を参照。

### 実装済み

- **基盤**: bootstrap（flavor別エントリ/エラーハンドラ集約）、AppEnv（dart-define解決）、
  デモモード（developmentのみ・明示バナー、本番は設定不備で起動停止）、
  Result/Failure、センシティブ情報マスキングロガー（テスト付き）、Clock注入、
  Drift ローカルDB（キャッシュ/下書き/Outbox/KV）、SyncEngine（Outbox→Supabase、
  client_mutation_id 冪等、updated_at LWW + conflict記録）
- **ルーティング**: go_router StatefulShellRoute 5タブ、未認証→ログイン /
  チュートリアル未完了→オンボーディング redirect
- **機能**: オンボーディング(4画面/スキップ可/再表示)、メール+パスワード認証（Supabase Auth / デモ）、
  現場CRUD（状態機械: 予定/準備中/本日/余韻中/思い出/中止、日跨ぎ・深夜公演対応、下書き自動保存）、
  チケット/交通/宿泊/Todo/メモの子データ編集（不要と未登録の区別）、
  ホーム（現場カード: 残日数/未完了Todo/準備状態/次の1アクション、当日モード、余韻中→感想導線）、
  思い出（同一IDで表示区分変更、段階入力: 終演直後/翌日/後日、写真ローカル参照+アップロード境界）、
  マイ推し（グループ/メンバーCRUD、推し区分、現場作成時に選択）、
  設定（テーマ、チュートリアル再表示、ログアウト、アカウント削除RPC境界、アプリ情報）
- **サーバー**: `supabase/migrations/0001〜0005`（profiles/oshi/performances/genba集約/
  memory集約/outbox_operations/Storageポリシー/delete_account RPC。全テーブルRLS+
  子テーブル所有権トリガー）、`supabase/tests/`（pgTAP 22アサーション）
- **境界のみ**: 公演DB検索/共有/通知/写真再試行キュー（follow-up-work.md）

### 検証結果（Windows / Flutter 3.44.4 / Dart 3.12.2）

| 検証 | 結果 |
|---|---|
| `flutter pub get` + `dart run build_runner build` | ✅ 成功（pubspec.lock コミット済み） |
| `dart format` / `dart analyze` | ✅（下記の analyze 注意参照） |
| `flutter test`（単体+Widget） | ✅ 全件成功（結果は最終報告参照） |
| `flutter build apk --flavor development` | ⛔ 未実行（Android SDK / JDK17 未導入） |
| `flutter test integration_test` | ⛔ 未実行（エミュレータ/実機なし。テストは実装済み） |
| `supabase test db`（pgTAP） | ⛔ 未実行（Supabase CLI / Docker 未導入。CI db-authz ジョブで実行） |
| iOS ビルド | ⛔ 未実行（macOS 必須・従来からのブロッカー） |

> 注意: 本マシンではリポジトリパスに非ASCII文字が含まれるため `flutter analyze` が
> analysis server ごと落ちる。`dart analyze` は正常動作（decisions.md 参照）。

## Phase 1 以降（旧計画）

上記の根幹一括実装により、Phase 1〜4 相当の中心機能は実装済み。
残りは [follow-up-work.md](follow-up-work.md) の依存順に沿って進める。

## R1〜R7 修正パッケージ（2026-07-02〜2026-07-04）

`docs/current-program-review-and-remediation-prompts.md` のR1〜R7を実施し、
owner分離・同期ライフサイクル・暗号化・flavor構成・現場状態機械・画像基調UIの
データ契約・design-spec準拠のDesign Systemと主要6領域UIを実装した。
各パッケージの実装判断・受入条件・テスト結果は [decisions.md](decisions.md) の
該当節（D-40〜D-166）を正とする。

## R8監査時点の実態（2026-07-04, Claude Sonnet 5による独立監査）

`docs/fable-post-implementation-review-prompt.md` 準拠の独立監査を実施した。
監査手法・全指摘・重大度判定は [decisions.md「R8 独立監査」節](decisions.md) を参照。

### ツール・実行環境（2026-07-04時点、Windows host）

| ツール | 状態 |
|---|---|
| Flutter SDK / Dart SDK | ✅ 利用可能（`C:\src\flutter`） |
| `dart format` / `dart analyze` | ✅ 利用可能・issues無し |
| `flutter test`（単体+Widget） | ✅ 利用可能・実行済み（358件パス/6件失敗、失敗は全件 `ink_sparkle.frag`/Vulkan の既知環境制約） |
| Android SDK | ❌ 未導入。`flutter build apk` は未実行 |
| Xcode/macOS | ❌ 本機（Windows）には無く未確認。iOSビルドは未実行 |
| Supabase CLI / Docker | ❌ 未導入。`supabase test db` は未実行（pgTAPは静的レビューのみ） |
| 実機・エミュレータ | ❌ 無し。`flutter test integration_test` は未実行 |

「Flutter SDK未導入」という旧Phase 0の記述は誤り（2026-07-02時点で既に解消済みだった）。
Android/iOSビルド・pgTAP実行・integration_testは**環境不足により継続して未実行**であり、
コード不良ではない。

### R8監査結果サマリ

- Critical: 0件
- High: 3件（同期競合(conflict)状態が永久に解消されない／RLS pgTAPカバレッジ欠如／
  Supabase通信のタイムアウト欠如。いずれも `docs/current-program-review-and-remediation-prompts.md`
  §8 のR8-A/R8-B/R8-Cとして Claude Opus 4.8 向けに切り出し済み、未修正）
- Medium: 6件、Low: 6件（詳細はdecisions.md参照）
- 中心フロー（初回起動→ログイン→現場登録→準備→当日→思い出→再起動復元）は
  静的読解でエンドツーエンドの配線を確認済み。実機での動作確認は未実施。
