# Rebanada de prueba en Godot

Prueba pequeña para decidir entre Python y Godot (ver `docs/motor.md`). **Es solo un
experimento**: el juego sigue siendo el prototipo en Python de la raíz del repositorio.

## Cómo se juega hoy (migración, etapa 1)

La escena principal ahora es `game.tscn`: el **menú del juego** (Jugar / Opciones / Salir), las opciones
(pantalla completa, FPS, modo debug; se guardan solas), la pausa (Esc), el game over y los diálogos, todo
igual que en el prototipo Python. "Jugar" abre una **partida provisoria**: `Esc` pausa, `E` abre un
diálogo, `K` muestra el game over y `R` reinicia. El piso, el jugador y los enemigos llegan en las
etapas 2 a 4 de `docs/migracion-godot.md`. Con el mouse se puede tocar el menú, las opciones y la pausa.

La rebanada original (estante con Gala y Aida) sigue en `main.tscn`: para verla, ábrela en el editor y
ejecútala con *Ejecutar escena actual* (F6), o desde la terminal con `godot --path godot main.tscn`.

## Qué hay en la rebanada

Un estante con la manzana y dos amigas (Gala y Aida). Con **flechas o WASD** te mueves;
cerca de una amiga aparece "Z: hablar" y con **Z / Enter / Espacio** se abre el diálogo
estilo Undertale (efecto de escritura, pausas `{pause=...}`, quién habla, completar con la
misma tecla). Un contador de banderas muestra con quién hablaste.

Los textos se leen de `../data/dialogues.json` (`acto1_gala`, `acto1_aida`), los mismos
del prototipo Python y sin modificarlos. Si no se encuentra el archivo, usa textos de
muestra y avisa en la consola.

## Cómo probarlo

1. Instala **Godot 4.3 o más nuevo** (versión estándar, no .NET).
2. Abre Godot → *Importar* → elige `godot/project.godot` → *Ejecutar* (F5).
3. Sigue el checklist de `docs/motor.md` (sección 4).

## Estado

La base (movimiento, diálogo, lectura de `dialogues.json` y exportación a Linux) fue probada
por el equipo y funciona. **Sin probar todavía:** la carga de sprites desde `sprites/` y la
carpeta `data/` junto al ejecutable (se agregaron después). Si algo falla, copia el mensaje
de la consola de Godot.

## Pruebas

Etapas 0 y 1 de la migración (`docs/migracion-godot.md`). Se corren desde la raíz del repositorio:

```
godot --headless --path godot --script res://tests/run_tests.gd
```

Termina con código 1 si algo falla. Si Godot no encuentra un `class_name` nuevo, corre antes una vez
`godot --headless --path godot --import`. Los tests viven en `tests/test_*.gd`; los valores que
comparan los calcula Python y están en `tests/golden/` (se regeneran con
`python tools/export_golden.py`; un test de Python avisa si quedaron viejos).

**Verificado en Godot 4.7:** la etapa 0 (9 pruebas, 187 comprobaciones, 0 fallos). La lógica de la etapa 1 (pila de estados, cursor, diálogo) también pasó: 53 pruebas, 914 comprobaciones. Las pantallas, el director y las preferencias se escribieron después y todavía no se probaron.

## Arte

Para cambiar los dibujos de formas por arte real, basta dejar PNG en `sprites/` (ver
`sprites/LEEME.md`: nombres, tamaño de 32 × 32 y cómo verlo). El juego los lee en tiempo
de ejecución, sin importar nada en Godot; también funciona con la versión exportada si hay
una carpeta `sprites/` junto al ejecutable. De la misma forma, una carpeta `data/` junto al
ejecutable se usa antes que `../data`.

## Archivos

| Archivo | Qué hace |
|---|---|
| `scripts/main.gd` | Sala, paredes, acciones de teclado, interacción y banderas |
| `scripts/player.gd` | Movimiento de la manzana |
| `scripts/npc.gd` | Una fruta hablante |
| `scripts/sprites.gd` | Carga de PNG por nombre desde `sprites/` (con respaldo a figuras) |
| `scripts/dialogue/dialogue_parser.gd` | Parseo de `{pause=...}`, errores de etiquetas y corte en renglones (`dialogue/text.py`) |
| `scripts/dialogue/dialogue_lines.gd` | Validación de `data/dialogues.json` (`dialogue/lines.py`) |
| `scripts/dialogue/dialogue_runner.gd` | Efecto de escritura, pausas y paso de línea (`dialogue/runner.py`) |
| `scripts/states/state.gd`, `state_stack.gd` | Pantallas y pila de estados (`states/base.py`) |
| `scripts/states/cursor.gd` | Cursor de menús y filas tocables (`states/cursor.py`) |
| `scripts/states/*_state.gd` | Menú, opciones, pausa, game over, diálogo y la partida provisoria |
| `scripts/core/` | `settings`, `controls`, `preferences`, `text_draw` y `game` (el director) |
| `scripts/ui/menu_view.gd`, `scripts/dialogue/dialogue_box.gd` | Dibujo de los menús y de la caja de diálogo |
| `scripts/dialogue_box.gd` | Caja de diálogo con máquina de escribir |
