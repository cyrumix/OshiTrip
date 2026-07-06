-- ============================================================================
-- 0014_itinerary_entry_reference_unique.sql
--   同一計画に同じ交通／宿泊を二重に参照追加させない部分ユニーク制約
--   （§5.3 / Phase 2レビュー）。UI とローカルDBに加え、サーバー側でも
--   apply_mutation 経由・直接INSERT/UPDATE の両方で重複を弾く。
--
--   0012 を書き換えず前方専用で追加する（0012 適用済み環境でも安全に適用）。
--   transport_id / lodging_id が NULL の行（spot/note）は対象外の部分索引。
-- ============================================================================

create unique index if not exists idx_itinerary_entries_plan_transport
  on public.itinerary_entries (plan_id, transport_id)
  where transport_id is not null;

create unique index if not exists idx_itinerary_entries_plan_lodging
  on public.itinerary_entries (plan_id, lodging_id)
  where lodging_id is not null;
