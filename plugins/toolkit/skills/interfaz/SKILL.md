---
name: interfaz
description: Use al crear o cambiar una pantalla, una página o un componente visible de un producto (web o app). Hace que la interfaz siga el diseño propio del producto (docs/diseno/DESIGN.md y su imagen de referencia) y que la mires en capturas de móvil y escritorio, con sus estados y su accesibilidad, antes de darla por terminada.
---

# Interfaz

Que lo que ve el cliente sea coherente, cuidado y accesible, sin gastar de más. Cada producto tiene su propia identidad: el diseño sale de **su** `DESIGN.md`, nunca de otro producto ni de un estilo por defecto.

## 1. Antes de tocar la pantalla

- Lee `docs/diseno/DESIGN.md` del producto. Mira la imagen `docs/diseno/referencia.*` solo si la pantalla es nueva o si el `DESIGN.md` no aclara algo (una imagen cuesta muchos tokens).
- **Si no hay `DESIGN.md`, para antes de hacer pantallas y pregunta al usuario** (una sola pregunta) cómo seguir:
  1. **Me pasas una imagen de referencia** (la que prepara Andrés): la guardo en `docs/diseno/referencia.*` y escribo el `DESIGN.md` a partir de ella con `plantilla-design.md`.
  2. **Lo diseño yo con `/design`**: propongo el diseño, lo apruebas, y con eso escribo el `DESIGN.md`.
  3. **Si el producto ya tiene pantallas**: escribo el `DESIGN.md` a partir de cómo se ve hoy.
  No sigas con la interfaz hasta tener la respuesta. Si el usuario dice que siga sin diseño, imita las pantallas que ya existen y recuérdalo al terminar.
- Reutiliza los componentes y tokens del producto. Un color, una fuente o un tamaño que no esté en el `DESIGN.md` no se inventa: se propone añadirlo allí.

## 1b. Constrúyela con lo que ya trae el navegador (solo web)

En la parte web de un producto (no en backend, bots ni infraestructura), antes de construir una pieza
con un patrón conocido, consulta la guía de Chrome, Edge, Firefox y MDN: así no salen patrones viejos ni
librerías de más. Viene en el plugin `modern-web-guidance@googlechrome`, que se actualiza solo.
- **Cuándo**: modales, popovers y menús; formularios y su validación; tablas; animaciones y transiciones;
  modo oscuro; rendimiento (LCP, INP, CLS, imágenes); limpiar HTML del usuario; fechas y zonas horarias.
  Para extensiones de Chrome, su skill `chrome-extensions`.
- **Cómo**: sigue su skill (`search` y luego `retrieve`), pero ejecuta su CLI siempre con la versión más
  nueva que lleve **al menos 7 días publicada**, nunca la recién salida: si una versión saliera
  comprometida, suele detectarse en esos días. En Windows usa `npx.cmd`:
  `npx -y --before=<fecha de hace 7 días, AAAA-MM-DD> modern-web-guidance@latest search "<consulta>"`.
- **Todo en español**: no añadas su sección final «### Modern Web Guidance» en inglés. En la línea de
  cierre de esta skill (punto 4) di, en español y sencillo, qué guías usaste y qué cambiaron.
- Si el plugin no está instalado, sigue sin él y avisa al usuario en una línea.

## 2. Mírala antes de darla por hecha

Captura **solo la pantalla que cambiaste**, en móvil (390×844) y escritorio (1280×800), con el navegador integrado o Playwright, y mírala de verdad: ¿se parece al `DESIGN.md`? ¿algo cortado, desalineado o ilegible? Si es una captura de verificación, usa escala reducida.

Revisa solo los estados que aplican a esa pantalla:

- **Vacío** (sin datos), **cargando**, **error** (incluido sin conexión si el producto funciona offline).
- **Texto largo** (nombres largos, otros idiomas si el producto los tiene) y números grandes.
- **Teclado**: se llega a todo con Tab, el foco se ve y Escape cierra lo que se abre.
- **Red**: si la pantalla guarda o carga datos, mira las peticiones de la acción (pestaña Network o `read_network_requests`): cada consulta una sola vez, sin repetidas tras guardar (ver la skill `escrituras`, «Una sola recarga por cambio»).
  - Si tiene un buscador, escribe letra por letra: debe salir una petición al dejar de escribir, no una por letra.
  - Si tiene botones que guardan, dales doble clic: debe salir una sola petición y el botón quedar deshabilitado mientras tanto.
- **Celular**: nada depende de pasar el mouse. Las ayudas largas van en un «¿Cómo funciona?» que se abre con un toque, no en un tooltip de hover; los objetivos táctiles miden al menos 44 px.
- **Navegación**: toda pantalla a la que se llega desde otra tiene cómo volver en el celular (un «← Volver a X» visible), sin depender del botón atrás del sistema.
- **Textos de ayuda**: cada paso que se le explica al usuario (asistentes, tooltips, «¿Cómo funciona?») sale de cómo funciona hoy el código, con los nombres reales de los botones; léelo antes de escribirlo.
- **Modo oscuro**, solo si el producto lo tiene.

## 3. Accesibilidad

- Si los E2E del producto ya pasan axe, basta con que sigan en verde.
- Si no: contraste suficiente (4.5:1 en texto normal), cada botón e input con nombre o etiqueta, imágenes con `alt`, objetivos táctiles de al menos 44 px y nada que dependa solo del color.
- Para una pantalla nueva entera o un flujo de compra/registro, pasa además la skill `design:accessibility-review` si está instalada. Para cambios pequeños no hace falta.

## 4. Al terminar

Una línea: qué pantallas y estados miraste y qué corregiste. Si algo no se pudo comprobar (p. ej. no hay datos para el estado vacío), dilo.

## Montar esto en un producto nuevo

Ver `montaje.md` (axe y capturas en los E2E, reglas de arquitectura y analíticas: Cloudflare Web Analytics o Umami si hay que medir clics). Léelo solo al montar un producto o si el usuario lo pide.
