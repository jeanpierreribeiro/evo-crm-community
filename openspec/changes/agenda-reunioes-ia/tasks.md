# Tasks: Agenda e Inteligência de Reuniões

## 1. Segurança e Contratos de Autenticação

- [x] 1.1 Implementar middleware de autenticação JWT (`jose`) e validação de token em `evo-scheduling-service`, verificando com teste unitário que tokens inválidos ou expirados são rejeitados com HTTP 401.
- [x] 1.2 Proteger rotas administrativas (`/bookings`, `/bookings/:id`, `/schedules`, `/event-types`) extraindo o usuário autenticado de `request.user.sub` e verificando que consultas retornam apenas dados pertencentes ao dono.
- [x] 1.3 Adicionar autenticação por token de serviço (`SCHEDULING_SERVICE_TOKEN`) para o bot de WhatsApp e manter `POST /users/sync` protegido como no-op seguro para compatibilidade com as demais telas do frontend.
- [x] 1.4 Adicionar trava `pg_advisory_xact_lock(hashtext(userId))` e parâmetro `excludeBookingId` no cálculo determinístico de slots, verificando que reagendamento para horários sobrepostos à própria reunião é permitido e reservas simultâneas são serializadas.

## 2. Modelagem de Dados e API de Compromissos e Sumário

- [x] 2.1 Criar modelo Prisma `MeetingSummary` e enum `SummaryStatus` em `schema.prisma`, gerando migração versionada (`prisma migrate dev`) e verificando a aplicação da tabela `meeting_summaries` no PostgreSQL.
- [x] 2.2 Criar esquemas de validação Zod separados para extração de IA (`aiOutputSchema`) e atualização manual (`updateSummarySchema`), verificando com testes unitários que atualizações parciais via `PUT` não zeram blocos inalterados.
- [x] 2.3 Atualizar rota `GET /api/v1/scheduling/bookings` com suporte a `from`, `to`, `search`, `eventTypeId` e retornar indicador `hasSummary`, verificando com testes de integração que a filtragem por texto e período opera corretamente.
- [x] 2.4 Implementar rotas CRUD de sumário (`GET /bookings/:id/summary`, `PUT /bookings/:id/summary` e `DELETE /bookings/:id/summary`), validando que URLs externas rejeitam esquemas não seguros e aceitam apenas `https://`.

## 3. Motor de Inteligência Artificial no Servidor

- [x] 3.1 Implementar cliente HTTP OpenAI-compatible (`src/meetings/ai/client.ts`) consumindo `POST {MEETING_AI_BASE_URL}/chat/completions` com timeout configurável de 90s, retry para erros transitórios e validação Zod da resposta.
- [x] 3.2 Criar prompt de sistema versionado (`PROMPT_VERSION`) instruindo a extração estrita dos 8 blocos de tópicos da reunião em JSON e proibindo geração de tarefas/pendências, verificando a acurácia com transcrição simulada.
- [x] 3.3 Implementar endpoint `POST /api/v1/scheduling/bookings/:id/summary/generate` com resposta imediata HTTP 202 `PENDING`, processamento assíncrono em background e rotina de recuperação para tarefas órfãs após reinício.
- [x] 3.4 Implementar rota `GET /api/v1/scheduling/meetings/ai-status` retornando `{ enabled, host, model }` sem vazar a chave de API, verificando a resposta quando a IA estiver habilitada e desabilitada.

## 4. Frontend: Reformulação da Lista de Compromissos

- [x] 4.1 Criar barra de filtros no topo de `BookingsPage.tsx` com campos `De`, `Até`, seletor de `Tipo de Evento` e campo de `Busca Textual` com debounce de 300ms, sincronizando o estado dos filtros com a URL.
- [x] 4.2 Refatorar layout de `BookingsPage.tsx` de cards em grade para linhas horizontais full-width exibindo data/hora, tipo de evento, status, dados do participante e link direto para WhatsApp (`https://wa.me/55...`).
- [x] 4.3 Integrar navegação ao clicar na linha do compromisso para a rota `/scheduling/bookings/:id` e adicionar modal de reagendamento direto na lista de compromissos com atualização reativa.

## 5. Frontend: Tela de Detalhes da Reunião e Tópicos com IA

- [x] 5.1 Criar página `BookingDetailPage.tsx` com cabeçalho contendo botão voltar, título editável inline, data/hora e links externos opcionais do Google Drive (`Resumo completo ↗` e `Transcrição ↗`), registrando a rota `/scheduling/bookings/:id` no React Router com `PrivateRoute`.
- [x] 5.2 Construir os componentes visuais para os 8 blocos de **Tópicos da Reunião** (Assunto, Participantes, Principais Pontos, Decisões, Aprendizados, Fatos e Números, Próximos Passos e Clientes/Projetos Citados) com botões de edição inline e salvamento via `PUT`.
- [x] 5.3 Criar modal de geração de tópicos com campo de texto para transcrição, contador de caracteres, aviso sobre o host de IA configurado e polling de 3 segundos enquanto o status for `PENDING`.

## 6. Orquestração, Verificação Integrada e Documentação

- [x] 6.1 Atualizar `docker-compose.yml` com as variáveis de ambiente de JWT e IA (`MEETING_AI_ENABLED`, `MEETING_AI_BASE_URL`, `MEETING_AI_API_KEY`, `MEETING_AI_MODEL`), verificando inicialização saudável dos containers `evo-scheduling` e `evo-frontend`.
- [x] 6.2 Executar suite de testes automatizados (`npm test`) em `evo-scheduling-service` e verificar que todos os testes de slots, autenticação, rotas e IA passam com sucesso.
- [x] 6.3 Atualizar a documentação técnica oficial em `docs/MODULO-AGENDA-ESPECIFICACAO-COMPLETA.md` e o índice em `docs/README.md` refletindo as novas capacidades de segurança, listagem executiva e sumarização por IA.
