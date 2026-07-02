-- ============================================================================
-- 0001_init.sql — 基盤: 拡張・共通関数・profiles
-- 方針（ADR-0008）: サーバー（RLS）を信頼境界とする。全ユーザーデータ行に
-- owner_id を持たせ、既定で所有者以外は読み書き不可。
-- ============================================================================

create extension if not exists pgcrypto;

-- updated_at 自動更新
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- 子テーブルの所有権が親現場と一致することを強制する
-- （子テーブル経由の所有権迂回を防ぐ。owner_id の偽装も拒否する）
create or replace function public.enforce_genba_child_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
begin
  select owner_id into parent_owner from public.genbas where id = new.genba_id;
  if parent_owner is null then
    raise exception 'parent genba not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent genba owner';
  end if;
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- profiles（auth.users 1:1）
-- ----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (id = auth.uid());
create policy "profiles_insert_own" on public.profiles
  for insert with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- 新規ユーザー作成時に profile を自動作成
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
