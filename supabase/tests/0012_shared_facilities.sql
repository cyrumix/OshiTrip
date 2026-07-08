-- pgTAP: 共有施設基盤＋モデレーション境界（旅程Phase 3 / 0022 + 0024）
--
-- - owner 別下書き→承認。data_origin は4種のみ、承認は rights_basis 必須。
-- - 投稿者は自分の draft を更新・削除できるが、approved は変更・削除・差し戻し
--   できない（Fix1）。service_role のみが承認・approved の修正を行える。
-- - 承認済みは他ユーザーも閲覧できるが変更・削除できない。
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(16);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'u1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'u2@example.com');

-- ===========================================================================
-- user1
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 1) 本人は下書きを作成できる（F1）
select lives_ok(
  $$insert into public.shared_facilities (id, created_by, name, data_origin)
    values ('f0000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '会場前カフェ', 'user_provided')$$,
  'owner can insert own draft'
);

-- 承認なし/削除テスト用の下書き F2（プレーン insert）
insert into public.shared_facilities (id, created_by, name, data_origin)
values ('f0000000-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', '別の下書き', 'user_provided');

-- 2) data_origin は4種のみ（Google 応答を出典にできない）
select throws_ok(
  $$insert into public.shared_facilities (id, created_by, name, data_origin)
    values ('f0000000-0000-0000-0000-0000000000f9',
            '11111111-1111-1111-1111-111111111111', 'X', 'google')$$,
  '23514',
  'invalid data_origin (e.g. google) is rejected'
);

-- 3) 投稿者は自分の draft を更新できる（Fix1 追加#1）
select lives_ok(
  $$update public.shared_facilities set name = '会場前カフェ（改称）'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'creator can update own draft'
);

-- 4) 一般ユーザーは自己承認できない（service role 限定）
select throws_ok(
  $$update public.shared_facilities
      set moderation_status = 'approved', rights_basis = 'r'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'moderation transition requires service role',
  'user cannot self-approve'
);

-- 5) 本人は draft→pending（提出）できる
select lives_ok(
  $$update public.shared_facilities set moderation_status = 'pending'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'owner can submit own draft to pending'
);

-- ===========================================================================
-- user2: 他人の下書き/pending は不可視・不可削除
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

-- 6) 他ユーザーの pending は SELECT できない
select results_eq(
  $$select count(*)::int from public.shared_facilities
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  $$values (0)$$,
  'other user cannot see pending facility'
);

-- 7) 他ユーザーは他人の draft を削除できない（0行）
select results_eq(
  $$with d as (
      delete from public.shared_facilities
        where id = 'f0000000-0000-0000-0000-000000000002' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete another user draft'
);

-- ===========================================================================
-- service role（モデレーション）
-- ===========================================================================
reset role;
set local role postgres;
select set_config('request.jwt.claims', null, true);

-- 8) rights_basis 付きで承認できる（Fix1 追加#5）
select lives_ok(
  $$update public.shared_facilities
      set moderation_status = 'approved', rights_basis = '施設提供の掲載許諾あり'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'service role can approve with rights_basis'
);

-- 9) rights_basis 無しの承認は拒否される
select throws_ok(
  $$update public.shared_facilities set moderation_status = 'approved'
    where id = 'f0000000-0000-0000-0000-000000000002'$$,
  'approve without rights_basis is rejected'
);

-- 10) service_role は approved を修正できる（Fix1 追加#5）
select lives_ok(
  $$update public.shared_facilities set name = '会場前カフェ（公式表記）'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'service role can manage (update) approved facility'
);

-- ===========================================================================
-- user1（投稿者）: approved は変更・差し戻し・削除できない
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 11) 投稿者は approved を更新できない（RLS USING で対象外 → 0行, Fix1 追加#2）
select results_eq(
  $$with u as (
      update public.shared_facilities set name = 'X'
        where id = 'f0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'creator cannot update approved facility'
);

-- 12) 投稿者は approved を pending へ戻せない（0行, Fix1 追加#3）
select results_eq(
  $$with u as (
      update public.shared_facilities set moderation_status = 'pending'
        where id = 'f0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'creator cannot revert approved to pending'
);

-- 13) 投稿者は approved を削除できない（0行, Fix1 追加#4）
select results_eq(
  $$with d as (
      delete from public.shared_facilities
        where id = 'f0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'creator cannot delete approved facility'
);

-- ===========================================================================
-- user2: approved は閲覧できるが変更・削除できない（Fix1 追加#6）
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

-- 14) 承認済みは他ユーザーから閲覧できる
select results_eq(
  $$select count(*)::int from public.shared_facilities
    where id = 'f0000000-0000-0000-0000-000000000001'
      and moderation_status = 'approved'$$,
  $$values (1)$$,
  'approved facility is visible to any authenticated user'
);

-- 15) 他ユーザーは承認済みを更新できない（0行）
select results_eq(
  $$with u as (
      update public.shared_facilities set name = 'Y'
        where id = 'f0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$,
  'other user cannot update approved facility'
);

-- 16) 他ユーザーは承認済みを削除できない（0行）
select results_eq(
  $$with d as (
      delete from public.shared_facilities
        where id = 'f0000000-0000-0000-0000-000000000001' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete approved facility'
);

select * from finish();
rollback;
