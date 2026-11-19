-- Executar somente no banco evo_community após inventário e autorização.
-- A validação inicial impede aplicação quando a ACL ou os papéis mudaram.
\set ON_ERROR_STOP on
BEGIN;
DO $guard$
DECLARE
  current_acl text;
  unexpected_roles text;
BEGIN
  IF current_database() <> 'evo_community' THEN
    RAISE EXCEPTION 'Banco incorreto; operação cancelada';
  END IF;
  SELECT nspacl::text INTO current_acl FROM pg_namespace WHERE nspname = 'public';
  IF current_acl IS DISTINCT FROM '{pg_database_owner=UC/pg_database_owner,=U/pg_database_owner}' THEN
    RAISE EXCEPTION 'ACL do schema public mudou desde o inventário; operação cancelada';
  END IF;
  SELECT string_agg(rolname, ', ' ORDER BY rolname) INTO unexpected_roles FROM pg_roles
   WHERE rolname NOT LIKE 'pg\_%' ESCAPE '\'
     AND rolname NOT IN ('postgres', 'projects_app', 'projects_migrator');
  IF unexpected_roles IS NOT NULL THEN
    RAISE EXCEPTION 'Papéis adicionais exigem inventário antes da aplicação: %', unexpected_roles;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'projects_app')
     OR NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'projects_migrator') THEN
    RAISE EXCEPTION 'Papéis esperados não encontrados';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_stat_activity WHERE datname=current_database() AND usename NOT IN ('postgres','projects_app','projects_migrator')) THEN
    RAISE EXCEPTION 'Há sessões por papel não inventariado';
  END IF;
END
$guard$;
GRANT USAGE ON SCHEMA public TO projects_app, projects_migrator;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;
DO $verify$
BEGIN
  IF NOT has_schema_privilege('postgres', 'public', 'USAGE')
     OR NOT has_schema_privilege('projects_app', 'public', 'USAGE')
     OR NOT has_schema_privilege('projects_migrator', 'public', 'USAGE') THEN
    RAISE EXCEPTION 'Um consumidor identificado perdeu acesso; transação revertida';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_namespace n, LATERAL aclexplode(n.nspacl) a
     WHERE n.nspname='public' AND a.grantee=0 AND a.privilege_type='USAGE'
  ) THEN
    RAISE EXCEPTION 'PUBLIC continua com USAGE; transação revertida';
  END IF;
END
$verify$;
COMMIT;
