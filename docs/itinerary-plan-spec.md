# 現場詳細「計画」タブ・推し活遠征旅程 仕様書

> 版: 1.0（2026-07-06）  
> 対象: Flutter製 iOS／Androidアプリ OshiTrip  
> 関連: [requirements.md](requirements.md) §7.9、[design-spec.md](design-spec.md) §7.3、[ADR-0010](adr/0010-google-maps-platform.md)

## 1. 目的

現場を旅の中心に置き、ライブ・イベントの前後に立ち寄る観光地、飲食店、ホテル、駅、空港等を、移動を含む一つの時系列として管理できるようにする。

一般的な旅行アプリとの差は次のとおりとする。

- 公演日時と会場を旅程の動かせない基準点として扱う
- 既存のチケット、交通、宿泊、Todo・持ち物、思い出と重複入力させない
- 「開場に間に合う」「終演後の最終便に乗れる」を優先して余裕時間を示す
- 計画中の情報はセンシティブ情報としてデフォルト非公開にする
- Google連携が停止・未契約・上限到達でも、手動入力だけで旅程が完成する

## 2. 前提と今回置く仮定

曖昧な部分は次のように定義する。

1. MVPでは現場1件につき既定の旅程を1件作成できる。DBは将来の複数旅程に備えて1対多を許容する。
2. 「宿泊情報から取得」は現在の現場へ登録済みの宿泊を参照する操作を指す。
3. 「交通情報から取得」は現在の現場へ登録済みの往路・復路交通を参照する操作を指す。
4. 取り込んだ交通・宿泊は複製せず、原則として元データを参照する。元データ変更時は計画にも反映する。
5. スポット自体と訪問予定を分離する。同じスポットを別日・別時間に複数回予定できる。
6. 旅程の基準タイムゾーンをIANA形式で保持する。国内MVPの既定値は端末タイムゾーンとし、変更可能にする。
7. Google Places／Maps／RoutesはMVPの主要機能として実装する。ただし機能単位で分離した境界に置き、未設定・障害・上限到達時も手動登録を妨げない。

## 3. 情報設計

### 3.1 現場詳細のタブ

```text
概要 / Todo・持ち物 / 計画 / チケット / 交通 / 宿泊 / メモ
```

「計画」は現場に紐づく旅程の入口とする。公演会場と公演時間は計画上の固定アンカーとして表示するが、会場情報をスポットとして重複保存しない。

### 3.2 計画タブの表示モード

- `タイムライン`: 日別・時系列の主表示
- `地図`: 登録スポットと選択日の経路を表示
- `候補`: 日時未設定のスポットを一時保管

リリースMVPでは3表示すべてを実装する。開発はタイムラインと候補を先に完成させ、その後に地図を接続する。地図の障害時もGoogle Maps URLによる外部表示とタイムラインを利用可能にする。

## 4. スポット

### 4.1 登録方法

常に次の2入口を並べ、手動登録を隠さない。

- `自分で入力`
- `Google Mapsから探す`（利用可能な環境のみ）

Google連携が無効、オフライン、予算上限、API障害の場合は理由を短く表示し、同じ画面から手動登録へ移れるようにする。

### 4.2 手動登録項目

| 項目 | 必須 | 備考 |
|---|---:|---|
| 施設名 | 必須 | 前後空白を除去、空文字不可 |
| カテゴリ | 必須 | §4.4の列挙値 |
| 住所 | 任意 | センシティブ情報として扱う |
| 緯度・経度 | 任意 | 両方揃ったときだけ座標として有効 |
| 訪問日 | 任意 | 未設定なら候補リストへ |
| 開始時間・終了時間 | 任意 | 終了は開始以後。日跨ぎ可 |
| メモ | 任意 | 予約番号等をログへ出さない |
| ユーザー画像 | 任意 | 利用権限を持つ画像のみ |
| リンク | 任意・複数 | §4.5の種別つきURL |
| 前後の余裕時間 | 任意 | 0／15／30／45／60分＋カスタム |

手動登録、編集、削除、並び替えは無料・プレミアムの判定に依存させない。

### 4.3 Google Placesから取り込む項目

取得できた値だけを初期入力し、欠落項目は空欄のまま手動編集可能にする。

- Google Place ID
- 施設名
- 住所
- 緯度・経度
- Google Maps URL
- primary typeから変換したアプリ内カテゴリ
- 電話番号
- 公式サイトURL
- 営業時間の表示文
- 写真メタデータと帰属表示
- 取得日時

Google由来の値はスナップショットとして表示し、「最終取得日時」と「情報が変更されている可能性」を示す。自動定期更新は行わず、ユーザーの明示的な再取得で更新する。

### 4.4 カテゴリ

| 内部値 | 表示名 | 例 |
|---|---|---|
| `venue` | ライブ・イベント会場 | ホール、ドーム、ライブハウス |
| `sightseeing` | 観光地 | 展望台、名所 |
| `restaurant` | 飲食店 | レストラン、居酒屋 |
| `cafe` | カフェ | 推し活カフェを含む |
| `lodging` | ホテル・宿泊 | ホテル、旅館 |
| `station` | 駅 | 鉄道駅、バスターミナル |
| `airport` | 空港 | 空港ターミナル |
| `shopping` | 買い物・グッズ | 商業施設、公式ショップ |
| `shrine_temple` | 神社・寺院 | 聖地巡礼を含む |
| `museum` | 美術館・博物館 | 展示施設 |
| `park` | 公園・屋外 | 公園、庭園 |
| `photo_spot` | 撮影スポット | 推しぬい・アクスタ撮影 |
| `convenience` | コンビニ・補給 | 飲み物、電池調達 |
| `other` | その他 | 上記以外 |

Googleのplace typeとアプリカテゴリはマッピングテーブルで変換する。変換不能なら`other`とし、ユーザーが変更できるようにする。

### 4.5 URL種別

URLは1フィールドへ詰め込まず、種別つきで複数保持する。

- `reference`: 参考URL
- `reservation`: 予約URL
- `google_maps`: Google Maps URL
- `social`: SNS投稿URL
- `ticket`: チケットURL
- `official`: 公式サイトURL
- `other`: その他

`https`を基本とし、外部遷移前にドメインを表示する。危険なスキームは拒否する。

## 5. 旅程とタイムライン

### 5.1 旅程項目

タイムラインは次の項目を同一の流れで表示する。

- スポット訪問
- 公演会場・開場・開演・終演（固定アンカー）
- 登録済み交通から取り込んだ移動
- 登録済み宿泊から取り込んだチェックイン・チェックアウト
- 自由メモ／集合予定
- スポット間の移動区間

### 5.2 日別表示

- 旅程期間の日付ごとにセクションを分ける
- 日付内は開始時刻、手動順、作成時刻の順で決定的に並べる
- 時刻未設定は各日の「時間未定」、日付未設定は「候補」に置く
- ドラッグ並び替えは手動順を変更する。時刻と矛盾した場合は確認を出す
- 日跨ぎ項目は開始日に置き、終了日を併記する
- 端末と旅程のタイムゾーンが違う場合は旅程現地時刻を主表示し、必要に応じて端末時刻も補助表示する

### 5.3 交通・宿泊の取り込み

計画タブに次の操作を置く。

- `登録済みの交通を追加`
- `登録済みの宿泊を追加`

選択画面では既に計画へ追加済みの項目を明示し、重複追加を防ぐ。参照元が削除された場合は旅程項目を勝手に削除せず、「元の交通／宿泊が削除されました」と表示して、手動項目への変換または旅程から削除を選べるようにする。

### 5.4 余裕時間

- 各訪問に到着前・出発後の余裕時間を設定できる
- 会場アンカーの推奨既定値は開場30分前とするが、強制しない
- 前項目の終了＋移動時間＋余裕時間が次項目の開始を超える場合、「間に合わない可能性」を文言とアイコンで表示する
- 混雑そのもののリアルタイム予測はMVP対象外。ユーザー設定の余裕時間で代替する

## 6. 経路

### 6.1 対応手段

- 徒歩
- 公共交通
- 車
- 自転車
- タクシー
- 飛行機
- その他

Google Routes自動取得は徒歩・公共交通・車・自転車を中心とし、未対応手段や取得失敗は手動入力に縮退する。

### 6.2 保存項目

- 出発旅程項目／出発地
- 到着旅程項目／到着地
- 移動手段
- 出発・到着日時
- 所要時間（分）
- 距離（m）
- 運賃、通貨
- 乗換・経路概要
- 公共交通の路線・停留所・乗換ステップ
- Google Mapsで開くURL
- データソース（手動／Google）
- 取得日時、取得条件、再計算が必要か

運賃はGoogleが全区間を算定できた場合だけ返るため、常に任意項目とし、手動上書きを許可する。手動上書き値とAPI取得値を区別して保持する。

### 6.3 再計算

- スポットの座標、順序、時刻、移動手段が変わったら経路を`要再計算`にする
- 編集やドラッグのたびにAPIを自動実行しない
- ユーザーが`経路を更新`を押したときだけ再計算する
- 同一の出発地・到着地・手段・時刻帯に対する結果は期限つきキャッシュを利用する
- 公共交通は時刻表変動を考慮し、古い結果であることを明示する

## 7. 画像

### 7.1 ユーザー画像

- スポットごとにユーザー所有画像を登録できる
- 既存のowner分離されたImageStore／Supabase Storage方針を再利用する
- スポットカード、旅程、思い出、アルバムへ利用できる
- 思い出へ追加するときはユーザーの明示操作を必要とする

### 7.2 Google Place写真

- Google提供写真はユーザー所有画像と別フィールド・別表示経路にする
- 必要なカードが表示されるとき、またはユーザーが取得を選んだときだけ読み込む
- 返却されたauthor attributionを写真の近くに必ず表示する
- 写真リソース名は期限切れし得るため永続的なユーザー画像として扱わない
- Google写真を思い出アルバムへ自動複製しない
- 写真がない、取得失敗、オフライン、予算上限ではカテゴリ別プレースホルダーへ縮退する

## 8. Google API料金抑制

### 8.1 原則

1. 手動登録を常時利用可能にする
2. APIは画面表示だけで自動実行しない
3. 必要なフィールドだけをField Maskで取得する
4. 検索候補と詳細取得を分ける
5. 経路は明示操作時のみ取得する
6. ユーザー単位・環境単位の上限と停止スイッチを持つ

### 8.2 Places検索

- 3文字未満では検索しない
- 400〜500msのdebounceを行い、古いリクエストをキャンセルする
- 検索開始ごとに一意なAutocomplete session tokenを発行し、候補選択のPlace Detailsまで同じtokenを使う
- 候補未選択で画面を閉じたらsessionを終了する
- 現場会場または表示中地図をlocation biasに利用し、結果件数を抑える
- MVPの基本取得は名称、住所、座標、Place ID、Google Maps URL、primary typeに限定する
- 電話、Webサイト、営業時間、写真等の高コストになり得るフィールドは`詳細も取得`の明示操作へ分ける
- 本番でワイルドカードField Maskを禁止する

### 8.3 Routes

- タイムライン初期表示で全区間を一括計算しない
- 未計算区間だけをユーザーが選んで計算できる
- 自動更新は行わず、古い結果と要再計算を表示する
- 無料利用枠を前提にせず、Google Cloud側の日次クォータ、予算通知、アプリ側ユーザー別レート制限を設定する
- 月間利用量が運用閾値へ達した場合、管理者がGoogle自動取得だけを停止できるkill switchを持つ

料金額や無料枠は変更され得るためコードへ固定しない。運用設定と公式料金表をリリース前・四半期ごとに確認する。

## 9. セキュリティ・プライバシー

- Web Service用Google APIキーをアプリへ埋め込まない
- Places Web Service／Routesは認証済みSupabase Edge Function等のサーバー仲介を原則とする
- 地図表示用のクライアントキーはiOS bundle ID等のアプリ制限とAPI制限を付け、環境別に分ける
- Edge Functionは認証、owner、機能フラグ、ユーザー別クォータを検証する
- リクエストログへ住所、座標、旅程本文、予約番号を平文で残さない
- 旅程、住所、座標、予約URL、共有範囲はデフォルト非公開とする
- 共同編集時もowner／editor／viewerをRLSで強制し、UI判定だけに依存しない

## 10. オフライン

- 保存済み旅程、スポット、メモ、ユーザー画像サムネイル、最後に取得した経路概要はオフライン閲覧可能にする
- 手動での追加・編集・削除・並び替えはOutboxへ保存し、接続復旧後に同期する
- Google検索、新規Google写真、新規経路計算はオフラインでは行わない
- 地図タイルの完全オフライン保証はしない。地図が使えなくてもタイムラインと住所、保存済み経路を表示する
- 外部データが古い可能性を最終取得時刻とともに表示する

## 11. 共有・共同編集・通知

### 11.1 共有

- 初期状態は本人のみ
- viewerは閲覧のみ、editorは旅程項目を編集可能、ownerだけが共有設定と旅程削除を行える
- 個人メモ、正確な住所、予約URL、位置情報、画像を項目単位で共有対象外にでき、安全側を既定値にする
- 同時編集は更新版による競合検知を行い、黙って上書きしない

共有と共同編集の実装は既存の現場共有基盤完成後とする。

### 11.2 通知

- 出発時刻
- スポット開始時刻
- チェックイン時刻
- 会場へ向かう推奨時刻
- 経路上の余裕不足

OS通知許可は価値説明後に要求し、拒否しても旅程機能は利用可能にする。同一旅程・同一項目・同一種別の通知は冪等にする。

## 12. データモデル案

### 12.1 `itinerary_plans`

- `id`, `genba_id`, `owner_id`
- `title`, `memo`
- `start_date`, `end_date`, `time_zone_id`
- `cover_image_local_path`, `cover_image_storage_path`, `cover_image_upload_status`
- `sort_order`, `version`, `created_at`, `updated_at`

### 12.2 `itinerary_spots`

- `id`, `plan_id`, `owner_id`
- `source` (`manual` / `google_places`)
- `google_place_id`
- `name`, `category`, `address`
- `latitude`, `longitude`
- `phone_number`, `website_url`, `opening_hours_text`
- `google_maps_url`, `google_fetched_at`
- `google_photo_name`, `google_photo_attribution`
- `user_image_local_path`, `user_image_storage_path`, `user_image_upload_status`, `user_image_alt_text`
- `memo`, `version`, `created_at`, `updated_at`

### 12.3 `itinerary_spot_links`

- `id`, `spot_id`, `owner_id`
- `kind`, `url`, `label`, `sort_order`
- `version`, `created_at`, `updated_at`

### 12.4 `itinerary_entries`

- `id`, `plan_id`, `owner_id`
- `kind` (`spot` / `transport` / `lodging` / `note`)
- `spot_id`, `transport_id`, `lodging_id`（kindに応じて1つだけ）
- `title_override`, `start_at`, `end_at`, `local_date`, `time_zone_id`
- `buffer_before_minutes`, `buffer_after_minutes`
- `memo`, `sort_order`
- `version`, `created_at`, `updated_at`

### 12.5 `itinerary_legs`

- `id`, `plan_id`, `owner_id`
- `origin_entry_id`, `destination_entry_id`
- `source` (`manual` / `google_routes`)
- `travel_mode`, `departure_at`, `arrival_at`
- `duration_minutes`, `distance_meters`
- `fare_amount_minor`, `fare_currency`
- `route_summary`, `transit_steps_json`, `encoded_polyline`
- `google_maps_url`, `fetched_at`, `cache_key`, `is_stale`
- `version`, `created_at`, `updated_at`

全子テーブルでownerと親のowner一致をローカル境界とSupabaseトリガーの両方で強制する。削除はplan→spot／entry／leg／linkへ安全にcascadeする。既存transport／lodging削除時は参照切れを検出できる設計にする。

## 13. 状態・エラー

- 初回空状態: 「現場の前後に行きたい場所を追加しましょう」
- API未設定: 手動登録を主CTAとして表示
- API上限: 「自動検索は一時停止中です。手動で登録できます」
- Places候補なし: 入力語を引き継いで手動登録
- 経路取得不可: 出発地・到着地を保持したまま手動入力
- 写真なし: カテゴリ別プレースホルダー
- オフライン: 保存済み内容を表示し、外部取得ボタンを無効化
- 参照元削除: 交通／宿泊を手動項目へ変換または削除
- 同期競合: ローカル／サーバーの差分を示して選択

## 14. MVPと後続範囲

### 14.1 旅程MVP

- 現場詳細の計画タブ
- 手動スポット登録・編集・削除
- カテゴリ、複数URL、メモ、ユーザー画像
- 日別タイムライン、候補リスト、手動並び替え
- 公演アンカー表示
- 既存交通・宿泊の参照追加
- 手動移動区間、所要時間、運賃、余裕時間
- オフライン閲覧・編集・同期
- Google Maps URLを外部で開く
- Google Mapsによるアプリ内地図表示
- Google Placesによる施設検索・基本情報取得
- Google Place写真と帰属表示
- Google Routesによる徒歩・公共交通・車・自転車の経路取得
- Places／Routes取得不能時の手動フォールバック

### 14.2 MVP後

- 複数区間の再計算、ルート最適化
- 旅程共有・共同編集
- 通知・リマインダー
- 思い出アルバムとの高度な連携

### 14.3 将来

- AI旅程作成・観光地提案
- 混雑予測
- 年間遠征レポート
- プレミアム制御と課金

### 14.4 将来の機能区分候補

現時点では課金制御を実装せず、UseCase／サーバー境界を機能単位で分ける。最終的な無料範囲は利用実績とAPI原価を確認して決定する。

| 常に利用可能にする基礎機能 | プレミアム候補 |
|---|---|
| 手動スポット登録・編集 | Google Places自動入力 |
| 基本旅程・日別タイムライン | Google Routes自動取得 |
| メモ・複数URL | 複数区間のルート最適化 |
| ユーザー画像 | AI旅程・観光地提案 |
| 既存交通・宿泊の参照 | 高度な画像アルバム |
| 手動経路・余裕時間 | 年間遠征レポート |
| 保存済み旅程の端末内閲覧 | クラウド容量・複数端末・高度なオフライン |
| Google Maps URLで外部表示 | 広告非表示 |

オフライン編集と同期は現在のOshiTrip基盤に含まれるため、既存利用者から安易に取り上げない。クラウド容量や複数端末上限を課金候補として分離する。

## 15. 受入条件

1. Google APIを一切設定しなくても、手動登録だけで旅程を完成できる。
2. 現場会場、交通、宿泊、スポットが同じ日別タイムラインで時系列表示される。
3. 交通・宿泊を重複入力せず参照追加でき、二重追加されない。
4. 時刻未定・日付未定・日跨ぎ・タイムゾーン違いを失わず表示できる。
5. 経路取得失敗時も入力内容を失わず、手動入力へ切り替えられる。
6. Google由来写真へ必要な帰属表示があり、ユーザー画像と混同しない。
7. オフラインで保存済み旅程を閲覧・編集でき、復旧後に同期される。
8. 別ownerの旅程、スポット、画像、経路をID推測や直接APIで取得・変更できない。
9. API呼び出しがdebounce、session token、Field Mask、キャッシュ、クォータで制御される。
10. Dynamic Type、VoiceOver、色覚差、片手操作で主要機能を利用できる。

## 16. 公式技術資料

- [Autocomplete (New)](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete)
- [Place Details (New)](https://developers.google.com/maps/documentation/places/web-service/place-details)
- [Place Photos (New)](https://developers.google.com/maps/documentation/places/web-service/place-photos)
- [Routes API: transit](https://developers.google.com/maps/documentation/routes/transit-route)
- [Routes API: field masks](https://developers.google.com/maps/documentation/routes/choose_fields)
- [Google Maps Platform pricing](https://developers.google.com/maps/billing-and-pricing/pricing)
- [API security best practices](https://developers.google.com/maps/api-security-best-practices)
