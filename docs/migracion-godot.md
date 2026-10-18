# Guía de migración: del prototipo Python (pygame) a Godot

Para quien tenga que pasar el código del juego a Godot. Explica **cómo traducir cada archivo**,
en qué orden hacerlo y qué detalles no se pueden perder para que el juego se sienta igual.
Complementa a `docs/motor.md` (que explica *por qué* migrar) y a `docs/diseno.md` (el diseño).

> **Estado y límites de este documento**
> - Se escribió leyendo el código de `main` (no se ejecutó nada en Godot). Todo lo que dice de
>   Godot sale de conocimiento general de Godot 4.x; **el equipo usa Godot 4.7**, más nuevo
>   que lo que conozco. Si una API da error o aviso de obsoleta, manda la documentación de 4.7.
> - Las cifras (velocidades, tiempos, daños) están en `data/enemies.json` y en
>   `core/settings.py`; este documento las cita para guiar, pero **la fuente de verdad son esos
>   archivos**. Si cambian, el documento queda viejo.
> - El prototipo Python **no se borra** hasta que Godot lo iguale (etapa 5).

## 1. Principios

1. **Fidelidad primero, mejoras después.** La primera meta es que el juego en Godot se comporte
   igual que el de Python. Cambiar el balance o la sensación se hace *después*, en PRs aparte.
2. **No usar la física del motor para el combate.** Python resuelve las colisiones con
   rectángulos alineados a los ejes, moviendo un eje por vez. Para que se sienta igual y se pueda
   comprobar con números, se porta esa misma lógica con `Rect2` y no con `CharacterBody2D`,
   `Area2D` ni `move_and_slide()`. (La rebanada de `godot/` usa `CharacterBody2D` solo porque era
   una prueba; el jugador del juego real no.)
3. **Primero la lógica pura.** Los módulos que ya no dependen de pygame (`states/base.py`,
   `states/cursor.py`, `dialogue/text.py`, `dialogue/lines.py`, `dialogue/runner.py`,
   `rooms/layout.py`, `core/phases.py`) se portan primero y se comprueban contra los resultados de
   Python (sección 7).
4. **Los datos no se tocan.** `data/*.json` se comparten tal cual entre Python y Godot. Si hay que
   cambiar un formato, se cambia en los dos lados en la misma PR.
5. **Escenas armadas por código.** Igual que la rebanada actual: los nodos se crean desde scripts
   y no se escriben archivos `.tscn` a mano. Es más fácil de revisar en Git y de portar línea a
   línea. El editor se usa para el arte, los mapas del Acto 1 y la exportación.
6. **Una etapa, una PR**, con su checklist de prueba. No se mezcla migración con cambios de diseño.
7. **Los nombres se conservan** (clases, funciones, constantes, claves de JSON), pasando a
   `snake_case`/`PascalCase` de GDScript, para que quien conozca el Python encuentre todo igual.

## 2. Mapa de conceptos pygame → Godot

| En Python (pygame) | En Godot | Notas |
|---|---|---|
| `pygame.Surface` `canvas` de 480×288, escalado a la ventana | Ventana base 480×288 con `stretch/mode="canvas_items"` y `scale_mode="integer"` (ya está en `project.godot`) | Reemplaza `core/viewport.py`, `canvas`, `_present_canvas` y `queue_text`. |
| `pygame.Rect` (enteros) | `Rect2` (decimales) | Ver 4.2 y 4.3: hay que imitar los redondeos de pygame. |
| `pygame.Vector2` | `Vector2` | `rotate(grados)` → `rotated(deg_to_rad(grados))`. |
| `pygame.sprite.Sprite` / `Group` | Clases propias (`RefCounted`) y `Array` | Sin `Node` para cada bala; se dibujan desde un solo nodo. |
| `sprite.kill()` | Marcar `alive = false` y filtrar la lista al final del cuadro | Ver 4.5. |
| `pygame.draw.*`, `blit` | `_draw()` de un `Node2D`: `draw_rect`, `draw_circle`, `draw_line`, `draw_texture` | Una sola `Screen` dibuja todo. |
| `pygame.font` + `queue_text` | `draw_string(fuente, pos, texto, alineación, ancho, tamaño, color)` | No hace falta la cola: Godot dibuja el texto nítido a resolución de ventana. |
| `pygame.key.get_pressed()` | `Input.is_action_pressed(...)` | Acciones creadas por código (ver 6.1). |
| `KEYDOWN` | `_unhandled_input(event)` con `event.is_action_pressed(...)` | Ignorar eco (`event.is_echo()`). |
| `FINGERDOWN/UP`, `MOUSEBUTTONUP` | `InputEventScreenTouch/Drag` | Apagar `emulate_mouse_from_touch` para evitar el doble toque. |
| `clock.tick(FPS)` con `dt = min(dt, 0.05)` | `_process(delta)` con `delta = min(delta, 0.05)` | La tasa de cuadros se fija con `Engine.max_fps`. |
| `StateStack` y `State` | Se portan **1:1** como clases `RefCounted` | Mantiene las mismas reglas y sus tests. |
| `json.load` de `data/` | `JSON.parse_string(FileAccess.get_file_as_string(...))` | Ver cómo ubica los archivos `scripts/main.gd` de la rebanada. |
| `core/preferences.py` | `ConfigFile` en `user://settings.cfg` | Godot ya resuelve la carpeta por plataforma. |
| `random` | `RandomNumberGenerator` inyectable | Solo la usa la sandía; ver 6.7. |

## 3. Estructura propuesta del proyecto

La rebanada actual (`godot/scripts/`) se reorganiza así. Los nombres de carpeta replican los del
prototipo para encontrar cada cosa rápido:

```
godot/
  project.godot
  main.tscn                  una sola escena: Node2D con scripts/main.gd (arranca todo)
  scripts/
    core/        settings.gd  controls.gd  game.gd  preferences.gd  touch_controls.gd  phases.gd
    states/      state.gd  state_stack.gd  cursor.gd  menu_state.gd  options_state.gd
                 pause_state.gd  gameover_state.gd  dialogue_state.gd  play_state.gd
    ui/          menu_view.gd  hud_view.gd
    dialogue/    dialogue_parser.gd  dialogue_lines.gd  dialogue_runner.gd  dialogue_box.gd
    rooms/       layout.gd  room.gd  floor.gd
    entities/    player.gd  enemy.gd  projectile.gd  patterns.gd  trinkets.gd
                 strawberry.gd  pineapple.gd  banana.gd  lemon.gd  peach.gd  watermelon.gd
    sprites.gd   (ya existe: carga de PNG por nombre)
  sprites/       PNG de la artista
  tests/         run_tests.gd  y un archivo test_*.gd por cada test de Python
  tests/golden/  valores esperados exportados desde Python (sección 7)
```

La rebanada actual (`main.gd`, `player.gd`, `npc.gd`, `dialogue_box.gd`) se va reemplazando; la
parte de **NPCs, banderas e interacción por Z** pertenece al Acto 1 y se retoma en esa etapa, sobre
la nueva base. `dialogue_parser.gd` y `sprites.gd` se conservan (con los ajustes de 6.5).

## 4. Convenciones de traducción (léelas antes de portar nada)

### 4.1 Coordenadas y unidades
- Misma orientación que pygame: **x crece a la derecha, y crece hacia abajo**. Las posiciones son
  píxeles del lienzo de 480×288. Una casilla mide `TILE = 32`.
- Tiempos en segundos, velocidades en px/s, ángulos en **grados** en los datos. Godot trabaja
  en radianes: convierte siempre con `deg_to_rad()` (los datos siguen en grados).
- `0°` apunta a la derecha y los ángulos positivos giran hacia abajo (sentido horario en pantalla),
  igual que `Vector2(1, 0).rotate(a)` de pygame. `Vector2.RIGHT.rotated(deg_to_rad(a))` da lo mismo.

### 4.2 Rectángulos como los de pygame
`pygame.Rect` guarda enteros y se crea con `get_rect(center=pos)`, que fija `left = cx - w//2`
(división entera). Para tamaños impares (el durazno mide 23) el centro queda medio píxel corrido.
Para que las colisiones coincidan al píxel:
- Crea un ayudante `Geo.rect_from_center(center: Vector2, size: Vector2i) -> Rect2` que haga
  `Rect2(round_py(cx) - size.x / 2, round_py(cy) - size.y / 2, size.x, size.y)` con **división
  entera** (en GDScript, `int / int` ya es entera; silencia el aviso con
  `@warning_ignore("integer_division")`).
- `colliderect` es estricto: dos rectángulos que solo se tocan por el borde **no** chocan.
  `Rect2.intersects(otro)` es igual de estricto por defecto. No uses `include_borders=true`.
- `inflate(x, y)` de pygame agranda en `x` el ancho total (`x/2` por lado). Equivale a
  `Rect2.grow_individual(x/2, y/2, x/2, y/2)`; para valores impares revisa el redondeo.
- Para las posiciones que cada entidad guarda como `pos` (decimal) y `rect` (entero) se mantienen
  **las dos cosas** como en Python: `pos` avanza con decimales y `rect` se recalcula con
  `round_py(pos)` en cada eje. Después de chocar, `pos` toma el valor entero del rectángulo.

### 4.3 Redondeo, módulo y división: tres diferencias con Python
1. **`round()` de Python redondea la mitad al par** (`round(2.5) == 2`, `round(3.5) == 4`).
   `roundf()` de GDScript la redondea hacia afuera (`3`). Define `Geo.round_py(x)` que imite a
   Python. Una versión que cubre también los negativos:
   ```gdscript
   static func round_py(x: float) -> int:
   	var f := floorf(x)
   	if x - f == 0.5:  # justo en la mitad: va al entero par
   		return int(f) if posmod(int(f), 2) == 0 else int(f) + 1
   	return roundi(x)
   ```
   (`2.5→2`, `3.5→4`, `-2.5→-2`, `-3.5→-4`; añade esos cuatro casos como test.) Úsalo en **toda**
   conversión `pos → rect`.
2. **El módulo con negativos**: `-1 % 3` es `2` en Python y `-1` en GDScript. En `MenuCursor.move`
   y en `change_option` (`(indice + dirección) % cantidad`) usa **`posmod()`**.
3. **`/` entre enteros**: en GDScript es división entera (con aviso); en Python 3 es decimal. Revisa
   cada `/` según el original (`//` en Python = entero, `/` = decimal; usa `float()` si hace falta).

### 4.4 Tiempo y orden de actualización
- `dt` se limita a `0.05` s como en `Game.run`. Todo se multiplica por `dt`, igual que en Python.
- **El orden importa.** Conserva el orden de `PlayState.update` y de `Room.update` (6.2 y 6.6): hay
  daños y bandas de invulnerabilidad que dependen de quién se actualiza primero.
- Los estados se actualizan de arriba hacia abajo mientras `pauses_below` sea falso (6.2).

### 4.5 `kill()` y los grupos
En Python, `sprite.kill()` saca al sprite de **todos** sus grupos al instante (y se itera sobre
copias: `for shot in list(group)`). En GDScript:
- Cada entidad tiene `var alive := true`. `kill()` la pone en `false`.
- Las listas (`enemies`, `enemy_shots`, `acid_puddles`, `player_shots`) se recorren sobre una copia
  (`.duplicate()`) y al terminar cada paso se **depura** con `filter(func(e): return e.alive)`.
- `Room.cleared` es `enemies.is_empty()` **después de depurar**. Depura al final de `update` y
  antes de comprobar la sala limpia, para que el aviso "Sala despejada." salga en el mismo cuadro.

### 4.6 Dibujo
- Un solo `Node2D` (la "pantalla") hace `queue_redraw()` cada cuadro y en `_draw()` llama a
  `states.draw(self)`. Cada estado dibuja con ese nodo: `canvas.draw_rect(...)`, etc.
- `pygame.draw.rect(..., border_radius=r)` no existe en `draw_rect`. Para esquinas redondeadas
  usa `canvas.draw_style_box(StyleBoxFlat, rect)` con `corner_radius_*` (o resuélvelo sin
  redondeo, ver 6.6 sobre el fondo).
- La transparencia (`set_alpha`, `SRCALPHA`) se hace con el alfa del `Color` en `draw_*`.
- **Colores**: `core/settings.py` los guarda como tuplas 0–255; en Godot `Color8(r, g, b)`.

### 4.7 Nombres y mensajes
Los textos del juego (menús, carteles, diálogos) quedan **en español y con las mismas palabras**.
Las claves de diálogo (`sandia_intro`, etc.) no cambian. Los comentarios del código nuevo también
van en español, como en el resto del repositorio.

## 5. Etapas

Cada etapa es una PR. Python sigue jugable durante todo el proceso.

| # | Etapa | Qué incluye | Se da por buena cuando |
|---|---|---|---|
| 0 | **Cimientos de prueba** | `tools/export_golden.py` (Python) que genera `godot/tests/golden/*.json`; `godot/tests/run_tests.gd` y un runner por línea de comandos (sección 7); `Geo` con `round_py` y `rect_from_center` | `godot --headless --path godot --script res://tests/run_tests.gd` corre y pasa un test de prueba |
| 1 | **Base y pantallas** | `settings`, `controls`, `preferences`, `State`/`StateStack`, cursor, menú, opciones, pausa, game over, diálogo (runner + caja), controles táctiles, ajuste de ventana | Los tests de pila, cursor y diálogo pasan; en el editor se navega por menú → opciones → atrás, y se ve un diálogo con pausas |
| 2 | **Datos y piso** | `layout`, `room` (sin enemigos), `floor`, minimapa y HUD, puertas, llave, fundido entre salas | Los tests de `layout` pasan con los valores dorados; se recorren las 8 salas del piso 1 y las puertas se abren/cierran como en Python |
| 3 | **Jugador y enemigos** | `player`, `projectile`, `patterns`, fresa, piña, banana, limón (con charcos), durazno | Se juega el piso 1 completo con todos los enemigos menos el jefe; daño, invulnerabilidad y limpieza de sala coinciden |
| 4 | **Sandía y flujo completo** | `phases`, `watermelon`, refuerzos de la fase 3, diálogos del jefe, agujero final, game over | Los tests de fases pasan; se vence a la sandía y se llega al agujero; morir y reintentar funciona |
| 5 | **Paridad y archivo** | Recorrido completo con el checklist de la sección 8; el equipo lo aprueba | Entonces (no antes) se mueve el código Python a `legacy/` o se archiva con una etiqueta de Git |

Las etapas 2 a 4 dependen de la 1 y entre sí en ese orden. La CI de Godot (opcional) se puede
agregar al terminar la etapa 0; hoy no existe y no puedo probarla desde mi entorno.

> **Estado de la etapa 0:** `tools/export_golden.py`, `godot/tests/run_tests.gd`, `Geo` y los primeros
> tests (`test_geo.gd`, `test_dialogue_golden.gd`) ya existen. Por ahora el exportador cubre solo lo
> que no depende de pygame (fases, estructura del piso, diálogos); los valores de movimiento, patrones y
> jefe se agregan en las etapas 3 y 4. Ojo: en `golden/layout.json` los mensajes de error traen las
> coordenadas con el formato de Python (`(2, 0)`); el validador de Godot tiene que imitarlo.

> **Estado de la etapa 1 (mitad lógica):** ya están `states/state.gd`, `state_stack.gd`, `cursor.gd`,
> `dialogue/dialogue_runner.gd`, `dialogue_lines.gd` (validador) y las funciones `tag_errors` y `wrap_spans`
> en `dialogue_parser.gd`, con sus tests (`test_states`, `test_cursor`, `test_dialogue_logic`) y valores dorados
> nuevos (errores de etiquetas, corte en renglones y avance del runner paso a paso). Faltan `settings`,
> `controls`, `preferences`, `Game`, las pantallas (menú, opciones, pausa, game over, diálogo), la caja de
> diálogo nueva y los controles táctiles. Diferencias respecto de Python a tener en cuenta:
> `StateStack.switch` se llama **`switch_to`** (`switch` es palabra reservada de GDScript), `len(stack)` es
> `size()` y `states`/`top` son métodos; los errores de la pila (pop con la pila vacía) se anotan en
> `errors` en vez de lanzar excepciones.
>
> **Estado de la etapa 1 (mitad pantallas):** ya están `core/settings.gd`, `controls.gd`, `preferences.gd`
> (ConfigFile en `user://settings.cfg`), `text_draw.gd` (anclas de texto), `game.gd` (director), los estados
> menú / opciones / pausa / game over / diálogo, `ui/menu_view.gd`, `dialogue/dialogue_box.gd` y una partida
> provisoria (`play_placeholder_state.gd`), con `game.tscn` como escena principal. Decisiones tomadas:
> escalado entero (el que ya tenía `project.godot`); el ratón hace de dedo (`emulate_mouse_from_touch`),
> así que el antirrebote del diálogo no se portó; los tamaños de letra están en `Settings.FONT_SIZES`.
> **Pendiente de la etapa 1:** controles táctiles reales (joystick, botones) y sus opciones de móvil.

> **Estado de la etapa 2 (parte 1):** ya están `rooms/layout.gd` (estructura y validador, con los mismos
> mensajes que Python), `core/data_paths.gd` (dónde buscar `data/`) y `scripts/tools/validate_floor.gd`
> (`godot --headless --path godot --script res://scripts/tools/validate_floor.gd`), con `test_layout.gd` contra
> `golden/layout.json` (11 pisos mal armados y 5 errores de armado, además del piso 1). Diferencia con Python:
> `setup()` devuelve el mensaje de error en vez de lanzar `ValueError`, y `validate()` devuelve las líneas del
> mensaje (`[]` si está bien).

> **Estado de la etapa 2 (partes 2 y 3):** `rooms/room.gd` y `rooms/floor.gd` portan geometría, sólidos,
> puertas abiertas/cerradas/bloqueadas, aparición a dos baldosas, espera al entrar, llave, candados a ambos
> lados del jefe, descubrimiento del mapa y creación perezosa de salas. `ui/hud.gd` dibuja HP, minimapa,
> avisos, llave y barra del jefe. `room_test_state.gd` permite recorrer las ocho salas, recoger la llave y
> entrar al jefe; por ahora ignora las letras de enemigo hasta integrar la etapa 3. `room_floor.json` exporta
> trazas Python de puertas, geometría, llave y progreso; `test_room_floor.gd` las compara y prueba la espera
> de activación y el recorrido. El fondo usa baldosas, paredes y obstáculos simples, como se decidió en la
> sección 9; se deja el bodegón procedural para cuando haya arte.

## 6. Archivo por archivo

Cada entrada dice **qué hace**, **cómo se traduce** y **qué no se puede perder**. Las rutas son las del
repositorio Python; la columna "Destino" de la sección 3 da la ruta en Godot.

### 6.1 `core/`

**`core/settings.py` → `scripts/core/settings.gd`**
Constantes globales. Se pasa como `class_name Settings` con `const` para lo fijo y `static var` para
lo que cambia en ejecución (`FPS`, `DEBUG_KEYS`, que las opciones modifican). Valores actuales:

| Grupo | Constantes |
|---|---|
| Pantalla | `TILE=32`, `ROOM_COLS=15`, `ROOM_ROWS=9`, `SCREEN_W=480`, `SCREEN_H=288`, `SCALE=2` (solo ventana inicial), `FPS=60` |
| Salas | `ENEMY_WAKE_DELAY=0.5`, `FADE_TIME=0.15`, `BANNER_TIME=2.0`, `DEBUG_KEYS=true` |
| Jugador | `PLAYER_SPEED=124`, `PLAYER_HP=6`, `PLAYER_FIRE_RATE=0.35`, `PLAYER_SHOT_SPEED=220`, `PLAYER_SHOT_DAMAGE=1`, `PLAYER_INVULN_TIME=1.0` |
| HUD | `MAP_CELL_W=10`, `MAP_CELL_H=7`, `MAP_GAP=2`, `BOSS_BAR_W=200`, `BOSS_BAR_H=8`, `BOSS_BAR_Y=12` |
| Colores | todos los de `settings.py`, con `Color8` |

`SCALE` y `viewport` desaparecen (lo hace Godot). `S.FPS` mutable se aplica con `Engine.max_fps`.

**`core/controls.py` → `scripts/core/controls.gd`**
Define las teclas. En Godot se crean **acciones por código** en `Controls.setup()` (como `main.gd`
de la rebanada, para no depender del formato de `project.godot`):

| Acción | Teclas (igual que Python) | Uso |
|---|---|---|
| `move_up/down/left/right` | W/A/S/D | Mover (solo en partida) |
| `aim_up/down/left/right` | Flechas | Disparar (solo en partida) |
| `menu_up`, `menu_down` | Flechas arriba/abajo y W/S | Cursor de los menús |
| `menu_left`, `menu_right` | Flechas izq./der. y A/D | Cambiar opciones |
| `confirm` | Enter, Espacio | Elegir en un menú |
| `advance` | Espacio, Enter, Z | Pasar un diálogo |
| `pause` | Esc | Pausa / volver atrás |
| `interact` | E | Recoger llave, usar llave, agujero |
| `debug_restart`, `debug_clear` | R, K | Solo con `DEBUG_KEYS` |

Trampa: en Python **las flechas** disparan en partida *y* mueven el cursor en menús, y **W/A/S/D**
mueven al jugador *y* el cursor. No es un problema porque lo decide el estado que está arriba de la
pila, no la tecla. Mantén ese reparto: el estado recibe el evento y pregunta por la acción que le
interesa. `move_cursor_with_key` se vuelve `Controls.move_cursor(cursor, event) -> bool`.

**`core/game.py` → `scripts/core/game.gd`** (el director)
Guarda el estado de la partida (`floor`, `player`, `player_shots`, `banner`, `hole_dialogue_shown`),
las preferencias, la pila de estados y los atajos que usan las pantallas. Se traduce como un `Node`
raíz (`class_name Game`). Qué conservar:
- `reset()`: crea `Floor.load("floor1")`, un `Player` en el centro `(240, 144)`, vacía los disparos,
  `banner = null`, `hole_dialogue_shown = false`.
- `start_run()`, `open_pause()`, `open_game_over()`, `open_options()`, `return_to_menu()`,
  `say(key, dark, on_close)`, `quit()`, `idle_selection()` (en móvil, ninguna opción resaltada;
  con teclado, la primera). Mismos nombres.
- `is_mobile`: `OS.has_feature("mobile")` (o `"android"`/`"ios"`).
- Cuadro: `tick(dt)` → `states.update(dt)`; el dibujo ocurre en `queue_redraw()`.
- `option_entries()` y `option_row_y(i)`: mismos textos y mismas filas (escritorio: sin las opciones
  táctiles; móvil: sin "Pantalla completa"). Los textos se conservan tal cual (con "izq./der. o Enter").
- `fps_options = (30, 60, 120, 144, 165, 180)`; `change_fps`, `toggle_debug`, `toggle_fullscreen`
  (`DisplayServer.window_set_mode`), `change_option(nombre, dirección)` con **`posmod`** (ver 4.3).
- Preferencias guardadas: `fullscreen`, `fps`, `debug_keys`, `move_mode`, `aim_mode`,
  `dynamic_base_enabled`, `base_travel_index`, `joystick_size_index`. Validan tipo y rango al leer,
  y se guardan al cambiarlas y al salir.
- **No se traduce:** la carga de ícono (`set_icon` → ajuste del proyecto), `pygame.init`, fuentes y
  `queue_text` / `draw_queued_text` / `_scaled_fonts`, `_present_canvas`, `_touch_event_position`
  (Godot ya da coordenadas del lienzo; ver `touch_controls`).

**`core/preferences.py` → `scripts/core/preferences.gd`**
`ConfigFile` en `user://settings.cfg` (sección `[preferencias]`). Conserva el comportamiento:
leer nunca falla (si no existe o está roto, devuelve un diccionario vacío), guardar devuelve
`true/false` y no deja archivo a medio escribir (no asumas que `ConfigFile.save` es atómico:
guarda en un `.tmp` y renombra con `DirAccess.rename_absolute`). No se migran las preferencias
viejas de Python (formato JSON en otra carpeta): el equipo las reconfigura.

**`core/viewport.py` → se elimina.**
`viewport_rect` y `window_to_canvas` existen solo porque pygame no escala solo. Con
`canvas_items` + `integer`, Godot da las coordenadas del lienzo directamente
(`get_viewport().get_mouse_position()` y `InputEventScreenTouch.position` ya vienen en 480×288).
Diferencia: pygame escalaba de forma proporcional (cualquier factor) y Godot con `integer` usa
múltiplos enteros (2×, 3×…), dejando franjas negras más grandes; para llenar la pantalla del
teléfono se usaría `keep`. Queda como pendiente de diseño (sección 10).

**`core/touch_controls.py` → `scripts/core/touch_controls.gd`** (294 líneas; la parte más ancha)
Controles para Android: flechas o joystick virtual para mover y disparar, botón de interactuar
(`E`, centro `(340, 260)`, radio 19) y de pausa (centro `(240, 44)`, radio 19), con zona muerta de 9 px,
base dinámica y tamaños configurables. Se traduce como un `Node` que procesa `InputEventScreenTouch`
y `InputEventScreenDrag` (con el índice del dedo en lugar de `finger`). Conservar:
- Los dedos se asignan a un **rol** (`move` a la izquierda de la pantalla, `aim` a la derecha) al
  apoyarse, y lo mantienen hasta soltarse.
- `move` y `aim` son `Vector2` ya normalizados que lee el jugador (`touch_move`, `touch_aim`).
- Soltar un dedo produce una acción: `"pause"`, `"interact"` o `"tap"` (con posición); el antirrebote
  de **350 ms / 24 px** evita acciones repetidas.
- Constantes: `JOYSTICK_RADIUS=42`, `DEADZONE=9`, `BASE_TRAVEL_OPTIONS=(8,14,20)`,
  `JOYSTICK_SIZE_OPTIONS=(0.8,1.0,1.2)`, etiquetas "Corto/Medio/Largo" y "Pequeño/Mediano/Grande".
- El dibujo de los controles se hace **sobre el lienzo** (no fuera del juego como hace hoy sobre la
  ventana): decide con el equipo si los controles van sobre las franjas negras (necesita
  `scale_mode="keep"` y una capa `CanvasLayer`) o encima del juego. Es una decisión de diseño táctil
  y no una traducción; se anota como pendiente.
- Apagar `input_devices/pointing/emulate_mouse_from_touch` para que un toque no llegue dos veces
  (el `DialogueState` de Python ya tiene un antirrebote para ese problema: se puede quitar si se apaga
  la emulación).
**Esta es la única pieza sin prueba automática posible: se valida a mano en el teléfono.**

**`core/phases.py` → `scripts/core/phases.gd`**
`PHASE_DIALOGUE = {1: "sandia_intro", 2: "sandia_fase2", 3: "sandia_fase3"}`, `DEATH_DIALOGUE =
"sandia_death"` y `phase_for_hp(hp, max_hp, thresholds)`: empieza en fase 1 y suma 1 por cada umbral
con `hp / max_hp <= umbral`. Es lógica pura, se traduce directo con división **decimal**
(`float(hp) / max_hp`). Con `[0.66, 0.33]` y 110 de vida: fase 1 hasta 72,6 de vida; fase 2 hasta 36,3;
fase 3 después (compara con el golden de `export_golden.py`).

### 6.2 `states/`

**`states/base.py` → `state.gd` y `state_stack.gd`** (lógica pura, la más testeada)
Se portan **línea por línea**, incluidos los comentarios. Reglas a conservar:
- Banderas de `State`: `transparent`, `pauses_below` (por defecto `true`), `touch_overlay`.
- Ganchos: `enter`, `exit`, `resume`, `handle_key`, `handle_pointer`, `handle_touch`, `handle_release`
  (devuelve `bool`), `update(dt)`, `draw(canvas)`. En Godot `ctx` es el `Game`.
- `StateStack` con `push/pop/replace/switch/clear` **diferidos**: lo pedido mientras se procesa un
  evento, una actualización o un dibujo se aplica recién al terminar (contador `_busy`, cola
  `_pending`, `_flush`). Es lo que permite que un estado se saque a sí mismo sin romper la iteración.
- `update` recorre de arriba hacia abajo y se detiene en el primer estado con `pauses_below`;
  `draw` busca el primer estado opaco (de arriba hacia abajo) y dibuja desde ahí hasta el tope.
- `lambda` de Python → `Callable`. Cuidado con las capturas: en GDScript las lambdas capturan por
  valor (los `int`, `bool`, `String` se copian); si necesitas mutar algo capturado, usa un `Array`
  de un elemento como hace el original (`result = []`).
Los tests de `tests/test_states.py` son la especificación; se portan todos (sección 7).

**`states/cursor.py` → `cursor.gd`**
`MenuCursor(size, index=0)` con `index` posiblemente `null`; `move(delta)` parte de 0 si es `null`
y usa **`posmod`**. `row_at(position, first_y, spacing, count, tolerance, center_x, half_width)`:
`index = round((y - first_y) / spacing)` con **`round_py`**, y exige `0 <= index < count`,
`|x - center_x| <= half_width` y `|y - (first_y + index*spacing)| <= tolerance`. En Python
`round(x.5)` va al par: es justo lo que cubre el test que falló una vez (y=126+18).

**`states/menu.py` → `menu_state.gd` y `options_state.gd`**
- `MENU_OPTIONS = ("Jugar", "Opciones", "Salir")`, `MENU_FIRST_Y=126`, `MENU_SPACING=34`,
  `MENU_TOLERANCE=16`; ancho de acierto `SCREEN_W * 0.44` centrado en `SCREEN_W/2`.
- `MenuState`: Esc sale del juego; cursor con teclas; Enter/Espacio elige; `resume` deja el cursor en
  `idle_selection()` (para móvil). `choose`: `0` → `start_run`, `1` → `open_options`, `2` → `quit`.
- `OptionsState`: se abre **encima** del menú; Esc hace `pop`. Izquierda/derecha cambian solo las
  entradas `ADJUSTABLE = ("fps","move","aim","dynamic","travel","size")`; Enter elige
  (`fullscreen`, `debug`, o cambia +1 en las ajustables; `back` hace `pop`). Las filas de toque
  dependen de `is_mobile` (separación 20 y tolerancia 10 en móvil; 30 y 15 en escritorio).

**`states/pause.py` → `pause_state.gd`**
`PAUSE_OPTIONS = ("Continuar", "Reiniciar", "Salir")`; `transparent = true`, `pauses_below = true`,
`touch_overlay = false`. Esc = `pop`. `choose`: `0` pop, `1` `start_run`, `2` `return_to_menu`.
Toque: con `top = SCREEN_H/2 - 12`, vale si `top-18 <= y <= top+80`, índice
`clamp(round_py((y - top) / 32), 0, 2)`; la acción `"pause"` también hace `pop`. El cursor **vuelve
a 0 cada vez** que se abre (comportamiento conocido, se conserva).

**`states/gameover.py` → `gameover_state.gd`**
`GAME_OVER_OPTIONS = ("Reintentar", "Salir al menú")`, `FIRST_Y = SCREEN_H/2 + 26`, `SPACING = 32`.
Transparente, `touch_overlay = false`. **Esc no hace nada.** Toque: `row_at(..., 16, SCREEN_W/2, SCREEN_W*0.44)`.
`0` → `start_run`, `1` → `return_to_menu`.

**`states/dialogue.py` → `dialogue_state.gd`**
Se abre con `game.say(key, dark, on_close)`: `transparent`, `pauses_below`, `touch_overlay = true`.
- `enter`: inicia la caja; si el diálogo no tiene líneas, se cierra enseguida.
- `handle_key`: Esc abre la pausa; Espacio/Enter/Z avanza.
- Un toque en **cualquier lugar** avanza (`handle_release` devuelve `true`). El antirrebote
  (250 ms / 48 px entre eventos *de distinto tipo*) es solo para el doble evento dedo+ratón; si en
  Godot se apaga `emulate_mouse_from_touch`, se puede omitir y quitar su test.
- `dark=true` oscurece el fondo (negro con alfa 190).
- `_close`: `pop` y luego `on_close()` (que puede, por ejemplo, volver al menú).
- `snapshot()` (speaker, index, shown, text) se conserva: lo usan los tests.

**`states/play.py` → `play_state.gd`** (el corazón de la partida)
`touch_overlay = true`, `DEATH_DELAY = 1.2`. Estado propio: `death_time`, `transition`.
Teclas: Esc = pausa; **R** (si `DEBUG_KEYS`) reinicia; **K** (si `DEBUG_KEYS`) mata a todos los
enemigos de la sala; **E** = `interact`. Acciones táctiles: `"pause"` y `"interact"`.

`interact` (en este orden): 1) recoger la llave (cartel "¡Recogiste la llave!"); 2) si es la sala
del jefe, está limpia, no se mostró el diálogo y el jugador toca el agujero agrandado en 28 px →
`say("hole_continue", dark=true, on_close=return_to_menu)` y marca `hole_dialogue_shown`; 3) usar la
llave en la puerta del jefe (si el jugador toca esa puerta agrandada 32 px; cartel "¡La llave abrió la puerta!").

`update(dt)` **en este orden** (no lo reordenes):
1. Si el jugador está muerto: suma `death_time`; al llegar a 1,2 s abre `game over` **una sola vez**
   (`death_time = -inf`) y sale.
2. Si no hay transición y la sala tiene `pending_dialogues`: abre el primero (`game.say`) y sale.
3. Descuenta el cartel (`banner[1] -= dt`).
4. Si hay transición: `update_transition` y sale.
5. Actualiza al jugador (con `room.solids`, `touch.move`, `touch.aim`), los disparos del jugador y la sala.
6. Disparos del jugador: si chocan con un sólido, mueren; si no, golpean al **primer** enemigo que
   tocan (`take_damage(shot.damage)`) y mueren.
7. `floor.drop_key_if_ready()` (cartel "Hay una llave en el centro de la sala").
8. Aviso al limpiar: si `room.cleared and not room.announced and not room.pending_dialogues` →
   `announced = true` y, si la sala tuvo enemigos, cartel "¡Piso completado!" (jefe) o "Sala despejada.".
9. `exit_direction`: si el jugador toca una puerta abierta, empieza la transición `{dir, t=0, swapped=false}`.

`update_transition`: suma `dt`; al pasar `FADE_TIME` (una sola vez) hace `floor.move(dir)`, vacía los
disparos, **teletransporta** al jugador a `room.entry_point(OPPOSITE[dir])` y borra el cartel; termina
a los `2*FADE_TIME`. Dibujo: sala, disparos, jugador (solo si vive), HUD, controles táctiles y
el fundido negro con alfa `255 * clamp(progreso)` (sube en la primera mitad, baja en la segunda).

### 6.3 `ui/`

**`ui/menu.py` → `menu_view.gd`** — solo dibuja. Conserva textos, posiciones y colores:
título "ForestApple" (centro, y=46); menú principal (filas desde y=126, paso 34, resaltado en `SEED`);
"OPCIONES" (y=92, con subrayado); "PAUSA" (centro − 60) con velo negro alfa 170; game over ("Fallaste..."
en el centro − 6, opciones desde `FIRST_Y`); pie: "Versión 0.0" a la izquierda y los créditos
"Santino Zerda, Gael Ledesma y Ara Prociuk" a la derecha. La cola `queue_text` desaparece: se llama
a `draw_string` directamente. El tamaño de fuente `Font(None, N)` de pygame **no equivale** al de
Godot; ajusta a ojo hasta que el menú se lea igual (o fija una fuente pixel cuando exista).

**`ui/hud.py` → `hud_view.gd`** — HUD de combate:
- `HP: x/y` en `(36, 8)`; con `DEBUG_KEYS`, velocidad y FPS debajo (`y=26` y `y=44`).
- Trinkets (íconos de 12 px, separación 4) bajo el minimapa, alineados a la derecha.
- Minimapa: celdas de 10×7 con separación 2, anclado arriba a la derecha (`origin_x = SCREEN_W - cols*12 - 4`,
  `origin_y = 3`). Actual = blanco; visitada = verde si está limpia, gris si no; conocida sin visitar =
  contorno; sala del jefe = contorno rojo (salvo si es la actual). Usa `floor.known_cells()`.
- Barra del jefe: solo si hay un enemigo con `is_boss` y `phase != 0`; 200×8 en `y=12`.
- Avisos inferiores (centrados en `y = SCREEN_H - 18`): "E: usar llave" / "Necesito una llave para entrar"
  (cerca de la puerta del jefe, agrandada 32 px), "E: agarrar llave" (cerca de la llave, 28 px) y
  "E: bajar" (cerca del agujero, 28 px, antes del diálogo final).
- Cartel central (`banner`) sobre un recuadro de fondo, en `y = TILE * 2`; no se dibuja si el jugador murió.

### 6.4 `dialogue/`

**`dialogue/text.py` → `dialogue_parser.gd`** (ya existe una versión en la rebanada)
`parse_text` devuelve `(texto visible, pausas)`, donde cada pausa es `(letras_antes, segundos)`; **se
descartan** las pausas al principio y al final. `tag_errors`: solo vale `{pause=N}` con `0 < N <= 5`;
cualquier otra llave es un error. `wrap_spans(texto, medir, ancho_máximo)` corta en renglones y respeta
`\n`; devuelve `(inicio, fin)` sobre el **mismo texto**, para revelar letra por letra sin que las
palabras salten de renglón. Falta añadirlo a la versión de la rebanada.

**`dialogue/lines.py` → `dialogue_lines.gd`**
`load_dialogue(clave)` desde `data/dialogues.json`. Una línea es un texto o un objeto
`{text, speaker, speed}`; `speaker` pisa al del diálogo solo en esa caja; `speed` en letras por
segundo (1–400). Estructuras `Line(text, speaker, speed)` y `Dialogue(speaker, lines, line_speakers,
line_speeds, speed)`. Incluye la **validación** (`python -m dialogue.lines`): se porta a un script de
Godot que corre en la línea de comandos y falla si hay un error.

**`dialogue/runner.py` → `dialogue_runner.gd`** (lógica pura; **velocidad por defecto: 45 letras/s**)
Ojo: la rebanada de Godot usa 30; al migrar se cambia a **45**. Algoritmo de `update(dt)`: mientras
queden `dt` y la línea no esté completa, consume pausa si hay; si no, avanza `shown += speed * resto`;
si ese avance alcanza la próxima pausa, se detiene **exactamente** en su posición, resta el tiempo
usado y empieza la espera. `advance()`: primera pulsación completa la línea (y borra pausas pendientes);
la segunda pasa a la siguiente; al terminar, `active = false`. `shown_count = min(int(shown), len)`.

**`dialogue/box.py` → `dialogue_box.gd`**
Caja de 84 px de alto con margen 8, relleno interno 10, hasta **3 renglones** de 18 px: rectángulo
en `(8, 196)` de 464×84 con fondo `BG` y borde blanco de 2 px; nombre arriba a la izquierda (`SEED`);
"[Espacio]" arriba a la derecha cuando la línea está completa; texto desde `y + 26`. Los renglones se
calculan con el texto completo (`wrap_spans`) y se revelan letra a letra. **Hay un test que exige que
todos los textos del juego entren en 3 renglones**; se porta, midiendo con la fuente real de Godot
(`font.get_string_size`), lo que puede cambiar qué textos caben: revisa los diálogos largos.

### 6.5 `rooms/`

**`rooms/layout.py` → `scripts/rooms/layout.gd`** (lógica pura)
`FloorLayout(floor_data, rooms_data)`: `cells` (diccionario `(col, fila) → id de sala`), `start`,
`neighbor`, `doors` (conjunto de direcciones con vecina), `room_data`, `validate(enemy_letters)`.
- Constantes: `COLS=15`, `ROWS=9`, `DIRECTIONS` (up/down/left/right → `(0,-1),(0,1),(-1,0),(1,0)`),
  `OPPOSITE`, `DOOR_TILE` (`up=(7,0)`, `down=(7,8)`, `left=(0,4)`, `right=(14,4)`), `APPROACH_TILE`
  (`up=(7,1)`, `down=(7,7)`, `left=(1,4)`, `right=(13,4)`), `BASE_TILES = "#.X"`,
  `ROOM_TYPES = {start, normal, boss}`, `MIN_ENEMY_DOOR_DISTANCE = 2.5`.
- **Letras de enemigos** (único lugar donde se definen): `S` fresa, `P` piña, `B` banana, `L` limón,
  `D` durazno, `W` sandía. Se conserva el diccionario `ENEMY_LETTERS`.
- La validación junta **todos** los problemas antes de fallar (filas, anchos, caracteres, bordes `#`,
  baldosas de entrada libres, separación entre enemigos y el punto de entrada, conectividad por BFS).
  Los mensajes en español se conservan; los usan los tests.
- Cuidado: las claves de las celdas son tuplas en Python; en GDScript usa `Vector2i` como clave de
  `Dictionary`. Las coordenadas del JSON vienen como `float`; conviértelas con `int()`.
- `__main__` (`python -m rooms.layout`) se vuelve un script de línea de comandos de Godot.

**`rooms/room.py` → `scripts/rooms/room.gd`** (318 líneas, la más grande)
Una sala: `id`, `kind`, `layout`, `doors`, `locked_doors`, listas de `walls`, `obstacles`,
`door_rects{dirección → Rect2}`, `enemies`, `enemy_shots`, `acid_puddles`, `pending_dialogues`,
`key_drop`, `key_rect`, `hole_rect`, `wake_timer`, `announced`, `had_enemies`.
- **Construcción** (`_build`): recorre el layout; un `#` en una baldosa de puerta **con vecina**
  guarda un rectángulo de puerta (y no es pared); un `#` normal es pared; `X` es obstáculo; una letra de
  enemigo crea el enemigo en el centro de la casilla. El limón recibe también el grupo de charcos.
  `enemy.attach(room)` le da acceso a la sala. `hole_rect = Rect2(SCREEN_W/2 - 28, SCREEN_H/2 - 14, 56, 28)`.
- `solids` (con caché por estado): paredes + obstáculos + puertas que estén cerradas (sala **no**
  limpia) o bloqueadas por llave (`locked_doors`). Se invalida cuando cambia ese par de valores.
- `entry_point(dir)` = `((col+0.5)*32 - dx*64, (row+0.5)*32 - dy*64)` con `(dx, dy)` hacia afuera:
  aparece **2 casillas** adentro de la puerta. El validador usa la misma fórmula; no las separes.
- `exit_direction(rect)`: solo si la sala está limpia; devuelve la puerta no bloqueada que toca `rect`.
- `enter()`: vacía disparos y charcos y, si hay enemigos, `wake_timer = 0.5`.
- `drop_key()`: la llave (16×16) va en la baldosa `.` más cercana al centro `(7, 4)` (distancia
  euclídea al cuadrado), una sola vez. `collect_key(player)`: se recoge si el rectángulo de la llave
  toca el del jugador agrandado 28 px; agrega el trinket `key`.
- `spawn_enemy(kind, pos)`: crea un enemigo en pleno combate (lo usa la sandía en la fase 3).
- `say(key)`: agrega a `pending_dialogues`.
- **`update(dt, player)`** (orden fijo): `current_player = player`; si `wake_timer > 0`, lo descuenta
  y **sale** (los enemigos y sus disparos quedan congelados mientras tanto); luego actualiza enemigos,
  disparos y charcos; después los disparos enemigos mueren al tocar un sólido o dañan al jugador al
  tocarlo; los charcos dañan **cada cuadro** que se toquen (la invulnerabilidad del jugador lo
  limita); por último, el daño por contacto de cada enemigo.
- **Dibujo**: fondo, llave, agujero (si es sala de jefe limpia: tres elipses), puertas, enemigos,
  disparos, charcos. Puertas: bloqueadas por llave en gris plata con borde; cerradas por enemigos en
  `DOOR_CLOSED` con borde `WALL`; abiertas en `DOOR_OPEN`.
- **El fondo procedural** (`_build_backdrop`, ~100 líneas de `pygame.draw`: heladera, bandejas, productos
  con una semilla por sala) no se traduce línea por línea. `room.gd` dibuja baldosas con las tres
  tonalidades deterministas, paredes y obstáculos como rectángulos; los productos detallados quedan
  para cuando haya arte real de la artista (sección 9).

**`rooms/floor.py` → `scripts/rooms/floor.gd`**
Piso completo: grilla de salas **creadas la primera vez que se entra** (y guardadas, para que sigan
limpias), `pos`, `visited`, `boss_unlocked`, `key_dropped`. `Floor.load(nombre)` carga, valida con las
letras de `Room.LETTERS` y construye. Métodos: `room_at`, `current_room`, `move(dir)` (visita y
`enter()` y refresca cierres), `boss_door_directions(cell)` (direcciones cuyas vecinas son `boss`),
`refresh_boss_locks()` (**las dos caras** de la puerta del jefe se cierran hasta usar la llave),
`all_non_boss_rooms_cleared()` (exige que **todas** las salas que no son del jefe hayan sido creadas
y estén limpias), `drop_key_if_ready()` (deja la llave **en la sala actual**, una sola vez),
`collect_key`, `use_key_at_boss_door` (consume la llave y desbloquea), `known_cells()` (visitadas +
vecinas). Esto último lo usa el minimapa.

### 6.6 `entities/`

**Reglas comunes de movimiento (jugador y enemigos)**
Mueven **un eje por vez**: suman al eje, recalculan el `rect` con `round_py`, y si choca con un
sólido lo alinean al borde (`right = wall.left` si iba hacia `+`, `left = wall.right` si iba hacia `-`),
reasignan `pos` al entero del rectángulo y (jugador/rebote) cambian la velocidad de ese eje.
**No** hay `break` tras un choque en el jugador, en `Enemy._move` ni en el durazno (pueden resolver
varias paredes en el mismo cuadro); **sí** lo hay en `Watermelon._move_and_bounce`. Respeta cada uno.

**`entities/player.py` → `entities/player.gd`**
Cuadrado de 20 px, vida 6, velocidad 124. Movimiento con **aceleración y fricción** (`speed * 8`):
`move` = (D−A, S−W) + toque; si su longitud² > 1 se normaliza; con entrada acelera
`velocity += dir * accel * dt`; sin entrada, la fricción baja la rapidez a 0 **sin invertir** la dirección;
la rapidez se limita a `speed`. Disparo con flechas (+ toque): **un solo eje**, gana el de mayor valor
absoluto (`abs(x) >= abs(y)` elige horizontal); proyectil de 6 px que sale del centro del jugador,
velocidad 220, daño 1, enfriamiento 0,35 s; `_cooldown` baja siempre. Invulnerabilidad tras recibir
daño: **1,0 s**, con parpadeo (alfa 120 cuando `int(invuln*12) % 2` es impar; 255 si no).
`take_damage` no hace nada si hay invulnerabilidad o ya murió; `alive = hp > 0`; `teleport(centro)`
fija posición, borra la velocidad y recalcula el rectángulo. Trinkets: `has_trinket`, `add_trinket`
(sin duplicados), `consume_trinket` (solo consumibles). `character` (`"manzana"` / niño, aún sin usar):
si hay sprite `manzana.png`, se dibuja con `Sprites.get_texture` como ya hace la rebanada.

**`entities/projectile.py` → `entities/projectile.gd`**
Círculo de `size` px (6 por defecto), `velocity = direction.normalized() * speed` (cero si la dirección
es nula), `lifetime = 2.0` (los enemigos usan 4.0 o 3.0 según el caso), daño. No choca por sí mismo:
lo hace quien lo contiene (`Room` / `PlayState`).

**`entities/patterns.py` → `entities/patterns.gd`**
- `fan(origin, target, count, spread_deg, speed, damage, color, size=6, lifetime=4.0)`: dirección base
  hacia `target` (si coincide con el origen, `(1, 0)`); con `count == 1` el ángulo es `0`; si no,
  `-spread/2 + i * spread/(count-1)`.
- `shot_at_angle(origin, angle_deg, ...)`: dirección `Vector2(1,0).rotate(ángulo)`.

**`entities/trinkets.py` → `entities/trinkets.gd`**
`Trinket(id, name, icon, consumable)`. Único hoy: `key` ("Llave", consumible, ícono 12×12: cuadrado
gris oscuro `(75,79,88)`, interior plateado `(218,222,230)` y `(160,166,177)`, un píxel brillante). Un id desconocido
lanza `KeyError` → en Godot, `push_error` y devolver `null`.

**`entities/enemy.py` → `entities/enemy.gd`**
Base. Carga `ENEMY_DATA` de `data/enemies.json` **una vez**. Atributos: `max_hp`, `hp`, `speed`,
`contact_damage`, `stats` (el diccionario completo), `enemy_shots`, `size`, `color`, `room`.
`take_damage(n)`: resta y activa un destello blanco de **0,08 s**; si `hp <= 0` hace `kill()`.
`update(dt, player, walls)`: llama al comportamiento y luego atenúa el destello (mientras dura,
el cuerpo se dibuja blanco). Cada enemigo se registra en `ENEMY_TYPES` (nombre → clase); en Godot, un
diccionario `nombre → Script` en `entities/enemy_types.gd`.

**`strawberry.py` (fresa)**: no se mueve; dispara una semilla (5 px, vida 4 s, color `SEED`) hacia
el jugador cada `fire_rate` (1,2 s); el primer disparo tarda un `fire_rate` completo.
**`pineapple.py` (piña)**: persigue al jugador a `speed` (38) con `_move`; 15 de vida.
**`banana.py`**: persigue a `speed` (52); si el jugador está a `guard_range` (120) o menos y no hay
carga ni enfriamiento, **carga** en línea recta a `charge_speed` (165) durante `charge_time` (0,3 s) y
entra en enfriamiento de `charge_cooldown` (1,4 s). Guarda la dirección al empezar la carga.
**`peach.py` (durazno)**: apunta **una sola vez** hacia el jugador y rueda a `speed` (205) rebotando
en cada pared (`velocity *= -1` en el eje chocado), sin `break` (ver arriba). Tamaño 23.
**`lemon.py` (limón)**: persigue a `speed` (22) y cada `fire_rate` (1,8 s) lanza una **`AcidDrop`**
(8 px, vida 3 s, velocidad `shot_speed` 220) que va dejando un **`AcidPuddle`** (14 px, vida 2,6 s,
daño 1, se desvanece en el último segundo con alfa `min(255, 255 * vida)`) cada **0,12 s**. La gota vive en
`enemy_shots` (muere en sólidos y daña al jugador); los charcos viven en `acid_puddles`.
La sandía reutiliza `AcidPuddle` con otro color y vida (jugo).

**`watermelon.py` (sandía, jefe del piso 1; 110 de vida)** — es la pieza más delicada. Máquina de
estados `walk → telegraph → (roll → stunned | spiral | disparo de abanico) → walk`, con `phase` 0
(todavía no empezó; no recibe daño), 1, 2 y 3.
- `update_behavior`: baja `grace`; si `phase == 0` inicia la fase 1; calcula la fase objetivo con
  `phase_for_hp`; si es mayor que la actual, `_begin_phase(objetivo)`; si no, ejecuta el estado.
- `_begin_phase(n)`: fija fase y color, vuelve a `walk` con `walk_time` (1,4 s), frena, `grace =
  grace_after_phase` (1,0 s, invulnerable), `_spiral_next = false`, **limpia disparos y charcos**, y en la
  fase 3 hace aparecer refuerzos (`["banana","banana","lemon"]`); luego pide el diálogo de la fase
  (`room.say`).
- `take_damage`: ignora si `phase == 0` o `grace > 0`; ×`0,7` en fase 3; ×`2` si está aturdida; si ese golpe
  la mata, limpia peligros y pide `sandia_death`, **antes** de restar la vida.
- `walk`: se acerca a `speed` (30; 55 en fase 3) hasta `keep_distance` (90); en fase 3 deja un charco de
  jugo (color `(214,52,84)`, vida 6 s) cada 0,6 s; cuando `timer` llega a 0, elige ataque y pasa a `telegraph`
  con `<ataque>_telegraph` (0,5 / 0,6 / 0,5 s). Ataque por fase: 1 = abanico; 2 = rodar; 3 = alterna
  espiral y abanico (empieza por espiral).
- `telegraph`: parpadea cada 0,12 s (destello de 0,06 s) hasta lanzar.
- Abanico: 5 semillas, apertura de 50°, velocidad 115; luego `walk` con `fan_cooldown` (1,6 s).
- Rodar: velocidad 200 hacia el jugador; rebotes objetivo `random.randint(2, 4)` en fase 2 (**inclusivo**:
  `randi_range(2, 4)`); en cada rebote de fase 2 suelta un anillo de **8** semillas (a `fan_speed`);
  al llegar a los rebotes, queda **aturdida** `stun_time` (1,5 s, daño ×2, color claro) y vuelve a `walk`.
- Espiral: dura 2,0 s, una ráfaga cada 0,14 s con **dos brazos opuestos** (offset 0° y 180°) y un giro de
  18° por ráfaga, velocidad 100; luego `walk` con `spiral_cooldown` (1,2 s).
- Refuerzos de la fase 3 (`_spawn_phase3_enemies`): candidatos = casillas `.` cuyo rectángulo de 28 px no
  toque al jefe ni al jugador agrandados 24 px; para cada refuerzo elige la casilla **más lejana** (por
  distancia al cuadrado mínima a jefe y jugador) y la retira de los candidatos.
Casi todos los números salen de `enemies.json` (`watermelon`); las excepciones están en el código (8 semillas del anillo, parpadeo de 0,12 s, destello de 0,06 s, colores de cada fase y del aturdimiento, color del jugo). **El azar** (`random`) solo se usa para los
rebotes: inyecta un `RandomNumberGenerator` para poder fijar la semilla en las pruebas.

### 6.7 `data/`, `assets/`, raíz

- `data/*.json`: sin cambios. En Godot se leen desde `res://` al exportar; mientras tanto la carpeta
  `data/` del repositorio sigue siendo la fuente (ver el cargador de la rebanada). Cuando se archive el
  Python, se decide si `data/` se mueve dentro de `godot/` (hace falta para exportar a Android).
- `assets/icon.png`: ícono del proyecto (`application/config/icon`).
- `main.py` → `main.tscn` + `scripts/main.gd`. `buildozer.spec` → preajuste de exportación de Android
  (versión, paquete `org.forestapple.forestapple`, orientación horizontal, arquitecturas `arm64-v8a`
  y `armeabi-v7a`, API mínima 23). `requirements.txt` desaparece.
- `.github/workflows/tests.yml`: hoy corre Python. Para Godot hace falta bajar el ejecutable en la CI
  (por ejemplo con una acción de instalación de Godot o la imagen `barichello/godot-ci`); no está
  probado y se decide en la etapa 0.

### 6.8 `tests/` — qué se porta y cómo

| Test de Python | Se porta como | Notas |
|---|---|---|
| `test_states.py` (pila, cursor, `row_at`, pausa, flujo) | `test_states.gd` | Los mismos casos, con `posmod` y `round_py`. |
| `test_dialogue.py` (texto, runner, líneas, caja) | `test_dialogue.gd` | Los de la caja dependen de la fuente: revisar. |
| `test_gameover.py` | `test_gameover.gd` | |
| `test_layout.py` (validador y salas) | `test_layout.gd` | Usa los `golden` (sección 7). |
| `test_boss.py` (fases, daño, refuerzos) | `test_boss.gd` | Con el generador de azar fijado. |
| `test_smoke.py` / `smoke_game.py` (partida completa) | `smoke_game.gd` | Partida guiada por script en modo sin ventana. |

## 7. Cómo comprobar que la traducción es fiel

El mayor riesgo es una diferencia que solo se nota jugando. Para reducirlo, **Python genera los
valores esperados y Godot los compara**.

1. **`tools/export_golden.py`** (se escribe en la etapa 0) importa los módulos puros de Python y
   escribe archivos JSON en `godot/tests/golden/`:
   - `phases.json`: `phase_for_hp` para una malla de vidas y umbrales.
   - `layout.json`: por sala, las puertas, los rectángulos de pared/obstáculo/puerta, los
     `entry_point` y el resultado de `validate()` (también con los casos de error de los tests).
   - `patterns.json`: ángulos y velocidades de `fan` y `shot_at_angle` con varios parámetros.
   - `dialogue.json`: para **cada** clave de `dialogues.json`, el texto visible, las pausas y los
     renglones medidos con un ancho fijo; y la traza de `DialogueRunner` (`shown_count` cada 1/60 s).
   - `movement.json`: trayectorias del jugador y de cada enemigo con una entrada fija (por ejemplo, 3 s
     moviendo a la derecha y disparando) sobre una sala conocida.
   - `boss.json`: traza de la sandía con la semilla del azar fijada (estado y fase cada 1/60 s).
2. **`godot/tests/run_tests.gd`** extiende `SceneTree`, carga los `test_*.gd`, ejecuta cada `test_*`
   y termina con código de salida distinto de cero si algo falla. Sin dependencias externas (no se usa
   GUT, para no instalar nada). Se corre con:
   ```
   godot --headless --path godot --script res://tests/run_tests.gd
   ```
3. Cada etapa **no se da por terminada** si sus pruebas de paridad no pasan **y** el checklist manual
   de la etapa no está completo.

## 8. Checklist de paridad (etapa 5)

Se recorre en Python y en Godot, uno al lado del otro, y se marcan las diferencias:
- [ ] Menú, opciones (cada entrada), pausa (cada opción) y salir al menú; se guardan las preferencias.
- [ ] Mover con aceleración y frenado, deslizarse contra paredes y obstáculos; igual velocidad máxima.
- [ ] Disparo en un solo eje; cadencia 0,35 s; el proyectil muere en paredes y al golpear.
- [ ] Cada enemigo se comporta como en Python (fresa quieta; piña lenta; banana carga; limón y charcos;
      durazno rebota); daño y 1 s de invulnerabilidad con parpadeo.
- [ ] Las puertas se cierran al entrar con enemigos vivos y se abren al limpiar; fundido entre salas;
      aparición a 2 casillas de la puerta; los enemigos tardan 0,5 s en despertar.
- [ ] Minimapa (colores y salas conocidas), HP, avisos y cartel central.
- [ ] La llave aparece al limpiar todas las salas menos la del jefe, se recoge con E y abre la puerta del jefe.
- [ ] La sandía: fase 1 (abanicos), fase 2 (rodar, anillos, aturdimiento), fase 3 (espiral, charcos, refuerzos);
      diálogos de cada fase; frases finales; barra de vida; "¡Piso completado!"; agujero y "E: bajar".
- [ ] Morir: se ve la escena 1,2 s, aparece "Fallaste..."; Reintentar y Salir al menú funcionan; Esc no hace nada.
- [ ] Android (a mano, en un teléfono real): controles táctiles, diálogos con toque, pausa.

## 9. Lo que se descarta a propósito

`core/viewport.py`, el lienzo y su escalado manual, la cola de texto, la carga de fuentes de pygame,
la compensación de toques duplicados (si se apaga la emulación de ratón) y el fondo procedural
detallado de las salas (hasta que haya arte). Todo lo demás se porta.

## 10. Pendientes de decisión antes de empezar

1. **Controles táctiles**: ¿sobre las franjas negras (necesita `scale_mode="keep"`) o encima del juego?
2. **Escalado**: ¿`integer` (nítido, pero con franjas) o `keep` (llena más pantalla)?
3. **Fondo de las salas**: ¿simple hasta tener arte, o portar los productos detallados?
4. **Fuente**: ¿la de Godot por defecto o una fuente pixel? Afecta qué diálogos caben en 3 renglones.
5. **Dónde viven los datos**: ¿`data/` se mueve dentro de `godot/` al archivar Python?
6. **CI de Godot**: ¿se agrega en la etapa 0?
