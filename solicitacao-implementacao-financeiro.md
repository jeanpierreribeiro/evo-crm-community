# Solicitação de Implementação: Submódulo de Gestão Financeira Completa (jprOS + Engine Financeira)

Olá! Estou trabalhando no ecossistema **jprOS** (`C:\Users\pi3rr3\Documents\Projetos\jprOS`), nosso fork customizado do `evo-crm-community` da Evolution Foundation.

Nosso ecossistema é gerenciado por **Git Submodules** e orquestrado via **Docker Compose** e **Nginx** (com serviços como `evo-auth-service-community`, `evo-ai-crm-community`, `evo-ai-frontend-community`, `evo-scheduling-service`, `evo-projects-service`, `evolution-api`, `evo-bot-runtime`, etc.).

---

### AMBIENTE E INSTÂNCIA DE REFERÊNCIA (iLAB4 GESTÃO FINANCEIRA)
O sistema de referência já está **implantado e rodando localmente** nesta máquina para consulta, inspeção e testes:
- **URL da Aplicação Ativa**: `http://localhost:8085/` (acesso: `http://localhost:8085/financeiro`)
- **Caminho do Código-Fonte Completo**: `C:\Users\pi3rr3\Documents\Projetos\gestao-financeira`
- **Usuário Admin de Teste**: `admin` / **Senha**: `demo`
- **Arquivos-Chave no `gestao-financeira` para consulta**:
  - Modelagem do banco: `C:\Users\pi3rr3\Documents\Projetos\gestao-financeira\database\migrations/`
  - Lógica de Lançamentos e Transferências: `app/Http/Controllers/Financeiro/LancamentoController.php`
  - Lógica de Dashboard e Gráficos: `app/Http/Controllers/Financeiro/DashboardController.php`
  - Cálculos de Extrato, Saldo e Razão: `app/Http/Controllers/Financeiro/RelatorioController.php`
  - Estrutura de Pessoas e Contas: `app/Http/Controllers/Financeiro/PessoaController.php` e `ContaController.php`
  - Configurações da Empresa (CNPJ, Endereço, Logo): `app/Http/Controllers/Financeiro/ConfiguracaoController.php`

---

### DIRETRIZ E CONTEXTO DE NEGÓCIO (MONO-EMPRESA)
Diferente do módulo de Projetos (que é multi-workspace porque a empresa atende a múltiplos clientes externos), o **Módulo Financeiro é ESTRITAMENTE MONO-EMPRESA**.
- Será destinado **exclusivamente à gestão da própria empresa do jprOS**.
- Não haverá separação multi-workspace/multi-tenancy no financeiro. Toda a operação de caixa, bancos, receitas, despesas e DRE pertence à mesma entidade corporativa central.

---

### OBJETIVO
Implementar um novo submódulo dedicado à **Gestão Financeira Completa** (`evo-finance-service`) para o ecossistema `jprOS`, com frontend nativo integrado ao `evo-ai-frontend-community` e proxy reverso no Nginx.

Optamos pela **Abordagem Headless (Engine de Regras + API REST)**:
- Não traremos código PHP, Blade, jQuery ou Bootstrap legado para o jprOS.
- Criaremos um microsserviço limpo em **Node.js/TypeScript** (**Fastify v5 + Prisma v6** com PostgreSQL compartilhado do jprOS no schema `finance`).
- A autenticação dos operadores será integrada diretamente ao token JWT do `evo-auth-service-community`, com controle de acesso baseado em roles (ex: `admin`, `financial`).
- O armazenamento de comprovantes e arquivos anexos utilizará volume persistente dedicado no Docker com rota estática segura.
- A interface de usuário será implementada nativamente no `evo-ai-frontend-community` em **React + TypeScript + Tailwind CSS + shadcn/ui**, seguindo o padrão de navegação com menu lateral e drawer retrátil (idêntico à Agenda e Projetos).

---

### ESCOPO DETALHADO DA IMPLEMENTAÇÃO

#### 1. Dashboard Financeiro (Cockpit de Gestão)
- **Cards de Indicadores (KPIs):**
  - `Saldo em Contas`: Saldo bancário total consolidado (somente contas marcadas com `is_dashboard: true`).
  - `Receitas do Mês`: Total realizado de entradas no mês corrente vs. mês anterior (% de variação).
  - `Despesas do Mês`: Total realizado de saídas no mês corrente vs. mês anterior.
  - `Resultado Operacional Líquido`: Receitas (-) Despesas no mês (com badge verde/vermelho).
  - `A Pagar Hoje / A Vencer`: Total programado pendente para o dia e próximos 7 dias.
  - `Inadimplência / Atrasadas`: Total de contas a receber vencidas e não pagas.
- **Gráficos Dinâmicos:**
  - `Evolução do Fluxo de Caixa (6 meses)`: Gráfico de barras/área comparando Receitas vs Despesas reais realizadas mês a mês.
  - `Composição de Gastos`: Gráfico de rosca/pizza com o percentual de despesas por Plano de Contas / Categorias no mês.
- **Tabelas de Ação Rápida:**
  - `Próximos Vencimentos`: Títulos de contas a pagar e receber ordenados por vencimento iminente, com botão de baixa rápida.
  - `Últimos Lançamentos`: Histórico recente de transações no extrato bancário.

---

#### 2. Lançamentos de Caixa (Fluxo Realizado / Extrato)
- **Operação de Entrada (Receita / Crédito):**
  - Conta bancária de destino.
  - Cliente/Pagador (vínculo com tabela de Pessoas).
  - Plano de Contas (Receita), Centro de Custo e Meio de Pagamento.
  - **Tratamento de Taxas (Bruto vs Líquido e DRE):**
    - `Valor Bruto`: Valor faturado da venda/serviço.
    - `Taxa de Intermediação`: Desconto de gateway/maquininha/cartão (`feeAmount`).
    - `Valor Líquido Creditado`: Valor real que entra na conta bancária (`netAmount = grossAmount - feeAmount`).
    - *Regra Contábil:* A transação no extrato reflete fielmente o valor líquido creditado na conta bancária para conciliação perfeita. O valor da taxa (`feeAmount`) é computado diretamente na linha de deduções do DRE por competência.
  - Data de Lançamento / Compensação e Data de Competência.
  - Número do Documento / NF / Comprovante, Histórico, Observações e Upload de Anexo.
- **Operação de Saída (Despesa / Débito):**
  - Conta bancária de origem.
  - Fornecedor ou Colaborador (pessoa).
  - Plano de Contas (Despesa), Centro de Custo e Meio de Pagamento.
  - Valor nominal, Juros, Multa e Descontos aplicados.
  - Datas (Lançamento e Competência), Histórico, Documento e Anexo do comprovante.
- **Transferência entre Contas Bancárias:**
  - Conta de Origem e Conta de Destino.
  - Cria atomicamente no banco o par de lançamentos vinculados por `transferGroupId`: Débito (`DEBIT`) na origem e Crédito (`CREDIT`) no destino.
  - Histórico descritivo automático (*"Transf. para [Conta Destino]"* / *"Transf. de [Conta Origem]"*).
  - *Regra de Integridade:* A exclusão ou edição de qualquer uma das pontas da transferência cancela ou atualiza atomicamente a contrapartida. As transferências possuem a flag `isTransfer: true` para serem desconsideradas do cálculo de receitas e despesas no DRE.

---

#### 3. Programação Financeira (Contas a Pagar e Contas a Receber)
- **Gestão de Títulos Futuros:**
  - Tipo: `PAGAR` (`PAYABLE`) ou `RECEBER` (`RECEIVABLE`).
  - Título / Documento (ex: NF 1042, Contrato #45).
  - Pessoa (Cliente ou Fornecedor).
  - Plano de Contas, Centro de Custo e Meio de Pagamento planejado.
  - Datas: `Data de Emissão`, `Data de Vencimento` e `Data de Competência`.
  - Valores: `Valor Original`, `Juros Previstos`, `Multa`, `Desconto Previsto` e `Valor Total`.
- **Controle de Vencimentos & Aging (Inadimplência):**
  - Status do Título:
    - `PENDING`: No prazo.
    - `OVERDUE`: Vencimento < data atual. Exibição com badge vermelho e contador de **Dias em Atraso** (ex: *Atrasado há 8 dias*).
    - `PAID`: Baixado totalmente.
    - `PARTIALLY_PAID`: Amortizado parcialmente com saldo pendente.
    - `CANCELLED`: Cancelado.
- **Amortizações e Baixas Parciais (`SchedulePayment`):**
  - Suporte a múltiplas baixas parciais de um mesmo título.
  - Cada liquidação (seja parcial ou total) registra um `SchedulePayment` com: valor pago, juros, multa, desconto, data, conta bancária e a respectiva `Transaction` criada no extrato.
  - O `Schedule` recalcula dinamicamente `paidAmount` e atualiza seu status para `PARTIALLY_PAID` (se `paidAmount < totalAmount`) ou `PAID` (se `paidAmount >= totalAmount`).
  - *Estorno de Baixa:* Se a transação gerada for excluída ou a baixa for estornada, o valor é deduzido de `paidAmount` e o status volta automaticamente para `PARTIALLY_PAID` ou `PENDING`.
- **Parcelamento e Recorrência Automática:**
  - Suporte a compras/vendas parceladas: gera lote de parcelas vinculadas (ex: 1/10, 2/10... 10/10) com vencimentos a cada 30 dias.
  - Suporte a despesas/receitas fixas recorrentes: pré-geração em lote (ex: 12 meses futuros) vinculadas pelo `recurringSeriesId`, permitindo alteração individual ou cancelamento em lote das parcelas futuras não liquidadas.

---

#### 4. Conciliação Bancária & Importação de Extrato (.OFX / .CSV)
- **Leitor de Arquivos OFX com Suporte a Encodings Brasileiros:**
  - Parser em TypeScript para arquivos bancários padrão `.OFX` (Febraban / Open Financial Exchange).
  - Suporte robusto a decodificação de `ISO-8859-1` (Latin-1) e `UTF-8` (frequente em bancos como BB, Bradesco e Caixa Econômica Federal).
  - Extração de `FITID` (ID único da transação bancária para prevenir duplicidades), `Data`, `Valor` e `MEMO/Descrição`.
- **Tela de Conciliação em 2 Colunas (Extrato Bancário ↔ Sistema):**
  - **Correspondência Inteligente (Match com Tolerância):** sugere conciliação com 1 clique se houver título com valor idêntico e vencimento dentro de uma janela configurável de tolerância de datas (±3 dias de compensação bancária).
  - **Ação de "Conciliar":** vincula a linha do extrato ao título existente (`Schedule`), executa a liquidação automática e vincula a transação ao registro importado.
  - **Ação de "Novo Lançamento":** para tarifas bancárias, IOF ou despesas não provisionadas, abre o formulário pré-preenchido com data, valor e histórico do extrato para lançamento rápido.

---

#### 5. Suporte Completo a PIX e Dados Bancários
- **No Cadastro de Fornecedores e Colaboradores:**
  - Tipo de Chave PIX: `CNPJ`, `CPF`, `EMAIL`, `TELEFONE`, `ALEATORIA`.
  - Chave PIX e dados bancários tradicionais (Banco, Agência, Conta Corrente/Poupança).
- **Na Tela de Contas a Pagar:**
  - Botão de **"Copiar Chave PIX"** com feedback visual (`toast`), permitindo ao operador colar a chave instantaneamente no internet banking ou app do banco.

---

#### 6. Emissão de Recibo Simples de Pagamento/Recebimento (Impressão / PDF)
- Emissão de recibo elegante e padronizado para qualquer lançamento ou título liquidado.
- **Dados da Empresa Emissora:** Puxados dinamicamente da tabela `CompanySettings` (Razão Social, Nome Fantasia, CNPJ, Inscrição Estadual, Endereço, Contato e Logo).
- **Numeração Sequencial Atômica:** Gerada de forma única e concorrente pela API (ex: `REC-2026/0001`, incrementando `receiptCurrentNumber` com base no ano vigente).
- **Conteúdo Estruturado:**
  - Cabeçalho timbrado com logo e dados corporativos.
  - Declaração de quitação formal: *"Recebemos de [Pessoa], inscrito sob o CPF/CNPJ [Doc], a quantia de R$ [Valor] ([Valor por extenso]), referente a [Histórico / Descrição]..."*.
  - Local e Data por extenso.
  - Linha de assinatura do responsável com cargo/empresa.
- **Visualização e Impressão:** Modal com layout formatado em folha A4 com folhas de estilo `@media print` para impressão nativa ou geração direta de PDF pelo navegador.

---

#### 7. Cadastros Estruturados de Pessoas e Contas Bancárias
- **Pessoas (Clientes, Fornecedores, Colaboradores):**
  - Tipo de Pessoa: `PF` ou `PJ`.
  - Classificação: `CLIENTE`, `FORNECEDOR`, `COLABORADOR` (uma mesma pessoa pode acumular flags).
  - Nome / Razão Social, Nome Fantasia, CPF/CNPJ, Inscrição Estadual, RG.
  - Telefones, Celular (com atalho para abrir WhatsApp), E-mail financeiro.
  - Endereço completo (com busca automática por CEP via ViaCEP).
  - Dados bancários e chave PIX cadastrados.
- **Contas Bancárias / Caixas:**
  - Nome da Conta (ex: *Itaú PJ*, *Nubank PJ*, *Cora Pagamentos*, *Caixa Físico Escritório*).
  - Tipo: `CHECKING` (Conta Corrente), `SAVINGS` (Poupança), `INVESTMENT` (Aplicação), `CASH` (Caixa Físico).
  - Banco (código e nome Febraban), Agência, Conta com dígito.
  - Saldo Inicial e Data de Abertura.
  - Flag `is_dashboard` (define quais contas compõem o KPI de saldo consolidado).

---

#### 8. Relatórios e DRE (Demonstrativo de Resultado do Exercício)
- **Extrato Financeiro Detalhado:** Filtro por período e conta bancária, com saldo inicial do período, todas as entradas/saídas ordenadas e saldo acumulado progressivo.
- **Posição de Saldo de Contas:** Saldo de todas as contas ativas em qualquer data retroativa ou presente.
- **Livro Razão Analítico:** Agrupamento por Plano de Contas e Centro de Custo para conferência contábil e auditoria.
- **Fluxo de Caixa Projetado (30/60/90 dias):** Visão diária/semanal comparando saldo em conta + entradas previstas - saídas previstas, antecipando se haverá saldo negativo no futuro.
- **Análise por Clientes / Fornecedores:** Ranking de maior faturamento por cliente e maiores gastos por fornecedor.
- **DRE Operacional Real (Regime de Competência):**
  - `(+) Receita Bruta de Serviços/Vendas`
  - `(-) Deduções e Taxas de Vendas (Taxas de Gateway/Cartão/Impostos s/ Nota)`
  - `(=) Receita Operacional Líquida`
  - `(-) Custos dos Serviços Prestados (Custos Diretos)`
  - `(=) Lucro Bruto Operacional`
  - `(-) Despesas Operacionais (Administrativas, Pessoal, Marketing, Gerais)`
  - `(+/-) Resultado Financeiro (Juros recebidos vs Tarifas bancárias/Juros pagos)`
  - `(=) Lucro Líquido / Resultado do Exercício`

---

#### 9. Configurações da Empresa e Auxiliares
- **Configurações da Empresa (`CompanySettings`):** Cadastro único centralizando Razão Social, CNPJ, dados de contato, endereço, chave PIX principal, logo e controle sequencial de recibos.
- **Plano de Contas:** Árvore hierárquica (Nível 1 Sintético, Nível 2 Analítico) dividida em `RECEITAS` (`CREDIT`) e `DESPESAS` (`DEBIT`).
- **Centros de Custo:** Classificação por departamento ou projeto (com campo opcional `projectId` para vinculação direta a projetos do `evo-projects-service`).
- **Formas de Pagamento:** PIX, Boleto Bancário, Cartão de Crédito, Cartão de Débito, Transferência (TED), Dinheiro.

---

#### 10. Segurança, Controle de Acesso (RBAC) e Auditoria
- **Autenticação:** Validação de token JWT do `evo-auth-service-community`.
- **Autorização (RBAC):** Restrição aos operadores autorizados (ex: roles `admin`, `owner` ou usuários com permissão específica para o módulo financeiro). Bloqueio no backend e ocultação do menu no frontend para usuários não autorizados.
- **Auditoria e Rastreabilidade:** Registro de `createdById` e `updatedById` nas operações sensíveis de lançamento e título, além de `deletedAt` (Soft Delete) para garantir integridade contábil em caso de auditoria.

---

### MODELAGEM DO BANCO DE DADOS REFINADA (PRISMA SCHEMA)

Criar no microsserviço `evo-finance-service/prisma/schema.prisma` com conexão PostgreSQL compartilhada no schema `finance`:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

enum OperationType {
  CREDIT
  DEBIT
}

enum ScheduleType {
  PAYABLE
  RECEIVABLE
}

enum ScheduleStatus {
  PENDING
  OVERDUE
  PAID
  PARTIALLY_PAID
  CANCELLED
}

enum PersonType {
  INDIVIDUAL // PF
  LEGAL_ENTITY // PJ
}

enum AccountCategory {
  CHECKING // Conta Corrente
  SAVINGS // Poupança
  INVESTMENT // Aplicação
  CASH // Dinheiro em Caixa
}

enum PixKeyType {
  CPF
  CNPJ
  EMAIL
  PHONE
  RANDOM
}

enum ReconciliationStatus {
  PENDING
  RECONCILED
  IGNORED
}

// Configurações da Empresa Emissora (Mono-Empresa)
model CompanySettings {
  id                   String   @id @default(uuid())
  companyName          String   // Razão Social
  tradeName            String?  // Nome Fantasia
  documentNumber       String   // CNPJ
  stateRegistry        String?  // Inscrição Estadual
  email                String?
  phone                String?
  whatsapp             String?
  zipCode              String?
  address              String?
  addressNumber        String?
  complement           String?
  neighborhood         String?
  city                 String?
  state                String?
  logoUrl              String?
  receiptPrefix        String   @default("REC")
  receiptCurrentNumber Int      @default(0)
  receiptCurrentYear   Int      @default(2026)
  defaultPixKeyType    PixKeyType?
  defaultPixKey        String?
  createdAt            DateTime @default(now())
  updatedAt            DateTime @updatedAt

  @@map("company_settings")
}

model BankAccount {
  id              String          @id @default(uuid())
  name            String
  category        AccountCategory @default(CHECKING)
  bankCode        String?
  bankName        String?
  agency          String?
  accountNumber   String?
  initialBalance  Decimal         @default(0) @db.Decimal(12, 2)
  initialDate     DateTime        @default(now())
  isDashboard     Boolean         @default(true)
  isActive        Boolean         @default(true)
  contactName     String?
  contactPhone    String?
  notes           String?
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt

  transactions     Transaction[]
  schedules        Schedule[]
  schedulePayments SchedulePayment[]
  importedEntries  ImportedBankStatement[]

  @@map("bank_accounts")
}

model ChartOfAccounts {
  id              String        @id @default(uuid())
  parentId        String?
  code            String?       // ex: 1.1, 1.1.01
  name            String
  type            OperationType // CREDIT (Receita) ou DEBIT (Despesa)
  isActive        Boolean       @default(true)
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt

  parent          ChartOfAccounts?  @relation("AccountHierarchy", fields: [parentId], references: [id], onDelete: Cascade)
  children        ChartOfAccounts[] @relation("AccountHierarchy")
  transactions    Transaction[]
  schedules       Schedule[]

  @@map("chart_of_accounts")
}

model CostCenter {
  id          String       @id @default(uuid())
  parentId    String?
  code        String?
  name        String
  manager     String?
  projectId   String?      // Vínculo opcional com evo-projects-service
  isActive    Boolean      @default(true)
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  parent      CostCenter?  @relation("CostCenterHierarchy", fields: [parentId], references: [id], onDelete: Cascade)
  children    CostCenter[] @relation("CostCenterHierarchy")
  transactions Transaction[]
  schedules   Schedule[]

  @@map("cost_centers")
}

model Person {
  id              String      @id @default(uuid())
  personType      PersonType  @default(LEGAL_ENTITY)
  isClient        Boolean     @default(false)
  isSupplier      Boolean     @default(false)
  isEmployee      Boolean     @default(false)
  name            String      // Nome Completo ou Razão Social
  tradeName       String?     // Nome Fantasia
  documentNumber  String?     // CPF ou CNPJ
  stateRegistry   String?     // Inscrição Estadual ou RG
  email           String?
  phone           String?
  mobilePhone     String?     // WhatsApp
  zipCode         String?
  address         String?
  addressNumber   String?
  complement      String?
  neighborhood    String?
  city            String?
  state           String?
  pixKeyType      PixKeyType?
  pixKey          String?
  bankName        String?
  bankAgency      String?
  bankAccount     String?
  notes           String?
  isActive        Boolean     @default(true)
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt

  transactions    Transaction[]
  schedules       Schedule[]

  @@index([name])
  @@index([documentNumber])
  @@map("people")
}

model PaymentMethod {
  id               String            @id @default(uuid())
  name             String            // PIX, Boleto, Cartão, Dinheiro
  isActive         Boolean           @default(true)
  createdAt        DateTime          @default(now())
  updatedAt        DateTime          @updatedAt

  schedules        Schedule[]
  transactions     Transaction[]
  schedulePayments SchedulePayment[]

  @@map("payment_methods")
}

model Schedule {
  id                String          @id @default(uuid())
  type              ScheduleType    // PAYABLE (A Pagar) / RECEIVABLE (A Receber)
  status            ScheduleStatus  @default(PENDING)
  documentNumber    String?
  description       String
  personId          String?
  accountId         String?
  chartOfAccountsId String?
  costCenterId      String?
  paymentMethodId   String?
  issueDate         DateTime        @default(now())
  dueDate           DateTime
  competenceDate    DateTime
  originalAmount    Decimal         @db.Decimal(12, 2)
  interestAmount    Decimal         @default(0) @db.Decimal(12, 2)
  fineAmount        Decimal         @default(0) @db.Decimal(12, 2)
  discountAmount    Decimal         @default(0) @db.Decimal(12, 2)
  feeAmount         Decimal         @default(0) @db.Decimal(12, 2) // Taxa de gateway estimada
  totalAmount       Decimal         @db.Decimal(12, 2)
  paidAmount        Decimal         @default(0) @db.Decimal(12, 2)
  installmentNumber Int?            @default(1)
  totalInstallments Int?            @default(1)
  recurringSeriesId String?
  notes             String?
  attachmentUrl     String?
  createdById       String?
  updatedById       String?
  deletedAt         DateTime?
  createdAt         DateTime        @default(now())
  updatedAt         DateTime        @updatedAt

  person            Person?           @relation(fields: [personId], references: [id])
  account           BankAccount?      @relation(fields: [accountId], references: [id])
  chartOfAccounts   ChartOfAccounts?  @relation(fields: [chartOfAccountsId], references: [id])
  costCenter        CostCenter?       @relation(fields: [costCenterId], references: [id])
  paymentMethod     PaymentMethod?    @relation(fields: [paymentMethodId], references: [id])
  payments          SchedulePayment[]
  transactions      Transaction[]

  @@index([status, dueDate])
  @@index([type, dueDate])
  @@index([personId])
  @@map("schedules")
}

// Registro histórico de baixas / liquidações parciais ou totais
model SchedulePayment {
  id              String         @id @default(uuid())
  scheduleId      String
  transactionId   String?
  accountId       String
  paymentMethodId String?
  amount          Decimal        @db.Decimal(12, 2) // Valor amortizado principal
  interestAmount  Decimal        @default(0) @db.Decimal(12, 2)
  fineAmount      Decimal        @default(0) @db.Decimal(12, 2)
  discountAmount  Decimal        @default(0) @db.Decimal(12, 2)
  totalPaid       Decimal        @db.Decimal(12, 2) // Valor total desembolsado
  paidAt          DateTime       @default(now())
  notes           String?
  createdById     String?
  createdAt       DateTime       @default(now())

  schedule        Schedule       @relation(fields: [scheduleId], references: [id], onDelete: Cascade)
  transaction     Transaction?   @relation(fields: [transactionId], references: [id])
  account         BankAccount    @relation(fields: [accountId], references: [id])
  paymentMethod   PaymentMethod? @relation(fields: [paymentMethodId], references: [id])

  @@index([scheduleId])
  @@index([paidAt])
  @@map("schedule_payments")
}

model Transaction {
  id                String            @id @default(uuid())
  operation         OperationType     // CREDIT (Entrada) ou DEBIT (Saída)
  accountId         String
  personId          String?
  chartOfAccountsId String?
  costCenterId      String?
  scheduleId        String?
  paymentMethodId   String?
  grossAmount       Decimal           @db.Decimal(12, 2)
  feeAmount         Decimal           @default(0) @db.Decimal(12, 2) // Taxa de gateway / maquininha
  netAmount         Decimal           @db.Decimal(12, 2) // Valor que entrou/saiu do banco
  transactionDate   DateTime          @default(now())
  competenceDate    DateTime          @default(now())
  documentNumber    String?
  description       String
  notes             String?
  attachmentUrl     String?
  isTransfer        Boolean           @default(false)
  transferGroupId   String?           // Vincula débito e crédito na transferência
  transferNotes     String?
  isReconciled      Boolean           @default(false)
  receiptNumber     String?           // Ex: REC-2026/0001
  createdById       String?
  updatedById       String?
  deletedAt         DateTime?
  createdAt         DateTime          @default(now())
  updatedAt         DateTime          @updatedAt

  account           BankAccount       @relation(fields: [accountId], references: [id])
  person            Person?           @relation(fields: [personId], references: [id])
  chartOfAccounts   ChartOfAccounts?  @relation(fields: [chartOfAccountsId], references: [id])
  costCenter        CostCenter?       @relation(fields: [costCenterId], references: [id])
  schedule          Schedule?         @relation(fields: [scheduleId], references: [id])
  paymentMethod     PaymentMethod?    @relation(fields: [paymentMethodId], references: [id])
  statementEntries  ImportedBankStatement[]
  schedulePayments  SchedulePayment[]

  @@index([accountId, transactionDate])
  @@index([competenceDate])
  @@index([chartOfAccountsId])
  @@index([transferGroupId])
  @@map("transactions")
}

model ImportedBankStatement {
  id                   String                @id @default(uuid())
  accountId            String
  fitId                String                // ID único da transação bancária no OFX
  datePosted           DateTime
  amount               Decimal               @db.Decimal(12, 2)
  memo                 String                // Descrição do extrato
  reconciliationStatus ReconciliationStatus  @default(PENDING)
  transactionId        String?
  createdAt            DateTime              @default(now())

  account              BankAccount           @relation(fields: [accountId], references: [id])
  transaction          Transaction?          @relation(fields: [transactionId], references: [id])

  @@unique([accountId, fitId])
  @@index([accountId, datePosted])
  @@map("imported_bank_statements")
}
```

---

### ARQUITETURA DE REDE, VOLUMES E SERVIÇOS NO JPROS

#### 1. Novo Serviço no `docker-compose.yml`
```yaml
  # Financial Service (Node.js / Fastify / Prisma) - Port 3004
  # ---------------------------------------------------------------------------
  evo-finance:
    build:
      context: ./evo-finance-service
      dockerfile: Dockerfile
    restart: unless-stopped
    ports:
      - "3014:3004"
    volumes:
      - ./storage/finance/uploads:/app/uploads
    environment:
      PORT: "3004"
      HOST: 0.0.0.0
      NODE_ENV: development
      DATABASE_URL: postgresql://${POSTGRES_USERNAME:-postgres}:${POSTGRES_PASSWORD:-evoai_dev_password}@postgres:5432/${POSTGRES_DATABASE:-evo_community}?schema=finance
      CORS_ORIGIN: "*"
      UPLOAD_DIR: "/app/uploads"
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:3004/health"]
      interval: 15s
      timeout: 5s
      retries: 5
      start_period: 20s
```

#### 2. Rota no Nginx Gateway (`nginx/default.conf.template`)
```nginx
    set $finance_service http://evo-finance:3004;

    # Financial Service Routes (com suporte a uploads de até 25MB para OFX e Comprovantes)
    location ~ ^/api/v1/finance {
        client_max_body_size 25M;
        proxy_pass $finance_service$request_uri;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Authorization $http_authorization;
    }
```

---

### ESTRUTURA DE INTERFACE NO FRONTEND (`evo-ai-frontend-community`)

Seguindo o design system do jprOS (Barra Lateral Principal + Drawer Secundário Retrátil):

1. **Menu Principal (Barra Lateral Esquerda - `Sidebar.tsx`):**
   - Item de menu: `💰 Financeiro` com indicador retrátil (visível apenas para usuários com permissão/role administrativa ou financeira).
2. **Drawer Retrátil do Financeiro (`FinanceSidebarDrawer.tsx`):**
   - **VISÃO GERAL**
     - `📊 Dashboard`: Cockpit com saldos consolidados, gráficos de fluxo de caixa e composição de despesas.
   - **MOVIMENTAÇÃO (EXTRATO)**
     - `💳 Lançamentos de Caixa`: Lista unificada com filtros rápidos: *Todos*, *Entradas*, *Saídas*, *Transferências*.
     - `⚡ Conciliação OFX`: Importação de arquivo de extrato bancário com correspondência inteligente.
   - **CONTAS FUTURAS**
     - `🔴 Contas a Pagar`: Títulos com alerta de dias em atraso, botão de copiar PIX e modal de liquidação (parcial/total).
     - `🟢 Contas a Receber`: Títulos com controle de inadimplência, baixa e emissão de recibo.
   - **CADASTROS BASE**
     - `👥 Pessoas`: Clientes, Fornecedores e Colaboradores (com dados de PIX e endereço via CEP).
     - `🏦 Contas Bancárias`: Gerenciamento de bancos e caixas físicos com controle de saldo inicial.
   - **RELATÓRIOS & DRE**
     - `📈 DRE Operacional`: Demonstrativo do resultado por regime de competência.
     - `🗓️ Fluxo de Caixa Projetado`: Projeção de liquidez futura em 30, 60 e 90 dias.
     - `📑 Livro Razão / Extratos`: Posição detalhada por plano de contas.
     - `👤 Análise por Clientes / Fornecedores`: Relatório de volume transacionado.
   - **CONFIGURAÇÕES**
     - `🏢 Dados da Empresa`: Razão social, CNPJ, logo e parâmetros do recibo.
     - `🌳 Plano de Contas`: Árvore de receitas e despesas.
     - `🎯 Centros de Custo`: Árvore de departamentos/projetos.
     - `⚙️ Formas de Pagamento & Bancos`: Cadastros auxiliares.

---

### DIRETRIZES DE EXECUÇÃO
1. **Submódulo Backend (`evo-finance-service`):**
   - Inicializar o projeto com Fastify v5, TypeScript, Prisma v6, `@fastify/cors`, `@fastify/static` e `@fastify/multipart`.
   - Implementar migração inicial do Prisma gerando o schema `finance` no PostgreSQL compartilhado.
   - Implementar seed com plano de contas padrão, formas de pagamento e configuração inicial da empresa.
   - Configurar middleware JWT com RBAC e endpoints REST seguros para todas as entidades.
2. **Infraestrutura Docker & Nginx:**
   - Adicionar o serviço `evo-finance` no `docker-compose.yml` com volume persistente de uploads.
   - Configurar o roteamento no Nginx (`/api/v1/finance`).
3. **Frontend jprOS (`evo-ai-frontend-community`):**
   - Criar `FinanceSidebarDrawer.tsx` e integrar ao `Sidebar.tsx`.
   - Adicionar rotas protegidas em `src/routes/index.tsx`.
   - Implementar as páginas e modais: Dashboard, Lançamentos, Contas a Pagar/Receber, Conciliação OFX, Recibo Timbrado (com `@media print`) e DRE.
4. **Validação Ponta a Ponta:**
   - Testar o fluxo completo: Lançamento ➔ Impacto no Saldo Bancário ➔ Baixa de Título ➔ Emissão de Recibo ➔ DRE Operacional.
