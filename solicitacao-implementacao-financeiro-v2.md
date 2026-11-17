# Solicitação de Implementação v2: Submódulo Financeiro (`evo-finance-service`)

> **Versão:** 2.0 (revisão crítica da v1 `solicitacao-implementacao-financeiro.md`)
> **Data:** 26/10/2026
> **Escopo deste documento:** exclusivamente o módulo Financeiro. Ajustes necessários no módulo de Projetos estão em `solicitacao-ajustes-projetos.md` e **não** são tratados aqui; este documento só define o *contrato* que o Financeiro espera de outros módulos (seção 10).
> **Status:** pronto para implementação por fases (seção 14). Pontos que dependem de decisão do dono do produto estão na seção 15.

---

## 0. O que mudou em relação à v1

| # | Problema na v1 | Correção na v2 |
|---|---|---|
| 1 | DRE inconstruível: plano de contas só tinha CREDIT/DEBIT; taxa, juros e multa sem conta de destino | `ChartOfAccount.dreGroup`, `isAnalytic`, tabela `AccountMapping`, e `TransactionLine` (rateio por componente) |
| 2 | "Regime de competência" calculado só sobre `Transaction` (na prática, caixa) | Regra RN-20: DRE por competência = títulos (`Schedule`) + componentes de baixa + avulsos; visão de caixa como alternativa |
| 3 | `paidAmount` ambíguo (principal × total pago); `OVERDUE` armazenado | `paidPrincipal` definido; `OVERDUE` passa a ser derivado |
| 4 | Dois caminhos para a mesma ligação (`Transaction.scheduleId` e `SchedulePayment.transactionId`) | Apenas `SchedulePayment` liga título e movimento (N:1, permite baixa em lote) |
| 5 | Sem auditoria real, sem fechamento de período, estorno por exclusão | `AuditLog`, `PeriodClosure`, estorno por lançamento reverso |
| 6 | Recibo sem entidade; numeração em linha única com ano fixo (2026) | `Receipt` com snapshot imutável + `ReceiptSequence` por ano |
| 7 | Conciliação 1:1 e só por valor exato | `ReconciliationMatch` N:N; match por valor líquido; `ImportBatch`; dedupe com fallback |
| 8 | Recorrência sem entidade; parcelas "a cada 30 dias" | `RecurringSeries`; parcelas por mês-calendário com resto de centavos tratado |
| 9 | Papéis `admin/financial/owner` inexistentes no `evo-auth`; JWT sem método de validação definido | Permissões `finance.*` no catálogo RBAC do `evo-auth`; verificação de assinatura do JWT Doorkeeper + `/permissions/check` (seção 8) |
| 10 | Comprovantes servidos por rota estática | Download autenticado, sem `@fastify/static` para arquivos sensíveis |
| 11 | `db push`, banco compartilhado sem isolamento nem backup | `prisma migrate`, usuário de banco dedicado ao schema `finance`, backup obrigatório |
| 12 | Sem cartão de crédito, múltiplos anexos, moeda, contrato de API, testes | Incluídos (fase indicada em cada item) |
| 13 | Docs do projeto prometiam multi-moeda, assinaturas, MCP "CFO virtual", time-tracking e cobrança de reuniões; a v1 não os especificava | Classificados explicitamente por fase (seção 14). Nada é prometido sem estar aqui |

---

## 1. Contexto e referências

Ecossistema **jprOS** (`C:\Users\pi3rr3\Documents\Projetos\jprOS`): fork do `evo-crm-community`, Git Submodules, Docker Compose e Nginx. Serviços relevantes: `evo-auth-service-community` (Rails), `evo-ai-frontend-community` (React/Vite), `evo-scheduling-service` e `evo-projects-service` (Node/Fastify/Prisma).

**Sistema de referência (iLAB4 Gestão Financeira)** rodando localmente:
- URL: `http://localhost:8085/financeiro` (credenciais de teste na v1; não repetir segredos neste documento).
- Código: `C:\Users\pi3rr3\Documents\Projetos\gestao-financeira`
- Arquivos de consulta: `database/migrations/`, `LancamentoController.php`, `DashboardController.php`, `RelatorioController.php`, `PessoaController.php`, `ContaController.php`, `ConfiguracaoController.php` (todos sob `app/Http/Controllers/Financeiro/`).
- **O iLAB4 é referência de regras de negócio, não de implementação.** Nenhum código PHP/Blade/jQuery é trazido. Onde esta v2 divergir do iLAB4, a v2 prevalece.

**Diretriz mono-empresa:** o módulo atende exclusivamente a empresa dona do jprOS. Não há multi-tenant. Mesmo assim, `CompanySettings` é um registro único (singleton) e nenhuma tabela carrega `tenantId`.

---

## 2. Objetivo e abordagem

Microsserviço headless `evo-finance-service` (Node.js/TypeScript, **Fastify v5 + Prisma v6**, PostgreSQL compartilhado, schema `finance`), com frontend nativo em `evo-ai-frontend-community` (React + TypeScript + Tailwind + shadcn/ui), roteado pelo Nginx em `/api/v1/finance`.

### 2.1 Fora de escopo (declarado)
- Emissão de NF-e/NFS-e e escrituração fiscal (SPED). O recibo do módulo **não tem valor fiscal**.
- Apuração de impostos (Simples/DAS, ISS, etc.): o módulo registra impostos como *lançamentos* classificados em conta de dedução, mas não os calcula.
- Integração bancária direta (Open Finance, API de banco). Entrada de dados bancários é por OFX/CSV.
- Folha de pagamento.
- Multi-empresa.

---

## 3. Decisões de arquitetura (ADR resumido)

| ID | Decisão | Motivo |
|---|---|---|
| ADR-01 | **Dinheiro**: `Decimal(14,2)` no banco; `Decimal` (decimal.js, já usado pelo Prisma) em todo cálculo; na API, valores trafegam como **string decimal** (`"1234.50"`), nunca `number` | Evitar erro de ponto flutuante |
| ADR-02 | **Datas contábeis** (`dueDate`, `competenceDate`, `transactionDate`, `issueDate`, `paidAt`) usam `@db.Date` (sem hora). Fuso de referência: `America/Sao_Paulo`, definido em `CompanySettings.timezone`. "Hoje" é sempre calculado nesse fuso | Evitar vencimento "um dia antes" por UTC |
| ADR-03 | **Migrações com `prisma migrate`** (histórico versionado) e `prisma migrate deploy` no start do container. Proibido `db push` neste serviço | Dados financeiros exigem rastreabilidade de schema |
| ADR-04 | **Usuário de banco dedicado** `finance_app`, com permissões somente no schema `finance` | O Postgres é compartilhado com CRM/Auth; `db:schema:load` e `make clean` não podem alcançar o financeiro |
| ADR-05 | **Fonte de verdade do DRE**: ver RN-20 | Eliminar ambiguidade competência × caixa |
| ADR-06 | **Nada financeiro é apagado fisicamente.** Exclusão = soft delete com motivo; correção de movimento já conciliado ou em período fechado = **estorno** (lançamento reverso) | Integridade contábil e auditoria |
| ADR-07 | **Idempotência**: todo `POST` que cria movimento financeiro aceita o header `Idempotency-Key` | Duplo clique/retry de rede não pode duplicar lançamento |
| ADR-08 | **Concorrência**: operações compostas (baixa, estorno, transferência, recibo, conciliação) rodam em `prisma.$transaction` com bloqueio de linha (`SELECT ... FOR UPDATE`) nos registros afetados; entidades editáveis têm `version Int` (bloqueio otimista, HTTP 409 em conflito) | Duas baixas simultâneas no mesmo título |
| ADR-09 | **Moeda**: coluna `currency` (padrão `BRL`) em `BankAccount` desde o dia 1; **multi-moeda operacional é Fase 3**. Na Fase 1 e 2 o serviço rejeita contas com moeda ≠ BRL | Evitar migração de schema futura sem prometer o que não existe |
| ADR-10 | **Sem `@fastify/static` para dados sensíveis.** Comprovantes e OFX só saem por endpoint autenticado (seção 8.4). Apenas o logo da empresa pode ser público | Vazamento de documentos financeiros |

---

## 4. Escopo funcional (resumo por módulo da interface)

Legenda de fase: **F1** = primeira entrega (núcleo utilizável), **F2** = segunda entrega, **F3** = backlog planejado.

### 4.1 Dashboard (F1)
KPIs: saldo em contas (`isDashboard`), receitas e despesas **realizadas** do mês vs. mês anterior (excluindo transferências e estornos pareados), resultado de caixa do mês, a pagar hoje e próximos 7 dias, inadimplência (títulos a receber vencidos) **com faixas de aging** (1–30, 31–60, 61–90, 90+ dias). Gráficos: fluxo de caixa 6 meses e composição de despesas por conta do plano.
> O KPI "Resultado Operacional Líquido" da v1 foi renomeado para **"Resultado de Caixa do Mês"**, pois é calculado em regime de caixa. O resultado por competência aparece apenas no DRE.

### 4.2 Lançamentos de caixa (F1)
Entrada, saída e transferência. Cada lançamento é um **movimento bancário** (`Transaction`) com uma ou mais **linhas de classificação** (`TransactionLine`): principal, juros, multa, desconto, taxa e imposto. Rateio por mais de uma conta do plano/centro de custo é possível já na F1 (várias linhas de principal).

### 4.3 Contas a pagar e a receber (F1)
Títulos (`Schedule`), baixa parcial/total/em lote, estorno de baixa, parcelamento, cálculo de juros e multa, aging. Recorrência (`RecurringSeries`) na F1 com horizonte de 12 meses e job de extensão.

### 4.4 Conciliação bancária (F1: OFX; F2: CSV)
Importação OFX com `ImportBatch`, correspondência N:N, conciliação por valor líquido, criação de lançamento a partir de linha do extrato.

### 4.5 PIX e dados bancários de pessoas (F1)
Cadastro do tipo/chave PIX com validação por tipo; botão "Copiar chave PIX" em contas a pagar.

### 4.6 Recibos (F1)
Entidade `Receipt` imutável, com numeração anual atômica, cancelamento e reemissão. HTML com `@media print`; **PDF gerado no servidor na F2** (consistência entre navegadores).

### 4.7 Cadastros (F1)
Pessoas (cliente/fornecedor/colaborador), contas bancárias (incluindo `CREDIT_CARD` — fatura na F2), plano de contas, centros de custo, formas de pagamento, dados da empresa, mapeamento contábil (`AccountMapping`).

### 4.8 Relatórios (F1/F2)
- F1: extrato com saldo acumulado, posição de saldos em data retroativa, **DRE** (competência e caixa), fluxo de caixa projetado 30/60/90 dias.
- F2: livro razão analítico, ranking por cliente/fornecedor, exportação CSV/XLSX/PDF de todos os relatórios, orçamento previsto × realizado.

### 4.9 Controles (F1)
Auditoria, fechamento de período, permissões `finance.*`, anexos múltiplos.

### 4.10 Backlog (F3)
Multi-moeda operacional (câmbio, variação cambial), cobrança PIX copia-e-cola/boleto via PSP, lembretes de vencimento por WhatsApp, ferramentas MCP ("CFO virtual"), assinaturas/faturamento recorrente de clientes, cobrança de reuniões da Agenda, faturamento de horas de Projetos. Detalhe na seção 10.

---

## 5. Regras de negócio (normativas)

Cada regra tem um ID que deve aparecer nos testes automatizados (seção 12).

### 5.1 Valores e sinais
- **RN-01** Todos os valores armazenados são **não negativos**; o sentido é dado por `operation` (`CREDIT` = entra, `DEBIT` = sai).
- **RN-02** Definições para um movimento:
  - `grossAmount` = Σ(linhas `PRINCIPAL`, `INTEREST`, `FINE`) − Σ(linhas `DISCOUNT`) → valor cobrado do pagador / pago ao fornecedor.
  - `feeAmount` = Σ(linhas `FEE`) → só existe em `CREDIT` (taxa de gateway/maquininha). Em `DEBIT`, `feeAmount = 0`.
  - `netAmount = grossAmount − feeAmount` → valor que efetivamente altera o saldo bancário.
  - Verificado por `CHECK` no banco e por validação de serviço.
- **RN-03** Tarifas bancárias, IOF e juros de conta são **movimentos próprios** (`DEBIT`) classificados em conta de despesa financeira, nunca "taxa" de outro lançamento.
- **RN-04** Linhas de imposto (`TAX`) são classificadas em conta com `dreGroup = REVENUE_DEDUCTION`. O módulo registra, não calcula (seção 2.1).

### 5.2 Contas e saldos
- **RN-05** `saldo(conta, data) = openingBalance + Σ(CREDIT.net) − Σ(DEBIT.net)` para movimentos não excluídos com `openingDate ≤ transactionDate ≤ data`. Movimentos anteriores a `openingDate` são rejeitados.
- **RN-06** Conta com movimentos não pode ser excluída (somente `isActive=false`). Chaves estrangeiras de movimentos usam `onDelete: Restrict`.
- **RN-07** Lançamento só pode ser feito em conta do plano **analítica** (`isAnalytic=true`) e ativa, e cujo `type` seja compatível com a operação (`CREDIT` → conta de receita; `DEBIT` → conta de despesa). Exceção: contas com `dreGroup = NOT_IN_DRE` (ex.: aporte, retirada de sócio) aceitam ambos.

### 5.3 Transferências
- **RN-08** Transferência cria **dois** `Transaction` com o mesmo `transferGroupId` (um `DEBIT`, um `CREDIT`), `isTransfer = true`, mesmo valor líquido, na mesma `$transaction`. Constraint `UNIQUE(transferGroupId, operation)` garante par único.
- **RN-09** Editar ou estornar uma ponta aplica-se atomicamente à outra. Cada ponta é conciliada separadamente com o seu extrato.
- **RN-10** Transferências ficam fora de receitas, despesas, DRE e KPIs. Taxa de transferência (TED) é um `DEBIT` separado (RN-03).

### 5.4 Títulos e baixas
- **RN-11** `Schedule.originalAmount` é o **principal** do título. Juros, multa e desconto não são gravados no título; são **calculados e confirmados no momento da baixa** (RN-13).
- **RN-12** `paidPrincipal` = Σ(`SchedulePayment.amount`) de baixas **não estornadas**. Status armazenado (`PENDING`, `PARTIALLY_PAID`, `PAID`, `CANCELLED`) é recalculado pelo serviço: `PENDING` se `paidPrincipal = 0`; `PARTIALLY_PAID` se `0 < paidPrincipal < originalAmount`; `PAID` se `paidPrincipal ≥ originalAmount`.
  **Vencido não é status armazenado.** `isOverdue = status ∈ {PENDING, PARTIALLY_PAID} ∧ dueDate < hoje(America/Sao_Paulo)`; `daysOverdue = hoje − dueDate`. Retornados na API e usados nos filtros.
- **RN-13** Cálculo sugerido na baixa (editável pelo operador, que informa o motivo se alterar): se `paidAt > dueDate`, `multa = saldoPrincipal × CompanySettings.lateFeePercent` (padrão 2%) e `juros = saldoPrincipal × (lateInterestMonthlyPercent / 30) × diasAtraso` (padrão 1% a.m., pro rata die, juros simples). Percentuais configuráveis; zero desativa.
- **RN-14** Uma baixa gera: 1 `SchedulePayment` por título e 1 `Transaction` bancária. **Baixa em lote** (vários títulos, um pagamento) gera N `SchedulePayment` apontando para o mesmo `Transaction`; Σ(`totalPaid`) = `gross` do movimento.
- **RN-15** `SchedulePayment.amount` não pode exceder o saldo de principal do título (`originalAmount − paidPrincipal`). Excesso é rejeitado (adiantamento/crédito de cliente fica fora de escopo).
- **RN-16** **Estorno de baixa:** marca `SchedulePayment.reversedAt/reversedById/reversalReason`, cria `Transaction` reverso (operação oposta, `reversalOfId` apontando para o original, `source = REVERSAL`) e recalcula `paidPrincipal`/status. O movimento original permanece. Movimento conciliado exige desfazer o vínculo (RN-26) antes.
- **RN-17** `CANCELLED` só é permitido para título sem baixas ativas.

### 5.5 Parcelamento e recorrência
- **RN-18** **Parcelamento** de valor `V` em `n` parcelas: parcela base = `trunc(V/n, 2)`; o **resto de centavos vai para a última parcela** (R$ 100,00 em 3 → 33,33 + 33,33 + 33,34). Vencimentos: `addMonths(primeiroVencimento, i)` calculado **sempre a partir da data base** (nunca encadeado), com ajuste para o último dia do mês (31/jan → 28/fev → 31/mar). Intervalo em dias fixos é opção explícita (`intervalDays`). Todas compartilham `installmentGroupId`.
- **RN-19** **Recorrência:** `RecurringSeries` define a regra (frequência, dia, início, fim opcional). O serviço pré-gera títulos até **12 meses à frente** e um job diário estende o horizonte. Alterações têm escopo: `THIS`, `THIS_AND_FUTURE`, `ALL_UNPAID`. Títulos com baixa nunca são alterados retroativamente. Encerrar a série cancela os títulos futuros sem baixa.

### 5.6 DRE
- **RN-20** **Fonte de verdade do DRE.** Para o regime de **competência**:
  1. **Principal de títulos** — `Schedule.originalAmount` (exceto `CANCELLED`/excluídos), reconhecido em `Schedule.competenceDate`, na conta/centro do título. Vale pago ou não.
  2. **Componentes de baixa** — linhas `INTEREST`, `FINE`, `DISCOUNT`, `FEE`, `TAX` de movimentos, reconhecidas em `TransactionLine.competenceDate` (padrão: data da baixa), na conta da linha.
  3. **Movimentos avulsos** (sem título) — todas as linhas, em `TransactionLine.competenceDate`.
  4. **Excluir** linhas `PRINCIPAL` vinculadas a título (`scheduleId` preenchido), pois já entram pelo item 1 (evita dupla contagem); excluir transferências e contas `NOT_IN_DRE`; excluir estornos **pareados** com o original no mesmo período (o par se anula).
  Para o regime de **caixa**: todas as linhas de movimentos por `transactionDate`.
- **RN-21** Estrutura do DRE por `dreGroup` do plano de contas:
  `(+) GROSS_REVENUE` → `(−) REVENUE_DEDUCTION` (taxas de gateway, impostos s/ nota, descontos concedidos) → `(=) Receita Líquida` → `(−) DIRECT_COST` → `(=) Lucro Bruto` → `(−) OPERATING_EXPENSE` → `(+/−) FINANCIAL_INCOME / FINANCIAL_EXPENSE` → `(+/−) NON_OPERATING` → `(=) Resultado do Período`. Cada linha do relatório permite *drill-down* até os lançamentos/títulos de origem.
- **RN-22** A conta de destino de cada componente automático vem de `AccountMapping` (seção 6): `GATEWAY_FEE`, `BANK_FEE`, `INTEREST_INCOME`, `INTEREST_EXPENSE`, `FINE_INCOME`, `FINE_EXPENSE`, `DISCOUNT_GRANTED`, `DISCOUNT_OBTAINED`, `TAX_ON_SALES`. Sem mapeamento configurado, a operação é rejeitada com erro explicando qual chave falta.

### 5.7 Conciliação
- **RN-23** Importação OFX: o charset é lido do **cabeçalho** (`CHARSET:1252` → Windows-1252/Latin-1; `UTF-8`); sem cabeçalho, tenta UTF-8 estrito e cai para Windows-1252. O parser aceita OFX 1.x (SGML) e 2.x (XML).
- **RN-24** O arquivo é rejeitado se `BANKID`/`ACCTID` não corresponderem à conta (`BankAccount.ofxBankId/ofxAcctId`; na primeira importação o operador confirma e o sistema grava). `LEDGERBAL` é comparado ao saldo calculado na data; divergência gera **aviso** (não bloqueio).
- **RN-25** Deduplicação: `dedupeKey = FITID` quando presente e único no arquivo; caso contrário `sha256(datePosted|amount|memo|ordinalNoDia)`. `UNIQUE(accountId, dedupeKey)`. Reimportar o mesmo arquivo (`fileSha256`) é bloqueado; reimportar período sobreposto ignora entradas já existentes e informa o resumo.
- **RN-26** **Vínculo N:N** (`ReconciliationMatch`): uma entrada pode conciliar com N movimentos e um movimento com N entradas. A entrada está `RECONCILED` quando Σ(`match.amount`) = |`entry.amount`|; parcial fica `PENDING`. Desfazer vínculo é permitido (registra auditoria) enquanto o período estiver aberto.
- **RN-27** Sugestão automática compara o valor do extrato com o **`netAmount`** de movimentos e com o **valor líquido esperado** de títulos (`originalAmount − expectedFeeAmount` para recebíveis), janela `CompanySettings.matchToleranceDays` (padrão 3). Conciliar com título executa a baixa (RN-14) e o vínculo em uma única transação.
- **RN-28** Desfazer uma importação (`ImportBatch.status = UNDONE`) só é permitido se nenhuma entrada do lote estiver conciliada.

### 5.8 Recibos
- **RN-29** `Receipt` é emitido a partir de um movimento ou de uma baixa (`SchedulePayment`). Contém `snapshot` JSON imutável (empresa, pessoa, valor, valor por extenso, descrição, local e data). Alterar cadastros depois **não** altera recibos emitidos.
- **RN-30** Numeração `PREFIXO-AAAA/NNNN` via `ReceiptSequence(prefix, year)`: incremento com `UPDATE ... RETURNING` dentro da mesma transação da emissão. Virada de ano cria nova sequência automaticamente (começa em 0001). Número emitido nunca é reutilizado.
- **RN-31** Cancelar recibo exige motivo e gera nova emissão referenciando o anterior (`replacesReceiptId`); o cancelado permanece visível como `CANCELLED`.
- **RN-32** Baixa parcial emite um recibo **por baixa**.
- **RN-33** O texto do recibo deixa explícito que é "recibo simples, sem valor fiscal" (configurável em `CompanySettings.receiptFooter`).

### 5.9 Fechamento de período e auditoria
- **RN-34** `PeriodClosure` fecha o período até `periodEnd`. Em período fechado são **bloqueados**: criar, editar, excluir ou estornar movimentos e baixas com `transactionDate`/`paidAt` no período; alterar `competenceDate` para dentro do período; desfazer conciliação. Correções entram como lançamentos no período aberto (com competência original permitida **apenas** se a competência estiver em período aberto).
- **RN-35** Reabrir período exige permissão `finance.close_period`, motivo e fica no `AuditLog`.
- **RN-36** Toda escrita em entidade financeira grava `AuditLog` (quem, quando, ação, antes/depois, motivo, IP, `requestId`) na mesma transação. Leitura de dados sensíveis (PIX/dados bancários completos, anexos) também é registrada (seção 8.3).

---

## 6. Modelagem do banco (Prisma v2)

Arquivo: `evo-finance-service/prisma/schema.prisma`. Conexão com `?schema=finance` na `DATABASE_URL`, usuário `finance_app` (ADR-04).

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

// ───────────────────────────── ENUMS ─────────────────────────────

enum OperationType {
  CREDIT
  DEBIT
}

enum ScheduleType {
  PAYABLE
  RECEIVABLE
}

// OVERDUE é DERIVADO (RN-12), não armazenado.
enum ScheduleStatus {
  PENDING
  PARTIALLY_PAID
  PAID
  CANCELLED
}

enum PersonType {
  INDIVIDUAL
  LEGAL_ENTITY
}

enum AccountCategory {
  CHECKING
  SAVINGS
  INVESTMENT
  CASH
  CREDIT_CARD
}

enum PixKeyType {
  CPF
  CNPJ
  EMAIL
  PHONE
  RANDOM
}

enum BankAccountType {
  CHECKING
  SAVINGS
}

// Agrupamento do DRE (RN-21)
enum DreGroup {
  GROSS_REVENUE
  REVENUE_DEDUCTION
  DIRECT_COST
  OPERATING_EXPENSE
  FINANCIAL_INCOME
  FINANCIAL_EXPENSE
  NON_OPERATING
  NOT_IN_DRE        // transferências, aportes, retiradas de sócio
}

enum LineKind {
  PRINCIPAL
  INTEREST
  FINE
  DISCOUNT
  FEE
  TAX
}

enum TransactionSource {
  MANUAL
  SETTLEMENT     // gerado por baixa de título
  TRANSFER
  RECONCILIATION // criado a partir de linha de extrato
  REVERSAL
  RECURRING
}

enum MappingKey {
  GATEWAY_FEE
  BANK_FEE
  INTEREST_INCOME
  INTEREST_EXPENSE
  FINE_INCOME
  FINE_EXPENSE
  DISCOUNT_GRANTED
  DISCOUNT_OBTAINED
  TAX_ON_SALES
}

enum RecurrenceFrequency {
  WEEKLY
  MONTHLY
  YEARLY
}
enum RecurrenceStatus {
  ACTIVE
  PAUSED
  ENDED
}

enum EntryStatus {
  PENDING
  RECONCILED
  IGNORED
}
enum ImportFormat {
  OFX
  CSV
}
enum ImportStatus {
  ACTIVE
  UNDONE
}

enum ReceiptStatus {
  ISSUED
  CANCELLED
}

enum AttachmentOwner {
  TRANSACTION
  SCHEDULE
  PERSON
}

enum AuditAction {
  CREATE
  UPDATE
  DELETE
  REVERSE
  RECONCILE
  UNRECONCILE
  CLOSE_PERIOD
  REOPEN_PERIOD
  READ_SENSITIVE
  ISSUE_RECEIPT
  CANCEL_RECEIPT
  IMPORT
  UNDO_IMPORT
}

// ─────────────────────── CONFIGURAÇÃO (singleton) ───────────────────────

model CompanySettings {
  id                       String      @id @default("singleton")
  companyName              String
  tradeName                String?
  documentNumber           String      // CNPJ (somente dígitos)
  stateRegistry            String?
  email                    String?
  phone                    String?
  whatsapp                 String?
  zipCode                  String?
  address                  String?
  addressNumber            String?
  complement               String?
  neighborhood             String?
  city                     String?
  state                    String?
  logoStorageKey           String?
  defaultPixKeyType        PixKeyType?
  defaultPixKey            String?
  timezone                 String      @default("America/Sao_Paulo")
  baseCurrency             String      @default("BRL") @db.Char(3)
  // Recibos
  receiptPrefix            String      @default("REC")
  receiptFooter            String      @default("Recibo simples, sem valor fiscal.")
  // Encargos por atraso (RN-13)
  lateFeePercent           Decimal     @default(2.00) @db.Decimal(5, 2)
  lateInterestMonthlyPercent Decimal   @default(1.00) @db.Decimal(5, 2)
  // Conciliação (RN-27)
  matchToleranceDays       Int         @default(3)
  createdAt                DateTime    @default(now())
  updatedAt                DateTime    @updatedAt

  @@map("company_settings")
}

model ReceiptSequence {
  id         String @id @default(uuid())
  prefix     String
  year       Int
  lastNumber Int    @default(0)

  @@unique([prefix, year])
  @@map("receipt_sequences")
}

model AccountMapping {
  key               MappingKey @id
  chartOfAccountId  String
  updatedAt         DateTime   @updatedAt
  updatedById       String?

  chartOfAccount    ChartOfAccount @relation(fields: [chartOfAccountId], references: [id], onDelete: Restrict)

  @@map("account_mappings")
}

// ───────────────────────────── CADASTROS ─────────────────────────────

model BankAccount {
  id             String          @id @default(uuid())
  name           String
  category       AccountCategory @default(CHECKING)
  currency       String          @default("BRL") @db.Char(3)   // ADR-09
  bankCode       String?         // Febraban
  bankName       String?
  agency         String?
  accountNumber  String?
  ofxBankId      String?         // validação na importação (RN-24)
  ofxAcctId      String?
  openingBalance Decimal         @default(0) @db.Decimal(14, 2)
  openingDate    DateTime        @default(now()) @db.Date
  isDashboard    Boolean         @default(true)
  isActive       Boolean         @default(true)
  // Cartão de crédito (F2)
  statementClosingDay Int?
  statementDueDay     Int?
  creditLimit         Decimal?   @db.Decimal(14, 2)
  payFromAccountId    String?
  notes          String?
  version        Int             @default(1)
  createdAt      DateTime        @default(now())
  updatedAt      DateTime        @updatedAt

  payFromAccount BankAccount?    @relation("CardPayer", fields: [payFromAccountId], references: [id], onDelete: Restrict)
  cardsPaidBy    BankAccount[]   @relation("CardPayer")
  transactions   Transaction[]
  schedules      Schedule[]
  payments       SchedulePayment[]
  importBatches  ImportBatch[]
  statementEntries BankStatementEntry[]

  @@map("bank_accounts")
}

model ChartOfAccount {
  id          String         @id @default(uuid())
  parentId    String?
  code        String         @unique         // ex.: 1, 1.1, 1.1.01
  name        String
  type        OperationType                  // CREDIT = receita, DEBIT = despesa
  dreGroup    DreGroup
  isAnalytic  Boolean        @default(true)  // só analíticas recebem lançamentos (RN-07)
  isSystem    Boolean        @default(false) // contas do seed não podem ser excluídas
  isActive    Boolean        @default(true)
  createdAt   DateTime       @default(now())
  updatedAt   DateTime       @updatedAt

  parent      ChartOfAccount?  @relation("ChartHierarchy", fields: [parentId], references: [id], onDelete: Restrict)
  children    ChartOfAccount[] @relation("ChartHierarchy")
  lines       TransactionLine[]
  schedules   Schedule[]
  mappings    AccountMapping[]

  @@index([parentId])
  @@map("chart_of_accounts")
}

model CostCenter {
  id                  String   @id @default(uuid())
  parentId            String?
  code                String?  @unique
  name                String
  manager             String?
  // Vínculo opcional com evo-projects-service (seção 10). Sem FK entre serviços:
  externalProjectId   String?
  externalWorkspaceId String?
  externalProjectName String?  // snapshot para exibição se o projeto sumir
  isActive            Boolean  @default(true)
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt

  parent    CostCenter?  @relation("CostCenterHierarchy", fields: [parentId], references: [id], onDelete: Restrict)
  children  CostCenter[] @relation("CostCenterHierarchy")
  lines     TransactionLine[]
  schedules Schedule[]

  @@unique([externalProjectId])
  @@map("cost_centers")
}

model Person {
  id              String      @id @default(uuid())
  personType      PersonType  @default(LEGAL_ENTITY)
  isClient        Boolean     @default(false)
  isSupplier      Boolean     @default(false)
  isEmployee      Boolean     @default(false)
  name            String
  tradeName       String?
  documentNumber  String?     // somente dígitos; único quando preenchido (índice parcial, seção 6.1)
  stateRegistry   String?
  email           String?
  phone           String?
  mobilePhone     String?
  zipCode         String?
  address         String?
  addressNumber   String?
  complement      String?
  neighborhood    String?
  city            String?
  state           String?
  pixKeyType      PixKeyType?
  pixKey          String?
  bankCode        String?
  bankName        String?
  bankAgency      String?
  bankAccount     String?
  bankAccountType BankAccountType?
  crmContactId    String?     // vínculo opcional com contato do evo-crm (seção 10)
  notes           String?
  isActive        Boolean     @default(true)
  deletedAt       DateTime?
  version         Int         @default(1)
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt

  schedules       Schedule[]
  transactions    Transaction[]
  receipts        Receipt[]

  @@index([name])
  @@index([documentNumber])
  @@index([crmContactId])
  @@map("people")
}

model PaymentMethod {
  id        String   @id @default(uuid())
  name      String   @unique
  isActive  Boolean  @default(true)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  schedules    Schedule[]
  transactions Transaction[]
  payments     SchedulePayment[]

  @@map("payment_methods")
}

// ─────────────────────── PROGRAMAÇÃO (TÍTULOS) ───────────────────────

model RecurringSeries {
  id               String              @id @default(uuid())
  type             ScheduleType
  status           RecurrenceStatus    @default(ACTIVE)
  frequency        RecurrenceFrequency @default(MONTHLY)
  intervalCount    Int                 @default(1)
  dayOfMonth       Int?                // 1–31; ajustado ao último dia do mês
  startDate        DateTime            @db.Date
  endDate          DateTime?           @db.Date
  generatedUntil   DateTime?           @db.Date
  // Modelo dos títulos gerados
  description      String
  amount           Decimal             @db.Decimal(14, 2)
  personId         String?
  accountId        String?
  chartOfAccountId String
  costCenterId     String?
  paymentMethodId  String?
  createdById      String?
  createdAt        DateTime            @default(now())
  updatedAt        DateTime            @updatedAt

  schedules        Schedule[]

  @@map("recurring_series")
}

model Schedule {
  id                  String         @id @default(uuid())
  type                ScheduleType
  status              ScheduleStatus @default(PENDING)
  documentNumber      String?
  description         String
  personId            String?
  accountId           String?        // conta bancária prevista (opcional)
  chartOfAccountId    String
  costCenterId        String?
  paymentMethodId     String?
  issueDate           DateTime       @default(now()) @db.Date
  dueDate             DateTime       @db.Date
  competenceDate      DateTime       @db.Date
  originalAmount      Decimal        @db.Decimal(14, 2)           // principal (RN-11)
  paidPrincipal       Decimal        @default(0) @db.Decimal(14, 2) // RN-12
  expectedFeeAmount   Decimal        @default(0) @db.Decimal(14, 2) // taxa estimada de gateway (só RECEIVABLE)
  installmentGroupId  String?
  installmentNumber   Int            @default(1)
  installmentCount    Int            @default(1)
  recurringSeriesId   String?
  // Referência a origem em outro módulo (seção 10)
  sourceModule        String?        // "projects" | "scheduling" | ...
  sourceRef           String?        // id no módulo de origem
  notes               String?
  cancelledAt         DateTime?
  cancelReason        String?
  createdById         String?
  updatedById         String?
  deletedAt           DateTime?
  deletedById         String?
  version             Int            @default(1)
  createdAt           DateTime       @default(now())
  updatedAt           DateTime       @updatedAt

  person         Person?          @relation(fields: [personId], references: [id], onDelete: Restrict)
  account        BankAccount?     @relation(fields: [accountId], references: [id], onDelete: Restrict)
  chartOfAccount ChartOfAccount   @relation(fields: [chartOfAccountId], references: [id], onDelete: Restrict)
  costCenter     CostCenter?      @relation(fields: [costCenterId], references: [id], onDelete: Restrict)
  paymentMethod  PaymentMethod?   @relation(fields: [paymentMethodId], references: [id], onDelete: Restrict)
  recurringSeries RecurringSeries? @relation(fields: [recurringSeriesId], references: [id], onDelete: SetNull)
  payments       SchedulePayment[]
  lines          TransactionLine[]
  attachments    Attachment[]

  @@unique([sourceModule, sourceRef, installmentNumber])
  @@index([status, dueDate])
  @@index([type, dueDate])
  @@index([competenceDate])
  @@index([personId])
  @@index([recurringSeriesId])
  @@index([installmentGroupId])
  @@map("schedules")
}

// Baixa de título. N baixas podem apontar para o mesmo Transaction (lote, RN-14).
model SchedulePayment {
  id               String    @id @default(uuid())
  scheduleId       String
  transactionId    String
  accountId        String
  paymentMethodId  String?
  amount           Decimal   @db.Decimal(14, 2)  // principal amortizado
  interestAmount   Decimal   @default(0) @db.Decimal(14, 2)
  fineAmount       Decimal   @default(0) @db.Decimal(14, 2)
  discountAmount   Decimal   @default(0) @db.Decimal(14, 2)
  totalPaid        Decimal   @db.Decimal(14, 2)  // amount + juros + multa − desconto
  paidAt           DateTime  @db.Date
  notes            String?
  reversedAt       DateTime?
  reversedById     String?
  reversalReason   String?
  createdById      String?
  createdAt        DateTime  @default(now())

  schedule      Schedule       @relation(fields: [scheduleId], references: [id], onDelete: Restrict)
  transaction   Transaction    @relation(fields: [transactionId], references: [id], onDelete: Restrict)
  account       BankAccount    @relation(fields: [accountId], references: [id], onDelete: Restrict)
  paymentMethod PaymentMethod? @relation(fields: [paymentMethodId], references: [id], onDelete: Restrict)
  receipts      Receipt[]

  @@index([scheduleId])
  @@index([transactionId])
  @@index([paidAt])
  @@map("schedule_payments")
}

// ───────────────────────────── MOVIMENTO ─────────────────────────────

// Movimento bancário (altera saldo). A classificação contábil fica em TransactionLine.
model Transaction {
  id              String            @id @default(uuid())
  operation       OperationType
  source          TransactionSource @default(MANUAL)
  accountId       String
  personId        String?
  paymentMethodId String?
  grossAmount     Decimal           @db.Decimal(14, 2)
  feeAmount       Decimal           @default(0) @db.Decimal(14, 2)
  netAmount       Decimal           @db.Decimal(14, 2)   // CHECK: net = gross − fee (RN-02)
  transactionDate DateTime          @db.Date
  documentNumber  String?
  description     String
  notes           String?
  isTransfer      Boolean           @default(false)
  transferGroupId String?           // UNIQUE(transferGroupId, operation) — RN-08
  reversalOfId    String?           @unique              // estorno aponta para o original
  idempotencyKey  String?           @unique
  createdById     String?
  updatedById     String?
  deletedAt       DateTime?
  deletedById     String?
  deleteReason    String?
  version         Int               @default(1)
  createdAt       DateTime          @default(now())
  updatedAt       DateTime          @updatedAt

  account       BankAccount     @relation(fields: [accountId], references: [id], onDelete: Restrict)
  person        Person?         @relation(fields: [personId], references: [id], onDelete: Restrict)
  paymentMethod PaymentMethod?  @relation(fields: [paymentMethodId], references: [id], onDelete: Restrict)
  reversalOf    Transaction?    @relation("Reversal", fields: [reversalOfId], references: [id], onDelete: Restrict)
  reversedBy    Transaction?    @relation("Reversal")
  lines         TransactionLine[]
  payments      SchedulePayment[]
  matches       ReconciliationMatch[]
  attachments   Attachment[]
  receipts      Receipt[]

  @@unique([transferGroupId, operation])
  @@index([accountId, transactionDate])
  @@index([personId])
  @@index([transferGroupId])
  @@map("transactions")
}

// Classificação do movimento (base do DRE, RN-20/21). Valor sempre positivo (RN-01).
model TransactionLine {
  id               String    @id @default(uuid())
  transactionId    String
  kind             LineKind
  chartOfAccountId String
  costCenterId     String?
  scheduleId       String?   // preenchido nas linhas PRINCIPAL de baixa (RN-20 item 4)
  amount           Decimal   @db.Decimal(14, 2)
  competenceDate   DateTime  @db.Date
  description      String?
  createdAt        DateTime  @default(now())

  transaction    Transaction    @relation(fields: [transactionId], references: [id], onDelete: Restrict)
  chartOfAccount ChartOfAccount @relation(fields: [chartOfAccountId], references: [id], onDelete: Restrict)
  costCenter     CostCenter?    @relation(fields: [costCenterId], references: [id], onDelete: Restrict)
  schedule       Schedule?      @relation(fields: [scheduleId], references: [id], onDelete: Restrict)

  @@index([transactionId])
  @@index([chartOfAccountId, competenceDate])
  @@index([costCenterId, competenceDate])
  @@index([scheduleId])
  @@map("transaction_lines")
}

// ─────────────────────────── CONCILIAÇÃO ───────────────────────────

model ImportBatch {
  id               String       @id @default(uuid())
  accountId        String
  format           ImportFormat @default(OFX)
  fileName         String
  fileSha256       String
  storageKey       String
  ofxBankId        String?
  ofxAcctId        String?
  periodStart      DateTime?    @db.Date
  periodEnd        DateTime?    @db.Date
  ledgerBalance    Decimal?     @db.Decimal(14, 2)
  ledgerBalanceDate DateTime?   @db.Date
  entryCount       Int          @default(0)
  newEntryCount    Int          @default(0)
  status           ImportStatus @default(ACTIVE)
  importedById     String?
  importedAt       DateTime     @default(now())

  account  BankAccount          @relation(fields: [accountId], references: [id], onDelete: Restrict)
  entries  BankStatementEntry[]

  @@unique([accountId, fileSha256])
  @@map("import_batches")
}

model BankStatementEntry {
  id           String      @id @default(uuid())
  batchId      String
  accountId    String
  fitId        String?
  dedupeKey    String      // RN-25
  datePosted   DateTime    @db.Date
  amount       Decimal     @db.Decimal(14, 2)  // COM SINAL: positivo = crédito, negativo = débito
  memo         String
  status       EntryStatus @default(PENDING)
  ignoredReason String?
  createdAt    DateTime    @default(now())

  batch    ImportBatch @relation(fields: [batchId], references: [id], onDelete: Restrict)
  account  BankAccount @relation(fields: [accountId], references: [id], onDelete: Restrict)
  matches  ReconciliationMatch[]

  @@unique([accountId, dedupeKey])
  @@index([accountId, datePosted])
  @@index([status])
  @@map("bank_statement_entries")
}

model ReconciliationMatch {
  id             String   @id @default(uuid())
  entryId        String
  transactionId  String
  amount         Decimal  @db.Decimal(14, 2)  // parcela do vínculo (positiva)
  createdById    String?
  createdAt      DateTime @default(now())
  undoneAt       DateTime?
  undoneById     String?

  entry        BankStatementEntry @relation(fields: [entryId], references: [id], onDelete: Restrict)
  transaction  Transaction        @relation(fields: [transactionId], references: [id], onDelete: Restrict)

  @@index([entryId])
  @@index([transactionId])
  @@map("reconciliation_matches")
}

// ───────────────────── RECIBOS, ANEXOS, AUDITORIA, CONTROLE ─────────────────────

model Receipt {
  id                String        @id @default(uuid())
  prefix            String
  year              Int
  sequence          Int
  number            String        @unique   // ex.: REC-2026/0001
  status            ReceiptStatus @default(ISSUED)
  transactionId     String?
  schedulePaymentId String?
  personId          String?
  amount            Decimal       @db.Decimal(14, 2)
  issuedAt          DateTime      @default(now())
  issuedById        String?
  snapshot          Json          // empresa, pessoa, valor, extenso, descrição, local/data (RN-29)
  cancelledAt       DateTime?
  cancelledById     String?
  cancelReason      String?
  replacesReceiptId String?

  transaction     Transaction?     @relation(fields: [transactionId], references: [id], onDelete: Restrict)
  schedulePayment SchedulePayment? @relation(fields: [schedulePaymentId], references: [id], onDelete: Restrict)
  person          Person?          @relation(fields: [personId], references: [id], onDelete: Restrict)
  replaces        Receipt?         @relation("ReceiptReplacement", fields: [replacesReceiptId], references: [id])
  replacedBy      Receipt[]        @relation("ReceiptReplacement")

  @@unique([prefix, year, sequence])
  @@index([transactionId])
  @@index([schedulePaymentId])
  @@map("receipts")
}

model Attachment {
  id            String          @id @default(uuid())
  ownerType     AttachmentOwner
  transactionId String?
  scheduleId    String?
  personId      String?
  storageKey    String          @unique  // nome interno (UUID), nunca o nome original
  originalName  String
  mimeType      String
  sizeBytes     Int
  sha256        String
  uploadedById  String?
  uploadedAt    DateTime        @default(now())
  deletedAt     DateTime?

  transaction Transaction? @relation(fields: [transactionId], references: [id], onDelete: Restrict)
  schedule    Schedule?    @relation(fields: [scheduleId], references: [id], onDelete: Restrict)

  @@index([transactionId])
  @@index([scheduleId])
  @@map("attachments")
}

model AuditLog {
  id         String      @id @default(uuid())
  entity     String      // "Transaction", "Schedule", "Receipt"...
  entityId   String
  action     AuditAction
  actorId    String
  actorName  String
  reason     String?
  before     Json?
  after      Json?
  ip         String?
  requestId  String?
  createdAt  DateTime    @default(now())

  @@index([entity, entityId])
  @@index([actorId, createdAt])
  @@index([createdAt])
  @@map("audit_logs")
}

model PeriodClosure {
  id           String    @id @default(uuid())
  periodEnd    DateTime  @db.Date    // fechado até esta data (inclusive)
  closedAt     DateTime  @default(now())
  closedById   String
  reopenedAt   DateTime?
  reopenedById String?
  reopenReason String?

  @@index([periodEnd])
  @@map("period_closures")
}

model IdempotencyKey {
  key          String   @id
  actorId      String
  route        String
  requestHash  String
  responseCode Int
  responseBody Json
  createdAt    DateTime @default(now())
  expiresAt    DateTime

  @@index([expiresAt])
  @@map("idempotency_keys")
}
```

### 6.1 Constraints que o Prisma não expressa (migração SQL manual, obrigatória)

```sql
-- RN-02: coerência entre bruto, taxa e líquido
ALTER TABLE finance.transactions
  ADD CONSTRAINT ck_tx_amounts
  CHECK (gross_amount >= 0 AND fee_amount >= 0 AND net_amount = gross_amount - fee_amount);

-- RN-02: taxa só em CREDIT
ALTER TABLE finance.transactions
  ADD CONSTRAINT ck_tx_fee_credit_only
  CHECK (operation = 'CREDIT' OR fee_amount = 0);

-- RN-01: valores não negativos
ALTER TABLE finance.transaction_lines ADD CONSTRAINT ck_line_amount CHECK (amount > 0);
ALTER TABLE finance.schedules
  ADD CONSTRAINT ck_sched_amounts
  CHECK (original_amount > 0 AND paid_principal >= 0 AND paid_principal <= original_amount);
ALTER TABLE finance.schedule_payments
  ADD CONSTRAINT ck_pay_amounts CHECK (amount > 0 AND total_paid >= 0);

-- Pessoa: documento único entre ativos (quando informado)
CREATE UNIQUE INDEX uq_people_document_active
  ON finance.people (document_number)
  WHERE document_number IS NOT NULL AND deleted_at IS NULL;

-- Consultas de saldo/DRE ignoram excluídos com índice parcial
CREATE INDEX ix_tx_active_account_date
  ON finance.transactions (account_id, transaction_date)
  WHERE deleted_at IS NULL;
CREATE INDEX ix_sched_open_due
  ON finance.schedules (due_date)
  WHERE deleted_at IS NULL AND status IN ('PENDING','PARTIALLY_PAID');

-- Sequência de recibo e fechamento: sem duplicidade
-- (já cobertos por UNIQUE do Prisma)

-- Isolamento de acesso (ADR-04)
CREATE ROLE finance_app LOGIN PASSWORD :'FINANCE_DB_PASSWORD';
GRANT USAGE, CREATE ON SCHEMA finance TO finance_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA finance TO finance_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA finance GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO finance_app;
REVOKE ALL ON SCHEMA public FROM finance_app;
-- AuditLog: append-only
REVOKE UPDATE, DELETE ON finance.audit_logs FROM finance_app;
```

> Regras que dependem de validação em serviço (não expressáveis em `CHECK` simples): compatibilidade `ChartOfAccount.type` × `operation` (RN-07), soma das linhas = bruto (RN-02), `isAnalytic`, fechamento de período (RN-34). Devem ter teste automatizado.

### 6.2 Seed obrigatório
- `CompanySettings` singleton (CNPJ placeholder editável).
- **Plano de contas padrão** com `dreGroup` e `isAnalytic` preenchidos, incluindo as contas de sistema (`isSystem=true`) usadas pelo `AccountMapping`: taxas de gateway, tarifas bancárias, juros/multa recebidos e pagos, descontos concedidos/obtidos, impostos sobre vendas.
- `AccountMapping` completo apontando para essas contas (RN-22).
- Formas de pagamento: PIX, Boleto, Cartão de Crédito, Cartão de Débito, TED/Transferência, Dinheiro.
- O seed é **idempotente** (`upsert`) e **nunca** apaga dados.

---

## 7. API REST (contrato)

Prefixo: `/api/v1/finance`. JSON em UTF-8.

### 7.1 Convenções
- **Valores monetários**: string decimal (`"1234.50"`). **Datas contábeis**: `YYYY-MM-DD`. **Instantes** (`createdAt`...): ISO-8601 UTC.
- **Paginação**: `?page=1&pageSize=50` (máx. 200), resposta `{ data: [...], meta: { page, pageSize, total } }`. Ordenação `?sort=field:asc`.
- **Erros**: `{ error: { code, message, details?, requestId } }` com códigos estáveis (`PERIOD_CLOSED`, `VERSION_CONFLICT`, `ACCOUNT_NOT_ANALYTIC`, `MAPPING_MISSING`, `OVERPAYMENT`, `DUPLICATE_IMPORT`, ...). HTTP: 400 validação, 401, 403, 404, 409 (conflito/versão/idempotência), 422 (regra de negócio).
- **Idempotência**: header `Idempotency-Key` em `POST` de movimento, baixa, transferência, recibo, importação (ADR-07). Mesma chave + mesmo corpo → mesma resposta; mesma chave + corpo diferente → 422.
- **Versionamento otimista**: `PATCH/PUT` exigem `version`; divergência → 409 `VERSION_CONFLICT`.
- **OpenAPI** gerado a partir dos schemas `zod` (`@fastify/swagger` + `fastify-type-provider-zod`), publicado em `/api/v1/finance/docs` apenas em ambiente não produtivo.
- Validação de entrada com `zod` em todas as rotas; nenhum campo desconhecido é aceito.

### 7.2 Recursos principais
| Recurso | Endpoints | Permissão |
|---|---|---|
| Saúde | `GET /health` (sem auth; sem dados) | — |
| Dashboard | `GET /dashboard?month=YYYY-MM` | `finance.read` |
| Lançamentos | `GET/POST /transactions`, `GET/PATCH /transactions/:id`, `POST /transactions/:id/reverse`, `DELETE /transactions/:id` (soft, com `reason`) | `read` / `write` |
| Transferências | `POST /transfers`, `POST /transfers/:groupId/reverse` | `write` |
| Títulos | `GET/POST /schedules`, `GET/PATCH /schedules/:id`, `POST /schedules/:id/cancel`, `POST /schedules/installments` (parcelamento), `GET /schedules/aging` | `read` / `write` |
| Baixas | `POST /settlements` (um ou N títulos), `POST /settlements/:paymentId/reverse`, `GET /settlements/preview` (calcula juros/multa, RN-13) | `finance.settle` |
| Recorrência | `GET/POST /recurring-series`, `PATCH /recurring-series/:id` (`scope`), `POST /recurring-series/:id/end` | `write` |
| Conciliação | `POST /reconciliation/imports` (multipart), `GET /reconciliation/imports`, `POST /reconciliation/imports/:id/undo`, `GET /reconciliation/entries`, `GET /reconciliation/entries/:id/suggestions`, `POST /reconciliation/matches`, `DELETE /reconciliation/matches/:id`, `POST /reconciliation/entries/:id/ignore`, `POST /reconciliation/entries/:id/create-transaction` | `finance.reconcile` |
| Recibos | `POST /receipts`, `GET /receipts/:id`, `GET /receipts/:id/pdf` (F2), `POST /receipts/:id/cancel` | `finance.settle` |
| Cadastros | `/people`, `/bank-accounts`, `/chart-of-accounts`, `/cost-centers`, `/payment-methods`, `/account-mappings` | `read` / `finance.manage` |
| Empresa | `GET/PUT /company-settings` | `finance.manage` |
| Relatórios | `GET /reports/statement`, `/reports/balances?date=`, `/reports/dre?from=&to=&basis=competence\|cash`, `/reports/cashflow-projection?days=30\|60\|90`, `/reports/ledger` (F2), `/reports/by-party` (F2); sufixo `.csv`/`.xlsx` (F2) | `read` |
| Anexos | `POST /attachments` (multipart), `GET /attachments/:id/download`, `DELETE /attachments/:id` | `write` |
| Período | `GET /period-closures`, `POST /period-closures`, `POST /period-closures/:id/reopen` | `finance.close_period` |
| Auditoria | `GET /audit-logs?entity=&entityId=` | `finance.audit` |

### 7.3 Integração com outros módulos (entrada)
`POST /integrations/receivables` — cria título a receber originado em outro módulo (seção 10), autenticado por token de serviço (não por usuário), idempotente por `(sourceModule, sourceRef)`.

---

## 8. Segurança, acesso e privacidade

### 8.1 Autenticação (verificado no código do `evo-auth`)
O `evo-auth` assina os tokens de acesso com Doorkeeper-JWT (`config/initializers/doorkeeper.rb`): segredo `DOORKEEPER_JWT_SECRET_KEY`, algoritmo `DOORKEEPER_JWT_ALGORITHM` (padrão `hs256`). O payload emitido contém `iss`, `aud`, `jti`, `iat`, `exp`, `sub` (id do usuário), `email`, `name`, `type`, `role`. Tokens sem usuário (sem `sub`) também podem ser emitidos. O `evo-finance-service` deve:
1. **Verificar assinatura, expiração e emissor** (`jose`, algoritmo fixado em configuração, `iss` = `DOORKEEPER_JWT_ISS`). **Nunca decodificar sem verificar.**
2. **Exigir `sub`**: token sem `sub` (sem usuário) é rejeitado com 401.
3. Rejeitar tokens ausentes, inválidos ou expirados com 401. **Sem fallback de desenvolvimento por header** (`x-user-id`) em nenhum ambiente.
4. Receber o segredo por variável de ambiente (mesmo valor do auth), nunca em código.
5. Usar `sub`, `email` e `name` do token para `createdById`/auditoria. O campo `role` do token **não** é fonte de autorização do Financeiro; vale o catálogo de permissões (8.2).

### 8.2 Autorização (RBAC)
O `evo-auth` já possui catálogo central de permissões (`ResourceActionsConfig`, formato `recurso.ação`) e o endpoint `GET /api/v1/permissions/check?permission_key=` (cache de 60 s). Portanto:
- **Pré-requisito no `evo-auth-service-community`:** adicionar o recurso `finance` ao `ResourceActionsConfig` com as ações abaixo, incluí-las no seed de RBAC e associar ao papel `account_owner` (e a um novo papel opcional `finance_operator`):

| Permissão | Efeito |
|---|---|
| `finance.read` | Ver dashboard, lançamentos, títulos, relatórios |
| `finance.write` | Criar/editar lançamentos, títulos, cadastros operacionais |
| `finance.settle` | Baixar títulos, estornar baixas, emitir recibos |
| `finance.reconcile` | Importar OFX e conciliar |
| `finance.manage` | Plano de contas, mapeamento contábil, dados da empresa, contas bancárias |
| `finance.close_period` | Fechar e reabrir períodos |
| `finance.audit` | Consultar auditoria |
| `finance.pii` | Ver CPF/CNPJ, PIX e dados bancários **completos** (sem a permissão, aparecem mascarados) |

- O serviço financeiro consulta `permissions/check` (ou lê `GET /permissions` uma vez por requisição) com **cache local de 60 s** por `(userId, permissão)`.
- **A checagem é sempre no backend.** Ocultar o menu no frontend é só conveniência. Super admin não ignora a checagem de `finance.*` sem estar explicitamente no catálogo.

### 8.3 Dados pessoais e sensíveis (LGPD)
- CPF/CNPJ, chave PIX e dados bancários: **mascarados** na listagem (`***.456.789-**`); valor completo só com `finance.pii`, e cada leitura completa gera `AuditLog` `READ_SENSITIVE`.
- Logs da aplicação **não** podem conter documento, chave PIX, conta, memo de extrato ou conteúdo de anexos (redação por *serializer* do logger).
- Retenção: comprovantes e OFX ficam retidos por no mínimo 5 anos; exclusão de pessoa é *soft delete* (obrigação fiscal), com anonimização possível somente por rotina administrativa documentada.
- Backup criptografado (seção 9.3).

### 8.4 Upload e download de arquivos
- Limites: 25 MB (OFX/anexos), tipos permitidos por *allowlist* de MIME **e** verificação por assinatura de bytes (`file-type`): `pdf, png, jpg, ofx, csv, xlsx`.
- Armazenamento com `storageKey` UUID, fora de qualquer diretório servido estaticamente; o nome original fica só no banco e é sanitizado ao baixar (`Content-Disposition`).
- Download exclusivamente por `GET /attachments/:id/download` (autenticado + permissão + registro de auditoria). Proteção contra *path traversal* por construção (chave opaca, sem caminho do cliente).
- Logo da empresa: único arquivo possível de servir em rota pública (recibo impresso/PDF).
- Antivírus (ClamAV) é recomendado na F2; na F1, a *allowlist* e o limite de tamanho são obrigatórios.

### 8.5 Outros controles
- **CORS**: lista explícita de origens (`CORS_ORIGINS`), nunca `*` com `Authorization`. 
- **Rate limit** (`@fastify/rate-limit`): geral por usuário e restrito em importação/uploads.
- **Headers de segurança** (`@fastify/helmet`); `trustProxy` configurado para obter o IP real atrás do Nginx.
- Mensagens de erro não expõem stack, SQL ou caminhos.
- Segredos só por variáveis de ambiente (no Swarm, via *secrets*).

---

## 9. Infraestrutura

### 9.1 Docker Compose (`docker-compose.yml`)
```yaml
  # ---------------------------------------------------------------------------
  # Finance Service (Node.js / Fastify / Prisma) — Port 3004 (host 3014)
  # ---------------------------------------------------------------------------
  evo-finance:
    build:
      context: ./evo-finance-service
      dockerfile: Dockerfile
    restart: unless-stopped
    ports:
      - "3014:3004"
    volumes:
      - finance_storage:/app/storage        # volume nomeado (não bind-mount de pasta do repositório)
    environment:
      PORT: "3004"
      HOST: 0.0.0.0
      NODE_ENV: ${NODE_ENV:-development}
      DATABASE_URL: postgresql://finance_app:${FINANCE_DB_PASSWORD}@postgres:5432/${POSTGRES_DATABASE:-evo_community}?schema=finance
      DOORKEEPER_JWT_SECRET_KEY: ${DOORKEEPER_JWT_SECRET_KEY}
      DOORKEEPER_JWT_ALGORITHM: ${DOORKEEPER_JWT_ALGORITHM:-hs256}
      DOORKEEPER_JWT_ISS: ${DOORKEEPER_JWT_ISS:-evo-auth-service}
      AUTH_BASE_URL: http://evo-auth:3001
      CORS_ORIGINS: ${FINANCE_CORS_ORIGINS:-http://localhost:5173}
      STORAGE_DIR: /app/storage
      MAX_UPLOAD_MB: "25"
      SERVICE_TOKEN: ${FINANCE_SERVICE_TOKEN}   # integrações entre serviços (seção 10)
    depends_on:
      postgres:
        condition: service_healthy
      evo-auth:
        condition: service_started
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:3004/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 20s
    # Ao iniciar: `prisma migrate deploy` (ADR-03) e só então o servidor.

volumes:
  finance_storage:
```
> Observações: (1) o healthcheck usa Node (imagens `node:alpine` não trazem `curl`); (2) o volume é nomeado e **excluído de `make clean`** (ajustar o Makefile para não remover `finance_storage` e documentar); (3) mesmo padrão deve ser aplicado em `docker-compose.prod.yml` e `docker-compose.swarm.yaml`, com `secrets` no Swarm.

### 9.2 Nginx (`nginx/default.conf.template`)
```nginx
    set $finance_service http://${FINANCE_UPSTREAM};   # default evo-finance:3004

    location ~ ^/api/v1/finance {
        client_max_body_size 25M;
        proxy_pass $finance_service$request_uri;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;   # não fixar "https"
        proxy_set_header Authorization $http_authorization;
        proxy_read_timeout 60s;
    }
```
Adicionar `FINANCE_UPSTREAM` ao `nginx/README.md`. O endpoint `/integrations/*` **não** é exposto externamente (bloquear no Nginx; acessível só pela rede interna do Docker).

### 9.3 Backup e continuidade (obrigatório antes de uso com dados reais)
- `pg_dump -n finance` diário, criptografado, com retenção mínima de 30 dias e cópia fora da máquina; cópia diária do volume `finance_storage`.
- **Teste de restauração** documentado e executado antes do go-live.
- Sem backup validado, o módulo não vai para uso real (critério de aceite da F1).
- `make clean` e `db:schema:load` do CRM **não** podem alcançar o schema `finance` (ADR-04 + volume nomeado fora do `clean`).

### 9.4 Observabilidade
Logs JSON com `requestId`; métricas Prometheus (`/metrics` interno); alertas sugeridos: falha de `migrate deploy`, job de recorrência/overdue sem execução em 24 h, divergência `LEDGERBAL`.

---

## 10. Contratos de integração (lado do Financeiro)

Este módulo **não depende** dos outros para funcionar; integrações são opcionais e desacopladas (sem FK entre serviços).

| Origem | O que o Financeiro oferece/espera | Fase |
|---|---|---|
| **Projetos** → Financeiro | Centro de custo com `externalProjectId/externalWorkspaceId/externalProjectName`. Opcional: Projetos chama `POST /integrations/receivables` para gerar título a receber a partir de horas faturáveis ou entrega aprovada (idempotente por `sourceModule="projects"`, `sourceRef=<id>`). **As alterações necessárias no serviço de Projetos estão no documento `solicitacao-ajustes-projetos.md`.** | F2 |
| **Agenda** → Financeiro | Título a receber por reserva paga (`sourceModule="scheduling"`, `sourceRef=<bookingId>`). Sem acoplamento: se a Agenda não chamar, nada muda. | F3 |
| **CRM** ↔ Financeiro | `Person.crmContactId` opcional. Na F2, tela "importar do CRM" cria `Person` a partir de contato. O CRM **continua** dono dos dados de contato; o Financeiro mantém o que é financeiro (documento, PIX, banco). | F2 |
| **IA/MCP** ("CFO virtual") | Servidor MCP somente-leitura com autenticação própria: `get_cash_position`, `list_overdue_receivables`, `get_projected_balance`, `get_dre_summary`. **Nenhuma ferramenta de escrita na primeira versão.** Mesmas permissões `finance.*` do usuário em nome de quem o agente atua. | F3 |
| **WhatsApp** (lembretes) | Eventos `schedule.due_soon` / `schedule.overdue` publicados no RabbitMQ; um consumidor no bot-runtime envia a mensagem. | F3 |

Regras comuns: autenticação serviço-a-serviço por `SERVICE_TOKEN` (header), rede interna apenas; idempotência obrigatória; falha na integração nunca bloqueia operação financeira local.

---

## 11. Interface (`evo-ai-frontend-community`)

Padrão do jprOS: menu lateral principal + drawer secundário retrátil (como Agenda e Projetos).

- **Menu**: item `Financeiro`, visível somente com `finance.read` (checagem real no backend, RN/§8.2).
- **`FinanceSidebarDrawer.tsx`** com as seções: Visão Geral (Dashboard) · Movimentação (Lançamentos, Conciliação) · Contas Futuras (A pagar, A receber, Recorrências) · Cadastros (Pessoas, Contas bancárias) · Relatórios (DRE, Fluxo projetado, Extrato, Razão e Análise por parte — F2) · Configurações (Empresa, Plano de contas, Centros de custo, Formas de pagamento, **Mapeamento contábil**, **Fechamento de período**, Auditoria).
- **Regras de UI**
  - Valores em `string` na API; formatação `pt-BR` no cliente; nunca somar com `Number` (usar `decimal.js` ou `big.js`).
  - Botões de ação com bloqueio durante o envio e envio de `Idempotency-Key` gerada por tentativa.
  - Em conflito `409 VERSION_CONFLICT`, mostrar "registro alterado por outra pessoa" e recarregar.
  - Dados sensíveis mascarados; botão "Revelar" só aparece com `finance.pii` e dispara o log.
  - Período fechado: campos de data e ações exibem o bloqueio e o motivo (`PERIOD_CLOSED`).
  - Conciliação em 2 colunas: extrato à esquerda; à direita, sugestões (com base em valor **líquido**), busca manual e "Novo lançamento" pré-preenchido; permite vincular 1 entrada a N itens e N entradas a 1 item.
  - Aging do contas a receber com faixas e filtros; "vencido" sempre derivado (RN-12).
  - Recibo: modal A4 com `@media print` na F1; PDF no servidor na F2.
- Bibliotecas de gráfico leves e já presentes no frontend; evitar nova dependência pesada sem necessidade.

---

## 12. Estratégia de testes e critérios de aceite técnicos

**Testes automatizados obrigatórios (Vitest + banco real em container):**
1. **Aritmética e arredondamento** (RN-02, RN-13, RN-18): parcelamento com resto de centavos; 31/jan→28/fev→31/mar; juros pro rata.
2. **Baixa e estorno** (RN-12, 14, 15, 16): baixa parcial → parcial → total; estorno restaura status; baixa em lote; excesso rejeitado; **duas baixas concorrentes** no mesmo título (uma deve falhar).
3. **Transferência** (RN-08–10): par atômico, falha parcial reverte tudo, `UNIQUE(transferGroupId, operation)`.
4. **DRE golden test** (RN-20/21): conjunto fixo de títulos/movimentos com resultado esperado calculado à mão — competência e caixa; sem dupla contagem; estorno pareado se anula; transferência fora.
5. **Conciliação** (RN-23–28): OFX 1.x/SGML Windows-1252 e OFX 2.x UTF-8 (arquivos de exemplo versionados); reimportação; `FITID` repetido; N:N; desfazer lote.
6. **Recibo** (RN-29–32): numeração concorrente sem buracos/duplicidade (50 emissões paralelas); virada de ano; snapshot imutável.
7. **Período fechado** (RN-34/35) e **auditoria** (RN-36): cada escrita gera exatamente 1 registro de auditoria.
8. **Segurança**: JWT inválido/expirado/assinatura trocada → 401; sem permissão → 403; mascaramento de PII; tentativa de download de anexo alheio/`../`.
9. **Idempotência**: repetir `POST` com a mesma chave não duplica.
10. **Fuso**: vencimento em `2026-11-01` não vira `2026-10-31` em nenhum fuso.

**Critérios de aceite do fluxo ponta a ponta (da v1, ampliado):** Lançamento → saldo bancário → título → baixa parcial → baixa final → recibo → estorno → DRE (competência) conferido contra o golden test → conciliação OFX → fechamento do período → tentativa de edição bloqueada.

**Não funcionais:** listagens com 50 mil movimentos respondem em < 500 ms (p95) com os índices definidos; DRE de 12 meses em < 2 s; `migrate deploy` repetível; build reproduzível.

---

## 13. Diretrizes de execução

1. **Backend (`evo-finance-service`)**: Fastify v5, TypeScript estrito, Prisma v6, `zod`, `@fastify/cors`, `@fastify/multipart`, `@fastify/helmet`, `@fastify/rate-limit`, `jose`, `decimal.js`, `file-type`. **Sem `@fastify/static`** para dados sensíveis. Estrutura em camadas: `routes` → `services` (regras RN-xx) → `repositories` (Prisma). Regras de negócio **somente** em `services`, cada função citando os RN que implementa.
2. **Banco**: migração inicial gerada com `prisma migrate dev` + migração SQL manual da seção 6.1; seed idempotente (6.2).
3. **`evo-auth-service-community`**: adicionar recurso `finance` (seção 8.2) antes do início do frontend.
4. **Infra**: seções 9.1–9.3 (Compose, Nginx, Swarm/prod, backup).
5. **Frontend**: `FinanceSidebarDrawer.tsx`, rotas protegidas, páginas conforme fase.
6. **Processo**: plano por fase com confirmação a cada etapa, diffs pequenos, seguindo os padrões do `evo-scheduling-service`.

---

## 14. Plano de entrega por fases

| Fase | Conteúdo | Pronto quando |
|---|---|---|
| **F0 — Fundações** | Auth/RBAC `finance.*` no `evo-auth`; esqueleto do serviço (JWT verificado, erros, idempotência, auditoria, `requestId`); schema + migração SQL; seed; Compose/Nginx; backup e restauração testados | Login real acessa `/health` e uma rota protegida; 401/403 testados; restauração de backup validada |
| **F1 — Núcleo** | Cadastros; contas e saldos; lançamentos com linhas; transferências; títulos (parcelamento, recorrência, baixa, estorno, aging); recibos; conciliação OFX; DRE (competência/caixa); fluxo projetado; dashboard; fechamento de período; anexos | Todos os testes da seção 12 verdes; fluxo ponta a ponta aprovado; DRE confere com o golden test |
| **F2 — Consolidação** | CSV de extrato; PDF de recibo no servidor; cartão de crédito (fatura); rateio de título (várias contas/centros por título); razão analítico; análise por cliente/fornecedor; exportações CSV/XLSX/PDF; orçamento previsto × realizado; ClamAV; integração com Projetos e CRM | Critérios por item aprovados |
| **F3 — Expansão** | Multi-moeda operacional (câmbio, variação cambial); assinaturas/faturamento recorrente de clientes; cobrança PIX/boleto via PSP; lembretes WhatsApp; MCP "CFO virtual" somente leitura; integração com Agenda | Decisão do produto e especificação própria por item |

---

## 15. Decisões em aberto (precisam do dono do produto)

1. **Escopo fiscal**: o jprOS vai emitir NFS-e? Se sim, é um módulo próprio (fora desta spec).
2. **Regime tributário** da empresa (Simples/Presumido): define as contas de imposto no plano padrão.
3. **Dia útil**: vencimento em fim de semana/feriado é prorrogado automaticamente? (padrão desta spec: não).
4. **Juros e multa**: confirmar 2% + 1% a.m. como padrão, e se juros são simples (spec) ou compostos.
5. **Rateio de título na F1** em vez de F2? Aumenta a complexidade das baixas parciais.
6. **Multi-moeda**: existe caso real de receber/pagar em USD/EUR em 2026? Se não, adiar sem custo.
7. **Dados do iLAB4**: há dados reais a migrar? Se sim, adicionar uma fase de importação com conferência de saldos.
8. **Quem fecha o mês**: definir o responsável e a rotina (sugestão: até o 5º dia útil).
9. **Retenção/anonimização** de dados pessoais: confirmar prazos com a assessoria contábil/jurídica.

---

## 16. Rastreabilidade com a v1

Itens da v1 mantidos sem alteração conceitual: mono-empresa, bruto/taxa/líquido, transferência com par atômico, baixas parciais com histórico, parcelamento/recorrência, conciliação OFX com `FITID`, PIX nos cadastros, recibo com numeração anual, árvore de plano de contas e centros de custo, drawer lateral e seções do menu.
Itens da v1 **alterados**: ver seção 0.
Itens que o documento principal do projeto citava mas a v1 não especificava: tratados na seção 14 (F2/F3) e 10.
