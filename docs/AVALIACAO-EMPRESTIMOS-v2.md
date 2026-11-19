# Revisão técnica e otimização do plano de Empréstimos

> **Registro histórico da revisão v2.** Após esta avaliação, o dono definiu carteiras independentes, cadastro manual inicial e outras regras. O [plano v2.1](../solicitacao-implementacao-emprestimos.md) prevalece sobre as propostas anteriores deste relatório.

Data: 28/10/2026 · Base: arquivos locais do jprOS examinados nesta revisão.

**Resultado:** o desenho de serviço próprio foi mantido. O plano agora explicita as invariantes que sustentam cálculo, pagamento, migração e indicadores, e separa decisões pendentes de implementação verificável. Ainda não está liberado para implementação indiscriminada: cada capacidade depende das decisões e testes do seu gate.

**Delimitação confirmada pelo dono:** Empréstimos e Financeiro são módulos diferentes e independentes. A revisão não propõe compartilhar dados, regras econômicas, serviços de negócio ou ciclo de entrega. Auth, gateway, banco com papéis isolados e componentes visuais genéricos são infraestrutura comum do jprOS.

Plano vigente: [solicitacao-implementacao-emprestimos.md](../solicitacao-implementacao-emprestimos.md). Original preservado: [v1 de 28/10/2026](historico/solicitacao-implementacao-emprestimos.v1-20261028.md).

## 1. O que foi verificado

- Contexto documental em `docs`, incluindo arquitetura geral, especificações/planejamentos da Agenda, contratos de identidade e integração de Projetos, retenção e registro de evidências.
- Estrutura da raiz, `.gitmodules`, manifests de desenvolvimento/produção, Nginx e CI.
- JWT, cliente do Auth, projeção/diretório de usuários, autorização, transações, idempotência, datas civis e testes correspondentes de Projetos.
- Emissão do JWT e contrato de validação no Auth.
- Clientes HTTP, menu/rotas, gaveta e injeção de configuração do frontend.
- Inspeção inicial do serviço Financeiro apenas como comparação técnica de padrões existentes. Essa comparação não criou dependência e foi retirada como fundamento de negócio do plano de Empréstimos.
- Reprodução matemática dos três exemplos da v1 e de dois casos adicionais de arredondamento.

**Não verificado nesta revisão:** planilha original, protótipo navegável, PRD original, dados reais, disponibilidade de portas no host, credenciais, containers, migrações aplicadas ou testes de aplicação com banco. Nenhum serviço existente foi modificado ou implantado. As contagens herdadas da planilha precisam de fonte identificada e conferência na Fase 0.

Não foi executada a suíte geral de Projetos: a tarefa é documental e há testes que buscam um workspace preexistente (`test/idempotency-general.test.ts:15`) e alteram registros de idempotência. Isso não é necessário para validar este plano. Os novos gates exigem banco descartável e fixtures próprios.

## 2. Apontamentos de maior impacto

### A01 — Bloqueante para G1: arredondamento não fecha apenas com “parcela × quantidade”

**Evidência:** a RN-03 da v1 proibia ajuste na última parcela, enquanto o modelo exigia composição principal/juros e K1 dependia de principal restante. Os exemplos originais conferem, mas não cobrem resíduos.

**Reprodução:** R$ 1.000,00 a 1% em três parcelas de R$ 340,02, arredondando juros por período, deixa R$ 0,01 de principal. A 0%, R$ 100,00 / 3 resulta em total de R$ 99,99 se todas as parcelas forem R$ 33,33.

**Ajuste:** RN-02 trata taxa zero; RN-03 separa total original, ajustes e valor atual. D12 exige decisão sobre composição e centavos, mantendo a regra da planilha como referência, sem modificá-la silenciosamente. A proposta de ajustar apenas a composição não resolve todo caso a 0%, por isso a exceção continua explícita.

**Ganho:** evita contrato aparentemente quitado com capital residual, juros negativos e total exibido que ignora ajustes manuais. Testes: T1.3.

### A02 — Bloqueante para G2: pagamento precisa definir principal e juros separadamente

**Evidência:** RN-08 da v1 ordenava “multa, mora, encargos e valor da parcela”. Não definia como o último componente se divide em principal/juros, embora Alocação e K6 exijam essa divisão. Desconto estava listado como componente de pagamento, sem distinguir redução da dívida de dinheiro recebido.

**Ajuste:** RN-08 exige soma das alocações igual ao recebimento, saldo não negativo e decisão D2 sobre ordem, antecipação e descontos. Ajuste/desconto é registro próprio. Valores acima do devido são rejeitados enquanto não houver regra específica. A prévia identifica parcelas e componentes e a confirmação recalcula sob bloqueio.

**Ganho:** um mesmo recebimento não muda de significado entre saldo, ficha, indicadores e exportação. Testes: T2.2, T2.10, T4.1.

### A03 — Bloqueante para G2: rolagem, estorno e renegociação têm efeitos dependentes

**Evidência:** a v1 descrevia prorrogação do principal, mas não dizia se a próxima obrigação incluiria juros novos. Transferia o saldo da renegociação para o novo principal sem discriminar composição. O estorno não considerava que o contrato poderia ter sido prorrogado ou renegociado depois.

**Ajuste:** RN-09 exige evento explícito de prorrogação e exemplo aceito em D1. RN-10 preserva original e inverso e bloqueia reversão isolada quando houver operação dependente. RN-17 separa transferência de dívida, componentes capitalizados e capital novo. Renegociação não gera recebimento nem desembolso fictício.

**Ganho:** não contar duas dívidas ou inventar caixa; preservar rastreabilidade quando houver correções. Testes: T2.3, T2.4, T2.8, T4.5.

### A04 — Bloqueante para G2: idempotência deve usar a mesma transação da operação

**Evidência de código:** em [idempotency.service.ts](../evo-projects-service/src/services/idempotency.service.ts), o callback é `operation: () => Promise<...>` (linha 34), o serviço inicia `withTransaction` (67), chama `operation()` (101) e depois grava o resultado (106). A rota de tarefa chama outro serviço nesse callback ([tasks.routes.ts](../evo-projects-service/src/routes/tasks.routes.ts), linha 207).

A interface não entrega o `tx` ao callback. Portanto, copiá-la não garante que a gravação do pagamento e a gravação da chave sejam uma unidade atômica. Este é um limite identificado estaticamente; não foi reproduzida falha de pagamento em serviço existente.

**Ajuste:** RN-11 e RN-19 exigem propagação explícita do mesmo `tx`, unicidade, hash canônico, revalidação de autorização, replay estável e retenção da identidade da operação enquanto persistir seu efeito. Não herdar expiração genérica de 72 horas como autorização para repetir um pagamento.

**Ganho:** retry após timeout/commit não duplica dinheiro. Testes: T2.5–T2.7, incluindo falha injetada antes do registro idempotente e chamadas concorrentes reais.

### A05 — Bloqueante para G5: dados ausentes não autorizam criar dívida ou pagamento

**Evidência:** a v1 propunha reconstruir automaticamente parcelas de 95 contratos e converter situação/observações em pagamentos com data de vencimento estimada. Também agrupava contratos por atributos que não são necessariamente únicos.

**Ajuste:** conferência em área separada, proveniência por linha/célula, aprovação de reconstruções e agrupamentos, identidade própria para CPF inválido e saldo de abertura quando o histórico não for comprovável. O saldo de abertura já considera fatos anteriores; estes não podem abatê-lo outra vez. Identificador da fonte e mapeamento persistente protegem contra reimportação de arquivo corrigido/reordenado.

**Ganho:** a automação continua útil para normalizar e propor, mas não inventa obrigações. Contagens e totais passam a ser reproduzíveis. Testes: T5.1–T5.6.

### A06 — Prioridade para G2/G4: status e indicadores tinham significados incompatíveis

**Evidência:** “parcial” e “vencida” eram estados concorrentes; na operação podem ocorrer juntos. K1 mantinha todo o principal de parcela única até quitação, mesmo admitindo pagamento parcial. K6 era chamado de resultado do período no trecho sobre perdas. K7 não especificava o capital médio. A v1 declarava indicadores de capital confiáveis desde a migração sem garantir composição do saldo.

**Ajuste:** RN-12 separa liquidação e prazo; RN-13 separa ciclo de vida e situação de cobrança. K1 reduz principal amortizado, distingue capitalização e não duplica renegociações. K6 mede juros recebidos; K7 usa média diária e continua bruto. KPIs mostram cobertura, base incompleta e datas estimadas, com denominador zero como não aplicável.

**Ganho:** painel não mascara atraso nem apresenta como lucro ou capital conhecido um número que a origem não comprova. Testes: T2.9 e T4.1–T4.5.

## 3. Ajustes para integrar no jprOS sem depender de outro domínio

### A07 — Fundação: autenticação comum, autorização própria

O Auth emite `sub` canônico, papel e audiência configurável, inclusive o default textual `[]` ([doorkeeper.rb](../evo-auth-service-community/config/initializers/doorkeeper.rb), linhas 164–174). `/validate` retorna o resultado do validador ([auth_controller.rb](../evo-auth-service-community/app/controllers/api/v1/auth_controller.rb), linhas 146–155). Seu cache é de cinco minutos, com checagem de revogação no caminho de cache ([token_validation_service.rb](../evo-auth-service-community/app/services/token_validation_service.rb), linhas 8 e 25–31).

Projetos oferece referência para assinatura e consulta de revogação, mas seu middleware atribui a identidade retornada pelo Auth sem comparar explicitamente com o `sub` local ([auth.middleware.ts](../evo-projects-service/src/middlewares/auth.middleware.ts), linhas 73–99); `auth-client.ts:96` trata respostas HTTP não-200 de forma genérica como recusa, enquanto a indisponibilidade por exceção é tratada à parte.

O plano agora pede igualdade de identidade, distinção entre 401/503, teste de audiência real e política de cache verificável. Membro local ativo de Empréstimos concede o papel; login válido sozinho não concede acesso. Sem workspaces, usuários fictícios ou herança de privilégios de outro módulo. T0.2/T0.5.

### A08 — Fundação: gateway, frontend e deploy precisam ser entregues juntos

- [nginx/Dockerfile](../nginx/Dockerfile), linhas 5–16: defaults de upstream e filtro de `envsubst` precisam incluir o serviço novo.
- [Frontend Dockerfile](../evo-ai-frontend-community/Dockerfile), linhas 23–24, e [entrypoint](../evo-ai-frontend-community/docker-entrypoint.sh), linhas 25–26: variáveis são substituídas no startup; declarar só a URL no Compose é insuficiente.
- [projectsApi.ts](../evo-ai-frontend-community/src/services/projects/projectsApi.ts): cliente existente exemplifica renovação da sessão; retry do novo módulo deve preservar a chave de operação.
- [Sidebar.tsx](../evo-ai-frontend-community/src/components/layout/components/Sidebar.tsx), linhas 281 e 298: Projetos tem gaveta específica. Empréstimos não precisa importar seletor de workspace.
- [docker-compose.yml](../docker-compose.yml), linhas 441–482: job de migração e dependência explícita são precedente técnico. O processo de implantação em Swarm precisa de execução/check de migração próprios, não de suposição sobre `depends_on`.

O plano inclui flags coerentes entre servidor e UI, piloto após G3 e corte após G5. A v1 proibia liberação até G5, mas exigia um dia de cobrança no G3; a distinção piloto/corte resolve essa ambiguidade. T0.1/T0.4.

### A09 — Segurança e recuperação: schema e soft delete não bastam

`?schema=loans` escolhe namespace, não concede isolamento por si só. O plano exige papéis e grants próprios, teste de acesso cruzado, nomes físicos de tabelas/mapeamentos conferidos e aplicação sem DDL. CPF completo não pode chegar ao visualizador nem em DTO/exportação; documentos precisam de download autenticado.

Os 90 dias da política de Projetos não foram copiados como prazo legal de descarte de crédito. Empréstimos mantém janela de restauro operacional proposta, sem purga automática. Cliente inativo não faz dívida desaparecer. Banco, anexos e chaves precisam de recuperação ensaiada; restaurar um snapshot pré-corte depois de novos recebimentos requer reconciliar esses eventos.

T0.3/T0.4, T3.3–T3.5 e T5.6. São requisitos de engenharia do novo módulo, sem afirmação de conformidade jurídica.

### A10 — Aceite: testar o efeito real, sem herdar a homologação de outro módulo

O teste [tx-concurrency.test.ts](../evo-projects-service/test/tx-concurrency.test.ts), por exemplo nas linhas 11–15 e 103–119, substitui `$transaction` e verifica chamadas. Ele é útil para a unidade, mas não demonstra isolamento de dois pagamentos simultâneos no PostgreSQL.

O job atual de Projetos em [ci.yml](../.github/workflows/ci.yml), linhas 71–97, instala, gera Prisma e executa testes; esse trecho não provisiona PostgreSQL descartável. O job do novo módulo deve fazê-lo expressamente, com fixtures independentes e proteção contra URL da operação.

A matriz ampliada mantém RF-01–RF-16 e RN-01–RN-20, e testa matemática, contratos, concorrência, falhas, importação, interface e restauração. Nenhum teste da matriz foi marcado como executado nesta revisão.

## 4. Otimizações de escopo e sequência

1. Diagnóstico da planilha na Fase 0, sem antecipar importação em produção. Isso permite resolver identidade, resíduos e histórico antes de construir todos os relatórios.
2. Cadastro e autorização próprios usando identidades do Auth; nenhum segundo login ou domínio multi-workspace.
3. Motor único no servidor para simular e confirmar, com parâmetros congelados por contrato. UI consome a prévia, não implementa uma segunda fórmula autoritativa.
4. Estados temporais derivados em consulta; não introduzir job de reclassificação diária.
5. Lotes com resultado por contrato e chave por item; evita uma grande transação abrangendo clientes sem relação entre si.
6. Fila de notificações apenas na Fase 6, com consumidor/provedor escolhido. Não criar broker, worker ou outbox vazio na fundação.
7. Separar decisões do dono de verificações técnicas. D6 não bloqueia o núcleo; D9 é verificação de engenharia; D10 não impede validar matemática. D12 bloqueia confirmação de cronogramas.
8. Manter K6/K7 brutos e declarar D11 adiada quando não houver escopo de perdas aceito. Não criar uma contabilidade adicional por interpretação da palavra “rentabilidade”.

## 5. Verificação reproduzível e arquivos entregues

Executar da raiz:

```text
node docs/emprestimos/validar-exemplos.mjs
```

O script usa somente `node:assert/strict` e aritmética racional com `BigInt`, sem dependências de serviço. **Executado nesta revisão: dez assertivas passaram**, cobrindo os cinco cenários documentados. Ele não consulta dados reais, não acessa rede e não escreve no banco. A demonstração com juros arredondados a cada período expõe um caso de resíduo; não seleciona a política D12 pelo dono.

Também foram conferidos links locais, tabelas Markdown, fechamento dos blocos de código, ausência de caracteres inválidos e contagens sem duplicidade: 16 requisitos RF, 20 regras RN, 12 decisões D e sete gates G. A cópia histórica preserva o SHA-256 `CF7D2C9EB2403CEFBCAF516E8E7275C7A9D4A352EC862497ECD76F77DFE968A1` do original.

Arquivos desta revisão:

- Plano atualizado no caminho original.
- Este relatório de apontamentos e evidências.
- Cópia histórica exata da v1, preservada antes de editar porque o arquivo estava não rastreado no Git.
- Script de reprodução dos exemplos, independente de qualquer módulo de negócio.

As alterações preexistentes em serviços, Compose, outros documentos e submódulos foram preservadas. Próxima ação de produto: resolver D1/D2/D3/D7/D8/D11/D12 no momento definido no plano; a escolha do início da implementação é uma etapa separada desta revisão documental.
