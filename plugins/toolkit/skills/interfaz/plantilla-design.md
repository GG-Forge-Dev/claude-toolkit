# Plantilla de `docs/diseno/DESIGN.md`

Copia esto al producto y rellénalo a partir de `docs/diseno/referencia.*` (o de cómo se ve hoy el producto). Corto y concreto: es lo que la IA lee cada vez que toca una pantalla. Solo valores que se ven en la referencia o que el equipo decidió; lo que no se sepa, se deja como pregunta.

```markdown
# Diseño de <producto>

Referencia: `docs/diseno/referencia.png` (de <quién>, <fecha>).

## Personalidad
<2-3 adjetivos y para quién es. Ej.: «nocturno, rápido, legible con poca luz; para meseras con prisa».>

## Colores
| Token | Valor | Uso |
|---|---|---|
| fondo | #… | |
| superficie | #… | tarjetas, paneles |
| texto | #… | |
| texto-suave | #… | secundario (contraste ≥ 4.5:1 sobre fondo) |
| primario | #… | acción principal, una por pantalla |
| peligro / éxito / aviso | #… | |

## Tipografía
Fuente(s), tamaños (escala), pesos y alturas de línea. Tamaño mínimo de texto.

## Forma y espacio
Radio de bordes, escala de espaciado, sombras o bordes, densidad (compacta / aireada), tamaño mínimo táctil.

## Componentes
Cómo son los botones, inputs, tarjetas, listas, modales y avisos (y dónde están en el código).

## Tono de los textos
Tuteo o usted, largo de los mensajes, cómo se escriben los errores. Idiomas.

## Evitar
Lo que no encaja con este producto (p. ej. «degradados», «emojis en la interfaz», «texto en mayúsculas»).
```
