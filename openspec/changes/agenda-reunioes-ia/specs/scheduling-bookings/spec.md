# Spec Delta: scheduling-bookings

## Purpose

Fornece consulta, filtragem avançada e gerenciamento de compromissos da agenda de forma autenticada, garantindo isolamento por usuário e proteção contra sobreposição de horários.

## ADDED Requirements

### Requirement: Autenticação obrigatória em rotas administrativas de compromissos
O sistema SHALL exigir token JWT emitido pelo serviço de autenticação para todas as operações administrativas de listagem e detalhamento de compromissos, ignorando qualquer identificador de usuário fornecido no corpo ou nos parâmetros da requisição e utilizando estritamente a identidade extraída do token (`sub`).

#### Scenario: Requisição sem token de autenticação
- **WHEN** um cliente envia requisição para `GET /api/v1/scheduling/bookings` sem cabeçalho `Authorization`
- **THEN** o sistema SHALL responder com status HTTP 401 Unauthorized e código `UNAUTHORIZED`

#### Scenario: Requisição com token de autenticação válido
- **WHEN** um atendente autenticado envia requisição para `GET /api/v1/scheduling/bookings` com JWT válido
- **THEN** o sistema SHALL responder com status HTTP 200 e retornar apenas os compromissos pertencentes àquele usuário

### Requirement: Filtragem combinada de compromissos no servidor
O sistema SHALL permitir filtrar compromissos por status, intervalo de datas (`from` e `to`), tipo de evento (`eventTypeId`) e busca textual (`search`), interpretando datas simples (`YYYY-MM-DD`) no fuso horário do atendente.

#### Scenario: Filtragem por período e busca textual
- **WHEN** o usuário requisita compromissos com `from=2026-10-01`, `to=2026-10-31` e `search=Carlos`
- **THEN** o sistema SHALL retornar apenas os compromissos agendados para outubro de 2026 cujo título, nome do participante, e-mail ou telefone contenham o termo "Carlos"

#### Scenario: Parâmetro de data inicial posterior à data final
- **WHEN** o usuário requisita compromissos com `from=2026-11-01` e `to=2026-10-01`
- **THEN** o sistema SHALL responder com status HTTP 422 Unprocessable Entity e código `INVALID_DATE_RANGE`

### Requirement: Indicador de sumário na listagem de compromissos
O sistema SHALL incluir na resposta da listagem de compromissos o campo booleano `hasSummary`, indicando se a reunião possui tópicos analíticos cadastrados, sem trafegar o conteúdo completo dos tópicos.

#### Scenario: Compromisso com reunião sumarizada
- **WHEN** a listagem de compromissos é consultada e determinado agendamento possui registro associado em `meeting_summaries`
- **THEN** o item correspondente no array `data` SHALL apresentar `hasSummary: true`

### Requirement: Bloqueio anti-conflito e integridade em reservas e reagendamentos
O sistema SHALL validar a disponibilidade do slot contra os horários de expediente e buffers do tipo de evento sob trava transacional, permitindo que uma reunião seja reagendada para horário parcialmente sobreposto a si mesma sem conflitar com seu próprio registro anterior.

#### Scenario: Reagendamento seguro excluindo a própria reunião
- **WHEN** o atendente solicita o reagendamento de um compromisso existente fornecendo novo horário que sobrepõe parcialmente o intervalo original
- **THEN** o sistema SHALL calcular os slots excluindo a reunião em alteração e efetivar o reagendamento com status HTTP 200 caso o novo horário esteja livre

#### Scenario: Tentativa simultânea de agendamento no mesmo horário
- **WHEN** duas requisições concorrentes tentam reservar exatamente o mesmo slot de um atendente
- **THEN** uma das requisições SHALL ser aceita com status HTTP 201 e a outra SHALL ser rejeitada com status HTTP 409 Conflict
