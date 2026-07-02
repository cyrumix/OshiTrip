-- pgTAP: 現場集約の所有権/RLS 検証（ADR-0008）
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(12);

-- テストユーザーを2人作成
insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

-- ---------------------------------------------------------------------------
-- user1 として: 自分のデータを CRUD できる
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$insert into public.genbas (id, owner_id, artist_name, title, event_date)
    values ('aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'テストアーティスト', 'テスト公演', '2026-08-01')$$,
  'owner can insert own genba'
);

select lives_ok(
  $$insert into public.tickets (id, genba_id, owner_id, seat)
    values ('bbbbbbbb-0000-0000-0000-000000000001',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'A-10')$$,
  'owner can insert child ticket'
);

select results_eq(
  $$select count(*)::int from public.genbas$$,
  $$values (1)$$,
  'owner can select own genba'
);

select lives_ok(
  $$update public.genbas set venue = 'テスト会場'
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  'owner can update own genba'
);

select lives_ok(
  $$insert into public.todos (id, genba_id, owner_id, name)
    values ('cccccccc-0000-0000-0000-000000000001',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '物販列に並ぶ')$$,
  'owner can insert todo'
);

select lives_ok(
  $$insert into public.outbox_operations (id, owner_id, entity_table, entity_id, op_type)
    values ('dddddddd-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert')$$,
  'owner can record mutation for idempotency'
);

-- ---------------------------------------------------------------------------
-- user2 として: 他人のデータへは到達不可
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select results_eq(
  $$select count(*)::int from public.genbas$$,
  $$values (0)$$,
  'other user cannot select genba'
);

select results_eq(
  $$select count(*)::int from public.tickets$$,
  $$values (0)$$,
  'other user cannot select tickets'
);

-- UPDATE/DELETE は対象0行（到達不可）
select results_eq(
  $$with u as (
      update public.genbas set title = '乗っ取り'
      where id = 'aaaaaaaa-0000-0000-0000-000000000001'
      returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update genba'
);

select results_eq(
  $$with d as (
      delete from public.tickets
      where id = 'bbbbbbbb-0000-0000-0000-000000000001'
      returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete ticket'
);

-- 子テーブル経由の所有権迂回: 他人の現場へ自分名義の子行は挿入できない
select throws_ok(
  $$insert into public.todos (id, genba_id, owner_id, name)
    values ('cccccccc-0000-0000-0000-000000000002',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222', '不正なTodo')$$,
  'owner_id must match parent genba owner'
);

-- 他人になりすました owner_id での挿入は RLS with check で拒否
select throws_ok(
  $$insert into public.todos (id, genba_id, owner_id, name)
    values ('cccccccc-0000-0000-0000-000000000003',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'なりすましTodo')$$,
  '42501'
);

select * from finish();
rollback;
