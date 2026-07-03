-- ============================================================================
-- 0007_image_design_fields.sql — 画像基調UIのデータ契約（H-05 / design-spec §12.1）
--
-- 追加:
--  - genbas: 明示参加状態 attendance_status、hero画像の storage/upload/alt。
--    （hero_image_local_path は端末専用のためサーバーには持たせない, H-04）
--  - memory_entries: is_favorite（思い出単位のお気に入り）
--  - memory_photos: cover は同一現場で最大1件（部分ユニークインデックス）
--  - oshi_groups / oshi_members: image_alt_text、oshi_groups.is_favorite
--    （image_local_path は端末専用のためサーバーには持たせない, H-04）
--  - oshi_anniversaries: ユーザー定義記念日（正規化）
--
-- 既存データ移行: is_canceled = true の現場は attendance_status = 'canceled' へ
-- 明示移行する。過去公演を勝手に attended へ推測しない（既定は planned）。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- genbas: 参加状態 + hero 画像（storage / upload state / alt text）
-- ----------------------------------------------------------------------------
alter table public.genbas
  add column if not exists attendance_status text not null default 'planned'
    check (attendance_status in ('planned', 'attended', 'not_attended', 'canceled'));
alter table public.genbas
  add column if not exists hero_image_storage_path text;
alter table public.genbas
  add column if not exists hero_image_upload_status text not null default 'local_only'
    check (hero_image_upload_status in ('local_only', 'queued', 'uploaded', 'failed'));
alter table public.genbas
  add column if not exists hero_image_alt_text text;

-- 既存の中止済み現場を参加状態 canceled へ移行（attended へは推測しない）。
update public.genbas set attendance_status = 'canceled'
  where is_canceled = true and attendance_status <> 'canceled';

-- ----------------------------------------------------------------------------
-- memory_entries: is_favorite
-- ----------------------------------------------------------------------------
alter table public.memory_entries
  add column if not exists is_favorite boolean not null default false;

-- ----------------------------------------------------------------------------
-- memory_photos: 表紙は同一現場で最大1件（design-spec §12.1）
-- ユニークインデックス作成前に、既存データの重複 cover を決定的に1件へ整理
-- する（複数 cover でも migration が失敗しない, R6独立レビュー#5）。保持規則は
-- sort_order → created_at → id の昇順で最小（ローカル Drift と同一, D-141）。
-- 既存写真は削除せず is_cover のみ修正する。
-- ----------------------------------------------------------------------------
update public.memory_photos p set is_cover = false
where p.is_cover = true and exists (
  select 1 from public.memory_photos o
  where o.genba_id = p.genba_id and o.is_cover = true
    and (o.sort_order, o.created_at, o.id) < (p.sort_order, p.created_at, p.id)
);

create unique index if not exists idx_memory_photos_cover_unique
  on public.memory_photos (genba_id) where is_cover;

-- ----------------------------------------------------------------------------
-- oshi_groups / oshi_members: 代替説明・グループお気に入り
-- ----------------------------------------------------------------------------
alter table public.oshi_groups
  add column if not exists image_alt_text text;
alter table public.oshi_groups
  add column if not exists is_favorite boolean not null default false;
alter table public.oshi_members
  add column if not exists image_alt_text text;

-- ----------------------------------------------------------------------------
-- oshi_anniversaries: ユーザー定義記念日（グループに属し、任意でメンバーへ紐づく）
-- ----------------------------------------------------------------------------
-- 列名はクライアントの JSON ペイロードキー（OshiAnniversary の snake_case）と
-- 一致させる。日付フィールドのキーは "date" のため列名も "date"（非予約語・要引用）。
create table if not exists public.oshi_anniversaries (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  group_id uuid not null references public.oshi_groups (id) on delete cascade,
  member_id uuid references public.oshi_members (id) on delete set null,
  label text not null,
  "date" date not null,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_oshi_anniversaries_owner
  on public.oshi_anniversaries (owner_id);
create index if not exists idx_oshi_anniversaries_group
  on public.oshi_anniversaries (group_id);
alter table public.oshi_anniversaries enable row level security;

create policy "oshi_anniversaries_all_own" on public.oshi_anniversaries
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_oshi_anniversaries_updated_at
  before update on public.oshi_anniversaries
  for each row execute function public.set_updated_at();

-- version 増加トリガー（H-02 の版CAS対象に加える）
create trigger trg_oshi_anniversaries_bump_version
  before insert or update on public.oshi_anniversaries
  for each row execute function public.bump_version();

-- 親グループ経由の所有権迂回防止（メンバーと同じ方針, C-01）
create or replace function public.enforce_oshi_anniversary_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
  member_owner uuid;
begin
  select owner_id into parent_owner from public.oshi_groups where id = new.group_id;
  if parent_owner is null then
    raise exception 'parent group not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent group owner';
  end if;
  -- member_id を指定する場合、そのメンバーも同一グループ・同一 owner であること。
  if new.member_id is not null then
    select owner_id into member_owner from public.oshi_members
      where id = new.member_id and group_id = new.group_id;
    if member_owner is null then
      raise exception 'member does not belong to the group';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_oshi_anniversaries_owner
  before insert or update on public.oshi_anniversaries
  for each row execute function public.enforce_oshi_anniversary_owner();

-- ----------------------------------------------------------------------------
-- apply_mutation の許可テーブルへ oshi_anniversaries を追加（列は
-- information_schema 参照で自動対応するため、新テーブルの許可のみ更新する）。
-- 本文は 0006 と同一。v_allowed に oshi_anniversaries を加えるためだけに再定義する。
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
    'visited_places', 'oshi_groups', 'oshi_members', 'oshi_anniversaries'
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
