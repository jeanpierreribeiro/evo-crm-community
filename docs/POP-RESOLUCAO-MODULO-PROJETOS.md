# Relatório Técnico de Resolução e Procedimento Operacional Padrão (POP)
## Módulo de Gestão de Projetos — evo-projects-service & evo-ai-frontend

**Documento de Auditoria, Correção e Replicação entre Instâncias**  
**Data:** 17/11/2026  
**Ecossistema:** jprOS / Evo CRM Community  
**Componentes Afetados:** `evo-projects-service` (Backend Fastify/Prisma) e `evo-ai-frontend-community` (SPA React/Vite)

---

### 1. Resumo Executivo

Durante a validação operacional do módulo de Gestão de Projetos (`/projects`), foram diagnosticadas e sanadas duas falhas críticas:

1. **Falha 1 — Bloqueio de Rede (Network Error) na Criação de Workspace:** A interface exibia toast vermelho de erro de rede sem chegar a emitir requisições HTTP válidas ao servidor de produção.
2. **Falha 2 — Colunas do Fluxo (Kanban / Configurações) Ocultas e Falsa Impressão de "Não Gravação":** Ao acessar `/projects/:id/settings` ou o quadro Kanban, as colunas do projeto não eram exibidas. Ao adicionar novas colunas, o input era limpo mas a tela permanecia vazia, gerando o falso diagnóstico de que o banco de dados não estava persistindo os dados.

Ambas as causas raízes foram isoladas, tratadas a nível de código-fonte e runtime de containers, validadas via testes automatizados e devidamente persistidas na documentação técnica.

---

### 2. Diagnóstico Detalhado e Resolução

#### Falha 1: "Network Error" na Criação de Workspace em Produção

##### A. Sintomas
* Ao preencher o modal "Nova Empresa / Workspace" na rota `/projects` em ambiente de produção (`crm.jeanpierreribeiro.com.br`) e clicar em "Criar Empresa", a interface disparava um alerta vermelho "Network Error".
* Nenhuma requisição POST correspondente era registrada nos logs do container `evocrm_projects` no Docker Swarm.

##### B. Causa Raiz Técnica
O bundle compilado do frontend servido pelo Nginx continha a URL base de desenvolvimento local gravada de forma estática:
```javascript
d4 = "http://localhost:3013",
gea = d4.endsWith("/api/v1/projects") ? d4 : `${d4.replace(/\/+$/,"")}/api/v1/projects`,
Xt = Va.create({ baseURL: gea, headers: { "Content-Type": "application/json" } });
```
O navegador do usuário, acessando o domínio seguro `https://crm.jeanpierreribeiro.com.br`, tentava emitir requisições para `http://localhost:3013/api/v1/projects/workspaces`.  
As políticas de segurança do navegador (Mixed Content — página HTTPS chamando recurso HTTP não-cifrado) e a ausência da porta 3013 aberta no computador local do cliente abortavam a conexão imediatamente, gerando a exceção padrão do Axios: `Network Error`.

##### C. Solução Aplicada
1. **Defesa em Profundidade no Frontend (`projectsApi.ts` e `schedulingApi.ts`):**
   Implementado fallback dinâmico: se a variável de ambiente não estiver substituída ou estiver vazia e a aplicação estiver em contexto HTTPS/produção, utiliza automaticamente `VITE_API_URL` ou `window.location.origin`, eliminando o risco de requisições `http://localhost:3013`.
2. **Substituição nos Bundles de Produção e Script de Branding (`install-branding.sh`):**
   Adicionada sanitização automática no passo 4 de branding:
   ```bash
   sed -i 's|http://localhost:3013|https://api-crm.jeanpierreribeiro.com.br|g' "$js_file" 2>/dev/null || true
   sed -i 's|http://localhost:3012|https://api-crm.jeanpierreribeiro.com.br|g' "$js_file" 2>/dev/null || true
   ```
3. **Injeção de Variáveis nos Compose Files (`docker-compose.prod.yml` e `docker-compose.swarm.yaml`):**
   Configuradas explicitamente as variáveis `VITE_PROJECTS_API_URL`, `VITE_SCHEDULING_API_URL` e `VITE_FINANCE_API_URL` para serem injetadas no startup do container Nginx via `docker-entrypoint.sh`.
4. **Invalidação de Cache:**
   Atualizado o sufixo de versão (`?v=<timestamp>`) no `index.html` e executado `nginx -s reload`.

---

#### Falha 2: Colunas Invisíveis nas Configurações e no Kanban ("Não Gravação")

##### A. Sintomas
* Na tela de configurações do projeto (`/projects/:projectId/settings`), o bloco "Colunas do Fluxo (Kanban)" exibia apenas o formulário de inclusão, sem listar nenhuma das colunas existentes do projeto.
* Ao digitar um nome (ex: 1, 2) e clicar em "+ Adicionar Coluna", o campo de texto era limpo, mas a coluna não aparecia na tela.
* Ao navegar para o quadro Kanban (`/projects/:projectId/kanban`), o quadro também ficava vazio sem nenhuma coluna.

##### B. Causa Raiz Técnica
1. **Inspeção no Banco de Dados (PostgreSQL):**
   As colunas estavam sendo criadas com sucesso no banco:
   ```sql
   SELECT id, name, position, "isDoneColumn" FROM projects.columns WHERE "projectId" = 'cmwk2ufo10009pq010ekk35fk';
   ```
   Retornando as 5 colunas padrão e as novas adicionadas.
2. **Gargalo no Backend (`ProjectService.getProject`):**
   O método apenas delegava para `AccessService.getAuthorizedProject`, que validava autorização mas não trazia o include da relação `columns`, respondendo com `columns: undefined`.
3. **Fragilidade no Frontend (`ProjectDetailsPage.tsx`):**
   O hook de carregamento assumia que `getProject` traria as colunas e forçava `setColumns(projData.columns || [])`.

##### C. Solução Aplicada
1. **Backend (`evo-projects-service/src/services/project.service.ts`):**
   Atualizado `ProjectService.getProject` para buscar explicitamente as colunas ordenadas por `position`:
   ```typescript
   static async getProject(id: string, actor: Actor, expectedWorkspaceId?: string) {
     const project = await AccessService.getAuthorizedProject(id, actor, 'read_project', expectedWorkspaceId);
     const columns = await prisma.column.findMany({
       where: { projectId: project.id },
       orderBy: { position: 'asc' },
     });
     return {
       ...project,
       columns,
     };
   }
   ```
2. **Frontend (`evo-ai-frontend-community/src/pages/projects/ProjectDetailsPage.tsx`):**
   Adicionado carregamento concorrente com tratamento resiliente via `projectsService.listColumns(projectId)`:
   ```typescript
   const [projData, colsData, tasksData] = await Promise.all([
     projectsService.getProject(projectId),
     projectsService.listColumns(projectId).catch(() => []),
     projectsService.listTasks(projectId),
   ]);
   setProject(projData);
   setColumns(colsData?.length ? colsData : (projData.columns || []));
   setTasks(tasksData);
   ```

---

### 3. Guia de Replicação para Outra Instância (Passo a Passo)

Para aplicar estas mesmas correções em outro servidor ou ambiente (homologação/produção), execute os procedimentos abaixo:

#### Passo 1: Atualizar o Backend (`evo-projects-service`)
1. Localize o arquivo `src/services/project.service.ts` no microsserviço de projetos.
2. Garanta que o método `getProject` inclui a busca explícita das colunas do projeto.
3. Se estiver rodando o serviço compilado em Docker/Swarm:
   ```bash
   # Recompilação padrão:
   npm run build
   docker compose restart evo-projects
   # ou no Swarm:
   docker service update --force <stack_name>_evocrm_projects
   ```

#### Passo 2: Atualizar o Frontend (`evo-ai-frontend-community`)
1. No arquivo `src/pages/projects/ProjectDetailsPage.tsx`, garanta a busca concorrente de `listColumns` em `loadProjectData`.
2. Em `src/services/projects/projectsApi.ts`, mantenha o fallback dinâmico HTTPS.

#### Passo 3: Sanitizar URLs de Microsserviços nos Bundles de Produção
Em ambientes de produção com proxy reverso (Traefik / Nginx):
1. Verifique se os bundles JS servidos contêm referências residuais de localhost:
   ```bash
   grep -rn "http://localhost:3013" /caminho/para/nginx/html/assets/
   ```
2. Se houver ocorrências, execute a sanitização ou rode o script de branding:
   ```bash
   API_DOMAIN="https://api-crm.seudominio.com.br"
   for f in /caminho/para/nginx/html/assets/*.js; do
     sed -i "s|http://localhost:3013|${API_DOMAIN}|g" "$f" 2>/dev/null || true
     sed -i "s|http://localhost:3012|${API_DOMAIN}|g" "$f" 2>/dev/null || true
   done
   ```
3. Invalide o cache do `index.html`:
   ```bash
   NEW_V=$(date +%s)
   sed -i "s|?v=[0-9]*|?v=${NEW_V}|g" /caminho/para/nginx/html/index.html
   nginx -s reload
   ```

---

### 4. Checklist de Homologação Pós-Correção

| Item | Ação de Teste | Resultado Esperado | Status |
| :--- | :--- | :--- | :---: |
| 1 | Acessar `/projects` e clicar em "Nova Empresa / Workspace" | Modal abre normalmente | Concluído |
| 2 | Criar um workspace preenchendo nome e cor | Workspace criado sem erro de rede (Network Error) | Concluído |
| 3 | Acessar um projeto criado e ir na aba "Configurações" | Exibe as 5 colunas padrão (Backlog, A Fazer, Em Andamento, Em Revisão, Concluído) | Concluído |
| 4 | Digitar um novo nome no campo de coluna e clicar em "Adicionar Coluna" | A nova coluna é salva e surge imediatamente na lista | Concluído |
| 5 | Alternar para a aba "Quadro (Kanban)" | O Kanban exibe todas as colunas em conformidade com as configurações | Concluído |
| 6 | Abrir modal "Nova Tarefa" | O select de coluna lista todas as colunas ativas do fluxo | Concluído |
