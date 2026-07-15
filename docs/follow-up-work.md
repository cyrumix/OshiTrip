# 後続作業計画（依存順）

対象: 根幹一括実装（2026-07-02）で「境界と土台」に留めた範囲。
各項目に前提（依存）と、実装の起点となる既存境界を記す。

## R8監査是正（2026-07-04, High 3件 → **実施済み**）

R1〜R7完了後の独立監査（`docs/decisions.md`「R8 独立監査」節）でHigh 3件を検出し、
Claude Opus 4.8 で R8-A → R8-C → R8-B の順に是正した（`docs/decisions.md`
「R8 是正実施」節, D-169〜D-177）。

- **R8-A ✅**: Outbox競合(conflict)の正式な解決処理を実装（`ConflictResolver`・
  `OutboxStore` の owner 限定解決メソッド・`reconcileServerVersionInto`・
  競合解決シートUI）。サーバー採用／端末再送の2択、conflictの黙殺なし、owner分離維持。
- **R8-C ✅**: Supabase全通信に共通タイムアウト（`TimeoutHttpClient` + 各境界の
  `.withRemoteTimeout()`）を導入し、`TimeoutException`→`NetworkFailure`へ変換。
  `AccountController.deleteAccount()` に二重タップ防止を追加。
- **R8-B ✅（SQLは静的検証のみ）**: 子テーブル7種+`outbox_operations`のpgTAP正例/負例を
  `supabase/tests/0005_rls_child_and_master.sql` に追加。`performances` は DELETE 不可を
  意図的仕様として明記・テスト化。`enforce_oshi_anniversary_owner` の直接防御を
  `0008_anniversary_owner_hardening.sql` で追加。**Docker 未導入のため `supabase test db`
  は未実行**（静的検証済み・要実機確認）。

## 追加方針: UI・ビジュアル刷新（2026-07-02）

ユーザー提示の画面コンセプトを[UI・ビジュアルデザイン仕様書](design-spec.md)と要件§2.5／§19へ反映した。実装は[Fable後Phase別プロンプト](post-fable-phase-prompts.md)のPhase 1を正とし、根幹実装後レビューのCritical／High修正が完了してから行う。

主な追加対象:

- Design Tokenと共通カード／ヒーロー／タブ／アバター／設定コンポーネント
- ホーム、現場詳細、思い出一覧・詳細、マイ推し、設定／テーマの情報階層刷新
- 現場ヒーロー画像、思い出お気に入り、参加状態、表紙写真、推し画像の永続化
- 活動統計、次の現場、誕生日・記念日の実データ導出
- ライト／ダーク、推しカラー、写真あり／なし、文字拡大、狭幅のWidget／Golden test

特定アーティスト画像をサンプルとして同梱せず、権利処理済み素材または抽象プレースホルダーを使用する。

## フェーズA: 同期の完成（他のすべての土台）

1. **リモート pull の全エンティティ対応**
   - 現状: `GenbaRepositoryImpl.refreshFromRemote()` のみ（現場集約）。memory_* / oshi_* の pull 未実装。
   - 起点: `_pullTable()`（genba_repository_impl.dart）を共通化し、Memory/Oshi リポジトリへ展開。
   - 完了条件: 再インストール後のログインで全データが復元される。
2. **接続監視の実装**
   - 現状: `ConnectivityObserver` 抽象 + 常時オンライン仮定（`core/network/connectivity.dart`）。
   - connectivity_plus 等を data 層に実装し、`onlineChanges` → `SyncEngine.poke()` を接続。
   - アプリライフサイクル（resume）でも poke する。
3. **競合解決の高度化**
   - 現状: LWW（リモート優先）+ conflict 記録。conflict の解消UIなし。
   - conflict になった Outbox 行の内容確認・「自分の変更で上書き」「破棄」UI。
   - 将来: フィールド単位マージ（payload はフル行JSONなので拡張可能）。

## フェーズB: 写真・チケット画像（Aの後）

4. **写真バックグラウンドアップロード + 再試行キュー**
   - 起点: `MemoryPhotoUploader`（domain）/ `SupabasePhotoUploader`（単発実装済み）/
     `MemoryPhoto.uploadStatus`（local_only/queued/uploaded/failed）。
   - Outbox と同様のキュー駆動 + サムネイル生成。`delete_account()` の Storage 掃除も拡充。
5. **チケット画像の認可付きアップロード**
   - 起点: `Ticket.imagePath`（Storage）/`imageLocalPath`（端末）分離済み。
   - バケット `ticket-images` を memory-photos と同方式で追加（0005 参照）。署名URL表示。

## フェーズC: 公演DB・共有（§10 / §7.8）

6. **ユーザー投稿型公演DBの実装**
   - 起点: `performances` テーブル + RLS（0002）、`PerformanceRepository` 抽象、`Genba.performanceId`。
   - インクリメンタル検索（完全一致→登録者数→日付近さ）、重複候補提示、登録者数集計
     （閾値未満マスキングは Edge Function/ビュー）、通報・管理者統合。
   - pgTAP: 管理者のみ統合可・少人数マスキングの検証を追加。
7. **共有・権限（owner/editor/viewer + 項目単位）**
   - **共有データ基盤は実装済み**（2026-07-09, D-226）: `genba_shares` テーブル（role editor/viewer
     ＋項目grant4種＋version）・**owner 管理 RLS**（owner が自共有をCRUD／grantee は自共有を
     SELECTのみ）・子owner トリガ・apply_mutation 登録・Drift v17・`GenbaSharesRepositoryImpl`
     （owner スコープ CRUD＋同期）・ドメイン（`share.dart` 拡張／`shareInvariantError`）・
     pgTAP `0015`(静的)。**既存データ表の RLS は無改変**（C-01 リスク回避）。
   - **残り（次増分・要 pgTAP 実行環境=Docker/CI）**: grantee による共有データの実 read/write の
     **ロール別 RLS**、**項目マスキング（view/カラム）**、**Storage 共有ポリシー**、
     **editor write-through**（apply_mutation の owner矯正＋子ownerトリガ＋書込RLS改修）、
     **Realtime 共同編集**、**共有向け競合UI／共有解除後キャッシュ到達不能**。
     全表へロール別RLSを適用する変更は owner隔離(C-01)の盲目改変になるため pgTAP 実行検証を前提とする。
   - **招待URL・フレンド・簡易プロフィールのデータ基盤は実装済み**（2026-07-11, D-233）:
     `profiles`/`friendships`/`genba_invites` テーブル・RLS・SECURITY DEFINER RPC 7種
     （フレンド申請/応答/削除・招待発行/無効化/プレビュー/参加）・helper（`users_share_genba`/
     `can_view_profile`）・pgTAP `0016`(静的)・ドメイン型＋純粋ロジック（`profile.dart`/
     `friendship.dart`/`genba_invite.dart`）＋Repository 抽象・Dartテスト（`test/domain/*`）。
     共有メンバーの実体は `genba_shares`、招待参加は `join_genba_via_invite` が `genba_shares` 行を作る。
   - **Phase 2 実装済み**（2026-07-11, D-234）: **プロフィール編集画面**（表示名/ひとこと/推し名/
     フレンド申請受付/検索可否・本人限定保存）と**フレンド画面**（一覧/申請中/受信の3タブ・承認/拒否/
     削除/取消）、Supabase-backed `ProfileRepository`/`FriendRepository`（＋Unavailable フォールバック）と
     provider 配線（`social_providers.dart`）、設定＞つながり導線・ルート（`/settings/profile`・
     `/settings/friends`）、widgetテスト。
   - **フレンドコード実装済み**（2026-07-13, D-249, migration 0033 / pgTAP 0018）: `profiles.friend_code`
     （NOT NULL/UNIQUE・サーバー採番 `OSHI-XXXX-XXXX`・トリガ自動採番＋既存 backfill）と
     `send_friend_request_by_code`（コード完全一致で相手特定＝無制限検索なし・`searchable=false` でも可・
     自分/存在しないコードは拒否・状態機械は `send_friend_request` と同一）。フレンド画面に自コード表示/コピー
     ＋「フレンドコードで追加」。招待URLのロール選択から「おすすめ」表記を削除（viewer 既定は維持）。
     **実DB検証済み**（`supabase db reset`＋`supabase test db`＝18ファイル/334テスト PASS）。
   - **Phase 3 実装済み**（2026-07-11, D-235）: 現場詳細＞**メンバー・共有画面**（`/genba/:id/members`・
     AppBar people 導線）。オーナー視点でメンバー一覧・自分の権限・**フレンドから追加**（viewer/editor 選択）・
     **権限変更**（viewer↔editor）・**メンバー削除**・**メンバーへのフレンド申請**（§7.8.4）。`genbaMembersProvider`
     が genba オーナー＋`genba_shares`＋プロフィール＋フレンド状態を合成。招待URL枠はプレースホルダ（Phase 4）。
   - **Phase 4 実装済み**（2026-07-11, D-236）: **招待URL発行/コピー/無効化**（メンバー画面 `_InviteSection`・
     権限 viewer/editor 選択・クリップボード）、**参加確認画面**（`/invite/:token`＝`InviteJoinScreen`・現場名/
     公演名/日付/オーナー/権限表示・参加→現場詳細）、**token参加処理**（`join_genba_via_invite`）と
     `GenbaInviteRepository` Supabase 実装。Deep Link 代替として設定＞つながり＞「招待リンクで参加」
     （`InvitePasteScreen`＝URL/コード貼り付け）。
   - **Phase 5 実装済み**（2026-07-11, D-237）: **Deep Link のネイティブ設定**（Android App Links intent-filter
     `autoVerify`・iOS Associated Domains entitlement・`deeplink/` に AASA/assetlinks 雛形＋手順）と、未ログイン
     招待の `/login?from=<invite>` 退避→ログイン後復帰（`resolveAuthRedirect`・オープンリダイレクト防止）。
     go_router がパス `/invite/{token}` をルーティング（追加パッケージ不要）。
   - **共有現場アクセス（read/write RLS・editor共同編集）は設計・静的実装まで**（2026-07-11, D-238）:
     `0031_shared_genba_access.sql`（member SELECT ポリシー16表・`apply_shared_mutation` editor RPC・
     `is_genba_member`/`is_genba_editor`/`is_plan_member`）＋pgTAP `0017`。クライアントは権限モデル
     `GenbaPermission`＋`myGenbaRolesProvider`/`genbaPermissionProvider` の基礎のみ。
   - **共有現場の一覧/閲覧詳細/editor編集/非オーナーメンバー閲覧を実装**（2026-07-11, D-239/D-240/D-241）:
     現場一覧の「共有された現場」節（共有/権限バッジ）、閲覧専用の共有詳細（`/shared-genba/:id`・概要/準備状況/
     Todo/持ち物/メモ/計画スポット/思い出=感想・グッズ・場所・食べもの・セットリスト・写真件数）、editor の Todo
     完了トグル/削除を `apply_shared_mutation` RPC 経由で編集（`SharedMutationClient`）、viewer 編集不可、非オーナーの
     メンバー画面閲覧（管理は owner 限定）。共有現場は Drift owner スコープに混ぜずサーバー権威の別経路。
     **2026-07-12（D-242）**: RPC 戻り値 `{status}` を `parseSharedMutationResult` で必ず解析し、`applied` のみ成功・
     `conflict`（版CAS不一致）は `ConflictFailure`＋SnackBar通知＋再取得・未知/欠落は失敗扱い（競合の握りつぶし修正）。
     **2026-07-12（D-243）**: editor の**メモ共同編集**（追加/編集/削除）を `apply_shared_mutation`（genba_memos）で追加。
     編集/削除は memoVersions で楽観CAS、conflict は通知＋再取得、viewer は導線なし。
     **2026-07-12（D-244）**: 共有メモを **free/checklist/bingo/vote の4種類**に対応。fetcher が category/kind/content/sort_order を
     復元、`_MemoView`/`_BingoView`/`_VoteView` で種類別閲覧、追加/編集は**既存メモエディタを再利用**（`MemoSubmit` onSubmit で
     保存だけ apply_shared_mutation へ差し替え・kind/content 維持）。
     **2026-07-12（D-245）**: editor の共同編集を **計画スポット（追加/編集/削除）・移動区間（削除のみ）・思い出テキスト（感想/ベストシーン編集）**へ拡張。
     スポットは owner の Places 連携UIを流用せず name+category の共有専用ダイアログ（`_SpotEditorDialog`）で手入力し `plan_id` で帰属検証。
     移動区間は origin/destination_entry_id が entries 参照のため**追加/編集は次増分**とし削除のみ対応。思い出は memory_entries が1現場1行のため無ければ新規作成。
     各行 version で baseVersion CAS・conflict は通知＋再取得・viewer は導線なし。`SharedGenbaData` を id/plan_id/version 付きへ拡張（`firstPlanId`/`legs` 追加）。
     **2026-07-12（D-245b 是正）**: スポットのカテゴリ選択を単一の情報源 `ItinerarySpotCategory`（`wireValue`＋`label`）から生成し**聖地(sacred_place)含む全15種**に整合（独自マップ廃止・`wireValue` は round-trip テストで `@JsonValue` 一致を担保）。
     既存スポットの未知カテゴリは `other` に落とさず保持。**plan 未作成時（`hasPlan==false`）は editor に案内表示のみ**（「計画はまだ作成されていません。オーナーが計画を作成すると共同編集できます」）で追加導線は出さず、**editor に計画本体(itinerary_plans)作成は開放しない**（安全側・apply_shared_mutation/RLS/pgTAP 未対応のため）。
     **2026-07-13（D-246）**: editor の共同編集を残りの対象へ拡張。**移動区間（追加/編集/削除）**＝端点は旅程項目(entries)から選ぶ共有専用ダイアログ・plan で帰属検証・端点2つ未満は追加不可の案内；
     **チケット/交通/宿泊（追加/編集/削除）**＝主要フィールドの共有専用ダイアログ・ステータス/交通手段は check 制約準拠のコード選択；**グッズ/行った場所/食べたもの(visited_places category=spot/food)/セットリスト(position 末尾自動採番)（追加/編集/削除）**；
     **写真/アルバム**＝一覧表示＋caption/カバー編集＋行削除のみ（画像アップロード/サムネイルは Storage メンバーポリシー未実装で次増分）。各行 version で CAS・conflict は通知＋再取得・viewer は導線なし。ダイアログは `shared_edit_dialogs.dart` に分離。
     **2026-07-13（D-247 是正）**: (1) **計画本体(itinerary_plans)を apply_shared_mutation の allowlist から除外**し、editor による計画本体の作成/更新/削除を RPC でも不可にした（仕様・UI 案内・docs と一致）。計画配下の子データ（spots/entries/legs）編集は維持。(2) **写真カバー(is_cover)の安全切替**を RPC 内特別処理で実装（同一現場の他カバーを version CAS 通過後/insert 前に false 化・帰属チェックはサーバー側・他現場は触らない）。1現場1カバーの unique 衝突を回避。
   - **注意（共同編集は概ね完了・残は明記）**: editor が**編集できるのは Todo・持ち物／メモ（4種類）／計画スポット／移動区間（追加/編集/削除）／チケット／交通／宿泊／思い出テキスト（感想）／
     グッズ／行った場所／食べたもの／セットリスト／写真（caption/カバー編集・削除）**。**editor による計画本体(itinerary_plans)作成・編集は未開放（RPC allowlist からも除外済み, D-247）／写真の画像アップロードも未実装**（次増分）。
   - **残り（クライアント配線・別増分）**: 写真の**画像アップロード**（メンバー用 Storage read/write ポリシー＋サムネイル表示）、**editor による計画本体(itinerary_plans)作成の開放**（要 apply_shared_mutation allowlist 追加＋RLS＋pgTAP・現状は案内表示のみ）、共有解除後のローカル非表示の追加テスト。
   - **残り（実環境検証）**: **Deep Link 実機検証**（AASA/assetlinks の実ホスティング・TeamID・リリース
     署名SHA256・Xcode Associated Domains＋`CODE_SIGN_ENTITLEMENTS`・Play App Signing。`deeplink/README.md` 参照）、
     **migration 0030/0031 実デプロイ＋pgTAP 0016/0017 実行＋実 RLS/RPC・E2E**（Docker/Supabase 必要）、
     **プロフィール画像アップロード**（Supabase Storage バケット＋本人限定RLS。表示名イニシャルで代替中）。

## フェーズD: 通知（§8.3 / §11）

8. **FCM/APNs 登録と通知スケジューリング**
   - 起点: `features/notifications/domain/notification_plan.dart`
     （NotificationKind/NotificationPlan/NotificationScheduler）。
   - firebase_core / firebase_messaging / flutter_local_notifications を追加
     （google-services.json は環境別・コミット禁止）。
   - 許可要求は「通知価値が発生した時点」（初回起動では要求しない、実装済みの方針を維持）。
   - 思い出未入力通知は `MemoryEntry.declinedFields`（「今回は入力しない」）を尊重する。
9. **ディープリンク実処理**
   - 起点: go_router のパス設計は通知遷移を想定済み（/genba/:id, /memories/:id/edit）。

## フェーズE: その他

10. **Todoテンプレート提案**（§7.6: 種別・遠征有無・日数に応じた提案、適用前確認）
11. **マネタイズ導線**（§12: 要否=required かつ未登録のときのみ。`GenbaPreparation` が判定材料）
12. **l10n（ARB化）**: 現状は ja リテラル直書き（decisions.md D-30）
13. **riverpod_generator への移行**（decisions.md D-01。機械的変換）
14. ~~**iOS flavor 対応**: Xcode Scheme/Config~~ 解消済み（H-01/M-02、decisions.md）。
    development/staging/production の共有Schemeとxcconfigを追加した。
    macOS実機/CIでのXcodeビルド・アーカイブ検証のみ未実施（macOS 必須工程、setup.md §6）。
15. **分析・クラッシュレポート・ストア提出自動化**

## フェーズF: 計画タブ・推し活遠征旅程（§7.9）

16. **旅程ドメイン・DB・同期基盤**
17. **手動旅程・フォールバックUI**（日別タイムライン、スポット、交通・宿泊参照、手動経路、余裕時間）
18. **Google Maps／Places MVP連携**（サーバー仲介、Field Mask、session token、帰属、クォータ）
19. **Google Routes MVP連携**（公共交通、手動フォールバック、キャッシュ、明示再計算）
20. **旅程共有・共同編集・通知・思い出連携**
21. **共有概算経路（`shared_route_estimates`）のFlutter側再利用（UI・Repository）**:
    Phase 4では DB基盤（スキーマ・RLS・モデレーション・不変条件・pgTAP）、routes-proxy／
    RoutesGateway実装（Google Routesライブ取得）、および**再利用の強制ゲート**
    （`shared_route_estimate.dart`: `parseSharedRouteEstimate`／
    `sharedRouteEstimateReuseError` — approved のみ／data_origin4種で 'google' 等を型で
    却下／rights_basis 必須）までを実装した。**残りは、この強制ゲートを通す
    読み取りRepository と UI表示**。UI表示は「旅程スポット→施設ID→共有経路」の突き合わせ
    が必要で、施設ID解決には shared_facilities の Flutter クライアント（下記の前提）が
    要る。旅程作成の通常表示で「保存済み概算経路を優先／Google自動呼び出しなし」は、
    各旅程内の `itinerary_legs` と route_live_panel（明示タップのみ）で機能的に満たして
    いる。クロスユーザー再利用（他人の権利確認済み概算経路を共有マスタから引く）を
    本項目で完成させる。
    - 前提: 18の一部（**shared_facilities の Flutter クライアント／施設ID解決**）が
      本項目のブロッカー。18（Places連携）ではDB基盤のみ実装済みで、施設の検索・
      ローカル同期クライアントは未実装（D-209）。

詳細仕様は `docs/itinerary-plan-spec.md`、技術判断はADR-0010、実装指示は `docs/itinerary-implementation-prompts.md` を参照する。16〜19を旅程MVPとし、Google連携を含めて完成判定する。**共有概算経路のFlutter側再利用（項目21）が未実装のため、旅程MVPは完成扱いにしない**（実環境検証未了と併せ、decisions.md「旅程Phase 4 レビュー是正」節を参照）。AI旅程、混雑予測、ルート最適化、本課金はこのフェーズの対象外。

## 検証の未完了項目（環境依存）

- `flutter build apk --flavor development`: 現行の開発機に Android SDK が
  未導入のため未実行（setup.md §2）。Gradle設定・productFlavor・署名境界
  （H-01/M-02, decisions.md）はソースレビュー済み。
- `flutter test integration_test`: エミュレータ/実機が必要。テスト自体は `integration_test/app_flow_test.dart` に実装済み。
- `supabase test db`（pgTAP）: Supabase CLI + Docker 未導入のため未実行。`supabase/tests/` に実装済み。CI の db-authz ジョブで実行される。
- iOS ビルド・Xcode Scheme(development/staging/production)の実機/CI検証:
  macOS 環境が必要（従来からのブロッカー）。pbxproj/xcconfig/xcscheme は
  再パース・ID参照整合性の検証済みだが、実際の Xcode でのビルド・
  アーカイブは未実施。
