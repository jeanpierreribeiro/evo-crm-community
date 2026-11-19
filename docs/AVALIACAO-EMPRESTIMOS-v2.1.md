# Reavaliação integral do plano de Empréstimos v2.1

> **Registro histórico:** este relatório retrata a v2.1 antes das decisões e validações posteriores. Consulte o [plano vigente](../solicitacao-implementacao-emprestimos.md) e o [detalhamento de regras e cenários](emprestimos/REGRAS-E-CENARIOS-v2.1.md) para o estado atual.

Data: 28/10/2026. Objeto: [plano vigente](../solicitacao-implementacao-emprestimos.md), após a rodada de decisões do dono.

**Conclusão:** as decisões principais estão registradas, mas ainda existem ambiguidades capazes de produzir cobranças, cancelamentos e indicadores diferentes. A fundação técnica pode ser preparada; os comportamentos afetados não devem ser considerados especificados ou homologados antes dos fechamentos abaixo.

Este relatório não altera decisões nem autoriza implementação. As recomendações de negócio são propostas, não aprovações. Financeiro e Empréstimos continuam independentes. Não haverá importação da planilha nesta entrega.

O plano foi preservado sem edição. SHA-256 da versão examinada: `35EEC875BFA2897D659B9001AD171D41BBE2A7790113561647C5D814DC734BC3`. As linhas citadas referem-se a essa versão.

## 1. Pontos de negócio que ainda precisam ser fechados

São seis grupos de decisão remanescentes, não uma promessa de seis perguntas individuais. Cada grupo pode precisar de exemplos para resolver seus detalhes. Não é necessário voltar a perguntar o que já foi escolhido.

### L01 — Pagamento só de juros quando existe multa

**Evidência:** RN-08 põe multa antes de juros contratuais; RN-09 associa pagamento só de juros à prorrogação (linhas 208–209).

**Exemplo:** o cliente deve R$ 700 de principal, R$ 140 de juros e R$ 20 de multa. Entrega R$ 140 dizendo que está pagando os juros. Pela ordem já aprovada, R$ 20 quitam a multa e apenas R$ 120 quitam os juros. Ainda restam R$ 20 de juros antigos.

**Falta definir:** se a prorrogação exige quitar todos os juros antigos ou se permite carregar a parte não paga; como isso aparece na operação. Não presumir que selecionar “só juros” ignora a multa ou concede desconto.

**Recomendação:** manter a ordem aprovada e apresentar quanto é necessário para quitar multa e juros, distinguindo o pagamento de uma eventual concessão de desconto ou transferência de saldo. Em parcelados, estabelecer quais componentes podem compor a base negociada dos juros e como remanejar parcelas seguintes parcialmente pagas.

**Aceite necessário:** exemplo acima, pagamento insuficiente, parcela com pagamento anterior e alteração de vencimentos futuros sem modificar alocações já confirmadas. Bloqueia a conclusão de rolagem em G2.

### L02 — Cancelamento com devolução depois de recebimentos

**Evidência:** RN-10 diz que estorno não comprova devolução bancária; RN-16 exige estornar pagamentos antes de cancelar e registrar a devolução do dinheiro emprestado (linhas 210 e 224).

**Exemplo:** houve entrega de R$ 1.000 e recebimento de R$ 200. Estornar o registro dos R$ 200 não informa se esse dinheiro foi devolvido ao cliente. Se ele ficou com o credor, exigir outra devolução de R$ 1.000 pode exceder o dinheiro que falta recuperar. Se os R$ 200 incluíam juros, também é preciso determinar o tratamento desses juros no cancelamento.

**Falta definir:** valor e direção de cada devolução real; se os recebimentos anteriores serão devolvidos ou compensados; tratamento de juros/encargos já recebidos. A exigência aprovada de estornar antes do cancelamento permanece, mas deve ser acompanhada do registro correto do dinheiro efetivamente movimentado.

**Recomendação:** uma prévia de cancelamento com entrega original, recebimentos, estornos, devoluções/compensações e valor ainda necessário. Cancelamento com dinheiro entregue e cancelamento por erro sem entrega precisam produzir históricos distintos. Isso é controle operacional de Empréstimos, sem lançamentos no Financeiro.

**Aceite necessário:** sem entrega; entrega sem pagamento; entrega com pagamento de principal; pagamento de juros; devoluções em data posterior. Bloqueia cancelamento operacional em G2 e sua apresentação em G4.

### L03 — Histórico antigo incompleto e correção posterior

**Evidência:** modelo e D8 admitem composição desconhecida; cadastro manual exige todas as parcelas e sugere principal/juros; RN-04 impede ajuste abaixo do liquidado (linhas 169, 191, 358–367 e 422).

**Falta definir:** como cadastrar valor recebido que inclui multa/mora desconhecidas; como tratar parcela considerada paga por valor menor após um desconto antigo; o que fazer quando parcelas reais diferem do cronograma calculado; como corrigir uma data estimada quando a data exata for descoberta.

**Recomendação:** preservar valor conhecido, marcar composição não confirmada e exigir conferência do saldo remanescente. Não preencher automaticamente a diferença como juros, perdão ou pagamento. Componentes desconhecidos não devem ser obrigatoriamente distribuídos para fazer um indicador parecer completo. O dono precisa escolher se esses casos podem ser confirmados com ressalva ou permanecem em rascunho até conferência.

**Parte técnica:** entrada histórica deve ter prévia, confirmação atômica e chave idempotente próprias, incluindo contrato, parcelas e recebimentos. A lista atual de operações idempotentes não descreve esse comando composto. Detectar repetição de uma mesma submissão não equivale a detectar dois cadastros manuais independentes do mesmo contrato: definir identificação/aviso de possível duplicidade sem impedir contratos legítimos parecidos.

**Aceite necessário:** desconto histórico, encargos desconhecidos, pagamento parcial histórico, data estimada corrigida, cronograma negociado e repetição após timeout. Bloqueia os casos incompletos em G2/G5, não o cadastro de contratos novos completos.

### L04 — Perda, recuperação e retorno à cobrança

**Evidência:** RN-18 congela o valor e permite recuperação; D11 deixa composição e indicadores pendentes; RN-14 deriva cliente de contratos confirmados; a tabela K1–K8 não fecha a elegibilidade das perdas (linhas 217–226, 248–264 e 425).

**Falta definir:** se a baixa abrange sempre todo o saldo ou pode ser parcial; quais componentes são recuperados primeiro; se o restante continua congelado após recebimento parcial; se uma marcação errada pode ser desfeita e a partir de quando voltam os encargos.

**Recomendação:** exibir dívida em cobrança e dívida marcada como perda separadamente, com perda original, recuperado e perda restante. Não classificar automaticamente como quitado um cliente apenas porque sua dívida deixou de ser cobrada. A regra de retirar da cobrança já exclui perdas de mensagens automáticas; falta tornar essa exclusão explícita em T6.4.

**Aceite necessário:** perda parcial ou rejeição dessa modalidade, recuperação de componentes, estorno da recuperação, correção da baixa e efeitos em K1/K3/K4/K6/K7/K8. Bloqueia perda/recuperação em G2 e seus indicadores em G4.

### L05 — Encargos no dia do pagamento e na modalidade de 30 dias

**Evidência:** RN-06 define início, dias reais, alternativa por 30 dias, saldo após pagamentos e ausência de capitalização; RN-08 permite recebimentos retroativos sem recálculo automático dos encargos posteriores (linhas 196–208).

**Falta definir:** se o pagamento ocorrido no dia de uma multa recorrente reduz a base antes ou depois da multa; se o dia efetivo do pagamento entra na mora; na modalidade de 30 dias, como um pagamento parcial no meio do bloco altera a cobrança do dia 30. A ordem exata entre mora e outros encargos também ficou agrupada em RN-08.

**Exemplo:** parcela de R$ 1.000, redução do saldo-base em R$ 400 no dia 15, juros de 1% por bloco de 30 dias. Cobrar sobre o saldo de R$ 600 do dia 30 gera R$ 6; considerar os saldos durante o período pode gerar outro resultado. A especificação precisa selecionar uma regra, sem inventar uma terceira modalidade.

**Parte técnica:** no proporcional diário, dividir a linha do tempo por mudança de mês e mudança de saldo; não aplicar o saldo final a todo o atraso. Preservar cálculos já confirmados quando chegar lançamento retroativo, conforme a decisão existente, e mostrar a divergência para ajuste manual. Fixar o ponto de arredondamento e a ordem para eventos na mesma data.

**Aceite necessário:** meses de 28/29/30/31 dias; travessia de mês; múltiplos pagamentos parciais; dias 29/30/31/60; pagamento no dia da multa; dispensa de multa sem reaplicação; lançamento retroativo. Bloqueia a conclusão do cálculo de encargos em G2.

### L06 — Desfazer operações que têm outras operações depois delas

**Evidência:** RN-10 bloqueia estorno isolado quando há dependência, mas deixa desfazer a dependência “quando permitido”; RN-16/RN-17 deixam eventos posteriores pendentes; RN-04 restringe ajustes em contratos encerrados (linhas 191, 210 e 224–225).

**Exemplo:** um recebimento foi registrado errado, depois houve acordo e um pagamento no novo contrato. Bloquear o primeiro estorno protege o saldo, mas ainda falta um caminho permitido para corrigir o erro.

**Falta definir:** quais correções podem ser feitas em sequência reversa e quais exigem uma nova operação corretiva; quem vê os impedimentos e como proceder sem apagar história. Isso inclui perda após pagamento e estorno de recuperação.

**Recomendação:** começar com reversão explícita da operação mais recente, sem desfazer dinheiro ou acordos silenciosamente em cadeia. Detalhar os casos em uma matriz de transições e dependências. Essa proposta ainda precisa de aceite quanto ao procedimento operacional.

**Aceite necessário:** pagamento → prorrogação → pagamento; pagamento → acordo → pagamento no destino; perda → recuperação → estorno; ajuste que muda o saldo usado por operação posterior. Bloqueia os fluxos de correção correspondentes em G2.

## 2. Correções que não exigem repetir decisões do dono

### L07 — CPF pendente: restou orientação antiga incompatível

Na tabela de qualidade de dados, a linha “CPF inválido” ainda recomenda não autorizar novo crédito até saneamento (linha 97). RN-15, D8 e T1.5 permitem novo empréstimo com CPF pendente. Embora a tabela se declare histórica, sua coluna “Tratamento” pode ser interpretada como regra vigente. O mapeamento das colunas também descreve CPF apenas como “único e validado” (linha 57).

**Correção:** marcar a proibição como superada e alinhar o mapeamento com CPF opcional/pendente, unicidade por carteira somente quando válido. Não voltar a perguntar se o dono permite novos empréstimos: já permite.

### L08 — Fonte da planilha ainda aparece como tarefa de Fase 0

O trecho histórico manda registrar arquivo/aba/hash na Fase 0 (linha 43), enquanto o restante elimina a planilha como pré-requisito de liberação (linhas 24, 360 e 394).

**Correção:** deixar a verificação da fonte como opcional para pesquisa histórica; fonte ausente não bloqueia G0–G5. Os exemplos sintéticos do motor devem ser suficientes para validar as regras selecionadas. Não reintroduzir importação.

### L09 — O exemplo de atraso e o script continuam baseados na regra antiga

A fórmula de 30 dias é explicitamente histórica, mas a tabela de exemplos ainda apresenta R$ 441,62 para 21 dias sem indicar as datas ou a modalidade (linhas 198–202 e 236). A alternativa atual por blocos completos não cobra proporcional de 21/30; logo esse exemplo também não demonstra a modalidade alternativa aprovada.

**Verificação executada:** `node docs/emprestimos/validar-exemplos.mjs` passou suas dez assertivas. Isso reproduz exemplos antigos, não valida RN-06 atual.

**Contraprova sintética:** com base constante de R$ 430,01, taxa ilustrativa de 1%, exatamente 21 dias computáveis num mesmo mês e arredondamento ao final, a mora é R$ 3,23 em mês de 28 dias, R$ 3,01 em mês de 30 e R$ 2,91 em mês de 31. Com exatamente uma multa ilustrativa de R$ 8,60, os totais são respectivamente R$ 441,84, R$ 441,62 e R$ 441,52. Valores reproduzidos separadamente por aritmética inteira; taxas não são novos padrões aprovados.

**Correção:** substituir o exemplo normativo por datas e parâmetros explícitos e acrescentar testes das regras atuais. Preservar exemplos antigos somente com identificação de sua finalidade histórica.

### L10 — Taxa zero está simultaneamente permitida e pendente

O escopo diz que empréstimos de dinheiro sem juros ainda dependem das regras de produto (linha 133), mas RN-02 aceita taxa não negativa, trata taxa zero e G1 a testa (linhas 189 e 390).

**Correção:** registrar uma posição única. A existência de cálculo para taxa zero não prova autorização de produto. Se não houver decisão anterior específica, fazer uma confirmação curta antes de liberar essa opção; não confundir empréstimo de dinheiro sem juros com financiamento de bens, que está excluído.

### L11 — Painel e elegibilidade ainda usam expressões anteriores às decisões

K6 afirma “mesmo se D11 vier a incluir perdas”, embora perdas já tenham sido aprovadas (linha 262). K1 menciona componentes capitalizados, mas RN-17 proíbe novos juros sobre juros e multas anteriores. A expressão deve restringir qualquer capitalização às bases efetivamente autorizadas; não transformar juros antigos em principal novo por conveniência do modelo.

**Correção:** alinhar linguagem e criar uma tabela única de inclusão por estado para cobrança, indicadores, relatórios e notificações. Particularmente, contrato histórico/transferido aceito, perda e cancelamento precisam de tratamento explícito; RN-14 não deve perder dívida elegível por filtrar apenas um rótulo de ciclo de vida.

## 3. Especificações técnicas ainda necessárias

Os itens desta seção cabem à equipe. Só parâmetros de operação, como responsáveis e tolerância à indisponibilidade/perda de dados, precisam de validação do dono. Não transformar escolha de algoritmo, banco ou nomes de endpoints em nova rodada de perguntas de negócio.

### L12 — Fechar o motor monetário e os limites da simulação

RN-03 autoriza ajustar a última parcela, mas não define o total-alvo e a composição Price. Documentar a ordem: juros do período, amortização, saldo e última prestação. Pelo algoritmo ilustrativo do script, R$ 1.000 a 1% em três parcelas fechariam com R$ 340,02, R$ 340,02 e R$ 340,03; esse resultado é proposta técnica a validar, não decisão adicional do dono.

Definir também precisão máxima, escala de taxa, principal máximo, quantidade de parcelas, limite de datas, BRL explícito para esta entrega, componentes não negativos e rejeição de cronogramas incompatíveis com centavos. Validar primeira parcela irregular e impedir que os componentes antigos de um acordo entrem na base Price geradora de novos juros. Persistir a versão do algoritmo, não apenas a taxa.

### L13 — Materialização de encargos e consultas históricas

RN-06 manda persistir cálculo; a API aceita `asOf`; K7 usa história diária; pagamento retroativo não recalcula encargos automaticamente. Falta dizer quando nasce um encargo e como saldo calculado, saldo persistido e ajustes se reconciliam.

**Recomendação técnica:** uma função determinística por contrato/parcela/data e uma identidade estável para cada ocorrência de multa e intervalo de mora. Consultas/prévias não devem criar dívida adicional por serem repetidas. Operações confirmadas materializam os efeitos de maneira atômica e auditada, respeitando dispensas já dadas. Não depender de abrir a tela para a dívida começar a atrasar.

Especificar se consulta histórica mostra o que se sabe hoje sobre aquela data ou o que estava registrado naquela data; datas efetiva e de registro permitem distinguir, mas não escolhem o significado. Manter exportação e painel coerentes, incluindo correções retroativas. A prévia deve detectar mudança de data e parâmetros mesmo sem mudança de `version` do contrato.

### L14 — Carteiras: administração, troca de contexto e diretório Auth

A autorização por carteira está bem estabelecida, mas faltam contratos para capacidade global de criar carteira versus capacidade de administrar carteiras específicas, criação do primeiro responsável, administração da carteira recém-criada, perda do último administrador e suspensão de carteira. Suspender cadastro não pode apagar dívida ou conceder a terceiros acesso aos dados.

**Evidência nova de código:** `evo-auth-service-community/app/controllers/api/v1/users_controller.rb:233` exige `users.read` na listagem de usuários. Um designado apenas em Empréstimos não necessariamente possui essa permissão do Auth. Definir como o seletor resolve identidades existentes com dados mínimos sem pressupor permissão global nem criar login alternativo. Testar usuário designado localmente sem papel administrativo no Auth; 403 e indisponibilidade não podem ser apresentados como “pessoa não existe”.

No frontend, chaves de cache, formulários, exportações e respostas HTTP atrasadas devem incluir o contexto da carteira. Trocar de carteira enquanto uma prévia está aberta precisa impedir confirmação na carteira errada. No servidor, testar revogação concorrente com escrita, além de leitura/exportação por ID direto. Definir código uniforme para recurso fora de escopo, sem revelar sua existência.

**Aceite:** criação atômica de carteira e responsável, revogação, ausência de administrador, troca rápida de carteira, resposta atrasada e tentativa de ampliar o próprio escopo. Não copiar o modelo de workspaces de Projetos.

### L15 — Completar comandos, devoluções e recuperação operacional

A tabela de endpoints ainda não enumera prorrogação, perda/recuperação, reversões dessas operações nem confirmação do cadastro histórico. Também falta um registro explícito de devolução no modelo de domínio, necessário a RN-16. Definir os contratos e eventos correspondentes antes da migração que os suportará; não reaproveitar pagamento para representar indiscriminadamente todas as direções de dinheiro.

Backup e restore já são exigidos, mas “sem perda de pagamentos posteriores” em T5.5 precisa de mecanismo e procedimento demonstráveis. Um snapshot antigo sozinho não entrega isso. Definir frequência, retenção operacional de backups, cópia de anexos, recuperação das chaves, interrupção/reabertura de escritas e captura/reaplicação dos eventos posteriores ou recuperação temporal do banco. Escolher topologia de implantação e estratégia de reversão de versão sem descartar recebimentos novos.

O piloto de G3 já prevê dados operacionais: os controles de restauração e os casos de G2 que ele utilizar precisam estar comprovados antes desse piloto, sem esperar G5 para descobrir que não há recuperação utilizável. Homologação deve indicar quais capacidades estão habilitadas e quais continuam bloqueadas.

## 4. Conferência com a base e limites desta revisão

Foi relido integralmente o plano vigente e consultados o relatório anterior, índice documental, contexto de arquitetura, código Auth/Projetos, cliente HTTP do frontend, Dockerfile/entrypoint, manifests Compose/Swarm, gateway e CI. Não existe serviço `evo-loans-service` na árvore examinada nem configuração de `loans` nos manifests/gateway pesquisados. Isso é trabalho previsto, não defeito de implementação já existente.

As cautelas técnicas da revisão anterior continuam pertinentes:

- `evo-projects-service/src/services/idempotency.service.ts:34` recebe callback sem `tx`; a chamada em `:101` não propaga a transação. Empréstimos precisa de operação e idempotência na mesma transação.
- `evo-projects-service/src/auth/auth-client.ts` trata HTTP não-200 genericamente; `auth.middleware.ts` associa o usuário retornado sem comparação explícita com o `sub` local. Aplicar o contrato mais estrito já descrito no plano do novo módulo.
- `evo-auth-service-community/app/services/token_validation_service.rb:8` mantém cache de cinco minutos e verifica revogação no caminho de cache. Testar o comportamento efetivo de revogação/desativação, sem deduzir seu prazo apenas do cache do cliente.
- `nginx/Dockerfile:16` ainda não inclui `LOANS` no filtro de substituição. Frontend e manifests exigem mudanças coordenadas, como o plano já prevê.

Não foram executados serviços, testes integrados, migrações, restaurações ou acesso a dados de operação. A planilha e o protótipo não foram revalidados. Não houve alteração em serviços, Financeiro ou plano vigente. As únicas verificações executáveis desta revisão foram o script documental existente e a contraprova aritmética descrita em L09.

## 5. Ordem recomendada de fechamento

1. Corrigir os resíduos documentais L07–L11, preservando decisões já tomadas e identificando a única eventual confirmação adicional sobre taxa zero.
2. Fechar L05 e L01 com exemplos de cobrança e prorrogação; depois L02, L06, L04 e L03 com exemplos das operações e suas correções.
3. Especificar L12–L15 pela equipe e atualizar modelo, endpoints e matriz de testes com os mesmos exemplos aprovados.
4. Manter WhatsApp para G6. Provedor, remetente, horário e mensagens continuam pendentes dessa fase; não são novos impedimentos para o núcleo.

Não classificar a aprovação de decisões principais como homologação do motor. A próxima versão coerente do plano deve demonstrar que o mesmo caso chega ao mesmo saldo na prévia, confirmação, histórico, painel e exportação.
