# Módulo Empréstimos — débitos técnicos e pendências

Criado em 28/10/2026. Estado: **DT-04 concluído; demais itens abertos**. Este registro reúne as quatro frentes da [conclusão de prontidão](CONCLUSAO-PRONTIDAO-20261028.md), para tratamento durante o desenvolvimento futuro. Alguns itens são decisões de negócio ainda não fechadas, além de tarefas técnicas; estão identificados abaixo.

**Limite de escopo:** Empréstimos é independente do Financeiro. Não há importação da planilha nesta entrega. Registrar um item como débito futuro não autoriza habilitar uma operação afetada sem que sua regra e seus testes estejam concluídos. Fundação, cadastros e outras capacidades independentes podem avançar.

Os momentos indicados são condições de aceite da capacidade, não datas prometidas. G1, G2, G3 e G4 são os gates definidos no [plano vigente](../../solicitacao-implementacao-emprestimos.md). Os exemplos monetários são sintéticos; percentuais são ilustrativos, não parâmetros aprovados.

## DT-01 — Base e sequência de multa e juros de atraso

**Origem:** P1. **Estado:** aberto. **Quando resolver:** antes de homologar G2 ou habilitar a cobrança afetada.

**Pendência:** especificar a composição da base de encargos quando houver encargos avulsos; a sequência de pagamento, mora e fechamento de bloco no 30º dia; e o comportamento de pagamentos sucessivos na mesma data ou de multa já calculada antes do pagamento. Preservar a regra aprovada: pagar primeiro os componentes já devidos, calcular depois a multa nova do dia sobre a base restante e deixá-la para pagamento posterior; não recalcular automaticamente encargos já confirmados por registro retroativo.

**Impacto:** interpretações diferentes podem produzir valores de cobrança diferentes. No exemplo da revisão, R$ 400 pagos de uma vez e dois pagamentos de R$ 200 podem deixar saldos distintos sob determinada sequência. Isso é uma hipótese demonstrada, não defeito comprovado em serviço existente.

**Encerramento:** documentar base e linha do tempo; demonstrar eventos únicos e reenvios; testar meses de 28/29/30/31 dias, virada de mês, dias 29/30/31/60, pagamentos parciais, vários pagamentos no mesmo dia, multa já calculada, quitação, múltiplas parcelas e cálculo por parcela. Validar com o dono somente as alternativas que alterem o valor cobrado. Base zero com multa percentual sobre esse saldo resulta em zero; não reabrir essa consequência matemática sem uma situação distinta.

## DT-02 — Correções, estornos, acordos e cancelamentos encadeados

**Origem:** P2. **Estado:** aberto. **Quando resolver:** antes de homologar G2 ou habilitar correções e cancelamentos afetados.

**Pendência:** estabelecer estados, dependências e efeitos de pagamentos, correções, estornos, acordos, perda e cancelamento. A correção deve preservar o registro original, mostrar o dinheiro realmente recebido e não criar movimentação fictícia nem efeito duplicado na dívida. Considerar estorno de recebimento já corrigido; acordo quitado; recuperação de perda; e cancelamento com juros ou encargos recebidos que serão mantidos ou devolvidos conforme o acordo.

**Impacto:** saldo, dinheiro recebido e relatórios podem divergir ou um mesmo valor pode ser revertido duas vezes.

**Encerramento:** matriz de transições e exemplos de efeitos líquidos; prévia de impedimentos e efeitos por componente; testes da operação real com idempotência, concorrência, falhas e histórico auditável. Se uma solução exigir nova decisão econômica, como perdão, crédito excedente ou devolução não autorizada, consultar o dono; não inferir autorização. O pagamento acima do devido continua proibido.

## DT-03 — Indicadores de perda e correções retroativas

**Origem:** P3. **Estado:** resolvido e formalizado em 29/10/2026 (`CRITERIOS-DT03-INDICADORES.md`). **Quando resolver:** antes de aprovar indicadores e relatórios definitivos em G4.

**Pendência:** definir filtros de perda e recuperação em K1, K3, K4, K7 e K8; explicitar efeitos de correção de valor ou data no período original e no período da alteração; reconciliar K6 e relatórios com estornos, cancelamentos e devoluções reais.

**Impacto:** uma perda pode parecer quitação, uma correção pode parecer recebimento novo ou os valores de meses diferentes podem ficar incoerentes.

**Encerramento:** critérios formalizados em `docs/emprestimos/CRITERIOS-DT03-INDICADORES.md`: perdas segregadas em `k1Loss` sem poluir o giro ativo; recuperações tratadas por ordem de amortização como receita de recuperação; K6 focado estritamente em juros contratuais recebidos sem afirmar lucro líquido; K7 com média diária real e tratamento seguro de denominador zero; renegociações não criam desembolsos fictícios. Evidências implementadas e testadas na Sprint 5.

## DT-04 — Alinhar o plano às decisões já tomadas

**Origem:** P4. **Estado:** concluído em 29/10/2026. **Quando resolvido:** durante a consolidação do plano, antes de implementar os trechos afetados.

**Pendência:** alinhar a exceção de alocação com saldo legado não classificado à decisão de deixar em rascunho o contrato histórico com componente de recebimento desconhecido; atualizar o parágrafo que ainda trata esse ponto como não decidido; completar os resumos D3, D8 e D11 com as escolhas posteriores e tirar da coluna de pendências a decisão já tomada de rascunho.

**Impacto:** interpretações incompatíveis podem levar a equipe a implementar uma regra superada ou perguntar novamente uma decisão já tomada.

**Encerramento:** uma leitura de consistência entre regras, tabela de decisões, modelo, detalhamento e cenários; nenhuma alteração silenciosa das escolhas do dono. Manter versões históricas identificadas como históricas.

**Evidência:** o plano foi alinhado em Alocação, cadastro histórico e resumos D3/D8/D11; os 19 cenários documentais passaram. A cópia prévia conferida está em `docs/historico/solicitacao-implementacao-emprestimos.v2.1-antes-dt04-20261029.md`. Isso não homologa a implementação.

## DT-05 — Contrato de cálculo Price e arredondamento

**Origem:** P4. **Estado:** resolvido na implementação e nos testes sintéticos; não implica aprovação do gate G1. **Quando resolver:** antes de aprovar G1 para cronogramas.

**Pendência:** transformar a proposta de cálculo e os exemplos em contrato único do motor: precisão, arredondamento por período, composição principal/juros, última parcela, limites e rejeição de cronogramas inválidos.

**Impacto:** diferenças de centavos ou principal residual podem deixar um contrato aparentemente quitado com saldo.

**Encerramento:** testes parametrizados do motor real para taxa zero, valores pequenos, diferentes taxas e quantidades, componentes não negativos e saldo final zero; confirmar que a última parcela absorve a diferença, conforme decisão já tomada. Não substituir valores reais informados em contrato histórico por um cronograma calculado.

**Evidência:** `CONTRATO-CALCULO-PRICE.md`, testes `test/calculation.test.mjs` e integração `test/integration/migrations.test.mjs` no `evo-loans-service`. Os testes incluem taxa zero, resíduos, limites, comparação independente em centavos e contrato histórico de R$ 500 preservado apesar de uma referência calculada de R$ 550. A operação histórica permanece bloqueada no serviço até os demais gates aplicáveis.

## DT-06 — Autorização, infraestrutura e transações

**Origem:** P4. **Estado:** aberto. **Quando resolver:** progressivamente na fundação e antes do gate da capacidade correspondente; isolamento e recuperação precisam estar comprovados antes de uso real, inclusive piloto G3.

**Pendência:** definir bootstrap e recuperação dos administradores das carteiras; resolver a seleção de identidades existentes respeitando as permissões do Auth; migrations e papéis de banco próprios; transações e idempotência do novo módulo; configuração coordenada de gateway e frontend; backup e recuperação de banco, anexos e chaves.

**Impacto:** acesso indevido entre carteiras, pagamentos duplicados, impossibilidade de administrar usuários ou perda de dados.

**Encerramento:** testes com banco descartável e conexões independentes, concessão/revogação e tentativa de acesso cruzado; reenvio após timeout e falha transacional; migração versionada; ensaio de recuperação incluindo como preservar fatos posteriores ao backup. O Auth, o gateway e o banco são infraestrutura compartilhada; não criar dependência de negócio com Financeiro.

**Evidência parcial de G0:** `EVIDENCIAS-IMPLEMENTACAO-G0.md` e `ENSAIO-RECUPERACAO-G0.md` registram testes de carteiras, Auth real, migrations e um ensaio sintético de banco, anexo, chaves, cadastro e recebimento posteriores. A reaplicação do recebimento cria novo identificador e não preserva automaticamente dependências posteriores; outros fatos e recuperação operacional ainda exigem procedimento e testes. DT-06 permanece aberto até os critérios aplicáveis serem demonstrados.

## DT-07 — Testes de implementação e evidências dos gates

**Origem:** limitações de verificação na conclusão de prontidão. **Estado:** aberto. **Quando resolver:** em cada fase, antes de aprovar seu gate.

**Pendência:** substituir a confiança em exemplos documentais por testes do motor, API, interface, banco e fluxos reais implementados. Os 19 cenários existentes são demonstrações sintéticas, incluindo contraprovas históricas; não homologam o serviço.

**Impacto:** cálculos exemplificados podem passar enquanto persistência, concorrência, permissões ou recuperação falham.

**Encerramento:** registrar em `docs/emprestimos-evidencias.md` as versões, comandos, resultados e limites dos testes; cobrir as situações de DT-01 a DT-06 e os critérios de G0–G5 aplicáveis. Validar isolamento e recuperação antes de piloto; executar testes com dados sintéticos e banco descartável.

## Fora deste débito de núcleo

Notificações automáticas por WhatsApp seguem como fase G6, com provedor, remetente, horário e mensagens ainda a definir. Elas não bloqueiam o núcleo. A importação da planilha continua fora desta entrega e, se desejada no futuro, exigirá decisão e planejamento próprios.
