# Matriz de Consumidores MCP e Compatibilidade de Protocolo (Entrega 4.0-a)

Este documento define a matriz de compatibilidade técnica para o servidor MCP (*Model Context Protocol*) embutido no microsserviço de Projetos (`evo-projects-service`), conforme especificado na Seção 8, Seção 17 e Etapa E4.0 da `solicitacao-ajustes-projetos-v2.0.md`.

---

## 1. Identificação dos Consumidores do Ecossistema

| Consumidor | Natureza | Função no Ecossistema | Transporte Primário | Protocolo MCP | Autenticação |
|---|---|---|---|---|---|
| **`evo-ai-processor-community`** | Serviço Interno (Node/Go) | Assistente de Operador e Automações de Background | Streamable HTTP (`POST /mcp`) | `2024-11-05` / `2025-11-25` (`initialize`) | Bearer Service Principal (`sp_*`) |
| **`evo-bot-runtime`** | Serviço Interno (Node) | Agente de Atendimento ao Cliente (WhatsApp / Omnichannel) | Streamable HTTP (`POST /mcp`) | `2024-11-05` / `2025-11-25` (`initialize`) | Bearer Service Principal (`sp_*`) + Headers de Contexto CRM |
| **IDEs / Clientes Externos** (Claude Desktop, Cursor, Antigravity) | Clientes MCP Externos | Assistência técnica e desenvolvimento para operadores | Streamable HTTP ou Stdio Bridge | `2024-11-05` / `2025-11-25` | Bearer JWT de Operador (`ADMIN`/`MEMBER`) ou Service Principal |
| **Rotas Legadas de Transição** (`/mcp/tools`, `/mcp/call`) | Legado em Depreciação | Suporte transitório a consumidores sem cliente MCP JSON-RPC 2.0 | REST HTTP síncrono | N/A (JSON Schema direto) | Bearer JWT ou Service Principal (`sp_*`) |

---

## 2. Versões do Protocolo MCP e Métodos Suportados

### 2.1 Especificações do Protocolo
- **Versão Homologada**: Revisões `2024-11-05` e `2025-11-25` (padrão estável suportado pelos SDKs oficiais e pelas ferramentas de mercado).
- **Mecanismo de Descoberta / Handshake**:
  - Suporte ao método `initialize` com resposta contendo `serverInfo` (`name: "evo-projects-service"`, `version: "1.0.0"`) e declaração das capabilities (`tools: {}`).
  - Suporte a `notifications/initialized` idempotente.
  - Mapeamento preparado para a revisão `2026-07-28` (`server/discover` via cabeçalhos HTTP sem forçar handshake stateful).

### 2.2 Métodos JSON-RPC 2.0 Aceitos (`POST /api/v1/projects/mcp`)
1. **`initialize`**: Negocia capacidades e versão do protocolo.
2. **`tools/list`**: Lista ferramentas ativas condicionadas estritamente aos grants do ator (`IntegrationGrant`).
3. **`tools/call`**: Executa ferramenta com validação de escopo, permissões e parâmetros tipados via Zod.
4. **`ping`**: Teste de liveness leve.

---

## 3. Decisão sobre Transportes de Rede (ADR de Transporte)

### 3.1 Streamable HTTP (Transporte Padrão Homologado)
- **Endpoint**: `POST /api/v1/projects/mcp`
- **Justificativa**: Transporte síncrono, stateless, compatível com o proxy reverso Nginx, com Swarm e com Kubernetes. Não exige manter conexões abertas por longos períodos nem sessões em memória no cluster.
- **Formato**: JSON-RPC 2.0 com `Content-Type: application/json`.

### 3.2 Decisão sobre SSE Legado (Server-Sent Events - `/mcp/sse`)
- **Decisão**: **NÃO HABILITADO POR PADRÃO**.
- **Motivo Técnico**: O ecossistema jprOS não possui nenhum consumidor ativo que exija SSE bidirecional persistente. O transporte SSE em ambientes com múltiplas réplicas e containers Swarm introduz complexidade desnecessária de afinidade de sessão (*sticky sessions*), buffering de proxy no Nginx e riscos de memory leak.
- O protocolo oficial MCP suporta nativamente Streamable HTTP para todas as operações síncronas de ferramentas (`tools/call` e `tools/list`).

---

## 4. Segurança, Autenticação e Proteção do Transporte

1. **Autenticação Obrigatória**:
   - Nenhuma ferramenta MCP pode ser executada anonimamente (`isPublic: false`).
   - Requisições devem fornecer cabeçalho `Authorization: Bearer <token>`.
   - Se o token iniciar com `sp_`, é validado pelo hash criptográfico SHA-256 em `ServiceCredential`, verificando expiração (`expiresAt`), revogação (`revokedAt`) e a existência de `IntegrationGrant` ativo para o workspace solicitado.
   - Se for um token JWT emitido pelo Auth Service, valida a assinatura e autoriza as permissões do operador.
2. **Validação de Origem (`Origin` Header Validation)**:
   - O endpoint MCP valida o cabeçalho `Origin` (quando presente em requisições de navegadores) contra a lista de domínios permitidos (`APP_URL`, `SUBDOMAIN_FRONTEND`), prevenindo ataques de DNS rebinding e Cross-Site MCP Hijacking.
3. **Isolamento de Erros e Stack Traces**:
   - Erros de execução retornam mensagens amigáveis e estruturadas em JSON-RPC (`-32000` ou `-32602`), sem expor stack traces, consultas de banco de dados ou caminhos do servidor.
4. **Rate Limit e Quotas Operacionais**:
   - Quota de chamadas por Service Principal: limite configurável de requisições por minuto com chaveamento no Redis/memória para prevenir loops em automações.

---

## 5. Matriz de Ferramentas Homologadas para Fase 4

| Ferramenta | Tipo | Restrição de Acesso | DTO de Retorno |
|---|---|---|---|
| `list_workspaces` | Leitura | Apenas workspaces explicitamente concedidos em `IntegrationGrant` | `WorkspaceDTO` sanitizado |
| `list_projects` | Leitura | Requer grant no workspace/projeto especificado | `ProjectDTO` sanitizado |
| `list_tasks` | Leitura | Filtros de escopo obrigatórios; tarefas do escopo do ator | `TaskInternalDTO` ou `TaskCustomerAgentDTO` |
| `get_task` | Leitura | Requer acesso autorizado à tarefa | `TaskCustomerAgentDTO` (se agente cliente) |
| `create_task` | Escrita | Projeto e coluna válidos; suporta `idempotencyKey` | Tarefa criada sanitizada |
| `update_task` | Escrita | Versão esperada (`expectedVersion`) obrigatória (OCC) | Tarefa atualizada |
| `create_task_share` | Escrita | Requer `canShare: true` no `IntegrationGrant` | Link e PIN de 6 dígitos |
| `resolve_workspace` | Resolução | Consulta vínculos do CRM (`FOUND`, `NOT_FOUND`, `AMBIGUOUS`) | Resultado de resolução sem conceder escrita |

*Nota: Exclusão definitiva de tarefas, remoção de projetos, concessão de privilégios de membros e transferência entre projetos são **estritamente vedadas** ao MCP por design de segurança.*
