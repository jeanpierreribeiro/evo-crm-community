-- Reversão condicionada à ACL após a aplicação específica documentada.
-- Não sobrescrever alterações independentes feitas posteriormente.
\set ON_ERROR_STOP on
BEGIN;
DO $guard$
DECLARE acl text;
BEGIN
  IF current_database() <> 'evo_community' THEN RAISE EXCEPTION 'Banco incorreto'; END IF;
  SELECT nspacl::text INTO acl FROM pg_namespace WHERE nspname='public';
  IF acl IS DISTINCT FROM '{pg_database_owner=UC/pg_database_owner,projects_app=U/pg_database_owner,projects_migrator=U/pg_database_owner}' THEN
    RAISE EXCEPTION 'ACL atual difere da aplicação esperada; requer restauração manual';
  END IF;
END
$guard$;
GRANT USAGE ON SCHEMA public TO PUBLIC;
REVOKE USAGE ON SCHEMA public FROM projects_app, projects_migrator;
DO $verify$
DECLARE acl text;
BEGIN
  SELECT nspacl::text INTO acl FROM pg_namespace WHERE nspname='public';
  IF acl IS DISTINCT FROM '{pg_database_owner=UC/pg_database_owner,=U/pg_database_owner}' THEN
    RAISE EXCEPTION 'ACL não retornou ao estado anterior';
  END IF;
END
$verify$;
COMMIT;
