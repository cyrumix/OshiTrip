-- pgTAP: Phase 1 で itinerary_legs へ Google Routes ライブ応答を保存できない
--        ことをサーバー側で強制する（0013 の CHECK 制約）検証。
--
--   - source='google_routes' の直接 INSERT を拒否（23514）
--   - manual leg への source='google_routes' UPDATE を拒否（23514）
--   - fetched_at / cache_key / encoded_polyline それぞれ非null の INSERT を拒否
--   - apply_mutation 経由（upsert）でも source='google_routes' を拒否
--   - 拒否時に行が作成・更新されないこと
--   - source='manual' かつ Google 応答固有フィールドが null の leg は保存できる
--     （直接 INSERT・apply_mutation の両方）
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(14);

insert into auth.users (id, email)
values ('11111111-1111-1111-1111-111111111111', 'user1@example.com');

-- 認証切替ヘルパは authenticated ロールに CREATE 権限が無いため、
-- role を切り替える前（＝スーパーユーザー時）に作成する（D-248）。
create or replace function _as(uid text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

set local role authenticated;

select _as('11111111-1111-1111-1111-111111111111');

-- 親（現場・計画・端点となる旅程項目2件）を用意する。
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演',
        '2026-08-01');
insert into public.itinerary_plans
  (id, genba_id, owner_id, title, time_zone_id)
values ('b1000000-0000-0000-0000-000000000001',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '計画', 'Asia/Tokyo');
insert into public.itinerary_entries (id, plan_id, owner_id, kind)
values ('b5000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'note'),
       ('b5000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'note');

-- ---------------------------------------------------------------------------
-- source='manual' かつ Google 応答固有フィールド null の leg は保存できる。
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id)
    values ('b6000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002')$$,
  'manual leg with null google fields is saved'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id = 'b6000000-0000-0000-0000-000000000001'),
  1,
  'manual leg exists'
);

-- ---------------------------------------------------------------------------
-- source='google_routes' の直接 INSERT は拒否（23514）され行も作られない。
-- ---------------------------------------------------------------------------
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id, source)
    values ('b6000000-0000-0000-0000-00000000000a',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002', 'google_routes')$$,
  '23514', null,
  'direct INSERT with source=google_routes is rejected'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id = 'b6000000-0000-0000-0000-00000000000a'),
  0,
  'rejected google_routes leg is not created'
);

-- ---------------------------------------------------------------------------
-- fetched_at / cache_key / encoded_polyline それぞれ非null の INSERT を拒否。
-- ---------------------------------------------------------------------------
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id, fetched_at)
    values ('b6000000-0000-0000-0000-00000000000b',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002', now())$$,
  '23514', null,
  'INSERT with fetched_at is rejected'
);
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id, cache_key)
    values ('b6000000-0000-0000-0000-00000000000c',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002', 'k1')$$,
  '23514', null,
  'INSERT with cache_key is rejected'
);
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id,
       encoded_polyline)
    values ('b6000000-0000-0000-0000-00000000000d',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002', 'abc')$$,
  '23514', null,
  'INSERT with encoded_polyline is rejected'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id in ('b6000000-0000-0000-0000-00000000000b',
                'b6000000-0000-0000-0000-00000000000c',
                'b6000000-0000-0000-0000-00000000000d')),
  0,
  'legs with google reserved fields are not created'
);

-- ---------------------------------------------------------------------------
-- manual leg への UPDATE で source / 予約フィールドへ変更しようとしても拒否。
-- ---------------------------------------------------------------------------
select throws_ok(
  $$update public.itinerary_legs set source = 'google_routes'
    where id = 'b6000000-0000-0000-0000-000000000001'$$,
  '23514', null,
  'UPDATE to source=google_routes is rejected'
);
select throws_ok(
  $$update public.itinerary_legs set cache_key = 'x'
    where id = 'b6000000-0000-0000-0000-000000000001'$$,
  '23514', null,
  'UPDATE setting cache_key is rejected'
);
select is(
  (select source from public.itinerary_legs
   where id = 'b6000000-0000-0000-0000-000000000001'),
  'manual',
  'manual leg is unchanged after rejected UPDATE'
);

-- ---------------------------------------------------------------------------
-- apply_mutation 経由でも source='google_routes' は拒否され、行も作られない。
-- ---------------------------------------------------------------------------
select throws_ok(
  $$select public.apply_mutation(
      'dd000000-0000-0000-0000-000000000001',
      'itinerary_legs', 'b6000000-0000-0000-0000-0000000000aa', 'upsert',
      jsonb_build_object(
        'id', 'b6000000-0000-0000-0000-0000000000aa',
        'owner_id', '11111111-1111-1111-1111-111111111111',
        'plan_id', 'b1000000-0000-0000-0000-000000000001',
        'origin_entry_id', 'b5000000-0000-0000-0000-000000000001',
        'destination_entry_id', 'b5000000-0000-0000-0000-000000000002',
        'source', 'google_routes'),
      null)$$,
  '23514', null,
  'apply_mutation upsert with source=google_routes is rejected'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id = 'b6000000-0000-0000-0000-0000000000aa'),
  0,
  'rejected apply_mutation leg is not created'
);

-- ---------------------------------------------------------------------------
-- apply_mutation 経由の manual leg は従来どおり保存できる（弱体化していない）。
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dd000000-0000-0000-0000-000000000002',
    'itinerary_legs', 'b6000000-0000-0000-0000-0000000000bb', 'upsert',
    jsonb_build_object(
      'id', 'b6000000-0000-0000-0000-0000000000bb',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'plan_id', 'b1000000-0000-0000-0000-000000000001',
      'origin_entry_id', 'b5000000-0000-0000-0000-000000000001',
      'destination_entry_id', 'b5000000-0000-0000-0000-000000000002',
      'source', 'manual'),
    null
  ) ->> 'status'),
  'applied',
  'apply_mutation with manual leg still syncs'
);

select * from finish();
rollback;
