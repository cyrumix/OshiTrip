# 現行プログラム再レビューと修正実行プロンプト

レビュー日: 2026-07-02  
基準コミット: `7415653`（`初期実装: OshiTrip（Flutter）`）  
対象: `docs/requirements.md` §1〜§19、`docs/design-spec.md`、承認済みADR、現行Flutter／Supabase実装

## 1. 総合判定

**FAIL**

中心フローの骨格と63件の単体・Widgetテストは成立している。一方で、ローカルデータのユーザー分離にCritical、同期・端末保存・環境分離・画像基調デザインの実データ契約と主要6画面にHighが残る。現状のままデザインだけを上塗りせず、本書のR1から依存順に修正する。

## 2. 実行環境と検証結果

- Git: `main`、作業ツリーはレビュー開始時・終了時ともclean
- Flutter 3.44.4 stable / Dart 3.12.2
- `flutter pub get`: 成功
- `dart format --output=none --set-exit-if-changed lib test integration_test`: 成功、変更0件
- `dart analyze`: 成功、問題0件
- `flutter test`: 成功、63件すべて通過
- Android debug build: Android SDKがないため未実行。コード不良による失敗とは判定しない
- integration test: Android/iOS端末・エミュレータがないため未実行
- `supabase test db`: Supabase CLI / Dockerがないため未実行
- iOS build: Windows環境のため未実行

補足: 最初にリポジトリ全体へ実行した`dart format .`は、生成途中の`build/`内ディレクトリが消えたことによる`PathNotFoundException`になった。CIと同じ対象である`lib test integration_test`へ再実行し、こちらは成功した。

## 3. 達成できている基準線

- Flutter / Riverpod / go_router / Drift / Supabaseの基礎配線が存在する
- 5タブ、オンボーディング、デモ認証、現場CRUD、準備情報、当日表示、思い出入力、マイ推し、設定の基本導線が存在する
- 現場状態の日時境界、深夜公演、終演予定なし、「不要」と「未登録」、Outboxの基本状態を単体テストしている
- Supabase側はユーザー固有テーブルでRLSを有効化し、親子owner整合トリガーとpgTAPファイルを用意している
- 思い出表紙用の`MemoryPhoto.isCover`は既に存在する
- ライト／ダークテーマの切替自体は存在する

## 4. 指摘一覧

### Critical

#### C-01 ローカルDBのユーザー分離がなく、他ユーザーの閲覧・同期・削除が起こり得る

- 要件: §15.2、ADR-0005、ADR-0008
- 証拠:
  - `lib/features/genba/data/genba_repository_impl.dart:64-77`は全ownerの現場・子データを取得する
  - `lib/features/memory/data/memory_repository_impl.dart:56-72`は`genba_id`だけで取得する
  - `lib/features/oshi/data/oshi_repository_impl.dart:48-54`は全ownerを取得する
  - `lib/core/sync/outbox_store.dart:36-41, 97-98`はownerを絞らず送信・集計する
  - `lib/features/genba/data/genba_repository_impl.dart:379-393`は、現在ユーザーのRLS結果に存在しない別ownerのローカル行まで削除候補にする
  - `lib/bootstrap.dart:90`のDBファイルはflavor単位で、ユーザー単位ではない
- 影響: 同一端末でログアウト後に別アカウントへ切り替えると、前ユーザーの個人情報が見える、別ユーザーのOutboxを送ろうとする、pullで別ユーザーのキャッシュを消す可能性がある
- 期待動作: すべての読み書き・Outbox・下書き・KV・画像キャッシュを認証主体で分離し、未認証時にはユーザーデータを返さない。ログアウト・ユーザー切替・アカウント削除後に前主体の情報へ到達できない

### High

#### H-01 flavorとDartエントリポイントの組合せを誤るとproductionアプリがdevelopmentとして動く

- 証拠: `lib/main.dart:5`は常に`Flavor.development`。Android flavorは存在するが、native flavorから対応するDart entryを強制していない。`APP_ENV`も`AppEnv`のflavor判定には使われない
- 影響: production applicationIdでデモモードやdevelopment設定を使う誤ビルドを防げない

#### H-02 Outbox同期が再起動・実接続回復・ユーザー復元で確実に再開しない

- 証拠: `SyncEngine`生成時に初回`drain`を行わず、既定の`AlwaysOnlineConnectivity.onlineChanges`は空ストリーム。OS接続監視は未実装。`memory`と`oshi`にはリモートpullがない
- 影響: 書込み直後の一度の送信に失敗すると、次の操作まで残り続ける。再インストール・別端末・キャッシュ消失後に思い出と推しを復元できない
- 追加リスク: LWWがクライアントの`updated_at`同士を直接比較しており、端末時計のずれを盲信する

#### H-03 センシティブ情報を含むSQLiteが平文

- 証拠: `lib/bootstrap.dart:88-91`は通常の`NativeDatabase`を開く。座席、整理番号、予約番号、住所、交通・宿泊、メモ、ローカル画像パスが同DBへ保存される
- 影響: 端末バックアップやファイル取得時の漏えい耐性が要件を満たさない

#### H-04 選択画像をアプリ管理領域へコピーせず、一時・外部パスを永続化する

- 証拠: `memory_edit_screen.dart:59-61`と`child_editors.dart:138-140`が`ImagePicker`の`picked.path`をそのまま保存する
- 影響: OSの一時ファイル整理、権限変更、再起動後に画像が消える。チケット画像にも同じ問題がある

#### H-05 デザイン仕様を成立させるドメイン／DB項目が不足する

- 欠落: 現場ヒーロー画像、参加状態、思い出お気に入り、推しグループ／メンバー画像、推しグループお気に入り、ユーザー定義記念日、画像代替説明
- 証拠: `Genba`に画像・参加状態なし、`MemoryEntry`に`isFavorite`なし、`OshiGroup`／`OshiMember`に画像なし。DriftとSupabase migrationにも対応列がない
- 影響: 画像モックに見せるため固定ダミー値を置くしかなく、`design-spec.md` §12.1、§15を満たせない

#### H-06 主要6領域の情報階層が画像基調デザインへ未追随

- テーマ: `app_theme.dart:9`のseedはピンク`#E85A8A`で、指定Primary `#7B5CFF`や意味ベースTokenがない
- ホーム: 次の現場ヒーロー、4分割準備ショートカット、今後の現場の階層がない
- 現場詳細: ヒーロー領域と「概要/Todo/チケット/交通/宿泊/メモ」タブがなく、1本の長い画面
- 思い出一覧: 「すべて/参戦済み/お気に入り」タブとお気に入り操作がない
- 思い出詳細: 大型カルーセル、`1/N`、感想/セトリ/グッズ/メモの閲覧タブがない
- マイ推し: プロフィール、アバター列、導出統計、次の現場、誕生日・記念日の構成がない
- 設定: 階層型設定、テーマプレビュー、推しカラーパレットがない
- 共通Design System: `AppCard`、`HeroEventCard`、`PhotoMemoryCard`等が未実装

#### H-07 中止と手動終演の運用が主要導線で不完全

- 証拠: 未来の中止現場は`isUpcoming`で除外され、思い出には公演終了後まで入らないため通常一覧から消える。`manualEndedAt`を戻す明確な操作もない
- 影響: 中止済み予定の確認・編集・取消、誤タップからの復旧が難しい

### Medium

#### M-01 presentationがRepositoryへ直接書込み、Resultを無視する箇所が多い

- 例: `genba_detail_screen.dart:375-377, 488-490`。失敗時のロールバックやユーザー通知がなく、application層の責務が薄い

#### M-02 iOS構成が要件未達

- `IPHONEOS_DEPLOYMENT_TARGET = 13.0`で要件のiOS 15以上と不一致
- development / staging / productionのXcode schemeがない
- 写真選択に必要な用途説明キーが`Info.plist`にない

#### M-03 テストが新デザイン、ユーザー分離、完全な中心フローを証明しない

- Golden testなし、推しカラー8色、200%文字、360dp、ダーク、Semanticsの体系的検証なし
- integration testは現場登録までで、準備→当日→思い出→再起動復元を通していない
- 2ユーザー切替、ログアウト後キャッシュ不可視、再起動Outbox復旧、永続画像のテストがない

#### M-04 ローカルDB制約・索引が弱い

- owner/date、genba_id、Outbox owner/status等のローカル索引がない。Drift側のFKもなく、整合性をRepositoryの手続きへ依存する

#### M-05 実装状況とトレーサビリティが現状と矛盾する

- `implementation-status.md`前半に「Flutter未導入・テスト未実行」が残る一方、後半では実装済み
- `requirements-traceability.md`は既に存在する設定・チュートリアル等も未実装表記があり、§19は全項目未実装のまま

## 5. デザイン仕様カバレッジ

| 領域 | 判定 | 現状 |
|---|---|---|
| コンセプト・配色・Token | 未達 | ピンクseedの汎用Materialテーマ |
| 共通コンポーネント | 未達 | 画面固有Card/ListTile中心 |
| 5タブ | 達成 | `StatefulShellRoute` + `NavigationBar` |
| ホーム | 一部達成 | 現場一覧・当日カードはあるがヒーロー階層なし |
| 現場詳細 | 一部達成 | CRUDはあるがヒーロー／タブなし |
| 思い出一覧 | 一部達成 | 表紙写真は出るがフィルタ／お気に入りなし |
| 思い出詳細 | 一部達成 | 記録閲覧は可能だがカルーセル／タブなし |
| マイ推し | 一部達成 | CRUDはあるがプロフィール型情報階層なし |
| 設定・テーマ | 一部達成 | ThemeMode切替のみ。プレビュー／推しカラーなし |
| 画像状態・永続性 | 未達 | 一時パス依存、状態別placeholder不足 |
| レスポンシブ・a11y | 証拠不足 | 基本Tooltip等はあるが受入条件の自動テストなし |

## 6. 修正実行順

`R1 → R2 → R3 → R4`を先に完了し再レビューする。その後、`R5 → R6 → R7`を実行する。R8で全体を再監査する。Critical／Highが残る間は`docs/post-fable-phase-prompts.md`の通常Phaseへ進まない。

---

## 修正パッケージ R1: 認証主体ごとのローカルデータ完全分離

- 対象: C-01、M-04のowner関連部分
- 推奨モデル: **Claude Opus 4.8**
- 理由: 認証、Drift、Repository、Outbox、pull削除、ログアウト、データ移行を横断し、誤ると情報漏えい・データ損失になる
- 前提: なし
- 完了後: unit / repository / widget / 2ユーザー切替integration、format、analyze

```text
あなたはFlutter/Drift/Supabaseのセキュリティ修復を担当するシニアエンジニアです。対象リポジトリは現在開いている OshiTrip です。

最初に docs/requirements.md、docs/design-spec.md、docs/architecture.md、docs/adr/0005-local-persistence-drift.md、docs/adr/0008-authorization-and-data-protection.md、docs/current-program-review-and-remediation-prompts.md と、認証・DB・Repository・Outbox・同期関連コードを全文読んでください。

解消対象はC-01です。現在、GenbaRepositoryImpl、MemoryRepositoryImpl、OshiRepositoryImpl、OutboxStoreがowner_idで読み取りを絞らず、flavor共通SQLiteを複数ユーザーで共有しています。さらにGenbaRepositoryImpl._pullTableは、現在ユーザーのRLS結果にない別ownerのローカル行を削除し得ます。

次を実装してください。

1. 認証済み主体を示す明示的なLocalDataScope/UserScopeをapplication/data境界へ導入し、未認証状態ではユーザーデータのwatch/read/write/syncを開始しない。
2. genbas、全子テーブル、memory、oshi、outbox、ユーザー固有KV、下書きのすべてをowner_idで絞る。IDだけで更新・削除するAPIもownerを併用し、別ownerの同一ID・推測IDを操作できないようにする。
3. pullの差分削除は「現在ownerのローカル集合」と「現在ownerのRLS結果」の間だけで行う。他ownerの行を絶対に読まず、変更せず、削除しない。
4. Outboxのpending取得、状態集計、retry、deleteSynced、競合確認を現在ownerへ限定する。別ownerの操作をremoteへ渡さない。
5. ログアウト、ユーザー切替、アカウント削除時のポリシーを実装する。前ユーザーのデータを画面へ出さず、必要ならユーザー別DBまたはowner partitionを採用する。選択理由と移行方針をdocs/decisions.mdへ記録する。
6. 既存の単一ユーザーデータを失わない安全なmigrationを用意する。owner不明データを別ユーザーへ推測帰属させない。
7. authState復元前の一瞬に前ユーザーのキャッシュが表示されないよう、Providerのライフサイクルを修正する。
8. owner/date、genba_id、owner/status等、今回の問い合わせに必要なDrift索引と親子整合制約を追加する。SQLiteで安全に表現できない制約はtransactionとテストで担保する。

受入条件:

- user-Aで保存→ログアウト→user-Bログイン時、Aの現場・チケット・交通・宿泊・Todo・メモ・思い出・推し・Outbox・下書き・同期件数が一切見えない。
- Bのrefresh/pull/delete/retryがAのローカル行とOutboxを変更しない。
- 未認証中はユーザー固有ストリームが空または認証待ちであり、直前ユーザーの値を返さない。
- user-Aへ戻る場合の保持方針が仕様どおりで、意図せぬ消失がない。
- アカウント削除成功後、対象ユーザーのローカルDB・KV・下書き・画像参照が削除される。

必須テスト:

- 2ユーザーを同一DBで切り替えるRepositoryテスト
- 別ownerの同一entity ID、子ID、Outboxを操作できない負例
- pull差分削除が別ownerを消さない回帰テスト
- ログアウト中の不可視性とユーザー復帰テスト
- account delete後のローカル消去テスト

生成コードを更新し、dart format、dart analyze、flutter testを実行してください。Android/iOS/DBテストは利用可能な環境だけ実行し、未実行を成功と書かないでください。R2以降の同期方式やデザインUIはまだ作り替えません。無関係な変更、テストskip、常時成功stub、秘密情報、実ユーザーデータの追加は禁止です。

最後に変更ファイル、設計判断、migration、実行コマンドと成否、残課題を報告してください。
```

## 修正パッケージ R2: 同期ライフサイクル・復元・競合制御

- 対象: H-02
- 推奨モデル: **Claude Opus 4.8**
- 理由: 再起動、接続復帰、認証復元、サーバー冪等性、競合、pullを一貫させる必要がある
- 前提: R1

```text
現在開いている OshiTrip で、R1完了後の同期基盤を本番利用可能な形へ修復してください。docs/requirements.md §15.3、docs/architecture.md、ADR-0005、docs/current-program-review-and-remediation-prompts.md、core/sync、core/network、全Repository、Supabase migrations/testsを読んでください。

解消対象はH-02です。現状はSyncEngine生成時の初回drainがなく、AlwaysOnlineConnectivityは変化を通知せず、OS接続回復を検知しません。memory/oshiのremote pullもなく、LWWは端末updated_atを盲信します。

実装内容:

1. 認証セッション復元完了、アプリ起動・resume、オンライン復帰、ローカルenqueueの各イベントで、現在ownerのOutboxを安全にdrainするSyncCoordinatorをapplication層に実装する。
2. 実接続監視を安定パッケージで実装する。ただし接続あり=インターネット到達可能とはみなさず、通信失敗をpendingへ戻す。
3. 指数バックオフ、ジッター、最大間隔、手動再試行を導入し、再起動後もattempt/status/next_retry_atを復元する。多重drainと二重送信を防ぐ。
4. genba子データだけでなくmemory、memory photos metadata、setlist、goods、visited places、oshi groups/membersをキャッシュ先行→owner限定pullできるようにする。ローカル未同期変更を上書きしない。
5. mutation ledgerと実データ変更をサーバー側の1 transaction/RPCで冪等に適用する。クライアントが変更成功後・ledger記録前に落ちても二重適用しない。
6. 競合判定を端末時計だけに依存させない。サーバーversionまたはserver timestampを用いた方針を設計し、既存データmigrationと競合記録を実装する。将来のフィールド単位mergeを妨げない。
7. pending/syncing/synced/failed/conflictのUI状態が実際のowner別状態と一致するようProviderを修正する。

受入条件:

- オフライン書込み→アプリ終了→再起動→認証復元→オンライン復帰で自動同期する。
- 同一mutationを何度再送してもリモート変更は1回だけ。
- user-Aの同期中にuser-Bへ切り替えてもAの操作をBセッションで送らない。
- 新規端末相当の空キャッシュへgenba、準備、memory、oshiが復元される。
- 端末時計が大きくずれても、誤ったLWWで新しいサーバーデータを失わない。

Fake接続、再起動を模したDB再open、認証切替、通信切断位置、二重drain、RPC冪等性、競合のunit/repository/pgTAPテストを追加してください。format、analyze、flutter test、可能ならintegration_testとsupabase test dbを実行します。テストskip、sleep依存の不安定テスト、常時成功stubは禁止です。最後に変更ファイル、migration/RPC、検証結果、未確認事項を報告してください。
```

## 修正パッケージ R3: 端末暗号化と画像の耐久保存

- 対象: H-03、H-04
- 推奨モデル: **Claude Opus 4.8**
- 理由: 暗号鍵管理、平文DB移行、画像の機密区分、バックアップ除外、失敗時復旧が必要
- 前提: R1、R2

```text
現在開いている OshiTrip で、端末保存の暗号化とローカル画像の耐久保存を実装してください。requirements.md §15.2、design-spec.md §12、ADR-0005/0008、docs/current-program-review-and-remediation-prompts.md、bootstrap、Drift、画像選択・表示・アップロード境界を読んでください。

対象はH-03/H-04です。通常SQLiteへ座席・整理番号・予約番号・住所等を平文保存し、ImagePickerの一時パスをそのまま永続化しています。

実装内容:

1. Flutter stableとiOS/Androidで保守可能な暗号化方式を選び、SQLite全体のSQLCipher相当または同等の保護を導入する。鍵はOS Keychain/Keystoreに保存し、ログ・dart-define・ソースへ置かない。
2. 既存平文DBから暗号化DBへの一度だけの安全なmigration、電源断時のロールバック、失敗時の明示エラーを実装する。migration完了前に平文を削除しない。
3. 画像選択後、思い出写真・現場ヒーロー・推し画像・チケット画像を用途別のアプリ管理領域へcopyし、推測困難なファイル名、owner別ディレクトリ、atomic writeを使う。
4. チケット画像を最も機密度の高い区分として扱い、OSバックアップ除外、ログ除外、ヒーロー／思い出表紙への自動流用禁止を担保する。
5. DBにはアプリ管理上の相対参照またはasset IDを保存し、絶対一時パスへ依存しない。ファイル欠損、権限喪失、削除済みを型付き状態へ変換する。
6. レコード削除、アカウント削除、画像差替え時に孤立ファイルを安全に清掃する。別ownerのファイルは触らない。
7. iOS/Androidの写真権限説明を追加し、権限拒否でも主要フローを継続できるUIにする。

受入条件:

- アプリ再起動とImagePickerの一時ファイル削除後も、コピー済み画像を表示できる。
- DBファイルを直接開いても機密本文を平文検索できない。
- 鍵消失、migration失敗、容量不足、画像コピー失敗を成功扱いにせず、入力データを可能な限り保持する。
- user-Bはuser-Aの画像参照も物理ファイルも取得できない。

暗号化migration、再open、鍵不一致、画像コピー、欠損、削除、owner分離をテストしてください。format/analyze/flutter testと、利用可能ならAndroid/iOS buildを実行してください。独自暗号の発明、固定鍵、秘密情報追加、テストskipは禁止です。選定ライブラリと脅威モデルをdocs/decisions.mdへ記録し、変更ファイル・検証結果・残課題を報告してください。
```

## 修正パッケージ R4: flavor・iOS・CIの誤構成防止

- 対象: H-01、M-02
- 推奨モデル: **Claude Sonnet 5**
- 理由: 原因と設定範囲が明確なプラットフォーム修正
- 前提: R1〜R3と独立して実行可能だが、統合確認はR3後

```text
現在開いている OshiTrip のdevelopment/staging/production構成を修正してください。ADR-0006/0007、docs/setup.md、bootstrap/env、Android Gradle、iOS Xcode project/schemes、CIを読んでください。

H-01/M-02を解消します。

- Androidの各productFlavorが対応するlib/main_<flavor>.dartを使う手順をCIとREADMEで固定し、production applicationId + development entryの組合せをbuild-timeまたは起動時に必ず拒否する。APP_ENVを使うならnative flavorと一致検証し、使わないなら削除して二重の真実を作らない。
- 汎用lib/main.dartからproduction native buildがdevelopment/demoで動かない構成にする。
- development/staging/productionのアプリ名、applicationId/bundle ID、Supabase設定を分離する。
- iOS deployment targetを15.0へ統一し、3 flavorのxcconfigとshared schemeを作る。各schemeが正しいDart entryと環境を使う。
- Info.plistへ実際に利用する写真権限の日本語説明を追加する。不要な権限は追加しない。
- CIで全flavorの設定不備、productionのdemo fallback禁止、Android development build、macOS iOS development buildを検証する。release signingは秘密情報なしで無理に構成しない。
- Android releaseでdebug signingを使う現状は本番リリース不可として明示し、安全な署名注入境界を用意する。

AppEnv unit test、entry/flavor不一致テスト、production設定欠落テストを追加し、format/analyze/flutter test、可能なbuildを実行してください。秘密鍵や実Supabaseキーをコミットせず、未実行buildを成功と報告しないでください。最後に変更ファイル、実行コマンド、各環境の起動コマンド、残課題を報告してください。
```

## 修正パッケージ R5: 主要操作のapplication層と復旧可能性

- 対象: H-07、M-01、integration test不足の中心フロー部分
- 推奨モデル: **Claude Sonnet 5**
- 理由: 既存ドメインを保った局所的な状態操作・UIエラー処理・回帰テスト
- 前提: R1、R2

```text
現在開いている OshiTrip で、現場・Todo・準備情報・思い出の主要操作をapplication層へ整理し、失敗から復旧できるよう修正してください。requirements.md §6〜§8、architecture.md、design-spec.md、現行controller/provider/presentationを読んでください。

対象はH-07/M-01です。

1. presentationからRepositoryを直接呼びResultを捨てる操作を、用途別Notifier/UseCaseへ移す。loading、楽観更新、成功、型付き失敗、ロールバックを一貫して表現する。
2. Todo完了、交通/宿泊の要否、子データ削除、現場中止、手動終演、思い出お気に入り（R6後に存在する場合）の二重タップを安全にする。
3. 未来の中止現場を現場一覧から消さず、「中止」区分・フィルタ等で確認、編集、日程変更、削除できる。思い出側へ移る条件は要件と明示参加状態に合わせる。
4. 「終演した」操作に確認と取消/訂正手段を設ける。日程・終演時刻変更後に状態を再導出し、データを複製しない。
5. 失敗時にSnackBar等で理由と再試行を示し、成功していない操作を成功表示しない。
6. 現場作成時の推しグループ／メンバー選択が実データとつながり、未登録時にも導線があることを確認・修正する。

中心フローintegration testを、初回起動→ログイン→現場登録→チケット/交通/宿泊/Todo/メモ→当日→終演→思い出入力→アプリ再起動後復元まで拡張してください。未来の中止、手動終演取消、保存失敗ロールバック、二重タップもテストします。

デザインの全面刷新はR7で行うため、このパッケージでは操作状態と責務を整えます。無関係な色・レイアウト変更、テストskip、常時成功stubは禁止です。format/analyze/flutter testと可能なintegration testを実行し、変更ファイル・結果・残課題を報告してください。
```

## 修正パッケージ R6: 画像デザイン用ドメイン・migration・Repository

- 対象: H-05、design-spec.md §12.1
- 推奨モデル: **Claude Opus 4.8**
- 理由: Drift/Supabase/RLS/Outbox/freezed migrationを横断し、既存データを保持する必要がある
- 前提: R1〜R3

```text
現在開いている OshiTrip に、docs/design-spec.mdの画像基調UIを固定ダミーなしで成立させるデータ契約を実装してください。requirements.md §2.5/§6〜§9/§13/§19、design-spec.md全体、architecture.md、ADR-0005/0008、既存domain/Drift/Supabase/Repository/Outboxを読んでください。

H-05を解消します。実装対象:

1. 現場ヒーロー画像をチケット画像と完全に別用途・別モデルで追加する。local asset ID、storage path、upload state、alt text等を画像モデルまたは明確な型で持たせる。
2. Genbaに明示参加状態 planned / attended / notAttended / canceled を追加する。日時から自動的にattendedへせず、既存isCanceledとの移行・整合規則を決める。
3. 思い出単位のisFavoriteを追加し、一覧・詳細から更新できるRepository/UseCaseを用意する。表紙は既存MemoryPhoto.isCoverを利用し、同一思い出のcover一意性をDB制約またはtransactionで担保する。
4. OshiGroup/OshiMemberに画像参照とalt textを追加し、グループお気に入り、ユーザー定義記念日を正規化する。写真なしはイニシャルfallback可能にする。
5. 現場数、思い出数、参戦数、次の現場、誕生日・記念日は保存固定値ではなくowner限定のQuery/Domain serviceで導出する。
6. Drift schemaVersion/migration、Supabase migration、RLS、owner親子整合、index、JSON/freezed、mapper、Outbox、remote pullを更新する。
7. 既存データは安全な既定値へ移行する。過去公演を勝手にattendedと推測しない。既存isCanceled=trueはcanceledへ明示移行する。
8. チケット画像をヒーロー・思い出cover候補へ絶対に含めない。

受入条件:

- すべて実データから表示でき、サンプル固定値をproductionへ入れない。
- favoriteと参加状態は再起動・同期後も保持される。
- 「参戦済み」はattendedだけを返す。
- cover一意性、owner分離、RLS正負ケースがテストされる。
- 画像なしでも各Queryが正常に縮退する。

build_runnerを実行し、domain/repository/migration/pgTAPテストを追加してください。format/analyze/flutter test、可能ならsupabase test dbを実行します。既存ユーザーのデータ破棄、認可をUIだけで済ませること、常時成功stub、秘密情報追加は禁止です。変更ファイル、migration、検証結果、残課題を報告してください。
```

## 修正パッケージ R7: 「夜明け前の遠征ノート」Design Systemと主要6領域

- 対象: H-06、design-spec.md §1〜§15
- 推奨モデル: **Claude Fable 5**
- 理由: 共通Design Systemと6領域を横断する長時間の一括UI再構成が必要
- 前提: R1〜R6

```text
あなたはFlutterのリードUIエンジニア兼モバイルUX実装者です。現在開いている OshiTrip を、docs/design-spec.mdの「夜明け前の遠征ノート」へ一括で再構成してください。

最初にdocs/requirements.md §2.5/§6〜§9/§13/§15.4/§19、docs/design-spec.md、docs/architecture.md、docs/current-program-review-and-remediation-prompts.md、既存のdomain/application/presentation、R1〜R6の変更を読んでください。機能・セキュリティ・同期を壊さず、画像モックの完全なピクセルコピーではなく、情報階層、色、余白、カード、写真、状態、片手操作を一致させます。

実装内容:

1. Primary #7B5CFF、Primary Light #EEE9FF、Background #F8F6FC、Surface #FFFFFF、Text/Divider/Error/Oshi Accentを意味ベースDesign TokenとColorSchemeへ実装する。画面へ色コードを直書きしない。ライト／ダーク双方でWCAG AA相当を保つ。
2. AppScaffold、AppCard、HeroEventCard、EventListCard、StatusIconItem、SectionHeader、SegmentTabs、PhotoMemoryCard、OshiAvatar、CountStat、SettingsRow、EmptyState、LoadingSkeleton、SyncBadge、FavoriteButtonを再利用可能な小さなDesign Systemとして作る。
3. ホーム: 次の現場ヒーロー、残日数、日付/時刻/会場/公演名、Todo/交通/宿泊/チケット4分割状態、今後の現場、FAB。当日は既存の当日重要情報を最上位へ切替える。
4. 現場詳細: 写真または紫fallbackのヒーロー、可読オーバーレイ、概要/Todo/チケット/交通/宿泊/メモの横スクロールタブ。既存CRUDとResult状態を各タブへ接続し、巨大フォームにしない。
5. 思い出一覧: すべて/参戦済み/お気に入り、cover thumbnail、日付/公演/会場、写真数/セトリ/感想、お気に入り。孤立した思い出レコードは作らない。
6. 思い出詳細: 大型写真カルーセルと1/N、写真なし縮退、メタ情報、お気に入り、感想/セトリ/グッズ/メモの閲覧タブ、明確な編集入口。
7. マイ推し: グループプロフィール、画像/initial fallback、推しカラーring、横スクロールメンバー、導出統計3件、次の現場、誕生日/記念日。単なる登録数を参戦数と表示しない。
8. 設定: 階層型リスト、ライト/ダークpreview、推しカラー8色以上とcustom、選択ring/check、preview即時反映、危険操作分離。未実装通知等を押せる見せかけUIとして出さない。
9. 画像loading/error/offline/permission lost/deleted、写真なしplaceholderを実装する。権利処理済み素材または抽象gradientだけを使い、アーティスト・公演画像を同梱しない。チケット画像をヒーローや一覧に流用しない。
10. 360〜430dp、横向き、文字200%、keyboard、safe area、48dp tap target、Semantics/Tooltip、Reduce Motionを考慮する。固定高さで文字を切らない。
11. loading/empty/error/offline/dataを主要6領域で揃え、オフラインと最終同期状態を誤認させない。
12. StatefulShellRouteのタブ状態・スクロール位置を保持し、FABがBottom Navigationや最終カードを覆わないようにする。

テスト:

- Design Tokenと共通componentのWidget test
- 主要6領域のlight/dark、360dp、430dp、textScale 2.0、推しカラー8色
- 写真あり/なし、loading/error/offline、favorite/attendance/coverの実データ反映
- Semantics label、48dp tap target、色以外の状態表現
- 安定する範囲のGolden test。OSフォント差で不安定な全面Goldenだけに依存せず意味上のWidget testを主証拠にする
- 既存の中心フロー、routing、同期テストの回帰

format、analyze、flutter test、可能なintegration testとAndroid/iOS buildを実行してください。機能削除、Repositoryのpresentation直呼び復活、固定ダミー統計、利用不能ボタン、権利不明画像、テストskip、秘密情報追加は禁止です。

最後に、実装した画面と共通component、design-specの受入条件マトリクス、変更ファイル、検証結果、未確認事項を報告してください。
```

## 修正パッケージ R8: 最終回帰・文書整合・リリース判定

- 対象: M-03〜M-05、全修正の回帰
- 推奨モデル: **Claude Sonnet 5**（監査で複雑な認証・RLS・同期問題が出た場合、その修正だけClaude Opus 4.8へ切り出す）
- 前提: R1〜R7

```text
現在開いている OshiTrip のR1〜R7完了後成果を独立監査し、Critical/Highが0件になるまで限定修正してください。docs/fable-post-implementation-review-prompt.mdを監査手順として使い、requirements.md §1〜§19、design-spec.md、全ADR、current-program-review-and-remediation-prompts.mdを読みます。

必須作業:

1. 2ユーザー分離、ログアウト、アカウント削除、再起動Outbox、接続回復、冪等RPC、競合、暗号化migration、耐久画像、RLS/Storageを再監査する。
2. 初回起動→ログイン→現場登録→準備→当日→終演→思い出→再起動復元のE2Eを確認する。
3. design-spec主要6領域を写真あり/なし、light/dark、360/430dp、文字200%、推しカラー8色、loading/empty/error/offline/data、Semanticsで確認する。
4. production/stagingのdemo fallback禁止、3 flavor、iOS 15、権限説明、CIを確認する。
5. TODO/FIXME/UnimplementedError/空catch/skip/常時成功stub/秘密情報/実ユーザーデータ/権利不明画像を検索する。
6. requirements-traceability.mdを実装ファイルとテストへ正確に接続し、implementation-status.md、decisions.md、follow-up-work.md、README/setupを実証結果だけで更新する。古い「Flutter未導入」等の矛盾を解消する。
7. format、analyze、全test、integration、Android build、iOS build、supabase test dbを利用可能な環境で実行する。環境不足とコード失敗を区別する。

Critical/Highが見つかった場合は、その場で推測修正せず原因と影響範囲を特定する。認証/RLS/同期/暗号化/データmigrationはClaude Opus 4.8向けの独立修正プロンプトとして切り出し、局所UI/テスト/文書はこのセッションで修正してよい。テストの削除・skip・弱体化、常時成功stubは禁止です。

最終報告はPASS/CONDITIONAL PASS/FAIL、要件・design-specマトリクス、指摘、変更ファイル、全コマンド結果、未確認事項、残余リスク、次に実行するpost-Fable Phaseを示してください。
```

## 7. 次に行うこと

最初に実行するのは通常Phase 1ではなく、**修正パッケージR1**である。R1〜R4完了後に`docs/fable-post-implementation-review-prompt.md`で中間再レビューし、Critical／Highが解消してからR5〜R7へ進む。

## 8. R8監査是正パッケージ（2026-07-04, Claude Sonnet 5によるR8独立監査結果）

R8（`docs/fable-post-implementation-review-prompt.md`準拠）の独立監査でCritical 0件・High 3件を検出した。3件はいずれも認証／同期／RLSの複雑な領域のため、この場での推測修正を行わず、Claude Opus 4.8向けの独立修正パッケージとして切り出す。監査全文と全指摘の重大度別一覧はセッション報告（本ファイルには含めない）を参照。局所的なUI/テスト/文書修正（ロガーのキー正規化バグ、`decisions.md`等のドキュメント更新）はR8監査セッション内で完了済み。

### 修正パッケージ R8-A: Outbox競合(conflict)状態が永久に解消されない

- 対象指摘: E-1（High）
- 推奨モデル: **Claude Opus 4.8**
- 選定理由: 同期エンジンの状態遷移とOutbox設計全体に関わる複雑な同期競合の修正
- 前提: なし（R1〜R7完了状態が前提）
- 完了後に再実行するテスト: `flutter test test/core/sync_engine_test.dart test/core/outbox_backoff_test.dart`、新規追加する競合解消の回帰テスト、`flutter test`（全件）

```text
現在開いている OshiTrip（c:\Users\naman\OneDrive\ドキュメント\Claude\claude code\OshiTrip）を対象に、Outbox同期の「競合(conflict)状態が永久に解消されない」バグを修正してください。

最初に次を読んでください。
- docs/architecture.md §7/§9/§11（Repository境界・エラー表現・認可）
- docs/decisions.md のD-60〜D-71（同期ライフサイクル・版CAS）、D-118〜D-122（現場更新競合の是正）
- lib/core/sync/outbox_store.dart、lib/core/sync/sync_engine.dart、lib/core/sync/outbox_operation.dart、lib/core/sync/remote_pull.dart
- lib/core/widgets/sync_status_banner.dart、lib/app/design_system/sync_badge.dart
- supabase/migrations/0006_sync_versioning.sql（apply_mutation RPCの版CAS）

指摘と証拠:
OutboxStore.retryFailed()（lib/core/sync/outbox_store.dart:166-177）は`status = 'failed'`の行のみをpendingへ戻し、`status = 'conflict'`の行には一切触れません。OutboxStore.hasPendingFor()（同ファイル181-197行）は`status.isNotIn(['synced'])`でconflict行も「未同期あり」として扱うため、remote_pull.dart:44の`if (await outbox.hasPendingFor(...)) continue;`によりconflictになったエンティティはpullでも上書きされず、ローカルとサーバーの内容が永久に乖離します。UIには同期状態バナー（sync_status_banner.dart）でconflict件数を表示していますが、それを解消する操作（再試行・破棄・サーバー優先で上書き等）が一切実装されていません。

再現条件: 同一エンティティ（例: Todo）を2台の端末でほぼ同時に編集し、版CAS（apply_mutation RPCのp_base_version不一致）でどちらか一方がconflictになった状態を作ると、そのエンティティのOutbox行はconflictのまま固定され、以後の編集も再びconflictになりやすくなり、pullでも回復しません。

変更してよい範囲:
- lib/core/sync/outbox_store.dart（新しい解消メソッドの追加、既存メソッドの拡張）
- lib/core/sync/sync_engine.dart（解消時のremote_versionsキャッシュ更新・再pull連携）
- lib/core/sync/remote_pull.dart（解消済みconflictの扱い）
- lib/core/widgets/sync_status_banner.dart、必要なら新規UI（確認ダイアログ等）
- 各RepositoryImpl（lib/features/*/data/*_repository_impl.dart）が解消操作を呼び出す導線
- 関連テストの追加

変更してはいけない範囲:
- apply_mutation RPCの版CASロジック自体（supabase/migrations/配下）は変更しない（正しく動作している）
- R1〜R7で確立したowner分離・認証切替の排他制御（SyncAuthSnapshot、pauseForAuthTransition等）は壊さない
- 既存の同期テストを削除・弱体化しない

期待動作と受入条件:
- conflictになったOutbox行に対し、ユーザーが「サーバーの内容を使う（この端末の変更を破棄）」を選べる。選択すると該当opをOutboxから削除し、remote_versionsのキャッシュをクリアしてから該当エンティティを強制再pullし、ローカル行がサーバー内容で上書きされる。
- 上記操作後、同期状態バナーのconflict件数が正しく減る。
- 「破棄」を選ばない限り、ローカルの変更内容そのものは消えない（誤操作防止のため、破棄には確認ダイアログを要求する）。
- owner分離・認証切替時の安全性（C-01）を壊さない。別ownerのconflict行を解消できないこと、解消操作もowner限定であることをテストで担保する。

必要な回帰テスト:
- OutboxStoreの新規解消メソッドの単体テスト（対象owner限定・別owner不可侵）
- SyncEngineまたはRepositoryレベルで「conflict解消→強制pull→ローカル行がサーバー値になる」ことを検証する統合的なテスト
- 既存のtest/core/sync_engine_test.dart、test/core/outbox_backoff_test.dartが回帰しないこと

検証: dart format、dart analyze、flutter test（全件）を実行し結果を報告してください。integration_test/Android buildは環境があれば実行し、無ければ未実行と明記してください。

無関係な変更、テストのskip、常時成功stub、秘密情報追加は禁止です。実施後に変更ファイル、検証結果、残課題を報告してください。
```

### 修正パッケージ R8-B: RLS/pgTAPカバレッジ欠如とトリガー堅牢化

- 対象指摘: F-2（High）、F-1（Medium）、F-3（Medium）
- 推奨モデル: **Claude Opus 4.8**
- 選定理由: RLSポリシー・pgTAPテスト・トリガー関数の追加はSupabase/Postgresセキュリティレビューの専門領域
- 前提: なし
- 完了後に再実行するテスト: `supabase test db`（Docker利用可能な環境）。不可なら静的検証（plan数とアサーション数の一致等）を実施し、未実行を明記する。

```text
現在開いている OshiTrip（c:\Users\naman\OneDrive\ドキュメント\Claude\claude code\OshiTrip）を対象に、RLS/pgTAPカバレッジの欠如とオーナーシップトリガーの堅牢化を行ってください。

最初に次を読んでください。
- docs/adr/0008-authorization-and-data-protection.md
- docs/decisions.md のD-40〜D-71（owner分離）、D-133〜D-150（R6画像/参加状態）、D-147（記念日オーナー整合の既知の弱点）
- supabase/migrations/0001_init.sql〜0007_image_design_fields.sql（全件）
- supabase/tests/0001_rls_genbas.sql〜0004_image_design_fields.sql（全件）

指摘と証拠:

1. （High）`transports`、`lodgings`、`genba_memos`、`setlist_items`、`goods_items`、`visited_places`、`profiles`の7テーブルには正例・負例いずれのpgTAPテストも存在しません（`supabase/tests/*.sql`にテーブル名でgrepしても一致しない）。`outbox_operations`には正例テストのみで負例（別ユーザーが読み書きできないことの検証）がありません。これらのテーブルは`lodgings.address`、`transports.reservation_number`等、要件§15.2が名指しする機微情報を保持します。RLS自体は`0001`〜`0004`の各マイグレーションで他テーブルと同一パターン（`for all using (owner_id = auth.uid())`）で実装済みですが、自動テストによる担保がありません。

2. （Medium）`performances`テーブル（supabase/migrations/0002_oshi_performances.sql:104-110）にはSELECT/INSERT/UPDATEポリシーのみでDELETEポリシーが無く、投稿者が自分の投稿を削除できません。意図的な仕様（公開マスタは削除させない）なのか実装漏れなのか、decisions.mdにもfollow-up-work.mdにも記録がありません。

3. （Medium）`enforce_oshi_anniversary_owner()`トリガー関数（supabase/migrations/0007_image_design_fields.sql:104-131）は`member_owner`を取得しながら`new.owner_id`と直接比較せず、`oshi_members.owner_id`が常に親グループのownerと一致するという別トリガー（`enforce_oshi_member_owner`）の不変条件に暗黙に依存しています。decisions.md D-147で開発者自身がこの設計を認識し、テストで代替担保していますが、トリガー自体に直接チェックはありません。

変更してよい範囲:
- supabase/migrations/ 配下への新規マイグレーションファイルの追加（既存マイグレーションの内容変更は不可、追記のみ）
- supabase/tests/ 配下への新規pgTAPテストファイルの追加、または既存ファイルへのアサーション追加（plan数の整合を必ず取ること）
- docs/decisions.md、docs/follow-up-work.mdへの判断記録の追記

変更してはいけない範囲:
- 既存マイグレーション（0001〜0007）の内容を変更しない（新規マイグレーションで追加・修正する）
- 既存pgTAPアサーションを削除・弱体化しない
- クライアント側（lib/）のRepository実装や画面は変更しない（本パッケージはサーバー側のみ）

期待動作と受入条件:
1. 上記7テーブル＋`outbox_operations`それぞれについて、最低1件の正例（owner本人はCRUDできる）と1件の負例（別ownerは読み書きできない、RLSでブロックされる）のpgTAPアサーションが追加されている。
2. `performances`のDELETEについて、要件§10を再確認した上で「投稿者本人が削除できる」ポリシーを追加するか、削除不可が意図的である理由をdocs/decisions.mdに明記し、pgTAPで「投稿者でもDELETEできないこと」を明示的に検証するテストを追加する（いずれかを選び、無記載のまま放置しない）。
3. `enforce_oshi_anniversary_owner()`に`new.owner_id`との直接比較を追加し、たとえ`enforce_oshi_member_owner`の不変条件が将来崩れても記念日のオーナー不一致を検出できるようにする。既存のdecisions.md D-147の記述を更新し、直接チェックへ変更した理由を記録する。

必要な回帰テスト:
- 新規pgTAPアサーション（上記2点）
- 既存pgTAPアサーション（0001〜0004）が全て回帰しないこと（plan数とアサーション数の一致を確認）

検証: `supabase test db`をDocker等が利用可能な環境で実行し、結果を報告してください。実行できない場合は、各SQLファイルのplan数と実アサーション数（`results_eq`/`throws_ok`/`lives_ok`の出現数）が一致することを静的に確認し、「未実行」であることを明記してください（成功と報告しない）。

無関係な変更、テストのskip、常時成功stub、秘密情報追加は禁止です。実施後に変更ファイル、検証結果、残課題を報告してください。
```

### 修正パッケージ R8-C: Supabase通信のタイムアウト欠如とアカウント削除の二重タップ防止

- 対象指摘: H-A（High）、E-2（Medium）
- 推奨モデル: **Claude Opus 4.8**
- 選定理由: SyncEngineの認証切替排他制御（pauseForAuthTransition）と絡む変更のため、複数層にまたがる原因調査が必要
- 前提: なし（R8-Aと同時並行可、依存関係なし）
- 完了後に再実行するテスト: `flutter test test/core/sync_engine_test.dart test/notifier/account_controller_test.dart`、新規タイムアウトテスト、`flutter test`（全件）

```text
現在開いている OshiTrip（c:\Users\naman\OneDrive\ドキュメント\Claude\claude code\OshiTrip）を対象に、Supabase通信の無期限ハングを防ぐタイムアウト導入と、アカウント削除の二重タップ防止を行ってください。

最初に次を読んでください。
- lib/bootstrap.dart（Supabase.initialize呼び出し）
- lib/core/sync/sync_engine.dart、lib/core/sync/supabase_remote_mutation_client.dart、lib/core/sync/session_refresher.dart
- lib/features/auth/data/supabase_auth_repository.dart、lib/features/settings/data/supabase_account_repository.dart、lib/features/memory/data/supabase_photo_uploader.dart
- lib/features/settings/application/account_controller.dart
- lib/features/genba/application/genba_actions_controller.dart（二重タップ防止の既存パターン、_run参照実装）
- lib/core/error/result.dart（guardResultのTimeoutException→NetworkFailure変換）
- docs/decisions.md のD-49〜D-53（認証切替の排他制御）

指摘と証拠:

1. （High）`Supabase.initialize()`（lib/bootstrap.dart:83-88）に`httpClient`のタイムアウト設定が無く、`supabase_remote_mutation_client.dart`のRPC呼び出し、`supabase_auth_repository.dart`の各認証操作、`supabase_photo_uploader.dart`のアップロードにも`.timeout(...)`がありません。`SyncEngine._drainOnce()`（sync_engine.dart:134-230）は`snapshot.remote.apply(op)`を`await`しており、これがハングすると`_running`フラグが解除されず`_inFlight`（`pauseForAuthTransition()`が待つCompleter）も永久に完了しません。`AccountController.deleteAccount()`（lib/features/settings/application/account_controller.dart:48）は`await engine.pauseForAuthTransition();`をtry/finallyの外で呼んでおり、ここがハングすると同関数のfinally節（80行目、コメントで「AsyncLoadingのまま固まらないようにする」と明記）が実行されず、アカウント削除画面が無期限にスピナー状態のまま固まります。

2. （Medium）`AccountController.deleteAccount()`（同ファイル37-82行）には他のコントローラ（GenbaActionsController、MemoryActionsController、OshiActionsController）と同じ操作キー単位の二重タップ防止（`_run`パターン）が実装されておらず、削除ボタンの連打で`deleteAccount()`が並行して2回呼ばれ得ます。

変更してよい範囲:
- lib/bootstrap.dart（Supabase.initializeへのhttpClient/タイムアウト設定追加）
- lib/core/sync/supabase_remote_mutation_client.dart、lib/features/auth/data/supabase_auth_repository.dart、lib/features/settings/data/supabase_account_repository.dart、lib/features/memory/data/supabase_photo_uploader.dart（各呼び出しへの.timeout追加）
- lib/features/settings/application/account_controller.dart（二重タップ防止の追加）
- 関連テストの追加・拡張

変更してはいけない範囲:
- SyncEngineの認証切替排他制御（pauseForAuthTransition/resumeAfterAuthTransition/SyncAuthSnapshot）の設計自体は変更しない。タイムアウトはその内側（実際のHTTP呼び出し）に追加する。
- 既存のGenbaActionsController等の二重タップ防止パターン（操作キー単位のSet<String>ガード）は変更せず、同じパターンをAccountControllerへ適用する。
- 暗号化・DB移行・RLS関連のコードは変更しない。

期待動作と受入条件:
1. すべてのSupabase呼び出し（RPC、Auth、Storage）に妥当なタイムアウト（例: 10〜30秒、既存のconnectivityProviderの5秒probeとは別に設定してよい）が設定され、タイムアウト時は`guardResult`経由で`NetworkFailure`（またはそれに準ずる型）に変換され、Outboxはpendingに戻ってバックオフ再送される（既存のNetworkFailure処理パスに正しく合流すること）。
2. タイムアウトが発生しても`SyncEngine._running`/`_inFlight`が確実に解除され、`pauseForAuthTransition()`が無期限に待ち続けない。
3. `AccountController.deleteAccount()`に他コントローラと同じ操作キー単位の二重タップ防止を追加し、連打しても実際のRPC呼び出しは1回だけになる。

必要な回帰テスト:
- タイムアウト注入可能なfakeのRemoteMutationClient/MutationTransportを用意し、「呼び出しが返らない場合でもpauseForAuthTransition()が有限時間で解決する」ことを検証するテスト
- AccountControllerの二重タップ防止テスト（既存のtest/notifier/genba_actions_controller_test.dartの二重タップテストと同型）
- 既存のtest/notifier/account_controller_test.dart、test/core/sync_engine_test.dartが回帰しないこと

検証: dart format、dart analyze、flutter test（全件）を実行し結果を報告してください。

無関係な変更、テストのskip、常時成功stub、秘密情報追加は禁止です。実施後に変更ファイル、検証結果、残課題を報告してください。
```

R8-A・R8-B・R8-Cは互いに独立しており、並行して別セッションで実行できる。3件完了後、`docs/fable-post-implementation-review-prompt.md`でR8相当の再監査を行い、Critical/Highが0件になったことを確認してからPhase 1（デザイン適用の後続部分）またはfollow-up-work.mdの残項目へ進む。
