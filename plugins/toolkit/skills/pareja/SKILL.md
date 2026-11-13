---
name: pareja
description: Use al escribir o cambiar código delicado, donde un error cuesta dinero, seguridad o datos - pagos y facturación, autenticación, permisos y roles, borrado o migración de datos, cálculos con dinero, criptografía o secretos, sincronización. Desarrolla en pasos pequeños guiados por tests (un test en rojo, el código mínimo, verde) con la lista de tests aprobada antes de empezar.
---

# Pareja

Programación en pareja para el código donde un error sale caro. Tú escribes el código; el usuario aprueba **una sola vez** la lista de tests, que es la especificación. Adaptado de `/pair` de [hola-ai](https://github.com/nschurmann/hola-ai) (MIT, Nicolás Schurmann): allí se para tras cada test; aquí avanzas solo y paras únicamente en los casos de abajo, porque el usuario prefiere no tener que intervenir.

## 1. Revisa

- Parte de los criterios de aceptación (de la skill `historia` o del pedido). Si no los hay, escríbelos primero con `historia`.
- Compara el plan con el código actual; si algo ya no encaja, dilo antes de empezar.

## 2. Lista de tests (único punto de aprobación)

- A partir de los criterios, propón **la lista de tests: solo los nombres**, y dónde se prueba cada uno (endpoint, servicio, componente…). Prefiere el nivel más alto que sea práctico.
- Marca como **verificación manual** lo que no se puede probar bien (p. ej. lo visual).
- Si hay lógica pura con una regla que se puede enunciar («ningún token sale sin tapar», «el total nunca es negativo», «normalizar dos veces da lo mismo que una»), añade a la lista **su test de propiedad** (ver «Tests de propiedad» abajo).
- Pide la aprobación de la lista en un solo mensaje corto y espera. Si el usuario ya dijo que no lo esperes en esta tarea, muéstrala y sigue.

## 3. Ciclo, un test cada vez

1. Escribe el test.
2. Ejecútalo y **comprueba que falla** (rojo), y que falla por el motivo esperado.
3. Escribe el **código mínimo** para que pase. Nada que el test no pida.
4. Ejecuta los tests y comprueba que pasan (verde).

Repite con el siguiente test sin esperar. Al terminar, resume en una línea por test lo que hiciste (`archivo:línea`) y las decisiones que tomaste.

### Para y pregunta (aunque estés a mitad) si:

- Necesitas una decisión de diseño que no está en el plan.
- Quieres añadir algo que no se pidió, aunque parezca razonable.
- Para que un test pase habría que cambiar, saltar o borrar un test.
- Llevas dos intentos sin llegar a verde.
- Un paso pasa de ~50 líneas o toca más de 3 archivos: propón partirlo.

### Reglas de los tests

- El valor esperado sale del criterio de aceptación, **nunca calculado con la misma lógica que el código**.
- Prueba comportamiento por la interfaz pública, no detalles internos.

## 4. Comprueba

- Con todo en verde, repasa los criterios de **verificación manual** (si puedes comprobarlos tú, p. ej. abriendo la app, hazlo).
- **Intento de romperlo.** Lanza un subagente que reciba solo los criterios de aceptación y la interfaz pública (firmas, rutas, el contrato), **sin** la implementación ni tus tests, con este encargo: escribir tests que demuestren que el código **no** cumple los criterios (entradas raras, bordes, órdenes inesperados, dos a la vez). Ejecuta lo que entregue: cada test que falla es un defecto (arréglalo con el ciclo de arriba y el test se queda) o un criterio ambiguo (pregunta). Los que pasan y aportan se quedan; los repetidos se descartan. Solo en este código delicado: en el resto no compensa lo que cuesta.
- Pide además una revisión con contexto limpio (un subagente revisor o la skill de code review), no te revises tú mismo.
- Si algo se repite o quedó desordenado, refactoriza solo con los tests en verde y en un commit aparte de la funcionalidad.
- Si salió una decisión que aplica a todo el proyecto, propón una línea para el `CLAUDE.md`.

## Tests de propiedad

En vez de tres ejemplos elegidos por quien escribió el código, se escribe la regla y la librería genera cientos de entradas (vacías, enormes, Unicode, negativas, repetidas); si una la rompe, la reduce al caso más pequeño que falla. Encaja en lógica pura con una regla clara; no sustituye a los tests de ejemplo, los completa.

| Stack | Librería |
|---|---|
| Python | Hypothesis (`@given`) |
| TypeScript | fast-check (`fc.assert(fc.property(...))`), funciona dentro de Vitest y Jest |
| Go | `pgregory.net/rapid` (o el `testing/quick` de la librería estándar) y el fuzzing nativo (`func FuzzX(f *testing.F)`) para analizadores que reciben datos de fuera |
| Rust | proptest |

Reglas que suelen valer la pena:
- **Ida y vuelta**: `leer(escribir(x)) == x` (serializar, codificar, formatear y volver a leer).
- **Idempotencia**: `normalizar(normalizar(x)) == normalizar(x)`.
- **Invariante**: lo que nunca pasa, salga lo que salga (ningún secreto visible, ningún saldo negativo, ninguna fecha fuera de rango, nunca un 500).
- **Equivalencia**: dos entradas que el negocio considera la misma dan el mismo resultado (el mismo error con otros números cae en el mismo grupo; «  Cervezas » y «cervezas» chocan).

El generador produce los datos; la regla sigue saliendo del requisito, nunca de repetir la lógica del código. Si encuentra un fallo, ese caso concreto se añade también como test de ejemplo, para que quede a la vista.

Los commits y PRs siguen el flujo normal del repo.
