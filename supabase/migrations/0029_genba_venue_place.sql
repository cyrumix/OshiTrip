-- ============================================================================
-- 0029_genba_venue_place.sql
--   会場（venue）のGoogle連携。genbas へ会場の住所・Google Place ID を追加する。
--   Google検索＋手入力の一体型UIで、候補選択時に住所・Place ID を保存する。
--   永続保存してよい Google 由来値は Place ID を主とし、名称・住所はユーザーが
--   確認・保存した値として扱う（D-178/D-179）。座標は Places の Field Mask 対象外
--   のため保存しない（スポットと同方針）。
--
--   前方専用で追加する（既存データは null のまま）。ローカル Drift v18 と一致。
-- ============================================================================

alter table public.genbas
  add column if not exists venue_address text,
  add column if not exists venue_google_place_id text;
