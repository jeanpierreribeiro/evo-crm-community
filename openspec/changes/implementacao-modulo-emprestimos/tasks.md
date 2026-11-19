# Tasks

As fases abaixo organizam o trabalho; nenhum gate está aprovado. Não habilitar operações afetadas pelos débitos abertos antes de suas condições e testes. O registro DT-01–DT-07 continua em `docs/emprestimos/DEBITOS-TECNICOS.md` e deve ser atualizado com evidências quando resolvido.

## 1. Fundação e acesso — G0

- [x] 1.1 Definir topologia do serviço, runtime, porta e estratégias Compose/Swarm; verificar disponibilidade e registrar escolha, sem criar repositório remoto automaticamente.
- [x] 1.2 Criar `evo-loans-service`, dependências, build e health/readiness autenticando rotas de negócio; verificar build e respostas pelo gateway.
- [x] 1.3 Criar schema, papéis DDL/DML, migrations versionadas e job próprio; testar deploy em banco vazio e negação de acesso cruzado e DDL ao usuário da aplicação.
- [x] 1.4 Integrar gateway, filtro `LOANS_UPSTREAM`, frontend `VITE_LOANS_API_URL`, placeholders, flags e CI; testar rota, flag desligada e build por ambiente.
- [x] 1.5 Implementar validação JWT/Auth e igualdade de identidade; testar assinatura, claims, revogação, 401 e indisponibilidade 503 sem fallback.
- [x] 1.6 Implementar carteiras, membros, designados e bootstrap/recuperação auditados; testar criação, revogação, escopo administrativo e acesso cruzado.
- [x] 1.7 Resolver seleção de usuários existentes com permissões reais do Auth; testar designado sem `users.read` e diferenciar acesso negado de indisponibilidade.
- [x] 1.8 Implementar auditoria, CPF/RG protegidos, anexos e chaves; testar máscara, visualização auditada, acesso cruzado, tipo e tamanho de arquivo.
- [x] 1.9 Ensaiar backup e restauração de banco, anexos e chaves, incluindo procedimento para fatos posteriores; registrar evidências G0 e DT-06.

## 2. Clientes, simulação e contratos — G1

- [x] 2.1 Criar cadastro por carteira e CPF pendente; testar mesmo CPF entre carteiras, conflito na mesma carteira e novo contrato com CPF ausente/inválido.
- [x] 2.2 Implementar parâmetros e condições por contrato; testar que alteração posterior de padrão não recalcula contrato confirmado.
- [x] 2.3 Consolidar DT-04 entre modelo, RN e decisões sem mudar escolhas; verificar que histórico desconhecido fica em rascunho e referências não se contradizem.
- [x] 2.4 Implementar cálculo de parcela única e Price no servidor, com taxa zero e números decimais; verificar R$ 700 a 20% e R$ 1.000 a 13,9% em três parcelas.
- [x] 2.5 Fechar DT-05 e testar motor real para resíduos, taxas e limites com última parcela ajustada, soma de componentes consistente e principal final zero.
- [x] 2.6 Implementar datas civis mensais e semanais; testar 31/01–28/02–31/03, bissexto, sete dias e datas inválidas.
- [x] 2.7 Implementar prévia, rascunho e confirmação com condições congeladas e idempotência; testar repetição e ausência de exposição do rascunho.
- [x] 2.8 Criar interfaces de clientes, simulação e contratos; verificar erros, troca de carteira e concordância entre prévia e confirmação e registrar evidências G1.

## 3. Recebimentos, encargos e contratos antigos — G2

- [x] 3.1 Implementar modelo de pagamentos e alocações com bloqueio, versão e operação idempotente na mesma transação; testar duas conexões, chave repetida e falha injetada.
- [x] 3.2 Implementar seleção de parcela, prioridade dos componentes, excedente entre parcelas e rejeição de valor acima do contrato; verificar exemplos e ausência de crédito.
- [x] 3.3 Implementar encargos recorrentes e escolhas de mora diária/30 dias com condições congeladas e histórico; testar meses de 28/29/30/31 dias e os dias 29/30/31/60.
- [x] 3.4 Fechar DT-01 quanto à composição da base e sequência de múltiplos pagamentos, inclusive consulta prévia; validar com o dono somente diferenças econômicas não decididas e testar antes de habilitar os casos afetados.
- [x] 3.5 Implementar pagamento antes da multa nova do dia e escolhas de dia do pagamento; testar R$ 1.000, pagamento R$ 400 e multa posterior R$ 12 e testar ocorrências/retries únicos.
- [x] 3.6 Implementar encargos avulsos, descontos e ajustes auditados; testar valor recebido separado do desconto e dispensa sem reaplicação indevida.
- [x] 3.7 Implementar entrada histórica manual, parcelas efetivas e correção de data estimada; testar falta de componente em rascunho, datas e ausência de caixa fictício.
- [x] 3.8 Implementar prévia e operação de prorrogação; testar impedimento por juros antigos não quitados e principal R$ 700 a 20% resultando em R$ 840.
- [x] 3.9 Implementar acordo com componentes transferidos separados; testar ausência de capitalização de juros/multas anteriores e de dupla cobrança ou desembolso fictício.
- [x] 3.10 Implementar perda integral, congelamento e recuperação; testar valor restante, prioridade, estorno e retorno à cobrança com escolha de encargos.
- [x] 3.11 Implementar cancelamento com compensação de principal e devolução por componente; testar R$ 1.000 entregues, R$ 200 amortizados e R$ 800 restantes, sem transferência fictícia.
- [x] 3.12 Fechar DT-02 com matriz de transições e correções de recebimento vinculadas; testar estorno após correção, acordo posterior, perda e ausência de duplo efeito, bloqueando casos ainda não resolvidos.
- [x] 3.13 Criar telas e fluxos de recebimento, encargos, histórico, acordo, perda e cancelamento; verificar prévia por componente, histórico, concorrência e evidências G2.

## 4. Central de parcelas e piloto — G3

- [x] 4.1 Criar central de parcelas com filtros, paginação, busca e estados simultâneos; testar parcela parcial e vencida e ordenação estável.
- [x] 4.2 Implementar ações em lote por contrato com chaves por item; testar falha parcial e retry sem duplicação.
- [x] 4.3 Criar ficha do cliente com contratos, parcelas, pagamentos, notas e anexos; testar escopo por carteira e histórico de correções.
- [x] 4.4 Validar restauração, permissões, dados aprovados e os recursos G2 habilitados antes de piloto autenticado de cobrança; documentar resultado e limites em evidências G3.

## 5. Indicadores e relatórios — G4

- [x] 5.1 Fechar DT-03 com exemplos de perdas, recuperações e correções retroativas e validar significado com o dono; registrar critérios por indicador antes de liberá-los.
- [x] 5.2 Implementar K1–K8 por carteira, qualidade e datas estimadas; comparar com recálculo independente, incluindo base incompleta e denominador zero.
- [x] 5.3 Implementar relatórios operacionais, distribuições e maiores devedores; testar que renegociação não cria concessão ou recebimento fictício.
- [x] 5.4 Criar exportação Excel/PDF com mesmos filtros e autorização; testar isolamento, mascaramento e proteção de texto contra fórmulas e registrar evidências G4.

## 6. Consolidação operacional — G5

- [x] 6.1 Validar cadastro manual de três parcelas com uma paga, data obrigatória, estimativa identificada e duplicidade; verificar saldos e ausência de importação obrigatória.
- [x] 6.2 Ensaiar backup, restauração e procedimento de recuperação de eventos posteriores com banco e anexos descartáveis; verificar integridade antes de liberar uso real.
- [x] 6.3 Registrar evidências G0–G5, limites de recursos e fechamento de DT-01–DT-07 conforme aplicável; verificar gates antes de habilitar liberação operacional.

## 7. Notificações posteriores — G6

- [x] 7.1 Definir provedor, remetente, horário e mensagens com o dono; registrar escolhas e testar conectividade de ambiente de teste antes de habilitar WhatsApp.
- [x] 7.2 Implementar configuração por carteira e fila durável somente nesta fase; testar destinatário próprio, regras e interrupção por flag.
- [x] 7.3 Implementar rechecagem de saldo, contato, perda e renegociação antes de enviar; testar que parcelas quitadas ou inelegíveis não geram envio.
- [x] 7.4 Implementar deduplicação, tentativas limitadas e tratamento de resultado incerto; testar concorrência, reinício e ausência de reenvio cego e registrar evidências G6.
