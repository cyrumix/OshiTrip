-- pgTAP: 思い出写真の分類・関連項目の不変条件（§8.4 / Issue3 / 0020）
--
-- enforce_memory_photo_subject トリガが、直接 INSERT/UPDATE で不正な組み合わせを
-- 拒否し、正しい組み合わせを許容することを検証する。owner/genba/category の
-- 明示照合により、別owner・別genba・category不一致・存在しない項目も拒否される。
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(17);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

-- ===========================================================================
-- user1: 現場・グッズ・行った場所(spot)・食べたもの(food) を用意する
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演', '2026-08-01');

insert into public.goods_items (id, genba_id, owner_id, name)
values ('90000000-0000-0000-0000-000000000001',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'ペンライト'),
       ('90000000-0000-0000-0000-000000000005',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'グッズ2');

insert into public.visited_places (id, genba_id, owner_id, name, category)
values ('40000000-0000-0000-0000-000000000001',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '聖地', 'spot'),
       ('40000000-0000-0000-0000-000000000002',
        'a1111111-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'ラーメン', 'food');

-- user2: 別ownerの現場と項目（別owner/別genba参照の負例に使う）
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('b2222222-0000-0000-0000-000000000001',
        '22222222-2222-2222-2222-222222222222', '別', '別公演', '2026-08-02');
insert into public.goods_items (id, genba_id, owner_id, name)
values ('90000000-0000-0000-0000-0000000000f2',
        'b2222222-0000-0000-0000-000000000001',
        '22222222-2222-2222-2222-222222222222', '別グッズ');

-- ===========================================================================
-- user1 に戻り、正例（許可される組み合わせ）
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 1) 当日の写真（subject 無し）
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category)
    values ('c0000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'event')$$,
  'event photo without subject is allowed'
);

-- 2) グッズ（同owner/genbaのgoods）
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-000000000002',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods', 'goods',
            '90000000-0000-0000-0000-000000000001')$$,
  'goods photo referencing own goods is allowed'
);

-- 3) 行った場所（category=spot の visited_place）
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-000000000003',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'visited_place', 'visited_place',
            '40000000-0000-0000-0000-000000000001')$$,
  'visited_place photo referencing a spot place is allowed'
);

-- 4) 食べたもの（category=food の visited_place）
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-000000000004',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'food', 'visited_place',
            '40000000-0000-0000-0000-000000000002')$$,
  'food photo referencing a food place is allowed'
);

-- 5) 関連解除済み（goods 分類で両方 NULL, アルバムに残した状態）
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category)
    values ('c0000000-0000-0000-0000-000000000005',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods')$$,
  'detached goods photo (both null) is allowed'
);

-- ===========================================================================
-- 負例（拒否される組み合わせ）
-- ===========================================================================

-- subject_type だけ設定
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type)
    values ('c0000000-0000-0000-0000-0000000000f1',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods', 'goods')$$,
  'subject_type and subject_id must be set together',
  'reject subject_type only'
);

-- subject_id だけ設定
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f2',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods',
            '90000000-0000-0000-0000-000000000001')$$,
  'subject_type and subject_id must be set together',
  'reject subject_id only'
);

-- event に subject を設定
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f3',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'event', 'goods',
            '90000000-0000-0000-0000-000000000001')$$,
  'event photo must not reference a subject',
  'reject event with subject'
);

-- goods から visited_place を参照（種別不一致）
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f4',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods', 'visited_place',
            '40000000-0000-0000-0000-000000000001')$$,
  'goods photo requires subject_type goods',
  'reject goods referencing visited_place type'
);

-- food から spot を参照（category不一致）
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f5',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'food', 'visited_place',
            '40000000-0000-0000-0000-000000000001')$$,
  'food photo must reference a food place',
  'reject food referencing a spot place'
);

-- visited_place から food を参照（category不一致）
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f6',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'visited_place', 'visited_place',
            '40000000-0000-0000-0000-000000000002')$$,
  'visited_place photo must reference a spot place',
  'reject visited_place referencing a food place'
);

-- 存在しない項目
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f7',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods', 'goods',
            '99999999-9999-9999-9999-999999999999')$$,
  'goods subject not found for owner/genba',
  'reject nonexistent subject'
);

-- 別owner の項目（user2 のグッズを参照）
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f8',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'goods', 'goods',
            '90000000-0000-0000-0000-0000000000f2')$$,
  'goods subject not found for owner/genba',
  'reject other owner subject'
);

-- 別genba の項目（同owner だが別現場の項目を参照）: 別現場を作って検証
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('a1111111-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', 'A', '別現場', '2026-08-03');
select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, album_category, subject_type, subject_id)
    values ('c0000000-0000-0000-0000-0000000000f9',
            'a1111111-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111', 'goods', 'goods',
            '90000000-0000-0000-0000-000000000001')$$,
  'goods subject not found for owner/genba',
  'reject subject from another genba'
);

-- apply_mutation 経由でも同じ不変条件で拒否される（event に subject を混入）
select throws_ok(
  $$select public.apply_mutation(
      'dddddddd-0000-0000-0000-0000000000fa'::uuid,
      'memory_photos',
      'c0000000-0000-0000-0000-0000000000fa'::uuid,
      'upsert',
      jsonb_build_object(
        'id', 'c0000000-0000-0000-0000-0000000000fa',
        'genba_id', 'a1111111-0000-0000-0000-000000000001',
        'owner_id', '11111111-1111-1111-1111-111111111111',
        'album_category', 'event',
        'subject_type', 'goods',
        'subject_id', '90000000-0000-0000-0000-000000000001'),
      null)$$,
  'event photo must not reference a subject',
  'apply_mutation is also rejected by the subject invariant'
);

-- UPDATE 正例: グッズ写真の関連先を別の有効なグッズへ付け替えられる（uuid比較）。
select lives_ok(
  $$update public.memory_photos
      set subject_id = '90000000-0000-0000-0000-000000000005'
    where id = 'c0000000-0000-0000-0000-000000000002'$$,
  'update goods photo to another valid goods succeeds (uuid = uuid)'
);

-- apply_mutation 正例: 有効なグッズ写真の upsert は適用される。
select is(
  (select public.apply_mutation(
      'dddddddd-0000-0000-0000-0000000000fb'::uuid,
      'memory_photos',
      'c0000000-0000-0000-0000-0000000000fb'::uuid,
      'upsert',
      jsonb_build_object(
        'id', 'c0000000-0000-0000-0000-0000000000fb',
        'genba_id', 'a1111111-0000-0000-0000-000000000001',
        'owner_id', '11111111-1111-1111-1111-111111111111',
        'album_category', 'goods',
        'subject_type', 'goods',
        'subject_id', '90000000-0000-0000-0000-000000000001'),
      null) ->> 'status'),
  'applied',
  'apply_mutation accepts a valid goods photo (positive)'
);

select * from finish();
rollback;
