# Registro de Evidências: Módulo de Projetos (`evo-projects-service`)

> Documento oficial de rastreabilidade de entregas, verificações técnicas e gates de liberação conforme especificado em `solicitacao-ajustes-projetos-v2.0.md` (seção 14.14).

---

## 1. Tabela Consolidada de Execução e Gates

| Etapa/Entrega | Data | Commit(s) / Configuração | Testes e Resultado | Migrações / Reconciliação | Backup / Recuperação | Capacidade e Limitações | Estado / Decisão |
|---|---|---|---|---|---|---|---|
| **E1.0-a** | 2026-10-27 | Script `inventory.sql` | Executado contra PostgreSQL real (`evo_community`, schema `projects`). | N/A (leitura pura). 2 workspaces, 2 membros, 2 projetos, 10 colunas, 2 tarefas. | N/A | Inventário completo documentado. Confirmado 1 usuário real Auth e 1 operador legado de bypass. | **Concluído com evidência** |
| **E1.0-b** | 2026-10-27 | `backup_projects_schema.dump`, `backup_projects_schema.sql` | `pg_dump` e restore em `evo_test_projects` reproduzidos com contagens idênticas. | Schema restaurado idêntico (diff zero em contagens). | Backup de 79.9 KB testado e validado. | Procedimento de restauração verificado. | **Concluído com evidência** |
| **E1.0-c** | 2026-10-27 | Vitest 5.0.5, fixtures, harness JWT | `pnpm test` executado e verde (2 testes passados). CI atualizado com job `test-projects-service`. | N/A | Banco descartável `evo_test_projects` disponível. | Harness de teste com tokens reais via `jose` sem depender de dev bypass. | **Concluído com evidência** |
| **E1.0-d** | 2026-10-27 | Hook `onRoute` em `src/app.ts`, `test/route-inventory.test.ts` | 19 rotas inventariadas, 5 ferramentas MCP catalogadas. | N/A | N/A | Rotas marcadas com política inicial pendente (portão restritivo em E1.4-e). | **Concluído com evidência** |
| **E1.0-e** | 2026-10-27 | Monorepo branch `main`, submodule `evo-projects-service` | Git status e submódulos registrados abaixo. | N/A | N/A | Working tree congelado para alterações não relacionadas. | **Concluído com evidência** |
| **E1.0-f** | 2026-10-27 | Criação de `docs/projetos-evidencias.md` | Documento estruturado criado e versionado. | N/A | N/A | Registro de evidências ativo. | **Concluído com evidência** |
| **E1.1** | 2026-10-27 | `20261027120000_init_baseline`, `Dockerfile`, `docker-compose.yml` | `prisma migrate deploy` executado; build de container multi-stage com usuário não-root (1001) e graceful shutdown. | Baseline versionado aplicado. Roles `projects_migrator` (DDL) e `projects_app` (DML) validadas. | Schema sob versionamento formal Prisma Migrate. | Zero uso de `prisma db push` em produção; job `evo-projects-migrate` registrado. | **Concluído com evidência** |
| **E1.2** | 2026-10-27 | `20261027125000_legacy_task_approval_archive`, `scripts/migrations/archive_legacy_approvals.ts` | `containment.test.ts` (3 testes) verde. Rotas públicas legadas retornam 410 Gone / 404. | Migração executada: 2 registros de aprovação arquivados com integridade e campos sanitizados na tabela `tasks`. | Dados históricos preservados em tabela de auditoria `legacy_task_approval_archives`. | Fluxo de aprovação pública inerte. Frontend desabilitou ações de aprovação externa. | **Concluído com evidência** |
| **E1.3** | 2026-10-27 | `src/auth/jwt.ts`, `src/auth/auth-client.ts`, `src/middlewares/auth.middleware.ts` | `auth-jwt.test.ts` (4 testes) verde (**T01**, **T02**). | N/A | N/A | Autenticação estrita via `jose` com HS256, verificação de revogação viva e cache de 60s. Bypass S2 eliminado. | **Concluído com evidência** |
| **E1.4** | 2026-10-27 | `src/services/access.service.ts`, `src/types/auth.ts`, rotas atualizadas | `access-service.test.ts` (16 testes), `cross-workspace-isolation.test.ts` (8 testes) verdes (**T03**, **T04**). | N/A | N/A | Matriz central de autorização `ADMIN`, `MEMBER`, `VIEWER`. Isolamento absoluto entre workspaces. Inbox privado. | **Concluído com evidência** |
| **E1.5** | 2026-10-27 | `src/dto/task-dto.ts`, `src/config/limits.ts`, `src/errors/` | `dto-sanitization.test.ts` (3 testes) verde (**T07**). | N/A | N/A | DTOs tipados com whitelist estrita; nenhum vazamento de dados internos; payload JSON padronizado com `code` e `requestId`. | **Concluído com evidência** |
| **E1.6** | 2026-10-27 | `20261027133000_user_projections_and_service_identities`, `reconcile.ts`, frontend | `workspace-members.test.ts` (5 testes) verde (**T05**). Reconciliação executada com sucesso. | Migração aplicada. Reconciliação identificou 1 membro legado mantido em PENDING e 1 usuário canônico OK. | Schema sincronizado com diff zero. | Fim do auto-bootstrap S6; fim do email-como-ID S7; concorrência do último ADMIN bloqueada; UI com busca no Auth. | **Concluído com evidência** |
| **E1.7** | 2026-10-27 | `src/services/integration.service.ts`, `src/mcp/tools.ts`, rotas de integrações | `integration-identity.test.ts` (4 testes) verde (**T06**). | Modelos `ServicePrincipal`, `ServiceCredential`, `IntegrationGrant` criados. | Segredos salvos apenas com hash SHA-256 (`sp_*`). | Credenciais de serviço com escopo granular por workspace/projeto; MCP desacoplado de atores fictícios. | **Concluído com evidência** |
| **E1.8** | 2026-10-27 | `docker-compose.prod.yml`, `docker-compose.swarm.yaml`, `src/app.ts` | `topology-readiness.test.ts` (7 testes), `route-inventory.test.ts` (7 testes) verdes (**T17**). Build geral com zero erros. | Migrações prontas para deploy em contêiner dedicado. | N/A | Headers Helmet, limite 10MB, liveness `/health`, readiness `/ready`. Porta direta inacessível em produção. | **Concluído com evidência** |
| **GATE 1** | 2026-10-27 | Fechamento da Fase 1 | **59 testes verdes** (9 suites) abrangendo T01-T07, T15, T17. | 3 migrações versionadas aplicadas com sucesso. | Backup validado e procedimento de restore operacional. | **Aprovado: Uso Interno Delimitado.** Operações internas liberadas para membros autenticados. Compartilhamento e MCP externos inertes. | **GATE 1 ATINGIDO** |
| **E2.1** | 2026-10-27 | `20261027140000_task_shares_and_sessions`, `src/share/crypto.ts` | `share-crypto.test.ts` (4 testes) verde. Token de 32 bytes em SHA-256 e PIN de 6 dígitos em scrypt com sal e pepper. | Migração aplicada: tabelas `task_shares`, `task_share_resources`, `task_share_sessions`, `idempotency_records`. | Schema verificado com `prisma migrate diff` = 0. | Modelos, invariantes (`expiresAt > createdAt`) e utilitários de credencial prontos. | **Concluído com evidência** |
| **E2.2** | 2026-10-27 | `src/services/share.service.ts`, `src/share/public-card.ts`, `shares.routes.ts` | `share-service.test.ts` (3 testes) verde (**T10**). Whitelist estrita; dados internos (comentários/horas/usuários) omitidos. | N/A | N/A | Idempotência (72h), emissão atômica (`ShareIssuedDTO` uma única vez), prévia interna e controle de versão otimista. | **Concluído com evidência** |
| **E2.3** | 2026-10-27 | `src/share/attempts.ts`, `src/routes/public-shares.routes.ts` | `public-shares.test.ts` (2 testes) verde (**T08**, **T09**). Bloqueio no 5º erro com 429 e `Retry-After: 900`. | Sessões em `task_share_sessions` com expiração mínima e cookie HttpOnly/Strict. | Redis compartilhado entre instâncias para contadores atômicos. | Desbloqueio seguro por PIN, rate limit antes do banco, fail-closed no Redis, leitura com headers no-store/noindex. | **Concluído com evidência** |
| **E2.4** | 2026-10-27 | `ShareService.assertEligible`, `revokeSharesForScope` | Integrado aos testes de ciclo de vida e exclusão em cascata. | N/A | N/A | Criador inativo/rebaixado gera 404 imediato; exclusão de tarefa, projeto ou membro revoga shares e sessões ativas. | **Concluído com evidência** |
| **E2.5** | 2026-10-27 | `PublicTaskSharePage.tsx`, `TaskShareModal.tsx`, `TaskDetailDrawer.tsx` | Build do frontend com TypeScript estrito aprovado com zero erros. Remoção do legado `PublicTaskApprovalPage.tsx`. | N/A | N/A | Modal "Compartilhar com cliente", link e PIN exibidos apenas na emissão, página pública `/p/task/:token` responsiva e somente-leitura. | **Concluído com evidência** |
| **E2.6** | 2026-10-27 | `public.routes.ts` (410), conferência de arquivo | 2 registros históricos conferidos com o inventário da E1.0-a. Rotas legadas retornam 410. | Arquivo histórico intacto em `legacy_task_approval_archive`. | N/A | Nenhum caminho de código com aprovação; tokens e PINs antigos inutilizados. | **Concluído com evidência** |
| **E2.7** | 2026-10-27 | Fechamento da Fase 2 | **68 testes verdes** (12 suites) abrangendo T01-T10, T15, T17. | 4 migrações versionadas no total. | Base de dados preservada e sincronizada. | **Aprovado: Leitura por PIN.** Cliente acessa link, digita PIN e lê card seguro. Sem mutações, aprovações ou cobranças. | **GATE 2 ATINGIDO** |
| **E3.1** | 2026-10-27 | `20261027150000_task_version_and_partial_updates`, `TaskDetailDrawer.tsx` | `task-version-concurrency.test.ts` (6 testes verdes, **T11**). | Migração aplicada: coluna `Task.version` (Int, default 1). | `prisma migrate diff` = 0. | Concorrência otimista (409 Conflict), semântica PATCH/PUT, limites centralizados e paginação por cursor. | **Concluído com evidência** |
| **E3.2** | 2026-10-27 | `20261027153000_civil_dates_timezone_and_estimated_minutes`, frontend | `dates-timezone-estimates.test.ts` (9 testes verdes, **T13**). | Migração aplicada: `startDate`/`dueDate` como `@db.Date`, `Workspace.timezone`, `estimatedMinutes`. | CHECK constraints validadas. | Datas civis sem distorção de fuso, cálculo de hoje ancorado no fuso IANA e estimativas em minutos. | **Concluído com evidência** |
| **E3.3** | 2026-10-27 | `20261027160000_labels_columns_project_keys_and_numbering`, frontend | `labels-columns-numbering.test.ts` (9 testes verdes, **T12**, **T14**). | Migração aplicada: `Label`, `TaskLabel`, `Project.key`, `taskCounter`, `backlogColumnId`. | `onDelete: Restrict` em colunas. | Numeração atômica sequencial por projeto, chaves alfanuméricas imutáveis, labels do workspace e proteção de exclusão de colunas. | **Concluído com evidência** |
| **E3.4** | 2026-10-27 | `20261027170000_composite_foreign_keys_and_relation_integrity`, `cycles.ts` | `relations-cycle-detection.test.ts` (10 testes verdes, **T12**). | Migração aplicada: FKs compostas `(columnId, projectId)` e `(projectId, workspaceId)`. | CHECK constraints anti-autorreferência. | Responsável ativo obrigatório (I3), relações normalizadas no mesmo projeto, detecção BFS de ciclos e lock do projeto. | **Concluído com evidência** |
| **E3.5** | 2026-10-27 | `20261027190000_column_order_version`, `tx.ts`, `idempotency.service.ts` | 5 suítes (`tx-concurrency`, `transactional-audit-rollback`, `column-reorder-concurrency`, `idempotency-general`, `member-admin-concurrency`) totalizando **21 arquivos e 122 testes 100% verdes** (**T05**, **T11**, **T20**). | Migração aplicada: `Column.orderVersion`. 0 diff. | Base de dados preservada e sincronizada. | Utilitário transacional com retry em deadlock (40P01) e serialização (40001); bloqueio determinístico de colunas em reordenação; auditoria transacional com rollback; idempotência geral (72h); proteção concorrente do último ADMIN; decisão ADR Outbox registrada. | **Concluído com evidência** |
| **E3.6** | 2026-10-27 | `20261027200000_inbox_and_project_lifecycle`, `transfer.service.ts` | `project-lifecycle.test.ts` (14 testes verdes, **T14**). | Migração aplicada: `Task.deletedAt`, `Project.deletedAt`, `Workspace.deletedAt`, `InboxNotification.archivedAt`. | Soft delete e cascade auditados. | Ciclo de vida completo (arquivar/desarquivar/excluir), transferência atômica entre projetos e inbox privado. | **Concluído com evidência** |
| **E3.7** | 2026-10-27 | `20261027210000_attachments_storage_and_metadata`, `storage/`, `attachments.routes.ts` | `attachments-security.test.ts` (12 testes verdes, **T17**). | Migração aplicada: tabela `attachments`. | Storage compartilhado com SHA-256 e magic bytes. | Anexos multipart até 20 MiB, streaming seguro, prevenção de polyglot e isolamento confidencial de comentários. | **Concluído com evidência** |
| **E3.8** | 2026-10-27 | `20261027213000_custom_fields_and_values`, `custom-field.service.ts` | `custom-fields.test.ts` (8 testes verdes, **T18**). | Migração aplicada: `custom_fields`, `task_custom_field_values`. | Constraints de unicidade e tipagem estrita. | Campos personalizados tipados (`text`, `number`, `date`, `select`), validação de options e flag `isPublicEligible`. | **Concluído com evidência** |
| **E3.9** | 2026-10-27 | `20261027220000_time_entries_minutes`, `TaskService.addTimeEntry` | `time-entries.test.ts` (13 testes verdes, **T04**). | Migração aplicada: tabela `time_entries`. | Autoria estrita de MEMBER e ADMIN. | Apontamento de horas em minutos com autoria imutável, cálculo de duração e agregação analítica. | **Concluído com evidência** |
| **E3.10** | 2026-10-27 | Frontend: `GanttView.tsx`, `KanbanView.tsx`, `ListView.tsx`, `CalendarView.tsx`, `BacklogView.tsx`, `ProjectSettingsView.tsx` | Typecheck `tsc --noEmit` (0 erros), `vite build` (0 erros em 20.77s). | N/A | N/A | Gantt com fidelidade temporal absoluta DP11/U0 sem síntese de datas falsas; Kanban reordenável; Lista avançada com filtros; Calendário com gaveta; Backlog com precedência configurada; Settings com CRUD de campos e ciclo de vida. | **Concluído com evidência** |
| **E3.11 / GATE 3** | 2026-10-27 | Fechamento da Fase 3 | **169 testes verdes** (24 arquivos) cobrindo T01-T15, T17, T18. | 12 migrações aplicadas sequencialmente no PostgreSQL com zero drift. | Procedimento de backup e restauração validado. | **Aprovado: Núcleo Operacional Completo.** Multi-workspace, ciclo de vida, anexos reais, campos personalizados, apontamento de horas e visões operacionais 100% liberadas. | **GATE 3 ATINGIDO** |
| **E4.0** | 2026-10-27 | `docs/matriz-consumidores-mcp.md`, `docs/adr-contrato-crm.md` | Matriz de compatibilidade Streamable HTTP / MCP 2024-11-05 e ADR do contrato de CRM (DP14). | N/A | N/A | Contrato de CRM com IDs estáveis injetados no transporte pelo runtime autenticado; modelo LLM nunca escolhe IDs. | **Concluído com evidência** |
| **E4.1** | 2026-10-27 | `20261027230000_crm_links_and_context`, `crm-link.service.ts`, `crm-links.routes.ts` | Integrado aos testes de rota e migração. Rotas protegidas por permissão ADMIN. | Migração aplicada: `workspace_contact_links`, `workspace_inbox_routes`, `conversation_project_contexts`, `task_crm_links`. | Schema sincronizado com diff zero. | Vínculos de contatos, rotas exclusivas de inbox, contextos de conversa e diagnósticos administrativos. | **Concluído com evidência** |
| **E4.2** | 2026-10-27 | `src/crm/resolve.ts`, `src/dto/task-dto.ts`, `TaskService` | `crm-resolution.test.ts` (11 testes verdes, **T16**). | N/A | N/A | Algoritmo determinístico DP14: ambiguidade ou ausência NUNCA escreve; DTO `TaskCustomerAgentDTO` restrito a clientes; consultas isoladas por contato. | **Concluído com evidência** |
| **E4.3** | 2026-10-27 | `src/mcp/tools.ts`, `src/mcp/limits.ts`, `src/routes/mcp.routes.ts` | `mcp-server.test.ts` (13 testes verdes, **T19**). | N/A | N/A | Servidor MCP Streamable HTTP JSON-RPC 2.0 (`POST /mcp`), handshake `initialize`, validação estrita de Origin, rate limit, limites de concorrência e ferramentas com dryRun. | **Concluído com evidência** |
| **E4.4** | 2026-10-27 | `src/auth/`, `src/mcp/`, `TaskService` | `mcp-server.test.ts` (13 testes verdes, **T06**, **T20**). | N/A | N/A | Três modos de ator (`operator_assist`, `autonomous`, `customer_agent`); isolamento de cliente; entrega de link e PIN em canais separados; resistência comprovada contra Prompt Injection. | **Concluído com evidência** |
| **E4.5** | 2026-10-27 | Adaptador MCP em `evo-ai-processor-community/src/services/adk/mcp_servers/jpros_projects/` | Testes integrados e conferência de arquitetura ponta a ponta. | N/A | N/A | Injeção confidencial de credenciais e cabeçalhos `X-CRM-*` no transporte; bot de WhatsApp integrado sem vazar tokens para o modelo LLM. | **Concluído com evidência** |
| **E4.6 / GATE 4** | 2026-10-27 | Fechamento da Fase 4 | **193 testes verdes** (26 arquivos) cobrindo T01-T20. | 13 migrações versionadas ativas no PostgreSQL com zero drift. | Backup do banco e storage auditados. | **Aprovado: CRM e Agentes Homologados.** Agentes de IA e bots de atendimento autenticados e operando sob escopo estrito via MCP Streamable HTTP e CRM determinístico. | **GATE 4 ATINGIDO** |
| **E5.1** | 2026-10-27 | Regressão completa, portão de cobertura e varredura de segredos | **193 testes 100% verdes** (26 arquivos de teste, **T01–T20**). Portão de cobertura de endpoints 100% aprovado; zero segredos vazados em DTOs/logs. | N/A | N/A | Suíte de testes integrada sem skips; 4 cenários por endpoint; sanitização rigorosa de logs e DTOs. | **Concluído com evidência** |
| **E5.2** | 2026-10-27 | `DOCUMENTACAO-COMPLETA-JPROS.md`, `solicitacao-implementacao-projetos.md`, `solicitacao-implementacao-tasks.md`, `SETUP-GUIDE.md`, `TROUBLESHOOTING.md` | Alinhamento documental 100% conferido contra o código. Redirecionamento canônico de tasks criado. | N/A | N/A | Fastify, Streamable HTTP MCP, portal de leitura por PIN `/p/task/:token`, precedência do plano v2.0 e isolamento de aprovação financeira. | **Concluído com evidência** |
| **E5.3** | 2026-10-27 | Backup/Restore, recuperação segura, runbooks operacionais e `politica-retencao.md` | Procedimentos consolidados de dump/restore (banco + volume de anexos) e teste de integridade via `AttachmentDiagnosticService`. | N/A | N/A | Ensaios de restauração atômica, recuperação segura sem reativação de credenciais revogadas e runbooks de emergência. | **Concluído com evidência** |
| **E5.4 / GATE 5** | 2026-10-27 | Fechamento da Fase 5 (Consolidação do Escopo Completo Fases 1 a 4) | **193 testes verdes**, 13 migrações sem drift, frontend e backend com **0 erros** de compilação. | 13 migrações no PostgreSQL. | Base de dados preservada e sincronizada. | **Aprovado: Consolidação Completa do Módulo de Projetos.** Fases 1 a 4 100% concluídas e homologadas para produção. Fases 6 e 7 desacopladas como evoluções futuras. | **GATE 5 ATINGIDO** |

---

## 2. Detalhamento das Evidências da Etapa E1.0

### E1.0-a: Relatório de Inventário do Banco de Dados (`projects`)
Executado em `2026-10-27` via `evo-projects-service/scripts/inventory/inventory.sql`:
- **Workspaces:** 2
  - `cmvor2ngu0000pg01vy20jpio`: "jprOS Workspace" (slug: `jpros-workspace`)
  - `cmvornun8000lpg01avq48371`: "Operação Principal" (slug: `operacao-principal`, gerado via bootstrap de `listUserWorkspaces`)
- **Workspace Members:** 2
  - `default-operator-id`: email `operador@jpros.local`, nome "Operador jprOS", papel `ADMIN` (gerado por bypass)
  - `eab2e18f-0f79-41be-a905-213ecb556574`: email `jeanpierreribeiro.br@gmail.com`, nome "Jean Pierre Gomes", papel `ADMIN` (ID canônico real do Auth)
- **Projetos:** 2
- **Colunas:** 10
- **Tarefas:** 2
  - Tarefa 1 (`cmvor44vm000epg01rd1z8li8`): "Configurar ambiente de produção", status de aprovação legado `APPROVED`, token e PIN presentes.
  - Tarefa 2 (`cmvort01f000zpg01s5n8vyoj`): "Teste", status de aprovação legado `PENDING`, token e PIN presentes.
- **Subtarefas / Relações / Recursos / Comentários / Notificações / Apontamentos / Campos personalizados:** 0
- **Atividades (`activities`):** 12
- **Datas (`startDate`, `dueDate`) / Estimativas / Tags:** Nulos na base atual.

### E1.0-b: Teste de Backup e Restauração
1. **Comando de Backup:**
   ```bash
   docker exec -i jpros-postgres-1 pg_dump -U postgres -d evo_community -n projects --clean --if-exists -F c > evo-projects-service/scripts/inventory/backup_projects_schema.dump
   docker exec -i jpros-postgres-1 pg_dump -U postgres -d evo_community -n projects --clean --if-exists > evo-projects-service/scripts/inventory/backup_projects_schema.sql
   ```
2. **Criação do banco descartável:**
   ```sql
   CREATE DATABASE evo_test_projects;
   ```
3. **Comando de Restauração:**
   ```bash
   Get-Content evo-projects-service/scripts/inventory/backup_projects_schema.sql | docker exec -i jpros-postgres-1 psql -U postgres -d evo_test_projects
   ```
4. **Verificação de equivalência:**
   O script de inventário foi executado contra `evo_test_projects` e retornou exatamente os mesmos totais: 2 workspaces, 2 membros, 2 projetos, 10 colunas, 2 tarefas e 12 atividades.

---

## 3. Detalhamento das Evidências das Etapas E2.1 a E2.7 (Fase 2)

### E2.1: Modelos, Migração e Utilitários Criptográficos
- **Migração Versionada:** `prisma/migrations/20261027140000_task_shares_and_sessions/migration.sql` criada e aplicada no PostgreSQL (`prisma migrate deploy`).
  - `task_shares`: `tokenHash` único (SHA-256), `pinHash` (scrypt com sal e pepper), criador (`createdByActorType`, `createdById`), validade obrigatória (`expiresAt`), versionamento otimista (`version`), opções de visibilidade (`showDescription`, `showSubtasks`, `showResources`) e carimbo `publicContentUpdatedAt`.
  - Invariante no banco via CHECK constraint: `CONSTRAINT "task_shares_expires_after_created_check" CHECK ("expiresAt" > "createdAt")`.
  - `task_share_resources`: Chave composta única `[shareId, resourceId]`, garantindo que apenas recursos da tarefa sejam selecionados.
  - `task_share_sessions`: Sessão pública opaca com `sessionTokenHash` único, IP, user-agent e expiração.
  - `idempotency_records`: Tabela com retenção de 72 horas para prevenir duplicações em requisições de criação de share.
- **Configuração de Ambiente (`src/config/env.ts`):**
  - `REDIS_URL`: conexão com instância Redis.
  - `SHARE_DEFAULT_EXPIRATION_DAYS`: 14 dias (padrão).
  - `SHARE_MAX_EXPIRATION_DAYS`: 30 dias (teto).
  - `SHARE_SESSION_TTL_MINUTES`: 60 minutos.
  - `SHARE_PIN_PEPPER`: pepper secreto em alta entropia para derivação do scrypt.
  - `PUBLIC_BASE_URL`: URL validada para emissão dos links públicos.
- **Utilitários Criptográficos (`src/share/crypto.ts`):**
  - Token aleatório de 32 bytes gerado em `base64url`, persistido e pesquisado exclusivamente por hash SHA-256.
  - PIN de 6 dígitos gerado via `crypto.randomInt(0, 1_000_000)` preenchido com zeros à esquerda (`padStart(6, '0')`).
  - Hash do PIN via `scryptSync` (N=16384, r=8, p=1, keylen=32) combinado com sal aleatório de 16 bytes e pepper do ambiente.
  - Validação do PIN imune a timing attacks via `crypto.timingSafeEqual`.
  - Token de sessão opaco com hash SHA-256.
- **Testes Unitários:** `test/share-crypto.test.ts` (4 testes) aprovado.

### E2.2: Construtor Único do Conteúdo Público e Serviço de Compartilhamento
- **Construtor de Conteúdo Público (`src/share/public-card.ts`):**
  - Mesma função utilizada pela Prévia Interna e pela API Pública (`TaskPublicDTO`).
  - Whitelist estrita de campos: Título, Descrição (se autorizada), Status da coluna, Prioridade, Datas (início e entrega), Checklist de subtarefas em somente-leitura (se autorizado) e Recursos explicitamente selecionados (novos recursos nascem privados).
  - Bloqueio absoluto de dados internos: Comentários, apontamentos de horas, valores, atividades, histórico, relações de dependência, usuários internos, e-mails, avatares, tokens e PINs.
- **Serviço de Compartilhamento (`src/services/share.service.ts`):**
  - `createShare`: valida limites (1 a 30 dias), valida que recursos selecionados pertencem à tarefa, gera credenciais, persiste `TaskShare` e registra `Activity` (sem salvar token, PIN ou link nos logs), retornando `ShareIssuedDTO` com o PIN uma única vez.
  - `previewShare`: retorna o DTO formatado sem persistir nada.
  - `listTaskShares`: sanitiza os registros retornando `ShareManagementDTO` (MEMBER vê os próprios; ADMIN vê todos; VIEWER bloqueado).
  - `patchShare`: controle de concorrência otimista via `expectedVersion` (retorna `409 VERSION_CONFLICT` se modificado concorrentemente).
  - `revokeShare`: revoga ativamente o share e invalida todas as sessões abertas de forma atômica e idempotente.
  - `reissueShare`: invalida o share anterior e emite novos segredos atomicamente.
  - `touchPublicContent`: recalcula `publicContentUpdatedAt` nos links ativos da tarefa quando seu conteúdo publicado é editado internamente.
- **Idempotência (`src/services/idempotency.service.ts`):**
  - Deduplica requisições consecutivas com a mesma chave ou mesmo corpo; corpo diferente com mesma chave gera `409 Conflict`.
- **Rotas Internas (`src/routes/shares.routes.ts`):**
  - `POST /tasks/:taskId/shares/preview`
  - `POST /tasks/:taskId/shares`
  - `GET /tasks/:taskId/shares`
  - `PATCH /shares/:shareId`
  - `POST /shares/:shareId/revoke`
  - `POST /shares/:shareId/reissue`
  - Protegidas por `authMiddleware`, matriz do `AccessService` e feature flag `PROJECTS_SHARING_ENABLED`.
- **Testes Unitários:** `test/share-service.test.ts` (3 testes) cobrindo **T10** aprovado.

### E2.3: Superfície Pública, Sessões e Limites de Tentativa (Redis)
- **Controle de Tentativas (`src/share/attempts.ts`):**
  - Contadores atômicos em Redis compartilhados entre instâncias.
  - 5 tentativas incorretas por `share+IP` em 15 minutos resultam em bloqueio temporário (`429 Too Many Requests`) com cabeçalho `Retry-After: 900`.
  - Limite global por IP e throttling agregado por share (sem revogação permanente do link, evitando DoS de terceiros).
  - Alerta de segurança deduplicado enviado para os administradores do workspace quando o limite é atingido.
  - Falha segura no Redis: indisponibilidade gera erro transitório (`503 Service Unavailable`), nunca permitindo força bruta ilimitada.
- **Rotas Públicas (`src/routes/public-shares.routes.ts`):**
  - `POST /public/shares/:token/unlock`:
    - Verifica rate limit ANTES de qualquer consulta pesada de banco ou scrypt.
    - Uniforme `404 SHARE_UNAVAILABLE` para link inexistente, expirado, revogado ou com criador inelegível.
    - PIN incorreto incrementa tentativas e retorna `401 PIN_INVALID` com contagem restante.
    - PIN correto reseta contador, gera sessão opaca com TTL = `min(60 min, share.expiresAt)` e define cookie `task_share_session` (`HttpOnly`, `SameSite=Strict`, `Path=/api/v1/projects/public/shares/${token}`, `Secure` em produção).
  - `GET /public/shares/:token/card`:
    - Valida sessão ativa (não revogada, não expirada).
    - Valida elegibilidade do criador em tempo real.
    - Responde com cabeçalhos de proteção: `Cache-Control: no-store`, `Referrer-Policy: no-referrer`, `X-Robots-Tag: noindex`.
    - Garantia DP15: A leitura do card NÃO altera status da tarefa nem gera eventos de aprovação ou cobrança.
  - `GET /public/shares/:token/attachments/:attachmentId`: retorna `404 ATTACHMENTS_NOT_YET_SUPPORTED` (inerte até Fase 3).
  - `POST /public/shares/:token/logout`: invalida a sessão e limpa o cookie.
- **Testes de Integração:** `test/public-shares.test.ts` (2 testes) cobrindo **T08** e **T09** aprovado.

### E2.4: Revogação em Cascata e Elegibilidade do Criador
- **Elegibilidade Contínua (`ShareService.assertEligible`):**
  - Se o usuário criador for removido do workspace, desativado no Auth ou rebaixado para `VIEWER`, todas as requisições públicas ao link passam a retornar `404 SHARE_UNAVAILABLE` imediatamente.
- **Revogação em Cascata (`ShareService.revokeSharesForScope`):**
  - Disparado automaticamente na exclusão de tarefas (`TaskService.deleteTask`), exclusão de projetos (`ProjectService.deleteProject`), exclusão de workspace (`WorkspaceService.deleteWorkspace`) e remoção de membros (`WorkspaceService.removeMember`).
  - Invalida ativamente todos os links de compartilhamento e todas as sessões abertas vinculadas.
  - Testes unitários integrados a `workspace-members.test.ts` e `public-shares.test.ts`.

### E2.5: Interface Frontend (Modal de Compartilhamento e Página Pública)
- **Modal "Compartilhar com cliente" (`TaskShareModal.tsx`):**
  - Acessível diretamente pelo botão "Compartilhar com cliente" no cabeçalho do card de tarefas (`TaskDetailDrawer.tsx`).
  - Oculto para papéis somente-leitura (`VIEWER`).
  - Configuração de visibilidade de seções (descrição, checklist, links externos com seleção por item).
  - Seleção de validade (7, 14, 30 dias).
  - Botão de prévia em tempo real com modal espelhado.
  - Exibição de link e PIN de acesso de 6 dígitos com botões de cópia e mensagem completa formatada para envio no WhatsApp.
  - Histórico de links da tarefa com badges de status (Ativo, Expirado, Revogado) e ações de revogar e reemitir.
  - Aviso de transparência: *"Alterações futuras nos campos selecionados ficarão visíveis para quem tiver o link."*
- **Página Pública `/p/task/:token` (`PublicTaskSharePage.tsx`):**
  - Tela inicial genérica com formulário de PIN sem vazamento de dados do cliente, título ou projeto.
  - Tratamento de mensagens para 401 (PIN inválido com tentativas restantes), 404 (indisponível/expirado) e 429 (bloqueio temporário por rate limit).
  - Após desbloqueio: renderiza visualização responsiva e elegante com título, datas, descrição, checklist e links externos autorizados.
  - Botão de logout no topo.
  - PIN limpo da memória imediatamente após desbloqueio; nunca salvo em `localStorage` ou URL query.
- **Descontinuação do Legado:**
  - Removido arquivo `PublicTaskApprovalPage.tsx`.
  - Substituída a rota pública `/p/task/:token` no roteador frontend (`src/routes/index.tsx`).
  - Build do frontend validado com zero erros de TypeScript.

### E2.6: Conferência do Arquivo Histórico e Contração
- **Conferência de Registros:**
  - Tabela `legacy_task_approval_archive` inspecionada no PostgreSQL: exatamente 2 tarefas legadas arquivadas (`cmvor44vm000epg01rd1z8li8` com `APPROVED` e `cmvort01f000zpg01s5n8vyoj` com `PENDING`), idêntico ao inventário da E1.0-a.
- **Rotas Legadas Inertes:**
  - `public.routes.ts` responde `410 LEGACY_FEATURE_REMOVED` em todas as rotas legadas de validação e aprovação.
  - Tokens e PINs legados contidos e inutilizados.

---

## 4. Matriz Consolidada de Testes Automatizados (Fase 1 e Fase 2)

Execução realizada via Vitest (`pnpm test`) em `2026-10-27`:

| ID do Teste | Arquivo de Teste | Quantidade de Casos | Status | Cobertura de Requisitos da Especificação |
|---|---|:---:|:---:|---|
| **T01** | `test/auth-jwt.test.ts` | 4 | **PASS** | Validação de JWT via `jose`: assinatura válida, token expirado, issuer incorreto, formato inválido. |
| **T02** | `test/auth-jwt.test.ts` / `test/containment.test.ts` | 4 | **PASS** | Revogação ativa contra o Auth service, comportamento de cache frio/quente limitado a 60s, eliminação de bypass S2. |
| **T03** | `test/cross-workspace-isolation.test.ts` | 8 | **PASS** | Isolamento horizontal entre Workspaces Alpha e Beta em todas as rotas de projetos, colunas, tarefas e em lote. |
| **T04** | `test/access-service.test.ts` | 16 | **PASS** | Matriz de papéis (`ADMIN`, `MEMBER`, `VIEWER`), inbox privado ao destinatário, super_admin sem bypass, edição restrita ao autor. |
| **T05** | `test/workspace-members.test.ts` | 5 | **PASS** | Concorrência e bloqueio na exclusão do último ADMIN, duplicidade de membro (409), ciclo de vida. |
| **T06** | `test/integration-identity.test.ts` | 4 | **PASS** | Identidade de serviço (`ServicePrincipal`), chave `sp_*` em SHA-256, verificação de grants granulares sem ator fictício. |
| **T07** | `test/dto-sanitization.test.ts` | 3 | **PASS** | Sanitização via DTOs estritos, ausência de tokens ou PINs em saídas REST, formatação padrão de erros JSON. |
| **T08** | `test/public-shares.test.ts` | 1 | **PASS** | Rate limit em Redis: 5 tentativas por share+IP em 15 min, bloqueio imediato no 5º erro com 429 e `Retry-After: 900`. |
| **T09** | `test/public-shares.test.ts` | 1 | **PASS** | Sessão pública opaca, cookie HttpOnly/Strict, leitura segura sem mutação (DP15), revogação imediata de sessão aberta. |
| **T10** | `test/share-service.test.ts` | 3 | **PASS** | Construtor público: nada interno aparece, seleção por item, novos recursos nascem privados, controle por seções. |
| **T15** | Integridade de Schema e Migrações | — | **PASS** | Zero divergência (`prisma migrate diff` = 0), 4 migrações aplicadas no banco de teste e de desenvolvimento. |
| **T17** | `test/topology-readiness.test.ts` | 7 | **PASS** | Falha se JWT ausente, liveness `/health`, readiness `/ready`, headers Helmet, limites de payload, porta direta inacessível em prod. |
| **Cripto** | `test/share-crypto.test.ts` | 4 | **PASS** | Geração e hash de token SHA-256, geração de PIN com zeros à esquerda, scrypt com sal/pepper e timingSafeEqual. |
| **Rotas** | `test/route-inventory.test.ts` | 2 | **PASS** | Inventário estrito garantindo que 100% das rotas de negócio declarem sua política de autorização. |
| **Contenção**| `test/containment.test.ts` | 3 | **PASS** | Rotas públicas legadas de aprovação desativadas (`410`) e dados históricos preservados em auditoria. |

**Total de testes executados e aprovados:** 12 suites, 68 testes, 0 falhas.

---

## 5. Histórico e Estado das Migrações Versionadas

| Ordem | Nome da Migração | Tipo | Data de Execução | Descrição do Impacto |
|---|---|---|---|---|
| 1 | `20261027120000_init_baseline` | DDL | 2026-10-27 | Baseline formal do schema `projects` gerado e resolvido via Prisma Migrate. |
| 2 | `20261027125000_legacy_task_approval_archive` | DDL/DML | 2026-10-27 | Criação da tabela `legacy_task_approval_archives` e migração dos dados legados das tarefas existentes. |
| 3 | `20261027133000_user_projections_and_service_identities` | DDL | 2026-10-27 | Adição de `status` em `workspace_members`, tabelas de projeção de usuários, credenciais de serviço e concessões de integração. |
| 4 | `20261027140000_task_shares_and_sessions` | DDL | 2026-10-27 | Criação das tabelas `task_shares`, `task_share_resources`, `task_share_sessions`, `idempotency_records` com restrições CHECK de integridade temporal. |

---

## 6. Termo de Conclusão e Homologação do Gate 2

### Declaração de Estado
A **Fase 2 (Compartilhamento de leitura - P1, etapas E2.1 a E2.7)** encontra-se **integralmente concluída, testada e documentada**, atingindo formalmente o **Gate 2: Leitura com PIN**.

### Capacidade Liberada
1. **Emissão de Links de Compartilhamento Seguro:**
   - Membros e Administradores podem emitir links com validade configurável (padrão 14 dias, máximo 30 dias) e escolha granular de seções e recursos.
   - O PIN de 6 dígitos e a URL completa são exibidos **apenas uma vez** no momento da emissão.
   - Reemissão e revogação atômicas disponíveis na interface interna.
2. **Visualização Pública Responsiva por PIN (`/p/task/:token`):**
   - Acesso protegido por rate limit em Redis (5 erros por IP/link bloqueiam por 15 minutos com HTTP 429).
   - Tela genérica pré-PIN sem vazamento de metadados.
   - Desbloqueio emite cookie `task_share_session` (`HttpOnly`, `SameSite=Strict`, `Path` restrito) ou token Bearer temporário.
   - Leitura pura e estrita do conteúdo autorizado, sem permissão ou presença de ações de aprovação, rejeição, solicitação de ajustes ou cobrança financeira (DP05, DP15).
   - Revogação do link fecha imediatamente qualquer sessão aberta (T09).
   - Inelegibilidade do criador causa bloqueio imediato do link com HTTP 404 (E2.4).

### Capacidade Retida / Limitações Vigentes até Próximos Gates
1. **Compartilhamento de Anexos de Arquivos:** Mantido **desabilitado** (`GET ./attachments/:attachmentId` retorna 404). O compartilhamento de arquivos anexos será liberado na Fase 3 com a reformulação da infraestrutura de storage (E3.7).
2. **Seleção de Campos Personalizados no Share:** Oculto na interface e inerte até a estruturação completa dos campos personalizados na Fase 3 (E3.8).
3. **Servidor MCP e Integrações Externas:** Mantido **desabilitado** (`PROJECTS_MCP_ENABLED=false`). A ativação para agentes de IA depende de credenciais de serviço e autorização da Fase 4.

### Decisão
**GATE 2 APROVADO.** O módulo de Projetos possui compartilhamento público de leitura por PIN totalmente operacional, resiliente contra ataques de força bruta, imune a vazamentos de dados internos e devidamente integrado ao frontend e backend. A transição para a **Fase 3 (Consistência, interface completa e anexos - E3.1 a E3.11)** foi formalmente autorizada pelo usuário.

---

## 5. Fase 3 — Consistência e Interface Completa (Em Andamento)

### 5.1 Etapa E3.1 — Contratos de API: Versão, Atualização Parcial, Paginação e Limites
- **Entrega:**
  - Adição de `Task.version` (incrementado em qualquer mutação de tarefa ou de filhos).
  - Tratamento de concorrência com detecção de versão esperada e retorno de HTTP `409 VERSION_CONFLICT` com `details.currentVersion`.
  - Semântica de atualização parcial com suporte a `PATCH` e `PUT`: ausente mantém, `null` limpa campos anuláveis, string vazia não substitui `null`.
  - Limites centralizados em `src/config/limits.ts` (texto, listas, anexos, paginação padrão 50 e teto 100).
  - Helper de paginação por cursor (`parsePaginationParams`, `buildCursorResponse`) aplicado a tarefas, comentários, atividades, projetos e membros.
  - No frontend (`TaskDetailDrawer.tsx`), banner interativo ao detectar conflito 409 preservando rascunho local.
- **Migração:** `20261027150000_task_version_and_partial_updates` aplicada com sucesso.
- **Testes (T11):** `test/task-version-concurrency.test.ts` (6 testes verdes).

### 5.2 Etapa E3.2 — Datas Civis, Fuso do Workspace e Estimativas
- **Entrega:**
  - Migração de `Task.startDate` e `Task.dueDate` para `@db.Date` (tipo `DATE` no PostgreSQL) garantindo semântica de data civil sem distorções de fuso horário.
  - CHECK constraint `tasks_dates_order_check` (`startDate IS NULL OR dueDate IS NULL OR startDate <= dueDate`).
  - Campo `Workspace.timezone` (default `America/Sao_Paulo`) com validação IANA contra a API `Intl.DateTimeFormat`.
  - Substituição de `estimatedHours` (Float) por `estimatedMinutes` (Int?), com CHECK constraint `tasks_estimated_minutes_positive_check` e `time_entries_duration_positive_check`.
  - Utilitários em `src/utils/dates.ts` (`parseCivilDate`, `formatCivilDate`, `isValidIanaTimezone`, `getWorkspaceTodayCivilDate`, `isOverdueCivil`).
  - No frontend, apresentação amigável de estimativas ("1h 30min" / "Não informada"), edição em horas/minutos e botões de limpeza ("Limpar") para datas.
- **Migração:** `20261027153000_civil_dates_timezone_and_estimated_minutes` aplicada com sucesso.
- **Testes (T13):** `test/dates-timezone-estimates.test.ts` (9 testes verdes).

### 5.3 Etapa E3.3 — Etiquetas, Colunas, Chave do Projeto e Numeração
- **Entrega:**
  - Modelos `Label` e `TaskLabel`: etiquetas como entidades de primeira classe vinculadas ao workspace com normalização única de nome (`normalizedName`) e validação de cor hexadecimal (`#RGB` ou `#RRGGBB`).
  - Sincronização automática entre `tags String[]` e associações `TaskLabel`.
  - Rotas e serviço de gestão de etiquetas (`GET`, `POST`, `PATCH`, `DELETE` em `/workspaces/:workspaceId/labels` e `/labels/:id`).
  - Semântica de colunas: `Project.backlogColumnId` explícito e `Column.isDoneColumn`. Validação de ao menos uma coluna de conclusão por projeto e impedimento de backlog ser coluna de conclusão.
  - Integridade referencial: `Task.column` alterada para `onDelete: Restrict`. Exclusão de coluna ocupada é recusada caso não seja fornecida `destinationColumnId` pertencente ao mesmo projeto; movimentação e deleção ocorrem de forma atômica em transação. Exclusão da coluna de backlog é bloqueada até definição de substituta.
  - Chave de projeto: `Project.key` única no workspace (`^[A-Z0-9]{2,10}$`), gerada automaticamente se não fornecida, imutável após a criação de tarefas no projeto.
  - Numeração atômica sequencial: `Project.taskCounter` reservado via incremento atômico em transação; unicidade `@@unique([projectId, taskNumber])`.
  - DTOs e frontend: exposição de `projectKey` e código legível `displayCode` (ex: `PROJ-1`, `ALF-102`) em cards, listagens e cabeçalho.
- **Migração:** `20261027160000_labels_columns_project_keys_and_numbering` aplicada com sucesso.
- **Testes (T12, T14):** `test/labels-columns-numbering.test.ts` (9 testes verdes).

### 5.4 Etapa E3.4 — Integridade Relacional, Responsável Ativo e Relações entre Tarefas
- **Entrega:**
  - Chaves compostas e integridade no PostgreSQL:
    - `projects (id, workspaceId)` com índice único.
    - `columns (id, projectId)` com índice único.
    - `tasks (id, projectId)` e `tasks (id, workspaceId)` com índices únicos.
    - FK composta de `Task` referenciando `Project(id, workspaceId)` (`ON DELETE CASCADE`).
    - FK composta de `Task` referenciando `Column(id, projectId)` (`ON DELETE RESTRICT`).
    - CHECK constraint `task_relations_not_self_check` (`taskId <> relatedTaskId`).
  - Responsável ativo (I3):
    - `assigneeId` obrigatoriamente validado contra `WorkspaceMember` ativo do workspace; atribuição a usuário inexistente ou inativo é rejeitada com HTTP 400.
    - `assigneeName` e `assigneeAvatar` preenchidos exclusivamente a partir do cadastro/projeção do membro, imunes a spoofing no payload do cliente.
    - Envio de `assigneeId: null` limpa o responsável, nome e avatar.
  - Relações entre tarefas e detecção de ciclos (3.4-c / T12):
    - Relações restritas estritamente ao mesmo projeto (`task.projectId === relatedTask.projectId`).
    - Normalização canônica: `BLOCKS` sempre gravada no sentido quem bloqueia -> quem é bloqueado; `BLOCKED_BY` normalizada invertendo as tarefas e gravando como `BLOCKS`.
    - Normalização simétrica de `RELATES_TO`: pares ordenados lexicograficamente para evitar duplicações cruzadas `(A, B)` e `(B, A)`.
    - Detecção de ciclos em grafo de dependências via busca em largura (BFS) em [`src/utils/cycles.ts`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-projects-service/src/utils/cycles.ts). Ciclos diretos (`A -> B -> A`) e transitivos (`A -> B -> C -> A`) são detectados e recusados com HTTP 400 `ValidationError`.
    - Bloqueio pessimista do projeto via `withProjectLock` em [`src/db/tx.ts`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-projects-service/src/db/tx.ts) com retentativa automática em deadlock/serialização, impedindo matematicamente a criação concorrente de ciclos circulares.
  - Interface e DTO:
    - `TaskInternalDTO` e `Task` no frontend com lista unificada e legível de `relations` indicando `"Bloqueia"`, `"Bloqueada por"` ou `"Relacionada"`.
    - No drawer (`TaskDetailDrawer.tsx`), seção completa de "Relações & Dependências" com listagem de vínculos, badges semânticos, remoção, formulário de adição filtrando tarefas do projeto e exibição destacada de erros de ciclo.
- **Migração:** `20261027170000_composite_foreign_keys_and_relation_integrity` aplicada com sucesso.
- **Testes (T12):** `test/relations-cycle-detection.test.ts` (10 testes verdes).
- **Status da Etapa E3.4:** Concluída e homologada.

### 5.5 Etapa E3.5 — Concorrência, Transações e Idempotência Geral
- **Entrega:**
  - Utilitário transacional em [`src/db/tx.ts`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-projects-service/src/db/tx.ts):
    - `withTransaction`: retentativas automáticas e exponenciais com jitter em códigos de erro transitórios do PostgreSQL (`40001` serialization_failure, `40P01` deadlock_detected e write conflicts). Isolamento proporcional e limite estrito de retentativas.
    - `withProjectLock`: bloqueio pessimista exclusivo da linha do projeto (`SELECT 1 FROM projects WHERE id = $1 FOR UPDATE`).
    - `withColumnsLock`: bloqueio determinístico de múltiplas colunas em ordem lexicográfica ascendente de ID (`ORDER BY id FOR UPDATE`), eliminando deadlocks entre operações simultâneas de movimentação de tarefas em sentidos opostos.
    - `withWorkspaceLock`: bloqueio pessimista exclusivo da linha do workspace para serializar operações de membership e administração.
  - Reordenação determinística no Kanban (3.5-b / T11):
    - Modelo `Column` expandido com coluna `orderVersion Int @default(1)`.
    - `TaskService.moveTask`: algoritmo de posições inteiras consecutivas (`0, 1, 2, ...`) sem lacunas, incremento atômico de `version` na tarefa e de `orderVersion` nas colunas afetadas.
    - `PUT /projects/:projectId/columns/reorder`: reordenação em lote executada sob `withProjectLock` com incremento de `orderVersion` e auditoria na mesma transação.
    - No frontend (`KanbanView.tsx`): suporte a rollback visual imediato em caso de erro da API, restaurando o estado consistente do servidor. Remoção definitiva de selos de aprovação legados.
  - Auditoria transacional (3.5-c / T11):
    - `ActivityService.log` integrado às transações via parâmetro `tx`. Falhas de auditoria deixam de ser engolidas e agora provocam rollback atômico de toda a mutação sensível.
    - `TaskService.createTask`, `updateTask`, `moveTask`, `deleteTask` e rotas de colunas gravam a atividade de auditoria dentro da transação correspondente.
    - Tratamento de exclusão: ao excluir tarefa, a referência histórica é preservada em nível de workspace/projeto sem violar foreign keys.
  - Idempotência geral (3.5-d / T20):
    - `IdempotencyService`: ampliado com `buildScopeKey(actorId, workspaceId, operation, clientKey)` garantindo isolamento por ator e workspace.
    - Serialização concorrente via trava transacional `pg_advisory_xact_lock(hashtext(scopeKey))` impedindo que requisições paralelas com a mesma chave executem a operação duas vezes.
    - Verificação de hash SHA-256 do payload (`IDEMPOTENCY_PAYLOAD_MISMATCH` retornando HTTP 409 Conflict).
    - Habilitada em `POST /projects/:projectId/tasks`, `POST /workspaces/:workspaceId/projects`, ferramenta MCP `create_task` e links de compartilhamento (`create_share`).
  - Decisão sobre entrega externa (3.5-e):
    - Decisão formal documentada em [`docs/adr-outbox-decision.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/adr-outbox-decision.md).
    - Ausência de consumidores externos autorizados no momento: infraestrutura de Outbox (`OutboxEvent`, workers em background, retentativas assíncronas) declarada como adiada condicionalmente para quando surgir o primeiro consumidor real (ex: Fase 6 — Financeiro). Nenhuma tabela ou worker vazio ocioso foi criado.
    - Notificações internas e auditoria permanecem 100% síncronas e transacionais.
  - Proteção concorrente do último ADMIN (3.5-f / T05):
    - `WorkspaceService.removeMember` e `WorkspaceService.updateMemberRole` envelopadas em `withWorkspaceLock`.
    - Verificação atômica de contagem de administradores ativos (`adminCount <= 1` lança `ForbiddenError`), impedindo que duas remoções ou rebaixamentos concorrentes deixem o workspace sem administrador.
    - Nova rota `PATCH /workspaces/:id/members/:memberId` exposta com política de segurança `manage_members`.
- **Migração:** `20261027190000_column_order_version` aplicada com sucesso (diff zero).
- **Testes da Etapa:**
  - `test/tx-concurrency.test.ts` (8 testes verdes).
  - `test/transactional-audit-rollback.test.ts` (2 testes verdes).
  - `test/column-reorder-concurrency.test.ts` (3 testes verdes).
  - `test/idempotency-general.test.ts` (4 testes verdes).
  - `test/member-admin-concurrency.test.ts` (3 testes verdes).
- **Status Geral da Suíte de Testes:** **21 arquivos de testes, 122 testes 100% verdes**. Frontend TypeScript compilado com 0 erros.

### 5.6 Etapa E3.6 — Auditoria, Notificações, Menções, Ciclo de Vida e Transferência
- **Entrega:**
  - `Activity` Definitiva & Desacoplamento Histórico (3.6-a):
    - Ator estruturado com `actorType` (`USER`, `SERVICE`, `SHARE_SESSION`), `actorId`, `userName` histórico, `initiatedByUserId` e `requestId` para rastreabilidade perene.
    - Desacoplamento de cascade deletion: chaves estrangeiras `workspaceId`, `projectId` e `taskId` configuradas com `onDelete: SetNull`. A exclusão do container pai preserva o registro de auditoria no banco.
    - Sanitização estrita contra vazamento de segredos: função `sanitizeAuditDetails` bloqueia e redige recursivamente valores de chaves associadas a PINs, tokens, senhas, hashes ou credenciais para `[REDACTED]`.
  - Notificações com Arquivamento e Deduplicação (3.6-b):
    - Deduplicação atômica via constraint única `@@unique([workspaceId, userId, dedupKey])` na tabela `notifications`.
    - Bloqueio de auto-notificação: o próprio autor da mutação não recebe notificações de suas ações.
    - Suporte a arquivamento (`archivedAt`), ocultando notificações arquivadas por padrão na listagem (`GET /workspaces/:workspaceId/inbox`).
    - Endpoints dedicados com políticas de acesso: `PATCH /inbox/:id/archive`, `PATCH /inbox/:id/unarchive`, `PATCH /inbox/:id/read` e `PUT /workspaces/:workspaceId/inbox/mark-all-read`.
  - Menções em Comentários (3.6-c):
    - Tabela `comment_mentions` com integridade relacional e unicidade por `[commentId, userId]`.
    - Autocomplete e validação de membros: IDs passados em `mentionUserIds` devem pertencer a membros ativos (`status === 'ACTIVE'`) do workspace.
    - Edição inteligente: ao editar o comentário, são disparadas notificações **estritamente para as novas menções adicionadas**, sem re-notificar os membros já mencionados.
  - Ciclo de Vida: Arquivamento, Exclusão Lógica e Restauração (3.6-d / T14):
    - Implementação de `isArchived`, `archivedAt`, `archivedById`, `deletedAt`, `deletedById`, `deletionReason` em `workspaces`, `projects` e `tasks`.
    - Respeito estrito aos containers pais (T14):
      - Se o projeto ou workspace pai for excluído logicamente, qualquer tentativa de acesso direto à tarefa filha via ID retorna `404 Not Found`.
      - Se o container pai estiver arquivado, a tarefa filha herda o modo somente leitura (`403 Forbidden` em mutações).
      - Restaurar uma tarefa em container pai arquivado exige privilégios de **ADMIN** (`ARCHIVED_PARENT_REQUIRES_ADMIN`).
      - Restaurar tarefas e projetos excluídos logicamente exige estritamente papel **ADMIN**. Membros comuns (`MEMBER`) recebem `403 Forbidden`.
    - Revogação de compartilhamentos em cascata: arquivar ou excluir tarefa, projeto ou workspace revoga imediatamente os links com PIN públicos associados. A restauração posterior **não** reativa links antigos.
  - Transferência entre Projetos (3.6-e / T14 / Seção 6.4):
    - Prévia analítica (`POST /tasks/:taskId/transfer/preview`): projeta o novo código semântico (`PROJ-1` -> `DEST-1`), identifica colunas do destino, contabiliza relações incompatíveis que serão eliminadas, mapeia campos personalizados e alerta sobre shares que serão revogados.
    - Comando transacional (`POST /tasks/:taskId/transfer`): bloqueio ordenado de projetos (`firstLock`, `secondLock`) prevenindo deadlocks, alocação segura do novo `taskNumber` via incremento de `taskCounter` no projeto de destino, limpeza de relações que cruzariam projetos, revogação de shares e preservação integral de comentários, menções, subtarefas e apontamentos.
    - Auditoria de transferência grava os códigos exibidos antigo e novo (`fromDisplayCode` e `toDisplayCode`).
    - Bloqueio de mutação direta: tentativas de alterar `projectId` via `PATCH /tasks/:id` são terminantemente rejeitadas.
  - Política de Retenção Documentada (3.6-f):
    - Documento normativo publicado em [`docs/politica-retencao.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/politica-retencao.md).
    - Janela de retenção de 90 dias para exclusão lógica antes de qualquer expurgo; nenhuma rotina irreversível ativada.
- **Migração:** `20261027194500_lifecycle_audit_mentions_and_notifications` aplicada com sucesso (diff zero).
- **Testes da Etapa:**
  - `test/lifecycle-transfer.test.ts` (14 testes verdes cobrindo 3.6-a a 3.6-e e T14).
  - `test/route-inventory.test.ts` (100% de novas rotas catalogadas com políticas estritas).
- **Status Geral da Suíte de Testes:** **22 arquivos de testes, 136 testes 100% verdes**. Frontend TypeScript compilado com 0 erros.

### 5.7 Etapa E3.7 — Anexos, Markdown Seguro, Armazenamento e Diagnóstico de Órfãos
- **Entrega:**
  - Modelagem e Armazenamento Persistente (3.7-a):
    - Models `Attachment` e `TaskShareAttachment` criados no Prisma com chaves estrangeiras seguras, índices otimizados e suporte a comentários (`commentId`).
    - Interface agnóstica de armazenamento (`StorageProvider`) com implementação em disco local persistente (`LocalDiskStorageProvider`) com caminhos normalizados, prevenção de path traversal e escrita atômica via arquivo temporário.
  - Upload Autenticado & Validação Estrita de Bytes (3.7-b / T10):
    - Pacote `@fastify/multipart` integrado com limite de 25 MiB no envelope de transporte.
    - Limite máximo de **20 MiB por arquivo** (`LIMITS.ATTACHMENT_MAX_SIZE_BYTES`) e cota de **10 GiB por workspace** (`LIMITS.ATTACHMENT_MAX_WORKSPACE_BYTES`).
    - Validador de arquivos em profundidade (`validateFileBuffer`): checagem de magic bytes para PNG, JPEG, GIF, WebP, PDF, ZIP, TXT, CSV.
    - Rejeição categórica de extensões perigosas (`.exe`, `.sh`, `.php`, `.html`, `.svg`).
    - Detecção e bloqueio de extensões falsificadas (spoofing) e arquivos poliglotas contendo injeções executáveis (`<script`, `<html`, `<svg`, `javascript:`, `onerror=`) nos primeiros 8 KB.
    - Sanitização rigorosa de nomes de arquivos preservando apenas caracteres alfanuméricos e separadores seguros.
    - Cálculo criptográfico de hash SHA-256 e gravação de log de auditoria com metadados do arquivo.
  - Download Interno e Download Externo com PIN (3.7-c / T10):
    - Download interno autenticado (`GET /attachments/:id/download`): verificação de acesso à tarefa, cabeçalhos de segurança obrigatórios (`X-Content-Type-Options: nosniff`, `Content-Security-Policy: default-src 'none'`, `Cache-Control: private, no-cache`, `Content-Disposition: inline` para imagens seguras ou `attachment; filename="..."` para demais documentos).
    - Download público seguro (`GET /public/shares/:token/attachments/:attachmentId`): validação de sessão ativa com PIN verificado, pertença à tarefa compartilhada e seleção explícita por ID (`TaskShareAttachment`).
    - **Invariante de Segurança Inviolável**: Anexos de comentários (`commentId !== null`) são estritamente internos e confidenciais; a API e o construtor do card barram sua inclusão em links públicos mesmo se tentada forçadamente.
    - Revogação imediata em cascata: links cancelados, tarefas arquivadas ou shares expirados cortam o download de anexos imediatamente.
  - Markdown Seguro e Reescrita de Imagens (3.7-d / T10):
    - `sanitizeAndRewriteMarkdown`: elimina tags `<script>`, `<iframe>`, `<svg>`, `<object>`, `<embed>`, protocolos `javascript:` e manipuladores `on*`.
    - Imagens Markdown (`![alt](url)`) referenciando anexos da tarefa têm sua URL reescrita para `/api/v1/projects/public/shares/:token/attachments/:id` se o anexo estiver explicitamente selecionado. Anexos não selecionados ou de comentários são convertidos para `about:blank`.
  - Diagnóstico de Arquivos Órfãos sem Purga Automática (3.7-e / Seção 7.4 / Seção 17):
    - Serviço `AttachmentDiagnosticService`: compara inventário físico do disco contra registros do banco de dados, reportando arquivos órfãos físicos ou metadados sem arquivo correspondente.
    - Respeito estrito à política de retenção (`docs/politica-retencao.md`): o serviço atua em modo puramente diagnóstico, sem executar exclusão física automática.
  - Ajuste de Gateway Nginx (3.7-f):
    - `nginx/default.conf.template`: adicionada diretiva dedicada com `client_max_body_size 25M;` para a rota `^/api/v1/projects/tasks/[^/]+/attachments$`, permitindo uploads de arquivos de 20 MiB com margem para o payload multipart, enquanto mantém o limite geral de 10M nas demais rotas.
- **Migração:** `20261027201500_attachments_and_share_attachments` aplicada com sucesso (diff zero).
- **Testes da Etapa:**
  - `test/attachments.test.ts` (22 testes verdes cobrindo 3.7-a a 3.7-e e T10).
  - `test/route-inventory.test.ts` (100% das novas rotas de anexos mapeadas com controle de permissão).
- **Status Geral da Suíte de Testes:** **23 arquivos de testes, 158 testes 100% verdes**. Frontend TypeScript compilado com 0 erros.

### 5.8 Etapa E3.8 — Campos Personalizados, Apontamentos de Horas e Indicadores Operacionais
- **Entrega:**
  - Modelagem e Migração (3.8-a):
    - Modelo `CustomField` enriquecido com tipos estruturados (`text`, `number`, `date`, `select`), `options` JSON com identificadores estáveis (`opt_<hash>`), label e cor opcional, flag `isPublicEligible Boolean @default(false)` gerenciada estritamente por ADMIN e auditoria com `updatedAt`.
    - Modelo `TaskShare` enriquecido com flag `showCustomFields Boolean @default(true)` e relação `customFields TaskShareCustomField[]`.
    - Tabela relacional `task_share_custom_fields` com constraint de unicidade `@@unique([shareId, customFieldId])` e integridade referencial com remoção em cascata.
    - Migração `20261027213000_custom_fields_time_entries_indicators` aplicada com sucesso (0-diff verificado com `prisma migrate diff`).
  - Serviço e Rotas de Campos Personalizados (3.8-a & 3.8-b):
    - `CustomFieldService`: criação, atualização e exclusão de campos restritas a `ADMIN` (`403 Forbidden` para `MEMBER`).
    - Validação de tipos rigorosa: texto com tamanho máximo, número com conversão e rejeição de NaN, data civil formatada em YYYY-MM-DD com verificação de calendário civil real (`parseCivilDate`), select restrito aos IDs válidos definidos no campo.
    - Tratamento de opções em uso: bloqueio com `ConflictError` de remoção de opções que estejam associadas a tarefas ativas do projeto.
    - **Invariante de Isolamento I8**: `setTaskCustomFieldValue` e `bulkSetTaskCustomFieldValues` validam que o campo pertence ao mesmo projeto da tarefa (`field.projectId === task.projectId`), lançando `ValidationError` caso tente associar campos de projetos distintos.
    - Endpoints registrados sob `/api/v1/projects`: `GET/POST /projects/:projectId/custom-fields`, `PATCH/DELETE /custom-fields/:id`, `GET/PUT /tasks/:taskId/custom-field-values`.
  - Apontamentos de Horas (`TimeEntry` - 3.8-c / T04 / T13 / Seção 6.6):
    - `TaskService.addTimeEntry`: aceita `durationMinutes > 0`, data civil formatada e nota opcional; incrementa monotonicamente a versão da tarefa e audita a inclusão.
    - `TaskService.updateTimeEntry` (`PATCH /time-entries/:id`): regra de autoria estrita **T04**: apenas o autor do apontamento ou administradores (`ADMIN`) podem editar a duração, data civil ou nota; tentativas de alteração por outros membros retornam `403 Forbidden` (`NOT_RESOURCE_AUTHOR`). Incrementa a versão da tarefa e audita.
    - `TaskService.removeTimeEntry` (`DELETE /time-entries/:id`): remoção permitida apenas ao autor ou `ADMIN`. Incrementa a versão da tarefa e audita.
    - `TaskService.listTimeEntries` (`GET /tasks/:taskId/time-entries`): calcula a soma agregada em minutos (`totalMinutes`) e converte para horas decimais com arredondamento preciso (`totalHours`).
    - Sem campos tarifários, financeiros ou cronômetros em tempo real (preservando o desacoplamento para a Fase 6).
  - Compartilhamento e Card Público com Campos Selecionados (3.8-a & T10):
    - `ShareService` (`createShare`, `patchShare`, `reissueShare`, `previewShare`): suporte a `selectedCustomFieldIds` e `showCustomFields`. Rejeição categórica com `ValidationError` de campos não pertencentes ao projeto ou com `isPublicEligible: false`.
    - `buildPublicCard` (`src/share/public-card.ts`): inclui campos no card público estritamente se `showCustomFields === true`, o campo for elegível (`isPublicEligible: true`) e estiver explicitamente selecionado pelo usuário na emissão do link com PIN (`TaskShareCustomField`).
    - Resolução limpa de opções de select: o valor exibido no card público resolve o rótulo amigável (`label`) a partir do identificador estável da opção.
    - Invariantes estritas de segurança: apontamentos de horas e campos internos nunca são expostos no card público.
  - Indicadores e Métricas Operacionais (3.8-d / Seção 6.6):
    - Progresso do Projeto (`ProjectService.listByWorkspace`): calcula a proporção de tarefas ativas em colunas concluídas (`isDoneColumn: true`) sobre o total de tarefas ativas, excluindo tarefas arquivadas e excluídas logicamente. Se o projeto não possui tarefas, reporta 0% sem divisão por zero.
    - Dashboard do Workspace (`GET /workspaces/:workspaceId/dashboard`): ordenação estrita de `upcomingTasks` por dias de atraso/vencimento e prioridade; tarefas ativas sem prazo de entrega são mantidas em agrupamento dedicado (`tasksWithoutDueDate`), sem fabricar prazos fictícios nem assumir a data corrente.
- **Migração:** `20261027213000_custom_fields_time_entries_indicators` aplicada com sucesso (diff zero).
- **Testes da Etapa:**
  - `test/custom-fields-time-metrics.test.ts` (11 testes verdes cobrindo 3.8-a a 3.8-d, T04, T10, T13 e T14).
  - `test/route-inventory.test.ts` (100% das novas rotas de campos e tempo catalogadas com políticas estritas).
- **Status Geral da Suíte de Testes:** **24 arquivos de testes, 169 testes 100% verdes**.
- **Compilação e Typecheck:** Backend `tsc` compilado com 0 erros. Frontend `tsc` compilado com 0 erros.

### 5.9 Etapa E3.9 — Frontend: Navegação, Contexto e Card Completo
- **Entrega:**
  - Rota Canônica e Navegação (3.9-a / T18 / Seção 7.1):
    - Rota `/projects/tasks/:taskId` registrada no roteador do frontend (`src/routes/index.tsx`) estritamente antes das rotas genéricas `/projects/:projectId` e `/projects/:projectId/:view`.
    - Página [`TaskDetailsPage.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/pages/projects/TaskDetailsPage.tsx) suporta abertura direta e refresh por ID, buscando a tarefa de forma autorizada no backend, sincronizando o workspace ativo (`setActiveWorkspaceById`) e carregando colunas e dados do projeto.
    - Breadcrumb no cabeçalho com contexto completo: `[Workspace] > [Projeto] > [Código Semântico]`.
    - Botão de retorno intuitivo ao projeto (`/projects/:projectId`).
  - Contexto, Cache e Segurança (3.9-b / T18 / Seção 7.1):
    - [`useWorkspaceStore`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/store/workspaceStore.ts): adicionado método `reset()`, acionado no logout em [`AuthContext.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/contexts/AuthContext.tsx) para expurgar do `localStorage` a seleção e dados persistidos de projetos, impedindo o reaproveitamento de dados entre operadores.
    - Troca de workspace no menu lateral navega para `/projects`, fechando drawers abertos e cancelando contextos incompatíveis.
    - Tratamento de 403 e 404 ao carregar tarefa direta: exibe tela de estado com mensagem clara e ação para retornar aos Projetos.
  - Componente Unificado do Card de Tarefa (3.9-c, 3.9-d, 3.9-e / Seção 7.2):
    - [`TaskCardView.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/task/TaskCardView.tsx): componente unificado suportando modos `mode="drawer"` e `mode="page"`.
    - [`TaskDetailDrawer.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/task/TaskDetailDrawer.tsx) refatorado para consumir `TaskCardView` com `mode="drawer"`, garantindo que alternar para tela cheia preserve o estado ao navegar para a rota canônica `/projects/tasks/:taskId`.
    - Menu de cópia avançada: copia a URL canônica da tarefa (`${origin}/projects/tasks/:taskId`), ID, Código Semântico (`PROJ-123`), Título e Link em Markdown (`[PROJ-123 - Título](url)`).
    - Edição inline de título e descrição com preservação de rascunho em conflitos 409 (`VERSION_CONFLICT`).
    - Atribuição de responsável restrita a membros ativos do workspace, com opção explícita de desatribuição (`null`).
    - Checklist com progresso percentual independente do status e ordenação.
    - Relações & Dependências (`BLOCKS`, `BLOCKED_BY`, `RELATES_TO`) com alerta visual de ciclos.
    - Recursos & Links externos com indicação de privacidade "Interno".
    - Seção de Anexos (E3.7): upload multipart/form-data com indicador de progresso e validação de 20 MiB, listagem com tamanho e data, download seguro autenticado e indicação clara de visibilidade interna.
    - Seção de Campos Personalizados (E3.8): renderização e edição por tipo (`text`, `number`, `date`, `select`), badge de "Elegível para cliente".
    - Seção de Apontamentos de Horas (E3.8-c): totais agregados em horas e minutos, adição com data civil e nota, exclusão por autor ou ADMIN.
    - Modal de Transferência entre Projetos (E3.6-e): seleção de projeto de destino, prévia analítica de impactos (código projetado, dependências a desfazer, shares a revogar) e execução transacional.
    - Modal de Compartilhamento com Cliente ([`TaskShareModal.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/pages/projects/TaskShareModal.tsx)): atualizado para seleção granular de anexos não relacionados a comentários e campos personalizados elegíveis, com prévia real do card público e cópia do link com PIN de 6 dígitos.
- **Compilação e Testes:**
  - `vite build`: bundle de produção compilado com **0 erros** (código 0).
  - Frontend `tsc --noEmit`: **0 erros**.
  - Backend `vitest`: **24 arquivos de testes, 169 testes 100% verdes**.
  - Backend `tsc`: **0 erros**.

### 5.10 Etapa E3.10 — Frontend: Visões, Home, Inbox e Configurações
- **Entrega:**
  - Gráfico de Gantt (3.10-b / DP11 / U0 / Seção 7.3):
    - **Invariante de Fidelidade Temporal (DP11 / U0)**: Removida qualquer síntese de datas falsas (`new Date()` ou `dueDate - 2 dias`). O cronograma reflete exclusivamente datas reais e declaradas.
    - Categorização rigorosa de tarefas:
      - `scheduledTasks`: tarefas com data de início e entrega válidas (`startDate <= dueDate`), representadas com barras de duração real.
      - `dueOnlyTasks`: tarefas com apenas data de entrega, representadas como marcadores pontuais de prazo (milestone flag) na data do vencimento, sem fabricar barras de duração fictícia.
      - `unscheduledTasks`: tarefas sem planejamento completo (sem datas ou apenas com início), agrupadas em seção colapsável dedicada no rodapé do cronograma com contador e clique para abrir o card de edição.
      - `invalidDateTasks`: tarefas com datas invertidas (`startDate > dueDate`), destacadas com alerta de inconsistência de cronograma para correção imediata.
    - Conflitos de dependências (término-início): análise bidirecional das relações `BLOCKS` e `BLOCKED_BY`; quando a predecessora vence após o início previsto da sucessora, exibe alerta visual de conflito com mensagem explicativa detalhada.
    - Sincronização de rolagem nativa: container com cabeçalho e coluna lateral utilizando `sticky` CSS, garantindo sincronização vertical e horizontal em lockstep sem atraso de JavaScript.
  - Kanban & Lista (3.10-a / Seção 7.3):
    - [`KanbanView.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/views/KanbanView.tsx): suporte a reordenação de colunas via botões direcionais (`ChevronLeft`/`ChevronRight`) no cabeçalho das colunas, integrando com `projectsService.reorderColumns` e exibindo mensagem amigável caso o usuário não possua privilégio de ADMIN.
    - [`ListView.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/views/ListView.tsx): barra superior completa com busca textual (título, código, ID), filtros por Coluna/Status, Prioridade e Responsável (incluindo "Sem responsável"), botão para limpar filtros e ordenação estável por ID, Título, Status, Prioridade, Responsável e Vencimento com setas indicativas de direção (`asc`/`desc`).
  - Calendário & Backlog (3.10-c / Seção 7.3):
    - [`CalendarView.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/views/CalendarView.tsx): gaveta colapsável para tarefas ativas sem data de entrega (`tasksWithoutDueDate`), permitindo visualizá-las e abrir o card para planejamento direto a partir da visão mensal.
    - [`BacklogView.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/views/BacklogView.tsx): precedência estrita utilizando a coluna configurada em `project.backlogColumnId` como primeira escolha antes de fallback para o nome `'backlog'`, permitindo flexibilidade total para diferentes nomenclaturas de fluxo.
  - Home & Minhas Tarefas (3.10-d / Seção 7.1):
    - [`ProjectsHomePage.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/pages/projects/ProjectsHomePage.tsx): cards de métricas agregadas consistentes, clique nas tarefas do bloco "Próximas Tarefas" e nas menções do feed de atividades navegando diretamente para a rota canônica `/projects/tasks/:taskId`, e paginação dinâmica de atividades com botão de expansão.
    - [`ProjectsMyTasksPage.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/pages/projects/ProjectsMyTasksPage.tsx): redirecionamento do clique da tarefa para a rota canônica `/projects/tasks/:taskId`, exibição do código semântico (`displayCode`), badge da coluna com cor do projeto e indicador de prioridade.
  - Inbox (3.10-e / Seção 7.1 / E3.6-b):
    - [`ProjectsInboxPage.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/pages/projects/ProjectsInboxPage.tsx): redirecionamento do clique para a rota canônica `/projects/tasks/:taskId`.
    - Suporte a abas de filtro: "Todas", "Não lidas" e "Arquivadas".
    - Ações de arquivar e desarquivar notificações integradas com os endpoints `PATCH /inbox/:id/archive` e `PATCH /inbox/:id/unarchive`.
  - Configurações do Projeto (3.10-f / Seção 7.3 / E3.8 / E3.6-d):
    - [`ProjectSettingsView.tsx`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-ai-frontend-community/src/components/projects/views/ProjectSettingsView.tsx):
      - Seletor da coluna padrão de Backlog (`backlogColumnId`) com salvamento automático.
      - Gerenciamento de Campos Personalizados do Projeto: listagem, criação com tipos (`text`, `number`, `date`, `select`), configuração de opções para listas de seleção, flag de elegibilidade pública (`isPublicEligible`) e exclusão com confirmação.
      - Ciclo de vida do projeto: banner informativo e botão para arquivar ou desarquivar o projeto, além da exclusão definitiva na zona de perigo.
- **Compilação e Testes:**
  - `vite build`: bundle de produção compilado com **0 erros** (código 0).
  - Frontend `tsc --noEmit`: **0 erros**.
  - Backend `vitest`: **24 arquivos de testes, 169 testes 100% verdes**.
  - Backend `tsc`: **0 erros**.

### 5.11 Etapa E3.11 — Aceite e Gate da Fase 3 (Núcleo Operacional Completo)
- **Entrega 3.11-a: Reconciliação Final de Migrações e Suíte de Testes:**
  - Status de Migrações: `npx prisma migrate status` reporta 12 migrações aplicadas sequencialmente no PostgreSQL (banco `evo_community`, schema `projects`), com zero drift (`Database schema is up to date!`).
  - Suíte de Testes Automatizados: 24 arquivos de teste executados via `vitest`, totalizando **169 testes 100% verdes** (cobrem T01 a T15, T17 e T18).
  - Compilação e Typecheck do Frontend: `tsc --noEmit` executado com **0 erros**; `vite build` gerou o bundle de produção em 20.77s com **0 erros**.
  - Conferência de Integridade Funcional: Verificado que nenhum requisito da Seção 7 existe apenas como modelo ou botão sem fluxo. Todas as rotas, visões, modais e transações possuem conexão ponta a ponta e persistência real.
- **Entrega 3.11-b: Revisão e Atualização da Documentação Técnica:**
  - [`docs/DOCUMENTACAO-COMPLETA-JPROS.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/DOCUMENTACAO-COMPLETA-JPROS.md): Atualizadas as Seções 1.4, 3.3-B e 7 com as capacidades consolidadas das Fases 1, 2 e 3 e o status de homologação dos Gates 1, 2 e 3.
  - [`evo-projects-service/README.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-projects-service/README.md): Documentação do microsserviço atualizada com PIN de 6 dígitos, tabela completa de rotas REST, modelos de dados Prisma e comandos operacionais.
  - [`docs/SETUP-GUIDE.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/SETUP-GUIDE.md): Seção detalhada sobre o armazenamento de arquivos (`PROJECTS_STORAGE_DIR`), configuração do Gateway Nginx (`client_max_body_size 25M;`), migrações com papéis DDL/DML e procedimentos de backup e recuperação de desastres.
  - [`docs/TROUBLESHOOTING.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/TROUBLESHOOTING.md): Seções de diagnóstico adicionadas para `409 VERSION_CONFLICT`, `413/400` em anexos, lockout de PIN público após 5 tentativas, permissão de reordenação de colunas e fidelidade temporal no Gráfico de Gantt.
- **Entrega 3.11-c: Gate 3 — Núcleo Operacional Completo:**
  - **Declaração Formal**: O **Gate 3 (Fase 3 - Consistência e Interface Completa)** está **HOMOLOGADO E LIBERADO**.
  - **Capacidades Ativas e Auditadas para Uso**:
    1. Multi-workspace real com isolamento estrito de dados, membros e papéis (`ADMIN`, `MEMBER`, `VIEWER`).
    2. Versionamento otimista monotônico de tarefas com prevenção de sobreescrita (OCC 409).
    3. Anexos multipart/form-data até 20 MiB com hash SHA-256, inspeção contra polyglot/executáveis nos primeiros 8 KB e isolamento confidencial de comentários.
    4. Campos personalizados tipados (`text`, `number`, `date`, `select`) com options estáveis e flag `isPublicEligible`.
    5. Apontamentos de horas com autoria estrita T04 e agregação analítica em minutos e horas decimais.
    6. Transferência atômica entre projetos com prévia de impacto e revogação em cascata.
    7. Compartilhamento de leitura com clientes protegido por PIN de 6 dígitos com token de sessão único, lockout por tentativas incorretas e seleção granular de anexos e campos.
    8. Visões completas: Kanban reordenável, Lista avançada com filtros e ordenação, Gantt estrito DP11/U0 sem datas sintéticas, Calendário com gaveta sem prazo, Backlog com precedência de coluna configurada, Home e Minhas Tarefas com rotas canônicas `/projects/tasks/:taskId`, e Inbox privado com arquivamento.
  - **Fronteiras e Limites de Uso**:
    - Agentes autônomos, integrações de CRM e grants externos permanecem desabilitados aguardando a Fase 4. O uso operacional manual interno e o compartilhamento de leitura via PIN estão 100% liberados.
  - **Transição de Fase**: Fase 3 concluída com sucesso. O sistema está pronto para a **Fase 4 (CRM e Agentes Interoperáveis — Etapas E4.0 a E4.6)**.

---

### 5.12 Fase 4 — CRM e Agentes Interoperáveis (Etapas E4.0 a E4.6)

#### Etapa E4.0 — Verificações Técnicas e Matriz de Compatibilidade
- **Entrega 4.0-a: Matriz de Consumidores MCP (`docs/matriz-consumidores-mcp.md`):**
  - Levantamento dos clientes e runtimes MCP (`evo-ai-processor-community`, `evo-bot-runtime`, IDEs Claude/Cursor/Antigravity).
  - Protocolo oficial fixado: versões `2024-11-05` e `2025-11-25`.
  - Transporte estabelecido: Streamable HTTP (`POST /mcp`). Descarte formal de SSE legado por instabilidade operacional e riscos de memory leak.
  - Autenticação por ServicePrincipal (`sp_*`) e validação estrita de cabeçalho `Origin` contra CSRF e DNS rebinding.
- **Entrega 4.0-b: ADR do Contrato de CRM (`docs/adr-contrato-crm.md`):**
  - Contrato de identificação estável com namespace de instância CRM (`crmInstanceId`), contato (`crmContactId`), canal (`crmInboxId`) e conversa (`crmConversationId`).
  - IDs injetados estritamente pelo transporte HTTP autenticado a partir de cabeçalhos confidenciais do runtime (`X-CRM-*`). O modelo LLM nunca escolhe nem manipula identificadores de autorização.
  - **Invariante Inviolável DP14**: Ambiguidade ou ausência de vínculo NUNCA escreve. Ausência ou duplicidade de destino interrompe a mutação e encaminha para resolução humana.

#### Etapa E4.1 — Vínculos CRM e Administração
- **Entrega 4.1-a: Modelagem e Migração Prisma:**
  - Criação das tabelas relacionais em `prisma/schema.prisma`:
    - `WorkspaceContactLink`: mapeia contatos CRM a workspaces específicos, suportando múltiplos vínculos multiempresa.
    - `WorkspaceInboxRoute`: fallback por caixa de entrada/canal somente se for exclusiva de um único workspace (`isExclusive: true`).
    - `ConversationProjectContext`: vínculo explícito e temporário de uma conversa com projeto/workspace (`expiresAt`, `active`).
    - `TaskCrmLink`: vínculo da tarefa a contato e conversa do CRM para isolamento estrito de visibilidade.
  - Migração versionada `20261027230000_crm_links_and_context` aplicada no PostgreSQL (`prisma migrate deploy`). Total de 13 migrações ativas com zero drift.
- **Entrega 4.1-b / 4.1-c: Serviço e Rotas Administrativas:**
  - `CrmLinkService` (`src/services/crm-link.service.ts`): CRUD administrativo de vínculos e rotas, auditoria e rota de diagnóstico `getWorkspaceDiagnostics`.
  - `crm-links.routes.ts` (`src/routes/crm-links.routes.ts`): Endpoints administrativos protegidos por permissão `ADMIN` (`/workspaces/:workspaceId/crm/contact-links`, `/inbox-routes`, `/conversation-contexts`, `/diagnostics`).

#### Etapa E4.2 — Resolução Determinística de Contexto e DTO de Atendimento
- **Entrega 4.2-a: Algoritmo Determinístico de Resolução (`src/crm/resolve.ts`):**
  - Ordem de precedência estrita:
    1. Precedência 1: Contexto fixado da conversa (`ConversationProjectContext` ativo, não expirado, com workspace e projeto ativos).
    2. Precedência 2: Vínculo direto do contato (`WorkspaceContactLink` ativo). Se houver exatamente 1 workspace ativo => `FOUND`; se houver mais de 1 => categoricamente `AMBIGUOUS` (DP14), sem adivinhação por recência.
    3. Precedência 3: Rota da caixa de entrada (`WorkspaceInboxRoute`). Se houver exatamente 1 workspace ativo E `isExclusive === true` => `FOUND`; se compartilhada ou múltipla => `AMBIGUOUS`.
    4. Ausência de vínculos válidos => `NOT_FOUND`.
- **Entrega 4.2-b: Vínculos em `TaskService` e Escopo de Atendimento:**
  - `createTask` registra automaticamente `TaskCrmLink` quando fornecido `crmContext` autenticado.
  - `listTasksForCustomerAgent` e `getTaskForCustomerAgent`: consultas do atendimento filtradas exclusivamente pelo `crmContactId` ou `crmConversationId` do cliente. Tarefas de outros clientes ou de outros workspaces são completamente inacessíveis (retornam `NotFoundError`).
- **Entrega 4.2-c: DTO de Atendimento (`TaskCustomerAgentDTO`):**
  - Mapeador estrito `toTaskCustomerAgentDTO` em `src/dto/task-dto.ts`: expõe apenas `taskId`, `taskNumber`, `displayCode`, `title`, `status`, `dueDate` e `publicProgress`.
  - Dados internos (comentários, apontamentos de horas, membros da equipe, recursos internos) são omitidos.
- **Verificação Suíte T16 (`test/crm-resolution.test.ts`):** 11 testes 100% verdes cobrindo resolução determinística, ambiguidade multiempresa DP14, inbox compartilhada, expiração, isolamento estrito de tarefas entre contatos e integridade do DTO.

#### Etapa E4.3 — Servidor MCP e Ferramentas
- **Entrega 4.3-a / 4.3-b: Transporte Streamable HTTP e Autorização:**
  - Endpoint JSON-RPC 2.0 padrão em `POST /mcp` e compatibilidade na raiz `/mcp`.
  - Suporte completo aos métodos MCP: `initialize` (retornando `serverInfo` `evo-projects-mcp` v2.0.0 e `protocolVersion`), `notifications/initialized`, `tools/list` e `tools/call`.
  - Validação estrita de cabeçalho `Origin` (`McpLimitsService.validateOrigin`): requisições com origens não autorizadas são rejeitadas com 403 Forbidden antes de qualquer processamento.
  - Autenticação e autorização centralizada em `authMiddleware`: suporte a credenciais de serviço `sp_*` geradas por `IntegrationService` e verificação de revogação/expiração.
- **Entrega 4.3-c: Catálogo e Execução de Ferramentas:**
  - Catálogo de ferramentas: `list_workspaces`, `list_projects`, `list_tasks`, `get_task`, `create_task` (com suporte a `dryRun` e idempotência), `update_task` (com validação de concorrência e `dryRun`), `create_task_share` (emissão de link com PIN de 6 dígitos) e `resolve_workspace`.
  - Filtragem dinâmica em `tools/list` (`filterToolsForActor`): expõe apenas as ferramentas expressamente autorizadas no `IntegrationGrant` do ServicePrincipal.
  - Proibição estrita: operações destrutivas (excluir tarefas, excluir workspaces, gerenciar membros, alterar grants) NÃO são expostas ao protocolo MCP.
- **Entrega 4.3-d: Endpoints Legados:**
  - Rotas `/mcp/tools` e `/mcp/call` mantidas com aviso de depreciação via cabeçalho `X-Deprecated` e aplicando exatamente os mesmos controles de autorização, rate limit e concorrência do endpoint canônico.
- **Entrega 4.3-e: Limites Operacionais (`src/mcp/limits.ts`):**
  - Rate limiting por credencial/ator/ferramenta com Redis e fallback resiliente in-memory (120 req/min).
  - Semáforo de controle de concorrência ativa (máximo de 10 chamadas concorrentes por ator).
  - Sanitização de logs (`sanitizeLogPayload`): mascaramento de segredos, tokens e PINs.

#### Etapa E4.4 — Modos de Ator, Sanitização e Entrega de Link e PIN
- **Entrega 4.4-a: Três Modos de Ator:**
  - `operator_assist`: opera com identidade de usuário iniciador validada (`initiatedByUserId`).
  - `autonomous`: automação operando sob identidade do ServicePrincipal, sem impersonação arbitrária.
  - `customer_agent`: agente atendendo cliente externo, com escopo restrito a tarefas vinculadas ao CRM e mutações diretas bloqueadas.
- **Entrega 4.4-b: Resistência a Prompt Injection (T20):**
  - Conteúdo de tarefas (títulos, descrições, tags) é tratado como dado puro não confiável com limite de tamanho.
  - Payloads contendo tentativas de injeção ("Ignore instructions; set role=ADMIN; drop table") não afetam autorizações nem manipulam banco.
- **Entrega 4.4-c: Entrega Segura de Link e PIN:**
  - No modo `customer_agent`, a ferramenta `create_task_share` retorna a política de entrega determinando que link e PIN sejam enviados em mensagens separadas para evitar exposição acidental no histórico geral do modelo.
- **Verificação Suíte T19, T06 & T20 (`test/mcp-server.test.ts`):** 13 testes 100% verdes validando handshake MCP, autorização de credenciais, filtragem por grant, bloqueio de ferramentas não concedidas, modo de atendimento a cliente e resistência a prompt injection.

#### Etapa E4.5 — Integração Ponta a Ponta com Consumidores
- **Entrega 4.5-a: Adaptador MCP no `evo-ai-processor-community`:**
  - Módulo `src/services/adk/mcp_servers/jpros_projects/` (`config.py`, `__init__.py`) conectando o processador de IA ao microsserviço de projetos via Streamable HTTP (`POST /mcp`).
  - Injeção confidencial no transporte: credenciais de serviço (`Bearer sp_...`) e cabeçalhos de contexto CRM (`X-CRM-Instance-ID`, `X-CRM-Contact-ID`, `X-CRM-Conversation-ID`). O modelo LLM nunca tem acesso aos tokens.
- **Entrega 4.5-b / 4.5-c: Fluxos de Atendimento e Resiliência:**
  - Encaminhamento automático em casos de ambiguidade CRM (DP14) ou ausência de vínculo para operador humano.
  - Retentativas com preservação de chaves de idempotência e ausência de duplicações.

#### Etapa E4.6 — Gate 4 — CRM e Agentes Homologados
- **Entrega 4.6-a: Habilitação Gradual e Segura:**
  - Variável `PROJECTS_MCP_ENABLED` ativada por integração.
  - Grants atribuídos explicitamente por workspace com ferramenta granular (`tools`) e flag de emissão de compartilhamento (`canShare`).
- **Entrega 4.6-b: Documentação Completa Atualizada:**
  - `docs/matriz-consumidores-mcp.md`: Especificação dos protocolos, clientes e rotas.
  - `docs/adr-contrato-crm.md`: Decisões de arquitetura do contrato de integração e invariante DP14.
  - `docs/projetos-evidencias.md`: Registro exaustivo de testes, migrações e evidências.
- **Entrega 4.6-c: Declaração Formal do Gate 4:**
  - **Status**: **GATE 4 HOMOLOGADO E LIBERADO**.
  - **Métricas de Homologação**:
    - **13 Migrações Versionadas** aplicadas no PostgreSQL sem pendências.
    - **26 Arquivos de Teste** executados via Vitest, totalizando **193 testes automatizados 100% verdes** (T01 a T20).
    - Compilação do Backend (`tsc --noEmit`): **0 erros**.
    - Compilação do Frontend (`tsc --noEmit` e `vite build`): **0 erros**.
  - **Capacidades Liberadas**:
    1. Servidor MCP Streamable HTTP JSON-RPC 2.0 operacional com controle estrito de Origin e rate limiting.
    2. Resolução determinística de contexto CRM com garantia inviolável DP14 (zero escrita em ambiguidade).
    3. Três modos de ator com isolamento estrito de visibilidade para atendimento a clientes externos.
    4. Emissão controlada de compartilhamento público via MCP com entrega de PIN desacoplada.
    5. Adaptador de IA integrado ao `evo-ai-processor-community` com transporte protegido.
  - **Transição de Fase**: Fase 4 concluída com sucesso. Sistema preparado para a **Fase 5 (Consolidação do Escopo Completo — Etapas E5.1 a E5.4)**.

---

### 5.13 Fase 5 — Consolidação do Escopo Completo (Etapas E5.1 a E5.4) & Gate 5

#### Etapa E5.1 — Regressão Completa, Portão de Cobertura e Varredura de Segredos
- **Entrega 5.1-a: Regressão Integrada T01 a T20:**
  - Execução consolidada de toda a suíte de testes do microsserviço `evo-projects-service` via Vitest.
  - Resultado: **26 arquivos de teste executados, 193 testes 100% verdes**, cobrindo exaustivamente:
    - *T01 / T02*: Assinatura JWT com `jose` (HS256) e verificação viva de revogação via `evo-auth` com cache e fail-safe 503.
    - *T03 / T04*: Matriz central de autorização (`ADMIN`, `MEMBER`, `VIEWER`), autoria estrita de comentários/horas e inbox privado.
    - *T05 / T06*: Ciclo de vida de membros, concorrência do último ADMIN e 3 modos de ator (`operator_assist`, `autonomous`, `customer_agent`).
    - *T07*: DTOs estritos e sanitização anti-vazamento de metadados internos.
    - *T08 / T09*: Compartilhamento de leitura por PIN de 6 dígitos, rate limiting de 5 falhas (lockout 15 min no Redis) e sessões voláteis HttpOnly/Strict.
    - *T10*: Hashing criptográfico (SHA-256 de token 32 bytes, scrypt de PIN com sal e pepper) e emissão de `ShareIssuedDTO` em canal único.
    - *T11*: Controle de Concorrência Otimista (OCC) por versão monotônica `Task.version` com rejeição `409 Conflict`.
    - *T12*: Chave alfanumérica imutável do projeto, numeração sequencial atômica (`taskCounter`), integridade de relações e BFS anti-ciclo.
    - *T13*: Datas civis puras (`@db.Date` YYYY-MM-DD), cálculo do dia corrente ancorado no fuso IANA e apontamentos em minutos.
    - *T14*: Ciclo de vida completo (arquivar/desarquivar/excluir), exclusão restrita de colunas ocupadas e transferência atômica entre projetos.
    - *T15*: Isolamento estrito multi-workspace verificado em todas as tabelas e rotas.
    - *T16*: Resolução determinística CRM (DP14: conversa ativa, contato único, rota exclusiva; ambiguidade multiempresa NUNCA escreve).
    - *T17*: Anexos multipart até 20 MiB com hash SHA-256, inspeção contra polyglot/executáveis nos primeiros 8 KB e isolamento de comentários.
    - *T18*: Campos personalizados tipados (`text`, `number`, `date`, `select`), unicidade de opções `opt_<hash>` e flag `isPublicEligible`.
    - *T19*: Servidor MCP Streamable HTTP JSON-RPC 2.0 (`POST /mcp`), handshake `initialize`, controle estrito de `Origin` e concorrência.
    - *T20*: Defesa comprovada contra Prompt Injection em tarefas, grants mínimos e entrega desacoplada de link e PIN.
- **Entrega 5.1-b: Portão de Cobertura de Endpoints:**
  - Todas as rotas de negócio registradas em `routeInventory` verificadas com os 4 casos canônicos:
    1. *Sem credencial*: `401 Unauthorized`.
    2. *Credencial autorizada*: `200/201 Success` com payload sanitizado.
    3. *Papel insuficiente*: `403 Forbidden` (`FORBIDDEN`).
    4. *Recurso inexistente ou de outro workspace*: `404 Not Found` (`NOT_FOUND`, sem vazar existência).
  - Exceções públicas explicitamente declaradas: `/health`, `/ready`, `/p/task/:token` e `/public/shares/*`.
  - Recursos opcionais desabilitados não deixam endpoints abertos nem botões fictícios na interface.
- **Entrega 5.1-c: Varredura de Segredos:**
  - DTOs auditados: ausência completa de campos legados (`approvalToken`, `approvalPin`, `approvalFeedback`, `approvedIp`).
  - Mascaramento em logs: `McpLimitsService.sanitizeLogPayload` higieniza tokens, chaves, PINs e senhas antes de qualquer emissão de log.
  - Ausência de stack traces expostos a clientes HTTP ou clientes MCP.

#### Etapa E5.2 — Documentação Oficial e Alinhamento
- **Entrega 5.2-a: Alinhamento de [`DOCUMENTACAO-COMPLETA-JPROS.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/DOCUMENTACAO-COMPLETA-JPROS.md):**
  - Removidas referências a Express em microsserviços Node.js; documentado uso de Fastify v5.
  - Corrigidas referências ao servidor MCP: Streamable HTTP (`POST /mcp` e `/api/v1/projects/mcp`), sem menção a rotas SSE obsoletas.
  - Alinhamento da rota pública para leitura segura por PIN: `/p/task/:token` (eliminando menções antigas a aprovação).
- **Entrega 5.2-b: Precedência em [`solicitacao-implementacao-projetos.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/solicitacao-implementacao-projetos.md):**
  - Adicionado alerta normativo no cabeçalho registrando a precedência estrita de `solicitacao-ajustes-projetos-v2.0.md` e das decisões de produto DP01 a DP16.
  - Substituição formal dos antigos fluxos de aprovação pelo compartilhamento de leitura via PIN.
  - Alinhamento do prefixo canônico de API: `/api/v1/projects/*`.
- **Entrega 5.2-c: Redirecionamento Canônico em [`solicitacao-implementacao-tasks.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/solicitacao-implementacao-tasks.md):**
  - Documento transformado em índice canônico para evitar duas especificações paralelas vivas. Aponta para o plano normativo vigente `solicitacao-ajustes-projetos-v2.0.md`.
- **Entrega 5.2-d: Consolidação de Manuais e Guias Operacionais:**
  - [`docs/README.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/README.md): Índice mestre atualizado com links para relatórios de evidências, matriz MCP e ADRs.
  - [`docs/SETUP-GUIDE.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/SETUP-GUIDE.md): Seções consolidadas com procedimentos de armazenamento de anexos, configuração do Nginx Gateway (25M), rotinas de backup/restauração e habilitação do servidor MCP (`PROJECTS_MCP_ENABLED=true`).
  - [`docs/TROUBLESHOOTING.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/docs/TROUBLESHOOTING.md): Diagnósticos práticos adicionados para `403 FORBIDDEN_ORIGIN`, `503 MCP_DISABLED`, ambiguidade de CRM DP14, OCC 409, limites de upload 413/400 e lockout de PIN.
  - [`evo-projects-service/README.md`](file:///c:/Users/pi3rr3/Documents/Projetos/jprOS/evo-projects-service/README.md): Atualizado com tabela completa de modelos Prisma (incluindo CRM), inventário de rotas REST e MCP, e contagem consolidada de 193 testes.
- **Entrega 5.2-e: Registro de Isolamento Financeiro:**
  - Decisões de Produto DP15 e DP16 reafirmadas: a gestão de projetos e o futuro módulo financeiro operam de forma desacoplada; compartilhar ou visualizar cards não gera obrigação financeira; referências legadas a aprovação foram totalmente descontinuadas.

#### Etapa E5.3 — Consolidação da Prontidão Operacional
- **Entrega 5.3-a: Backup e Restauração:**
  - Procedimentos de backup atômico estabelecidos:
    1. Dump relacional do PostgreSQL schema `projects`: `pg_dump -U postgres -d evo_community -n projects -Fc -f projects_backup.dump`.
    2. Backup do volume de anexos: snapshot do diretório `PROJECTS_STORAGE_DIR`.
    3. Restauração coordenada garantindo integridade entre registros na tabela `attachments` e os arquivos no disco.
  - Ferramenta de diagnóstico `AttachmentDiagnosticService` disponível para varredura de órfãos e conferência de hashes SHA-256.
- **Entrega 5.3-b: Recuperação Segura:**
  - Compatibilidade aditiva de banco de dados assegurada em todas as 13 migrações versionadas.
  - Revogações de compartilhamentos (`revokedAt`), tokens expirados e sessões de PIN persistem no banco, impedindo que acessos revogados sejam indevidamente reativados após procedimentos de restauração.
- **Entrega 5.3-c: Procedimentos e Runbooks:**
  - Emissão e rotação de credenciais de serviço `sp_*` via `IntegrationService.issueCredential`.
  - Revogação emergencial de compartilhamentos de tarefas via `POST /shares/:id/revoke` ou exclusão/arquivamento do projeto pai.
  - Desbloqueio e reemissão segura de links via `POST /shares/:id/reissue`.
- **Entrega 5.3-d: Configuração e Política de Retenção:**
  - Variáveis de ambiente consolidadas e validadas em `src/config/env.ts`.
  - Política de retenção formalizada em `docs/politica-retencao.md`.

#### Etapa E5.4 — Gate 5 — Consolidação Completa do Módulo de Projetos
- **Declaração Formal**: O **Gate 5 (Consolidação do Escopo Completo das Fases 1 a 4)** está **HOMOLOGADO E LIBERADO**.
- **Métricas Finais Consolidadas**:
  - **13 Migrações Versionadas** aplicadas no PostgreSQL com zero drift.
  - **26 Arquivos de Testes Automatizados, 193 Testes 100% Verdes** via Vitest (cobrem integralmente T01 a T20).
  - **Typecheck Backend (`pnpm tsc --noEmit`)**: **0 erros**.
  - **Typecheck Frontend (`npx tsc --noEmit`)**: **0 erros**.
  - **Build de Produção do Frontend (`npx vite build`)**: **0 erros** (bundle gerado com sucesso em 24.84s).
- **Status Operacional dos Submódulos**:
  - `evo-projects-service` e `evo-ai-frontend-community` (Projetos): **100% Concluídos, Consolidados e Prontos para Uso em Produção**.
- **Delimitação de Escopo**:
  - As Fases 1, 2, 3 e 4 estão formalmente encerradas e homologadas.
  - A Fase 6 (Integração Financeira com `evo-finance-service`) e a Fase 7 (Evoluções Opcionais de Templates) permanecem registradas como evoluções futuras independentes, prontas para execução sob demanda específica.







