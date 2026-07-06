# ADR-0010: 旅程MVPの外部地図連携にGoogle Maps Platformを採用する

- Status: Accepted
- Date: 2026-07-06
- Related: 要件 §7.9、[旅程仕様](../itinerary-plan-spec.md)

## Context

計画タブでは施設検索、場所詳細、写真、徒歩・公共交通等の経路が必要になる。一方、Google Maps Platformは従量課金であり、フィールドやSKUによって料金が変わる。API障害、未契約、予算上限時にも推し活遠征の計画を失わない設計が必要である。

FlutterアプリへWeb Service用キーを埋め込むと、抽出・不正利用・利用量制御のリスクがある。GoogleもiOSではネイティブSDK、Web Serviceでは安全なプロキシとキー制限を推奨している。

## Decision

1. Google Maps／Places／Routesを旅程MVPの主要機能として採用する。一方、旅程のドメインとRepositoryは地図事業者に依存させず、未設定・障害・上限到達時に手動入力へ縮退できるようにする。
2. PlacesはAutocomplete (New)／Place Details (New)、経路はRoutes APIを新規連携の第一候補とする。Directions API (Legacy)を新規設計の中心にしない。
3. Places Web ServiceとRoutesは、認証済みSupabase Edge Function等のサーバー仲介を経由する。Web Service用キーをアプリへ埋め込まない。
4. アプリ内地図表示でクライアントSDKを使う場合は、development／staging／productionごとにキーを分離し、iOS bundle IDと対象APIで制限する。Android追加時は別キーと署名制限を使う。
5. Autocompleteは1検索セッション1token、3文字以上、debounce、location biasを使用する。候補選択時のPlace Detailsまで同じtokenを使う。
6. Places／RoutesはField Maskを必須とし、`*`を本番で禁止する。電話、営業時間、写真等は基本情報と分けて明示取得する。
7. 経路は明示操作時のみ計算し、編集・並び替え時は`要再計算`にする。キャッシュ、ユーザー別レート制限、Google Cloudクォータ、予算通知、kill switchを併用する。
8. Google写真はユーザー画像と分離し、返却された帰属表示を画像の近くに出す。写真リソース名を永続的なユーザー資産として扱わず、思い出へ自動複製しない。
9. Googleが返さない、または地域・日時条件で不安定な運賃、公共交通、営業時間等は常にnullableとし、手動入力・手動上書きを提供する。
10. 料金額や無料利用枠をアプリコードへ固定しない。リリース前と四半期ごとに公式料金表、利用規約、帰属要件を確認する。

## Consequences

### Positive

- Google停止時も手動旅程が利用できる
- APIキーと利用量をサーバー側で制御できる
- 将来別の地図・経路事業者へ差し替えやすい
- 不要な自動呼び出しと高単価フィールドを抑制できる

### Negative

- Edge Function、クォータ、監視の実装と運用が必要
- 外部データは完全なリアルタイム性を保証できない
- Google写真とユーザー写真で表示・キャッシュ規則が分かれる
- 地図事業者非依存のDTO／ドメイン変換が必要

## Rejected alternatives

### アプリからWeb Serviceを直接呼ぶ

キー秘匿、ユーザー別制限、kill switch、監査が弱くなるため不採用。

### Google連携だけで旅程を成立させる

Google連携自体はMVPへ含めるが、料金・障害・地域差によって基本機能が使えなくなる設計は不採用。手動フォールバックを必須とする。

### すべての詳細と経路を画面表示時に自動取得する

従量課金と無駄な再計算が増えるため不採用。

### Google写真をStorageへ恒久コピーする

帰属・キャッシュ・利用条件とユーザー所有画像の境界が曖昧になるため不採用。

## Verification

- Google設定なし、オフライン、上限到達、APIエラーの各状態で手動登録が完了する
- クライアントバイナリにWeb Service用キーが含まれない
- Field Maskなし／ワイルドカード／認証なし／上限超過をサーバー境界で拒否する
- session tokenの生成、選択完了、放棄、再利用禁止をテストする
- Google写真の帰属表示をWidgetテストする
- API呼び出し件数を匿名集計し、住所・座標・旅程内容をログへ残さない
