-- pgTAP: 共有現場のロール別アクセス（0031 / 追加要件 §7）
--
-- 検証:
-- - viewer は read 可・write 不可
-- - editor は read/write 可（apply_shared_mutation・owner_id は現場ownerへ正規化）
-- - editor はメンバー管理不可（genbas/genba_shares を editor 経由で書けない）
-- - 未共有ユーザーは read/write 不可
-- - 共有解除後は read/write 不可
-- - owner は従来どおり全操作可
--
-- 実行: supabase start → supabase db reset → supabase test db
-- 注意: 本リポジトリ環境は Docker/Supabase CLI 未導入のため**未実行**（静的レビューのみ）。
begin;

create extension if not exists pgtap with schema extensions;

select plan(43);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'viewer@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'editor@example.com'),
  ('44444444-4444-4444-4444-444444444444', 'stranger@example.com');

set local role authenticated;

-- ---- owner (u1): 現場・子データ・共有を用意 ----------------------------------
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111', 'A', 'T', '2026-08-01');

insert into public.todos (id, genba_id, owner_id, name)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111', 'owner-todo');

insert into public.genba_shares (id, owner_id, genba_id, grantee_id, role) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc',
   '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '22222222-2222-2222-2222-222222222222', 'viewer'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd',
   '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '33333333-3333-3333-3333-333333333333', 'editor');

-- itinerary: 共有現場 g1 の plan/spot と、別現場 g2（未共有）の plan/spot。
-- itinerary_spot_links は spot_id 経由で所属現場を辿るため、この構成で検証する。
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a2222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111', 'B', 'T2', '2026-09-01');
insert into public.itinerary_plans (id, genba_id, owner_id, title, time_zone_id)
values
  ('b1111111-1111-1111-1111-111111111111',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '11111111-1111-1111-1111-111111111111', 'plan1', 'Asia/Tokyo'),
  ('b2222222-2222-2222-2222-222222222222',
   'a2222222-2222-2222-2222-222222222222',
   '11111111-1111-1111-1111-111111111111', 'plan2', 'Asia/Tokyo');
insert into public.itinerary_spots (id, plan_id, owner_id, name, category)
values
  ('c1111111-1111-1111-1111-111111111111',
   'b1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111', 'spot1', 'sightseeing'),
  ('c2222222-2222-2222-2222-222222222222',
   'b2222222-2222-2222-2222-222222222222',
   '11111111-1111-1111-1111-111111111111', 'spot2', 'sightseeing');

-- 共有現場 g1 の plan1 に2つの旅程項目と、その間の移動区間（editor 削除の検証用）。
insert into public.itinerary_entries (id, plan_id, owner_id, kind, spot_id)
values
  ('e1111111-1111-1111-1111-111111111111',
   'b1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111', 'spot',
   'c1111111-1111-1111-1111-111111111111'),
  ('e2222222-2222-2222-2222-222222222222',
   'b1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111', 'spot',
   'c1111111-1111-1111-1111-111111111111');
insert into public.itinerary_legs
  (id, plan_id, owner_id, origin_entry_id, destination_entry_id, travel_mode)
values
  ('f1111111-1111-1111-1111-111111111111',
   'b1111111-1111-1111-1111-111111111111',
   '11111111-1111-1111-1111-111111111111',
   'e1111111-1111-1111-1111-111111111111',
   'e2222222-2222-2222-2222-222222222222', 'transit');

-- 未共有現場 g2 の写真（editor がカバー切替で他現場を触れないことの検証用, D-247）。
insert into public.memory_photos (id, genba_id, owner_id, caption, is_cover)
values
  ('f0f0f0f0-0000-0000-0000-000000000002',
   'a2222222-2222-2222-2222-222222222222',
   '11111111-1111-1111-1111-111111111111', 'g2-photo', false);

-- ===========================================================================
-- viewer (u2): read 可・write 不可
-- ===========================================================================
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);

select results_eq(
  $$select count(*)::int from public.genbas
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  $$values (1)$$, 'viewer can read the shared genba');

select results_eq(
  $$select count(*)::int from public.todos
      where genba_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  $$values (1)$$, 'viewer can read child rows of the shared genba');

select throws_ok(
  $$insert into public.todos (id, genba_id, owner_id, name) values (
      '00000000-0000-0000-0000-0000000000e1',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '11111111-1111-1111-1111-111111111111', 'viewer-hack')$$,
  '42501', null, 'viewer cannot write directly (RLS)');

select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-0000000000e2'::uuid, 'todos',
      '00000000-0000-0000-0000-0000000000e3'::uuid, 'upsert',
      '{"id":"00000000-0000-0000-0000-0000000000e3",
        "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","name":"x"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'viewer cannot write via apply_shared_mutation');

-- ===========================================================================
-- editor (u3): read/write 可、メンバー管理不可
-- ===========================================================================
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);

select results_eq(
  $$select count(*)::int from public.genbas
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  $$values (1)$$, 'editor can read the shared genba');

select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-0000000000f1'::uuid, 'todos',
    '99999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"99999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","name":"editor-todo"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a child row via apply_shared_mutation');

select results_eq(
  $$select owner_id from public.todos
      where id = '99999999-9999-9999-9999-999999999999'$$,
  $$values ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'editor-created row is owned by the genba owner (normalized)');

select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-0000000000f2'::uuid, 'todos',
    '99999999-9999-9999-9999-999999999999'::uuid, 'delete',
    '{"id":"99999999-9999-9999-9999-999999999999"}'::jsonb,
    (select version from public.todos
       where id = '99999999-9999-9999-9999-999999999999'),
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can delete a child row via apply_shared_mutation');

select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-0000000000f3'::uuid, 'genbas',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'delete',
      '{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '22023', null, 'editor cannot edit/delete the genba itself');

select throws_ok(
  $$insert into public.genba_shares (id, owner_id, genba_id, grantee_id, role)
    values ('00000000-0000-0000-0000-0000000000f4',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '44444444-4444-4444-4444-444444444444', 'viewer')$$,
  '42501', null, 'editor cannot manage members');

-- ===========================================================================
-- 未共有 (u4): read/write 不可
-- ===========================================================================
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);

select results_eq(
  $$select count(*)::int from public.genbas
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  $$values (0)$$, 'unshared user cannot read the genba');

select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-0000000000f5'::uuid, 'todos',
      '00000000-0000-0000-0000-0000000000f6'::uuid, 'upsert',
      '{"id":"00000000-0000-0000-0000-0000000000f6",
        "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","name":"x"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'unshared user cannot write via apply_shared_mutation');

-- ===========================================================================
-- D-245: editor は計画スポット・思い出テキスト・移動区間(削除) を共同編集できる
-- ===========================================================================
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);

-- 計画スポット（plan_id 経由で g1 所属を検証）を編集できる。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000bb01'::uuid, 'itinerary_spots',
    'c1111111-1111-1111-1111-111111111111'::uuid, 'upsert',
    '{"id":"c1111111-1111-1111-1111-111111111111",
      "plan_id":"b1111111-1111-1111-1111-111111111111",
      "name":"spot1-edited","category":"cafe"}'::jsonb,
    (select version from public.itinerary_spots
       where id = 'c1111111-1111-1111-1111-111111111111'),
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can edit an itinerary_spot of the shared genba');

-- 思い出テキスト（memory_entries）を新規作成でき、owner に正規化される。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000bb02'::uuid, 'memory_entries',
    'a9999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"a9999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "impression":"最高だった","best_moment":"アンコール"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create memory_entries of the shared genba');

select results_eq(
  $$select owner_id from public.memory_entries
      where id = 'a9999999-9999-9999-9999-999999999999'$$,
  $$values ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'editor-created memory_entries is owned by the genba owner (normalized)');

-- 移動区間（plan_id 経由で g1 所属を検証）を削除できる。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000bb03'::uuid, 'itinerary_legs',
    'f1111111-1111-1111-1111-111111111111'::uuid, 'delete',
    '{"id":"f1111111-1111-1111-1111-111111111111"}'::jsonb,
    (select version from public.itinerary_legs
       where id = 'f1111111-1111-1111-1111-111111111111'),
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can delete an itinerary_leg of the shared genba');

-- ===========================================================================
-- D-246: editor は移動区間(追加)・チケット/交通/宿泊・グッズ/行った場所/
--         セットリスト・写真(メタデータ) を共同編集できる
-- ===========================================================================
-- 移動区間の新規作成（端点 e1/e2 は D-245 の setup。plan_id で g1 帰属検証）。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc01'::uuid, 'itinerary_legs',
    'f2222222-2222-2222-2222-222222222222'::uuid, 'upsert',
    '{"id":"f2222222-2222-2222-2222-222222222222",
      "plan_id":"b1111111-1111-1111-1111-111111111111",
      "origin_entry_id":"e1111111-1111-1111-1111-111111111111",
      "destination_entry_id":"e2222222-2222-2222-2222-222222222222",
      "travel_mode":"walking","duration_minutes":10}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create an itinerary_leg of the shared genba');

-- チケット（genba_id で帰属検証・owner 正規化）。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc02'::uuid, 'tickets',
    'c9999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"c9999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","seat":"A-1"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a ticket of the shared genba');
select results_eq(
  $$select owner_id from public.tickets
      where id = 'c9999999-9999-9999-9999-999999999999'$$,
  $$values ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'editor-created ticket is owned by the genba owner (normalized)');

-- 交通。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc03'::uuid, 'transports',
    'd9999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"d9999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "direction":"outbound","method":"shinkansen"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a transport of the shared genba');

-- 宿泊。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc04'::uuid, 'lodgings',
    'e9999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"e9999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","name":"HotelA"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a lodging of the shared genba');

-- グッズ。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc05'::uuid, 'goods_items',
    'aa999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"aa999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","name":"penlight"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a goods_item of the shared genba');

-- 行った場所/食べたもの（category=food）。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc06'::uuid, 'visited_places',
    'bb999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"bb999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "name":"ramen","category":"food"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a visited_place of the shared genba');

-- セットリスト。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc07'::uuid, 'setlist_items',
    'cc999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"cc999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "position":1,"song_title":"song A"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a setlist_item of the shared genba');

-- 写真（メタデータ：caption/cover）。画像本体 Storage は本増分の対象外。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc08'::uuid, 'memory_photos',
    'dd999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"dd999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "caption":"stage","is_cover":true}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create/annotate a memory_photo of the shared genba');

-- 作成したチケットを削除できる（版 CAS）。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000cc09'::uuid, 'tickets',
    'c9999999-9999-9999-9999-999999999999'::uuid, 'delete',
    '{"id":"c9999999-9999-9999-9999-999999999999"}'::jsonb,
    (select version from public.tickets
       where id = 'c9999999-9999-9999-9999-999999999999'),
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can delete a ticket of the shared genba');

-- viewer はこれらを書けない（代表として tickets で検証）。
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-00000000cc10'::uuid, 'tickets',
      '00000000-0000-0000-0000-00000000cc11'::uuid, 'upsert',
      '{"id":"00000000-0000-0000-0000-00000000cc11",
        "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","seat":"X"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'viewer cannot create a ticket via apply_shared_mutation');
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);

-- ===========================================================================
-- D-247: 計画本体(itinerary_plans)は editor 経由で編集不可・写真カバーの安全切替
-- ===========================================================================
-- editor は itinerary_plans（計画本体）を upsert できない（allowlist から除外）。
select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-00000000dd01'::uuid, 'itinerary_plans',
      '00000000-0000-0000-0000-00000000dd02'::uuid, 'upsert',
      '{"id":"00000000-0000-0000-0000-00000000dd02",
        "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","title":"hack"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '22023', null, 'editor cannot create itinerary_plans via shared mutation');

-- editor は既存 plan を delete もできない。
select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-00000000dd03'::uuid, 'itinerary_plans',
      'b1111111-1111-1111-1111-111111111111'::uuid, 'delete',
      '{"id":"b1111111-1111-1111-1111-111111111111"}'::jsonb,
      (select version from public.itinerary_plans
         where id = 'b1111111-1111-1111-1111-111111111111'),
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '22023', null, 'editor cannot delete itinerary_plans via shared mutation');

-- plan 本体は消えずに残っている（子データ経路のみ許可されている）。
select results_eq(
  $$select count(*)::int from public.itinerary_plans
      where id = 'b1111111-1111-1111-1111-111111111111'$$,
  $$values (1)$$, 'itinerary_plans is untouched by editor');

-- 写真カバーの安全切替: g1 には D-246 で dd999...(is_cover=true) がある。editor が
-- 別の新規写真を is_cover=true で保存しても unique 制約に衝突せず適用される。
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000dd04'::uuid, 'memory_photos',
    'ee999999-9999-9999-9999-999999999999'::uuid, 'upsert',
    '{"id":"ee999999-9999-9999-9999-999999999999",
      "genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "caption":"new-cover","is_cover":true}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can switch cover even when another cover exists');

-- カバーは1枚だけ（現場内の is_cover=true はちょうど1件）。
select results_eq(
  $$select count(*)::int from public.memory_photos
      where genba_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and is_cover$$,
  $$values (1)$$, 'exactly one cover remains after switching');

-- 新しい写真がカバーで、以前のカバー(dd999...)は false になっている。
select results_eq(
  $$select is_cover from public.memory_photos
      where id = 'ee999999-9999-9999-9999-999999999999'$$,
  $$values (true)$$, 'the newly designated photo is the cover');
select results_eq(
  $$select is_cover from public.memory_photos
      where id = 'dd999999-9999-9999-9999-999999999999'$$,
  $$values (false)$$, 'the previous cover was cleared');

-- 他現場(g2)の写真はカバー切替でも触れない（行帰属チェックで拒否）。
select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-00000000dd05'::uuid, 'memory_photos',
      'f0f0f0f0-0000-0000-0000-000000000002'::uuid, 'upsert',
      '{"id":"f0f0f0f0-0000-0000-0000-000000000002",
        "genba_id":"a2222222-2222-2222-2222-222222222222","is_cover":true}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'editor cannot touch another genba''s photo cover');

-- ===========================================================================
-- itinerary_spot_links（spot_id → spot → plan → genba 経由の共有判定, Critical修正）
-- ===========================================================================
-- editor (u3): 共有現場 g1 に属する spot(c1) の spot_link を作成できる。
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);
select is(
  (public.apply_shared_mutation(
    '00000000-0000-0000-0000-00000000aa01'::uuid, 'itinerary_spot_links',
    'd1111111-1111-1111-1111-111111111111'::uuid, 'upsert',
    '{"id":"d1111111-1111-1111-1111-111111111111",
      "spot_id":"c1111111-1111-1111-1111-111111111111",
      "kind":"reference","url":"https://example.com/a"}'::jsonb,
    null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') ->> 'status'),
  'applied', 'editor can create a spot_link on a spot of the shared genba');

select results_eq(
  $$select owner_id from public.itinerary_spot_links
      where id = 'd1111111-1111-1111-1111-111111111111'$$,
  $$values ('11111111-1111-1111-1111-111111111111'::uuid)$$,
  'spot_link owner_id is normalized to the genba owner');

-- editor が別現場 g2 の spot(c2) を p_genba=g1 で書こうとすると拒否される。
select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-00000000aa02'::uuid, 'itinerary_spot_links',
      '00000000-0000-0000-0000-00000000aa03'::uuid, 'upsert',
      '{"id":"00000000-0000-0000-0000-00000000aa03",
        "spot_id":"c2222222-2222-2222-2222-222222222222",
        "kind":"reference","url":"https://example.com/b"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'editor cannot write a spot_link for another genba''s spot');

-- viewer (u2): spot_link を読めるが書けない。
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select results_eq(
  $$select count(*)::int from public.itinerary_spot_links
      where spot_id = 'c1111111-1111-1111-1111-111111111111'$$,
  $$values (1)$$, 'viewer can read spot_links of the shared genba');
select throws_ok(
  $$select public.apply_shared_mutation(
      '00000000-0000-0000-0000-00000000aa04'::uuid, 'itinerary_spot_links',
      '00000000-0000-0000-0000-00000000aa05'::uuid, 'upsert',
      '{"id":"00000000-0000-0000-0000-00000000aa05",
        "spot_id":"c1111111-1111-1111-1111-111111111111",
        "kind":"reference","url":"https://example.com/c"}'::jsonb,
      null, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'viewer cannot write spot_links');

-- 未共有 (u4): spot_link を読めない。
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);
select results_eq(
  $$select count(*)::int from public.itinerary_spot_links
      where spot_id = 'c1111111-1111-1111-1111-111111111111'$$,
  $$values (0)$$, 'unshared user cannot read spot_links');

-- ===========================================================================
-- 共有解除・owner 全操作
-- ===========================================================================
-- owner が viewer(u2) の共有を解除する。
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
delete from public.genba_shares
  where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

-- 解除後、u2 は読めない。
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select results_eq(
  $$select count(*)::int from public.genbas
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  $$values (0)$$, 'unshared-after-revoke user cannot read the genba');

-- owner は従来どおり現場本体を更新できる。
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select lives_ok(
  $$update public.genbas set title = 'T2'
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'owner can still update the genba');

select * from finish();
rollback;
