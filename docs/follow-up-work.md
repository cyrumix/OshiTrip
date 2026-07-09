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
   - 起点: `features/sharing/domain/share.dart`（ShareRole/FieldGrants/ShareRepository）。
   - `genba_shares` テーブル + RLS 改修（現状は所有者のみ）。ADR-0008 の設計に従い
     viewer/editor ポリシーと field_grants ビュー/マスキングを実装。pgTAP 拡充必須。
   - Realtime 共同編集はさらにその後。

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
21. **共有概算経路（`shared_route_estimates`）のFlutter側再利用**: Phase 4では
    DB基盤（スキーマ・RLS・モデレーション・不変条件・pgTAP）と、routes-proxy／
    RoutesGateway実装（Google Routesライブ取得）までを実装した。**共有概算経路を
    Flutter側で検索・通常表示に使うクライアント実装（owner境界・approvedのみ・
    data_origin/rights_basis確認つきの再利用UI/Repository）は未実装**。旅程作成の
    通常表示で「保存済み概算経路を優先」する動作は、各旅程内の `itinerary_legs`
    （手動または権利根拠つきの永続概算値）で機能的に満たしており、クロスユーザー
    再利用（他人の権利確認済み概算経路を共有マスタから引く）は本項目で実装する。

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
