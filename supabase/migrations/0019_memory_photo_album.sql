-- ============================================================================
-- 0019_memory_photo_album.sql
--   思い出写真にアルバム分類・関連項目を追加する（§8.4）。
--   - album_category: event / goods / visited_place / food（既定 event）
--   - subject_type:   goods / visited_place（当日の写真では null）
--   - subject_id:     関連項目のID（緩い参照。FK は張らない）
--
--   写真の保存元は memory_photos に一本化し、画面ごとに複製しない。項目
--   （グッズ/行った場所）を削除しても写真はアルバムへ残す（既定）ため、
--   subject_id には外部キー制約を張らず、緩い参照として扱う。
--
--   0004 を書き換えず前方専用で追加する。ローカル Drift v13 と同一方針。
--   既存写真は削除せず album_category='event'（当日の写真）へ移行する。
--   apply_mutation の列許可は information_schema から動的取得するため、新列は
--   自動的に対象になる（0011）。RLS は owner ベースの既存ポリシーを継承する。
-- ============================================================================

alter table public.memory_photos
  add column if not exists album_category text not null default 'event';
alter table public.memory_photos
  add column if not exists subject_type text;
alter table public.memory_photos
  add column if not exists subject_id text;

-- 既存写真は当日の写真へ移行する（空・null のものだけ）。
update public.memory_photos
   set album_category = 'event'
 where coalesce(album_category, '') = '';

-- 分類・種別の値を安定コードに限定する。
alter table public.memory_photos
  drop constraint if exists memory_photos_album_category_check;
alter table public.memory_photos
  add constraint memory_photos_album_category_check
  check (album_category in ('event', 'goods', 'visited_place', 'food'));

alter table public.memory_photos
  drop constraint if exists memory_photos_subject_type_check;
alter table public.memory_photos
  add constraint memory_photos_subject_type_check
  check (subject_type is null or subject_type in ('goods', 'visited_place'));

-- アルバム分類・関連項目での絞り込みを速くする。
create index if not exists idx_memory_photos_album_category
  on public.memory_photos (genba_id, album_category);
create index if not exists idx_memory_photos_subject
  on public.memory_photos (subject_id);
