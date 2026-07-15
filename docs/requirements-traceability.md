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
| §5 | 5タブ、現場=未来+当日、思い出=過去、移行は表示区分変更。**2026-07-11追補（D-230）**: 終演済み（`afterglow`＝終演超過/手動終了・当日中）は「思い出」に表示しつつ当日は「ホーム」「現場」一覧にも残す二重表示、終演日翌0時（`memoryStartAt`）から「思い出」専用へ。`isMemory` を `afterglow`/`memory` でtrue、`isUpcoming` を `memory` 以外でtrue | `lib/app/router.dart`（StatefulShellRoute）、`genba_schedule.dart`のisMemory/isUpcoming | `test/widget/app_shell_navigation_test.dart`、`test/domain/genba_schedule_test.dart`（終演済み当日二重表示・翌日思い出のみ） |

## §6 ホーム

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §6.1 | 通常時ホーム（近い順/カード項目/準備状態/次アクション） | ✅ | `lib/features/home/presentation/home_screen.dart` | `test/widget/home_screen_hero_test.dart` |
| §6.2 | 当日ホーム（本日モード/キャッシュ/余韻中切替/複数当日公演） | ✅ | `today_card.dart`、`deriveGenbaStatus` | `test/widget/home_screen_hero_test.dart`、`test/domain/genba_schedule_test.dart` |

## §7 現場

| 節 | 内容 | 状態 | 実装箇所 | テスト |
|---|---|---|---|---|
| §7.1 | 状態機械（予定/準備中/本日/余韻中/思い出/中止）。**2026-07-11追補（D-229）**: 予想終演（`endTimeMinutes`）と実際の終演を区別。余韻・思い出入力の「実際の終演時間」で `setActualEndTime` が `manualEndedAt`＋`endTimeMinutes` を更新し、概要・当日・計画（終演アンカー）へ反映（深夜終演は1440超）。準備サマリは現場詳細のヒーローとタブの間へ常時表示 | `lib/features/genba/domain/genba_schedule.dart`、`genba_actions_controller.dart`（`setActualEndTime`）、`memory_edit_screen.dart`（`_ActualEndTimeCard`）、`genba_overview_tab.dart`（`GenbaPrepSummaryBar`）、`genba_detail_screen.dart` | `test/domain/genba_schedule_test.dart`（境界値・深夜公演・手動終演）、`test/notifier/genba_actions_controller_test.dart`（setActualEndTime） |
| §7.2 | 現場作成（最小3項目＋段階追加） | ✅ | `genba_form_screen.dart`/`genba_form_controller.dart` | `test/notifier/genba_form_controller_test.dart` |
| §7.3 | チケット | ✅（画像アップロードは§フェーズB未実装、ローカル参照のみ） | `lib/features/genba/data/genba_repository_impl.dart`、`child_editors.dart` | `test/data/repositories_test.dart` |
| §7.4 | 交通（不要/未登録の区別）。**2026-07-10追補**: 新規追加時、出発/到着時刻ピッカーの初期日付（`initialDate`）はイベント日にするが、ユーザーが未選択の間 `departAt`/`arriveAt` はUI表示「未設定」のまま実データも null を保つ（イベント日0:00を無選択のまま保存しない）。往路を新規保存すると「同様の経路で復路を登録しますか？」の確認ダイアログを表示し、承諾時は同一交通手段・出発地/到着地を逆にした復路（時刻未設定）を追加登録する。既存交通の編集時はこの確認を出さない | `genba_preparation.dart`（`CategoryPrepState`）。`child_editors.dart`（`_TransportEditorState`: `_departAt`/`_arriveAt` は新規時null初期化、`_pickerDefaultDate`はピッカーの`initialDate`のみに使用。往路新規保存後の復路確認ダイアログ→承諾で復路Transport作成）・`genba_child_sections.dart`（`TransportTab`が`eventDate: genba.eventDate`を editor へ配線） | R8監査B章で確認・`test/widget/transport_lodging_dates_test.dart` |
| §7.5 | 宿泊（宿泊なし区別）。**2026-07-10追補**: 新規追加時、チェックイン・チェックアウト日の初期値は現場の開催日とする（日付のみの項目のため実データにも開催日を入れる） | 同上。`child_editors.dart`（`_LodgingEditorState`: `_checkin`/`_checkout` 初期値=開催日）・`genba_child_sections.dart`（`LodgingTab`が`eventDate: genba.eventDate`を editor へ配線） | 同上・`test/widget/transport_lodging_dates_test.dart` |
| §7.6 | Todo | ✅（テンプレート提案は未実装、follow-up-work.mdフェーズE） | `child_editors.dart`、`genba_actions_controller.dart` | `test/notifier/genba_actions_controller_test.dart` |
| §7.7 | メモ（複数登録・テンプレート） | ✅ **2026-07-07 複数化**（D-199）: 現場ごとに複数メモを作成・編集・削除・並び替え。タイトル/種類/並び順を追加し「現場×種類ごと1件」制約を撤廃。テンプレート5種＋「テンプレートなし」。既存メモは種類名をタイトル初期値に移行 | `GenbaMemo`（title/sortOrder/`MemoCategory.other`）、Drift v12・Supabase `0018_genba_memos_multi.sql`、`genba_repository_impl.dart`（ID単位upsert・`reorderMemos`）、`genba_child_sections.dart`（`MemoTab`）・`child_editors.dart`（`_MemoEditor`） | `test/data/genba_memo_test.dart`（複数保持・並び替え・v11→v12移行）・`test/data/repositories_test.dart`（ID単位upsert）・`test/widget/genba_detail_tabs_test.dart`（空状態）。pgTAP 未追加（Docker未導入） |
| §7.8 | 共有（owner/editor/viewer） | 🟡 **共有データ基盤を実装**（2026-07-09, D-226）: `genba_shares` テーブル（role editor/viewer＋項目grant＋version）・owner 管理 RLS（owner が自共有CRUD／grantee は自共有SELECTのみ）・子owner トリガ・apply_mutation 登録・Drift v17・`GenbaSharesRepositoryImpl`（owner スコープ CRUD＋同期）・ドメイン拡張。**既存データ表の RLS は無改変**。ロール別 read/write RLS・項目マスキング・Storage 共有・editor write-through・Realtime 共同編集・共有向け競合UI・通知は次増分（要 Docker/pgTAP 実行環境）。**2026-07-11 招待URL・フレンド・簡易プロフィールのデータ基盤を追加（D-233）**: `profiles`（本人PK・本人のみ編集・可視範囲=本人/承認フレンド/同一現場メンバー/searchable）・`friendships`（requester/receiver・状態機械・本人のみ操作）・`genba_invites`（現場ごと・token・default_role viewer既定・expires_at/revoked_at/max_uses/used_count）＋RLS＋SECURITY DEFINER RPC 7種（`send_friend_request`/`respond_friend_request`/`remove_friend`/`create_genba_invite`/`revoke_genba_invite`/`get_invite_preview`/`join_genba_via_invite`）＋helper（`users_share_genba`/`can_view_profile`）。共有メンバー実体は `genba_shares`、招待参加は `join_genba_via_invite` が `genba_shares` 行を作成（owner限定発行/無効化・token検証[revoked/expired/max_uses]・重複参加防止・無制限検索禁止）。3表は offline 同期に載せずサーバー権威RPCで扱う。**Phase 2 実装済み（D-234）**: プロフィール編集画面・フレンド画面（一覧/申請中/受信・承認/拒否/削除）、Supabase-backed `ProfileRepository`/`FriendRepository`（＋Unavailable）・provider 配線（`social_providers.dart`）・設定導線（`/settings/profile`・`/settings/friends`）・widgetテスト。**Phase 3 実装済み（D-235）**: 現場詳細＞メンバー・共有画面（`/genba/:id/members`）＝オーナー視点のメンバー一覧・権限変更（viewer/editor）・削除・フレンドから追加・メンバーへのフレンド申請（`genbaMembersProvider`/`genba_members_screen.dart`）。**Phase 4 実装済み（D-236）**: 招待URL発行/コピー/無効化（メンバー画面 `_InviteSection`）・参加確認画面（`/invite/:token`＝`InviteJoinScreen`）・token参加（`join_genba_via_invite`）・`GenbaInviteRepository` Supabase実装、Deep Link 代替の貼り付け参加（`InvitePasteScreen`・`/settings/join`）。**Phase 5 実装済み（D-237）**: Deep Link ネイティブ設定（Android App Links intent-filter・iOS Associated Domains・`deeplink/` AASA/assetlinks 雛形）＋未ログイン招待の `/login?from=<invite>` 退避→復帰（`resolveAuthRedirect`）。go_router がパス `/invite/{token}` をルーティング。**共有現場のロール別アクセス（read/write RLS・editor共同編集）は設計・静的実装まで（D-238）**: `0031_shared_genba_access.sql`（member SELECT ポリシー16表・`apply_shared_mutation` editor RPC・`is_genba_member`/`is_genba_editor`/`is_plan_member`）＋pgTAP `0017`（viewer read可/write不可・editor read/write可・editor はメンバー管理/現場削除不可・未共有/解除後 read/write不可・owner 全操作可）、クライアント権限モデル `GenbaPermission`＋`myGenbaRolesProvider`/`genbaPermissionProvider`（`test/domain/genba_permission_test.dart`）。**2026-07-11 共有現場の一覧/閲覧詳細/editor編集/非オーナーメンバー閲覧を実装（D-239/D-240/D-241）**: 現場一覧に「共有された現場」節＋共有/権限バッジ（`sharedGenbaSummariesProvider`）；閲覧専用の共有現場詳細（`/shared-genba/:id`＝`SharedGenbaDetailScreen`）でサーバー権威に genba＋子データ（概要/準備状況/Todo/持ち物/メモ/計画スポット/移動件数/思い出=感想・グッズ・行った場所・食べたもの・セットリスト・写真件数）を取得表示；editor は **Todo・持ち物（完了トグル/削除）／メモ（free/checklist/bingo/vote の追加/編集/削除, D-243/D-244・既存メモエディタ再利用で kind/content 維持）／計画スポット（既存planがある場合のみ追加/編集/削除, D-245／D-245b・owner の Places 連携UIは流用せず name+category の共有専用ダイアログ・カテゴリは通常計画と同一の `ItinerarySpotCategory`＝聖地含む全15種・未知カテゴリは other に落とさず保持・plan で帰属検証。**plan 未作成時は案内表示のみで追加不可**＝editor に計画本体作成は開放しない）／移動区間（追加/編集/削除, D-246・端点は旅程項目 entries から選ぶ共有専用ダイアログ・plan で帰属検証・端点2つ未満は追加不可の案内）／思い出テキスト（感想/ベストシーンの編集, D-245・memory_entries は1現場1行で無ければ新規作成）／チケット・交通・宿泊（追加/編集/削除, D-246・主要フィールドの共有専用ダイアログ・ステータス/交通手段は check 制約準拠のコード選択）／グッズ・行った場所・食べたもの（visited_places の category=spot/food）・セットリスト（position 末尾自動採番）（追加/編集/削除, D-246）／写真・アルバム（caption/カバー編集・行削除のみ, D-246・**画像アップロード/サムネイル表示はメンバー用 Storage ポリシー未実装で次増分**）** を **`apply_shared_mutation` RPC 経由**（`SharedMutationClient`・戻り値 `status` を `parseSharedMutationResult` で解析し `conflict` は `ConflictFailure`＋再取得, D-242・各行 version で baseVersion CAS）で編集、viewer は編集導線なし・構造化メモも閲覧可；写真カバー(is_cover)は apply_shared_mutation 内で同一現場の他カバーを安全に落としてから設定（1現場1カバーの unique 衝突を回避・他現場は不可, D-247）；**editor による計画本体(itinerary_plans)の作成・編集・削除は未開放（RPC allowlist からも除外済み, D-247）／写真の画像アップロード(Storage メンバー書込)も未実装（次増分）**；非オーナーもメンバー画面を閲覧のみ可（管理は owner 限定、`_MemberReadOnlyView`）；`itinerary_spot_links` の spot_id→spot→plan→genba 判定を 0031/pgTAP0017 で修正。**2026-07-13 フレンドコードを実装（D-249, migration 0033）**: `profiles.friend_code`（NOT NULL/UNIQUE・**形式 CHECK** `^OSHI-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$`・サーバー採番 `OSHI-XXXX-XXXX`・曖昧文字0/1/I/O除外・`gen_friend_code`/`gen_unique_friend_code` 衝突再生成・BEFORE INSERT トリガ自動採番＋既存ユーザー backfill・**サーバー採番専用＝本人でも変更不可**: friend_code 列を authenticated から書けないよう profiles のテーブル INSERT/UPDATE 権限を編集可能列のみへ列指定で付与し直し、加えて BEFORE UPDATE `enforce_friend_code_immutable` トリガで採番済み値の変更を拒否。内部関数 `gen_friend_code`/`gen_unique_friend_code`/`set_profile_friend_code`/`enforce_friend_code_immutable` は public から execute revoke）と `send_friend_request_by_code(text)`（**コード完全一致**で相手特定＝無制限検索なし・`searchable=false` でもコードなら申請可・自分/存在しないコード/空は拒否・受付可否/ブロック/状態機械は既存 `send_friend_request` と同一）を追加（`send_friend_request(uuid)` は無改変・profiles 主キーは `id` のまま）。Flutter は `Profile.friendCode`＋`SupabaseProfileRepository` が `friend_code` 取得、`FriendRepository.sendRequestByCode`＋Supabase/Unavailable 実装、フレンド画面に自コード表示/コピー＋「フレンドコードで追加」ダイアログ。招待URLのロール選択UIから「おすすめ」表記を削除（viewer 既定は維持）。pgTAP `0018_friend_codes.sql`（一意性・backfill/NOT NULL・コード申請 pending・自コード拒否・存在しないコード拒否・searchable=false でもコードなら可・メンバー経由申請の回帰・無制限検索禁止の維持）。**実DB検証済み**: `supabase db reset`＋`supabase test db`（18ファイル/334テスト PASS）。**共有現場は Drift owner スコープに混ぜずサーバー権威の別経路**。**残: 写真の画像アップロード（メンバー用 Storage read/write ポリシー）・計画本体(itinerary_plans)作成の editor 開放（要 allowlist/RLS/pgTAP）、Deep Link 実機検証・iOS entitlements の Xcode リンク・migration 0030/0031 実デプロイ＋pgTAP 0016/0017 実行＋実 RLS/RPC・写像の E2E・プロフィール画像アップロード（実 Supabase / 実機 / 署名鍵 / Xcode が必要・未実施）** | `supabase/migrations/0028_genba_shares.sql`＋`0030_social_profiles_friends_invites.sql`、`lib/features/sharing/`（`domain/share.dart`・`domain/genba_invite.dart`・`data/genba_shares_repository_impl.dart`・`data/share_mappers.dart`）、`lib/features/social/`（`domain/profile.dart`・`domain/friendship.dart`・`data/profile_repository_impl.dart`・`data/friend_repository_impl.dart`・`application/social_providers.dart`・`presentation/profile_edit_screen.dart`・`presentation/friends_screen.dart`）、`lib/app/router.dart`／`lib/features/settings/presentation/settings_screen.dart`（導線）、`lib/core/db/app_database.dart`（v18）、`lib/core/providers.dart`／`outbox_operation.dart`／`session_refresher.dart` | `test/data/genba_shares_repository_test.dart`・`test/data/genba_shares_migration_test.dart`・`test/domain/share_test.dart`・`test/domain/profile_test.dart`・`test/domain/friendship_test.dart`・`test/domain/genba_invite_test.dart`・`test/widget/profile_edit_screen_test.dart`・`test/widget/friends_screen_test.dart`、pgTAP `supabase/tests/0015_genba_shares.sql`＋`0016_social_profiles_friends_invites.sql`（**未実行**: Docker未導入）。Supabase-backed repo の実RPC/RLS・migration 0030 実デプロイは**未検証**。follow-up-work.mdフェーズC 項目7 |
| §7.9 | 計画・推し活遠征旅程 | 🟡 **Phase 1〜4はコード実装済み（Places/地図/Routesを含む）。ただしEdge Function実デプロイ・実Google API呼び出し・`supabase test db`（pgTAP）・実機検証は未実施のため「旅程MVP」は完全完了ではない**。Phase 2で計画タブ・日別タイムライン・手動スポットCRUD・種別つきURL・交通/宿泊の参照追加・手動移動区間・余裕不足警告・オフライン閲覧編集・ユーザー画像を実装。Phase 3でGoogle Places連携境界（`PlacesGateway`・Autocomplete制御・共有施設スキーマ）、Phase 4でGoogle Routes連携（`RoutesGatewayImpl`・entitlement・費用制御・単体テスト済みのFieldMask/エラー変換）を実装（Google検索/地図/経路の見せかけUIは出さない設計を維持）。共同編集・通知はPhase 5前提基盤（共有データ基盤`genba_shares`のみ）まで、Phase 5本体は未実装。**2026-07-07 Phase 2追補**（D-188〜D-193）: カテゴリ「聖地」(`sacred_place`)追加、緯度・経度の手動入力廃止（列は温存・既存座標保持）、移動区間の日付を前後予定から内部決定（時刻のみ入力）、訪問日の初期値=現在操作中の予定日・新規開始時刻=直前実予定の終了時刻、メモ(note)を時間整合の全警告から除外。**2026-07-10 UX仕上げ追補**: (1) 現場詳細タブ順を 概要/Todo・持ち物/チケット/交通/宿泊/計画/メモ に統一（計画は6番目、メモが7番目）。(2) 計画タブは「行きたい場所」未追加＝計画未作成の状態でも登録済みの公演会場・開場・開演・終演アンカーを最初から表示し、アンカーには時刻に加えアーティスト名・公演タイトルも表示する。この閲覧だけではDBに計画を作成せず、追加メニューからの追加操作時にのみ既存の`ensurePlan`で作成する。(3) 現場詳細の概要タブには、開催当日かつ計画にユーザー追加項目（スポット・移動区間等）がある場合のみ、概要カードの下・Todo一覧の前に「次の予定」カードとその時刻を表示する（計画未作成、または開催当日でない場合は非表示）。**2026-07-11 場所入力・移動区間UX改善**（D-228）: 移動区間の出発/到着表示名を単一関数 `itineraryTimelineEntryLabel` へ共通化し内部enum/IDを画面に出さない（参照切れは「削除済みの…」）；移動区間の通常UIから通貨・運賃・経路概要・「日付は自動決定」説明・手動MapsURL欄を撤去（DB項目は温存し既存値は保持）；スポット施設名を「Google候補＋手入力」の一体型UIに統合し、実 Places ゲートウェイ（`PlacesGatewayImpl`→places-proxy）を接続、候補選択時に施設名・住所を入力欄へ反映し Place ID を保持（永続してよいGoogle由来値はPlace IDのみ, D-178/D-179）、無効時は同じ欄が手入力として動く；移動区間に常時「経路を確認（Google Mapsで開く）」導線を追加（Routes非対応/非プレミアム環境のフォールバック。経路結果は所要・距離中心で運賃非表示）。**2026-07-11(2) 計画・概要・会場・余韻UX（D-229）**: 準備サマリをヒーローとタブの間へ常時表示（`GenbaPrepSummaryBar`）；移動区間の出発時刻=移動元終了/到着時刻=移動先開始を初期値化、所要（分）は手入力廃止で出発・到着から自動計算の読み取り表示、金額欄は残し通貨欄廃止（JPY固定・「1,200円」表示）；「経路を確認」を Google 公式 dir 形式へ修正＋施設名/住所フォールバック＋起動多段化（`googleMapsRouteUrl`/`launchExternalUrl`）；スポットに「地図で開く」導線；会場入力をGoogle検索＋手入力一体型に（`venueAddress`/`venueGooglePlaceId`・Drift v18・Supabase 0029・座標非保存）；計画タブ「会場を追加」（category=会場・訪問日=開催日・開始=開場・終了=終演・重複確認）；会場/公演アンカーを「目安」補助表示化（予定カードと区別）；余韻入力の「実際の終演時間」で `manualEndedAt`＋`endTimeMinutes` を更新し終演参照箇所へ反映（`setActualEndTime`）。**2026-07-11(3) Google日本語・経路確認アプリ内化（D-230）**: Places/Routesリクエストに `languageCode:ja`/`regionCode:JP`（Routesは加えて `units:METRIC`）をGateway層で付与；住所欄の非公開説明文を撤去；移動区間カードの経路導線を「経路を確認」（アプリ内Routes取得・公共交通は徒歩合計＋路線/乗降駅/発着時刻/乗換の乗換タイムライン・出発予定時刻ベース）／「最新の経路」（現在時刻ベース再取得）／「Google Mapsで開く」（外部補助）に役割分離（`RouteLivePanel` を `_LegRow` と編集シートへ配置、誤称の `_LegRouteOpenButton` 撤去）；「この経路を保存」はGoogleコンテンツを恒久保存せず所要・距離・地図URL・確認日時のみ `user_provided` として保存（明示変換, D-178/D-180）；Routes Field Mask を発着時刻・徒歩所要へ拡張し `routes-proxy` handler が `walkMinutes`・発着時刻テキストを算出。**2026-07-11(4) 経路検索プレミアム制限の現仕様化（D-232）**: 現時点ではプレミアム／ノーマルのアカウント区分・課金導線が未整備のため、経路検索（「経路を確認」「最新の経路」）を全認証ユーザーに開放。`RouteRecalculationController` のクライアント側 `isPremium==false` 早期拒否を削除、UIの「プレミアム限定」文言を撤去。Edge Function `routes-proxy` の entitlement 検証を `ROUTES_REQUIRE_PREMIUM`（既定 `false`）でフラグ化し、`true` の環境でのみ `has_premium_routes_entitlement` を検証（`isFlagOn`/`premiumGateError` の純粋関数へ分離）。将来のプレミアム化に備え `isPremium`引数・`routesIsPremiumProvider`・entitlement RPC/テーブルは温存。API使用量はプレミアム制限ではなくレート制限・kill switch・timeout・最小Field Maskで制御（これらは維持） | Phase1: `lib/features/itinerary/domain/`・`data/`・`application/itinerary_timeline.dart`、Drift v9〜v17: `lib/core/db/app_database.dart`、Supabase: `supabase/migrations/0012`〜`0028`（itinerary/shared_facilities/routes_entitlement/genba_shares等）。Phase2 UI: `lib/features/itinerary/presentation/`（`plan_tab.dart`・`itinerary_editors.dart`・`itinerary_import_and_leg.dart`ほか）、`application/itinerary_actions_controller.dart`、追補の純粋関数 `domain/itinerary_schedule.dart`（`resolveInitialVisitDate`・`resolveInitialStartFromPrevious`・`deriveLegTimestamps`・`effectiveItinerarySchedule`）、`genba_detail_screen.dart`（タブ順: 概要/Todo・持ち物/チケット/交通/宿泊/計画/メモ）。UX仕上げ追補: `plan_tab.dart`（`_EventSchedulePreview`・`_AnchorRow`）、`genba_overview_tab.dart`（`_TodayNextPlanCard`）。Phase3: `domain/places_gateway.dart`・`application/places_search_controller.dart`・`supabase/functions/places-proxy/`。Phase4: `domain/routes_gateway.dart`・`data/routes_gateway_impl.dart`・`data/routes_entitlement_repository_impl.dart`・`presentation/route_live_panel.dart`・`supabase/functions/routes-proxy/`。Phase5前提基盤: `features/sharing/`（`domain/share.dart`・`data/genba_shares_repository_impl.dart`） | domain/data: `test/domain/itinerary_*_test.dart`（追補 `itinerary_phase2b_test.dart`・`itinerary_source_reflection_test.dart`・`itinerary_json_test.dart`「聖地」・`places_gateway_test.dart`・`routes_gateway_test.dart`・`shared_route_estimate_test.dart`・`share_test.dart`）・`test/data/itinerary_*_test.dart`（`itinerary_v9_migration_test.dart`ほか）・`routes_gateway_impl_test.dart`・`routes_entitlement_repository_test.dart`・`genba_shares_repository_test.dart`。Phase2 UI: `test/widget/itinerary_plan_tab_test.dart`・`itinerary_editor_phase2b_test.dart`・`genba_detail_tabs_test.dart`・`route_live_panel_test.dart`。UX仕上げ追補: `test/widget/genba_detail_tabs_test.dart`（タブ順7種）・`test/widget/itinerary_plan_tab_test.dart`（計画未作成でも公演アンカー表示）・`test/widget/genba_overview_next_plan_test.dart`（「次の予定」カードの表示条件）。**2026-07-11 UX改善**: `test/domain/itinerary_display_name_test.dart`（表示名に内部名`spot/transport/lodging/note`を出さない・各種別の日本語名・削除済み）・`test/data/places_gateway_impl_test.dart`（Places実Gatewayのpayload/応答変換/エラー変換）・`test/widget/itinerary_spot_place_search_test.dart`（Google無効でも手入力可・候補選択で名称/住所/Place ID反映）。**2026-07-11(2)**: `test/domain/itinerary_map_links_test.dart`（手入力スポット/経路URL生成）・`test/domain/itinerary_fare_format_test.dart`（円整形）・`test/domain/routes_gateway_test.dart`（dir URL形式）・`test/widget/itinerary_leg_venue_test.dart`（時刻初期値・所要自動・金額欄/通貨欄・会場追加）・`test/notifier/genba_actions_controller_test.dart`（setActualEndTime）・`test/notifier/genba_form_controller_test.dart`（会場Place ID保存）・`test/widget/itinerary_plan_tab_test.dart`＋`itinerary_plan_tab_phase2_test.dart`（地図導線・目安バッジ・金額円表示）・更新 `itinerary_editor_phase2b_test.dart`（通貨/運賃/経路概要/日付説明/手動MapsURLの非表示）・`itinerary_plan_tab_phase2_test.dart`＋`route_live_panel_test.dart`（運賃非表示）、integration: `integration_test/itinerary_offline_encrypted_sync_test.dart`（要実機・**未実行**）。pgTAP: `supabase/tests/0008`・`0009`・`0010`・`0012`〜`0015`（**未実行**: Docker/Supabase CLI未導入、静的レビューのみ）。Edge Function実デプロイ・実Google Places/Routes呼び出し・実機E2Eは**未実施**（成功扱いにしない）。**2026-07-11(3) D-230**: `test/data/routes_gateway_impl_test.dart`（ja/JP/METRIC payload）・`test/data/places_gateway_impl_test.dart`（ja/JP payload）・`test/widget/route_live_panel_test.dart`（経路を確認＝アプリ内取得・乗換タイムライン＋発着時刻＋徒歩合計・運賃非表示・自動保存なし・「この経路を保存」で所要/距離のみ保存・「最新の経路」現在時刻ベース・非プレミアム抑止）・`test/widget/itinerary_spot_place_search_test.dart`（住所欄に非公開文言なし）。`supabase/functions/routes-proxy/handler_test.ts`（`walkMinutes`/発着時刻抽出）は Deno 未導入で**未実行**。**2026-07-11(4) D-232**: `test/application/route_recalculation_controller_test.dart`（`isPremium=false` でも Gateway を呼ぶ）・`test/widget/route_live_panel_test.dart`（非プレミアムでも「経路を確認」「最新の経路」で Gateway 呼び出し・「プレミアム」文言なし）・`supabase/functions/routes-proxy/handler_test.ts`（`isFlagOn`/`premiumGateError`。Deno未導入で**未実行**）。詳細は decisions.md「旅程Phase 3」「旅程Phase 4」「旅程Phase 5」「終演済み二重表示・Google日本語優先」各節、Phase 5本体は `docs/itinerary-implementation-prompts.md` |

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
| §15.3 | パフォーマンス・可用性 | 🟡 | キャッシュ先行/Outbox/自動保存は実装済み。R8監査で検出したOutbox conflict状態が永久に解消されない欠陥（E-1, High）は**R8-Aで修正済み**（`ConflictResolver`/`showConflictResolutionSheet`によるサーバー採用/端末再送の明示解決、owner分離を維持）。残課題: 一覧のページング・インクリメンタル検索（公演DB等）は未実装、実環境（Docker/pgTAP・実機・Edge Function実デプロイ）での検証は未実施 | R8監査E章、decisions.md「R8是正実施」節（D-169〜D-172） |
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
