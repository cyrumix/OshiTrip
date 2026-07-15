-- pgTAP: フレンドコード（0033）
--
-- 検証:
-- - friend_code は一意（全プロフィールで重複なし）
-- - 既存/新規ユーザーにも friend_code が入る（NOT NULL・トリガ採番）
-- - 形式は OSHI-XXXX-XXXX（読みやすい英数字）
-- - コード完全一致で申請できる（pending 行が作られる）
-- - searchable=false の相手でもコードを知っていれば申請できる
-- - 自分自身のコードは拒否
-- - 存在しないコード・空文字は拒否
-- - 既存の同一現場メンバー経由申請（send_friend_request）は壊れていない
-- - 無制限検索禁止は維持（非searchable・非メンバーへの uuid 申請は拒否）
--
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(13);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'u1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'u2@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'u3@example.com'),
  ('44444444-4444-4444-4444-444444444444', 'u4@example.com'),
  ('55555555-5555-5555-5555-555555555555', 'u5@example.com');

-- 認証切替ヘルパは authenticated に CREATE 権限が無いため role 変更前に作る。
create or replace function _as(uid text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- コードは本人しか SELECT できない（RLS）ため、スーパーユーザーのうちに退避する。
create temporary table _codes (name text primary key, code text);
grant all on _codes to authenticated;
insert into _codes values
  ('u1', (select friend_code from public.profiles
            where id = '11111111-1111-1111-1111-111111111111')),
  ('u2', (select friend_code from public.profiles
            where id = '22222222-2222-2222-2222-222222222222'));

-- ---------------------------------------------------------------------------
-- 1) friend_code は全員に入っている（NOT NULL / トリガ採番）
-- ---------------------------------------------------------------------------
select results_eq(
  $$select count(*)::int from public.profiles where friend_code is null$$,
  $$values (0)$$, 'every profile has a friend_code (auto-assigned)');

-- 2) friend_code は一意
select results_eq(
  $$select (count(*) = count(distinct friend_code))::boolean
      from public.profiles$$,
  $$values (true)$$, 'friend_code is unique across profiles');

-- 3) 生成された friend_code は期待形式 OSHI-XXXX-XXXX（0/1/I/O を含まない）に一致
select ok(
  (select friend_code ~ '^OSHI-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$'
     from public.profiles
     where id = '11111111-1111-1111-1111-111111111111'),
  'generated friend_code matches the expected format');

-- 3b) 不正な形式の friend_code は CHECK 制約で拒否される（サーバー採番専用の担保）。
--     自動採番トリガは非 null 値をそのまま通すため、直接 INSERT した不正値は
--     形式 CHECK が弾く（ここはスーパーユーザー実行）。
delete from public.profiles where id = '55555555-5555-5555-5555-555555555555';
select throws_ok(
  $$insert into public.profiles (id, friend_code)
      values ('55555555-5555-5555-5555-555555555555', 'not-a-code')$$,
  '23514', null, 'invalid friend_code format is rejected by the CHECK');

-- u2 は searchable=false（既定）。u3 と現場を共有させる（メンバー経由申請の回帰用）。
set local role authenticated;
select _as('11111111-1111-1111-1111-111111111111');
insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111', 'A', 'T', '2026-08-01');
insert into public.genba_shares (id, owner_id, genba_id, grantee_id, role)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '33333333-3333-3333-3333-333333333333', 'viewer');

-- ---------------------------------------------------------------------------
-- 4) コード完全一致で申請できる（u2 は searchable=false でもコードなら可）
-- ---------------------------------------------------------------------------
select is(
  (public.send_friend_request_by_code(
    (select code from _codes where name = 'u2')) ->> 'status'),
  'pending', 'by-code request to a non-searchable user succeeds (pending)');

-- 5) u1 -> u2 の pending 行が作られている
select results_eq(
  $$select status from public.friendships
      where requester_id = '11111111-1111-1111-1111-111111111111'
        and receiver_id = '22222222-2222-2222-2222-222222222222'$$,
  $$values ('pending')$$, 'by-code request creates the pending friendship');

-- 5b) authenticated ユーザーは自分の friend_code を直接変更できない（immutable トリガ）。
select throws_ok(
  $$update public.profiles set friend_code = 'OSHI-ZZZZ-ZZZZ'
      where id = '11111111-1111-1111-1111-111111111111'$$,
  '42501', null,
  'authenticated user cannot update own friend_code directly');

-- 6) 自分自身のコードは拒否
select throws_ok(
  $$select public.send_friend_request_by_code(
      (select code from _codes where name = 'u1'))$$,
  '22023', null, 'own friend code is rejected');

-- 7) 存在しないコードは拒否
select throws_ok(
  $$select public.send_friend_request_by_code('OSHI-ZZZZ-ZZZZ')$$,
  '22023', null, 'nonexistent friend code is rejected');

-- 8) 空文字のコードは拒否
select throws_ok(
  $$select public.send_friend_request_by_code('   ')$$,
  '22023', null, 'blank friend code is rejected');

-- ---------------------------------------------------------------------------
-- 9) 無制限検索禁止は維持: 非searchable・非メンバーへの uuid 申請は拒否
-- ---------------------------------------------------------------------------
select throws_ok(
  $$select public.send_friend_request(
      '44444444-4444-4444-4444-444444444444')$$,
  '42501', null,
  'uuid request to a non-searchable non-member is still rejected');

-- ---------------------------------------------------------------------------
-- 10/11) 既存の同一現場メンバー経由申請は壊れていない（regression）
-- ---------------------------------------------------------------------------
select is(
  (public.send_friend_request(
    '33333333-3333-3333-3333-333333333333') ->> 'status'),
  'pending', 'member-based send_friend_request still works');
select results_eq(
  $$select status from public.friendships
      where requester_id = '11111111-1111-1111-1111-111111111111'
        and receiver_id = '33333333-3333-3333-3333-333333333333'$$,
  $$values ('pending')$$, 'member-based request creates the pending friendship');

select * from finish();
rollback;
