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
| D-180 | Google Routesは、プレミアムユーザーが経路詳細を開くか`最新ルートを更新`を押した場合だけ呼ぶ。通常表示は権利確認済みの保存済み概算経路を優先する。Googleライブ応答は一時表示とし、書面許諾等が無い限り共有DBへ永続キャッシュしない | Routesの現行個別規約で明示されるキャッシュ許可は緯度・経度の最長30日であり、経路概要・所要時間・路線・運賃等を恒久DB化してAPIを代替する許可は確認できない。明示操作・single-flight・クォータ・kill switchで呼出しを抑える |
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
