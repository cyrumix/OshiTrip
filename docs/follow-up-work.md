# 後続作業計画（依存順）

対象: 根幹一括実装（2026-07-02）で「境界と土台」に留めた範囲。
各項目に前提（依存）と、実装の起点となる既存境界を記す。

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
14. **iOS flavor 対応**: Xcode Scheme/Config（macOS 必須工程、setup.md §6）
15. **分析・クラッシュレポート・ストア提出自動化**

## 検証の未完了項目（環境依存）

- `flutter build apk --flavor development`: Android SDK / JDK17 未導入のため未実行（setup.md §2）。
- `flutter test integration_test`: エミュレータ/実機が必要。テスト自体は `integration_test/app_flow_test.dart` に実装済み。
- `supabase test db`（pgTAP）: Supabase CLI + Docker 未導入のため未実行。`supabase/tests/` に実装済み。CI の db-authz ジョブで実行される。
- iOS ビルド: macOS 環境が必要（従来からのブロッカー）。
