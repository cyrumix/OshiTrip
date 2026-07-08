-- ============================================================================
-- 0023_api_usage_and_rate_limit.sql
--   Places プロキシ（Edge Function）の費用集計・レート制限の基盤
--   （旅程Phase 3 / itinerary-plan-spec §8・ADR-0010 §7 の費用抑制）。
--
--   - api_usage_daily: サービス／SKU相当／環境／日単位の**件数のみ**を集計する。
--     検索文・住所・座標・Place ID 等の個人内容は保存しない。
--   - places_rate_limit: ユーザー別のレート制限窓（件数のみ。内容は保存しない）。
--   - いずれも service role（Edge Function）だけが読み書きする。RLS を有効化し
--     一般ユーザー向けポリシーを作らない（不可視・不可変）。
--   - 料金額はここへ固定しない（閾値・単価はサーバー設定で扱う, ADR-0010 §12）。
--
--   前方専用。過去 migration は変更しない。
-- ============================================================================

-- ---- 日次の API 利用件数（内容は保存しない）---------------------------------
create table public.api_usage_daily (
  id uuid primary key default gen_random_uuid(),
  environment text not null,          -- development / staging / production
  service text not null,              -- 'places'
  sku text not null,                  -- 'autocomplete' / 'place_details' 等
  usage_date date not null default current_date,
  count bigint not null default 0,
  updated_at timestamptz not null default now(),
  unique (environment, service, sku, usage_date)
);
alter table public.api_usage_daily enable row level security;
-- ポリシーを作らない = 一般ユーザーからは不可視・不可変（service role のみ）。

-- 件数を +1 する（当日行を upsert）。service role/Edge Function からのみ実行する。
create or replace function public.increment_api_usage(
  p_environment text,
  p_service text,
  p_sku text
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.api_usage_daily
    (environment, service, sku, usage_date, count, updated_at)
  values (p_environment, p_service, p_sku, current_date, 1, now())
  on conflict (environment, service, sku, usage_date)
  do update set count = api_usage_daily.count + 1, updated_at = now();
end;
$$;

-- ---- ユーザー別レート制限（件数のみ・窓管理）-------------------------------
create table public.places_rate_limit (
  owner_id uuid primary key references auth.users (id) on delete cascade,
  window_start timestamptz not null default now(),
  count integer not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.places_rate_limit enable row level security;
-- ポリシーを作らない = service role のみ。

-- 窓内なら count++ して true（許可）、超過なら false。窓経過でリセットする。
-- 内容（検索文等）は一切保存しない。
create or replace function public.check_and_increment_rate_limit(
  p_owner uuid,
  p_limit integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_row public.places_rate_limit;
  v_now timestamptz := now();
begin
  insert into public.places_rate_limit (owner_id, window_start, count, updated_at)
  values (p_owner, v_now, 0, v_now)
  on conflict (owner_id) do nothing;

  select * into v_row from public.places_rate_limit
    where owner_id = p_owner for update;

  -- 窓を過ぎていればリセットして 1 件目として許可。
  if v_row.window_start < v_now - make_interval(secs => p_window_seconds) then
    update public.places_rate_limit
      set window_start = v_now, count = 1, updated_at = v_now
      where owner_id = p_owner;
    return true;
  end if;

  if v_row.count >= p_limit then
    return false; -- 上限到達 → 自動取得を止める（手動登録は別経路で継続）
  end if;

  update public.places_rate_limit
    set count = count + 1, updated_at = v_now
    where owner_id = p_owner;
  return true;
end;
$$;

-- 実行権は service role（Edge Function）に限定する（一般ユーザーは呼べない）。
revoke execute on function
  public.increment_api_usage(text, text, text) from public;
revoke execute on function
  public.check_and_increment_rate_limit(uuid, integer, integer) from public;
grant execute on function
  public.increment_api_usage(text, text, text) to service_role;
grant execute on function
  public.check_and_increment_rate_limit(uuid, integer, integer) to service_role;
