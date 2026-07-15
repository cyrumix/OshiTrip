-- ============================================================================
-- 0032_public_role_grants.sql
--   public スキーマ配下のオブジェクトへの基本権限を Supabase の PostgREST ロール
--   （anon / authenticated / service_role）へ付与する。
--
--   背景（D-248）: 本プロジェクトの過去 migration は RLS ポリシーと per-function の
--   `grant execute` は定義してきたが、テーブル/スキーマの GRANT を一切行っていない。
--   Supabase クラウドは既定でこれらを付与するが、`supabase db reset` のローカル適用
--   では付与されず、`set local role authenticated`/`anon` で動く pgTAP（0001〜0017）
--   や PostgREST 経由の認証アクセスが `permission denied` で失敗していた。
--
--   最小権限方針（D-248 是正）:
--   - anon / authenticated には **DML（select/insert/update/delete）のみ**を付与し、
--     TRUNCATE / REFERENCES / TRIGGER / MAINTAIN といったテーブル管理権限は与えない。
--     行レベルの可否は各テーブルの RLS が担う（GRANT=テーブル層 / RLS=行層）。
--   - service_role（Edge Function・管理用。RLS を bypass する）にのみ ALL を付与する。
--
--   前方専用・冪等。すべてのテーブルが出揃った後（最後）に適用する。
-- ============================================================================

grant usage on schema public to anon, authenticated, service_role;

-- anon / authenticated: テーブルの DML と sequence の利用のみ。
-- **関数の EXECUTE はブランケット付与しない**。認証ユーザーが呼んでよい関数
-- （apply_mutation / apply_shared_mutation / プロフィール・フレンド・招待 RPC 等）は
-- 各 migration で個別に `grant execute ... to authenticated` 済み。増分 API 用の
-- 内部関数（increment_api_usage・has_premium_routes_entitlement 等）は
-- service_role 専用のままにするため、ここでは一括付与しない（D-248 是正）。
grant select, insert, update, delete on all tables in schema public
  to anon, authenticated;
grant usage, select on all sequences in schema public
  to anon, authenticated;

-- service_role: 管理/Edge Function 用（RLS bypass ロール）。
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all routines in schema public to service_role;

-- 以降の migration で作られるオブジェクトにも既定で同じ権限を付与する。
alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated;
alter default privileges in schema public
  grant usage, select on sequences to anon, authenticated;
alter default privileges in schema public
  grant all on tables to service_role;
alter default privileges in schema public
  grant all on sequences to service_role;
alter default privileges in schema public
  grant execute on routines to service_role;
