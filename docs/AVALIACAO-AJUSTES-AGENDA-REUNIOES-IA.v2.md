# Avaliação técnica do planejamento de ajustes da Agenda — v2

Data: 27/10/2026, no fuso America/Sao_Paulo.

**Parecer: o planejamento cobre o núcleo funcional, mas ainda precisa de ajustes antes de servir como especificação completa de implementação e liberação.** Há contradições de execução, dependências entre fases não declaradas e casos de integridade e recuperação sem comportamento definido. Não é necessário redesenhar o módulo; é necessário fechar esses contratos.

Esta avaliação preserva o planejamento v2 e o código. Os achados abaixo distinguem comportamento observado no código, lacunas do desenho proposto e decisões de produto. Não representam falhas reproduzidas em produção.

## 1. Contexto e verificações realizadas

Foram lidos o índice de `docs`, a documentação geral do jprOS, a especificação da Agenda, os planejamentos v1 e v2, os documentos de setup e troubleshooting, a decisão de outbox, a matriz MCP, o contrato CRM e a política de retenção. Foram consultadas as regras de execução da seção 14.1 do planejamento de Projetos e as referências de evidências desse módulo. As regras específicas de Projetos não foram automaticamente convertidas em novos requisitos da Agenda.

A revisão cruzou esses documentos com rotas, serviços, engine, schema, Dockerfile e testes da Agenda; consumidores de Agenda no frontend; emissão/validação de identidade no Auth; padrão de autenticação do Projects; gateway e manifests da raiz.

Verificações executadas:

- `npm test` em `evo-scheduling-service`: **5 casos passaram**. São testes da engine, sem banco e sem rotas.
- Execução pontual da engine, sem alterações de arquivos, com reunião existente das 10h às 10h30 em 07/01/2030: os slots de 10h e 10h15 não são oferecidos; o das 10h30 é oferecido quando o candidato tem buffers zero. Isso demonstra a necessidade de excluir a própria reunião no reagendamento e de definir como entram os buffers das reuniões existentes.
- Inspeção estática confirmou chamadas de `syncUser` nas quatro telas administrativas e a ausência do serviço de Agenda nos manifests `docker-compose.prod.yml` e `docker-compose.swarm.yaml` examinados.
- A busca pelos nomes das tools e pelo endpoint da Agenda não encontrou um adaptador específico no bot runtime ou no processor. Isso **não prova ausência de integração configurada externamente**: essa configuração precisa ser inventariada.

Não foram consultados dados reais do PostgreSQL, executadas chamadas a provedores de IA, testes concorrentes com banco, implantação ou validação visual da referência externa. O status Git da raiz foi consultado com submódulos ignorados após a consulta recursiva encontrar restrição de acesso aos metadados de um submódulo. Alterações preexistentes foram preservadas.

## 2. O que a v2 já contempla bem

| Tema | Avaliação |
|---|---|
| Lista com filtros no servidor, paginação e navegação | Coberto, com detalhes de contrato a completar. |
| Detalhe e oito blocos de tópicos | Coberto. |
| Edição manual e apresentação como rascunho de IA | Coberto, mas concorrência e atualização parcial estão incompletas. |
| Chaves de IA somente no servidor | Decisão adequada; evita o desenho inseguro da v1. |
| Autenticação e isolamento por dono | Direção adequada; exige completar regras do bot e projeção de identidade. |
| Reserva validada pela engine e trava no banco | Direção adequada; a engine e os caminhos de alteração precisam dos ajustes descritos abaixo. |
| IA assíncrona, preservação do resumo anterior e flag desligada | Coberto conceitualmente; recuperação ainda incorreta. |
| Escopo sem criação automática de tarefas | Preservado. |
| Critérios de aceite e evidências por fase | Boa base, mas os 14 critérios não cobrem os riscos identificados nesta revisão. |

## 3. Achados que precisam entrar no planejamento

### R01 — P1: migração proposta contradiz as regras que a própria v2 adota

**Evidência:** a v2, linhas 13 e 284, adota as regras 1–12 da seção 14.1 de Projetos. A regra 6 determina migração controlada e proíbe `db push` em implantação. Entretanto, A2.1, linha 324 da v2, manda aplicar `db push` no modelo atual do Dockerfile. A seção 8.1 não resolve expressamente essa divergência.

**Consequência:** dois executores podem seguir caminhos incompatíveis. Voltar à imagem anterior também volta a um bootstrap que sincroniza o banco com o schema antigo; pode bloquear a inicialização diante da tabela nova ou demandar intervenção sobre dados.

**Ajuste mínimo:** estabelecer baseline conferida com o banco real, migração aditiva versionada, aplicação em etapa controlada, teste em banco vazio e cópia do existente, backup com restauração verificada e retorno para uma imagem segura e compatível. Não recriar a base nem aceitar perda de dados para resolver divergências. Não afirmar que backup está ausente da v2: ele já é exigido pela regra incorporada; falta concretizar sua execução para a Agenda.

O Prisma distingue `db push`, voltado a prototipação sem histórico de migrações, de migrações versionadas para replicar mudanças entre ambientes. [Documentação oficial do Prisma v6](https://www.prisma.io/docs/orm/v6/prisma-migrate/workflows/prototyping-your-schema).

### R02 — P1: uma geração pode permanecer em PENDING indefinidamente após reinício

**Evidência:** seção 5.2, linha 189: somente na inicialização são interrompidos trabalhos com mais de dez minutos. O trabalho executa na memória do processo.

**Cenário:** geração começa; processo cai após 30 segundos; serviço volta após um minuto. O registro tem menos de dez minutos, permanece `PENDING` e perdeu o executor. Como a limpeza ocorre apenas no início, ele não será corrigido quando completar dez minutos. Novas gerações podem continuar recebendo 409.

**Ajuste mínimo:** definir identificação da tentativa, início e prazo de expiração. Recuperar tentativas órfãs/expiradas por verificação periódica ou durante leitura/nova geração, sem depender de outro reinício. Para uma única instância, pode-se invalidar o trabalho do processo anterior no boot; para múltiplas instâncias, é necessário distinguir dono ativo e trabalho órfão. Não é obrigatório introduzir Redis ou broker.

**Aceite:** reiniciar com trabalho de 30 segundos e verificar que chega a estado terminal e permite nova tentativa. Testar também trabalho realmente ativo em outra réplica, caso essa topologia seja suportada.

### R03 — P1: faltam regras para geração, edição e exclusão concorrentes do resumo

**Evidência:** a v2 prevê trava de geração única e DELETE, mas seu modelo não define tentativa, versão de escrita nem atualização condicional na conclusão.

**Cenários:** o usuário edita durante a geração e o resultado atrasado apaga sua edição; exclui o resumo e o trabalho em curso o recria; inicia nova tentativa e a conclusão de uma tentativa anterior substitui o resultado atual. A confirmação visual antes de regenerar não resolve operações concorrentes em outra aba.

**Ajuste mínimo:** aquisição atômica da tentativa no banco; conclusão condicionada à mesma tentativa e versão; política explícita para PUT/DELETE durante `PENDING`. Pode-se bloquear edição durante geração, ou invalidar a geração ao editar. A exclusão precisa impedir a reaplicação do resultado atrasado. Duas edições manuais devem usar controle de versão para não perder alterações silenciosamente. A chamada externa não deve manter uma transação de banco aberta.

Definir ainda quando limpar `errorCode`, atualizar `editedAt`, `generatedAt`, modelo e prompt. Falha preserva conteúdo e origem anteriores; regeneração concluída deve deixar os selos coerentes com o novo conteúdo.

### R04 — P1: edição parcial conflita com defaults de listas vazias

**Evidência:** linha 177: listas ausentes valem `[]`; linha 184: PUT é parcial; linha 195: cada bloco salva individualmente.

**Consequência possível:** enviar apenas `topics.decisions` e aplicar o schema completo com defaults pode zerar os demais sete blocos. Isso é uma ambiguidade do contrato, não uma implementação de resumo já existente.

**Ajuste mínimo:** separar o schema completo de saída da IA do schema parcial de edição, reutilizando as definições de cada campo. Na edição, campo ausente preserva; `[]` limpa uma lista explicitamente; `""` limpa assunto; `null` limpa URL, se esse for o contrato adotado. Fazer merge dos blocos alterados sobre o registro atual, com versão esperada. Campos desconhecidos são rejeitados.

**Aceite:** editar apenas Decisões preserva os demais blocos e links; duas abas não sobrescrevem silenciosamente o trabalho uma da outra.

### R05 — P1: reativação de reserva pode contornar o bloqueio de conflitos

**Evidência:** `bookings.routes.ts`, linhas 149–155, permite atualizar status diretamente; a proteção proposta em 3.3 cobre criação e reagendamento. `CANCELLED`/`REJECTED` não bloqueiam slots, mas `ACCEPTED`/`PENDING` bloqueiam.

**Cenário:** cancelar A, reservar B no mesmo horário e mudar A para `ACCEPTED` apenas pelo status. Autenticar a rota não elimina a colisão.

**Ajuste mínimo:** definir transições permitidas. Toda transição que volta a ocupar horário deve passar pela mesma trava e validação, ou ser proibida explicitamente. Recusar intervalos incompletos e combinações ambíguas de cancelamento com mudança de horário. Definir cancelamento repetido e a identidade canônica usada nas mutações: o GET aceita id/uid, enquanto os métodos atuais de alteração procuram id.

**Aceite:** cancelar → reservar por outro → reativar não produz duas reservas ativas sobrepostas; concorrer reativação com criação também não.

### R06 — P1: reutilizar getSlots exige adaptações além da trava

**Evidência:** `scheduling.service.ts`, método `getSlots`, usa cliente Prisma global e não recebe `excludeBookingId`; sua consulta contém `startTime >= rangeStart` e `endTime <= rangeEnd`. A engine compara o candidato expandido pelos seus buffers com o intervalo simples das reservas existentes.

**Lacunas relevantes:**

- **Própria reunião:** reagendar para o mesmo horário, ou para um horário parcialmente sobreposto ao antigo, exige excluir a própria reserva. A verificação pontual confirmou a exclusão desses slots pela engine atual quando a reserva permanece na entrada.
- **Buffers de tipos diferentes:** uma reunião existente com 30 minutos de intervalo posterior não é representada com esse intervalo na entrada atual. Um novo tipo com buffer zero pode ocupar esse período. Definir a regra dos buffers das duas reuniões e carregá-los ou preservar o intervalo ocupado correspondente.
- **Reservas antigas longas:** a consulta seleciona intervalos inteiramente contidos na janela. Uma reserva que atravessa toda a janela pode ficar de fora. Consultar por sobreposição, considerando também os buffers aplicáveis.
- **Atomicidade:** a trava só é suficiente se a reconferência e a gravação usarem a mesma transação. Recalcular regras relevantes sob a trava e coordenar alterações de expediente/tipo que possam mudar a validação durante a reserva.
- **Consistência da consulta pública:** aplicar também em GET /slots a relação correta entre dono e tipo ativo, para não oferecer slots que a criação inevitavelmente rejeita.

**Aceite:** testes com reagendamento sobre si mesmo, tipos com buffers distintos, reserva antiga atravessando a janela e alteração simultânea de disponibilidade. Definir que slot ocupado retorna 409; slot fora das regras retorna 422, inclusive quando a pré-consulta já não o encontra.

### R07 — P1: mudanças de autenticação afetam mais telas e dados do que o diagnóstico registra

**Evidência:** chamadas de `syncUser` em `BookingsPage.tsx:60`, `AvailabilityPage.tsx:67`, `EventTypesPage.tsx:57` e `PublicPreviewPage.tsx:32`. A v2 identifica nominalmente a primeira; A0.2 menciona remoção no frontend genericamente.

**Ajuste mínimo:** enumerar as quatro telas nos entregáveis e na regressão. Definir se `/users/sync` é removida ou mantida autenticada durante transição; em nenhum caso aceitar identidade arbitrária do corpo. A projeção canônica deve existir antes de operações que dependam de suas FKs.

Há ainda dois contratos necessários:

- `ensureUser` gera slug pela parte do e-mail anterior a `@`; `username` e `email` são únicos. Pessoas com o mesmo prefixo em domínios distintos podem colidir. Definir desambiguação estável e preservar URLs já publicadas. `PublicPreviewPage.tsx:25` hoje reconstrói o slug pelo e-mail; deve receber o username canônico da API.
- Fazer inventário dos vínculos atuais antes de ativar filtro obrigatório por `sub`. Não presumir que todo registro criado pela rota anônima corresponde à identidade certa; não reatribuir automaticamente por semelhança de nome ou e-mail.

**Aceite:** primeiro acesso em qualquer uma das quatro telas, dois usuários com prefixo igual, alteração de e-mail e preservação de link público existente.

### R08 — P0 para habilitar o bot: credencial de serviço não define autorização por cliente

**Evidência:** seção 3.2 permite consultas e alterações de reservas com um token de serviço. Não define atendentes concedidos, vínculo do cliente/conversa ou origem confiável do bookingId. A tool de cancelamento aceita apenas `bookingId` e motivo. Além disso, a seção 4.1 inclui `summary` no GET de detalhe, embora DA10/seção 7 proíbam acesso do bot aos resumos.

**Consequências:** validar o token identifica o runtime, mas não prova que um cliente pode cancelar a reserva selecionada. Bloquear somente as rotas `/summary` deixa ambígua a exposição do resumo embutido no GET de reserva.

**Ajuste mínimo:** enumerar exatamente as rotas e os campos permitidos ao serviço; filtrar consultas e mutações pelo escopo autorizado do atendente e do atendimento; usar contexto confiável do runtime, sem autorizar por parâmetros inventados pelo modelo. DTO do bot sem tópicos, links de resumo/transcrição nem texto bruto, inclusive nas respostas indiretas. Definir rotação da credencial e recusa externa efetiva: usar o hostname interno é uma escolha do cliente, não um bloqueio de rede.

Inventariar quem executa realmente cada tool — bot, processor ou integração HTTP configurada — antes de dizer que basta alterar exemplos. Se o consumidor não existir, registrar essa situação e manter o acesso de serviço desabilitado até sua implementação e teste, sem bloquear a lista interna por uma integração hipotética.

**Aceite:** cliente A não consulta/cancela reserva de B por troca de ID; token do bot não obtém resumo em nenhuma resposta; chamada externa ao caminho interno é recusada conforme a topologia definida.

### R09 — P1: as fases não são independentes como a tabela afirma

**Evidência:** Fase 1 depende apenas da Fase 0, mas inclui `hasSummary`, cujo modelo só aparece na Fase 2. A linha da lista também navega para uma rota criada na Fase 3. A v2 afirma que Fases 1 e 2 podem andar em paralelo sem especificar integração/liberação.

**Ajuste mínimo:** distinguir desenvolvimento paralelo de implantação independente. Antecipar a migração mínima e o contrato de detalhe, ou declarar dependência de A1.1 em A2.1 e liberar navegação somente após A3.1. Alternativamente, liberar primeiro filtros/lista sem acesso ao detalhe e indicar explicitamente a capacidade parcial.

O schema de tópicos deve estar definido antes dos consumidores das rotas, embora A2.3 venha numericamente depois de A2.2. Isso pode ser entregue num conjunto coeso, sem criar fases extras.

### R10 — P1 para liberação: falta fechar a topologia de implantação da Agenda

**Evidência:** o Compose local publica `3012:3002`, sem bind explícito de loopback. Os manifests prod/swarm examinados não contêm Agenda. O gateway já encaminha o prefixo inteiro, incluindo Authorization, ao mesmo serviço. A v2 concentra as etapas em `docker-compose.yml`.

**Ajuste mínimo:** escolher e documentar o ambiente efetivamente suportado pela entrega; se produção/Swarm fizer parte dela, incluir imagem, serviço, upstream, URL de frontend em runtime, segredos, migração, healthcheck e estratégia de atualização. Se for entrega local, declarar esse limite em vez de pressupor produção pronta.

Para rate limit, especificar proxies confiáveis e origem real do IP, restringir a porta direta e testar cabeçalhos encaminhados falsificados. Com múltiplas réplicas, limites em memória são por processo: decidir limite compartilhado ou restringir a topologia. A documentação do Fastify alerta que cabeçalhos encaminhados podem ser falsificados sem confiança corretamente configurada. [Fastify v5.2 — trustProxy](https://fastify.dev/docs/v5.2.x/Reference/Server/#trustproxy).

### R11 — P1 na Fase 4: limites de execução da IA ainda são incompletos

**Evidência:** timeout de 90 segundos por chamada, nova tentativa em erro transitório e nova tentativa por JSON inválido, mas polling só por três minutos. Não há teto global de tentativas/duração nem orçamento de saída. O limite de 120 mil caracteres é o mesmo para qualquer modelo configurado.

**Ajuste mínimo:** definir número máximo total de chamadas e duração total, comportamento de 429/Retry-After, limite de concorrência por usuário e global, limite de saída e erro por contexto excedido/truncamento/recusa. O teto de entrada precisa ser compatível com o modelo homologado; quantidade de caracteres não garante caber na janela de tokens. Não é necessário implementar fragmentação.

O polling deve terminar com estado compreensível e permitir retomar a consulta após navegação; três minutos não podem virar uma indicação falsa de falha enquanto o servidor continua. Texto vazio/espaços deve ser rejeitado. Nenhum corpo bruto de erro do provedor deve chegar aos logs ou ao usuário.

A abordagem de um cliente compatível é viável. O endpoint Gemini pode ser registrado como `https://generativelanguage.googleapis.com/v1beta/openai/`, com composição de caminho sem barra duplicada e modelo homologado no ambiente. Isso não substitui o teste do provedor escolhido. [Documentação oficial de compatibilidade Gemini](https://ai.google.dev/gemini-api/docs/openai).

### R12 — P1: fuso, disponibilidade e filtros precisam de uma fonte consistente

**Evidência:** a v2 fala em “fuso do atendente” sem escolher entre `User.timeZone`, `Schedule.timeZone` e o navegador. `getSlots` prioriza o Schedule; salvar disponibilidade atualiza o Schedule, não o User. A página pública usa inicialmente o fuso retornado pelo User.

**Ajuste mínimo:** definir a fonte dos filtros/exibição e a fonte do expediente, retorná-las explicitamente e manter o comportamento consistente quando forem diferentes. Validar nomes IANA, datas civis reais, horários e ordem dos intervalos; ISO com hora precisa de offset explícito. Para filtro por dia, preferir limite final exclusivo no início do próximo dia no fuso escolhido.

`saveUserSchedule` apaga disponibilidades e recria fora de transação (`scheduling.service.ts:349` e `:354`). Uma falha intermediária pode deixar a agenda vazia. Tornar a substituição atômica; isso afeta diretamente a promessa de que reservar e consultar usam a mesma disponibilidade.

Na listagem, fechar: inteiros positivos para limit, offset inteiro não negativo, desempate por id na ordenação, reset de página ao mudar filtros e preservação de paginação/ordenação ao voltar. Busca por telefone exige normalizar tanto a consulta quanto o valor armazenado/consultado; apenas retirar os símbolos do termo não encontra necessariamente um telefone formatado. Não incluir `contains: ""` quando o termo não tiver dígitos.

### R13 — P1 na Fase 0: copiar o AuthClient não basta para cumprir o contrato descrito

**Evidência:** o Auth emite `sub`, e-mail e nome, compatíveis com a direção da v2. Entretanto, `evo-projects-service/src/auth/auth-client.ts:96` trata qualquer HTTP diferente de 200 como token não autorizado; 5xx não vira indisponibilidade. O middleware usa o id da validação remota sem comparação explícita com o sub verificado localmente. O emissor tem audiência padrão legada `'[]'`.

**Ajuste mínimo:** distinguir token inválido/revogado (401) de falha do Auth (503); comparar identidade remota com sub; definir política de audiência compatível com tokens reais, sem aceitar inadvertidamente tokens destinados a outro consumidor. Enumerar todas as mutações sensíveis, incluindo exclusão de resumo e alterações de disponibilidade/tipo. Usar dados canônicos atuais para projeção, sem reverter perfil com claims antigos de uma sessão.

**Aceite:** JWT real de teste, revogação, Auth respondendo 500, timeout, divergência de identidade, claims ausentes e comportamento de cache. Não foi reproduzida falha de login no ambiente real nesta revisão.

## 4. A v2 contempla todos os ajustes originalmente pretendidos?

**Não integralmente.** Algumas mudanças são simplificações explícitas; outras ficaram sem encaminhamento.

| Requisito anterior ou comportamento existente | Situação na v2 | Decisão necessária |
|---|---|---|
| Lista executiva, filtros, detalhe e oito blocos | Preservados | Completar os contratos técnicos acima. |
| Editar o título da reunião no cabeçalho | Previsto na v1, linha 128; não especificado na v2 nem no PATCH atual | Incluir atualização autenticada, validação e UI, ou registrar retirada expressa. |
| Usar credencial de IA já cadastrada no CRM | Adiado explicitamente em D1/DA04 | Confirmar que env atende à primeira entrega; não considerar esse requisito entregue. |
| Escolher provedor/modelo pela interface | Substituído por configuração do serviço | É mudança de experiência; registrar aceitação se fizer parte da intenção original. |
| Fornecer somente link de documento para processamento | A v1 é ambígua; a v2 exige rawText e trata links como referências | Declarar “colar texto é obrigatório; não há importação automática de Docs/Meet”. Não implementar fetch arbitrário de URL. |
| Reagendar pela lista | Tornou-se opcional em D4 | Definir antes de encerrar o escopo funcional. |
| Criar reunião sem tipo de evento | Existe no código e no schema de tool; 3.3 passa a exigir tipo válido | Manter modalidade manual com regras explícitas ou exigir tipo e atualizar todos os consumidores, incluindo reservas antigas sem tipo. |
| Editar/remover links sem IA habilitada | API de edição existe no plano, mas o formulário de links é descrito no modal de geração | Prever edição independente da geração, inclusive quando AI_ENABLED=false. |
| Não gerar tarefas automaticamente | Preservado | Nenhuma integração com Projetos é necessária para os tópicos. |

D2 também requer definição antes de habilitar armazenamento bruto: prazo, remoção e acesso. Manter `false` não bloqueia a primeira entrega. A cascata de exclusão do Booking é uma garantia do banco; não significa que já exista endpoint para excluir reunião, pois o fluxo atual é cancelamento. Não é necessário criar uma nova operação destrutiva apenas para testar a FK.

## 5. Complementos sugeridos aos critérios de aceite

Os testes abaixo complementam T-A01–T-A14; não foram executados nesta revisão, exceto as observações pontuais da engine descritas na seção 1.

| Teste sugerido | Evidência exigida antes de liberar a capacidade |
|---|---|
| V-A01 — Migração e retorno | Banco vazio e cópia com dados; restauração conferida; retorno sem perda e sem reabrir API anônima. |
| V-A02 — Reinício precoce | PENDING com menos de dez minutos converge para estado terminal e permite tentar novamente. |
| V-A03 — Concorrência do resumo | Gerar/editar/excluir/regenerar em paralelo não perde edição nem ressuscita conteúdo excluído. |
| V-A04 — PUT parcial | Alterar um bloco preserva os outros sete e os links; omissão e limpeza têm semântica diferente. |
| V-A05 — Reativação | Reativar cancelada/rejeitada não contorna conflito nem disponibilidade. |
| V-A06 — Reagendamento | Exclui apenas a própria reserva, conserva bloqueios das outras e respeita buffers. |
| V-A07 — Intervalos e buffers | Tipos diferentes e reservas longas antigas bloqueiam os intervalos corretos. |
| V-A08 — Perfil e telas | Quatro telas, primeiro acesso, slug duplicado, alteração de e-mail e links existentes. |
| V-A09 — Bot e isolamento | Cliente/atendente fora do escopo não é acessado; resumo não aparece nem embutido em DTO. |
| V-A10 — Fases implantáveis | Cada capacidade liberada tem tabela, API e tela presentes; sem link quebrado. |
| V-A11 — Gateway e topologia | Auth, IP real, limite de taxa, porta direta e rota de serviço verificados no ambiente escolhido. |
| V-A12 — IA sob falha | 429, 5xx, timeout, JSON inválido, resposta truncada, limite de contexto e polling interrompido. |
| V-A13 — Fuso e grade | Filtros/exibição coerentes; alteração de grade atômica; fusos distintos e datas inválidas. |
| V-A14 — Auth | Revogação, indisponibilidade, identidade divergente e audiência conforme contrato homologado. |
| V-A15 — Regressão funcional | Criação manual/pública, cancelamento, tipagem opcional ou obrigatória decidida, título e links conforme escopo aceito. |

Os testes da engine usam datas fixas de novembro de 2026 e dependem do relógio real. Devem usar relógio controlado ao integrar a nova suíte; passar hoje não garante que continuarão passando após essas datas.

## 6. Ordem recomendada para corrigir o planejamento

1. Fechar a tabela de cobertura funcional e as decisões efetivamente necessárias; manter escolhas reversíveis já adequadas, como IA desligada e não persistir transcrição.
2. Resolver migração, ambiente e dependências das fases. Tornar explícito o que pode ser desenvolvido em paralelo e o que pode ser liberado separadamente.
3. Completar identidade, projeção, consumidores e escopo do bot; adaptar engine e transições de reservas.
4. Definir merge parcial, versão do resumo, tentativas de geração e recuperação de trabalho órfão.
5. Acrescentar os testes acima às etapas correspondentes e registrar evidências por capacidade.

**Conclusão:** aprovar a direção da v2, mas revisar os pontos acima antes de considerá-la completa. Nenhum planejamento garante ausência de problemas técnicos; neste caso já há problemas previsíveis que podem ser eliminados documentalmente e depois verificados por testes. A implementação pode continuar enxuta, sem obrigar fila externa, novo sistema de permissões por papéis ou integração com Projetos fora do escopo.
