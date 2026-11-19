# Evidências parciais — clientes, simulação e contratos

Registro de 29/10/2026. Estes testes são sintéticos e **não aprovam o gate G1 nem autorizam uso operacional**. A confirmação de novos contratos continua desativada por padrão; a confirmação histórica está bloqueada no serviço em execução.

- `evo-loans-service: npm test`: exemplos de parcela única, Price, taxa zero, resíduos, datas civis e limites. O motor informa sua versão e os testes comparam componentes em centavos por cálculo independente.
- `evo-loans-service: npm run test:db`: banco PostgreSQL descartável com criação e correção de clientes, CPF pendente ou duplicado, isolamento de carteira, parâmetros, prévia, rascunho e confirmação em modo de teste. O cronograma confirmado foi comparado com a prévia; mudança posterior de parâmetros não o alterou. Repetição, concorrência, falha na auditoria e confirmação com CPF ausente ou inválido também foram testadas.
- `evo-ai-frontend-community: npm test -- ...` para os testes em `src/pages/loans` e `src/services/loans`: cobertura de cliente, máscara, edição, parâmetros, taxa sugerida alterável, erro de simulação, troca de carteira, rascunho, confirmação de entrega, contrato confirmado, anexos e entrada histórica manual. As respostas de API nesses testes de interface são simuladas.
- A entrada histórica foi ensaiada separadamente no banco descartável com três parcelas, uma paga, data estimada, correção auditada, desconto separado e conferência de possível duplicidade; os valores reais informados não são substituídos pela referência calculada.

Ainda faltam teste integrado em navegador pelo gateway com Auth e serviços reais, validação visual e operacional dos fluxos, configuração segura de segredos e verificação dos demais critérios de liberação. Os débitos e gates de cobrança permanecem acompanhados em `DEBITOS-TECNICOS.md`; o Financeiro não participa dessas regras nem dos dados de Empréstimos.
