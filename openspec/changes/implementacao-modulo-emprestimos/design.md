# Design

## Context

O repositório não contém `evo-loans-service` nem `LOANS_UPSTREAM`. Auth, gateway, PostgreSQL e frontend já existem; Projetos oferece referências técnicas, sem fornecer regras de empréstimos. O callback de idempotência de Projetos não recebe `tx`; a listagem do Auth exige `users.read`; gateway filtra variáveis e frontend substitui placeholders no startup. Não se deve assumir que copiar esses trechos resolve as necessidades do novo serviço.

As regras aprovadas e exemplos estão em `solicitacao-implementacao-emprestimos.md` e `docs/emprestimos/REGRAS-E-CENARIOS-v2.1.md`. `docs/emprestimos/DEBITOS-TECNICOS.md` registra DT-01–DT-07 e seus gates. A fonte original da planilha e o protótipo não foram revalidados.

## Goals / Non-Goals

**Goals:** implementar serviço independente, autorização e dados por carteira, motor único determinístico, trilha auditável, recuperação e liberação por capacidade demonstrada.

**Non-Goals:** reutilizar domínio financeiro, importar dados, sincronizar CRM, introduzir contabilidade geral, barramento ou integração MCP. Não definir por suposição decisões econômicas em aberto nem validar produção com exemplos documentais.

## Decisions

### Serviço, banco e implantação

Novo serviço TypeScript/Fastify/Prisma/Zod com schema `loans`, papéis DDL e DML separados, migrações versionadas e frontend Evo via Nginx. Compartilhar banco com grants isolados é preferível a depender do Financeiro; schema por si só não constitui isolamento. Validar porta 3005/3015 e runtime no ambiente real. Definir se o serviço será diretório ou submódulo durante G0, com CI e deploy coerentes; não criar repositório remoto como efeito da proposta.

### Identidade e autorização

JWT com assinatura, algoritmo, emissor, expiração, `sub` e audiência compatível; comparar `sub` com identidade do Auth e distinguir recusa de indisponibilidade. Operações sensíveis consultam Auth; testar efeito do cache de revogação de ponta a ponta. Autorização local por carteira é sempre verificada no servidor, inclusive exportações/anexos e replay. Bootstrap e recuperação são auditados. Para seleção sem `users.read`, foi autorizada uma API interna restrita no Auth, com chave exclusiva e bearer do operador: `verify` verifica identidade, expiração e revogação; `search` e `resolve` fornecem somente ID, nome e confirmação após autorização local. Ver detalhes e evidências pendentes em `docs/emprestimos/PROPOSTA-DIRETORIO-AUTH.md`.

### Modelo e dinheiro

Contrato, parcela, componente, pagamento, alocação, ajuste, correção, devolução, perda e eventos de acordo mantêm vínculos de carteira. Valores e taxas trafegam como strings decimais, sem float; cálculo usa precisão superior e arredondamento versionado. Original, data efetiva, data de registro e correções ficam auditáveis. Prévia não é reserva: confirmação releitora de versão, data e parâmetros recalcula no servidor.

Em Price, a proposta técnica é arredondar juros por período e ajustar última parcela ao saldo remanescente; DT-05 exige limites e testes antes de G1. Ao registrar contrato antigo, manter valores reais e bloquear confirmação de recebimento sem composição identificada. Desconto e entrega histórica não criam recebimento ou desembolso novo.

### Integridade e concorrência

Cada operação sensível exige chave idempotente por carteira, ator e operação, payload normalizado e autorização renovada. Versão esperada e bloqueio por contrato protegem o saldo. A mesma transação deve conter mutação, alocações, auditoria e resultado idempotente; serviços recebem explicitamente o contexto transacional. Lotes são independentes por contrato e reportam resultados parciais; não realizar chamada de rede dentro da transação. Histórico anterior e correções vinculadas preservam causalidade e não duplicam valores.

### Encargos e limites de liberação

A multa nova do dia é apurada após o pagamento; a regra anterior da ordem de abatimento se aplica aos componentes anteriores. DT-01 preserva as dúvidas de base e sequência, inclusive múltiplos pagamentos no dia. Não liberar o caso afetado sem regra validada e teste. DT-02 mantém bloqueadas correções encadeadas ou cancelamentos que ainda não tenham efeito íntegro demonstrável. Resolver essas pendências nas fases correspondentes, não presumir que foram aprovadas nem impedir a fundação.

### Apresentação, relatórios e notificações

Frontend consome prévias do motor, apresenta escolhas, máscaras e estados, e inclui carteira no contexto de consulta/cache; troca de carteira não pode confirmar prévia antiga. K1–K8 usam registros próprios e sinalizam qualidade, sem visão consolidada nem resultado líquido presumido. DT-03 exige validar perda e correções retroativas antes de G4. Avisos WhatsApp usam fila durável e verificação de elegibilidade somente em G6; provedor, remetente e horários continuam a definir. Não prometer envio exatamente uma vez.

## Risks / Trade-offs

- [Divergência de base ou data] → Exemplos aprovados, cálculo versionado e impedir casos sem regra; consultar dono apenas sobre resultado econômico não decidido.
- [Correção duplica saldo ou dinheiro] → Eventos vinculados, prévia por componente, validação transacional e cenários encadeados com banco real.
- [Acesso cruzado ou identidade revogada] → Escopo em todos os recursos e testes de revogação, concorrência e exportação; ausência do Auth não autoriza fallback.
- [Perda de dados após restore] → Backup coerente de banco/anexos e procedimento ensaiado para recuperar fatos posteriores; snapshot sozinho não garante recuperação.
- [Documentos históricos inconsistentes] → Consolidar DT-04 sem alterar escolhas e manter precedência do plano vigente sobre revisões históricas.

## Migration Plan

1. Validar topologia e credenciais, provisionar schema/papéis, preparar backup e restaurar em ambiente descartável. Aplicar migrations versionadas por job próprio antes de iniciar a aplicação; não usar `db push` em produção.
2. Entregar infraestrutura, motor, telas e controles com flags desativadas, habilitando recursos somente após gates e evidências. Não importar planilha.
3. Para rollback de versão, interromper novas escritas, preservar banco/anexos/chaves e reconciliar fatos confirmados depois do backup antes de retomar. Não restaurar snapshot antigo sobre novos recebimentos sem recuperação demonstrada.

## Open Questions

Identidade do provedor e remetente de WhatsApp, modelos e horário podem ser definidos em G6 e não impedem o núcleo. Porta e topologia real são verificações técnicas de G0. Outras pendências com impacto em cobrança ou indicadores constam explicitamente como DT-01–DT-03 e são pré-condições da capacidade correspondente, não defaults aprovados.
