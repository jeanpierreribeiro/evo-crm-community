# Ensaio de recuperação — escopo atual

Em 29/10/2026, `npm run test:db` criou banco e diretórios descartáveis, registrou carteira, cliente cifrado e anexo sintéticos e produziu uma cópia do schema `loans` e do arquivo. O teste restaurou o schema em outro banco, recuperou o CPF com as mesmas chaves e comparou o anexo restaurado com o hash registrado. Após o snapshot, registrou outro cliente na origem: ele estava ausente da restauração e foi reaplicado no destino usando os dados e a chave de operação conhecidos. A origem não foi sobrescrita.

O ensaio também registrou um recebimento sintético de R$ 25,00 após o snapshot e o reaplicou no banco restaurado com os mesmos dados, ator e chave de operação. Os componentes e o saldo foram comparados com a origem; repetir a operação no destino não gerou outro recebimento. A reaplicação criou **outro identificador de pagamento**: ela não preserva automaticamente vínculos de correções, acordos ou outros fatos posteriores. Esse teste isolado não valida a recuperação dessas dependências nem é um procedimento aprovado para uso real.

Em outro ensaio, com a origem ainda íntegra e escritas interrompidas, foi produzida uma cópia posterior dos dados e arquivos. Nessa cópia havia um recebimento, uma correção de data histórica, um acordo após o recebimento e um anexo, todos posteriores ao primeiro snapshot. A restauração isolada preservou os identificadores do recebimento, da correção e do acordo, os vínculos com o pagamento e os contratos de origem e destino, as alocações, a auditoria e as chaves de idempotência; repetição das operações devolveu os resultados originais. O teste verificou as migrations, a decifração de um dado sintético e o hash de todos os anexos copiados. Essa alternativa depende de uma origem íntegra e de uma cópia coerente: não recupera fatos que já foram perdidos nem demonstra recuperação de todos os tipos de evento encadeado.

A recuperação de fatos posteriores exige fonte externa íntegra, conferência humana e teste específico de cada operação, suas dependências e idempotência; não se deve presumir que um snapshot contém fatos posteriores.

Antes de uma recuperação operacional:

1. Interromper escritas e preservar o estado atual do banco, volume de anexos, registros operacionais e chaves, sem restaurar sobre a única cópia disponível.
2. Selecionar um conjunto coerente de banco e anexos, identificar as versões necessárias das chaves e restaurar em ambiente isolado. O volume Swarm deve permanecer no nó e volume configurados para Empréstimos.
3. Verificar migrations, permissões, acesso por carteira, leitura dos dados cifrados e correspondência dos hashes dos anexos. Arquivos sem registro e registros sem arquivo precisam ser investigados; não removê-los automaticamente quando houver confirmação de gravação incerta.
4. Identificar e conferir os fatos posteriores ao ponto de backup com as fontes disponíveis. Reaplicá-los apenas por procedimentos aprovados e testados para cada tipo de fato, preservando os vínculos e as chaves de operação; quando isso não for possível, manter a operação suspensa para investigação.
5. Validar resultados e integridade antes de autorizar o retorno das escritas. Nunca substituir a origem operacional por uma restauração anterior sem preservar e reconciliar os fatos posteriores.

O procedimento operacional completo, a montagem e recuperação segura das chaves, a reconciliação de arquivos órfãos e os ensaios de operações futuras permanecem pendentes. Este documento não aprova o gate G0 nem libera uso real.

## Conferência de anexos restaurados

O utilitário de leitura `node scripts/check-attachment-integrity.mjs <diretório-absoluto>` compara os registros de anexos do banco indicado por `DATABASE_URL` com o diretório informado. Execute após `npm run build`, com as escritas interrompidas e apontando para uma restauração isolada e coerente. Ele informa arquivos ausentes, tamanho ou hash divergente, entradas que não são arquivos comuns e arquivos órfãos; não modifica ou remove arquivos. Saída 0 indica ausência de divergências detectadas, 1 indica divergências e 2 indica erro de execução. O resultado contém identificadores internos de arquivos e deve ser tratado como informação operacional restrita.

Em 29/10/2026, `npm test` verificou detecção de ausência, corrupção, tamanho divergente e órfão preservado; `npm run test:db` executou a conferência sobre os anexos da restauração sintética posterior. Isso não comprova consistência de uma cópia feita durante escritas, recuperação de eventos perdidos, disponibilidade de todas as chaves ou prontidão para produção.

## Ensaio isolado de backup físico e WAL

Em 29/10/2026, `node --test test/integration/pitr.test.mjs` passou usando containers PostgreSQL 16 descartáveis e tabelas sintéticas. O ensaio criou backup físico, registrou uma transação posterior com pagamento, atualização de saldo e vínculos de auditoria e idempotência, arquivou o segmento WAL correspondente e copiou backup e arquivo para uma área separada. Depois removeu o container de origem, restaurou o backup em outro container e confirmou os valores e vínculos sintéticos.

O mesmo ensaio foi ampliado com migrations do módulo e operações reais sobre dados sintéticos: criou contrato antes do backup e, depois dele, registrou pagamento, uma carteira e um anexo. Com a origem removida, restaurou o banco pelo backup e WAL e uma cópia separada do volume de anexos, feita após interromper escritas. Confirmou o saldo, o identificador e as alocações do pagamento pela repetição idempotente, sua auditoria, a carteira e sua chave de operação, o hash e download do anexo e a decifração de CPF usando chaves sintéticas lidas novamente de um arquivo temporário separado do banco. Esse arquivo não representa um cofre operacional nem prova suas permissões, retenção ou recuperação.

O cenário posterior ao backup também passou com uma cadeia de recebimento, acordo, novo recebimento no destino, perda, recuperação parcial e correção da perda sem encargos. Após a restauração, foram conferidos os identificadores e vínculos de origem e destino, auditoria, repetição das operações com suas chaves e saldo restante de R$ 60,00. A simulação utiliza taxa zero e não resolve as regras econômicas ou correções encadeadas pendentes. Na restauração sem o WAL posterior, os fatos posteriores estavam ausentes.

Na restauração completa, `npm run test:db` também verificou a integridade das migrations conhecidas, a negação de DDL ao usuário da aplicação e a recusa de consulta a pessoa sem acesso à carteira. Esses ensaios usam roles e usuários sintéticos e não substituem a validação das permissões e identidade no ambiente de operação.

O mesmo ensaio testou chaves sintéticas diferentes: a decifração falhou e a repetição protegida do acordo foi recusada, sem criar outro acordo. Isso verifica uma contraprova de chave incorreta; não demonstra recuperação do cofre, de todas as versões históricas de chave ou das permissões de acesso a elas.

Em uma segunda restauração, o segmento WAL que continha os eventos posteriores foi removido apenas da cópia descartável. O PostgreSQL iniciou, mas o saldo retornou ao valor anterior e o pagamento e a carteira posteriores estavam ausentes. A cópia do anexo posterior apareceu como órfã na conferência. Esse achado prova que a disponibilidade do banco não confirma que todos os eventos foram recuperados. A detecção do órfão dependeu da existência de anexo posterior: sem um anexo divergente, a conferência de arquivos não detecta pagamentos perdidos. É necessária uma referência externa íntegra do ponto esperado e reconciliação dos fatos; não se deve concluir que o histórico está completo apenas porque o servidor iniciou ou porque a verificação de anexos passou.

O teste também conservou fora do container de origem a posição `pg_current_wal_flush_lsn()` obtida depois dos fatos sintéticos e a comparou com `pg_last_wal_replay_lsn()` nas restaurações. A restauração completa alcançou o ponto registrado; a restauração sem o segmento posterior não o alcançou. Essa referência ficou apenas na memória do teste: não existe ainda mecanismo operacional para registrá-la de forma independente, íntegra e durável. A posição registrada indica WAL persistido na origem, não comprova que foi arquivado ou que fatos confirmados depois dela foram recuperados; a comparação isolada também não substitui a identificação da origem, da linha do tempo, a integridade do backup e a reconciliação de anexos.

Este é um ensaio técnico, não uma implantação de backup. Não demonstra recuperação ou guarda operacional das chaves, cópia de anexos durante escritas, todos os eventos encadeados, interrupções antes do arquivamento, nem a continuidade e durabilidade dos segmentos. A recuperação somente alcança os eventos presentes no backup e no WAL disponível. A configuração usa caminhos temporários descartáveis e não deve ser aplicada diretamente em produção. A tarefa 6.2 está concluída no escopo do ensaio descartável; antes de uso real, permanece necessário integrar e testar uma estratégia apropriada ao PostgreSQL compartilhado, aos anexos e às chaves, incluindo perda ou atraso de WAL e reconciliação. Nenhum gate é aprovado por este ensaio.

## Critérios de parada da recuperação

Não retomar escritas enquanto qualquer uma destas condições permanecer sem resolução:

- O conjunto disponível não comprova a origem e a linha do tempo do banco, a integridade da cópia base e do WAL necessário ou o ponto mínimo de recuperação esperado por referência externa íntegra. Uma posição de WAL obtida apenas na origem perdida não é recuperável por si só; uma posição antiga não comprova eventos posteriores a ela.
- A restauração não alcança o ponto esperado, ou há fatos confirmados conhecidos depois desse ponto que não foram recuperados e reconciliados. Não repetir operações por tentativa: isso pode gerar novos identificadores ou duplicar efeitos.
- Há anexo registrado ausente, conteúdo com hash ou tamanho divergente, entrada inesperada ou arquivo órfão ainda não reconciliado. Preservar as evidências e não excluir automaticamente arquivos sem registro.
- Alguma versão necessária de chave de cifragem ou de índice está indisponível, não corresponde ao conjunto restaurado ou não passou na conferência controlada de dados sintéticos e de metadados. Nunca registrar chaves ou dados pessoais completos nos relatórios do ensaio.
- Migrations, papéis de banco, acesso por carteira ou vínculos e saldos dos fatos conhecidos divergirem. Aplicar migrations não é substituto para recuperar fatos ausentes.

Esses critérios orientam a avaliação e não são uma garantia de recuperação nem um procedimento de corte para o ambiente real. A operação do PostgreSQL compartilhado, a cópia coerente dos anexos e a guarda e recuperação das chaves ainda precisam ser definidos e ensaiados no ambiente apropriado antes da liberação.
