-- pgTAP: 画像基調UIデータ契約の制約・認可検証（H-05 / design-spec §12.1）
begin;

create extension if not exists pgtap with schema extensions;

select plan(15);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 現場: attendance_status は既定 planned
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演', '2026-06-01');

select results_eq(
  $$select attendance_status from public.genbas
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  $$values ('planned')$$,
  'attendance_status defaults to planned'
);

-- 不正な attendance_status は check で拒否
select throws_ok(
  $$update public.genbas set attendance_status = 'went'
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  '23514',
  null,
  'invalid attendance_status is rejected by check constraint'
);

-- attended へは明示更新できる
select lives_ok(
  $$update public.genbas set attendance_status = 'attended'
    where id = 'aaaaaaaa-0000-0000-0000-000000000001'$$,
  'attendance_status can be set to attended explicitly'
);

-- 思い出: is_favorite は既定 false
insert into public.memory_entries (id, genba_id, owner_id, impression)
values ('eeeeeeee-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '最高だった');

select results_eq(
  $$select is_favorite from public.memory_entries
    where id = 'eeeeeeee-0000-0000-0000-000000000001'$$,
  $$values (false)$$,
  'memory_entries.is_favorite defaults to false'
);

-- 表紙: 同一現場で cover は最大1件（部分ユニークインデックス）
insert into public.memory_photos (id, genba_id, owner_id, is_cover)
values ('cccccccc-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', true);

select throws_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, is_cover)
    values ('cccccccc-0000-0000-0000-000000000002',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', true)$$,
  '23505',
  null,
  'a genba can have at most one cover photo (partial unique index)'
);

-- 非 cover は複数可
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, is_cover)
    values ('cccccccc-0000-0000-0000-000000000003',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', false)$$,
  'multiple non-cover photos are allowed'
);

-- 推しグループ + メンバー + 記念日（owner=user1）
insert into public.oshi_groups (id, owner_id, name, is_favorite)
values ('ffffffff-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '推しグループ', true);

insert into public.oshi_members (id, group_id, owner_id, name)
values ('88888888-0000-0000-0000-000000000001',
        'ffffffff-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'メンバーA');

select lives_ok(
  $$insert into public.oshi_anniversaries
      (id, owner_id, group_id, member_id, label, "date")
    values ('dddddddd-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111',
            'ffffffff-0000-0000-0000-000000000001',
            '88888888-0000-0000-0000-000000000001', '結成記念日', '2020-04-01')$$,
  'owner can insert anniversary tied to own group/member'
);

-- 記念日: 親グループ経由の所有権迂回防止（owner_id が親と不一致は拒否）
select throws_ok(
  $$insert into public.oshi_anniversaries
      (id, owner_id, group_id, label, "date")
    values ('dddddddd-0000-0000-0000-000000000009',
            '22222222-2222-2222-2222-222222222222',
            'ffffffff-0000-0000-0000-000000000001', '不正記念日', '2021-01-01')$$,
  'owner_id must match parent group owner'
);

-- ----------------------------------------------------------------------------
-- 記念日: member_id の親子整合（R6再レビュー: enforce_oshi_anniversary_owner の
-- メンバー整合チェックを、同一owner・別グループの場合と別ownerの場合の
-- 両方について個別のfixtureで検証する）
-- ----------------------------------------------------------------------------

-- ケース1: 同一owner（user1）だが別グループに所属するmember_idは拒否される。
insert into public.oshi_groups (id, owner_id, name)
values ('ffffffff-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', '別グループ');
insert into public.oshi_members (id, group_id, owner_id, name)
values ('88888888-0000-0000-0000-000000000002',
        'ffffffff-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', 'メンバーB');

select throws_ok(
  $$insert into public.oshi_anniversaries
      (id, owner_id, group_id, member_id, label, "date")
    values ('dddddddd-0000-0000-0000-000000000002',
            '11111111-1111-1111-1111-111111111111',
            'ffffffff-0000-0000-0000-000000000001',
            '88888888-0000-0000-0000-000000000002', '別グループ記念日', '2021-01-01')$$,
  'P0001',
  'member does not belong to the group',
  'member_id belonging to a different group of the same owner is rejected'
);

-- ケース2: 別owner（user2）が所有するmember_idは拒否される。
-- user2自身のグループ・メンバーを、一時的にuser2として作成する。
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);
insert into public.oshi_groups (id, owner_id, name)
values ('ffffffff-0000-0000-0000-000000000003',
        '22222222-2222-2222-2222-222222222222', 'user2のグループ');
insert into public.oshi_members (id, group_id, owner_id, name)
values ('88888888-0000-0000-0000-000000000003',
        'ffffffff-0000-0000-0000-000000000003',
        '22222222-2222-2222-2222-222222222222', 'user2のメンバー');

-- user1へ戻り、自分のグループへ user2 のメンバーを紐づけようとする。
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select throws_ok(
  $$insert into public.oshi_anniversaries
      (id, owner_id, group_id, member_id, label, "date")
    values ('dddddddd-0000-0000-0000-000000000003',
            '11111111-1111-1111-1111-111111111111',
            'ffffffff-0000-0000-0000-000000000001',
            '88888888-0000-0000-0000-000000000003', '侵入記念日', '2021-01-01')$$,
  'P0001',
  'member does not belong to the group',
  'member_id owned by a different user is rejected'
);

-- ----------------------------------------------------------------------------
-- oshi_member 削除: 記念日レコードは残り member_id が null になる
-- （member_id ... on delete set null）
-- ----------------------------------------------------------------------------
insert into public.oshi_members (id, group_id, owner_id, name)
values ('88888888-0000-0000-0000-000000000004',
        'ffffffff-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'メンバーC');
insert into public.oshi_anniversaries
    (id, owner_id, group_id, member_id, label, "date")
values ('dddddddd-0000-0000-0000-000000000004',
        '11111111-1111-1111-1111-111111111111',
        'ffffffff-0000-0000-0000-000000000001',
        '88888888-0000-0000-0000-000000000004', 'メンバーC記念日', '2022-01-01');

delete from public.oshi_members
  where id = '88888888-0000-0000-0000-000000000004';

select results_eq(
  $$select member_id from public.oshi_anniversaries
    where id = 'dddddddd-0000-0000-0000-000000000004'$$,
  $$values (null::uuid)$$,
  'deleting a member keeps the anniversary but nulls member_id (on delete set null)'
);

-- ----------------------------------------------------------------------------
-- oshi_group 削除: そのグループの記念日も端末（サーバー）から削除される
-- （group_id ... on delete cascade）
-- ----------------------------------------------------------------------------
insert into public.oshi_groups (id, owner_id, name)
values ('ffffffff-0000-0000-0000-000000000004',
        '11111111-1111-1111-1111-111111111111', '削除予定グループ');
insert into public.oshi_anniversaries (id, owner_id, group_id, label, "date")
values ('dddddddd-0000-0000-0000-000000000005',
        '11111111-1111-1111-1111-111111111111',
        'ffffffff-0000-0000-0000-000000000004', '削除予定記念日', '2022-02-02');

delete from public.oshi_groups
  where id = 'ffffffff-0000-0000-0000-000000000004';

select results_eq(
  $$select count(*)::int from public.oshi_anniversaries
    where group_id = 'ffffffff-0000-0000-0000-000000000004'$$,
  $$values (0)$$,
  'deleting a group cascades deletion of its anniversaries'
);

-- user2 視点: 他ユーザーの記念日は読めない・更新できない
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

select results_eq(
  $$select count(*)::int from public.oshi_anniversaries$$,
  $$values (0)$$,
  'other user cannot read anniversaries'
);

select results_eq(
  $$with u as (
      update public.oshi_anniversaries set label = '改ざん'
      where id = 'dddddddd-0000-0000-0000-000000000001'
      returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update anniversaries'
);

-- 他ユーザーは cover 一意インデックスの影響も受けない（自分の現場を作れる）
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-0000-0000-0000-000000000002',
        '22222222-2222-2222-2222-222222222222', 'B', 'B公演', '2026-07-01');
select lives_ok(
  $$insert into public.memory_photos (id, genba_id, owner_id, is_cover)
    values ('cccccccc-0000-0000-0000-000000000010',
            'aaaaaaaa-0000-0000-0000-000000000002',
            '22222222-2222-2222-2222-222222222222', true)$$,
  'cover uniqueness is per-genba, not global (other user unaffected)'
);

select * from finish();
rollback;
