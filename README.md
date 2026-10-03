# Manzana (título provisorio)

Juego top-down estilo The Binding of Isaac, con diálogos estilo Undertale.
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
| Reiniciar sala | R |
| Salir | Esc |

## Estructura

```
main.py          punto de entrada
core/            configuración global y game loop
entities/        jugador, proyectiles, enemigos
rooms/           salas (enemigos, paredes, puertas)
dialogue/        sistema de diálogo (pendiente)
data/            stats de enemigos en JSON (se editan sin tocar código)
assets/          sprites y sonidos (por ahora todo son cuadrados de colores)
```

## Cómo agregar un enemigo nuevo

1. Agregar sus stats en `data/enemies.json`.
2. Crear `entities/<nombre>.py` con una clase que herede de `Enemy` y redefina `update_behavior()`.
3. Registrarlo en `entities/__init__.py` (diccionario `ENEMY_TYPES`).
4. Ponerlo en una sala desde `rooms/room.py`.

Mirá `entities/strawberry.py` como ejemplo.

## Reglas del equipo

- Nadie trabaja directo en `main`: una rama por funcionalidad.
- Todo cambio entra por Pull Request revisado por otra persona.
- Tamaño de sprite acordado: **32x32** (no cambiar sin avisar).

## Próximos hitos

- [ ] Varias salas conectadas por puertas
- [ ] Piña, banana, durazno y limón
- [ ] Cambio manzana / niño
- [ ] Sistema de diálogo
- [ ] Sandía (jefe)
- [ ] Arte final, sonido y menús
