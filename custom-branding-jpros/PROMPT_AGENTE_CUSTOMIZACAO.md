# PROMPT DE EXECUÇÃO: WHITE-LABEL E CORREÇÃO DE UI JPROS (EVO CRM)

Copie e cole o texto abaixo integralmente para o Agente de IA que for atuar na instância:

---

```markdown
Você é um Engenheiro de Software Sênior especializado em Frontend, Nginx e Docker.
Sua missão é aplicar a identidade visual completa do **jprOS** nesta instância do Evo CRM, eliminando qualquer menção residual à marca antiga ("Evo CRM", "Evolution Foundation", links de suporte externo) e corrigindo um bug visual crítico nos campos de input da tela de login.

---

### 🎯 OBJETIVOS DA MISSÃO

1. **Correção Visual dos Inputs (Login/Formulários)**:
   - Os campos de "Email" e "Senha" não podem ficar com fundo azul sólido (`#3B82F6`). 
   - Devem possuir fundo escuro translúcido (`rgba(255, 255, 255, 0.05)` ou `#1e293b`), borda sutil, texto branco `#ffffff` legível em repouso, foco e digitação, e autofill de navegador tratado.
   - O botão "Entrar" deve permanecer azul primário com texto branco.

2. **Purificação da Marca (Brand Shield Total)**:
   - Substituir qualquer ocorrência de "Evo CRM" por "jprOS".
   - Substituir "© 2026 Evolution Foundation. All rights reserved." por "© 2026 jprOS. Todos os direitos reservados.".
   - Remover do rodapé/menu lateral os links externos de "Documentação" e "Preciso de suporte" que apontam para a Evolution Foundation ou WhatsApp de terceiros.
   - Garantir que o logo na tela de login e no menu lateral seja o SVG oficial do jprOS.

---

### 🛠️ CAUSA RAIZ TÉCNICA (LEIA COM ATENÇÃO)

- **Bug do Input Azul**: O Tailwind/Design System usa classes como `bg-primary` ou `selection:bg-primary`. Se for injetada uma regra CSS genérica como `.bg-primary { background-color: #3B82F6 !important; }` sem restringir os seletores, elementos `<input>` herdam essa cor, cobrindo o texto digitado. A regra deve ser estritamente restrita a botões e tags específicas: `button.bg-primary, .bg-primary:not(input):not(textarea):not(select)`.
- **Persistência de Texto no React**: O React renderiza textos a partir de bundles JS compilados (`index-*.js`) e i18n JSONs. Apenas alterar o HTML estático não basta se o bundle for reexecutado. É necessário:
  1. Realizar substituição estática via `sed` nos arquivos `.js` compilados.
  2. Implementar um `MutationObserver` + `TreeWalker` resiliente no `<head>` do `index.html` para interceptar e substituir nós de texto dinâmicos injetados pelo React.

---

### 📋 GUIA DE EXECUÇÃO PASSO A PASSO

#### PASSO 1: Localizar os arquivos estáticos do Frontend
Identifique o diretório do frontend web (seja no host local `/usr/share/nginx/html`, no container Docker `evo-frontend`, ou container LXD).
Localize o `index.html` e o diretório `assets/` (onde ficam os arquivos `index-*.js` e `index-*.css`).

#### PASSO 2: Injetar as Regras de CSS Corretas
No final do arquivo CSS principal em `assets/` (e opcionalmente dentro da tag `<style>` do `index.html`), garanta a seguinte estrutura estrita:

```css
/* Paleta de Cores jprOS */
:root, .dark, html, body, [data-theme] {
  --primary: #3B82F6 !important;
  --primary-foreground: #ffffff !important;
  --color-primary: #3B82F6 !important;
  --color-primary-foreground: #ffffff !important;
  --sidebar-primary: #3B82F6 !important;
}

/* Botões Primários - Somente botões e elementos que NÃO sejam campos de texto */
button.bg-primary, 
.bg-primary:not(input):not(textarea):not(select), 
.dark button.bg-primary {
  background-color: #3B82F6 !important;
  color: #ffffff !important;
}

.hover\:bg-primary\/90:hover:not(input), 
button.bg-primary:hover {
  background-color: #2563EB !important;
}

.text-primary {
  color: #3B82F6 !important;
}

.border-primary {
  border-color: #3B82F6 !important;
}

.bg-primary\/10, .bg-primary\/15, .bg-primary\/20, a.bg-primary\/15 {
  background-color: rgba(59, 130, 246, 0.15) !important;
  color: #3B82F6 !important;
  border-left-color: #3B82F6 !important;
}

/* FIX CRÍTICO DOS INPUTS: Fundo escuro e texto sempre legível */
input:not([type="button"]):not([type="submit"]):not([type="reset"]), 
textarea, 
select {
  background-color: rgba(255, 255, 255, 0.05) !important;
  color: #ffffff !important;
  border: 1px solid rgba(255, 255, 255, 0.15) !important;
}

input:not([type="button"]):not([type="submit"]):not([type="reset"]):focus, 
textarea:focus, 
select:focus {
  background-color: rgba(255, 255, 255, 0.08) !important;
  color: #ffffff !important;
  border-color: #3B82F6 !important;
  outline: none !important;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.25) !important;
}

/* Tratamento do Autofill do navegador (Chrome/Edge) para não sobrescrever a cor */
input:-webkit-autofill,
input:-webkit-autofill:hover, 
input:-webkit-autofill:focus {
  -webkit-text-fill-color: #ffffff !important;
  -webkit-box-shadow: 0 0 0px 1000px #0f172a inset !important;
  transition: background-color 5000s ease-in-out 0s !important;
}
```

#### PASSO 3: Substituição Estática de Marca nos Bundles JavaScript
Execute uma varredura `sed` nos arquivos `.js` dentro de `assets/`:
```bash
# 1. Substituir referências literais de nome
sed -i 's/Evo CRM/jprOS/g' assets/*.js
sed -i 's/Evolution Foundation/jprOS/g' assets/*.js

# 2. Neutralizar links de Documentação e Suporte Externo
sed -i 's|https://evolutionfoundation.com.br|https://jpros.com.br|g' assets/*.js
sed -i 's|https://wa.me/553196219989|#|g' assets/*.js
```

#### PASSO 4: Injetar Brand Shield Dinâmico no `<head>` do `index.html`
Para garantir que o React não reidrate textos antigos em tela após trocar de rotas, insira o seguinte script antes do fechamento de `</head>`:

```html
<script>
  (function() {
    function sanitizeDOM() {
      // 1. Remover links de Documentação e Preciso de suporte
      var links = document.querySelectorAll('a');
      for (var i = 0; i < links.length; i++) {
        var a = links[i];
        var href = (a.getAttribute('href') || '').toLowerCase();
        var text = (a.textContent || '').trim().toLowerCase();
        
        if (text === 'documentação' || text === 'preciso de suporte' ||
            href.indexOf('evolutionfoundation') !== -1 ||
            href.indexOf('553196219989') !== -1) {
          // Remove o item ou o container de menu correspondente
          var item = a.closest('li') || a;
          item.remove();
        }
      }

      // 2. Substituir textos nos nós da árvore DOM
      if (document.body) {
        var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null, false);
        var node;
        while (node = walker.nextNode()) {
          var val = node.nodeValue;
          if (val) {
            if (val.indexOf('Evo CRM') !== -1) {
              node.nodeValue = val.replace(/Evo CRM/g, 'jprOS');
            }
            if (val.indexOf('Evolution Foundation') !== -1) {
              node.nodeValue = node.nodeValue.replace(/Evolution Foundation/g, 'jprOS');
            }
          }
        }
      }
    }

    var observer = new MutationObserver(sanitizeDOM);
    observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
    window.addEventListener('DOMContentLoaded', sanitizeDOM);
    window.addEventListener('load', sanitizeDOM);
    setInterval(sanitizeDOM, 400);
  })();
</script>
```

#### PASSO 5: Substituir Logos SVG
Copie o logotipo oficial `jpros-logo-dark.svg` e `jpros-logo-light.svg` sobrepondo os arquivos SVGs originais em `assets/` (como `EVO_CRM-*.svg` e `EVO_CRM_light-*.svg`) e na raiz do frontend (`favicon.svg`).

#### PASSO 6: Cache-Busting e Validação
1. No `index.html`, incremente a versão de consulta dos links:
   - Exemplo: `href="/assets/index-jpros.css?v=2026_input_fix"`
2. Limpe os cabeçalhos de cache ou reinicie o Nginx.
3. Teste na interface:
   - Abra a tela de login (`/login`): Verifique se os campos "Email" e "Senha" têm fundo cinza-escuro/translúcido e o texto digitado é 100% nítido em branco.
   - Faça login: Verifique o rodapé e sidebar. Não deve existir "Evo CRM", "Evolution Foundation", nem links para "Documentação" ou "Preciso de suporte".
```
