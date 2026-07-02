-- ============================================================================
-- 0005_storage_account.sql — 認可付きStorageバケットとアカウント削除RPC
-- ============================================================================

-- ----------------------------------------------------------------------------
-- memory-photos バケット（private）。パス: {owner_id}/{genba_id}/{photo_id}.jpg
-- 所有者のみ読み書き可（ADR-0008: 画像への認可付きアクセス）。
-- チケット画像用の将来バケットも同方式で追加する（follow-up-work 参照）。
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('memory-photos', 'memory-photos', false)
on conflict (id) do nothing;

create policy "memory_photos_select_own" on storage.objects
  for select using (
    bucket_id = 'memory-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "memory_photos_insert_own" on storage.objects
  for insert with check (
    bucket_id = 'memory-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "memory_photos_update_own" on storage.objects
  for update using (
    bucket_id = 'memory-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "memory_photos_delete_own" on storage.objects
  for delete using (
    bucket_id = 'memory-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ----------------------------------------------------------------------------
-- delete_account() — アカウントと関連データのカスケード削除（§15.2）
-- ユーザーデータは auth.users への FK (on delete cascade) で削除される。
-- Storage オブジェクトの物理削除は後続（docs/follow-up-work.md）。
-- ----------------------------------------------------------------------------
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from storage.objects
    where bucket_id = 'memory-photos'
      and (storage.foldername(name))[1] = auth.uid()::text;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
