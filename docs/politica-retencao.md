# Política de Retenção de Dados, Ciclo de Vida e Auditoria — jprOS Projetos

**Documento Normativo**: ADR-003 / E3.6-f / Seção 17  
**Data de Emissão**: 27/10/2026  
**Status**: Em Vigor  
**Submódulo**: `evo-projects-service`

---

## 1. Princípio Fundamental de Não-Purga Automática

> [!IMPORTANT]
> **Nenhuma rotina de purga física ou exclusão irreversível é executada automaticamente** sem aprovação prévia, confirmação administrativa explícita e auditoria registrada.

Todos os comandos de exclusão acionados por usuários ou serviços no submódulo de Projetos operam exclusivamente sob a modalidade de **Exclusão Lógica** (*soft delete*).

---

## 2. Janela de Retenção de Exclusão Lógica (90 Dias)

### 2.1 Escopo Aplicável
A exclusão lógica com carimbos `deletedAt`, `deletedById` e motivo opcional `deletionReason` aplica-se a:
- **Workspaces** (`workspaces`)
- **Projetos** (`projects`)
- **Tarefas** (`tasks`)

### 2.2 Comportamento Durante os 90 Dias
1. **Ocultação Operacional**: Registros com `deletedAt IS NOT NULL` são imediatamente excluídos de:
   - Listagens gerais de tarefas (`GET /projects/:projectId/tasks`), projetos e workspaces.
   - Painéis, contadores e métricas agregadas do dashboard.
2. **Invisibilidade por Link Direto**:
   - Tentativas de acesso direto por ID (`GET /tasks/:id`, `GET /projects/:id`) a recursos excluídos logicamente retornam `404 Not Found` para operadores normais, sem vazar a existência do registro.
3. **Restauro Administrativo Exclusivo**:
   - Apenas usuários com papel **ADMIN** no workspace podem restaurar um recurso excluído logicamente (`POST /tasks/:id/restore`, `POST /projects/:id/restore`, `POST /workspaces/:id/restore`).
   - Operadores com papel **MEMBER** que tentarem restaurar um registro excluído logicamente recebem `403 Forbidden`.
4. **Revogação em Cascata de Compartilhamentos**:
   - A exclusão lógica revoga imediatamente todos os compartilhamentos públicos com PIN ativos no escopo correspondente.
   - **O restauro posterior NÃO reativa compartilhamentos revogados** (prevenção contra vazamento de informações para portadores de PINs antigos).

---

## 3. Arquivamento e Congelamento em Modo Somente Leitura

1. **Preservação**: O arquivamento (`isArchived: true`, `archivedAt`, `archivedById`) não apaga nenhum registro nem remove histórico, subtarefas, comentários ou apontamentos.
2. **Somente Leitura**:
   - Recursos arquivados (ou pertencentes a container pai arquivado) tornam-se estritamente **somente leitura**.
   - Qualquer tentativa de mutação (edição de título, movimentação no Kanban, adição de comentários ou subtarefas) é bloqueada com `403 Forbidden`.
3. **Respeito ao Container Pai (T14)**:
   - Se um projeto ou workspace estiver arquivado, todas as suas tarefas filhas herdam o estado arquivado.
   - Membros (`MEMBER`) podem arquivar/restaurar tarefas em projetos ativos. No entanto, restaurar uma tarefa pertencente a um projeto ou workspace arquivado **exige papel ADMIN**.
4. **Compartilhamentos**: Ao arquivar, todos os compartilhamentos públicos do escopo são revogados imediatamente e não são reativados no desarquivamento.

---

## 4. Imutabilidade e Desacoplamento da Auditoria (`Activity`)

1. **Desacoplamento Relacional**:
   - A tabela `activities` utiliza chaves estrangeiras com regra `ON DELETE SET NULL` para `workspaceId`, `projectId` e `taskId`.
   - Se um recurso for excluído, seu histórico de auditoria **NÃO é apagado em cascata**, preservando a rastreabilidade perene de quem executou cada ação.
2. **Ator Estruturado**:
   - Todo registro de auditoria cataloga `actorType` (`USER`, `SERVICE`, `SHARE_SESSION`), `actorId`, `userName` histórico, `initiatedByUserId` (quando aplicável) e `requestId` para correlação de telemetria.
3. **Sanitização Estrita contra Vazamento de Segredos**:
   - Detalhes em JSON passam obrigatoriamente por filtro recursivo que redige para `[REDACTED]` qualquer campo contendo padrões de PINs, tokens, senhas, hashes, cookies ou autorizações (`/pin|token|password|cookie|secret|authorization|bearer/i`).

---

## 5. Diretrizes para Futuras Políticas de Anexos Órfãos (E3.7)

Quando o serviço de anexos e armazenamento for entregue (Etapa E3.7):
- Arquivos órfãos (arquivos sem referência em tarefas ativas ou arquivadas) serão identificados por jobs analíticos.
- Tais jobs emitirão **relatórios de diagnóstico**, sem executar `rm` ou `DELETE` físico em disco/bucket até que uma rotina manual ou automatizada com quarentena seja homologada.
