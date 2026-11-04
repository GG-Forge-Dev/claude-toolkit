# Herramientas por stack

Léelo solo para el stack que estés tocando.

## Códigos de error de la base

| Postgres (`SQLSTATE`) | Significa | Respuesta |
|---|---|---|
| `23505` unique_violation | ya existe | 409 |
| `23503` foreign_key_violation | en uso / no existe el padre | 409 o 422 |
| `23514` check_violation, `23502` not_null_violation | valor imposible | 422 |
| `23P01` exclusion_violation | se pisa con otro (horarios, reservas) | 409 |
| `40001` serialization_failure, `40P01` deadlock_detected | choque de transacciones | reintentar la transacción (2-3 veces) |

SQLite / Cloudflare D1: el error trae el texto `UNIQUE constraint failed: tabla.columna` (o `FOREIGN KEY constraint failed`, `CHECK constraint failed`); se detecta por ese texto.

## Go + Postgres

- **pgx v5**: `var pgErr *pgconn.PgError; if errors.As(err, &pgErr) && pgErr.Code == pgerrcode.UniqueViolation { ... }` (constantes en `github.com/jackc/pgerrcode`). `pgErr.ConstraintName` dice qué índice chocó: nómbralos bien (`categorias_bar_nombre_unico`) para traducir al campo.
- **sqlc**: la restricción va en la migración; sqlc genera la consulta tipada. Para «insertar si no existe»: `INSERT ... ON CONFLICT (...) DO NOTHING RETURNING id` (sin fila = ya existía).
- **golangci-lint**: `errorlint` (comparar errores con `errors.As/Is`), `rowserrcheck` y `sqlclosecheck` (filas sin cerrar o sin comprobar `rows.Err()`), `nilerr`.
- **Tests**: `go test -race -shuffle=on -count=N`. Propiedades: `pgregory.net/rapid`. Entradas raras: fuzzing nativo (`go test -fuzz`).

## TypeScript / Node

- **Validación en el borde**: Zod (`@hono/zod-validator` en Hono). Normaliza ahí igual que la base (`.trim()`, comparación sin mayúsculas).
- **Drizzle**: ``uniqueIndex('categorias_bar_nombre_unico').on(t.barId, sql`lower(${t.nombre})`)``, con ``.where(sql`deleted_at is null`)`` si hay borrado lógico. Drizzle envuelve el error del driver: el código está en `err.cause.code` (recorre la cadena de `cause`, a veces hay más de un nivel).
- **Prisma**: `@@unique([barId, nombre])`; errores `P2002` (único), `P2003` (FK), `P2025` (no existe). Un índice sobre `lower(nombre)` o parcial no se expresa en el schema: va en una migración SQL a mano.
- **node-postgres / postgres.js**: `err.code === '23505'`; el nombre del índice en `err.constraint` (pg) o `err.constraint_name` (postgres.js).
- **D1**: no hay transacciones interactivas; varias escrituras que van juntas, en `db.batch([...])`. Las FK se aplican por defecto (en SQLite normal hace falta `PRAGMA foreign_keys = ON`). Sin mayúsculas: `nombre TEXT COLLATE NOCASE` o índice sobre `lower(nombre)`.
- **Tests**: Vitest con `--sequence.shuffle`; base real con Testcontainers o PGlite (Postgres), `@cloudflare/vitest-pool-workers` (D1). Propiedades: `fast-check`.

## Rust (sqlx)

`err.as_database_error()` y luego `is_unique_violation()`, `is_foreign_key_violation()`, `is_check_violation()`. Consultas comprobadas al compilar con `sqlx::query!`. Propiedades: `proptest`.

## Firebase / Firestore

No hay índices únicos. Para un nombre único: un documento cuyo id es el nombre normalizado (`bares/{bar}/nombresCategoria/{nombre}`) creado con `create()` dentro de la misma transacción que la categoría; `create()` falla si ya existe. Y reglas de seguridad que lo exijan.

## Migraciones (Postgres)

- **Squawk** (`squawk-cli` en npm o pip; corre en Linux/macOS, en Windows vía WSL o CI): avisa de migraciones peligrosas, p. ej. `CREATE INDEX` sin `CONCURRENTLY` en tablas existentes (bloquea las escrituras mientras se crea).
- **Atlas** (`atlas migrate lint`): análisis parecido y detección de cambios destructivos.
- Antes de añadir un índice único, cuenta duplicados: `SELECT bar_id, lower(btrim(nombre)), count(*) FROM categorias GROUP BY 1, 2 HAVING count(*) > 1`.

## Toda la API de golpe

Si el producto publica OpenAPI, **Schemathesis** genera cientos de peticiones contra cada endpoint a partir del contrato y avisa de los 500 y de las respuestas que no cumplen el contrato; su modo con estado encadena crear → leer → editar → borrar siguiendo los links de OpenAPI. Se corre en el CI contra el servidor de pruebas. La sintaxis cambió entre versiones: mira `--help` de la instalada.

## Interfaz

- React 19: `useActionState` / `useFormStatus` (`pending`). TanStack Query: `isPending` de la mutación. React Hook Form: `formState.isSubmitting`.
- Id o clave de idempotencia: `crypto.randomUUID()` generado **una vez** al abrir el formulario o al encolar la acción offline, y reutilizado en cada reintento.

## E2E (Playwright)

- Localizadores estrictos: si hay dos coincidencias, fallan. Es una ayuda (así salió el defecto de skalpos): no la tapes con `.first()`.
- `expect(locator).toHaveCount(n)` espera hasta que se cumpla; úsalo en vez de leer la lista una vez.
- Detectar inestables: `--repeat-each=10 --retries=0`; en CI se puede añadir `--fail-on-flaky-tests` para que un test que solo pasa al reintentar cuente como fallo.
