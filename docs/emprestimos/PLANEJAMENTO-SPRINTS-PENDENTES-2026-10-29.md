# Planejamento das tarefas restantes — Empréstimos

Data: 29/10/2026. Base consultada: `openspec/changes/implementacao-modulo-emprestimos/tasks.md`, regras v2.1, débitos técnicos e estado da implementação nesta conversa.

## Objetivo e situação de partida

Concluir o módulo em sprints com entregas funcionais, reunindo implementação, integração e verificação. O estado registrado é **25 de 45 tarefas concluídas e 20 abertas**. A meta intermediária continua sendo alcançar 30 tarefas concluídas no total. Os identificadores abaixo são os do OpenSpec, não posições na contagem total.

Este documento planeja a execução futura. Sua criação não executa simulações, não aprova decisões pendentes, não altera checkboxes e não habilita capacidades. Os critérios do OpenSpec e do plano vigente continuam obrigatórios.

Preservar: independência do Financeiro; cadastro histórico manual sem importação da planilha; rejeição de pagamento acima do saldo elegível; distinção entre recebimento, desconto, estorno e devolução real; alterações existentes no workspace.

DT-01, DT-02 e DT-03 foram adiados pelo dono. Continuam pendentes. Colocá-los na sequência de dependências não revoga esse adiamento: a execução que depende de suas decisões só pode concluir quando essas decisões forem retomadas. Preparações técnicas independentes podem avançar, mas não contam como tarefa completa.

## Organização das sprints

| Sprint | Entrega | Tarefas abertas abrangidas | Total se todas as anteriores concluírem |
| --- | --- | --- | --- |
| 1 | Encargos e recebimentos integrados | 3.4, 3.3, 3.5 | 28/45 |
| 2 | Correções, prorrogação e acordo | 3.12, 3.8, 3.9 | 31/45 |
| 3 | Perda, cancelamento e fluxos completos | 3.10, 3.11, 3.13, 4.3 | 35/45 |
| 4 | Validação para piloto autenticado | 4.4 | 36/45 |
| 5 | Indicadores, relatórios e exportações | 5.1, 5.2, 5.3, 5.4 | 40/45 |
| 6 | Consolidação para liberação operacional | 6.3 | 41/45 |
| 7 | WhatsApp | 7.1, 7.2, 7.3, 7.4 | 45/45 |

Os totais são condicionais, não previsões nem compromissos de prazo. A meta de 30 será alcançada durante a sprint 2 se a sprint 1 e duas tarefas da sprint 2 forem integralmente concluídas. A sprint deve continuar até sua entrega combinada; alcançar a contagem intermediária não exige interromper a execução.

## Sprint 1 — Encargos e recebimentos integrados

**Dependência:** resolver as decisões de DT-01 necessárias à cobrança. Enquanto o adiamento persistir, não prometer encerramento desta sprint.

**Ponto atual:** `src/late-interest.ts` contém funções de cálculo e calendário, ainda sem a integração completa de apuração e gravação dos encargos no fluxo de recebimento. `payments.ts` já aloca pagamentos e protege operações por versão e idempotência.

1. **3.4 — Contrato econômico de encargos.** Consolidar a composição da base, sequência no fechamento do bloco de 30 dias, pagamentos sucessivos na mesma data e multa já apurada antes do recebimento. Distinguir decisões já aprovadas de alternativas que alteram o valor cobrado. Registrar somente as escolhas efetivamente decididas, inclusive interpretação de espera zero. Encerrar DT-01 apenas com regras e implementação coerentes.
2. **3.3 — Apuração recorrente.** Integrar datas civis, condições congeladas, multa recorrente e mora proporcional ou por blocos de 30 dias ao serviço. Persistir ocorrência, versão de cálculo, período, base, escolha e detalhamento; impedir reaplicação de ocorrência dispensada ou já registrada. A consulta deve informar escolhas pendentes e não transformar consulta em cobrança por efeito colateral.
3. **3.5 — Recebimento e encargo do dia.** Recalcular a prévia e a confirmação com a mesma rotina; aplicar recebimento antes da multa nova; registrar a escolha de inclusão do dia e a opção de base de bloco sem seleção automática. Confirmar pagamento, alocações, encargos, auditoria e idempotência na mesma transação.

**Aceite da entrega:** concordância entre prévia, banco e saldo consultado; ausência de capitalização de multa/mora anteriores; calendário de 28/29/30/31 dias e blocos 29/30/31/60; R$ 1.000 menos R$ 400 com multa posterior de R$ 12; concorrência, repetição e falha transacional sem efeitos duplicados. Casos ainda economicamente indefinidos permanecem impedidos e não permitem marcar a tarefa completa.

**Áreas principais:** `evo-loans-service/src/late-interest.ts`, `payments.ts`, `wallet-routes.ts`, schema e migrations de ocorrências; formulários de recebimento e encargos no frontend.

## Sprint 2 — Correções, prorrogação e acordo

**Dependências:** motor da sprint 1 e decisões necessárias de DT-02. Desenvolver os três fluxos em conjunto para que uma alteração de contrato preserve as dependências dos pagamentos.

1. **3.12 — Correções e estornos.** Definir a matriz de transições e impedimentos; implementar correção vinculada do dinheiro recebido e efeitos na dívida atual, estorno único e vínculo às operações anteriores. Cobrir pagamento já corrigido, pagamentos posteriores, acordo posterior e recuperação de perda. Evitar que correção e ajuste apliquem a mesma diferença duas vezes. Fechar DT-02 somente após conferir efeitos líquidos e bloqueios dos casos sem tratamento aprovado.
2. **3.8 — Prorrogação completa.** Completar contratos parcelados: seleção explícita da base aprovada e do destino dos vencimentos, preservação dos pagamentos, tratamento das demais parcelas e cronograma resultante coerente. Consolidar o caso de parcela única existente, histórico, antes/depois e encargos anteriores separados.
3. **3.9 — Acordo completo.** Conservar componentes anteriores separados dos novos, definir o registro preciso da atribuição de juros em recebimentos posteriores, tratar acordos sem principal pendente e conectar o histórico de correções. A consulta atual de limites matemáticos não substitui essa atribuição. Qualquer escolha econômica ainda necessária deve ser decidida antes da implementação dependente.

**Aceite da entrega:** juros antigos pendentes impedem prorrogação; R$ 700 prorrogados a 20% resultam em R$ 840 mais encargos separados; acordo não capitaliza encargos antigos nem duplica dívida ou dinheiro; correção e estorno preservam original, saldos e dinheiro efetivamente recebido. Confirmações idempotentes, concorrência, autorização e rollback verificados nos fluxos implementados.

**Áreas principais:** `extensions.ts`, `negotiation.ts`, `interest-attribution.ts`, `payment-dependencies.ts`, `payments.ts`, novos registros de correção e respectivas telas.

## Sprint 3 — Perda, cancelamento e experiência completa

**Dependências:** encargos e correções das sprints anteriores. Há implementações parciais de perda e prévias de cancelamento, além de telas e ficha existentes.

1. **3.10 — Perda e recuperação.** Completar estorno de recuperação por componente e opção de calcular encargos do período congelado ao corrigir a perda. Preservar a suspensão da cobrança e dos encargos durante a perda. Conservar a marcação original e recuperação como fatos distintos.
2. **3.11 — Cancelamento.** Implementar confirmação, estornos necessários, compensação do principal já recebido e registro separado de devoluções reais. Exigir escolhas por componente e evidências de devolução quando exigida; impedir conclusão com devolução obrigatória pendente. Conservar os impedimentos para dependências não tratadas.
3. **3.13 — Fluxos de operação.** Conectar recebimento, encargos, histórico manual, prorrogação, acordo, perda e cancelamento às APIs completas. Exibir componentes e impedimentos na prévia; preservar chave em repetição e resultado incerto; tratar mudança de carteira e versão antiga. Integrar também os consumidores existentes da central e ações em lote ao novo motor de encargos.
4. **4.3 — Ficha completa.** Consolidar contratos, parcelas, recebimentos, notas, anexos, correções e vínculos entre origem e destino. Incorporar os eventos de correção e estorno concluídos nesta sequência. A correção de paginação já feita é parte da tarefa, não seu encerramento.

**Aceite da entrega:** perda de R$ 860 com recuperação de R$ 140 deixa R$ 720 pela prioridade acordada; estorno restaura os componentes; cancelamento de principal R$ 1.000 com R$ 200 já amortizados exige os R$ 800 restantes; histórico mostra fatos e correções sem apresentar perda como quitação. Verificar os fluxos integrados e a apresentação em navegador, além dos testes automatizados necessários.

**Áreas principais:** `losses.ts`, `cancellation.ts`, `contracts.ts`, schema/migrations de estornos, compensações e devoluções, `src/pages/loans` e `src/services/loans` do frontend.

## Sprint 4 — Preparação e validação do piloto

**Tarefa 4.4. Dependências:** capacidades G2 pretendidas completas, permissões e restauração verificadas no ambiente apropriado, conjunto de dados de piloto aprovado.

- Consolidar quais recursos podem ser habilitados e quais ainda permanecem impedidos.
- Preparar a configuração de execução correspondente: hoje `server.ts` não transmite as opções de pagamentos, histórico e acordos usadas pelos testes de aplicação. A integração dessas opções e suas condições de liberação deve ser explícita antes do piloto.
- Validar Auth, gateway, frontend, carteira, concessão/revogação, anexos e persistência nos fluxos autenticados.
- Conferir a recuperação aplicável ao ambiente: destino de backup/WAL, anexos, versões de chaves, referência de recuperação e reconciliação. A 6.2 concluída é o ensaio descartável, não aprovação deste ambiente.
- Executar o piloto somente quando suas condições e dados estiverem aprovados. Registrar resultados e limitações em evidências G3.

**Aceite:** condições de G2 aplicáveis demonstradas, piloto autenticado executado e evidência reproduzível do que foi efetivamente habilitado. Sem essas condições, a tarefa continua aberta.

## Sprint 5 — Indicadores, relatórios e exportações

**Dependências:** fatos e correções estabilizados; retomada das decisões adiadas de DT-03. Componentes independentes podem ser preparados antes, sem liberar resultados definitivos afetados.

1. **5.1 — Significado dos resultados.** Documentar efeitos de perdas, recuperações, estornos, devoluções e correções retroativas; filtros e datas de cada indicador; validar com o dono apenas os significados ainda pendentes. Fechar DT-03 com critérios registrados.
2. **5.2 — K1–K8.** Implementar consultas por carteira e referência temporal, qualidade e cobertura, sinalização de datas estimadas, base incompleta e denominador zero. Reconciliar com cálculo independente e com os mesmos fatos exibidos na ficha.
3. **5.3 — Relatórios.** Implementar fluxo operacional de seis meses, distribuição por situação, maiores devedores e faixas de valor. A transferência para acordo não é nova concessão nem novo recebimento. Definir filtros e ordenação consistentes com as consultas.
4. **5.4 — Excel e PDF.** Exportar os mesmos filtros e resultados autorizados, aplicar mascaramento e tratamento de textos que possam ser interpretados como fórmula; conferir conteúdo e apresentação dos arquivos gerados. Registrar evidências G4.

**Aceite:** indicadores e relatórios conciliados com pagamentos, correções e saldos; ausência de acesso cruzado; Excel/PDF concordantes com a consulta; textos não executáveis como fórmulas. Não denominar juros recebidos como lucro líquido.

## Sprint 6 — Consolidação operacional

**Tarefa 6.3. Dependências:** entregas aplicáveis G0–G4 concluídas e verificadas, decisões e condições de operação necessárias resolvidas.

Reunir evidências por requisito e versão, atualizar estados de DT-01–DT-07 conforme realmente demonstrado, conferir migrations e configuração de execução, limites de recursos, permissões e recuperação. Resolver divergências entre plano, checkboxes, evidências e comportamento. Registrar o estado de cada gate e a decisão de liberação operacional aplicável.

**Aceite:** pacote de evidências coerente com a implementação e condições de liberação demonstradas. Registrar uma limitação não encerra por si só o débito ou a tarefa afetada. A ausência de aprovação de um gate não deve ser ocultada por um total de tarefas.

## Sprint 7 — WhatsApp, fase posterior

**Dependência:** núcleo apto à operação e retomada explícita desta fase; provedor e política de mensagens ainda não definidos.

1. **7.1 — Escolhas de integração.** Definir com o dono provedor, remetente, horário e mensagens; preparar credenciais e comprovar conectividade em ambiente de teste.
2. **7.2 — Configuração e fila.** Implementar regras por carteira, fila durável, destinatário próprio e interrupção por flag.
3. **7.3 — Elegibilidade.** Reconsultar saldo, vencimento, contato e estado imediatamente antes de enviar; excluir quitados, perdas, contratos substituídos e demais casos inelegíveis.
4. **7.4 — Confiabilidade.** Deduplicar, limitar tentativas e preservar resultado incerto; retomar após reinício e concorrência sem reenvio cego. Registrar evidências G6.

**Aceite:** mensagens de teste somente aos destinatários e nas condições autorizadas; fila recuperável; histórico e tratamento de incerteza demonstrados. Não prometer entrega exatamente uma vez.

## Condução da execução futura

- Selecionar a entrega da sprint e suas dependências antes de editar código. Reaproveitar o que já existe, verificando lacunas em vez de reconstruir módulos.
- Executar implementação e integração de ponta a ponta. Uma função isolada, uma prévia ou um teste adicional não é uma entrega funcional completa.
- Manter trabalho independente em andamento quando surgir decisão pendente. Concentrar perguntas apenas nas escolhas necessárias que não estejam decididas, respeitando o adiamento vigente.
- Não criar novos ensaios exploratórios nesta fase de planejamento. Na execução futura, a verificação deve ser vinculada ao critério de aceite do código entregue; repetir somente após mudança, falha ou preocupação concreta. A solicitação de parar simulações não elimina os critérios de aceite das tarefas.
- Atualizar checkboxes individualmente somente quando todos os critérios forem atendidos; agrupar o relatório ao final da sprint. Informar entregas completas, parciais, bloqueios concretos e total confirmado.
- Encerrar uma resposta de execução ao concluir a entrega combinada ou ao esgotar o trabalho autorizado que possa avançar sem informação obrigatória. Atualizações de andamento acompanham a execução, sem exigir novos comandos de continuidade.

Não há datas ou duração comprometidas neste plano. Estimativas de calendário devem ser feitas após as decisões necessárias e a seleção de cada sprint, sem presumir disponibilidade do ambiente ou aprovação do dono.
