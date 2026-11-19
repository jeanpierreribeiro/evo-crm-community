# Proposal: Agenda e Inteligência de Reuniões

## Why

O submódulo de agendamentos (`evo-scheduling-service`) foi introduzido como um motor headless mínimo, mas sua interface de compromissos ainda exibe cards curtos em grade sem filtros de data ou busca por cliente. Além disso, as reuniões realizadas necessitam de uma visão de detalhe executiva que processe resumos e transcrições via IA para consolidar os 8 blocos analíticos (Tópicos da Reunião) sem depender de ferramentas externas e sem sobrecarregar a equipe com tarefas manuais. Por fim, o serviço opera atualmente sem autenticação nas rotas administrativas, expondo dados de reservas e demandando o isolamento imediato por JWT antes da liberação.

## What Changes

- **Segurança e Autenticação (Fase 0)**:
  - Proteção de rotas administrativas com validação de JWT (`jose`), isolamento rigoroso por `sub` (dono da reunião) e token de serviço (`SCHEDULING_SERVICE_TOKEN`) dedicado para o bot de WhatsApp.
  - Eliminação da chamada anônima `POST /users/sync`, substituída pela projeção de usuário canônica a partir do token de autenticação.
  - Validação estrita de reserva com bloqueio anti-conflito atômico (`pg_advisory_xact_lock`) e validação de expediente na engine.
- **Listagem Executiva de Compromissos**:
  - Transição do grid de cards para layout em lista com linhas horizontais full-width.
  - Filtros avançados no servidor: intervalo de datas (`from`/`to`), tipo de evento (`eventTypeId`) e busca textual livre (`search` por título, participante, e-mail e telefone com sanitização de dígitos).
  - Link direto para iniciar conversa no WhatsApp (`https://wa.me/55...`) e persistência do estado dos filtros na URL da aplicação.
- **Tela de Detalhe da Reunião (`/scheduling/bookings/:id`)**:
  - Cabeçalho com título editável, data/hora e links externos opcionais do Google Drive (`Resumo completo ↗` e `Transcrição ↗`).
  - Seção estruturada **"Tópicos da Reunião"** composta por 8 blocos analíticos: Assunto, Participantes, Principais Pontos, Decisões, Aprendizados, Fatos e Números, Próximos Passos (texto informativo) e Clientes/Projetos Citados.
  - **Exclusão explícita**: Nenhuma geração automática de tarefas ou pendências no módulo de Projetos.
- **Motor de Inteligência Artificial (OpenAI-Compatible)**:
  - Integração assíncrona no servidor (`POST .../summary/generate` respondendo `202 Accepted` com estados `PENDING`, `DONE`, `FAILED`), sem expor credenciais nem URLs ao navegador.
  - Suporte flexível a modelos via variáveis de ambiente (`MEETING_AI_BASE_URL`, `MEETING_AI_API_KEY`, `MEETING_AI_MODEL`) cobrindo OpenAI, OpenRouter e Google Gemini (endpoint de compatibilidade).
  - Edição manual bloco a bloco com controle de concorrência e preservação do histórico de edições (`editedAt`).

## Capabilities

### New Capabilities
- `scheduling-bookings`: Listagem executiva de compromissos no padrão de linhas horizontais, filtros combinados de período e texto no servidor, navegação para detalhes e segurança de acesso autenticado por dono via JWT.
- `meeting-intelligence`: Extração assíncrona e estruturada de tópicos analíticos de reuniões a partir de transcrições brutas usando LLM compatível com OpenAI, persistência em tabela `meeting_summaries` e capacidade de edição manual de cada bloco.

### Modified Capabilities
<!-- Nenhuma capacidade existente modificada, pois os módulos da Agenda estão recebendo sua primeira especificação formal no OpenSpec. -->

## Impact

- **Backend (`evo-scheduling-service`)**:
  - Novo modelo Prisma `MeetingSummary` no schema `scheduling` com relação 1-para-1 com `Booking`.
  - Novos endpoints: `GET /bookings` (com parâmetros de busca/data e `hasSummary`), `GET /bookings/:id`, `GET /bookings/:id/summary`, `PUT /bookings/:id/summary`, `POST /bookings/:id/summary/generate`, `DELETE /bookings/:id/summary` e `GET /meetings/ai-status`.
  - Novo middleware de autenticação JWT e cliente de validação contra `evo-auth-service`.
- **Frontend (`evo-ai-frontend-community`)**:
  - Refatoração de `src/pages/scheduling/BookingsPage.tsx` com novo componente de barra de filtros e linhas horizontais.
  - Criação da página `src/pages/scheduling/BookingDetailPage.tsx` e registro da rota `/scheduling/bookings/:id`.
  - Atualização dos serviços de API em `src/services/scheduling/schedulingService.ts` e tipos em `src/types/scheduling/index.ts`.
- **Orquestração e Gateway**:
  - `docker-compose.yml`: Adição das variáveis de autenticação (`JWT_SECRET_KEY`, `EVO_AUTH_SERVICE_URL`) e de IA (`MEETING_AI_ENABLED`, `MEETING_AI_BASE_URL`, etc.) ao serviço `evo-scheduling`.
