# Empréstimos — conclusão de prontidão

Data: 28/10/2026, após a decisão de aplicar o pagamento antes da multa do dia.

**Parecer: pronto para iniciar a implementação por etapas; ainda não pronto para considerar toda a especificação fechada ou liberar operação real.** Recomendo iniciar a fundação e os fluxos básicos de clientes, simulação e contratos, fechando as pendências abaixo antes das capacidades afetadas. Este parecer não inicia implementação nem muda decisões do dono.

## Base examinada

- [Plano v2.1](../../solicitacao-implementacao-emprestimos.md), SHA-256 `CAE6AFA81670A083057E7B40745203F82607808C4F6A3528372B1006EC56E8FC`.
- [Detalhamento R1–R8](REGRAS-E-CENARIOS-v2.1.md), SHA-256 `389588C93004AE9689324EDA7DBB07D285D265F2C801D8DFDEBD50F2D638150F`.
- Scripts documentais, relatórios e decisões anteriores da conversa; conferência atual da presença do serviço, manifests, gateway, idempotência de Projetos e permissão de diretório do Auth.
- Reexecução: **19 cenários documentais passaram e dez assertivas históricas passaram**. Não somar essas contagens como 29 funcionalidades validadas: são unidades de contagem diferentes e incluem contraprovas de hipóteses antigas.

`evo-loans-service` ainda não existe na árvore examinada. Nenhum teste de serviço, API, interface, concorrência real, migração ou restore foi executado nesta avaliação. Ausência dessas entregas é esperada antes da implementação; não é um motivo para impedir seu início.

## O que está suficientemente definido para começar

Independência do Financeiro; carteiras e clientes próprios; permissões operacionais iguais por carteira; CPF pendente permitido; empréstimos de dinheiro com ou sem juros; cadastro histórico manual sem importação; ordem dos pagamentos; proibição de excedente; desconto separado de recebimento; principal já recebido compensado no cancelamento; decisão por componente sobre devoluções; perda integral e recuperação pela ordem normal; preservação do histórico em correções; ajustes de centavos na última parcela.

As escolhas de cada acordo fazem parte do produto. Não é necessário perguntar antecipadamente ao dono qual será cada taxa, desconto ou devolução futura. A equipe deve construir prévias, campos explícitos e validações para essas escolhas.

## Quatro frentes a fechar antes da entrega completa

### P1 — Base e sequência de encargos (antes de G2)

R1 ainda não fecha a composição da base quando existem encargos avulsos. R2 ainda deixa aberta a interação entre pagamento no 30º dia, escolha de incluir esse dia e cálculo do bloco. R3 define pagamento antes da multa nova, mas não define toda a sequência com vários pagamentos na mesma data ou com uma multa já materializada antes de receber. Como RN-08 não recalcula encargos confirmados retroativamente, a ordem em que o operador abre ou confirma uma operação não pode definir a cobrança por acidente.

**Demonstração reproduzida nesta avaliação:** dívida de R$ 1.000, multa 2%, sem outros encargos. Um pagamento de R$ 400 seguido da multa deixa R$ 612. Sob uma interpretação sequencial possível, dois pagamentos de R$ 200 no mesmo dia deixam R$ 616: após o primeiro, principal R$ 800 e multa R$ 16; o segundo paga R$ 16 de multa e R$ 184 de principal. Não é prova de bug de serviço existente; demonstra que a política de sequência altera a cobrança e precisa ser explícita. Não selecionar uma política silenciosamente.

**Quem resolve:** equipe especifica a linha do tempo, ocorrência única, bases e arredondamento. O dono confirma somente as alternativas que mudam o que será cobrado, como composição da base e efeito de vários pagamentos no mesmo dia. Percentuais padrão continuam sendo configuração do usuário.

**O que não precisa virar nova pergunta:** sob a regra de percentual sobre saldo pós-pagamento, base zero produz multa zero. Isso é consequência matemática da decisão, salvo se houver uma multa já confirmada em outro evento. Esta última situação pertence à sequência acima. Distribuição entre parcelas já tem ordem aprovada e precisa ser implementada e testada, não decidida novamente.

### P2 — Ciclo completo de correções e cancelamentos (antes de G2)

O comportamento desejado está claro, mas faltam contratos de transição entre pagamento, correção, estorno, acordo, perda e cancelamento. O exemplo atual de correção cobre apenas uma diferença simples integralmente em principal.

É preciso definir, por exemplo, como estornar um recebimento que já foi corrigido: um registro original de R$ 150 corrigido para R$ 100 não pode produzir reversão líquida de R$ 150 e mais R$ 50 de efeito corretivo. Cancelamento que estorna registros mas mantém juros recebidos deve preservar a classificação desses juros nos relatórios. Correção sobre acordo quitado ou após recuperação de perda precisa produzir um estado válido, não apenas uma mensagem genérica de impedimento sem caminho de tratamento.

**Quem resolve:** inicialmente a equipe, com matriz de estados, eventos vinculados, efeitos líquidos, restrições e testes encadeados. Só escalar ao dono uma situação cuja solução exija nova decisão econômica, como conceder perdão, gerar crédito ou exigir uma devolução não autorizada. Não permitir que uma correção reintroduza o crédito excedente rejeitado pelo dono.

### P3 — Relatórios com perdas e correções retroativas (antes de G4)

R7 deixa pendentes os filtros de perda em K1/K3/K4/K7/K8. K6 fala de estorno pela data do estorno, mas a nova correção de valor e de data não tem regra completa de apresentação mensal. É necessário definir se uma correção registrada hoje sobre um recebimento antigo altera a série histórica ou aparece no mês da correção, mantendo rastreabilidade em ambos os casos.

**Quem resolve:** equipe propõe exemplos de antes/depois e uma tabela de inclusão por estado; dono valida o significado que espera ver no painel. Isso não impede construir cadastros e motor, mas impede chamar os indicadores de definitivos. Uma perda não pode parecer quitação, e uma correção não pode ser contada como nova transferência.

### P4 — Consolidação documental e contratos técnicos (por fase)

Ainda há resíduos que não exigem reabrir decisões:

- O modelo de `Alocação` permite saldo legado não classificado, enquanto o cadastro histórico exige manter rascunho quando houver componente de recebimento desconhecido. A exceção não deve autorizar recebimento confirmado sem composição nesta entrega.
- O parágrafo anterior às regras diz que o tratamento dos componentes desconhecidos continua pendente; a decisão já é deixar em rascunho.
- D3, D8 e D11 não resumem todas as últimas escolhas presentes nas regras; D8 coloca a decisão de rascunho na coluna de pendências. A tabela de decisões precisa refletir as regras atuais.
- Price e arredondamento têm proposta e exemplos, mas ainda precisam ser fixados num contrato de cálculo único, com limites e testes parametrizados. A decisão de ajustar a última parcela já foi dada; não há motivo para perguntar novamente sobre centavos.
- Bootstrap de administração, diretório Auth, migrações, idempotência transacional, isolamento entre carteiras e recuperação precisam de desenho e execução. São trabalho técnico previsto, não aprovação de produto ainda ausente.

Pontos de código reconfirmados: o callback de idempotência de Projetos continua sem argumento `tx` (`idempotency.service.ts:34,101`); a listagem do Auth exige `users.read` (`users_controller.rb:233`); o filtro Nginx ainda não tem `LOANS` (`nginx/Dockerfile:16`). O plano já reconhece esses limites; a implementação deve resolvê-los no novo módulo e nos pontos necessários da infraestrutura.

## Força e limites dos testes atuais

Os scripts são úteis para conferir os exemplos numéricos e tornar as decisões legíveis. Não exercitam todas as combinações. O caso Price usa a prestação R$ 340,02 já informada; os testes de cancelamento e correção validam diferenças aritméticas, não uma máquina de estados; o teste dos 30 dias usa contagem inteira, não datas civis reais. Duas contraprovas históricas tratam hipóteses descartadas. Portanto, “19 passaram” não demonstra que todo o motor foi validado.

Para os gates da implementação, os testes devem chamar o motor real e as rotas reais, cobrindo datas bissextas, mudanças de mês, pagamentos sucessivos, estorno após correção, falha entre gravações, dois operadores concorrentes, revogação de acesso, mesma chave reenviada, cruzamento de carteiras, backup e restauração. Não há necessidade de executar essas verificações contra dados de operação nesta fase de planejamento.

## Decisão de avanço

| Etapa | Parecer | Condição |
| --- | --- | --- |
| Fundação, serviço próprio, carteiras, Auth e migrações | Pode iniciar | Desenhar e testar autorização e transações no próprio módulo |
| Clientes, rascunhos, simulação e cronogramas | Pode iniciar | Consolidar cálculo e limites antes de aprovar G1 |
| Cobrança, correções e cancelamento completos | Desenvolvimento condicionado | Fechar P1/P2 antes de homologar G2 e permitir operações afetadas |
| Painel e relatórios definitivos | Ainda condicionado | Fechar P3 e reconciliar resultados em G4 |
| Uso com dados reais | Não liberado | Demonstrar implementação, testes e recuperação dos gates aplicáveis; piloto de G3 também exige controles comprovados |
| WhatsApp | Fase posterior | Provedor e operação definidos em G6, sem bloquear núcleo |

**Recomendação:** seguir para implementação incremental. Encerrar a rodada genérica de questionamento; manter uma lista curta de pendências econômicas de P1/P3 e resolver o desenho técnico durante a fase correspondente. Não declarar o plano 100% fechado nem prometer entrega completa sem essas condições. Nenhuma mudança no Financeiro é necessária.
