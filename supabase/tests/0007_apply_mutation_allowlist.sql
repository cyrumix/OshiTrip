-- pgTAP: apply_mutation の許可テーブル復旧（0011）検証
--   - oshi_anniversaries の upsert/delete が拒否されない（記念日同期の復旧）
--   - todo_templates / todo_template_items が同期できる
--   - テンプレートは別ownerから読み書きできない
--   - template item の owner が親 template と違う場合は拒否される
--   - 不正な entity_table は引き続き拒否される
-- 実行: supabase start → supabase db reset → supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select plan(10);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'user1@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'user2@example.com');

-- 認証切替ヘルパは authenticated ロールに CREATE 権限が無いため、
-- role を切り替える前（＝スーパーユーザー時）に作成する（D-248）。
create or replace function _as(uid text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

set local role authenticated;

select _as('11111111-1111-1111-1111-111111111111');

-- ---------------------------------------------------------------------------
-- oshi_anniversaries: apply_mutation で拒否されず同期できる（許可リスト復旧）
--   親グループ（user1所有）を用意してから記念日を upsert する。
-- ---------------------------------------------------------------------------
insert into public.oshi_groups (id, owner_id, name)
values ('99999999-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'グループ');

select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000001',
    'oshi_anniversaries', 'aa000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'aa000000-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'group_id', '99999999-0000-0000-0000-000000000001',
      'label', '記念日', 'date', '2026-12-25'
    ),
    null
  ) ->> 'status'),
  'applied',
  'oshi_anniversaries upsert is NOT rejected by apply_mutation'
);
select is(
  (select label from public.oshi_anniversaries
   where id = 'aa000000-0000-0000-0000-000000000001'),
  '記念日',
  'oshi_anniversaries row was written'
);
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000002',
    'oshi_anniversaries', 'aa000000-0000-0000-0000-000000000001', 'delete',
    '{}'::jsonb, 1
  ) ->> 'status'),
  'applied',
  'oshi_anniversaries delete is NOT rejected by apply_mutation'
);

-- ---------------------------------------------------------------------------
-- todo_templates / todo_template_items: apply_mutation で同期できる
-- ---------------------------------------------------------------------------
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000003',
    'todo_templates', 'bb000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'bb000000-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'name', '基本Todo', 'item_type', 'todo'
    ),
    null
  ) ->> 'status'),
  'applied',
  'todo_templates upsert syncs'
);
select is(
  (select public.apply_mutation(
    'dddddddd-0000-0000-0000-000000000004',
    'todo_template_items', 'cc000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'cc000000-0000-0000-0000-000000000001',
      'owner_id', '11111111-1111-1111-1111-111111111111',
      'template_id', 'bb000000-0000-0000-0000-000000000001',
      'name', '項目A'
    ),
    null
  ) ->> 'status'),
  'applied',
  'todo_template_items upsert syncs'
);

-- ---------------------------------------------------------------------------
-- 不正な entity_table は引き続き拒否される（22023）
-- ---------------------------------------------------------------------------
select throws_ok(
  $$select public.apply_mutation(
      'dddddddd-0000-0000-0000-000000000005',
      'auth.users', 'bb000000-0000-0000-0000-000000000001', 'upsert',
      '{}'::jsonb, null)$$,
  '22023', null,
  'invalid entity_table is still rejected'
);

-- ---------------------------------------------------------------------------
-- テンプレートは別ownerから読み書きできない
-- ---------------------------------------------------------------------------
select _as('22222222-2222-2222-2222-222222222222');

-- user2 は user1 のテンプレートを RLS で参照できない。
select is(
  (select count(*)::int from public.todo_templates
   where id = 'bb000000-0000-0000-0000-000000000001'),
  0,
  'other owner cannot read user1 template'
);

-- user2 が user1 の既存テンプレート id を上書きしようとしても不可（不可視→conflict）。
select is(
  (select public.apply_mutation(
    'eeeeeeee-0000-0000-0000-000000000001',
    'todo_templates', 'bb000000-0000-0000-0000-000000000001', 'upsert',
    jsonb_build_object(
      'id', 'bb000000-0000-0000-0000-000000000001',
      'owner_id', '22222222-2222-2222-2222-222222222222',
      'name', 'hijack', 'item_type', 'todo'
    ),
    null
  ) ->> 'status'),
  'conflict',
  'other owner cannot overwrite user1 template'
);

-- ---------------------------------------------------------------------------
-- template item の owner が親 template と違う場合は拒否される
--   user2 が user1 のテンプレート配下へ item を作ろうとすると、item の owner は
--   user2 に矯正される一方、親テンプレートは user1 所有のため、
--   enforce_todo_template_item_owner トリガーが所有者不一致で拒否する。
-- ---------------------------------------------------------------------------
-- enforce_todo_template_item_owner の `raise exception`（errcode 未指定）は
-- SQLSTATE P0001。
select throws_ok(
  $$select public.apply_mutation(
      'eeeeeeee-0000-0000-0000-000000000002',
      'todo_template_items', 'cc000000-0000-0000-0000-000000000002', 'upsert',
      jsonb_build_object(
        'id', 'cc000000-0000-0000-0000-000000000002',
        'owner_id', '22222222-2222-2222-2222-222222222222',
        'template_id', 'bb000000-0000-0000-0000-000000000001',
        'name', 'X'),
      null)$$,
  'P0001', null,
  'template item with owner different from parent template is rejected'
);

-- user1 の item は書き換えられていない（回帰確認）。
select _as('11111111-1111-1111-1111-111111111111');
select is(
  (select name from public.todo_template_items
   where id = 'cc000000-0000-0000-0000-000000000001'),
  '項目A',
  'user1 template item untouched by user2'
);

select * from finish();
rollback;
