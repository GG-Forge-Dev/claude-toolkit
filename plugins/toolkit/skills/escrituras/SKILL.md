---
name: escrituras
description: Use al crear o cambiar un endpoint, server action, mutación o pantalla que crea, edita o borra datos; al escribir una migración o tabla nueva; o cuando un test falla a veces y otras no. Evita duplicados, condiciones de carrera, borrados indebidos y tests frágiles - la regla va en la base de datos, cada escritura y borrado lleva su batería de tests y los tests no dependen de los datos de partida.
---

# Escrituras seguras

Caso real que motiva esta skill (skalpos): cada bar nace con 5 categorías, entre ellas «Cervezas». Trece tests creaban otra «Cervezas» y buscaban «la categoría Cervezas»: a veces veían dos y fallaban. Detrás había un defecto real: nada impedía dos categorías, zonas o cajas con el mismo nombre. Bastaba un doble toque, un reintento o dos dispositivos a la vez.

## 1. La regla, en la base de datos

Antes de escribir el endpoint, decide qué **no** puede pasar y ponlo en el esquema (con su migración):

| Qué no puede pasar | Cómo |
|---|---|
| Dos con el mismo nombre en el mismo ámbito | Índice único compuesto con el ámbito: `UNIQUE (bar_id, lower(btrim(nombre)))`. Si hay borrado lógico: `... WHERE deleted_at IS NULL` (índice parcial) |
| Que quede algo apuntando a lo borrado | FK con `ON DELETE` explícito: `RESTRICT` (no se borra si se usa), `CASCADE` (se borra con el padre) o `SET NULL`. Nunca sin decidir |
| Valores imposibles (cantidad ≤ 0, estado inventado, fin antes que inicio) | `CHECK` / enum |
| Dos cosas que se pisan (dos reservas de la misma mesa a la vez) | Restricción de exclusión (`EXCLUDE USING gist`) o índice único parcial (`UNIQUE (mesa_id) WHERE abierta`) |
| Contadores y saldos que se descuadran | `UPDATE ... SET saldo = saldo - $1 WHERE id = $2 AND saldo >= $1` (atómico) o `SELECT ... FOR UPDATE` dentro de la transacción. Nunca leer, calcular en el código y escribir |
| Dos ediciones que se pisan | Bloqueo optimista: columna `version`, `UPDATE ... WHERE id = $1 AND version = $2`; 0 filas → 409 |

- **Normaliza igual en todas las capas**: lo que la base compara (`lower(btrim(...))`) es lo que la UI y la API deben considerar «el mismo nombre».
- **Migración sobre datos que ya existen**: crear un índice único falla si ya hay duplicados. Primero una consulta que los cuente; si hay, la migración los resuelve (renombrar con sufijo, fusionar) y se le dice al usuario qué hará antes de ejecutarla en producción. En tablas grandes, `CREATE UNIQUE INDEX CONCURRENTLY` (fuera de transacción).
- **Nada de «comprobar y luego insertar»** como única protección. Se inserta y se traduce el error de la base.

## 2. El endpoint

- **Traduce el error de la base a una respuesta clara**, nunca un 500: violación de único → 409 con qué campo choca; FK → 409 («está en uso») o 422; CHECK → 422. Códigos y cómo leerlos en cada stack: `herramientas.md`.
- **Ámbito siempre**: toda escritura y borrado filtra por el dueño (`WHERE id = $1 AND bar_id = $2`). Un id de otro cliente responde 404, no 403 (no se revela que existe).
- **Reintentos sin duplicar**: si el cliente puede reintentar (red móvil, cola offline), que el id lo genere el cliente (UUID v7) e inserte con `ON CONFLICT (id) DO NOTHING`, o usa una cabecera `Idempotency-Key` guardada con la respuesta. Obligatorio en pagos y en todo lo que pase por una cola offline.
- **Borrar**: decide y prueba qué pasa si se usa (bloquear o borrar en cascada), si se borra dos veces (204 o 404, pero siempre igual) y si el borrado es lógico (y entonces el índice único debe ser parcial para poder volver a crear el nombre).
- Si el borrado es irreversible o en cascada sobre datos del cliente, sigue la skill `pareja`.

## 3. La interfaz

Ayuda, no garantiza:
- Botón deshabilitado mientras se envía (`isPending`, `useFormStatus`) y la misma clave de idempotencia si se reintenta.
- El 409 se muestra junto al campo («Ya existe una categoría con ese nombre»), no como error genérico.
- Si hay actualización optimista, se deshace cuando el servidor rechaza.

## 4. Tests de cada escritura y borrado

Plantillas en `tests.md`. Para cada endpoint que crea, edita o borra, los que apliquen:

1. Camino feliz: responde bien **y** el dato quedó en la base como se esperaba.
2. Validación: entrada inválida → 400/422, y la base no cambió.
3. Sin sesión → 401. Recurso de otro cliente → 404 y **no** se tocó.
4. Duplicado secuencial → 409.
5. **Duplicado concurrente**: N peticiones iguales a la vez → exactamente 1 éxito, el resto 409, y 1 fila en la base.
6. Reintento con el mismo id o clave de idempotencia → mismo resultado, sin duplicar.
7. Borrar: en uso (bloquea o cascada, lo decidido), dos veces, y que luego no aparezca en listados.

Además, un **test guardián** que lista las rutas de escritura del router y falla si alguna no está en la matriz de tests comunes (sin sesión, otro cliente, cuerpo inválido, nunca 500). Así un endpoint nuevo sin tests rompe el CI. Ver `tests.md`.

## 5. Tests que no dependen de los datos de partida

- Cada test crea sus propios datos con nombres únicos (`Cervezas ${idDelTest}`) o usa el id que devolvió la API. Nunca busques por un nombre que la semilla también puede tener.
- En los E2E, espera a que la lista termine de cargar antes de contar o buscar, y comprueba cantidades exactas (`toHaveCount(1)`); los localizadores de Playwright son estrictos (si hay dos coincidencias, fallan), no lo desactives con `.first()` para que pase.
- Test nuevo de escritura o de E2E: córrelo varias veces antes de darlo por bueno (`go test -count=20 -race -shuffle=on`, `playwright test --repeat-each=10 --retries=0`).
- Si un test falla a veces, **primero busca el defecto real en la app** (como el nombre duplicado); arreglar solo el test lo esconde.

## 6. Revisar un producto que ya existe

Para inventariar todas las escrituras y borrados de un repo y ver qué restricciones y tests faltan, usa el agente `auditor-escrituras` (solo lee y devuelve una tabla de huecos). No cambies nada de ese repo sin que el usuario lo pida.

## Al terminar

Una línea: qué restricción quedó en la base, qué tests de la lista se añadieron (y cuáles no aplican) y si hubo datos existentes que resolver.
