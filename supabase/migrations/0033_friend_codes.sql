-- ============================================================================
-- 0033_friend_codes.sql
--   アカウントごとの一意なフレンドコードと、コードによるフレンド申請（追加要件）。
--
--   方針:
--   - profiles に一意な `friend_code`（NOT NULL / UNIQUE）を持たせる。
--   - コードはサーバー生成（gen_random_bytes・読みやすい32文字英数字・OSHI-XXXX-XXXX）。
--   - 新規ユーザーは BEFORE INSERT トリガで自動採番、既存ユーザーは backfill。
--   - `send_friend_request_by_code(text)` を追加。**コード完全一致のみ**で相手を
--     特定し（＝無制限検索はしない）、searchable=false でもコードを知っていれば
--     申請できる（明示的な到達手段とみなす）。状態機械・本人性・ブロック判定は
--     既存 `send_friend_request` と同じくサーバーで強制する。
--   - 既存 `send_friend_request(uuid)` は無改変。profiles の主キーは `id` のまま。
--
--   前方専用。RLS は変更しない（friend_code は本人が見える profiles 行に含まれる）。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- friend_code 列（まずは NULL 可で追加し、backfill 後に NOT NULL / UNIQUE 化）
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists friend_code text;

-- ---------------------------------------------------------------------------
-- コード生成（読みやすい 32 文字英数字・曖昧文字 0/1/I/O を除外）
-- ---------------------------------------------------------------------------
create or replace function public.gen_friend_code()
returns text
language plpgsql
volatile
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- 32 文字（0/1/I/O 除外）
  bytes bytea := gen_random_bytes(8);
  code text := '';
  i int;
begin
  for i in 0..7 loop
    code := code || substr(alphabet, 1 + (get_byte(bytes, i) % 32), 1);
  end loop;
  return 'OSHI-' || substr(code, 1, 4) || '-' || substr(code, 5, 4);
end;
$$;

-- 衝突時は再生成して一意なコードを返す（UNIQUE 索引が最終ガード）。
create or replace function public.gen_unique_friend_code()
returns text
language plpgsql
volatile
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  candidate text;
  attempts int := 0;
begin
  loop
    candidate := public.gen_friend_code();
    exit when not exists (
      select 1 from public.profiles where friend_code = candidate
    );
    attempts := attempts + 1;
    if attempts > 20 then
      raise exception 'could not generate a unique friend code';
    end if;
  end loop;
  return candidate;
end;
$$;

-- 新規 profiles 行に friend_code を自動採番する（handle_new_user 経由の作成も含む）。
create or replace function public.set_profile_friend_code()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
begin
  if new.friend_code is null then
    new.friend_code := public.gen_unique_friend_code();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_friend_code on public.profiles;
create trigger trg_profiles_friend_code
  before insert on public.profiles
  for each row execute function public.set_profile_friend_code();

-- ---------------------------------------------------------------------------
-- 既存ユーザーへの backfill（1 行ずつ一意コードを採番する）
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in select id from public.profiles where friend_code is null loop
    update public.profiles
      set friend_code = public.gen_unique_friend_code()
      where id = r.id;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- NOT NULL / UNIQUE / 形式 CHECK 化
-- ---------------------------------------------------------------------------
alter table public.profiles alter column friend_code set not null;
create unique index if not exists idx_profiles_friend_code
  on public.profiles (friend_code);

-- 形式 CHECK: OSHI-XXXX-XXXX（曖昧文字 0/1/I/O を含まない英数字のみ）。
-- I/O は A-Z から除外するため文字クラスを A-H, J-N, P-Z, 2-9 に限定する。
alter table public.profiles drop constraint if exists profiles_friend_code_format;
alter table public.profiles add constraint profiles_friend_code_format
  check (friend_code ~ '^OSHI-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$');

-- ---------------------------------------------------------------------------
-- friend_code は**サーバー採番専用**（本人でも直接変更できない）。
-- 一度採番された値（NOT NULL 化後は常に非 null）の変更を BEFORE UPDATE で拒否する。
-- null→採番（初回・backfill）は許可するため old.friend_code が非 null のときだけ弾く。
-- ---------------------------------------------------------------------------
create or replace function public.enforce_friend_code_immutable()
returns trigger
language plpgsql
as $$
begin
  if old.friend_code is not null
     and new.friend_code is distinct from old.friend_code then
    raise exception 'friend_code is server-assigned and cannot be changed'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_friend_code_immutable on public.profiles;
create trigger trg_profiles_friend_code_immutable
  before update on public.profiles
  for each row execute function public.enforce_friend_code_immutable();

-- ---------------------------------------------------------------------------
-- 内部用の採番/検証関数は一般ロールから実行できないようにする（トリガ経由でのみ
-- 使う。send_friend_request_by_code だけ authenticated へ公開する）。
-- ---------------------------------------------------------------------------
revoke execute on function public.gen_friend_code() from public;
revoke execute on function public.gen_unique_friend_code() from public;
revoke execute on function public.set_profile_friend_code() from public;
revoke execute on function public.enforce_friend_code_immutable() from public;

-- friend_code 列そのものを anon/authenticated から**書けなくする**（列レベル権限）。
-- テーブル全列 UPDATE/INSERT の GRANT（0032）は列レベル REVOKE を上書きしてしまう
-- ため、profiles だけテーブル権限を剥がし、**編集可能な列のみ**を列指定で付与し直す
-- （friend_code / id / created_at / updated_at は除外＝サーバー専用）。SELECT/DELETE は
-- 0032 のまま維持する。サーバー側（handle_new_user=SECURITY DEFINER トリガ採番・
-- backfill=superuser・各生成関数）は所有者権限で動くため影響を受けない。
revoke insert, update on public.profiles from anon, authenticated;
grant insert (id, display_name, avatar_url, bio, favorite_name,
              accepts_friend_requests, searchable)
  on public.profiles to anon, authenticated;
grant update (display_name, avatar_url, bio, favorite_name,
              accepts_friend_requests, searchable)
  on public.profiles to anon, authenticated;

-- ---------------------------------------------------------------------------
-- フレンドコードによる申請 RPC（コード完全一致のみ・searchable 不問）
-- ---------------------------------------------------------------------------
create or replace function public.send_friend_request_by_code(p_friend_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_code text := upper(btrim(coalesce(p_friend_code, '')));
  v_receiver uuid;
  v_accepts boolean;
  v_id uuid;
  v_status text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if v_code = '' then
    raise exception 'friend code is required' using errcode = '22023';
  end if;

  -- コード完全一致で相手を特定する（部分一致・列挙はしない = 無制限検索禁止を維持）。
  select id into v_receiver from public.profiles where friend_code = v_code;
  if v_receiver is null then
    raise exception 'friend code not found' using errcode = '22023';
  end if;
  if v_receiver = v_uid then
    raise exception 'cannot friend yourself' using errcode = '22023';
  end if;

  -- ブロックはどちらの向きでも申請不可。
  if exists (
    select 1 from public.friendships f
    where f.status = 'blocked'
      and ((f.requester_id = v_uid and f.receiver_id = v_receiver)
        or (f.requester_id = v_receiver and f.receiver_id = v_uid))
  ) then
    raise exception 'blocked' using errcode = '42501';
  end if;

  -- 受付可否のみ確認する。**searchable は問わない**（コードを知っている＝到達手段）。
  select accepts_friend_requests into v_accepts
    from public.profiles where id = v_receiver;
  if not coalesce(v_accepts, true) then
    raise exception 'receiver is not accepting friend requests' using errcode = '42501';
  end if;

  -- 相手→自分の pending があれば承認成立（相互申請の自然化）。
  update public.friendships
    set status = 'accepted', updated_at = now()
    where requester_id = v_receiver and receiver_id = v_uid and status = 'pending'
    returning id into v_id;
  if v_id is not null then
    return jsonb_build_object('id', v_id, 'status', 'accepted');
  end if;

  -- 自分→相手の行を pending で upsert（rejected からの再申請も pending に戻す）。
  insert into public.friendships (requester_id, receiver_id, status)
  values (v_uid, v_receiver, 'pending')
  on conflict (requester_id, receiver_id) do update
    set status = case
      when public.friendships.status = 'accepted' then 'accepted'
      else 'pending' end,
      updated_at = now()
  returning id, status into v_id, v_status;

  return jsonb_build_object('id', v_id, 'status', v_status);
end;
$$;
revoke execute on function public.send_friend_request_by_code(text) from public;
grant execute on function public.send_friend_request_by_code(text) to authenticated;
