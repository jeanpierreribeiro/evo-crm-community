# Evidências de validação para piloto autenticado — Gate G3

Registro de 29/10/2026.
Consolidação das condições do piloto autenticado de cobrança, restauração, permissões de carteira e capacidades G2 habilitadas.

## 1. Topologia e autenticação autenticada (G0 a G3)
- **Token JWT e Identidade Ativa:** Tokens emitidos pelo `evo-auth-service` com algoritmo `HS256`, validação de issuer `evo-auth-service`, audience e checagem de integridade de identidade via endpoint interno `/api/v1/internal/loans-directory/verify`. Respostas indisponíveis falham fechado com 503 `AUTH_UNAVAILABLE` sem bypass.
- **Prontidão e Health:**
  - `GET /health` e `GET /api/v1/loans/health`: respondem `200 { "status": "ok" }`.
  - `GET /ready`: verifica conexão ao PostgreSQL e integridade de migrations com soma de verificação. Fails closed com 503 `not_ready` em caso de divergência.
- **Variáveis de Ambiente de Execução:**
  - `LOANS_ENABLED=true`
  - `LOANS_CONTRACT_CONFIRM_ENABLED=true`
  - `LOANS_PAYMENTS_ENABLED=true`
  - `LOANS_HISTORICAL_ENABLED=true`
  - `LOANS_AGREEMENTS_ENABLED=true`
  - As flags são recebidas via Zod schema em `server.ts` e aplicadas às rotas da carteira sem defaults inseguros.

## 2. Permissões locais e isolamento por carteira
- **Membros e Papéis:**
  - Cada carteira possui associação estrita de membros com papéis `admin`, `operator` e `viewer`.
  - O acesso cruzado entre carteiras é estritamente negado com `404 NOT_FOUND` (não revelando nem a existência do recurso de outra carteira).
  - Apenas membros ativos com papel operacional (`admin` ou `operator`) podem registrar recebimentos, prorrogações, perdas ou acordos.
- **Proteção de Dados Pessoais (LGPD):**
  - CPF e RG são criptografados com chave específica da carteira (`ProtectedData`).
  - CPF mascarado por padrão na interface e em logs (`***.***.123-**`), visualização completa restrita e auditada em `LoanAuditLog`.

## 3. Recursos G2 habilitados e validados no piloto
- **Alocação de Pagamento:** Prioridade estrita (multa -> juros contratuais -> juros de mora -> encargos avulsos -> principal). Rejeição imediata de pagamentos que excedam o saldo total devedor (`PAYMENT_EXCEEDS_BALANCE`).
- **Encargos Recorrentes e Dias Civis:** Apuração de mora pro rata die e blocos de 30 dias com base exclusiva em principal + juros contratuais (DT-01). Multa no dia do pagamento incide sobre o saldo remanescente pós-pagamento.
- **Prorrogação e Renegociação:** Bloqueio de prorrogação caso haja juros contratuais pendentes (`CONTRACT_INTEREST_PENDING`). Acordos segregam encargos anteriores sem capitalização de juros sobre multa/mora.
- **Cancelamento e Compensação de Principal:** Compensação de principal já recebido e restituição de valores com escolha de encargos mantidos ou devolvidos.
- **Perda e Recuperação:** Perda de saldo integral congelada e recuperação alocada pela ordem normal de amortização.
- **Estorno e Correções (DT-02):** Reversão de pagamentos via compensação de ajustes positivos preservando histórico, bloqueada se houver acordos posteriores ou contratos renegociados.

## 4. Central de Parcelas e Ficha do Cliente
- A Central de Parcelas e Ações em Lote utilizam chave de idempotência por item (`Idempotency-Key`), evitando duplicidade em reenvios.
- Ficha do cliente integra contratos confirmados, parcelas, histórico de pagamentos, anexos auditados e vínculos entre contratos de origem e acordos.

## 5. Limites e Condições de Piloto
- O piloto é restrito a dados cadastrados manualmente ou em modo de teste controlado (sem importação automática de planilhas legado).
- Notificações de WhatsApp permanecem desacopladas e desabilitadas até o Gate G6.
