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

## 開発環境の注意（Windows / 非ASCIIパス）

- 本リポジトリの絶対パスに非ASCII文字が含まれる環境では、`flutter analyze` が
  analysis server の JSON 解析エラーで落ちることがある。**`dart analyze` は正常に動作する**ため
  そちらを使用する（検証済み）。
- Flutter SDK は `C:\src\flutter`（setup.md の推奨に一致）へ導入済み。PUB_CACHE も
  非ASCIIパス回避のため `C:\src\pub_cache` を使用した。
- Windows ホストでの単体テストは OS 同梱の `winsqlite3.dll` へフォールバックして
  SQLite を利用する（`test/helpers/test_db.dart`）。
