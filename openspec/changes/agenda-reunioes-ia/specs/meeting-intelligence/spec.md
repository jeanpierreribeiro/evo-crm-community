# Spec Delta: meeting-intelligence

## Purpose

Permite a extração automatizada e estruturada de tópicos analíticos de reuniões via inteligência artificial a partir de transcrições, com persistência dedicada e capacidade de edição manual.

## ADDED Requirements

### Requirement: Extração estruturada dos 8 blocos analíticos da reunião
O sistema SHALL extrair exclusivamente oito blocos analíticos (Assunto, Participantes, Principais Pontos, Decisões, Aprendizados, Fatos e Números, Próximos Passos e Clientes/Projetos Citados) a partir de uma transcrição fornecida, sem gerar tarefas automáticas ou pendências no sistema.

#### Scenario: Geração bem-sucedida de tópicos estruturados
- **WHEN** o usuário envia uma transcrição válida para `POST /api/v1/scheduling/bookings/:id/summary/generate`
- **THEN** o sistema SHALL responder com status HTTP 202 Accepted, iniciar o processamento em segundo plano e registrar o status `PENDING`

#### Scenario: Transcrição excedendo limite máximo de tamanho
- **WHEN** o usuário envia um texto de transcrição com quantidade de caracteres superior ao limite configurado em `MEETING_MAX_INPUT_CHARS`
- **THEN** o sistema SHALL responder com status HTTP 413 Payload Too Large e código `TRANSCRIPT_TOO_LARGE`

### Requirement: Consulta e acompanhamento do estado de processamento da IA
O sistema SHALL permitir consultar o sumário da reunião retornando seu estado atual (`PENDING`, `DONE` ou `FAILED`), modelo utilizado e os blocos de tópicos quando concluído, sem expor o texto bruto da transcrição nem chaves de API.

#### Scenario: Consulta de reunião com processamento concluído
- **WHEN** o usuário consulta `GET /api/v1/scheduling/bookings/:id/summary` para uma reunião com estado `DONE`
- **THEN** o sistema SHALL retornar status HTTP 200 contendo o objeto `topics` com os oito blocos preenchidos e a data de geração

#### Scenario: Consulta de reunião inexistente ou sem sumário gerado
- **WHEN** o usuário consulta `GET /api/v1/scheduling/bookings/:id/summary` para um agendamento que ainda não possui sumário
- **THEN** o sistema SHALL responder com status HTTP 404 Not Found e código `SUMMARY_NOT_FOUND`

### Requirement: Edição manual parcial com preservação de blocos inalterados
O sistema SHALL permitir a edição manual de qualquer bloco individual de tópicos e de links externos (`summaryUrl` e `transcriptUrl`), realizando mesclagem com os dados preexistentes e marcando a data de edição manual (`editedAt`).

#### Scenario: Atualização parcial de um único bloco
- **WHEN** o usuário envia `PUT /api/v1/scheduling/bookings/:id/summary` contendo apenas alterações para o bloco `decisions`
- **THEN** o sistema SHALL atualizar as decisões, preservar integralmente os demais sete blocos e registrar o carimbo `editedAt`

#### Scenario: Envio de link externo inválido
- **WHEN** o usuário tenta salvar uma URL externa que não utilize o esquema seguro `https://`
- **THEN** o sistema SHALL rejeitar a requisição com status HTTP 422 Unprocessable Entity e código `INVALID_EXTERNAL_URL`

### Requirement: Exclusão completa do sumário analítico
O sistema SHALL permitir a remoção definitiva do sumário associado a uma reunião, apagando todos os tópicos e metadados persistidos sem remover o compromisso original da agenda.

#### Scenario: Exclusão com sucesso do sumário
- **WHEN** o atendente autenticado envia requisição `DELETE /api/v1/scheduling/bookings/:id/summary`
- **THEN** o sistema SHALL remover o registro em `meeting_summaries`, responder com status HTTP 204 No Content e atualizar `hasSummary` para falso na listagem
