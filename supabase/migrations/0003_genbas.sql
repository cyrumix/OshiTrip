-- ============================================================================
-- 0003_genbas.sql — 現場集約（genbas + tickets/transports/lodgings/todos/memos）
-- 全テーブル RLS 有効・所有者のみ。子テーブルはトリガーで親との所有権一致を強制。
-- ============================================================================

create table public.genbas (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  artist_name text not null,
  title text not null,
  event_date date not null,
  oshi_group_id uuid references public.oshi_groups (id) on delete set null,
  oshi_member_ids jsonb not null default '[]'::jsonb,
  venue text,
  -- 公演日 0:00 からの分数。深夜公演（日跨ぎ）は 1440 超を許容する。
  door_time_minutes integer check (door_time_minutes between 0 and 2880),
  start_time_minutes integer check (start_time_minutes between 0 and 2880),
  end_time_minutes integer check (end_time_minutes between 0 and 2880),
  performance_type text,
  performance_id uuid references public.performances (id) on delete set null,
  is_expedition boolean,
  transport_requirement text not null default 'unknown'
    check (transport_requirement in ('unknown', 'required', 'not_required')),
  lodging_requirement text not null default 'unknown'
    check (lodging_requirement in ('unknown', 'required', 'not_required')),
  is_canceled boolean not null default false,
  manual_ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_genbas_owner_date on public.genbas (owner_id, event_date);
alter table public.genbas enable row level security;

create policy "genbas_all_own" on public.genbas
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create trigger trg_genbas_updated_at
  before update on public.genbas
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- tickets（§7.3）
-- 注意: seat / entry_number / image_path はセンシティブ。共有時は既定で対象外
-- （共有機能は後続。ADR-0008 の field_grants 参照）。
-- ----------------------------------------------------------------------------
create table public.tickets (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  acquisition_status text not null default 'not_applied'
    check (acquisition_status in ('not_applied', 'applied', 'won', 'lost', 'acquired')),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid', 'not_required')),
  issuance_status text not null default 'not_issued'
    check (issuance_status in ('not_issued', 'issued', 'digital')),
  seat text,
  entry_number text,
  gate text,
  url text,
  image_path text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_tickets_genba on public.tickets (genba_id);
create index idx_tickets_owner on public.tickets (owner_id);
alter table public.tickets enable row level security;
create policy "tickets_all_own" on public.tickets
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_tickets_updated_at
  before update on public.tickets
  for each row execute function public.set_updated_at();
create trigger trg_tickets_owner
  before insert or update on public.tickets
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- transports（§7.4）
-- ----------------------------------------------------------------------------
create table public.transports (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  direction text not null default 'outbound'
    check (direction in ('outbound', 'inbound')),
  method text,
  from_place text,
  to_place text,
  depart_at timestamptz,
  arrive_at timestamptz,
  reservation_number text,
  url text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_transports_genba on public.transports (genba_id);
create index idx_transports_owner on public.transports (owner_id);
alter table public.transports enable row level security;
create policy "transports_all_own" on public.transports
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_transports_updated_at
  before update on public.transports
  for each row execute function public.set_updated_at();
create trigger trg_transports_owner
  before insert or update on public.transports
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- lodgings（§7.5）
-- ----------------------------------------------------------------------------
create table public.lodgings (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text,
  checkin_date date,
  checkout_date date,
  address text,
  reservation_number text,
  url text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_lodgings_genba on public.lodgings (genba_id);
create index idx_lodgings_owner on public.lodgings (owner_id);
alter table public.lodgings enable row level security;
create policy "lodgings_all_own" on public.lodgings
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_lodgings_updated_at
  before update on public.lodgings
  for each row execute function public.set_updated_at();
create trigger trg_lodgings_owner
  before insert or update on public.lodgings
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- todos（§7.6）
-- ----------------------------------------------------------------------------
create table public.todos (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  due_date date,
  is_done boolean not null default false,
  assignee text,
  priority text not null default 'normal'
    check (priority in ('low', 'normal', 'high')),
  memo text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_todos_genba on public.todos (genba_id);
create index idx_todos_owner_due on public.todos (owner_id, due_date);
alter table public.todos enable row level security;
create policy "todos_all_own" on public.todos
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_todos_updated_at
  before update on public.todos
  for each row execute function public.set_updated_at();
create trigger trg_todos_owner
  before insert or update on public.todos
  for each row execute function public.enforce_genba_child_owner();

-- ----------------------------------------------------------------------------
-- genba_memos（§7.7、区分ごとに1件）
-- ----------------------------------------------------------------------------
create table public.genba_memos (
  id uuid primary key,
  genba_id uuid not null references public.genbas (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  category text not null
    check (category in ('free', 'goods', 'meetup', 'around', 'notice')),
  body text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (genba_id, category)
);

create index idx_genba_memos_owner on public.genba_memos (owner_id);
alter table public.genba_memos enable row level security;
create policy "genba_memos_all_own" on public.genba_memos
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create trigger trg_genba_memos_updated_at
  before update on public.genba_memos
  for each row execute function public.set_updated_at();
create trigger trg_genba_memos_owner
  before insert or update on public.genba_memos
  for each row execute function public.enforce_genba_child_owner();
