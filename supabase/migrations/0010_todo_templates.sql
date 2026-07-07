-- ============================================================================
-- 0010_todo_templates.sql — Todo・持ち物のテンプレート（owner 単位）
--
-- 目的:
--   現場ごとに同じTodoや持ち物を毎回入力せずに済むよう、owner 単位で再利用
--   できるテンプレートを保存・同期する。1テンプレートは item_type で種別
--   （todo / belonging）が固定され、テンプレート内に両種別を混在させない。
--
--   標準プリセットはアプリ内の読み取り専用データとして管理し、ここには
--   保存しない（ユーザーが作成したテンプレートのみを保持する）。
--
-- 認可:
--   両テーブルとも RLS で owner のみ。todo_template_items は親テンプレートの
--   owner と一致することをトリガーで強制する（グループ経由の迂回防止と同型）。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- todo_templates（所有者のみ）
-- ----------------------------------------------------------------------------
create table public.todo_templates (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  item_type text not null check (item_type in ('todo', 'belonging')),
  -- 同期の版管理（0006 と同型。競合判定を端末時計に依存させない）。
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_todo_templates_owner on public.todo_templates (owner_id);
alter table public.todo_templates enable row level security;

create policy "todo_templates_all_own" on public.todo_templates
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_todo_templates_updated_at
  before update on public.todo_templates
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- todo_template_items（所有者のみ・親テンプレートに CASCADE）
--   priority は Todo テンプレートのみ（持ち物では null）。
-- ----------------------------------------------------------------------------
create table public.todo_template_items (
  id uuid primary key,
  template_id uuid not null
    references public.todo_templates (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  priority text check (priority in ('low', 'normal', 'high')),
  memo text,
  sort_order integer not null default 0,
  -- 同期の版管理（0006 と同型）。
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_todo_template_items_owner
  on public.todo_template_items (owner_id);
create index idx_todo_template_items_template
  on public.todo_template_items (template_id);
alter table public.todo_template_items enable row level security;

create policy "todo_template_items_all_own" on public.todo_template_items
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_todo_template_items_updated_at
  before update on public.todo_template_items
  for each row execute function public.set_updated_at();

-- 親テンプレート経由の所有権迂回防止（enforce_oshi_member_owner と同型）。
create or replace function public.enforce_todo_template_item_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
begin
  select owner_id into parent_owner
    from public.todo_templates where id = new.template_id;
  if parent_owner is null then
    raise exception 'parent template not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent template owner';
  end if;
  return new;
end;
$$;

create trigger trg_todo_template_items_owner
  before insert or update on public.todo_template_items
  for each row execute function public.enforce_todo_template_item_owner();

-- ----------------------------------------------------------------------------
-- 同期版トリガー（0006 の bump_version を新テーブルへ適用）
-- ----------------------------------------------------------------------------
create trigger trg_todo_templates_bump_version
  before insert or update on public.todo_templates
  for each row execute function public.bump_version();
create trigger trg_todo_template_items_bump_version
  before insert or update on public.todo_template_items
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- apply_mutation の許可テーブルへ新テーブルを追加する（0006 を create or
-- replace で拡張）。RPC 本体のロジックは変更せず、v_allowed のみ2件追加する。
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
    'visited_places', 'oshi_groups', 'oshi_members',
    'todo_templates', 'todo_template_items'
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
