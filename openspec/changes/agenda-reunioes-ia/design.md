# Design: Agenda e Inteligência de Reuniões

## Context

O microsserviço `evo-scheduling-service` e o frontend `evo-ai-frontend-community` possuem uma base operacional para agendamentos (`Booking`, `EventType`, `Schedule`, `Availability`), porém operam com falhas estruturais de segurança (rotas sem JWT, CORS irrestrito) e com uma interface de compromissos limitada a cards curtos em grade. A necessidade de consolidar os tópicos das reuniões realizadas demanda um motor de IA assíncrono e persistente sem acoplamento a um provedor proprietário específico e sem criar tarefas automáticas desnecessárias. Veja `proposal.md` para a motivação detalhada.

## Goals / Non-Goals

**Goals:**
- Proteger 100% das rotas administrativas de agendamento com JWT validado pelo `evo-auth-service`, isolando consultas e mutações por `sub` (dono).
- Refatorar a visualização de compromissos para lista horizontal com filtros avançados no servidor (`from`, `to`, `search`, `eventTypeId`).
- Implementar a página de detalhes da reunião (`/scheduling/bookings/:id`) com extração de 8 blocos analíticos (Tópicos da Reunião) a partir de transcrições coladas.
- Construir motor de inferência no servidor compatível com a API OpenAI (`POST {MEETING_AI_BASE_URL}/chat/completions`), suportando OpenRouter, OpenAI e Gemini.
- Garantir concorrência segura na reserva com `pg_advisory_xact_lock` e suporte a reagendamento sobreposto à própria reunião.
- Adotar baseline de migração Prisma controlada (`prisma migrate dev/deploy`), evitando `db push` desgovernado em produção.

**Non-Goals:**
- Criação automática de tarefas ou pendências no módulo de Projetos (escopo estritamente focado em notas/tópicos).
- Transcrição de áudio em tempo real pelo serviço (o usuário fornece o texto ou links já gerados).
- Envio automático de mensagens no WhatsApp com o resumo da reunião.
- Sincronização bidirecional com Google Calendar ou Outlook nesta fase.

## Decisions

### D01: Isolamento de Segurança e Token de Serviço
- **Decisão:** Rotas administrativas validam JWT emitido pelo `evo-auth-service` via biblioteca `jose` e cache de validação em memória (60s). O identificador de usuário (`userId`) do cliente é ignorado; a operação vincula-se ao `sub` do token. O bot de WhatsApp acessa a criação/cancelamento via `SCHEDULING_SERVICE_TOKEN` em tempo constante.
- **Alternativas consideradas:** Manter `userId` no corpo com verificação de papéis (descartado por permitir manipulação de identidade).

### D02: Modelo de Dados em JSON Versionado (`topics Json?`)
- **Decisão:** A tabela `meeting_summaries` persiste os 8 blocos em uma coluna `topics Json?` acompanhada de `topicsVersion Int @default(1)` e status de geração `SummaryStatus (PENDING, DONE, FAILED)`.
- **Alternativas consideradas:** Colunas relacionais `String[]` separadas para cada bloco (descartado por rigidez e necessidade de migrações DDL a cada novo campo).

### D03: Separação de Schemas Zod de Entrada e Saída
- **Decisão:** Separar rigorosamente `aiOutputSchema` (onde todos os 8 blocos são obrigatórios na resposta do LLM) de `updateSummarySchema` (onde todos os campos são opcionais e a operação `PUT` faz merge profundo, preservando blocos não enviados e evitando zerá-los por defaults de array vazio).
- **Alternativas consideradas:** Reutilizar o mesmo schema com valores default (descartado pelo risco R04 identificado na avaliação técnica).

### D04: Reagendamento Seguro e Trava de Concorrência
- **Decisão:** O cálculo de slots (`getSlots`) recebe `excludeBookingId` opcional para permitir reagendar reuniões para intervalos adjacentes ou sobrepostos a si mesmas. A criação e o reagendamento executam sob `pg_advisory_xact_lock(hashtext(userId))` para serializar reservas do mesmo atendente.
- **Alternativas consideradas:** Verificação em tempo de leitura sem trava (descartado por permitir race conditions em cliques simultâneos).

### D05: Provedor de IA em Camada Única Compatível com OpenAI
- **Decisão:** O servidor consome a IA através de chamada padronizada `POST {MEETING_AI_BASE_URL}/chat/completions` com timeout de 90s e validação estrita de JSON. As credenciais residem apenas no servidor via variáveis de ambiente (`MEETING_AI_API_KEY`, etc.).
- **Alternativas consideradas:** Enviar credenciais e base URLs pelo navegador (descartado por vulnerabilidade de SSRF e vazamento de chaves).

## Risks / Trade-offs

- **[Risco R01] Divergência entre `db push` e histórico de migrações**  
  → *Mitigação:* Estabelecer baseline inicial de migrações com `npx prisma migrate dev --name init_scheduling` e documentar `prisma migrate deploy` no Dockerfile e nos pipelines.
- **[Risco R02] Trabalhos de IA presos em `PENDING` após reinício do container**  
  → *Mitigação:* Adicionar timestamp de expiração (`expiresAt`) ou varredura de recuperação na inicialização marcando tarefas órfãs com mais de 10 minutos como `FAILED/INTERRUPTED`.
- **[Risco R03] Concorrência entre geração de IA e edição manual simultânea**  
  → *Mitigação:* Atualização condicional por versão ou bloqueio de edição na interface enquanto o status do sumário for `PENDING`.
- **[Risco R07] Falha de chamadas legadas a `syncUser` nas outras telas do frontend**  
  → *Mitigação:* Manter temporariamente o endpoint `POST /users/sync` protegido por JWT realizando no-op seguro para preservar o funcionamento de `AvailabilityPage`, `EventTypesPage` e `PublicPreviewPage`.

## Migration Plan

1. **Baseline do Banco de Dados**:
   - Rodar script de verificação do schema atual no PostgreSQL.
   - Gerar a migração Prisma com a nova tabela `meeting_summaries` e o enum `SummaryStatus`.
   - Executar `npx prisma migrate deploy` no container de banco de dados.
2. **Atualização do Backend**:
   - Injetar as novas variáveis no `docker-compose.yml` (`JWT_SECRET_KEY`, `MEETING_AI_ENABLED`, etc.).
   - Reconstruir e subir o container `evo-scheduling`.
3. **Atualização do Frontend**:
   - Recompilar o container `evo-frontend` com as novas telas e rotas.
4. **Rollback Strategy**:
   - Em caso de inconsistência na migração, aplicar script reverso para descartar a tabela `meeting_summaries` sem afetar a tabela `bookings`.
