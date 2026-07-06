# ADR-0010: 旅程MVPの外部地図連携にGoogle Maps Platformを採用する

- Status: Accepted
- Date: 2026-07-06
- Related: 要件 §7.9、[旅程仕様](../itinerary-plan-spec.md)

## Context

計画タブでは施設検索、地図、徒歩・公共交通等の経路が必要になる。一方、Google Maps Platformは従量課金であり、フィールドやSKUによって料金が変わる。Google Maps Contentには保存・キャッシュ制限もあるため、API障害、未契約、予算上限時にも推し活遠征の計画を失わず、Google応答の共有キャッシュをAPI代替にしない設計が必要である。

FlutterアプリへWeb Service用キーを埋め込むと、抽出・不正利用・利用量制御のリスクがある。GoogleもiOSではネイティブSDK、Web Serviceでは安全なプロキシとキー制限を推奨している。

## Decision

1. Google Maps／Places／Routesを旅程MVPの主要機能として採用する。一方、旅程のドメインとRepositoryは地図事業者に依存させず、未設定・障害・上限到達時に手動入力へ縮退できるようにする。
2. PlacesはAutocomplete (New)／Place Details (New)、経路はRoutes APIを新規連携の第一候補とする。Directions API (Legacy)を新規設計の中心にしない。
3. Places Web ServiceとRoutesは、認証済みSupabase Edge Function等のサーバー仲介を経由する。Web Service用キーをアプリへ埋め込まない。
4. アプリ内地図表示でクライアントSDKを使う場合は、development／staging／productionごとにキーを分離し、iOS bundle IDと対象APIで制限する。Android追加時は別キーと署名制限を使う。
5. Autocompleteは1検索セッション1token、3文字以上、debounce、location biasを使用する。候補選択時のPlace Detailsまで同じtokenを使う。
6. PlacesのField MaskはPlace ID・名称・住所・表示に必要な帰属情報だけをallowlist化し、`*`を本番で禁止する。電話、Webサイト、営業時間、写真、評価、レビュー、primary type、座標はMVPで取得しない。
7. Place IDは永続保存・再利用できる。Google由来の施設名・住所をAPI呼び出しの代替となるユーザー横断恒久キャッシュへ保存しない。共有施設DBはユーザー入力、施設提供、オープンデータ、契約データ等、権利根拠を説明できるデータで構築する。
8. 通常表示は権利確認済みの保存済み概算経路を優先する。Google Routesはプレミアムユーザーが経路詳細を開くか`最新ルートを更新`を押した場合だけ呼び、編集・並び替え・初期表示では呼ばない。
9. Google Routesの応答はライブ表示用の一時状態として扱い、書面許諾等が無い限り所要時間、路線、乗換、運賃等を恒久共有キャッシュへ保存しない。Google由来緯度・経度を一時保存する場合は現行規約の最長30日以内で自動削除する。
10. 概算経路は徒歩距離、手段、路線名、乗換概要、所要時間、任意運賃、Google Maps URLを基本とし、厳密な時刻表・リアルタイム性を保証しない。運賃は手動入力・修正可能にし、ライブ値で手動値を上書きしない。
11. Google Place写真はMVPで取得しない。ユーザー画像またはカテゴリ別プレースホルダーを使う。
12. 料金額や無料利用枠をアプリコードへ固定しない。リリース前と四半期ごとに公式料金表、利用規約、キャッシュ制限、帰属要件を確認する。

## Consequences

### Positive

- Google停止時も手動旅程が利用できる
- APIキーと利用量をサーバー側で制御できる
- 将来別の地図・経路事業者へ差し替えやすい
- 不要な自動呼び出しと高単価フィールドを抑制できる
- Place IDと権利確認済み自前データを再利用し、規約違反の共有キャッシュを避けられる

### Negative

- Edge Function、クォータ、監視の実装と運用が必要
- 外部データは完全なリアルタイム性を保証できない
- Googleライブ情報と永続概算情報でDTO・表示・帰属を分離する必要がある
- 地図事業者非依存のDTO／ドメイン変換が必要

## Rejected alternatives

### アプリからWeb Serviceを直接呼ぶ

キー秘匿、ユーザー別制限、kill switch、監査が弱くなるため不採用。

### Google連携だけで旅程を成立させる

Google連携自体はMVPへ含めるが、料金・障害・地域差によって基本機能が使えなくなる設計は不採用。手動フォールバックを必須とする。

### すべての詳細と経路を画面表示時に自動取得する

従量課金と無駄な再計算が増えるため不採用。

### Google施設名・住所・経路結果を全ユーザー向けDBへ恒久キャッシュする

API呼び出しの代替を目的とするGoogle Maps Contentの保存は、現行のPlacesポリシーとService Specific Termsで許可を確認できないため不採用。Place IDと、独立した権利根拠を持つ共有データを利用する。

## Verification

- Google設定なし、オフライン、上限到達、APIエラーの各状態で手動登録が完了する
- クライアントバイナリにWeb Service用キーが含まれない
- Field Maskなし／ワイルドカード／認証なし／上限超過をサーバー境界で拒否する
- session tokenの生成、選択完了、放棄、再利用禁止をテストする
- Place ID以外のGoogle Places応答とGoogle Routesライブ結果が永続／共有DBへ書かれないことをテストする
- 非プレミアムは保存済み概算経路を閲覧でき、Google最新取得はサーバー側で拒否されることをテストする
- Googleライブ情報の帰属表示をWidgetテストする
- API呼び出し件数を匿名集計し、住所・座標・旅程内容をログへ残さない
