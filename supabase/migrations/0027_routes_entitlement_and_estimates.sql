-- ============================================================================
-- 0027_routes_entitlement_and_estimates.sql
--   旅程Phase 4（Google Routes連携）の基盤: プレミアムentitlement・
--   Routesレート制限・共有概算経路スキーマ（itinerary-plan-spec §6.3/§8.3/§12.6・
--   ADR-0010 §8・requirements.md §7.9・decisions.md D-214〜D-216）。
--
--   - user_entitlements: 「Google Routesのライブ取得はプレミアム限定」を
--     サーバー側で強制するための最小entitlementテーブル。課金・購入フローは
--     このmigrationにも実装しない（spec §14.4）。既定は全員 false（非プレミアム）。
--     クライアントは自分の行を読めるが、書き込み（INSERT/UPDATE/DELETE）は
--     一切できない（service_role のみ）——「クライアントだけで偽装できない」
--     ことをRLSで保証する。
--   - routes_rate_limit: Routesプロキシ用のユーザー別レート制限（0023の
--     places_rate_limit と同型・別テーブル。既存migrationは変更しない
--     前方専用方針を踏襲）。
--   - shared_route_estimates: 権利確認済み共有概算経路（itinerary-plan-spec
--     §12.6）。shared_facilities（0022/0024/0025）と同じ理由でスキーマ・
--     不変条件・サーバー強制までとし、クライアント側の投稿・閲覧UIは
--     後続増分とする。0022の初期版ではなく0024/0025で確定した最終形
--     （draft-only insert・承認済みは投稿者が変更不可）を最初から適用する。
--
--   前方専用。過去 migration は変更しない。
-- ============================================================================

-- ---- プレミアムentitlement（読み取り専用レプリカの正本）----------------------
create table public.user_entitlements (
  owner_id uuid primary key references auth.users (id) on delete cascade,
  premium_routes_live boolean not null default false,
  granted_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.user_entitlements enable row level security;

-- 本人は自分の行だけ読める。INSERT/UPDATE/DELETEポリシーは作らない
-- （= 一般ユーザーは一切書き込めない。付与はservice_roleのみ）。
create policy "user_entitlements_select_own"
  on public.user_entitlements
  for select using (owner_id = auth.uid());

create trigger trg_user_entitlements_updated_at
  before update on public.user_entitlements
  for each row execute function public.set_updated_at();

-- Edge Function から呼ぶ entitlement 検証ヘルパ（行が無ければ false）。
create or replace function public.has_premium_routes_entitlement(p_owner uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select premium_routes_live from public.user_entitlements
       where owner_id = p_owner),
    false
  );
$$;
revoke execute on function
  public.has_premium_routes_entitlement(uuid) from public;
grant execute on function
  public.has_premium_routes_entitlement(uuid) to service_role;

-- ---- Routes プロキシ用レート制限（0023 の places_rate_limit と同型）----------
create table public.routes_rate_limit (
  owner_id uuid primary key references auth.users (id) on delete cascade,
  window_start timestamptz not null default now(),
  count integer not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.routes_rate_limit enable row level security;
-- ポリシーを作らない = service role のみ。

create or replace function public.check_and_increment_routes_rate_limit(
  p_owner uuid,
  p_limit integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_row public.routes_rate_limit;
  v_now timestamptz := now();
begin
  insert into public.routes_rate_limit (owner_id, window_start, count, updated_at)
  values (p_owner, v_now, 0, v_now)
  on conflict (owner_id) do nothing;

  select * into v_row from public.routes_rate_limit
    where owner_id = p_owner for update;

  if v_row.window_start < v_now - make_interval(secs => p_window_seconds) then
    update public.routes_rate_limit
      set window_start = v_now, count = 1, updated_at = v_now
      where owner_id = p_owner;
    return true;
  end if;

  if v_row.count >= p_limit then
    return false; -- 上限到達 → 手動入力へ縮退（保存済み概算経路は閲覧可のまま）
  end if;

  update public.routes_rate_limit
    set count = count + 1, updated_at = v_now
    where owner_id = p_owner;
  return true;
end;
$$;

revoke execute on function
  public.check_and_increment_routes_rate_limit(uuid, integer, integer)
  from public;
grant execute on function
  public.check_and_increment_routes_rate_limit(uuid, integer, integer)
  to service_role;

-- ---- 共有概算経路（shared_facilities と同型、最終形を最初から適用）------------
create table public.shared_route_estimates (
  id uuid primary key,
  created_by uuid not null references auth.users (id) on delete cascade,

  -- 出発・到着スポットの照合キー（任意、shared_facilities.id を参照する
  -- クロスユーザー再利用を想定。名称・住所同様に権利根拠にはしない）。
  origin_facility_id uuid,
  destination_facility_id uuid,

  travel_mode text not null
    check (travel_mode in ('walking', 'transit', 'driving', 'bicycling')),
  representative_time_bucket text,

  distance_meters integer,
  duration_minutes integer,
  route_summary text,
  fare_amount_minor integer,
  fare_currency text,

  -- 権利根拠を説明できる出典のみ（'google' は存在しない = Google応答の
  -- そのままの共有登録を型で不可能にする）。
  data_origin text not null
    check (data_origin in
      ('user_provided', 'facility_provided', 'open_data', 'licensed')),
  rights_basis text,

  moderation_status text not null default 'draft'
    check (moderation_status in ('draft', 'pending', 'approved', 'rejected')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint shared_route_estimates_approved_requires_rights
    check (
      moderation_status <> 'approved'
      or (rights_basis is not null and length(trim(rights_basis)) > 0)
    )
);

create index idx_shared_route_estimates_endpoints
  on public.shared_route_estimates (origin_facility_id, destination_facility_id);
create index idx_shared_route_estimates_moderation
  on public.shared_route_estimates (moderation_status);
create index idx_shared_route_estimates_owner
  on public.shared_route_estimates (created_by);

alter table public.shared_route_estimates enable row level security;

create policy "shared_route_estimates_select_own_or_approved"
  on public.shared_route_estimates
  for select using (
    created_by = auth.uid() or moderation_status = 'approved'
  );

-- INSERT: 新規登録は必ず draft から（shared_facilities の 0025 相当を最初から適用）。
create policy "shared_route_estimates_insert_own_draft"
  on public.shared_route_estimates
  for insert
  with check (
    auth.uid() is not null
    and created_by = auth.uid()
    and moderation_status = 'draft'
  );

-- UPDATE: 本人の draft/pending のみ対象、結果も draft/pending のみ
-- （approved/rejected は投稿者から読み取り専用, 0024 相当）。
create policy "shared_route_estimates_update_own"
  on public.shared_route_estimates
  for update
  using (
    created_by = auth.uid()
    and moderation_status in ('draft', 'pending')
  )
  with check (
    created_by = auth.uid()
    and moderation_status in ('draft', 'pending')
  );

-- DELETE: 本人の draft のみ。
create policy "shared_route_estimates_delete_own"
  on public.shared_route_estimates
  for delete
  using (created_by = auth.uid() and moderation_status = 'draft');

create trigger trg_shared_route_estimates_updated_at
  before update on public.shared_route_estimates
  for each row execute function public.set_updated_at();

-- モデレーション強制（shared_facilities の enforce_shared_facility_moderation
-- と同じ規則。テーブルごとにトリガ関数が必要なため専用関数を用意する）。
create or replace function public.enforce_shared_route_estimate_moderation()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' and auth.uid() is not null
     and new.moderation_status <> 'draft' then
    raise exception 'new shared route estimate must start as draft';
  end if;

  if tg_op = 'UPDATE' and auth.uid() is not null
     and old.moderation_status in ('approved', 'rejected') then
    raise exception 'approved/rejected route estimate is read-only for its creator';
  end if;

  if new.moderation_status in ('approved', 'rejected')
     and auth.uid() is not null then
    raise exception 'moderation transition requires service role';
  end if;

  if new.moderation_status = 'approved'
     and (new.rights_basis is null or length(trim(new.rights_basis)) = 0) then
    raise exception 'approved shared route estimate requires rights_basis';
  end if;

  return new;
end;
$$;

create trigger trg_shared_route_estimates_moderation
  before insert or update on public.shared_route_estimates
  for each row execute function public.enforce_shared_route_estimate_moderation();
