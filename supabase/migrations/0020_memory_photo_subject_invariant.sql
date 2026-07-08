-- ============================================================================
-- 0020_memory_photo_subject_invariant.sql
--   思い出写真の分類と関連項目の不変条件を DB 側でも強制する（§8.4 / Issue3）。
--   apply_mutation・直接 INSERT/UPDATE を含む全経路で不正な組み合わせを拒否する。
--
--   RLS だけに依存せず、owner_id / genba_id / 対象 category を明示照合する。
--   検証トリガは security definer ではなく security invoker とし、search_path を
--   固定する（スキーマ乗っ取り対策）。owner/genba を明示比較するため、RLS が
--   バイパスされる文脈でも別owner・別genbaの関連付けは成立しない。
--
--   許可する組み合わせ:
--   - event:         subject_type IS NULL かつ subject_id IS NULL
--   - goods:         subject_type='goods' かつ subject_id が同owner/genbaのgoods_items
--   - visited_place: subject_type='visited_place' かつ同owner/genbaのvisited_places(category=spot)
--   - food:          subject_type='visited_place' かつ同owner/genbaのvisited_places(category=food)
--   - goods/visited_place/food は「両方 NULL（関連解除済み・アルバムに残す）」も許容する。
-- ============================================================================

create or replace function public.enforce_memory_photo_subject()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  vp_category text;
begin
  if new.album_category = 'event' then
    if new.subject_type is not null or new.subject_id is not null then
      raise exception 'event photo must not reference a subject';
    end if;
    return new;
  end if;

  -- 関連項目削除時にアルバムへ残した写真（両方 NULL）を許容する（§8.4）。
  if new.subject_type is null and new.subject_id is null then
    return new;
  end if;
  -- 片方だけの設定は不正（subject_type だけ / subject_id だけ）。
  if new.subject_type is null or new.subject_id is null then
    raise exception 'subject_type and subject_id must be set together';
  end if;

  if new.album_category = 'goods' then
    if new.subject_type is distinct from 'goods' then
      raise exception 'goods photo requires subject_type goods';
    end if;
    perform 1 from public.goods_items
      where id = new.subject_id
        and genba_id = new.genba_id
        and owner_id = new.owner_id;
    if not found then
      raise exception 'goods subject not found for owner/genba';
    end if;
    return new;
  elsif new.album_category in ('visited_place', 'food') then
    if new.subject_type is distinct from 'visited_place' then
      raise exception 'visited_place/food photo requires subject_type visited_place';
    end if;
    select category into vp_category from public.visited_places
      where id = new.subject_id
        and genba_id = new.genba_id
        and owner_id = new.owner_id;
    if not found then
      raise exception 'visited_place subject not found for owner/genba';
    end if;
    if new.album_category = 'food' and vp_category is distinct from 'food' then
      raise exception 'food photo must reference a food place';
    end if;
    if new.album_category = 'visited_place'
       and vp_category is distinct from 'spot' then
      raise exception 'visited_place photo must reference a spot place';
    end if;
    return new;
  end if;

  raise exception 'unknown album_category %', new.album_category;
end;
$$;

-- owner トリガ（trg_memory_photos_owner）より後に走るよう命名する
-- （同一タイミングは名前順: owner < subject < updated_at）。
drop trigger if exists trg_memory_photos_subject on public.memory_photos;
create trigger trg_memory_photos_subject
  before insert or update on public.memory_photos
  for each row execute function public.enforce_memory_photo_subject();
