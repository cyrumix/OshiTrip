-- pgTAP: Todo/持ち物の種別列（0009_todo_item_type.sql）の制約・既定値検証
begin;

create extension if not exists pgtap with schema extensions;

select plan(5);

insert into auth.users (id, email)
values ('11111111-1111-1111-1111-111111111111', 'user1@example.com');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

insert into public.genbas (id, owner_id, artist_name, title, event_date)
values ('aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', 'アーティスト', '公演', '2026-06-01');

-- 種別を省略すると既定値 'todo'（既存データとの後方互換）。
insert into public.todos (id, genba_id, owner_id, name)
values ('dddddddd-0000-0000-0000-000000000001',
        'aaaaaaaa-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111', '銀テを拾う');

select results_eq(
  $$select type from public.todos
    where id = 'dddddddd-0000-0000-0000-000000000001'$$,
  $$values ('todo')$$,
  'todos.type defaults to todo'
);

-- 持ち物として明示登録できる。
select lives_ok(
  $$insert into public.todos (id, genba_id, owner_id, name, type)
    values ('dddddddd-0000-0000-0000-000000000002',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', 'ペンライト', 'belonging')$$,
  'todos.type accepts belonging'
);

select results_eq(
  $$select type from public.todos
    where id = 'dddddddd-0000-0000-0000-000000000002'$$,
  $$values ('belonging')$$,
  'belonging is stored as-is'
);

-- 不正な種別は check 制約で拒否される。
select throws_ok(
  $$insert into public.todos (id, genba_id, owner_id, name, type)
    values ('dddddddd-0000-0000-0000-000000000003',
            'aaaaaaaa-0000-0000-0000-000000000001',
            '11111111-1111-1111-1111-111111111111', '不正な種別', 'shopping')$$,
  '23514',
  null,
  'invalid type is rejected by check constraint'
);

-- 種別は後から変更できる（Todo⇄持ち物の切り替え）。
select lives_ok(
  $$update public.todos set type = 'belonging'
    where id = 'dddddddd-0000-0000-0000-000000000001'$$,
  'type can be changed from todo to belonging'
);

select finish();
rollback;
