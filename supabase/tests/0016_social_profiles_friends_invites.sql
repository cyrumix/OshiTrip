-- pgTAP: 社会機能データ基盤（profiles / friendships / genba_invites, 0030）
--
-- 追加要件 §7/§10 のセキュリティを検証する:
-- - owner だけが招待URLを発行・無効化できる
-- - token が正しい場合のみ参加できる（revoked/expired/max_uses を守る）
-- - 参加時に genba_shares が作成される・重複参加しない
-- - フレンド申請は本人のみ作成/更新できる（無制限検索禁止の許可条件）
-- - 他人のプロフィールを編集できない・可視範囲が限定される
--
-- 実行: supabase start → supabase db reset → supabase test db
-- 2026-07-13: ローカル Supabase（Docker）で実行し plan(20) 全通過を確認（D-248）。
-- profiles の主キーは id（handle_new_user が自動作成）。本テストは id 基準で upsert する。
begin;

create extension if not exists pgtap with schema extensions;

select plan(20);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'friend@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'searchable@example.com'),
  ('44444444-4444-4444-4444-444444444444', 'joiner@example.com'),
  ('55555555-5555-5555-5555-555555555555', 'stranger@example.com');

create temporary table _t (name text primary key, token text);
-- テスト内で role を authenticated に切り替えて token を退避するため、この
-- セッション一時表への権限を authenticated へ付与する（pg_temp は 0032 の
-- public 付与の対象外のため個別に付与, D-248）。
grant all on _t to authenticated;

set local role authenticated;

-- ---- owner (u1): 現場・自分のプロフィール・招待を用意 --------------------------
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);

insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111', 'A', 'T', '2026-08-01');

-- profiles は 0001 の handle_new_user トリガで auth.users 作成時に id だけの行が
-- 自動作成される。主キーは id。ここでは重複 insert ではなく本人が自分の行を
-- 更新する（upsert on conflict id, D-248）。
insert into public.profiles (id, display_name)
values ('11111111-1111-1111-1111-111111111111', 'Owner')
on conflict (id) do update set display_name = excluded.display_name;

-- ---- u2/u3: 自分のプロフィール（u3 は searchable=true）--------------------------
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
insert into public.profiles (id, display_name, searchable)
values ('22222222-2222-2222-2222-222222222222', 'Friend', false)
on conflict (id) do update
  set display_name = excluded.display_name, searchable = excluded.searchable;

select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);
insert into public.profiles (id, display_name, searchable)
values ('33333333-3333-3333-3333-333333333333', 'Searchable', true)
on conflict (id) do update
  set display_name = excluded.display_name, searchable = excluded.searchable;

-- ===========================================================================
-- 招待URL: owner のみ発行、参加は token 検証つき
-- ===========================================================================

-- 1) 非owner は招待を発行できない
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select throws_ok(
  $$select public.create_genba_invite('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','viewer')$$,
  '42501', null, 'only owner can create an invite');

-- owner が招待を発行（token を _t へ退避）
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
insert into _t(name, token) select 'main',
  (public.create_genba_invite('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','viewer'))->>'token';

-- 2) owner は招待を発行できた（token が返る）
select ok((select token is not null from _t where name = 'main'),
  'owner can create an invite (token returned)');

-- 3) grantee (u2) は有効な token で参加できる
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select is(
  (public.join_genba_via_invite((select token from _t where name='main')))->>'status',
  'joined', 'valid token joins the genba');

-- 4) 参加で genba_shares 行が作成される
select results_eq(
  $$select count(*)::int from public.genba_shares
      where genba_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        and grantee_id = '22222222-2222-2222-2222-222222222222'$$,
  $$values (1)$$, 'join creates a genba_shares row');

-- 5) 参加済みが同じ URL を再度開いても重複追加しない
select is(
  (public.join_genba_via_invite((select token from _t where name='main')))->>'status',
  'already_member', 're-opening the same invite does not re-join');

-- 6) genba_shares は重複しない
select results_eq(
  $$select count(*)::int from public.genba_shares
      where genba_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        and grantee_id = '22222222-2222-2222-2222-222222222222'$$,
  $$values (1)$$, 'no duplicate share on re-join');

-- 7) used_count は新規参加ぶんだけ増える（再訪では増えない）
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select results_eq(
  $$select used_count from public.genba_invites
      where token = (select token from _t where name='main')$$,
  $$values (1::integer)$$, 'used_count only counts new joins');

-- 8) 非owner は無効化できない
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select throws_ok(
  $$select public.revoke_genba_invite(
      (select id from public.genba_invites where token=(select token from _t where name='main')))$$,
  '42501', null, 'only owner can revoke an invite');

-- 9) owner は無効化できる
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select lives_ok(
  $$select public.revoke_genba_invite(
      (select id from public.genba_invites where token=(select token from _t where name='main')))$$,
  'owner can revoke an invite');

-- 10) 無効化済みの token では参加できない
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);
select throws_ok(
  $$select public.join_genba_via_invite((select token from _t where name='main'))$$,
  '42501', 'invite_revoked', 'revoked invite cannot be used');

-- 期限切れ招待を用意
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
insert into _t(name, token) select 'expired',
  (public.create_genba_invite('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','viewer',
    now() - interval '1 hour'))->>'token';

-- 11) 期限切れの token では参加できない
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);
select throws_ok(
  $$select public.join_genba_via_invite((select token from _t where name='expired'))$$,
  '42501', 'invite_expired', 'expired invite cannot be used');

-- max_uses=1 の招待を用意
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
insert into _t(name, token) select 'max1',
  (public.create_genba_invite('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','viewer',
    null, 1))->>'token';

-- 12) 1人目（u4）は参加できる
select set_config('request.jwt.claims',
  '{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated"}', true);
select is(
  (public.join_genba_via_invite((select token from _t where name='max1')))->>'status',
  'joined', 'first join within max_uses succeeds');

-- 13) max_uses 超過（u5）は参加できない
select set_config('request.jwt.claims',
  '{"sub":"55555555-5555-5555-5555-555555555555","role":"authenticated"}', true);
select throws_ok(
  $$select public.join_genba_via_invite((select token from _t where name='max1'))$$,
  '42501', 'invite_exhausted', 'join beyond max_uses is rejected');

-- ===========================================================================
-- フレンド: 本人のみ操作・許可条件（searchable または 同一現場メンバー）
-- ===========================================================================

-- 14) u1 は searchable な u3 へ申請できる（pending）
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select is(
  (public.send_friend_request('33333333-3333-3333-3333-333333333333'))->>'status',
  'pending', 'can request a searchable user');

-- 15) 受信者でない者は申請へ応答できない
select throws_ok(
  $$select public.respond_friend_request(
      (select id from public.friendships
        where requester_id='11111111-1111-1111-1111-111111111111'
          and receiver_id='33333333-3333-3333-3333-333333333333'), true)$$,
  '42501', null, 'non-receiver cannot respond to a request');

-- 16) 受信者 u3 は承認できる
select set_config('request.jwt.claims',
  '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}', true);
select is(
  (public.respond_friend_request(
    (select id from public.friendships
      where requester_id='11111111-1111-1111-1111-111111111111'
        and receiver_id='33333333-3333-3333-3333-333333333333'), true))->>'status',
  'accepted', 'receiver can accept a request');

-- 17) searchable でも同一現場メンバーでもない相手へは申請できない（無制限検索禁止）
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}', true);
select throws_ok(
  $$select public.send_friend_request('55555555-5555-5555-5555-555555555555')$$,
  '42501', 'not allowed to request this user',
  'cannot request a non-searchable non-comember user');

-- ===========================================================================
-- プロフィール: 可視範囲と本人限定編集
-- ===========================================================================

-- 18) searchable なユーザーのプロフィールは見える
select ok(public.can_view_profile('33333333-3333-3333-3333-333333333333'),
  'can view a searchable profile');

-- 19) 無関係（非searchable・非フレンド・非メンバー）のプロフィールは見えない
select ok(not public.can_view_profile('55555555-5555-5555-5555-555555555555'),
  'cannot view an unrelated profile');

-- 20) 他人のプロフィールは編集できない（本人限定 = 0行更新）
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}', true);
select results_eq(
  $$with u as (
      update public.profiles set display_name = 'HACK'
        where id = '11111111-1111-1111-1111-111111111111' returning 1)
    select count(*)::int from u$$,
  $$values (0)$$, 'cannot edit another user''s profile');

select * from finish();
rollback;
