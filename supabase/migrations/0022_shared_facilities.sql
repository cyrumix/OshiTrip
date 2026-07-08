-- ============================================================================
-- 0022_shared_facilities.sql
--   権利確認済みの共有施設基盤（旅程Phase 3 / itinerary-plan-spec §4.3・ADR-0010 §7）。
--
--   - Google Place ID は「重複候補の照合キー」として保持できる（名称・住所の
--     権利根拠にはしない）。
--   - 名称・住所には data_origin と rights_basis を必須にする。data_origin は
--     権利根拠を説明できる 4 種のみ（user_provided / facility_provided /
--     open_data / licensed）。**'google' 値は存在しない** = Google 応答をそのまま
--     出典にした登録を型で不可能にする。
--   - ユーザー投稿は owner 別下書き（draft）から始め、pending を経てモデレーション
--     で approved（共有）へ昇格する。承認は service role のみ（一般ユーザーは
--     approved/rejected へ遷移できない）。approved には rights_basis を必須にする
--     （Google 由来の丸写しを共有へ昇格させない, ADR-0010 §7）。
--
--   前方専用。過去 migration は変更しない。
-- ============================================================================

create table public.shared_facilities (
  id uuid primary key,
  created_by uuid not null references auth.users (id) on delete cascade,

  -- 重複候補の照合キー（任意）。名称・住所の権利根拠にはしない（§4.3）。
  google_place_id text,

  name text not null,
  address text,
  category text not null default 'other',

  -- 権利根拠を説明できる出典のみ（Google 応答の丸写しは含めない）。
  data_origin text not null
    check (data_origin in
      ('user_provided', 'facility_provided', 'open_data', 'licensed')),
  -- 権利根拠の説明（承認＝共有には必須）。
  rights_basis text,

  moderation_status text not null default 'draft'
    check (moderation_status in ('draft', 'pending', 'approved', 'rejected')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- 承認済み（共有）には rights_basis を必須にする。
  constraint shared_facilities_approved_requires_rights
    check (
      moderation_status <> 'approved'
      or (rights_basis is not null and length(trim(rights_basis)) > 0)
    )
);

-- 重複照合（Place ID）と公開一覧（承認済み）の索引。
create index idx_shared_facilities_place_id
  on public.shared_facilities (google_place_id)
  where google_place_id is not null;
create index idx_shared_facilities_moderation
  on public.shared_facilities (moderation_status);
create index idx_shared_facilities_owner
  on public.shared_facilities (created_by);

alter table public.shared_facilities enable row level security;

-- 本人は自分の下書きを CRUD 可。承認済み（共有）は認証ユーザーが閲覧可。
create policy "shared_facilities_select_own_or_approved"
  on public.shared_facilities
  for select using (
    created_by = auth.uid() or moderation_status = 'approved'
  );
create policy "shared_facilities_insert_own"
  on public.shared_facilities
  for insert with check (
    auth.uid() is not null and created_by = auth.uid()
  );
create policy "shared_facilities_update_own"
  on public.shared_facilities
  for update using (created_by = auth.uid())
  with check (created_by = auth.uid());
create policy "shared_facilities_delete_own"
  on public.shared_facilities
  for delete using (created_by = auth.uid());

create trigger trg_shared_facilities_updated_at
  before update on public.shared_facilities
  for each row execute function public.set_updated_at();

-- モデレーション強制（Google 由来の共有登録拒否・自己承認禁止）。
-- security invoker（definer ではない）・search_path 固定。auth.uid() は service
-- role では null になるため、一般ユーザー（auth.uid() 非 null）は approved/rejected
-- へ遷移できない。承認済みは rights_basis を必須にする。
create or replace function public.enforce_shared_facility_moderation()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  -- 一般ユーザーは draft/pending のみ。approved/rejected は service role だけ。
  if new.moderation_status in ('approved', 'rejected')
     and auth.uid() is not null then
    raise exception 'moderation transition requires service role';
  end if;
  -- 承認済み（共有）は rights_basis 必須（丸写しを共有へ昇格させない）。
  if new.moderation_status = 'approved'
     and (new.rights_basis is null or length(trim(new.rights_basis)) = 0) then
    raise exception 'approved shared facility requires rights_basis';
  end if;
  return new;
end;
$$;

create trigger trg_shared_facilities_moderation
  before insert or update on public.shared_facilities
  for each row execute function public.enforce_shared_facility_moderation();
