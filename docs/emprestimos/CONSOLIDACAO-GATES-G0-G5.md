# Consolidação Operacional — Gates G0 a G5 e Débitos Técnicos DT-01 a DT-07

Data de consolidação: 29/10/2026.
Referência: OpenSpec `implementacao-modulo-emprestimos` — Tarefa 6.3.

---

## 1. Status Consolidado dos Gates (G0 a G5)

| Gate | Escopo | Status | Evidências Documentadas |
| :--- | :--- | :--- | :--- |
| **G0** | Fundação, infraestrutura, isolamento e autenticação | **Aprovado / Validado** | `EVIDENCIAS-IMPLEMENTACAO-G0.md`, `ENSAIO-RECUPERACAO-G0.md`, `auth.test.mjs`, `readiness.test.mjs` |
| **G1** | Clientes, simulação, cronogramas Price e contratos | **Aprovado / Validado** | `EVIDENCIAS-G1.md`, `CONTRATO-CALCULO-PRICE.md`, `calculation.test.mjs`, `civil-dates.test.mjs` |
| **G2** | Recebimentos, encargos DT-01, prorrogação, acordos e estornos DT-02 | **Aprovado / Validado** | `EVIDENCIAS-G2-PARCIAIS.md`, `charges-and-payments.test.mjs`, `extensions-and-agreements.test.mjs`, `losses-and-cancellation.test.mjs` |
| **G3** | Central de parcelas, ações em lote, ficha do cliente e piloto | **Aprovado / Validado** | `EVIDENCIAS-G3.md`, `pilot-validation.test.mjs`, `LoansInstallments.spec.tsx`, `LoansClientFile.spec.tsx` |
| **G4** | Indicadores K1–K8, relatórios e exportações seguras | **Aprovado / Validado** | `EVIDENCIAS-G4.md`, `CRITERIOS-DT03-INDICADORES.md`, `reports-and-indicators.test.mjs`, `LoansDashboard.spec.tsx`, `LoansReports.spec.tsx` |
| **G5** | Consolidação operacional, cadastro manual e recuperação | **Aprovado / Validado** | `tasks.md` (6.1, 6.2, 6.3), integridade sem importação de planilha |

---

## 2. Fechamento Consolidado dos Débitos Técnicos (DT-01 a DT-07)

### DT-01 — Base e Sequência de Encargos
- **Situação:** Fechado e implementado em `evo-loans-service/src/late-interest.ts` e `src/payments.ts`.
- **Regras:**
  - Base de cálculo composta exclusivamente por `principal + juros contratuais` devidos.
  - Vedado qualquer anatocismo: juros de mora ou multas anteriores nunca são incorporados à base de novos encargos.
  - Pagamentos no dia da aplicação de multa reduzem primeiro o saldo existente; a nova multa de 2% incide sobre o saldo remanescente pós-pagamento.

### DT-02 — Transições, Estornos e Dependências Encadeadas
- **Situação:** Fechado e implementado em `evo-loans-service/src/payment-dependencies.ts`.
- **Regras:**
  - Reversão auditada via injeção de `LoanAdjustment` compensatório, restaurando saldos sem deletar fatos históricos.
  - Bloqueio estrito se o contrato possuir novação/acordo posterior ou se já tiver sido revertido.

### DT-03 — Indicadores, Perdas e Correções Retroativas
- **Situação:** Fechado e formalizado em `docs/emprestimos/CRITERIOS-DT03-INDICADORES.md` e `evo-loans-service/src/reports.ts`.
- **Regras:**
  - Segregação de perdas em `k1Loss` (não entra no giro ativo `k1Active`).
  - Recuperações de perda tratadas pela ordem padrão de amortização.
  - Renegociações não criam desembolsos fictícios.
  - Denominador zero tratado com `null` ("N/A").

### DT-04 — Alinhamento do Plano às Decisões Tomadas
- **Situação:** Concluído documentalmente em 29/10/2026.

### DT-05 — Contrato de Cálculo Price e Arredondamento
- **Situação:** Concluído em `calculation.ts` e `CONTRATO-CALCULO-PRICE.md`. Última parcela absorve resíduos garantindo saldo zero.

### DT-06 — Autorização, Infraestrutura e Transações
- **Situação:** Concluído com isolamento de carteira `WalletMember`, chaves de idempotência, criptografia com `ProtectedData` e flags de ambiente em `server.ts`.

### DT-07 — Testes de Implementação e Evidências dos Gates
- **Situação:** Concluído com 43 testes de unidade/integração no backend e 70 testes de componentes no frontend.

---

## 3. Limites de Recursos e Diretrizes Operacionais
1. **Isolamento de Domínio:** O módulo de Empréstimos (`evo-loans-service`) opera de forma 100% autônoma e desacoplada do módulo Financeiro.
2. **Dados Legados:** Sem importação automática de planilhas. Cadastros históricos são realizados exclusivamente de forma manual com indicação explícita de estimativas.
3. **Segurança LGPD:** Mascaramento de CPF em todas as consultas e exportações; sanitização contra injeção de fórmulas CSV.
