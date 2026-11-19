# Empréstimos — evidências de implementação

## Topologia inicial — tarefa 1.1

- Serviço próprio `evo-loans-service` como diretório do repositório principal, sem criar repositório remoto ou submódulo. Suas dependências e código não dependem do Financeiro.
- Runtime previsto Node.js 22 no container, alinhado ao Dockerfile e à CI de Projetos. O Node do host consultado era v24.15.0; isso não comprova build em Node 22, que deve ser testado no container/CI.
- Porta interna proposta 3005; publicação opcional local restrita a `127.0.0.1:3015`. Em 28/10/2026, ambas foram testadas por bind em loopback e estavam disponíveis. É uma verificação pontual, não reserva para deploy futuro.
- Desenvolvimento: Compose com serviço e job de migração próprio; produção Swarm: imagem própria, sem publicar porta de serviço, e migração verificada como etapa explícita antes de atualizar a aplicação. `depends_on` não comprova ordenação em Swarm.
- Docker Engine respondeu com versão 29.9.2. Os contêineres jprOS observados não incluem gateway em execução; outra aplicação estava publicada em 3030. Validar a topologia e a porta do gateway no ambiente de teste antes de afirmar conectividade.
- Isso registra a escolha e a verificação inicial; G0, migração, build, acesso, backup e operação ainda não foram homologados.

## Fundação parcial — tarefas 1.2 a 1.4 ainda abertas

- Estrutura inicial de serviço criada em `evo-loans-service`; não existem rotas de negócio liberadas. `npm test` passou dois testes de saúde e prontidão. A imagem local com Node 22 foi construída.
- A primeira migration foi aplicada com sucesso em PostgreSQL descartável. A verificação por papel sintético confirmou leitura da tabela de carteira e ausência de `CREATE` no schema de empréstimos e de uso do schema público.
- O teste também encontrou que privilégios padrão genéricos concediam escrita em `_prisma_migrations`. O privilégio foi removido manualmente **apenas no banco descartável** e a leitura passou a ser permitida sem `UPDATE`. Ainda falta automatizar e testar o provisionamento seguro em conjunto com o job de migração; a tarefa 1.3 não está concluída.
- O serviço isolado retornou 200 em `/health` e `/ready` após a migration. Readiness sem banco/migração retorna 503 nos testes de unidade; falta validar cenários reais adicionais.
- O gateway isolado não iniciou: o template preexistente repete `client_header_buffer_size` e `large_client_header_buffers` dentro de blocos `location`, contexto inválido no Nginx. As mesmas diretivas já existem no nível `server`. A rota de empréstimos foi adicionada, mas ainda não foi validada pelo gateway; a tarefa 1.2 e a integração 1.4 permanecem abertas.
- Os três contêineres descartáveis e sua rede foram removidos após os testes. Nenhum banco operacional foi migrado ou alterado.

## Continuação — gateway e isolamento (29/10/2026)

- Com autorização do dono, foram removidas as cópias inválidas de duas diretivas do template Nginx; as diretivas no nível `server` foram mantidas. Um gateway descartável iniciou e encaminhou `/api/v1/loans/health` com HTTP 200. Uma requisição sem token a `/api/v1/loans/session` retornou 401; `/ready` retornou 503 com o banco indisponível.
- O serviço tem flag desativada por padrão e valida assinatura JWT e resposta do Auth sem fallback. Seis testes sintéticos passaram; a revogação nesses testes é simulada. Autorização por carteira e verificação ponta a ponta contra Auth ainda não foram concluídas.
- Em banco descartável vazio, `scripts/provision-loans.sql` criou papéis e schema e `npm run migrate:deploy` aplicou a migration; verificou-se leitura do histórico de migrações sem permissão de UPDATE, escrita na tabela própria e ausência de CREATE no schema. Não se considera a tarefa 1.3 concluída.
- No banco descartável, o papel de aplicação herdou `USAGE` do schema `public` via `PUBLIC`. Consulta somente de metadados no banco jprOS existente confirmou o mesmo `USAGE` público e dois objetos `public` com SELECT concedido a `PUBLIC`: `pg_stat_statements` e `pg_stat_statements_info`. Não foram consultados dados desses objetos nem alteradas permissões do banco jprOS. Isso contraria a exigência planejada de ausência de acesso a outros schemas; não revogar privilégios globais sem avaliar efeitos nos serviços existentes.
- Foram removidos os contêineres e a rede descartáveis. A mudança está em 2/45 tarefas; G0, isolamento completo, backup e liberação continuam pendentes.

## Estudo da opção B — 29/10/2026

- Consultas de metadados mostraram que o grant de `USAGE` a `PUBLIC` é herdado por todos os papéis; no momento, os papéis não internos eram `postgres`, `projects_app` e `projects_migrator`. Não se presumiu que essa lista cubra consumidores externos ou futuros.
- Em PostgreSQL descartável, conceder `USAGE` explicitamente aos papéis existentes e retirar de `PUBLIC` manteve consulta efetiva como `projects_app` e negou consulta efetiva como `loans_app`; um papel criado depois não recebeu `USAGE` automaticamente. A alternativa afeta o banco inteiro e exige inventário e aprovação antes de qualquer aplicação no jprOS.
- O job de migração ganhou checagem anterior à migration: falhou quando os papéis herdavam `USAGE` de outro schema e não criou a tabela de histórico; passou após correção das ACLs **somente no banco descartável**. O papel de aplicação manteve escrita na tabela própria, sem `CREATE` no schema e sem `UPDATE` no histórico de migrações.
- `npm test` passou seis testes sintéticos. O PostgreSQL descartável foi removido. O banco operacional foi acessado somente para leitura de metadados, sem mudança de ACL ou leitura de dados das visões técnicas. Ver detalhes e SQL proposto em `docs/emprestimos/ESTUDO-ISOLAMENTO-BANCO-COMPARTILHADO.md`.

## Aplicação autorizada da ACL — 29/10/2026

- Autorização expressa do dono para aplicar a alternativa B após reconfirmar consumidores e preparar reversão. ACL anterior e papéis observados registrados em `docs/emprestimos/ACL-PUBLIC-ANTES-20261029.md`.
- Scripts de aplicação e reversão foram testados em PostgreSQL 16 descartável; um papel inesperado abortou a transação sem alteração. O contêiner descartável foi removido após os testes.
- Em `evo_community`, `acl-public-aplicacao.sql` passou nas condições e confirmou transação: `projects_app` e `projects_migrator` receberam `USAGE` explícito no schema `public`, e `PUBLIC` deixou de receber `USAGE`. ACL posterior: `{pg_database_owner=UC/pg_database_owner,projects_app=U/pg_database_owner,projects_migrator=U/pg_database_owner}`.
- Verificação posterior: `postgres`, `projects_app` e `projects_migrator` mantiveram `USAGE`; consultas de zero linhas às visões técnicas funcionaram sob ambos os papéis de Projetos. Contêineres de Auth, CRM, Projetos, Agenda, Financeiro e PostgreSQL estavam em estado `healthy` na verificação; isso não comprova todos os fluxos nem consumidores externos.
- `acl-public-reversao.sql` é guardado para reversão condicionada à ACL esperada; não foi executado no jprOS. Futuras identidades que precisem do schema devem receber `USAGE` explicitamente, após análise. Nenhuma tabela, dado de negócio ou regra do Financeiro foi alterada.

## Fundação — implementação em andamento

- Tarefa OpenSpec 1.3 concluída em ambiente descartável: dois papéis separados, schema e migrations, job de migração e execução repetida; teste automatizado `npm run test:db` verifica bloqueio por grants públicos, aplicação em banco vazio, negação de DDL e leitura cruzada. A aplicação tem somente leitura sobre o histórico de migrações e não pode alterar auditoria.
- `npm test` passou oito testes sintéticos de autenticação, flag, saúde e integridade das migrations em arquivo. Não é validação de Auth real, revogação ponta a ponta, autorização por carteira ou G0.
- `docker-compose.yml` inclui os componentes de Empréstimos em perfil `loans` de adesão explícita, desativado por padrão; o serviço não foi habilitado nem migrations aplicadas no banco jprOS.

## Integração e acesso — continuação em 29/10/2026

- A tarefa 1.3 foi concluída com provisionamento e migrações versionadas, job no perfil Compose e teste automatizado em PostgreSQL descartável. O teste confirma bloqueio prévio por ACL insegura, duas migrations, repetição, negação de DDL e leitura cruzada, e preservação somente de leitura no histórico de migrations. G0 completo permanece pendente.
- A tarefa 2.3 foi concluída: o plano e D3/D8/D11 foram alinhados sem mudar decisões; backup prévio com hash verificado e 19 cenários documentais foram registrados em DT-04.
- Foram iniciadas as tarefas 1.4–1.6: configuração do gateway/Compose, placeholders do frontend, pipeline, flag, testes de JWT/Auth simulado e lógica inicial de carteiras/autorização; não estão concluídas nem liberadas. O build do frontend passou antes da última adição de teste, e o teste do cliente de Empréstimos verificou preservação de `Idempotency-Key` após renovação de sessão.
- O serviço passou nove testes sintéticos de autenticação, CORS e readiness; o teste integrado de migrations, bootstrap/recuperação, usuários sintéticos e isolamento passou em banco descartável. Não houve teste de revogação com Auth real ou comprovação de G0 de ponta a ponta.
- A ACL de `evo_community.public` foi alterada com autorização separada, preservando `USAGE` explícito dos papéis inventariados; novo papel que precisar do schema exige grant explícito. A reversão e o estado anterior permanecem documentados em `docs/emprestimos/ACL-PUBLIC-ANTES-20261029.md` e nos scripts de ACL. O banco jprOS não recebeu schema ou dados de Empréstimos.
- A tarefa 1.7 encontrou necessidade de um diretório de identidades restrito; `docs/emprestimos/PROPOSTA-DIRETORIO-AUTH.md` descreve a alteração proposta no Auth e não representa implementação. Não foram modificadas rotas ou permissões do Auth para isso.
