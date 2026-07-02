-- pgTAP: 思い出・マイ推し・公演マスタの認可検証（ADR-0008）
begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

-- user1: 現場 + 思い出 + マイ推し + 公演マスタ投稿
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演', '2026-06-01');

select lives_ok(
  $$insert into public.memory_entries (id, genba_id, owner_id, impression)
    values ('eeeeeeee-0000-0000-0000-000000000001',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '最高だった')$$,
  'owner can insert memory entry'
);

select lives_ok(
  $$insert into public.oshi_groups (id, owner_id, name)
    values ('ffffffff-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '推しグループ')$$,
  'owner can insert oshi group'
);

select lives_ok(
  $$insert into public.performances
      (id, group_name, title, venue, event_date, start_time_minutes, created_by)
    values ('99999999-0000-0000-0000-000000000001',
            'アーティスト', '共通公演', 'ホール', '2026-09-01', 1080,
            '11111111-1111-1111-1111-111111111111')$$,
  'authenticated user can submit performance'
);

-- user2: 個人データは見えない・書けない。公演マスタは読める。
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select results_eq(
  $$select count(*)::int from public.memory_entries$$,
  $$values (0)$$,
  'other user cannot read memory entries'
);

select results_eq(
  $$select count(*)::int from public.oshi_groups$$,
  $$values (0)$$,
  'other user cannot read oshi groups'
);

select results_eq(
  $$with u as (
      update public.memory_entries set impression = '改ざん'
      where id = 'eeeeeeee-0000-0000-0000-000000000001'
      returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update memory entry'
);

select results_eq(
  $$select count(*)::int from public.performances$$,
  $$values (1)$$,
  'performance master is readable by authenticated users'
);

-- 公演マスタは作成者以外は更新不可（更新対象0行）
select results_eq(
  $$with u as (
      update public.performances set title = '書き換え'
      where id = '99999999-0000-0000-0000-000000000001'
      returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'non-creator cannot update performance master'
);

-- メンバーの所有権迂回防止
select throws_ok(
  $$insert into public.oshi_members (id, group_id, owner_id, name)
    values ('88888888-0000-0000-0000-000000000001',
            'ffffffff-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222', '不正メンバー')$$,
  'owner_id must match parent group owner'
);

-- 未認証（anon）は公演マスタも読めない（デフォルト非公開方針）
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);

select results_eq(
  $$select count(*)::int from public.performances$$,
  $$values (0)$$,
  'anonymous cannot read performance master'
);

select * from finish();
rollback;
