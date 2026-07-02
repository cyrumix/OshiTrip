-- ============================================================================
-- 0004_memories_outbox.sql — 思い出（memory_*）と冪等化テーブル（outbox_operations）
-- ============================================================================

-- ----------------------------------------------------------------------------
-- memory_entries（1現場につき1件、§8）
-- ----------------------------------------------------------------------------
create table public.memory_entries (
  id uuid primary key,
  genba_id uuid not null unique references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  impression text not null default '',
  best_moment text not null default '',
  mc_notes text not null default '',
  seat_view text not null default '',
  tags jsonb not null default '[]'::jsonb,
  declined_fields jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_memory_entries_owner on public.memory_entries (owner_id);
alter table public.memory_entries enable row level security;
create policy "memory_entries_all_own" on public.memory_entries
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_memory_entries_updated_at
  before update on public.memory_entries
  for each row execute function public.set_updated_at();
create trigger trg_memory_entries_owner
  before insert or update on public.memory_entries
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- memory_photos（メタデータのみ。実体は Storage バケット memory-photos）
-- ----------------------------------------------------------------------------
create table public.memory_photos (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  storage_path text,
  upload_status text not null default 'local_only'
    check (upload_status in ('local_only', 'queued', 'uploaded', 'failed')),
  caption text,
  is_cover boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_memory_photos_genba on public.memory_photos (genba_id);
create index idx_memory_photos_owner on public.memory_photos (owner_id);
alter table public.memory_photos enable row level security;
create policy "memory_photos_all_own" on public.memory_photos
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_memory_photos_updated_at
  before update on public.memory_photos
  for each row execute function public.set_updated_at();
create trigger trg_memory_photos_owner
  before insert or update on public.memory_photos
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- setlist_items / goods_items / visited_places（§8.2/§8.4）
-- ----------------------------------------------------------------------------
create table public.setlist_items (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  position integer not null,
  song_title text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_setlist_items_genba on public.setlist_items (genba_id, position);
create index idx_setlist_items_owner on public.setlist_items (owner_id);
alter table public.setlist_items enable row level security;
create policy "setlist_items_all_own" on public.setlist_items
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_setlist_items_updated_at
  before update on public.setlist_items
  for each row execute function public.set_updated_at();
create trigger trg_setlist_items_owner
  before insert or update on public.setlist_items
  for each row execute function public.enforce_genba_child_owner();

create table public.goods_items (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  price integer,
  quantity integer not null default 1,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_goods_items_genba on public.goods_items (genba_id);
create index idx_goods_items_owner on public.goods_items (owner_id);
alter table public.goods_items enable row level security;
create policy "goods_items_all_own" on public.goods_items
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_goods_items_updated_at
  before update on public.goods_items
  for each row execute function public.set_updated_at();
create trigger trg_goods_items_owner
  before insert or update on public.goods_items
  for each row execute function public.enforce_genba_child_owner();

create table public.visited_places (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category text not null default 'spot' check (category in ('spot', 'food')),
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_visited_places_genba on public.visited_places (genba_id);
create index idx_visited_places_owner on public.visited_places (owner_id);
alter table public.visited_places enable row level security;
create policy "visited_places_all_own" on public.visited_places
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_visited_places_updated_at
  before update on public.visited_places
  for each row execute function public.set_updated_at();
create trigger trg_visited_places_owner
  before insert or update on public.visited_places
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- outbox_operations — クライアント書き込みの冪等化記録（§15.3）
-- id = client_mutation_id。適用済み操作の再送を無害化する。
-- ----------------------------------------------------------------------------
create table public.outbox_operations (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  entity_table text not null,
  entity_id uuid not null,
  op_type text not null check (op_type in ('upsert', 'delete')),
  applied_at timestamptz not null default now()
);

create index idx_outbox_operations_owner on public.outbox_operations (owner_id);
alter table public.outbox_operations enable row level security;
create policy "outbox_operations_all_own" on public.outbox_operations
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
