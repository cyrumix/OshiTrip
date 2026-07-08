-- ============================================================================
-- 0016_genba_performance_type_code.sql
--   公演種別 genbas.performance_type を自由入力から「選択式の安定コード」へ
--   移行する（§7.1）。変換不能な旧・自由入力を失わないための
--   genbas.performance_type_other を追加する。
--
--   0003 を書き換えず前方専用で追加する。ローカル Drift v10 の変換ロジックと
--   同一（既にコードなら素通し、既知語→対応コード、変換不能→other）。
--   移行後に performance_type へ CHECK 制約（既知コードのみ）を付け、以後の
--   自由入力を直接INSERT/apply_mutation 双方で防ぐ。
-- ============================================================================

alter table public.genbas
  add column if not exists performance_type_other text;

-- 1. 変換不能な旧・自由入力（コード以外）を other 領域へ退避する。
update public.genbas
   set performance_type_other = performance_type
 where performance_type is not null
   and btrim(performance_type) <> ''
   and performance_type not in (
     'live_concert','festival','release_event','meet_greet','fan_meeting',
     'talk_event','stage_musical','exhibition','sports','online','other');

-- 2. 安定コードへ変換する（既にコードなら素通し・未知は other）。
update public.genbas
   set performance_type = case
     when performance_type in (
       'live_concert','festival','release_event','meet_greet','fan_meeting',
       'talk_event','stage_musical','exhibition','sports','online','other')
       then performance_type
     when performance_type like '%ライブ%' or performance_type like '%コンサート%'
       or performance_type like '%ワンマン%' or lower(performance_type) like '%live%'
       then 'live_concert'
     when performance_type like '%フェス%' or lower(performance_type) like '%festival%'
       then 'festival'
     when performance_type like '%リリイベ%' or performance_type like '%リリース%'
       then 'release_event'
     when performance_type like '%特典会%' or performance_type like '%撮影会%'
       or performance_type like '%チェキ%' then 'meet_greet'
     when performance_type like '%ファンミ%' then 'fan_meeting'
     when performance_type like '%トーク%' then 'talk_event'
     when performance_type like '%舞台%' or performance_type like '%ミュージカル%'
       or performance_type like '%演劇%' then 'stage_musical'
     when performance_type like '%展示%' or performance_type like '%展覧%'
       then 'exhibition'
     when performance_type like '%スポーツ%' or performance_type like '%観戦%'
       or performance_type like '%試合%' then 'sports'
     when performance_type like '%オンライン%' or performance_type like '%配信%'
       or lower(performance_type) like '%online%' then 'online'
     else 'other'
   end
 where performance_type is not null and btrim(performance_type) <> '';

-- 3. 既知コードへ変換できた行の退避（other 領域）は消す（冗長を残さない）。
update public.genbas
   set performance_type_other = null
 where performance_type <> 'other';

-- 4. 以後は既知コードのみ許可する（自由入力の再混入を防ぐ）。
alter table public.genbas
  drop constraint if exists genbas_performance_type_code_check;
alter table public.genbas
  add constraint genbas_performance_type_code_check
  check (performance_type is null or performance_type in (
    'live_concert','festival','release_event','meet_greet','fan_meeting',
    'talk_event','stage_musical','exhibition','sports','online','other'));
