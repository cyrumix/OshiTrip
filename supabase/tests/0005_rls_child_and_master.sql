-- pgTAP: 子テーブル・outbox・profiles・performances の RLS 正例/負例（R8-B / F-1・F-2・F-3）
--
-- 監査(F-2)で pgTAP 未カバーだった transports / lodgings / genba_memos /
-- setlist_items / goods_items / visited_places / profiles / outbox_operations に
-- ついて、owner本人はCRUD可・別ownerは SELECT/INSERT/UPDATE/DELETE 不可・
-- 親ID経由の owner 迂回不可を検証する。lodgings.address / transports.reservation_number
-- 等の機微情報が別ownerへ露出しないことは、別ownerの SELECT が 0 件になることで担保する。
--
-- F-1: performances は DELETE ポリシーが無い（共有マスタの削除・統合は後続の
-- モデレーション機能で扱う, decisions.md R8-B節）。ここでは「投稿者本人でも
-- DELETE できない」ことを明示的に検証する。
--
-- F-3: 記念日の member owner 直接防御（0008）は、既存 0004 の member 整合テスト
-- （別グループ/別owner の member_id 拒否）が最終トリガー定義に対して回帰として
-- 働くことで担保される。ここでは記念日 owner 迂回の基本ケースを再掲しない。
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(43);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

-- ===========================================================================
-- user1 として: 親現場と各子テーブル1件ずつ、outbox・performance を用意する
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

-- ---- transports -----------------------------------------------------------
select lives_ok(
  $$insert into public.transports (id, genba_id, owner_id, reservation_number, from_place, to_place)
    values ('c1000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'RSV-T-1', '東京', '大阪')$$,
  'owner can insert own transport'
);

-- ---- lodgings -------------------------------------------------------------
select lives_ok(
  $$insert into public.lodgings (id, genba_id, owner_id, name, address, reservation_number)
    values ('10000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'ホテル', '大阪市北区1-2-3', 'RSV-L-1')$$,
  'owner can insert own lodging'
);

-- ---- genba_memos ----------------------------------------------------------
select lives_ok(
  $$insert into public.genba_memos (id, genba_id, owner_id, category, body)
    values ('e0000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'free', '自由メモ')$$,
  'owner can insert own genba_memo'
);

-- ---- setlist_items --------------------------------------------------------
select lives_ok(
  $$insert into public.setlist_items (id, genba_id, owner_id, position, song_title)
    values ('50000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 1, 'オープニング')$$,
  'owner can insert own setlist_item'
);

-- ---- goods_items ----------------------------------------------------------
select lives_ok(
  $$insert into public.goods_items (id, genba_id, owner_id, name)
    values ('90000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'ペンライト')$$,
  'owner can insert own goods_item'
);

-- ---- visited_places -------------------------------------------------------
select lives_ok(
  $$insert into public.visited_places (id, genba_id, owner_id, name, category)
    values ('40000000-0000-0000-0000-000000000001',
            'a1111111-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'カフェ', 'food')$$,
  'owner can insert own visited_place'
);

-- ---- outbox_operations（正例）---------------------------------------------
select lives_ok(
  $$insert into public.outbox_operations (id, owner_id, entity_table, entity_id, op_type)
    values ('0b000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'transports', 'c1000000-0000-0000-0000-000000000001', 'upsert')$$,
  'owner can record own outbox operation'
);

-- ---- performances（共有マスタ・投稿）--------------------------------------
insert into public.performances (id, group_name, title, venue, event_date, created_by)
values ('9e000000-0000-0000-0000-000000000001', 'グループ', 'マスタ公演', '会場', '2026-08-01',
        '11111111-1111-1111-1111-111111111111');

-- ===========================================================================
-- user2 として: 他人（user1）のデータへ一切到達できないことを検証する
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

-- ---- transports: 別ownerは SELECT/UPDATE/DELETE 不可 + owner迂回不可 --------
select results_eq(
  $$select count(*)::int from public.transports$$,
  $$values (0)$$,
  'other user cannot select transports (reservation_number/place not exposed)'
);
select results_eq(
  $$with u as (update public.transports set memo = 'x'
      where id = 'c1000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update transports'
);
select results_eq(
  $$with d as (delete from public.transports
      where id = 'c1000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete transports'
);
select throws_ok(
  $$insert into public.transports (id, genba_id, owner_id)
    values ('c1000000-0000-0000-0000-000000000099',
            'a1111111-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222')$$,
  'owner_id must match parent genba owner'
);

-- ---- lodgings（address 機微情報の非露出を含む）-----------------------------
select results_eq(
  $$select count(*)::int from public.lodgings$$,
  $$values (0)$$,
  'other user cannot select lodgings (address not exposed)'
);
select results_eq(
  $$with u as (update public.lodgings set memo = 'x'
      where id = '10000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update lodgings'
);
select results_eq(
  $$with d as (delete from public.lodgings
      where id = '10000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete lodgings'
);
select throws_ok(
  $$insert into public.lodgings (id, genba_id, owner_id)
    values ('10000000-0000-0000-0000-000000000099',
            'a1111111-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222')$$,
  'owner_id must match parent genba owner'
);

-- ---- genba_memos ----------------------------------------------------------
select results_eq(
  $$select count(*)::int from public.genba_memos$$,
  $$values (0)$$,
  'other user cannot select genba_memos'
);
select results_eq(
  $$with u as (update public.genba_memos set body = 'x'
      where id = 'e0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update genba_memos'
);
select results_eq(
  $$with d as (delete from public.genba_memos
      where id = 'e0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete genba_memos'
);
select throws_ok(
  $$insert into public.genba_memos (id, genba_id, owner_id, category, body)
    values ('e0000000-0000-0000-0000-000000000099',
            'a1111111-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222', 'notice', '不正')$$,
  'owner_id must match parent genba owner'
);

-- ---- setlist_items --------------------------------------------------------
select results_eq(
  $$select count(*)::int from public.setlist_items$$,
  $$values (0)$$,
  'other user cannot select setlist_items'
);
select results_eq(
  $$with u as (update public.setlist_items set note = 'x'
      where id = '50000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update setlist_items'
);
select results_eq(
  $$with d as (delete from public.setlist_items
      where id = '50000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete setlist_items'
);
select throws_ok(
  $$insert into public.setlist_items (id, genba_id, owner_id, position, song_title)
    values ('50000000-0000-0000-0000-000000000099',
            'a1111111-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222', 2, '不正曲')$$,
  'owner_id must match parent genba owner'
);

-- ---- goods_items ----------------------------------------------------------
select results_eq(
  $$select count(*)::int from public.goods_items$$,
  $$values (0)$$,
  'other user cannot select goods_items'
);
select results_eq(
  $$with u as (update public.goods_items set memo = 'x'
      where id = '90000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update goods_items'
);
select results_eq(
  $$with d as (delete from public.goods_items
      where id = '90000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete goods_items'
);
select throws_ok(
  $$insert into public.goods_items (id, genba_id, owner_id, name)
    values ('90000000-0000-0000-0000-000000000099',
            'a1111111-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222', '不正グッズ')$$,
  'owner_id must match parent genba owner'
);

-- ---- visited_places -------------------------------------------------------
select results_eq(
  $$select count(*)::int from public.visited_places$$,
  $$values (0)$$,
  'other user cannot select visited_places'
);
select results_eq(
  $$with u as (update public.visited_places set memo = 'x'
      where id = '40000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update visited_places'
);
select results_eq(
  $$with d as (delete from public.visited_places
      where id = '40000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete visited_places'
);
select throws_ok(
  $$insert into public.visited_places (id, genba_id, owner_id, name)
    values ('40000000-0000-0000-0000-000000000099',
            'a1111111-0000-0000-0000-000000000001',
            '22222222-2222-2222-2222-222222222222', '不正スポット')$$,
  'owner_id must match parent genba owner'
);

-- ---- outbox_operations（負例）---------------------------------------------
select results_eq(
  $$select count(*)::int from public.outbox_operations$$,
  $$values (0)$$,
  'other user cannot select outbox_operations'
);
select throws_ok(
  $$insert into public.outbox_operations (id, owner_id, entity_table, entity_id, op_type)
    values ('0b000000-0000-0000-0000-000000000099',
            '11111111-1111-1111-1111-111111111111',
            'transports', 'c1000000-0000-0000-0000-000000000001', 'upsert')$$,
  '42501', null,
  'other user cannot insert outbox with foreign owner_id (RLS with check)'
);
select results_eq(
  $$with u as (update public.outbox_operations set op_type = 'delete'
      where id = '0b000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update outbox_operations'
);
select results_eq(
  $$with d as (delete from public.outbox_operations
      where id = '0b000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete outbox_operations'
);

-- ---- profiles -------------------------------------------------------------
-- profiles は handle_new_user トリガーで user1/user2 の分が自動作成される。
select results_eq(
  $$select count(*)::int from public.profiles
    where id = '11111111-1111-1111-1111-111111111111'$$,
  $$values (0)$$,
  'other user cannot select another user profile'
);
select results_eq(
  $$with u as (update public.profiles set display_name = 'x'
      where id = '11111111-1111-1111-1111-111111111111' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update another user profile'
);
-- profiles は DELETE ポリシーを持たない（アカウント削除は auth.users カスケード）。
-- 本人でも直接 DELETE できないことを明示する。
select results_eq(
  $$with d as (delete from public.profiles
      where id = '22222222-2222-2222-2222-222222222222' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'profiles has no delete policy: even owner cannot delete own profile row'
);

-- ---- performances（共有マスタ）--------------------------------------------
-- 認証ユーザーは共有マスタを SELECT できる（§10.3 公開）。
select results_eq(
  $$select count(*)::int from public.performances
    where id = '9e000000-0000-0000-0000-000000000001'$$,
  $$values (1)$$,
  'any authenticated user can select shared performances'
);
-- 非投稿者は更新できない（0行）。
select results_eq(
  $$with u as (update public.performances set title = '改ざん'
      where id = '9e000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'non-creator cannot update performance'
);
-- 非投稿者は削除できない（DELETEポリシー無し → 0行）。
select results_eq(
  $$with d as (delete from public.performances
      where id = '9e000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'non-creator cannot delete performance (no delete policy)'
);

-- ===========================================================================
-- user1（投稿者）へ戻る: 更新はできるが DELETE は意図的に不可（F-1）
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);
select lives_ok(
  $$update public.performances set title = '更新後'
    where id = '9e000000-0000-0000-0000-000000000001'$$,
  'creator can update own performance'
);
-- 投稿者本人でも DELETE できない（共有マスタの削除・統合は後続のモデレーション
-- 機能で扱う, decisions.md R8-B節）。DELETE ポリシーが無いため 0 行。
select results_eq(
  $$with d as (delete from public.performances
      where id = '9e000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'creator cannot delete own performance (intentional: no delete policy, F-1)'
);

select * from finish();
rollback;
