# Proposal

## Why

A operação de empréstimos precisa de controle confiável de clientes, contratos, vencimentos, recebimentos e acordos, sem depender da planilha como banco de dados. O módulo deve preservar a composição da dívida e o histórico, permitindo operação e acompanhamento por carteiras isoladas.

## What Changes

- Criar módulo de Empréstimos independente, com carteiras, acessos, clientes, documentos, parâmetros e auditoria próprios.
- Simular e registrar empréstimos em parcela única ou Price, cronogramas, dados históricos manuais e condições definidas por carteira e contrato.
- Registrar recebimentos, encargos, ajustes, prorrogações, acordos, perdas, recuperações, correções e cancelamentos sem duplicar obrigações ou movimentos de dinheiro.
- Disponibilizar central de parcelas, ficha de cliente, indicadores, relatórios e exportações por carteira.
- Planejar avisos automáticos por WhatsApp na fase posterior, com regras por carteira; escolha do provedor e remetente permanece pendente.
- Implementar por fases G0–G6, com validação e liberação controladas; os débitos DT-01–DT-07 permanecem rastreados e as capacidades afetadas não são liberadas antes das decisões e testes correspondentes.

Não importar planilha nem integrar regras, dados, serviços ou lançamentos do Financeiro. Não incluir financiamento de bens, portal do tomador, webhook PIX, CRM de negócio ou visão consolidada de carteiras. Compartilhar somente infraestrutura genérica do jprOS.

## Capabilities

### New Capabilities

- `loans-wallets`: carteiras isoladas, identidade, acesso, parâmetros, clientes e documentos.
- `loans-contracts`: simulação, contratos, parcelas, cronogramas e cadastro manual histórico.
- `loans-collections`: pagamentos, encargos, ajustes, prorrogação, acordo, perda, correção e cancelamento.
- `loans-portfolio`: central de cobrança, ficha do cliente, indicadores e relatórios.
- `loans-notifications`: notificações automáticas por WhatsApp em fase posterior.

### Modified Capabilities

Nenhuma especificação principal existente é modificada; o inventário OpenSpec atual não possui specs principais.

## Impact

Novo `evo-loans-service`, schema e migrações próprios, API `/api/v1/loans`, frontend Evo, gateway, configuração de ambientes, CI e recuperação de dados. Auth fornece identidade, não autorização de negócio; nenhuma dependência do Financeiro ou alteração de suas regras. Referências: `solicitacao-implementacao-emprestimos.md`, `docs/emprestimos/REGRAS-E-CENARIOS-v2.1.md` e `docs/emprestimos/DEBITOS-TECNICOS.md`. A planilha original e o protótipo não foram revalidados; seus números históricos não são critério de aceite.
