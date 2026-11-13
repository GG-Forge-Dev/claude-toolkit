# claude-toolkit

Configuración de Claude Code de GG Forge, portable a cualquier PC.

## Qué incluye

| Pieza | Qué hace |
|---|---|
| Plugin `stive-toolkit` | Reglas globales (idioma español, calidad de código, desarrollo con IA: especificar justo a tiempo, proceso proporcional al tamaño y verificar ejecutando) inyectadas en cada sesión |
| Skills `historia` y `pareja` | Claude las usa solo, sin `/`: `historia` antes de una funcionalidad nueva (criterios de aceptación, mini plan, fuera de alcance) y `pareja` en código delicado (pagos, auth, borrado de datos…: lista de tests aprobada, ciclos rojo → verde, tests de propiedad para las reglas de lógica pura y un subagente que, sin ver la implementación, escribe tests para romperla). Adaptadas de [hola-ai](https://github.com/nschurmann/hola-ai) (MIT) |
| Skill `interfaz` y regla de productos | Al tocar una pantalla, Claude sigue el diseño propio del producto (`docs/diseno/DESIGN.md` y su imagen de referencia) y la revisa en capturas de móvil y escritorio, con sus estados y accesibilidad. Al crear un producto nuevo, monta axe y capturas en los E2E, reglas de arquitectura en el linter y analíticas sin cookies: Cloudflare Web Analytics para visitas, o Umami si hay que medir clics o conversiones (`skills/interfaz/montaje.md`) |
| Skill `ci-rapido` | Al montar o cambiar un CI, o si tarda: medir antes, base de datos plantilla en los tests de integración, jobs en paralelo sin choques (varios runners, puertos libres) y limpieza aunque se cancele. Sin quitar ningún test |
| Regla de datos, skill `escrituras` y agente `auditor-escrituras` | Lo que no puede repetirse o romperse se garantiza en la base de datos (índice único, FK, CHECK), no solo en el código. Cada endpoint que crea, edita o borra lleva su batería de tests (duplicado, dos peticiones a la vez, otro cliente, borrar en uso) y un test guardián hace fallar el CI si una escritura nueva no tiene tests. Los tests crean sus propios datos y no dependen de la semilla. En la interfaz: las búsquedas al escribir llevan debounce (una petición al dejar de escribir) y todo control que escribe queda deshabilitado mientras su petición está en curso, con E2E que lo cuentan. Y cada campo que escribe el usuario se valida en el servidor (largo, rango, formato, una sola línea) con los mismos límites en la web. `herramientas.md` resume cómo hacerlo en Go, TypeScript (Drizzle, Prisma, D1), Rust y Firestore; el agente audita un producto existente y devuelve la tabla de huecos sin tocar nada |
| Quality gate (hook Stop) | Al terminar cada turno ejecuta typecheck, lint, Knip y clippy/fmt sobre los archivos cambiados. Bloquea solo si hay errores en lo que cambió Claude |
| `setup/install.*` | Instala y configura RTK (`rtk init -g`), graphify, superpowers, context7 y este plugin |

RTK no va dentro del plugin: se configura con su propio `rtk init -g`, que es su forma oficial y evita avisos de "No hook installed".

Los **conectores** y las **skills de claude.ai** no van aquí: viajan con tu cuenta al iniciar sesión.

## Instalar en un PC nuevo

Requisitos: Claude Code, Node.js y Git.

```powershell
git clone https://github.com/GG-Forge-Dev/claude-toolkit.git
cd claude-toolkit
powershell -ExecutionPolicy Bypass -File setup\install.ps1
```

En macOS/Linux: `bash setup/install.sh`.

## Actualizar

1. Edita este repo (reglas en `plugins/toolkit/rules/`, skills en `plugins/toolkit/skills/`, agentes en `plugins/toolkit/agents/`, hooks en `plugins/toolkit/hooks/`).
2. Sube la `version` en `plugins/toolkit/.claude-plugin/plugin.json` y en `.claude-plugin/marketplace.json`.
3. Haz push y, en cada PC: `claude plugin marketplace update stive` y luego `claude plugin update stive-toolkit@stive`.

## Desactivar el quality gate

- En un repo concreto: crea `.claude/no-quality-gate`.
- En todos: variable de entorno `CLAUDE_QUALITY_GATE=off`.
- Una regla concreta: renombra su `.md` en `rules/` a `.md.off`.

## Nota para el PC de la empresa

Algunas organizaciones bloquean los plugins o hooks personales con su configuración gestionada. Si no carga, revisa esa política antes de depurar.
