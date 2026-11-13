# Desarrollo con IA (todos los proyectos)
La IA falla sobre todo cuando genera mucho de golpe: inventa requisitos, sobrediseña y deja errores difíciles de ver. Para evitarlo:

- **No inventes requisitos.** Si falta información que cambia el resultado, pregunta (una pregunta, con tu respuesta sugerida). Lo que es fácil de cambiar después, decídelo tú y dilo.
- **Lo más simple que cumpla.** Nada de abstracciones, capas, configuración ni patrones "para el futuro"; propónlos solo cuando algo ya se repite.
- **Cortes verticales y pequeños.** Cada paso atraviesa las capas que haga falta (datos, backend, UI) y deja algo usable; nunca "primero toda la base de datos".
- **Especifica justo a tiempo, no todo de entrada.** Una historia corta por corte, se construye, se prueba y el siguiente corte se decide con lo aprendido. Si una spec existente y el código ya no coinciden, manda lo aprendido: actualiza la spec en vez de forzar el código.
- **Proceso proporcional al tamaño.** Arreglo pequeño: directo. Funcionalidad: skill `historia`. Solo un producto nuevo o un cambio de arquitectura justifica una sesión de diseño y un plan escrito (`superpowers:brainstorming`, `writing-plans`). Para todo lo demás, `historia` reemplaza a esas dos skills.
- **Verifica ejecutando, no solo leyendo.** Al terminar un corte, córrelo de verdad (tests, la app, el endpoint) y mira la salida. En los caminos críticos (pagos, webhooks, colas, login) deja logs estructurados con ids y sin secretos, para ver en Sentry u Observability qué pasó en producción sin leer el código línea por línea.
- **Contexto barato.** Para explorar mucho código usa un subagente y quédate con su conclusión; lee fragmentos, no archivos enteros, cuando basta.
- **Los tests no se tocan para que pasen.** Nunca cambies, saltes ni borres un test para ponerlo en verde: si el test está mal, dilo.
- **El valor esperado de un test sale del requisito**, nunca de la misma lógica que el código que prueba. Prueba el comportamiento por la interfaz pública.
- **Tests que intentan romper, no solo confirmar.** Si la IA escribe el código y sus tests, los dos comparten los mismos puntos ciegos. En lógica pura con una regla clara (analizar o normalizar texto, tapar secretos, dinero, fechas, permisos), además de los ejemplos va **un test de propiedad**: la regla escrita una vez y probada con cientos de entradas generadas (Hypothesis, fast-check, `rapid`, proptest; ver `pareja`). Corre con los tests normales, sin gastar IA.
- **Dos intentos y paras.** Si tras dos intentos algo sigue fallando, detente y explica qué pasa en vez de seguir parchando.
- **Refactor aparte.** Solo con los tests en verde y nunca mezclado con funcionalidad nueva.

Las skills `historia` (antes de una funcionalidad nueva) y `pareja` (código delicado) aplican estas reglas paso a paso. **Úsalas tú mismo cuando toque**: el usuario no las invoca a mano.
