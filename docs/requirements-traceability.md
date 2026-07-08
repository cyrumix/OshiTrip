# 要件トレーサビリティ

版: 2.0（R8監査時点, 2026-07-04）
基準: [要件定義書 v2.1](requirements.md) / [UI・ビジュアルデザイン仕様書](design-spec.md) / [実装判断の記録](decisions.md)

各節を担当Phaseへ割り当てる。**未割当は0件**。状態は 未着手 / 進行中 / 完了 / 非MVP のいずれか。
「実装箇所」「テスト」は実際のファイルパス・テスト名を証拠として記入する。証拠のない項目は完了にしない。

> **2026-07-04 改訂**: 版1.0はPhase 0（旧計画のフェーズ番号）時点の割当表のまま全項目が
> ⬜未着手だった。実際には「根幹一括実装」（2026-07-02）と修正パッケージR1〜R7
> （2026-07-02〜2026-07-04）により大半のMVP機能が実装済みである。本改訂は
> `docs/decisions.md` のD-01〜D-168と、R8独立監査（同ファイル「R8 独立監査」節）の
> 確認結果に基づき、実装箇所・状態を実証結果のみで更新する。旧Phase番号（P0〜P7）の
> 呼称は歴史的経緯として残すが、実装は「根幹一括実装＋R1〜R7」という別の進め方で行われた。

凡例: ⬜未着手 / 🟡進行中（境界のみ・部分実装） / ✅完了（実装＋テスト証拠あり） / 🅱️非MVPバックログ

---

## 横断原則（全Phaseで遵守・検証）

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §1 | プロダクト概要 / 中心単位=1現場 | ✅ | `lib/features/genba/`配下の集約設計（genba×ticket/transport/lodging/todo/memo） | `test/domain/genba_schedule_test.dart`ほか |
| §2.1 | 最小入力・段階的開示 | ✅ | `genba_form_controller.dart`（最小3項目バリデーション、下書き自動保存） | `test/notifier/genba_form_controller_test.dart` |
| §2.2 | 現場を育てる体験 | ✅ | 現場状態機械（`genba_schedule.dart`）＋思い出への段階移行 | `test/domain/genba_schedule_test.dart` |
| §2.3 | 当日の即時性 | ✅ | `TodayCard`（`lib/features/home/presentation/widgets/today_card.dart`）、ローカルDB直読でオフライン表示 | R8監査E章で確認 |
| §2.4 | 非公開を基本 | ✅ | 全ユーザー所有テーブルRLS（`supabase/migrations/0001〜0007`） | `supabase/tests/0001〜0004`（一部pgTAPカバレッジ欠如あり、decisions.md F-2参照） |
| §2.5, §19 | 写真と余韻を中心にした視覚体験 / design-spec準拠 | ✅ | `lib/app/design_system/`、`lib/app/theme/` | `test/widget/design_system_test.dart`ほか |
| §3 | 対象ユーザー（設計前提） | ✅ | 要件・本表で反映 | — |
| §18 | 最重要思想（現場中心） | ✅ | `architecture.md`設計方針、genba集約 | — |

## §4 初回起動・チュートリアル

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §4.1 | 初回チュートリアル（4画面/スキップ/完了状態保存/通知許可を要求しない/設定から再表示） | ✅ | `lib/features/onboarding/` | `test/widget/routing_test.dart`（環境制約で本ホスト未実行、R8-B1参照） |
| §4.2 | 初回現場登録（最小必須3項目） | ✅ | `genba_form_controller.dart`（残日数/次の準備の直後表示は簡略実装） | `test/notifier/genba_form_controller_test.dart` |

## §5 情報設計とグローバルメニュー

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §5 | 5タブ、現場=未来+当日、思い出=過去、移行は表示区分変更 | ✅ | `lib/app/router.dart`（StatefulShellRoute）、`genba_schedule.dart`のisMemory/isUpcoming | `test/widget/app_shell_navigation_test.dart`、`test/domain/genba_schedule_test.dart` |

## §6 ホーム

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §6.1 | 通常時ホーム（近い順/カード項目/準備状態/次アクション） | ✅ | `lib/features/home/presentation/home_screen.dart` | `test/widget/home_screen_hero_test.dart` |
| §6.2 | 当日ホーム（本日モード/キャッシュ/余韻中切替/複数当日公演） | ✅ | `today_card.dart`、`deriveGenbaStatus` | `test/widget/home_screen_hero_test.dart`、`test/domain/genba_schedule_test.dart` |

## §7 現場

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §7.1 | 状態機械（予定/準備中/本日/余韻中/思い出/中止） | ✅ | `lib/features/genba/domain/genba_schedule.dart` | `test/domain/genba_schedule_test.dart`（境界値・深夜公演・手動終演を網羅） |
| §7.2 | 現場作成（最小3項目＋段階追加） | ✅ | `genba_form_screen.dart`/`genba_form_controller.dart` | `test/notifier/genba_form_controller_test.dart` |
| §7.3 | チケット | ✅（画像アップロードは§フェーズB未実装、ローカル参照のみ） | `lib/features/genba/data/genba_repository_impl.dart`、`child_editors.dart` | `test/data/repositories_test.dart` |
| §7.4 | 交通（不要/未登録の区別） | ✅ | `genba_preparation.dart`（`CategoryPrepState`） | R8監査B章で確認 |
| §7.5 | 宿泊（宿泊なし区別） | ✅ | 同上 | 同上 |
| §7.6 | Todo | ✅（テンプレート提案は未実装、follow-up-work.mdフェーズE） | `child_editors.dart`、`genba_actions_controller.dart` | `test/notifier/genba_actions_controller_test.dart` |
| §7.7 | メモ（複数登録・テンプレート） | ✅ **2026-07-07 複数化**（D-199）: 現場ごとに複数メモを作成・編集・削除・並び替え。タイトル/種類/並び順を追加し「現場×種類ごと1件」制約を撤廃。テンプレート5種＋「テンプレートなし」。既存メモは種類名をタイトル初期値に移行 | `GenbaMemo`（title/sortOrder/`MemoCategory.other`）、Drift v12・Supabase `0018_genba_memos_multi.sql`、`genba_repository_impl.dart`（ID単位upsert・`reorderMemos`）、`genba_child_sections.dart`（`MemoTab`）・`child_editors.dart`（`_MemoEditor`） | `test/data/genba_memo_test.dart`（複数保持・並び替え・v11→v12移行）・`test/data/repositories_test.dart`（ID単位upsert）・`test/widget/genba_detail_tabs_test.dart`（空状態）。pgTAP 未追加（Docker未導入） |
| §7.8 | 共有（owner/editor/viewer） | 🟡 境界のみ | `lib/features/sharing/domain/share.dart`（型のみ、data層未実装・未配線） | follow-up-work.mdフェーズC |
| §7.9 | 計画・推し活遠征旅程 | 🟡 **Phase 1基盤＋Phase 2手動旅程UIを実装。Phase 3（Places/地図）・Phase 4（Routes）は未実装のため「旅程MVP」は未完成**。Phase 2で計画タブ・日別タイムライン・手動スポットCRUD・種別つきURL・交通/宿泊の参照追加・手動移動区間・余裕不足警告・オフライン閲覧編集・ユーザー画像を実装（Google検索/地図/経路の見せかけUIは出さない）。共同編集・通知も未実装（Phase 5）。**2026-07-07 Phase 2追補**（D-188〜D-193）: カテゴリ「聖地」(`sacred_place`)追加、緯度・経度の手動入力廃止（列は温存・既存座標保持）、移動区間の日付を前後予定から内部決定（時刻のみ入力）、訪問日の初期値=現在操作中の予定日・新規開始時刻=直前実予定の終了時刻、メモ(note)を時間整合の全警告から除外 | Phase1: `lib/features/itinerary/domain/`・`data/`・`application/itinerary_timeline.dart`、Drift v9: `lib/core/db/app_database.dart`、Supabase: `supabase/migrations/0012_itinerary.sql`・`0013_..._google_ban.sql`・`0014_..._reference_unique.sql`・`0015_..._sacred_place.sql`。Phase2 UI: `lib/features/itinerary/presentation/`（`plan_tab.dart`・`itinerary_editors.dart`・`itinerary_import_and_leg.dart`ほか）、`application/itinerary_actions_controller.dart`、追補の純粋関数 `domain/itinerary_schedule.dart`（`resolveInitialVisitDate`・`resolveInitialStartFromPrevious`・`deriveLegTimestamps`・`effectiveItinerarySchedule`）、`genba_detail_screen.dart`（計画タブ=7タブ目） | domain/data: `test/domain/itinerary_*_test.dart`（追補 `itinerary_phase2b_test.dart`・`itinerary_source_reflection_test.dart`・`itinerary_json_test.dart`「聖地」）・`test/data/itinerary_*_test.dart`（`itinerary_v9_migration_test.dart`ほか）。Phase2 UI: `test/widget/itinerary_plan_tab_test.dart`・`itinerary_editor_phase2b_test.dart`・`genba_detail_tabs_test.dart`、integration: `integration_test/itinerary_offline_encrypted_sync_test.dart`（要実機）。pgTAP: `supabase/tests/0008`・`0009`・`0010`（**未実行**: Docker未導入）。Phase 3/4/5 は `docs/itinerary-implementation-prompts.md` |

## §8 思い出

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §8.1 | 移行（同一ID表示区分変更） | ✅ | `genba_schedule.dart`のisMemory/isUpcoming | `test/domain/genba_schedule_test.dart` |
| §8.2 | 段階入力（終演直後/翌日/後日、任意順） | ✅ | `lib/features/memory/domain/memory.dart`、`memory_edit_screen.dart` | R8監査B章で確認（全フィールド任意・非順序拘束を確認） |
| §8.3 | 入力通知 | ⬜ 境界のみ | `lib/features/notifications/domain/notification_plan.dart`（型のみ、未配線） | — |
| §8.4 | 思い出詳細 | ✅（共有メンバー表示は§7.8同様未実装） | `memory_detail_screen.dart` | `test/widget/memory_detail_view_test.dart`、`test/widget/memory_image_states_test.dart` |
| §8.4 | 思い出アルバム（写真分類・関連項目） | ✅ **2026-07-08**（D-200/D-201）: 写真を `MemoryPhoto` に一本化し `albumCategory`/`subjectType`/`subjectId` を追加。アルバム画面（分類チップ・正方形グリッド・表紙・関連元導線・空状態）、グッズ/行った場所/食べものへの写真添付、行った場所と食べものの追加時分岐、項目削除時の「アルバムに残す（既定）／写真も削除」確認まで実装。ローカル写真ファイルの掃除・DB失敗時の孤立ファイル削除は既存境界を継承 | `MemoryPhoto`／`MemoryBundle`（`photosInAlbum`/`photosForSubject`/`coverPhoto`）、Drift v13・Supabase `0019_memory_photo_album.sql`、`memory_repository_impl.dart`（`_subjectExists` 検証）、`memory_mappers.dart`、`memory_album_screen.dart`（新規）、`memory_edit_screen.dart`（`_ItemsWithPhotosEditor`・場所/食べもの分割）、`memory_detail_screen.dart`（アルバム導線）、`router.dart`（`/memories/:id/album`）、`memory_controllers.dart`（`addPhoto` 拡張） | `test/data/memory_album_test.dart`・`test/data/repositories_test.dart`（関連項目実在検証）・`test/widget/memory_album_screen_test.dart`（分類チップ絞り込み・空状態）・`test/widget/memory_edit_stages_test.dart`（場所/食べもの分割）。pgTAP 未追加（Docker未導入） |

## §9 マイ推し

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §9 | グループ/メンバー/推し区分/カラー/記念日/画像、現場登録中の同時作成 | ✅ | `lib/features/oshi/`、`genba_form_screen.dart`の`_quickAddGroup` | `test/widget/oshi_selection_test.dart`、`test/widget/oshi_screen_stats_test.dart` |

## §10 ユーザー投稿型公演DB

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §10.1 | 基本方針（共通マスタ） | 🟡 境界のみ | `performances`テーブル+RLS（`supabase/migrations/0002`）、`Genba.performanceId` | pgTAPカバレッジ一部欠如（decisions.md F-1） |
| §10.2 | 公演登録・重複判定 | ⬜ 未実装 | インクリメンタル検索・重複候補UIは未着手 | follow-up-work.mdフェーズC |
| §10.3 | 公開とプライバシー | 🟡 部分実装 | RLSポリシーのみ（登録者数集計・閾値マスキングは未実装） | — |
| §10.4 | 信頼性と運用 | ⬜ 未実装 | — | follow-up-work.mdフェーズC |
| — | 外部公演API（§14 MVP対象外） | 🅱️ | [非MVPバックログ](#非mvpバックログ) | — |
| — | 公式メンバーDB（§14 MVP対象外） | 🅱️ | [非MVPバックログ](#非mvpバックログ) | — |

## §11 通知

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §11 | 通知対象一式/FCM/APNs | ⬜ 境界のみ | `NotificationPlan`型のみ、firebase_messaging等未導入 | follow-up-work.mdフェーズD |

## §12 マネタイズ

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §12 | 必要かつ未登録時のみ導線 | ⬜ 未実装 | `GenbaPreparation`が判定材料として利用可能だが導線自体は未実装 | follow-up-work.mdフェーズE |
| §12 | プレミアム候補 | 🅱️ | [非MVPバックログ](#非mvpバックログ) | — |

## §13 設定

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §13 | アカウント/表示・テーマ・推しカラー | ✅ | `lib/features/settings/`（`account_settings_screen.dart`、`theme_settings_screen.dart`、`oshi_color_settings_screen.dart`） | `test/widget/settings_screens_test.dart`、`test/notifier/oshi_color_controller_test.dart` |
| §13 | 通知設定 | ⬜ 未実装 | §11に依存 | — |
| §13 | プライバシー/人数集計参加/共有範囲 | ⬜ 未実装 | §7.8/§10.3に依存 | — |
| §13 | データ出力・削除 | 🟡 部分実装 | `AccountController.deleteAccount`（アカウント削除は実装、データ**出力**は未実装） | `test/notifier/account_controller_test.dart` |
| §13 | チュートリアルをもう一度見る | ✅ | `settings_screen.dart`の「チュートリアルをもう一度見る」行 | R8監査B章で確認 |

## §14 MVP範囲

| 内容 | 状態 |
|---|---|
| MVP機能一式 | 🟡 大半が✅（現場/思い出/マイ推し/設定/同期/認証）。共有・通知・公演DB高度機能・マネタイズは未実装（詳細は各節） |
| MVP対象外 | 🅱️非MVP（下記バックログ） |

## §15 非機能要件

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §15.1 | 対応環境/OS最低バージョン | ✅ | [ADR-0006](adr/0006-minimum-os-versions.md)（iOS 15/Android API 26） | `dart run tool/verify_flavor_config.dart` |
| §15.2 | セキュリティ・プライバシー | 🟡 | RLS全テーブル・SQLCipher暗号化・ログマスキング実装済みだが、R8監査でpgTAPカバレッジ欠如（F-2）とログマスキングのcamelCase欠陥（H-B、本監査で是正済み）を検出 | `supabase/tests/`、`test/core/result_and_logging_test.dart`、`test/core/encrypted_db_resolver_test.dart` |
| §15.3 | パフォーマンス・可用性 | 🟡 | キャッシュ先行/Outbox/自動保存は実装済み。R8監査でOutbox conflict状態が永久に解消されない欠陥（E-1, High）を検出、Opus 4.8向け修正待ち。ページング・インクリメンタル検索は未実装 | R8監査E章 |
| §15.4 | アクセシビリティ | ✅ | Semantics境界・Tooltip・48dp・文字200%対応（R7） | `test/widget/design_system_matrix_test.dart`、`test/widget/screen_matrix_test.dart` |

## §16 開発・リリース前提

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §16.1 | クライアント技術選定 | ✅ | [ADR-0001](adr/0001-flutter-client.md) | — |
| §16.2 | Windows開発範囲 / macOS必須工程 | 🟡 | Windows側（format/analyze/test/Android設定静的検証）は実行可能・実行済み。Android実ビルド・iOSビルドはSDK/macOS環境が本機に無く未実行（環境制約、コード不良ではない） | `.github/workflows/ci.yml`（CI環境では実行される想定） |

## §17 成功指標

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §17 | 匿名イベント計測 | ⬜ 未実装 | — | — |

## §19 UI・ビジュアルデザイン

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §2.5, §19 | Design Token・共通コンポーネント | ✅ | `lib/app/design_system/`（15コンポーネント）、`lib/app/theme/app_tokens.dart` | `test/widget/design_system_test.dart`、`test/widget/design_system_matrix_test.dart` |
| §19 | 主要6領域の画面構成 | ✅ | ホーム/現場一覧・詳細/思い出一覧・詳細/マイ推し/設定の各presentation | `test/widget/screen_matrix_test.dart`ほか |
| §19 | 写真あり／なし、ライト／ダーク、推しカラー、レスポンシブ、a11y | ✅ | 同上 | `test/widget/design_system_matrix_test.dart`（360/430dp×light/dark×textScale2.0×推しカラー10色） |
| §19 | 権利処理済み画像のみ使用、チケット画像の自動露出禁止 | ✅ | `Genba.heroImage`とTicketの型分離（`genba.dart`） | R8監査C章で構造分離を確認 |

---

## 非MVPバックログ

MVPへ混入させない。将来対応候補として維持する（§14 対象外 / §12 プレミアム / §10 外部連携）。

| 項目 | 根拠節 |
|---|---|
| 外部公演API連携 | §14 |
| 公式メンバーDB | §14 |
| 本格SNS機能 | §14 |
| 支出管理 | §14 |
| AI機能（思い出整理 等） | §14, §12 |
| 年間レポート | §14, §12 |
| 公開プロフィール / ランキング / 公式ニュース連携 | §14 |
| 写真・動画保存容量拡張（プレミアム） | §12 |
| 推しカラー着せ替え（プレミアム） | §12 |
| 高度な検索（プレミアム） | §12 |
| クラウドバックアップ（プレミアム） | §12 |
| 共有人数上限拡張（プレミアム） | §12 |

---

## 未割当チェック

要件定義書 §1〜§19（サブ節含む）はすべて上記いずれかの状態・非MVPバックログへ割り当て済み。**未割当: 0件**。

## 未実装・境界のみの項目一覧（follow-up-work.md対応表）

| 節 | 内容 | follow-up-work.md該当フェーズ |
|---|---|---|
| §7.8 | 共有・権限 | フェーズC |
| §8.3 | 入力通知 | フェーズD |
| §10.2〜§10.4 | 公演DB検索・重複統合・通報 | フェーズC |
| §11, §13通知設定 | Push通知一式 | フェーズD |
| §12 | マネタイズ導線 | フェーズE |
| §13データ出力 | データエクスポート | 未着手（follow-up-work.md未記載、要追加） |
| §17 | 成功指標計測 | 未着手（follow-up-work.md未記載、要追加） |
