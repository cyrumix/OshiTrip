-- ============================================================================
-- 0012_itinerary.sql — 現場詳細「計画」タブ・推し活遠征旅程の基盤（Phase 1）
--
-- 目的:
--   現場（genba）を中心に、スポット・訪問予定・移動区間を owner 単位で安全に
--   永続化・同期する。Google連携（Places/Routes）は後続Phaseで、本Phaseは
--   手動旅程が成立する境界（テーブル・RLS・親子owner整合・版管理・冪等RPC
--   許可リスト）を完成させる（itinerary-plan-spec.md §12）。
--
-- 認可（ADR-0008 / C-01）:
--   全テーブル RLS で owner のみ。子テーブルは親の owner と一致することを
--   トリガーで強制する（親ID経由の owner 迂回を防ぐ）。
--     - itinerary_plans      … 親は genbas（enforce_genba_child_owner を再利用）
--     - itinerary_spots      … 親は itinerary_plans
--     - itinerary_spot_links … 親は itinerary_spots
--     - itinerary_entries    … 親は itinerary_plans。加えて kind別の参照先
--                              （spot/transport/lodging）が同一owner・同一
--                              計画/現場に属することも強制する（参照整合性）。
--     - itinerary_legs       … 親は itinerary_plans。加えて origin/destination
--                              が同一owner・同一計画の項目であることも強制する。
--
-- 削除の cascade（§12 末尾）:
--   plan 削除 → spot / entry / leg / spot_link まで安全に cascade。
--   spot 削除 → その spot_link と、その spot を参照する entry、さらにその entry
--   を始点/終点とする leg も cascade。
--   一方、entry.transport_id / entry.lodging_id は既存 transports / lodgings を
--   「参照するだけ」で FK を張らない。交通・宿泊本体が削除されても旅程項目は
--   勝手に消さず、アプリ側で「参照切れ」として検出する（§5.3）。
--
-- 注: 本ファイルは Supabase(Postgres) 環境で適用・検証する。ローカル Windows
--     環境では未実行（pgTAP は supabase/tests/0008 に用意）。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 親が itinerary_plans である子（spots / entries / legs）の owner 整合を強制する
-- ----------------------------------------------------------------------------
create or replace function public.enforce_itinerary_plan_child_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
begin
  select owner_id into parent_owner
    from public.itinerary_plans where id = new.plan_id;
  if parent_owner is null then
    raise exception 'parent itinerary plan not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent plan owner';
  end if;
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 親が itinerary_spots である子（spot_links）の owner 整合を強制する
-- ----------------------------------------------------------------------------
create or replace function public.enforce_itinerary_spot_child_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
begin
  select owner_id into parent_owner
    from public.itinerary_spots where id = new.spot_id;
  if parent_owner is null then
    raise exception 'parent itinerary spot not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent spot owner';
  end if;
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- itinerary_entries: 親plan の owner 整合に加え、kind に対応する参照先が
-- 同一 owner・同一計画/現場に属することを強制する（存在しないID・別計画・
-- 別owner・別現場の spot/transport/lodging を弾く, C-01 / 参照整合性）。
--   spot      → itinerary_spots（同一 owner・同一 plan）
--   transport → transports（同一 owner・plan の genba に登録済み）
--   lodging   → lodgings（同一 owner・plan の genba に登録済み）
-- ----------------------------------------------------------------------------
create or replace function public.enforce_itinerary_entry_owner_and_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  plan_owner uuid;
  plan_genba uuid;
begin
  select owner_id, genba_id into plan_owner, plan_genba
    from public.itinerary_plans where id = new.plan_id;
  if plan_owner is null then
    raise exception 'parent itinerary plan not found';
  end if;
  if new.owner_id is distinct from plan_owner then
    raise exception 'owner_id must match parent plan owner';
  end if;

  if new.kind = 'spot' then
    if not exists (
      select 1 from public.itinerary_spots
      where id = new.spot_id
        and owner_id = new.owner_id
        and plan_id = new.plan_id
    ) then
      raise exception 'spot_id must reference a spot in the same plan and owner';
    end if;
  elsif new.kind = 'transport' then
    if not exists (
      select 1 from public.transports
      where id = new.transport_id
        and owner_id = new.owner_id
        and genba_id = plan_genba
    ) then
      raise exception
        'transport_id must reference a transport of the same genba and owner';
    end if;
  elsif new.kind = 'lodging' then
    if not exists (
      select 1 from public.lodgings
      where id = new.lodging_id
        and owner_id = new.owner_id
        and genba_id = plan_genba
    ) then
      raise exception
        'lodging_id must reference a lodging of the same genba and owner';
    end if;
  end if;
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- itinerary_legs: 親plan の owner 整合に加え、origin/destination が同一 owner・
-- 同一計画の項目であることを強制する。
-- ----------------------------------------------------------------------------
create or replace function public.enforce_itinerary_leg_owner_and_refs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  plan_owner uuid;
begin
  select owner_id into plan_owner
    from public.itinerary_plans where id = new.plan_id;
  if plan_owner is null then
    raise exception 'parent itinerary plan not found';
  end if;
  if new.owner_id is distinct from plan_owner then
    raise exception 'owner_id must match parent plan owner';
  end if;
  if not exists (
    select 1 from public.itinerary_entries
    where id = new.origin_entry_id
      and owner_id = new.owner_id
      and plan_id = new.plan_id
  ) then
    raise exception
      'origin_entry_id must reference an entry in the same plan and owner';
  end if;
  if not exists (
    select 1 from public.itinerary_entries
    where id = new.destination_entry_id
      and owner_id = new.owner_id
      and plan_id = new.plan_id
  ) then
    raise exception
      'destination_entry_id must reference an entry in the same plan and owner';
  end if;
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- itinerary_plans（現場に属する計画。親は genbas）
-- ----------------------------------------------------------------------------
create table public.itinerary_plans (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  memo text,
  start_date date,
  end_date date,
  time_zone_id text not null,
  cover_image_storage_path text,
  cover_image_upload_status text not null default 'local_only'
    check (cover_image_upload_status
      in ('local_only', 'queued', 'uploaded', 'failed')),
  sort_order integer not null default 0,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_itinerary_plans_owner on public.itinerary_plans (owner_id);
create index idx_itinerary_plans_genba on public.itinerary_plans (genba_id);
create index idx_itinerary_plans_owner_sort
  on public.itinerary_plans (owner_id, sort_order);
alter table public.itinerary_plans enable row level security;

create policy "itinerary_plans_all_own" on public.itinerary_plans
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_itinerary_plans_updated_at
  before update on public.itinerary_plans
  for each row execute function public.set_updated_at();
create trigger trg_itinerary_plans_owner
  before insert or update on public.itinerary_plans
  for each row execute function public.enforce_genba_child_owner();
create trigger trg_itinerary_plans_bump_version
  before insert or update on public.itinerary_plans
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- itinerary_spots（計画のスポット。親は itinerary_plans）
-- ----------------------------------------------------------------------------
create table public.itinerary_spots (
  id uuid primary key,
  plan_id uuid not null
    references public.itinerary_plans (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  source text not null default 'manual'
    check (source in ('manual', 'google_places')),
  google_place_id text,
  name text not null,
  category text not null check (category in (
    'venue', 'sightseeing', 'restaurant', 'cafe', 'lodging', 'station',
    'airport', 'shopping', 'shrine_temple', 'museum', 'park', 'photo_spot',
    'convenience', 'other'
  )),
  address text,
  -- 永続する名称・住所の出典・権利根拠（§12.2, D-178/D-179）。Google応答由来値を
  -- 恒久保存・共有再利用の権利根拠にはできない（google_places はここに含めない）。
  data_origin text not null default 'user_provided'
    check (data_origin in (
      'user_provided', 'facility_provided', 'open_data', 'licensed'
    )),
  rights_basis text,
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  -- google_place_id 以外の以下の列は「将来の契約変更に備えた予約領域」であり、
  -- MVPでは Google 応答の保存先に使わない（§12.2, D-178）。Google コンテンツを
  -- ユーザー横断の恒久キャッシュとして投入しないこと。
  phone_number text,
  website_url text,
  opening_hours_text text,
  google_maps_url text,
  google_fetched_at timestamptz,
  google_photo_name text,
  google_photo_attribution text,
  user_image_storage_path text,
  user_image_upload_status text not null default 'local_only'
    check (user_image_upload_status
      in ('local_only', 'queued', 'uploaded', 'failed')),
  user_image_alt_text text,
  memo text,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- user_provided 以外の出典は権利根拠（非空）を必須にする（§12.2, D-179）。
  constraint itinerary_spots_rights_basis check (
    data_origin = 'user_provided'
    or (rights_basis is not null and btrim(rights_basis) <> '')
  )
);

create index idx_itinerary_spots_owner on public.itinerary_spots (owner_id);
create index idx_itinerary_spots_plan on public.itinerary_spots (plan_id);
alter table public.itinerary_spots enable row level security;

create policy "itinerary_spots_all_own" on public.itinerary_spots
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_itinerary_spots_updated_at
  before update on public.itinerary_spots
  for each row execute function public.set_updated_at();
create trigger trg_itinerary_spots_owner
  before insert or update on public.itinerary_spots
  for each row execute function public.enforce_itinerary_plan_child_owner();
create trigger trg_itinerary_spots_bump_version
  before insert or update on public.itinerary_spots
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- itinerary_spot_links（スポットの種別つきURL。親は itinerary_spots）
-- ----------------------------------------------------------------------------
create table public.itinerary_spot_links (
  id uuid primary key,
  spot_id uuid not null
    references public.itinerary_spots (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in (
    'reference', 'reservation', 'google_maps', 'social', 'ticket',
    'official', 'other'
  )),
  url text not null,
  label text,
  sort_order integer not null default 0,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_itinerary_spot_links_owner
  on public.itinerary_spot_links (owner_id);
create index idx_itinerary_spot_links_spot
  on public.itinerary_spot_links (spot_id);
alter table public.itinerary_spot_links enable row level security;

create policy "itinerary_spot_links_all_own" on public.itinerary_spot_links
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_itinerary_spot_links_updated_at
  before update on public.itinerary_spot_links
  for each row execute function public.set_updated_at();
create trigger trg_itinerary_spot_links_owner
  before insert or update on public.itinerary_spot_links
  for each row execute function public.enforce_itinerary_spot_child_owner();
create trigger trg_itinerary_spot_links_bump_version
  before insert or update on public.itinerary_spot_links
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- itinerary_entries（タイムライン項目。親は itinerary_plans）
--   spot_id は内部スポットを FK 参照（cascade）。transport_id / lodging_id は
--   既存 transports / lodgings を「参照するだけ」で FK を張らない（削除時は
--   参照切れとして検出する。§5.3）。
-- ----------------------------------------------------------------------------
create table public.itinerary_entries (
  id uuid primary key,
  plan_id uuid not null
    references public.itinerary_plans (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  kind text not null
    check (kind in ('spot', 'transport', 'lodging', 'note')),
  spot_id uuid references public.itinerary_spots (id) on delete cascade,
  transport_id uuid,
  lodging_id uuid,
  title_override text,
  start_at timestamptz,
  end_at timestamptz,
  local_date date,
  time_zone_id text,
  buffer_before_minutes integer not null default 0
    check (buffer_before_minutes between 0 and 1440),
  buffer_after_minutes integer not null default 0
    check (buffer_after_minutes between 0 and 1440),
  memo text,
  sort_order integer not null default 0,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- kind に対応する参照だけを許可する（アプリ側 domain 検証と同じ不変条件）。
  constraint itinerary_entries_reference_by_kind check (
    (kind = 'spot'
      and spot_id is not null
      and transport_id is null and lodging_id is null)
    or (kind = 'transport'
      and transport_id is not null
      and spot_id is null and lodging_id is null)
    or (kind = 'lodging'
      and lodging_id is not null
      and spot_id is null and transport_id is null)
    or (kind = 'note'
      and spot_id is null and transport_id is null and lodging_id is null)
  ),
  -- 終了は開始以後（日跨ぎ可）。
  constraint itinerary_entries_time_order check (
    start_at is null or end_at is null or end_at >= start_at
  )
);

create index idx_itinerary_entries_owner on public.itinerary_entries (owner_id);
create index idx_itinerary_entries_plan on public.itinerary_entries (plan_id);
create index idx_itinerary_entries_spot on public.itinerary_entries (spot_id);
create index idx_itinerary_entries_transport
  on public.itinerary_entries (transport_id);
create index idx_itinerary_entries_lodging
  on public.itinerary_entries (lodging_id);
create index idx_itinerary_entries_plan_date_order
  on public.itinerary_entries (plan_id, local_date, sort_order);
alter table public.itinerary_entries enable row level security;

create policy "itinerary_entries_all_own" on public.itinerary_entries
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_itinerary_entries_updated_at
  before update on public.itinerary_entries
  for each row execute function public.set_updated_at();
create trigger trg_itinerary_entries_owner
  before insert or update on public.itinerary_entries
  for each row execute function public.enforce_itinerary_entry_owner_and_refs();
create trigger trg_itinerary_entries_bump_version
  before insert or update on public.itinerary_entries
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- itinerary_legs（スポット間の移動区間。親は itinerary_plans）
--   origin/destination は itinerary_entries を FK 参照（cascade）。
-- ----------------------------------------------------------------------------
create table public.itinerary_legs (
  id uuid primary key,
  plan_id uuid not null
    references public.itinerary_plans (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  origin_entry_id uuid not null
    references public.itinerary_entries (id) on delete cascade,
  destination_entry_id uuid not null
    references public.itinerary_entries (id) on delete cascade,
  source text not null default 'manual'
    check (source in ('manual', 'google_routes')),
  travel_mode text not null default 'other' check (travel_mode in (
    'walking', 'transit', 'driving', 'bicycling', 'taxi', 'flight', 'other'
  )),
  departure_at timestamptz,
  arrival_at timestamptz,
  duration_minutes integer check (duration_minutes between 0 and 1440),
  distance_meters integer check (distance_meters >= 0),
  fare_amount_minor integer check (fare_amount_minor >= 0),
  fare_currency text,
  -- 永続する概算経路値の出典・権利根拠・代表時刻帯・最終確認（§12.5, D-180/D-181）。
  -- Google Routes のライブ応答をここに恒久保存（共有再利用）しない。
  value_origin text not null default 'user_provided'
    check (value_origin in (
      'user_provided', 'facility_provided', 'open_data', 'licensed'
    )),
  rights_basis text,
  representative_time_bucket text,
  last_verified_at timestamptz,
  route_summary text,
  transit_steps_json text,
  encoded_polyline text,
  google_maps_url text,
  fetched_at timestamptz,
  cache_key text,
  is_stale boolean not null default false,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- 出発と到着に同じ旅程項目は指定できない。
  constraint itinerary_legs_distinct_endpoints
    check (origin_entry_id <> destination_entry_id),
  -- 運賃は金額と通貨を組で扱う（片方だけを許可しない）。
  constraint itinerary_legs_fare_pair check (
    (fare_amount_minor is null) = (fare_currency is null)
  ),
  -- 到着は出発以後（日跨ぎ可）。
  constraint itinerary_legs_time_order check (
    departure_at is null or arrival_at is null or arrival_at >= departure_at
  ),
  -- user_provided 以外の出典は権利根拠（非空）を必須にする（§12.5, D-179）。
  constraint itinerary_legs_rights_basis check (
    value_origin = 'user_provided'
    or (rights_basis is not null and btrim(rights_basis) <> '')
  )
);

create index idx_itinerary_legs_owner on public.itinerary_legs (owner_id);
create index idx_itinerary_legs_plan on public.itinerary_legs (plan_id);
create index idx_itinerary_legs_origin
  on public.itinerary_legs (origin_entry_id);
create index idx_itinerary_legs_destination
  on public.itinerary_legs (destination_entry_id);
alter table public.itinerary_legs enable row level security;

create policy "itinerary_legs_all_own" on public.itinerary_legs
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_itinerary_legs_updated_at
  before update on public.itinerary_legs
  for each row execute function public.set_updated_at();
create trigger trg_itinerary_legs_owner
  before insert or update on public.itinerary_legs
  for each row execute function public.enforce_itinerary_leg_owner_and_refs();
create trigger trg_itinerary_legs_bump_version
  before insert or update on public.itinerary_legs
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- apply_mutation の許可テーブルへ旅程5テーブルを追加する（0011 を create or
-- replace で拡張）。RPC 本体のロジックは 0006/0007/0010/0011 と完全に同一で、
-- v_allowed のみ5件追加する（既存の全許可テーブルを落とさない）。
-- ----------------------------------------------------------------------------
create or replace function public.apply_mutation(
  p_mutation_id uuid,
  p_entity_table text,
  p_entity_id uuid,
  p_op_type text,
  p_payload jsonb,
  p_base_version bigint
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_allowed text[] := array[
    'genbas', 'tickets', 'transports', 'lodgings', 'todos', 'genba_memos',
    'memory_entries', 'memory_photos', 'setlist_items', 'goods_items',
    'visited_places', 'oshi_groups', 'oshi_members', 'oshi_anniversaries',
    'todo_templates', 'todo_template_items',
    'itinerary_plans', 'itinerary_spots', 'itinerary_spot_links',
    'itinerary_entries', 'itinerary_legs'
  ];
  v_current bigint;
  v_uid uuid := auth.uid();
  v_data jsonb;
  v_cols text;
  v_setclause text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if not (p_entity_table = any (v_allowed)) then
    raise exception 'invalid entity_table: %', p_entity_table using errcode = '22023';
  end if;
  if p_op_type not in ('upsert', 'delete') then
    raise exception 'invalid op_type: %', p_op_type using errcode = '22023';
  end if;
  if p_op_type = 'upsert'
     and (p_payload ->> 'id') is distinct from p_entity_id::text then
    raise exception 'payload id mismatch' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtext('mutation'), hashtext(p_mutation_id::text));
  perform pg_advisory_xact_lock(hashtext(p_entity_table), hashtext(p_entity_id::text));

  if exists (select 1 from public.outbox_operations where id = p_mutation_id) then
    execute format('select version from public.%I where id = $1', p_entity_table)
      into v_current using p_entity_id;
    return jsonb_build_object('status', 'applied', 'version', v_current);
  end if;

  execute format('select version from public.%I where id = $1', p_entity_table)
    into v_current using p_entity_id;

  if p_op_type = 'upsert' then
    select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
      into v_data
      from jsonb_each(p_payload) e
      where e.key in (
        select c.column_name
        from information_schema.columns c
        where c.table_schema = 'public' and c.table_name = p_entity_table
      )
      and e.key not in ('id', 'owner_id', 'version');

    if v_current is not null then
      if p_base_version is null or v_current <> p_base_version then
        return jsonb_build_object('status', 'conflict', 'version', v_current);
      end if;
      select string_agg(format('%I = src.%I', k, k), ', ') into v_setclause
        from jsonb_object_keys(v_data) k;
      if v_setclause is not null then
        execute format(
          'update public.%1$I as t set %2$s '
          'from jsonb_populate_record(null::public.%1$I, $1) as src '
          'where t.id = $2',
          p_entity_table, v_setclause
        ) using v_data, p_entity_id;
      else
        execute format(
          'update public.%I set owner_id = owner_id where id = $1',
          p_entity_table
        ) using p_entity_id;
      end if;
      execute format('select version from public.%I where id = $1', p_entity_table)
        into v_current using p_entity_id;
    else
      v_data := v_data
        || jsonb_build_object('id', p_entity_id::text)
        || jsonb_build_object('owner_id', v_uid::text);
      select string_agg(quote_ident(k), ', ') into v_cols
        from jsonb_object_keys(v_data) k;
      execute format(
        'insert into public.%1$I (%2$s) '
        'select %2$s from jsonb_populate_record(null::public.%1$I, $1) '
        'on conflict (id) do nothing returning version',
        p_entity_table, v_cols
      ) into v_current using v_data;
      if not found then
        return jsonb_build_object('status', 'conflict', 'version', null);
      end if;
    end if;
  else
    if v_current is null then
      null;
    elsif p_base_version is null or v_current <> p_base_version then
      return jsonb_build_object('status', 'conflict', 'version', v_current);
    else
      execute format('delete from public.%I where id = $1', p_entity_table)
        using p_entity_id;
    end if;
    v_current := null;
  end if;

  insert into public.outbox_operations (id, owner_id, entity_table, entity_id, op_type)
  values (p_mutation_id, v_uid, p_entity_table, p_entity_id, p_op_type)
  on conflict (id) do nothing;

  return jsonb_build_object('status', 'applied', 'version', v_current);
end;
$$;

grant execute on function public.apply_mutation(uuid, text, uuid, text, jsonb, bigint) to authenticated;
