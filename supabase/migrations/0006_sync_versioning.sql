-- ============================================================================
-- 0006_sync_versioning.sql — 同期の版管理と冪等な適用RPC（H-02）
--
-- 目的:
--  1. 各ユーザーデータ行に単調増加する `version` を持たせ、競合判定を
--     端末時計ではなくサーバー版で行う（clock skew に強い）。
--  2. `apply_mutation` RPC で「版のCAS（compare-and-swap）＋実データ変更＋
--     冪等ledger記録」を1トランザクションで行い、二重適用と部分適用を防ぐ。
--
-- 注: 本ファイルは Supabase(Postgres) 環境（CI: `supabase db reset` + pgTAP）で
--     適用・検証する。ローカル Windows 環境では未実行。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- version 列と増加トリガー
-- ---------------------------------------------------------------------------
create or replace function public.bump_version()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    -- 明示指定が無ければ 1 から。負値・0 は 1 に矯正。
    if new.version is null or new.version < 1 then
      new.version := 1;
    end if;
    return new;
  else
    new.version := old.version + 1;
    return new;
  end if;
end;
$$;

do $$
declare
  t text;
  versioned_tables text[] := array[
    'genbas', 'tickets', 'transports', 'lodgings', 'todos', 'genba_memos',
    'memory_entries', 'memory_photos', 'setlist_items', 'goods_items',
    'visited_places', 'oshi_groups', 'oshi_members'
  ];
begin
  foreach t in array versioned_tables loop
    execute format(
      'alter table public.%I add column if not exists version bigint not null default 1',
      t
    );
    execute format('drop trigger if exists trg_%I_bump_version on public.%I', t, t);
    execute format(
      'create trigger trg_%I_bump_version before insert or update on public.%I '
      'for each row execute function public.bump_version()',
      t, t
    );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_mutation RPC（原子的な版CAS＋冪等ledger）
--
-- 認可はすべて RLS（security invoker）に委ねる。RLS を跨いで他ユーザーの
-- owner_id を取得するような SECURITY DEFINER 補助関数は公開しない。
--
-- 排他制御:
--   同一 mutation_id と同一 entity(table+id) について transaction-scoped の
--   advisory lock を取得し、並行呼び出しを直列化する。ロックはRPCトランザクション
--   終了時に自動解放される。ロック取得後に ledger・現在version を再確認する。
--
-- upsert の判定:
--   - RLS で自分に見える既存行がある → version CAS 後に通常 UPDATE。
--   - 見える行が無い → owner_id=auth.uid で INSERT ... ON CONFLICT DO NOTHING
--     RETURNING。0 行なら「他ユーザー所有 id」または「並行挿入衝突」として
--     conflict を返す（他ユーザーの owner_id は取得も返却もしない）。
-- 冪等: outbox_operations に mutation_id があれば再適用しない（version も進めない）。
-- 競合(conflict): 既存行の base_version 不一致/null、または上記 INSERT 0 行。
-- 原子性: 実データ変更と ledger 記録を必ず同一トランザクションで行う。
-- 安全な列制御: payload のうち「実在する許可列（id/owner_id/version 除く）」だけを
--   書き込み対象にし、欠落列にはDB default を効かせる。id/owner_id/version は
--   クライアント値を使わずサーバーが制御する。
-- 戻り値 jsonb: {status: 'applied'|'conflict', version: bigint|null}
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
    'visited_places', 'oshi_groups', 'oshi_members'
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
  -- payload.id と p_entity_id の一致を強制（食い違うペイロードを拒否）。
  if p_op_type = 'upsert'
     and (p_payload ->> 'id') is distinct from p_entity_id::text then
    raise exception 'payload id mismatch' using errcode = '22023';
  end if;

  -- 直列化: mutation_id → entity(table+id) の順で常に同じ順序でロックし
  -- デッドロックを避ける。transaction-scoped なので RPC 終了で自動解放。
  perform pg_advisory_xact_lock(hashtext('mutation'), hashtext(p_mutation_id::text));
  perform pg_advisory_xact_lock(hashtext(p_entity_table), hashtext(p_entity_id::text));

  -- ロック取得後に ledger を再確認（並行同一 mutation の二重適用防止）。
  if exists (select 1 from public.outbox_operations where id = p_mutation_id) then
    execute format('select version from public.%I where id = $1', p_entity_table)
      into v_current using p_entity_id;
    return jsonb_build_object('status', 'applied', 'version', v_current);
  end if;

  -- ロック取得後に現在版を再確認（RLS により自分の行のみ見える）。
  execute format('select version from public.%I where id = $1', p_entity_table)
    into v_current using p_entity_id;

  if p_op_type = 'upsert' then
    -- 編集可能列（id/owner_id/version 以外の実在列）だけを payload から抽出。
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
      -- 自分に見える既存行 → CAS 後に通常 UPDATE（RLS が自分の行に限定）。
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
        -- 編集列が無くても version を進める（no-op UPDATE でトリガー発火）。
        execute format(
          'update public.%I set owner_id = owner_id where id = $1',
          p_entity_table
        ) using p_entity_id;
      end if;
      execute format('select version from public.%I where id = $1', p_entity_table)
        into v_current using p_entity_id;
    else
      -- 見える行が無い → INSERT を試みる。id/owner_id はサーバー制御。
      -- 他ユーザー所有 or 並行挿入で id 使用中なら ON CONFLICT DO NOTHING で
      -- 0 行 → conflict（他ユーザーの行は変更せず、owner_id も取得しない）。
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
      -- 動的 EXECUTE は FOUND を設定しないため、挿入されたか否かは
      -- RETURNING version（新規は bump_version で必ず >=1）で判定する。
      -- ON CONFLICT DO NOTHING で衝突した場合は v_current が null → conflict。
      if v_current is null then
        return jsonb_build_object('status', 'conflict', 'version', null);
      end if;
    end if;
  else
    -- delete にも CAS を適用（古い端末が新しいリモート行を消せないように）。
    if v_current is null then
      -- 自分に見える行が無い（既に削除済み or 他ユーザー所有）。冪等 no-op。
      null;
    elsif p_base_version is null or v_current <> p_base_version then
      return jsonb_build_object('status', 'conflict', 'version', v_current);
    else
      execute format('delete from public.%I where id = $1', p_entity_table)
        using p_entity_id;
    end if;
    v_current := null;
  end if;

  -- 冪等ledger（同一トランザクション内）。
  insert into public.outbox_operations (id, owner_id, entity_table, entity_id, op_type)
  values (p_mutation_id, v_uid, p_entity_table, p_entity_id, p_op_type)
  on conflict (id) do nothing;

  return jsonb_build_object('status', 'applied', 'version', v_current);
end;
$$;

grant execute on function public.apply_mutation(uuid, text, uuid, text, jsonb, bigint) to authenticated;
