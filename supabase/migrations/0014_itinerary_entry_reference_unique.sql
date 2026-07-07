-- ============================================================================
-- 0014_itinerary_entry_reference_unique.sql
--   同一計画に同じ交通／宿泊を二重に参照追加させない部分ユニーク制約
--   （§5.3 / Phase 2レビュー）。UI とローカルDBに加え、サーバー側でも
--   apply_mutation 経由・直接INSERT/UPDATE の両方で重複を弾く。
--
--   0012 を書き換えず前方専用で追加する（0012 適用済み環境でも安全に適用）。
--   transport_id / lodging_id が NULL の行（spot/note）は対象外の部分索引。
--
-- 既存重複がある場合の移行方針（Phase 2レビュー点1/点6）:
--   部分ユニーク索引を張る前に、同一計画に同じ交通/宿泊を参照する重複項目を
--   決定的に1件へ整理する（既存重複があっても本マイグレーションが失敗しない）。
--   保持する1件の選択規則は、ローカル Drift v9 の dedup と同一:
--     (sort_order, created_at, id) の昇順で最小の1件を残し、他（負け側）を削除。
--   削除する負け側項目を端点とする移動区間(itinerary_legs)は、legs の
--   origin/destination FK が ON DELETE CASCADE のため自動削除される
--   （交通/宿泊“本体”テーブルには FK が無く参照だけなので触れない, §5.3）。
--   本 dedup は冪等（重複が無ければ0行削除）。
-- ============================================================================

with losers as (
  select e.id
    from public.itinerary_entries e
   where e.transport_id is not null
     and exists (
       select 1
         from public.itinerary_entries o
        where o.plan_id = e.plan_id
          and o.transport_id = e.transport_id
          and o.id <> e.id
          and (o.sort_order, o.created_at, o.id)
              < (e.sort_order, e.created_at, e.id)
     )
  union
  select e.id
    from public.itinerary_entries e
   where e.lodging_id is not null
     and exists (
       select 1
         from public.itinerary_entries o
        where o.plan_id = e.plan_id
          and o.lodging_id = e.lodging_id
          and o.id <> e.id
          and (o.sort_order, o.created_at, o.id)
              < (e.sort_order, e.created_at, e.id)
     )
)
delete from public.itinerary_entries e
 where e.id in (select id from losers);

create unique index if not exists idx_itinerary_entries_plan_transport
  on public.itinerary_entries (plan_id, transport_id)
  where transport_id is not null;

create unique index if not exists idx_itinerary_entries_plan_lodging
  on public.itinerary_entries (plan_id, lodging_id)
  where lodging_id is not null;
