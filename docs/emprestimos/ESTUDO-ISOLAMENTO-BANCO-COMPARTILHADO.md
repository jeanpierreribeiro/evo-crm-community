# Estudo de isolamento no PostgreSQL compartilhado

Data: 29/10/2026. Opção B escolhida: preservar o banco compartilhado. A alteração abaixo foi autorizada pelo dono e aplicada no banco jprOS após confirmação dos papéis, registro da ACL anterior e teste de aplicação e reversão em banco descartável. O registro anterior está em `ACL-PUBLIC-ANTES-20261029.md`; o resultado está nas evidências de implementação.

## Diagnóstico observado

- Em consulta somente de metadados no banco jprOS, `PUBLIC` possui `USAGE` no schema `public`. Os schemas `finance`, `projects` e `scheduling` consultados não tinham `USAGE` concedido a `PUBLIC`.
- No schema `public`, os dois objetos que tinham `SELECT` concedido a `PUBLIC` eram as visões técnicas `pg_stat_statements` e `pg_stat_statements_info`. Os dados dessas visões não foram consultados.
- No momento da consulta, os papéis locais não internos eram `postgres`, `projects_app` e `projects_migrator`; os três tinham acesso herdado ao schema `public`. As 13 sessões observadas no banco usavam `postgres`. Esta fotografia não prova que não existam consumidores externos, papéis futuros, conexões intermitentes ou necessidades operacionais adicionais.
- Uma permissão concedida a `PUBLIC` é herdada pelos papéis. Um `REVOKE` somente em `loans_app` não neutraliza o acesso herdado. A verificação é necessária para o migrador também.

## Alternativa ensaiada em banco descartável

Uma possibilidade é conceder explicitamente `USAGE` aos papéis que já precisam dele e depois retirar a concessão de `PUBLIC`, em uma transação. O dono do banco/schema e superusuários conservam seus privilégios por outros meios. O resultado depende das permissões e da lista de papéis existentes no ambiente efetivo.

No PostgreSQL descartável, uma tabela sintética tinha `SELECT` público. Antes da alteração, o papel sintético de Empréstimos conseguia usar o schema mesmo após um `REVOKE` somente para ele. Após conceder `USAGE` explicitamente aos dois papéis sintéticos de Projetos e revogar `USAGE` de `PUBLIC`:

- Uma consulta efetiva como papel de Empréstimos falhou com `permission denied for schema public`.
- Uma consulta efetiva como papel de Projetos manteve acesso.
- Um papel criado depois da mudança não recebeu `USAGE` automaticamente: ele precisa de concessão explícita quando apropriado.
- `has_table_privilege` continuou indicando `SELECT` na tabela sintética por causa do grant na própria tabela; a consulta foi negada porque faltou `USAGE` no schema. As duas verificações são necessárias para interpretar o resultado.

## Alteração aplicada após revisão

No banco `evo_community`, o trecho abaixo foi aplicado após o inventário registrado, autorização do dono e teste da reversão. Uma futura aplicação em outro ambiente requer novo inventário e não deve presumir que a lista de papéis ainda seja a mesma:

```sql
BEGIN;
GRANT USAGE ON SCHEMA public TO projects_app, projects_migrator;
REVOKE USAGE ON SCHEMA public FROM PUBLIC;
COMMIT;
```

`postgres` é superusuário no ambiente consultado e não precisa desse grant para manter acesso. Não presumir que a lista acima continuará completa: refazer a inspeção imediatamente antes de executar e conceder acesso a todos os papéis legítimos identificados. A transação evita uma janela entre as duas mudanças, mas não impede que processos externos ou futuros dependam do grant genérico. A mudança afeta todo o banco, não apenas Empréstimos.

Restauração conceitual do grant público, se necessária, é `GRANT USAGE ON SCHEMA public TO PUBLIC`. A reversão completa dos grants explícitos deve usar a ACL capturada imediatamente antes da alteração, pois privilégios podem ter mudado entre inspeção, aplicação e rollback; não remover grants preexistentes às cegas. A extensão e seus objetos não precisam ser alterados por essa proposta.

## Condições antes de considerar a mudança segura

1. Confirmar ambiente e banco; inventariar ACL do schema, papéis, membros, serviços, monitoramento e sessões, inclusive acesso externo e criação futura de papéis. Registrar a ACL de origem.
2. Testar em cópia ou banco descartável com privilégios e papéis equivalentes, incluindo Auth/CRM, Projetos, Agenda, Financeiro e monitoramento; confirmar que nenhum perde acesso necessário. Não alterar regras ou dados desses módulos.
3. Definir procedimento de concessão para novos papéis, responsável operacional, janela de aplicação e restauração por ACL registrada. Preparar backup adequado; mudanças de ACL não são cobertas por suposição de que um snapshot é suficiente.
4. No ambiente jprOS, a ACL foi aplicada após autorização e verificadas as consultas efetivas dos papéis de Projetos. A negação efetiva dos papéis de Empréstimos no banco jprOS ainda deve ser verificada quando forem provisionados; em outro ambiente, validar novamente antes de aplicar.

## Proteção acrescentada ao novo serviço

O job local `evo-loans-service/scripts/migrate.mjs` agora verifica, **antes da migration**, se os papéis de Empréstimos possuem `USAGE` herdado em schemas fora de `loans` e dos schemas de sistema. Em banco descartável com acesso herdado, a migration foi bloqueada e nenhuma tabela de migração foi criada; após retirar o grant público no mesmo banco de teste, a migration passou. O job não altera as ACLs de outros schemas. A verificação não substitui a análise de privilégios sobre objetos, conexões ou infraestrutura.

Após a migração descartável, `loans_app` pôde atualizar a tabela de carteira, não pôde criar objetos no schema de Empréstimos e não pôde atualizar `_prisma_migrations`. Ainda faltam testes automatizados, verificação em todas as topologias previstas e o job integrado ao deploy. DT-06 e a tarefa OpenSpec 1.3 permanecem abertos.
