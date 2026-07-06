# 「計画」タブ・旅程機能 フェーズ別実装プロンプト

> 作成日: 2026-07-06  
> 対象ブランチの最新状態を確認してから使用する。各Phaseは前Phaseの完了・レビュー後に実行する。  
> 仕様の単一の真実: [itinerary-plan-spec.md](itinerary-plan-spec.md)

## 0. モデル選択

| Phase | 推奨Claudeモデル | 理由 |
|---|---|---|
| 1. データ基盤 | Claude Opus 4.8 | DB移行、RLS、Outbox、親子owner整合が中心 |
| 2. 手動旅程・フォールバックUI | Claude Sonnet 5 | UI実装量が多く、仕様境界はPhase 1で固定済み |
| 3. Maps／Places | Claude Opus 4.8 | APIキー、課金、規約、障害縮退を横断する |
| 4. Routes | Claude Opus 4.8 | 公共交通、日時、キャッシュ、費用制御が複雑 |
| 5. 共有・通知・品質 | Claude Opus 4.8 | RLS共同編集、競合、通知、プライバシー監査が必要 |

**旅程のリリースMVPはPhase 1〜4をすべて完了した状態**とする。Phase 2はGoogleを外した完成版ではなく、Google障害時にも使える基礎UIとフォールバックを先に作る工程である。

## 共通指示

各Phaseのプロンプトへ次を含めた状態で実行する。

```text
作業前に、git status、現在ブランチ、最新コミット、既存の未コミット変更を確認してください。ユーザーの既存変更を上書き・破棄しないでください。

必ず次を読んでから実装してください。

- docs/itinerary-plan-spec.md
- docs/requirements.md §7.9
- docs/design-spec.md §7.3
- docs/architecture.md
- docs/adr/0010-google-maps-platform.md
- docs/decisions.mdの最新決定

既存のFlutter／Riverpod／go_router／Drift／Supabase／Outbox／Result型／owner分離のパターンへ合わせてください。generatedファイルは手編集せずbuild_runnerで生成してください。

このPhaseより後の機能を先行実装しないでください。押せない見せかけUI、常に成功するstub、固定ダミーデータを完成機能として追加しないでください。

住所、座標、予約URL、旅程内容をログ・分析イベント・通知本文へ出さないでください。クライアントの権限判定はUX補助に留め、強制はSupabase RLS／Storage policyで行ってください。

Google Maps Platformのコンテンツを保存・共有する実装では、コスト削減を理由にキャッシュ可否を推測しないでください。作業時点のGoogle公式ポリシーとService Specific Termsを確認し、許可フィールド・保存期間・帰属をdocs/decisions.mdへ記録してください。Place ID以外のGoogle PlacesコンテンツやGoogle Routes応答を、API呼び出しの代替となるユーザー横断恒久キャッシュへ保存しないでください。共有再利用にはユーザー入力・施設提供・オープンデータ・契約データ等、権利根拠を説明できるデータだけを使ってください。

変更後はdart format、flutter analyze、flutter testを実行してください。Supabase変更があるPhaseではpgTAPも実行し、実行不能なら理由を明記して成功扱いにしないでください。

最後に変更ファイル、設計判断、マイグレーション、テスト結果、未実装の次Phase範囲、残るリスクを報告してください。
```

---

## Phase 1：旅程ドメイン・DB・同期基盤

推奨モデル: **Claude Opus 4.8**

```text
Phase 1として、現場詳細「計画」タブの土台となる旅程ドメイン、ローカルDB、Repository、同期、Supabase認可を実装してください。このPhaseでは本番UI、Google API、経路自動取得、共有、通知は実装しません。

目的は、Google APIなしでも成立する手動旅程を安全に永続化できる境界を完成させることです。

実装対象:

1. features/itineraryをfeature-firstで追加する。
   - domain: entity、enum、値検証、Repository抽象
   - application: 後続UIが利用する操作境界
   - data: Drift／Supabase／Outbox対応Repository

2. 次のモデルを仕様書どおり実装する。
   - ItineraryPlan
   - ItinerarySpot
   - ItinerarySpotLink
   - ItineraryEntry
   - ItineraryLeg

3. enumを型安全に定義する。
   - spot source: manual / googlePlaces
   - spot category: 仕様書§4.4
   - link kind: 仕様書§4.5
   - entry kind: spot / transport / lodging / note
   - leg source: manual / googleRoutes
   - travel mode: walking / transit / driving / bicycling / taxi / flight / other

4. ドメイン不変条件を純粋関数で実装する。
   - 緯度と経度は両方nullまたは両方有効値
   - 緯度-90〜90、経度-180〜180
   - 終了日時は開始日時以後。日跨ぎを許可
   - bufferは0以上で合理的な上限を設ける
   - URLは許可スキームだけ
   - entry kindに対応する参照IDだけを許可
   - legのoriginとdestinationは同じにしない
   - fareは通貨と金額を組で扱う
   - Google由来nullableフィールドを必須扱いしない

5. Driftへ次のテーブルを追加する。
   - itinerary_plans
   - itinerary_spots
   - itinerary_spot_links
   - itinerary_entries
   - itinerary_legs

   最新schemaVersionと未使用のmigration番号を確認して、安全な追加マイグレーションを作ること。既存テーブルやデータを作り直さないこと。

6. Supabaseへ同等テーブルを追加する。
   - UUID主キー
   - owner_id
   - version、created_at、updated_at
   - 親削除時の適切なCASCADE
   - 既存transport／lodging参照の削除方針
   - owner index、plan/date/order用index
   - RLS
   - 子ownerと親owner一致トリガー
   - apply_mutation許可リストへ追加

   apply_mutationを再定義する場合、既存の全許可テーブルを落とさない回帰テストを追加すること。

7. Repositoryを既存のローカル先行方式で実装する。
   - owner限定watch／取得
   - upsert／delete
   - 複数行操作はDB更新とOutboxを同一トランザクションにする
   - syncEngine.pokeはcommit後
   - remote pullは認証切替のisStaleを尊重
   - 競合解決のserver/local採用へ接続
   - アカウント削除時のlocal purgeへ追加

8. 旅程タイムラインを組み立てる純粋関数を実装する。
   - localDate→startAt→sortOrder→createdAtの決定的順序
   - 日付未定と時刻未定を失わない
   - 公演アンカーはGenbaから導出し、DBへ重複保存しない
   - 交通・宿泊は既存IDを参照し、複製しない
   - 参照切れを状態として返す

必須テスト:

- 全enum JSON／DB round-trip
- バリデーション境界値
- 日跨ぎ、時刻未定、日付未定、タイムゾーン
- owner Aの全データをowner Bが取得・更新・削除できない
- 子ownerと親owner不一致の拒否
- 親削除cascade
- transport／lodging参照切れ
- DB migrationで既存データを失わない
- ローカル書込みとOutboxの原子性
- offline→再起動→同期
- apply_mutationの既存entityを壊さないpgTAP

完了条件:

- Google設定なしで全Repositoryテストが通る
- presentationへGoogle型が漏れない
- Web Service用キーや架空のAPIレスポンスを追加しない
- docs/requirements-traceability.mdへ「Phase 1基盤、UI未実装」と正確に追記する
```

---

## Phase 1レビュー修正・Google低コスト方針の基盤反映

推奨モデル: **Claude Opus 4.8**

```text
Phase 1実装後レビューで見つかった参照整合性・バリデーション・競合解決・テスト不足を修正し、改訂されたGoogle API低コスト／保存規約方針をPhase 1のデータ境界へ反映してください。この作業ではUI、Places/Routesの実呼び出し、プレミアム課金UIは実装しません。

作業前に共通指示と次を必ず確認してください。

- docs/itinerary-plan-spec.md 版1.1以降
- docs/decisions.md D-178〜D-181
- 現在のgit diffと未追跡ファイル
- supabase/migrations/0012_itinerary.sqlが既に適用済みか

既存マイグレーションが適用済みなら書き換えず、新しい未使用番号の追補マイグレーションを作成してください。未適用であることを確認できた場合だけ0012を修正できます。

1. 参照整合性をローカルとSupabaseの両方で強制する。
   - spot entryのspot_idは実在し、entryと同じowner・同じplanに属すること
   - transport entryのtransport_idは実在し、同じownerかつplanの親genbaと同じgenbaに属すること
   - lodging entryも同様に、同じowner・同じgenbaに属すること
   - legのorigin/destination entryは両方実在し、legと同じowner・同じplanに属すること
   - endpointが異なるだけでは不十分
   - insertだけでなくupdateでも検証する
   - 検証と書込みとOutbox enqueueを同一transactionで行う
   - ID推測による別owner参照を拒否し、存在有無を外部へ漏らさない同一の型付きFailureへ正規化する
   - SupabaseはRLSだけに依存せずSECURITY DEFINERの親参照整合トリガーで強制する

2. URL・数値バリデーションを完成させる。
   - ItinerarySpotLink.urlだけでなく、spot.websiteUrl、spot.googleMapsUrl、leg.googleMapsUrlもhttp/httpsだけ許可する
   - URLはschemeだけでなくhostが存在することを確認する
   - 緯度・経度はNaNとInfinityを拒否する
   - nullable Googleフィールドはnullのまま許可する

3. 競合解決時も端末専用画像参照を保持する。
   - itinerary planのcoverImageLocalPath
   - itinerary spotのuserImageLocalPath
   - 通常pullとadoptServerEntityの両方でpreserveLocalImageを使用する
   - 「サーバーを採用」でサーバー列は更新しつつ、サーバーに存在しない端末内pathをnull上書きしない

4. タイムラインの順序を完全に決定的にする。
   - localDate→startAt→sortOrder→createdAtの後にidを最終tie-breakerとして使う
   - candidatesと同時刻entryの両方に適用する

5. Google保存規約に依存しない永続モデルへ整理する。
   - Google Place IDは永続保存可能な識別子として維持する
   - Google由来の名称・住所・経路結果を共有恒久キャッシュへ保存する前提をモデル・コメント・テストから除く
   - 永続する名称・住所・概算経路にはdata_origin/value_originとrights_basisを表現できる境界を用意する
   - 候補値はuser_provided / facility_provided / open_data / licensedとし、Google API応答の自動転記を共有可能データとして扱わない
   - googlePlaces/googleRoutesのenumを維持する場合は「一時DTOまたは将来の書面許諾用」であることを明確にし、通常の共有永続化へ流れ込まないようにする
   - 共有施設DB・共有概算経路DBそのものはPhase 3/4のため、この修正で先行実装しない

6. 必須テストを実体のある検証にする。
   - 全5旅程entityについてowner Aのデータをowner Bがread/upsert/deleteできない
   - 別owner・別plan・存在しないspot/transport/lodging/endpoint参照を拒否
   - ローカルDB更新後にOutbox enqueueを意図的に失敗させ、行とOutboxの両方がrollbackされること
   - offline保存→DBを閉じて再open→SyncEngineで送信→pendingが解消し、リモート側へ反映されること
   - adoptServerEntityで端末内画像pathが保持されること
   - NaN/Infinity、host無しURL、各URLフィールドの危険スキーム拒否
   - 全sort key同値でもidで同じ順序になること
   - pgTAPで全5テーブルのSELECT/INSERT/UPDATE/DELETE owner分離、参照先owner/plan/genba不一致拒否、cascade、apply_mutation既存entity回帰を検証する

7. 検証する。
   - 変更Dartファイルだけdart format
   - flutter analyze
   - itinerary関連テスト
   - flutter test全件
   - supabase db reset / supabase test db
   - Supabase CLIやDockerが無ければ未実行理由を明記し、成功扱いにしない
   - git diff --check

最後に、修正したレビュー指摘、データモデル判断、マイグレーションの扱い、Google由来データを保存しない境界、テスト件数、未実行検証、Phase 2以降へ残した範囲を日本語で報告してください。勝手にコミットしないでください。
```

---

## Phase 2：現場詳細「計画」タブ・手動旅程フォールバック

推奨モデル: **Claude Sonnet 5**

```text
Phase 2として、Phase 1の旅程基盤を使い、現場詳細「計画」タブのタイムラインと手動旅程を実装してください。これはGoogle APIを切ったMVP完成版ではなく、Phase 3・4でGoogle Maps／Places／Routesを接続するための基礎UIであり、同時にAPI障害・上限到達時の必須フォールバックになります。このPhaseではGoogle API接続、共同編集、通知はまだ実装しません。

1. 現場詳細タブを次の順にする。

   概要 / Todo・持ち物 / 計画 / チケット / 交通 / 宿泊 / メモ

   横スクロール、選択状態、PageStorage、Dynamic Type、既存タブindex参照を更新し、全routing／widgetテストを修正する。

2. 計画タブを実装する。
   - 日付ごとのタイムライン
   - 日付未定の候補リスト
   - 公演会場・開場・開演・終演の固定アンカー
   - 空状態、loading、error、offline、data
   - スクロール位置保持
   - 追加FABまたは明確な追加ボタン

3. 手動スポットCRUDを実装する。
   - 施設名、カテゴリ、住所
   - 訪問日、開始・終了時間
   - 緯度・経度
   - メモ
   - 複数の種別つきURL
   - 前後の余裕時間
   - ユーザー画像

   「自分で入力」を常に主要導線として表示する。Google検索ボタンはまだ表示しない。

4. URL管理を実装する。
   - 参考、予約、Google Maps、SNS、チケット、公式、その他
   - 複数追加、編集、削除、並び替え
   - 不正スキーム拒否
   - 外部遷移前にドメインを確認できる表示

5. 交通・宿泊取り込みを実装する。
   - 「登録済みの交通を追加」
   - 「登録済みの宿泊を追加」
   - 追加済み表示と重複防止
   - 元データ編集の即時反映
   - 元データ削除時に参照切れを明示し、手動項目へ変換／旅程から削除を選択

6. 手動移動区間を実装する。
   - 出発・到着項目
   - 移動手段
   - 出発・到着時刻
   - 所要時間、距離、運賃、通貨、経路概要
   - Google Mapsで開くURL
   - すべて手動編集可能

7. タイムラインUXを実装する。
   - 時刻とカテゴリを色だけでなく文字・アイコンで表示
   - 日付内の並び替え
   - 時刻順との矛盾時に確認
   - 日跨ぎ表示
   - 時刻未定ブロック
   - 移動時間＋余裕時間で次の予定に間に合わない可能性を警告
   - 会場到着余裕の推奨値を提示するが強制しない

8. ユーザー画像は既存ImageStore／Storage契約を再利用する。
   - owner分離
   - 失敗を成功表示しない
   - missing／inaccessible／upload failedを区別
   - スポットカードの代替テキスト
   - Google写真用フィールドは使用しない

9. オフラインを完成させる。
   - 保存済み計画を閲覧可能
   - CRUD／並び替えをOutboxへ保存
   - 接続復旧後に同期
   - 外部地図を開けない場合も住所と座標を表示

必須テスト:

- 計画タブのroutingとタブindex
- 空→手動登録→タイムライン表示→編集→削除
- 日別、候補、時刻未定、日跨ぎ
- 交通・宿泊の追加、重複防止、元更新、参照切れ
- 手動移動区間と余裕不足判定
- URLスキームと外部遷移
- 画像状態
- 失敗ロールバック、二重タップ防止
- 320pt幅、横向き、文字200%、VoiceOver用Semantics
- offline→編集→再起動→同期

完了条件:

- Google APIキーなしで旅程を最初から最後まで作れる
- 既存の交通・宿泊と二重データにならない
- Google／AI／プレミアムの見せかけUIを出さない
- integration_testへ「現場作成→計画→手動スポット→交通宿泊追加→再起動復元」を追加する
- このPhaseだけで「旅程MVP完成」と記録しない。Phase 3・4が未完了であることをimplementation-statusとtraceabilityへ明記する
```

---

## Phase 3：旅程MVPのアプリ内地図・最小Google Places・共有施設基盤

推奨モデル: **Claude Opus 4.8**

```text
Phase 3として、手動旅程フォールバックを維持したまま、Google Maps Platformの地図と最小限のPlaces検索を実装してください。API費用と保存規約を優先し、MVPのGoogle取得項目はPlace ID・名称・住所・表示に必要な帰属情報だけに限定します。Google Place写真、電話、Webサイト、営業時間、評価、レビュー、primary type、座標の自動取得は実装しません。作業前にGoogle公式ドキュメントの現行仕様、料金SKU、キャッシュ制限、帰属要件を確認し、確認日と採用Field Maskをdocs/decisions.mdへ記録してください。

1. 外部API境界を実装する。
   - PlacesGateway抽象をdomain/application側へ置く
   - Places RESTは認証済みSupabase Edge Function等から呼ぶ
   - Web Service用キーをFlutterアプリへ入れない
   - 地図SDKキーは環境別、iOS bundle ID制限、API制限
   - development/staging/productionの利用量を分離
   - Google未設定時は型付きUnavailableFailure

2. Edge Functionで次を強制する。
   - Supabase認証
   - ユーザー別レート制限
   - 許可Field Maskのallowlist
   - `*` Field Mask拒否
   - リクエストtimeout
   - Googleエラーの型付き変換
   - 機能kill switch
   - ログから検索文、住所、座標、Place IDを除外または不可逆化
   - Google由来の名称・住所を共有DBへ保存する経路の禁止

3. Autocomplete (New)を実装する。
   - 3文字以上
   - 400〜500ms debounce
   - 古いレスポンスを破棄
   - 1検索セッション1 UUIDv4 token
   - 候補選択のPlace Detailsまで同じtoken
   - session token再利用禁止
   - 会場周辺location bias
   - 結果なし／中断／timeoutから手動入力へ移動

4. Places取得を最小化する。
   - Field Mask: Place ID、名称、住所、表示に必要な帰属情報のみ
   - 電話、Webサイト、営業時間、写真、評価、レビュー、primary type、座標を要求しない
   - Google Maps URLはPlace IDからアプリ側で生成し、追加Details取得を避ける
   - Place IDだけを永続保存可能なGoogle識別子として扱う
   - 名称・住所は検索／選択画面の一時状態として表示し、Google応答をAPI代替目的のユーザー横断恒久キャッシュへ保存しない
   - 旅程へ保存する表示名・住所はユーザーが独立して入力した値として扱い、Google応答の自動コピーを共有可能データへ昇格させない
   - Googleコンテンツ表示時はGoogle Mapsと第三者帰属を同じ表示コンテナで示す

5. 計画タブへ地図モードを追加する。
   - 選択日のスポットと会場を表示
   - 手動座標のあるスポットだけピン表示し、Google検索のためだけに座標を追加取得しない
   - 未座標スポットは一覧表示とGoogle Mapsで開く導線を提供する
   - ピンタップでスポット概要
   - 地図が失敗してもタイムラインを隠さない
   - Google Mapsアプリ／ブラウザで開く
   - 地図表示だけでPlace DetailsやRoutesを呼ばない

6. 権利確認済みの共有施設基盤を実装する。
   - Google Place IDは重複候補の照合キーとして利用できる
   - 名称・住所にはdata_originとrights_basisを必須にする
   - user_provided / facility_provided / open_data / licensedだけを共有候補にできる
   - Google API応答を出典とする名称・住所は共有登録をサーバーで拒否する
   - ユーザー投稿はowner別下書きから始め、個人情報を除去してモデレーション後に共有へ昇格する
   - 共有施設ヒット時はGoogleを呼ばず、必要ならPlace IDからGoogle Mapsを開く
   - Google Place写真はこのPhaseで実装しない。ユーザー画像またはカテゴリ別プレースホルダーを使う

7. 費用制御を実装する。
   - API呼び出し件数をサービス／SKU相当／環境／日単位で集計
   - 個人の検索内容は保存しない
   - Google Cloudの日次クォータと予算通知の設定手順をdocs/setup.mdへ追記
   - 利用量閾値で自動取得を止め、手動登録は止めない
   - 料金額をコードへ固定しない

必須テスト:

- debounce、キャンセル、古い応答の破棄
- session tokenの開始／完了／放棄／再利用禁止
- Field Mask allowlistとワイルドカード拒否
- 未認証、別owner、上限、kill switch、timeout
- Google未設定／オフライン／候補なし→手動入力
- 名称・住所・帰属情報の欠落を安全に扱い、手動入力へ移れる
- Place ID以外のGoogle応答が永続／共有DBへ保存されない
- data_origin／rights_basis必須、Google由来共有登録拒否、owner下書き分離
- Google Maps／第三者帰属
- 地図失敗時もタイムライン利用可能
- API秘密がログ・生成物・git差分へ入っていない

完了条件:

- Google連携を無効化してPhase 2の全フローがそのまま通る
- 検索画面を開いただけでは課金APIを呼ばない
- 共有施設ヒット時はPlaces APIを呼ばない
- PlacesのField MaskがPlace ID・名称・住所・必要帰属だけである
- 公式帰属表示を目視・Widgetテストで確認する
- iOS実機検証ができない場合はmacOS実機確認項目を明記する
- RoutesがPhase 4未完了の間は旅程MVP全体を完成扱いにしない
```

---

## Phase 4：旅程MVPのGoogle Routes・移動経路・余裕時間

推奨モデル: **Claude Opus 4.8**

```text
Phase 4として、登録スポット間の権利確認済み概算経路と、Google Routesによる最新経路の明示取得を実装してください。旅程作成・イメージ計画では保存済み概算経路を優先し、自動API取得しません。Google Routesはプレミアムユーザーが経路詳細を開くか「最新ルートを更新」を押した場合だけ呼びます。手動移動区間を置き換えず、取得不能時のフォールバックとして維持してください。作業前にRoutes APIの公共交通、代表時刻、運賃、Field Mask、料金SKU、キャッシュ制限、帰属要件を公式資料で確認してください。Google応答を恒久共有キャッシュへ保存できると推測してはいけません。このPhaseの完了をもって、Phase 1〜4の受入条件がすべて満たされた場合に限り旅程MVP完成と判定します。

1. RoutesGatewayを実装する。
   - Edge Function経由
   - 認証、owner、レート制限、kill switch
   - origin／destination／mode／日時の検証
   - 許可Field Mask固定
   - timeout、retry、Googleエラーの型付き変換
   - プレミアムentitlementのサーバー側検証
   - リクエスト条件単位のsingle-flight

2. 対応経路を実装する。
   - 徒歩
   - 公共交通
   - 車
   - 自転車
   - taxi／flight／otherは手動入力のまま

3. 概算経路とGoogleライブ結果を分離する。
   - 通常表示は同一出発スポット・到着スポット・手段に対する保存済み概算経路を優先する
   - 概算経路は徒歩距離、移動手段、路線名、乗換概要、所要時間、任意運賃、Google Mapsで開くURLだけを基本とする
   - 厳密な時刻表やリアルタイム性は保証せず、代表時刻・確認日時・概算表示を付ける
   - 永続概算経路はmanual / user_provided / open_data / licensed等、保存・再利用権限を持つ情報源に限定する
   - data_origin/value_origin、rights_basis、representative_time_bucket、last_verified_atを保持する
   - Googleライブ結果は一時DTO／画面状態に置き、永続ItineraryLegや共有概算DBへ暗黙保存しない
   - Google Mapsで開くURLはorigin/destinationのPlace ID等からアプリ側で生成する
   - 運賃は取得できる場合だけライブ表示し、永続値はユーザーが手動入力・修正できる
   - 手動運賃と一時Google運賃を別値として扱い、ライブ応答で手動値を上書きしない

4. 公共交通の制約を正しく扱う。
   - transitで中間waypointを前提にしない
   - APIが対応する過去／未来時刻範囲外では自動取得せず説明する
   - 遠い未来の時刻表は変わり得ると表示する
   - 全ステップの運賃が算定できない場合はfareを未取得として手動入力可能にする
   - preferred modeが必ず採用されるとは表示しない
   - 完全に時間帯を無視できないため、旅程時刻または仕様で定めた代表時刻を使い、リクエスト条件を表示する

5. 再計算と重複抑止を実装する。
   - origin、destination、mode、代表時刻帯からrequest fingerprintを生成
   - 位置、順番、日時、mode変更でisStale=true
   - ドラッグごとにAPIを呼ばない
   - 通常の旅程表示や未計算区間の出現だけではAPIを呼ばない
   - プレミアムユーザーが詳細を開く、または「最新ルートを更新」を押した場合だけ取得する
   - 同じ条件の重複リクエストをsingle-flight化
   - Google応答は同一画面／短期セッション内の重複抑止にだけ利用する
   - Google由来の緯度・経度を一時キャッシュする場合だけ、規約上の上限30日以内のexpires_atと自動削除を実装する
   - 所要時間、路線、乗換、運賃等をGoogle応答から恒久キャッシュしてAPIを代替しない
   - 権利確認済み保存概算はオフライン閲覧可能

6. タイムラインへ移動区間を表示する。
   - スポット間に所要時間と手段を挿入
   - 展開時に乗換詳細
   - 出発推奨時刻
   - 移動＋bufferで開場／次予定に間に合わない可能性
   - 色だけでなく文言とアイコン
   - 手動修正と再取得の優先関係を明示
   - 非プレミアムにも保存済み概算経路を表示し、最新更新だけを制限する
   - Googleライブ結果にはGoogle Maps／第三者帰属を表示する

7. 費用制御を実装する。
   - 初期表示で全区間を自動計算しない
   - 詳細表示／更新を明示選択した区間のみ
   - ユーザー別日次回数
   - 権利確認済み概算経路ヒット時は通常表示でAPIを呼ばない
   - Field Maskは距離、所要時間、必要最小限のtransit路線・乗換・運賃に限定する
   - 上限時は手動入力へ縮退
   - ルート最適化はこのPhaseでは実装しない

必須テスト:

- 各modeのrequest／mapping
- transitの時刻範囲、運賃なし、乗換、徒歩区間
- request fingerprint、single-flight、stale判定
- 並び替え時に自動呼出ししない
- 初期表示・未計算区間表示でAPIを呼ばない
- 非プレミアムは最新取得不可だが保存済み概算を閲覧可能
- entitlementをクライアントだけで偽装できない
- Googleライブ結果が永続ItineraryLeg／共有概算DBへ書かれない
- data_origin／rights_basisのない概算経路は共有登録できない
- 一部区間失敗でも他区間と手動データを失わない
- 上限、kill switch、timeout、offline→手動入力
- 余裕不足と出発推奨時刻
- 権利確認済み保存概算経路のoffline表示
- APIレスポンスに欠落フィールドがあってもクラッシュしない

完了条件:

- API取得不能でも手動経路で旅程を完成できる
- 画面再描画や並び替えだけでAPI件数が増えない
- 経路詳細または更新操作以外ではGoogle Routesを呼ばない
- Google応答をAPI代替目的の恒久共有キャッシュへ保存しない
- 運賃・公共交通が取得できない地域を正常状態として扱う
- ルート最適化とAI提案を先行実装しない
```

---

## Phase 5：共有・共同編集・通知・リリース品質

推奨モデル: **Claude Opus 4.8**

```text
Phase 5として、既存の現場共有と通知基盤が完成していることを確認したうえで、旅程の共有・共同編集・通知・最終品質を実装してください。前提基盤が未完成なら見せかけUIを作らず、依存不足を報告して先に必要な基盤を完成させてください。

1. 共有・共同編集を実装する。
   - 初期は本人のみ
   - owner / editor / viewer
   - ownerだけが共有設定、権限変更、旅程削除可能
   - editorは許可された旅程項目を編集可能
   - viewerは閲覧のみ
   - RLSとStorage policyで強制
   - 共有解除直後にキャッシュ、画像URL、画面履歴から到達不能にする

2. 項目単位共有を実装する。
   - 個人メモ
   - 正確な住所・座標
   - 予約URL・チケットURL
   - ユーザー画像
   - 交通／宿泊の予約情報

   安全側を既定値とし、Google由来の帰属表示は共有先でも維持する。

3. 共同編集競合を実装する。
   - version CAS
   - 項目単位の競合表示
   - server／local採用
   - 並び替え競合
   - 削除対編集
   - 同時追加
   - 黙ったlast-write-winsを禁止

4. 通知を実装する。
   - 出発時刻
   - スポット開始
   - チェックイン
   - 会場へ向かう推奨時刻
   - 余裕不足
   - 共有旅程更新

   通知価値を説明してからOS権限を要求する。拒否後も利用可能。同一旅程／項目／種別で冪等化し、同日通知を集約する。通知本文へ住所、座標、予約番号を入れない。

5. 思い出連携を実装する。
   - 訪問済みスポットを思い出へ選択追加
   - ユーザー画像だけを明示操作でアルバムへ追加
   - Google Place写真をアルバムへ複製しない
   - 計画と実際に訪れた場所を区別
   - 旅程削除で既存思い出を消さない

6. 品質を収束させる。
   - 一覧ページング
   - 低速通信、timeout、retry
   - offline→再起動→同期
   - タイムゾーン変更、日程変更、公演中止
   - Dynamic Type 200%、VoiceOver、横向き、320pt幅
   - Google API上限、kill switch、キー無効
   - 画像権限喪失、Storage失敗
   - アカウント削除と共有データ

7. 運用監視を実装する。
   - API種別ごとの匿名件数、成功率、cache hit率、上限到達率
   - 住所、座標、検索語、旅程本文を分析へ送らない
   - 予算通知とkill switch手順
   - Google規約・料金・帰属の四半期確認チェックリスト

8. プレミアムは機能フラグ境界だけ用意する。
   - 手動登録、基本旅程、メモ、URL、ユーザー画像、日別表示を制限しない
   - 課金画面や購入処理は実装しない
   - Places、Routes、最適化、AI等を将来制御できるUseCase境界に置く
   - クライアント表示だけでなくサーバー側でも将来制御可能にする

必須テスト:

- 全権限の正負RLS／Storageテスト
- 項目単位非共有
- 共有解除後のキャッシュ到達不能
- 同時編集、削除対編集、並び替え競合
- 通知冪等、同日集約、権限拒否、ディープリンク
- 通知・ログ・分析の禁止フィールド
- 思い出追加とGoogle写真非複製
- API上限／停止中も手動フロー成功
- アカウント削除、owner移譲、共有解除
- iOS実機で地図、外部URL、写真、通知、VoiceOver

完了条件:

- Critical／Highの未解決レビュー指摘が0件
- flutter analyze／全unit・widget・integration・pgTAP・iOS無署名buildが成功
- 手動のみ、Google有効、Google停止、offline、共有の主要E2Eが成功
- docs/requirements-traceability.mdとimplementation-status.mdが実装事実と一致
- AI旅程、ルート最適化、本課金は未実装としてバックログへ残す
```
