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
- La sala del jefe es un **placeholder** con frutillas hasta que esté la sandía.

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

Los tests de estructura no necesitan pygame.

## Estructura

```
main.py          punto de entrada
core/            configuración global y game loop
entities/        jugador, proyectiles, enemigos
rooms/           layout.py (estructura del piso, sin pygame),
                 room.py (una sala con puertas), floor.py (el piso entero)
dialogue/        sistema de diálogo (pendiente)
data/            enemies.json, rooms.json, floor1.json
tests/           tests de la estructura del piso
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

## Hitos

- [x] Una sala, jugador + frutilla
- [x] Varias salas conectadas por puertas, minimapa
- [x] Piña, banana, durazno y limón
- [ ] Cambio manzana / niño
- [ ] Sistema de diálogo
- [ ] Sandía (jefe)
- [ ] Arte final, sonido y menús
