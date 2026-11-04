---
name: ci-rapido
description: Use al montar o cambiar el CI de un repo (GitHub Actions), cuando el CI tarda mucho o se queda en cola, o al escribir tests de integración contra una base de datos real. Hace el CI rápido sin quitar ninguna comprobación ni test: medir primero, base de datos plantilla, jobs en paralelo sin choques y limpieza aunque se cancele.
---

# CI rápido sin perder calidad

La meta es que el CI tarde lo que dura su job más largo, nunca quitar tests, lint ni comprobaciones para ganar tiempo. Lecciones del CI de Skalpos (2026-11): el paquete de tests más lento pasó de ~10 min a ~3 y los jobs dejaron de hacer cola.

## 1. Mide antes de tocar nada

- Tiempo en cola frente a tiempo de ejecución, por job: `gh api repos/<org>/<repo>/actions/runs/<id>/jobs --jq '.jobs[] | "\(.name) creado \(.created_at) inicio \(.started_at) fin \(.completed_at) runner=\(.runner_name)"'`. Si `inicio - creado` es grande, el problema es la cola (pocos runners), no el código.
- Pasos lentos: `--jq '.jobs[] | .name as $j | .steps[] | select(.completed_at) | "\($j)\t\((.completed_at|fromdateiso8601)-(.started_at|fromdateiso8601))s\t\(.name)"'`.
- Dentro de los tests, el tiempo por paquete o archivo (`go test` imprime `ok <paquete> <s>`; Vitest `--reporter=verbose`). Casi siempre lo lento es un solo paquete.

## 2. Tests contra una base real: plantilla, no migrar en cada test

Crear una base y aplicar todas las migraciones en cada test es lo que más tarda. En su lugar:

- Migrar **una sola vez** una base plantilla y, en cada test, `CREATE DATABASE <nueva> TEMPLATE <plantilla>`: cada test sigue con su base limpia y aislada.
- Nombre de la plantilla con el hash de las migraciones (si cambian, se crea otra y se borran las viejas).
- Varios procesos de test a la vez (uno por paquete) se coordinan con un candado (`pg_advisory_lock`) al crear la plantilla.
- Ejemplo: `server/internal/testdb/testdb.go` de Skalpos (un paquete pasó de ~10 min a ~3).
- Con D1/SQLite el equivalente es aplicar el esquema una vez y copiar el archivo o el estado.

## 3. Jobs en paralelo sin que choquen

- Un runner solo ejecuta un job a la vez: con un runner, los jobs de un CI (y los de dos PR) hacen cola. En el runner propio (WSL del PC, porque la org no tiene minutos de Actions) se registran varios runners por repo; script de ejemplo: `C:\Users\stive\runner-propio\add-skalpos-runners.sh` (instalar servicios necesita el OK del usuario).
- Varios runners en la misma máquina comparten puertos y Docker. Por eso:
  - servicios con puerto del host aleatorio (`ports: ['5432']` y leer `job.services.<svc>.ports['5432']`);
  - servidores de prueba en un puerto libre, nunca uno fijo;
  - contenedores con nombre propio de la corrida (`$GITHUB_RUN_ID`, `$GITHUB_JOB`) y la limpieza borra **solo los suyos**.
- En el runner propio no se usa la caché de GitHub: los módulos y el almacén de paquetes ya quedan en el disco, y bajarlos de GitHub es más lento.

## 4. Limpiar siempre, también al cancelar

- Los pasos de limpieza llevan `if: always()` (corren también al cancelar el job).
- Un contenedor que escribe como root en el workspace (p. ej. Playwright) hay que pararlo y devolver los archivos al usuario del runner; si no, el siguiente checkout falla con `EACCES`.
- `concurrency` con `cancel-in-progress` en ramas de PR (no en `main`) para no gastar runner en commits viejos.

## 5. El CI de `main` tras mergear

Si la rama principal no exige que el PR esté al día antes de mergear, el CI de `main` prueba algo nuevo (la mezcla real): se deja. Solo sobra si se exige estar al día o hay merge queue.
