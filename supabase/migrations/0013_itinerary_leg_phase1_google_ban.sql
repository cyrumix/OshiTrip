-- ============================================================================
-- 0013_itinerary_leg_phase1_google_ban.sql
--   Phase 1: Google Routes のライブ応答を itinerary_legs へ永続保存させない
--   サーバー側強制（クライアント境界だけに頼らない, §12.5 / D-180）。
--
-- 背景:
--   0012 で itinerary_legs に source(manual/google_routes) と Google 応答予約
--   フィールド（fetched_at / cache_key / encoded_polyline 等）を将来利用のため
--   列として用意した。Phase 1 ではクライアント（ItineraryRepository.upsertLeg）が
--   これらを拒否するが、apply_mutation RPC 経由や直接 SQL でも保存できないよう
--   サーバーでも強制する。
--
-- 方針:
--   列・enum は将来（書面許諾を得た Phase 4）のため残し、Phase 1 では CHECK
--   制約で「保存不能」にする。CHECK は直接 INSERT/UPDATE と apply_mutation の
--   INSERT/UPDATE の両方で評価されるため、経路を問わず拒否できる（違反は
--   SQLSTATE 23514）。将来解禁する際はこの制約を drop する別マイグレーションで
--   行い、feature flag／Phase 4 の判断とする（ここでは先行解禁しない）。
--
--   本追補は 0012 を書き換えず前方専用で追加する（0012 が既に適用済みの環境でも
--   安全に適用できるようにするため）。適用時点で itinerary_legs に google_routes
--   由来の行は存在しない想定（Phase 1 クライアントは書き込まない）。
--
-- 注: 本ファイルは Supabase(Postgres) 環境（CI: supabase db reset + pgTAP）で
--     適用・検証する。ローカル Windows 環境では未実行。
-- ============================================================================

alter table public.itinerary_legs
  add constraint itinerary_legs_phase1_no_google_live check (
    source <> 'google_routes'
    and fetched_at is null
    and cache_key is null
    and encoded_polyline is null
  );

comment on constraint itinerary_legs_phase1_no_google_live
  on public.itinerary_legs is
  'Phase 1: Google Routes ライブ応答の永続保存を禁止する（§12.5/D-180）。'
  '将来の解禁は別マイグレーションで本制約を drop する。';
