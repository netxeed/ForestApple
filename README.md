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

La caja de diálogo (`dialogue/box.py`) es **provisoria**: máquina de escribir y
nada más. Cuando esté el sistema definitivo se reemplaza manteniendo su interfaz
(`start`, `update`, `advance`, `draw`, `active`). Para que algo muestre un diálogo
desde el código: `room.say("clave")`; el juego se pausa mientras se lee.

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

Los tests de estructura, fases y diálogos no necesitan pygame. Los del
comportamiento del jefe (`tests/test_boss.py`) sí lo usan y se saltean solos si
no está instalado.

## Estructura

```
main.py          punto de entrada
core/            configuración global, game loop y phases.py (fases de jefes, sin pygame)
entities/        jugador, trinkets.py, proyectiles, enemigos, patterns.py (abanico/espiral), watermelon.py (jefe)
rooms/           layout.py (estructura del piso, sin pygame),
                 room.py (una sala con puertas), floor.py (el piso entero)
dialogue/        lines.py (carga de textos, sin pygame) y box.py (caja provisoria)
data/            enemies.json, rooms.json, floor1.json, dialogues.json
tests/           estructura del piso, fases, diálogos y comportamiento del jefe
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
