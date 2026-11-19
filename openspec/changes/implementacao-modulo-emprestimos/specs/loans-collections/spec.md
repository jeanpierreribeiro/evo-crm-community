# Spec Delta

## Purpose

Controlar recebimentos e modificações da dívida com saldos consistentes, escolhas explícitas e histórico verificável.

## ADDED Requirements

### Requirement: Alocação do recebimento
O sistema MUST sugerir a parcela mais antiga, permitir escolha de outra e aplicar valores por ordem: multa, juros contratuais, mora, encargos avulsos e principal.

#### Scenario: Excedente em parcela selecionada
- **WHEN** o valor recebido supera o saldo da parcela selecionada e não supera o devido no contrato
- **THEN** o sistema quita a parcela selecionada e aplica o restante à parcela mais antiga aberta do mesmo contrato

#### Scenario: Valor acima da dívida
- **WHEN** o valor recebido excede o total devido no contrato
- **THEN** o sistema rejeita integralmente o recebimento, informa o limite e não gera crédito excedente

### Requirement: Encargos configuráveis
O sistema MUST calcular multa recorrente e mora segundo as condições do contrato, sem capitalizar multas ou mora anteriores, permitindo redução ou dispensa com motivo.

#### Scenario: Mora proporcional
- **WHEN** há 21 dias computáveis em mês de 31 dias, base constante de R$ 430,01 e taxa mensal ilustrativa de 1%
- **THEN** a prévia apresenta R$ 2,91 de mora, sob a política de arredondamento documentada

#### Scenario: Multa no dia do pagamento
- **WHEN** a parcela deve R$ 1.000,00, recebe R$ 400,00 e há multa nova de 2% naquele dia, sem outros componentes
- **THEN** o pagamento reduz o saldo a R$ 600,00 e a multa de R$ 12,00 fica pendente para pagamento posterior

#### Scenario: Regra pendente de cobrança
- **WHEN** uma operação depende de composição de base ou sequência de encargos ainda não definida no DT-01
- **THEN** o sistema impede confirmação dessa operação até que a regra aplicável esteja definida e validada

### Requirement: Escolhas na mora
O sistema MUST apresentar a inclusão do dia do pagamento como opção alterável, pré-selecionada; na modalidade de 30 dias com pagamento parcial, MUST exigir escolha explícita da base sem pré-seleção.

#### Scenario: Pagamento parcial em bloco de 30 dias
- **WHEN** houve R$ 1.000,00 por 15 dias e R$ 600,00 por 15 dias com taxa ilustrativa de 1%
- **THEN** o sistema apresenta R$ 6,00 pela base final e R$ 8,00 pela base proporcional ao tempo para escolha

### Requirement: Prorrogação e renegociação
O sistema MUST exigir quitação dos juros antigos antes de prorrogar e registrar renegociação vinculada sem gerar recebimento ou desembolso fictício.

#### Scenario: Juros antigos insuficientemente pagos
- **WHEN** há R$ 20,00 de multa e R$ 140,00 de juros e o cliente paga R$ 140,00
- **THEN** a multa é abatida primeiro, restam R$ 20,00 de juros e a prorrogação fica impedida até sua quitação

#### Scenario: Renegociação
- **WHEN** o saldo é transferido a um novo acordo
- **THEN** novos juros incidem sobre o principal ainda devido, juros e multa anteriores permanecem separados e o saldo antigo deixa de ser cobrado sem dupla contagem

### Requirement: Ajustes e correções rastreáveis
O sistema MUST preservar registros originais e permitir correção justificada do dinheiro efetivamente recebido e da dívida sem criar transferência nem duplicar efeito.

#### Scenario: Valor de recebimento registrado incorretamente
- **WHEN** um recebimento registrado como R$ 150,00 foi na realidade R$ 100,00
- **THEN** a correção vinculada preserva o registro original e os relatórios mostram R$ 100,00 efetivamente recebidos

#### Scenario: Dependência sem tratamento seguro
- **WHEN** a correção depende de operação posterior e não há procedimento validado que preserve os saldos
- **THEN** o sistema apresenta o impedimento e não confirma a operação afetada

### Requirement: Cancelamento e devoluções
O sistema MUST preservar fatos e distinguir estorno de registro, compensação de principal e devolução real no cancelamento.

#### Scenario: Parte do principal já recebida
- **WHEN** R$ 1.000,00 foram entregues e R$ 200,00 de principal já foram recebidos
- **THEN** os R$ 200,00 contam para a devolução e restam R$ 800,00 a devolver

#### Scenario: Encargos recebidos
- **WHEN** um contrato é cancelado após recebimento de juros ou encargos
- **THEN** o operador pode escolher manter, devolver integralmente ou devolver parcialmente cada componente e o sistema registra devolução real separadamente

### Requirement: Perda e recuperação
O sistema MUST permitir marcar apenas o saldo integral do contrato como perda, congelar encargos e suspender cobrança, permitindo recuperação posterior pela ordem normal de pagamentos.

#### Scenario: Recuperação parcial
- **WHEN** uma dívida em perda de R$ 860,00 inclui principal de R$ 700,00, juros de R$ 140,00 e multa de R$ 20,00 e recebe R$ 140,00
- **THEN** a perda restante é R$ 720,00 e não são gerados novos encargos enquanto estiver em perda

#### Scenario: Correção de marcação de perda
- **WHEN** a perda é corrigida e a dívida volta à cobrança
- **THEN** o operador escolhe se serão calculados encargos do período congelado e a decisão fica registrada

### Requirement: Confirmação concorrente e repetição
O sistema MUST confirmar saldos, alocações, auditoria e identificação de operação atomicamente, impedindo duplicação e rejeitando versões ou chaves incompatíveis.

#### Scenario: Reenvio após tempo esgotado
- **WHEN** o mesmo pagamento é reenviado com a mesma chave e conteúdo após uma resposta perdida
- **THEN** o sistema devolve o resultado anterior sem registrar outro pagamento
