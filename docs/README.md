# Documentação Técnica do jprOS

Bem-vindo ao diretório de documentação oficial do ecossistema **jprOS**.

---

### Documentos Disponíveis:

1. 📘 **[DOCUMENTACAO-COMPLETA-JPROS.md](./DOCUMENTACAO-COMPLETA-JPROS.md)**
   * **Leitura Principal Obrigatória.**
   * Explicação aprofundada de **como o sistema nasceu e evoluiu** pelas 5 sessões de engenharia.
   * Visão geral de arquitetura, paradigma Headless, catálogo de módulos do core da Evolution Platform e módulos customizados (`evo-scheduling-service`, `evo-projects-service`, `evo-finance-service`).
   * Matriz de portas, roteamento reverso Nginx, integração MCP (Model Context Protocol) para IA e guia de operação Git/Docker.

2. 📅 **[MODULO-AGENDA-ESPECIFICACAO-COMPLETA.md](./MODULO-AGENDA-ESPECIFICACAO-COMPLETA.md)**
   * **Especificação Técnica do Módulo de Agendamentos (`evo-scheduling-service`).**
   * Paradigma Headless, porting da engine do Cal.com, cálculo determinístico de slots anti-conflito, modelagem Prisma, API REST, telas no frontend, guardas de rota e Function Calling para agentes de IA no WhatsApp.

3. 🤖 **[PLANEJAMENTO-AJUSTES-AGENDA-REUNIOES-IA.md](./PLANEJAMENTO-AJUSTES-AGENDA-REUNIOES-IA.md)**
   * **Planejamento de Ajustes de Lista de Reuniões & Inteligência de Tópicos com IA.**
   * Layout em lista horizontal com filtros avançados (`De`/`Até`, tipo, busca).
   * Tela de detalhes da reunião (`/scheduling/bookings/:id`) com extração de 8 blocos de tópicos via IA (OpenAI, OpenRouter e Gemini com Base URL personalizada ou conta integrada em `/settings/integrations`).

4. 🚀 **[SETUP-GUIDE.md](./SETUP-GUIDE.md)**
   * Guia passo a passo para inicialização da infraestrutura Docker local ou deploy em Docker Swarm.

5. 🛠️ **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**
   * Resolução de problemas comuns com conexões de banco de dados, variáveis de ambiente Vite, concorrência OCC (409) e portas de containers.

6. 📋 **[projetos-evidencias.md](./projetos-evidencias.md)**
   * Rastreabilidade oficial de entregas, suítes de testes T01 a T20, reconciliação de 13 migrações e homologação formal dos Gates 1, 2, 3 e 4 do submódulo de projetos.

7. 🤖 **[adr-contrato-crm.md](./adr-contrato-crm.md)** & **[matriz-consumidores-mcp.md](./matriz-consumidores-mcp.md)**
   * ADR de integração determinística do CRM (invariante DP14) e matriz de compatibilidade do servidor MCP Streamable HTTP.

8. 🔒 **[politica-retencao.md](./politica-retencao.md)**
   * Diretrizes de retenção, expiração de links/PINs e auditoria.

---

### Especificações Técnicas de Módulos (na Raiz do Projeto):
- 📋 **[solicitacao-ajustes-projetos-v2.0.md](../solicitacao-ajustes-projetos-v2.0.md)**: Plano normativo vigente, decisões de produto (DP01 a DP16) e arquitetura de segurança do submódulo de Projetos.
- 📋 **[solicitacao-implementacao-projetos.md](../solicitacao-implementacao-projetos.md)**: Especificação funcional inicial (Kaneo Engine).
- 💰 **[solicitacao-implementacao-financeiro.md](../solicitacao-implementacao-financeiro.md)**: Especificação funcional e de banco do Módulo Financeiro (iLAB4 Gestão Financeira).
