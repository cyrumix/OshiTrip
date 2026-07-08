-- ============================================================================
-- 0025_shared_facility_draft_only_insert.sql
--   一般ユーザーによる shared_facilities の新規登録を draft のみに限定する
--   （旅程Phase 3 / 共有施設基盤の厳格化）。
--
--   これまでの INSERT RLS ポリシーは created_by = auth.uid() のみを要求しており、
--   一般ユーザーが moderation_status='pending' を直接指定して新規登録できる
--   抜け穴があった（'approved'/'rejected' は既存トリガで既に禁止済み）。
--
--   本 migration は:
--   - RLS: INSERT の WITH CHECK に moderation_status = 'draft' を追加する。
--   - トリガ: INSERT で一般ユーザー（auth.uid() 非 null）が draft 以外を
--     指定した場合を明示的に拒否する（RLS だけに依存しない多層防御）。
--   - service_role（auth.uid() が null な文脈）は制限しない。管理・移行での
--     任意ステータスでの直接 INSERT を妨げない。
--   - draft→pending の正規申請（UPDATE, 0024 のポリシー）はそのまま維持される。
--
--   前方専用。過去 migration は変更しない。
-- ============================================================================

-- INSERT は created_by 一致に加え、moderation_status='draft' を必須にする。
drop policy if exists "shared_facilities_insert_own" on public.shared_facilities;
create policy "shared_facilities_insert_own"
  on public.shared_facilities
  for insert
  with check (
    auth.uid() is not null
    and created_by = auth.uid()
    and moderation_status = 'draft'
  );

-- トリガ: 新規登録（INSERT）は一般ユーザーなら必ず draft から開始する
-- （RLS だけに依存しない多層防御）。service_role（auth.uid() が null）は対象外。
create or replace function public.enforce_shared_facility_moderation()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' and auth.uid() is not null
     and new.moderation_status <> 'draft' then
    raise exception 'new shared facility must start as draft';
  end if;

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
