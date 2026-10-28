# Solicitação de Implementação: Submódulo de Gestão de Projetos, Multi-Workspace, Dashboard, Gantt & Portal de Tarefas (jprOS + Kaneo Engine)

> [!IMPORTANT]
> **DOCUMENTO HISTÓRICO COM PRECEDÊNCIA DO PLANO V2.0:**
> As diretrizes, arquitetura e decisões deste documento foram formalmente atualizadas e substituídas pela especificação normativa **`solicitacao-ajustes-projetos-v2.0.md`** (Versão 2.0, Revisão 2) e homologadas conforme registrado em `docs/projetos-evidencias.md`.
> - **Precedência Normativa:** Em qualquer divergência de requisitos, prevalece estritamente `solicitacao-ajustes-projetos-v2.0.md` e as Decisões de Produto DP01 a DP16.
> - **Substituição do Portal de Aprovação:** O fluxo legado de aprovação pública foi aposentado e substituído pelo **Compartilhamento de Leitura Protegido por PIN de 6 dígitos** (Fase 2 / DP07), acessível exclusivamente em `/p/task/:token`.
> - **Alinhamento de Rotas da API:** A API oficial é disponibilizada com prefixo canônico `/api/v1/projects/*` (porta 3030 no Gateway Nginx e 3013 em desenvolvimento local) e o servidor MCP opera via Streamable HTTP JSON-RPC 2.0 em `POST /mcp` e `/api/v1/projects/mcp`.

Olá! Estou trabalhando no ecossistema **jprOS** (`C:\Users\pi3rr3\Documents\Projetos\jprOS`), que é nosso fork customizado do `evo-crm-community` da Evolution Foundation.

Nosso ecossistema é gerenciado por **Git Submodules** e orquestrado via **Docker Compose** e **Nginx** (com serviços como `evo-auth-service-community`, `evo-ai-crm-community`, `evo-ai-frontend-community`, `evo-scheduling-service`, `evolution-api`, `evo-bot-runtime`, `evo-ai-processor-community`, etc.).

---

### AMBIENTE E INSTÂNCIA DO KANEO (FONTE DE REFERÊNCIA)
O Kaneo já está **implantado e rodando localmente** nesta máquina para consulta, inspeção e testes:
- **URL da Aplicação Ativa**: `http://localhost:5180/`
- **Caminho do Código-Fonte Completo**: `C:\Users\pi3rr3\Documents\Projetos\kaneo`
- **Histórico da Implantação Local**: Sessão `a70081da-9697-4d03-a704-60376197a2c8`
- **Arquivos-Chave no `kaneo` para consulta e extração**:
  - **Estrutura do Card de Tarefas (Drawer e Tela Cheia)**:
    - `C:\Users\pi3rr3\Documents\Projetos\kaneo\apps\web\src\components\task/` (Todos os componentes do card: título inline, descrição markdown, subtarefas, relações, recursos, atividade, comentários e painel lateral de propriedades).
    - `apps/web/src/routes/_layout/_authenticated/dashboard/workspace/$workspaceId/project/$projectId/task.$taskId.tsx` (Visualização em página inteira / Fullscreen).
  - **Home (Dashboard) & Feed de Atividades**:
    - `C:\Users\pi3rr3\Documents\Projetos\kaneo\apps\web\src\routes\_layout\_authenticated\dashboard\workspace\$workspaceId\index.tsx` (Dashboard com calendário semanal, "Up next", projetos com % e feed "Activity").
    - `apps/api/src/activity/` (Histórico de atividades do workspace).
  - **Inbox & Notificações**:
    - `apps/web/src/routes/_layout/_authenticated/dashboard/workspace/$workspaceId/inbox.tsx` e `apps/api/src/notification/`.
  - **Gráfico de Gantt**:
    - `C:\Users\pi3rr3\Documents\Projetos\kaneo\apps\web\src\components\gantt\timeline.ts` (cálculo de timeline com `date-fns`).
    - `apps/web/src/components/gantt/gantt-task-bar.tsx` e rota `gantt.tsx`.
  - **Quadro Kanban e Visualizações**:
    - `apps/web/src/components/board/` (Kanban), `list.tsx` (Lista), `calendar.tsx` (Calendário), `backlog.tsx` (Backlog).
  - **Multi-Workspace & Organizações**:
    - `apps/api/src/workspace/` e `apps/api/src/workspace-members/`.
  - **Integração MCP (Model Context Protocol) para IA**:
    - `packages/mcp/src/tools/register.ts` (ferramentas como `list_workspaces`, `list_projects`, `list_tasks`, `create_task`, `update_task`, etc.).

---

### OBJETIVO
Implementar um novo submódulo dedicado à **Gestão de Projetos, Multi-Workspace, Dashboard Central, Inbox, Gantt e Portal de Validação/Aprovação de Tarefas** (`evo-projects-service`) para o ecossistema `jprOS`.

Optamos pela **Abordagem Headless (Engine de Regras + API)**:
- Não traremos o monorepo inteiro do Kaneo nem substituiremos a autenticação base do Evo CRM.
- Criaremos um microsserviço limpo em Node.js/TypeScript (Fastify ou Hono + Prisma/Drizzle com PostgreSQL compartilhado do jprOS).
- A autenticação dos operadores será integrada diretamente ao token JWT do `evo-auth-service-community`.
- A interface de usuário será implementada nativamente no `evo-ai-frontend-community` seguindo exatamente o design system existente do Evo CRM.

---

### ESCOPO DETALHADO DA IMPLEMENTAÇÃO

#### 1. Arquitetura Multi-Workspace (Isolamento por Empresa/Negócio)
- Cada **Workspace** representa uma empresa ou cliente atendido (ex: "Empresa Alfa", "Barbearia GodOfBarber", "Operação Interna").
- Os projetos, quadros, tarefas, membros, etiquetas e gráficos de Gantt pertencem a um workspace específico, garantindo isolamento total de dados entre clientes.
- O usuário logado no jprOS pode pertencer a múltiplos workspaces e alternar entre eles instantaneamente por meio do seletor no topo da navegação.
- Permite gerenciar membros e níveis de acesso (Admin da Empresa, Membro, Visualizador) por workspace.

#### 2. Anatomia Completa do Card de Tarefa (Idêntica ao Kaneo)
O card de tarefa deve suportar alternância entre **Drawer Lateral** (modal sobreposto) e **Página Inteira (Fullscreen)** com todas as seguintes seções:
- **Cabeçalho (Header)**:
  - Breadcrumb navegável (`Nome do Projeto > ID-123`).
  - Botão `Copiar link da tarefa`.
  - Botão `Alternar tela cheia` (Drawer ↔ Fullscreen).
  - Menu `Mais Ações`: Copiar ID da tarefa, Copiar título, Copiar como Markdown, Excluir tarefa.
  - **Botão `Compartilhar para Validação`** (veja item 3 abaixo).
- **Corpo Central**:
  - Título inline editável.
  - Descrição rica em Markdown com suporte a upload de arquivos e imagens.
  - **Subtarefas (Checklists)**: Itens com checkbox, ordenação e barra de progresso visual com cálculo automático de `%` concluído.
  - **Relações (Dependências)**: Vínculos entre tarefas (*bloqueia*, *bloqueada por*, *relacionada a*), alimentando o Gráfico de Gantt.
  - **Recursos (Links Externos)**: Links diretos para Figma, Google Drive, documentos ou repositórios vinculados à tarefa.
  - **Atividade & Comentários**: Histórico cronológico de mudanças e caixa para novos comentários com menções (`@`) e anexos.
- **Barra Lateral de Propriedades**:
  - `Status`: Coluna atual do fluxo com dropdown de transição rápida.
  - `Prioridade`: Sem prioridade, Baixa, Média, Alta, Urgente (com ícones e cores).
  - `Responsável`: Seleção de membro da equipe com avatar.
  - `Etiquetas (Labels)`: Tags coloridas customizáveis.
  - `Datas`: Data de início e Data de vencimento (com datepicker visual).
  - `Projeto`: Vínculo do projeto.
  - `Apontamento de Horas (Time Tracking)`: Registro de tempo gasto pelo operador.
  - `Campos Personalizados (Custom Fields)`: Campos dinâmicos do projeto (texto, número, seleção, data).

#### 3. Recurso Exclusivo: Link de Validação e Aprovação da Tarefa pelo Cliente
Para prestadores de serviços, agências e suporte:
- O operador clica em `Gerar Link de Validação / Aprovação`.
- O sistema gera um link seguro com um **Token / Código de Acesso único (PIN)** (ex: `https://meucrm.com/tasks/validate/xyz123?pin=8492` ou tela pública onde o cliente digita o PIN informado).
- **Página Pública do Cliente (Mobile-friendly e limpa)**:
  - O cliente visualiza o resumo da entrega (título, descrição, anexos para download/visualização e checklist de itens finalizados).
  - Botões de Ação do Cliente:
    - **[ ✅ Aprovar Entrega ]**: Ao clicar, a tarefa é marcada automaticamente como *Aprovada* (ou movida para a coluna configurada, ex: "Concluído") e grava a data/hora e IP da aprovação no histórico da tarefa.
    - **[ 💬 Solicitar Ajustes ]**: Abre um campo para o cliente descrever o que precisa ser corrigido, gerando uma notificação imediata no Inbox do responsável.
  - O cliente **não tem acesso** aos comentários internos, outras tarefas ou dados de outros clientes.

#### 4. Backend: Novo Microsserviço (`evo-projects-service`)
Criar o submódulo em `C:\Users\pi3rr3\Documents\Projetos\jprOS\evo-projects-service`:
- **Modelagem de Dados**:
  - `workspaces`, `workspace_members`, `projects`, `columns`, `tasks`, `subtasks`, `task_relations`, `custom_fields`, `custom_field_values`, `time_entries`, `comments`, `activities`, `notifications`.
  - `task_approvals`: Tokens de validação externa, PIN, status de aprovação (`pending`, `approved`, `changes_requested`), feedback do cliente e timestamps.
- **API REST**:
  - Endpoints de workspaces, membros e alternância de contexto.
  - Endpoints da Home/Dashboard (estatísticas, tarefas "Up next" e feed).
  - Endpoints do Inbox (listar notificações, marcar como lida, arquivar).
  - Endpoints CRUD para projetos, tarefas, colunas, subtarefas e movimentação drag-and-drop.
  - Endpoints públicos para validação de tarefa com PIN (`/api/projects/public/tasks/:token/validate` e `/approve`).
- **Servidor MCP Embutido (`/api/mcp`)**:
  - Ferramentas MCP (`list_workspaces`, `list_projects`, `list_tasks`, `create_task`, `update_task`, `get_task`, `request_task_approval`) para consumo pelo `evo-ai-processor-community` e `evo-bot-runtime`.
- **Infraestrutura**:
  - Adicionar o serviço `evo-projects` no `docker-compose.yml` e `docker-compose.prod.yml` do `jprOS`.
  - Configurar proxy e rotas no `nginx/` para `/api/projects`.

#### 5. Frontend (`evo-ai-frontend-community`)
Integrar no padrão de navegação nativo do Evo CRM (Menu Principal + Drawer Secundário Retrátil):
- **Menu Principal (Barra Lateral Esquerda)**:
  - Adicionar item raiz com o nome **`📁 Projetos >`** e a seta expansora (seguindo exatamente o padrão dos itens *Contatos*, *Agentes de IA* e *Agenda*).
- **Drawer Secundário Retrátil (ao clicar em Projetos)**:
  - **Seletor de Workspace no Topo**:
    - Dropdown rápido para selecionar a **Empresa Ativa** (ex: `[ 🏢 Empresa Alfa ▾ ]`), com botão para criar/gerenciar workspaces.
  - **Navegação Global da Empresa**:
    - `🏠 Início (Home)`: Dashboard com mini-calendário, tarefas "Up next", lista de projetos com `%` e feed de atividades.
    - `📥 Caixa de Entrada (Inbox)`: Central de notificações de tarefas daquela empresa.
    - `👤 Minhas Tarefas`: Visão consolidada de todas as tarefas daquela empresa atribuídas ao operador.
    - `👥 Membros`: Listagem e convite de membros do workspace.
  - **Seção de Projetos da Empresa**:
    - Lista de projetos existentes com contador e botão `[ + Novo Projeto ]`.
    - Ao selecionar um projeto, exibe as visões:
      - `📌 Quadro (Kanban)`: Visão padrão com colunas arrastáveis (Drag & Drop).
      - `📄 Lista`: Visão tabular ágil para triagem e edição rápida.
      - `📊 Gráfico de Gantt`: **(Requisito Essencial)** Visualização de cronograma baseada em tempo (engine `date-fns` extraída do Kaneo), destacando dependências e janelas de execução.
      - `📅 Calendário`: Grade mensal/semanal de datas de entrega e marcos.
      - `📥 Backlog`: Área de triagem e priorização.
      - `⚙️ Configurações`: Colunas, etiquetas e campos personalizados.
- **Página Pública de Validação do Cliente**:
  - Rota pública e responsiva (`/p/task/:token`) para o cliente validar e aprovar a entrega via PIN sem precisar de login.

#### 6. Integração com IA e WhatsApp (Agentes Autônomos)
- Deixar a API e o MCP prontos para expor Tools para o `evo-ai-processor-community` e `evo-bot-runtime`.
- Durante um atendimento no WhatsApp pelo Evo CRM, a IA poderá:
  - Identificar o workspace/empresa correta pelo contato ou canal.
  - Criar tarefas de suporte ou comerciais vinculadas ao projeto correto.
  - Gerar e enviar o link de aprovação da tarefa diretamente na conversa do WhatsApp para o cliente aprovar.
  - Consultar prazos no projeto/Gantt e responder o cliente diretamente no WhatsApp.

---

### O QUE NÃO DEVE SER INCLUÍDO
- Não incluir autenticação Better Auth externa (usar a autenticação JWT do `evo-auth-service-community`).
- Não incluir integrações de branches Git (GitHub/GitLab PRs).
- Não incluir projetos públicos abertos para a internet (todas as tarefas são internas e seguras, exceto a validação pontual de card por PIN).
- Não incluir rotinas de faturamento/billing (Creem).

---

### DIRETRIZES DE EXECUÇÃO
1. Antes de codificar, analise a estrutura atual do `jprOS` (especialmente `docker-compose.yml`, `.gitmodules` e a navegação no `evo-ai-frontend-community`).
2. Apresente o plano de execução dividido em fases incrementais e me peça confirmação para iniciar cada etapa.
3. Mantenha os diffs pequenos, código tipado com TypeScript e siga os padrões visuais e arquiteturais dos submódulos já existentes (como o `evo-scheduling-service`).
