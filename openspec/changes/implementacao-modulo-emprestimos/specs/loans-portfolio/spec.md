# Spec Delta

## Purpose

Oferecer acompanhamento operacional de parcelas, clientes, indicadores e relatórios de uma carteira autorizada.

## ADDED Requirements

### Requirement: Central de parcelas
O sistema MUST disponibilizar central de parcelas com busca, filtros de período e situação, paginação e ações em lote com resultado por contrato.

#### Scenario: Parcela parcial e vencida
- **WHEN** uma parcela possui saldo após pagamento parcial e está vencida
- **THEN** aparece tanto nos filtros de parcial quanto de vencida

#### Scenario: Falha parcial em lote
- **WHEN** alguns itens de lote são confirmados e outros rejeitados
- **THEN** a interface apresenta resultados individuais e uma repetição não refaz os itens confirmados

### Requirement: Ficha do cliente
O sistema MUST apresentar por cliente os contratos, parcelas, pagamentos, notas e documentos da carteira autorizada, preservando histórico de correções.

#### Scenario: Cliente com dívida em perda
- **WHEN** um cliente tem contrato marcado como perda com saldo restante
- **THEN** a ficha conserva o histórico da dívida e não a representa como paga

### Requirement: Indicadores por carteira
O sistema MUST apresentar K1–K8 conforme o plano vigente, em uma carteira por vez, com qualidade e cobertura dos dados e denominador zero como não aplicável.

#### Scenario: Histórico estimado
- **WHEN** indicadores incluem pagamento com data estimada
- **THEN** o sistema identifica a estimativa e distingue séries exatas de estimadas

#### Scenario: Regras de perda pendentes
- **WHEN** uma interpretação dos indicadores de perda ou correção retroativa ainda não estiver definida e validada
- **THEN** o indicador afetado não é liberado como resultado definitivo

### Requirement: Relatórios e exportação
O sistema MUST oferecer fluxo operacional de concessões e recebimentos, distribuição por status, maiores devedores e faixas de valor, com exportação Excel e PDF respeitando filtros e autorização.

#### Scenario: Transferência para acordo
- **WHEN** dívida é transferida a uma renegociação sem novo desembolso
- **THEN** o relatório não conta a transferência como nova concessão de dinheiro

#### Scenario: Conteúdo inserido pelo usuário
- **WHEN** uma exportação contém texto iniciado por caracteres que podem formar fórmula
- **THEN** o conteúdo é exportado como texto e não como fórmula executável
