-- ============================================================================
-- 0008_anniversary_owner_hardening.sql — 記念日オーナー整合の直接防御（R8-B / F-3）
--
-- 目的:
--   `enforce_oshi_anniversary_owner()`（0007）は member_id 指定時に
--   「member が同一 group に属する」ことだけを確認し、取得した member_owner を
--   new.owner_id と直接比較していなかった。安全性は別トリガー
--   `enforce_oshi_member_owner`（0002）が維持する不変条件
--   （oshi_members.owner_id は常に親 group の owner と一致）に暗黙依存していた。
--
--   R8監査（F-3）指摘に従い、その不変条件が将来崩れても記念日のオーナー不一致を
--   検出できるよう、member_owner と new.owner_id の直接比較を追加する（多層防御）。
--   既存マイグレーションは変更せず、ここで関数を再定義する（トリガー
--   `trg_oshi_anniversaries_owner` は関数名参照のため自動的に新定義を使う）。
-- ============================================================================

create or replace function public.enforce_oshi_anniversary_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  parent_owner uuid;
  member_owner uuid;
begin
  select owner_id into parent_owner from public.oshi_groups where id = new.group_id;
  if parent_owner is null then
    raise exception 'parent group not found';
  end if;
  if new.owner_id is distinct from parent_owner then
    raise exception 'owner_id must match parent group owner';
  end if;
  -- member_id を指定する場合、そのメンバーも同一グループに属すること。
  if new.member_id is not null then
    select owner_id into member_owner from public.oshi_members
      where id = new.member_id and group_id = new.group_id;
    if member_owner is null then
      raise exception 'member does not belong to the group';
    end if;
    -- 直接防御（R8-B / F-3）: メンバーの owner が記念日の owner と一致すること。
    -- 通常は enforce_oshi_member_owner の不変条件により group_id 一致で owner も
    -- 一致するが、その前提が崩れた場合でもここで確実に検出する。
    if member_owner is distinct from new.owner_id then
      raise exception 'member owner mismatch';
    end if;
  end if;
  return new;
end;
$$;
