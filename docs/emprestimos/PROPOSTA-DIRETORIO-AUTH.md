# Proposta de diretório restrito para Empréstimos

Estado: **alteração autorizada e em implementação**, ainda dependente dos testes completos e da configuração segura em cada ambiente. Relacionada à tarefa OpenSpec 1.7 e à autorização de carteiras da tarefa 1.6.

## Problema confirmado no código

O endpoint existente `GET /api/v1/users` do Auth exige `users.read` para o usuário chamador (`evo-auth-service-community/app/controllers/api/v1/users_controller.rb`). Seu serializador completo inclui dados que a seleção de pessoas em Empréstimos não precisa, como `pubsub_token`, configurações e atributos extras. Dar `users.read` globalmente a um gestor de carteira amplia suas permissões em outros contextos; tratar o erro 403 como lista vazia esconderia o problema.

O Auth também possui um token de serviço genérico que evita verificações de autorização (`ServiceTokenAuthConcern` e `PermissionCheckable`). **Não reutilizar essa credencial** para a nova função, pois concede uma capacidade mais ampla do que a necessária.

## Alteração proposta

1. Acrescentar no Auth um endpoint interno específico para pesquisa e confirmação de identidade existente, com resposta mínima: ID, nome de exibição e confirmação de conta. Não retornar token de publicação, papéis, configurações, telefone, endereço nem atributos extras. Confirmar antes da implementação os critérios atuais do Auth para usuário elegível e o formato de identidade.
2. Autenticar a chamada com uma credencial dedicada ao diretório de Empréstimos, distinta do token de serviço genérico, sem valor padrão; também validar no Auth o token real do operador. Na ausência de credencial ou token válido, negar o pedido. Não conceder `users.read` ao operador e não mudar o comportamento do endpoint geral de usuários.
   A verificação de identidade usa a ação interna `verify`, protegida pela mesma chave e pelo bearer do operador, e verifica explicitamente revogação e expiração; pesquisa e resolução permanecem ações separadas.
3. O backend de Empréstimos só consulta esse endpoint **depois** de validar o usuário e verificar que ele é gestor da carteira correspondente ou dono com capacidade de designação. A credencial interna nunca chega ao navegador. A rota interna não deve ser publicada pelo gateway como rota de negócio; restringir acesso à rede interna e aplicar limite de requisições.
4. A pesquisa deve ter paginação e limites; a confirmação de uma pessoa deve usar ID exato. Evitar incluir termos de pesquisa, credenciais ou dados sensíveis nos logs. Distinguir token inválido, autorização local insuficiente e Auth indisponível; não inventar pessoa nem converter indisponibilidade em lista vazia.
5. Registrar auditoria da concessão ou revogação no próprio Empréstimos, na mesma transação da alteração. Conceder ou revogar acesso não cria conta ou senha no Auth e não altera permissões de outros módulos.

## Arquivos e configuração que precisariam mudar

- No submódulo `evo-auth-service-community`: rota, controller ou serviço interno limitado e testes de segurança. O endpoint existente de usuários e seu controle de permissões seriam preservados.
- Em `evo-loans-service`: cliente do diretório, integração com o controle de carteiras e testes. A lista só é apresentada após autorização local.
- Nos manifests e configuração dos dois serviços: uma nova credencial dedicada, carregada por mecanismo seguro do ambiente; não colocar valor real em repositório nem reaproveitar credencial ampla. Nenhum deploy ou criação de credencial em ambiente operacional faz parte desta proposta.
- Em frontend e evidências: seleção de usuário e mensagens de erro; testes end-to-end em ambiente descartável.

## Verificação antes de habilitar

- Gestor autorizado sem `users.read` pesquisa identidades somente pela tela local e pode conceder acesso à própria carteira.
- Pessoa sem autorização local não obtém diretório, mesmo autenticada; ID inexistente ou inelegível não é atribuído.
- Chave ausente, inválida ou genérica é rejeitada; token do operador expirado ou revogado é rejeitado; Auth indisponível não cria membro.
- Resposta não contém tokens ou atributos extras; logs não registram termos ou credenciais. Paginação, concorrência e limites são verificados.
- Testes existentes do endpoint geral de usuários continuam passando, sem alteração de sua permissão `users.read`. Não testar criando contas no banco operacional.

## Alternativas e consequência

- **Permissão `users.read` ao gestor:** aproveita a API atual, mas amplia seu acesso ao diretório geral, contrariando a intenção de não conceder privilégios globais por conveniência.
- **Lista de usuários que já acessaram Empréstimos:** evita alterar Auth, mas exige que a pessoa entre antes de ser selecionável e não atende necessariamente à seleção de qualquer identidade existente.
- **Token genérico de serviço:** evita código novo no Auth, mas pode ultrapassar permissões para outras ações e é inadequado para este acesso limitado.

Esta é uma extensão da infraestrutura de identidade compartilhada; não cria integração com dados ou regras de negócio do Financeiro. A implementação deve permanecer desabilitada até os testes e controles de acesso serem validados.
