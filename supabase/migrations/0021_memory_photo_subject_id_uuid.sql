-- ============================================================================
-- 0021_memory_photo_subject_id_uuid.sql
--   memory_photos.subject_id を text から uuid へ統一する（再レビュー High）。
--
--   参照先 goods_items.id / visited_places.id は uuid のため、0020 の検証トリガ内で
--   `id = new.subject_id`（uuid = text）が「operator does not exist」になり得た。
--   subject_id を uuid にすることで、トリガは uuid 同士で比較する（文字列連結・
--   動的SQL・キャストで回避しない）。
--
--   既存データの移行:
--   - NULL はそのまま
--   - 正しい UUID 文字列は uuid へ変換
--   - 不正な文字列は subject_type/subject_id を NULL に戻して「関連解除済み」に
--     する（album_category と写真自体は維持・写真は削除しない）
--   - 不正値があっても migration をクラッシュさせない（先に detach してから型変換）
--
--   0020 を書き換えず前方専用で追加する。ローカル Drift（SQLite）は subject_id を
--   TEXT のまま扱う（SQLite に uuid 型は無く、同期時に文字列で往復する）。
-- ============================================================================

-- 1) 不正な UUID 文字列を先に関連解除する（型変換のクラッシュを防ぐ）。
--    標準の 8-4-4-4-12 形式に一致しないものを対象にする。
update public.memory_photos
   set subject_type = null,
       subject_id = null
 where subject_id is not null
   and subject_id !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

-- 2) 残りは NULL または正しい UUID 文字列のみ。安全に uuid へ変換する。
alter table public.memory_photos
  alter column subject_id type uuid using subject_id::uuid;

-- 索引は型変更で自動的に再構築される（idx_memory_photos_subject）。
-- 0020 のトリガ enforce_memory_photo_subject は `id = new.subject_id` を
-- 参照しており、subject_id が uuid になったことで uuid 同士の比較になる
-- （関数の再作成は不要）。
