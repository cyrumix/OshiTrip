# ADR-0002: バックエンドに Supabase を採用

- 状態: 承認済み（ユーザー承認 2026-07-01）
- 日付: 2026-07-01
- 関連要件: §7.8, §10, §15.2, §15.3, §16.1

## 背景 / 課題

認証、RDB、画像ストレージ、リアルタイム共有、Push通知、サーバー側の認可（行単位・項目単位）を満たすバックエンドを選定する。データモデルは強い関係性（1現場 ↔ チケット/交通/宿泊/Todo/メモ/思い出/マイ推し、共有公演マスタDB）を持つ。

## 選択肢

1. **Supabase** — Postgres + RLS、Storage（認可付き）、Realtime、Auth、Edge Functions。関係モデル・サーバー側認可・SQLによる重複判定に適合。RLSはpgTAPで自動テスト可能。
2. **Firebase** — Firestore(NoSQL) + Auth + Storage + FCM + Security Rules。FCM統合は強いが、関係性の強い公演DB・項目単位共有・重複統合をNoSQLで表現/テストするのが難しい。
3. 自前API（例: Node/Go + Postgres） — 柔軟だが運用/工数増、MVPには過剰。

## 決定

**Supabase** を採用する。理由:

- データモデルが強く関係的で Postgres が自然（§7, §10）。
- §15.2「共有権限のサーバー側検証」「ユーザー単位データ分離」「画像への認可付きアクセス」を **RLS + Storage ポリシー**で強制でき、**pgTAPで自動テスト可能**（Phase 0 完了条件「認可ポリシーを自動テストできる基盤」に直結）。
- §10 公演DBの重複判定（グループ/日付/会場/開演時間）、登録者数集計、閾値未満の匿名化、管理者修正/通報がSQL/Edge Functionで実装しやすい。
- Push（§16.1 FCM/APNs）はバックエンド非依存で FCM を直接利用（ADR-0009）。

## 影響

- 環境ごとに独立したSupabaseプロジェクトを用意（ADR-0007）。
- スキーマ・所有権・RLS・インデックスは `supabase/migrations/` で管理し、`supabase/tests/`（pgTAP）で認可を検証。
- 集計・重複統合・通報・少人数閾値マスキングは Edge Functions / SQL で実装。
- クライアントは `supabase_flutter` を利用（バージョンはSDK導入後に固定）。

## 検証方法

- `supabase/tests/` の pgTAP で、他ユーザーの現場/チケット/画像に到達不可、閲覧のみ権限で書込不可、管理者のみ公演マスタ修正可、を検証。
- CIで Supabase ローカル（`supabase start`）に対しマイグレーション適用＋pgTAP実行。
