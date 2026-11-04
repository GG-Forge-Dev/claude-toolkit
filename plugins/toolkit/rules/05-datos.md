# Datos que se crean, editan o borran
- Lo que no puede repetirse o romperse (nombres únicos, una reserva por mesa, saldo ≥ 0, que no quede algo huérfano) se garantiza **en la base de datos**: índice único, FK, CHECK o transacción. Comprobarlo antes en el código no basta, porque dos peticiones simultáneas pasan las dos la comprobación. La UI (deshabilitar el botón) solo ayuda.
- Cada endpoint o acción que **crea, edita o borra** lleva sus tests, incluido el de duplicado y el de dos peticiones a la vez. Al tocar uno, usa la skill `escrituras`.
- Los tests no dan por hecho qué datos hay: cada test crea los suyos con nombres únicos y los busca por id. Si un test falla «a veces», antes de arreglar el test busca el fallo real en la app.
