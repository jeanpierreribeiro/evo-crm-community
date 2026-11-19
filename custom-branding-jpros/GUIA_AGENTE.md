# 🤖 GUIA DE EXECUÇÃO PARA AGENTE DE IA: APLICAÇÃO DA IDENTIDADE VISUAL jprOS NO EVO CRM

Este documento é uma instrução técnica estruturada para que qualquer **Agente de IA** (ou desenvolvedor) aplique com 100% de precisão a identidade visual **jprOS** em uma nova ou existente instância do **Evo CRM** (Frontend / Nginx).

---

## 🎯 1. Objetivo da Tarefa
Substituir completamente a identidade visual padrão do Evo CRM pela marca **jprOS**, garantindo:
1. **Logotipo e Ícone**: Exibir os novos logotipos em vetor SVG (`jpros-logo-dark.svg`, `jpros-logo-light.svg`, `favicon.svg`).
2. **Cores da Marca**: Substituir a predominância de tons de verde (`#00ffa7` / verde primário) pelo azul oficial da logo (`#3B82F6` / hover `#2563EB`).
3. **Menu Lateral**: Destacar o item ativo com fundo azul translúcido (`rgba(59, 130, 246, 0.15)`) e borda `#3B82F6`.
4. **Campos de Formulário / Login (CRÍTICO)**: Preservar o fundo escuro suave e o texto branco (`#f8fafc`) sempre visível nos campos de entrada (`Email`, `Senha`, pesquisas, selects). **Nunca** aplicar seletores globais como `[class*="bg-primary"]` que colidam com a classe do Tailwind `selection:bg-primary` dos inputs!
5. **Rodapé e Links**:
   - Mudar de: `Evo CRM © [Ano] Evolution Foundation. Todos os direitos reservados.`
   - Para: `jprOS © [Ano] jprOS. Todos os direitos reservados.`
   - Remover permanentemente os links de `Documentação` e `Preciso de suporte`.
6. **Bypass de Cache**: Impedir que o cache do Cloudflare ou navegador sirva assets antigos (`Clear-Site-Data`, versionamento `?v=timestamp`).

---

## 📂 2. Estrutura do Pacote
Certifique-se de que os seguintes arquivos estejam presentes na mesma pasta:
- `assets/jpros-logo-dark.svg`
- `assets/jpros-logo-light.svg`
- `assets/favicon.svg`
- `custom-styles.css`
- `install-branding.sh`

---

## ⚡ 3. Modo Rápido (Execução Automatizada)

### Cenário A: Instância rodando em contêiner Docker (Padrão)
Se o frontend estiver rodando em um contêiner Docker (ex: `evo-frontend`, `jpros-evo-frontend-1`):

1. **Copie a pasta de branding para dentro do contêiner**:
   ```bash
   docker cp custom-branding-jpros/. <NOME_DO_CONTAINER>:/tmp/branding/
   ```

2. **Execute o script de automação dentro do contêiner**:
   ```bash
   docker exec -it <NOME_DO_CONTAINER> bash /tmp/branding/install-branding.sh
   ```

3. **Verifique se o Nginx recarregou sem erros**:
   ```bash
   docker exec -it <NOME_DO_CONTAINER> nginx -t
   ```

---

### Cenário B: Instância em LXD / Host Nginx Direto
Se o frontend for servido diretamente pelo Nginx do sistema:

1. **Execute o instalador passando o diretório web do Nginx**:
   ```bash
   sudo bash install-branding.sh /usr/share/nginx/html
   # ou /var/www/html (conforme a configuração da distro)
   ```

---

## 🛠️ 4. Modo Passo a Passo (Manual / Cirúrgico)

Caso o contêiner não possua `bash`, ou você precise aplicar as etapas manualmente, siga esta sequência exata:

### Passo 1: Copiar e Sobrescrever Imagens
No diretório `/usr/share/nginx/html/assets/`:
1. Copie `jpros-logo-dark.svg` como `jpros-logo-dark-v1.svg`.
2. Copie `jpros-logo-light.svg` como `jpros-logo-light-v1.svg`.
3. Sobrescreva também os SVGs originais para anular caches legados:
   - `cp jpros-logo-dark.svg EVO_CRM-BPOP0TvS.svg`
   - `cp jpros-logo-light.svg EVO_CRM_light-6_wHNvBP.svg`
4. Na raiz `/usr/share/nginx/html/`:
   - `cp favicon.svg favicon.svg`
   - `cp favicon.svg logo.svg`

### Passo 2: Atualizar os Bundles JavaScript
O Vite/React compila as strings de imagem e i18n dentro dos bundles `assets/index-*.js`.
Execute para cada arquivo `.js`:
```bash
sed -i 's/EVO_CRM-BPOP0TvS\.svg/jpros-logo-dark-v1\.svg/g' /usr/share/nginx/html/assets/*.js
sed -i 's/EVO_CRM_light-6_wHNvBP\.svg/jpros-logo-light-v1\.svg/g' /usr/share/nginx/html/assets/*.js
sed -i 's/Evolution Foundation/jprOS/g' /usr/share/nginx/html/assets/*.js
```

### Passo 3: Injetar Estilos nos Bundles CSS
Nos arquivos `/usr/share/nginx/html/assets/*.css`:
1. Substitua os verdes hexadecimais:
   ```bash
   sed -i 's/#00ffa7/#3B82F6/gI' /usr/share/nginx/html/assets/*.css
   sed -i 's/#00FFA7/#3B82F6/gI' /usr/share/nginx/html/assets/*.css
   ```
2. Adicione ao final de cada arquivo `.css` o conteúdo de `custom-styles.css`.

> [!CAUTION]
> **ATENÇÃO AO SELETOR DE INPUTS**:
> Nunca adicione `[class*="bg-primary"]` globalmente! O componente `<Input>` do design-system usa a classe `selection:bg-primary`. Um seletor de substring deixará os campos de texto com fundo azul sólido e letras invisíveis. Use os seletores restritos definidos em `custom-styles.css`.

### Passo 4: Configurar `index.html` com Guardião do DOM
Substitua `/usr/share/nginx/html/index.html` garantindo:
1. Headers `no-cache, no-store, must-revalidate` nas meta tags.
2. Inclusão do MutationObserver + TreeWalker que limpa os links de suporte e documentação externos toda vez que o React re-renderizar a página:
```javascript
function clean() {
  var links = document.querySelectorAll('a');
  for (var i = 0; i < links.length; i++) {
    var l = links[i];
    var href = (l.getAttribute('href') || '').toLowerCase();
    var text = (l.textContent || '').toLowerCase();
    if (href.indexOf('evolutionfoundation.com.br') !== -1 || 
        href.indexOf('553196219989') !== -1 || 
        text.indexOf('documenta') !== -1 || 
        text.indexOf('preciso de suporte') !== -1) {
      l.remove();
    }
  }
  if (document.body) {
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
    var node;
    while (node = walker.nextNode()) {
      var val = node.nodeValue;
      if (val) {
        if (val.indexOf('Evo CRM') !== -1) node.nodeValue = val.replace(/Evo CRM/g, 'jprOS');
        if (val.indexOf('Evolution Foundation') !== -1) node.nodeValue = val.replace(/Evolution Foundation/g, 'jprOS');
      }
    }
  }
}
var obs = new MutationObserver(clean);
obs.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
setInterval(clean, 500);
```

### Passo 5: Recarregar Nginx
```bash
nginx -s reload
```

---

## ✅ 5. Checklist de Verificação para o Agente

Após a execução, realize as seguintes verificações antes de dar a tarefa como concluída:

- [ ] **Headers HTTP**: Fazer `curl -sI https://<dominio>/` e confirmar presença de `cache-control: no-cache` ou `Clear-Site-Data: "cache"`.
- [ ] **Logo no Header**: Verificar se `jpros-logo-dark-v1.svg` retorna `HTTP 200`.
- [ ] **Tela de Login**:
  - Logo `jprOS.` visível.
  - Botão `Entrar` azul (`#3B82F6`).
  - Campos `Email` e `Senha` com fundo escuro e digitação branca perfeitamente visível.
- [ ] **Menu Lateral (Autenticado)**:
  - Itens ativos (Dashboard, Conversas, Produtos) destacados em azul suave.
  - Botão `+ Novo produto` azul.
- [ ] **Rodapé**:
  - Exibe `jprOS © 2026 jprOS. Todos os direitos reservados.`.
  - Links de documentação e WhatsApp de suporte foram removidos.
