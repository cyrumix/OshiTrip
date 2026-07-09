-- ============================================================================
-- 0026_memo_kinds_and_templates.sql
--   メモ種類（§7.7 改訂）: 自由メモ/チェックリスト/BINGO/投票。
--
--   - genba_memos に kind（種類）と content（種類別の構造化データ, jsonb）を追加。
--     既存メモは kind='free'（自由メモ）へ移行し消さない。apply_mutation の列許可は
--     information_schema から動的取得するため、新列は自動的に対象になる（0011）。
--   - memo_templates（owner 単位・単一行）を新規追加。Todo テンプレートと同思想で
--     保存・同期する（雛形の構造化データは content(jsonb) に持つ）。
--   - apply_mutation の v_allowed に memo_templates を追加（前方専用の再定義。
--     既存許可テーブルは落とさない）。
--
--   0003/0018 を書き換えず前方専用で追加する。
-- ============================================================================

-- ---- genba_memos: kind / content ------------------------------------------
alter table public.genba_memos
  add column if not exists kind text not null default 'free';
alter table public.genba_memos
  add column if not exists content jsonb;

update public.genba_memos
   set kind = 'free'
 where kind is null or trim(kind) = '';

alter table public.genba_memos
  drop constraint if exists genba_memos_kind_check;
alter table public.genba_memos
  add constraint genba_memos_kind_check
  check (kind in ('free', 'checklist', 'bingo', 'vote'));

-- ---- memo_templates（所有者のみ・単一行） ---------------------------------
create table public.memo_templates (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  kind text not null default 'free'
    check (kind in ('free', 'checklist', 'bingo', 'vote')),
  category text not null default 'other'
    check (category in
      ('free', 'goods', 'meetup', 'around', 'notice', 'other')),
  title text not null default '',
  body text not null default '',
  content jsonb,
  -- 同期の版管理（0006 と同型。競合判定を端末時計に依存させない）。
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_memo_templates_owner on public.memo_templates (owner_id);
alter table public.memo_templates enable row level security;

create policy "memo_templates_all_own" on public.memo_templates
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_memo_templates_updated_at
  before update on public.memo_templates
  for each row execute function public.set_updated_at();

create trigger trg_memo_templates_bump_version
  before insert or update on public.memo_templates
  for each row execute function public.bump_version();

-- ----------------------------------------------------------------------------
-- apply_mutation: v_allowed に memo_templates を追加（前方専用の再定義）。
-- v_allowed 以外は 0012 の定義と同一（既存の全許可テーブルを落とさない）。
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
    'todo_templates', 'todo_template_items', 'memo_templates',
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
