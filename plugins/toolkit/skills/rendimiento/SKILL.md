---
name: rendimiento
description: Use al montar un producto nuevo, cuando algo va lento (una pantalla, una consulta, el arranque), o antes de una optimización de rendimiento. Lo barato que todo producto trae desde el primer día, cómo medir antes de tocar nada (p95, EXPLAIN, Lighthouse, web-vitals) y qué no vale la pena hacer sin un número que lo pida.
---

# Rendimiento

Que la app no vaya lenta sin construir de más. Sale de revisar una lista popular de 27 optimizaciones contra Skalpos (2026-11-20): la mayoría ya venía resuelta por lo barato, y lo que faltaba era **medir**, no construir.

## 1. Lo barato, desde el primer día

Al montar un producto (o si falta en uno que ya existe y el usuario lo pide):

- **Fuentes:** la del sistema (`system-ui, …`) o una propia alojada en el producto, con 2 grosores como máximo. Nunca Google Fonts en caliente.
- **Imágenes:** las que sube el usuario se reducen en el cliente antes de subir (p. ej. 480 px en WebP) y se sirven con la URL con huella; las del producto, en WebP o SVG con `width` y `height`. La imagen más grande de la primera pantalla lleva `fetchpriority="high"` y nunca `loading="lazy"`.
- **JavaScript:** cada ruta con carga perezosa; los paneles internos, en un build aparte; los scripts de terceros (pagos, captcha, reproductores, analíticas) solo en la pantalla que los usa.
- **Caché:** los archivos con huella llevan `Cache-Control: public, max-age=31536000, immutable`; el HTML lleva `no-cache`. Detrás de una CDN, comprueba que el HTML también salga comprimido (un `no-transform` lo impide).
- **Servidor:** en la misma región que la base de datos, con pool de conexiones (mínimo, máximo y tiempos máximos de consulta y de bloqueo).
- **Datos:** ver la regla de datos (índice para cada filtro común, listados con tope) y la skill `escrituras` (debounce, una sola recarga por cambio).

## 2. Medir antes de optimizar

Sin un número de antes y después, la optimización no se hace. Qué medir según el síntoma:

| Síntoma | Cómo se mide |
|---|---|
| Una consulta o un informe lento | `EXPLAIN (ANALYZE, BUFFERS)` con un volumen realista (un año de datos de prueba), o `pg_stat_statements` en producción |
| El servidor responde lento | p95 por ruta (un middleware que registre la duración, o trazas de Sentry con muestreo bajo) |
| La primera carga | Lighthouse o PageSpeed en **móvil**, y con sesión si la pantalla la pide (sin sesión mide la entrada) |
| Lo que viven los usuarios | `web-vitals` (LCP, INP, CLS) enviado a Sentry o a un endpoint propio |
| Una pantalla que se traba | React Profiler (o el del framework) en un celular de gama baja, antes de añadir `memo` |

## 3. Probar como el usuario

- En los E2E de los flujos críticos (entrar, la acción principal, pagar), un proyecto móvil (`devices['Pixel 7']`) además del de escritorio.
- Una prueba con red lenta (latencia alta con `Network.emulateNetworkConditions` de CDP) en el arranque y en la acción principal. Si el producto funciona sin conexión, también sin red.

## 4. Lo que no se hace sin un número que lo pida

Renderizar en el servidor una app detrás de login (rompe la app empaquetada y el modo sin conexión), virtualizar listas de cientos de filas, una cola de trabajos con framework para poco volumen, OpenTelemetry completo en un solo servicio, más instancias sin que suba el p95, esqueletos de carga cuando los datos ya salen de la caché.

## Al terminar

Una línea: qué se midió, el número de antes y de después, y qué se dejó sin hacer por no tener número.
