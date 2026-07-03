-- pgTAP: apply_mutation RPC の原子的CAS・冪等・owner矯正・列default検証（H-02）
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(24);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

set local role authenticated;

create or replace function _as(uid text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

select _as('11111111-1111-1111-1111-111111111111');

-- ---------------------------------------------------------------------------
-- 新規 INSERT: applied / version=1 / 欠落列はDB default
--   payload に transport_requirement を含めない → default 'unknown' になる
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000001',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'artist_name', 'A', 'title', 'T', 'event_date', '2026-08-01'
    ),
    null
  ) ->> 'status'),
  'applied',
  'new insert applies'
);

select is(
  (select version from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1::bigint,
  'version starts at 1'
);

select is(
  (select transport_requirement from public.genbas
   where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  'unknown',
  'omitted column uses DB default (not null)'
);

-- ---------------------------------------------------------------------------
-- 冪等: 同一 mutation_id 再送で version 不変・データ不変
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000001',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'artist_name', 'A2', 'title', 'T2', 'event_date', '2026-08-02'
    ),
    null
  ) ->> 'status'),
  'applied',
  'idempotent resend returns applied'
);
select is(
  (select version from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1::bigint, 'idempotent resend does not bump version'
);
select is(
  (select artist_name from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  'A', 'idempotent resend does not overwrite data'
);

-- ---------------------------------------------------------------------------
-- 正しい base_version(1) 更新: applied / version=2
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000002',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'artist_name', 'A-updated', 'title', 'T', 'event_date', '2026-08-01'
    ),
    1
  ) ->> 'status'),
  'applied', 'update with correct base_version applies'
);
select is(
  (select version from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  2::bigint, 'version bumped to 2'
);

-- ---------------------------------------------------------------------------
-- stale base_version(1) は conflict（データ不変）
-- 直列化された並行writerの片方が負ける状況の決定的プロキシ。
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000003',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'artist_name', 'stale', 'title', 'T', 'event_date', '2026-08-01'
    ),
    1
  ) ->> 'status'),
  'conflict', 'stale base_version yields conflict'
);
select is(
  (select artist_name from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  'A-updated', 'conflict does not overwrite data'
);

-- ---------------------------------------------------------------------------
-- 既存行への base_version=null は blind overwrite 禁止 → conflict
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000004',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'artist_name', 'blind', 'title', 'T', 'event_date', '2026-08-01'
    ),
    null
  ) ->> 'status'),
  'conflict', 'null base_version on existing row is conflict'
);

-- ---------------------------------------------------------------------------
-- payload.id と p_entity_id 不一致は拒否（22023）
-- ---------------------------------------------------------------------------
select throws_ok(
  $$select public.apply_mutation(
      'dddddddd-0000-0000-0000-000000000005',
      'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
      jsonb_build_object('id', 'aaaaaaaa-0000-0000-0000-0000000000ff',
        'owner_id', '11111111-1111-1111-1111-111111111111',
        'artist_name', 'x', 'title', 'y', 'event_date', '2026-08-01'),
      2)$$,
  '22023', 'payload id mismatch is rejected'
);

-- 未許可 table / op は拒否
select throws_ok(
  $$select public.apply_mutation('dddddddd-0000-0000-0000-000000000006',
      'auth.users', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
      '{}'::jsonb, null)$$,
  '22023', 'invalid table is rejected'
);
select throws_ok(
  $$select public.apply_mutation('dddddddd-0000-0000-0000-000000000007',
      'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'frobnicate',
      '{}'::jsonb, null)$$,
  '22023', 'invalid op is rejected'
);

-- ---------------------------------------------------------------------------
-- owner矯正: 新規idに他ユーザーowner_idを入れても、現在ユーザー所有で作成される
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000008',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000010', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000010',
      'owner_id', '22222222-2222-2222-2222-222222222222', -- なりすまし試行
      'artist_name', 'B', 'title', 'T', 'event_date', '2026-08-01'
    ),
    null
  ) ->> 'status'),
  'applied', 'new row with foreign owner_id is created (owner coerced)'
);
select is(
  (select owner_id from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000010'),
  '11111111-1111-1111-1111-111111111111'::uuid,
  'owner_id is coerced to auth.uid()'
);

-- ---------------------------------------------------------------------------
-- delete: 正しい base_version で削除できる
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000009',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000010', 'delete',
    '{}'::jsonb, 1
  ) ->> 'status'),
  'applied', 'delete with correct base_version applies'
);
select is(
  (select count(*)::int from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000010'),
  0, 'row deleted'
);

-- delete の stale base_version は conflict（削除されない）
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-00000000000a',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'delete',
    '{}'::jsonb, 1
  ) ->> 'status'),
  'conflict', 'stale delete is rejected (current version is 2)'
);
select is(
  (select count(*)::int from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  1, 'row not deleted by stale delete'
);

-- ---------------------------------------------------------------------------
-- 他ユーザーの既存行: 取得・更新・削除できない
-- ---------------------------------------------------------------------------
select _as('22222222-2222-2222-2222-222222222222');

-- user2 が user1 の既存 id を upsert → 見えないため衝突（上書き不可）
select is(
  (select public.apply_mutation(
    'eeeeeeee-0000-0000-0000-000000000001',
    'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aaaaaaaa-0000-0000-0000-000000000001',
      'owner_id', '22222222-2222-2222-2222-222222222222',
      'artist_name', 'hijack', 'title', 'T', 'event_date', '2026-08-01'
    ),
    null
  ) ->> 'status'),
  'conflict', 'cannot overwrite another user''s existing row'
);

-- user2 の delete も user1 の行を消せない（見えない→no-op applied だが未削除）
select lives_ok(
  $$select public.apply_mutation(
      'eeeeeeee-0000-0000-0000-000000000002',
      'genbas', 'aaaaaaaa-0000-0000-0000-000000000001', 'delete',
      '{}'::jsonb, 2)$$,
  'other user delete is a no-op (invisible row)'
);

select _as('11111111-1111-1111-1111-111111111111');
select is(
  (select artist_name from public.genbas where id = 'aaaaaaaa-0000-0000-0000-000000000001'),
  'A-updated', 'user1 row untouched by user2 upsert/delete'
);

-- ---------------------------------------------------------------------------
-- RLS を跨いで owner_id を取得する SECURITY DEFINER 補助関数は存在しない
-- ---------------------------------------------------------------------------
select is(
  (select count(*)::int from pg_proc where proname = '_entity_owner'),
  0,
  'no SECURITY DEFINER _entity_owner helper exists'
);

select * from finish();
rollback;
