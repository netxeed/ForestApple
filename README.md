# ForestApple

Juego de mazmorras estilo The Binding of Isaac.
Sos una manzana (y un niño) que avanza de sala en sala contra frutas hostiles.

## Cómo correrlo

```bash
python -m venv .venv
source .venv/bin/activate        # En Windows: .venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

## Prototipo para Android

El proyecto incluye controles táctiles y una configuración inicial para generar
un APK de prueba en orientación horizontal. Para compilarlo hace falta Linux o
macOS con Java, Android SDK/NDK y Buildozer instalados; la primera compilación
descarga las herramientas de Android y puede tardar varios minutos.

```bash
buildozer android debug
```

El APK queda en `bin/`. Se puede instalar en un teléfono Android con depuración
USB activada usando `buildozer android debug deploy run`, o copiar el APK al
teléfono e instalarlo manualmente. La configuración usa una receta de
`pygame-ce` mantenida en una rama de python-for-android porque todavía no está
incluida en la rama principal de esa herramienta. El empaquetado debe probarse
en un dispositivo Android antes de darlo por listo.

En el juego, usa el pad izquierdo para moverte y el derecho para disparar. El
botón `E` interactúa y `Ⅱ` pausa. Toca la zona central para confirmar en los
menús. Los controles táctiles solo se muestran con el controlador de pantalla
Android; en computadora siguen disponibles teclado y ventana.

## Controles

| Acción | Tecla |
|---|---|
| Moverse | W A S D |
| Disparar | Flechas |
| Reiniciar | R |
| Salir | Esc |
| Menú de pausa / continuar | Esc |
| Elegir opción del menú | ↑ / ↓ o W / S, Enter o Espacio |
| Reiniciar | R (durante la partida) o desde el menú de pausa |
| Salir | Desde el menú de pausa |
| Avanzar un diálogo (la primera pulsación muestra la línea completa) | Espacio, Enter o Z |
| Recoger/usar la llave o entrar al agujero tras el jefe | E |
| (debug) Eliminar enemigos de la sala | K |

La tecla de debug se apaga con `DEBUG_KEYS = False` en `core/settings.py`.

## Cómo funciona el piso

- El piso 1 son 8 salas en una grilla (`data/floor1.json`). Si dos salas están
  una al lado de la otra, **las puertas aparecen solas** entre ellas.
- Al entrar a una sala con enemigos las puertas se cierran (se ven marrones) y
  los enemigos tardan unos instantes en despertar. Al matarlos todos se abren.
- Las salas limpias quedan limpias al volver.
- El minimapa (arriba a la derecha) muestra la sala actual en blanco, las
  limpias en verde y las que todavía no visitaste como contorno. El jefe
  tiene contorno rojo.
- La sala del jefe tiene a la **sandía** (ver abajo). Mientras se pelea, la barra
  de vida del jefe aparece arriba, al centro.
- La puerta plateada de la sandía queda cerrada hasta limpiar las otras siete
  salas (incluida la inicial). Al limpiar la última aparece la llave en el
  centro de esa sala: acércate y pulsa **E** para recogerla. Luego úsala con
  **E** junto a la puerta para gastarla y entrar.
- Al derrotar a la sandía aparece un agujero en el centro de su sala. Acércate
  y pulsa **E** para oscurecer la pantalla y mostrar el diálogo sin nombre
  «La batalla continuará...». El piso 2 todavía no tiene contenido.
- El minimapa aparece arriba a la derecha y los trinkets se muestran debajo
  como iconos. La llave es el primero; aún no hay trinkets que mejoren las
  estadísticas de la manzana.

## La sandía (jefe del piso 1)

Tiene 3 fases según su vida (66 % y 33 %). Al empezar cada fase la pelea se
frena y habla (diálogo provisorio), y es invulnerable 1 segundo.

| Fase | Qué hace | Cómo se juega |
|---|---|---|
| 1 | Camina lento hacia vos (se frena a cierta distancia) y escupe abanicos de 5 semillas. | Esquivar entre los huecos del abanico. |
| 2 | Se sacude (aviso), rueda rebotando 3 veces y queda aturdida. | Esquivar la rodada y dispararle mientras está aturdida: ahí recibe **doble daño**. |
| 3 | Es más rápida, alterna abanicos con espirales de semillas y deja charcos de jugo que dañan. | Moverse sin parar: los charcos achican el espacio. |

Todos los números (vida, velocidades, tiempos de aviso) están en
`data/enemies.json` → `watermelon` (la clave `_nota` explica las unidades).
**Son provisorios y no están balanceados jugando**: ajústenlos probando. Los
pilares de la sala sirven de cobertura contra las semillas.

## Diálogos

Los textos están en `data/dialogues.json` (provisorios). Cada clave es un diálogo
con `speaker` (quién habla) y `lines` (las cajas de texto, en orden). Para
revisar que el archivo esté bien armado:

```bash
python -m dialogue.lines
```

Una línea puede ser un texto o un objeto con más datos:

```json
"speaker": "Sandía",
"lines": [
  "Mira manzana...{pause=0.6} estoy abierta.",
  {"text": "¿Quién habla ahora?\nOtro renglón.", "speaker": "Niño"},
  {"text": "¡Rápido!", "speed": 90}
]
```

- `speaker` dentro de una línea reemplaza al del diálogo solo en esa caja (vacío = sin nombre).
- `speed` son letras por segundo (45 por defecto); sirve en una línea o en el diálogo entero.
- `{pause=0.5}` frena la escritura ese tiempo (hasta 5 s). `\n` fuerza un renglón nuevo.
- La caja muestra el nombre y hasta **3 renglones**; `python -m dialogue.lines` avisa de
  etiquetas mal escritas, velocidades fuera de rango y campos desconocidos, y los tests
  fallan si algún texto del juego necesita más de 3 renglones.

Cómo está armado: `dialogue/text.py` (etiquetas y corte en renglones), `dialogue/lines.py`
(carga y validación), `dialogue/runner.py` (efecto de escritura y pausas) y
`dialogue/box.py` (dibujo). Los tres primeros no usan pygame. Todavía no hay retratos ni
opciones para elegir.

Para que algo muestre un diálogo desde el código: `game.say("clave")` (desde una sala, se
agrega la clave a `room.pending_dialogues` y la partida lo abre); el juego se pausa
mientras se lee.

## Pantallas (estados)

Cada pantalla es un `State` (`states/`): menú, opciones, partida, pausa y diálogo.
Viven en una pila (`StateStack`, `states/base.py`): el de arriba recibe las teclas y
los toques y se actualiza; si es `transparent` se dibuja encima del de abajo, que queda
congelado (la pausa y los diálogos se ven sobre la partida).

```
[Menú]  →  [Partida]  →  [Partida, Pausa]  →  [Partida, Diálogo, Pausa]
```

`Game` es el director y ofrece lo que los estados necesitan: `start_run()`,
`open_pause()`, `open_options()`, `return_to_menu()`, `say(clave, dark, on_close)` y
`quit()`. Los estados no se importan entre sí. Para una pantalla nueva: heredar de
`State`, redefinir lo que haga falta (`handle_key`, `handle_touch`, `update`, `draw`) y
abrirla con `game.states.push(...)`. La pila y el cursor de menús no usan pygame y
están testeados en `tests/test_states.py`.

## Cómo agregar o editar salas (sin tocar código)

Las salas viven en `data/rooms.json`. Cada una es una grilla de 15x9 caracteres:

| Carácter | Significa |
|---|---|
| `#` | pared (el borde entero tiene que ser `#`) |
| `.` | piso |
| `X` | obstáculo (bloquea al jugador y a los disparos) |
| `S` | frutilla |
| `P` | piña |
| `B` | banana |
| `L` | limón |
| `D` | durazno |
| `W` | sandía (jefe: una sola por sala, solo en la sala del jefe) |

No dibujen las puertas: se generan según los vecinos en `data/floor1.json`.
Solo asegúrense de que las 4 casillas de entrada (centro de cada pared, una
hacia adentro) sean `.`, para que nadie aparezca dentro de un obstáculo.
Los enemigos tienen que quedar a **2,5 casillas o más** del punto donde aparece
el jugador al entrar por cada puerta (2 casillas hacia adentro de la puerta).
Si no, el jugador recibe daño apenas llega. El validador lo revisa solo para las
puertas que de verdad existen en esa sala.

Para armar o cambiar el mapa del piso, editen la grilla de `data/floor1.json`
(`null` = no hay sala). Después validen todo con:

```bash
python -m rooms.layout
```

Tira un listado con todos los problemas si algo está mal (tamaño, bordes,
caracteres raros, enemigos pegados a una puerta, salas inalcanzables).

## Tests

```bash
python -m unittest discover tests -v
```

Los tests de estructura, fases, diálogos y estados no necesitan pygame. Los del
comportamiento del jefe (`tests/test_boss.py`) sí lo usan y se saltean solos si
no está instalado.

## Estructura

```
main.py          punto de entrada
core/            configuración global, game loop (Game), controles, preferencias, táctil y
                 phases.py (fases de jefes, sin pygame)
states/          pila de estados (base.py, cursor.py: sin pygame) y las pantallas:
                 menu.py, play.py, pause.py, dialogue.py
entities/        jugador, trinkets.py, proyectiles, enemigos, patterns.py (abanico/espiral), watermelon.py (jefe)
rooms/           layout.py (estructura del piso, sin pygame),
                 room.py (una sala con puertas), floor.py (el piso entero)
dialogue/        text.py, lines.py y runner.py (sin pygame) y box.py (la caja)
data/            enemies.json, rooms.json, floor1.json, dialogues.json
tests/           estructura del piso, fases, diálogos, pila de estados y comportamiento del jefe
assets/          sprites y sonidos (por ahora todo son cuadrados de colores)
```

## Cómo agregar un enemigo nuevo

1. Agregar sus stats en `data/enemies.json`.
2. Crear `entities/<nombre>.py` con una clase que herede de `Enemy` y redefina `update_behavior()`.
3. Registrarlo en `entities/__init__.py` (diccionario `ENEMY_TYPES`).
4. Asignarle una letra en `ENEMY_LETTERS` (`rooms/layout.py`, es el único lugar donde se define)
   y usarla en `data/rooms.json`.

Mirá `entities/strawberry.py` como ejemplo.

## Reglas del equipo

- Nadie trabaja directo en `main`: una rama por funcionalidad.
- Todo cambio entra por Pull Request revisado por otra persona.
- Tamaño de sprite acordado: **32x32** (no cambiar sin avisar).

## Estado del demo

- Piso 1 del acto 2: ocho salas conectadas, minimapa y cinco enemigos regulares.
- Sandía con tres fases, diálogos provisorios y números todavía sin balancear.
- Llave consumible para entrar al jefe y agujero placeholder tras derrotarlo.
- Arte, música, balance y textos todavía provisionales. El niño, el acto 1,
  el acto 3, el piso 2 y los trinkets que mejoran a la manzana son desarrollo
  futuro.
