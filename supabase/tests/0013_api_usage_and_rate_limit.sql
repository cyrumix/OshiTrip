-- pgTAP: Places プロキシの費用集計・レート制限（旅程Phase 3 / 0023）
--
-- - increment_api_usage は環境/サービス/SKU/日で件数を集計する
-- - check_and_increment_rate_limit は窓内の上限で false を返す
-- - api_usage_daily / places_rate_limit は service role のみ（一般ユーザーは
--   読めず、増分 RPC も実行できない）
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(6);

insert into auth.users (id, email)
values ('11111111-1111-1111-1111-111111111111', 'u1@example.com');

-- 件数の集計（service/postgres 相当）。
select public.increment_api_usage('development', 'places', 'autocomplete');
select public.increment_api_usage('development', 'places', 'autocomplete');

-- 1) 同一キーで件数が加算される
select results_eq(
  $$select coalesce(sum(count), 0)::int from public.api_usage_daily
    where environment = 'development' and service = 'places'
      and sku = 'autocomplete' and usage_date = current_date$$,
  $$values (2)$$,
  'increment_api_usage aggregates count by env/service/sku/day'
);

-- 2) レート制限: 上限内の初回は許可
select is(
  public.check_and_increment_rate_limit(
    '11111111-1111-1111-1111-111111111111', 1, 60),
  true,
  'rate limit allows the first call under the limit'
);

-- 3) レート制限: 上限到達で拒否
select is(
  public.check_and_increment_rate_limit(
    '11111111-1111-1111-1111-111111111111', 1, 60),
  false,
  'rate limit blocks once the per-window limit is reached'
);

-- ===========================================================================
-- 一般ユーザー（authenticated）: 集計・レート表は不可視、増分 RPC は実行不可
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 4) 集計は読めない（RLS・service role のみ）
select results_eq(
  $$select count(*)::int from public.api_usage_daily$$,
  $$values (0)$$,
  'authenticated cannot read api_usage_daily'
);

-- 5) レート制限表も読めない
select results_eq(
  $$select count(*)::int from public.places_rate_limit$$,
  $$values (0)$$,
  'authenticated cannot read places_rate_limit'
);

-- 6) 増分 RPC は実行できない（execute 権を revoke 済み）
select throws_ok(
  $$select public.increment_api_usage('development', 'places', 'autocomplete')$$,
  '42501',
  'authenticated cannot execute increment_api_usage'
);

select * from finish();
rollback;
