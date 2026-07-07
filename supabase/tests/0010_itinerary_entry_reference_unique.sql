-- pgTAP: 同一計画に同じ交通／宿泊を二重参照させない部分ユニーク索引（0014）の
--        サーバー側強制を検証する（§5.3 / Phase 2レビュー点6）。
--
--   - 同一計画・同一 transport_id の直接 INSERT 重複を拒否（23505）
--   - transport_id を衝突させる UPDATE を拒否（23505）
--   - apply_mutation 経由の重複 upsert も拒否（23505）
--   - 異なる計画では同じ transport_id / lodging_id を許可（複製ではなく参照）
--   - 宿泊(lodging_id)も同様に重複拒否
--   - spot / note（transport_id・lodging_id が NULL）は重複対象外＝回帰なし
--   - 既存重複がある状態からの移行方針（0014 の dedup）で決定的に1件へ整理され、
--     負け側を端点とする leg も cascade で消え、索引を張り直せること
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(16);

insert into auth.users (id, email)
values ('11111111-1111-1111-1111-111111111111', 'user1@example.com');

set local role authenticated;

create or replace function _as(uid text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

select _as('11111111-1111-1111-1111-111111111111');

-- 親: 現場と計画2件、スポット2件（spot 回帰確認用）。
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演',
        '2026-08-01');
insert into public.itinerary_plans (id, genba_id, owner_id, title, time_zone_id)
values ('b1000000-0000-0000-0000-000000000001',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '計画1', 'Asia/Tokyo'),
       ('b1000000-0000-0000-0000-000000000002',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '計画2', 'Asia/Tokyo'),
       ('b1000000-0000-0000-0000-000000000003',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '移行検証', 'Asia/Tokyo');
insert into public.itinerary_spots
  (id, plan_id, owner_id, name, category)
values ('e1000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'スポットA', 'other'),
       ('e1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'スポットB', 'other');

-- ---------------------------------------------------------------------------
-- 交通: 計画1に tr-1 を1件追加できる。同一計画への tr-1 二重追加は拒否。
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind, transport_id)
    values ('c5000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'transport',
            'd0000000-0000-0000-0000-000000000001')$$,
  'first transport reference is inserted'
);
select throws_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind, transport_id)
    values ('c5000000-0000-0000-0000-000000000002',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'transport',
            'd0000000-0000-0000-0000-000000000001')$$,
  '23505',
  'duplicate (plan, transport) direct INSERT is rejected'
);
select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'c5000000-0000-0000-0000-000000000002'),
  0,
  'rejected duplicate transport entry is not created'
);

-- ---------------------------------------------------------------------------
-- 異なる計画では同じ tr-1 を参照できる（複製ではなく参照なので許可）。
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind, transport_id)
    values ('c5000000-0000-0000-0000-000000000003',
            'b1000000-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'transport',
            'd0000000-0000-0000-0000-000000000001')$$,
  'same transport in a different plan is allowed'
);

-- ---------------------------------------------------------------------------
-- 既存 tr-2(計画1) を tr-1 へ UPDATE して衝突させる操作も拒否。
-- ---------------------------------------------------------------------------
insert into public.itinerary_entries (id, plan_id, owner_id, kind, transport_id)
values ('c5000000-0000-0000-0000-000000000004',
        'b1000000-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'transport',
        'd0000000-0000-0000-0000-000000000002');
select throws_ok(
  $$update public.itinerary_entries
      set transport_id = 'd0000000-0000-0000-0000-000000000001'
    where id = 'c5000000-0000-0000-0000-000000000004'$$,
  '23505',
  'UPDATE that collides on (plan, transport) is rejected'
);

-- ---------------------------------------------------------------------------
-- apply_mutation 経由の重複 upsert も拒否（23505）＝経路を問わず弾く。
-- ---------------------------------------------------------------------------
select throws_ok(
  $$select public.apply_mutation(
      'dd000000-0000-0000-0000-000000000001',
      'itinerary_entries', 'c5000000-0000-0000-0000-0000000000aa', 'upsert',
      jsonb_build_object(
        'id', 'c5000000-0000-0000-0000-0000000000aa',
        'owner_id', '11111111-1111-1111-1111-111111111111',
        'plan_id', 'b1000000-0000-0000-0000-000000000001',
        'kind', 'transport',
        'transport_id', 'd0000000-0000-0000-0000-000000000001'),
      null)$$,
  '23505',
  'apply_mutation upsert that duplicates (plan, transport) is rejected'
);
select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'c5000000-0000-0000-0000-0000000000aa'),
  0,
  'rejected apply_mutation duplicate is not created'
);

-- apply_mutation は重複でなければ従来どおり適用できる（弱体化していない）。
select is(
  (select public.apply_mutation(
    'dd000000-0000-0000-0000-000000000002',
    'itinerary_entries', 'c5000000-0000-0000-0000-0000000000bb', 'upsert',
    jsonb_build_object(
      'id', 'c5000000-0000-0000-0000-0000000000bb',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'plan_id', 'b1000000-0000-0000-0000-000000000002',
      'kind', 'transport',
      'transport_id', 'd0000000-0000-0000-0000-000000000002'),
    null
  ) ->> 'status'),
  'applied',
  'apply_mutation with a non-duplicate transport still syncs'
);

-- ---------------------------------------------------------------------------
-- 宿泊も同様: 計画1に lo-1 を1件、二重は拒否。
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind, lodging_id)
    values ('c6000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'lodging',
            'd1000000-0000-0000-0000-000000000001')$$,
  'first lodging reference is inserted'
);
select throws_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind, lodging_id)
    values ('c6000000-0000-0000-0000-000000000002',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'lodging',
            'd1000000-0000-0000-0000-000000000001')$$,
  '23505',
  'duplicate (plan, lodging) direct INSERT is rejected'
);

-- ---------------------------------------------------------------------------
-- spot / note は transport_id・lodging_id が NULL のため対象外＝回帰なし。
-- 同一計画に spot を複数、note を複数入れても弾かれない。
-- ---------------------------------------------------------------------------
select lives_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind, spot_id)
    values ('c7000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'spot',
            'e1000000-0000-0000-0000-000000000001'),
           ('c7000000-0000-0000-0000-000000000002',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'spot',
            'e1000000-0000-0000-0000-000000000002')$$,
  'multiple spot entries in one plan are allowed (no regression)'
);
select lives_ok(
  $$insert into public.itinerary_entries (id, plan_id, owner_id, kind)
    values ('c8000000-0000-0000-0000-000000000001',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'note'),
           ('c8000000-0000-0000-0000-000000000002',
            'b1000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'note')$$,
  'multiple note entries in one plan are allowed (no regression)'
);

-- ---------------------------------------------------------------------------
-- 既存重複がある状態からの移行方針（0014 の dedup）を検証する。
-- 索引を一旦落として重複を作り、0014 と同じ dedup を流し、索引を張り直す。
-- 期待: 決定的に1件（sort_order 最小）だけ残り、負け側を端点とする leg は
--       cascade で消え、索引を問題なく再作成できる。
-- ---------------------------------------------------------------------------
drop index if exists idx_itinerary_entries_plan_transport;
drop index if exists idx_itinerary_entries_plan_lodging;

-- 計画3に同じ tr-9 を参照する2件（勝ち: sort_order=0 / 負け: sort_order=1）。
insert into public.itinerary_entries
  (id, plan_id, owner_id, kind, transport_id, sort_order, created_at)
values ('f9000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111', 'transport',
        'd0000000-0000-0000-0000-000000000009', 0, '2026-01-01T00:00:00Z'),
       ('f9000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111', 'transport',
        'd0000000-0000-0000-0000-000000000009', 1, '2026-01-02T00:00:00Z');
-- 別項目（note）と、負け側を終点とする leg（cascade 掃除の確認用）。
insert into public.itinerary_entries (id, plan_id, owner_id, kind)
values ('f9000000-0000-0000-0000-0000000000a1',
        'b1000000-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111', 'note');
insert into public.itinerary_legs
  (id, plan_id, owner_id, origin_entry_id, destination_entry_id)
values ('fa000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111',
        'f9000000-0000-0000-0000-0000000000a1',
        'f9000000-0000-0000-0000-000000000002');

-- 0014 と同一の dedup（負け側を決定的に削除）。
with losers as (
  select e.id
    from public.itinerary_entries e
   where e.transport_id is not null
     and exists (
       select 1 from public.itinerary_entries o
        where o.plan_id = e.plan_id and o.transport_id = e.transport_id
          and o.id <> e.id
          and (o.sort_order, o.created_at, o.id)
              < (e.sort_order, e.created_at, e.id))
  union
  select e.id
    from public.itinerary_entries e
   where e.lodging_id is not null
     and exists (
       select 1 from public.itinerary_entries o
        where o.plan_id = e.plan_id and o.lodging_id = e.lodging_id
          and o.id <> e.id
          and (o.sort_order, o.created_at, o.id)
              < (e.sort_order, e.created_at, e.id))
)
delete from public.itinerary_entries e where e.id in (select id from losers);

select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'f9000000-0000-0000-0000-000000000001'),
  1,
  'dedup keeps the deterministic winner (min sort_order)'
);
select is(
  (select count(*)::int from public.itinerary_entries
   where id = 'f9000000-0000-0000-0000-000000000002'),
  0,
  'dedup removes the losing duplicate'
);
select is(
  (select count(*)::int from public.itinerary_legs
   where id = 'fa000000-0000-0000-0000-000000000001'),
  0,
  'leg whose endpoint was a losing duplicate is cascade-deleted'
);

-- 重複が消えたので索引を張り直せる。
create unique index idx_itinerary_entries_plan_transport
  on public.itinerary_entries (plan_id, transport_id)
  where transport_id is not null;
select has_index(
  'public', 'itinerary_entries', 'idx_itinerary_entries_plan_transport',
  'unique index can be recreated after dedup'
);

select * from finish();
rollback;
