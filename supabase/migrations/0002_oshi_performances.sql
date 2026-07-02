-- ============================================================================
-- 0002_oshi_performances.sql — マイ推し（個人データ）と公演マスタ（共有データ）
-- 公演マスタと個人の現場情報は混在させない（§10.3）。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- oshi_groups / oshi_members（所有者のみ）
-- ----------------------------------------------------------------------------
create table public.oshi_groups (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  kind text,
  color text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_oshi_groups_owner on public.oshi_groups (owner_id);
alter table public.oshi_groups enable row level security;

create policy "oshi_groups_all_own" on public.oshi_groups
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_oshi_groups_updated_at
  before update on public.oshi_groups
  for each row execute function public.set_updated_at();

create table public.oshi_members (
  id uuid primary key,
  group_id uuid not null references public.oshi_groups (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  rank text not null default 'oshi'
    check (rank in ('saioshi', 'oshi', 'yuruoshi', 'hakooshi', 'curious')),
  color text,
  oshi_since date,
  birthday date,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_oshi_members_owner on public.oshi_members (owner_id);
create index idx_oshi_members_group on public.oshi_members (group_id);
alter table public.oshi_members enable row level security;

create policy "oshi_members_all_own" on public.oshi_members
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_oshi_members_updated_at
  before update on public.oshi_members
  for each row execute function public.set_updated_at();

-- グループ経由の所有権迂回防止
create or replace function public.enforce_oshi_member_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
begin
  select owner_id into parent_owner from public.oshi_groups where id = new.group_id;
  if parent_owner is null then
    raise exception 'parent group not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent group owner';
  end if;
  return new;
end;
$$;

create trigger trg_oshi_members_owner
  before insert or update on public.oshi_members
  for each row execute function public.enforce_oshi_member_owner();

-- ----------------------------------------------------------------------------
-- performances（ユーザー投稿型公演マスタ、§10 — 今回は境界のみ）
--   認証ユーザーは閲覧・投稿可。更新は作成者のみ。
--   重複統合・通報・登録者数集計・少人数マスキングは後続
--   （docs/follow-up-work.md）。
-- ----------------------------------------------------------------------------
create table public.performances (
  id uuid primary key,
  group_name text not null,
  title text not null,
  venue text not null,
  event_date date not null,
  start_time_minutes integer check (start_time_minutes between 0 and 2880),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 類似判定（グループ/日付/会場/開演時間, §10.2）用の索引
create index idx_performances_similarity
  on public.performances (group_name, event_date, venue, start_time_minutes);
alter table public.performances enable row level security;

create policy "performances_select_authenticated" on public.performances
  for select using (auth.role() = 'authenticated');
create policy "performances_insert_authenticated" on public.performances
  for insert with check (auth.uid() is not null and created_by = auth.uid());
create policy "performances_update_creator" on public.performances
  for update using (created_by = auth.uid())
  with check (created_by = auth.uid());

create trigger trg_performances_updated_at
  before update on public.performances
  for each row execute function public.set_updated_at();
