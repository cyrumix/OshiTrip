# アーキテクチャ設計書

版: 1.0（Phase 0）
対象: iOS／Android（Flutter / Dart）
バックエンド: Supabase
関連: [要件定義書](requirements.md) / [ADR](adr/) / [トレーサビリティ](requirements-traceability.md)

> 本書はPhaseごとにADR確定に合わせて更新する。矛盾が生じた場合は要件定義書 → ADR → 本書の順に優先する。

---

## 1. 全体像

```text
┌──────────────────────────── Flutter App (iOS / Android) ────────────────────────────┐
│                                                                                       │
│  Presentation                State                    Domain            Data          │
│  ┌───────────────┐           ┌──────────────┐         ┌──────────┐      ┌───────────┐ │
│  │ Screens/Widgets│──watch──▶│ Riverpod      │──call──▶│ UseCase / │──▶ │ Repository │ │
│  │ (go_router)    │◀─state───│ Notifiers     │◀────────│ Entity    │◀── │ (interface)│ │
│  └───────────────┘           └──────────────┘         └──────────┘      └─────┬─────┘ │
│                                                                               │        │
│                                        ┌──────────────────────────────────────┴──────┐ │
│                                        │ Data sources                                │ │
│                                        │  • Remote: Supabase (Postgres/Storage/RT)   │ │
│                                        │  • Local:  Drift (SQLite) cache + outbox     │ │
│                                        │  • Push:   FCM (+ APNs)                       │ │
│                                        └───────────────────────────────────────────── │
└───────────────────────────────────────────────────────────────────────────────────────┘
                                                │ HTTPS / WSS (RLS enforced)
                                                ▼
┌──────────────────────────────── Supabase (per-flavor project) ────────────────────────┐
│  Auth │ Postgres + Row Level Security │ Storage (authorized) │ Realtime │ Edge Functions │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

サーバー側（Postgres RLS / Storage ポリシー / Edge Functions）を**信頼境界**とする。クライアントUIのガードは利便性であり、認可の最終判断ではない（要件 §7.8, §15.2）。

---

## 2. レイヤリングと依存方向

依存は上位（presentation）→下位（data）への一方向のみ。逆方向は禁止。

| レイヤ | 責務 | 主な構成 |
|---|---|---|
| **presentation** | 画面、Widget、ルーティング、入力バリデーション（UI用） | `lib/features/<feature>/presentation/` |
| **application (state)** | ユースケース調整、画面状態、楽観更新、再試行 | Riverpod `Notifier`/`AsyncNotifier` |
| **domain** | エンティティ、値オブジェクト、リポジトリ抽象、ドメインルール（状態遷移・日時判定） | `lib/features/<feature>/domain/` |
| **data** | リポジトリ実装、DTO、リモート/ローカルデータソース、マッピング | `lib/features/<feature>/data/` |
| **core** | 横断機能（エラー型、Result、ネットワーク、ロガー、時刻、env、認可クライアント） | `lib/core/` |

`domain` は Flutter/Supabase に非依存（純Dart）に保ち、テスト容易性を確保する。

---

## 3. ディレクトリ構成（feature-first）

```text
lib/
  main.dart                      # flavor別エントリから呼ぶ共通起動
  main_development.dart          # flavor: development
  main_staging.dart              # flavor: staging
  main_production.dart           # flavor: production
  bootstrap.dart                 # DI/初期化/エラーハンドラ設定
  app/
    app.dart                     # MaterialApp.router, テーマ, ロケール(ja基準)
    router.dart                  # go_router 定義, リダイレクト(認証/チュートリアル)
    theme/                       # ライト/ダーク, 推しカラー, コントラスト保証
  core/
    config/                      # Flavor, Env読込, SupabaseConfig
    error/                       # Failure/AppException, Result型
    network/                     # Supabaseクライアント, 接続監視, 再試行
    logging/                     # ロガー(センシティブ情報マスキング)
    auth/                        # 認可ヘルパ(現在ユーザー/権限判定のUI補助)
    time/                        # Clock抽象, タイムゾーン, 日跨ぎ/深夜公演判定
    sync/                        # Outbox, 楽観更新, オフラインキュー
    widgets/                     # 共通UI(空状態/エラー/ローディング/バナー)
  features/
    onboarding/                  # チュートリアル(§4)
    auth/                        # 登録・ログイン(§14)
    home/                        # ホーム/当日ホーム(§6)
    genba/                       # 現場: 作成/詳細/状態(§7) — ticket/transport/lodging/todo/memo
    itinerary/                   # 現場の計画: spot/entry/leg/map連携(§7.9)
    memory/                      # 思い出(§8)
    oshi/                        # マイ推し(§9)
    performance_db/              # ユーザー投稿型公演DB(§10)
    sharing/                     # 共有・権限(§7.8)
    notifications/               # 通知(§11)
    settings/                    # 設定(§13)
  l10n/                          # 日本語基準の文言リソース
test/                            # 単体/Widget
integration_test/                # 統合
supabase/
  migrations/                    # SQLマイグレーション(所有権/RLS/インデックス)
  tests/                         # pgTAP による RLS/認可テスト
  functions/                    # Edge Functions(集計/重複統合/通報 等)
```

`genba` 配下はチケット・交通・宿泊・Todo・メモを子モジュールとして持つが、いずれも「1現場」に属する集約として設計する（要件の中心単位＝1現場, §1）。

---

## 4. 状態管理

**採用: Riverpod（`flutter_riverpod` + `riverpod_generator`）** — [ADR-0003](adr/0003-state-management-riverpod.md)。

- 画面状態は `AsyncNotifier`/`Notifier` で表現し、`AsyncValue` で loading/data/error/**empty** を明示的に扱う（空状態は要件で重要: 一覧・思い出・現場なし時）。
- 依存注入はProviderで行い、テストでは `overrideWith` で差し替える。
- 楽観更新（Todo完了、思い出入力など）はNotifier内で行い、失敗時にロールバックしOutboxへ退避（§7）。

## 5. ルーティング

**採用: go_router** — [ADR-0004](adr/0004-routing-go-router.md)。

- 宣言的ルート＋`redirect`で「未認証→ログイン」「チュートリアル未完了→オンボーディング」を制御（§4.1 完了状態保存）。
- ディープリンク（通知タップ→対象入力画面, §8.3/§11）を名前付きルート＋パラメータで受ける。
- タブシェル（ホーム/現場/思い出/マイ推し/設定, §5）は `StatefulShellRoute` で状態保持。

## 6. API / Repository 境界

- `domain` に純粋な `abstract interface class XxxRepository` を定義。`data` に `SupabaseXxxRepository` を実装。
- リポジトリは **Result型**（`Result<T, Failure>`）を返し、例外を上位へ素通ししない。ネットワーク/認可/バリデーション/競合の各Failureを型で区別する。
- DTO（Supabase行 ↔ JSON）とドメインエンティティを分離し、マッピング層で変換。センシティブ項目はDTO→ログ出力時にマスク。
- 読み取りは **ローカルキャッシュ優先→バックグラウンド同期**（§15.3）。書き込みは即ローカル反映→Outbox→サーバー同期（§15.3 自動保存/通信復旧後同期）。
- Places／Routesは`itinerary` domainから直接呼ばず、`PlacesGateway`／`RoutesGateway`抽象をapplication層から利用する。Web Service用Google APIキーはクライアントへ置かず、認証・クォータ・Field Mask allowlistを持つEdge Function等のサーバー境界から呼ぶ（[ADR-0010](adr/0010-google-maps-platform.md)）。
- Google DTOを永続ドメインへ漏らさず、欠落フィールドを許容するアプリ内スナップショットへ変換する。手動データと外部取得データのsource・取得日時・stale状態を区別する。

## 7. ローカルキャッシュ / オフライン

**採用: Drift（SQLite）** — [ADR-0005](adr/0005-local-persistence-drift.md)。

- 当日重要情報（チケット表示メタ、座席/整理番号、開場・開演・終演、交通、宿泊, §6.2）をローカルへキャッシュし、オフライン閲覧可能にする。
- 保存済み旅程、スポット、ユーザー画像サムネイル、最後に取得した経路概要もローカルへ保持する。Google検索、Google写真の新規取得、経路再計算はオフライン対象外だが、手動旅程の閲覧・編集を止めない。
- **Outboxパターン**: 変更をローカルにコミット＋未同期キューへ。接続回復で冪等に再送（`client_mutation_id` で二重送信防止, §15.3 再試行）。
- チケット**画像**はSupabase Storageの署名付きURLで取得し、端末側は認可付きキャッシュに保存。画像バイト列はログに出さない（§15.2）。
- 外部チケットサービスへのリンクと保存済みチケット画像はデータモデル上も別項目として区別（§6.2）。

## 8. 環境分離（flavors）

**dev / staging / production の3環境** — [ADR-0007](adr/0007-environment-separation.md)。

- Flutter flavor（`--flavor`）＋ `--dart-define-from-file` でビルド時に環境注入。実行時は `core/config` が解決。
- 各環境に**独立したSupabaseプロジェクト**（URL/anon key）を割り当て、本番データと開発データを混在させない。
- 秘密情報はリポジトリに置かず、`.env.<flavor>`（gitignore）とCIシークレットで供給。テンプレートは [.env.example](../.env.example)。

## 9. エラー表現

- `core/error/failure.dart`: `Failure`（sealed）— `NetworkFailure` / `AuthFailure` / `PermissionFailure` / `ValidationFailure` / `ConflictFailure` / `NotFoundFailure` / `UnknownFailure`。
- `core/error/result.dart`: `sealed Result<T>` = `Ok<T>` | `Err<Failure>`。
- UIは `AsyncValue`＋共通の `ErrorView`/`EmptyView`/`RetryBanner`（`core/widgets`）で loading/empty/error/offline を一貫表示。
- 未捕捉例外は `bootstrap.dart` の `FlutterError.onError` / `runZonedGuarded` / `PlatformDispatcher.onError` で集約し、マスキング済みで記録。

## 10. 日時処理

- `core/time/clock.dart` の `Clock` 抽象を全所で使用（テストで固定時刻を注入）。`Date.now()`相当を直接呼ばない。
- 端末タイムゾーン基準で現場状態（予定/準備中/本日/余韻中/思い出/中止, §7.1）を判定。日跨ぎ・深夜公演・複数公演・日程変更・中止を状態機械で表現。
- 判定ロジックは `domain` の純関数に置き、単体テストで境界（0時またぎ、終演後→余韻中、翌日→思い出移行）を網羅。

## 11. セキュリティ / 認可（クライアント側の位置づけ）

- クライアントの権限判定（オーナー/編集可/閲覧のみ, §7.8）はUX最適化のためのみ。**強制はサーバー（RLS/Storageポリシー/Edge Function）**で行う — [ADR-0008](adr/0008-authorization-and-data-protection.md)。
- ロガーはチケット画像・座席・整理番号・予約番号・住所・交通/宿泊詳細を**マスクまたは除外**（§15.2）。`core/logging` に禁止フィールドのリストを持ち、テストで検証。
- 認可の**自動テスト基盤**は `supabase/tests`（pgTAP）で、行単位・項目単位・管理者権限のポリシーを検証する（Phase 0 完了条件）。

## 12. テスト戦略

| 種別 | 対象 | 場所 |
|---|---|---|
| 単体 | domain（状態遷移/日時/バリデーション）、mapping、Result | `test/` |
| Widget | 画面の loading/empty/error/data、片手操作、a11yラベル | `test/` |
| 統合 | 主要フロー（現場作成→当日→思い出）、オフライン→同期 | `integration_test/` |
| DB/認可 | RLS・Storageポリシー・所有権・管理者権限 | `supabase/tests/`（pgTAP） |

CIは Windows（analyze/format/unit/widget/Android build）と macOS（iOS build 無署名）で実行する — [CI設定](../.github/workflows/ci.yml)、[setup.md](setup.md)。

---

## 13. Phase 0 時点の未確定・次Phaseへの申し送り

- Drift/Supabase等の**依存バージョンとlockファイル**はFlutter SDK導入後に確定（現状ツールチェーン未導入。[setup.md](setup.md) 参照）。
- 認証方式の詳細（メール＋パスワード / OAuth / Magic Link）はPhase 1（auth）でADR化。Phase 0 では Supabase Auth 採用のみ確定。
- 通知の具体的スケジューリング（サーバー/端末ローカルの分担）はPhase（notifications）でADR化。
