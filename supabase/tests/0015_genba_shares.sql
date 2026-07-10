-- pgTAP: 現場共有データ基盤（Phase 5 前提基盤 / 0028）
--
-- 保守的スライスのため、本テストは genba_shares 表**自身**の owner 管理 RLS と
-- 子owner トリガ・CHECK・apply_mutation 版CAS を検証する（既存データ表の RLS は
-- 無改変。grantee による共有データの read/write ロール別RLSは次増分）。
--
-- 検証:
-- - owner（現場所有者）が自分の共有を CRUD できる
-- - grantee は「自分に共有された行」を SELECT できるが insert/update/delete 不可
-- - 他人の現場は共有できない（子owner トリガ）
-- - owner_id 偽装は RLS WITH CHECK で拒否
-- - 自己共有・不正role は CHECK 制約で拒否
-- - apply_mutation 経由の版CAS（新規=applied / 古いbase_version=conflict）
--
-- 実行: supabase start → supabase db reset → supabase test db
-- 注意: 本リポジトリ環境は Docker/Supabase CLI 未導入のため**未実行**（静的レビューのみ）。
begin;

create extension if not exists pgtap with schema extensions;

select plan(13);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'grantee@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'grantee2@example.com');

-- ===========================================================================
-- owner（user-1）: 現場を用意し、共有を CRUD する
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

insert into public.genbas (id, owner_id, artist_name, title, event_date)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'A', 'T', '2026-08-01'
);

-- 1) owner は自分の現場の共有を作成できる
select lives_ok(
  $$insert into public.genba_shares
      (id, owner_id, genba_id, grantee_id, role)
    values (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '22222222-2222-2222-2222-222222222222',
      'viewer'
    )$$,
  'owner can create a share for their own genba'
);

-- 2) owner は自分の共有を閲覧できる
select results_eq(
  $$select count(*)::int from public.genba_shares
      where genba_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  $$values (1)$$,
  'owner can read their own share'
);

-- 3) owner は共有権限を変更できる
select lives_ok(
  $$update public.genba_shares set role = 'editor'
      where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'$$,
  'owner can update a share role'
);

-- ===========================================================================
-- grantee（user-2）: 自分に共有された行を SELECT できるが書けない
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

-- 4) grantee は自分に共有された行を閲覧できる
select results_eq(
  $$select count(*)::int from public.genba_shares
      where grantee_id = '22222222-2222-2222-2222-222222222222'$$,
  $$values (1)$$,
  'grantee can read a share granted to them'
);

-- 5) grantee は共有行を作成できない（owner を詐称した insert は RLS WITH CHECK で拒否）
select throws_ok(
  $$insert into public.genba_shares
      (id, owner_id, genba_id, grantee_id, role)
    values (
      'cccccccc-cccc-cccc-cccc-cccccccccccc',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '33333333-3333-3333-3333-333333333333',
      'viewer'
    )$$,
  '42501',
  'grantee cannot insert a share (owner spoof blocked by RLS WITH CHECK)'
);

-- 6) grantee は共有行を更新できない（update ポリシー無し = 0行）
select results_eq(
  $$with u as (
      update public.genba_shares set role = 'viewer'
        where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'grantee cannot update a share (no update policy)'
);

-- 7) grantee は共有行を削除できない（delete ポリシー無し = 0行）
select results_eq(
  $$with d as (
      delete from public.genba_shares
        where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'grantee cannot delete a share (no delete policy)'
);

-- 8) 非owner が他人の現場を共有しようとすると子owner トリガで拒否
select throws_ok(
  $$insert into public.genba_shares
      (id, owner_id, genba_id, grantee_id, role)
    values (
      'dddddddd-dddd-dddd-dddd-dddddddddddd',
      '22222222-2222-2222-2222-222222222222',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '33333333-3333-3333-3333-333333333333',
      'viewer'
    )$$,
  'owner_id must match parent genba owner',
  'non-owner cannot share another user''s genba (child-owner trigger)'
);

-- ===========================================================================
-- owner（user-1）: 偽装・CHECK・apply_mutation 版CAS
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 9) owner_id 偽装（owner_id を他人にした insert）は RLS WITH CHECK で拒否
select throws_ok(
  $$insert into public.genba_shares
      (id, owner_id, genba_id, grantee_id, role)
    values (
      'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
      '22222222-2222-2222-2222-222222222222',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '33333333-3333-3333-3333-333333333333',
      'viewer'
    )$$,
  '42501',
  'owner_id spoofing is rejected by RLS WITH CHECK'
);

-- 10) 自己共有（grantee = owner）は CHECK 制約で拒否
select throws_ok(
  $$insert into public.genba_shares
      (id, owner_id, genba_id, grantee_id, role)
    values (
      'ffffffff-ffff-ffff-ffff-ffffffffffff',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '11111111-1111-1111-1111-111111111111',
      'viewer'
    )$$,
  '23514',
  'self-share (grantee = owner) is rejected by CHECK'
);

-- 11) 不正role（owner）は CHECK 制約で拒否（共有行は editor/viewer のみ）
select throws_ok(
  $$insert into public.genba_shares
      (id, owner_id, genba_id, grantee_id, role)
    values (
      '99999999-9999-9999-9999-999999999999',
      '11111111-1111-1111-1111-111111111111',
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '33333333-3333-3333-3333-333333333333',
      'owner'
    )$$,
  '23514',
  'role=owner is rejected by CHECK (share rows are editor/viewer only)'
);

-- 12) apply_mutation 経由の新規 upsert は applied（owner_id はサーバー矯正）
select is(
  (select public.apply_mutation(
    '00000000-0000-0000-0000-0000000000a1'::uuid,
    'genba_shares',
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    'upsert',
    '{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc",'
    '"genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",'
    '"grantee_id":"33333333-3333-3333-3333-333333333333",'
    '"role":"viewer"}'::jsonb,
    null
  ) ->> 'status'),
  'applied',
  'apply_mutation upsert (new share) returns applied'
);

-- 13) 既存行への base_version 不一致は conflict（黙った last-write-wins 禁止）
select is(
  (select public.apply_mutation(
    '00000000-0000-0000-0000-0000000000a2'::uuid,
    'genba_shares',
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    'upsert',
    '{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc",'
    '"genba_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",'
    '"grantee_id":"33333333-3333-3333-3333-333333333333",'
    '"role":"editor"}'::jsonb,
    999
  ) ->> 'status'),
  'conflict',
  'apply_mutation upsert with stale base_version returns conflict'
);

select * from finish();
rollback;
