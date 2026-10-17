# Carpeta de sprites (para quien hace el arte)

Deja aquí tus PNG y el juego los usa. **No hay que abrir Godot ni importar nada.**
Si falta un archivo, el juego dibuja una figura de color en su lugar.

## Nombres

El nombre del archivo es el del personaje, en minúsculas y sin tildes:

| Archivo | Quién es |
|---|---|
| `manzana.png` | La protagonista |
| `gala.png` | Gala |
| `aida.png` | Aida |

Más adelante se agregan (`isolde.png`, etc.) y el juego los toma por el mismo nombre.

## Reglas de arte (decisiones por defecto, se pueden cambiar)

- **Formato:** PNG con fondo transparente.
- **Tamaño:** 32 × 32 píxeles por personaje (el juego usa casillas de 32 px). Otro tamaño
  se muestra tal cual, sin escalar.
- **Estilo:** pixel art. El juego no suaviza los píxeles (se ven nítidos al agrandar).
- **Punto de apoyo:** el centro de la imagen es la posición del personaje.
- **Pantalla:** el juego se dibuja a 480 × 288 y se amplía en números enteros, así que 1 píxel
  de tu arte = 1 píxel del juego.
- **Una sola imagen por personaje.** Todavía no hay animación ni direcciones (ver abajo).

## Cómo ver tu arte

- **Desde Godot:** guarda el PNG en `godot/sprites/` y ejecuta el juego (F5).
- **Desde el juego exportado:** crea una carpeta `sprites/` junto al ejecutable y deja ahí los PNG.
  Reinicia el juego para ver los cambios.

## Pendiente de decidir con el equipo

- ¿Animaciones? Propuesta: una tira horizontal `manzana_walk.png` con cuadros de 32 × 32.
- ¿Distintas direcciones (arriba, abajo, izquierda, derecha) o una sola vista?
- Fondos y objetos del estante (hoy es un color liso).
- Paleta o resolución final (si se cambia de 32 px, se ajusta el juego).
