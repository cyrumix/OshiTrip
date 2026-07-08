-- ============================================================================
-- 0017_transport_method_code.sql
--   遠征の交通手段 transports.method を自由入力から「選択式の安定コード」へ
--   移行する（§7.5）。変換不能な旧・自由入力を失わないための
--   transports.method_other を追加する。
--
--   0003 を書き換えず前方専用で追加する。ローカル Drift v11 の変換ロジックと
--   同一（既にコードなら素通し、既知語→対応コード、変換不能→other）。
-- ============================================================================

alter table public.transports
  add column if not exists method_other text;

-- 1. 変換不能な旧・自由入力（コード以外）を other 領域へ退避する。
update public.transports
   set method_other = method
 where method is not null
   and btrim(method) <> ''
   and method not in (
     'shinkansen','train','airplane','highway_bus','local_bus','private_car',
     'rental_car','ferry','taxi','walk_bicycle','other');

-- 2. 安定コードへ変換する（既にコードなら素通し・未知は other）。
update public.transports
   set method = case
     when method in (
       'shinkansen','train','airplane','highway_bus','local_bus','private_car',
       'rental_car','ferry','taxi','walk_bicycle','other') then method
     when method like '%新幹線%' then 'shinkansen'
     when method like '%夜行バス%' or method like '%高速バス%' then 'highway_bus'
     when method like '%路線バス%' then 'local_bus'
     when method like '%レンタカー%' or lower(method) like '%rental%'
       then 'rental_car'
     when method like '%自家用%' or method like '%マイカー%' then 'private_car'
     when method like '%タクシー%' or lower(method) like '%taxi%' then 'taxi'
     when method like '%フェリー%' or method like '%船%' or lower(method) like '%ferry%'
       then 'ferry'
     when method like '%徒歩%' or method like '%自転車%' or method like '%チャリ%'
       or lower(method) like '%walk%' or lower(method) like '%bicycle%'
       then 'walk_bicycle'
     when method like '%飛行機%' or method like '%空路%' or lower(method) like '%ana%'
       or lower(method) like '%jal%' or lower(method) like '%plane%'
       or lower(method) like '%flight%' then 'airplane'
     when method like '%バス%' or lower(method) like '%bus%' then 'local_bus'
     when method like '%電車%' or method like '%在来線%' or lower(method) like '%jr%'
       or method like '%私鉄%' or method like '%地下鉄%' or method like '%鉄道%'
       or lower(method) like '%train%' then 'train'
     else 'other'
   end
 where method is not null and btrim(method) <> '';

-- 3. 既知コードへ変換できた行の退避は消す。
update public.transports
   set method_other = null
 where method <> 'other';

-- 4. 以後は既知コードのみ許可する（自由入力の再混入を防ぐ）。
alter table public.transports
  drop constraint if exists transports_method_code_check;
alter table public.transports
  add constraint transports_method_code_check
  check (method is null or method in (
    'shinkansen','train','airplane','highway_bus','local_bus','private_car',
    'rental_car','ferry','taxi','walk_bicycle','other'));
