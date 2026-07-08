-- ============================================================================
-- 0018_genba_memos_multi.sql
--   メモを「現場×種類ごと1件」から複数可へ変更する（§7.7）。
--   - title / sort_order 列を追加（title は既存メモの種類名を初期値に）
--   - {genba_id, category} のユニーク制約を撤廃（同一種類の複数メモを許容）
--   - category に 'other'（テンプレートなし）を追加
--
--   0003 を書き換えず前方専用で追加する。ローカル Drift v12 と同一方針。
--   既存メモは削除しない。apply_mutation の列許可は information_schema から動的
--   取得するため、新列 title/sort_order は自動的に対象になる（0011）。
-- ============================================================================

alter table public.genba_memos
  add column if not exists title text not null default '';
alter table public.genba_memos
  add column if not exists sort_order integer not null default 0;

-- 既存メモの title を種類名で初期化する（空のものだけ）。
update public.genba_memos
   set title = case category
     when 'free' then '自由メモ'
     when 'goods' then '物販'
     when 'meetup' then '集合場所'
     when 'around' then '周辺施設'
     when 'notice' then '注意事項'
     else 'メモ'
   end
 where coalesce(title, '') = '';

-- 「現場×種類ごと1件」制約を撤廃する（複数メモを許容）。
alter table public.genba_memos
  drop constraint if exists genba_memos_genba_id_category_key;

-- category に 'other'（テンプレートなし）を許可する。
alter table public.genba_memos
  drop constraint if exists genba_memos_category_check;
alter table public.genba_memos
  add constraint genba_memos_category_check
  check (category in ('free', 'goods', 'meetup', 'around', 'notice', 'other'));
