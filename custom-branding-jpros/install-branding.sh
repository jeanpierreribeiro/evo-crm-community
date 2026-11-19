#!/usr/bin/env bash
# ==============================================================================
# Script de Aplicação Automática da Identidade Visual jprOS para Evo CRM
# Uso: bash install-branding.sh [caminho_para_html_do_nginx]
# Exemplo padrão: bash install-branding.sh /usr/share/nginx/html
# Ou dentro de container Docker:
# docker cp custom-branding-jpros/. <container_name>:/tmp/branding/
# docker exec -it <container_name> bash /tmp/branding/install-branding.sh
# ==============================================================================

set -e

HTML_DIR="${1:-/usr/share/nginx/html}"
ASSETS_DIR="$HTML_DIR/assets"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== [1/6] Verificando diretórios ==="
if [ ! -d "$HTML_DIR" ]; then
  echo "ERRO: Diretório '$HTML_DIR' não encontrado."
  exit 1
fi

echo "Diretório do frontend: $HTML_DIR"
echo "Diretório de assets: $ASSETS_DIR"

echo "=== [2/6] Copiando logotipos e favicons ==="
# Cópia dos arquivos novos com nomes jprOS
cp "$SCRIPT_DIR/assets/jpros-logo-dark.svg" "$ASSETS_DIR/jpros-logo-dark-v1.svg"
cp "$SCRIPT_DIR/assets/jpros-logo-light.svg" "$ASSETS_DIR/jpros-logo-light-v1.svg"
cp "$SCRIPT_DIR/assets/favicon.svg" "$HTML_DIR/favicon.svg"
cp "$SCRIPT_DIR/assets/favicon.svg" "$HTML_DIR/logo.svg"

# Sobrescrever também os arquivos SVG originais caso estejam em cache
if [ -f "$ASSETS_DIR/EVO_CRM-BPOP0TvS.svg" ]; then
  cp "$SCRIPT_DIR/assets/jpros-logo-dark.svg" "$ASSETS_DIR/EVO_CRM-BPOP0TvS.svg"
fi
if [ -f "$ASSETS_DIR/EVO_CRM_light-6_wHNvBP.svg" ]; then
  cp "$SCRIPT_DIR/assets/jpros-logo-light.svg" "$ASSETS_DIR/EVO_CRM_light-6_wHNvBP.svg"
fi

echo "=== [3/6] Injetando estilos personalizados nos bundles CSS ==="
CUSTOM_CSS=$(cat "$SCRIPT_DIR/custom-styles.css")

for css_file in "$ASSETS_DIR"/*.css; do
  if [ -f "$css_file" ]; then
    echo "Aplicando estilos em: $(basename "$css_file")"
    # Substituir cores verdes hexadecimais legadas
    sed -i 's/#00ffa7/#3B82F6/gI' "$css_file"
    sed -i 's/#00FFA7/#3B82F6/gI' "$css_file"
    
    # Anexar bloco de override caso ainda não exista
    if ! grep -q "JPROS BRAND BLUE OVERRIDES" "$css_file"; then
      echo "" >> "$css_file"
      echo "$CUSTOM_CSS" >> "$css_file"
    fi
  fi
done

echo "=== [4/6] Atualizando referências nos bundles JS ==="
for js_file in "$ASSETS_DIR"/*.js; do
  if [ -f "$js_file" ]; then
    # Substituir nome dos SVGs compilados
    sed -i 's/EVO_CRM-BPOP0TvS\.svg/jpros-logo-dark-v1\.svg/g' "$js_file" 2>/dev/null || true
    sed -i 's/EVO_CRM_light-6_wHNvBP\.svg/jpros-logo-light-v1\.svg/g' "$js_file" 2>/dev/null || true
    
    # Sanitização de URLs de microsserviços para evitar Mixed Content e Network Error
    sed -i 's|http://localhost:3013|https://api-homologar.jeanpierreribeiro.com.br|g' "$js_file" 2>/dev/null || true
    sed -i 's|http://localhost:3012|https://api-homologar.jeanpierreribeiro.com.br|g' "$js_file" 2>/dev/null || true

    # Substituir marca textual de rodapé padrão
    sed -i 's/Evolution Foundation/jprOS/g' "$js_file" 2>/dev/null || true

    # Sanitização de portas locais de microsserviços em produção (Projetos e Agenda)
    sed -i 's|http://localhost:3013|https://api-crm.jeanpierreribeiro.com.br|g' "$js_file" 2>/dev/null || true
    sed -i 's|http://localhost:3012|https://api-crm.jeanpierreribeiro.com.br|g' "$js_file" 2>/dev/null || true
  fi
done

echo "=== [5/6] Configurando index.html com guardiões e sem cache ==="
cat << 'EOF' > "$HTML_DIR/index.html"
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <title>jprOS</title>
    <script>
      // 1. Limpeza forçada de ServiceWorkers e CacheStorage legados
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(function(regs) {
          for (var r of regs) { r.unregister(); }
        });
      }
      if ('caches' in window) {
        caches.keys().then(function(names) {
          for (var n of names) { caches.delete(n); }
        });
      }

      // 2. Guardião contínuo do DOM: sanitiza rodapé, remove links externos legados e garante jprOS
      (function() {
        function sanitizeBranding() {
          // Remove links indesejados (documentação antiga e suporte whatsapp antigo)
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

          // Varre todos os nós de texto do corpo para garantir a marca jprOS
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

        var obs = new MutationObserver(sanitizeBranding);
        obs.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
        window.addEventListener('DOMContentLoaded', sanitizeBranding);
        window.addEventListener('load', sanitizeBranding);
        setInterval(sanitizeBranding, 500);
      })();
    </script>
EOF

# Detectar arquivo principal CSS e JS para manter hashes corretos
MAIN_JS=$(ls -1 "$ASSETS_DIR"/index-*.js 2>/dev/null | head -n 1 | xargs basename 2>/dev/null || echo "")
MAIN_CSS=$(ls -1 "$ASSETS_DIR"/index-*.css 2>/dev/null | head -n 1 | xargs basename 2>/dev/null || echo "")
TIMESTAMP=$(date +%s)

if [ -n "$MAIN_CSS" ]; then
  echo "    <link rel=\"stylesheet\" crossorigin href=\"/assets/$MAIN_CSS?v=$TIMESTAMP\">" >> "$HTML_DIR/index.html"
fi
if [ -n "$MAIN_JS" ]; then
  echo "    <script type=\"module\" crossorigin src=\"/assets/$MAIN_JS?v=$TIMESTAMP\"></script>" >> "$HTML_DIR/index.html"
fi

cat << 'EOF' >> "$HTML_DIR/index.html"
    <style>
      :root, .dark, html, body, [data-theme] {
        --primary: #3B82F6 !important;
        --primary-foreground: #ffffff !important;
        --color-primary: #3B82F6 !important;
        --color-primary-foreground: #ffffff !important;
        --sidebar-primary: #3B82F6 !important;
      }
      button.bg-primary, .bg-primary:not(input):not(textarea):not(select), .dark button.bg-primary {
        background-color: #3B82F6 !important;
        color: #ffffff !important;
      }
      .hover\:bg-primary\/90:hover:not(input), button.bg-primary:hover {
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
      input:not([type="button"]):not([type="submit"]):not([type="reset"]), textarea, select {
        background-color: rgba(255, 255, 255, 0.05) !important;
        color: #f8fafc !important;
        border-color: rgba(255, 255, 255, 0.15) !important;
      }
      input:-webkit-autofill,
      input:-webkit-autofill:hover, 
      input:-webkit-autofill:focus {
        -webkit-text-fill-color: #ffffff !important;
        -webkit-box-shadow: 0 0 0px 1000px #0f172a inset !important;
        transition: background-color 5000s ease-in-out 0s !important;
      }
    </style>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF

echo "=== [6/6] Recarregando Nginx (se disponível) ==="
if command -v nginx >/dev/null 2>&1; then
  nginx -s reload || true
elif command -v systemctl >/dev/null 2>&1; then
  systemctl reload nginx || true
fi

echo "=========================================================="
echo " Identidade visual jprOS aplicada com sucesso!"
echo " Recarregue o navegador com Ctrl + F5 para testar."
echo "=========================================================="
