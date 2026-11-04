# Plantillas de tests de escrituras y borrados

Adáptalas a los ayudantes que ya tenga el repo (servidor de pruebas, sesión, base plantilla). Nombres y rutas son de ejemplo.

## Duplicado concurrente (Go)

```go
func TestCrearCategoria_DuplicadoConcurrente(t *testing.T) {
	env := nuevoEntorno(t) // servidor de pruebas + un bar propio de este test
	const n = 10
	codigos := make([]int, n)
	errs := make([]error, n)
	salida := make(chan struct{})
	var wg sync.WaitGroup
	for i := range n {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-salida // todas salen a la vez
			codigos[i], errs[i] = env.post("/v1/categorias", `{"nombre":"Tapas"}`) // sin t.Fatal dentro de la goroutine
		}()
	}
	close(salida)
	wg.Wait()

	creadas, duplicadas := 0, 0
	for i, c := range codigos {
		if errs[i] != nil {
			t.Fatalf("petición %d: %v", i, errs[i])
		}
		switch c {
		case http.StatusCreated:
			creadas++
		case http.StatusConflict:
			duplicadas++
		default:
			t.Errorf("petición %d: código %d, se esperaba 201 o 409", i, c)
		}
	}
	if creadas != 1 || duplicadas != n-1 {
		t.Errorf("creadas=%d duplicadas=%d; se esperaba 1 y %d", creadas, duplicadas, n-1)
	}
	if got := env.contar(t, "SELECT count(*) FROM categorias WHERE bar_id = $1 AND lower(nombre) = 'tapas'", env.barID); got != 1 {
		t.Errorf("filas en la base = %d, se esperaba 1", got)
	}
}
```

## Duplicado concurrente (TypeScript, Vitest + Hono)

```ts
it('diez creaciones iguales a la vez dejan una sola', async () => {
  const { app, headers, contarCategorias } = await entornoConBarPropio();
  const nombre = `Tapas ${crypto.randomUUID().slice(0, 8)}`;
  const respuestas = await Promise.all(
    Array.from({ length: 10 }, () =>
      app.request('/v1/categorias', { method: 'POST', headers, body: JSON.stringify({ nombre }) }),
    ),
  );
  const codigos = respuestas.map((r) => r.status);
  expect(codigos.filter((c) => c === 201)).toHaveLength(1);
  expect(codigos.filter((c) => c === 409)).toHaveLength(9);
  expect(await contarCategorias(nombre)).toBe(1);
});
```

## Test guardián: ninguna escritura sin su matriz

La **matriz** es una tabla con cada ruta de escritura y un cuerpo válido de ejemplo. Un test común la recorre y comprueba para todas: sin sesión → 401, recurso de otro cliente → 404 (y no cambió nada), cuerpo inválido → 400/422, y nunca 500. El **guardián** compara la matriz con las rutas reales del router: si alguien añade un `POST`/`PUT`/`PATCH`/`DELETE` y no lo mete en la matriz, el CI falla.

Cómo listar las rutas según el router:

- **Go `net/http` (ServeMux 1.22+)**: no permite listarlas; registra las rutas con un ayudante que guarde el patrón:

  ```go
  type rutas struct {
  	mux      *http.ServeMux
  	patrones []string
  }

  func (r *rutas) handle(patron string, h http.HandlerFunc) {
  	r.patrones = append(r.patrones, patron)
  	r.mux.HandleFunc(patron, h)
  }
  ```

- **chi**: `chi.Walk(router, func(metodo, ruta string, ...) error { ... })`. **echo**: `e.Routes()`. **gin**: `r.Routes()`.
- **Hono**: `app.routes` (el método `ALL` es middleware: ignóralo).

```go
var matriz = map[string]casoEscritura{
	"POST /v1/categorias":        {cuerpo: `{"nombre":"x"}`},
	"PATCH /v1/categorias/{id}":  {cuerpo: `{"nombre":"y"}`, crear: crearCategoria},
	"DELETE /v1/categorias/{id}": {crear: crearCategoria},
	// ...
}

func TestTodaEscrituraEstaEnLaMatriz(t *testing.T) {
	for _, p := range nuevoEntorno(t).rutas.patrones {
		metodo, _, _ := strings.Cut(p, " ")
		if metodo == "GET" || metodo == "HEAD" {
			continue
		}
		if _, ok := matriz[p]; !ok {
			t.Errorf("%s no tiene tests de escritura: añádela a la matriz", p)
		}
	}
}
```

Los casos propios de cada endpoint (duplicado, concurrencia, borrar en uso, idempotencia) siguen yendo en sus tests; la matriz solo cubre lo que es igual para todos.

## Borrar

- En uso: crear el hijo, borrar el padre → lo decidido (409 y el padre sigue, o cascada y el hijo desaparece).
- Dos veces → mismo código siempre (204 o 404).
- Después del borrado no aparece en el listado; con borrado lógico, se puede volver a crear con el mismo nombre.
- De otro cliente → 404 y sigue existiendo.

## E2E que no dependen de la semilla (Playwright)

```ts
test('crea una categoría', async ({ page }) => {
  const nombre = `Cervezas ${crypto.randomUUID().slice(0, 8)}`; // nunca «Cervezas» a secas: la semilla ya la tiene
  await page.getByRole('button', { name: 'Nueva categoría' }).click();
  await page.getByLabel('Nombre').fill(nombre);
  await page.getByRole('button', { name: 'Guardar' }).click();
  await expect(page.getByRole('listitem').filter({ hasText: nombre })).toHaveCount(1);
});
```
