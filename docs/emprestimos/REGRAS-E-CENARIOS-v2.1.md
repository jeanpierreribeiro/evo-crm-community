# Empréstimos — detalhamento e validação de regras v2.1

Data: 28/10/2026. Complementa o [plano vigente](../../solicitacao-implementacao-emprestimos.md). As decisões do dono prevalecem; onde o texto usa “proposta técnica”, não há decisão adicional de produto. Os exemplos são sintéticos e taxas exemplificativas. Não existe integração de negócio com Financeiro, nem importação da planilha.

## 1. Condições de implementação

O módulo não foi implementado. Os exemplos executáveis são uma especificação independente, não testes do serviço, de banco ou de interface. Antes de G2, a implementação deve reproduzir os resultados aplicáveis em prévia, confirmação, consulta e exportação, sob concorrência real. Casos em aberto abaixo devem impedir a confirmação da operação afetada até que a regra seja definida; não substituir essas decisões por suposições. Esta condição não implica bloquear a fundação ou outras capacidades independentes.

### R1 — Juros proporcionais por mês civil

- Taxas configuradas por carteira são copiadas às condições do contrato; exemplos de 1% não são padrão aprovado. Data civil em São Paulo. Para intervalo computável, separar dias por mês e por mudança de base; em cada trecho calcular `saldo_base × taxa_mensal × dias_trecho / dias_no_mês`. Somar sem arredondar cada dia ou trecho e arredondar HALF_UP uma vez por parcela e período de cálculo; persistir detalhamento e versão do cálculo. Essa política de arredondamento é proposta técnica verificável, não alteração da taxa.
- O primeiro dia possível é o dia seguinte ao vencimento. A prévia do recebimento pergunta se inclui o dia de pagamento; incluir vem selecionado. A decisão e data efetiva ficam registradas. Em caso de pagamento parcial, especificar se a escolha vale para o cálculo daquela operação; não recalcular encargos já confirmados automaticamente. Diferença causada por registro retroativo deve ser visível e passível de ajuste justificado.
- Não incluir multa ou mora anteriores na base. Deve-se definir explicitamente no contrato de cálculo se “saldo da parcela” inclui todos os demais componentes originais e avulsos: o dono excluiu multa e juros de atraso anteriores, mas não selecionou a composição detalhada da base. Não inferir que é somente principal.
- Exemplo com base constante R$ 430,01 e 1%: 21 dias computáveis em mês de 28 dias = R$ 3,23; mês de 31 dias = R$ 2,91. R$ 1.000 com um dia em fevereiro de 28 e um em março de 31 = R$ 0,68, somando antes do arredondamento.

### R2 — Juros por blocos de 30 dias

- São devidos em blocos completos, aos 30, 60 dias e assim sucessivamente. Não cobrar um bloco por apenas 29 dias. Se houve alteração de saldo no bloco, exigir escolha explícita, sem opção pré-selecionada: (a) taxa integral sobre saldo ao final do bloco; ou (b) soma proporcional dos saldos ao tempo dentro dos 30 dias. Salvar opção por bloco, bases, dias, valor e justificativa quando necessária; confirmação deve verificar novamente versão e condições.
- Exemplo sem encargos anteriores: R$ 1.000 por 15 dias e R$ 600 por 15 dias, taxa 1%: opção (a) R$ 6,00; opção (b) R$ 8,00. Dias 29/30/31/60, quitação antes do fim do bloco e escolha de inclusão do dia do pagamento devem ser testados. A opção de dia do pagamento não autoriza inventar cobrança de fração antes de completar 30 dias; a sequência exata quando o pagamento ocorre no 30º dia permanece a definir.
- Um período concluído com escolha pendente não pode ser confirmado automaticamente por suposição. A operação que necessitar daquele valor deve apresentar as escolhas; mecanismos de consulta devem sinalizar pendência em vez de mostrar valor definitivo.

### R3 — Multa no mesmo dia do pagamento

Decisão do dono: primeiro aplicar o recebimento às obrigações existentes, pela ordem de RN-08; em seguida, calcular a multa daquele dia sobre o saldo-base após o pagamento. A multa nova permanece em aberto para pagamento posterior e não é abatida pelo mesmo recebimento. Multas anteriores continuam sendo abatidas primeiro.

Exemplo sem outros componentes: principal de R$ 1.000, recebimento de R$ 400 e multa de 2%. O pagamento reduz o saldo para R$ 600; a multa do dia é R$ 12 e permanece pendente. Total após as duas operações: R$ 612. Se o recebimento também pagar multa anterior, a parcela dirigida a essa multa não reduz o principal; a nova base deve refletir os valores efetivamente alocados.

A prévia deve exibir saldo e encargos anteriores, alocações, base após pagamento, multa nova e total restante. Confirmação deve recalcular sob bloqueio, registrar a ocorrência uma única vez e persistir pagamento, alocações, multa e auditoria na mesma transação. Repetições não podem cobrar duas multas. Decisões posteriores de dispensa preservam vínculo à ocorrência. Se o pagamento foi registrado retroativamente, não recalcular automaticamente encargos já confirmados.

**Limites ainda a definir e testar:** o tratamento quando o pagamento quita totalmente o saldo-base; se o limite de pagamento permitido naquele dia inclui ou não a multa que só será calculada depois; composição exata da base além da exclusão de multas e mora anteriores; e distribuição entre várias parcelas. Não inferir regra de produto para esses casos. O conflito circular analisado na revisão ocorreu sob a hipótese descartada de que a multa do dia fosse abatida do mesmo recebimento; não aplicá-la à decisão atual.
### R4 — Recebimento, prorrogação e ajustes

- Alocar por parcela: multa, juros contratuais, mora, encargo avulso e principal. A primeira parcela é selecionável; a sobra vai à mais antiga aberta no mesmo contrato. Soma das alocações = recebido, sem saldo negativo. Valor acima do total devido é rejeitado integralmente, sem crédito.
- Exemplo: R$ 700 de principal + R$ 140 de juros + R$ 20 de multa, recebimento R$ 140: R$ 20 abatidos da multa e R$ 120 dos juros. Restam R$ 20 de juros. Não prorrogar até quitar esses R$ 20; após sua quitação, se o principal for prorrogado a 20%, dever-se-ão R$ 840 no novo prazo, mais eventuais encargos elegíveis separados.
- A prorrogação de parcelados exige seleção explícita da base de novos juros e destino de cada vencimento, sem apagar pagamentos ou vencer parcelas duas vezes. Não confirmar se o plano resultante não for coerente ou se a base escolhida não estiver definida dentro das regras aprovadas. Não capitalizar encargos antigos em parcela única.
- O ajuste da dívida não representa pagamento nem devolução. Uma prévia mostra antes/depois por componente, efeitos em saldos, pagamento e indicadores, e impedimentos. Correções não podem reduzir saldo abaixo de quantias já alocadas nem criar saldo negativo. RN-04 deve permitir as operações corretivas específicas de RN-10, sem abrir edição genérica de contratos encerrados.

### R5 — Correção de recebimento e dependências

O valor efetivamente recebido pode divergir de um registro anterior. Original, alocações e correção permanecem identificáveis e auditáveis. Proposta técnica: lançamento de correção vinculado ao original, com diferenças assinadas por componente e por dinheiro recebido, data original, data de registro da correção, autor, motivo e chave idempotente. Não é recebimento ou devolução adicional.

Exemplo simples: registro original de R$ 150 integralmente em principal, quando foram recebidos R$ 100. Correção do recebido = −R$ 50; correção do principal abatido = −R$ 50; dívida aumenta R$ 50 uma vez; relatório mostra R$ 100 líquidos e história de R$ 150 mais correção de −R$ 50. Não aplicar um segundo ajuste de R$ 50 sobre o mesmo efeito. Qualquer ajuste adicional deve declarar componente e razão independente.

Quando houver acordo posterior, preservar o original e levar a diferença para o acordo atual, com vínculo ao recebimento de origem; quando houver pagamentos posteriores sem acordo, corrigir no contrato atual. Em ambos, corrigir também o total efetivamente recebido se estiver errado. A operação não prova transferência ou estorno bancário. Na prévia, mostrar diferenças, dependências, componentes e eventuais valores que já foram transferidos ou quitados. Se o resultado provocar saldo negativo, ultrapassar o saldo elegível, exigir devolução real, ou não houver composição suficiente para justificar a distribuição, bloquear e apresentar o impedimento; a decisão de tratamento posterior não foi dada.

Confirmação: autorização, `expectedVersion`, bloqueio e releitura do contrato atual e dos vínculos de origem em ordem estável, nova prévia, chave idempotente e gravação atômica de correção, alocações, ajuste econômico necessário e auditoria. Repetição com mesma chave não duplica o efeito; payload diferente retorna conflito. Não recalcular automaticamente multas e mora já confirmadas por registro retroativo. Testar alteração por outro operador entre prévia e confirmação, reenvio após timeout, recuperação de perda, pagamento posterior e acordo parcialmente quitado, inclusive impossibilidade de aplicar a correção sem violar saldo.

### R6 — Cancelamento com devolução e compensação

Contrato confirmado equivale a dinheiro entregue; cancelamento sem entrega real exige motivo e preserva histórico. Se houve entrega, o valor anteriormente alocado ao principal conta como devolvido; só falta a diferença. No exemplo de principal R$ 1.000 e R$ 200 já recebidos em principal, faltam R$ 800. Não tratar juros como principal devolvido.

Para juros, multa, mora e encargos avulsos recebidos, operador escolhe por componente manter, devolver tudo ou parte; devolução real é um fato separado, com data, valor, meio e comprovante quando disponível. Ex.: juros recebidos R$ 100, devolver R$ 40 => mantidos R$ 60. A prévia discrimina principal já compensado, principal a devolver, valores recebidos, estornos de registro e devoluções reais. Estorno necessário ao cancelamento não é prova de transferência de dinheiro. Não concluir cancelamento com devolução exigida sem o registro da devolução real; se acordada devolução parcial, validar limites e distinguir pendência de confirmação. Repetição não pode duplicar devolução ou compensação.

### R7 — Perda e recuperação

Marcar como perda o saldo total do contrato, não parte; congelar componentes e retirar o contrato das cobranças e notificações. Valores congelados permanecem separados por componente. Recebimento posterior segue RN-08 e reduz perda restante, sem juros ou multa novos enquanto na perda. Ex.: principal R$ 700 + juros R$ 140 + multa R$ 20 = perda R$ 860; recuperação R$ 140 abate R$ 20 multa e R$ 120 juros; perda restante R$ 720 (R$ 700 principal e R$ 20 juros).

Correção de marcação devolve a dívida restante à cobrança; o operador escolhe se o período congelado permanecerá sem encargos ou se os encargos serão calculados, com motivo e histórico. Uma escolha de calcular depende de demonstrar base, datas e mesmas regras do contrato; não ocultar encargos já confirmados. Estorno de recuperação restaura a perda por componente. Impedir notificações em perda mesmo quando exista saldo.

Painel deve distinguir saldo em cobrança e saldo em perda para não confundir dívida perdoada com recebida. K6 considera alocação de juros efetivamente recebida, incluindo recuperação, descontadas correções/estornos. K1/K3/K4/K7/K8 precisam explicitar filtros de perda e acompanhar totais separados; a forma final de apresentar resultados com perda continua a especificar e não pode ser deduzida como decisão do dono.

### R8 — Contratos antigos e Price

Contrato antigo tem todas as parcelas reais, com valores e vencimentos informados, preservando o cálculo como referência. Pagamento histórico exige valor e data, exata ou marcada como estimada. Quando componente do recebido não é identificado, não confirmar: manter rascunho. Desconto conhecido é registrado separado, por exemplo R$ 500 original, R$ 50 desconto e R$ 450 recebidos, sem criar recebimento de R$ 500. A descoberta de data exata permite correção auditada da data estimada, sem recálculo automático dos encargos posteriores. Entrada inteira deve ser idempotente e atômica; detecção de duplo cadastro manual requer aviso e conferência, não fusão automática.

Proposta técnica para Price: calcular prestação com precisão superior, juros de cada período sobre principal restante, arredondar em centavos por período, abater principal e fazer última prestação igual ao principal restante mais juros finais. R$ 1.000 a 1% por três períodos resulta R$ 340,02, R$ 340,02 e R$ 340,03, com principal final zero. A 0%, R$ 100 em três parcelas dá R$ 33,33, R$ 33,33 e R$ 33,34. Testar limites e impedir componentes negativos ou cronogramas que quitem principal antes da última parcela; não extrapolar esses exemplos para todas as taxas/quantidades. Contratos históricos negociados podem diferir do cronograma calculado, sem alterá-los silenciosamente.

## 2. Verificações reproduzíveis e gates

Executar `node docs/emprestimos/validar-regras-v21.mjs`: 19 cenários sintéticos independentes passaram na revisão. Executar também `node docs/emprestimos/validar-exemplos.mjs`: dez assertivas históricas passaram; seu exemplo de atraso usa mês fixo de 30 dias e não valida a regra atual de mês civil.

Os cenários cobrem ordem e seleção de parcelas, pagamento excedente, rolagem, dias reais, as duas opções de 30 dias, contraprova de multa no mesmo dia, cancelamento, desconto histórico, perda, correção e resíduos. A contagem de cenários não equivale a cobertura completa: eles usam funções de demonstração e valores definidos em memória, não o serviço futuro. Não verificam persistência, API, reabertura, auditoria real, autorização, concorrência ou cálculos já materializados.

Antes de G2, criar testes de integração de PostgreSQL descartável com duas conexões, falhas injetadas, idempotência e isolamento de carteiras; testar os casos R1–R8 em prévia/confirmar, correções em cadeia, dia de aplicação da multa e configuração congelada. As condições-limite de R3 permanecem bloqueadas até definição. Para G4, reconciliar relatórios com eventos efetivos, correções e perda em cada data; para G5, demonstrar restauração com fatos posteriores preservados. WhatsApp segue em G6 e não bloqueia o núcleo.
