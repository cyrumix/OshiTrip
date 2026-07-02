# 実装判断の記録（根幹一括実装 / 2026-07-02）

要件・ADRで確定していない点について、実装時に行った判断と理由を記録する。
矛盾が見つかった場合は requirements.md → ADR → architecture.md の順に優先して見直すこと。

## アーキテクチャ・依存

| # | 判断 | 理由 |
|---|---|---|
| D-01 | Riverpod は `flutter_riverpod` 2.6 系の手書き Provider / (AutoDispose)AsyncNotifier で統一し、`riverpod_generator` の導入は見送った | ADR-0003 の本質（AsyncValue による状態表現・override による DI/テスト差し替え）は全面採用。codegen 面は freezed / json_serializable / drift_dev で既に大きく、生成器を1つ減らして基盤の見通しを優先した。後続での generator 移行は機械的に可能 |
| D-02 | firebase_core / firebase_messaging は今回追加しない | 通知は「境界と土台」まで（プロンプト§4）。Firebase を依存に入れると google-services.json 無しでビルド不能になり、中心フローの検証を阻害する。境界型は `features/notifications/domain/notification_plan.dart` |
| D-03 | 接続監視は `ConnectivityObserver` 抽象 + 既定は「常時オンライン仮定・失敗時にpending保持」実装。connectivity_plus 等のプラグインは未導入 | 同期エンジンはネットワーク失敗を pending として保持し再poke で回復するため、OSイベント連動は最適化。テストでは `ManualConnectivity` を注入 |
| D-04 | サーバー行 JSON とドメインエンティティの二重定義（DTO層）は作らず、freezed エンティティの snake_case `fromJson/toJson` を Supabase 行 / Outbox payload と共用する | 単一ユーザー所有データで形が完全一致しており、DTO 分離は現段階では意味のない薄いラッパーになる。端末専用フィールド（例: `Ticket.imageLocalPath`）は payload から明示的に除外している |
| D-05 | ローカルDBの共有テーブル定義は `lib/core/db/app_database.dart` に集約 | Drift の DB は1つであり、feature 毎に分割すると part 構成が複雑化する。読み書きは各 feature の data 層のみが行う |
| D-06 | 端末KV（チュートリアル完了・テーマ・デモユーザー）も Drift の `app_kvs` テーブルに保存し、shared_preferences は未導入 | 依存削減。DB は起動時に必ず開かれる |

## ドメイン・時刻

| # | 判断 | 理由 |
|---|---|---|
| D-10 | 開場/開演/終演は「公演日 0:00 からの分数」で保持し、深夜公演は 1440 超（例 25:30 = 1530）で表現。終演≦開演の入力は翌日終演として自動補正 | タイムゾーン変換に依存せず日跨ぎを一意に表現できる。UI では終演入力時に「当日/翌日」を確認 |
| D-11 | 終演予定なしの場合の終演見込み: 開演あり→開演+4時間、時刻なし→公演日の終わり | 保守的仮定。§7.1「終演予定なしを壊さない」ため状態遷移が破綻しない値を採用 |
| D-12 | 余韻中は「終演見込み〜その暦日の終わり」、思い出は「終演日の翌日 0:00 から」 | §8.1「翌日以降は現場一覧・通常ホームに表示しない」に一致。深夜公演（翌1:30終演）は終演翌日から思い出になる |
| D-13 | 「準備中」は公演7日前から | 要件に閾値の定義がないため。`deriveGenbaStatus(preparingWindowDays:)` で変更可能 |
| D-14 | 中止現場は公演日経過後に思い出一覧へ表示（記録として残す） | §8.1 は「終了した現場」を思い出とするが、中止も推し活の記録であり削除しない方針（§18）に沿う |
| D-15 | 公演日は「会場現地の暦日」として端末TZで解釈し、DB上は `yyyy-MM-dd` 文字列。タイムスタンプは UTC ISO8601 | 現場の状態判定は端末TZ基準（architecture §10）。交通の出発/到着は timestamptz（UTC保存・ローカル表示） |

## 同期・データ

| # | 判断 | 理由 |
|---|---|---|
| D-20 | `outbox_operations`（サーバー側）は「適用済み client_mutation_id の記録」として実装 | プロンプト§5 のスキーマ一覧に含まれるため。再送の冪等化（二重適用防止）に使用。クライアント側キュー本体は Drift の `outbox_ops` |
| D-21 | LWW 判定はリモート `updated_at` > payload `updated_at` のとき ConflictFailure とし、Outbox に conflict として記録・自動再送しない（リモート優先） | §5「updated_at による last-write-wins を既定とし、競合記録を残す」。フィールド単位マージへの拡張は Outbox payload がフル行 JSON のため妨げない |
| D-22 | リモート pull（refreshFromRemote）は今回 genba 集約のみ実装。memory / oshi の pull は後続 | push（ローカル→Outbox→リモート）は全エンティティ対応済み。pull は「ホームのキャッシュ先行+背景更新」の実動対象である現場を優先。follow-up-work.md #1 |
| D-23 | pull 時、未同期変更（pending Outbox）がある行はリモートで上書きしない | 自動保存した端末変更を失わないため（§15.3） |
| D-24 | デモモード（development かつ SUPABASE_URL 未設定）ではリモート同期を完全停止し、Outbox は pending のまま保持。UI に「デモモード」バナーを常時表示 | 本番/staging は env 不備で起動を止める（暗黙フォールバック禁止）。デモ→本アカウントへの移行は将来課題 |

## UI・その他

| # | 判断 | 理由 |
|---|---|---|
| D-30 | UI文言は日本語リテラル直書き。gen_l10n（ARB）は未導入 | 単一ロケール（ja）のMVPで抽象化の益が薄い。多言語化時に一括抽出する |
| D-31 | チケットの「画像参照」は `imageLocalPath`（端末参照・同期対象外）と `imagePath`（Storage パス・境界）を分離 | 外部URLと保存画像の区別（§6.2）をデータモデルで担保。画像アップロードは後続 |
| D-32 | メモ（自由/物販/集合場所/周辺/注意）は区分ごとに1件で upsert | UI の即時確認性優先。複数メモが必要になれば unique 制約を外す拡張で対応可能 |
| D-33 | 現場フォームの下書きは `form_drafts` にキー `genba_form_new` / `genba_form_<id>` で自動保存 | §2.1 自動保存・再開。保存成功時に削除 |
| D-34 | 思い出のテキスト系は600msデバウンスの自動保存。「短い感想」は感想本文と同一フィールド | §8.2 の明示要件 |
| D-35 | アカウント削除はサーバー RPC `delete_account()`（SECURITY DEFINER）で auth.users を削除し FK カスケード。デモモードでは明示的に失敗を返す | 未実装処理を成功に見せない（プロンプト§3.6） |

## 開発環境の注意（Windows / 非ASCIIパス）

- 本リポジトリの絶対パスに非ASCII文字が含まれる環境では、`flutter analyze` が
  analysis server の JSON 解析エラーで落ちることがある。**`dart analyze` は正常に動作する**ため
  そちらを使用する（検証済み）。
- Flutter SDK は `C:\src\flutter`（setup.md の推奨に一致）へ導入済み。PUB_CACHE も
  非ASCIIパス回避のため `C:\src\pub_cache` を使用した。
- Windows ホストでの単体テストは OS 同梱の `winsqlite3.dll` へフォールバックして
  SQLite を利用する（`test/helpers/test_db.dart`）。
