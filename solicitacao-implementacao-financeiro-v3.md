# Planejamento v3 — Módulo Financeiro do jprOS

> **Versão:** 3.0 — 26/10/2026  
> **Objeto:** regras, dados, API, telas, controles e operação do módulo Financeiro.  
> **Status:** planejamento revisado, com decisões propostas explícitas e entregas verificáveis. Não representa implementação nem validação em produção.  
> **Precedência:** este documento substitui a v2 como planejamento do Financeiro. A v2 permanece como histórico; suas regras, seu schema e seu SQL não devem ser copiados sem adaptação.  
> **Limite:** nenhuma entrega deste plano altera funcionalidades de outros módulos ou executa uma revisão geral do ecossistema. Dependências de identidade, hospedagem e persistência são apenas condições de funcionamento do Financeiro.

## 1. Resultado da revisão socrática

Cada recomendação anterior foi confrontada com quatro perguntas: há um erro demonstrável? Qual regra está faltando? É necessária nesta entrega? Há uma solução menor que preserve a consistência?

| Recomendação questionada | Pergunta e contraponto | Decisão para a v3 |
|---|---|---|
| Separar sentido bancário e efeito no resultado | Uma taxa dentro de um recebimento prova que o modelo é inviável? Não: o tipo da conta poderia ser reinterpretado, mas a v2 não define isso. | **Reformular.** Manter movimento com componentes e explicitar a matriz de sinais. Não introduzir contabilidade de partidas dobradas. |
| Tratar impostos dentro de qualquer baixa | O núcleo precisa contemplar todas as retenções para funcionar? Não há caso operacional definido. | **Simplificar.** Imposto pago é título/saída própria. Retenção na fonte e compensação de tributos ficam para especificação posterior. Retirar TAX da fórmula de baixa do núcleo. |
| Permitir taxa no estorno de entrada | Basta copiar uma entrada com taxa e inverter a operação? A restrição da v2 impede essa cópia. | **Manter com solução menor.** Exceção estrita para reversão integral, derivada do original e validada pelo serviço. |
| Estornar individualmente qualquer item de um lote | Uma baixa de R$ 100 pode reverter o movimento compartilhado de R$ 300? Não. Precisamos de estorno parcial já? Não necessariamente. | **Manter o problema, reduzir o escopo.** Estorno integral da operação de baixa no núcleo. |
| Distinguir correção e devolução | Toda devolução implica apagar o recebimento ou reabrir o título? Não. | **Manter a distinção.** Correção usa estorno; devolução real usa novo movimento. Automatização de devoluções fica para evolução. |
| Versionar todo cadastro | É indispensável manter uma tabela de versões de cada conta? Não, se os atributos que alteram relatórios forem imutáveis após uso. | **Descartar a generalização.** Congelar atributos estruturais usados; auditar alterações descritivas. |
| Criar rascunhos para todos os títulos | A diferença entre previsão e obrigação exige mais um estado persistente? Não, se apenas obrigações confirmadas forem cadastradas e a interface exigir confirmação. | **Não exigir DRAFT.** Título salvo é obrigação confirmada. Orçamento e hipótese comercial não viram título automaticamente. |
| Proteger o fechamento além dos movimentos | Cancelar um título antigo ou trocar sua classificação pode modificar o DRE fechado? Sim. | **Manter.** Validar todas as datas e dependências que alteram os relatórios. |
| Separar competência e vencimento | Uma venda parcelada e um serviço mensal têm a mesma distribuição econômica? Não. | **Manter.** Escolha explícita da competência na geração; nenhuma inferência automática pelo vencimento. |
| Incluir renegociação na primeira entrega | É necessário construir esse fluxo antes de registrar pagamentos simples? Não. | **Adiar.** Impedir que cancelamento e recriação sejam apresentados como renegociação segura. |
| Limitar conciliação dos dois lados | A mesma transação pode ser utilizada em excesso se só o extrato for limitado? Sim. | **Manter.** Limites por entrada e por movimento, sob concorrência. |
| Substituir a deduplicação OFX | Um hash sem identificador bancário consegue distinguir com certeza dois débitos legítimos iguais? Não. | **Reformular.** Identidade forte quando disponível; suspeita revisável nos casos ambíguos. |
| Corrigir Prisma e SQL | Os nomes de coluna da v2 correspondem aos campos sem @map? Não. | **Manter.** Nomes físicos explícitos e validação da migração gerada. |
| Acrescentar todas as constraints possíveis | CHECK comum garante soma de linhas relacionadas? Não. | **Reformular.** Constraints locais no banco; invariantes entre entidades no serviço transacional, com testes. |
| Proteger dados e anexos | Proteger só arquivos protege o banco? Não. O Financeiro controla a remoção global dos volumes? Não. | **Manter a exigência local.** Backup/restauração do Financeiro e requisito explícito de persistência; nenhuma promessa de isolamento contra administração externa. |
| Redesenhar autenticação da plataforma | Isso é necessário para planejar o Financeiro? Não está no escopo solicitado. | **Excluir o redesenho.** Definir somente o consumo da identidade e a autorização exigida pelo Financeiro. |
| Exigir revogação instantânea em qualquer cache | O Financeiro pode garantir o comportamento interno do provedor? Não. | **Reformular.** Não adicionar cache local de autorização no núcleo; testar o contrato real e documentar o limite do provedor. |
| Automatizar juros e multa completos | A fórmula sobre todo o saldo a cada baixa pode recobrar encargos? Sim. É necessário um motor contratual amplo? Não. | **Simplificar.** Sugestão por parcela de principal liquidada, taxas explícitas e confirmação do operador. |
| Fixar ausência absoluta de lacunas na numeração | Um cancelamento precisa remover ou reutilizar número? Não. | **Reformular.** Unicidade, sequência transacional, rastreabilidade e não reutilização; cancelados permanecem. |
| Rejeitar uma de quaisquer duas baixas concorrentes | Duas baixas de R$ 400 e R$ 600 sobre R$ 1.000 devem falhar? Não. | **Corrigir o teste.** Rejeitar apenas a operação que viola o saldo disponível. |
| “Exatamente um log por escrita” | Uma baixa em lote pode produzir vários registros necessários? Sim. | **Reformular.** Um evento de negócio correlaciona os registros de auditoria das entidades afetadas. |
| Entregar toda a F1 de uma vez | A divisão reduz o escopo funcional final? Não; permite validar o núcleo antes de automatizar. | **Manter a divisão.** Entregas verticais com critérios objetivos, sem antecipar funcionalidades opcionais. |

## 2. Objetivo e limites do produto

O Financeiro controla uma única empresa, inicialmente em BRL. Deve permitir saber quanto existe em cada conta, o que falta pagar/receber, quais movimentos explicam o saldo e qual resultado foi reconhecido em cada competência.

### 2.1 Núcleo planejado

- Pessoas, dados bancários/PIX, contas financeiras, plano de contas, centros de custo, formas de pagamento e configuração da empresa.
- Entradas, saídas, rateio de movimentos avulsos e transferências entre contas.
- Títulos a pagar/receber, parcelamento, baixas parciais, baixas em lote e estorno integral de uma operação.
- Recibos simples, anexos privados e histórico de operações.
- Extrato, saldos em data, DRE gerencial por competência e por caixa, aging e projeção de caixa.
- Fechamento/reabertura, auditoria, autorização, idempotência e prevenção de conflitos.
- Importação OFX e conciliação assistida N:N.
- Recorrências de obrigações confirmadas.

### 2.2 Evoluções financeiras posteriores

CSV de extrato; PDF de recibo gerado no servidor; exportações XLSX/PDF; orçamento; razão analítico; análise por pessoa; rateio de títulos; fatura de cartão; renegociação; devolução assistida; adiantamentos/créditos; retenções tributárias; multi-moeda.

Esses itens não recebem schema especulativo nem endpoints incompletos no núcleo. Cada um exige sua própria regra e aceite quando entrar em desenvolvimento. O campo currency = BRL fica desde o início, sem afirmar que isso resolve a modelagem futura de câmbio.

### 2.3 Restrições explícitas

- Gestão financeira gerencial; sem escrituração contábil completa, apuração tributária, documento fiscal ou folha.
- Sem execução de pagamentos pelo banco. Registrar uma baixa informa um pagamento/recebimento já ocorrido.
- Sem automações ou integrações com outros módulos neste plano.
- Contas operacionais do núcleo: corrente, poupança, caixa e conta de investimento com movimentação registrada manualmente. Sem valorização automática de aplicações.
- Conta de cartão de crédito não pode operar antes da entrega de faturas. O cadastro de “Cartão” como forma de pagamento não cria uma conta de cartão.
- Movimentos realizados não podem ter data futura. Obrigações futuras são títulos.

## 3. Decisões estruturais

| Tema | Decisão |
|---|---|
| Serviço | evo-finance-service, TypeScript, Fastify 5 e Prisma 6, mantendo a escolha da v2. Fixar versões compatíveis no lockfile ao implementar. |
| Persistência | PostgreSQL, schema finance, migrações versionadas. Credenciais de migração separadas da credencial de execução. |
| Interface | Telas do Financeiro na interface existente: menu principal e drawer secundário. Mudanças restritas às necessidades dessas telas. |
| Dinheiro | Decimal(14,2) para valores monetários; cálculos intermediários em Decimal com precisão suficiente; API em strings decimais. |
| Arredondamento | ROUND_HALF_UP a duas casas na conclusão de cada componente. Somar componentes já arredondados; a distribuição de centavos fecha no total original. |
| Datas | Datas de negócio em YYYY-MM-DD / PostgreSQL DATE. Instantes em UTC. “Hoje” calculado em America/Sao_Paulo no serviço. |
| Fuso | Fixo no núcleo; não oferecer troca de fuso depois do início da operação. Não usar now() do banco como fonte implícita de uma data de negócio. |
| Valores com sinal | Componentes e amortizações são magnitudes positivas. Saldo inicial, saldo de extrato e valor da entrada OFX podem ser negativos. |
| Histórico | Movimentos confirmados são imutáveis nos campos financeiros. Correções usam estorno. Cadastros utilizados são desativados, não removidos. |
| DRE | Consulta derivada de títulos e linhas, com regras explícitas. Não criar livro contábil geral ou event sourcing para resolver este núcleo. |
| Relatórios | Uma única camada de cálculo de saldos, baixas e resultado, reutilizada pelos relatórios e dashboard. |

## 4. Regras financeiras consolidadas

### FIN-01 — Separar dinheiro movimentado e efeito econômico

Transaction.operation determina entrada/saída do banco. ChartOfAccount.resultNature determina o efeito normal da classificação: INCREASE_RESULT, DECREASE_RESULT ou NO_RESULT. DreGroup determina a seção do relatório.

O antigo ChartOfAccount.type CREDIT/DEBIT é substituído por resultNature; não deve ser interpretado como restrição direta sobre a transação bancária inteira.

| Operação normal | Componente | Efeito normal no resultado | Classificação típica |
|---|---|---|---|
| Entrada | PRINCIPAL | Aumenta, ou nenhum para movimentação patrimonial | Receita ou NOT_IN_DRE |
| Entrada | INTEREST / FINE | Aumenta | Receita financeira |
| Entrada | DISCOUNT | Diminui | Dedução de receita |
| Entrada | FEE | Diminui | Dedução ou despesa, conforme política configurada |
| Saída | PRINCIPAL | Diminui, ou nenhum para movimentação patrimonial | Custo, despesa, dedução ou NOT_IN_DRE |
| Saída | INTEREST / FINE | Diminui | Despesa financeira |
| Saída | DISCOUNT | Aumenta | Desconto obtido |
| Saída normal | FEE | Não permitido | Registrar tarifa em saída própria |
| Transferência | PRINCIPAL | Nenhum | NOT_IN_DRE |
| Estorno de correção | Cópia dos componentes originais | Inverso do efeito original | Mesmas classificações do original |

A classificação deve ser analítica e ativa para novos registros normais. O estorno utiliza a classificação original mesmo que ela tenha sido desativada.

Uma conta de recuperação pode aumentar o resultado dentro de um grupo normalmente de despesa, desde que sua natureza seja explícita. O relatório soma contribuições com sinal; não aplica uma segunda inversão ao somar grupos de despesa.

NO_RESULT exige dreGroup = NOT_IN_DRE e vice-versa. Os demais grupos exigem natureza econômica explícita; a validação considera componente e operação conforme a matriz.

AccountMapping resolve juros, multa, desconto e taxa por operação. Mudanças no mapeamento afetam apenas novos registros.

### FIN-02 — Fórmulas e limites

- grossAmount = soma(PRINCIPAL + INTEREST + FINE) − soma(DISCOUNT).
- feeAmount = soma(FEE).
- netAmount = grossAmount − feeAmount.
- Para movimento bancário normal: grossAmount > 0 e netAmount > 0; feeAmount >= 0.
- Componentes efetivamente gravados têm amount > 0; componentes zerados são omitidos.
- Desconto não excede principal + juros + multa.
- Transação com líquido zero é rejeitada no núcleo: não representa movimento bancário. Compensações e liquidações sem caixa precisam de fluxo posterior próprio.
- Tarifas bancárias e impostos pagos são saídas próprias com PRINCIPAL classificado adequadamente.
- TAX não integra LineKind do núcleo. Retenção na fonte não pode ser disfarçada como desconto ou taxa.
- O serviço recalcula totais; valores calculados enviados pelo cliente não são autoridade.

### FIN-03 — Saldo e início de operação

Saldo em D = saldo inicial + entradas líquidas − saídas líquidas, desde openingDate até D, inclusive.

openingBalance representa o saldo imediatamente anterior aos movimentos de openingDate. Antes dessa data, o relatório informa “histórico indisponível”; não replica o saldo inicial para datas anteriores.

openingBalance e openingDate ficam imutáveis depois do primeiro movimento ou do primeiro fechamento que os abranja. Saldo inicial negativo é permitido. Ajuste posterior exige movimento identificado, motivo e classificação definida; o sistema não cria ajuste automático para esconder divergência.

Conta inativa permanece nos relatórios históricos e no total patrimonial. isDashboard serve como filtro de apresentação e não exclui valores silenciosamente de totais gerais.

### FIN-04 — Título e competência

Título salvo representa obrigação confirmada, com tipo, valor, competência, vencimento e conta analítica obrigatórios. Pessoa, conta bancária prevista e centro de custo podem ser opcionais, mas a ausência deve aparecer na interface.

Usar settledPrincipal para o principal liquidado e SchedulePayment.principalSettled para cada amortização. O nome distingue principal liquidado do dinheiro efetivamente pago: liquidar R$ 1.000 com desconto de R$ 100 consome R$ 1.000 do título e movimenta R$ 900 antes de taxas.

- remainingPrincipal = originalAmount − settledPrincipal.
- PENDING: nada liquidado; PARTIALLY_PAID: saldo entre zero e original; PAID: saldo zero.
- CANCELLED é uma transição explícita, preservada ao recalcular status.
- Vencido é derivado do saldo positivo, vencimento e data de referência.
- Título não pode ser cancelado com baixa ativa.
- Campos financeiros de título sem baixa podem ser corrigidos, com version e auditoria, somente se os períodos afetados estiverem abertos.
- Depois de uma baixa, valor original, tipo, competência e classificação não podem ser alterados diretamente. Corrigir exige tratar a operação de baixa primeiro.
- Cancelar não pode apagar resultado de período fechado.

Não criar rascunho persistente no núcleo. A tela informa o efeito no caixa previsto e na competência antes de confirmar. Se a obrigação ainda não existe, ela não deve ser salva como título.

### FIN-05 — Parcelamento

Manter o cálculo da v2: divisão truncada em centavos, resto na última parcela e datas mensais calculadas sempre a partir da data base.

Validar número de parcelas positivo e impedir parcelas de valor zero. Intervalo em dias fixos é opção explícita.

A geração exige escolha de competência:

1. **Única:** todas as parcelas compartilham a competência informada.
2. **Por período:** cada parcela recebe uma competência explicitamente apresentada na prévia.

Vencimento e competência aparecem em colunas separadas. A aplicação não decide se a operação corresponde a entrega única ou prestação continuada.

installmentGroupId e installmentNumber identificam cada parcela; unicidade no banco impede repetição dentro do grupo.

### FIN-06 — Baixa individual e em lote

Criar Settlement como identidade da operação de baixa, com um Transaction e um ou mais SchedulePayment.

No núcleo, um lote exige mesmo tipo de título, mesma pessoa (inclusive ausência uniforme), conta bancária, data de pagamento e forma de pagamento. Agrupamentos heterogêneos são recusados.

Cada pagamento contém principal liquidado, juros, multa, desconto e taxa alocada:

- totalPaid = principalSettled + interestAmount + fineAmount − discountAmount.
- Soma(totalPaid) dos pagamentos = grossAmount da transação.
- Soma(feeAmount) dos pagamentos = feeAmount da transação.
- principalSettled > 0 e <= saldo disponível do título.
- Em título a pagar, feeAmount = 0.
- Todos os componentes de cada pagamento originam linhas vinculadas ao mesmo SchedulePayment, inclusive juros, descontos e taxas.

O rateio automático de uma taxa de lote é proporcional a totalPaid: truncar as parcelas em centavos e distribuir o resíduo pelos maiores restos, com desempate por ID. A interface apresenta o rateio antes de confirmar.

accountId, paidAt e paymentMethodId pertencem à operação de baixa; não manter cópias editáveis divergentes em cada pagamento.

### FIN-07 — Juros, multa e descontos

O módulo sugere encargos; o operador confirma o pagamento efetivamente ocorrido. Nenhuma configuração do software declara que um encargo é juridicamente devido.

Proposta simples para o núcleo:

- Juros simples sugeridos = principalSettled × (taxa mensal / 100 / 30) × dias de atraso.
- Multa sugerida = principalSettled × (taxa de multa / 100), se houver atraso.
- Dias de atraso = max(0, paidAt − dueDate).
- Cada fração de principal liquidada recebe seus próprios encargos. Não recalcular encargos sobre todo o saldo em toda baixa.
- Alteração manual em relação à sugestão exige motivo.
- Persistir taxas utilizadas, dias de atraso e valores confirmados na baixa; alteração de configuração não recalcula o passado.
- Taxas iniciam desativadas no primeiro uso e são configuradas explicitamente. Os 2% e 1% a.m. da v2 podem ser sugestões de configuração, não valores presumidos em títulos existentes.

Exemplo com taxa mensal de 1% e multa de 2%: R$ 400 liquidados com 10 dias de atraso geram sugestão de R$ 1,33 de juros e R$ 8 de multa; R$ 600 restantes com 20 dias geram R$ 4 e R$ 12. Total de multa = R$ 20; não se aplica novamente sobre os R$ 1.000.

Essa política não atende cobrança separada de encargos, juros compostos, capitalização ou contratos com cálculo específico. Tais situações exigem regra própria.

### FIN-08 — Estorno de correção

Estorno corrige um registro financeiro incorreto. Não significa, por si só, devolução de dinheiro ao cliente.

- Reverter integralmente o Settlement e todos os pagamentos de seu lote.
- Copiar valores, classificações e vínculos de componentes; inverter operação bancária e contribuição no resultado.
- Para estorno de entrada com taxa, permitir DEBIT com feeAmount > 0 exclusivamente quando for cópia integral validada da transação original. gross − fee continua igual ao líquido que deve ser revertido.
- reversalOfId é único: um estorno integral por transação. Não permitir estorno de estorno; uma nova operação correta deve ser registrada separadamente.
- Recalcular saldos dos títulos e cancelar recibos ativos da operação, com motivo e auditoria, na mesma transação.
- Movimento com vínculo de conciliação ativo, mesmo parcial, exige desconciliação antes da correção.
- Original e estorno permanecem nos relatórios, cada um em sua data. Não excluir o original por ter sido estornado depois.
- O estorno informa transactionDate e competenceDate por componente. Todas as datas de impacto devem estar abertas; nunca copiar uma competência fechada silenciosamente.
- A data bancária do estorno não pode anteceder a do original. Para componentes de competência aberta, a prévia propõe a competência original; para competência fechada, exige uma nova competência aberta, posterior ao fechamento. Não antecipar a reversão a uma competência anterior à original.
- Quando o original estiver em período fechado, admitir correção em período aberto se não exigir desfazer vínculos fechados. Se exigir, a reabertura deve ocorrer antes.

Uma baixa revertida em dezembro ainda conta como ativa na posição histórica de novembro. Usar a data financeira do estorno para esse cálculo, não apenas reversedAt, que registra o instante operacional.

### FIN-09 — Transferências e devoluções reais

Transferência cria um débito e um crédito de igual líquido, em contas diferentes, no mesmo commit. Não há taxa embutida nem resultado econômico.

Para estornar, criar um novo grupo de transferência vinculado ao original. Cada grupo continua com exatamente uma ponta de cada operação; UNIQUE(groupId, operation) não substitui a validação de existência das duas pontas.

Uma ponta parcialmente conciliada também exige desconciliação antes do estorno do par. Não permitir estornar ou editar uma ponta isoladamente.

Devolução real é registrada como nova entrada/saída avulsa, com classificação compatível e referência explicativa ao documento de origem. Não remove a conciliação do recebimento/pagamento original e não reabre automaticamente títulos. No núcleo não há cálculo automático de limite devolvível, rateio de componentes ou recomposição da obrigação; a tela não deve apresentar esse registro manual como um fluxo assistido de devolução.

### FIN-10 — DRE gerencial

**Competência:**

1. Principal de títulos não cancelados, em sua competenceDate, independentemente de pagamento.
2. Componentes não principais das baixas, em sua própria competenceDate.
3. Linhas de movimentos avulsos, em sua competenceDate.
4. Excluir principal vinculado a pagamento de título, tanto no original quanto no estorno, para não reconhecer duas vezes o mesmo principal.
5. Excluir transferências e classificações NO_RESULT.

**Caixa:** linhas de movimentos pela transactionDate, incluindo principal de baixas; excluir transferências e NO_RESULT.

Cada estorno contribui com sinal oposto ao original. Pares na mesma janela se anulam por soma. Pares em janelas distintas afetam cada janela corretamente; não existe filtro global de “excluir estornados”.

Somar grupos com as contribuições já sinalizadas. Apresentar despesas/deduções de maneira legível sem inverter novamente o total.

O relatório permite detalhar título, movimento e componente. DRE não precisa ser igual à variação do saldo: transferências e operações patrimoniais explicam parte da diferença.

Totais e detalhamento de um mesmo relatório usam um único snapshot consistente do banco, por consulta única ou transação de leitura apropriada. Uma baixa concorrente não pode aparecer no total e faltar nas linhas da mesma resposta.

resultNature, dreGroup, code e posição estrutural de contas do plano já utilizadas ficam imutáveis. Para reorganizar economicamente, criar outra conta e desativar a anterior. Descrições podem ser corrigidas com auditoria; não se promete identidade textual de relatórios antigos.

Hierarquias de plano de contas e centros de custo não podem conter ciclos. Mudança de agrupamento de centros já usados não pode reclassificar resultados históricos; criar novo centro para nova estrutura.

### FIN-11 — Fechamento

Manter FinanceState singleton com closedThrough e version, além de eventos de fechamento/reabertura.

Fechamento protege:

- Datas bancárias dos movimentos e das baixas.
- Competências dos títulos e das linhas.
- Cancelamento, valor, classificação e exclusão que alterariam período fechado.
- Datas antigas e novas de qualquer mudança: mover algo para fora de um período fechado também é bloqueado.
- Saldo/data inicial de contas abrangidas.
- Conciliações cujos movimentos ou entradas de extrato estejam em período fechado.

Leitura, anexação de comprovante e correção de descrição sem efeito numérico continuam possíveis, com auditoria. Isso não autoriza trocar documentos já existentes sem preservar a versão anterior.

O fechamento deve mostrar títulos pendentes, divergências conhecidas e entradas não conciliadas. Não exigir que tudo esteja pago para fechar: títulos em aberto são parte legítima do período. Pendências de conciliação exigem ciência e motivo, não ajuste artificial de saldo.

Antes de qualquer escrita que afete saldos/resultado/conciliação, adquirir bloqueio compartilhado na linha FinanceState e validar o limite. Fechar ou reabrir adquire bloqueio exclusivo nessa linha. Depois, bloquear as entidades afetadas em ordem estável. Assim o fechamento não ultrapassa uma escrita ainda em andamento.

Fechar avança o limite; reabrir remove o fechamento ativo mais recente, voltando ao limite anterior. Para reabrir um mês antigo, reabrir os posteriores em ordem. Exigir permissão, motivo e auditoria.

### FIN-12 — Conciliação N:N

Cada vínculo ativo tem amount > 0. Invariantes:

- Soma dos vínculos ativos de uma entrada <= abs(entry.amount).
- Soma dos vínculos ativos de um movimento <= transaction.netAmount.
- Mesma conta, moeda e sentido bancário.
- Nenhum vínculo com movimento excluído/inválido, lote desfeito ou entrada ignorada.
- Ignorar entrada exige ausência de vínculos ativos.
- Vínculos com undoneAt não entram nas somas.
- Bloquear entradas e movimentos envolvidos antes de validar capacidades e gravar.

O estado de conciliação dos dois lados é derivado dos vínculos: zero, parcial ou completo. Parcial não deve aparecer como ausência de conciliação.

Não combinar débitos e créditos para compensar um extrato líquido no núcleo. N:N resolve divisão/agregação de valores do mesmo sentido.

Sugestões consideram líquido ainda não conciliado do movimento ou saldo ainda não liquidado do título, com taxa estimada proporcional quando aplicável. A janela padrão é de três dias; sugestões não executam ações automaticamente.

Conciliar com título cria baixa e vínculo no mesmo commit. Desfazer o vínculo não estorna a baixa: apenas retira a declaração de correspondência com o banco.

### FIN-13 — Importação OFX e identidade

- Aceitar OFX 1.x/SGML e 2.x/XML; codificação tratada pelo cabeçalho e fallback documentado. Windows-1252 não deve ser tratado como sinônimo perfeito de ISO-8859-1.
- Validar identificação da conta e moeda. Primeiro vínculo de conta OFX exige confirmação explícita.
- XML sem entidades externas; limites de bytes, quantidade de entradas e custo de parsing. OFX é validado pelo parser, não apenas por MIME ou magic bytes.
- SHA-256 identifica o mesmo arquivo na mesma conta.
- FITID é identificador forte dentro da conta quando não há conflito de conteúdo. FITID já conhecido com conteúdo divergente gera conflito revisável.
- Sem FITID confiável, fingerprint de data/valor/texto auxilia a revisão, mas não prova duplicidade. Usar identidade própria da linha importada e marcar candidatos suspeitos.
- Não descartar automaticamente duas transações iguais apenas por hash, ordem ou ordinal diário.
- Entradas suspeitas ficam pendentes de decisão: manter como distinta ou associar ao registro já existente. A decisão é auditada.
- LEDGERBAL é comparado na data informada com a cobertura disponível do histórico. Divergência produz aviso, nunca movimento de ajuste automático.

Importação desfeita preserva arquivo, linhas e decisões para auditoria, deixando suas entradas inativas. Só pode ser desfeita sem qualquer vínculo ativo, inclusive parcial, e respeitando fechamento. Reativar o mesmo arquivo é uma ação explícita que reutiliza identidades; não duplicar o lote.

### FIN-14 — Recorrências

RecurringSeries representa obrigação recorrente confirmada. Pré-gerar até 12 meses à frente não autoriza transformar propostas incertas em receita.

- Frequências semanal, mensal e anual; intervalo positivo.
- Regra explícita para competência e vencimento; mês curto usa o último dia quando necessário, sempre a partir da âncora.
- UNIQUE(seriesId, occurrenceIndex); o índice identifica a ocorrência e não muda quando seu vencimento é editado.
- Job diário e execução manual usam o mesmo caminho idempotente, com bloqueio da série.
- generatedUntil é marcador de progresso, não garantia isolada contra duplicidade.
- Após interrupção, retomar a partir das ocorrências existentes; nunca recriar as já geradas.
- Uma alteração de valor/classificação pode afetar uma ocorrência ou ocorrências futuras elegíveis. Prévia informa quantas serão alteradas e quais foram bloqueadas por baixa/fechamento.
- Não alterar títulos com baixa nem competência fechada.
- Mudança estrutural de frequência/âncora encerra a série anterior e cria outra com fronteira explícita, impedindo sobreposição acidental.
- Pausar impede novas gerações; títulos existentes permanecem. Retomar começa na data escolhida, sem cobrança automática do intervalo pausado.
- Encerrar define última ocorrência e cancela apenas futuras sem baixa e sem competência fechada, após apresentar o efeito. Obrigações vencidas permanecem.

### FIN-15 — Recibos e anexos

Recibo é emitido por SchedulePayment ou por transação avulsa elegível, com uma única origem. Não emitir simultaneamente recibo da transação de uma baixa e dos pagamentos que a compõem.

- No núcleo, recibo de baixa usa totalPaid, valor desembolsado pelo pagador antes da taxa do recebedor.
- Recibo avulso usa grossAmount. Transferência e estorno não originam recibo normal.
- Uma emissão ativa por origem. Reimpressão recupera o mesmo recibo.
- Snapshot de empresa, pessoa, valor, componentes, texto e identificação da origem é imutável.
- Número único por prefixo/ano/sequência, com incremento transacional e ano no fuso de referência.
- Cancelamento exige motivo e não obriga reemissão. Reemissão explícita ganha novo número e aponta para o anterior.
- Estorno da baixa cancela os recibos ativos relacionados no mesmo commit.
- HTML imprimível A4 no núcleo; documento apresentado como recibo simples, sem emissão fiscal.

Anexos têm exatamente um proprietário: movimento, título ou pessoa, com FK e validação de coerência. Substituição cria outro anexo e preserva o histórico do anterior.

PDF, PNG e JPEG são os tipos de anexo inicial. OFX pertence ao fluxo de importação. CSV/XLSX só entram quando suas funções forem entregues.

Armazenar fora de diretório público com chave opaca. Download exige autorização e auditoria; arquivos sensíveis não são servidos por rota estática. Manter limite configurável de 25 MB e tratamento seguro de nomes.

### FIN-16 — Projeção, posição histórica e dashboard

Projeção parte do saldo real na data de referência e adiciona os saldos de títulos ainda abertos, sem duplicar valores já liquidados.

- Data prevista = expectedSettlementDate, quando informada; caso contrário, dueDate.
- Recebível projetado líquido = remainingPrincipal − taxa restante estimada.
- Taxa restante estimada = arredondar(expectedFeeAmount × remainingPrincipal / originalAmount). Trata-se de estimativa, não obrigação já incorrida.
- expectedFeeAmount deve estar entre zero e originalAmount e só se aplica a recebíveis.
- Títulos vencidos sem data futura de previsão ficam em bloco destacado “em atraso, sem data prevista”. Não são redistribuídos silenciosamente no calendário.
- Títulos sem conta prevista entram na visão consolidada em “sem conta definida”; não são atribuídos a uma conta arbitrária.
- Não projetar automaticamente juros/multa de títulos abertos.
- Cancelados e integralmente liquidados ficam fora da projeção.

Posição histórica de títulos usa pagamentos efetivos até a data e os estornos efetivos até a mesma data. O cache settledPrincipal não substitui esse cálculo.

Dashboard: saldos, entradas/saídas realizadas, resultado de caixa, títulos hoje/próximos sete dias e aging do saldo em aberto. Faixas sem sobreposição: 1–30, 31–60, 61–90 e acima de 90 dias.

Entradas/saídas realizadas e resultado econômico de caixa têm rótulos distintos. Movimentos patrimoniais alteram caixa sem compor DRE.

## 5. Modelo de dados mínimo

Este é um contrato de responsabilidades e invariantes. O schema executável será gerado na primeira entrega; não duplicar aqui centenas de linhas de Prisma ainda não validadas.

| Entidade | Responsabilidade e restrições principais |
|---|---|
| CompanySettings | Dados da empresa, moeda BRL, parâmetros de encargos/recibos; singleton real e version. |
| FinanceState | Singleton de fechamento; closedThrough e version; linha existente antes de aceitar escritas. |
| BankAccount | Saldo/data inicial, moeda, categoria, identificação OFX, ativa e version. |
| Person | Pessoa e dados financeiros; documento normalizado, exclusão lógica quando elegível, version. |
| ChartOfAccount | Hierarquia, resultNature, dreGroup, analítica/ativa; estrutura congelada após utilização. |
| CostCenter / PaymentMethod | Classificação gerencial e meio de pagamento; inativação e version. |
| AccountMapping | Chave de componente/operação para conta analítica; version; mudança só para novos registros. |
| Schedule | Obrigação, competência, vencimento, previsão, principal original/liquidado, estado, parcela/série e version. |
| Settlement | Identidade da operação; conta, data, meio, estado e referência única à transação. Unidade de estorno do lote. |
| SchedulePayment | Título + Settlement, principal e componentes, dados do cálculo; UNIQUE(settlementId, scheduleId). |
| Transaction | Movimento confirmado, valores, operação, origem, data, referência única de reversão ou grupo de transferência. |
| TransactionLine | Classificação, componente, valor e competência; schedulePaymentId opcional. O título é derivado desse pagamento. |
| TransferGroup | Identidade do par e referência ao grupo revertido, quando houver. |
| RecurringSeries | Regra, âncora, competência, estado, progresso e version; ocorrências únicas. |
| ImportBatch / BankStatementEntry | Arquivo, linhas, identidade, decisões de duplicidade e ciclo de importação. |
| ReconciliationMatch | Entrada + movimento + valor; histórico de desfazimento; somente vínculos ativos consomem capacidade. |
| Receipt / ReceiptSequence | Snapshot e numeração transacional; unicidade de emissão ativa por origem. |
| Attachment | Proprietário único, metadados e chave de armazenamento; referência real à pessoa quando aplicável. |
| AuditEvent / AuditLog | Evento de negócio e registros das entidades, correlacionados por operationId/requestId; ator USER ou SYSTEM. |
| PeriodClosure | Eventos de fechamento/reabertura e fronteiras anterior/nova. |
| IdempotencyRecord | Ator + rota canônica + chave, hash da entrada, resultado e IDs produzidos, persistidos atomicamente. |

### 5.1 Garantias no banco

- @map para nomes físicos snake_case; @@map para tabelas. SQL manual utiliza os nomes efetivamente gerados.
- CHECK de magnitudes, fórmulas da própria linha, proprietários exclusivos, moeda BRL e IDs singleton.
- CHECK de principal original positivo e principal liquidado entre zero e original.
- CHECK de totalPaid e componentes da baixa; líquido positivo.
- FK com Restrict nas referências financeiras; sem exclusão em cascata do histórico.
- Unicidade de estorno integral, parcela, ocorrência, idempotência, sequência e recibo ativo.
- Documento de pessoa: remover formatação, vazio vira NULL; unicidade quando informado entre registros não excluídos.
- Índices orientados a conta/data, vencimento/estado, competência/classificação, título/pagamento e vínculos ativos.

### 5.2 Garantias no serviço transacional

Somas entre tabelas, correspondência entre pagamentos e linhas, par de transferência, matriz de sinais, fechamento, limites N:N, ausência de ciclos e bloqueios de edição.

No estorno, linhas podem referenciar os pagamentos originais para conservar a origem; validar que a transação é a reversão da transação do Settlement. Não permitir reutilizar paymentId de operação alheia.

Snapshots de taxas/encargos são históricos; campos duplicados que possam ser derivados da operação não devem virar fontes independentes.

## 6. API, concorrência e idempotência

Prefixo: /api/v1/finance. JSON em UTF-8, valores em string decimal, datas civis em YYYY-MM-DD, instantes ISO-8601 UTC.

### 6.1 Operações

| Operação | Contrato principal | Acesso exigido |
|---|---|---|
| Consulta | Cadastros, títulos, movimentos, dashboard e relatórios paginados | finance.read |
| Cadastros | Criar/editar/inativar pessoas, contas, plano, centros, meios e mapeamentos | finance.manage |
| Caixa | POST /transactions; GET /transactions/:id; POST /transactions/:id/reverse | finance.write |
| Transferência | POST /transfers; POST /transfers/:id/reverse | finance.write |
| Títulos | POST/PATCH /schedules; POST /schedules/:id/cancel; POST /schedules/installments/preview; POST /schedules/installments | finance.write |
| Baixa | POST /settlements/preview; POST /settlements; POST /settlements/:id/reverse | finance.settle |
| Recorrência | Criar, pré-visualizar alteração, editar, pausar, retomar e encerrar | finance.write |
| Importação | Importar OFX, revisar ambiguidades, desfazer/reativar lote | finance.reconcile |
| Conciliação existente | Criar/desfazer vínculos; ignorar entrada sem vínculo | finance.reconcile |
| Conciliar baixando título | Baixa e vínculo em um commit | finance.reconcile + finance.settle |
| Conciliar criando avulso | Movimento e vínculo em um commit | finance.reconcile + finance.write |
| Recibos | Emitir/cancelar; recuperar/reimprimir emissão existente | finance.settle para escrita; finance.read para consulta |
| Anexos | Adicionar/remover logicamente; baixar | Permissão de escrita da entidade; finance.read para consulta, acrescida de finance.pii para conteúdo sensível |
| Fechamento | Prévia, fechar e reabrir último fechamento | finance.close_period |
| Auditoria | Consultar eventos e entidades relacionadas | finance.audit |

Não oferecer DELETE ou PATCH financeiro genérico para movimento confirmado. Notas e metadados permitidos usam endpoint separado, auditado e restrito.

O endpoint de estorno de transação avulsa recusa movimentos originados em Settlement ou TransferGroup: cada um deve passar pelo comando de sua operação completa, com a permissão correspondente. Isso impede usar finance.write para contornar finance.settle ou desfazer somente uma ponta de transferência.

Recibos com dados completos exigem também finance.pii; uma consulta sem essa permissão não pode revelar o snapshot por uma rota alternativa.

### 6.2 Concorrência

- Toda escrita composta usa transação no banco e ordem estável de bloqueios.
- Adquirir bloqueio do estado de fechamento antes dos demais.
- Baixa bloqueia todos os títulos do lote; conciliação bloqueia entradas e movimentos.
- Atualização de cadastro/título/série exige version; UPDATE condicionado à versão, com incremento atômico.
- Retry interno de deadlock/serialização é limitado e só ocorre sobre comando idempotente.
- Prévia não reserva saldo. Confirmar revalida versões, períodos e capacidades; mudança relevante retorna conflito e nova prévia.

### 6.3 Idempotência

Idempotency-Key é obrigatório em comandos que criam, liquidam, estornam, conciliam, importam, emitem recibos ou geram parcelas/séries.

- Chave representa intenção de negócio; repetir a mesma tentativa após timeout usa a mesma chave.
- Escopo único: usuário autenticado + rota canônica (incluindo recurso alvo) + chave.
- Mesmo escopo e corpo normalizado retorna o resultado existente; corpo diferente retorna 409 IDEMPOTENCY_CONFLICT.
- Em multipart, o hash inclui conteúdo e metadados relevantes.
- Registro de sucesso e efeitos financeiros são confirmados no mesmo commit.
- Requisição simultânea aguarda a primeira até o limite; timeout retorna conflito temporário documentado, sem emitir nova operação.
- Rollback não deixa registro de sucesso.
- Revalidar autorização antes de devolver resultado já persistido.
- Guardar vínculo entre chave e operação enquanto a operação existir; limpeza de cache de resposta não permite reutilizar chave para novo movimento.

Não duplicar a mesma chave em Transaction e IdempotencyRecord como mecanismos concorrentes.

### 6.4 Erros e contrato verificável

400 para formato inválido; 401 sem identidade válida; 403 sem autorização; 404 recurso indisponível; 409 para versão/idempotência/estado concorrente; 422 para regra financeira; 503 para dependência de autorização indisponível.

Resposta: error com code, message, details opcionais e requestId. Exemplos: PERIOD_CLOSED, OVERPAYMENT, RECONCILIATION_CAPACITY_EXCEEDED, BATCH_REVERSAL_REQUIRED, UNSUPPORTED_TAX_WITHHOLDING.

Schemas de entrada fechados, paginação padrão 50/máximo 200, ordenação por campos permitidos e contrato OpenAPI gerado junto da implementação.

## 7. Controles próprios do Financeiro

### 7.1 Identidade e acesso

O Financeiro consome a sessão existente e valida assinatura, algoritmo permitido, expiração, emissor e sub. A audiência segue o contrato efetivo dessa sessão, validado no teste de integração; não inventar um valor incompatível.

Consultar a autorização existente com a credencial apresentada. Não acrescentar cache local de autorização no núcleo. Em indisponibilidade, negar a execução com erro de dependência; não usar papel do token como liberação alternativa.

A disponibilidade das permissões finance.* é pré-condição do ambiente. Este plano não contém alteração do provedor de identidade. Revogação, expiração e retirada de acesso devem ser testadas com credenciais reais antes de uso produtivo; limites herdados do provedor são registrados, não ocultados por uma promessa local.

Não aceitar x-user-id ou usuário de desenvolvimento implícito. Menu oculto não substitui verificação no backend.

### 7.2 Auditoria e dados sensíveis

- Evento de negócio correlaciona alterações nas entidades. Uma operação pode gerar vários registros, todos no mesmo commit.
- Identificar usuário ou job de sistema, instante, motivo, requestId e IDs afetados.
- Campos monetários e de classificação têm antes/depois. Dados pessoais são mascarados na trilha comum; logs técnicos não repetem PIX, documento, conta, token ou conteúdo de arquivo.
- Consultas que revelam dados completos e downloads sensíveis também são auditados.
- Credencial da aplicação não pode atualizar, excluir ou truncar a auditoria, nem administrar o schema.
- Controle append-only não equivale a proteção contra administrador do banco; não fazer essa alegação.
- Retenção/anonimização de documentos pessoais depende de política operacional definida antes de dados reais. A v3 não fixa um prazo legal genérico.

### 7.3 Persistência e recuperação

Entregáveis restritos ao Financeiro: migrações, seed idempotente, configuração de execução, health/readiness, logs, rotina de backup e roteiro de restauração dos seus dados/arquivos.

Condições de operação:

- O ambiente fornece schema e credenciais provisionados; a aplicação não cria seu próprio usuário administrador.
- Migrações são executadas por identidade de migração; o runtime usa privilégios de dados estritamente necessários.
- Banco e arquivos do Financeiro precisam sobreviver às rotinas de manutenção do ambiente. Schema dedicado ou preservação só de anexos não garantem isso.
- Backup diário criptografado, cópia fora da máquina e retenção operacional inicial de 30 dias, sujeita à política escolhida.
- Para o primeiro procedimento de backup, pausar brevemente escritas financeiras e uploads para obter conjunto consistente; preservar arquivos referenciados e conferir hashes na restauração.
- Antes de produção, executar restauração e registrar tempo medido e perda de dados máxima aceita. Backup diário implica aceitar até aproximadamente um dia de perda; se isso não for aceitável, rever a frequência antes de operar.
- Não executar limpeza destrutiva como parte de teste no ambiente real.

Alertas locais: falha de backup, migração, geração de recorrências e importação. Verificação de saldo divergente gera pendência financeira identificável.

## 8. Experiência de uso

Navegação: Visão geral; Movimentos; A pagar; A receber; Conciliação; Recorrências; Pessoas; Contas; Relatórios; Configurações.

Requisitos:

- Em cada movimento, mostrar principal, encargos, desconto, taxa e líquido; evitar que “valor pago” represente valores diferentes em telas distintas.
- Baixa mostra quanto liquida do título e quanto movimenta no banco.
- Lote mostra todos os títulos e informa que a correção reverte a operação inteira.
- Parcelamento mostra vencimento e competência antes da criação.
- Estorno mostra datas de impacto, origem, efeito nos títulos e recibos.
- Período fechado informa a data limite e a ação impedida.
- Conciliação exibe saldo disponível dos dois lados e estado parcial visível.
- Conflito de versão preserva os dados digitados para comparação; não sobrescrever silenciosamente.
- Reenvio após timeout conserva a chave da operação.
- Recibos, dados pessoais e downloads seguem as mesmas permissões das APIs.
- Dados PIX têm tipo e formato validados; revelar ou copiar a chave completa exige finance.pii e registro de acesso.
- Telas de funcionalidades adiadas não oferecem botões sem implementação.

## 9. Plano de execução otimizado

As etapas seguintes são cumulativas. Cada uma inclui API, tela necessária, testes e documentação do comportamento entregue. Não criar todas as telas antes de comprovar as regras.

| Etapa | Entrega | Critério de saída |
|---|---|---|
| **P0 — Contratos e fundação** | Schema mínimo validado, migração/seed, matriz de sinais, autorização consumida pelo Financeiro, transações, idempotência, auditoria, FinanceState, valores/datas e contratos HTTP. | Banco vazio recebe migração; repetição é segura; restrições funcionam; acesso negado corretamente; testes de sinais/arredondamento passam. |
| **P1 — Caixa confiável** | Cadastros, saldo inicial, entradas/saídas, rateio avulso, transferências, estorno integral, anexos, extrato e saldo em data. | Saldo reproduzível pelo extrato; estorno com taxa fecha; par de transferência é atômico; nenhuma edição financeira direta de movimento confirmado. |
| **P2 — Obrigações e resultado** | Títulos, parcelamento, baixa parcial/lote, encargos simples, recibos, DRE, fechamento/reabertura, aging, projeção e dashboard. | Cenários numéricos de referência passam; relatórios fechados não mudam por caminhos proibidos; histórico de baixa/estorno correto; fluxo manual completo utilizável. |
| **P3 — Operação assistida** | Importação OFX, revisão de duplicidade, conciliação N:N, recorrência com retomada e interfaces de exceção. | Sem excesso de conciliação ou geração duplicada; importação sobreposta/ambígua tratada; desconciliação não desfaz pagamento. |
| **P4 — Homologação financeira** | Conferência de saldos iniciais/títulos, dados de teste representativos, permissões reais, recuperação, desempenho e manual de rotinas. | Responsável confere saldo, aberto, caixa e competência; restauração comprovada; limitações e configurações registradas. |

P2 já permite homologação manual com dados de teste. O núcleo planejado completo termina em P4. Piloto com dados reais antes disso só pode ocorrer com os mesmos controles de acesso, persistência, backup e recuperação exigidos em P4.

Evoluções da seção 2.2 não bloqueiam P0–P4. Escolher a próxima evolução por necessidade operacional demonstrada, não por expansão antecipada do schema.

## 10. Cenários de aceite

Executar regras financeiras com banco PostgreSQL real de teste e cenários de ponta a ponta representativos. Casos abaixo substituem expectativas ambíguas da v2.

| ID | Cenário | Resultado esperado |
|---|---|---|
| T01 | Entrada avulsa: principal 1.000, desconto 100, taxa 20 | Bruto 900; líquido 880; contribuições +1.000 −100 −20; resultado 880. |
| T02 | Estornar T01 integralmente na mesma janela | Débito líquido 880 com taxa preservada como exceção de reversão; soma bancária e econômica do par = zero. |
| T03 | Título de 1.000 em outubro; baixa em novembro com desconto 100/taxa 20 | DRE competência: outubro +1.000; novembro −120. Caixa novembro +880. Principal não duplicado. |
| T04 | Estornar a baixa de T03 em dezembro aberto, componentes em dezembro | Caixa dezembro −880; competência dezembro +120; título continua reconhecido em outubro. Posição em novembro liquidada; em dezembro reaberta. |
| T05 | Saída: principal 1.000, juros 10, desconto 50 | Líquido 960; contribuições −1.000 −10 +50 = −960. |
| T06 | Lote com títulos de 100 e 200; tentativa de estornar só um | Comando individual recusado; estorno da operação reverte 300 e ambos os pagamentos. |
| T07 | Título 1.000; baixas concorrentes de 400 e 600 | Ambas podem concluir; total liquidado 1.000. |
| T08 | Título 1.000; baixas concorrentes de 600 e 600 | Uma conclui; a outra falha por excesso após revalidar saldo. |
| T09 | Parcelar 100 em três; vencimento base 31/jan de ano não bissexto | 33,33 + 33,33 + 33,34; datas 31/jan, 28/fev, 31/mar; competências conforme prévia. |
| T10 | Encargos do exemplo FIN-07 | Juros total 5,33 e multa total 20; principal total liquidado 1.000. |
| T11 | Cancelar ou mudar valor/classificação de título que afeta mês fechado | Operação bloqueada, incluindo tentativa de mover competência para fora do mês fechado. |
| T12 | Baixa concorrente com fechamento | Resultado serializável do negócio: baixa conclui antes do fechamento ou é rejeitada depois; nunca atravessa o limite sem validação. |
| T13 | Movimento de 100 já vinculado em 70; novo vínculo de 40 | Rejeição por capacidade do movimento, mesmo que a entrada tenha saldo. |
| T14 | Entrada de 100 já vinculada em 70; novo vínculo de 40 | Rejeição por capacidade da entrada, mesmo que o movimento tenha saldo. |
| T15 | Contas diferentes, sentidos opostos ou vínculo desfeito | Os dois primeiros são rejeitados; o desfeito deixa de consumir capacidade. |
| T16 | Importar mesmo arquivo; FITID repetido conflitante; duas linhas iguais sem FITID | Mesmo arquivo recupera lote/gera conflito previsto; conflito não é ignorado; linhas ambíguas exigem revisão sem descarte silencioso. |
| T17 | Desfazer importação com vínculo parcial | Bloqueado até desfazer todos os vínculos; depois preserva histórico e permite reativação explícita. |
| T18 | Dois jobs de recorrência e retomada após falha | Uma ocorrência por índice; nenhuma duplicidade; títulos pagos/fechados não são alterados. |
| T19 | Emissões simultâneas, reimpressão, cancelamento e reemissão | Números únicos; reimpressão usa o mesmo; cancelamento não emite outro; reemissão ganha número novo e vínculo. |
| T20 | Retry simultâneo/depois de timeout com mesma chave | Uma operação e o mesmo resultado; hash diferente recebe 409. |
| T21 | Falha no meio de baixa, estorno, transferência ou conciliação | Nenhum efeito parcial, inclusive auditoria e resultado idempotente. |
| T22 | Saldo inicial −100; consulta antes da abertura | Saldo negativo válido; data anterior informa ausência de histórico. |
| T23 | Token inválido/expirado/revogado, permissão removida e provedor indisponível | Nenhuma execução não autorizada; medir revogação conforme contrato; indisponibilidade retorna 503 sem fallback. |
| T24 | Consulta de recibo/anexo/auditoria sem acesso a dados completos | Nenhuma rota alternativa expõe dados sensíveis; leitura autorizada é auditada. |
| T25 | Restaurar backup de banco e arquivos em ambiente isolado | Saldos, títulos, recibos e hashes dos anexos conferem com o conjunto de referência. |
| T26 | Projeção com baixa parcial, vencido e título sem conta | Só saldo restante projetado; atraso sem previsão separado; item sem conta aparece no consolidado identificado. |
| T27 | Transferência estornada | Novo grupo reverso, duas pontas por grupo, soma global zero e ausência de resultado econômico. |
| T28 | Tentar reverter movimento de baixa pelo endpoint de avulso | Rejeição sem efeitos; somente o comando do Settlement, com finance.settle, pode reverter a baixa. |

Verificações adicionais: fronteira de data no fuso, ano bissexto, MIME/conteúdo divergente, proprietário de anexo inválido, ciclo em hierarquia, permissão combinada para conciliar baixando título e restrição de escrita sobre auditoria.

Desempenho-alvo preservado: listagem paginada com base de 50 mil movimentos em p95 < 500 ms; DRE de 12 meses em < 2 s. Registrar hardware, volume de linhas/componentes e concorrência do ensaio para que o resultado seja reproduzível.

## 11. Premissas propostas e decisões operacionais

Este planejamento usa os seguintes padrões explícitos:

- BRL, empresa única, fuso America/Sao_Paulo.
- Vencimentos não são prorrogados automaticamente por fins de semana/feriados.
- Encargos desativados até configuração; juros simples por fração liquidada.
- Uma classificação/centro por título no núcleo; movimentos avulsos aceitam rateio.
- Correção de lote é integral; não há estorno parcial nem adiantamento automático.
- Retenções tributárias, fatura de cartão e renegociação assistida ficam fora do núcleo.
- Títulos são obrigações confirmadas; sem estado de rascunho ou hipóteses comerciais persistidas como receita.

Antes de dados reais, registrar apenas decisões operacionais que não podem ser inventadas pelo software: data de corte, saldos iniciais, títulos em aberto, pessoas autorizadas, parâmetros de encargos, política de dados pessoais e tolerância de perda/tempo de recuperação.

Saldo inicial incorpora o histórico bancário anterior ao corte; esse histórico não pode ser importado novamente como novos movimentos sobre o mesmo saldo. Se houver migração de títulos parcialmente pagos ou de competências já reconhecidas, preparar uma etapa financeira específica de conversão e conferência antes do piloto. Não presumir que cadastrar apenas o saldo restante como novo título preserva o DRE ou o histórico. Essa conversão depende dos dados efetivamente disponíveis e não está resolvida pelo cadastro de saldo inicial.

Essas decisões não impedem construir e testar o núcleo. Também não devem ser preenchidas automaticamente com dados presumidos da empresa.

## 12. Rastreabilidade da v2

| Origem na v2 | Destino |
|---|---|
| RN-01 a RN-04 — valores/componentes | FIN-01/02; sinais explícitos e retirada de TAX das baixas do núcleo. |
| RN-05 a RN-07 — saldo e contas | FIN-01/03/10; natureza econômica e estrutura usada imutável. |
| RN-08 a RN-10 — transferências | FIN-09; grupo separado para reversão. |
| RN-11 a RN-17 — títulos e baixas | FIN-04/06/07/08; principal liquidado, Settlement e estorno integral. |
| RN-18/19 — parcelas/recorrência | FIN-05/14; competência explícita e identidade de ocorrência. |
| RN-20 a RN-22 — DRE | FIN-01/10; contribuições sinalizadas e nenhuma exclusão global de estornados. |
| RN-23 a RN-28 — conciliação | FIN-12/13; capacidade nos dois lados, parcial visível e revisão de duplicidade. |
| RN-29 a RN-33 — recibos | FIN-15; origem exclusiva e cancelamento independente de reemissão. |
| RN-34 a RN-36 — fechamento/auditoria | FIN-11 e seção 7; proteção das fontes de relatório e evento de negócio correlacionado. |
| Schema/API da v2 | Seções 5/6; contrato mínimo a validar, sem copiar SQL incompatível. |
| Fases da v2 | Seção 9; P0–P4 para o núcleo e evoluções financeiras posteriores. |
| Contratos com outros módulos | Fora deste planejamento por delimitação do usuário. |

## 13. Fontes da revisão

- solicitacao-implementacao-financeiro-v2.md: fonte principal das regras confrontadas.
- Análise crítica anterior: hipóteses revisadas na seção 1, sem tratá-las automaticamente como requisitos.
- [Prisma 6 — Database mapping](https://docs.prisma.io/docs/orm/v6/prisma-schema/data-model/database-mapping): distinção entre mapeamento de campo e de tabela.
- [PostgreSQL 16 — Constraints](https://www.postgresql.org/docs/16/ddl-constraints.html): limites de CHECK e restrições relacionais.
- [PostgreSQL 16 — Privileges](https://www.postgresql.org/docs/16/ddl-priv.html): propriedade, privilégios e limites do isolamento por usuário/schema.

As referências técnicas sustentam os mecanismos; escolhas de produto e simplificações financeiras estão declaradas como decisões propostas deste planejamento.
