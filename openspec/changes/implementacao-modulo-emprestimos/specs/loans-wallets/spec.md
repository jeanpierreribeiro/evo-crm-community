# Spec Delta

## Purpose

Isolar carteiras de empréstimos, suas configurações e clientes, permitindo acesso somente a pessoas autorizadas.

## ADDED Requirements

### Requirement: Isolamento das carteiras
O sistema MUST restringir dados, operações, anexos, consultas e exportações à carteira autorizada, sem depender dos dados ou disponibilidade do Financeiro.

#### Scenario: Tentativa de acesso cruzado
- **WHEN** uma pessoa solicita um contrato ou documento de outra carteira sem autorização
- **THEN** o sistema nega o acesso e não divulga seus dados

### Requirement: Administração e permissões locais
O sistema MUST usar identidade existente do Auth e conceder acesso local por pessoa e carteira; pessoas designadas pelo dono podem criar carteiras e administrar apenas as carteiras atribuídas.

#### Scenario: Designado administra carteira atribuída
- **WHEN** uma pessoa designada recebe atribuição administrativa para uma carteira
- **THEN** pode gerir seus membros e acessar seus dados, sem acesso às demais carteiras não autorizadas

#### Scenario: Membros autorizados
- **WHEN** duas pessoas são membros ativos de uma mesma carteira
- **THEN** ambas recebem as mesmas permissões operacionais nessa carteira, sem adquirir direito de administrar acessos

### Requirement: Clientes por carteira e CPF pendente
O sistema MUST manter cadastros próprios por carteira, aceitar CPF ausente ou inválido como pendente e permitir contratos novos ou antigos nessa condição.

#### Scenario: CPF válido repetido em outra carteira
- **WHEN** o mesmo CPF válido é cadastrado em duas carteiras diferentes
- **THEN** o sistema mantém clientes independentes, impedindo duplicidade válida dentro de cada carteira

#### Scenario: Cliente com CPF pendente
- **WHEN** cliente com CPF ausente ou inválido solicita novo empréstimo
- **THEN** o sistema permite confirmar o contrato e mantém aviso de CPF pendente

### Requirement: Configuração da carteira
O sistema MUST permitir configurar padrões de condições, multa, mora, espera e frequência das multas por carteira, preservando as condições já confirmadas dos contratos.

#### Scenario: Alteração de parâmetros
- **WHEN** um operador altera um parâmetro padrão da carteira
- **THEN** o padrão passa a valer para novos contratos e não recalcula contratos existentes

### Requirement: Proteção de dados e auditoria
O sistema MUST proteger dados pessoais e anexos, mascarar CPF por padrão, auditar a exibição completa e conservar o histórico de alterações sem expor dados sensíveis nos logs.

#### Scenario: Anexo de outra carteira
- **WHEN** um usuário tenta baixar documento de cliente de carteira não autorizada
- **THEN** o download é negado mesmo que o identificador do arquivo seja conhecido
