# Pacote de Identidade Visual jprOS para Evo CRM

Este pacote contém todos os arquivos e scripts necessários para aplicar a identidade visual do **jprOS** em qualquer instalação ou contêiner do **Evo CRM** (Frontend / Nginx).

---

## 📁 Estrutura de Arquivos

- `assets/jpros-logo-dark.svg`: Logo principal do jprOS para tema escuro (azul `#3B82F6` com branco).
- `assets/jpros-logo-light.svg`: Logo do jprOS para tema claro (azul royal com ardósia escura).
- `assets/favicon.svg`: Ícone da aplicação/navegador.
- `custom-styles.css`: Estilos de substituição do verde pelo azul da marca, ajustes de menu ativo, botões e campos de entrada legíveis no dark mode.
- `install-branding.sh`: Script executável de 1 clique para aplicar tudo automaticamente no contêiner ou servidor Nginx.

---

## 🚀 Como Aplicar em Outra Instância do Evo CRM

### Opção 1: Em contêiner Docker (Mais Comum)

1. Envie a pasta `custom-branding-jpros` para o servidor onde está a nova instância:
   ```bash
   scp -r custom-branding-jpros user@ip-do-servidor:/tmp/
   ```

2. Copie para dentro do contêiner frontend do Evo CRM (ex: `evo-frontend` ou `jpros-evo-frontend-1`):
   ```bash
   docker cp /tmp/custom-branding-jpros/. <nome_container_frontend>:/tmp/branding/
   ```

3. Execute o script de instalação dentro do contêiner:
   ```bash
   docker exec -it <nome_container_frontend> bash /tmp/branding/install-branding.sh
   ```

4. Pronto! Limpe o cache do navegador (`Ctrl + F5`) para ver o resultado.

---

### Opção 2: Em Servidor Nginx Direto (Sem Docker)

1. Envie a pasta para o servidor.
2. Execute o script passando o caminho do Nginx:
   ```bash
   cd custom-branding-jpros
   sudo bash install-branding.sh /var/www/html
   # ou
   sudo bash install-branding.sh /usr/share/nginx/html
   ```

---

## 🎨 O que este pacote altera automaticamente:

1. **Logotipo e Ícone**: Substitui o logo do Evo CRM pelo logo moderno em SVG do **jprOS**.
2. **Cores da Marca**: Troca os tons de verde (`#00ffa7` / verde primário) pelo azul oficial (`#3B82F6` e `#2563EB`).
3. **Menu Lateral**: Destaca o menu selecionado com azul translúcido e borda lateral `#3B82F6`.
4. **Campos de Login & Formulários**: Garante fundo escuro suave e letras brancas sempre visíveis (corrige conflito de preenchimento do Tailwind).
5. **Rodapé e Links**: Atualiza o copyright para `jprOS © 2026` e remove os links antigos de documentação e suporte externo.
