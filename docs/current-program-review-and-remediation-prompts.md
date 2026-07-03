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
