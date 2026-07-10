-- ============================================================================
-- 0028_genba_shares.sql — 現場共有の**データ基盤**（Phase 5 前提基盤・保守的スライス）
--
--   ADR-0008 / itinerary-plan-spec §11 / requirements §7.8。owner/editor/viewer の
--   共有と項目単位の共有可否（チケット画像・予約番号・住所・感想）を表す
--   `genba_shares` 表を追加する。
--
--   **本マイグレーションの範囲は「共有データの表とその owner 管理 RLS」のみ**。
--   既存テーブル（genbas/tickets/... itinerary_*）の RLS は**一切変更しない**
--   （owner 隔離 C-01 を保つ）。grantee による共有データの実 read/write
--   （ロール別 RLS・項目マスキング view・Storage 共有・editor write-through）は、
--   pgTAP を実行検証できる環境（Docker/CI）で行う後続増分とする
--   （decisions.md D-226）。
--
--   モデル:
--   - owner（＝共有元）は現場の所有者（`genbas.owner_id`）。share 行にはしない。
--   - grantee は editor / viewer のいずれか。
--   - 項目 grant は安全側（既定 false）。
--   - owner だけが自分の現場の共有行を作成・変更・削除できる（RLS＋子owner
--     トリガの多層防御）。grantee は「自分に共有された行」を SELECT できるだけで、
--     書き込みは一切できない。genba 本体データはこの表からは出さない。
--
--   前方専用。過去 migration は変更しない。
-- ============================================================================

create table public.genba_shares (
  id uuid primary key,
  -- 共有元＝現場の所有者。子owner トリガで genbas.owner_id との一致を強制する。
  owner_id uuid not null references auth.users (id) on delete cascade,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  -- 共有先ユーザー。
  grantee_id uuid not null references auth.users (id) on delete cascade,
  -- owner は暗黙（genbas.owner_id）。share 行の role は editor/viewer のみ。
  role text not null check (role in ('editor', 'viewer')),

  -- 項目単位の共有可否（安全側＝既定 false, §7.8）。
  grant_ticket_image boolean not null default false,
  grant_reservation boolean not null default false,
  grant_address boolean not null default false,
  grant_impression boolean not null default false,

  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- 現場×共有先で1件。自分自身へは共有しない。
  unique (genba_id, grantee_id),
  constraint genba_shares_not_self check (grantee_id <> owner_id)
);

create index idx_genba_shares_genba on public.genba_shares (genba_id);
create index idx_genba_shares_grantee on public.genba_shares (grantee_id);
create index idx_genba_shares_owner on public.genba_shares (owner_id);

alter table public.genba_shares enable row level security;

-- owner（現場の所有者＝共有元）は自分の共有行を CRUD できる。
create policy "genba_shares_all_own" on public.genba_shares
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- grantee は「自分に共有された行」を SELECT できる（自分が共有されている事実の
-- 確認用）。書き込みポリシーは作らない = grantee は insert/update/delete 不可。
-- 露出するのは共有行そのものだけで、現場本体データはこの表から出ない。
create policy "genba_shares_select_grantee" on public.genba_shares
  for select using (grantee_id = auth.uid());

create trigger trg_genba_shares_updated_at
  before update on public.genba_shares
  for each row execute function public.set_updated_at();

create trigger trg_genba_shares_bump_version
  before insert or update on public.genba_shares
  for each row execute function public.bump_version();

-- 子owner トリガ（既存関数を再利用）: new.owner_id が親現場の owner_id と一致する
-- ことを SECURITY DEFINER で強制する。=「他人の現場を共有しようとする」試み
-- （owner_id は apply_mutation で caller に矯正されるため、非owner だと親の
-- owner_id と食い違い拒否される）を弾く。owner_id 偽装も同様に拒否。
create trigger trg_genba_shares_owner
  before insert or update on public.genba_shares
  for each row execute function public.enforce_genba_child_owner();

-- ---------------------------------------------------------------------------
-- apply_mutation の許可テーブルに genba_shares を追加（前方専用の再定義）。
-- 本体ロジック（認可＝RLS委譲・版CAS・冪等ledger・owner矯正・列default制御）は
-- 0026 と完全に同一。変更点は v_allowed に 'genba_shares' を加える1点のみ。
-- ---------------------------------------------------------------------------
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
    'todo_templates', 'todo_template_items', 'memo_templates',
    'itinerary_plans', 'itinerary_spots', 'itinerary_spot_links',
    'itinerary_entries', 'itinerary_legs',
    'genba_shares'
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
