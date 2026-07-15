-- pgTAP: 共有施設基盤＋モデレーション境界（旅程Phase 3 / 0022 + 0024 + 0025）
--
-- - owner 別下書き→承認。data_origin は4種のみ、承認は rights_basis 必須。
-- - 新規登録（INSERT）は一般ユーザーなら必ず draft から開始する（0025。pending/
--   approved/rejected を直接 INSERT できない）。
-- - 投稿者は自分の draft を更新・削除できるが、approved は変更・削除・差し戻し
--   できない（Fix1）。service_role のみが承認・approved の修正を行える。
-- - 承認済みは他ユーザーも閲覧できるが変更・削除できない。
--
-- service_role の検証は実際に `set local role service_role;` で実行する
-- （postgres 超権限によるバイパスではなく、本番と同じ service_role の
-- BYPASSRLS 属性による経路を検証する）。ロール切り替え自体は postgres
-- （session_user、superuser）でなければ行えないため、その準備と
-- service_role としての動作検証は明確に分離してコメントする。
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(20);

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

-- ---------------------------------------------------------------------------
-- 0025: 新規登録は必ず draft から開始する（moderation_status='draft' 必須）
-- ---------------------------------------------------------------------------

-- 1b) moderation_status を明示的に 'draft' としても新規登録できる
select lives_ok(
  $$insert into public.shared_facilities
      (id, created_by, name, data_origin, moderation_status)
    values ('f0000000-0000-0000-0000-000000000010',
            '11111111-1111-1111-1111-111111111111', '検証用ドラフト',
            'user_provided', 'draft')$$,
  'authenticated user insert with explicit moderation_status=draft succeeds'
);

-- 1c) 一般ユーザーが pending を直接 INSERT すると拒否される
--     （BEFORE トリガが RLS WITH CHECK より先に発火するため、トリガの
--     例外メッセージで検知する。RLS の WITH CHECK も同条件で独立に拒否する）。
select throws_ok(
  $$insert into public.shared_facilities
      (id, created_by, name, data_origin, moderation_status)
    values ('f0000000-0000-0000-0000-000000000011',
            '11111111-1111-1111-1111-111111111111', '直接pending',
            'user_provided', 'pending')$$,
  'new shared facility must start as draft',
  'authenticated user cannot insert directly as pending (trigger + RLS)'
);

-- 1d) draft(.010) → pending の正規申請（UPDATE）は引き続き成功する
select lives_ok(
  $$update public.shared_facilities set moderation_status = 'pending'
    where id = 'f0000000-0000-0000-0000-000000000010'$$,
  'draft to pending submission still works after insert hardening'
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
  '23514', null,
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
-- postgres 権限が必要な準備（役割切り替えのみ）
--   `reset role` はセッション既定（postgres, superuser）へ戻す操作であり、
--   NOLOGIN ロールである service_role への `SET ROLE` は superuser（または
--   service_role のメンバー）でなければ行えない。ここでは役割切り替えの
--   準備だけを行い、業務ロジックの検証は一切含めない。
-- ===========================================================================
reset role;
set local role service_role;
select set_config('request.jwt.claims', null, true);

-- ===========================================================================
-- service_role の動作検証（以降は実際に service_role として実行する）
--   postgres の superuser 属性ではなく、service_role 自身の BYPASSRLS 属性
--   による RLS バイパスを検証する（本番の Edge Function 呼び出しと同じ経路）。
-- ===========================================================================

-- 0025 追加) service_role は管理／移行のため、任意の moderation_status で
-- 直接 INSERT できる（draft-only 制限は一般ユーザーのみに適用される）。
select lives_ok(
  $$insert into public.shared_facilities
      (id, created_by, name, data_origin, moderation_status, rights_basis)
    values ('f0000000-0000-0000-0000-000000000012',
            '11111111-1111-1111-1111-111111111111', '移行データ', 'licensed',
            'approved', '契約データの一括移行')$$,
  'service_role can insert facility directly at any moderation_status (e.g. approved) for admin/migration use'
);

-- 8) rights_basis 付きで承認できる（Fix1 追加#5）
select lives_ok(
  $$update public.shared_facilities
      set moderation_status = 'approved', rights_basis = '施設提供の掲載許諾あり'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'service_role can approve with rights_basis'
);

-- 9) rights_basis 無しの承認は拒否される（承認ガードの raise = P0001）。
select throws_ok(
  $$update public.shared_facilities set moderation_status = 'approved'
    where id = 'f0000000-0000-0000-0000-000000000002'$$,
  'P0001', null,
  'approve without rights_basis is rejected'
);

-- 10) service_role は approved を修正できる（Fix1 追加#5）
select lives_ok(
  $$update public.shared_facilities set name = '会場前カフェ（公式表記）'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'service_role can manage (update) approved facility'
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
