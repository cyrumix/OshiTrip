-- ============================================================================
-- 0030_social_profiles_friends_invites.sql
--   現場共有を自然にする社会機能の**データ基盤**（Phase 5 拡張 / 追加要件）:
--   簡易プロフィール（profiles）・フレンド（friendships）・招待URL（genba_invites）。
--
--   共有メンバーの実体管理は既存 `genba_shares`（0028）を使う。招待URLの参加は
--   `join_genba_via_invite` RPC が `genba_shares` 行を作る導線とする。
--
--   セキュリティ方針（完全身内想定でも最低限守る, 追加要件 §7）:
--   - 招待 token を知らない人は参加できない（token は推測不能・SECURITY DEFINER
--     RPC 経由でのみ検証）。
--   - revoked_at / expires_at / max_uses を過ぎた招待は使えない。
--   - owner 以外は招待URLを発行・無効化できない。
--   - owner 以外は共有メンバーの権限変更・削除ができない（genba_shares の owner
--     管理 RLS＝0028 を継承）。
--   - フレンド申請・応答は本人（requester/receiver）だけが操作できる。
--   - 他人のプロフィールは編集できない（本人のみ upsert）。
--   - フレンドでない相手を無制限に検索できない: プロフィール参照は本人・承認済み
--     フレンド・同一現場の共有メンバー・searchable=true のユーザーに限る。フレンド
--     申請は「同一現場の共有メンバー」または「searchable=true」のユーザーにのみ送れる。
--
--   前方専用。過去 migration・既存データ表の RLS は変更しない（owner隔離 C-01を保つ）。
--   D-248: profiles は 0001 の既存表（id PK）を alter で拡張する（二重 create しない）。
--   pgTAP 0016 は `supabase db reset && supabase test db` で実行し合格を確認済み。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- profiles: 既存 0001 の profiles を拡張する（本人のみ編集・可視範囲を限定）。
-- **主キーは既存の `id`（= auth.users.id）を正とする**。0001 で既に profiles が
-- 作られ、`handle_new_user`（0001）が auth.users 作成時に `id` だけで profile 行を
-- 自動作成する。ここで `create table` すると二重定義になり `relation "profiles"
-- already exists` で停止するため、**alter table で社会機能の列だけを追加**する
-- （D-248 是正）。追加列はすべて既定値/NULL 可にし、自動作成行を壊さない。
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists avatar_url text,
  add column if not exists bio text,
  add column if not exists favorite_name text,
  add column if not exists accepts_friend_requests boolean not null default true,
  add column if not exists searchable boolean not null default false;

-- 文字数制約（いずれも NULL 許容＝handle_new_user の自動作成行や未設定を壊さない）。
-- 名前つき制約を drop→add で安全に再定義する（idempotent）。
alter table public.profiles drop constraint if exists profiles_display_name_len;
alter table public.profiles add constraint profiles_display_name_len
  check (display_name is null or char_length(display_name) between 1 and 40);
alter table public.profiles drop constraint if exists profiles_bio_len;
alter table public.profiles add constraint profiles_bio_len
  check (bio is null or char_length(bio) <= 140);
alter table public.profiles drop constraint if exists profiles_favorite_name_len;
alter table public.profiles add constraint profiles_favorite_name_len
  check (favorite_name is null or char_length(favorite_name) <= 40);

-- RLS は 0001 で有効化済み。insert/update（本人限定 id = auth.uid()）は 0001 の
-- `profiles_insert_own` / `profiles_update_own` をそのまま使う。SELECT は 0001 の
-- 「本人限定」を可視範囲判定（can_view_profile）へ差し替える（下部で作成）。
-- **DELETE ポリシーは追加しない**（0005 の「本人でも直接 DELETE 不可」を維持。
-- アカウント削除は auth.users のカスケードに任せる, D-248）。
-- updated_at トリガ（trg_profiles_updated_at）も 0001 で作成済みのため作り直さない。
drop policy if exists "profiles_select_own" on public.profiles;

-- ---------------------------------------------------------------------------
-- friendships: フレンド関係（本人同士のみ操作。書き込みは RPC 経由に限定）
-- ---------------------------------------------------------------------------
create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users (id) on delete cascade,
  receiver_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friendships_not_self check (requester_id <> receiver_id),
  unique (requester_id, receiver_id)
);

create index idx_friendships_requester on public.friendships (requester_id);
create index idx_friendships_receiver on public.friendships (receiver_id);

alter table public.friendships enable row level security;

-- 当事者（requester/receiver）だけが自分に関わるフレンド行を閲覧できる。
create policy "friendships_select_party" on public.friendships
  for select to authenticated
  using (requester_id = auth.uid() or receiver_id = auth.uid());
-- 書き込みポリシーは作らない = 直接 insert/update/delete 不可。状態遷移は
-- send_friend_request / respond_friend_request / remove_friend（SECURITY DEFINER）
-- でのみ行い、状態機械をサーバーで強制する。

create trigger trg_friendships_updated_at
  before update on public.friendships
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- genba_invites: 現場ごとの招待URL（owner のみ発行・無効化。参加は RPC 経由）
-- ---------------------------------------------------------------------------
create table public.genba_invites (
  id uuid primary key default gen_random_uuid(),
  genba_id uuid not null references public.genbas (id) on delete cascade,
  -- 発行者＝現場の所有者。子owner トリガで genbas.owner_id との一致を強制する。
  owner_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  default_role text not null default 'viewer'
    check (default_role in ('editor', 'viewer')),
  expires_at timestamptz,
  revoked_at timestamptz,
  max_uses integer check (max_uses is null or max_uses > 0),
  used_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_genba_invites_genba on public.genba_invites (genba_id);
create index idx_genba_invites_owner on public.genba_invites (owner_id);

alter table public.genba_invites enable row level security;

-- owner（現場所有者＝発行者）だけが自分の招待を閲覧できる。参加者は token を
-- SECURITY DEFINER RPC へ渡して参加するため、招待行を直接 SELECT する必要はない。
create policy "genba_invites_select_owner" on public.genba_invites
  for select to authenticated using (owner_id = auth.uid());
-- 書き込みポリシーは作らない = 直接 insert/update/delete 不可。発行・無効化は
-- create_genba_invite / revoke_genba_invite（SECURITY DEFINER）でのみ行う。

create trigger trg_genba_invites_updated_at
  before update on public.genba_invites
  for each row execute function public.set_updated_at();

-- 子owner トリガ（既存関数を再利用）: new.owner_id が親現場の owner_id と一致する
-- ことを強制する。=「他人の現場の招待を作る」試みを弾く（多層防御。RPCでも検証）。
create trigger trg_genba_invites_owner
  before insert or update on public.genba_invites
  for each row execute function public.enforce_genba_child_owner();

-- ---------------------------------------------------------------------------
-- ヘルパ関数（RLS/RPC から使う。SECURITY DEFINER で内部の存在確認は RLS を貫通）
-- ---------------------------------------------------------------------------

-- 2人が同一現場の共有メンバーか（一方が owner でもう一方が grantee、または両者が
-- 同一現場の grantee）。招待URLで同じ現場に参加した相手＝ここで true になる。
create or replace function public.users_share_genba(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    -- a が owner の現場に b が grantee（またはその逆）
    select 1 from public.genba_shares s
      join public.genbas g on g.id = s.genba_id
    where (g.owner_id = p_a and s.grantee_id = p_b)
       or (g.owner_id = p_b and s.grantee_id = p_a)
  ) or exists (
    -- a と b が同一現場の grantee 同士
    select 1
      from public.genba_shares s1
      join public.genba_shares s2 on s1.genba_id = s2.genba_id
    where s1.grantee_id = p_a and s2.grantee_id = p_b
  );
$$;
revoke execute on function public.users_share_genba(uuid, uuid) from public;
grant execute on function public.users_share_genba(uuid, uuid) to authenticated;

-- プロフィールの可視判定（本人・searchable・承認済みフレンド・同一現場の共有メンバー）。
create or replace function public.can_view_profile(p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    p_target = auth.uid()
    or exists (
      select 1 from public.profiles pr
      where pr.id = p_target and pr.searchable = true
    )
    or exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = auth.uid() and f.receiver_id = p_target)
          or (f.receiver_id = auth.uid() and f.requester_id = p_target)
        )
    )
    or public.users_share_genba(auth.uid(), p_target);
$$;
revoke execute on function public.can_view_profile(uuid) from public;
grant execute on function public.can_view_profile(uuid) to authenticated;

-- プロフィール参照は本人・承認フレンド・同一現場メンバー・searchable に限る
-- （フレンドでない相手を無制限に列挙・検索できないようにする, 追加要件 §2/§7）。
drop policy if exists "profiles_select_visible" on public.profiles;
create policy "profiles_select_visible" on public.profiles
  for select to authenticated using (public.can_view_profile(id));

-- ---------------------------------------------------------------------------
-- フレンド RPC（本人のみ・状態機械をサーバーで強制）
-- ---------------------------------------------------------------------------

-- 申請を送る。相手が申請受付中 かつ（searchable または 同一現場の共有メンバー）の
-- ときだけ送れる。相手が既に自分へ申請中なら承認扱いにする（相互申請の自然化）。
create or replace function public.send_friend_request(p_receiver uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_accepts boolean;
  v_searchable boolean;
  v_id uuid;
  v_status text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_receiver = v_uid then
    raise exception 'cannot friend yourself' using errcode = '22023';
  end if;

  -- ブロックが存在する場合はどちらの向きでも申請不可。
  if exists (
    select 1 from public.friendships f
    where f.status = 'blocked'
      and ((f.requester_id = v_uid and f.receiver_id = p_receiver)
        or (f.requester_id = p_receiver and f.receiver_id = v_uid))
  ) then
    raise exception 'blocked' using errcode = '42501';
  end if;

  select accepts_friend_requests, searchable into v_accepts, v_searchable
    from public.profiles where id = p_receiver;
  v_accepts := coalesce(v_accepts, true);
  v_searchable := coalesce(v_searchable, false);
  if not v_accepts then
    raise exception 'receiver is not accepting friend requests' using errcode = '42501';
  end if;
  -- 無制限検索禁止: 同一現場メンバー か 相手が searchable のときだけ申請できる。
  if not (v_searchable or public.users_share_genba(v_uid, p_receiver)) then
    raise exception 'not allowed to request this user' using errcode = '42501';
  end if;

  -- 相手から自分への pending があれば、承認として成立させる。
  update public.friendships
    set status = 'accepted', updated_at = now()
    where requester_id = p_receiver and receiver_id = v_uid and status = 'pending'
    returning id into v_id;
  if v_id is not null then
    return jsonb_build_object('id', v_id, 'status', 'accepted');
  end if;

  -- 自分→相手の行を pending で upsert（rejected からの再申請も pending に戻す）。
  insert into public.friendships (requester_id, receiver_id, status)
  values (v_uid, p_receiver, 'pending')
  on conflict (requester_id, receiver_id) do update
    set status = case
      when public.friendships.status = 'accepted' then 'accepted'
      else 'pending' end,
      updated_at = now()
  returning id, status into v_id, v_status;

  return jsonb_build_object('id', v_id, 'status', v_status);
end;
$$;
revoke execute on function public.send_friend_request(uuid) from public;
grant execute on function public.send_friend_request(uuid) to authenticated;

-- 申請に応答する（receiver 本人のみ・pending のときだけ accepted/rejected へ）。
create or replace function public.respond_friend_request(p_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_status text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  update public.friendships
    set status = case when p_accept then 'accepted' else 'rejected' end,
        updated_at = now()
    where id = p_id and receiver_id = v_uid and status = 'pending'
    returning status into v_status;
  if v_status is null then
    raise exception 'no pending request to respond to' using errcode = '42501';
  end if;
  return jsonb_build_object('id', p_id, 'status', v_status);
end;
$$;
revoke execute on function public.respond_friend_request(uuid, boolean) from public;
grant execute on function public.respond_friend_request(uuid, boolean) to authenticated;

-- フレンドを削除する（当事者どちらでも・どの状態でも自分に関わる行を消す）。
create or replace function public.remove_friend(p_other uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  delete from public.friendships
    where (requester_id = v_uid and receiver_id = p_other)
       or (requester_id = p_other and receiver_id = v_uid);
end;
$$;
revoke execute on function public.remove_friend(uuid) from public;
grant execute on function public.remove_friend(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 招待URL RPC（owner のみ発行/無効化。参加は token 検証つき）
-- ---------------------------------------------------------------------------

-- 招待URLを発行する（owner のみ）。token はサーバーで推測不能に生成する。
create or replace function public.create_genba_invite(
  p_genba uuid,
  p_role text default 'viewer',
  p_expires timestamptz default null,
  p_max_uses integer default null
)
returns jsonb
language plpgsql
security definer
-- token 生成に pgcrypto の gen_random_bytes を使う。Supabase では pgcrypto は
-- `extensions` スキーマに入るため、search_path に extensions を含める（D-248）。
set search_path = public, extensions, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_token text;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_role not in ('editor', 'viewer') then
    raise exception 'invalid role' using errcode = '22023';
  end if;
  select owner_id into v_owner from public.genbas where id = p_genba;
  if v_owner is null then
    raise exception 'genba not found' using errcode = '22023';
  end if;
  if v_owner <> v_uid then
    raise exception 'only the owner can create an invite' using errcode = '42501';
  end if;

  v_token := encode(gen_random_bytes(24), 'hex');
  insert into public.genba_invites
    (genba_id, owner_id, token, default_role, expires_at, max_uses)
  values (p_genba, v_uid, v_token, p_role, p_expires, p_max_uses)
  returning id into v_id;

  return jsonb_build_object(
    'id', v_id, 'token', v_token, 'genba_id', p_genba,
    'default_role', p_role, 'expires_at', p_expires, 'max_uses', p_max_uses
  );
end;
$$;
revoke execute on function
  public.create_genba_invite(uuid, text, timestamptz, integer) from public;
grant execute on function
  public.create_genba_invite(uuid, text, timestamptz, integer) to authenticated;

-- 招待URLを無効化する（owner のみ・冪等）。
create or replace function public.revoke_genba_invite(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  update public.genba_invites
    set revoked_at = coalesce(revoked_at, now()), updated_at = now()
    where id = p_id and owner_id = v_uid;
  if not found then
    raise exception 'only the owner can revoke this invite' using errcode = '42501';
  end if;
end;
$$;
revoke execute on function public.revoke_genba_invite(uuid) from public;
grant execute on function public.revoke_genba_invite(uuid) to authenticated;

-- 招待の内部検証（token → 有効性理由・現場・発行者。参加はしない）。
-- 戻り値: reason（null=有効 / 'invite_not_found' / 'invite_revoked' /
--         'invite_expired' / 'invite_exhausted'）。
create or replace function public._resolve_invite(p_token text)
returns public.genba_invites
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select * from public.genba_invites where token = p_token;
$$;
revoke execute on function public._resolve_invite(text) from public;

-- 参加確認画面のプレビュー（現場名・公演名・日付・発行者プロフィール・付与権限・
-- 有効性・参加済みか）。参加はしない。
create or replace function public.get_invite_preview(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_inv public.genba_invites;
  v_g public.genbas;
  v_reason text := null;
  v_already boolean := false;
  v_owner_name text;
  v_owner_avatar text;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  v_inv := public._resolve_invite(p_token);
  if v_inv.id is null then
    return jsonb_build_object('valid', false, 'reason', 'invite_not_found');
  end if;
  if v_inv.revoked_at is not null then
    v_reason := 'invite_revoked';
  elsif v_inv.expires_at is not null and v_inv.expires_at < now() then
    v_reason := 'invite_expired';
  elsif v_inv.max_uses is not null and v_inv.used_count >= v_inv.max_uses then
    v_reason := 'invite_exhausted';
  end if;

  select * into v_g from public.genbas where id = v_inv.genba_id;
  select display_name, avatar_url into v_owner_name, v_owner_avatar
    from public.profiles where id = v_inv.owner_id;

  v_already := (v_inv.owner_id = v_uid) or exists (
    select 1 from public.genba_shares s
    where s.genba_id = v_inv.genba_id and s.grantee_id = v_uid
  );

  return jsonb_build_object(
    'valid', v_reason is null,
    'reason', v_reason,
    'genba_id', v_inv.genba_id,
    'artist_name', v_g.artist_name,
    'title', v_g.title,
    'event_date', v_g.event_date,
    'default_role', v_inv.default_role,
    'owner_display_name', v_owner_name,
    'owner_avatar_url', v_owner_avatar,
    'already_member', v_already
  );
end;
$$;
revoke execute on function public.get_invite_preview(text) from public;
grant execute on function public.get_invite_preview(text) to authenticated;

-- 招待URLで参加する（token 検証つき）。参加済み/owner は重複追加せず現状を返す。
-- 有効なら genba_shares 行を作成し used_count を1増やす。
create or replace function public.join_genba_via_invite(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_inv public.genba_invites;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- 同一 token の同時参加を直列化（used_count の競合と二重参加を防ぐ）。
  perform pg_advisory_xact_lock(hashtext('genba_invite'), hashtext(p_token));

  select * into v_inv from public.genba_invites where token = p_token for update;
  if v_inv.id is null then
    raise exception 'invite_not_found' using errcode = '22023';
  end if;
  if v_inv.revoked_at is not null then
    raise exception 'invite_revoked' using errcode = '42501';
  end if;
  if v_inv.expires_at is not null and v_inv.expires_at < now() then
    raise exception 'invite_expired' using errcode = '42501';
  end if;

  -- owner 本人は共有メンバーにしない（現場詳細へ遷移させるだけ）。
  if v_inv.owner_id = v_uid then
    return jsonb_build_object('genba_id', v_inv.genba_id, 'status', 'owner');
  end if;

  -- 既に参加済みなら重複追加しない・used_count も増やさない。
  if exists (
    select 1 from public.genba_shares s
    where s.genba_id = v_inv.genba_id and s.grantee_id = v_uid
  ) then
    return jsonb_build_object(
      'genba_id', v_inv.genba_id, 'status', 'already_member'
    );
  end if;

  -- 使用上限は「新規参加」判定の後に効かせる（参加済み再訪は上限に数えない）。
  if v_inv.max_uses is not null and v_inv.used_count >= v_inv.max_uses then
    raise exception 'invite_exhausted' using errcode = '42501';
  end if;

  insert into public.genba_shares
    (id, owner_id, genba_id, grantee_id, role)
  values (
    gen_random_uuid(), v_inv.owner_id, v_inv.genba_id, v_uid, v_inv.default_role
  );

  update public.genba_invites
    set used_count = used_count + 1, updated_at = now()
    where id = v_inv.id;

  return jsonb_build_object(
    'genba_id', v_inv.genba_id, 'status', 'joined', 'role', v_inv.default_role
  );
end;
$$;
revoke execute on function public.join_genba_via_invite(text) from public;
grant execute on function public.join_genba_via_invite(text) to authenticated;
