-- ============================================================================
-- 0015_itinerary_spot_category_sacred_place.sql
--   スポットカテゴリに「聖地」(sacred_place) を独立カテゴリとして追加する
--   （itinerary-plan-spec.md §4.4 / Phase 2追補）。「神社・寺院」「観光地」とは
--   統合しない。
--
--   0012 の category CHECK 制約を書き換えず前方専用で差し替える（0012 適用済み
--   環境でも安全に適用）。既存値はすべて許可したまま 'sacred_place' を追加する
--   ので、後方互換を壊さない。
-- ============================================================================

alter table public.itinerary_spots
  drop constraint if exists itinerary_spots_category_check;

alter table public.itinerary_spots
  add constraint itinerary_spots_category_check
  check (category in (
    'venue', 'sightseeing', 'restaurant', 'cafe', 'lodging', 'station',
    'airport', 'shopping', 'shrine_temple', 'sacred_place', 'museum', 'park',
    'photo_spot', 'convenience', 'other'
  ));
