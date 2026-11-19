# Spec Delta

## Purpose

Permitir simular e registrar empréstimos de dinheiro com cronogramas rastreáveis e condições preservadas.

## ADDED Requirements

### Requirement: Simulação e confirmação
O sistema MUST permitir simular empréstimo de dinheiro em parcela única ou múltiplas parcelas Price, inclusive com taxa zero, salvar rascunho e apresentar cronograma antes da confirmação.

#### Scenario: Parcela única
- **WHEN** um operador simula principal de R$ 700,00 com taxa de 20% no período
- **THEN** a prévia apresenta parcela de R$ 840,00

#### Scenario: Rascunho
- **WHEN** um contrato é salvo como rascunho
- **THEN** ele não gera concessão, saldo em cobrança ou indicadores operacionais

### Requirement: Cronograma e centavos
O sistema MUST guardar o cronograma confirmado e ajustar a última parcela para eliminar resíduos de principal, sem parcelas ou componentes negativos.

#### Scenario: Divisão sem juros
- **WHEN** R$ 100,00 são divididos em três parcelas sem juros
- **THEN** as parcelas são R$ 33,33, R$ 33,33 e R$ 33,34 e o principal final é zero

#### Scenario: Datas mensais
- **WHEN** o vencimento mensal tem âncora no dia 31 e fevereiro tem 28 dias
- **THEN** os vencimentos incluem 31/01, 28/02 e 31/03, sem deslocamento por feriado

### Requirement: Condições confirmadas
O sistema MUST preservar condições e cronograma originais confirmados e registrar ajustes justificados sem editar livremente os termos originais.

#### Scenario: Mudança de taxa padrão
- **WHEN** a taxa padrão da carteira muda após a confirmação
- **THEN** o cronograma confirmado não é recalculado automaticamente

### Requirement: Contratos antigos manuais
O sistema MUST permitir cadastrar manualmente todas as parcelas históricas com valores e vencimentos combinados, sem importar dados nem registrar novos desembolsos ou recebimentos fictícios.

#### Scenario: Pagamento histórico conhecido
- **WHEN** um operador informa valor recebido e data de pagamento anterior
- **THEN** o sistema preserva o histórico e permite marcar data aproximada como estimada

#### Scenario: Componente desconhecido
- **WHEN** a composição de um recebimento antigo permanece desconhecida após conferência
- **THEN** o contrato histórico permanece em rascunho até que os componentes sejam identificados

#### Scenario: Desconto histórico
- **WHEN** uma parcela de R$ 500,00 foi quitada com desconto de R$ 50,00 e pagamento de R$ 450,00
- **THEN** o sistema registra valor original, desconto e recebimento separadamente

### Requirement: Correção de data histórica
O sistema MUST permitir corrigir data estimada para data exata preservando a estimativa anterior e auditoria, sem recalcular automaticamente encargos posteriores confirmados.

#### Scenario: Comprovante encontrado
- **WHEN** a data estimada de 10 de março é corrigida para a data exata de 12 de março
- **THEN** a data efetiva passa a ser 12 de março e a estimativa anterior permanece no histórico
