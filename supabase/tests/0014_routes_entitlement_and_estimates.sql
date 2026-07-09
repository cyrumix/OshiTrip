-- pgTAP: 旅程Phase 4 entitlement・Routesレート制限・共有概算経路（0027）
--
-- - user_entitlements: 本人は自分の行だけ読める。書き込みは一切できない
--   （INSERT/UPDATE/DELETEポリシー無し = クライアントだけで偽装できない）
-- - has_premium_routes_entitlement: 行が無ければfalse、付与済みならtrue
-- - routes_rate_limit: 0023のplaces_rate_limitと同型（一般ユーザーは不可視）
-- - shared_route_estimates: draft-only insert・承認済みは投稿者が変更不可・
--   rights_basis必須・他者は承認済みのみ閲覧可
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(20);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'owner2@example.com');

-- ===========================================================================
-- user_entitlements
-- ===========================================================================

-- 1) 行が無いownerはfalse
select is(
  public.has_premium_routes_entitlement('11111111-1111-1111-1111-111111111111'),
  false,
  'has_premium_routes_entitlement defaults to false when no row exists'
);

-- service role相当でowner1へ付与する。
insert into public.user_entitlements (owner_id, premium_routes_live, granted_at)
values ('11111111-1111-1111-1111-111111111111', true, now());

-- 2) 付与後はtrue
select is(
  public.has_premium_routes_entitlement('11111111-1111-1111-1111-111111111111'),
  true,
  'has_premium_routes_entitlement returns true once granted'
);

-- 3) 別ownerは引き続きfalse
select is(
  public.has_premium_routes_entitlement('22222222-2222-2222-2222-222222222222'),
  false,
  'has_premium_routes_entitlement is per-owner'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 4) 本人は自分の行を読める
select results_eq(
  $$select premium_routes_live from public.user_entitlements
      where owner_id = '11111111-1111-1111-1111-111111111111'$$,
  $$values (true)$$,
  'owner can read their own entitlement row'
);

-- 5) 他人の行は見えない
select results_eq(
  $$select count(*)::int from public.user_entitlements
      where owner_id = '22222222-2222-2222-2222-222222222222'$$,
  $$values (0)$$,
  'owner cannot read another owner''s entitlement row'
);

-- 6) 自己付与（INSERT）はできない（ポリシー無し = 拒否）
select throws_ok(
  $$insert into public.user_entitlements (owner_id, premium_routes_live)
      values ('11111111-1111-1111-1111-111111111111', true)$$,
  '42501',
  'authenticated cannot insert into user_entitlements (self-grant impossible)'
);

-- 7) 自己更新（UPDATE）もできない
select throws_ok(
  $$update public.user_entitlements set premium_routes_live = false
      where owner_id = '11111111-1111-1111-1111-111111111111'$$,
  '42501',
  'authenticated cannot update user_entitlements (self-modification impossible)'
);

-- 8) entitlement検証RPCは一般ユーザーから実行できない（service_role専用）
select throws_ok(
  $$select public.has_premium_routes_entitlement(
      '11111111-1111-1111-1111-111111111111')$$,
  '42501',
  'authenticated cannot execute has_premium_routes_entitlement'
);

reset role;

-- ===========================================================================
-- routes_rate_limit（0023 places_rate_limit と同型）
-- ===========================================================================

-- 9) 上限内の初回は許可
select is(
  public.check_and_increment_routes_rate_limit(
    '11111111-1111-1111-1111-111111111111', 1, 60),
  true,
  'routes rate limit allows the first call under the limit'
);

-- 10) 上限到達で拒否
select is(
  public.check_and_increment_routes_rate_limit(
    '11111111-1111-1111-1111-111111111111', 1, 60),
  false,
  'routes rate limit blocks once the per-window limit is reached'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 11) 一般ユーザーはレート表を読めない
select results_eq(
  $$select count(*)::int from public.routes_rate_limit$$,
  $$values (0)$$,
  'authenticated cannot read routes_rate_limit'
);

-- 12) 一般ユーザーは増分RPCを実行できない
select throws_ok(
  $$select public.check_and_increment_routes_rate_limit(
      '11111111-1111-1111-1111-111111111111', 1, 60)$$,
  '42501',
  'authenticated cannot execute check_and_increment_routes_rate_limit'
);

reset role;

-- ===========================================================================
-- shared_route_estimates（shared_facilities 0022/0024/0025 と同じ規則）
-- ===========================================================================

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 13) draft としての新規登録は成功する
select lives_ok(
  $$insert into public.shared_route_estimates
      (id, created_by, travel_mode, data_origin, moderation_status)
    values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '11111111-1111-1111-1111-111111111111',
      'walking', 'user_provided', 'draft'
    )$$,
  'authenticated can insert a draft shared_route_estimate'
);

-- 14) pending を直接指定した新規登録は拒否される
select throws_ok(
  $$insert into public.shared_route_estimates
      (id, created_by, travel_mode, data_origin, moderation_status)
    values (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      '11111111-1111-1111-1111-111111111111',
      'walking', 'user_provided', 'pending'
    )$$,
  'P0001',
  'authenticated cannot insert directly as pending'
);

-- 15) draft→pending の申請（UPDATE）は成功する
select lives_ok(
  $$update public.shared_route_estimates set moderation_status = 'pending'
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'authenticated can submit their draft as pending'
);

-- 16) 一般ユーザーは自分の投稿を自己承認できない（service role専用の遷移）
select throws_ok(
  $$update public.shared_route_estimates set moderation_status = 'approved'
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'P0001',
  'authenticated cannot self-approve their own submission'
);

reset role;

-- service role相当で承認（rights_basisを付与）。
update public.shared_route_estimates
  set moderation_status = 'approved', rights_basis = 'ユーザー入力の実測値'
  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 17) 承認済みは投稿者本人でも更新できない
select throws_ok(
  $$update public.shared_route_estimates set route_summary = '書き換え'
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  '42501',
  'creator cannot update an approved shared_route_estimate'
);

-- 18) 承認済みは投稿者本人でも削除できない
select throws_ok(
  $$delete from public.shared_route_estimates
      where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  '42501',
  'creator cannot delete an approved shared_route_estimate'
);

reset role;

-- 19) 別ownerは承認済みのみ閲覧できる（他者の draft は見えない）
insert into public.shared_route_estimates
  (id, created_by, travel_mode, data_origin, moderation_status)
values (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  '11111111-1111-1111-1111-111111111111',
  'transit', 'user_provided', 'draft'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select results_eq(
  $$select moderation_status::text from public.shared_route_estimates
      order by moderation_status$$,
  $$values ('approved')$$,
  'other users only see approved shared_route_estimates, not another owner''s draft'
);

reset role;

-- 20) data_origin に 'google' を直接指定した登録は型（CHECK制約）で拒否される
select throws_ok(
  $$insert into public.shared_route_estimates
      (id, created_by, travel_mode, data_origin, moderation_status)
    values (
      'dddddddd-dddd-dddd-dddd-dddddddddddd',
      '11111111-1111-1111-1111-111111111111',
      'walking', 'google', 'draft'
    )$$,
  '23514',
  'data_origin=google is rejected by the CHECK constraint'
);

select * from finish();
rollback;
