# 実装判断の記録（根幹一括実装 / 2026-07-02）

要件・ADRで確定していない点について、実装時に行った判断と理由を記録する。
矛盾が見つかった場合は requirements.md → ADR → architecture.md の順に優先して見直すこと。

## アーキテクチャ・依存

| # | 判断 | 理由 |
|---|---|---|
| D-01 | Riverpod は `flutter_riverpod` 2.6 系の手書き Provider / (AutoDispose)AsyncNotifier で統一し、`riverpod_generator` の導入は見送った | ADR-0003 の本質（AsyncValue による状態表現・override による DI/テスト差し替え）は全面採用。codegen 面は freezed / json_serializable / drift_dev で既に大きく、生成器を1つ減らして基盤の見通しを優先した。後続での generator 移行は機械的に可能 |
| D-02 | firebase_core / firebase_messaging は今回追加しない | 通知は「境界と土台」まで（プロンプト§4）。Firebase を依存に入れると google-services.json 無しでビルド不能になり、中心フローの検証を阻害する。境界型は `features/notifications/domain/notification_plan.dart` |
| D-03 | 接続監視は `ConnectivityObserver` 抽象 + 既定は「常時オンライン仮定・失敗時にpending保持」実装。connectivity_plus 等のプラグインは未導入 | 同期エンジンはネットワーク失敗を pending として保持し再poke で回復するため、OSイベント連動は最適化。テストでは `ManualConnectivity` を注入 |
| D-04 | サーバー行 JSON とドメインエンティティの二重定義（DTO層）は作らず、freezed エンティティの snake_case `fromJson/toJson` を Supabase 行 / Outbox payload と共用する | 単一ユーザー所有データで形が完全一致しており、DTO 分離は現段階では意味のない薄いラッパーになる。端末専用フィールド（例: `Ticket.imageLocalPath`）は payload から明示的に除外している |
| D-05 | ローカルDBの共有テーブル定義は `lib/core/db/app_database.dart` に集約 | Drift の DB は1つであり、feature 毎に分割すると part 構成が複雑化する。読み書きは各 feature の data 層のみが行う |
| D-06 | 端末KV（チュートリアル完了・テーマ・デモユーザー）も Drift の `app_kvs` テーブルに保存し、shared_preferences は未導入 | 依存削減。DB は起動時に必ず開かれる |

## ドメイン・時刻

| # | 判断 | 理由 |
|---|---|---|
| D-10 | 開場/開演/終演は「公演日 0:00 からの分数」で保持し、深夜公演は 1440 超（例 25:30 = 1530）で表現。終演≦開演の入力は翌日終演として自動補正 | タイムゾーン変換に依存せず日跨ぎを一意に表現できる。UI では終演入力時に「当日/翌日」を確認 |
| D-11 | 終演予定なしの場合の終演見込み: 開演あり→開演+4時間、時刻なし→公演日の終わり | 保守的仮定。§7.1「終演予定なしを壊さない」ため状態遷移が破綻しない値を採用 |
| D-12 | 余韻中は「終演見込み〜その暦日の終わり」、思い出は「終演日の翌日 0:00 から」 | §8.1「翌日以降は現場一覧・通常ホームに表示しない」に一致。深夜公演（翌1:30終演）は終演翌日から思い出になる |
| D-13 | 「準備中」は公演7日前から | 要件に閾値の定義がないため。`deriveGenbaStatus(preparingWindowDays:)` で変更可能 |
| D-14 | 中止現場は公演日経過後に思い出一覧へ表示（記録として残す） | §8.1 は「終了した現場」を思い出とするが、中止も推し活の記録であり削除しない方針（§18）に沿う |
| D-15 | 公演日は「会場現地の暦日」として端末TZで解釈し、DB上は `yyyy-MM-dd` 文字列。タイムスタンプは UTC ISO8601 | 現場の状態判定は端末TZ基準（architecture §10）。交通の出発/到着は timestamptz（UTC保存・ローカル表示） |

## 同期・データ

| # | 判断 | 理由 |
|---|---|---|
| D-20 | `outbox_operations`（サーバー側）は「適用済み client_mutation_id の記録」として実装 | プロンプト§5 のスキーマ一覧に含まれるため。再送の冪等化（二重適用防止）に使用。クライアント側キュー本体は Drift の `outbox_ops` |
| D-21 | LWW 判定はリモート `updated_at` > payload `updated_at` のとき ConflictFailure とし、Outbox に conflict として記録・自動再送しない（リモート優先） | §5「updated_at による last-write-wins を既定とし、競合記録を残す」。フィールド単位マージへの拡張は Outbox payload がフル行 JSON のため妨げない |
| D-22 | リモート pull（refreshFromRemote）は今回 genba 集約のみ実装。memory / oshi の pull は後続 | push（ローカル→Outbox→リモート）は全エンティティ対応済み。pull は「ホームのキャッシュ先行+背景更新」の実動対象である現場を優先。follow-up-work.md #1 |
| D-23 | pull 時、未同期変更（pending Outbox）がある行はリモートで上書きしない | 自動保存した端末変更を失わないため（§15.3） |
| D-24 | デモモード（development かつ SUPABASE_URL 未設定）ではリモート同期を完全停止し、Outbox は pending のまま保持。UI に「デモモード」バナーを常時表示 | 本番/staging は env 不備で起動を止める（暗黙フォールバック禁止）。デモ→本アカウントへの移行は将来課題 |

## UI・その他

| # | 判断 | 理由 |
|---|---|---|
| D-30 | UI文言は日本語リテラル直書き。gen_l10n（ARB）は未導入 | 単一ロケール（ja）のMVPで抽象化の益が薄い。多言語化時に一括抽出する |
| D-31 | チケットの「画像参照」は `imageLocalPath`（端末参照・同期対象外）と `imagePath`（Storage パス・境界）を分離 | 外部URLと保存画像の区別（§6.2）をデータモデルで担保。画像アップロードは後続 |
| D-32 | メモ（自由/物販/集合場所/周辺/注意）は区分ごとに1件で upsert | UI の即時確認性優先。複数メモが必要になれば unique 制約を外す拡張で対応可能 |
| D-33 | 現場フォームの下書きは `form_drafts` にキー `genba_form_new` / `genba_form_<id>` で自動保存 | §2.1 自動保存・再開。保存成功時に削除 |
| D-34 | 思い出のテキスト系は600msデバウンスの自動保存。「短い感想」は感想本文と同一フィールド | §8.2 の明示要件 |
| D-35 | アカウント削除はサーバー RPC `delete_account()`（SECURITY DEFINER）で auth.users を削除し FK カスケード。デモモードでは明示的に失敗を返す | 未実装処理を成功に見せない（プロンプト§3.6） |

## 認証主体ごとのローカルデータ分離（R1 / C-01, 2026-07-02）

| # | 判断 | 理由 |
|---|---|---|
| D-40 | ローカルDBの分離方式は「owner_id によるクエリ絞り込み（同一SQLiteファイル内でのowner partition）」を採用し、ユーザーごとの別DBファイルは採用しない | (1) `bootstrap.dart` は Supabase セッション復元が完了する前に `AppDatabase` を1つ開き、`databaseProvider` を override する設計になっており、DBのopen/close自体をログイン後まで遅延させる・ユーザー切替のたびに再openする設計へ変えるのはR1の範囲を超える大改造になる。(2) row-level分離はサーバー側RLS（ADR-0008）と対称的なモデルであり、2ユーザーを同一インメモリDBで切り替えるテスト（必須テスト要件）が容易に書ける。(3) 端末バックアップ等からの物理アクセスに対する防御は別ownerファイル分離でも row-level 分離でも解決しない（結局DB全体の暗号化が必要）ため、R3（H-03: SQLCipher相当の暗号化）で同時に対応する方が一貫性がある。DBファイル分離は将来的にR3以降で再検討の余地を残す |
| D-41 | 認証スコープを表す `LocalDataScope`（`lib/core/auth/local_data_scope.dart`）を `Loading / Unauthenticated / Authenticated(ownerId)` の3値で表現し、`currentUserProvider`（authStateChanges）から `localDataScopeProvider` として導出する | 「未認証」と「認証状態を復元中」を区別しないと、起動直後の一瞬だけ誤って空でなく前回値を返す・逆に本来復元されるはずのデータを一瞬空表示する、といった事故を防げない。3値にすることで「復元中は何も見せない」を型で強制できる |
| D-42 | `genbaRepositoryProvider` / `memoryRepositoryProvider` / `oshiRepositoryProvider` は `localDataScopeProvider` を `ref.watch` し、scope が変わるたびに Repository インスタンスを作り直す。Repository 自身は owner を再解決するのではなく、生成時に解決された owner を閉じ込めた `ownerIdResolver` を持つだけ | Riverpod の `Provider` は watch している依存が変わると再構築され、それに依存する `StreamProvider`（`genbaAggregatesProvider` 等）の購読も破棄→再購読される。これにより「ログイン/ログアウト/ユーザー切替の瞬間に古いRepositoryのStreamが新しい値を返すまでの間、前ownerの値を表示し続ける」というレース（要件7）を、ポーリングや手動invalidateなしに解消できる |
| D-43 | `SyncEngine` はログイン/ログアウトをまたいで単一インスタンスとして生存させ、drain 1回ごとに `ownerIdResolver()` と `remoteResolver()` を同じタイミングで読み直して owner とリモートクライアントを対応付ける。`OutboxStore` の `pendingOps/deleteSynced/retryFailed/hasPendingFor/watchStatusCounts` はすべて `ownerId` を必須引数にする | SyncEngineをRepositoryのようにscope変化のたびに作り直すと、drain中のFutureが完了してからdisposeされるまでの間に別ownerのremoteResolverへ切り替わり得るため、「Aの操作をBのセッションで送る」事故（C-01）を防げない。owner/remoteをdrain呼び出しの先頭で一度に確定させ、Outbox問い合わせ自体をownerで絞ることで、既存の1インスタンス設計を保ったまま安全にできる |
| D-44 | `FormDrafts` の主キーを `{key}` から `{ownerId, key}` の複合キーへ変更する（schemaVersion 1→2）。旧バージョンの行は移行時に破棄し、owner不明のまま引き継がない | 下書き（`genba_form_new` 等）はサーバーに存在しない端末専用データであり、どのownerの下書きか記録がない旧データを特定ユーザーへ推測で割り当てるのは要件6「owner不明データを別ユーザーへ推測帰属させない」に反する。下書きは自動保存の利便性機能であり、消えても再入力コストのみで実害がないため、安全側に倒して破棄する |
| D-45 | `AppKvs`（`tutorial_done` / `theme_mode` / `demo_user`）は owner 分離の対象外とし、端末単位の設定のまま維持する | チュートリアル完了・テーマは個人情報ではなく端末のUX設定であり、複数ユーザーが同一端末を使っても意図的に共有してよい。`demo_user` はそもそも「現在ログイン中のユーザーが誰か」を表すセッションポインタ自体であり、scope導出の入力であって分離対象のユーザーデータではない |
| D-46 | アカウント削除（`AccountController.deleteAccount`）はサーバーRPC成功後にのみ `purgeLocalDataForOwner` でローカル全テーブルの当該owner行を物理削除する。ログアウト・ユーザー切替では呼ばない | 要件「user-Aへ戻る場合の保持方針が仕様どおりで、意図せぬ消失がない」を満たすには、ログアウトはowner行を保持したままクエリ側の絞り込みで不可視化するだけにし、物理削除は取り消し不能な「アカウント削除」操作に限定する必要がある |
| D-47 | Drift の索引（owner/date, genba_id, owner/status 等, M-04）は `@TableIndex` アノテーションではなく `Migrator.database.customStatement('CREATE INDEX IF NOT EXISTS ...')` で作成する | `@TableIndex` は drift_dev のコード生成に依存し、`onUpgrade` から生成済み `Index` オブジェクトを参照する配線がバージョン依存で不安定になりやすい。`CREATE INDEX IF NOT EXISTS` は onCreate/onUpgrade のどちらから呼んでも冪等で、SQLite標準機能のみで完結する |
| D-48 | `GenbaRepositoryImpl` の pull 差分削除ロジック（`applyPulledRows`）は `SupabaseClient` への依存を持たず、リモート行 `List<Map<String, dynamic>>` を直接受け取る形へ分離し `@visibleForTesting` で公開する | 「pull差分削除が別ownerを消さない」ことを検証する回帰テストが必須要件だが、実 Supabase 接続なしに `SupabaseClient` をテストで模倣するのは非現実的（SDKの内部型に強く依存するため）。ロジック本体をSupabase型から切り離すことで、テストDBのみで決定的に検証できる |

## R1 追加修正（認証切替の排他制御・親owner整合・削除リカバリ, 2026-07-02）

| # | 判断 | 理由 |
|---|---|---|
| D-49 | 同期は owner と `RemoteMutationClient` を単一の `SyncAuthSnapshot` として「1回の provider 読み取りで同時確定」し、SyncEngine は `snapshotResolver` 1本だけを受け取る（owner と remote を別々の resolver で渡さない） | owner と remote を別々に読むと、await をまたいだ認証切替で「A の owner に B の remote」という不整合が起き得る。`syncAuthSnapshotProvider` が `localDataScopeProvider` と `remoteMutationClientProvider`（どちらも `currentUserProvider` 由来）を同時に watch することで、両者は構造的に常に同じ認証状態の組になる |
| D-50 | drain は先頭で snapshot を確定し、(1) その owner の op だけを (2) その snapshot の remote へ送り、(3) 各 op 送信の前後で `_isSnapshotCurrent`（owner 不変）を再確認して切替検出時に中断する。加えて `pauseForAuthTransition()` で「新規 drain 停止 + 実行中 drain の完了待ち」を行い、`AuthController.signOut` が認証状態を変える前に呼ぶ | 「A の Outbox が B のセッションへ渡らない」ことを多層で保証する。captured remote を使うため apply 自体は常に A→A で安全だが、await をまたぐ切替の早期中断と、切替と drain の排他制御（in-flight mutation 完了待ち）を明示的に加えることで、要件「実行中の remote mutation が安全に完了するまで認証主体を切り替えない」を満たす |
| D-51 | 子データ（ticket/transport/lodging/todo/memo, memory 各種, oshi member）の upsert 時に、書き込みと同一 transaction 内で親（genba / oshi_group）が現在 owner に属することを検証し、満たさなければ `ParentOwnershipException`→`ValidationFailure` で拒否してローカル行も Outbox も作らない。SQLite の FK ではなく Repository transaction + テストで担保 | Drift スキーマに宣言的 FK を後付けすると既存 v1 データの制約検証で移行が壊れやすく、また「別owner の親」という owner 軸の制約は素の FK では表現できない。存在しない親・別owner の親・推測 ID をすべて同一の型付き失敗に落とすことで、UIは一貫して扱える |
| D-52 | Outbox の `enqueue` は同一 mutationId の別owner行があれば拒否、`updateStatus` は owner を必須引数にして owner 一致行のみ更新する | mutationId は UUIDv4 で衝突しないが、多層防御として「別owner の mutationId・状態を書き換えられない」ことをストア層でも保証する（C-01 の防御強化） |
| D-53 | アカウント削除は「サーバー削除成功 → 未完了マーカー(`KvKeys.pendingAccountPurge`, AppKvs)記録 → ローカル purge → マーカー消去」の順で行い、purge 途中で落ちても起動時 `resumePendingAccountPurge` で再試行する。purge は owner 単位で冪等（対象owner の行を消すだけ）。`AccountController` は finally で必ず `AsyncData` に戻し、AsyncLoading で固まらない | サーバー削除済み・ローカル未削除の中間状態を安全に回収するため。マーカーはサーバー削除の後に書くので「サーバー未削除なのにローカルだけ消す」ことは起きず、purge の冪等性により部分削除済みでも再実行できる |

## R2 同期ライフサイクル・復元・競合制御（H-02, 2026-07-02）

| # | 判断 | 理由 |
|---|---|---|
| D-60 | 再送バックオフは純関数 `RetryPolicy`（指数＋ジッター＋最大間隔、乱数注入可）で計算し、次回時刻を `outbox_ops.next_retry_at`（TEXT, UTC ISO8601）へ永続化する（schema v3）。`OutboxStore.dueOps(now)` が待機明けの op だけを返す | バックオフを DB に持たせることで、再起動後も attempt/status/next_retry_at がそのまま復元され、タイトループ再送や二重送信を避けられる。乱数注入でテストを決定的にできる |
| D-61 | drain の駆動（いつ送るか）は application 層の `SyncCoordinator`、送信自体（どう送るか）は `SyncEngine` に分離。Coordinator は起動時・認証復元/ログイン・app resume・周期タイマー（バックオフ明け）で drain を促す。オンライン復帰は SyncEngine が接続監視を購読、enqueue 直後は Repository が poke するため二重に持たない | 責務分離でテスト容易性を確保（Coordinator は drain 回数だけ検証、Engine は送信挙動を検証）。トリガー元を1箇所に集約しない代わりに、各トリガーの所在をコメントで明示して二重化を防ぐ |
| D-62 | 実接続監視は `ReachabilityConnectivity`（プラグイン非依存、到達性 probe 注入）で実装。connectivity_plus は導入しない | 本環境（オフライン・pub cache に無い）で `flutter pub get` を壊さないため。かつ「OSがオンライン＝到達可能」ではないという要件を、能動的 probe で直接満たせる。probe/refresh を注入・直接呼び出しできる設計で、実タイマー・sleep なしにテストできる。実 probe は Supabase health への軽量 HTTP（非デモ時のみ） |
| D-63 | 競合判定はサーバー `version`（書き込みごとに単調増加、トリガー）による CAS で行い、端末 `updated_at` を用いない。クライアントは既知版を `remote_versions`（schema v3）にキャッシュし base_version として送る | 端末時計のずれ（clock skew）で新しいサーバーデータを誤って上書きする LWW の弱点を排除する（受入条件「端末時計が大きくずれても誤ったLWWで失わない」）。版はフィールド単位マージへ将来拡張しても壊れない |
| D-64 | サーバー適用は `apply_mutation` RPC（migration 0006, SECURITY INVOKER）で「版CAS＋実データ変更＋冪等ledger記録」を1トランザクションで行う。クライアントは `MutationTransport` seam 越しに呼ぶ | 変更成功後・ledger記録前のクラッシュでも二重適用しない（原子性, 受入条件「同一mutationを何度再送してもリモート変更は1回」）。seam により Supabase 実接続なしに冪等・競合ハンドリングを単体テストできる |
| D-65 | memory/oshi の remote pull を追加し、genba と同じ「owner限定・未同期は上書きしない・他ownerを読まない」共通ヘルパ `applyPulledRowsInto` に一本化。ログイン直後に genba/memory/oshi を pull | 新規端末相当の空キャッシュから genba/準備/memory/oshi を復元できる（受入条件）。C-01 の owner 境界を pull でも一貫させる |
| D-66 | drain の対象取得（dueOps/pendingOps）は created_at 昇順に加え、暗黙 rowid（挿入順）を第二キーにする | 固定Clockのテストや同一ミリ秒の連続 enqueue で created_at が同値でも、送信順（順序保持）を決定的にするため |

## R2 追加ハードニング（版CAS原子性・pull版キャッシュ, 2026-07-02）

| # | 判断 | 理由 |
|---|---|---|
| D-67 | `apply_mutation` RPC は mutation_id と entity(table+id) の transaction-scoped advisory lock（`pg_advisory_xact_lock`、常に mutation→entity の順で取得）で並行呼び出しを直列化し、ロック取得後に ledger・現在version・owner を再確認する | 「version読み取り→比較→upsert」が非排他だと同じ base_version の並行更新が両方成功し得る。advisory lock で直列化し、後発writerはロック取得後に version 増加を観測して conflict になる。同一 mutation_id の並行再送も lock＋ledger で実データ変更・version増加を1回に限定する |
| D-68 | 既存行への `base_version=null` は blind overwrite/delete とみなし conflict。delete にも version CAS を適用。payload.id と p_entity_id の不一致は拒否 | 「古い端末が新しいリモート行を無条件に上書き/削除する」事故を防ぐ。クライアント側でも、版キャッシュが無い既存行への更新は base=null 送信→サーバー conflict→pull 要求、という流れになる |
| D-69 | RPC の INSERT/UPDATE は payload の「実在許可列のみ」を対象にする（`information_schema` と突き合わせ、`jsonb_populate_record` から必要列だけ SELECT）。id/owner_id/version はクライアント値を使わずサーバーが制御（id=p_entity_id、owner_id=auth.uid、version=トリガー） | 全列 INSERT だと payload に無い列へ NULL が入り DB default が効かない。列を絞ることで default を正しく適用し、なりすまし列（owner_id/version）や未許可列の注入も防ぐ。テーブル名・列名は whitelist と実在列に限定して SQL 注入を排除 |
| D-70 | remote pull は各行の `version` を owner/table/id 単位で `remote_versions` に保存し、未同期(pending)行は取り込まず版も進めない。リモート削除の取り込みで版キャッシュも削除する | 新規端末が version=5 の行を pull した後の更新は base_version=5 で送られ、正しく CAS される（受入条件）。未同期行の版を進めると自分のローカル変更を競合扱いしてしまうため保存しない |
| D-71 | owner矯正の仕様に合わせ、pgTAP は「新規 id に他ユーザー owner_id を入れた payload は拒否ではなく現在ユーザー所有で作成」を期待値とする。他ユーザーの既存行への upsert は（RLS で不可視→id 衝突）conflict、delete は不可視 no-op で対象行は不変、を検証 | RPC が owner_id を auth.uid へ矯正する実仕様に一致させるため。既存行保護は RLS＋unique_violation→conflict で担保 |

## R3 端末暗号化と画像の耐久保存（H-03/H-04, 2026-07-02）

### 選定ライブラリ
| 用途 | 採用 | 理由 |
|---|---|---|
| DB暗号化 | `sqlcipher_flutter_libs`（SQLCipher, sqlite3_flutter_libs と置換） | 独自暗号を作らず、SQLite全体を業界標準の SQLCipher で暗号化（ADR-0005/§15.2）。drift 公式の暗号化レシピに一致。二重リンク回避のため sqlite3_flutter_libs は依存から外した |
| 暗号鍵保管 | `flutter_secure_storage`（iOS Keychain / Android Keystore(EncryptedSharedPreferences)） | 鍵をOSのセキュア領域に置き、ログ・dart-define・ソースへ置かない。鍵は初回に `Random.secure()` で256bit生成（固定鍵にしない） |
| SQLite Dart API | `sqlite3`（dependencies へ昇格） | 暗号化DBの open/export/verify に本番コードから使うため dev から通常依存へ移動 |

### 脅威モデル（H-03/H-04）
- **想定脅威**: 紛失・盗難端末やバックアップ経由でのローカルDBファイル/画像の直接読み取り（§15.2「保存データの暗号化」）。
- **対策**: SQLite全体を SQLCipher で暗号化（座席・整理番号・予約番号・住所・メモ・画像パス等の機密本文を平文検索不可に）。鍵はOSセキュアストレージのみに保持。チケット画像はアプリ管理領域（後日バックアップ除外）に隔離。
- **非対象（明示）**: root/jailbreak 済み端末でのメモリダンプや鍵抽出、OSレベルの完全侵害。独自の追加暗号は行わない。

| # | 判断 | 理由 |
|---|---|---|
| D-72 | DB暗号化は SQLCipher。平文DB `oshitrip_<flavor>.sqlite` → 暗号化DB `oshitrip_<flavor>.enc.sqlite` へ一度だけ移行する。移行は `EncryptionMigration`（プラグイン非依存の choreography）＋ device の `sqlcipher_export`/verify を注入 | 検証成功まで平文を消さない・確定は atomic rename・失敗は型付き Failure でロールバックし平文温存、を host テストで決定的に検証できるようにするため（受入条件「失敗を成功扱いにしない・入力を可能な限り保持」） |
| D-73 | 鍵取得・移行の失敗は起動を明示エラー画面で停止し、平文を残す（成功扱いにしない） | 鍵消失・容量不足・migration失敗時にデータを失わせない。原因解消後の再起動で再試行できる |
| D-74 | 画像は `ImageStore` で `images/<owner>/<category>/<uuid>.<ext>` へ atomic copy（tmp→rename）。DBには絶対一時パスではなく相対参照を保存。`resolve()` は旧絶対パスも許容（後方互換） | ImagePicker の一時ファイルが消えても表示でき（受入条件）、owner/用途別・推測困難名で隔離。相対参照によりアプリ移動・再起動に耐える |
| D-75 | チケット画像は最も機密度の高い区分（`ImageCategory.ticket.isSensitive`）。専用ディレクトリに隔離し、ヒーロー/思い出表紙へ流用しない（区分分離＋呼び出し側で担保）。ログ除外は `core/logging` の画像パスマスクで担保 | §7.3/§7.8/ADR-0008。iOS の NSURLIsExcludedFromBackupKey 実結線はプラットフォームチャネルが必要なため follow-up（best-effort no-op）とし、区分・ログ・cover流用の各禁止はコードで担保 |
| D-76 | 画像の孤立清掃: レコード削除で `deleteRef`(owner限定)、アカウント削除/起動時purgeで `purgeOwner`(owner配下のみ)。別 owner のファイルには触れない | §15.2「関連データ削除」・C-01 の owner 分離を物理ファイルにも適用 |
| D-77 | 写真権限: iOS `Info.plist` に `NSPhotoLibraryUsageDescription` を追加。Android は image_picker の Photo Picker（権限不要）。権限拒否/キャンセルは `pickImage` が null を返し主要フロー継続 | 受入「権限拒否でも主要フローを継続」。過剰な権限は追加しない |

## R3 ハードニング（H-03 暗号化状態機械 / H-04 実バックアップ除外, 2026-07-02）

D-72/D-74/D-75 の初回実装を、以下で強化・置換した（R1/R2 の挙動は不変）。

| # | 判断 | 理由 |
|---|---|---|
| D-78 | DB解決を `EncryptedDbResolver`（`EncryptionMigration` を置換）へ変更。平文/暗号化DB/`.migrating`/`.premigration.bak` の全組合せを状態機械として解決する。既存暗号化DBは起動時に必ず「正しい鍵で verify」してから使う | 「暗号化DB確定直後の電源断で平文/backup が残った状態」でも、まず暗号化DBを verify し、その後で残存を安全に掃除できる。未確定の `.migrating` は常に破棄する。全分岐を host テストで決定的に検証（`encrypted_db_resolver_test.dart`） |
| D-79 | 既存暗号化DBに対し鍵が無い（`key-missing`）／verify 失敗（`verify-failed`）の場合は、**鍵を再生成・上書きせず**型付き `EncryptionSetupException` で起動を停止し、平文を消さない | 鍵を再生成すると既存暗号化DBを永久に開けなくする。誤鍵/鍵消失時にデータを失わせないための最重要不変条件。エラー画面で再試行を促す |
| D-80 | 鍵読み取りは `readRaw`（生成しない）と `getOrCreateKey`（無ければ生成）を分離。resolver は「既存DBあり」では前者、「新規/移行」でのみ後者を使う | 「既存DBあり＋鍵無し」で誤って鍵生成してしまう事故を型で防ぐ。鍵は `Random.secure()` で256bit、OSセキュアストレージのみ（`db_key_store_test.dart` で256bit・非固定・再生成しないを検証） |
| D-81 | 実端末 SQLCipher 検証を `integration_test/encryption_sqlcipher_test.dart` として追加（device専用）。①暗号化DBは平文検索不可（生バイトに機密が出ない・"SQLite format 3"ヘッダも無い）②正鍵で再オープン可③誤鍵で失敗、を検証 | ホスト(winsqlite3)は PRAGMA key を持たず SQLCipher の実効性を検証できないため、実端末境界テストで担保する（`flutter test integration_test/... -d <device>`）。未実施は成功と報告しない |
| D-82 | `ImageStore.resolve()`（絶対パス後方互換）を**廃止**し、全て owner スコープ API（`resolveOwned`/`tryResolveOwned`/`statusOf`/`deleteRef`）へ変更。別owner参照・絶対パス・`..`・バックスラッシュ区切りは拒否。旧絶対パスも解決しない | 「別ユーザーの画像や任意パスを開けてしまう」経路を型と検証で塞ぐ（C-01/H-04）。負テスト（user-B から user-A 参照の resolve が拒否される）で担保（item9, `image_store_test.dart`） |
| D-83 | バックアップ除外を実装（no-op廃止）。iOS/macOS は MethodChannel `oshitrip/secure_files`→`AppDelegate` で `NSURLIsExcludedFromBackupKey` を設定。Android は `allowBackup=false`＋`fullBackupContent=false`＋`data_extraction_rules`（cloud-backup/device-transfer 全除外） | 紛失端末やバックアップ経由での機密画像流出を実際に防ぐ（H-04）。ImageStore は機密区分(ticket)の import 時にのみ `BackupExcluder` を呼ぶ（`image_store_test.dart` で実絶対パスで呼ばれる/非機密では呼ばれないを検証） |
| D-84 | `SupabasePhotoUploader` に `ImageStore` を注入し、`File(localPath)` 直参照をやめ `tryResolveOwned(photo.ownerId, ref)` で安全解決してからアップロード。不正参照は `ValidationFailure` | 相対参照化に伴い、別owner・絶対パス・トラバーサルを排したうえでのみ外部送信する（item6） |
| D-85 | 画像の孤立防止を全経路に適用: ①`addPhoto` の DB保存失敗時に import 済みファイルを削除 ②チケット編集は session import を追跡し、保存確定時に差替え/クリアで捨てた画像と元画像を削除、保存失敗時は今回importを全削除 ③チケット/現場レコード削除で紐づく画像を owner スコープで削除 ④アカウント削除/起動時 purge は `purgeOwner` | 「差替え・レコード削除・DB保存失敗・アカウント削除で孤立ファイルを残さない、他ownerのファイルには触れない」を満たす（item8）。全て owner スコープの `deleteRef`/`purgeOwner` で他ユーザー分離を維持 |
| D-86 | 行末コード方針を `.gitattributes` で明示。Dart/共通テキストは LF、Flutter生成のネイティブ(iOS/Android)ファイルは CRLF のまま `whitespace=cr-at-eol` を付与 | 既存の CRLF 慣習（HEAD のネイティブファイルは CRLF）を保ちつつ、`git diff --check` の CR 誤検知を解消（行末コードの一括変換という無関係な差分を避ける）。Info.plist の実トレイリング空白は無し（item10） |

### 検証状況（2026-07-02, Windows host）
- `dart format` / `dart analyze`（`flutter analyze` は非ASCIIパスで落ちるため）: **issues 無し**。
- `flutter test`: **162 件 全パス**（暗号化状態機械・鍵生成・画像owner分離/負テスト・孤立清掃を含む）。
- `git diff --check`: **クリーン（exit 0）**。
- **未実施（成功と報告しない）**: 実端末 SQLCipher 検証（`integration_test/encryption_sqlcipher_test.dart`）は device/emulator が必要で host では実行不可。Android/iOS の実機ビルドおよびバックアップ除外の実機設定確認も未実施（要 device）。これらは端末が利用可能な環境で実行すること。

## R3 最終修正（失敗の非成功化・端末画像の全用途結線, 2026-07-02）

R1/R2 と既存 R3 の挙動を変えずに、失敗の握りつぶし排除と hero/oshi 画像の
本結線を行った。

| # | 判断 | 理由 |
|---|---|---|
| D-87 | iOS バックアップ除外の失敗を成功扱いにしない。`ImageStore.import` は機密区分でバックアップ除外に失敗したら生成ファイルを削除し `ImageStorageException` を投げ、UI は `StorageFailure` を表示する。bootstrap の `_excludeFromBackup` は iOS/macOS で失敗時に rethrow する。Android は allowBackup=false を維持し no-op | 除外できない機密画像を保存し続けると流出リスクが残る。「確定保存できた」と偽らず、生成物を残さず、ユーザーに失敗を返す（H-04）。Android はプラットフォームで全体除外済みのため import 時の追加処理は不要 |
| D-88 | チケット/推し画像編集で、保存せず戻る・シートを閉じる・widget 破棄の場合、その編集セッションで import した未確定画像を owner スコープで削除する（チケットは `dispose`、推しは `showDialog` 終了後）。保存済み旧画像（`existing.imageLocalPath`）は session import に含めないため削除されない | 「キャンセルで孤立ファイルを残さない／保存済み画像は消さない」を満たす（item2）。差替え・クリア・保存失敗は従来どおり `_reconcileImageFiles` が処理し、キャンセル経路のみ dispose/後処理で補完する |
| D-89 | `ImageAssetStatus` に `inaccessible` を追加。`statusOf` は `exists/read` の `FileSystemException`（権限不足・端末ロック時の iOS ファイル保護等）や「ファイル位置がディレクトリ」の不整合を例外にせず `inaccessible` へ変換する。`deleteRef` も best-effort（後片付けの失敗を握りつぶす） | 端末ロック中の読み取り不能などをクラッシュさせず型付き状態で扱う（item3）。`present/missing/inaccessible` を UI/呼び出し側が区別できる |
| D-90 | `EncryptedDbResolver` は Secure Storage 読取(`key-read`)・生成(`key-create`)・ファイル操作(`cleanup`/`restore`/`finalize`)の失敗を段階付き `EncryptionSetupException` へ変換する。verify 内例外は「検証失敗」に倒す。bootstrap は `prepare`/`resolve`/`open` を付与し、あらゆる失敗を必ずエラー画面へ到達させる | 「Keychain 例外・rename/delete 失敗・SQLCipher 準備失敗を成功扱いにしない」を型で保証（item4）。鍵消失(null)は `key-missing` のまま維持し、鍵再生成による既存DB破壊を防ぐ（D-79） |
| D-91 | `AppDatabase` 生成後に `openVerifiedDatabase`（新規 `open_verified_database.dart`）で `SELECT 1` を実行し実際に open を強制する。失敗したら接続を閉じて `EncryptionSetupException('open')` を投げる（close 自体の失敗は握りつぶし、元の失敗を伝える） | NativeDatabase の遅延 open では鍵不一致・破損・IO 失敗を検出できない。強制 open で確実に検出し、開けない接続を残さない（item5）。host で `LazyDatabase` を使い open 失敗経路を単体テストできる |
| D-92 | `ImageCategory.genbaHero`/`oshiImage` を本結線。現場詳細に hero 画像、推しメンバー編集に推し画像の「選択・表示・差替え・削除」を実装。参照は owner 別相対参照（`images/<owner>/hero|oshi/...`）。Drift schema v4 で `genbas.hero_image_local_path` / `oshi_members.image_local_path` を nullable 列として安全に追加（既存行は null） | enum だけで終わらせず全用途を実フローへ接続（item6）。相対参照で再起動・移動に耐え、owner スコープ解決で他ユーザー分離を維持 |
| D-93 | hero/oshi の端末内参照は同期しない。upsert の payload から `hero_image_local_path`/`image_local_path` を除去し、pull は `preserveLocalImage: true`（`Value.absent`）でローカル参照を null 上書きしない | ローカル画像参照は端末固有でサーバー列も無い。Outbox/Supabase へ送らず、他端末由来の pull でローカル参照を失わない（item6）。ticket の既存方式（D-74/`image_local_path` 除去）と一貫 |
| D-94 | hero/oshi の孤立防止: 差替え・クリア・保存失敗・レコード削除（メンバー削除／グループ削除でメンバー画像を一括／現場削除の sweep に hero を追加）で owner スコープ削除。アカウント削除・起動時 purge は既存 `purgeOwner` が用途ディレクトリごと回収 | 全画像用途で「孤立を残さない・他ownerに触れない」を一貫させる（item6、D-85 の拡張） |

### 追加テスト（item7）
- `image_store_test.dart`: バックアップ除外失敗で import 失敗＆生成物を残さない／コピー元欠落で失敗／読み取り不能→`inaccessible`／hero・oshi の別owner解決拒否／編集キャンセル相当でセッション画像だけ削除。
- `encrypted_db_resolver_test.dart`: Keychain 読取例外→`key-read`、生成例外→`key-create`、確定 rename 失敗→`finalize`（いずれも平文/既存DB温存）。
- `open_verified_database_test.dart`: open 成功で `SELECT 1` 通過／open 失敗で接続を閉じ `open` ステージ停止。
- `local_image_ref_sync_test.dart`: hero/oshi 参照が Outbox payload に載らず DB 永続化（再起動相当で残る）／pull の preserve でローカル参照を保持し、preserve なしなら上書きされる（対照）。

### 検証状況（2026-07-02, Windows host, 再掲更新）
- `dart format` / `dart analyze`: issues 無し。`flutter test`: **175 件 全パス**。`git diff --check`: クリーン（exit 0）。
- **未実施（成功と報告しない）**: 実端末 SQLCipher 検証・Android/iOS 実機ビルド・実機でのバックアップ除外設定確認・実機の写真ピッカー経由フローは device 必須のため未実行。端末が使える環境で実施すること。

## R4 環境分離ハードニング（H-01/M-02, 2026-07-02）

development/staging/production の3flavorが取り違えビルド・不完全設定で
本番事故を起こさないよう、Dart entry・ネイティブ設定・CI・署名境界を
一貫させた。

| # | 判断 | 理由 |
|---|---|---|
| D-95 | `core/config/flavor_guard.dart` を新設。Dart entry 由来の [Flavor] と、実行中バイナリの applicationId(Android)/bundle id(iOS) を、`.dev`/`.stg`接尾辞・接尾辞なしという共通規約で照合する `matchesFlavor`/`assertFlavorMatchesNativeId`（純関数・単体テスト可）を実装。bootstrap は `package_info_plus` で実際の nativeId を取得し、起動直後（Supabase初期化・デモモード判定より前）に検証、不一致なら `_FlavorMismatchErrorApp` で停止する | 「production の applicationId + development entry」等の取り違えビルドを、CLI引数の付け間違いに関わらず実行時に必ず検出・拒否するため（build-time チェックはFlutterツールの`--flavor`と`-t`が独立引数で機械的に強制できないため、実行中バイナリの実アイデンティティを見る runtime ガードを採用） |
| D-96 | dart-define の `APP_ENV`/`APP_NAME`（.env.example・CIのenv jsonに存在したが `AppEnv` はどちらも未読）を削除。環境は Dart entry のみで決まり、表示名は `AppEnv.appTitle`（Dart）と各プラットフォームの flavor 別リソース（Android `res/values-<flavor>/strings.xml`、iOS `Flutter/<Flavor>.xcconfig` の `APP_DISPLAY_NAME`）で分離する | 使われない値が「環境を表しているように見える」ことで、実体（Dart entry/ネイティブ設定）と食い違っても検知できない二重の真実を生んでいたため（M-02） |
| D-97 | Android: `android/app/src/{development,staging,production}/res/values/strings.xml` で `app_name` をflavor別に定義し、`AndroidManifest.xml` の `android:label` を `@string/app_name` に変更（旧: 本番名をハードコードしていたため development/staging でも本番名が表示されていた） | resValue() Gradle DSL は最新AGPで不安定なため、標準のflavorソースセット別リソースで確実に分離する |
| D-98 | Android: `android/key.properties`（.gitignore済み）からのリリース署名注入境界を追加。無ければ development/staging の release は debug 署名にフォールバックするが、`assembleProductionRelease`/`bundleProductionRelease` タスクは実署名が無い場合に `doFirst` で明示的に `GradleException` を投げて拒否する（他flavor・他buildTypeの設定評価には影響しない） | 「Android release で debug 署名を使う現状は本番リリース不可」という状態を、検出不能な成功として通さないため。development の `flutter run --release` 等の既存ローカル運用は壊さない |
| D-99 | iOS: `IPHONEOS_DEPLOYMENT_TARGET` を全ビルド設定で13.0→15.0へ統一（ADR-0006）。`ios/Flutter/{Development,Staging,Production}.xcconfig` を新設し、各々 `PRODUCT_BUNDLE_IDENTIFIER`（`.dev`/`.stg`接尾辞・接尾辞なし）と `APP_DISPLAY_NAME` を定義。`Info.plist` の `CFBundleDisplayName` を `$(APP_DISPLAY_NAME)` に変更 | Android と同じ接尾辞規約をiOS側でも成立させ、`flavor_guard.dart` の判定ロジックを両OS共通にするため。iOS最低バージョンをADR-0006の決定どおりに反映 |
| D-100 | iOS: `project.pbxproj` の PBXProject/Runner ターゲット双方で、Debug/Release/Profile の3configurationを`{Debug,Release,Profile}-{development,staging,production}`の9configurationへ複製し、Runner側の `baseConfigurationReference` を対応するflavor xcconfigへ切替。ハードコードされていた `PRODUCT_BUNDLE_IDENTIFIER` はRunner側の複製configurationから削除し、xcconfig側の値のみを単一の真実とした。RunnerTests targetのconfiguration（Debug/Release/Profile）はflavor化せず維持し、共有Xcode Scheme `development`/`staging`/`production` を新設（各Actionで対応するflavor付きconfigurationを参照、Testablesは持たせない）。曖昧な既定の `Runner.xcscheme` は削除した | Flutterの `flutter build ios --flavor <name>` は同名のXcode Schemeを選択して叩くため、3flavorそれぞれに対応するSchemeが無いと `--flavor` を渡しても機能しない（従来の未実施状態, follow-up-work.md #14）。pbxprojの手編集はPythonの `pbxproj` ライブラリで行い、ID参照（`PBXKey`）の comment解決も含めて元のXcode書式と一致することをラウンドトリップ・ダングリング参照ゼロで検証した（Windows上にXcodeが無いため、実ビルドでの検証は別途macOS環境が必要） |
| D-101 | CI: Android buildステップに欠けていた `-t lib/main_development.dart` を追加（従来はflavorのみ指定されGradle上のapplicationIdとDart entryの対応がCI上でも保証されていなかった）。macOS iOS buildステップに `--flavor development` を追加（Xcode Schemeが揃ったため）。CIのenv jsonから `APP_ENV` を削除 | 全flavorの「Dart entry と ネイティブflavorの対応関係」を固定する、という要求をCI自体でも一貫させるため。設定不備・デモフォールバック禁止・flavor不一致ガードはビルドを要さない純Dartロジックのため `flutter test`（`test/core/env_flavor_test.dart`）で全flavor分を検証し、ネイティブビルドはdevelopmentのみに絞った（H-01の要求どおり、Android/iOSのdevelopment buildをCIで検証） |

### 追加テスト
- `test/core/env_flavor_test.dart`: `AppEnv.isDemoMode` が development+設定なしのみ許可されること（staging/productionは設定なしでもデモにならない）／`matchesFlavor`・`assertFlavorMatchesNativeId` がAndroid/iOS双方の接尾辞規約で正しく判定し、production applicationId+development entryのような取り違えを型付き例外で拒否すること。

### 検証状況（2026-07-02, Windows host）
- `dart format` / `dart analyze`: issues 無し。`flutter test`: **189件 全パス**。`git diff --check`: クリーン（exit 0）。
- pbxproj: `pbxproj`（Python）ライブラリでの再パース成功、ダングリングID参照ゼロ、9configuration×2ターゲットレベルの生成を確認。xcscheme 3件はXML妥当性を確認。
- **未実施（成功と報告しない）**: `flutter build apk --flavor development`（Android SDK未導入のため）、`flutter build ios`／Xcodeでの実ビルド・アーカイブ・実機起動確認（macOS環境が無いため）。Gradle Kotlin DSLの署名境界（key.properties分岐・productionタスクガード）とiOS pbxproj/scheme一式は、実際のGradle/Xcodeでの実行検証をしていない。

## R4 最終修正（flavor構成の完全一致化・静的検証, 2026-07-02）

R1〜R3は変更せず、flavor構成のみを修正した。

| # | 判断 | 理由 |
|---|---|---|
| D-102 | `flavor_guard.dart` の判定を `endsWith('.dev')`/`endsWith('.stg')` の接尾辞判定から、`allowedNativeIds`（Android/iOS共通の正式IDをflavorごとに列挙した完全一致の許可リスト、計3値）へ変更 | 旧実装は「.dev/.stgで終わらない任意の文字列」を無条件に production として一致させてしまい、無関係な別アプリのID・なりすましIDを誤って許可する余地があった（例: `com.attacker.app` が production 扱いされる）。既知の3値のみを許可することでこの穴を塞ぐ |
| D-103 | 正式プロダクト名を `OshiTrip`、Dart packageを`oshi_trip`、Android/iOS共通のproduction IDを`app.oshitrip.mobile`とする。developmentは`.dev`、stagingは`.stg`を付ける | 旧scaffoldに由来する無関係な組織名を完全に除去し、表示名・コード上のpackage・native ID・Supabaseローカルproject ID・端末DB/鍵prefixを製品名由来で統一するため。ストア登録前に固定し、公開後のID変更を避ける |
| D-103 | `test/core/env_flavor_test.dart` に「完全一致以外はすべて拒否する」回帰テスト群を追加（無関係アプリの`.dev`/`.stg`終端、なりすまし接尾辞、大文字小文字違い、空文字、前後空白など11パターン×3flavor＝33ケース＋α） | 旧実装なら通っていたはずのケースを列挙し、完全一致化で実際に拒否されることを固定する。将来の実装変更でこの保証が壊れたら即座にテストが落ちる |
| D-104 | `ios/Flutter/{Development,Staging,Production}.xcconfig` に `FLUTTER_TARGET = lib/main_<flavor>.dart` を明示追加（`#include "Generated.xcconfig"` の後に上書き） | Flutter公式ツール（`xcode_backend.dart`）は `environment['FLUTTER_TARGET']` が未設定なら `lib/main.dart` にフォールバックする。`Generated.xcconfig` の `FLUTTER_TARGET` は `flutter build/run -t <file>` を実行するたびに上書きされる一時的な値であり、Xcodeから直接 Run/Archive した場合（flutterツールを経由しない）は古い値または未設定のまま使われてしまう。各flavor xcconfigで明示固定することで、Xcodeから直接操作しても正しいDart entryが使われることを保証する |
| D-105 | `tool/verify_flavor_config.dart` を新設。Android（`build.gradle.kts` のproductFlavors・applicationId）、iOS（3xcconfigのbundle id/APP_DISPLAY_NAME/FLUTTER_TARGET、3xcschemeのconfiguration参照、pbxprojの9configuration存在・baseConfigurationReference・PRODUCT_BUNDLE_IDENTIFIER非ハードコード）、Dart entry（`main_<flavor>.dart`のbootstrap呼び出し、`main.dart`のdevelopment固定）を、`flavor_guard.dart`の`allowedNativeIds`を単一の真実として突き合わせる形で静的検証する。Android SDK/Xcodeのビルドを一切必要としない（ファイル内容の正規表現照合のみ）。CIの`windows`ジョブから`dart run tool/verify_flavor_config.dart`として実行 | 「各schemeのDebug/Profile/Release configuration・bundle ID・APP_DISPLAY_NAME・FLUTTER_TARGETを静的検証する」という要求を、ビルド環境が使えないCI/開発機でも実行できる形で満たす。意図的に3種類の設定破壊（FLUTTER_TARGET不一致・scheme buildConfiguration不一致・pbxprojへのPRODUCT_BUNDLE_IDENTIFIERハードコード混入）を注入し、それぞれ検出→復元→再検証で誤検知なく機能することを確認した |
| D-106 | CIの`windows`ジョブに`dart run tool/verify_flavor_config.dart`ステップを追加（`flutter test`の後、Android buildの前）。staging/productionは実ネイティブビルドをCIで行わない（実鍵が無いため）が、静的検証は3flavor全てを対象にするため、設定欠落やentry取り違えはネイティブビルド無しでCIが失敗する | 「必須ビルドはdevelopmentのみでよいが、staging/productionの設定欠落やentry取り違えをCIで失敗させる」という要求を、実鍵を必要としない静的検証で満たす |
| D-107 | `lib/main.dart` のdocコメントを明確化（development専用の汎用エントリであり`main_development.dart`と同一内容であることを明記）。`env_flavor_test.dart`に、development flavorがAndroid/iOSのproduction・staging双方のnativeIdと組み合わされた場合に必ず拒否されることを確認する回帰テスト群を追加 | 汎用`lib/main.dart`が誤ってproduction/staging名義のビルドに使われないことを、コメントとテストの両方で固定する |
| D-108 | `docs/setup.md`のツール状態表を実態に合わせて更新（Flutter/Dart SDKは`C:\src\flutter`に導入済みで利用可能、Android SDKは`flutter doctor`で`Unable to locate Android SDK`を確認した上で未導入、macOS/iOSビルド環境はWindows機のため未確認、と明記） | 旧記述は「Flutter SDK未導入」のまま何ターン分も更新されておらず、実態（Flutter/Dartは動く、Android SDKだけが無い）と乖離していた。現在の`flutter doctor -v`出力に基づき正確に記録した |

### 検証状況（2026-07-02, Windows host, 再掲更新）
- `dart format` / `dart analyze`（lib, test, integration_test, tool）: issues 無し。
- `flutter test`: **227件 全パス**（env_flavor_test.dartの完全一致回帰テスト追加により+38件）。
- `dart run tool/verify_flavor_config.dart`: **OK**。意図的な3種類の設定破壊注入でいずれも正しく検出・復元後に再度OKとなることを確認済み。
- `git diff --check`: クリーン（exit 0）。
- **未実施（成功と報告しない）**: `flutter build apk`（Android SDK未導入）、`flutter build ios`／Xcodeでの実ビルド・アーカイブ（macOS環境が無い）。`tool/verify_flavor_config.dart`は静的検証であり、実際のGradle/Xcodeビルドが通ることを保証するものではない。

## R5 現場状態・終演操作の是正（H-07, 2026-07-03）

R1〜R4（owner分離・同期・暗号化・flavor構成）は変更せず、中間レビューで残った
H-07（未来の中止現場が現場一覧・思い出のどちらにも表示されない）と、関連する
書込み経路（中止/終演/Todo/交通宿泊要否/子データ削除）の型付きFailure・
二重タップ防止・失敗ロールバックの欠落を修正した。

| # | 判断 | 理由 |
|---|---|---|
| D-109 | `genba_schedule.dart` の `isUpcoming` を `status != memory && status != canceled` という独立判定から `isUpcoming = !isMemory` に変更し、`isMemory` 側で「中止済みは公演日（`memoryStartAt`）を過ぎるまでは思い出に出さない」と明示した | 旧実装は中止現場を無条件に現場一覧から除外していたため、公演日前に中止した現場が現場一覧にも思い出にも一切出ず、確認・編集・日程変更・中止取消・削除がUIから不可能になっていた（H-07の核心）。`isUpcoming`を`isMemory`の否定として定義することで、現場一覧と思い出が構造的に排他的かつ網羅的（どちらにも出ない・両方に出るを型で防ぐ）になる |
| D-110 | `GenbaFormController.submit()` で公演日（`eventDate`）を変更した場合のみ、既存の `manualEndedAt` を解除する（時刻のみの変更では保持） | 手動終演時刻は「変更前の公演日」を前提にした絶対時刻であり、公演日だけ未来へ再スケジュールしてもそのまま持ち越すと新しい公演日でも終演済み・思い出扱いに誤判定される。日程変更時は再導出に委ね、複製せず状態を作り直す（要求3） |
| D-111 | 現場の主要書込み（中止/終演/交通宿泊要否/Todo/子データ削除/画像）を新設の `GenbaActionsController`（`Notifier<Set<String>>`、genbaId family）へ集約。state は「進行中の操作キー集合」とし、`todo:<id>`/`ticket:<id>` のように操作単位でキーを分けて二重タップを防ぐ。当初は `AsyncNotifier<void>` の単一ローディングフラグで実装したが、Todo Aの保存中にTodo Bのタップが無関係な操作として静かに無視される欠陥に気付き、実装前に per-key 方式へ設計変更した | UIから直接Repositoryを呼ぶ既存実装は失敗時に成功表示・状態不整合を招いていた。単一ロックは「同一操作の二重タップ防止」と「無関係操作のブロック」を区別できず、後者は正当な同時操作まで妨げてしまうため、操作キー単位のガードを採用した（要求4・5） |
| D-112 | `core/widgets/async_view.dart` に `confirmAction`（非危険色の確認ダイアログ）を追加。「終演した」操作は確認ダイアログを経てから `markEnded` を呼び、`manualEndedAt != null` の間は導出状態に関わらず「取り消す」「時刻を訂正」ボタンを表示し続ける | 「終演した」は不可逆ではないが誤操作の影響が大きい（余韻中・思い出への案内が始まる）。確認と、誤操作後の取消・訂正手段の両方を用意する（要求2） |
| D-113 | 現場の中止（`cancel`）にも `confirmDangerAction` による確認を追加した（従来は無確認で即座に `isCanceled: true` を書き込んでいた） | 中止は現場一覧の見え方・思い出への遷移タイミングを変える操作であり、誤操作からの回復手段（中止取消）はあるものの、削除に準ずる確認を課すのが妥当と判断した |
| D-114 | `_TodoSection` を `ConsumerStatefulWidget` 化し、`Map<String, bool> _optimistic` でタップ直後に見た目を即時反映する楽観更新を実装。保存の成否に関わらず処理完了後に楽観値を外し、実データ（成功時は新値、失敗時は元の値）に委ねる。ロールバックは「DBを変更していない」という事実そのものに委ね、明示的な巻き戻し処理は書かない | Todoチェックのような高頻度操作は即時フィードバックが無いと体感速度が悪化する。失敗時は実データが変わっていないため、楽観値を外すだけで自然に元へ戻り、`_handleActionResult` でSnackBar表示も行う（要求5・6） |
| D-115 | 子データ編集の共通シェル `_EditorScaffold`（チケット/交通/宿泊/Todo/メモ5種が共有）を `StatefulWidget` 化し、`_saving` フラグで保存中の再タップを無視・ボタンをスピナー表示にする | 5つの編集シートに個別ガードを実装する代わりに共有シェル1箇所を直せば全種で二重タップ防止が効く。個別実装より修正漏れのリスクが低い（要求5） |
| D-116 | `memory_edit_screen.dart` の写真削除・setlist/goods/places の追加削除で、これまで無視 (`unawaited`/戻り値未使用) されていた `Failure?` を `_showFailure` でSnackBar表示するよう修正 | `MemoryEditController` 自体は型付き `Failure?` を返す設計だったが、呼び出し側（画面）がその戻り値を握りつぶしており、失敗しても画面上は成功したように見えていた（要求6） |
| D-117 | `genba_form_screen.dart` の `_OshiGroupSelector` を、推しグループが1件も無い場合に `SizedBox.shrink()` を返す実装から、既存グループのチップ一覧＋「推しを登録」`ActionChip`（名前だけの簡易ダイアログ→`OshiGroup`をその場で作成）を常に表示する実装へ変更 | 旧実装では推しグループを1件も登録していない状態で現場登録フォームを開くと、フォーム内から推しを選ぶ手段が一切なく機能的な行き止まりになっていた。§6〜§8の読解時に発見した実装上の欠落で、現場登録フローの完結に必要な最小修正として合わせて直した |

### 追加テスト（要求7・8）
- `test/domain/genba_schedule_test.dart`: 中止現場が公演日を過ぎるまで現場一覧に残り、過ぎると思い出に移ることの直接検証。現場一覧・思い出が常に排他的であることの網羅的検証（中止/非中止 × 複数時点）。旧実装のバグをそのまま固定していた既存アサーションは修正後の正しい期待値へ書き換えた。
- `test/notifier/genba_form_controller_test.dart`: 公演日変更で `manualEndedAt` が解除されること／日程を変えない編集では保持されることの2件を追加。
- `test/helpers/fake_genba_repository.dart`（新設）: `upsertGenba` の失敗注入・遅延・呼び出し回数計測ができる `GenbaRepository` デコレータ。
- `test/notifier/genba_actions_controller_test.dart`（新設）: 保存失敗時に成功表示せずローカル状態も変わらないこと（cancel/markEnded）、連打しても `upsertGenba` が1回しか呼ばれないこと、操作キーが異なれば（別現場・別操作）同時実行がブロックされないこと、markEnded→undoMarkEndedで復旧できること、correctEndedAtで時刻訂正できること。
- `test/widget/genba_status_actions_test.dart`（新設）: 実際のUI操作（タップ→確認ダイアログ→確定）で、未来の中止現場が一覧から消えず中止取消までできること、「終演した」の確認ダイアログと取消操作がUIレベルで機能することを検証。
- `integration_test/app_flow_test.dart`: 既存の「初回起動→チュートリアル→ログイン→現場登録→ホーム表示」を、準備情報（チケット/交通/宿泊/Todo）→当日→終演（確認ダイアログ経由）→思い出記録→アプリ再起動後のデータ復元まで拡張。

### 検証状況（2026-07-03, Windows host）
- `dart run build_runner build --delete-conflicting-outputs`: 想定外の出力変更なし（freezed/drift モデルは未変更）。
- `dart format lib test integration_test`: 8ファイルを整形。`dart analyze lib test integration_test`: issues 無し。
- `flutter test`: **236件 全パス**（R4末時点227件 + R5追加9件）。
- `git diff --check`（R5で変更・新設したファイルのみ対象）: クリーン（exit 0）。
- **未実施（成功と報告しない）**: `flutter test integration_test`。`flutter devices` では Windows desktop / Chrome / Edge のみ検出され、Android実機・エミュレータは無い。試しに `-d windows` で起動を試みたが、本プロジェクトに `windows/` デスクトッププラットフォームが未構成のため `No Windows desktop project configured` で失敗した（デスクトップ対応の追加はR5のスコープ外のため行っていない）。iOSはmacOS環境が無いため実行不可。よって統合テストの拡張分は静的解析（`dart analyze`）の通過のみ確認済みで、実機/エミュレータでの実行確認はできていない。

## R5 独立レビュー是正（更新競合・手動終演・推しメン選択, 2026-07-03）

R1〜R4 と既存 R5（f5641b6）の挙動は変えず、R5 の独立レビューで見つかった
4点（同一現場の更新競合・手動終演時刻の扱い・現場フォームの推しメン欠落・
統合テスト不足）を是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-118 | 現場フィールドの更新（中止/終演取消/要否/ヒーロー画像）を「画面が保持していた古い [Genba] 全体を `copyWith` して `upsertGenba`」から、新設 `GenbaRepository.mutateGenba(genbaId, update)` による **read-latest-merge** へ変更した。`mutateGenba` は同一 DB transaction 内で最新行を読み直し、`update` で該当フィールドだけを差し替え、merge 後の最終状態から Outbox payload を生成する | 旧実装は操作キーが異なると並行実行できる（`transportRequirement`/`lodgingRequirement`/`cancel`/`ended`/`heroImage`）ため、後から完了した保存が先の変更を古いスナップショット値で巻き戻していた（例: 交通要否→中止 の順で操作すると中止の書込みが交通要否を unknown へ戻す）。Drift は単一コネクション上で transaction を直列化するので、transaction 内で最新値を読み直せば、別現場・独立した子データの操作を止めずに「同一現場の異なるフィールド更新」だけを安全に合流できる。Outbox payload も merge 後の行から作るため最終状態と一致する（H-02 の版CAS適用とも矛盾しない） |
| D-119 | `mutateGenba` は「更新前の [Genba]」を成功値として返す。ヒーロー画像の差替え/削除時の旧ファイル掃除は、画面が持っていた `genba.heroImageLocalPath` ではなくこの返り値（DB内の実際の旧参照）を使う | 画面のスナップショットは他操作で既に差し替わっている可能性があり、それを信じると「実際に置き換えた旧ファイルではない参照」を消す・掃除し損ねる。最新の旧参照を transaction から受け取ることで孤立ファイルの取り残しと誤削除を防ぐ（H-04 と一貫） |
| D-120 | `GenbaSchedule.effectiveEndAt` を「手動終演があれば予定終演との早い方を採用」から「**手動終演があれば無条件にそれを採用**」へ変更した。既存判断 D-11（終演予定なしの保守的見込み）と D-12（余韻中/思い出の区間）は手動終演が無い場合の規則として維持する | 旧実装は `manual.isBefore(scheduled) ? manual : scheduled` としており、予定より遅い終演（押した・アンコールが延びた）へ `correctEndedAt` で訂正しても予定時刻へ丸められ、訂正が反映されなかった。ユーザーが明示した終演時刻は実績値であり、予定より早くても遅くても最優先すべき。要件 §7.1「ユーザーが終了時刻を修正できる」に一致させ、D-11/D-12 と矛盾する旧クランプ挙動をここで解消する。深夜・日跨ぎの手動終演（例: 翌1:30）もそのまま実時刻として扱い、思い出移行はその暦日の翌日 0:00（D-12）で導出される。日程変更時に手動終演を解除する D-110 と併せ、状態は常に最新の入力から再導出され複製されない |
| D-121 | 現場フォームの推しグループ/メンバー選択を、状態操作に副作用を持たせないよう `GenbaFormController.selectOshiGroup(group)` / `toggleOshiMember(id, selected)` の2メソッドへ集約し、UI（`_OshiSection`）はそれを呼ぶだけにした。`selectOshiGroup` はグループ変更（別 id への切替）・解除時に `oshiMemberIds` を必ず空へリセットする | 旧実装はフォームに `oshiMemberIds` フィールドと下書き/保存の配線はあったが、メンバーを選ぶ UI が一切無く、かつグループ切替時に前グループのメンバー ID を掃除する処理も無かった（不正な所属メンバーが残り得た）。クリア規則を controller 側に置くことで「グループを変えたら前グループのメンバーは残さない」を Widget を起動せず単体テストで固定できる。メンバーは特定グループに属するため、別グループへ切替えた時点で以前の選択は必ず無効になる、という不変条件を型ではなくメソッドで強制する |
| D-122 | 推しメンバーの選択 UI（`_OshiSection`）は `oshiGroupsProvider`（`StreamProvider<List<OshiGroupWithMembers>>`）の AsyncValue を loading / error / data で明示的に出し分ける。グループ未登録・選択グループのメンバー未登録は固定ダミーを出さず、その場で登録できる ActionChip（`_quickAddGroup`/`_quickAddMember`、名前のみの簡易ダイアログ）を導線として常に表示する | 要件 §2.5/§9/§19「固定ダミー値を置かない・事前のマイ推し登録を必須にしない」。取得失敗を握りつぶして空表示にすると「本当に0件」と区別できないため error を可視化する。フォームから離れずに推し/メンバーを1往復で作成できるようにし、作成物は自動選択して入力の手戻りを無くす |

### 追加・変更テスト
- `test/domain/genba_schedule_test.dart`: 手動終演が「予定より早い/遅い/深夜(翌日)」で無条件採用されること、取消（null で予定へ復帰）、`correctEndedAt` 相当の訂正で状態が再導出されること、時刻のみ変更した場合の挙動を追加。
- `test/notifier/genba_actions_controller_test.dart`: 同一現場の異なるフィールドを **並行**（`setTransportRequirement`＋`setLodgingRequirement` を同一スナップショットから同時発火）・**連続**で更新しても両方の変更が保持されること（read-latest-merge の回帰）、手動終演後に予定より遅い時刻へ `correctEndedAt` して反映されることを追加。既存の失敗ロールバック・二重タップ・別現場並行のテストは、Fake が `mutateGenba` を同一計器で計測するためそのまま通る。
- `test/notifier/genba_form_controller_test.dart`: 推しグループ＋メンバーを選択して submit すると `Genba.oshiMemberIds` に保存されること、下書き経由で再オープンしても復元されること、グループを別グループへ変更・解除すると前グループのメンバー ID がクリアされることを追加。
- `test/widget/oshi_selection_test.dart`（新設）: 現場フォームで実データのメンバーが FilterChip として出て複数選択でき、グループ未登録・メンバー未登録時に登録導線が出ることを Widget レベルで確認。
- 更新競合（同一スナップショットからの並行更新）は UI 経路では操作間に rebuild が挟まり最新値を拾い直すため再現しにくい。そのため決定的な回帰は `genba_actions_controller_test.dart` の並行/連続 merge テストで固定し、`integration_test/app_flow_test.dart` は既存どおり中心フロー（交通=必要／宿泊=不要が終端まで共存）を検証する役割に留める。手動終演の時刻訂正（予定より遅い時刻）は同 controller テストで検証する。

## R5 再レビュー是正（推し整合性検証・統合テスト補完, 2026-07-03）

R1〜R4・既存 R5（f5641b6, D-109〜D-117）・R5独立レビュー是正（D-118〜D-122）の
挙動は変えず、再レビューで残った2点（推しグループ・推しメンの整合性検証、
R5統合テストの補完）を是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-123 | `GenbaFormController.submit()` に `_validateOshiSelection` を追加し、保存直前に選択中の `oshiGroupId`/`oshiMemberIds` を現在ownerの `OshiRepository.watchAll()`（owner分離済み）と照合する。**方針は「安全に除外して利用者へ知らせる」を採用し、型付きFailureで保存全体をブロックする方針は採らない**。グループが削除済み・別owner（owner分離により watchAll に現れない）なら選択解除、メンバーは「選択中のグループに実在するものだけ」を残す。除外が発生した場合のみ `submit()` の成功値に補正メッセージを載せる | 推しグループ／メンバーは要件§9「事前のマイ推し登録を必須にしない」が示すとおり現場登録にとって**オプショナル**な関連付けである。ticket/transport等の子データが親genbaに必須依存するのとは性質が異なり、他デバイスの同期や別画面でのメンバー削除といった、ユーザー自身の操作ミスではない理由で参照が古くなり得る。この場合に現場登録という主目的の保存自体を失敗させるのは要件の意図に反し、ユーザー体験上も過剰に厳格。一方で「黙って古いIDをそのまま保存する」ことも禁止されているため、実データで検証し除外したうえで、除外が起きたときだけ理由を通知する設計とした。owner不一致は `watchAll()` 自体がowner分離されているため、別ownerのIDは「削除済み」と同じ「見つからない」経路に自然に合流し、追加の分岐コードなしにC-01の境界を保つ |
| D-124 | `submit()` の戻り値を `Future<Result<String>>` から `Future<Result<({String id, String? oshiCorrectionMessage})>>` （Dart 3 レコード）へ変更した。`GenbaFormScreen._submit()` は `oshiCorrectionMessage` が非nullのときそれを優先してSnackBarに表示する（「端末に保存しました（〜）」） | 補正が起きたことを「黙って」処理せず利用者に知らせるには、成功パスに情報を載せる経路が必要。新しいfreezed型を起こすほどの複雑さではなく、呼び出し箇所が `genba_form_screen.dart` の1箇所のみのため、既存コードベースでテストヘルパー等に使われているDart 3レコード型を踏襲した（新規の共有APIサーフェスを増やさない） |
| D-125 | 統合テスト（`integration_test/r5_review_flow_test.dart`, 新設）で「保存失敗時のロールバック」だけは検証しない。代わりに `test/widget/genba_todo_failure_rollback_test.dart`（新設）で、本物の `GenbaDetailScreen`（`OshiExpeditionApp` 経由、presentation層はintegration testと同一実装）に対し `genbaRepositoryProvider` だけを `FakeGenbaRepository` へ差し替えて検証する | integration testは実配線（Drift＋SyncEngine、Supabase無しのデモ同期停止）を使い、実際のSQLite書込みを狙って失敗させる注入点が無い（本物のDBは通常失敗しない）。差し替え可能なのはテスト専用のProvider override機構であり、これは`ProviderScope`/`UncontrolledProviderScope`がテストコードに公開しているテスト境界であって、integration_test実行環境（実機/CI）の中で使える汎用の失敗注入手段ではない。Widget test側は presentation（`GenbaDetailScreen`/`_TodoSectionState`）→application（`GenbaActionsController`）→data（`GenbaRepositoryImpl`経由の実Drift）という**同一の経路**を通り、差し替えたのは経路の末端（実際のディスク書込み1箇所）のみであるため、要件の「同じpresentation経路を通ること」を満たす |
| D-126 | `integration_test/app_flow_test.dart`（既存の中心フロー: 初回起動→チュートリアル→ログイン→現場登録→…→再起動復元）は変更せず、R5再レビュー観点（未来中止取消・終演取消/訂正・二重タップ・推し選択復元・要否並行更新）は新設の `integration_test/r5_review_flow_test.dart` に独立させた | 既存テストは「削除・skip・弱体化しない」という制約があり、複雑な追加操作を同じ巨大なtestWidgets内に継ぎ足すと、途中のナビゲーション状態management（別現場の詳細を開いてから元の現場へ戻る等）が絡み合い、既存の通っているアサーションを壊すリスクが上がる。新しいシナリオは「事前ログイン状態（KV seed）から開始」という軽量なセットアップで足りるため、別ファイルの独立したtestWidgetsとして追加する方が、既存フローへの影響ゼロを保ちながら検証範囲を広げられる |
| D-127 | `r5_review_flow_test.dart` の交通/宿泊要否の並行更新テストは、2つのチップタップの間に `pumpAndSettle()` を挟まず連続して `tester.tap()` する。Todoの二重タップテストも「保存する」ボタンを pump を挟まず2回連続でタップする | Flutterの非同期実行モデル上、`tester.tap()` はジェスチャー認識・`onPressed`/`onChanged` コールバックの同期的な前半部分（ガード判定・`state`/`_saving` の同期的な更新）をそのタップの中で完了させてから制御を返す。次のタップまでに `pump()` を挟まないことで、2回目のコールバックは1回目が設定した「進行中」状態を確実に観測できる（Riverpodの状態変更・setStateいずれも、ウィジェットツリーの再描画を待たずに次の同期チェックへ反映される）。これにより、実際のUI操作としての「連打」「並行操作」を、artificialな遅延無しに決定的に再現できる。この性質は `GenbaActionsController._run`（D-111）と `_EditorScaffoldState._handleSave`（D-115）がいずれも**awaitの前に同期的なガード判定を置いている**ことに依存しており、両実装がこの前提を崩さない限り安定する |
| D-128 | `r5_review_flow_test.dart` の「時刻を訂正」ステップは、DatePicker/TimePickerの既定値をそのまま「OK」で確定するだけに留め、訂正後の具体的な時刻値（予定より早い/遅い等）はアサーションしない。具体的な時刻値の正しさは `test/notifier/genba_actions_controller_test.dart`（「markEnded 後、予定より遅い時刻へ correctEndedAt でき、予定へ丸められない」）で決定的に検証済み | Material TimePicker/DatePickerのダイヤル操作やキーボード入力モードへの切替をWidgetTesterで確実に模すのは、実機無しでは検証できないフォーマット依存の細部（ロケール別ラベル、ダイヤルのヒットテスト座標等）に依存し脆くなりやすい。統合テストの役割は「ボタン→ダイアログ→確定のUI導線が実際に破綻せず`correctEndedAt`まで到達し、失敗表示にならない」ことの確認に絞り、値の正しさはより決定的に検証できる下位レイヤのテストに委ねた |

### 追加・変更テスト（推し整合性検証, R5再レビュー #1）
- `test/notifier/genba_form_controller_test.dart`: 「正常系（実在するグループ・メンバーはそのまま保存）」「削除済み（外部でメンバー削除後は除外して保存）」「別グループ（選択中グループに属さないメンバーIDは除外）」「別owner（他ユーザーのグループIDを直接DB投入しても解除される）」「グループ解除（グループ未選択なのにメンバーIDが残っていても保存前にクリア）」の5件を追加。いずれも補正が起きた場合は `oshiCorrectionMessage` が非nullになることも確認する。既存の「グループとメンバーを選択して submit すると保存される」テストは新しい戻り値形状（レコード）へ追従させた。

### 追加テスト（統合テスト補完, R5再レビュー #2）
- `integration_test/r5_review_flow_test.dart`（新設）: 既ログイン状態から、推しグループ・メンバー選択を含む現場登録 → 未来の中止現場の作成・中止・現場一覧からの非消失・中止取消 → 交通/宿泊要否の並行タップ更新 → Todo保存の連打（1件のみ作成） → 「終演した」→取消→再度終演→時刻訂正のダイアログ導線 → アプリ再起動、まで一連のUI操作として検証し、再起動後に推し選択・要否・手動終演・Todo件数・中止取消状態がすべて復元されることを確認する。
- `test/widget/genba_todo_failure_rollback_test.dart`（新設）: 本物の `GenbaDetailScreen` に対し `genbaRepositoryProvider` のみを失敗注入可能な `FakeGenbaRepository` に差し替え、Todo完了操作が保存失敗時に成功表示されず、楽観的に反映していたチェック状態が実データ（変更されていない）へ戻ることを確認する。
- `test/helpers/fake_genba_repository.dart`: `upsertTodo` にも `failNextUpsertTodo` による一発失敗注入を追加（既存の `upsertGenba`/`mutateGenba` 用フックと同じ形）。

### 検証状況（2026-07-03, Windows host）
- `dart format lib test integration_test`: 変更0件（整形済み）。`dart analyze lib test integration_test`: issues 無し。
- `flutter test`: 本セッションの前半ではSmart App Controlが `flutter_tester.exe` を全ファイルでブロックし実行不可だったが、その後ブロックが解除され実行できた。**252件 通過 / 6件失敗**。失敗6件の原因を切り分けた:
  - 実際に本セッションの変更が原因だった不具合2件は特定し修正済み: (1) `test/notifier/genba_form_controller_test.dart` の「別owner」テストが `artistName` を設定し忘れておりバリデーション失敗で落ちていた（テスト側の不備、修正済み）。(2) `test/widget/main_flow_test.dart` の現場登録テストが、`_OshiSection`（R5独立レビューで追加）により縦に伸びたフォームで「登録する」ボタンが既定の小さいテストビューポート外(offstage)になりヒットテスト失敗していた。`genba_status_actions_test.dart`等と同じ縦長ビューポート指定を追加して解消（修正済み、再実行で確認）。
  - 残り6件はすべて同一原因: `Exception: Asset 'shaders/ink_sparkle.frag' does not contain appropriate runtime stage data for current backend (SkSL). Found stages: Vulkan`。`app_theme.dart` は `useMaterial3: true` で `splashFactory` を明示していないため、`FilledButton`/`Checkbox`/`Chip` 等のMaterial3既定リップル（ink sparkle）を伴うウィジェットをタップし `pump`/`pumpAndSettle` で描画が進むと、このホストの `flutter_tester.exe` のレンダリングバックエンドでシェーダーがロードできず例外が飛ぶ。各失敗テストを単独再実行し**決定的に**（毎回同じ形で）再現することを確認した。影響範囲は本セッションで変更していない既存テスト（`genba_status_actions_test.dart`、`routing_test.dart`、`user_switch_visibility_test.dart`）にも及ぶため、**本セッションのR5再レビュー対応が原因ではなく、このホスト環境に元から存在した制約**と判断する（`docs/decisions.md` の旧記載「flutter test: 236件 全パス」はこの制約が顕在化する前の別状態での記録であり、本セッションで再現できない）。アプリのテーマ（`splashFactory`）を変更する対応は無関係なUI変更にあたるため行っていない。実機/エミュレータまたはVulkan以外の描画バックエンドを使える環境での再検証が必要。
    - `test/widget/genba_status_actions_test.dart`（既存、未変更）
    - `test/widget/routing_test.dart`（既存、未変更）
    - `test/widget/user_switch_visibility_test.dart`（既存、未変更）
    - `test/widget/main_flow_test.dart`（本セッションでビューポート修正後も、上記シェーダー制約自体は残る）
    - `test/widget/oshi_selection_test.dart`（新設。ChoiceChip/FilterChipタップが同じ制約に該当）
    - `test/widget/genba_todo_failure_rollback_test.dart`（新設。CheckboxListTileタップが同じ制約に該当。中間の楽観値アサーション自体は単独再実行でも例外と共に失敗するため、ロジックの誤りではなく同一環境要因によるものと判定した）
- `flutter test integration_test -d windows`: 実行不可。本プロジェクトに `windows/` デスクトッププラットフォームが未構成のため `flutter build windows` の段階で失敗する（既存 `app_flow_test.dart`・`encryption_sqlcipher_test.dart` と同一の失敗理由。新設 `r5_review_flow_test.dart` はロードまで到達しており、ファイル自体の構成に問題は無い）。`flutter devices` ではWindows desktop/Chrome/Edgeのみ検出され、Android実機・エミュレータは無い。
- `git diff --check`: クリーン（exit 0）。

## R5 再々レビュー是正（推し選択検証の未処理エラー, 2026-07-03）

R1〜R4・既存R5（f5641b6, D-109〜D-117）・R5独立レビュー是正（D-118〜D-122）・
R5再レビュー是正（D-123〜D-128）の挙動は変えず、再々レビューで見つかった
`_validateOshiSelection()` の未処理エラーを是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-129 | `_validateOshiSelection()` 内の `await ref.read(oshiRepositoryProvider).watchAll().first` を `try/catch` で包み、例外を `Err(StorageFailure(message: '推しデータの読み込みに失敗しました', cause: e))` へ変換する。戻り値を素の record から `Result<({...})>` へ変更した | 修正前は `watchAll()` のStreamがエラーを発すると `.first` がそのまま例外を投げ、呼び出し元の `submit()` を経由して例外が外へ漏れていた。`submit()` は `Future<Result<...>>` を返す契約のメソッドであり、例外で終了することはその契約に反する（呼び出し側 `GenbaFormScreen._submit()` は `await` の失敗を想定しておらず、`result.when(...)` に一切到達しないまま保存中フラグ `_submitting` がtrueのまま固まる）。新しいFailureサブタイプは起こさず、既存の `StorageFailure`（端末データの読み書き失敗を表す既存の語彙）にメッセージを変えて流用した — 「推しデータの読み込み」は「端末（ローカルDB）からの読み取り」であり、既存のカテゴリで十分表現できるため |
| D-130 | `submit()` は `_validateOshiSelection()` の結果を「`Genba` を構築・`upsertGenba` する前」に確認し、`Err` であれば即座に `Err` を返して中断する。推し選択の安全な除外（D-123）ができない以上、`Genba` の他フィールドだけで保存を進めることは「除外すべきだったが確認できなかった参照を残したまま保存する」リスクを伴うため | 要件「読み込み失敗時に現場を不完全な状態で保存しない」を満たす。`_validateOshiSelection` が失敗する経路は「実在確認そのものができない」状態であり、D-123の安全な除外ロジックが機能する前提（実データと照合できること）が崩れている。中断が最も安全な選択で、ユーザーは再試行できる（`GenbaFormState` は破棄されずフォームに留まるため入力内容は失われない） |
| D-131 | `GenbaFormScreen._submit()` の `await ...submit()` 呼び出しと `result.when(...)` 処理全体を `try { ... } finally { if (mounted) setState(() => _submitting = false); }` で包んだ | `submit()` 自体は本修正で例外を投げない契約に揃えたが、UI側にも多層防御として「保存中表示は成功・失敗どちらの経路でも必ず解除する」を明示的に保証させる。将来 `submit()` の実装が変わっても、`GenbaFormScreen` 側の保存中フラグが固まる事故を局所的に防げる |
| D-132 | 推しデータ取得失敗のテストには、新設 `test/helpers/fake_oshi_repository.dart`（`OshiRepository` をラップし `watchAll()` のみエラー注入できるデコレータ）を用いる。オーバーライドしたプロバイダの構築は「ログイン（`localDataScopeProvider` の確定）を待ってから読む」順序を徹底する | `oshiRepositoryProvider` は `localDataScopeProvider` を watch しており、ログイン前に読むと未認証scope向けの別インスタンスが作られ、ログイン後に`submit()`が実際に使うインスタンス（scope確定後に再構築された別オブジェクト）と食い違う。先に `signInDemo`→`currentUserProvider.future` を待ってから `oshiRepositoryProvider` を読むことで、テストが捕まえた `fakeOshi` と `submit()` が使うインスタンスを一致させる（実装中に一度この順序を誤り、注入したエラーが反映されない誤テストを書いてしまったため、正しい順序をここに明記する） |

### 追加テスト
- `test/helpers/fake_oshi_repository.dart`（新設）: `OshiRepository` のデコレータ。`watchAllError` を設定すると `watchAll()` がそのエラーで即座に終了するStreamを返す。
- `test/notifier/genba_form_controller_test.dart`: 「推しグループ選択時に`watchAll()`が失敗しても`submit()`はthrowせず`Err`を返す」「取得失敗時は現場が保存されない」「推しグループ未選択の場合は`OshiRepository`を呼ばないため取得失敗の影響を受けない」の3件を追加。既存の正常系・削除済み・別グループ・別owner・グループ解除の5テストは無変更で全通過を確認した。
- `test/widget/oshi_selection_test.dart`: 本物の`GenbaFormScreen`に対し`oshiRepositoryProvider`のみ`FakeOshiRepository`へ差し替え、推しグループ選択・必須項目入力後、保存直前に読み込み失敗を注入するテストを追加。失敗理由のSnackBar表示、保存ボタン（`FilledButton.onPressed`）が再操作可能であること、画面がフォームに留まること、現場が保存されていないことを検証する。

### 検証状況（2026-07-03, Windows host）
- `dart format lib test integration_test`: 変更0件。`dart analyze lib test integration_test`: issues無し。
- `flutter test test/notifier/genba_form_controller_test.dart`: **20件 全パス**（新規3件を含む。既存の推し整合性検証5件・R5独立レビュー分・基本機能テストすべて回帰なし）。
- `flutter test test/widget/oshi_selection_test.dart`: 4件中3件パス。新設の推しデータ取得失敗テストはパス。既存の「選択グループのメンバーが FilterChip として出て複数選択できる」は、本セッションのR5再レビューで確認済みの `ink_sparkle.frag`/Vulkanシェーダー起因の既存環境制約により失敗（本修正・本テストとは無関係。詳細は直前の「R5 再レビュー是正」節を参照）。この制約解消のためのテーマ変更は行っていない。
- `flutter test integration_test`: 未実施。Android/iOS実機・エミュレータが利用できず、本プロジェクトに `windows/` デスクトッププラットフォームも未構成のため実行不可（前回セッションから状況変化なし）。成功として報告しない。
- `git diff --check`: クリーン（exit 0）。

## R6 画像基調UIのデータ契約（H-05 / design-spec §12.1, 2026-07-03）

R1〜R5系の挙動は変えず、design-spec.md の画像基調UIを固定ダミーなしで成立
させるためのデータ契約（ドメイン・Drift/Supabase migration・Repository・
導出クエリ）を実装した。UIの全面再構成は R7 の範囲であり、本パッケージは
データ契約に限定する。

| # | 判断 | 理由 |
|---|---|---|
| D-133 | 現場ヒーロー画像をチケット画像と完全に別型・別列で表現する。`Genba` に `heroImageLocalPath`（既存・端末専用/同期対象外）に加え `heroImageStoragePath`／`heroImageUploadStatus`（`core/images/ImageUploadStatus`）／`heroImageAltText` を追加し、`Genba.heroImage` getter で「明確な型」`GenbaHeroImage`（freezed値オブジェクト）へまとめる。参照が一切無ければ getter は null を返し、画像なしで縮退する | design-spec §12.1「現場ヒーロー画像はチケット画像とは別フィールド・別用途」。既存の `heroImageLocalPath` 参照コード（詳細画面/actions controller）を壊さないよう、フラット列を追加しつつ getter で型を提供する非破壊アプローチにした。チケット画像（`Ticket.imagePath`/`imageLocalPath`）とはモデル上も列上も交差しないため、ヒーロー・cover候補にチケット画像が混入する経路が構造的に存在しない（要求8） |
| D-134 | 明示参加状態 `AttendanceStatus{planned, attended, notAttended, canceled}` を `Genba.attendanceStatus`（既定 planned）として追加し、既存 `isCanceled` は残す。整合規則は **一方向不変条件「中止 ⟹ 参加状態 canceled」** を `normalizeAttendance()` で強制し、Repository の `upsertGenba`/`mutateGenba` が書き込み前に適用する。cancel/uncancel/setAttendanceStatus の各操作は isCanceled と attendanceStatus を同時に設定する | `isCanceled` は既存の状態導出（`deriveGenbaStatus`/`isMemory`/`isUpcoming`）すべてが依存する中止フラグであり、置き換えは影響範囲が大きすぎる。両立させ「canceled は必ず一致」だけを一方向で保証することで、`attended` を勝手に消さず、かつ矛盾状態（中止なのに attended 等）を作らない。日時から自動的に attended へはしない（要求2・7、統計の「参戦数」は attended のみを数える, 要求5） |
| D-135 | 思い出単位の `MemoryEntry.isFavorite`（同期対象）を追加し、`MemoryRepository.setEntryFavorite(genbaId, isFavorite)` で一覧・詳細どちらからでも切替可能にする。entry が無ければ作成する | design-spec §8/§12.1。favorite は「思い出（entry）」に属する属性であり、`memory_entries` は genba_id 単位で1件のため自然に一意。孤立レコードを作らず、既存 entry があれば copyWith で保持する（要求3） |
| D-136 | 表紙は既存 `MemoryPhoto.isCover` を用い、**同一現場の cover は最大1件**を (1) SQLite/Supabase の部分ユニークインデックス `unique (genba_id) where is_cover` と (2) `MemoryRepository.setCoverPhoto()` が「旧 cover を先に外してから新 cover を設定する」順序、の二重で担保する | 部分ユニーク索引だけだと「別写真を cover にする」際に旧 cover を外す前に新規設定すると索引違反で失敗する。順序制御（clear→set）で正常な切替を成立させつつ、索引で不変条件をDBレベルでも保証する。v5 まで `is_cover` を true にする経路が無かったため既存データに cover は存在せず、索引作成は安全（要求3） |
| D-137 | 推しグループ画像 `OshiGroup.imageLocalPath`（端末専用/同期除外）・`imageAltText`（同期）・`isFavorite`（同期）、推しメン `OshiMember.imageAltText`（同期）を追加。ユーザー定義記念日は正規化テーブル `oshi_anniversaries`（`OshiAnniversary`: group_id 必須・member_id 任意・label・date）として追加し、親グループの owner 整合を Repository transaction（ローカル）＋ trigger（サーバー）で強制する | design-spec §10/§12.1。画像の端末内参照は他の画像用途（hero/oshiメン, D-93/H-04）と同じく同期除外。記念日はメンバーの誕生日・推し始めた日と重複させず「ユーザー定義」を独立テーブルへ正規化し、子データとして親owner整合（C-01）を適用する（要求4） |
| D-138 | 活動統計（現場数・思い出数・参戦数・次の現場）と記念日一覧を、保存固定値ではなく **owner 限定の純関数** `deriveOshiStats()` / `deriveUpcomingAnniversaries()`（`oshi_stats.dart`）で導出する。入力は owner 限定リポジトリ（`genbaAggregatesProvider` / `oshiGroupsProvider` / `oshiAnniversariesProvider`）の結果であり、owner 分離は入力側で保証される。Provider `oshiStatsProvider`/`oshiUpcomingAnniversariesProvider` で公開する | design-spec §10/§12.1「統計は保存済みデータから導出し固定値として保持しない」「参戦数は attended のみ」。純関数にすることで owner 分離を入力に委ね、決定的に単体テストできる。「次の現場」は中止を除いた最も近い未来1件、記念日は毎年の月日で次回発生を導出して近い順に並べる。データ無しでも 0 件/空リストへ縮退する（要求5・受入「画像なしでも各Queryが正常に縮退」） |
| D-139 | 端末内画像参照（hero/グループ/メンバーの `*_local_path`）は Outbox payload から除去し（サーバー列も持たせない）、pull は `preserveLocalImage: true` でローカル参照を null 上書きしない。storage_path・upload_status・alt_text・attendance・is_favorite・記念日は通常同期する。`apply_mutation` RPC は `information_schema` 参照で列を動的解決するため既存テーブルの新列は自動対応し、新テーブル `oshi_anniversaries` のみ許可リストへ追加した | H-04（端末専用参照は同期しない）と D-93 の方針を新規画像用途へ一貫適用。RPCの列動的解決により、列追加のためのRPC改修は不要で、新テーブルの許可追加のみで版CAS・冪等ledgerがそのまま効く |
| D-140 | 既存データ移行: Drift v4→v5 と Supabase 0007 のどちらも「既存行は nullable 列を null／enum 列は既定値で追加」し、`is_canceled = true` の現場のみ `attendance_status = 'canceled'` へ明示 UPDATE する。過去公演を勝手に attended へ推測しない | 要求7「既存データは安全な既定値へ移行。過去公演を勝手に attended と推測しない。既存 is_canceled=true は canceled へ明示移行」。ローカル・サーバーの両 migration で同一規則を適用し、再起動・同期後も一貫させる |

### 変更ファイル
- ドメイン: `core/images/image_upload_status.dart`（新設）、`features/genba/domain/genba.dart`（AttendanceStatus/GenbaHeroImage/hero列/normalizeAttendance）、`features/memory/domain/memory.dart`（isFavorite）、`features/oshi/domain/oshi.dart`（group画像/alt/favorite・member alt・OshiAnniversary）、`features/oshi/domain/oshi_stats.dart`（新設・導出純関数）、`features/oshi/domain/oshi_repository.dart`（記念日/画像メソッド）、`features/memory/domain/memory_repository.dart`（favorite/cover）
- 永続化: `core/db/app_database.dart`（schema v5 列/テーブル/migration/cover索引/index）、`core/db/local_data_purge.dart`（記念日テーブル追加）
- data: `features/genba/data/genba_mappers.dart`、`features/memory/data/memory_mappers.dart`、`features/genba/data/genba_repository_impl.dart`（normalize）、`features/memory/data/memory_repository_impl.dart`（favorite/cover）、`features/oshi/data/oshi_repository_impl.dart`（画像/alt/favorite/記念日CRUD・pull）、`core/sync/outbox_operation.dart`（SyncEntity.oshiAnniversaries）
- application: `features/genba/application/genba_actions_controller.dart`（setAttendanceStatus・cancel/uncancel整合）、`features/oshi/application/oshi_providers.dart`（stats/記念日provider）
- migration: `supabase/migrations/0007_image_design_fields.sql`（新設）、`supabase/tests/0004_image_design_fields.sql`（新設・pgTAP）
- 生成物: `*.freezed.dart` / `*.g.dart`（`app_database.g.dart` 等、build_runner再生成）

### 追加テスト
- `test/domain/genba_attendance_test.dart`（新設）: normalizeAttendance の一方向整合、heroImage getter（縮退/型/チケット画像非依存）。
- `test/domain/oshi_stats_test.dart`（新設）: 現場数/思い出数/参戦数の導出、参戦数は attended のみ、次の現場は中止除外の最近1件、記念日の次回発生順、データ無しの縮退。
- `test/data/image_design_repositories_test.dart`（新設）: attendance の保存/同期、hero storage/alt 同期・local参照の同期除外、favorite の作成/同期、cover 一意性（切替で旧を外す）と NotFound、グループ画像同期除外・alt/favorite 同期、記念日の親owner整合（存在しない/別owner拒否）・owner分離。
- `supabase/tests/0004_image_design_fields.sql`（新設・pgTAP）: attendance 既定/check、is_favorite 既定、cover 部分ユニーク、記念日の owner 迂回防止・RLS 正負・cover 一意はper-genba。

### 検証状況（2026-07-03, Windows host）
- `dart run build_runner build --delete-conflicting-outputs`: 成功（freezed/drift/json 再生成）。
- `dart format lib test integration_test`: 整形済み（再実行で変更0件）。`dart analyze lib test integration_test`: **issues 無し**。
- `flutter test`: **279件パス / 6件失敗**。失敗6件はすべて前セッションで特定済みの `ink_sparkle.frag`/Vulkan シェーダー起因の既存環境制約（widget テスト。本R6の変更とは無関係で、同一の6ファイルが該当）。R6で追加した domain/data テスト（`oshi_stats_test`・`genba_attendance_test`・`image_design_repositories_test` 計22件）と既存 `repositories_test`（19件）は全パスし、スキーマ/ドメイン変更による回帰は無い。
- **未実施（成功と報告しない）**: `supabase test db`（Supabase CLI / Docker 未導入のため 0007 migration と 0004 pgTAP はローカル未適用・未検証。既存の 0001〜0006/0001〜0003 と同一の記法・パターンに従って記述）。`flutter test integration_test`（実機/エミュレータ・windows未構成のため実行不可）。
- `git diff --check`: クリーン（exit 0）。

## R6 独立レビュー是正（表紙原子性・記念日整合・pull保持・Provider伝播・cover移行, 2026-07-03）

R6（D-133〜D-140）の挙動を変えず、独立レビューで見つかった6点を是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-141 | cover 一意インデックス作成前に、同一 genba の重複 cover を決定的に1件へ整理する dedup を Drift（`dedupeMemoryCoversSql`）・Supabase 0007 の両方に追加する。**保持する1件の選択規則: `sort_order` 昇順 → `created_at` 昇順 → `id` 昇順で最小のもの**。他の cover は `is_cover=false` にするだけで写真レコード自体は削除しない | 一意インデックス作成時に既存データへ複数 cover があると `CREATE UNIQUE INDEX` が失敗し migration 全体が止まる（R6独立レビュー#5）。決定的な規則で1件に収束させれば、どの端末・サーバーでも同じ結果になり冪等。sort_order は「並び順の先頭に近い＝表紙にふさわしい」直感に沿い、同値時は作成が古い→id の順で一意に定まる。ウィンドウ関数非依存の相関サブクエリ（ローカル）／行値比較（サーバー）で表現し、既存写真を削除せず is_cover のみ修正して情報を失わない |
| D-142 | `MemoryRepository.setCoverPhoto()` の旧表紙解除・新表紙設定・両写真の Outbox 登録を単一 `_db.transaction` 内で行う。対象は現在owner・同一 genba の写真のみを DB から直接取得して検証し、対象なしは番兵例外 `_CoverNotFound`→`NotFoundFailure` にする。途中失敗（例: enqueue 失敗）は transaction ごとロールバックし、poke は変更成功時のみ | 旧実装は `updatePhoto` を複数回逐次呼び出しており、旧表紙解除は成功したが新表紙設定が失敗する中間状態（表紙0件）が起こり得た（R6独立レビュー#1）。単一 transaction で「全成功 or 全ロールバック」にすることで、失敗時に古い表紙が維持され、部分ユニーク索引と合わせて「同期後も最大1件」を保証する。Outbox も同一 transaction に含めるためローカル変更とサーバー送信予約が原子的に一致する |
| D-143 | `OshiRepository.upsertAnniversary()` で、`groupId` の owner 整合（既存の `parentBelongsToOwner`）に加え、`memberId` 指定時は同一 transaction 内で「そのメンバーが現在owner・かつ groupId のグループに所属する」ことを新設 `memberInGroupOfOwner` で検証し、満たさなければ `ParentOwnershipException`→`ValidationFailure` で拒否する。`deleteGroup` はそのグループの記念日も端末から削除（Supabase の ON DELETE CASCADE 相当）、`deleteMember` は記念日の `member_id` を null 更新（ON DELETE SET NULL 相当・記念日レコードは残す）する | 旧実装は group の owner しか検証せず、削除済み・別グループ・別owner のメンバー id を記念日に付けて保存できてしまった（R6独立レビュー#2）。サーバー側 trigger（`enforce_oshi_anniversary_owner`）と同じ整合を端末側でも同一 transaction 内で強制し、ローカルとサーバーで同じ結果にする。カスケード/SET NULL も端末で先取りしておくことで、member/group 削除操作の同期前でもローカル表示が破綻せず、サーバー FK と収束する（記念日の member_id 変更に別 Outbox op は積まず、サーバー FK と版キャッシュの pull 収束に委ねる） |
| D-144 | 思い出写真のリモート pull で `photoToCompanion(..., preserveLocalImage: true)` を使い、サーバーに無い `local_path` を `Value.absent()` で温存する（storage_path/upload_status/caption/is_cover 等の同期項目は更新）。新規リモート写真は `local_path` 列 default（null）で作成される | 旧実装は pull で `local_path` を null 上書きし、端末内に取り込んだ写真参照が同期のたびに消えていた（R6独立レビュー#3）。hero 画像（`genbaToCompanion`）・推し画像（`_memberToCompanion`/`_groupToCompanion`）と同じ `preserveLocalImage` 方針へ揃える（H-04） |
| D-145 | `oshiUpcomingAnniversariesProvider` は `oshiGroupsProvider`/`oshiAnniversariesProvider` の loading/error を `when(loading:.., error:.., data:..)` で伝播する。`valueOrNull ?? []` でエラーや読み込み中を空一覧へ握りつぶさない | 旧実装は記念日ストリームのエラー・loading を空一覧に変換しており、読み込み失敗が「記念日0件」と区別できずユーザーへ誤情報を出す（R6独立レビュー#4）。どちらかが loading なら loading、error なら error を返し、両方 data のときだけ導出する |
| D-146 | `supabase test db` は実行環境が整った場合のみ成功として扱い、Docker 等が無く未実行の場合は成功と報告しない | 本ホストは Supabase CLI 2.108.0 はあるが Docker 未導入のためローカル Postgres を起動できず、`supabase test db` は `PgClient: Failed to connect` で実行不可。SQL 未適用の状態を「R6完全完了」と報告しない（R6独立レビュー#6） |

### 追加・変更テスト
- `test/data/image_design_repositories_test.dart`: 表紙切替の原子性（enqueue 途中失敗で古い表紙維持／切替成功で新旧 upsert が Outbox に載り常に1件／別owner・別genbaは対象外）、記念日 member_id 整合（正常・存在しない・別グループ・別owner の3負例）とカスケード（group削除で記念日削除・member削除で member_id=null）、写真 pull の localPath 保持・同期項目更新・新規null・別owner不干渉を追加。
- `test/data/cover_dedupe_migration_test.dart`（新設）: 一意インデックスを外して同一 genba に複数 cover を投入 →`dedupeMemoryCoversSql`→ 索引再作成、で決定的に1件（sort_order 最小）へ収束し索引が有効化されることを検証（複数 cover を含む旧状態からの migration 相当）。
- `test/notifier/oshi_anniversaries_provider_test.dart`（新設）: `oshiUpcomingAnniversariesProvider` の 正常/空/読み込み中/失敗 の4状態を検証（error・loading を空へ変換しないこと）。
- `test/helpers/fake_oshi_repository.dart`: `watchAnniversaries` のエラー注入・ストリーム差替えを追加。

### 検証状況（2026-07-03, Windows host）
- `dart run build_runner build --delete-conflicting-outputs`: 成功。`dart format lib test integration_test`: 変更0件。`dart analyze lib test integration_test`: **issues 無し**。
- `flutter test`: **294件パス / 6件失敗**。失敗6件は前セッションから継続の `ink_sparkle.frag`/Vulkan シェーダー起因の既存環境制約（同一6 widget ファイル。本修正と無関係）。R6独立レビューで追加した data/provider テスト（cover原子性・記念日整合/カスケード・pull保持・provider4状態・cover dedup）はすべてパス。
- **未実施（成功と報告しない）**: `supabase test db` は Docker 未導入でローカル Postgres へ接続できず実行不可（`supabase test db` → `PgClient: Failed to connect` を確認）。よって 0007 migration と 0004 pgTAP は**ローカル未適用・未検証**であり、R6 は SQL 実行の観点では完全完了ではない。Docker + `supabase start` が使える環境での `supabase test db` 実行が必要。`flutter test integration_test` も実機/エミュレータ・`windows/` 未構成のため未実行。
- `git diff --check`: クリーン（exit 0）。

## R6 再レビュー是正（pgTAPアサーション不足, 2026-07-03）

`supabase/tests/0004_image_design_fields.sql` は `select plan(12)` と宣言していたが、
実際のpgTAPアサーション（`results_eq`/`throws_ok`/`lives_ok`）は11件で、plan数と
実アサーション数が一致していなかった（このまま実行するとplan不一致で失敗する）。
単純に `plan(11)` へ減らすのではなく、記念日 `member_id` の親子整合とグループ/
メンバー削除時の挙動について、サーバー側で不足していたテストを追加した。

| # | 判断 | 理由 |
|---|---|---|
| D-147 | `enforce_oshi_anniversary_owner()` のメンバー整合チェックに対し、**同一owner・別グループのmember_id**（ケース1）と**別ownerのmember_id**（ケース2）を、それぞれ独立したfixture（別々のgroup_id/member_idの組）で検証する2件の`throws_ok`を追加した。両ケースとも実装上は同じ分岐（`where id=member_id and group_id=new.group_id`が0件になる）で拒否されるが、要求された2つの脅威シナリオ（同一ユーザーの誤ったグループ参照／他ユーザーのデータの参照）を別個のテストとして固定した | トリガーの`select owner_id into member_owner from oshi_members where id=new.member_id and group_id=new.group_id`は、group_idの一致だけを見ており、member_ownerを取得しても`new.owner_id`との比較には使っていない（変数として宣言されているが未使用に見える）。これが安全なのは、`oshi_members`自体に「メンバーのowner_idは親グループのownerと一致する」という不変条件（migration 0002の`enforce_oshi_member_owner`）が既に成立しているため、group_idが一致すればownerも自動的に一致するからである。この前提が今後の変更で崩れた場合に検知できるよう、「別グループ」と「別owner」を意図的に別々のfixtureとして固定し、それぞれが独立して失敗することを保証した |
| D-148 | ケース1・ケース2のthrows_okには、SQLSTATE `'P0001'`（`RAISE EXCEPTION`にSQLSTATEを明示指定しない場合のPostgreSQLの既定値）とエラーメッセージ本文`'member does not belong to the group'`の両方を4引数形式`throws_ok(sql, errcode, errmsg, description)`で検証する。既存の制約違反系（`23514`/`23505`、message=null）と同じ4引数の形を踏襲しつつ、カスタム例外はメッセージも厳密一致で確認する | 既存の`23514`/`23505`はPostgreSQL組込み制約の自動生成メッセージのため厳密一致を求めずnullにしていたが、`enforce_oshi_anniversary_owner`の例外メッセージは自前で完全に制御しているため、SQLSTATEだけでなく文言まで固定することで「別の理由でたまたま同じSQLSTATEの例外が飛んだ」ケースとの誤検出を防げる |
| D-149 | `oshi_member`削除→記念日の`member_id`がnullになる（`on delete set null`）、`oshi_group`削除→そのグループの記念日も削除される（`on delete cascade`）を、それぞれ専用のfixture（グループ/メンバーを新規作成し、既存の`dddddddd-...-0001`等の既存テスト対象行には触れない）で検証する`results_eq`を1件ずつ追加した | 既存の「他ユーザーは記念日を更新できない」テストは`dddddddd-...-0001`をIDで指定してRLSブロックを検証しており、この行を本修正の削除系テストで消費すると「本当にRLSでブロックされたのか、単に行が存在しないだけなのか」を区別できなくなり既存テストの意味が弱まる。専用のfixtureを使うことで、既存アサーションの検証対象・意味を変えずに新規テストを追加した |
| D-150 | `plan(12)` → `plan(15)` へ修正（既存11件 + 新規4件 = 15件）。新規に追加したのは「別グループのmember_id拒否」「別ownerのmember_id拒否」「member削除でmember_id null化」「group削除で記念日カスケード削除」の4アサーションのみで、fixture用の素のINSERT/DELETE文はpgTAPアサーションとしてカウントしない（既存ファイルの流儀と一致） | plan数と実アサーション数の不一致はpgTAPの実行自体を失敗させるため、テスト内容を追加・変更するたびに正確な数へ更新する必要がある |

### 追加テスト
- `supabase/tests/0004_image_design_fields.sql`:
  1. 同一owner・別グループの`member_id`を記念日に指定 → 拒否（`throws_ok`, SQLSTATE `P0001` + メッセージ一致）
  2. 別ownerの`member_id`を記念日に指定 → 拒否（`throws_ok`, SQLSTATE `P0001` + メッセージ一致。検証のため一時的にuser2としてグループ・メンバーを作成し、user1へ戻ってから参照を試みる）
  3. `oshi_member`削除後も記念日レコードは残り`member_id`が`null`になる（`results_eq`）
  4. `oshi_group`削除でそのグループの記念日も削除される（`results_eq`, 件数0を確認）
  - 既存の「他ユーザーは記念日を読めない／更新できない」（RLS, 項目5相当）は既に実装済みのため変更せず維持。

### 検証状況（2026-07-03, Windows host, 静的確認のみ）
- **pgTAPアサーション数とplan数の一致確認**: `grep`で`results_eq`/`throws_ok`/`lives_ok`の呼び出し数を数え、**15件**であることを確認。`select plan(15)`と一致。
- **begin/rollback対応確認**: ファイル内に`begin;`が1箇所（2行目）、`rollback;`が1箇所（末尾）で対応していることを確認。
- **UUID/owner/group/memberの参照関係確認**: 新規追加した`oshi_groups`（`ffffffff-...-0002/0003/0004`）・`oshi_members`（`88888888-...-0002/0003/0004`）・`oshi_anniversaries`（`dddddddd-...-0002/0003/0004/0005`）のIDが既存フィクスチャと衝突しないこと、各`group_id`/`member_id`参照が意図した所有者・グループに正しく属することを手動でトレースして確認（ケース1はuser1の別グループのメンバー、ケース2はuser2所有のグループ・メンバー、ケース3/4は専用の使い捨てメンバー・グループを使用し既存の`dddddddd-...-0001`には触れない）。
- **`supabase test db`**: 未実施。Docker未導入のためローカルPostgresへ接続できず（`PgClient: Failed to connect`を再確認）、実行不可。**成功として報告しない**。したがって0007 migrationと0004 pgTAP（新規4件を含む）は実際のPostgres上では未検証であり、静的なSQL構文・参照関係のレビューのみ完了した状態である。
- `git diff --check`: クリーン（exit 0）。
- Dart側（lib/test）は変更していないため、`dart format`/`dart analyze`/`flutter test`は前回セッションの結果（294件パス/6件失敗、失敗はink_sparkle環境制約のみ）から変化なし。再実行は本修正の対象外。

### 残課題
- Docker（またはPostgres 15+ + pgTAP拡張）が使える環境で `supabase start` → `supabase db reset` → `supabase test db` を実行し、0007 migrationの適用成否と0004 pgTAP（15件）の実行結果を確認する。
- 特に「別グループ」「別owner」の2ケースが期待通り`P0001`＋期待メッセージで失敗すること、削除カスケード2ケースが期待通りの最終状態になることを実行結果で確認する。

## R7 「夜明け前の遠征ノート」Design Systemと主要6領域（H-06, 2026-07-03）

R1〜R6の認証・owner分離・同期・暗号化・Result処理・画像区分は変更せず、
design-spec.md の共通Design System（`lib/app/design_system/`・`app_tokens.dart`）
と主要6領域（ホーム/現場詳細/思い出一覧/思い出詳細/マイ推し/設定）のUIを
再構成した。本節は前セッションの中断分を引き継いで完成させた際の判断を含む。

| # | 判断 | 理由 |
|---|---|---|
| D-151 | 思い出のお気に入り・表紙設定は新設 `MemoryActionsController`、推しグループ／メンバー／記念日のCRUDとグループお気に入りは新設 `OshiActionsController` へ集約し、presentation からの Repository 直接呼び出しを排除した。いずれも R5 の `GenbaActionsController`（D-111）と同じ per-key 方式（操作キー単位の二重タップ防止・型付き `Failure` を返し呼び出し側が必ず表示） | R7中間版は一覧/詳細/ダイアログが `ref.read(xxxRepositoryProvider)` を直接呼んでおり、二重タップ防止・失敗表示・busy 表示が画面ごとにばらついていた。既存の実証済みパターン（D-111）へ揃えることで、挙動と実装の一貫性・テスト容易性を確保する。画像の取り込み（ImagePicker→ImageStore.import）はUI都合の前処理として presentation に残し、「削除成功後の owner スコープ画像掃除」は controller へ移した（H-04 と同じ順序保証） |
| D-152 | グループお気に入り切替は、画面が保持していたスナップショットの `OshiGroup` を丸ごと upsert せず、保存直前に owner 限定ストリームから最新行を読み直して `isFavorite` だけ差し替える（`OshiActionsController.setGroupFavorite`）。読み直し失敗は `StorageFailure`、対象消失は `NotFoundFailure` | D-118（現場の read-latest-merge）と同じ問題クラス: 並行する編集（名前・カラー等）を古いスナップショット値で巻き戻さないため。`OshiRepository` に transaction 版 mutate を足すほどの並行頻度ではないため、controller 側の読み直しで足りると判断（グループ編集はダイアログ1箇所のみ） |
| D-153 | お気に入り操作は楽観更新しない。進行中はボタンを無効化し、DBの watch ストリームを唯一の真実とする | 失敗時のロールバックを「DBが変わっていない」事実に委ねられ、明示的な巻き戻しコードが不要（D-114 の Todo と異なりお気に入りは連打頻度が低く、ストリーム反映も十分速い）。成功していない操作を成功表示しない要件を最小の複雑さで満たす |
| D-154 | loading/error を空データへ変換しない: (1) `MemoryDetailScreen` は bundle の AsyncValue を `AsyncValueView` で入れ子にし、読み込み中に空 `MemoryBundle` を表示しない (2) 思い出一覧のお気に入りフィルタは全 bundle が data になるまで skeleton/エラー（再試行つき）を表示し「0件」と誤認させない (3) 一覧カードは bundle 読み込み中/失敗をカード単位の progress/エラー＋再試行にする (4) マイ推しの統計・次の現場は `SizedBox.shrink` へ変換せず、loading はインジケーター・error は理由文言を出す | design-spec §15「主要画面の loading/empty/error/offline/data が揃う」。R6独立レビュー#4（D-145）で provider 層は伝播済みだったが、R7中間版の画面側が `valueOrNull ?? 既定値` で握りつぶしていた。再読込中に前回値がある場合（`hasValue`）は表示を維持し、レイアウトシフトを避ける |
| D-155 | 現場一覧（`GenbaListScreen`）を R7 Design System（`AppScaffold`/`EventListCard`）へ移行し、ホームの「今後の現場」カードと共通の `GenbaEventListCard` に一本化した。現場一覧は状態チップ（中止/予定/準備中/本日/余韻中）を常時表示、ホームは中止のみ表示（`alwaysShowStatus`） | 旧 `GenbaCard` 依存を外しつつ、ホームと一覧で同一情報のカード実装が2つに分かれる乱立を避ける（design-spec §4）。ホームはヒーロー直下の一覧で文脈が伝わるため正常系チップを省き、一覧タブでは状態を明示する。`GenbaStatusChip` へアイコンを追加し「色だけに依存しない」を状態チップでも満たす（§14）。未来の中止現場は一覧に残り、詳細から中止取消できる（H-07 維持、widget テストで固定） |
| D-156 | 推しカラーの優先順位を「①グループ固有カラー（`OshiGroup.color`）→ ②ユーザー推しカラー設定（設定画面）→ ③テーマPrimary」と定義する。適用先はアクセント（現場カード左罫線・アバターリング・写真なしプレースホルダー・設定プレビュー）に限定し、Primary自体は変更しない。メンバーのアバターリングのみ「メンバーカラー → グループカラー → ユーザー設定 → Primary」 | design-spec §2「推しカラーは個人化用アクセント」「Primaryは主要操作に限定」。グループ固有色は「その推しの色」という意味を持つため、紐づく現場・アバターではユーザー全体設定より優先する。ユーザー設定は「推し未設定・グループ色未設定の場所のフォールバック」および設定プレビューで常時視認でき、「設定を変えたのに何も変わらない」状態にならない（グループ色が優先される旨は設定画面に明記済み） |
| D-157 | ユーザー推しカラーは owner 単位のキー `oshi_accent_color.<ownerId>`（AppKvs）へ保存する。`OshiColorNotifier` は `localDataScopeProvider` を watch し、未認証・復元中は未設定（null）として扱い保存も拒否する。アカウント削除の `purgeLocalDataForOwner` で当該 owner のキーのみ削除する。owner 不明の旧キー `oshi_accent_color`（R7中間版のみが書いた値）は読み捨て、推測でどの owner へも帰属させない | 推しカラーは D-45 の「端末共通のUX設定」（テーマ・チュートリアル）と異なり個人化設定であり、ユーザー切替で別ユーザーへ漏れると「他人の推し色が自分のカードに出る」というC-01類似の漏えいになる。scope を watch するため、ログイン/ログアウト/切替で provider が自動再構築され、手動 invalidate 不要。旧キーの破棄は D-44（owner不明下書きの破棄）と同方針で、色設定は再選択コストのみで実害がない |
| D-158 | 共通Design Systemの読み上げ単位: 意味を持つ小コンポーネント（`CountStat`/`StatusIconItem`/`SyncBadge`/`OshiAvatar`/`GenbaStatusChip`/カラースウォッチ/テーマプレビューカード）の `Semantics` に `container: true`（+ラベル重複時は `excludeSemantics: true`）を付け、`AppCard` のタップ領域も `Semantics(container: true, button: true)` で独立ノードにする | Flutterのセマンティクスは境界が無いと祖先ノードへマージされ、マイ推しのグループカードが「カード全体で1つの巨大な読み上げノード（内部のタップ先も不明）」になっていた（実測で確認）。境界を張ることで、スクリーンリーダーが統計・状態・操作を個別に読み上げられ、`find.bySemanticsLabel` による意味上のwidgetテストも成立する（§14/§15） |
| D-159 | `flutter_tester` の `ink_sparkle.frag`/Vulkan 制約（R5で特定済みの環境制約）への対応として、**テストハーネス（`test/helpers/pump_screen.dart`）だけ** `splashFactory: InkRipple.splashFactory` へ差し替える。本番テーマ（`app_theme.dart`）は変更しない | 本番の見た目・挙動を環境都合で変えない。R7の新規widgetテストはこのハーネスを使うため本ホストでも実行でき、意味上のアサーション（Semantics・実データ反映）を主証拠にできる。旧来の6ファイル（`OshiExpeditionApp` を直接 pump する main_flow/routing/user_switch/genba_status_actions/genba_todo_failure_rollback/oshi_selection）は引き続き本ホストでは同制約で失敗する（コード不具合ではない。実機/エミュレータ環境での実行が必要） |
| D-160 | 思い出詳細のカルーセル等を検証する widget テストは、他画面テストと同じ縦長ビューポート（1080×2800 @2x）を明示する | 既定の 800×600 ビューポートでは sliver の遅延ビルドにより画面外のカード（感想・タブ）が構築されず、「表示されるべきものが0件」という誤った失敗になる。アサーション自体は変更していない |

### 実装対象（R7で完成した範囲）
- Design Token: `app_tokens.dart`（色・余白・角丸・時間・Reduce Motion・推しカラープリセット10色）、`app_theme.dart`（ColorScheme/コンポーネントテーマ、ライト/ダーク）
- 共通Design System（`lib/app/design_system/`）: AppScaffold / AppCard / HeroEventCard / EventListCard / StatusIconItem / SectionHeader / SegmentTabs / PhotoMemoryCard / OshiAvatar / CountStat / SettingsRow / EmptyState / LoadingSkeleton / SyncBadge / FavoriteButton
- ホーム: 次の現場ヒーロー（残日数・4分割状態・写真/紫fallback）、当日はTodayCard最上位、今後の現場、FAB余白
- 現場詳細: 写真/紫fallbackヒーロー＋可読オーバーレイ、概要/Todo/チケット/交通/宿泊/メモの横スクロールタブ（既存CRUD・GenbaActionsController接続、タブ別スクロールはNestedScrollView+TabBarViewが保持）
- 思い出一覧: すべて/参戦済み/お気に入り、cover thumbnail、件数/セトリ/感想、お気に入り、写真なしプレースホルダー
- 思い出詳細: カルーセル1/N、アップロード状態バッジ、感想/セトリ/グッズ/メモ閲覧タブ、編集FAB、写真なし縮退
- マイ推し: プロフィール（画像/initial・カラーring・お気に入り）、メンバー横スクロール、導出統計3件、次の現場、誕生日・記念日、グループ/メンバー/記念日エディタ
- 設定: 階層型リスト、テーマプレビュー、推しカラー8色以上＋カスタム（owner単位保存・即時プレビュー）、アカウント/データ管理、危険操作分離、未実装機能の行は出さない

### 検証状況（2026-07-03, Windows host）
- `dart format lib test integration_test`: 整形済み（`--set-exit-if-changed` で差分0）。
- `dart analyze lib test integration_test`: **issues 無し**（着手時は `hero_event_card.dart` の構文エラーでコンパイル不能だった）。
- `flutter test`: **338件パス / 6件失敗**。失敗6件はすべて R5 で特定済みの `ink_sparkle.frag`/Vulkan シェーダー環境制約（`OshiExpeditionApp` を production テーマのまま pump する main_flow / routing / user_switch_visibility / genba_status_actions / genba_todo_failure_rollback / oshi_selection の6ファイル。ログ上の例外もすべて同シェーダー例外で、R7の変更に起因する失敗は0件）。R7の新規テストは D-159 のハーネスにより本ホストで全パス。
- `git diff --check`: クリーン（exit 0）。
- **未実施（成功と報告しない）**: `flutter test integration_test`（`flutter devices` は Chrome/Edge のみ検出。Android実機/エミュレータ無し・`windows/` デスクトップ未構成のため実行不可）、`flutter build apk`（Android SDK 未導入）、`flutter build ios`（macOS環境なし）。横向き・実機キーボード表示・スクリーンリーダー実機挙動は widget テストでは代替しきれないため、実機環境での確認が必要。

## R7 最終不足分（通信状態表示・画像異常状態・実画面テスト, 2026-07-04）

R7残タスク（オフライン/同期状態の表示、画像異常状態の区別、主要6領域の
実画面テスト）を完成させた。認証・owner分離・同期・暗号化・Repository・
Outboxの実装は変更していない（表示層と読み取りAPIの追加のみ）。

| # | 判断 | 理由 |
|---|---|---|
| D-161 | 通信・同期状態の表示は AppShell 上部の共通 `SyncStatusBanner` 1箇所に集約し（主要6領域と配下の詳細画面すべてが共有）、優先順位を「デモ → オフライン → 競合 → 失敗（再試行つき）→ 同期待ち → 非表示」とした。オフライン判定は新設 `isOnlineProvider`（既存 `ConnectivityObserver.isOnline`＋`onlineChanges` をそのまま流す）から取り、件数は既存 `outboxStatusProvider`（owner限定）から取る | 画面ごとの独自実装を作らず、「同期済み」との誤認を1箇所の規則で防ぐ。オフライン中は失敗件数の再試行が成立しないため到達性を先に伝え、「端末のデータは利用できます」と明示してローカルデータを隠さない（要件対応1）。競合は失敗と文言を分け、自動再送しない既存方針（D-21）どおり再試行ボタンを付けない。最終同期時刻は記録が存在しないため表示しない（架空の値を作らない） |
| D-162 | 画像参照の状態確認に `ImageStore.statusOfSync`（既存 `statusOf` と同一判定規則の同期版）を追加し、`imageAssetStatusProvider`（Provider.family, record キー）で UI から watch する。表示は新設の共通部品 `ImageStateNote`（暗色面＋アイコン＋文言）で統一 | stat 相当の軽量チェックを build 中に確定させ、読み込み待ちのちらつき・スピナーを避ける（非同期版は flutter_test の FakeAsync 下で実IOが完了せず、実画面テストも書けない）。判定規則（missing/inaccessible、FileSystemException→inaccessible）は D-89 と同一で、非同期版はそのまま残す |
| D-163 | 画像異常状態の区別と導線: ヒーロー（ホーム/現場詳細）と思い出表紙は「未設定（装飾placeholder）」と「設定済みだが表示できない（missing=端末から削除 / inaccessible=権限・ロック）」を `ImageStateNote` で区別。思い出詳細カルーセルは missing→「写真を選び直す」（記録編集へ）、inaccessible→「再試行」（状態再判定）、localPath無し＋storagePath有り→「この端末に写真の実体がありません」、デコード失敗→「再試行」（画像キャッシュ破棄）、upload failed→SyncBadge＋「アップロードを再試行」（既存 `MemoryEditController.uploadPhoto`） | design-spec §12「読み込み中・失敗・オフライン・権限喪失・削除済みの各状態を用意する」「placeholderだけで隠さない」。対応可能な状態にのみ導線を出し、対応不能な状態（他端末の写真の実体なし＝画像Storage同期は後続範囲）は状態の明示に留める。チケット画像のヒーロー流用禁止は既存の構造分離（D-133）のまま不変 |
| D-164 | 実画面テストは全条件×全画面の総当たりにせず、各条件を最も崩れやすい画面で代表させた: 横向き=ホーム、dark×360dp=現場一覧、文字200%=思い出一覧、48dp/Tooltip=マイ推し、キーボード=現場詳細Todoエディタ、壊れ画像=思い出詳細/一覧、error状態=思い出一覧（bundle失敗注入）、シェル保持/FAB重なり=実GoRouter（`routerProvider`）+AppShell。バナーの全状態は単体で網羅 | R7要件の検証条件を実画面で証明しつつテスト時間の肥大化を避ける（共通部品のみのサンプルテストを実画面テストの代用にしない）。シェルテストは production テーマの `OshiExpeditionApp` を使わず `MaterialApp.router`＋テストテーマ（D-159）で ink_sparkle 制約を回避し、ルーティング・タブ保持・FAB余白を本物の router で検証する |
| D-165 | inaccessible の再現はテストで「ファイル位置にディレクトリを置く」ことで行う（D-89 の実分岐）。48dp の計測は Tooltip の視覚箱（40dp）ではなく `IconButton`（materialTapTargetSize.padded を含む実タップ領域）で行う | 実端末の権限喪失・端末ロックと同じ `inaccessible` 分岐を、ホストで決定的に再現できる。Material のタップ領域は視覚サイズの外側にパディングとして確保されるため、視覚箱の計測では 48dp 要件を誤って不合格にする |
| D-166 | `_Banner` のセマンティクスは、状態カテゴリのラベルをアイコン側の独立ノード（container: true）とし、詳細文言は Text ノードとしてそのまま読み上げさせる | ラベルをバナー全体へ付けると子テキストとマージされ「カテゴリ＋全文」の連結文字列になり、読み上げが冗長になるうえ意味上のテスト（bySemanticsLabel）も成立しない（D-158 と同じマージ問題の変種） |

### 検証状況（2026-07-04, Windows host）
- `dart format` / `dart analyze lib test integration_test`: issues 無し。
- `flutter test`: 本文の最終報告を参照。既知の `ink_sparkle.frag`/Vulkan 環境制約6ファイル以外は全パス。
- **未実施（成功と報告しない）**: integration test・Android/iOS build（実機/エミュレータ・Android SDK・macOS なし）。実端末での権限喪失・機内モード・スクリーンリーダー実挙動は widget テストの代替確認のみ。

## 開発環境の注意（Windows / 非ASCIIパス）

- 本リポジトリの絶対パスに非ASCII文字が含まれる環境では、`flutter analyze` が
  analysis server の JSON 解析エラーで落ちることがある。**`dart analyze` は正常に動作する**ため
  そちらを使用する（検証済み）。
- Flutter SDK は `C:\src\flutter`（setup.md の推奨に一致）へ導入済み。PUB_CACHE も
  非ASCIIパス回避のため `C:\src\pub_cache` を使用した。
- Windows ホストでの単体テストは OS 同梱の `winsqlite3.dll` へフォールバックして
  SQLite を利用する（`test/helpers/test_db.dart`）。

## R8 独立監査（H-06以降の最終回帰・文書整合・リリース判定, 2026-07-04, Claude Sonnet 5）

`docs/fable-post-implementation-review-prompt.md` 準拠でR1〜R7完了後の成果を監査した。
5領域（DB/認可/プライバシー、アーキテクチャ+UI、テスト信頼性、日時/状態、同期/ローカル保存）
を専門エージェントへ並列委任し、監査担当自身（本セッション）も主要な指摘を直接コード読解で
裏付けた上で統合した。R1〜R7の実装は変更していない（本節に記載する2件の局所修正を除く）。

### 総合判定: **FAIL**（Critical 0件・High 3件。監査ルーブリック上、High 1件以上はFAIL）

Critical/Highが認証・RLS・同期・暗号化・データmigrationに関わるため、その場で推測修正せず
`docs/current-program-review-and-remediation-prompts.md` §8 に Claude Opus 4.8 向け独立修正
パッケージ（R8-A/R8-B/R8-C）として切り出した。局所的なUI/文書修正はD-167〜D-168として本セッションで実施済み。

### 指摘一覧（重大度順）

| ID | 重大度 | 領域 | 指摘 | 証拠 |
|---|---|---|---|---|
| E-1 | **High** | 同期 | `OutboxStatus.conflict` になった操作を pending へ戻す・解消する経路が存在しない。`OutboxStore.retryFailed()`（`lib/core/sync/outbox_store.dart:166-177`）は `status='failed'` のみ対象。`hasPendingFor()`（同197行）は conflict も「未同期あり」として扱うため、`remote_pull.dart:44` の pull スキップにより該当エンティティは永久にサーバーへ追従しない。UIには競合件数を表示するのみで解消操作が無い（`sync_status_banner.dart`）。本セッションで直接コードを読み再現条件を確認済み。修正はR8-A（Opus 4.8）。 | `lib/core/sync/outbox_store.dart:166-197`、`lib/core/sync/remote_pull.dart:44` |
| F-2 | **High** | DB/認可 | `transports`/`lodgings`/`genba_memos`/`setlist_items`/`goods_items`/`visited_places`/`profiles` の7テーブルと `outbox_operations`（負例のみ欠如）に pgTAP テストが1件も存在しない（`supabase/tests/*.sql` を全ファイルgrepしても一致なし、本セッションで再確認済み）。`lodgings.address`/`transports.reservation_number` 等、要件§15.2が名指しする機微情報を持つテーブルが自動検証されていない。RLS実装自体は他テーブルと同一パターンで存在する。修正はR8-B（Opus 4.8）。 | `supabase/tests/0001〜0004*.sql`（該当テーブル名で一致なし） |
| H-A | **High** | テスト信頼性/同期 | Supabaseへの全通信（`Supabase.initialize`・RPC・Auth・Storage）にタイムアウト設定が無い。`SyncEngine._drainOnce()` の `await snapshot.remote.apply(op)` がハングすると `_running`/`_inFlight` が解除されず、`AccountController.deleteAccount()` の `pauseForAuthTransition()` 待ちが無期限化し、`finally`（「AsyncLoadingのまま固まらないように」とコメントされた解除処理）に到達しない。唯一のタイムアウトは接続監視probe（`providers.dart:81`, 5秒）のみ。修正はR8-C（Opus 4.8）。 | `lib/bootstrap.dart:83-88`、`lib/core/sync/sync_engine.dart:134-230`、`lib/features/settings/application/account_controller.dart:48,75-81` |
| E-2 | Medium | 同期/認証 | `AccountController.deleteAccount()` に他の操作コントローラ（Genba/Memory/Oshi Actions Controller）と同じ操作キー単位の二重タップ防止が無く、連打で並行実行され得る。本セッションで該当ファイルを読み再入防止コードが存在しないことを確認済み。修正はR8-C（Opus 4.8、H-Aと同一パッケージ）。 | `lib/features/settings/application/account_controller.dart:37-82`（`_run`相当のガード無し） |
| F-1 | Medium | DB/認可 | `performances` テーブルにDELETEポリシーが無く、投稿者が自分の投稿を削除できない。意図的仕様か実装漏れかが `decisions.md`/`follow-up-work.md` いずれにも記録されていない。修正はR8-B。 | `supabase/migrations/0002_oshi_performances.sql:104-110` |
| F-3 | Medium | DB/認可 | `enforce_oshi_anniversary_owner()` トリガーが `member_owner` を取得しながら `new.owner_id` と直接比較せず、別トリガー（`enforce_oshi_member_owner`）が維持する不変条件に暗黙依存している（D-147で開発者自身が認識しテストで代替担保済みだが、トリガー自体に直接防御が無い）。修正はR8-B。 | `supabase/migrations/0007_image_design_fields.sql:104-131`、本ファイルD-147 |
| C-1 | Medium | アーキテクチャ | `lib/features/genba/presentation/widgets/child_editors.dart` が990行（5つのエディタウィジェット+共有Scaffold）で、コーディング規約の800行上限を超える。機能的欠陥ではなくファイル分割の推奨。 | `lib/features/genba/presentation/widgets/child_editors.dart`（990行） |
| H-B | Medium | ログ/セキュリティ | `AppLogger.sensitiveKeyPatterns` が snake_case（`from_place`等）のみを持ち、camelCaseキー（`fromPlace`）で渡された場合にマスクを素通りする経路があった。現状の呼び出し箇所（2箇所のみ）は該当フィールド値を渡していないため実害は未確認だが、潜在的欠陥として**本セッションで是正済み（D-167）**。 | `lib/core/logging/app_logger.dart`（是正前） |
| H-C | Medium | 文書 | `docs/decisions.md` のR7節（D-151〜D-166）を含む一連の変更が本セッション開始時点でコミットされておらず（`git log` に該当コミットなし、`git status` で全件 modified/untracked）、記載されたテスト結果（「338件パス」等）を不変のスナップショットへ紐づけて検証できない状態だった。ユーザーの明示的な指示がない限りコミットは行わないため、本監査では「未コミットのまま」という事実を記録するに留める。 | `git log --oneline`、`git status`（本監査開始時点） |
| A-1 | Low | 環境/CI | `.github/workflows/ci.yml:3-5` の先頭コメントが「pubspec.yaml未生成のためPhase 0」という2026-07-01時点の記述のまま残り、実態（pubspec.yaml既存・各ジョブ実行中）と乖離している。機能的影響は無い。 | `.github/workflows/ci.yml:3-5` |
| A-2 | Low | 環境/CI | macOSジョブ（`ci.yml`の`macos-ios`）に `dart format`/`flutter analyze` の実行が無く、静的解析はWindowsジョブでのみ実施される。共有Dartコードを対象とするため実害は小さい。 | `.github/workflows/ci.yml:91-124` |
| D-1 | Low | 日時/状態 | `upcomingGenbasProvider`/`memoryGenbasProvider`（現場一覧・思い出一覧全体）は `eventDate` のみでソートし、同日複数公演の順序が決定的でない。要件§6.2「開始時刻順」はホームの当日セクションに限定されており該当箇所（`home_screen.dart:50-58`）は正しく実装済みだが、一覧タブ全体への拡張時は二次キー（`startTimeMinutes`）の追加を検討する。 | `lib/features/genba/application/genba_providers.dart:29-31,40-41` |
| D-2 | Low | 日時/状態 | ホーム当日セクションのソートで `startTimeMinutes == null` の現場が0扱いされ、早朝公演より先頭に来る。要件違反ではないが留意点として記録。 | `lib/features/home/presentation/home_screen.dart:50-58` |
| B-1 | Low | 機能 | オンボーディング文言が「通知は必要になったタイミングで案内」を示唆するが、その後続の通知許可要求（案内後の許可ダイアログ）自体は実装されていない（`permission_handler`等の依存が無い）。オンボーディング中に許可を要求しないという監査対象の要件自体は満たされている。follow-up-work.mdのフェーズD（通知）で対応予定。 | `lib/features/onboarding/presentation/onboarding_screen.dart:32-36` |
| E-3 | Low | 文書 | `RemoteMutationClient.apply()` のdocコメントが「last-write-wins: updated_atの比較」と記載し、実装（版CASによる `base_version` 比較）と一致していなかった。**本セッションで是正済み（D-168）**。 | `lib/core/sync/remote_mutation_client.dart`（是正前） |
| F-4 | Low(情報) | DB | `outbox_operations` に保持期限・削除ジョブが無く、テーブルが無制限に増加する。セキュリティ上の欠陥ではなくスケール上の留意点。 | `supabase/migrations/0004_memories_outbox.sql:139-151` |

「no issues found」と明示的に確認できた領域: presentation層からのSupabase/Drift直接呼び出し無し、
domain層の純Dart性、Repository/DTO境界、循環依存無し、go_routerのredirectループ無し、
デモ/本番Repository選択の一意性、Design System 15コンポーネント全実装、featureスクリーンへの
色ハードコード無し、Semantics/Tooltip、ヒーロー画像とチケット画像の構造分離、
`DateTime.now()`直呼び出し無し（Clock抽象を全箇所で使用）、状態遷移（予定/準備中/本日/余韻中/思い出/中止）
の境界値・深夜公演・手動終演訂正・中止現場の可視性、日程変更時のmanualEndedAtリセット、
タイムゾーン境界（UTCタイムスタンプ/ローカル暦日の一貫した分離）、
apply_mutation RPCのowner_id/version列ホワイトリストとSQLインジェクション対策、
子テーブルのオーナーシップ迂回防止トリガー、Storage署名付きURLのowner境界、
秘密情報のリポジトリ混入無し、TODO/FIXME/UnimplementedError無し、空catch1件（意図的で問題なし）、
テストskip無し、テストが検証対象機能を無効化して見せかけの成功にする例無し、
デモモードのstaging/production暗黙フォールバック不可、3flavorのAndroid/iOS/CI設定の整合性。

### 本セッションで実施した局所修正

| # | 修正 | 理由 |
|---|---|---|
| D-167 | `AppLogger.isSensitiveKey()` をアンダースコア除去後に比較する実装へ変更し、`sensitiveKeyPatterns` からアンダースコア込みの重複エントリ（`entry_number`等）と実在しない列名エントリ（`lodging_name`）を整理した。camelCaseキーでのマスク回避を防ぐ回帰テストを追加（`test/core/result_and_logging_test.dart`） | H-Bの是正。ログ経由の機微情報マスキングは要件§15.2の直接該当項目であり、RLS/同期/暗号化のいずれにも触れない局所的な文字列処理バグのため本セッションで是正可能と判断した |
| D-168 | `RemoteMutationClient.apply()` のdocコメントを実装（版CAS）と一致する内容へ修正 | E-3の是正。コメントのみの変更でロジックには触れていない |

### 検証状況（2026-07-04, Windows host, R8監査）

- `dart format lib test integration_test`: 変更0件。`dart analyze lib test integration_test`: **issues無し**。
- `flutter test`: **358件パス / 6件失敗**（失敗は全件、既知の `ink_sparkle.frag`/Vulkan 環境制約。本監査・是正による新規失敗は0件）。
- `git diff --check`: 検証はR8完了報告時点の値を参照。
- **未実施（成功と報告しない）**: `flutter test integration_test`、`flutter build apk`、`flutter build ios`、`supabase test db`（いずれも実機/エミュレータ・Android SDK・macOS・Docker が本環境に無いため）。

### 残課題

- `docs/current-program-review-and-remediation-prompts.md` §8 のR8-A/R8-B/R8-C（Claude Opus 4.8向け）を実行し、High 3件を解消する。
- R8-A/B/C完了後、本監査手順を再実施しCritical/Highが0件であることを確認してからfollow-up-work.mdの各フェーズ（同期の完成、写真、公演DB/共有、通知）または最終リリース判定へ進む。
- Medium/Low指摘（C-1のファイル分割、A-1/A-2のCI文書整合等）は次回の保守セッションで対応する。

## R8 是正実施（High 3件の修正, 2026-07-04, Claude Opus 4.8）

R8監査で切り出した R8-A/R8-C/R8-B を実施し、High 3件（E-1・H-A・F-2）と
併記の Medium（E-2・F-1・F-3）を解消した。R1〜R8の既存挙動・テストは
変更・弱体化していない（既存マイグレーションは追記のみ）。実装順は
R8-A → R8-C → R8-B。

### R8-A: Outbox競合(conflict)の正式な解決処理（E-1, High）

| # | 判断 | 理由 |
|---|---|---|
| D-169 | 競合を「サーバー採用（この端末の変更を破棄）」と「この端末の変更で再送」の2手段でユーザーが明示的に解決できるようにした。無条件に failed/pending へ戻して上書き競合を隠すことはしない。`OutboxStore` に owner 限定の `conflictOps`/`conflictById`/`discardConflict`/`reopenConflict` を追加し、`ConflictResolver`（core/sync）が両手段をオーケストレーションする | E-1: `retryFailed()` が `failed` のみ対象で `conflict` を放置し、`hasPendingFor` が conflict を「未同期あり」と扱うため pull もスキップし、当該エンティティが永久にサーバーへ追従しなかった。解決手段を型付き結果（`ConflictResolutionResult`）で返し、UIから選ばせることで恒久放置を断つ |
| D-170 | サーバー採用では、競合opを残したまま対象エンティティのサーバー最新内容を取得・強制適用し、成功を確認してから競合opを削除する。通信・保存失敗時はErrを返し、競合opと再試行経路を維持する | 既存のpull機構をそのまま再利用でき、当該エンティティだけを確実にサーバー最新へ収束させられる。破棄は不可逆のためUIで確認ダイアログを課す（誤操作防止） |
| D-171 | 「この端末の変更で再送」= 新設 `reconcileServerVersionInto`（remote_pull.dart）でサーバーの現在版だけを版キャッシュへ整合（ローカル行は保持）→ 競合op を pending へ戻す → drain。版CASが成立しサーバーがこの端末の内容で更新される。reconcile 後にサーバーが更に進んでいれば再び conflict になる | apply_mutation は既存行への `base_version=null` を blind overwrite として conflict にする（D-68）。よって「端末の変更を採用」には必ずサーバー現在版が要る。**既存テスト（remote_mutation_client_test）が固定する「通常の apply では conflict 時に版キャッシュを進めない」挙動は変えず**、ユーザーが明示的に選んだ reconcile のときだけ版を整合させる。自動同期では決して起きないため無条件上書きの穴を作らない |
| D-172 | 競合解決UIは AppShell 上部の共通 `SyncStatusBanner` の競合バナーに「解決する」を追加し、`showConflictResolutionSheet`（新設）で項目別に2択を提示する。owner分離は `localDataScopeProvider` の owner と OutboxStore の owner 限定メソッドで担保 | 画面ごとの独自実装を作らず共通部品に集約する（R7方針の踏襲）。別ownerの競合は解決できないことを OutboxStore の owner 条件とテストで固定 |

追加テスト: `test/core/conflict_resolution_test.dart` + `test/widget/conflict_resolution_sheet_test.dart`
（競合解決重点テスト: 24件成功。owner分離・再起動後の競合復元と解決・reconcile・
useServer/keepLocal統合（成功・通信/保存失敗・タイムアウト相当）・「reconcile後に
サーバーが更に進めば再conflict」・一覧表示・サーバー採用の確認ダイアログ経由・
端末再送・失敗時のUI表示（成功メッセージを出さず理由と再試行を提示）を含む）。
全テスト: 389件成功／6件失敗（6件は既知の `ink_sparkle.frag`/Vulkan環境制約のみ、
本是正による新規失敗は0件）。Critical 0件／High 0件。

### R8-C: Supabase通信の共通タイムアウトとアカウント削除の二重タップ防止（H-A・E-2）

| # | 判断 | 理由 |
|---|---|---|
| D-173 | 共通タイムアウト方針を2層で導入。(1) `Supabase.initialize(httpClient: TimeoutHttpClient(...))` で全通信（Auth/PostgREST/Storage/Realtime）にリクエスト単位の共通タイムアウト（20秒）。(2) 列挙した各境界（apply_mutation RPC・認証4種・アカウント削除RPC/signOut・写真upload/signedUrl・pullのselect）に `.withRemoteTimeout()` を付け、`TimeoutException` を `NetworkFailure` へ変換する。定数・ヘルパは `lib/core/network/network_timeout.dart` | H-A: どの境界にもタイムアウトが無く、`SyncEngine._drainOnce()` の `apply` がハングすると `_running`/`_inFlight` が解けず、`AccountController.deleteAccount()` の `pauseForAuthTransition()` 待ちが無期限化し finally（AsyncLoading解除）に到達しない。httpClient層で付け忘れを防ぎ、境界層で型付き失敗にして既存の NetworkFailure→pending/バックオフ再送の経路へ合流させる。SyncEngineの排他制御設計自体は変更していない（タイムアウトはその内側のHTTP呼び出しに追加） |
| D-174 | `AccountController.deleteAccount()` に他コントローラ（GenbaActionsController 等）と同じ操作単位ガード（`_deleting` フラグ）を追加。進行中の再入は即 null を返し、実RPCは1回だけ実行する | E-2: 削除ボタン連打で `deleteAccount()` が並行実行され得た。既存の二重タップ防止パターンを踏襲し、サーバー削除RPCの多重呼び出しを防ぐ |

追加テスト: `test/core/network_timeout_test.dart`（5件: withRemoteTimeout・
TimeoutHttpClient・「apply がハング→タイムアウトで op が pending へ戻り drain が
有限時間で完了」・「in-flight apply のタイムアウトで pauseForAuthTransition も返る」）、
`test/notifier/account_controller_test.dart` に二重タップ1件追加（連打でも実RPCは1回）。

### R8-B: RLS/pgTAPカバレッジ拡充・performances DELETE・トリガー堅牢化（F-2・F-1・F-3）

| # | 判断 | 理由 |
|---|---|---|
| D-175 | 未カバーだった `transports`/`lodgings`/`genba_memos`/`setlist_items`/`goods_items`/`visited_places`/`profiles`/`outbox_operations` について、`supabase/tests/0005_rls_child_and_master.sql`（新設）で正例（owner本人はCRUD可）・負例（別ownerは SELECT/UPDATE/DELETE 不可）・親ID経由の owner 迂回不可（`enforce_genba_child_owner` の拒否）を pgTAP で固定した（plan 43＝アサーション 43） | F-2: 機微情報（`lodgings.address`・`transports.reservation_number` 等）を持つテーブルが自動検証されていなかった。別ownerの SELECT が 0 件になることで「機微情報が他ownerへ露出しない」ことも同時に担保する |
| D-176 | `performances` は DELETE ポリシーを追加せず、「投稿者本人でも DELETE できない」ことを pgTAP で明示的に固定した。共有マスタ（§10.3公開データ）の削除・重複統合・通報は後続のモデレーション/管理者機能（follow-up-work.md フェーズC, §10.4）で扱う | F-1: 投稿者が任意に共有公演を削除できると、それを現場として登録した他ユーザーの参照（`genbas.performance_id`）を壊し得る。削除不可を意図的な仕様として明記し、テストで固定する（無記載の放置をしない） |
| D-177 | `enforce_oshi_anniversary_owner()` に `member_owner is distinct from new.owner_id` の直接比較を追加する（新規マイグレーション `0008_anniversary_owner_hardening.sql` で `create or replace`。既存0007は変更しない）。**D-147の方針（別トリガーの不変条件への暗黙依存）を更新**し、その不変条件が将来崩れても記念日のオーナー不一致を直接検出する多層防御へ変更した | F-3: 従来は取得した `member_owner` を `new.owner_id` と比較せず、`enforce_oshi_member_owner`（0002）が維持する「member.owner==group.owner」不変条件に暗黙依存していた。直接比較を足すことで前提崩壊時も検出できる。既存 0004 の member 整合テスト（別グループ/別owner の member_id 拒否）は、最終トリガー定義（0008適用後）に対する回帰として引き続き有効 |

### 検証状況（2026-07-04, Windows host, R8是正）

- `dart format lib test integration_test`: 変更0件。`dart analyze lib test integration_test`: **issues無し**。
- `flutter test`: 本文の最終報告を参照（R8-A/Cの新規テストを含め全パス。失敗は既知の `ink_sparkle.frag`/Vulkan 環境制約6件のみで、本是正による新規失敗は0件）。
- `git diff --check`: クリーン（本文の最終報告を参照）。
- **未実施（成功と報告しない）**: `supabase test db`（Supabase CLI 2.108.0 はあるが Docker 未導入で `supabase start` 不可）。R8-Bの SQL（0008 マイグレーション・0005 pgTAP）は**静的検証のみ**実施済み: plan数＝アサーション数（43＝43）、UUID全リテラルが16進形式、`begin;`/`rollback;` 対応、参照列がスキーマに実在、既存0004のplan/アサーション不変。実Postgres上での実行は未確認。`flutter test integration_test`・Android/iOSビルドも従来どおり環境不足で未実施。

### 残課題（R8是正後）

- Docker 導入環境で `supabase db reset` → `supabase test db` を実行し、0005 pgTAP（43件）と0008マイグレーションの適用・既存0001〜0004の回帰を実機確認する。
- R8-A/B/C完了により High 3件・Medium 3件（E-2/F-1/F-3）は解消。残 Medium（C-1: `child_editors.dart` 分割）と Low（A-1/A-2 のCI文書整合, D-1/D-2 の同日ソート二次キー, B-1 通知許可の後続実装）は保守セッションで対応する。
- 本是正後にR8監査手順（`fable-post-implementation-review-prompt.md`）を再実施し、Critical/High 0件を独立確認してからリリース判定へ進む。
## 旅程Google API低コスト・保存規約方針（2026-07-06）

確認した公式資料:

- [Places API policies and attributions](https://developers.google.com/maps/documentation/places/web-service/policies)（確認日: 2026-07-06）
- [Place IDs](https://developers.google.com/maps/documentation/places/web-service/place-id)（確認日: 2026-07-06）
- [Places API usage and billing](https://developers.google.com/maps/documentation/places/web-service/usage-and-billing)（確認日: 2026-07-06）
- [Routes API Compute Routes](https://developers.google.com/maps/documentation/routes/compute_route_directions)（確認日: 2026-07-06）
- [Google Maps Platform Service Specific Terms](https://cloud.google.com/maps-platform/terms/maps-service-terms)（確認日: 2026-07-06）

| # | 判断 | 理由 |
|---|---|---|
| D-178 | Places MVPの取得Field MaskをPlace ID・名称・住所・表示に必要な帰属情報へ限定し、電話、Web、営業時間、写真、評価、レビュー、primary type、座標は取得しない。Place IDは永続保存・再利用し、名称・住所はGoogle応答のユーザー横断恒久キャッシュにしない | Places公式ポリシーは原則としてPlacesコンテンツの事前取得・キャッシュ・保存を禁じ、Place IDだけをキャッシュ制限の例外としている。Field Maskは要求中の最高SKUに課金されるため、最小allowlistが費用と規約の両面で安全 |
| D-179 | 共有施設DBと共有概算経路DBは、ユーザー入力、施設提供、オープンデータ、契約データ等、保存・再利用権限を説明できるデータのみを正本とする。Google応答から名称・住所・経路内容を自動転記して共有キャッシュへ昇格させない。Place IDは照合キーとして利用可能 | 「誰かが一度取得したGoogle施設情報を全ユーザーで再利用する」構成はGoogle API呼び出しの代替となり、現行のキャッシュ制限に適合しない。出典・権利根拠を持つ独立データなら、API費用を抑えつつ共有再利用できる |
| D-180 | ~~Google Routesは、**プレミアムユーザーが**経路詳細を開くか`最新ルートを更新`を押した場合だけ呼ぶ~~。通常表示は権利確認済みの保存済み概算経路を優先する。Googleライブ応答は一時表示とし、書面許諾等が無い限り共有DBへ永続キャッシュしない | Routesの現行個別規約で明示されるキャッシュ許可は緯度・経度の最長30日であり、経路概要・所要時間・路線・運賃等を恒久DB化してAPIを代替する許可は確認できない。明示操作・single-flight・クォータ・kill switchで呼出しを抑える。**【現在はD-232で上書き】** プレミアム限定の部分は無効。現仕様では経路取得は全認証ユーザーが利用可能で、プレミアム制限は Edge Function `ROUTES_REQUIRE_PREMIUM=true`（既定 false）の環境でのみ有効。保存済み概算優先・恒久キャッシュ禁止・明示操作/single-flight/レート制限/kill switch は引き続き有効 |
| D-181 | Google由来の緯度・経度を一時保存する場合は、取得元・取得日時・失効日時を持ち、最長30日で自動削除する。無料／プレミアムにかかわらず同じ保存・帰属制約を適用し、規約確認をリリース前・四半期ごとに行う | Google Maps Platformの規約・料金・製品仕様は更新され得る。課金権限は保存権限を意味しないため、entitlementとcomplianceを分離して強制する |

## Phase 2最終レビュー是正（2026-07-07, Claude Opus 4.8）

`feat/todo-belonging-templates` の「計画タブ Phase 2」最終レビュー指摘6件を是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-182 | ローカルDBを **schema v8→v9** へ更新し、交通/宿泊の部分ユニーク索引 `idx_itinerary_entries_plan_transport` / `..._plan_lodging` を、cover索引と同じ「dedup→版付き作成」方式（`_dedupeItineraryEntryReferences` → `_createItineraryReferenceUniqueIndices`）へ格上げした。索引作成前に、同一計画に同じ交通/宿泊を参照する重複項目を `(sort_order, created_at, id)` 昇順の最小1件へ決定的に整理し、負け側を端点とする leg と、負け項目/leg の未送信 Outbox も掃除する | v8では索引作成が汎用 `_createOwnerIndices` に紛れており、既存重複があると `CREATE UNIQUE INDEX` が失敗して起動不能になり得た。版付きの dedup→作成にすることで、既存重複があっても決定的に整理してから索引を張れる。移行検証は `test/data/itinerary_v9_migration_test.dart` が **v8ファイルDB作成→v9再open→索引存在→重複INSERT拒否** をfile-backedで確認 |
| D-183 | `ItineraryRepository.reorderEntries` を「順序だけ変更するAPI」へ変更（`{planId, orderedEntryIds}`）。全IDの実在・同一owner・同一計画・**同一実効表示日**を単一トランザクション内で検証し、`sort_order` と `updated_at` **のみ** を UPDATE（項目内容を upsert しない）。存在しないID・別owner・別計画・別日は型付き Failure で拒否し、途中失敗は行とOutboxを全rollback | 旧実装は呼び出し側の entry 全体を `insertOnConflictUpdate` していたため、並び替えのつもりで中身も上書きし得た。ID一覧受け取り＋UPDATE限定にして副作用を排除。Outbox payload は更新後のDB行から作り、並び順以外を書き換えない保証を持たせた |
| D-184 | `saveSpotBundle` の `removedLinkIds` を、対象スポットかつ同一ownerに属するリンクだけに限定。別スポット・別owner・存在しないIDは一貫した型付き `ValidationFailure`（存在推測を防ぐ共通文言）で拒否し、不正が1件でもあれば spot/entry/links/Outbox を全rollback | 旧実装は id+owner だけで delete し、別スポットのリンク削除や、存在しないID指定時の空振り delete Outbox を許していた。トランザクション先頭で所属を検証して原子性と越境防止を両立 |
| D-185 | 交通・宿泊の元データ更新を**導出（derive）方式**で即時反映する（§5.3.1/§5.3.2）。取り込み時に日時をスナップショットせず、タイムラインの表示日・時刻順・融合・間に合い判定を参照元から毎回導出。ユーザー上書きは entry の `local_date`/`start_at`/`end_at` の非nullで明示モデル化（null=参照元に追従）。純粋関数 `effectiveItinerarySchedule` に集約 | 「参照するだけで複製しない」（§5.3）を名称だけでなく表示順に関係する日付・出発時刻・チェックイン日にも適用。同期更新方式は交通/宿泊更新経路への逆依存とOutbox増を招くため不採用。`test/domain/itinerary_source_reflection_test.dart` が「元データ変更で別日へ移動」「時刻変更で同一日内の並びが変わる」を検証 |
| D-186 | Supabase `0014` に、部分ユニーク索引作成前の**決定的dedup**（`(sort_order, created_at, id)` 最小1件保持、負け側を端点とする leg は FK `ON DELETE CASCADE` で自動掃除）を追加。pgTAP `tests/0010_itinerary_entry_reference_unique.sql`（plan 16）で、直接INSERT/UPDATE重複拒否（23505）・apply_mutation経由の重複拒否・別計画での同一参照許可・spot/note非回帰・既存重複からの移行方針を検証 | サーバー側でも UI/ローカルと同じく重複を弾き、既存重複があっても `0014` 適用が失敗しないようにする。ローカル v9 dedup と保持規則を一致させて端末・サーバーで同じ勝者を残す |
| D-187 | 実端末統合テスト `integration_test/itinerary_offline_encrypted_sync_test.dart` を追加。本番と同じ暗号化オープン（`prepareSqlCipher` + `openEncryptedExecutor` + `openVerifiedDatabase`）でfile-backed暗号化DBを開き、オフライン編集→Outbox保存→**DB完全close→正鍵で再open→データ/未送信復元→SyncEngine送信でpending解消・（擬似リモートで）反映** を検証。Windows非ASCII TEMP問題の回避手順（ASCIIパス配置／TEMP再設定／実機実行）をヘッダに文書化 | `openEncryptedExecutor` は SQLCipher `PRAGMA key` を使い host winsqlite3 で検証不可のため device/emulator 実行（encryption_sqlcipher_test と同方針）。実バックエンド反映は CI の pgTAP と手動E2Eで別途確認する |

### 検証状況（2026-07-07, Windows host / ASCIIパス `C:\Users\naman\StudioProjects\OshiTrip`）

- `dart analyze lib test integration_test`: 本文の最終報告を参照。
- `flutter test`（単体+Widget）: 本是正の新規/更新テスト（`itinerary_bundle_test` の reorder順序限定・removedLinkIds越境／`itinerary_v9_migration_test`／`itinerary_source_reflection_test`）を含む結果は本文の最終報告を参照。
- **未実施（成功と報告しない）**:
  - `flutter test integration_test --flavor development`: エミュレータ/実機・adb が無く未実行。`itinerary_offline_encrypted_sync_test` / `app_flow_test` / `encryption_sqlcipher_test` は静的にコンパイル確認のみ。
  - `supabase db reset` / `supabase test db`（pgTAP）: Docker 未導入で `supabase start` 不可。`0014` マイグレーションと `tests/0010`（plan 16）は**静的検証のみ**（plan数＝アサーション数、UUIDリテラルが16進、参照列がスキーマに実在、`begin;`/`rollback;` 対応）。実Postgres上での実行は未確認。

## Phase 2追補「計画」機能の仕様変更（2026-07-07, Claude Opus 4.8）

`feat/todo-belonging-templates` の計画機能に、Phase 2最終レビュー是正（D-182〜D-187）へ
追加する形で以下の仕様変更を実装した（既存の未コミット差分を保持したまま追加）。

| # | 判断 | 理由 |
|---|---|---|
| D-188 | スポットカテゴリに「聖地」(`sacred_place`) を独立カテゴリとして追加（enum・JSON wire・DBラベル・アイコン）。「神社・寺院」「観光地」とは統合しない。DB制約はローカルDrift（`itinerary_spots.category` は text で制約無し・enum往復で担保）とSupabaseの追加マイグレーション `0015_itinerary_spot_category_sacred_place.sql`（0012のCHECKを前方専用で差し替え、既存値を全許可のまま追加）で許可 | 聖地巡礼は推し活遠征の主要目的の一つで、神社・寺院や観光地と区別して集計・表示したい。追加のみで後方互換を壊さない |
| D-189 | 緯度・経度をスポット作成・編集画面から削除（入力欄・バリデーション・エラーを出さない）。ドメイン／DBの nullable な座標フィールドは将来の地図・Google連携用に残す。編集保存時は既存座標を保持（`widget.existing?.spot.latitude/longitude` を渡し、誤って null 上書きしない）、新規手動登録は null | MVPの手動入力で緯度・経度を求めるのはUX負荷が高く誤入力の温床。座標は将来Google Places/地図から取得する設計（D-178/D-179）なので、手動UIから外しつつ列は温存する |
| D-190 | 移動区間(leg)編集から日付入力を廃止し時刻のみ入力。出発日=出発元予定日、到着日=到着先予定日を内部決定し、同日で到着<出発なら日跨ぎで翌日。前後予定日が取れなければ本日を入れず日時はnull（所要時間等は保存可・日本語で案内）。純粋関数 `deriveLegTimestamps` に集約。既存 departureAt/arrivalAt 互換維持（ローカル壁時計→toUtc） | 移動区間は隣接する前後予定を結ぶ設計。別日付を自由入力できると前後予定と矛盾し得る。前後から導出すれば入力を減らしつつ整合を保てる |
| D-191 | スポット訪問の新規追加時、訪問日の初期値を「本日」ではなく現在操作中の予定日にする。優先: 現在表示日→前後予定日→現場開催日→旅程開始日。いずれも無ければ未設定（候補）。編集時は保存値を使用。純粋関数 `resolveInitialVisitDate` | 遠征の予定は開催日周辺に集中する。本日を初期値にすると毎回日付を直す手間が生じ、誤って本日で保存する事故も招く |
| D-192 | 新規予定の開始時刻の初期値を、同日タイムラインで直前にある「時刻付きの実予定」の終了時刻にする。メモ・時刻なし項目は読み飛ばす。直前実予定に終了時刻が無い／前予定が無ければ未設定。現在時刻・固定時刻は入れない。保存時の自動連動はしない。純粋関数 `resolveInitialStartFromPrevious` | 予定は前の予定の終了後から始めることが多く、初期値があると入力が速い。ただし開始のみ・前予定なしで安易に埋めると誤りになるため未設定に倒す |
| D-193 | `ItineraryEntryKind.note` を時間整合の全警告（時刻重複・移動時間不足・間に合わない可能性・余裕不足・leg自動前後接続・開始時刻の直前予定）から完全除外。`itineraryTightConnections` は実予定だけで判定（メモを読み飛ばし A→メモ→B は A-B で判定）、`placeItineraryLegs` の隣接連番からメモを除外、leg端点候補からメモを除外、`_conflictsWithTime` もメモを除外。メモの表示・日時入力・形式検証は維持 | メモは実際の訪問・移動ではないため、時間整合の警告対象にすると誤警告になる。表示や単体の形式検証は残し、「他予定との時間整合判定」だけ除外する |

### 検証状況（2026-07-07, Windows host / ASCIIパス `C:\Users\naman\StudioProjects\OshiTrip`）

- `dart format` / `dart analyze lib test integration_test` / `flutter analyze`: 本文の最終報告を参照。
- `flutter test`（単体+Widget）: 追加・更新した旅程テスト（`itinerary_json_test`「聖地」／`itinerary_phase2b_test`（点3/4/5/6の純粋関数）／`itinerary_editor_phase2b_test`（緯度経度非表示・座標保持・聖地選択・移動区間の日付欄非表示）／既存 `itinerary_timeline_test`・`itinerary_merged_timeline_test`・`itinerary_plan_tab_test` の是正）を含む結果は本文の最終報告を参照。
- **未実施（成功と報告しない）**: `flutter test integration_test`（実機/エミュレータ・adb 無し）、`supabase db reset` / `supabase test db`（Docker 無し）。`0015` マイグレーションは静的検証のみ（前方専用のCHECK差し替え・既存値を全許可）。実Postgres適用は未確認。

## Phase 2追補レビュー是正（2026-07-07, Claude Opus 4.8）

D-188〜D-193（計画機能の仕様変更）のレビューで見つかった2件を是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-194 | 移動区間(leg)の保存時、既存 departureAt/arrivalAt を消さない。端点・時刻を一切変更していない編集は既存の完全な日時を保持（運賃・所要時間・メモだけの編集で日時不変）。前後予定の日付が取れないまま時刻を「変更」した場合は保存を止め「前後予定の日付を設定してから時刻を変更してください」と案内。時刻の明示クリア時だけ null。新規/編集を区別。判定は純粋関数 `resolveLegTimestampsForSave`（`itinerary_schedule.dart`）へ集約し、TZ依存の時刻復元・変更判定だけを widget に残す | D-190で日付入力を廃止し前後予定から合成する設計にしたが、前後予定の日付が未取得のとき運賃だけ編集しても derived が null になり既存日時をnull上書きしていた（Highバグ）。変更有無で分岐し、確定できない時刻変更はサイレント削除せず保存を止める |
| D-195 | 訪問日の優先順位（現在表示日→前後予定→現場開催日→旅程開始日）を実画面へ接続。日別セクションに「この日に追加」ボタンを設け `contextDate=その日` を渡す。グローバル追加（右下＋）は `contextDate=null` で現場開催日→旅程開始日をフォールバック。開始時刻の直前予定も解決した日付内の予定から取る。共通導線 `openSpotEditorWithDefaults`（`plan_tab.dart`）に集約 | `resolveInitialVisitDate` に currentDay/adjacentDate を渡していなかったため、UI上は常にフォールバック（現場開催日）になっていた（Medium）。日別導線から currentDay を渡すことで「2日目から追加→2日目が初期値」を実操作で成立させる |

### 検証状況（2026-07-07, Windows host / ASCIIパス）

- `dart format` / `dart analyze lib test integration_test` / `flutter analyze`：本文の最終報告を参照。
- `flutter test`：追加/更新テスト（`itinerary_phase2b_test` の `resolveLegTimestampsForSave` 6件・`itinerary_editor_phase2b_test` の日別追加Widgetテスト）を含む結果は本文の最終報告を参照。
- **未実施**: `flutter test integration_test`（実機/エミュレータなし）、`supabase test db`（Dockerなし）。

## Phase 3前調整（2026-07-07, Claude Sonnet 5）: 公演種別・交通手段の選択式化・思い出段階名

新featureブランチ `feat/memory-album-and-enums` で、次Phase前の調整として実装。
本セッションでは以下3件を完了（メモ複数化・写真/アルバムは別途未実装, 下記報告参照）。

| # | 判断 | 理由 |
|---|---|---|
| D-196 | 思い出記録画面の段階名を「終演直後 / 翌日 / 後日」→「終演直後 / 終演後 / 後日」へ変更。「終演後」に MC・当日メモ / 座席・見え方 / セトリ を置く。これは入力画面の**段階名・説明の変更**であり、思い出移行の日時判定は変えない | 「翌日」だと当日中に書けないような誤解を招く。「終演後」なら終演後いつでも書ける意図が伝わる。ドメイン/DB/移行判定には影響しない表示のみの変更 |
| D-197 | 公演種別 `genbas.performance_type` を自由入力から**選択式の安定コード**（11種の `PerformanceType` enum）へ変更。内部値は日本語でなくコード。変換不能な既存自由入力は `other` とし、元文字列を新設 `genbas.performance_type_other` に保持して失わない。Drift v10 + Supabase 0016 で既存値を CASE で変換（既知語→コード・未知→other＋原文退避）。移行後は CHECK でコードのみ許可 | 自由入力は表記ゆれで集計・フィルタが困難。安定コード＋日本語ラベルで表示は保ちつつ機械処理可能に。移行で原文を失わないことを最優先（other_text へ退避）。addColumn は `_hasColumn` で冪等化し、最新スキーマから user_version だけ戻すテストでも二重追加で落ちない |
| D-198 | 交通手段 `transports.method` を同様に**選択式の安定コード**（11種の `TransportMethod` enum）へ変更。`transports.method_other` を新設。Drift v11 + Supabase 0017 で変換（「JR/夜行バス」等→コード・未知→other＋原文退避）。一覧・詳細・計画取り込み表示は `Transport.methodDisplay`（other は補足自由入力）で日本語ラベル化 | 公演種別と同方針。計画（旅程）タブの交通取り込み表示も同じラベルを共有 |

### 検証状況（2026-07-07, Windows host + Android emulator）

- `dart format` / `dart analyze lib test` クリーン、`flutter test` **650件 全パス**（新規: 公演種別4・交通手段6・思い出段階1 を含む）。
- Drift migration（v9→v10→v11）は file-backed 再open の移行テストで検証済み（原文保持を含む）。
- **未実施**: `supabase test db`（0016/0017 の pgTAP。Docker 未導入で `supabase start` 不可。SQL は静的検証のみ）。
- **本セッション未実装（スコープ）**: メモ複数登録化（点1）、グッズ/場所/食べもの写真・思い出アルバム（点5〜8）。データ設計が広範（MemoryPhoto 拡張・RLS・画像ストア・アルバム画面）で、緑を保ったまま完了できる単位に収めるため次セッションへ分割。

## Phase 3前調整（続き, 2026-07-07, Claude Sonnet 5）: メモの複数登録化

| # | 判断 | 理由 |
|---|---|---|
| D-199 | 現場メモを「現場×種類ごと1件」から**複数可**へ変更（§7.7）。`GenbaMemo` に `title`/`sortOrder` を追加、`MemoCategory.other`（「テンプレートなし」）を追加。DB は Drift v11→**v12**（title/sort_order 追加＋{genba_id,category} ユニーク制約をテーブル再作成で撤廃、既存メモの title を種類名で初期化）、Supabase **0018**（同方針＋category CHECK に other 追加）。Repository は「種類ごと1件」の削除ロジックを撤去してID単位upsertにし、`reorderMemos`（sort_order のみ更新）を追加。UI はテンプレート選択で追加・一覧・編集・削除・上下並び替え。タイトルと本文が空のメモは保存しない | 物販や集合場所など同種のメモを複数残したい要望に対し、1件制約が邪魔だった。テンプレートは入力補助に留め、保存はID単位で行うことで複数化・並び替え・同期を素直に実現。SQLite はユニーク制約を後から落とせないため、既存メモを失わないテーブル再作成で移行する。addColumn は `_hasColumn` と同様に冪等化（テーブル再作成は最新スキーマからの onUpgrade でも安全） |

### 検証状況（メモ複数化）

- `dart analyze lib test integration_test` クリーン、`flutter test` **653件 全パス**（新規: `genba_memo_test`（reorder／同一種類複数／v11→v12 移行）、更新: `repositories_test`（ID単位upsert＋複数保持）、`genba_detail_tabs_test`（メモタブ空状態）を含む）。
- メモUIのフルフロー Widget テストは、現場詳細の NestedScrollView（pinned AppBar がセクションヘッダを隠す）レイアウト都合でヒットテストが安定しないため見送り、複数化・並び替え・移行・ID単位upsert・空メモ非保存の各挙動はデータ層テストで担保した。
- **未実施**: `supabase test db`（0018 の pgTAP。Docker 未導入）。

## Phase 3前調整（続き, 2026-07-08, Claude Haiku 4.5）: 思い出アルバム データ基盤（点5〜8）

| # | 判断 | 理由 |
|---|---|---|
| D-200 | 思い出写真へアルバム分類・関連項目を追加し、写真の保存元を `MemoryPhoto` に一本化（§8.4）。`MemoryPhoto` に `albumCategory`（event/goods/visited_place/food）・`subjectType`（goods/visited_place, nullable）・`subjectId`（nullable）を追加。DB は Drift v12→**v13**（3列を冪等 addColumn で追加＋既存写真を `album_category='event'` へ移行）、Supabase **0019**（同3列＋分類/種別 CHECK＋`(genba_id,album_category)`/`subject_id` 索引）。Mapper でコード⇄enum を相互変換。Repository は写真 upsert 時に「関連項目（グッズ/行った場所）が同一 owner+genba に実在する」ことを検証し、孤立 `subject_id` を拒否（`_subjectExists`）。`MemoryBundle` に `sortedPhotos`/`photosInAlbum`/`photosForSubject`/`coverPhoto` を追加 | 写真をグッズ・場所・食べものへも付けたい要望に対し、画面ごとに画像を複製すると同期・削除・容量が破綻する。単一テーブル＋緩い参照（`subject_id` に FK を張らない）で「項目を消しても写真はアルバムへ残す」既定を素直に満たし、分類はコード化して SQLite/Postgres 双方で移行できる。過去 migration は変更せず前方専用で追加 |

| D-201 | 思い出アルバム UI と写真添付（点5〜7）。新規 `memory_album_screen.dart`（分類チップ＝すべて/当日/グッズ/行った場所/食べもの・各件数、正方形グリッド `SliverGridDelegateWithMaxCrossAxisExtent`、表紙バッジ、写真タップでボトムシート→関連元導線、分類別の空状態）。`memory_edit_screen.dart` は汎用 `_ItemsWithPhotosEditor` を導入し、グッズ／行った場所／食べものを名前＋写真サムネイルで編集、写真添付ボタンを各項目に付与。「行った場所・食べたもの」統合欄を **行った場所（category=spot）** と **食べたもの（category=food）** の2セクションへ分割。項目削除時に写真があれば「アルバムに残す（既定・FilledButton）／写真も削除／キャンセル」を確認。`memory_controllers.dart` の `addPhoto` に `albumCategory`/`subjectType`/`subjectId` を追加（画像コピー失敗・DB失敗時の孤立ファイル掃除は既存境界を継承）。導線は現場詳細の SliverAppBar アクションと `/memories/:id/album` | 写真を「どの入力から付けたか」で分類しつつ実体は一本化することで、同期・削除・容量を破綻させずアルバムを提供。削除時の既定を「残す」にして、うっかり写真を失わないようにする。食べものと場所は種別が違うだけで実体は `VisitedPlace` のため、UI 分割＋既存 `category` 流用で後方互換を保つ |

### 検証状況（アルバム: データ基盤＋UI）

- `dart analyze lib test integration_test` クリーン、`dart format` 差分なし、`flutter test` **663件 全パス**、`git diff --check` クリーン。
- 新規/更新テスト: `memory_album_test`（アルバム分類/関連項目/表紙のドメイン整理・v12→v13 移行で既存写真が event へ移行し消えない）、`repositories_test`（関連項目に紐づく写真の owner+genba 実在検証: 実在しない subject は拒否・実在すれば保存／**関連項目を削除しても写真はアルバムへ残る**）、`memory_album_screen_test`（分類チップの件数表示・絞り込み・空状態・**320pt幅×文字200%でのオーバーフロー無し**）、`memory_edit_stages_test`（行った場所/食べたものの分割表示）。
- **写真添付・削除確認のフルフロー Widget テスト**は ImagePicker のプラットフォームチャネル依存のため見送り、写真リンクの検証・分類フィルタ・分割表示・実在検証・削除時の残存はデータ層＋表示テストで担保した。追加中心・後方互換で既存の写真・思い出を消さない。
- **未実施**: `supabase test db`（0019 の pgTAP。Docker 未導入）。integration_test は本機能専用シナリオが無く、既存スイートは Windows デスクトップでのプラグイン（sqlcipher/image_picker/supabase）依存が重いため未実行（unit/widget 663件で担保）。

## Phase 3前調整（レビュー指摘対応, 2026-07-08, Claude Haiku 4.5）: アルバム3件修正

| # | 判断 | 理由 |
|---|---|---|
| D-202 | **[High] 写真と関連項目の削除を原子的にする**。UI で写真を1枚ずつ消す方式を撤廃し、Repository に `deleteSubjectWithPhotos`（写真メタデータ削除＋項目削除＋Outbox 登録＋画像削除キュー積みを**同一トランザクション**、途中失敗で全ロールバック）と `deleteSubjectDetachingPhotos`（アルバムに残す＝写真行・ファイルを消さず関連 subjectType/subjectId のみ解除し album_category は維持）を追加。画像ファイル削除は DB トランザクションと分離し、新テーブル `pending_image_deletions`（Drift **v14**）＋`ImageStore.deleteRefStrict`（失敗を握りつぶさない）で再試行キュー化。DB 削除後のファイル削除失敗は無視せず試行回数・理由を記録して残す | 途中失敗で写真だけ・項目だけが消える不整合を排除する。DB 整合はトランザクションで、ファイル削除は失敗しても後で再試行できるキューで補償することで、「成功していない処理を成功表示しない」を満たす。「残す」は既定で写真・ファイルを保全し、関連解除で分類だけ維持する |
| D-203 | **[Medium] アルバムから当日の写真を直接追加**。`MemoryAlbumScreen` に拡張FAB「写真を追加」（albumCategory=event / subject なし）。二重タップは `_adding` フラグ＋`onPressed:null` で防止、キャンセルは何も保存しない、取り込み・DB保存失敗の後始末は controller が担う（既存の孤立ファイル掃除を継承）。autoDispose の途中破棄を防ぐため `memoryEditControllerProvider` を build で watch。画像選択は注入可能（`pickImagePath`）にしてアルバム画面経由の Widget テストで pick→保存→即時表示（すべて/当日）を検証 | 記録画面を経由せずアルバムから直接足せる導線が要望。event 固定で subject を持たせないことで不変条件を自然に満たす |
| D-204 | **[Medium] 写真分類と関連先の不変条件を純粋関数化し二重で強制**。ドメインに `memoryPhotoShapeError`（event=subject無 / goods=goods+id / visited_place=visited_place+id(spot) / food=visited_place+id(food) / 関連解除=両方null を許可、片方だけ・種別不一致・event+subject を拒否）を追加し、Repository は形状＋実在＋owner/genba＋対象 category(spot/food) を検証。Supabase は **0020** で検証トリガ `enforce_memory_photo_subject`（**security invoker**・`search_path` 固定）を追加し、直接 INSERT/UPDATE・apply_mutation 全経路で同条件を強制（RLS だけに依存しない）。pgTAP 負例 `0011` を追加 | 分類と関連の不整合（別owner/別genba/category不一致/孤立参照）をローカルとサーバーの双方で塞ぐ。トリガは definer ではなく invoker とし owner/genba を明示比較することで、RLS バイパス文脈でも越境参照を成立させない |

### 検証状況（レビュー3件修正）

- `dart format` 差分なし、`dart analyze lib test integration_test` クリーン、`flutter test` **677件 全パス**、`git diff --check` クリーン。
- 新規/更新テスト:
  - Issue1（`repositories_test`）: 3枚＋グッズ一括削除成功／2枚目失敗で全ロールバック／項目削除失敗で写真残存／Outbox失敗で全ロールバック／ファイル削除失敗が再試行対象（attempts・lastError 記録）／「アルバムに残す」で写真行・ファイル保全＋関連解除。失敗注入は `deleteFailStage` シームで各ステージを実経路で検証。
  - Issue2（`memory_album_screen_test`）: アルバムFABから追加→すべて/当日へ即時表示（event・subject無）／キャンセルで無保存／二重タップで1枚のみ／FABの a11y ラベル・320pt×200%可視。
  - Issue3（`memory_album_test` ドメイン＋`repositories_test`）: 形状不変条件の許可/拒否マトリクス／food→spot・場所→food の category 不一致拒否／event+subject 拒否／別genba 参照拒否。
- **未実施**: `supabase test db`（0019/0020 の pgTAP。Docker 未導入で起動不可。CLI は有）。integration_test は本修正専用シナリオ無し・デスクトッププラグイン依存のため未実行（unit/widget 677件で担保）。
- **DB migration**: Drift **v14**（`pending_image_deletions` 追加のみ・既存不変）、Supabase **0020**（検証トリガ追加）。いずれも追加専用で過去 migration は不変。

## Phase 3前調整（再レビュー指摘対応, 2026-07-08, Claude Haiku 4.5）: アルバム2件修正

| # | 判断 | 理由 |
|---|---|---|
| D-205 | **[High] `memory_photos.subject_id` を text→uuid へ統一**（Supabase **0021**・前方専用）。参照先 `goods_items.id`/`visited_places.id` は uuid のため、0020 トリガの `id = new.subject_id` が uuid=text で `operator does not exist` になり得た。列を uuid にすることでトリガは **uuid 同士**で比較（文字列連結・動的SQL・キャスト回避はしない）。既存データ移行: NULL はそのまま／正しい UUID 文字列は uuid へ変換／不正な文字列は先に `subject_type`・`subject_id` を NULL へ戻して「関連解除済み」にしてから `alter … type uuid using subject_id::uuid`（クラッシュさせない・album_category と写真は維持・写真は消さない）。ローカル Drift(SQLite) は subject_id を TEXT のまま（uuid型なし・同期は文字列往復、`jsonb_populate_record` が uuid へ復元）。pgTAP `0011` は実検査数と `plan` を一致（**plan(17)**：UPDATE 正例と apply_mutation 正例を追加） | uuid 列同士の比較にすることが最も直截で、回避策（連結・動的SQL）を持ち込まない。不正既存値は写真を失わせず安全に関連解除する |
| D-206 | **[Medium] 画像削除キューの自動再試行**。`flushPendingImageDeletions` を認証確定時（起動・セッション復元・ユーザー切替）に `sessionSyncProvider` からバックグラウンド起動（`unawaited`＋sync/async 例外を握って認証フローを妨げない・UI をブロックしない）。owner スコープ・多重実行防止（`_flushingImages` ガード）・冪等（`deleteRefStrict` は対象無しでも成功）・自動再試行上限（`_maxImageDeletionAttempts=8` 以上は自動処理せず残す＝短時間の無限再試行を避ける）・1件失敗で他を止めない・別 owner のファイルに触れない。`local_data_purge`（アカウント削除／purge 再開）で対象 owner の `pending_image_deletions` を削除（実ファイルは `imageStore.purgeOwner` が owner 単位で全削除・他 owner のキュー/ファイルは残す） | 削除直後だけでなく後続の起動でも確実に片付ける。背景保守は失敗しても本流（認証・起動）を絶対に壊さない。ログアウト後に旧 owner の削除予定情報を放置しない |

### 検証状況（再レビュー2件修正）

- `dart format` 差分なし、`dart analyze lib test integration_test` クリーン、`flutter test` **684件 全パス**、`git diff --check` クリーン。
- 新規/更新テスト（Issue2）: `repositories_test`（成功行だけ消える／失敗行は attempts・lastError 増・残存／1件失敗でも他処理／別owner不干渉／多重実行安全／purge で対象owner キュー削除）、`image_deletion_retry_startup_test`（認証確定でキューを背景処理）。
- **subject_id 型**: 変更前 **text** → 変更後 **uuid**（Supabase）。ローカル SQLite は TEXT のまま。
- **pgTAP 実検査数**: **17**（`plan(17)` と一致）。event/goods/visited_place/food の保存・UPDATE正例・apply_mutation正例・各種負例（片方だけ/種別不一致/category不一致/別owner/別genba/存在しない）を含む。
- **未実施**: `supabase db reset` / `supabase test db`（0019/0020/0021 の適用と pgTAP。Docker 未導入で起動不可・CLI は有）。integration_test は本修正専用シナリオ無し・デスクトッププラグイン依存のため未実行（unit/widget 684件で担保）。
- **DB migration**: Supabase **0021**（subject_id を uuid 化・前方専用）。Drift 変更なし（SQLite は TEXT 継続）。過去 migration は不変。

## 旅程Phase 3（Google Maps Platform連携, 2026-07-08, Claude Haiku 4.5）

### Google公式仕様の確認記録（ADR-0010 §12・itinerary-plan-spec §8 の要求）

- **確認日**: 2026-07-08。
- **確認元**: Google Maps Platform 公式ドキュメント Place Details (New) の Field Mask とデータSKU階層
  （developers.google.com/maps/documentation/places/web-service/place-details ほか）。
- **採用 Field Mask（Place Details New）**: `id,displayName,formattedAddress,attributions`（`*` 禁止・本番 allowlist 強制）。
  - `id` / `attributions`: **Place Details Essentials (IDs Only)** 相当（最低コスト）。
  - `formattedAddress`: **Place Details Essentials** 相当。
  - `displayName`: **Place Details Pro** 相当。
  - → 名称＋住所を表示するため実質 **Pro SKU** に落ちる（設計上の許容。電話・URL・営業時間・写真・
    評価・レビュー・primary type・座標は要求せず Enterprise/Atmosphere に上げない）。
- **Autocomplete (New)**: session token（UUIDv4）で「複数 autocomplete ＋ 選択後の Place Details 1回」を
  1セッションとして課金する。候補選択せず離脱した場合は session を終了（未課金セッション化）。3文字以上・
  debounce・会場周辺 location bias で件数を抑制する（itinerary-plan-spec §8.2）。
- **キャッシュ制限・帰属**: Place ID 以外の Google Places コンテンツ（名称・住所・写真等）を API 代替目的の
  ユーザー横断恒久キャッシュへ保存しない。永続化する Google 識別子は原則 Place ID のみ。表示時は Google Maps
  と第三者帰属を同一表示コンテナで示す（`attributions`）。料金額はコードへ固定しない（本記録の日付で四半期
  ごとに再確認する, ADR-0010 §12）。
- **注意**: SKU 区分・フィールド分類は Google 側で変更され得る。リリース前と四半期ごとに本記録を更新する。

### D-207: 外部地図境界（PlacesGateway）とオフライン検証範囲の段階実装

| # | 判断 | 理由 |
|---|---|---|
| D-207 | 旅程の地図/検索を地図事業者非依存の境界 `PlacesGateway`（domain）に置く。Google 未設定・障害・上限時は型付き `UnavailableFailure`（新設）を返し、手動旅程フォールバックを妨げない。Google 連携は既定で無効（`GoogleMapsConfig.enabled=false`）とし Phase 2 の全フローを緑に保つ。Field Mask は allowlist 定数＋純粋関数で検証し `*`・非許可フィールドを拒否。Place ID → Google Maps URL はアプリ側生成（追加 Details 取得なし）。名称・住所は一時 DTO 状態に留め、永続 entity へ自動転記しない | ADR-0010/spec の「境界分離・手動フォールバック必須・キー秘匿・Google コンテンツ非恒久化」を、外部インフラ（Edge Function/鍵/実機）に依存せず**オフラインで検証可能**な単位から実装する。本環境は Docker・Google 鍵・モバイル実機が無く、Edge Function 実デプロイ／実 Places 呼び出し／ネイティブ地図描画／iOS 実機検証は各環境で別途行う（本コミットでは成功扱いにしない） |
| D-208 | Autocomplete (New) の検索制御を純粋な `PlacesSearchController`（application）に置く。3文字以上・debounce(450ms)・stale応答破棄・1検索セッション1 UUIDv4 token（選択 Details まで同一）・**完了/中断後の token 再利用禁止**（次クエリで新規発行）・結果なし/利用不可/失敗→手動フォールバック可。token 値は UI/ログへ出さない。ネットワークは `PlacesGateway`、token 生成は注入し `fake_async` で全経路を検証 | セッション課金の正しい束ね（複数 autocomplete＋1 Details＝1課金）と無駄呼び出し抑制を、UI/ネットワーク非依存の状態機械として先に確定・検証する |
| D-209 | 権利確認済み共有施設基盤（Supabase **0022**）。`shared_facilities`（owner別下書き→pending→approved）。`data_origin` は `user_provided/facility_provided/open_data/licensed` の CHECK のみ（**'google' 値が存在しない＝Google 応答をそのまま出典にした共有登録を型/制約で不能化**）。承認（共有）は `rights_basis` 必須（テーブル CHECK＋トリガ）。承認/却下は service role のみ（一般ユーザーの自己承認をトリガで拒否, security invoker・search_path 固定）。RLS は「本人の下書き＋承認済みは全認証ユーザー閲覧」。Google Place ID は重複照合キーとして保持可（名称・住所の権利根拠にはしない）。Dart 側に同一不変条件の純粋関数 `sharedFacilityInvariantError` と `FacilityModerationStatus` を用意。pgTAP `0012`（plan(9)）を記述 | 「Google 由来を共有マスタへ昇格させない」を型・制約・トリガ・RLS の多層で担保する。ローカル下書きの Drift/Outbox 同期とモデレーション UI は後続増分（本増分はスキーマ＋サーバー強制＋不変条件まで） |

| D-210 | 地図モードの座標・外部リンク・ピン選定を純粋関数（`itinerary_map_links.dart`）に置く。`spotHasMapPin`（**手動座標が両方揃うときだけ**ピン。地図のためだけに座標を追加取得しない）、`spotGoogleMapsUrl`（**Place ID→手動座標→名称検索**の優先で既存保存値だけから URL 生成。追加 Places/Details/Routes 取得なし）、`partitionSpotsForMap`（座標あり=ピン／座標なし=一覧、入力順維持）。座標なしスポットは一覧＋外部地図導線で扱う（§5） | ネイティブ地図（`google_maps_flutter`）の描画は実機依存で本環境では検証不可のため、地図ビューが消費する**データ/リンク層を先に純粋関数として確定・テスト**する。地図ウィジェット埋め込み・モード切替 UI・iOS bundle ID 制限は実機環境の後続増分（見せかけUIは追加しない） |

| D-211 | Places プロキシ Edge Function（`supabase/functions/places-proxy/`）＋費用/レート基盤（Supabase **0023**）。Web Service 用 Google キーはサーバー env のみ（アプリ非埋め込み, ADR-0010 §3）。関数は認証（platform verify_jwt＋getUser）・ユーザー別レート制限（`places_rate_limit`/RPC）・Field Mask allowlist（`*`/非許可拒否・`policy.ts`）・timeout・Google エラーの型付き変換・kill switch（env）・ログ秘匿（`safeLogMeta` のみ／検索文・住所・座標・Place ID を出さない）・費用集計（`api_usage_daily`/RPC・**件数のみ**）を強制し、**共有DBへ一切書き込まない**。純粋方針は `policy.ts` に分離（Dart 側 allowlist と同一許可集合）。集計/レート表は service role のみ（RLS＋execute 権 revoke）。pgTAP `0013`（plan(6)）。setup.md に日次クォータ・予算通知・キー分離の手順を追記（料金額はコードへ固定しない） | セキュリティ境界（キー秘匿・認証・レート・allowlist・kill switch・ログ秘匿・費用可視化）を1関数に集約する。本環境は Deno/Supabase/Docker 無しで**未デプロイ・未実行の成果物**（実行検証は各実環境。allowlist の中核は Dart 側テストで担保） |

### D-212: 旅程Phase 3 レビュー指摘4件（c8a99cc）の修正

Google公式仕様の再確認: **2026-07-08**、`attributions[]` は `{provider: string, providerUri: string}` の配列
（developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places）。Place Details でセッション
終了・終了後の token 再利用禁止（同 web-service/place-session-tokens）。

| # | 判断 | 理由 |
|---|---|---|
| D-212a（High） | 共有施設のモデレーション境界を RLS とトリガの**両方**で強制（Supabase **0024**）。UPDATE は USING（本人の draft/pending のみ）＋WITH CHECK（結果も draft/pending）で、approved/rejected を対象外にし approved/rejected への変更を拒否（pending→draft の差し戻しは許可）。DELETE は本人の draft のみ。トリガは一般ユーザー（auth.uid() 非 null）が OLD=approved/rejected の行を変更することと NEW を approved/rejected にすることを拒否。承認/却下・approved の修正は service role のみ。pgTAP `0012` を **plan(16)** へ拡張（投稿者は自 draft 更新/削除可・approved は更新/差し戻し/削除不可・service は approved 管理可・他者は approved 閲覧のみ） | RLS だけ／トリガだけの単一防御を避け、承認済み共有データを投稿者が壊せないようにする |
| D-212b（Medium） | `PlacesSearchController.select` の二重実行・token 再利用防止。session token を**通信完了を待たず同期的に消費**（session 終了）。選択中（`isSelecting`）の2回目は Google を呼ばず `OperationInProgressFailure`。Details 失敗でも同 token を再利用しない（次クエリで新 token）。abandon/dispose 後に完了した Details 結果は `_selectEpoch` 比較で採用しない。`isSelecting` を state で UI へ公開。fakeAsync で二重タップ・失敗後の新 token・中断無効化・進捗を検証 | Google 公式「Place Details でセッション終了・再利用禁止」に従い、1 token=Details 最大1回・二重課金/二重採用を防ぐ |
| D-212c（Medium） | 帰属を構造化型 `PlaceAttribution{provider, providerUri: Uri?}` に変更（`PlaceDetails.attributions: List<PlaceAttribution>`）。純粋変換 `parsePlaceAttributions`（provider 必須・空/巨大/非文字列/想定外は除外、providerUri は**有効な https のみ**・http/javascript/data・巨大・host 無しは null）。Edge も `sanitizeAttributions`（同条件）で Google 応答を透過せず許可フィールドだけへ変換。JSON 契約（`{provider, providerUri|null}`）を `PlaceDetails` へ明文化。純粋変換テスト追加 | 帰属を安全・確認付きで開ける形にし、危険 URI・巨大文字列・想定外オブジェクトを排除する |
| D-212d（Medium） | Google 呼び出し試行を漏れなく1回だけ費用計上。`increment_api_usage` を全検証・認証・レート通過後、**Google fetch の直前**に実行（timeout/通信例外でも計上済み。送らなかった不正リクエストは数えない）。集計 RPC 失敗時は**安全側で Google を呼ばず unavailable**。中核を `handler.ts`（fetch/RPC 注入）へ分離し Deno 単体テスト `handler_test.ts`（成功/4xx/5xx/timeout/例外/RPC失敗で1回だけ計上）を用意 | timeout を含む送信試行を保守的に計上し、費用の過少計上を防ぐ。RPC 失敗時は課金され得る呼び出しを避ける |
| D-213（High） | 共有施設の新規登録を **draft のみ**へ限定（Supabase **0025**）。INSERT の RLS `WITH CHECK` に `moderation_status = 'draft'` を追加（`created_by = auth.uid()` と両方必須）。トリガにも INSERT 専用チェックを追加し、一般ユーザー（`auth.uid()` 非 null）が draft 以外を指定した新規登録を拒否（RLS だけに依存しない多層防御）。service_role（`auth.uid()` が null な文脈）は制限せず、管理・移行での任意ステータス直接 INSERT を妨げない。draft→pending の正規申請（UPDATE, 0024）はそのまま維持。pgTAP `0012` を **plan(20)** へ拡張（draft INSERT成功／pending直接INSERT拒否／draft→pending更新成功／service_role直接INSERT成功の4件を追加） | 従来の INSERT ポリシーは `created_by` 一致のみを要求し、一般ユーザーが `moderation_status='pending'` を直接指定して draft 段階を飛ばせる抜け穴があった（`approved`/`rejected` は既存トリガで既に禁止済みだったが `pending` は未対応）。新規登録は必ず draft から始まる、という前提を RLS とトリガの両方で保証する |

### 検証状況（旅程Phase 3 オフライン増分）

- `dart format` 差分なし、`dart analyze lib test integration_test` クリーン、`flutter test` **729件 全パス**（D-212 追加: `place_attribution_test` 10・`places_search_controller_test` に二重タップ/失敗後新token/中断無効化/isSelecting の4件。D-213 は DB 専用のため Dart テストへの追加なし・729件は不変）、`git diff --check` クリーン。Phase 2 は無改変で緑。秘密情報のハードコード無し（Edge Function は全て env 参照）。
- **未実行（各実環境。成功扱いにしない）**: `deno check`／Edge Function 単体テスト `handler_test.ts`（**Deno 未導入**）、`supabase db reset`／`supabase test db`（0012〜0025 の pgTAP・**Docker 未導入・ローカル psql も無し**）、Edge Function 実デプロイ・実 Places 呼び出し・キー制限、ネイティブ地図描画・iOS 実機/bundle ID 制限。Field Mask allowlist・帰属変換・select セッション制御の中核は Dart 側テストで実行検証済み。pgTAP `0012`（plan(20)）は目視レビューのみで未実行
- **Edge Function（D-211）は未実行の成果物**: 本環境に Deno/Supabase/Docker/Google 鍵が無く、実デプロイ・実 Places 呼び出し・`supabase test db`（0013/0012/0022 の pgTAP）は各実環境で別途行う（成功扱いにしない）。Field Mask allowlist の中核挙動は Dart 側 `places_gateway_test` で実行検証済み。
- **実装済み（オフライン検証可能）**: Item1 境界＋型付き失敗＋設定（Google 既定無効）、Item4 クライアント側（Field Mask allowlist/`*`拒否・Place ID→URL）、Item3 Autocomplete 制御、Item6 共有施設スキーマ＋RLS＋モデレーショントリガ＋不変条件、Item5 地図リンク/ピン選定の純粋層。
- **未実施（要・各実環境。成功扱いにしない）**: `supabase db reset`/`supabase test db`（0022 の pgTAP `0012`。Docker 未導入で未実行）、Edge Function 実デプロイ・実 Places 呼び出し・キー制限（Supabase/Docker/Google 鍵）、ネイティブ地図描画・**iOS 実機/bundle ID 制限**（モバイル実機なし → iOS 不可時は macOS 実機確認項目を引き継ぎに明記）。
- **未着手（後続増分）**: Item2/7 Edge Function 成果物＋費用集計、Item5 地図ウィジェット埋め込み＋モード切替 UI、共有施設のローカル下書き Drift/Outbox 同期＋モデレーション UI、実ゲートウェイ（HTTP）接続。**Routes(Phase 4) 未完のため旅程 MVP 全体は完成扱いにしない**（ADR-0010・プロンプト完了条件）。

## 旅程Phase 4（Google Routes連携, 2026-07-09, Claude Sonnet 5）

### Google公式仕様の確認記録（本セッションで確認、四半期ごとの再確認要件, ADR-0010 §12）

- **確認日**: 2026-07-09。
- **Field Mask**（developers.google.com/maps/documentation/routes/choose_fields、
  .../reference/rest/v2/TopLevel/computeRoutes）: `routes.duration`,
  `routes.distanceMeters`, `routes.localizedValues.transitFare`,
  `routes.legs.steps.transitDetails.transitLine.{name,nameShort,vehicle.type}`,
  `routes.legs.steps.transitDetails.headsign`,
  `routes.legs.steps.transitDetails.stopDetails.{departureStop,arrivalStop}.name`
  が有効パス。polyline系（`routes.polyline.encodedPolyline` 等）は要求しない
  （§6.2 の最小範囲。本Phaseは地図描画・経路線を扱わない）。
- **SKU/料金**（.../routes/usage-and-billing、2回一致取得で確認）: Compute Routes
  は Essentials/Pro/Enterprise の3層。"Essentials: 基本機能・中間waypoint最大10"、
  "Pro: `TRAFFIC_AWARE`/`TRAFFIC_AWARE_OPTIMAL` route modifier使用時"、
  "Enterprise: two-wheel routing等の高度機能使用時"。→ `routingPreference` を
  一切送らず、travelModeに`TWO_WHEELER`を使わず`BICYCLE`のみ使用することで、
  対応4手段（徒歩/公共交通/車/自転車）は常に最安のEssentials SKUに収まる設計にした。
- **公共交通の制約**（.../routes/transit-route）: `departureTime`/`arrivalTime`は
  RFC3339 UTC必須。対応範囲は現在時刻から**過去7日〜未来100日**。中間waypoint
  **非対応**。運賃は「全ステップで算定可能な場合のみ」返る（nullable）。「時刻表は
  頻繁に変わり、先の予測の一貫性は保証されない」と明記。
- **キャッシュ制限**（.../maps-service-terms + 検索結果、既存 D-181 と整合を再確認）:
  緯度経度は最長30日でキャッシュ可、Place IDのみ無期限。**それ以外の内容
  （所要時間・距離・路線・運賃・経路概要）は永続キャッシュの許可が確認できない**。
  既存方針（Googleライブ応答は一時DTOのみ、永続entityへ暗黙変換しない）を維持する
  根拠として再確認した。
- **帰属**（.../routes/policies）: Google Mapに表示する場合を除き「Google Maps」
  ロゴまたは文字列を結果の近くに表示する必要がある。Routes APIの応答自体には
  Places の `attributions[]` のような帰属フィールドは含まれない（表示ポリシー上の
  要件であり、API応答の一部ではない）。

| # | 判断 | 理由 |
|---|---|---|
| D-214 | プレミアムentitlementを最小テーブル `user_entitlements`（owner_id主キー・`premium_routes_live boolean default false`）で実装する。課金・購入フロー自体はこのPhaseでも実装しない（spec §14.4「現時点では課金制御を実装せず」）。RLSは本人SELECTのみ、INSERT/UPDATEポリシーは作らない（一般ユーザーは自己付与不可・service_role限定）。Edge Functionは`has_premium_routes_entitlement` RPCでサーバー側検証し、クライアントの premium 主張を信用しない | タスクの完了条件「entitlementをクライアントだけで偽装できない」を満たすには、購入フローが無くても「サーバー側で強制する」ゲート機構自体が必要。既存の課金UI非実装方針（§14.4）と、entitlement強制インフラ自体は別物と整理した。**【現在はD-232で運用変更】** `user_entitlements` テーブル・`has_premium_routes_entitlement` RPC・強制インフラは**温存**するが、現仕様では entitlement 検証を既定で呼ばない。検証は Edge Function `ROUTES_REQUIRE_PREMIUM=true`（既定 false）の環境でのみ実行する（アプリに課金導線が未整備のため経路取得を全ユーザーへ開放） |
| D-215 | Google Routesのライブ結果を`_LegEditor`の手動欄へ自動コピーする機能は作らない。ライブ結果は`route_live_panel.dart`の閲覧専用パネルにのみ表示し、ユーザーが値を残したい場合は目視で入力し直す | Places実装（D-178/D-179）が「Google応答を自動コピーせず、ユーザーが独立入力した値のみuser_providedとして保存する」を徹底しているのに合わせた。コピー導線自体が「暗黙の永続保存」に近づくリスクを避ける。Google Routesの応答内容（所要時間・路線・運賃等）はGoogle公式規約上、緯度経度以外の恒久キャッシュ許可が確認できないため、`ItineraryLeg`（永続entity）へ自動的にも手動ボタン経由でも書き込まない設計にした |
| D-216 | 共有概算経路（spec §12.6 `route_estimates`）は、Phase 3の`shared_facilities`と同じ理由でスキーマ・不変条件・サーバー強制（`shared_route_estimates`, draft-only insert・承認済みは投稿者変更不可）までとし、クライアント側の投稿・閲覧UIは後続増分とする。タスク項目3の「保存済み概算経路を優先しGoogleを呼ばない」という中核動作は、既存`itinerary_legs`（1計画内でorigin/destination entry対ごとに一意な行）の`value_origin`/`representative_time_bucket`/`is_stale`で機能的に充足する。新規クロスユーザーテーブルが無くても「保存済み優先→明示操作のみGoogle」の動作は成立する | D-209の前例（shared_facilitiesもスキーマ＋不変条件のみで、クライアント下書き同期・モデレーションUIは後続増分と明記）を踏襲し、本Phaseで新規に大きな共有マーケットプレイス機能を先行実装しない（プロンプトの「このPhaseより後の機能を先行実装しない」を遵守） |
| D-217 | Google Routesの経路取得は**登録スポット↔スポットの区間のみ**を対象にする。`ItineraryEntryOption`にspotId/googlePlaceId/latitude/longitudeを追加し、transport/lodging/note端点はこれらが常にnullのため`RouteLivePanel`が自然に何も表示しない（`RouteEndpoint.hasLocation`がfalse） | タスクの依頼文自体が「登録スポット間の権利確認済み概算経路と、Google Routesによる最新経路の明示取得を実装してください」とスコープをスポット間に限定している。transport/lodging由来の区間は元データに座標を持たないため対象外は自然な帰結であり、既存の手動入力のみで運用する |
| D-218 | `isLegStale`（位置・順序・日時・手段変更でstale）を純粋関数として実装し単体テストで検証したが、タイムラインUI（`_LegRow`）へは接続しない。Googleライブ結果を`ItineraryLeg.cacheKey`/`source`へ書き込む経路が存在しない（D-215）ため、これらの列は本Phaseでは常にnull/manualのままであり、UIへ接続すると「一度もGoogle取得していない手動区間」まで常時stale表示になり誤解を招く | 将来Googleから書面許諾等を得てライブ結果の部分的永続化が許可された場合に備え、判定ロジック自体は確定・テスト済みにしておく。実際にcacheKeyが書き込まれるようになった時点でUI接続する（次Phase以降） |

### 実装対象（本Phaseで完成した範囲）

1. `RoutesGateway`（domain抽象、DTO、`UnavailableRoutesGateway`既定）＋
   `routesGatewayProvider`（Routes無効時は常に利用不可、Phase 1〜3を壊さない）。
2. 対応手段（徒歩・公共交通・車・自転車）。taxi/flight/otherはこの境界に到達しない
   （クライアント・Edge Function双方でtravelMode変換テーブルに存在しないため拒否）。
3. 概算経路とGoogleライブ結果の分離: `ItineraryLeg`の既存フィールド
   （value_origin/representative_time_bucket/last_verified_at/is_stale）が
   永続概算を表し、`RouteLiveResult`は一時DTO（`route_live_panel.dart`の画面状態
   にのみ存在、`upsertLeg`を一切呼ばない）。
4. 公共交通の制約: 過去7日〜未来100日の範囲外は`invalid_request`で拒否
   （Edge Function側）、中間waypoint非対応、運賃nullable、遠い未来（30日超）は
   UIで「最新ではない可能性」相当の注記を表示。
5. 再計算と重複抑止: `routeRequestFingerprint`＋`RouteRecalculationController`の
   single-flight（同一fingerprintの同時呼び出しはGoogle呼び出し1回）。呼び出しは
   「経路詳細を開く」「最新ルートを更新」の明示タップからのみ発生し、初期表示・
   並び替え・保存では一切呼ばれない（構造的に保証、widget/application両テストで検証）。
6. タイムラインへの移動区間表示は既存のまま（§5.4の間に合い判定・警告は無改変）。
   `route_live_panel.dart`が保存済み概算（非プレミアム含め常時閲覧可）＋
   Google帰属表示（「Google Maps」固定文言＋外部リンク）を追加。
7. 費用制御: `routes_rate_limit`（ユーザー別日次相当のレート制限）、Field Mask
   allowlist固定（Essentials維持）、権利確認済み概算経路ヒット時はAPIを呼ばない
   （明示操作のみ）、ルート最適化は実装しない。

### 検証状況（旅程Phase 4, 2026-07-09, Windows host / ASCIIパス `C:\src\OshiTrip`）

- `dart format lib test`: 差分なし。`dart analyze lib test integration_test`: クリーン。
- `flutter test`: **817件 全パス**（Phase 3までの729件 + 本Phase新規: domain
  `routes_gateway_test`15・`route_request_fingerprint_test`5・
  `representative_time_bucket_test`8・`route_staleness_test`5、application
  `route_recalculation_controller_test`6、data
  `routes_entitlement_repository_test`6・`routes_entitlement_migration_test`1、
  widget `route_live_panel_test`5、既存Drift v16マイグレーション影響分を含む）。
  widgetテストの1件（`route_live_panel_test`の非プレミアム検証）が実装バグ
  （expand操作が非プレミアムでも一度Google呼び出しを試み拒否されるだけの空振りを
  していた）を検出し、修正した（`_expanded`トグルの`isPremium`ガード追加）。
  Phase 1〜3の既存テストは無改変で全件green。
- **未実行（各実環境。成功扱いにしない）**: `deno check`／`handler_test.ts`
  （routes-proxy用、**Deno未導入**）、`supabase db reset`／`supabase test db`
  （0027の pgTAP `0014`、**Docker未導入・ローカルpsqlも無し**、静的レビューのみ）、
  Edge Function実デプロイ・実Google Routes呼び出し・Google Cloud側の日次クォータ/
  予算通知設定、entitlement付与の実運用（service_roleからのINSERT/UPDATE）、
  非プレミアム/プレミアム双方の実機E2E、ネイティブ地図描画（本Phase対象外）。
- **実装済み（オフライン検証可能）**: 上記「実装対象」1〜7の全項目。Field Mask
  allowlist・fingerprint・staleness判定・single-flight・entitlementゲート・
  transit時刻範囲判定の中核ロジックはDart側テストで実行検証済み。Edge Function
  （routes-proxy）は`places-proxy`と同型4ファイル構成で作成したが未実行の成果物。
- **旅程MVP判定について**: requirements.md §7.9は「Phase 4のRoutes完了までは
  旅程MVP完成と判定しない」としている。本セッションでPhase 4のコード実装・
  オフライン検証可能な範囲のテストは完了したが、Edge Function実デプロイ・実
  Google Routes呼び出し・pgTAP実行・entitlement付与の実運用・実機検証は本環境
  （Docker/Deno/Google鍵/モバイル実機いずれも無し）では行えていない。したがって
  「旅程MVP完成」を最終判定するのは、これらの実環境検証が完了した後とする
  （成功していない検証を成功と報告しない）。

## 旅程Phase 4 レビュー是正（2026-07-09, Claude Opus 4.8）

旅程Phase 4（Google Routes連携）のレビュー指摘5件を是正した。Google Routes応答を
許可なく共有DB／ItineraryLegへ永続保存しない方針（D-180/D-181/D-215）は維持する。

| # | 判断 | 理由 |
|---|---|---|
| D-219（修正1） | `RoutesGatewayImpl`（data層）と `SupabaseRoutesProxyTransport`（routes-proxy Edge Function 呼び出し）を新設し、`routesProxyTransportProvider`→`routesGatewayProvider` の2段で接続した。`env.googleRoutesAvailable == true` かつ Supabase クライアントありなら実 Gateway、無効・デモ・未設定・クライアント無しなら従来どおり `UnavailableRoutesGateway`。`RouteLiveRequest`→routes-proxy の JSON payload（origin/destination の placeId優先・座標フォールバック、travelMode の wire文字列、representativeDepartureUtc の UTC ISO8601）へ変換し、応答を `RouteLiveResult`（`requestedAt` は受信時刻をUTCで付与）へ変換。エラー `{error: kind}` は純粋関数 `routesProxyErrorToFailure` で型付き Failure へ変換（not_entitled→PermissionFailure／unauthorized→AuthFailure／rate_limited→NetworkFailure／invalid_request→ValidationFailure／unavailable→UnavailableFailure／timeout・upstream_error→NetworkFailure、kind不明時は status で概略判定）。TimeoutException・通信断は NetworkFailure。taxi/flight/other は送信せず ValidationFailure（非対応・費用制御, §6.1）。Google API キーはアプリに埋め込まず routes-proxy が保持（ADR-0010 §3） | Phase 4初版は `routesGatewayProvider` が常に `UnavailableRoutesGateway` を返すスタブだった（実 Gateway 未接続）。`SupabaseMutationTransport` と同じトランスポート seam を採用し、SupabaseClient 依存を `RoutesProxyTransport` へ閉じ込めることで、実 Gateway の payload 送出・エラー変換を Supabase 非依存で単体テストできる。ライブ結果は一時 DTO としてのみ返し、`ItineraryLeg`／共有DBへ書き込まない（D-215 維持） |
| D-220（修正2） | `RoutesEntitlementRepositoryImpl.refreshFromRemote()` の Supabase 取得に既存 `.withRemoteTimeout()` を付け、`TimeoutException` を `NetworkFailure` として扱うようにした（R8-C の通信タイムアウト方針に統一） | 初版は entitlement 取得にタイムアウトが無く、無期限ハングの余地があった。他の Repository（`_pullTable`／`SupabaseMutationTransport`）と同じ方針へ揃えた |
| D-221（修正3） | `RoutesEntitlementRepository.refreshFromRemote({bool Function()? isStale})` を追加し、`SessionRefresher` から `isStale` を渡すようにした。リモート取得後・ローカル書き込み直前に `isStale() == true`（別owner／世代交代／pause）なら、前owner の値を書かず成功扱いで中断する | 初版は `refreshFromRemote()` が `isStale` を受け取らず、認証切替と競合すると前owner の entitlement をローカルへ書き込む余地があった。他 Repository の pull（C-01 / H-02）と同じ「取得後・適用前チェック」に揃えた |
| D-222（修正4） | **共有概算経路（`shared_route_estimates`）のFlutter側再利用（検索・通常表示）は本Phaseでは未実装**とし、DB基盤（スキーマ・RLS・モデレーション・不変条件・pgTAP）までに留めることを明文化した。`docs/implementation-status.md`・`docs/follow-up-work.md`（項目21）へ「未実装」と明記し、**旅程MVPを完成扱いにしない**判定に反映した | クライアント側の共有再利用（owner境界・approvedのみ・data_origin/rights_basis確認つき）を今Phaseで新規実装すると「このPhaseより後の機能の先行実装」に当たる（D-216）。旅程内の「保存済み概算を優先」は各旅程の `itinerary_legs` で機能的に満たしており、クロスユーザー共有再利用は follow-up として分離。ステータス文書に反映して「未実装なら完成扱いにしない」を担保 |
| D-223（修正5） | `RouteLivePanel` で、公共交通の代表時刻が Google Routes の対応範囲（過去7日〜未来100日）外なら、**Edge Function を呼ぶ前に**案内文言（`route_range_notice`）を表示し、Google Routes を呼ばない。保存済み概算経路・手動入力は引き続き利用可能 | `resolveRepresentativeRequestTime` の `isOutOfSupportedRange`（既存の純粋関数）を UI へ接続し、範囲外リクエストで確実に失敗する API 呼び出し（＝無駄な課金試行）を未然に防ぐ。範囲判定は Edge Function 側でも二重に行う（多層防御） |

### 検証状況（旅程Phase 4 レビュー是正, 2026-07-09, Windows host / ASCIIパス `C:\src\OshiTrip`）

- `dart format` 差分なし、`dart analyze lib test integration_test` クリーン、
  `flutter test` **全パス**（本是正の新規テスト: `routes_gateway_impl_test`
  ＝payload送出・エラー変換・timeout・欠落フィールド耐性・非対応mode拒否・
  ライブ結果を永続保存しないこと、`routes_providers_test` ＝env有効/無効での
  Gateway選択・transport seam、entitlement の timeout/isStale、`route_live_panel_test`
  へ transit範囲外案内＝API非呼び出しを追加）。既存の Phase 1〜3 テストは無改変で緑。
- **未実行（各実環境。成功扱いにしない）**: 実 Google Routes 呼び出し・routes-proxy
  実デプロイ（**Deno/Docker/Google 鍵なし**）、`supabase test db`（pgTAP `0014`、
  **Docker 未導入**、静的レビューのみ）、entitlement 付与の実運用・実機E2E。
  実 Gateway の payload 送出・エラー変換・timeout・欠落耐性の中核は、トランスポート
  seam（fake transport）を使った Dart 側テストで実行検証済み。実 Supabase Functions
  への到達性・routes-proxy 側の認証/entitlement/レート/Field Mask 強制は各実環境で別途確認する。
- **旅程MVP完成判定**: 未完成。(1) 共有概算経路のFlutter側再利用が未実装（D-222）、
  (2) 実 Google Routes／pgTAP／実機検証が環境不足で未了。この2点が解消するまで
  旅程MVPは完成扱いにしない。

## 旅程Phase 4 残タスク整理（2026-07-09, Claude Opus 4.8）

Phase 4 の残タスク（共有概算経路の再利用・回帰テスト）を、既存実装を壊さず整理・
実装した。Google Routes ライブ応答を恒久保存しない／共有キャッシュ化しない方針
（D-180/D-181/D-215）は維持する。

| # | 判断 | 理由 |
|---|---|---|
| D-224 | 共有概算経路（`shared_route_estimates`）の**再利用の強制ゲートを純粋ドメイン層として先出し**した（`shared_route_estimate.dart`: `SharedRouteEstimate` DTO・`sharedRouteEstimateReuseError`・`parseSharedRouteEstimate`）。再利用の読み取りは必ず `parseSharedRouteEstimate` を通し、**approved のみ／data_origin は権利根拠4種のみ（'google' 等は型で表現不能＝弾く）／rights_basis 非空**を満たさない行を採用しない（多層防御。owner境界・approved可視性はサーバーRLSでも強制）。一方、**共有概算経路のUI表示（旅程スポット→施設ID解決→パネル表示）と読み取りRepositoryは本Phaseでも未実装**とし、次Phaseへ持ち越す | UIでの再利用は「旅程スポット↔施設ID↔共有経路」の突き合わせが必要で、施設ID解決には shared_facilities の Flutter クライアント（D-209で次Phase送り・現状 lib/ に一切存在しない）が前提になる。これを今Phaseで新規実装すると「後Phase機能の先行実装」に当たるため、**shared_facility.dart（D-209）と同じ「純粋な強制ゲートを先に出し、消費側（Repository/UI）は次Phase」方針**を踏襲。旅程内の「保存済み概算を優先」動作は各旅程の `itinerary_legs` で既に満たしており、通常表示で Google Routes を自動呼び出ししない不変条件（明示タップのみ）は route_live_panel で維持されている |
| D-225 | `RoutesEntitlementRepositoryImpl` の Supabase 取得を `EntitlementFetcher` seam（`fetcherResolver`）へ切り出し、`refreshFromRemote` の全経路（timeout→NetworkFailure・取得成功→書込み・行なし→premium=false・認証切替 isStale→書込み抑止）を実 Supabase 接続なしで単体テストできるようにした。実クエリ＋`.withRemoteTimeout()` は providers.dart のクロージャへ移し、デモ/未ログインは fetcher=null で no-op | 初版は取得が直接 `client.from(...)` で、`client` を差し替えられず timeout/成功/失敗の回帰テストが書けなかった。`ConflictResolver.fetchRemoteRows` と同じ関数seamにして、タイムアウト・認証切替の各不変条件をテストで固定した。通信タイムアウトは provider のクロージャで全通信に適用され続ける（R8-C 方針を維持） |

### 検証状況（旅程Phase 4 残タスク整理, 2026-07-09, Windows host / ASCIIパス `C:\src\OshiTrip`）

- `dart analyze lib test integration_test` クリーン、`dart format` 差分整形済み、
  `flutter test` **全パス**。本セッション新規/更新テスト:
  `shared_route_estimate_test`（再利用ゲート・防御的パース: approved限定／
  data_origin4種・'google'却下／rights_basis必須／非対応mode却下／欠損耐性）、
  `routes_entitlement_repository_test`（fetcher経路の timeout→NetworkFailure・
  取得成功書込み・行なし・isStale書込み抑止）、`routes_gateway_impl_test`（payload に
  Google APIキーを含めない）。既存 Phase 1〜3・Phase 4 初版テストは無改変で緑。
- **レビュー観点の担保**: (a) Google APIキーはアプリ非埋め込み（gateway payload に
  キー無しをテスト、Web Service キーは routes-proxy が env で保持）。(b) Google Routes
  ライブ結果は DB 非保存（panel テストで itinerary_legs 空を確認・共有DBへも書かない）。
  (c) 通信タイムアウトは routes-proxy transport（functions.invoke）・entitlement fetcher
  の双方で `.withRemoteTimeout()`。(d) 認証切替時は entitlement isStale で前owner値を
  書かない（テスト済み）。(e) 無駄なGoogle呼び出し防止＝明示タップのみ・single-flight・
  transit範囲外は呼ばない（テスト済み）。
- **未実行（各実環境。成功扱いにしない）**: 実 Google Routes 呼び出し・routes-proxy
  実デプロイ（**Deno/Docker/Google 鍵なし**）、`supabase test db`（pgTAP `0014`、
  **Docker 未導入**、静的レビューのみ）、共有概算経路 UI 再利用の実機E2E（施設ID解決＝
  shared_facilities クライアントが次Phase未実装のため、そもそも UI 導線が無い）。
- **旅程MVP完成判定**: 変わらず**未完成**。共有概算経路の UI 再利用（施設ID解決＋表示）と
  実 Google Routes／pgTAP／実機検証が未了。強制ゲート（D-224）と回帰テストは整備済み。

## 旅程Phase 5 依存ギャップ＋共有データ基盤（2026-07-09, Claude Opus 4.8）

Phase 5（旅程の共有・共同編集・通知・最終品質）の前提基盤を確認した結果、**現場共有・
通知基盤はドメイン型のみのスタブで未実装**（`genba_shares` 表・ShareRepository実装・ロールRLS・
NotificationScheduler実装・配線が一切無い）と判明した。プロンプトの「前提基盤が未完成なら
見せかけUIを作らず、依存不足を報告して先に必要な基盤を完成させる」に従い、Phase 5本体には
着手せず、**共有の必要基盤（保守的スライス）** を実装した。

現行セキュリティは3層すべて単一owner前提（各表RLS `owner_id=auth.uid()`／子owner トリガ
`enforce_genba_child_owner`／`apply_mutation` の insert時 owner矯正）で、Storageもパス先頭に
ownerを埋める。**非ownerが書ける「ロール型RLS」への拡張はこの3層＋Storage全部の書き換え**に
なり、かつ本環境は **Docker/pgTAP が無く実行検証できない**（`docs/setup.md`）。owner隔離(C-01)を
盲目で書き換えるのは高リスクなため、ユーザー合意のもと保守的スライスを採った。

| # | 判断 | 理由 |
|---|---|---|
| D-226 | Phase 5 前提基盤として **共有データ基盤（genba_shares）のみ**を実装する。`genba_shares` 表（role editor/viewer＋項目grant4種＋version）・**owner 管理 RLS**（owner は自共有を CRUD／grantee は自分に共有された行を SELECT のみ・書込不可、`user_entitlements` の split-policy 先例）・子owner トリガ＋CHECK・`apply_mutation` allowlist 登録（版CAS流用）・Drift v17・ShareRepository実装＋owner スコープ同期・pgTAP(静的)・Dartテストまで。**既存データ表の RLS は一切変更しない**（C-01リスクゼロ）。ロール別 read/write RLS・項目マスキングview・Storage共有・editor write-through・Realtime共同編集・共有向け競合UI・通知/FCM・iOS実機E2E は次増分へ明示繰り越し | (1) 全表へロール別RLS＋項目マスキングを適用する変更は Docker/pgTAP 不在で実行検証できず、owner隔離を盲目改変する高リスク。(2) editor write-through は apply_mutation の owner矯正＋子ownerトリガ＋書込RLS＋クライアントownerモデル＋クロスownerのCAS を一体で変える core write-path 改修であり、pgTAP検証なしに出すべきでない。→ 検証可能な環境（Docker/CI）で行う。共有データ基盤（表＋管理＋同期）は everything の substrate であり、既存RLSを触らず安全に先行実装できる（`shared_facility.dart`/`routes_entitlement` と同じ「基盤先行・enforcement/UIは次」方針） |
| D-227 | 通知基盤（NotificationScheduler実装・FCM/APNs・許可UX・ディープリンク）は本増分では実装しない | device/Firebase 依存で本環境（実機/Firebaseプロジェクト無し）では実装・検証不可。ユーザー選択「共有基盤を先に」に従い別増分。境界型（`notification_plan.dart`）は既存のまま維持 |

### 実装対象（本増分で完成した範囲）

- Supabase `0028_genba_shares.sql`: 表＋owner管理RLS＋grantee-select＋set_updated_at/bump_version/
  enforce_genba_child_owner トリガ＋apply_mutation 前方専用再定義（v_allowed に genba_shares 追加）。
- Drift v16→v17: `GenbaShares` 表（新規追加のみ・既存データ無改変）＋owner索引。
- ドメイン `share.dart` 拡張: `GenbaShare`(id/ownerId/version等)・`ShareRole` code・`FieldGrants`
  copyWith/等価・`shareInvariantError`（自己共有・role・空grantee）。
- データ `genba_shares_repository_impl.dart`＋`share_mappers.dart`: owner スコープ CRUD＋親現場
  所有権検証（`parentBelongsToOwner`）＋Outbox＋`refreshFromRemote`/`adoptServerEntity`。
- 配線: `SyncEntity.genbaShares`、`sessionRefresher`、`_adoptServerEntityRouter`、
  `genbaSharesRepositoryProvider`。

### 検証状況（旅程Phase 5 共有データ基盤, 2026-07-09, Windows host / ASCIIパス `C:\src\OshiTrip`）

- `dart run build_runner build`（Drift v17 codegen 成功）、`dart analyze lib test integration_test`
  クリーン、`dart format` 整形済み、`flutter test` **全パス**。本増分の新規テスト:
  `genba_shares_repository_test`（owner CRUD＋Outbox・項目grant保持・共有解除・自己共有拒否・
  他人の現場は共有不可＝親owner整合・owner分離C-01・owner_id偽装AuthFailure・未ログイン）、
  `genba_shares_migration_test`（v16→v17・既存データ無傷・既定値）、`share_test`（不変条件・role
  code・FieldGrants安全側既定）。既存 Phase 1〜4 テストは無改変で緑。
- **未実行（各実環境。成功扱いにしない）**: `supabase test db`（pgTAP `0015_genba_shares.sql`・
  **Docker/Supabase CLI 未導入**・静的レビューのみ）、ロール別 read/write RLS・項目マスキング・
  Storage共有・editor write-through（次増分・要pgTAP実行環境）、通知/FCM・iOS/実機E2E。
- **Phase 5 完成判定**: **未完成**。共有データ基盤のみ実装。共有の実 read/write・項目マスキング・
  Storage・共同編集・競合UI・通知・実機/pgTAP検証は次増分。旅程MVPも引き続き未完成。

## 旅程 場所入力・移動区間UX改善（2026-07-11, Claude Opus 4.8）

計画タブ・移動経路・場所入力のUXを非エンジニア向けに整理し、実 Google Places を接続した。

| # | 判断 | 理由 |
|---|---|---|
| D-228 | (1) 移動区間の出発/到着表示名を単一関数 `itineraryTimelineEntryLabel`（`application/itinerary_timeline.dart`）へ共通化し、内部の種別コード（`spot`/`transport`/`lodging`/`note` の enum 名）や ID を画面へ出さない。スポット=施設名、交通=方向＋手段（例「往路 新幹線」）、宿泊=施設名（無ければ「宿泊先」）、メモ=タイトル（無ければ「メモ」）、参照切れ=「削除済みの…」。計画タブ一覧・移動区間編集の端点候補・出発/到着選択肢・既存移動区間表示すべてで同じ生成元を使う。(2) 移動区間の通常UIから通貨・運賃・経路概要・「日付は前後予定から自動決定」説明文・手動MapsURL入力欄を撤去（DB列は温存し、編集時に既存値を破棄せず保持）。移動区間は出発地・到着地・移動手段・出発/到着時刻・所要・距離・経路確認導線を中心に表示。(3) スポット施設名欄を「Google候補＋手入力」の一体型UIへ統合（入力欄を分けない）。実 `PlacesGatewayImpl`（→ places-proxy Edge Function）を接続し、`placesGatewayProvider` は Places 有効かつ Supabase クライアントありのときだけ実 Gateway を返す（従来は常に `UnavailablePlacesGateway`）。候補選択で施設名・住所を入力欄へ反映し Place ID を保持、ユーザーが確認・保存した値を `user_provided` として永続化。無効・未設定・障害時は同じ欄が手入力として動く。(4) 移動区間に常時「経路を確認（Google Mapsで開く）」ボタンを追加（端点に Place ID または緯度経度があるときだけ表示）。Google Routes（プレミアム・課金）非依存で、押したときだけ Google Maps 経路URLを開くフォールバック。プレミアムの `最新ルートを更新`（Routes ライブ）は従来どおり明示タップ時のみ・結果は所要/距離中心で運賃非表示 | ユーザー（非エンジニア）から、出発/到着に内部パラメータ・英語種別名が出る不具合の是正と、Google検索と手入力を一体化した自然なUIの要望。(1) 表示名の生成が `_optionLabel`/`_entryLabel` で `e.kind.name`（英語 enum 名）へフォールバックしており、transport/lodging を解決できていなかった（`ItineraryEntry` しか渡していなかった）。`labelOf` を `ItineraryTimelineEntry` 受け取りへ変え、解決済みの交通/宿泊から日本語名を出せるようにした。(2) 運賃・通貨・経路概要は入力頻度が低く画面を複雑化する一方、DB互換のため列は残す方針（`follow-up-work`・§6.2）。(3) 名称・住所を Google 応答から**無確認で**永続化しない D-178/D-179 は維持しつつ、入力欄へ反映→ユーザー確認→保存という「明示変換」経路（spec §4.3・§8.2 で既に想定）を実装。Place ID のみ Google 由来値として永続。(4) Places 実 HTTP Gateway が未接続で autocomplete が常に unavailable だったため接続。Routes は課金・プレミアム前提のため、常時使える Google Maps URL フォールバックを別途用意して「経路確認」を非プレミアム・API不能環境でも成立させる |

### 実装対象（本増分で完成した範囲）

- `application/itinerary_timeline.dart`: `itineraryTimelineEntryLabel`（単一の表示名生成元）。
- `presentation/plan_tab.dart`: `_timelineEntryLabel`/`_optionLabel`/`_entryLabel` を撤去し共通関数へ集約、
  `buildLegEntryOptions` の `labelOf` を `ItineraryTimelineEntry` 受け取りへ変更、`_EntryCard._title`
  も共通関数へ、移動区間行から運賃・経路概要表示を撤去。
- `presentation/itinerary_import_and_leg.dart`: 通貨・運賃・経路概要・日付説明・手動MapsURL欄の撤去、
  `_LegRouteOpenButton`（常時Google Maps経路導線）追加、保存時は撤去項目の既存値を保持。
- `presentation/itinerary_editors.dart`: 施設名欄を Google候補＋手入力の一体型へ、`PlacesSearchController`
  を配線、候補選択で名称・住所反映＋Place ID保持、保存時に `googlePlaceId` を永続（従来は未設定＝
  編集で欠落するバグも同時に解消）。
- `presentation/route_live_panel.dart`: 保存済み概算・ライブ結果とも運賃を非表示（所要・距離中心）。
- `data/places_gateway_impl.dart`（新規）＋`application/itinerary_providers.dart`: 実 Places Gateway と
  `placesProxyTransportProvider`／`placesGatewayProvider` の実接続（routes と同設計）。

### 検証状況（旅程 場所入力・移動区間UX改善, 2026-07-11, Windows host / ASCIIパス `C:\src\OshiTrip`）

- `dart format lib test`、`dart analyze lib test` クリーン。新規テスト:
  `test/domain/itinerary_display_name_test.dart`（表示名に内部名を出さない・各種別・削除済み）、
  `test/data/places_gateway_impl_test.dart`（Places実Gateway payload/変換/エラー）、
  `test/widget/itinerary_spot_place_search_test.dart`（手入力/Google候補選択の反映）。既存テストは
  新仕様へ更新（通貨・運賃・経路概要・日付説明の非表示、運賃非表示）。
- **未実行（各実環境。成功扱いにしない）**: 実 Google Places autocomplete/Details の**ライブ呼び出し**
  （places-proxy 経由の実 API 応答）はエミュレータ手動スモークで別途確認予定であり、自動テストでは
  fake transport/gateway で payload・変換・縮退のみ検証。`supabase test db`（pgTAP）・実機E2E は未実施。

## 旅程・概要・会場・余韻のUX仕様変更（2026-07-11, Claude Opus 4.8）

非エンジニア向けに計画・概要・スポット・会場・余韻入力の使い勝手を整えた。Google連携は
手入力と一体化し、API無効でも手入力で完結する。

| # | 判断 | 理由 |
|---|---|---|
| D-229 | (1) 準備サマリを概要タブ内から現場詳細の「ヒーローカードとタブの間」へ移動し、常時表示（`GenbaPrepSummaryBar`、`SliverAppBar` の flexibleSpace 下部）。(2) 移動区間の出発時刻初期値＝移動元の終了時刻（無ければ開始時刻）、到着時刻初期値＝移動先の開始時刻（無ければ終了時刻）。端点候補（`ItineraryEntryOption`）に実効開始/終了時刻を持たせて内部決定。(3) 所要（分）は手入力欄を廃止し、出発・到着時刻から自動計算した読み取り表示（「所要 約35分」）にし、保存時に `durationMinutes` を自動保存。(4) 金額欄は残し通貨欄のみ廃止。通貨は JPY 固定、表示は「1,200円」（`formatJpyYen`）。(5) 「経路を確認」のURL生成を Google 公式 `dir/?api=1` 形式へ修正（`origin`/`destination` は text、Place ID は `*_place_id` 併記、`travelmode` 付与）。旧 `place_id:` 接頭辞を廃止。手入力スポットでも施設名・住所・座標からフォールバック生成（`googleMapsRouteUrl`/`MapRouteEndpoint`）。起動は external→platformDefault→inAppBrowser の順に試行し、対応アプリ非搭載でもブラウザで開く（`launchExternalUrl`、`canLaunchUrl` ゲート撤去）。(6) スポットカードに「地図で開く」導線を追加（Place ID→座標→施設名の順でURL生成。手入力スポットでも施設名で開ける）。(7) 会場入力を「Google検索＋手入力」一体型UIへ（スポットと同じ `PlacesSearchController` パターン）。会場に `venueAddress`/`venueGooglePlaceId` を追加（Drift v18・Supabase 0029・座標は Places Field Mask 対象外のため保存しない）。(8) 計画タブに「会場を追加」を追加し、会場を category=venue の予定スポット（訪問日=開催日・開始=開場・終了=終演）として追加。未登録は案内、重複は確認ダイアログ。(9) 会場・公演アンカーは予定カード（`AppCard`）ではなく小さめの枠線＋「目安」バッジの補助表示にして予定と区別（「会場: …」「公演情報: 開演 HH:MM」）。実際に予定として使うなら「会場を追加」から追加する導線。(10) 余韻・思い出入力に「実際の終演時間」を追加。初期値は現在の終演（`manualEndedAt` 優先→`endTimeMinutes` 投影）。確認ダイアログ後に `setActualEndTime` で `manualEndedAt` と `endTimeMinutes` の両方を更新し、概要・当日・計画など終演を参照する箇所すべてに反映（深夜終演は開演前時刻を翌日として1440超で保存） | ユーザー（非エンジニア）要望: 入力欄を増やしすぎない・Google連携も手入力と自然に一体化・API無効でも手入力可。(2)(3) 移動区間の時刻・所要は前後予定から自然に決まる方が手間が少ない。(4) 前回の増分で通貨欄を消す際に金額欄も一緒に落としたため復活。日本円前提で通貨欄は不要。(5) 旧URL形式 `origin=place_id:...` は Maps URLs `dir` api=1 で解釈されず「リンクを開けませんでした」の一因、加えて `canLaunchUrl`＋external専用が Maps 未搭載端末でブラウザ起動まで弾いていた。(7) 会場は従来 `venue` 文字列のみで住所・Place ID を持てず、スポットと同じ地図・経路導線に乗らなかった。(9) 公演情報・会場は「目安」であり計画の予定ではないため、同じ強さで見せると誤解を招く。(10) 最初の終演は予想値。実際の終演を記録し現場へ反映できるようにする。名称・住所を Google から無確認で永続化しない D-178/D-179 は会場でも維持（Place ID を主に、名称・住所はユーザー確認・保存の「明示変換」） |

### 実装対象（本増分で完成した範囲）

- 概要/詳細: `genba_overview_tab.dart`（`GenbaPrepSummaryBar` 新設・準備サマリ帯を抽出）、
  `genba_detail_screen.dart`（ヒーロー下・タブ上へ配置、`expandedHeight` 調整）。
- 移動区間: `itinerary_import_and_leg.dart`（時刻初期値・所要自動表示・金額欄復活/通貨欄撤去・
  経路ボタンを `googleMapsRouteUrl` 化）、`itinerary_map_links.dart`（`MapRouteEndpoint`/
  `googleMapsRouteUrl`/`spotGoogleMapsUrl` 拡張）、`routes_gateway.dart`（dir URL形式修正）、
  `external_link.dart`（`launchExternalUrl` 多段フォールバック）、`itinerary_leg.dart`
  （`formatJpyYen`）、`route_live_panel.dart`（保存済み概算に金額円表示）。
- スポット地図: `plan_tab.dart`（`_EntryCard` に「地図で開く」、`_VenueRow`/`_AnchorRow` を
  目安表示化＋`_GuideBadge`、`_AddMenu` に「会場を追加」）。
- 会場Google連携: `genba.dart`（`venueAddress`/`venueGooglePlaceId`）、`app_database.dart`
  （Genbas 2列・v18・`_hasColumn` ガード付き移行）、`genba_mappers.dart`、
  `genba_form_controller.dart`（フォーム状態）、`genba_form_screen.dart`（`_VenuePlacesField`）、
  `supabase/migrations/0029_genba_venue_place.sql`。
- 余韻・終演: `genba_actions_controller.dart`（`setActualEndTime`）、`memory_edit_screen.dart`
  （`_ActualEndTimeCard`）。

### 検証状況（2026-07-11, Windows host / ASCIIパス `C:\src\OshiTrip`）

- `dart run build_runner build`（Drift v18 codegen 成功）、`dart format lib test`、
  `dart analyze lib test` クリーン、`flutter test` **全パス（910件）**。新規/更新テスト:
  `itinerary_map_links_test`（URL生成・手入力フォールバック）・`itinerary_fare_format_test`
  （円整形）・`routes_gateway_test`（dir URL形式）・`itinerary_leg_venue_test`（時刻初期値・
  所要自動・金額欄/通貨欄・会場追加）・`genba_actions_controller_test`（`setActualEndTime`）・
  `genba_form_controller_test`（会場のPlace ID保存・手入力でPlace ID解除）・`itinerary_plan_tab*`
  （目安表示・地図導線・金額円表示）。
- **未実行（各実環境。成功扱いにしない）**: `supabase db push`（0029 の実適用）・実 Google Places
  ライブ検索・実機での地図アプリ起動は自動テスト対象外（エミュレータ手動確認予定）。準備サマリ帯の
  `expandedHeight` は端末実表示での見え方を目視確認予定。

## 終演済み二重表示・Google日本語優先・経路確認のアプリ内取得（2026-07-11, Claude Sonnet 5）

終演済み現場の表示区分、Google連携の言語、移動区間の経路確認UXを仕様変更した。

| # | 判断 | 理由 |
|---|---|---|
| D-230 | (1) **終演済み（`afterglow`＝終演予定超過または手動終了、当日中）を「思い出」にも表示しつつ、当日は「ホーム」「現場」一覧にも残す二重表示にする**。`isMemory` を `afterglow`/`memory` の両方でtrue、`isUpcoming` を「`memory` 以外」でtrue（`afterglow` はtrue、翌0時の `memory` 昇格でfalse）に変更し、`memoryStartAt`（終演日翌0時）を境に自動で「思い出」専用へ切り替える。中止は従来どおり `memoryStartAt` 基準。(2) **Google（Places／Routes）へのリクエストに `languageCode: ja` / `regionCode: JP`（Routesは加えて `units: METRIC`）を必ず付与する**。Gateway層（`places_gateway_impl`/`routes_gateway_impl`）で付与し、Edge Function（`places-proxy`/`routes-proxy`）はサーバー既定（ja/JP/METRIC）でフォールバック。(3) **住所入力欄の補足説明文（「共有時は規定で非公開として扱われます」）を削除**し、ラベルのみにする。(4) **移動区間カードの経路導線を3役割に分離**: 「経路を確認」＝アプリ内でGoogle Routesから取得し公共交通は徒歩合計＋路線／行き先／乗降駅／発着時刻／乗換の乗換タイムラインを表示（区間の出発予定時刻ベース）、「最新の経路」＝現在時刻を出発時刻に登録済み出発地から再取得、「Google Mapsで開く」＝外部地図の補助導線。旧「経路を確認（Google Mapsで開く）」ボタン（`_LegRouteOpenButton`）は誤称のため撤去し、`RouteLivePanel` を移動区間カード（`_LegRow`）と区間編集シートの双方へ配置。(5) **取得経路の保存は「明示変換」に限定**（D-178/D-179/D-180準拠）: 「この経路を保存」は乗換ステップ・路線・生レスポンス等のGoogleコンテンツを恒久保存せず、ユーザーが確定した所要時間・距離・地図URL・確認日時（`lastVerifiedAt`）だけを `user_provided` の `ItineraryLeg` として保存する（`source`/`fetchedAt`/`cacheKey`/`encodedPolyline` は付けず `validateItineraryLegPhase1Persistable` を通過）。(6) Routes Field Mask を発着時刻・徒歩所要へ拡張（`routes.legs.steps.travelMode`/`staticDuration`/`transitDetails.localizedValues.departureTime.time.text`/`arrivalTime.time.text`）。`routes-proxy` handler は `WALK` ステップ所要を `walkMinutes` に合算、`localizedValues` から発着時刻テキストを抽出 | (1) ユーザー要望: 終演直後に思い出へ入力を促しつつ、当日中は当日ホーム／現場一覧での最終確認も維持したい。(2) 施設名・住所・経路案内が英語で返る事象を避け、国内利用の日本語表記を優先する。(3) 住所欄の非公開文言は共有UIの責務であり入力欄では冗長。(4) 旧「経路を確認」は実体が外部Google Maps起動で、アプリ内取得の要望と食い違っていた。役割を明示分離。(5) Google Routesの応答内容（所要・路線・運賃等）はGoogle公式規約上、緯度経度以外の恒久キャッシュ許可が確認できない（D-180/D-215）。不明点は保守側に倒し、ユーザーが確認・確定した最小限の表示用データのみをPlacesと同じ「明示変換」で保存する。APIキー・秘密情報は保存しない |

### 実装対象

- 状態/表示: `genba_schedule.dart`（`isMemory`/`isUpcoming` を `afterglow` 二重表示へ）。
  下流の `upcomingGenbasProvider`/`memoryGenbasProvider`・ホーム/現場/思い出画面は述語経由で自動反映。
- Google言語: `places_gateway_impl.dart`/`routes_gateway_impl.dart`（`languageCode`/`regionCode`/
  `units` 付与）、`supabase/functions/places-proxy/index.ts`・`routes-proxy/{index,handler,policy}.ts`
  （サーバー既定＋Field Mask拡張＋handler の `walkMinutes`/発着時刻抽出）、`routes_field_mask.dart`。
- 住所欄: `itinerary_editors.dart`（`helperText` 撤去）。
- 経路UX: `route_live_panel.dart`（3ボタン・乗換タイムライン・「この経路を保存」）、
  `plan_tab.dart`（`_LegRow` へ `RouteLivePanel` 埋め込み・端点解決・保存済みURLフォールバック）、
  `itinerary_import_and_leg.dart`（`_LegRouteOpenButton` 撤去・編集シートへ `planId` 連携）、
  `routes_gateway.dart`（`RouteLiveResult.walkMinutes`・`RouteLiveTransitStep.departureTime`/
  `arrivalTime`）。

### 検証状況（2026-07-11, Windows host `C:\src\OshiTrip`）

- `dart format` / `dart analyze lib test`（クリーン）。更新/新規テスト: `genba_schedule_test`
  （終演済み当日二重表示・翌日思い出のみ）、`routes_gateway_impl_test`（ja/JP/METRIC payload）、
  `places_gateway_impl_test`（ja/JP payload）、`route_live_panel_test`（経路を確認＝アプリ内取得・
  乗換タイムライン＋発着時刻＋徒歩合計・運賃非表示・自動保存なし・「この経路を保存」で所要/距離のみ
  保存・「最新の経路」現在時刻ベース・非プレミアム抑止）、`itinerary_spot_place_search_test`
  （住所欄に非公開文言なし）。
- **未実行（環境未整備・成功扱いにしない）**: `routes-proxy/handler_test.ts`（Deno未インストール。
  `walkMinutes`/発着時刻抽出のアサーションを追加済みだが未実行）、`supabase db push`、実 Google
  Routes ライブ取得（プレミアム課金・実キー必要）、実機での地図アプリ起動。

## 既存住所の言語移行方針（自動上書きしない, 2026-07-11, Claude Sonnet 5）

D-230 の `languageCode: ja` 対応後、エミュレーターの既存データに英語表記の住所
（例 `Dogenzaka, Shibuya, Tokyo 150-0043, Japan`）が残っていた事象への対応方針を定めた。

| # | 判断 | 理由 |
|---|---|---|
| D-231 | (1) `languageCode: ja`/`regionCode: JP` の日本語優先は**新規のGoogle取得**にのみ適用する。ja/JP対応前に保存された既存の施設名・住所（ユーザーが手入力／Google候補選択で保存した値）は、アプリが自動で再取得・一括上書き**しない**。既存スポット・会場を編集で開いても住所をGoogleへ問い合わせ直さない（`_SpotEditor.initState` は保存値を読み込むだけで Places を呼ばず、住所が変わるのは `_selectSuggestion` でユーザーが候補を選び直したときのみ）。(2) 既存データの日本語化は**ユーザーの明示操作**（候補の選び直し＝明示変換, D-178/D-179。将来「Googleの情報で更新」導線を設ける場合も確認ダイアログ必須）でのみ許可する。(3) リポジトリ**同梱**のデモ/seed/fixture/サンプル/オンボーディング固定データの住所は日本語表記へ揃える。調査の結果、`lib`/`test`/`docs`/`integration_test`/`assets` に英語住所の同梱データは**存在せず**（`makeItinerarySpot` の既定 `name='展望台'`・`address=null`、demo_auth/onboarding は住所をseedしない）、エミュレーターで見えた英語住所は**実ユーザーがテスト中に保存した端末ローカルDBのデータ**（リポジトリ管理外）と判明。したがって同梱データの修正は不要で、回帰ガードのみ追加した | 実ユーザーが確認・保存した値を勝手に置き換えない（D-178/D-179/D-180 の「Google由来値はユーザー明示操作でのみ確定」を住所の言語移行にも一貫適用）。表示品質のためにデモ/fixtureは日本語へ揃えるが、実データの一括変換は所有者の意図を壊すリスクがあるため行わない |

### 実装・検証

- コード変更なし（既存の `_SpotEditor` が既に自動取得しない実装であることを確認）。
- ドキュメント: `requirements.md`・`itinerary-plan-spec.md §6.3` に上記方針を追記。
- テスト: `test/quality/demo_data_japanese_address_test.dart`（同梱のデモ/seed/fixture/アセットに
  英語表記の日本語住所——`..., Japan`／ローマ字郵便番号／ローマ字区名＋カンマ——が無いことの
  回帰ガード。施設名 "Tokyo Dome"・タイムゾーン "Asia/Tokyo" は誤検出しない住所文脈限定の正規表現）、
  `itinerary_spot_place_search_test`（既存スポットを開いても Places を呼ばず住所を上書きしない・
  候補を選び直したときだけ住所が更新される）。ja/JP payload は `places_gateway_impl_test`・
  `routes_gateway_impl_test` で担保。
- 未実施: エミュレーターの既存ユーザーデータの日本語化（方針どおり自動変換しない。必要なら
  ユーザーが編集画面で候補を選び直す）。

## 経路検索のプレミアム制限を現仕様に合わせて解除（2026-07-11, Claude Sonnet 5）

将来的に経路検索をプレミアム機能化する予定はあるが、現時点ではアプリ内にプレミアム／
ノーマルの正式なアカウント区分・課金導線が無い。そのためノーマルユーザーが「経路を確認」
「最新の経路」を使えないのは不適切として、現仕様では全ユーザーに開放する。

| # | 判断 | 理由 |
|---|---|---|
| D-232 | (1) **現仕様では経路検索を全認証ユーザーに開放する**。`RouteRecalculationController.recalculate` の `isPremium == false` による早期拒否（`PermissionFailure` 即返却）を削除。経路取得は Google Routes 有効・Supabase認証済み・API設定済みなら誰でも可。`isPremium` 引数と `routesIsPremiumProvider` は**将来のプレミアム化に備えて残す**が、現時点の取得可否には使わない。(2) UIから「プレミアム限定」文言を撤去（`route_live_panel.dart` の非プレミアム向けヒント文を削除）。(3) **Edge Function のプレミアム強制を設定フラグ化**: `routes-proxy/index.ts` は `ROUTES_REQUIRE_PREMIUM=true`（純粋関数 `isFlagOn` で判定）の環境でのみ `has_premium_routes_entitlement` RPC を検証し、非エンタイトルは `not_entitled` を返す。未設定/false（**既定**）では RPC を呼ばず認証済みユーザーを許可する（判定は純粋関数 `premiumGateError(requirePremium, entitled)` に切り出しテスト可能化）。将来のプレミアム化に備え entitlement RPC・テーブル（`user_entitlements`・`has_premium_routes_entitlement`）は**削除しない**。(4) `not_entitled` のエラー文言を「この環境では経路取得がプレミアム限定に設定されています」に変更（`ROUTES_REQUIRE_PREMIUM=true` の環境でのみ発生する想定。通常UIには出ない）。(5) レート制限（`check_and_increment_routes_rate_limit`）・kill switch（`ROUTES_KILL_SWITCH`）・timeout（`ROUTES_TIMEOUT_MS`）・APIキーのサーバー保持・最小Field Mask・費用計上は**すべて維持**。Google API 使用量はプレミアム制限ではなくこれらで制御する | アプリにプレミアム区分・課金導線が未整備の現状で経路検索を非プレミアムに閉ざすと、実質「誰も使えない中核機能」になり不適切。一方で将来のプレミアム化余地は残す必要があるため、削除ではなく**環境フラグ既定 false**で無効化し、境界（RPC・provider・引数）は温存する。費用暴走の防波堤（レート制限・kill switch・timeout）はプレミアム制限とは独立に必ず効かせる |

### 現仕様と将来の境界

- **現仕様（既定）**: `ROUTES_REQUIRE_PREMIUM` 未設定/false → 認証済みユーザーは全員経路検索可。UIにプレミアム文言なし。
- **将来プレミアム化するために残した境界**: `isPremium` 引数・`routesIsPremiumProvider`（クライアント）／`has_premium_routes_entitlement` RPC・`user_entitlements` テーブル（サーバー）／`ROUTES_REQUIRE_PREMIUM` フラグ。`true` にするだけでサーバー強制が復活する。
- **`ROUTES_REQUIRE_PREMIUM` 既定値**: `false`（未設定も false 扱い）。

### 検証

- `dart format` / `dart analyze lib test integration_test`（クリーン）。
- 更新テスト: `route_recalculation_controller_test`（`isPremium=false` でも Gateway を呼ぶ／single-flight・明示操作限定は不変）、`route_live_panel_test`（非プレミアムでも「経路を確認」「最新の経路」で Gateway が呼ばれ結果表示・「プレミアム」文言なし）。
- Deno（純粋関数）: `routes-proxy/handler_test.ts` に `isFlagOn`・`premiumGateError`（false/未設定なら常に許可、true のときだけ非エンタイトルを not_entitled）のテストを追加。**Deno未導入のため未実行**（成功扱いにしない）。`routes-proxy/index.ts` の serve 経路（レート制限・kill switch・認証）は従来どおり単体テスト対象外（Deno.serve 構造）だが、entitlement 判定を純粋関数へ切り出したことで分岐はテスト可能にした。
- 未実施: 実 Supabase での `ROUTES_REQUIRE_PREMIUM` 切替デプロイ・実 Routes ライブ取得（実キー必要）。

## 現場共有の拡張基盤: 招待URL・フレンド・簡易プロフィール Phase 1（2026-07-11, Claude Opus 4.8）

現場共有をLINE/DM経由でもアプリ内でも自然に行えるよう、招待URL・フレンド・簡易プロフィールを
追加する。D-226 の保守的スライス（genba_shares データ基盤のみ）を**上書き・拡張**し、共有メンバー
管理に profiles/friendships/genba_invites を足す。Phase 1 は**データ基盤＋ドメイン＋docs**まで
（UI・Deep Link 配線・実機E2Eは Phase 2〜5）。

| # | 判断 | 理由 |
|---|---|---|
| D-233 | (1) 共有メンバーの実体は既存 `genba_shares`（0028）を使い、招待URLは「参加時に `genba_shares` 行を作る導線」とする（新テーブルを増やさない）。(2) `profiles`（本人PK・本人のみ編集）・`friendships`（requester/receiver・状態機械）・`genba_invites`（現場ごと・token・default_role・expires_at・revoked_at・max_uses・used_count）を追加（migration 0030）。(3) **これら3表は既存の offline 同期（`apply_mutation`/outbox）に載せず、サーバー権威の SECURITY DEFINER RPC ＋専用 RLS で扱う**（複数ユーザーをまたぐ社会機能はオンライン前提で、owner隔離の core write-path=`apply_mutation` を触らない）。RPC: `send_friend_request`／`respond_friend_request`／`remove_friend`／`create_genba_invite`／`revoke_genba_invite`／`get_invite_preview`／`join_genba_via_invite`。(4) セキュリティ（§7）: 招待は owner のみ発行/無効化（`genbas.owner_id` 検証＋子ownerトリガ）、参加は token 検証（revoked/expired/max_uses、`join_genba_via_invite` で advisory lock＋重複参加防止＋used_count は新規参加のみ加算）、フレンド申請は本人のみ・相手が searchable か同一現場メンバーのときだけ（無制限検索禁止）、プロフィールは本人のみ編集・可視範囲は本人/承認フレンド/同一現場メンバー/searchable（`can_view_profile` SECURITY DEFINER）。(5) 招待URLは `https://oshitrip.app/invite/{token}`。Deep Link 実機確認が難しい間は token 入力/貼り付け参加を代替とする（`inviteTokenFromUrl` が URL・直貼り両対応）。(6) Dart は Phase 1 でドメイン型＋純粋ロジック（`profileInvariantError`／`canSendFriendRequest`／`friendshipRespondError`／`inviteValidityError`／`inviteTokenFromUrl`／状態・URL変換）と Repository 抽象のみ。Supabase 実装・各画面UIは Phase 2〜5 | (1) 共有の正本を1つ（genba_shares）に保ち、招待は導線に徹することで権限モデルを二重管理しない。(3) friendships（受信者が status を変える）・invites（他人が token で参加）は「owner_id=作成者」の単純所有モデルに収まらず、`apply_mutation` の owner 矯正では表現できない。RPC＋RLS でサーバー権威にすれば、owner隔離（C-01）を保ったまま安全に実装でき、pgTAP で分岐を検証できる。(4) 完全身内想定でも、token 漏洩・期限/上限・無制限検索・他人プロフィール編集の穴は塞ぐ必要がある。(6) 本環境は Docker/Supabase 未導入で RLS/RPC を実行検証できないため、Dart 側は純粋ロジックに検証を集中し、Supabase 側は静的（migration＋pgTAP）に留める |

### 実装（Phase 1）

- Supabase: `supabase/migrations/0030_social_profiles_friends_invites.sql`（profiles/friendships/genba_invites・RLS・7 RPC・helper `users_share_genba`/`can_view_profile`・index・子ownerトリガ再利用）。pgTAP `supabase/tests/0016_social_profiles_friends_invites.sql`（plan 20: owner限定発行/無効化・token検証・revoked/expired/max_uses・重複参加防止・genba_shares作成・フレンド許可条件/本人限定応答・プロフィール可視範囲/本人限定編集）。
- Dart domain: `lib/features/social/domain/profile.dart`・`friendship.dart`、`lib/features/sharing/domain/genba_invite.dart`（型＋純粋ロジック＋Repository 抽象）。
- Dart tests: `test/domain/profile_test.dart`・`friendship_test.dart`・`genba_invite_test.dart`（26件, 全パス）。

### 検証状況（2026-07-11, Windows host / Docker・Supabase なし）

- `dart format` / `dart analyze`（クリーン）・新規ドメインテスト 26 件パス。
- **未実行（成功扱いにしない）**: `supabase db reset` / `supabase test db`（pgTAP 0016）は Docker/Supabase CLI 未導入で未実行。migration/RLS/RPC/pgTAP は**静的作成のみ**。実 RLS・RPC の権限強制、招待参加のE2E、Deep Link 実機遷移は各実環境で別途検証が必要。
- **Phase 2〜5 未着手（明示繰り越し）**: プロフィール画面、フレンド一覧/申請/承認UI、共有メンバー画面、フレンドから共有追加、招待URL発行/参加画面/token参加処理、Deep Link 配線、Supabase-backed Repository 実装、回帰E2E。

## 招待URL・フレンド・プロフィール Phase 2: プロフィール/フレンドUI（2026-07-11, Claude Opus 4.8）

D-233 のデータ基盤の上に、プロフィール編集画面とフレンド画面（一覧/申請中/受信）を実装した。

| # | 判断 | 理由 |
|---|---|---|
| D-234 | (1) profiles/friendships はサーバー権威のため、Supabase-backed Repository（`SupabaseProfileRepository`/`SupabaseFriendRepository`）を直接 `from`/`rpc` で実装し、offline outbox には載せない。Supabase 未接続/デモ/未ログインは `Unavailable*Repository`（no-op/UnavailableFailure）へフォールバック（`profileRepositoryProvider`/`friendRepositoryProvider` が client＋uid の有無で選択）。(2) 一覧はサーバー権威のため Stream ではなく `Future` フェッチ＋`FutureProvider`（`myProfileProvider`/`friendsViewProvider`）とし、変更後は `ref.invalidate` で再取得。(3) フレンド画面は SegmentTabs の3区分（フレンド/申請中/受信）。受信のみ承認/拒否、フレンドは削除、申請中は取消。**フレンド申請の送信はこの画面に置かない**（無制限検索を避けるため、送信は Phase 3 の共有メンバー一覧から, §7）。(4) プロフィールのアイコン画像アップロードは Supabase Storage 基盤（バケット＋RLS）が未整備のため Phase 2 では見送り、表示名イニシャルの `OshiAvatar` プレビューで代替（画像アップロードは follow-up）。(5) 設定＞つながり に「プロフィール」「フレンド」導線を追加、ルートは `/settings/profile`・`/settings/friends` | (1) 既存 `_remoteClientOrNull`/`Unavailable*` パターンに合わせ、Supabase の有無で安全に縮退。(2) 複数ユーザーをまたぐデータは Drift 同期に載せず、都度サーバー取得のほうが権限・鮮度が正しい。(3) 送信導線を共有メンバー一覧に限定することで「フレンドでない相手の無制限検索」をUIレベルでも防ぐ。(4) Storage 構築は本環境で検証できず、画像なしでも表示名で機能が成立するため優先度を下げた |

### 実装（Phase 2）

- data: `lib/features/social/data/profile_repository_impl.dart`・`friend_repository_impl.dart`（Supabase実装＋Unavailable）。
- application: `lib/features/social/application/social_providers.dart`（repo provider・`currentUserIdProvider`・`myProfileProvider`・`friendsViewProvider`＋`FriendEntry`/`FriendsView`）。
- presentation: `lib/features/social/presentation/profile_edit_screen.dart`・`friends_screen.dart`。導線: `settings_screen.dart`（つながり節）・`router.dart`（`/settings/profile`・`/settings/friends`）。
- tests: `test/widget/profile_edit_screen_test.dart`（既存反映・空名バリデーション・保存でupsert）・`friends_screen_test.dart`（一覧表示・受信承認でrespond・申請中表示・空状態）。7件パス。

### 検証状況（2026-07-11, Windows host / Docker・Supabase なし）

- `dart format` / `dart analyze lib test integration_test`（クリーン）・widgetテスト7件パス。
- **未検証（成功扱いにしない）**: Supabase-backed Repository の実 RPC/RLS 動作は Docker/Supabase 未導入で未実行。migration 0030 が実 Supabase プロジェクトへ未デプロイのため、実機・エミュレーターでのプロフィール保存/フレンド操作は 0030 適用後でないと動かない（RPC/テーブル未存在）。
- **Phase 3〜5 未着手**: 共有メンバー画面・フレンドから共有追加（Phase 3）、招待URL発行/参加画面/token参加（Phase 4）、Deep Link・回帰E2E（Phase 5）。プロフィール画像アップロード（Storage）は follow-up。

## 招待URL・フレンド・プロフィール Phase 3: 現場メンバー・共有画面（2026-07-11, Claude Opus 4.8）

現場詳細に「メンバー・共有」画面を追加し、オーナーが共有メンバーを管理できるようにした。

| # | 判断 | 理由 |
|---|---|---|
| D-235 | (1) 現場詳細 AppBar に「メンバー・共有」導線（people アイコン）を追加し、`/genba/:id/members` へ遷移。(2) `genbaMembersProvider`（family）が genba オーナー（`genbaByIdProvider`）＋共有一覧（`genbaSharesStreamProvider`＝owner スコープ `watchShares`）＋相手プロフィール（`fetchProfiles`）＋フレンド状態（`myFriendshipsProvider`）を合成し `MembersView` を返す。(3) **この画面は当面オーナー専用**とする。grantee（非オーナー）による共有現場・メンバー一覧の閲覧はロール別 read RLS を伴う次増分（D-226）であり、現状 genba 本体の read RLS も owner 限定のため、非オーナーはそもそも現場を開けない。非オーナーが到達した場合は「管理はオーナーのみ」の案内を出す。(4) オーナー操作: フレンドから追加（承認済みフレンドのうち未メンバーを viewer/editor 選択で追加＝`upsertShare`）、権限変更（viewer↔editor＝`upsertShare(copyWith)`）、メンバー削除（`removeShare`）。追加時の共有行生成はクライアントで Uuid＋clock を用い、既存の owner 管理 RLS・子ownerトリガ・apply_mutation 版CAS に乗る。(5) メンバー行にフレンド状態チップ（フレンド/申請中/フレンド申請）を出し、未フレンドには「フレンド申請」ボタン＝`sendRequest`（§7.8.4 招待参加後のフレンド申請）。(6) 招待URLの発行/コピー/無効化は Phase 4 で接続するため、本画面には枠（`_InvitePlaceholder`）のみ置き `genbaInviteRepositoryProvider` は当面 null | (1)(2) 既存 `genba_shares` の owner スコープ Repository をそのまま使い、正本を1つに保つ。(3) 非オーナーのメンバー閲覧は read RLS 未整備（D-226）のため、無理に見せかけUIを作らずオーナー管理に限定する（プロンプトの「前提基盤が無ければ見せかけUIを作らない」に一致）。(4) 共有行の生成は既存 `ShareRepository.upsertShare`（親現場所有権検証つき）に委ね、権限モデルを二重化しない。(5) フレンド申請導線を共有メンバー一覧に置くことで「無制限検索なしでフレンドを増やす」要件（§7）を満たす |

### 実装（Phase 3）

- application: `lib/features/social/application/member_providers.dart`（`genbaSharesStreamProvider`・`genbaMembersProvider`・`MembersView`/`MemberEntry`/`AddableFriend`・`genbaInviteRepositoryProvider`[null]）、`social_providers.dart`（`myFriendshipsProvider`・`friendStatusFor` を追加し `friendsViewProvider` をこれに再構成）。
- presentation: `lib/features/social/presentation/genba_members_screen.dart`。導線: `genba_detail_screen.dart`（AppBar people アイコン）・`router.dart`（`/genba/:id/members`）。
- tests: `test/widget/genba_members_screen_test.dart`（オーナー/メンバー表示・フレンド申請でsendRequest・削除でremoveShare・フレンドから編集権限で追加でupsertShare・非オーナー案内）。5件パス。

### 検証状況（2026-07-11, Windows host / Docker・Supabase なし）

- `dart analyze lib test integration_test`（クリーン）・widgetテスト5件パス。
- **未検証**: Supabase-backed の実 RLS/RPC・migration 0030 実デプロイは未実行（Docker/Supabase 未導入）。実機・エミュレーターでのメンバー管理は 0030 適用後に検証が必要。
- **Phase 4〜5 未着手**: 招待URL発行/コピー/無効化・参加確認画面・token参加（`GenbaInviteRepository` 実装, Phase 4）、Deep Link・回帰E2E（Phase 5）、grantee 側のメンバー閲覧（ロール別 read RLS, D-226）、プロフィール画像アップロード。

## 招待URL・フレンド・プロフィール Phase 4: 招待URL発行・参加（2026-07-11, Claude Opus 4.8）

招待URLの発行/コピー/無効化、参加確認画面、token 参加処理を実装した。

| # | 判断 | 理由 |
|---|---|---|
| D-236 | (1) `GenbaInviteRepository` を Supabase 実装（`SupabaseGenbaInviteRepository`）: `fetchInvites`＝`from('genba_invites')`、`createInvite`/`revokeInvite`/`get_invite_preview`/`joinByToken`＝各 SECURITY DEFINER RPC。未接続/デモ/未ログインは `Unavailable*` へフォールバック（`genbaInviteRepositoryProvider`）。インターフェースは Phase 2/3 と同じく Stream ではなく `Future` フェッチ（`fetchInvites`）へ揃え、発行/無効化後に `genbaInvitesProvider` を invalidate。(2) メンバー画面の招待プレースホルダを実 `_InviteSection` へ置換: 「招待URLを作成」（権限 viewer/editor をボトムシートで選択→作成→クリップボードへコピー）、招待行ごとに URL 表示・コピー・無効化（確認ダイアログ）。無効化済みは一覧から除外、期限切れはラベル表示。(3) 参加確認画面 `InviteJoinScreen`（`/invite/:token`）: `get_invite_preview` で現場名・公演名・日付・オーナー表示名/アイコン・参加後の権限を表示し、「参加する」で `join_genba_via_invite`→現場詳細へ。無効（revoked/expired/exhausted/not_found）は理由文言、参加済みは「現場を開く」。(4) Deep Link 最終形 `https://oshitrip.app/invite/{token}` を top-level ルートに登録。実機 Deep Link 配線は Phase 5 だが、当面は設定＞つながり＞「招待リンクで参加」（`InvitePasteScreen`＝URL/コード貼り付け→`inviteTokenFromUrl`→参加画面）を代替導線とする（§8）。(5) 重複参加防止・token 検証・used_count 加算はサーバー RPC（0030）が担保し、クライアントは結果表示に徹する | (1) 既存 Supabase repo パターン（client＋uid で実装/Unavailable 選択）に合わせ、キー・権限強制をサーバーへ寄せる。(2)(3) §5/§9 の共有導線（発行→コピー→送付→参加）を素直に画面化。(4) Deep Link のネイティブ設定（AASA 等）は実機・環境依存で本環境検証不可のため、まず貼り付け導線で機能を成立させ、Deep Link は Phase 5 に分離 |

### 実装（Phase 4）

- data: `lib/features/sharing/data/genba_invite_repository_impl.dart`（Supabase実装＋Unavailable・token検証エラー→文言変換）。
- application: `member_providers.dart`（`genbaInviteRepositoryProvider` を実装選択へ・`genbaInvitesProvider`・`invitePreviewProvider`）。
- presentation: `genba_members_screen.dart`（`_InviteSection`/`_InviteRow`/`_InviteRoleSheet`）、`invite_join_screen.dart`、`invite_paste_screen.dart`。導線: `router.dart`（top-level `/invite/:token`・`/settings/join`）・`settings_screen.dart`（招待リンクで参加）。
- tests: `test/widget/invite_flow_test.dart`（作成でcreateInvite・無効化でrevokeInvite・参加確認の表示＋参加でjoin→遷移・無効理由表示・貼り付けの不正入力エラー）。5件パス。

### 検証状況（2026-07-11, Windows host / Docker・Supabase なし）

- `dart analyze lib test integration_test`（クリーン）・widgetテスト5件パス。
- **未検証**: Supabase 実 RPC/RLS・migration 0030 実デプロイは未実行。実機・エミュレーターでの発行/参加は 0030 適用後に検証が必要。
- **Phase 5 未着手**: Deep Link のネイティブ配線（Universal Links / App Links・AASA/assetlinks）、回帰E2E、grantee 側のメンバー閲覧（ロール別 read RLS, D-226）、プロフィール画像アップロード（Storage）。

## 招待URL・フレンド・プロフィール Phase 5: Deep Link・回帰・整合（2026-07-11, Claude Opus 4.8）

招待URL Deep Link のネイティブ配線（静的）と、未ログイン時の招待復帰、ドキュメント整合を行った。

| # | 判断 | 理由 |
|---|---|---|
| D-237 | (1) Deep Link は go_router（`MaterialApp.router`+`routerConfig`）が受信 URI のパス `/invite/{token}` をそのままルーティングするため、追加 Dart パッケージ（app_links 等）は導入しない。ネイティブ設定のみ追加: Android `AndroidManifest.xml` に `https://oshitrip.app/invite` の VIEW/BROWSABLE intent-filter（`autoVerify="true"`）、iOS `Runner.entitlements` に `applinks:oshitrip.app`。ドメイン検証ファイル雛形を `deeplink/`（`apple-app-site-association`・`assetlinks.json`・手順 README）に配置（TeamID・署名SHA256 はプレースホルダ）。(2) 未ログインで招待Deep Linkを開いた場合、`redirect` を純粋関数 `resolveAuthRedirect` へ切り出し、`/login?from=<invite>` に退避→ログイン後に `/invite/{token}` へ復帰する。`from` は `/invite/` 内部パスに限定し、外部URL・任意内部パスへのオープンリダイレクトを防ぐ | (1) 依存追加は pub get（ネットワーク）・実機ビルド検証が必要で本環境で確認できない。go_router 標準のプラットフォーム Deep Link 消費で足りるため、ネイティブ設定に閉じてリスクを最小化。(2) 招待は「初めてアプリを開く未ログインユーザー」が踏む可能性が高く、ログインで招待先を失う導線は致命的。復帰先を invite に限定することでセキュリティ（オープンリダイレクト）も担保 |

### 実装（Phase 5）

- ネイティブ: `android/app/src/main/AndroidManifest.xml`（App Links intent-filter）、`ios/Runner/Runner.entitlements`（Associated Domains）、`deeplink/{apple-app-site-association,assetlinks.json,README.md}`。
- Flutter: `lib/app/router.dart`（`resolveAuthRedirect` 純粋関数化＋招待 `from` 復帰）。
- docs: requirements §7.8.5、本節、follow-up-work、requirements-traceability。
- tests: `test/app/auth_redirect_test.dart`（ローディング/オンボーディング/未認証/招待退避/認証後復帰/from非invite無視=オープンリダイレクト防止/素通り）。8件パス。

### 検証状況（2026-07-11, Windows host / Docker・Supabase・実機なし）

- `dart analyze lib test integration_test`（クリーン）・redirect回帰8件パス・全体テストパス。
- **未検証（成功扱いにしない）**: 実機での Universal Links / App Links 起動（AASA/assetlinks の実ホスティング・TeamID・リリース署名SHA256・Xcode Associated Domains 有効化・Play App Signing が必要）は本環境で確認不可。`deeplink/README.md` の手順で実機検証する。
- **招待URL・フレンド・プロフィール（Phase 1〜5）の全体注記**: Supabase migration 0030・pgTAP 0016 は実 Supabase 未デプロイのため**未実行**。実 RLS/RPC・招待/フレンド/メンバーの E2E、Deep Link 実機、grantee 側のメンバー閲覧（ロール別 read RLS, D-226）、プロフィール画像アップロード（Storage）は残タスク。

## 共有現場のロール別アクセス（read/write RLS・editor共同編集）設計（2026-07-11, Claude Opus 4.8）

D-226 で次増分としていた「grantee による共有現場の read/write」を設計・静的実装した。
**本増分は owner 隔離（C-01）に触れる最重要部分であり、本環境（Docker/Supabase/pgTAP なし）
では実行検証できない**。Supabase 側は静的作成のみ・未実行として扱う。

| # | 判断 | 理由 |
|---|---|---|
| D-238 | (1) **READ**: genbas＋全子テーブル（tickets/transports/lodgings/todos/genba_memos/memory_entries/memory_photos/setlist_items/goods_items/visited_places/itinerary_plans、および plan 経由の itinerary_spots/spot_links/entries/legs）に、既存の owner 限定ポリシーへ**加算的**な member SELECT ポリシー（`is_genba_member`／`is_plan_member`）を足す。SELECT の USING は OR 合成されるため read だけが増え、write 権限は増えない（migration 0031）。項目単位マスキングは無し（完全身内・全項目可視）。(2) **WRITE（editor）**: 直接 INSERT/UPDATE/DELETE ポリシーは owner 限定のまま（editor の owner_id は現場owner≠auth.uid で RLS が弾く）。editor 書き込みは **SECURITY DEFINER `apply_shared_mutation` RPC 経由のみ**許可し、owner_id を現場owner へ正規化・行が対象現場に属することを検証・版CAS/冪等台帳。これで owner隔離の直接書き込み経路（`apply_mutation`）は無改変のまま editor 共同編集を監査可能な単一経路に閉じる。(3) **VIEWER** は write ポリシーにも editor 判定にも通らず read only。(4) **OWNER 限定**（現場削除・オーナー変更・メンバー管理・招待発行/無効化）は従来経路のまま。editor は allowlist に genbas/genba_shares/genba_invites を含めないため不可。(5) **クライアント**: 権限判定の純粋モデル `GenbaPermission`（`genbaPermissionFor(isOwner, memberRole)` → canView/canEditContent/canManageMembers/canDeleteGenba/isShared）と、共有ロール取得 `myGenbaRolesProvider`（`genba_shares` を grantee_id=自分で取得）・`genbaPermissionProvider` を追加。UIの共有バッジ・viewer/editor 出し分けの基礎とする | (1) 加算 SELECT ポリシーは PostgreSQL の OR 合成で「read だけ増やし write は増やさない」を構造的に保証でき、owner隔離の直接書き込み RLS を一切触らずに済む（C-01リスク最小）。(2) apply_mutation（owner_id=auth.uid 前提）は共有現場で破綻するため、editor 専用に owner_id を現場owner へ正規化する別RPCを設ける。SECURITY DEFINER で RLS を貫通する代わり、関数内で membership・現場帰属を厳格に検証し監査台帳へ記録する。(5) サーバーが最終強制する前提で、クライアントは「見せない/押させない」UXのみ担う |

### 実装（本増分）

- Supabase（**静的・未実行**）: `supabase/migrations/0031_shared_genba_access.sql`（`is_genba_member`/`is_genba_editor`/`is_plan_member`・16表の member SELECT ポリシー・genba_shares の co-member SELECT・`apply_shared_mutation` RPC）。pgTAP `supabase/tests/0017_shared_genba_access.sql`（plan 14: viewer read可/write不可・editor read/write可・editor はメンバー管理/現場削除不可・未共有 read/write不可・共有解除後 read/write不可・owner 全操作可）。
- クライアント（テスト済み）: `lib/features/sharing/domain/genba_permission.dart`（`GenbaPermission`/`genbaPermissionFor`）、`member_providers.dart`（`myGenbaRolesProvider`/`genbaPermissionProvider`）。`test/domain/genba_permission_test.dart`（6件パス）。

### 各要件の実装状況（正直な区分）

| 要件 | 状況 |
|---|---|
| §7 RLS（read/write ロール別・未共有拒否・共有解除後拒否） | **設計・静的実装（0031）＋pgTAP（0017）まで。実行検証は Docker/Supabase なしで未実施（成功扱いにしない）** |
| §3 editor 書き込み経路（apply_shared_mutation・owner_id正規化） | **静的実装のみ。実RPC動作は未検証** |
| §1 共有現場をホーム/現場一覧に表示（共有バッジ・権限表示） | **未実装（クライアント配線）**。`myGenbaRolesProvider`/`GenbaPermission` の基礎のみ。一覧/ホームへの共有現場マージ、`genbaByIdProvider` の共有現場フォールバック（現状ローカル owner スコープのみ）は次増分 |
| §2 共有現場の読み取り（各タブ/思い出/アルバム） | **未実装（クライアント配線）**。RLS では読めるが、現状のローカル owner スコープ Repository/Provider は共有現場を取得・表示しない |
| §4 viewer のUI非活性（保存/削除/編集を隠す） | **未実装（各エディタへの `GenbaPermission` 適用）**。判定モデルは用意済み |
| §6 共有解除後のローカルキャッシュ非表示 | **未実装**。共有現場をローカルに持たない設計なら自然に満たすが、実装/テストは次増分 |
| §8 Repository/Provider の owned+shared 対応 | **未実装（設計方針のみ）**。owner スコープを壊さず共有現場を別経路（サーバー権威）で扱う方針 |
| §9 メンバー画面を非オーナーも閲覧（管理は owner 限定） | **未実装**。非オーナーは現状 genba 本体へ到達不可のため、共有 read 配線後に対応 |
| §10 Deep Link | AASA/assetlinks は**プレースホルダ・未デプロイ**（`deeplink/README.md` に明記）。iOS `Runner.entitlements` は追加済みだが **Xcode project 未リンク**（`project.pbxproj` に `CODE_SIGN_ENTITLEMENTS` 無し）。Xcode で Associated Domains 有効化＋`CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` 設定が必要（本環境で安全に編集・検証できないため未実施） |
| §11 プロフィール画像 | **未実装**。`avatar_url` 列はあるが編集画面は表示名イニシャルのみ（アップロード未実装）。実装には Supabase Storage バケット＋本人限定 RLS が必要 |

### 検証状況

- `dart analyze lib test integration_test`（クリーン）・`GenbaPermission` テスト6件パス・全体テストパス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）・migration 0030/0031 実デプロイ・実 RLS/RPC 動作・共有 read/write の E2E・Deep Link 実機・iOS entitlements の Xcode リンク・プロフィール画像アップロードは Docker/Supabase/実機/Xcode 無しのため未検証。

## 共有現場アクセス レビュー是正: spot_links修正・共有一覧表示（2026-07-11, Claude Opus 4.8）

0031 のレビュー指摘（Critical）と、共有現場の一覧表示を是正・実装した。

| # | 判断 | 理由 |
|---|---|---|
| D-239 | (1) **Critical修正**: `itinerary_spot_links` は `plan_id` を持たず `spot_id` のみ。0031 で誤って `is_plan_member(plan_id)` を参照していた。`is_spot_member(p_spot)`（spot→plan→genba）を追加し、`itinerary_spot_links_select_member` を `is_spot_member(spot_id)` に修正。`apply_shared_mutation` の所属現場判定も、upsert は payload の `spot_id`→spot→plan→genba、delete は既存行の `spot_id`→spot→plan→genba に修正（`v_plan_tables` から spot_links を外し `v_is_spotlink` 分岐を追加）。(2) pgTAP 0017 に spot_links テスト6件（editor作成可・owner_id正規化・別現場spot_id拒否・viewer read可/write不可・未共有read不可）を追加（plan 14→20）。(3) **共有現場の一覧表示**（§1）: サーバー権威 `sharedGenbaSummariesProvider`（`genba_shares` を grantee_id=自分で取得し `genbas` を埋め込み結合）＋`SharedGenbaSummary` モデルを追加。現場一覧に「共有された現場」節を足し、各カードに**共有バッジ＋権限バッジ（編集可/閲覧のみ）**を表示。owned が空でも共有現場があれば空状態にしない。共有解除時は `genba_shares` から消えるため再取得で一覧から自然に消える | (1) スキーマ不整合の重大バグ。spot_links は spots 経由でしか所属現場を辿れない。(3) 共有現場をローカル owner スコープ store に混ぜると owner隔離（C-01）を壊すため、profiles/friends と同じ**サーバー権威の別経路**でサマリを取得し一覧へマージする。解除は取得元が消えるため追加のキャッシュ削除ロジック不要 |

### 実装

- Supabase（**静的・未実行**）: `0031_shared_genba_access.sql`（`is_spot_member` 追加・spot_links の policy と apply_shared_mutation を spot_id 経由へ修正）、pgTAP `0017`（spot_links 6件追加, plan 20）。
- クライアント: `lib/features/sharing/domain/shared_genba_summary.dart`、`member_providers.dart`（`sharedGenbaSummariesProvider`）、`genba_list_screen.dart`（「共有された現場」節・共有/権限バッジ）。
- tests: `test/widget/shared_genba_list_test.dart`（共有現場が一覧に出る・バッジ/権限表示・owned空でも空状態にしない・両方空なら空状態）。3件パス。

### 各要件の実装状況（正直な区分・前回 D-238 から更新）

| 要件 | 状況 |
|---|---|
| Critical: spot_links 修正 | **完了（静的）**。RLS/RPC を spot_id→spot→plan→genba へ修正。pgTAP で検証定義（**未実行**） |
| §1 共有現場を一覧表示（共有バッジ・権限） | **実装（現場一覧）**。`sharedGenbaSummariesProvider`＋「共有された現場」節。ホーム（当日ホーム）への表示は未（現場一覧のみ） |
| §3 genbaByIdProvider で共有現場取得・共有現場詳細/各タブ閲覧 | **未実装**。詳細は依然ローカル owner スコープのみ。共有現場をタップすると現状「現場が見つかりませんでした」（remote 集約取得＋各タブの source 非依存化は大規模な次増分） |
| §4 editor 書き込みを apply_shared_mutation へ | **未配線**。サーバー RPC は用意済み。クライアントの各エディタ→RPC 接続は未実装 |
| §5 viewer UI 制御（編集/保存/削除を非活性） | **未配線**。`GenbaPermission` は用意済み。各画面への適用は未実装 |
| §6 メンバー画面の非オーナー閲覧 | **未実装**（`genbaMembersProvider` はローカル owner スコープ。非オーナー閲覧は共有 read 配線後） |
| §7 共有解除後に一覧から消える | **一覧は満たす**（サーバー権威サマリの再取得で消える）。詳細/ローカルキャッシュ非表示は詳細配線後に検証 |

### 検証状況

- `dart format`（クリーン）・`dart analyze lib test integration_test`（クリーン）・widgetテスト（shared_genba_list 3件ほか）パス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。migration 0030/0031 実デプロイ・実 RLS/RPC・共有詳細/編集の E2E は未検証。

## 共有現場アクセス: 閲覧用詳細を実装（2026-07-11, Claude Opus 4.8）

一覧に出た共有現場をタップして開ける「閲覧用の共有現場詳細」を実装した。

| # | 判断 | 理由 |
|---|---|---|
| D-240 | (1) 共有現場はローカル owner スコープ store（Drift）に入れない（C-01 を壊さないため）。代わりに `SharedGenbaFetcher`（`SupabaseSharedGenbaFetcher`）が RLS 0031 の SELECT 権限で Supabase から genba＋子データ（todos/genba_memos/tickets/transports/lodgings）を直接取得し、閲覧用 `GenbaAggregate` を組み立てる。JSON(snake)→domain の写像は**状態が確定する表示フィールド**（表示名・日付・時刻・Todo名/完了・メモ・件数）を優先し、詳細ステータス enum は既定になり得るため件数用途に留める。(2) `sharedGenbaDetailProvider(genbaId)` は `myGenbaRolesProvider` から権限を求め、`canView==false`（未共有/共有解除後）なら aggregate=null で「表示できません」。(3) 専用の**閲覧専用** `SharedGenbaDetailScreen`（`/shared-genba/:id`）を新設し、owner の既存 `GenbaDetailScreen` は無改変。共有一覧カードのタップ先を `/genba/:id`→`/shared-genba/:id` に変更（旧「現場が見つかりませんでした」を解消）。(4) 権限バッジ（共有＋編集可/閲覧のみ）を表示。現状は全ロール閲覧専用で、editor の編集（`apply_shared_mutation` 配線）と計画/思い出/アルバムの取得は次増分 | (1) 共有データを owner スコープ Drift に混ぜると「owner_id=自分」の局所前提（C-01）を壊す。profiles/friends/一覧サマリと同じ**サーバー権威の別経路**に閉じる。(3) owner 詳細を触らず新画面にすることで既存の編集・同期経路への回帰リスクをゼロにする。(4) 閲覧を先に成立させ、編集は RLS 実検証後に安全に足す |

### 実装

- data: `lib/features/sharing/data/shared_genba_fetcher.dart`（`SharedGenbaFetcher`＋Supabase実装＋Unavailable・JSON→domain 写像）。
- application: `member_providers.dart`（`sharedGenbaFetcherProvider`・`sharedGenbaDetailProvider`・`SharedGenbaDetail`）。
- presentation: `shared_genba_detail_screen.dart`（閲覧専用・権限バッジ・概要/準備状況/Todo/メモ）。導線: `router.dart`（`/shared-genba/:id`）・`genba_list_screen.dart`（共有カードの遷移先変更）。
- tests: `test/widget/shared_genba_detail_test.dart`（viewer 閲覧可・閲覧のみバッジ・編集導線なし／editor 編集可バッジ／権限なし・共有解除で「表示できません」）。3件パス。

### 各要件の実装状況（正直な区分・D-239 から更新）

| 要件 | 状況 |
|---|---|
| §1 共有現場を一覧表示（共有/権限バッジ） | **実装済み**（現場一覧） |
| §1/§2/§3 共有現場を一覧から開ける・詳細/内容を閲覧 | **実装（閲覧専用）**: 概要・準備状況(件数)・Todo/持ち物・メモを表示。**計画/思い出/アルバムは未取得（次増分）** |
| §2 権限バッジ表示 | **実装済み**（共有＋編集可/閲覧のみ） |
| §3/§4 editor 書き込み（apply_shared_mutation 配線） | **未実装**。サーバー RPC は用意済み・pgTAP 定義済み（未実行）。クライアントの各エディタ→RPC 接続は未着手 |
| §3 viewer UI 制御 | **満たす（閲覧専用画面のため編集導線が存在しない）**。owner 詳細側の各エディタへの `GenbaPermission` 適用は editor 編集配線と同時の次増分 |
| §5/§7 共有解除後に見えなくなる | **満たす**: 一覧＝サマリ再取得で消える。詳細＝`myGenbaRoles` 再取得で権限が無くなり「表示できません」。直接 `/shared-genba/:id` でも権限判定で拒否 |
| §6 メンバー画面の非オーナー閲覧 | **未実装**（次増分） |

### 検証状況

- `dart format`（クリーン）・`dart analyze lib test integration_test`（クリーン）・widgetテスト（shared_genba_detail 3件ほか）パス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。migration 0030/0031 実デプロイ・実 RLS/RPC・共有取得/編集の E2E は未検証。JSON→domain 写像は実 Supabase 応答での検証が必要。

## 共有現場: editor編集(apply_shared_mutation)・詳細拡張・非オーナーメンバー閲覧（2026-07-11, Claude Opus 4.8）

共有現場詳細の表示範囲を拡張し、editor 編集を apply_shared_mutation へ接続、非オーナーの
メンバー閲覧を追加した。

| # | 判断 | 理由 |
|---|---|---|
| D-241 | (1) `SharedGenbaFetcher` を拡張し、計画（itinerary_plans→spots/legs）、思い出（memory_entries の感想）、グッズ（goods_items）、行った場所/食べたもの（visited_places の category 分け）、セットリスト（setlist_items）、写真件数（memory_photos）をサーバー権威で取得（`SharedGenbaData`）。editor CAS 用に Todo の版（todoVersions）も保持。(2) editor 書き込みは `SharedMutationClient`（`SupabaseSharedMutationClient`）＝**必ず `apply_shared_mutation` RPC 経由**（直接テーブル更新しない）。共有詳細の Todo をタップで完了トグル・削除を editor 用に配線（payload に genba_id を含め RPC の帰属検証を満たす、baseVersion=todoVersions）。viewer は編集導線を出さない（`GenbaPermission.canEditContent`）。owner 現場の編集は既存 apply_mutation のまま。(3) 非オーナーの**メンバー画面閲覧**（§4）: `genbaMembersProvider` に非オーナー経路を追加し、共有メンバーなら genba_shares をサーバーから読み（RLS 0031 の co-member SELECT）メンバー一覧＋自分の権限を**閲覧のみ**表示（管理＝追加/削除/権限変更/招待は owner 限定のまま）。共有詳細に「メンバーを見る」導線を追加。同一現場メンバーへのフレンド申請は維持 | (1) 完全身内前提で共有現場は原則全情報共有だが、閲覧用途では状態が確定する表示フィールドを優先し、複雑ステータス enum は件数用途に留めて写像リスクを抑える。(2) 既存 apply_mutation は owner_id=auth.uid 前提で共有では破綻するため、editor 書き込みは owner_id を現場owner へ正規化する apply_shared_mutation に一本化。UIの viewer 抑止＋サーバーの二層で守る。(3) 非オーナーもメンバーを見られるべき（§4）だが管理は owner 専用。genba 本体 read RLS が owner 限定でも genba_shares の co-member SELECT で一覧は出せる |

### 実装

- data: `shared_genba_fetcher.dart`（`SharedGenbaData`＋計画/思い出/グッズ/場所/セットリスト/写真取得）、`shared_mutation_client.dart`（apply_shared_mutation RPC クライアント＋Unavailable）。
- application: `member_providers.dart`（`sharedMutationClientProvider`・`SharedGenbaDetail.data`・`genbaMembersProvider` 非オーナー経路・`MembersView.isMember`）。
- presentation: `shared_genba_detail_screen.dart`（拡張read＋editor Todoトグル/削除＋メンバー導線）、`genba_members_screen.dart`（`_MemberReadOnlyView` 非オーナー閲覧）。
- tests: `shared_genba_detail_test.dart`（viewer 拡張read・編集導線なし／editor Todoトグル→apply呼び出し／editor 削除→apply delete／権限なし非表示）、`genba_members_screen_test.dart`（非オーナー閲覧・管理導線なし）、`shared_genba_list_test.dart`（一覧）。

### 各要件の実装状況（正直な区分・D-240 から更新）

| 要件 | 状況 |
|---|---|
| §1 共有現場詳細の表示範囲拡張（計画/スポット/移動区間/チケット/交通/宿泊/思い出/写真/グッズ/場所） | **実装（閲覧）**: 計画（スポット名・移動件数）・思い出（感想・グッズ・場所・食べもの・セットリスト曲数・写真件数）・チケット/交通/宿泊（件数）。個別行の全項目編集UIまでは持たない |
| §2 editor 編集導線（apply_shared_mutation） | **実装（Todo 完了トグル・削除）**。Todo以外（持ち物/メモ/計画等）の編集フォームは同じ `SharedMutationClient` で順次追加（未実装） |
| §2 viewer 編集不可 | **実装**（editor のみ編集導線を出す。サーバー RPC も viewer 拒否・pgTAP定義） |
| §2 owner限定（削除/オーナー変更/メンバー管理/招待） | **維持**（apply_shared_mutation の allowlist 外・owner 経路のまま） |
| §3 共有解除後に開けない/一覧から消える/ローカルに混ぜない | **満たす**（サーバー権威・`myGenbaRoles` 再取得で権限喪失→「表示できません」・Drift owner スコープに混ぜない） |
| §4 非オーナーのメンバー閲覧（管理は owner 限定・フレンド申請維持） | **実装** |

### 検証状況

- `dart format --output=none --set-exit-if-changed`（クリーン）・`dart analyze lib test integration_test`（クリーン）・widgetテストパス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。migration 0030/0031 実デプロイ・実 RLS/RPC（apply_shared_mutation の editor/owner_id正規化/帰属検証・viewer拒否・共有解除拒否）・JSON→domain 写像・Deep Link 実機は未検証。editor 編集は Todo トグル/削除のみ配線（他項目は次増分）。

## 共有現場: apply_shared_mutation の status 解析（競合の握りつぶし修正）（2026-07-12, Claude Opus 4.8）

editor 書き込みの RPC 戻り値を確認していなかった不具合を修正した。

| # | 判断 | 理由 |
|---|---|---|
| D-242 | `SharedMutationClient` は `apply_shared_mutation` の戻り値 `{status, version}` を無視し、例外が無ければ常に成功扱いだった（`status: conflict` でも成功に見える）。純粋関数 `parseSharedMutationResult(res)` を追加し、`applied`→`Ok`／`conflict`→`ConflictFailure`／未知・null・非Map・status欠落→失敗（成功扱いにしない）へ変換。クライアントは RPC 応答をこの関数で必ず解析する。共有詳細の editor 操作は競合時に「他のメンバーが先に更新しました。画面を再読み込みしてください」を SnackBar 表示し、`sharedGenbaDetailProvider(genbaId)` を invalidate して最新状態を取り直す | 版CAS（apply_shared_mutation は base_version 不一致で conflict を返す）を握りつぶすと、editor に「保存できた」と誤認させ、他メンバーの更新を上書きしたように見える。楽観ロックの結果は必ず解釈し、競合はユーザーへ通知して再読み込みへ導く必要がある |

### 実装

- `shared_mutation_client.dart`: `parseSharedMutationResult` 追加・`apply` が RPC 応答を解析。
- `shared_genba_detail_screen.dart`: `_write` が `ConflictFailure` で invalidate＋SnackBar。
- tests: `test/data/shared_mutation_client_test.dart`（applied→Ok・conflict→ConflictFailure・未知/null/欠落→失敗）、`test/widget/shared_genba_detail_test.dart`（editor 競合時 SnackBar・editor 更新/削除は RPC 経由・viewer 編集導線なし）。

### editor 編集の実装範囲（誤解防止・正確な表現）

「共同編集」は**未完了**。現時点で editor が共有現場を**編集できるのは Todo・持ち物の完了トグルと削除のみ**（`apply_shared_mutation` RPC 経由）。**メモ・計画・スポット・移動区間・思い出・写真/アルバム・チケット・交通・宿泊の編集は未実装**（今後、同じ `SharedMutationClient` で追加）。閲覧は概要/Todo/持ち物/メモ/計画（スポット・移動件数）/思い出（感想・グッズ・場所・食べもの・セットリスト・写真件数）まで。

### 検証状況

- `dart format --output=none --set-exit-if-changed`（クリーン）・`dart analyze lib test integration_test`（クリーン）・widget/unit テストパス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。実 `apply_shared_mutation` の conflict/applied 応答での動作、migration 0030/0031 実デプロイ、JSON→domain 写像、Deep Link 実機は未検証。

## 共有現場: editor メモ共同編集（増分・apply_shared_mutation経由）（2026-07-12, Claude Opus 4.8）

editor が共有現場のメモを追加・編集・削除できるようにした（Todo/持ち物に続く増分）。

| # | 判断 | 理由 |
|---|---|---|
| D-243 | 共有現場詳細の**メモ**を editor 用に追加/編集/削除できるようにした。保存は必ず `SharedMutationClient`→`apply_shared_mutation` RPC（entity_table='genba_memos'）。追加は payload に `category:'free'`（genba_memos.category は NOT NULL・既定なし）を含め、新規 id は Uuid で生成。編集は `{id, genba_id, title, body}`＋baseVersion=メモ版（`SharedGenbaData.memoVersions`）。削除は `{id}`＋baseVersion。conflict は既存どおり `ConflictFailure`＋SnackBar＋再取得（D-242）。viewer には追加/編集/削除導線を出さない（`GenbaPermission.canEditContent`）。owner 限定操作（現場削除・メンバー管理・招待）は不変 | Todo/持ち物のみだった editor 編集を、要望どおり**まずメモだけ**安全に増分。genba_memos は apply_shared_mutation の allowlist に既に含まれ、owner_id は RPC が現場ownerへ正規化するため editor 本人IDにならない。category 必須列を補うことで INSERT を成立させる |

### 実装

- `shared_genba_fetcher.dart`: `SharedGenbaData.memoVersions`（メモ版）を追加・genba_memos 行から収集。
- `shared_genba_detail_screen.dart`: メモ節に editor の「追加」ボタン・カードタップ編集・削除ボタン、`_MemoEditorDialog`（title/body）、`_addMemo`/`_editMemo`/`_deleteMemo`（apply_shared_mutation 経由）。
- tests: `test/widget/shared_genba_detail_test.dart`（editor メモ 追加[category=free]/編集/削除・viewer はメモ編集導線なし・競合通知）、`test/data/shared_mutation_client_test.dart`（status 解析）。

### editor 編集の実装範囲（正確な表現・共同編集は未完了）

editor が共有現場を**編集できるのは Todo・持ち物（完了トグル/削除）とメモ（追加/編集/削除）のみ**。**計画・スポット・移動区間・思い出・写真/アルバム・チケット・交通・宿泊の編集は未実装**（閲覧は可）。今後、同じ `SharedMutationClient` で増分する。

### 検証状況

- `dart format --output=none --set-exit-if-changed`（クリーン）・`dart analyze lib test integration_test`（クリーン）・widget/unit テストパス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。実 `apply_shared_mutation`（genba_memos の upsert/delete・owner_id正規化・帰属検証・conflict）、migration 0030/0031 実デプロイ、JSON→domain 写像、Deep Link 実機は未検証。

## 共有現場: 構造化メモ（4種類）の閲覧・共同編集（2026-07-12, Claude Opus 4.8）

共有現場のメモを free/checklist/bingo/vote の4種類に対応させ、既存のメモエディタを再利用した。

| # | 判断 | 理由 |
|---|---|---|
| D-244 | (1) `SharedGenbaFetcher` の genba_memos 変換で `category`/`kind`/`content`/`sort_order` を復元。`content` は Supabase jsonb（Map）/まれに JSON文字列の両方を `MemoContent.fromJson` で復元。(2) `SharedGenbaDetailScreen` のメモ表示を種類別（`_MemoView`）に: free=タイトル/本文、checklist=項目＋チェック状態、bingo=サイズ/マス/選択/BINGO判定、vote=説明/選択肢/得票/重複可否。(3) editor の追加・編集は**既存のメモエディタUI/ロジックを再利用**（`showAddMemoFlow`/`showMemoEditor`）。保存だけを差し替える `MemoSubmit`（`onSubmit`）コールバックを追加し、null=owner通常保存（`upsertMemo`）、指定時=共有の apply_shared_mutation 経由（`_applySharedMemo` が kind/content/category/title/body/sort_order を送る）。共有時はシート内の削除ボタンを隠し、削除は共有詳細カード側の `apply_shared_mutation` delete に一本化。(4) 楽観CASは memoVersions（baseVersion）で維持。conflict は D-242 どおり通知＋再取得。viewer は追加/編集/削除導線を出さない | 共有画面が title/body の自由メモ扱いに留まり、構造化メモが表示・編集できていなかった。エディタを二重実装せず、保存経路だけ差し替えることで UI/ドメインロジック（checklist/bingo/vote 編集・BINGO/投票の純粋ロジック）を完全再利用でき、kind/content を壊さない |

### 実装

- `shared_genba_fetcher.dart`: `_memo` が category/kind/content/sort_order を復元（`_memoContent`/`_enumByName`）。
- `memo_editors.dart`: `typedef MemoSubmit`＋`onSubmit` を `showAddMemoFlow`/`showMemoEditor`/`_MemoEditorSheet._save` に配線、共有時はシート内削除を非表示。
- `shared_genba_detail_screen.dart`: `_MemoView`/`_BingoView`/`_VoteView`（種類別閲覧）、`_applySharedMemo`/`_openMemoAdd`/`_openMemoEdit`（再利用エディタ＋apply_shared_mutation）。
- tests: `shared_genba_detail_test.dart`（viewer が checklist/bingo/vote を閲覧・BINGO判定表示／editor が checklist/bingo/vote を編集[kind維持で genba_memos upsert]／editor が種類選択フローで自由メモ追加／削除／競合通知）、`shared_mutation_client_test.dart`。

### editor 編集の実装範囲（正確な表現・共同編集は未完了）

editor が編集できるのは **Todo・持ち物（完了トグル/削除）とメモ（free/checklist/bingo/vote の追加/編集/削除）**。**計画・スポット・移動区間・思い出・写真/アルバム・チケット・交通・宿泊の編集は未実装**（閲覧は可）。

### 検証状況

- `dart format --output=none --set-exit-if-changed`（クリーン）・`dart analyze lib test integration_test`（クリーン）・widget/unit テストパス。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。実 `apply_shared_mutation`（genba_memos の content jsonb 書き込み・owner_id正規化・conflict）、migration 0030/0031 実デプロイ、content の JSON⇄domain 実応答検証、Deep Link 実機は未検証。

## 共有現場: 計画スポット・移動区間・思い出テキストの共同編集（2026-07-12, Claude Opus 4.8）

editor の共同編集を Todo/持ち物/メモに続き、計画スポット・移動区間(削除)・思い出テキストへ拡張した（要望の優先順位: 計画スポット→移動区間→思い出、写真/アルバムは次増分）。

| # | 判断 | 理由 |
|---|---|---|
| D-245 | (1) **計画スポット(itinerary_spots)**: editor が追加/編集/削除できる。owner 用の Google Places 連携UIは共有現場で誤爆すると危険なため**流用せず**、名前＋種別（category の check 制約に一致する代表値ドロップダウン）だけの**共有専用の小さなダイアログ**(`_SpotEditorDialog`)で手入力する。保存は `apply_shared_mutation`(entity_table='itinerary_spots')。追加/編集とも payload に `plan_id`(=`SharedGenbaData.firstPlanId`／既存スポットの planId)を含め、RPC が plan→genba を辿って現場所属を検証する。追加は新規 Uuid・baseVersion=null、編集は既存 version、削除は `{id}`＋version。(2) **移動区間(itinerary_legs)**: origin/destination_entry_id が NOT NULL（itinerary_entries 参照）で追加/編集は端点選択UIが要るため**削除のみ**対応（apply delete＋version）。追加/編集は次増分と明記。(3) **思い出テキスト(memory_entries)**: editor が感想(impression)/ベストシーン(best_moment)を編集できる（`_MemoryEditorDialog`）。memory_entries は1現場1行のため既存行が無ければ新規作成（新規 Uuid・baseVersion=null、既存は version）。payload に `genba_id`。(4) 楽観CASは各行の version(baseVersion)で維持。conflict は D-242 どおり ConflictFailure→SnackBar＋再取得（成功扱いにしない）。viewer には追加/編集/削除導線を一切出さない（`GenbaPermission.canEditContent`）。owner 限定操作（現場削除・メンバー管理・招待）は不変 | itinerary_spots/itinerary_legs/memory_entries は apply_shared_mutation の allowlist に既に含まれ、owner_id は RPC が現場ownerへ正規化する。スポットは owner UI(Places)を流用すると外部呼び出し・権利根拠列などが絡み危険なので、name/category だけの安全な共有専用UIに限定。legs は端点が entries 参照で複雑なため、安全な削除だけを今回の増分に含め、追加/編集は正直に繰り越す |

### 実装

- `shared_genba_fetcher.dart`: `SharedSpot`(id/planId/name/category/version)・`SharedLeg`(id/label/version)・`SharedMemory`(id/version 追加)へ拡張。`SharedGenbaData` に `firstPlanId`・`legs` を追加（`legCount` は撤去）。itinerary_spots は `id,plan_id,name,category,version`、itinerary_legs は `id,travel_mode,duration_minutes,version`（`_legLabel` で日本語ラベル化）、memory_entries は `id,impression,best_moment,version` を取得。
- `shared_genba_detail_screen.dart`: 計画スポット節（追加ボタン`spot_add_button`・カードタップ編集・削除）、移動区間節（削除のみ・「追加/編集は準備中」注記）、思い出節（`memory_edit_button` で感想編集・空でも editor は追加導線）。`_SpotEditorDialog`/`_MemoryEditorDialog`（共有専用）、`_openSpotAdd`/`_openSpotEdit`/`_deleteSpot`/`_deleteLeg`/`_openMemoryEdit`。フッタ注記を実装範囲に合わせ更新。
- tests: `shared_genba_detail_test.dart`（editor がスポット追加[plan_id付き]/編集[既存version]/削除・移動区間削除・思い出感想編集[genba_id付き]・viewer に編集導線なし・スポット追加の競合通知）。
- `supabase/tests/0017_shared_genba_access.sql`（**静的・未実行**）: plan を24へ拡張し、editor のスポット編集/思い出新規作成(owner正規化)/移動区間削除（entries＋leg を owner 準備）を追加。

### editor 編集の実装範囲（正確な表現・共同編集は未完了）

editor が編集できるのは **Todo・持ち物（完了トグル/削除）／メモ（free/checklist/bingo/vote の追加/編集/削除）／計画スポット（追加/編集/削除）／移動区間（削除のみ）／思い出テキスト（感想・ベストシーンの編集）**。**移動区間の追加/編集・写真/アルバム・チケット・交通・宿泊・グッズ/行った場所/食べたもの/セットリストの編集は未実装**（閲覧は可）。今後、同じ `SharedMutationClient` で増分する。

### 検証状況

- `dart format --output=none --set-exit-if-changed lib test integration_test`（クリーン）・`dart analyze lib test integration_test`（クリーン・No issues found）・`flutter test`（997 パス）。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。実 `apply_shared_mutation`（itinerary_spots/itinerary_legs/memory_entries の upsert/delete・plan_id/genba_id 帰属検証・owner_id正規化・conflict/applied 応答）、migration 0030/0031 実デプロイ、JSON→domain 写像、Deep Link 実機は未検証。

## 共有現場: 計画スポット編集の是正（カテゴリ整合・計画未作成の案内）（2026-07-12, Claude Opus 4.8）

D-245 の共有スポット編集UIに残っていた通常計画スポット仕様との差分を是正した。

| # | 判断 | 理由 |
|---|---|---|
| D-245b | (1) 共有スポット編集のカテゴリ選択肢を、手書きの独自マップから**単一の情報源 `ItinerarySpotCategory` 由来**へ変更（`ItinerarySpotCategory.values` を `wireValue`＋`label` で列挙）。これにより通常計画スポットとカテゴリ一覧がズレず、**聖地(sacred_place) を含む全15カテゴリ**が並ぶ。`wireValue` は `@JsonValue` と一致する snake_case を返す拡張として itinerary_spot.dart に追加し、`toJson` の値と全カテゴリで一致することを round-trip テストで担保（drift 防止）。(2) 既存スポットの編集時、カテゴリが選択肢に無い未知値でも `other` に落とさず、その値自体を選択肢として保持して保存する（`sacred_place` は既知値なので当然保持される）。表示ラベルも wire→label で引き、未知値は wire をそのまま表示。(3) 共有現場に itinerary_plan がまだ無い（`hasPlan == false`）場合、editor には「計画はまだ作成されていません。オーナーが計画を作成すると共同編集できます。」と**案内表示**し、追加導線（`spot_add_button`）は出さない。**editor に計画本体(itinerary_plans)の作成は開放しない**（安全側）| 共有UIが独自のカテゴリ短縮ラベル・部分集合を持ち、聖地が欠落し、未知カテゴリが other に化ける差分があった。enum を単一の情報源にすれば将来のカテゴリ追加も自動追随する。計画作成の editor 開放は apply_shared_mutation allowlist（現状 plan 配下の子データのみ）・RLS・pgTAP の追加が必要で、盲目実装は C-01/権限境界のリスクがあるため、要望どおり**安全優先で案内表示に留める** |

### 共有計画スポット編集の条件（正確な表現）

- **既存 plan がある場合**: editor は計画スポットを**追加・編集・削除**できる（`apply_shared_mutation`・`plan_id` で帰属検証・各行 version で CAS）。カテゴリは通常計画スポットと同一の `ItinerarySpotCategory`（聖地含む全15種）。
- **plan 未作成の場合**: editor でも共有現場からは計画本体を作成できないため、**案内表示のみ**（追加導線を出さない）。オーナーが計画を作成後に共同編集可能。
- **移動区間**: 削除のみ対応。追加/編集は端点（entries）選択UIが要るため**次増分**。

### 検証状況

- `dart format --output=none --set-exit-if-changed lib test integration_test`（クリーン）・`dart analyze lib test integration_test`（No issues found）・`flutter test test/widget/shared_genba_detail_test.dart`＋`test/domain/itinerary_json_test.dart`（パス・カテゴリ整合/未知値保持/計画未作成案内/wireValue drift防止を追加）。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。計画本体作成の editor 開放は未実装（apply_shared_mutation/RLS/pgTAP 未対応）。

## 共有現場: 移動区間(追加/編集)・チケット/交通/宿泊・思い出リスト・写真の共同編集（2026-07-13, Claude Opus 4.8）

editor の共同編集を、残っていた対象（移動区間の追加/編集、チケット/交通/宿泊、グッズ/行った場所/食べたもの/セットリスト、写真メタデータ）へ拡張した。すべて `apply_shared_mutation` 経由・version による baseVersion CAS・viewer 導線なし。

| # | 判断 | 理由 |
|---|---|---|
| D-246 | (1) **移動区間(itinerary_legs)**: 追加/編集を実装。端点 origin/destination は旅程項目（itinerary_entries）から選ぶ共有専用ダイアログ（`_LegEditorDialog`）。payload に `plan_id`＋`origin_entry_id`/`destination_entry_id`/`travel_mode`/`duration_minutes`。plan で g1 帰属検証。端点が2つ未満なら追加不可の案内。(2) **チケット/交通/宿泊(tickets/transports/lodgings)**: 追加/編集/削除を実装。owner の詳細UI（Google/画像連携等）は流用せず、主要フィールドだけの共有専用ダイアログ。ステータス/交通手段/往復は check 制約に一致するコードのドロップダウン（`TransportMethod`/`TicketAcquisition` 等の既存 enum に整合）。payload に `genba_id`。(3) **グッズ/行った場所/食べたもの/セットリスト(goods_items/visited_places/setlist_items)**: 追加/編集/削除。visited_places は category=spot/food で「行った場所」「食べたもの」を切替。setlist は position を末尾自動採番。(4) **写真/アルバム(memory_photos)**: 一覧表示＋caption/cover 編集＋行削除のみ。**画像本体アップロード・サムネイル表示は本増分の対象外**（メンバー用 Storage の read/write ポリシー未実装＝安全側で次増分・UIに明記）。(5) 全て version(baseVersion) で CAS、conflict は D-242 どおり ConflictFailure→SnackBar＋再取得（成功扱いにしない）。viewer には追加/編集/削除導線を一切出さない（`canEditContent`）。owner 限定操作（現場削除・メンバー管理・招待）は不変 | 対象テーブルは apply_shared_mutation の allowlist（v_genba_tables / v_plan_tables）に既に含まれ、owner_id は RPC が現場ownerへ正規化する（0006 で version 列・bump トリガも付与済み）。owner 用UIは外部連携や画像で誤爆リスクが高いため、apply_shared_mutation に渡す主要フィールドだけの共有専用ダイアログに分離。写真の画像アップロードは Storage のメンバー書き込みポリシー（未実装）が要るため、DB行のメタデータ編集/削除のみ安全に開放し画像本体は繰り越す |

### 実装

- `shared_genba_fetcher.dart`: `SharedEntry`（端点候補）・`SharedTicket`/`SharedTransport`/`SharedLodging`/`SharedGoods`/`SharedVisitedPlace`/`SharedSetlistItem`/`SharedPhoto` を追加。`SharedLeg` を端点/交通手段/所要付きへ拡張。`SharedGenbaData` に entries/tickets/transports/lodgings/goods/visitedPlaces(spot+food)/setlist/photos を追加（`visitedSpots`/`foods` getter）。fetch はチケット/交通/宿泊を既存 select から shared へ写像し、entries/legs/goods/visited/setlist/photos をフル取得。`legTravelModes`/`legTravelModeLabel` 追加。
- `shared_edit_dialogs.dart`（新規）: 共有専用の軽量編集ダイアログ群（leg/ticket/transport/lodging/goods/place/setlist/photo）と Draft・ステータス選択肢。
- `shared_genba_detail_screen.dart`: `_upsert`/`_deleteRow` 共通化。各エンティティのハンドラ・セクション（移動区間 add/edit、チケット/交通/宿泊、グッズ/行った場所/食べたもの/セットリスト、写真）。`_simpleSection` で一覧セクションを共通化。フッタ注記を実装範囲に更新。
- tests: `shared_genba_detail_test.dart`（editor: 移動区間 追加[端点選択]/編集[交通手段変更]、チケット 追加/削除、交通/宿泊/グッズ/行った場所/食べたもの/セットリスト 追加、写真 caption 編集/削除。viewer: 全セクションの追加・削除導線なし。競合は成功扱いにしない）。縦長化に伴いテストのビューポート高を拡大。
- `supabase/tests/0017_shared_genba_access.sql`（**静的・未実行**）: plan を35へ拡張し、editor の leg 追加・チケット(owner正規化含む)/交通/宿泊/グッズ/行った場所/セットリスト/写真 作成・チケット削除・viewer 書込拒否を追加。

### editor 編集の実装範囲（正確な表現）

editor が編集できるのは **Todo・持ち物／メモ（4種類）／計画スポット／移動区間（追加/編集/削除）／チケット／交通／宿泊／思い出テキスト（感想）／グッズ／行った場所／食べたもの／セットリスト／写真（caption/cover 編集・削除）**。**写真の画像アップロード（Storage メンバー書き込み）・計画本体(itinerary_plans)作成の editor 開放は未実装**（次増分）。

### 検証状況

- `dart format --output=none --set-exit-if-changed lib test integration_test`（クリーン）・`dart analyze lib test integration_test`（No issues found）・`flutter test`（1013 パス）。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017）は Docker/Supabase 未導入で未実行。実 `apply_shared_mutation`（各テーブルの upsert/delete・帰属検証・owner_id 正規化・conflict）、Storage メンバー read/write（写真画像）、migration 実デプロイは未検証。

## 共有現場: 計画本体を editor allowlist から除外・写真カバーの安全切替（2026-07-13, Claude Opus 4.8）

レビュー指摘に基づく共同編集の是正2点。

| # | 判断 | 理由 |
|---|---|---|
| D-247 | (1) **計画本体(itinerary_plans)を apply_shared_mutation の allowlist から除外**。`0031_shared_genba_access.sql` の `v_genba_tables` から `itinerary_plans` を外し、editor は計画本体の作成/更新/削除ができない（`table not editable via shared mutation` 22023）。**editor による計画本体作成・編集は未開放**という仕様（UI の「オーナーが計画を作成すると共同編集できます」案内・docs）と RPC を一致させた。計画配下の子データ（itinerary_spots/entries/legs は v_plan_tables、itinerary_spot_links は spot 経由）の共同編集は維持。(2) **写真カバー(memory_photos.is_cover)の安全切替**。`idx_memory_photos_cover_unique`（`(genba_id) where is_cover` の部分ユニーク）により1現場1カバー。editor が別写真を is_cover=true で保存すると unique 衝突し得たため、apply_shared_mutation 内に **RPC 内特別処理**を追加: memory_photos の upsert かつ payload `is_cover=true` のとき、対象行を書く直前（既存行は version CAS 通過後、新規行は insert 前）に `update memory_photos set is_cover=false where genba_id = p_genba and is_cover and id <> p_entity_id` で同一現場の他カバーを落とす。SECURITY DEFINER・genba 帰属チェック（v_row_genba = p_genba）・editor 判定は従来どおりサーバー側で先に実施し、他現場の写真は触らない。対象写真の version CAS は不変（他写真の version は trigger で進むが、それは正しい更新であり成功後にクライアントが再取得する） | (1) 仕様・UI・docs では「計画本体は editor 未開放」なのに RPC allowlist にだけ残っていた不整合を解消。(2) カバーは「最後に指定した1枚」を優先する自然な挙動が期待され、unique 制約で失敗させるべきでない。クリアをクライアントに任せると2回の RPC・競合窓が生じるため、サーバー1トランザクション内で原子的に行うのが安全。CAS は対象写真の版で維持する |

### 実装

- `supabase/migrations/0031_shared_genba_access.sql`: `v_genba_tables` から `itinerary_plans` を削除（ヘッダ/宣言にコメント）。`v_clear_cover` を追加し、upsert の既存行パス（CAS 後）と新規行パス（insert 前）で同一現場の他カバーを false 化。
- `supabase/tests/0017_shared_genba_access.sql`（**静的・未実行**）: plan を43へ拡張。負例（editor は itinerary_plans を upsert/delete 不可・plan 本体は不変）、カバー切替（既存カバーありでも別写真をカバー化でき、現場内カバーは常に1枚・旧カバーは false・他現場 g2 の写真は 42501 で触れない）を追加。g2 の写真を setup に追加。
- `test/widget/shared_genba_detail_test.dart`: 既存カバーがある状態で別写真をカバーにすると、クライアントが対象写真へ `is_cover:true` を送ることを検証（サーバー側の他カバー解除は pgTAP で担保）。

### 影響のない範囲（回帰防止）

- Todo・メモ・計画スポット・移動区間・チケット・交通・宿泊・思い出・グッズ・行った場所・食べたもの・セットリストの共同編集は不変。viewer に編集導線を出さない仕様、owner 専用（現場削除・メンバー管理・招待）も不変。クライアントは元々 itinerary_plans を書かないため UI 変更なし。

### 検証状況

- `dart format`（クリーン）・`dart analyze lib test integration_test`（No issues found）・`flutter test`（全パス）・`git diff --check`（空白エラーなし）。
- **未実施（成功扱いにしない）**: `supabase db reset`/`supabase test db`（pgTAP 0016/0017・**Docker/Supabase 未導入**）。実 RPC での allowlist 除外・カバー切替の原子性・帰属チェックは未検証（静的）。

## Supabase ローカル実行の安定化（profiles 二重定義・GRANT・apply_mutation 修正）（2026-07-13, Claude Opus 4.8）

`supabase start` が 0030 適用時に `relation "profiles" already exists` で停止していた問題を起点に、`supabase db reset`/`supabase test db` がローカル（Docker）で全通するまで安定化した。

| # | 判断 | 理由 |
|---|---|---|
| D-248 | (1) **profiles 二重定義の解消**: 0001 が `profiles(id uuid primary key)` を作成済みなのに 0030 が `profiles(user_id ...)` を再 create していた。0030 を **`create table` 廃止→`alter table` で社会機能列を追加**へ変更し、主キーは既存の `id` を正とする（`user_id` に戻さない）。0030 内の `profiles.user_id` 参照（`can_view_profile`/`profiles_select_visible`/`send_friend_request`/`get_invite_preview`）を `id` に統一。`SupabaseProfileRepository` も `id` 基準に修正（`r['id']`→`Profile.userId`・`.eq('id', uid)`・upsert `id`）。DELETE ポリシーは追加しない（0005 の「本人でも直接 DELETE 不可」を維持）。(2) **テーブル GRANT 追加（0032・最小権限）**: 本プロジェクトは RLS と per-function grant のみでテーブル GRANT が無く、`set local role authenticated`/`anon` の pgTAP や PostgREST が `permission denied` になっていた。anon/authenticated には **DML のみ**（TRUNCATE/TRIGGER/REFERENCES は与えない）、`grant execute on all routines` は**付けない**（内部関数は service_role 専用のまま・per-function grant が既存）、service_role のみ ALL。(3) **apply_mutation/apply_shared_mutation の conflict 判定バグ修正**: 動的 `EXECUTE` は `FOUND` を設定しないため `if not found` が効かず、別ユーザー既存行への upsert が `conflict` でなく `applied`（version null）を返していた（データ改変は無し＝実DBで確認）。`if v_current is null` 判定へ修正（最終定義 0028・0031）。(4) 既存 pgTAP（0001〜0017）の未実行由来の不具合を是正: `throws_ok` の期待メッセージ枠に説明文を渡していた誤用へ `null` を挿入、`authenticated` ロールでの `create function`/`drop index` を role 変更前/`reset role` へ、モデレーション承認の service_role 切替、参照先の transports/lodgings 未作成を補完 等 | ローカル/クラウドで Supabase を実運用するにはテーブル GRANT が必須（RLS は行制御、GRANT はテーブル層）。conflict 誤報は同期の破綻に繋がるため修正。テストは初回実行で顕在化した既存バグで、機能側の挙動は正しい（RLS/CHECK は正しく拒否している）ことを実DBで確認して是正 |

### 検証状況

- `supabase start`（0030 で停止せず全適用）・`supabase db reset`（成功）・`supabase test db`（**17→18 ファイル・323→334 テスト・Result: PASS**）。`dart analyze`（No issues）・`flutter test`（全緑）。実DB（psycopg2）で apply_mutation の非改変を確認。

## フレンドコードによるフレンド追加・招待「おすすめ」表記削除（2026-07-13, Claude Opus 4.8）

アカウントごとの一意なフレンドコードを追加し、コードからフレンド申請できるようにした。招待URLのロール選択から「おすすめ」表記を削除した。

| # | 判断 | 理由 |
|---|---|---|
| D-249 | (1) `profiles.friend_code`（**NOT NULL / UNIQUE / 形式 CHECK**・サーバー採番）を migration 0033 で追加。生成は `gen_random_bytes`＋読みやすい32文字英数字（曖昧文字 0/1/I/O を除外）で `OSHI-XXXX-XXXX`。`gen_unique_friend_code` が衝突時に再生成し、UNIQUE 索引を最終ガードにする。**BEFORE INSERT トリガ**で新規プロフィールに自動採番（`handle_new_user` 経由の作成も含む）、**既存ユーザーは backfill**（1行ずつ一意採番）。**フレンドコードはサーバー採番専用＝本人でも変更・設定できない**（レビュー是正）: (a) 形式 CHECK `^OSHI-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$`、(b) profiles のテーブル INSERT/UPDATE 権限を anon/authenticated から剥がし**編集可能列のみ**（display_name/avatar_url/bio/favorite_name/accepts_friend_requests/searchable）を列指定で再付与（friend_code/id/created_at/updated_at は除外＝列権限で書けない）、(c) BEFORE UPDATE `enforce_friend_code_immutable` トリガで採番済み値の変更を拒否（多層防御・null→採番は許可）、(d) 内部関数 `gen_friend_code`/`gen_unique_friend_code`/`set_profile_friend_code`/`enforce_friend_code_immutable` は public から execute revoke（`send_friend_request_by_code` のみ authenticated へ公開）。実DB（PostgREST）で「display_name 編集は 200／friend_code 変更は 42501 で拒否・値は不変」を確認。(2) `send_friend_request_by_code(text)` を追加。**コード完全一致のみ**で相手を特定する（部分一致・列挙はしない＝無制限検索を維持）。コードを知っていることを明示的な到達手段とみなし、**`searchable=false` でも申請できる**。自分自身のコード・存在しないコード・空文字は拒否。ブロック・受付可否・状態機械（相互申請の自然化・rejected 再申請）は既存 `send_friend_request` と同一。**既存 `send_friend_request(uuid)` は無改変**（同一現場メンバー/searchable の経路は従来どおり）。(3) Flutter: `Profile.friendCode`（既定 '' で既存構築を壊さない・`copyWith` で保持）、`SupabaseProfileRepository` が `friend_code` 取得、`FriendRepository.sendRequestByCode`＋`SupabaseFriendRepository`（RPC）＋`UnavailableFriendRepository`（UnavailableFailure）、フレンド画面に自コード表示（コピー可）＋「フレンドコードで追加」ダイアログ（controller は専用 StatefulWidget で破棄）。(4) 招待URLのロール選択UIの「閲覧のみ（おすすめ）」から**「おすすめ」表記を削除**（viewer 既定は維持・UI で誘導しない）。RLS/RPC の責務はサーバー側で保証し UI 判定に依存しない | フレンドは searchable でなくても「コードを直接伝える」明示的手段で繋がりたい需要がある。コード完全一致は列挙不能なので無制限検索禁止の方針と両立する。主キーは `id` のまま（D-248 と整合）。「おすすめ」はプロダクトが権限選択を誘導しないための表記削除 |

### 実装

- `supabase/migrations/0033_friend_codes.sql`（friend_code 列・生成/一意化関数・採番トリガ・backfill・NOT NULL/UNIQUE・`send_friend_request_by_code`）。
- `supabase/tests/0018_friend_codes.sql`（plan 11: 一意・全員採番・形式・コード申請 pending・自コード拒否・存在しないコード拒否・空拒否・searchable=false 可・メンバー経由申請回帰・無制限検索禁止維持）。
- `profile.dart`/`profile_repository_impl.dart`/`friendship.dart`/`friend_repository_impl.dart`/`friends_screen.dart`/`genba_members_screen.dart`（おすすめ削除）。
- tests: `friends_screen_test.dart`（自コード表示/コピー・コードで申請）、`profile_test.dart`（friendCode 保持/既定）、`friend_repository_test.dart`（Unavailable）、`genba_members_screen_test.dart`（fake に sendRequestByCode）。

### 検証状況

- `dart format`・`dart analyze lib test integration_test`（No issues）・`flutter test`（全緑）・`supabase db reset`＋`supabase test db`（18ファイル/334テスト PASS）・`git diff --check`（空白エラーなし）。

## 現場一覧カードの「デジタル半券」刷新（2026-07-14, Claude Fable 5）

現場一覧のカードUIを、淡い紫基調の半券（チケット）モチーフへ刷新した。

| # | 判断 | 理由 |
|---|---|---|
| D-250 | (1) `EventListCard`（design system）の通常バリアントを半券構成へ: 面は白〜淡紫のごく控えめな斜めグラデーション（`AppTokens.primarySoft` α.30）、左端は推しカラーの縦色帯（4px）、日付は紫（primary）＋等幅数字、右上の残日数は常にピル（残7日以内=推しカラー×暁の温感／未来=淡紫／過去=無彩）、本文と準備ステータスの間に**ミシン目（破線, `_PerforationPainter`）**。階層は**アーティスト名（主見出し w800）→ 公演名（1〜2行省略）→ 会場（📍つき1行省略）**へ変更（subtitle 未指定の従来利用は旧階層のまま＝HOME minimal・他利用は不変）。(2) 準備チップを Material `Chip` から小型ピル `_PrepPill` へ（アイコン13px＋labelSmall w600）: 完了=淡紫面＋紫字／進行中=無彩面／**未登録=淡ピンク面＋ピンクアイコン（本文は無彩でAA維持）**／不要=枠線のみ。カテゴリアイコン（チケット/交通/宿泊/持ち物/Todo）で判別性を上げる。文字列（`チケット 未登録` 等）と Semantics ラベルは不変。(3) **`TodoPrepChip` を新設し持ち物の左へ常時表示**（未登録/残りN/完了）。並び順は固定: **Todo→持ち物→チケット→交通→宿泊→次にやる**。(4) 「次にやる」は紫グラデーションのピル（1行・省略）。**文言は既存 `deriveNextAction` の表示文字（`次にやる: ${label}`）のまま**。タップ遷移（`/genba/:id`）・状態チップ（`GenbaStatusChip` Semantics）・一覧の機能（Refresh/FAB/共有節）は不変 | 参考モックの半券モチーフを、既存トークン（primarySoft/dawn/divider/favorite/textSecondary）だけで実現し、色コード直書き・テーマ非追従を避ける。未登録のピンクはアイコン/面のみに載せ本文コントラストを守る（§15.4: 状態は文字でも伝える）。ダークはトークンが暗色版を持つため破綻しない |

### 実装・テスト

- `event_list_card.dart`（半券化）・`genba_card.dart`（`_PrepPill`/`TodoPrepChip`/チップ刷新・レガシー`GenbaCard`も同チップへ）・`genba_event_list_card.dart`（並び順固定・`_NextActionPill`）。
- `test/widget/genba_list_screen_test.dart` に追加: 並び順（Todo→持ち物→チケット→交通→宿泊、読み順で検証）＋「次にやる」が既存文言でチップ列の後に出る／長い公演名・会場・次アクションで overflow 例外が出ない。既存テスト（チップ文言・Semantics・残日数・中止非消失）は無改変で通過。
- モックにある「並べ替え」「Upcoming/過去」トグルは現状の現場タブに存在しない機能のため**追加しない**（過去は思い出タブという既存情報設計を維持。見た目刷新の範囲外）。

| ID | 決定 | 理由 |
|----|------|------|
| D-251 | D-250 の「まだ味気ない」を受け、`EventListCard` を**デジタル半券 v2**へ再構成。(1) カードを**券面（上）＋半券（下）の2段**にし、間に `_TicketPerforation`（左右両端の半円ノッチ＋破線, 高さ固定16px）を挟む。ノッチはカード背後の背景色（`AppTokens.backgroundBottom`）で塗って「切り込み」に見せ、半券面は `primarySoft` α.18 の淡ラベンダーで券面と差をつける（本物の半券感）。(2) **最大の是正**: 準備ステータスを横並びピルから**等幅の縦タイル**（アイコン18px → ラベル → 状態 の縦積み）へ。`_PrepPill`→`_PrepTile`、`EventListCard.prepTiles` を Row+`Expanded` で**常に等幅**に配置（Wrap の行末ガタつきを解消）。状態色は4段（完了=紫／進行中=無彩／未登録=淡ピンクのアイコン＋彩度を落としたローズ文字でAA確保／不要=無彩）。ラベルと状態は別 `Text`＝`Semantics('ラベル: 状態')` で読み上げを維持。(3) 状態バッジ（`GenbaStatusChip`）は**券面**（会場の下）へ、準備タイルと分離。(4) 「次にやる」は紫グラデーションのピルから**淡紫（primarySoft）の全幅バー**へ変更し、タイル列の直下・1行・省略で出す。**文言は既存 `deriveNextAction`（`次にやる: ${label}`）のまま**。並び順は D-250 の Todo→持ち物→チケット→交通→宿泊 を踏襲。タップ遷移・Refresh/FAB/共有節・minimal（HOME）は不変 | 「終わっている」の主因は装飾ではなく**構造**（横並びピルの文字羅列＋Wrap のガタつき＋券面/半券の区切りの弱さ）と診断。等幅の縦タイル化で情報が整然と読め、両端ノッチで初めて「チケット」に見える。色は全てトークン経由でダーク追従。ノッチは高さ固定の描画で Dynamic Type と両立し、影・角丸（`AppCard`）を壊さない |

### 実装・テスト（D-251）

- `event_list_card.dart`（`_Face`＝券面／`_PrepTileRow`＝半券の等幅Row／`_TicketPerforation`＋ノッチ描画。`prepTiles`・`nextAction` slot を追加、`statusChips` は券面バッジ、`footer` は廃止）。`genba_card.dart`（`_PrepPill`→`_PrepTile` 縦タイル・4tier色・レガシー`GenbaCard` も等幅Rowへ）。`genba_event_list_card.dart`（`prepTiles`＝5タイル・`nextAction`＝`_NextActionBar` 全幅バー）。
- `test/widget/genba_list_screen_test.dart`: 状態検証を `bySemanticsLabel('チケット: 未登録')` へ移行（タイルはラベル/状態が別Text）。並び順はタイルのラベル中心座標で判定、**等幅は「ラベル中心の間隔が±1.5px以内で一定」で検証**、「次にやる」は既存文言でタイル列の下、追加で**狭幅320・ダークテーマの smoke**（overflow 例外なし＋5タイルの Semantics 維持）。全 1022 テスト緑。

### 検証

- `dart format`（クリーン）・`dart analyze lib test integration_test`（No issues）・`flutter test`（1021 パス）。
