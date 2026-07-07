-- pgTAP: 旅程（itinerary）テーブルの RLS・親子owner整合・cascade・参照切れ・
--        apply_mutation 許可リスト（0012 / Phase 1）検証
--
--   - owner本人は plan/spot/link/entry/leg を作成できる
--   - kind別参照・endpoint一致禁止・運賃ペア・出典別rights_basis必須の check 制約が効く
--   - entry の参照先・leg の両端が同一owner・同一計画/現場に属することを
--     トリガーが強制する（存在しないspot・別現場transport・別計画entryを拒否）
--   - 別ownerは他ownerの計画を読み書き削除できない（RLS）
--   - 親(plan)経由の owner 迂回（子の owner 偽装）はトリガーで拒否される
--   - transport 参照は FK を張らず、交通削除で旅程項目が消えない（参照切れ）
--   - spot 削除で link・訪問entry・その leg が cascade する
--   - genba 削除で配下の計画が cascade する
--   - apply_mutation で itinerary 5テーブルが同期でき、既存entity(記念日)も
--     壊れず、不正な entity_table は引き続き拒否される
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(35);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

set local role authenticated;

create or replace function _as(uid text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

select _as('11111111-1111-1111-1111-111111111111');

-- 親現場・推しグループ（apply_mutation 回帰用）を用意する。
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演', '2026-08-01');
insert into public.oshi_groups (id, owner_id, name)
values ('a2222222-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'グループ');

-- ===========================================================================
-- apply_mutation: itinerary 5テーブルが同期でき、既存entityも壊れない
-- ===========================================================================
select is(
  (select public.apply_mutation(
    'dd000000-0000-0000-0000-000000000001',
    'itinerary_plans', 'b1000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'b1000000-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'genba_id', 'a1111111-0000-0000-0000-000000000001',
      'title', 'RPC計画', 'time_zone_id', 'Asia/Tokyo'
    ),
    null
  ) ->> 'status'),
  'applied',
  'itinerary_plans upsert syncs via apply_mutation'
);
select is(
  (select public.apply_mutation(
    'dd000000-0000-0000-0000-000000000002',
    'itinerary_spots', 'b2000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'b2000000-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'plan_id', 'b1000000-0000-0000-0000-000000000001',
      'name', 'RPCスポット', 'category', 'cafe'
    ),
    null
  ) ->> 'status'),
  'applied',
  'itinerary_spots upsert syncs via apply_mutation'
);
select is(
  (select public.apply_mutation(
    'dd000000-0000-0000-0000-000000000003',
    'oshi_anniversaries', 'b3000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'b3000000-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'group_id', 'a2222222-0000-0000-0000-000000000001',
      'label', '記念日', 'date', '2026-12-25'
    ),
    null
  ) ->> 'status'),
  'applied',
  'existing entity (oshi_anniversaries) is still allowed (regression)'
);
select throws_ok(
  $$select public.apply_mutation(
      'dd000000-0000-0000-0000-000000000004',
      'auth.users', 'b1000000-0000-0000-0000-000000000001', 'upsert',
      '{}'::jsonb, null)$$,
  '22023',
  'invalid entity_table is still rejected'
);

-- ===========================================================================
-- owner本人による直接挿入（happy path）と check 制約
-- ===========================================================================
select lives_ok(
  $$insert into public.itinerary_plans
      (id, genba_id, owner_id, title, time_zone_id)
    values ('b1000000-0000-0000-0000-000000000002',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '計画1', 'Asia/Tokyo')$$,
  'owner can insert own plan'
);
select lives_ok(
  $$insert into public.itinerary_spots
      (id, plan_id, owner_id, name, category)
    values ('b2000000-0000-0000-0000-000000000002',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'スポット1', 'sightseeing')$$,
  'owner can insert own spot'
);
select lives_ok(
  $$insert into public.itinerary_spot_links
      (id, spot_id, owner_id, kind, url)
    values ('b4000000-0000-0000-0000-000000000001',
            'b2000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'official',
            'https://example.com')$$,
  'owner can insert own spot link'
);
select lives_ok(
  $$insert into public.itinerary_entries
      (id, plan_id, owner_id, kind, spot_id)
    values ('b5000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'spot',
            'b2000000-0000-0000-0000-000000000002')$$,
  'owner can insert own spot-entry'
);
select lives_ok(
  $$insert into public.transports (id, genba_id, owner_id, from_place, to_place)
    values ('c1000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '東京', '大阪')$$,
  'owner can insert own transport (for reference)'
);
select lives_ok(
  $$insert into public.itinerary_entries
      (id, plan_id, owner_id, kind, transport_id)
    values ('b5000000-0000-0000-0000-000000000002',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'transport',
            'c1000000-0000-0000-0000-000000000001')$$,
  'owner can insert own transport-entry (referencing existing transport)'
);
select lives_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id)
    values ('b6000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002')$$,
  'owner can insert own leg'
);

-- kind=note なのに spot_id を持つ → reference-by-kind check 違反。
select throws_ok(
  $$insert into public.itinerary_entries
      (id, plan_id, owner_id, kind, spot_id)
    values ('b5000000-0000-0000-0000-00000000000e',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'note',
            'b2000000-0000-0000-0000-000000000002')$$,
  '23514',
  'entry with reference not matching kind is rejected'
);
-- 出発=到着の leg → distinct endpoints check 違反。
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id)
    values ('b6000000-0000-0000-0000-00000000000e',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000001')$$,
  '23514',
  'leg with same origin and destination is rejected'
);
-- 運賃の金額だけ（通貨なし） → fare pair check 違反。
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id,
       fare_amount_minor)
    values ('b6000000-0000-0000-0000-00000000000f',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002', 1000)$$,
  '23514',
  'leg with fare amount but no currency is rejected'
);
-- data_origin が user_provided 以外なのに rights_basis 空 → rights check 違反。
select throws_ok(
  $$insert into public.itinerary_spots
      (id, plan_id, owner_id, name, category, data_origin)
    values ('b2000000-0000-0000-0000-0000000000f1',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', '施設', 'other',
            'facility_provided')$$,
  '23514',
  'spot with non-user origin but empty rights_basis is rejected'
);
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id,
       value_origin)
    values ('b6000000-0000-0000-0000-0000000000f2',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000001',
            'b5000000-0000-0000-0000-000000000002', 'open_data')$$,
  '23514',
  'leg with non-user origin but empty rights_basis is rejected'
);

-- ===========================================================================
-- 参照整合性: entry の参照先・leg の両端は同一owner・同一計画/現場に属する必要
-- ===========================================================================
-- 別計画・別現場を用意する。
select lives_ok(
  $$insert into public.itinerary_plans
      (id, genba_id, owner_id, title, time_zone_id)
    values ('b1000000-0000-0000-0000-000000000003',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '計画2', 'Asia/Tokyo')$$,
  'owner can insert a second plan'
);
select lives_ok(
  $$insert into public.itinerary_entries
      (id, plan_id, owner_id, kind)
    values ('b5000000-0000-0000-0000-000000000010',
            'b1000000-0000-0000-0000-000000000003',
            '11111111-1111-1111-1111-111111111111', 'note')$$,
  'owner can insert an entry into the second plan'
);
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a1111111-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', 'アーティスト2', '公演2',
        '2026-09-01');
insert into public.transports (id, genba_id, owner_id, from_place, to_place)
values ('c1000000-0000-0000-0000-000000000002',
        'a1111111-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', '名古屋', '博多');

-- spot 参照が存在しない → 参照整合トリガーで拒否（P0001）。
select throws_ok(
  $$insert into public.itinerary_entries
      (id, plan_id, owner_id, kind, spot_id)
    values ('b5000000-0000-0000-0000-000000000011',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'spot',
            'b2000000-0000-0000-0000-0000000000aa')$$,
  'P0001',
  'entry referencing a non-existent spot is rejected'
);
-- transport が別現場（genba2）のもの → 「この現場」でないため拒否（P0001）。
select throws_ok(
  $$insert into public.itinerary_entries
      (id, plan_id, owner_id, kind, transport_id)
    values ('b5000000-0000-0000-0000-000000000012',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'transport',
            'c1000000-0000-0000-0000-000000000002')$$,
  'P0001',
  'entry referencing a transport of another genba is rejected'
);
-- leg の origin が別計画（plan2）の項目 → 同一計画でないため拒否（P0001）。
select throws_ok(
  $$insert into public.itinerary_legs
      (id, plan_id, owner_id, origin_entry_id, destination_entry_id)
    values ('b6000000-0000-0000-0000-000000000020',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            'b5000000-0000-0000-0000-000000000010',
            'b5000000-0000-0000-0000-000000000002')$$,
  'P0001',
  'leg with an endpoint from another plan is rejected'
);

-- ===========================================================================
-- 別owner（user2）による迂回・分離
-- ===========================================================================
select _as('22222222-2222-2222-2222-222222222222');

-- user2 が自分を owner にして user1 の計画へスポットを差し込む → 親owner不一致
-- でトリガー拒否（RLS with_check は owner=self で通るが、SECURITY DEFINER の
-- トリガーが親(plan)owner を見て弾く）。
select throws_ok(
  $$insert into public.itinerary_spots
      (id, plan_id, owner_id, name, category)
    values ('b2000000-0000-0000-0000-0000000000ee',
            'b1000000-0000-0000-0000-000000000002',
            '22222222-2222-2222-2222-222222222222', '乗っ取り', 'other')$$,
  'P0001',
  'child insert into other owner plan is rejected by owner trigger'
);
-- user2 は user1 の全5テーブルを読めない（RLS, SELECT分離）。
select is(
  (select count(*)::int from public.itinerary_plans
   where id = 'b1000000-0000-0000-0000-000000000002'),
  0,
  'other owner cannot read user1 plan'
);
select is(
  (select count(*)::int from public.itinerary_spots
   where id = 'b2000000-0000-0000-0000-000000000002'),
  0,
  'other owner cannot read user1 spot'
);
select is(
  (select count(*)::int from public.itinerary_spot_links
   where id = 'b4000000-0000-0000-0000-000000000001'),
  0,
  'other owner cannot read user1 spot link'
);
select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'b5000000-0000-0000-0000-000000000001'),
  0,
  'other owner cannot read user1 entry'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id = 'b6000000-0000-0000-0000-000000000001'),
  0,
  'other owner cannot read user1 leg'
);
-- user2 の update / delete は RLS で 0 行（no-op、全5テーブル）。
update public.itinerary_plans set title = '乗っ取り'
  where id = 'b1000000-0000-0000-0000-000000000002';
delete from public.itinerary_plans
  where id = 'b1000000-0000-0000-0000-000000000002';
update public.itinerary_spots set name = '乗っ取り'
  where id = 'b2000000-0000-0000-0000-000000000002';
delete from public.itinerary_spots
  where id = 'b2000000-0000-0000-0000-000000000002';
delete from public.itinerary_spot_links
  where id = 'b4000000-0000-0000-0000-000000000001';
delete from public.itinerary_entries
  where id = 'b5000000-0000-0000-0000-000000000001';
delete from public.itinerary_legs
  where id = 'b6000000-0000-0000-0000-000000000001';

-- ===========================================================================
-- user1 に戻り、迂回が効いていないこと・参照切れ・cascade を検証する
-- ===========================================================================
select _as('11111111-1111-1111-1111-111111111111');

select is(
  (select title from public.itinerary_plans
   where id = 'b1000000-0000-0000-0000-000000000002'),
  '計画1',
  'user1 plan title unchanged by user2 update attempt'
);
select is(
  (select count(*)::int from public.itinerary_plans
   where id = 'b1000000-0000-0000-0000-000000000002'),
  1,
  'user1 plan not deleted by user2 delete attempt'
);
-- 子（spot）も user2 の delete で消えていない（全5テーブルの delete 分離）。
select is(
  (select count(*)::int from public.itinerary_spots
   where id = 'b2000000-0000-0000-0000-000000000002'),
  1,
  'user1 spot not deleted by user2 delete attempt'
);

-- 交通を削除しても、それを参照する旅程項目は消えない（FK なし＝参照切れ）。
delete from public.transports
  where id = 'c1000000-0000-0000-0000-000000000001';
select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'b5000000-0000-0000-0000-000000000002'),
  1,
  'transport-entry survives deletion of referenced transport (broken ref)'
);

-- スポット削除 → link・訪問entry・その entry を端点とする leg が cascade する。
delete from public.itinerary_spots
  where id = 'b2000000-0000-0000-0000-000000000002';
select is(
  (select count(*)::int from public.itinerary_spot_links
   where id = 'b4000000-0000-0000-0000-000000000001'),
  0,
  'spot delete cascades to its links'
);
select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'b5000000-0000-0000-0000-000000000001'),
  0,
  'spot delete cascades to its visit entries'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id = 'b6000000-0000-0000-0000-000000000001'),
  0,
  'spot delete cascades to legs using its visit entry'
);

-- 現場削除 → 配下の計画（planRPC / plan1）が cascade する。
delete from public.genbas
  where id = 'a1111111-0000-0000-0000-000000000001';
select is(
  (select count(*)::int from public.itinerary_plans
   where genba_id = 'a1111111-0000-0000-0000-000000000001'),
  0,
  'genba delete cascades to its itinerary plans'
);

select * from finish();
rollback;
