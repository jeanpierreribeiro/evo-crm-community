# ADR 001: Decisão sobre Entrega Externa e Adiantamento da Infraestrutura de Outbox (E3.5-e)

**Status:** Decidido / Adiado Condicionalmente  
**Data:** 2026-10-27  
**Etapa:** E3.5-e (`solicitacao-ajustes-projetos-v2.0.md` — Seção 10 e Seção 14.5)  
**Autor:** Equipe de Arquitetura jprOS / Antigravity Agent  

---

## 1. Contexto
A especificação do submódulo Projetos v2.0 (seção 10 e seção 14.5, item 3.5-e) define:
> *"Registrar se há consumidor concreto autorizado que exige entrega assíncrona confiável. Sem consumidor, marcar a decisão como concluída e a implementação como adiada/não aplicável ao gate do núcleo; não criar tabela, worker ou serviço vazio. Ao surgir o primeiro consumidor, implementar conjuntamente `OutboxEvent`, gravação transacional, retries, deduplicação por `eventId`, falhas persistentes e monitoramento. Sem evento `task.approved` nem cobrança por visualização."*

## 2. Inventário de Consumidores
1. **Consumidores Atuais do Núcleo:**
   - Interface Web Operacional (`evo-ai-frontend-community`): consome API REST síncrona com DTOs padronizados.
   - Ferramentas MCP (`evo-projects-service/src/mcp`): chamadas síncronas Streamable HTTP.
   - Portal de Leitura Externa por PIN: consumo síncrono somente-leitura autenticado via sessão de share.
2. **Consumidores Externos em Potencial:**
   - Módulo Financeiro (`evo-finance-service`): previsto para a Fase 6 (fora do núcleo operacional).
   - Webhooks ou mensageria externa de terceiros: não configurados no ambiente atual.

## 3. Decisão Arquitetural
1. **Implementação Adiada:** Como não existe consumidor concreto ativo que dependa de publicação assíncrona confiável, a criação de tabelas (`outbox_events`), workers de despacho em background e filas associadas é formalmente **adiada**.
2. **Não Proliferação de Infraestrutura Vazia:** Nenhuma tabela fantasma, worker ocioso ou mock de fila será criado no banco de dados neste estágio.
3. **Auditoria e Notificações Transacionais:** A auditoria (`activities`) e notificações internas (`notifications`) operam no mesmo boundary de transação do PostgreSQL (`withTransaction`), garantindo que se uma mutação sensível falhar, a auditoria é abortada, e se a auditoria falhar, a mutação sofre rollback completo (T11 / E3.5-c).
4. **Sem Eventos Legados:** Não será gerado nem publicado qualquer evento relativo ao legado de aprovação (`task.approved`) ou qualquer evento de cobrança/faturamento por abertura ou visualização de links de compartilhamento (DP05, DP15).

## 4. Consequências e Critérios de Ativação Futura
- **Gate 3:** O adiamento condicional cumpre formalmente o critério do item 3.5-e e não bloqueia a homologação do núcleo operacional.
- **Ativação Futura:** Quando o primeiro consumidor real surgir (ex: Fase 6 — Integração Financeira ou Fase 4 — Agentes com Webhooks), os seguintes componentes serão implementados conjuntamente:
  - Tabela `outbox_events` (`id`, `aggregateType`, `aggregateId`, `eventType`, `payload`, `status`, `retries`, `createdAt`, `processedAt`);
  - Gravação do evento na mesma transação da mutação de negócio;
  - Worker desacoplado com backoff exponencial e deduplicação estrita por `eventId`;
  - Monitoramento de eventos com falha definitiva (dead-letter).
