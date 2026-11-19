# ACL do schema public antes da alteração autorizada

Registro de metadados capturados no banco `evo_community`, em 29/10/2026, antes de qualquer alteração da ACL nesta operação.

- ACL original: `{pg_database_owner=UC/pg_database_owner,=U/pg_database_owner}`; `=U` representa `USAGE` concedido a `PUBLIC`.
- Papéis locais não internos: `postgres` (superusuário e login), `projects_app` e `projects_migrator` (ambos login, não superusuários). Os dois últimos herdavam `USAGE` por `PUBLIC`, sem grant explícito na ACL original.
- Sessões observadas em `evo_community`: 13 como `postgres`; esta fotografia não garante ausência de consumidores desconectados ou futuros.
- Configuração observada dos contêineres: Auth e CRM usam `postgres`; Agenda usa `postgres`; Projetos usa `projects_app`; Financeiro usa `postgres`. Apenas nomes de usuário e destino do banco foram verificados; senhas não foram registradas.
- `acl-public-aplicacao.sql` valida a ACL e o inventário de papéis antes de conceder `USAGE` explícito a Projetos e revogar `USAGE` de `PUBLIC`. `acl-public-reversao.sql` restaura a ACL original somente se a ACL corrente coincidir com a esperada, evitando sobrescrever alterações posteriores.
- Aplicação e reversão foram executadas com sucesso em PostgreSQL 16 descartável com os mesmos nomes de banco e papéis; um papel inesperado provocou abortamento e deixou a ACL original intacta. Isso não substitui a verificação do ambiente real.
- Novos papéis que precisem usar `public` não herdarão mais `USAGE` automaticamente; o procedimento de provisionamento deve concedê-lo explicitamente após análise. Não conceder esse acesso aos papéis de Empréstimos, conforme isolamento exigido.
