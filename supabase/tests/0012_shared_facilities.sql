-- pgTAP: 権利確認済み共有施設基盤（旅程Phase 3 / 0022 / itinerary-plan-spec §4.3）
--
-- - owner 別下書き（draft）から始まり、承認（approved）は service role のみ
-- - data_origin は 4 種のみ（'google' 等は CHECK で拒否）
-- - 承認済み（共有）には rights_basis が必須
-- - 承認済みは他ユーザーも閲覧可、下書き/pending は本人のみ
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(9);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'u1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'u2@example.com');

-- ===========================================================================
-- user1: 自分の下書きを作成・提出できる
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

-- 1) 本人は下書きを作成できる
select lives_ok(
  $$insert into public.shared_facilities (id, created_by, name, data_origin)
    values ('f0000000-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '会場前カフェ', 'user_provided')$$,
  'owner can insert own draft'
);

-- 2) data_origin は 4 種のみ（Google 応答を出典にできない）
select throws_ok(
  $$insert into public.shared_facilities (id, created_by, name, data_origin)
    values ('f0000000-0000-0000-0000-0000000000f9',
            '11111111-1111-1111-1111-111111111111', 'X', 'google')$$,
  '23514',
  'invalid data_origin (e.g. google) is rejected by check constraint'
);

-- 3) 一般ユーザーは自己承認できない（service role 限定）
select throws_ok(
  $$update public.shared_facilities
      set moderation_status = 'approved', rights_basis = 'r'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'moderation transition requires service role',
  'user cannot self-approve to shared'
);

-- 4) 本人は draft→pending（提出）できる
select lives_ok(
  $$update public.shared_facilities set moderation_status = 'pending'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'owner can submit own draft to pending'
);

-- 承認なし判定用にもう1件（本人が作成）
insert into public.shared_facilities (id, created_by, name, data_origin)
values ('f0000000-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111', '別の下書き', 'user_provided');

-- ===========================================================================
-- user2: 他人の下書き/pending は見えない・消せない
-- ===========================================================================
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

-- 5) 他ユーザーの下書き/pending は SELECT できない
select results_eq(
  $$select count(*)::int from public.shared_facilities
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  $$values (0)$$,
  'other user cannot see draft/pending facility'
);

-- 6) 他ユーザーの下書きは削除できない（0行）
select results_eq(
  $$with d as (
      delete from public.shared_facilities
        where id = 'f0000000-0000-0000-0000-000000000002' returning 1)
    select count(*)::int from d$$,
  $$values (0)$$,
  'other user cannot delete another user draft'
);

-- ===========================================================================
-- service role（モデレーション）: auth.uid() が null になる文脈
-- ===========================================================================
reset role;
set local role postgres;
select set_config('request.jwt.claims', null, true);

-- 7) rights_basis 付きで承認できる
select lives_ok(
  $$update public.shared_facilities
      set moderation_status = 'approved', rights_basis = '施設提供の掲載許諾あり'
    where id = 'f0000000-0000-0000-0000-000000000001'$$,
  'service role can approve with rights_basis'
);

-- 8) rights_basis 無しの承認は拒否される
select throws_ok(
  $$update public.shared_facilities set moderation_status = 'approved'
    where id = 'f0000000-0000-0000-0000-000000000002'$$,
  'approve without rights_basis is rejected'
);

-- ===========================================================================
-- user2 へ戻る: 承認済み（共有）は他ユーザーも閲覧できる
-- ===========================================================================
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}',
  true
);

-- 9) 承認済みは他ユーザーから閲覧できる
select results_eq(
  $$select count(*)::int from public.shared_facilities
    where id = 'f0000000-0000-0000-0000-000000000001'
      and moderation_status = 'approved'$$,
  $$values (1)$$,
  'approved shared facility is visible to any authenticated user'
);

select * from finish();
rollback;
