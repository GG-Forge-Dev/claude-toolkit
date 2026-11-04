# Instala toda la configuración de Claude Code en un PC Windows nuevo.
# Uso:  powershell -ExecutionPolicy Bypass -File setup\install.ps1
# Es idempotente: se puede ejecutar varias veces.

$ErrorActionPreference = 'Continue'

function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

foreach ($req in 'claude', 'node', 'git') {
  if (-not (Has $req)) { Write-Host "Falta '$req'. Instálalo y vuelve a ejecutar este script." -ForegroundColor Red; exit 1 }
}

Step 'RTK (recorta la salida de comandos para ahorrar tokens)'
if (Has 'rtk') { Write-Host 'Ya instalado.' }
elseif (Has 'winget') { winget install --id rtk-ai.rtk -e --accept-source-agreements --accept-package-agreements }
else { Write-Host 'No hay winget: instala RTK a mano (https://github.com/rtk-ai/rtk). El plugin funciona sin él.' -ForegroundColor Yellow }
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
if (Has 'rtk') { rtk init -g --auto-patch }

Step 'graphify (grafo de conocimiento del código)'
if (Has 'graphify') { Write-Host 'Ya instalado.' }
elseif (Has 'uv') { uv tool install graphifyy; graphify install }
else { Write-Host "Falta 'uv' (https://docs.astral.sh/uv/). Luego: uv tool install graphifyy; graphify install" -ForegroundColor Yellow }

Step 'Plugins de Claude Code'
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace
claude plugin marketplace add upstash/context7
claude plugin install context7@context7-marketplace
claude plugin marketplace add GG-Forge-Dev/claude-toolkit
claude plugin install stive-toolkit@stive

Step 'Listo'
Write-Host 'Abre una sesión nueva de Claude Code para que cargue todo.'
Write-Host 'Conectores y skills de claude.ai llegan solos al iniciar sesión con tu cuenta.'
