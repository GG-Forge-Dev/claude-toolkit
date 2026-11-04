#!/usr/bin/env bash
# Instala toda la configuración de Claude Code en un PC macOS/Linux nuevo.
# Uso:  bash setup/install.sh
# Es idempotente: se puede ejecutar varias veces.

has() { command -v "$1" >/dev/null 2>&1; }
step() { printf '\n==> %s\n' "$1"; }

for req in claude node git; do
  has "$req" || { echo "Falta '$req'. Instálalo y vuelve a ejecutar este script."; exit 1; }
done

step 'RTK (recorta la salida de comandos para ahorrar tokens)'
if has rtk; then echo 'Ya instalado.'
elif has brew; then brew install rtk || echo 'Instala RTK a mano: https://github.com/rtk-ai/rtk'
else echo 'Instala RTK a mano: https://github.com/rtk-ai/rtk (el plugin funciona sin él).'
fi
has rtk && rtk init -g --auto-patch

step 'graphify (grafo de conocimiento del código)'
if has graphify; then echo 'Ya instalado.'
elif has uv; then uv tool install graphifyy && graphify install
else echo "Falta 'uv' (https://docs.astral.sh/uv/). Luego: uv tool install graphifyy && graphify install"
fi

step 'Plugins de Claude Code'
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
claude plugin marketplace add upstash/context7
claude plugin install context7@context7-marketplace
claude plugin marketplace add GG-Forge-Dev/claude-toolkit
claude plugin install stive-toolkit@stive

step 'Listo'
echo 'Abre una sesión nueva de Claude Code para que cargue todo.'
echo 'Conectores y skills de claude.ai llegan solos al iniciar sesión con tu cuenta.'
