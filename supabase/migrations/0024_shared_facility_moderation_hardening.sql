-- ============================================================================
-- 0024_shared_facility_moderation_hardening.sql
--   承認済み共有施設を投稿者が変更・削除できないようにする（Fix1 / High）。
--   RLS（USING=旧行 / WITH CHECK=新行）とトリガの両方で強制する（片方に依存しない）。
--
--   一般ユーザーに許可:
--   - 自分の draft を閲覧・更新・削除、自分の pending を閲覧、pending→draft の差し戻し
--   - approved / rejected は閲覧のみ
--   一般ユーザーに禁止:
--   - approved の更新・削除、approved→pending/draft、rejected の直接更新、
--     approved/rejected への自己変更
--   service_role のみ: pending→approved / pending→rejected / approved・rejected の
--   修正・削除・差し戻し。
--
--   前方専用。過去 migration は変更しない。
-- ============================================================================

-- UPDATE: 本人の draft/pending だけを対象（USING）にし、結果も draft/pending に
-- 限る（WITH CHECK）。approved/rejected は USING で除外（触れられない）、approved/
-- rejected への変更は WITH CHECK で拒否。pending→draft（差し戻し）は両者 draft/
-- pending なので許可。
drop policy if exists "shared_facilities_update_own" on public.shared_facilities;
create policy "shared_facilities_update_own"
  on public.shared_facilities
  for update
  using (
    created_by = auth.uid()
    and moderation_status in ('draft', 'pending')
  )
  with check (
    created_by = auth.uid()
    and moderation_status in ('draft', 'pending')
  );

-- DELETE: 本人の draft だけ（安全な状態に限定）。pending/approved/rejected は不可。
drop policy if exists "shared_facilities_delete_own" on public.shared_facilities;
create policy "shared_facilities_delete_own"
  on public.shared_facilities
  for delete
  using (created_by = auth.uid() and moderation_status = 'draft');

-- トリガも強化（RLS だけに依存しない多層防御）。一般ユーザー（auth.uid() 非 null）:
--   - OLD が approved/rejected の行は変更不可
--   - NEW を approved/rejected にできない（自己承認/自己却下の禁止）
-- 承認済みは rights_basis 必須。service role（auth.uid() null）は制限しない。
create or replace function public.enforce_shared_facility_moderation()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'UPDATE' and auth.uid() is not null
     and old.moderation_status in ('approved', 'rejected') then
    raise exception 'approved/rejected facility is read-only for its creator';
  end if;
  if new.moderation_status in ('approved', 'rejected')
     and auth.uid() is not null then
    raise exception 'moderation transition requires service role';
  end if;
  if new.moderation_status = 'approved'
     and (new.rights_basis is null or length(trim(new.rights_basis)) = 0) then
    raise exception 'approved shared facility requires rights_basis';
  end if;
  return new;
end;
$$;
