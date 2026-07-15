-- ============================================================================
-- 0031_shared_genba_access.sql
--   共有現場のロール別アクセス（追加要件 §2/§3/§4/§5/§7・decisions D-238）。
--   D-226 で次増分としていた「grantee による共有データの read/write」を実装する。
--
--   モデル（完全身内想定・項目単位マスキングなし＝共有現場は全項目見える）:
--   - **READ**: owner または genba_shares の grantee（viewer/editor どちらでも）は、
--     その現場本体と全子データを読める。既存の owner 限定 SELECT ポリシーに
--     **加算的**な member SELECT ポリシーを足す（PostgreSQL は SELECT の USING を
--     OR 合成するため、書き込み権限は増えない）。
--   - **WRITE（editor）**: 直接の INSERT/UPDATE/DELETE ポリシーは owner 限定のまま
--     （editor の owner_id は現場 owner ≠ auth.uid のため直接書き込みは RLS で
--     弾かれる）。editor の書き込みは **SECURITY DEFINER の `apply_shared_mutation`
--     RPC 経由のみ**許可し、owner_id を現場 owner へ正規化し、行が対象現場に属する
--     ことを検証する（他現場への書き込みを防ぐ）。これにより owner 隔離（C-01）の
--     直接書き込み経路は無改変のまま、editor 共同編集を監査可能な単一経路に閉じる。
--   - **VIEWER**: 書き込みポリシーも apply_shared_mutation の editor 判定も通らない
--     ため read only。
--   - **OWNER 限定**: 現場そのものの UPDATE/DELETE・共有メンバー管理・招待発行、
--     **計画本体（itinerary_plans）の作成/更新/削除**は従来どおり owner のみ
--     （`genbas_all_own`・`genba_shares` の owner 管理・`create/revoke_genba_invite`）。
--     editor は現場削除・オーナー変更・メンバー管理・計画本体作成 不可
--     （apply_shared_mutation の allowlist に genbas/genba_shares/itinerary_plans を
--     入れない, D-247）。計画配下の子データ（spots/entries/legs）は編集できる。
--
--   前方専用。既存の owner 限定ポリシー・apply_mutation（owned 経路）は変更しない。
--   本環境（Docker/Supabase なし）では未デプロイ・未実行（pgTAP 0017 静的）。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- メンバー判定ヘルパ（SECURITY DEFINER で genba_shares を RLS 非依存に参照）
-- ---------------------------------------------------------------------------
create or replace function public.is_genba_member(p_genba uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.genba_shares s
    where s.genba_id = p_genba and s.grantee_id = auth.uid()
  );
$$;
revoke execute on function public.is_genba_member(uuid) from public;
grant execute on function public.is_genba_member(uuid) to authenticated;

-- owner または editor か（書き込み可否判定）。
create or replace function public.is_genba_editor(p_genba uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    exists (select 1 from public.genbas g
              where g.id = p_genba and g.owner_id = auth.uid())
    or exists (select 1 from public.genba_shares s
              where s.genba_id = p_genba and s.grantee_id = auth.uid()
                and s.role = 'editor');
$$;
revoke execute on function public.is_genba_editor(uuid) from public;
grant execute on function public.is_genba_editor(uuid) to authenticated;

-- plan_id から genba を辿ってメンバー判定（itinerary_spots/entries/legs 用）。
create or replace function public.is_plan_member(p_plan uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.itinerary_plans p
    where p.id = p_plan and public.is_genba_member(p.genba_id)
  );
$$;
revoke execute on function public.is_plan_member(uuid) from public;
grant execute on function public.is_plan_member(uuid) to authenticated;

-- spot_id から spot→plan→genba を辿ってメンバー判定（itinerary_spot_links 用）。
-- itinerary_spot_links は plan_id を**持たない**（spot_id のみ）ため、必ず
-- itinerary_spots を経由して所属現場を求める。
create or replace function public.is_spot_member(p_spot uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.itinerary_spots s
      join public.itinerary_plans p on p.id = s.plan_id
    where s.id = p_spot and public.is_genba_member(p.genba_id)
  );
$$;
revoke execute on function public.is_spot_member(uuid) from public;
grant execute on function public.is_spot_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 加算的な member SELECT ポリシー（owner 限定ポリシーはそのまま残す）
-- ---------------------------------------------------------------------------
create policy "genbas_select_member" on public.genbas
  for select using (public.is_genba_member(id));

create policy "tickets_select_member" on public.tickets
  for select using (public.is_genba_member(genba_id));
create policy "transports_select_member" on public.transports
  for select using (public.is_genba_member(genba_id));
create policy "lodgings_select_member" on public.lodgings
  for select using (public.is_genba_member(genba_id));
create policy "todos_select_member" on public.todos
  for select using (public.is_genba_member(genba_id));
create policy "genba_memos_select_member" on public.genba_memos
  for select using (public.is_genba_member(genba_id));
create policy "memory_entries_select_member" on public.memory_entries
  for select using (public.is_genba_member(genba_id));
create policy "memory_photos_select_member" on public.memory_photos
  for select using (public.is_genba_member(genba_id));
create policy "setlist_items_select_member" on public.setlist_items
  for select using (public.is_genba_member(genba_id));
create policy "goods_items_select_member" on public.goods_items
  for select using (public.is_genba_member(genba_id));
create policy "visited_places_select_member" on public.visited_places
  for select using (public.is_genba_member(genba_id));
create policy "itinerary_plans_select_member" on public.itinerary_plans
  for select using (public.is_genba_member(genba_id));

create policy "itinerary_spots_select_member" on public.itinerary_spots
  for select using (public.is_plan_member(plan_id));
-- itinerary_spot_links は spot_id 経由（plan_id を持たない）。
create policy "itinerary_spot_links_select_member" on public.itinerary_spot_links
  for select using (public.is_spot_member(spot_id));
create policy "itinerary_entries_select_member" on public.itinerary_entries
  for select using (public.is_plan_member(plan_id));
create policy "itinerary_legs_select_member" on public.itinerary_legs
  for select using (public.is_plan_member(plan_id));

-- 共有メンバー一覧をメンバー同士が閲覧できる（メンバー画面 §9）。
-- owner は既存 `genba_shares_all_own` で全共有を見える。ここでメンバーにも
-- 「同一現場の共有行」の SELECT を足す（書き込みは owner 限定のまま）。
create policy "genba_shares_select_member" on public.genba_shares
  for select using (public.is_genba_member(genba_id));

-- ---------------------------------------------------------------------------
-- editor 共同編集の書き込み経路（SECURITY DEFINER・監査可能な単一経路）
-- ---------------------------------------------------------------------------
-- 共有現場で editor（または owner）が子データを upsert/delete する。owner_id を
-- 現場 owner へ正規化し、対象行が p_genba に属することを検証する。genbas 本体・
-- genba_shares・genba_invites は allowlist に含めない（現場削除・オーナー変更・
-- メンバー管理は owner 専用の従来経路のまま）。
create or replace function public.apply_shared_mutation(
  p_mutation_id uuid,
  p_entity_table text,
  p_entity_id uuid,
  p_op_type text,
  p_payload jsonb,
  p_base_version bigint,
  p_genba uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  -- genba_id を直接持つ共同編集対象。
  -- 注: itinerary_plans（計画本体）は **含めない**。editor には計画本体の
  --     作成/更新/削除を開放しない仕様（D-247）。計画配下の子データ
  --     （itinerary_spots/entries/legs）は v_plan_tables 経由で編集できる。
  v_genba_tables text[] := array[
    'tickets', 'transports', 'lodgings', 'todos', 'genba_memos',
    'memory_entries', 'memory_photos', 'setlist_items', 'goods_items',
    'visited_places'
  ];
  -- plan_id 経由で genba に属する共同編集対象（既存 plan 配下の子データのみ）。
  v_plan_tables text[] := array[
    'itinerary_spots', 'itinerary_entries', 'itinerary_legs'
  ];
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_current bigint;
  v_data jsonb;
  v_cols text;
  v_setclause text;
  v_is_genba_tbl boolean;
  v_is_plan_tbl boolean;
  -- itinerary_spot_links は plan_id を持たず spot_id → spot → plan → genba で辿る。
  v_is_spotlink boolean;
  v_row_genba uuid;
  -- memory_photos は「1現場1カバー」の部分ユニーク制約
  -- （idx_memory_photos_cover_unique）がある。is_cover=true を保存する前に、
  -- 同一現場の他カバーを false にして unique 衝突を避ける（D-247）。
  v_clear_cover boolean := false;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select owner_id into v_owner from public.genbas where id = p_genba;
  if v_owner is null then
    raise exception 'genba not found' using errcode = '22023';
  end if;
  -- owner か editor のみ書ける（viewer/未共有は拒否）。
  if not public.is_genba_editor(p_genba) then
    raise exception 'not an editor of this genba' using errcode = '42501';
  end if;

  v_is_genba_tbl := p_entity_table = any (v_genba_tables);
  v_is_plan_tbl := p_entity_table = any (v_plan_tables);
  v_is_spotlink := p_entity_table = 'itinerary_spot_links';
  if not (v_is_genba_tbl or v_is_plan_tbl or v_is_spotlink) then
    -- genbas 本体・genba_shares・招待などは editor 経由で書けない。
    raise exception 'table not editable via shared mutation: %', p_entity_table
      using errcode = '22023';
  end if;
  if p_op_type not in ('upsert', 'delete') then
    raise exception 'invalid op_type: %', p_op_type using errcode = '22023';
  end if;
  if p_op_type = 'upsert'
     and (p_payload ->> 'id') is distinct from p_entity_id::text then
    raise exception 'payload id mismatch' using errcode = '22023';
  end if;

  -- 対象行が p_genba に属することを検証する（他現場への書き込みを防ぐ）。
  if p_op_type = 'upsert' then
    if v_is_genba_tbl then
      v_row_genba := (p_payload ->> 'genba_id')::uuid;
    elsif v_is_plan_tbl then
      select genba_id into v_row_genba from public.itinerary_plans
        where id = (p_payload ->> 'plan_id')::uuid;
    else
      -- itinerary_spot_links: payload の spot_id → spot → plan → genba。
      select p.genba_id into v_row_genba
        from public.itinerary_spots s
        join public.itinerary_plans p on p.id = s.plan_id
        where s.id = (p_payload ->> 'spot_id')::uuid;
    end if;
  else
    if v_is_genba_tbl then
      execute format('select genba_id from public.%I where id = $1', p_entity_table)
        into v_row_genba using p_entity_id;
    elsif v_is_plan_tbl then
      execute format(
        'select p.genba_id from public.itinerary_plans p '
        'join public.%I c on c.plan_id = p.id where c.id = $1',
        p_entity_table
      ) into v_row_genba using p_entity_id;
    else
      -- itinerary_spot_links の削除: 既存行の spot_id → spot → plan → genba。
      select p.genba_id into v_row_genba
        from public.itinerary_spot_links c
        join public.itinerary_spots s on s.id = c.spot_id
        join public.itinerary_plans p on p.id = s.plan_id
        where c.id = p_entity_id;
    end if;
  end if;
  if v_row_genba is null or v_row_genba <> p_genba then
    raise exception 'row does not belong to the authorized genba'
      using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtext('mutation'), hashtext(p_mutation_id::text));
  perform pg_advisory_xact_lock(hashtext(p_entity_table), hashtext(p_entity_id::text));

  -- 冪等: 同じ mutation は一度だけ適用する。
  if exists (select 1 from public.outbox_operations where id = p_mutation_id) then
    execute format('select version from public.%I where id = $1', p_entity_table)
      into v_current using p_entity_id;
    return jsonb_build_object('status', 'applied', 'version', v_current);
  end if;

  execute format('select version from public.%I where id = $1', p_entity_table)
    into v_current using p_entity_id;

  -- カバー写真の安全な切替: memory_photos を is_cover=true で upsert する場合、
  -- 対象行を書く直前に同一現場の他カバーを false にする（部分ユニーク制約回避）。
  v_clear_cover := p_op_type = 'upsert'
    and p_entity_table = 'memory_photos'
    and coalesce((p_payload ->> 'is_cover')::boolean, false);

  if p_op_type = 'upsert' then
    select coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb)
      into v_data
      from jsonb_each(p_payload) e
      where e.key in (
        select c.column_name from information_schema.columns c
        where c.table_schema = 'public' and c.table_name = p_entity_table
      )
      and e.key not in ('id', 'owner_id', 'version');

    if v_current is not null then
      if p_base_version is null or v_current <> p_base_version then
        return jsonb_build_object('status', 'conflict', 'version', v_current);
      end if;
      -- CAS 通過後（適用が確定してから）に他カバーを落とす。対象現場に限定し、
      -- 対象写真自身は除外する（他現場の写真は触らない）。
      if v_clear_cover then
        update public.memory_photos
          set is_cover = false
          where genba_id = p_genba and is_cover and id <> p_entity_id;
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
      end if;
      execute format('select version from public.%I where id = $1', p_entity_table)
        into v_current using p_entity_id;
    else
      -- 新規カバー写真の挿入前にも他カバーを落とす（対象はまだ存在しない）。
      if v_clear_cover then
        update public.memory_photos
          set is_cover = false
          where genba_id = p_genba and is_cover and id <> p_entity_id;
      end if;
      -- 新規行の owner_id は **現場 owner** に正規化する（editor ではない）。
      v_data := v_data
        || jsonb_build_object('id', p_entity_id::text)
        || jsonb_build_object('owner_id', v_owner::text);
      select string_agg(quote_ident(k), ', ') into v_cols
        from jsonb_object_keys(v_data) k;
      execute format(
        'insert into public.%1$I (%2$s) '
        'select %2$s from jsonb_populate_record(null::public.%1$I, $1) '
        'on conflict (id) do nothing returning version',
        p_entity_table, v_cols
      ) into v_current using v_data;
      -- 動的 EXECUTE は FOUND を設定しないため、RETURNING version で判定する
      -- （新規は bump_version で必ず >=1。ON CONFLICT DO NOTHING は null=conflict）。
      if v_current is null then
        return jsonb_build_object('status', 'conflict', 'version', null);
      end if;
    end if;
  else
    if v_current is not null then
      if p_base_version is null or v_current <> p_base_version then
        return jsonb_build_object('status', 'conflict', 'version', v_current);
      end if;
      execute format('delete from public.%I where id = $1', p_entity_table)
        using p_entity_id;
    end if;
    v_current := null;
  end if;

  -- 監査台帳（owner_id は現場 owner、実行者は auth.uid で記録）。
  insert into public.outbox_operations (id, owner_id, entity_table, entity_id, op_type)
  values (p_mutation_id, v_owner, p_entity_table, p_entity_id, p_op_type)
  on conflict (id) do nothing;

  return jsonb_build_object('status', 'applied', 'version', v_current);
end;
$$;
revoke execute on function public.apply_shared_mutation(
  uuid, text, uuid, text, jsonb, bigint, uuid) from public;
grant execute on function public.apply_shared_mutation(
  uuid, text, uuid, text, jsonb, bigint, uuid) to authenticated;
