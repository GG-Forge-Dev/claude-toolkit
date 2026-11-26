---
name: ci-rapido
description: "Use al montar o cambiar el CI de un repo (GitHub Actions), cuando el CI tarda mucho o se queda en cola, o al escribir tests de integración contra una base de datos real. Hace el CI rápido sin quitar ninguna comprobación ni test: medir primero, base de datos plantilla, jobs en paralelo sin choques y limpieza aunque se cancele."
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
- Hay un tope de runners por máquina. Todos los runners de todos los repos del PC comparten la memoria de WSL (9,7 GB). Con 6 runners de Skalpos y varios PR a la vez, WSL se quedó sin memoria (2026-11-19 y 2026-11-22): el OOM killer tumbó los runners y dejó contenedores huérfanos.
  - Antes de registrar o activar otro runner, mira la memoria libre en WSL (`free -h`) y cuántos runners hay activos, de todos los repos (`systemctl list-units 'actions.runner.*'`).
  - El tope por defecto es **3 runners por repo** en el PC de Stiven. Súbelo solo después de dos cosas: darle más memoria a WSL en `.wslconfig` y medir un CI con varios PR a la vez.
  - Un runner instalado como servicio queda habilitado y vuelve a arrancar al reiniciar. Para quitar uno, usa `systemctl disable --now <unidad>`: con solo `stop` vuelve en el siguiente reinicio.
- Un runner con systemd tiene que levantarse solo. La unidad que crea `svc.sh install` trae `Restart=no` y `OOMPolicy=stop`: si el OOM killer mata un proceso del job, systemd para todo el servicio y nadie lo vuelve a arrancar. El 2026-11-26 el CI de Partii pasó 4 horas en cola por eso.
  - Al registrar un runner (o el primero de una organización en esa máquina), crea el drop-in `/etc/systemd/system/actions.runner.<org hasta su primer guion>-.service.d/10-reinicio.conf`:
    ```ini
    [Unit]
    StartLimitIntervalSec=0

    [Service]
    Restart=always
    RestartSec=15
    OOMPolicy=continue
    ```
  - `OOMPolicy=continue`: el OOM mata solo el proceso que toca y el runner sigue. `Restart=always` con `RestartSec=15`: si el runner cae por lo que sea, vuelve a los 15 s. `StartLimitIntervalSec=0`: systemd nunca se rinde de reintentar.
  - systemd aplica el directorio `<prefijo>-.service.d` a toda unidad cuyo nombre empiece por ese prefijo hasta un guion. Con el nombre de la organización hasta su primer guion (`actions.runner.GG-` para GG-Forge-Dev) vale para todos los runners de esa organización, también los que se registren después.
  - Después, `sudo systemctl daemon-reload` y `sudo systemctl restart <unidad>` de cada runner, y compruébalo con `systemctl show <unidad> -p Restart -p OOMPolicy -p DropInPaths` (debe decir `Restart=always`, `OOMPolicy=continue` y la ruta del drop-in). Escribir en `/etc/systemd` necesita el OK del usuario.
  - Referencia en el PC de Stiven: `/etc/systemd/system/actions.runner.GG-.service.d/10-reinicio.conf`.
- Varios runners en la misma máquina comparten puertos y Docker. Por eso:
  - servicios con puerto del host aleatorio (`ports: ['5432']` y leer `job.services.<svc>.ports['5432']`);
  - servidores de prueba en un puerto libre, nunca uno fijo;
  - contenedores con nombre propio de la corrida (`$GITHUB_RUN_ID`, `$GITHUB_JOB`) y la limpieza borra **solo los suyos**.
- En el runner propio no se usa la caché de GitHub: los módulos y el almacén de paquetes ya quedan en el disco, y bajarlos de GitHub es más lento.

## 4. Limpiar siempre, también al cancelar

- Los pasos de limpieza llevan `if: always()` (corren también al cancelar el job).
- Un contenedor que escribe como root en el workspace (p. ej. Playwright) hay que pararlo y devolver los archivos al usuario del runner; si no, el siguiente checkout falla con `EACCES`.
- `concurrency` con `cancel-in-progress` en ramas de PR (no en `main`) para no gastar runner en commits viejos.

## 5. Esperar el CI siempre con tope

- Nunca un `gh run watch` sin límite: `timeout 45m gh run watch <id> --exit-status` (en segundo plano si la herramienta lo permite). Un runner caído deja el job en cola para siempre y un watch sin tope espera con él.
- Si un job lleva más de 10 min en `queued`, mira los runners: `gh api repos/<org>/<repo>/actions/runners --jq '.runners[] | "\(.name) \(.status) ocupado=\(.busy)"'`.
- Si el runner sale `offline`, revisa su servicio en la máquina (`systemctl status <unidad>` y `journalctl -u <unidad> -n 50`) y avisa al usuario en ese momento, con lo que viste; no esperes a que termine el tope.

## 6. El CI de `main` tras mergear

Si la rama principal no exige que el PR esté al día antes de mergear, el CI de `main` prueba algo nuevo (la mezcla real): se deja. Solo sobra si se exige estar al día o hay merge queue.
