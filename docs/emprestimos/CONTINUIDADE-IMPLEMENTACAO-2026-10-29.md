# Continuidade da implementação do módulo de empréstimos

**Atualização posterior:** após revisão do escopo da tarefa 6.2, o ensaio descartável foi concluído e registrado no OpenSpec. O progresso passou a 25 de 45 tarefas; os gates e a estratégia de recuperação operacional continuam pendentes. Consulte `ENSAIO-RECUPERACAO-G0.md` e `tasks.md` para o estado mais recente. Os números e estados nas seções abaixo refletem o registro original.

**Registro:** 29/10/2026. **Mudança OpenSpec:** `implementacao-modulo-emprestimos`. **Estado consultado neste registro:** 24 de 45 tarefas concluídas; 21 abertas. A solicitação de avançar até 30 tarefas concluídas ainda não foi atendida. O número é o total de tarefas marcadas, não o número de uma tarefa específica.

Este documento reúne o trabalho realizado e suas limitações. O estado detalhado e atualizado das tarefas está em `openspec/changes/implementacao-modulo-emprestimos/tasks.md`; não inferir conclusão apenas pela existência de código ou de testes parciais. Nenhum gate G0–G5 foi aprovado para operação, e não há autorização de piloto com dados reais.

## Decisões que devem ser preservadas

- Empréstimos e Financeiro são módulos distintos e independentes. Infraestrutura compartilhada, quando necessária, não constitui integração de negócio entre os módulos.
- Não importar a planilha nesta primeira etapa. O cadastro histórico é manual.
- O dono decidiu deixar débitos técnicos para resolução futura. DT-01 (encargos), DT-02 (correções e eventos encadeados) e DT-03 (indicadores) continuam abertos; não presumir decisões econômicas nem liberar funcionalidades dependentes.
- Pagamento acima do saldo elegível deve ser rejeitado. Pagamento, desconto, estorno de registro e devolução real são fatos distintos.
- Não marcar tarefa incompleta como concluída para atingir uma meta numérica; recursos de teste e prévias não equivalem à liberação operacional.

## Fontes principais

- `solicitacao-implementacao-emprestimos.md`: escopo, decisões e regras de negócio.
- `docs/emprestimos/REGRAS-E-CENARIOS-v2.1.md`: regras e cenários acordados.
- `docs/emprestimos/DEBITOS-TECNICOS.md`: débitos, impactos e critérios de encerramento.
- `openspec/changes/implementacao-modulo-emprestimos/`: proposta, desenho, especificações e tarefas.
- `docs/emprestimos/EVIDENCIAS-IMPLEMENTACAO-G0.md`, `EVIDENCIAS-G1.md`, `EVIDENCIAS-G2-PARCIAIS.md` e `EVIDENCIAS-G3-PARCIAIS.md`: evidências e seus limites.
- `docs/emprestimos/ENSAIO-RECUPERACAO-G0.md`: procedimento examinado e limites do ensaio de restauração.

## Fundação e cadastro

Foi criado `evo-loans-service`, com schema PostgreSQL próprio `loans`, migrações versionadas, papéis separados para migração e aplicação, autenticação integrada ao Auth, gateway, configuração de Compose/Swarm e integração de CI. A autorização é verificada por carteira. Foram implementados carteira, membros e administração delegada, bootstrap e recuperação de administração, trilha de auditoria, proteção de CPF/RG e armazenamento separado de anexos com hash e validação de tipo e tamanho.

O cadastro de clientes é próprio da carteira, permite CPF pendente e inclui contatos, endereço, origem, indicador e observações. Há parâmetros por carteira e condições congeladas por contrato. O cálculo usa valores decimais, cronogramas de parcela única e Price e datas civis mensais e semanais. Há simulação, rascunho e confirmação idempotente, sujeitos às flags e gates aplicáveis. O cadastro histórico manual preserva as parcelas combinadas, distingue desconto de dinheiro recebido e aceita data estimada com correção auditada.

## Cobrança e contratos: o que já existe

O serviço contém pagamentos e alocações por componente, ordem de abatimento, seleção de parcela, rejeição de excedente, controle de versão, bloqueio transacional, idempotência e auditoria. Há encargos avulsos, descontos e ajustes. A central de parcelas oferece filtros, busca, paginação, estados simultâneos e ações em lote por contrato; a ficha do cliente exibe contratos, parcelas, pagamentos, observações, anexos, eventos de cobrança e alocações por parcela. A ficha também navega entre contrato de origem e acordo e mostra correções de data registradas.

Estas capacidades de cobrança são **parciais e restritas a testes**, pois a apuração de encargos recorrentes e os cenários encadeados ainda não estão completos:

- Prorrogação de parcela única: sugere taxa e vencimento, exige quitação dos juros antigos e separa encargos anteriores. A prévia e a confirmação rejeitam data igual ou anterior ao vencimento atual. Parcelados ainda não estão implementados.
- Acordo: prévia e confirmação de teste preservam origem, destino, escolhas e componentes transferidos, sem criar recebimento ou desembolso. A distinção econômica exata entre juros antigos e novos em pagamentos posteriores ainda não está definida; uma consulta apresenta somente limites matemáticos quando cabíveis.
- Perda: marcação integral, recuperação e correção para retorno sem encargos congelados foram exercitadas em modo de teste. Estorno da recuperação e cálculo opcional de encargos congelados permanecem pendentes.
- Cancelamento: há prévia para casos simples e simulação de escolhas de manutenção ou devolução por componente. Confirmação, compensação e registro de devolução real não estão concluídos.
- Consulta de registros relacionados a recebimento: apresenta contagens de eventos do contrato e correções de data. Essas contagens incluem eventos anteriores e posteriores, não provam causalidade, não percorrem toda a cadeia de contratos e não autorizam correção ou estorno.

No `server.ts`, `LOANS_ENABLED` e `LOANS_CONTRACT_CONFIRM_ENABLED` vêm desligadas por padrão. As opções de pagamentos, histórico e acordos usadas em testes não são habilitadas pelo servidor de execução. As prévias de cobrança indicam que encargos não estão completos; não habilitar confirmação simplesmente alterando flags.

## Ensaios e verificação

- Os testes automatizados usam dados sintéticos. O serviço possui testes de cálculo, datas, autenticação, dados protegidos e outros; a integração cria PostgreSQL descartável e verifica migrações, isolamento, operações, concorrência, idempotência, falhas transacionais e auditoria.
- Os testes recentes da ficha e da consulta de registros foram executados com respostas simuladas; a verificação de tipos do frontend passou. Testes simulados de interface não substituem validação visual e integrada em navegador.
- O ensaio `npm run test:db` restaurou banco, anexo e chaves em ambiente descartável. A reaplicação isolada de um pagamento posterior gerou novo identificador e não preserva automaticamente vínculos posteriores.
- Um segundo ensaio capturou uma cópia posterior com a origem ainda íntegra e escritas interrompidas. Preservou identificadores e vínculos de pagamento, correção de data e acordo, auditoria e idempotência; verificou migrations, decifração sintética e hashes dos anexos. **Isso não recupera eventos já perdidos quando a origem não está disponível** e não cobre todos os eventos encadeados. A tarefa 6.2 continua aberta.
- Os exemplos documentais e testes existentes não aprovam gates nem comprovam deploy, operação real, recuperação completa, desempenho, todas as condições de concorrência ou todas as integrações.

Para reproduzir os testes do serviço, em `evo-loans-service`, executar `npm test` e `npm run test:db`; o segundo requer Docker e cria recursos descartáveis. Para as telas, em `evo-ai-frontend-community`, usar `npm test -- src/pages/loans src/services/loans` e `npx tsc -b`. Não executar testes que geram Prisma simultaneamente no mesmo serviço no Windows, pois podem disputar o arquivo do motor.

## Tarefas abertas

| Tarefas | Trabalho pendente |
| --- | --- |
| 3.3–3.5 | Encargos recorrentes, DT-01, pagamentos no dia e ocorrência idempotente. |
| 3.8–3.13 | Prorrogação completa, acordo, perda e estorno, cancelamento, DT-02 e fluxos de interface completos. Existem implementações parciais descritas acima. |
| 4.3–4.4 | Completar ficha e histórico das correções encadeadas; validar condições e recursos G2 antes de piloto autenticado G3. |
| 5.1–5.4 | Resolver e validar DT-03; implementar indicadores, relatórios e exportações com autorização e proteção de dados. |
| 6.2–6.3 | Completar e comprovar recuperação de fatos posteriores e consolidar evidências e gates necessários ao uso real. |
| 7.1–7.4 | Fase posterior de WhatsApp: decisões de provedor, remetente, horário e mensagens, seguidas de fila e validações. |

Os detalhes de cada tarefa e seus critérios estão no OpenSpec. Parte do trabalho pode avançar independentemente dos débitos adiados; decisões econômicas não autorizadas, uso real e etapas condicionadas a gates não devem ser antecipados.

## Para retomar

1. Consultar `openspec instructions apply --change implementacao-modulo-emprestimos --json` e os documentos de contexto retornados; confirmar o estado antes de alterar qualquer checkbox.
2. Examinar o código e as evidências existentes para selecionar trabalho independente dos débitos adiados; preservar alterações já presentes no workspace e a independência do Financeiro.
3. Completar cada requisito e seus testes antes de marcar a tarefa. Registrar evidências e limitações nos documentos correspondentes; consultar o dono apenas quando uma escolha econômica realmente não estiver decidida.
4. Antes de qualquer piloto, demonstrar os gates aplicáveis, a recuperação completa de dados e eventos posteriores, a autorização e a integridade de banco, anexos e chaves. Não substituir uma origem operacional pela restauração de um snapshot anterior sem preservar e reconciliar os fatos posteriores.
