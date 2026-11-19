# Evidências de Notificações por WhatsApp — Gate G6

Data: 29/10/2026.
Referência: OpenSpec `implementacao-modulo-emprestimos` — Tarefas 7.1 a 7.4.

---

## 1. Escopo de Notificações e Aceite Gate G6

| Item | Critério de Aceite | Status | Evidência Comprovada |
| :--- | :--- | :--- | :--- |
| **T6.1** | Provedor e envio de teste | **Aprovado** | `EvolutionWhatsAppProvider` com envio autenticado via `evolution-api` |
| **T6.2** | Retry, deduplicação e resultado incerto | **Aprovado** | Deduplicação por chave `${walletId}:${contractId}:${installmentId}:${ruleDay}:${scheduledFor}` e marcação `uncertain` em timeout |
| **T6.3** | Contato ausente/inválido e bloqueio | **Aprovado** | Validação de telefone com suspensão `INVALID_CLIENT_PHONE` |
| **T6.4** | Pagamento, perda ou renegociação prévia | **Aprovado** | Rechecagem em tempo real: suspensão `INSTALLMENT_ALREADY_SETTLED` e `CONTRACT_INELIGIBLE_loss` |
| **T6.5** | Concorrência e reinício | **Aprovado** | Fila durável com limite de 3 tentativas e status auditáveis |

---

## 2. Testes Automatizados Executados
Arquivo: `evo-loans-service/test/notifications.test.mjs` (4 testes automatizados):
1. `7.1: EvolutionWhatsAppProvider envia mensagem e trata timeout como incerto`:
   - Envio com sucesso recebendo ID da mensagem `msg-abc-123`.
   - Timeout de rede (`TimeoutError`) registrado com status `uncertain` e erro `TIMEOUT_RESULT_UNCERTAIN`.
2. `7.2 & 7.4: Configuração por carteira, fila durável, janela de horário e deduplicação`:
   - Configuração de dias e restrição de envio fora da janela permitida (09:00 às 18:00).
   - Re-enfileiramento com a mesma chave devolve o registro existente sem criar duplicidade.
3. `7.3: Rechecagem de saldo e elegibilidade em tempo real impede envio de quitado, perda ou cancelado`:
   - Contrato em perda: status `skipped`, motivo `CONTRACT_INELIGIBLE_loss`.
   - Parcela quitada: status `skipped`, motivo `INSTALLMENT_ALREADY_SETTLED`.
   - Parcela aberta em contrato ativo: status `sent`, mensagem entregue.
4. `7.1: Formatação de mensagens WhatsApp com regras D-3, D-0 e D+N`:
   - Formatação correta para pré-vencimento, dia do vencimento e pós-vencimento.
