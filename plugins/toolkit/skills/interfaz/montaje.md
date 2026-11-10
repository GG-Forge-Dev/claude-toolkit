# Montar la calidad de interfaz en un producto nuevo

Todo es gratis y está pensado para no alargar el CI: unos segundos por pantalla. Se monta al crear el producto; en uno ya en marcha, solo si el usuario lo pide.

## 1. Diseño propio

- `docs/diseno/referencia.png` (o `.jpg`/`.webp`): la imagen que prepara Andrés. Se guarda en el repo; si el diseño cambia, se reemplaza.
- `docs/diseno/DESIGN.md`: se escribe con `plantilla-design.md` a partir de esa imagen. Los tokens (colores, fuentes, radios) van también en el código (variables CSS o `@theme` de Tailwind) con los mismos nombres.

## 2. Accesibilidad en los E2E (axe)

`@axe-core/playwright` como devDependency de los E2E. Un ayudante y una llamada por pantalla visitada:

```ts
import AxeBuilder from '@axe-core/playwright';
import { expect, type Page } from '@playwright/test';

export async function sinErroresDeAccesibilidad(page: Page) {
  const { violations } = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa']).analyze();
  expect(violations.map((v) => `${v.id}: ${v.help}`)).toEqual([]);
}
```

Si una regla falla por algo de terceros que no se puede arreglar, se excluye ese selector con `.exclude(...)` y un comentario del porqué; nunca se apaga la regla entera.

## 3. Capturas de referencia (regresión visual)

Solo de **3 a 5 pantallas clave** (las que más ve el cliente), en móvil y escritorio:

```ts
await expect(page).toHaveScreenshot('inicio-movil.png', {
  fullPage: true,
  mask: [page.getByTestId('hora-actual')], // lo que cambia en cada corrida
});
```

- Las capturas base se generan **en la misma imagen de Docker de Playwright que usa el CI** (`--update-snapshots`), porque las fuentes cambian entre sistemas y darían falsos fallos.
- Si un cambio de diseño es intencionado, se regeneran y se suben en el mismo PR; quien revisa mira el diff de imágenes.
- Datos fijos (semilla) para que las pantallas salgan iguales en cada corrida.

## 4. Reglas de arquitectura en el linter

Las reglas de capas de los ADR se comprueban en el CI, no se dejan escritas solamente:

- **Go** (golangci-lint v2, `depguard`):

  ```yaml
  linters:
    enable: [depguard]
    settings:
      depguard:
        rules:
          httpapi-sin-db:
            files: ['**/internal/httpapi/**']
            deny:
              - pkg: '<módulo>/internal/db'
                desc: 'httpapi habla con service, nunca con la base directamente'
  ```

- **TypeScript**: `dependency-cruiser` con reglas `forbidden` (ejemplo en el repo de Partii, `.dependency-cruiser.cjs`).

## 5. Analíticas: Cloudflare Web Analytics o Umami (uso real, sin cookies)

**Cuál usar** (uno solo por sitio, nunca los dos: duplican visitas y el CSP):

- **Solo hace falta saber cuántas visitas y qué páginas** → Cloudflare Web Analytics (abajo). Es lo normal.
- **Hace falta medir clics o conversiones** (qué canal de contacto eligen, quién pulsa «demo», «registrarse» o «pedir presupuesto», desde qué sección) → **Umami Cloud** (abajo). Cloudflare Web Analytics no tiene eventos propios, solo páginas vistas.
- Si no está claro, pregunta al usuario en una línea qué decisión quiere tomar con los datos; si la respuesta incluye un botón, es Umami.

### Cloudflare Web Analytics

Gratis y sin cookies. Una sola cuenta de Cloudflare para todos los productos.

- **Web servida por un Worker o fuera de Cloudflare** (lo normal en nuestros productos): crear en *Analytics & Logs → Web Analytics* un sitio **manual** con el hostname del producto (no el automático de la zona: su token solo vale para el `/cdn-cgi/rum` propio y el envío falla por CORS) y poner su snippet en el layout:
  `<script type="module" src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon='{"token": "<token del sitio>"}'></script>`.
  El token es público (va en el HTML), no es un secreto. Ejemplo funcionando: `src/layouts/Base.astro` del repo `web`.
- **Página estática detrás del proxy, sin Worker**: basta la instalación automática; comprueba que el HTML servido incluye `beacon.min.js`.
- Comprueba en el navegador, en producción, que la petición a `cloudflareinsights.com/cdn-cgi/rum` no da error de CORS.
- Si hay `Content-Security-Policy`: `script-src https://static.cloudflareinsights.com` y `connect-src https://cloudflareinsights.com`.
- Apps nativas (Capacitor, Tauri, Expo): no aplica tal cual; decidir con el usuario.

### Umami Cloud (cuando hay que medir clics)

Sin cookies y con plan gratis. Ejemplo funcionando: el portafolio (`stiven.gg-forge.com`, repo `Parabellam/portfolio`): `src/layouts/Base.astro` y el CSP en `astro.config.mjs`.

- El sitio se crea en la cuenta de Umami de GG Forge: eso lo hace el usuario (necesita su sesión). Pídele el *Website ID*; es público (va en el HTML), no es un secreto.
- Snippet en el layout, limitado al dominio de producción para no contar local ni previews:
  `<script defer src="https://cloud.umami.is/script.js" data-website-id="<website id>" data-domains="<hostname de producción>"></script>`
- Eventos con atributos en el propio elemento, sin JavaScript: `data-umami-event="<nombre>"` y cada dato extra como `data-umami-event-<clave>="<valor>"`. Nombres en español, en minúsculas y con guiones, y los mismos en todo el producto. Ejemplo: `data-umami-event="ver-proyecto" data-umami-event-proyecto="ronda" data-umami-event-origen="scroll"`.
- Mide solo lo que lleva a una decisión (contacto, demo, registro, cambio de vista); no cada clic. Nunca datos personales en los eventos (ni correos, ni nombres, ni lo que escriben en un formulario).
- Si hay `Content-Security-Policy`: `script-src https://cloud.umami.is` y `connect-src https://gateway.umami.is`.
- Comprueba en el navegador, en producción, que al pulsar un botón medido sale la petición a `gateway.umami.is` sin error, y que el evento aparece en el panel de Umami.
