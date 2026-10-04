"""Estructura del piso: qué salas hay, dónde están y qué puertas tienen.

Este módulo NO usa pygame a propósito, para poder testearlo rápido
(ver tests/test_layout.py) y para que quien arma salas pueda validarlas
sin abrir el juego:

    python -m rooms.layout            # valida data/floor1.json
"""

import json
import math
from collections import deque
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

COLS = 15
ROWS = 9

# Dirección -> desplazamiento en la grilla del piso (col, fila)
DIRECTIONS = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
OPPOSITE = {"up": "down", "down": "up", "left": "right", "right": "left"}

# Baldosa (col, fila) de la puerta en cada pared de la sala
DOOR_TILE = {
    "up": (COLS // 2, 0),
    "down": (COLS // 2, ROWS - 1),
    "left": (0, ROWS // 2),
    "right": (COLS - 1, ROWS // 2),
}
# Baldosa justo adentro de cada puerta: tiene que estar libre (piso)
APPROACH_TILE = {
    "up": (COLS // 2, 1),
    "down": (COLS // 2, ROWS - 2),
    "left": (1, ROWS // 2),
    "right": (COLS - 2, ROWS // 2),
}

# '#' pared, '.' piso, 'X' obstáculo
BASE_TILES = set("#.X")
ROOM_TYPES = {"start", "normal", "boss"}

# Letra de cada enemigo en los layouts -> clave en data/enemies.json y en ENEMY_TYPES.
# Es el ÚNICO lugar donde se define: Room, el validador y los tests la leen de acá.
# Para sumar un enemigo (ej. la sandía) agregar su letra acá.
ENEMY_LETTERS = {
    "S": "strawberry",
    "P": "pineapple",
    "B": "banana",
    "L": "lemon",
    "D": "peach",
}

# Distancia mínima (en casillas) entre cualquier enemigo y el punto donde aparece el
# jugador al entrar por una puerta. Con menos que esto el jugador recibe daño al llegar.
MIN_ENEMY_DOOR_DISTANCE = 2.5


class FloorLayout:
    def __init__(self, floor_data, rooms_data):
        if not isinstance(floor_data, dict):
            raise ValueError("El archivo del piso debe contener un objeto JSON.")
        if not isinstance(rooms_data, dict):
            raise ValueError("rooms.json debe contener un objeto JSON.")

        grid = floor_data.get("grid")
        if not isinstance(grid, list) or not grid:
            raise ValueError("El piso debe tener una grilla no vacía.")
        if any(not isinstance(row, list) for row in grid):
            raise ValueError("Cada fila de la grilla del piso debe ser una lista.")
        width = len(grid[0])
        if width == 0 or any(len(row) != width for row in grid):
            raise ValueError("Todas las filas de la grilla del piso deben tener el mismo ancho.")

        start = floor_data.get("start")
        if (
            not isinstance(start, (list, tuple))
            or len(start) != 2
            or any(not isinstance(value, int) or isinstance(value, bool) for value in start)
        ):
            raise ValueError("'start' debe ser una coordenada [columna, fila] entera.")

        self.name = floor_data.get("name", "Piso")
        self.rooms = rooms_data
        self.start = tuple(start)
        self.cells = {}  # (col, fila) -> id de sala
        for row, line in enumerate(grid):
            for col, room_id in enumerate(line):
                if room_id is not None:
                    self.cells[(col, row)] = room_id

    # ---------- consultas ----------
    def neighbor(self, cell, direction):
        dx, dy = DIRECTIONS[direction]
        nxt = (cell[0] + dx, cell[1] + dy)
        return nxt if nxt in self.cells else None

    def doors(self, cell):
        """Direcciones en las que esta sala tiene puerta (hay sala vecina)."""
        return {d for d in DIRECTIONS if self.neighbor(cell, d) is not None}

    def room_data(self, cell):
        return self.rooms[self.cells[cell]]

    # ---------- validación ----------
    def validate(self, enemy_letters=None):
        """Revisa que todo esté bien armado. Tira ValueError con TODOS los problemas.

        `enemy_letters`: letras de enemigos válidas (por defecto, ENEMY_LETTERS).
        """
        if enemy_letters is None:
            enemy_letters = ENEMY_LETTERS
        enemy_letters = set(enemy_letters)
        valid_chars = BASE_TILES | enemy_letters
        errors = []

        if self.start not in self.cells:
            errors.append(f"La sala inicial {self.start} no existe en la grilla.")

        for cell, room_id in sorted(self.cells.items()):
            if not isinstance(room_id, str) or room_id not in self.rooms:
                errors.append(f"La grilla usa '{room_id}' en {cell} pero no está en rooms.json.")

        well_formed = set()
        for room_id in sorted({r for r in self.cells.values() if isinstance(r, str) and r in self.rooms}):
            room_errors = self._validate_room(room_id, valid_chars)
            errors.extend(room_errors)
            if not room_errors:
                well_formed.add(room_id)

        # Solo se revisa la distancia en salas con la estructura correcta
        errors.extend(self._validate_enemy_spacing(well_formed, enemy_letters))
        errors.extend(self._validate_connectivity())

        if errors:
            raise ValueError("Problemas en el piso:\n- " + "\n- ".join(errors))

    def _validate_room(self, room_id, valid_chars):
        errors = []
        data = self.rooms[room_id]
        if not isinstance(data, dict):
            return [f"[{room_id}] debe ser un objeto en rooms.json."]
        layout = data.get("layout")
        if not isinstance(layout, list) or not layout:
            return [f"[{room_id}] no tiene 'layout'."]

        if data.get("type", "normal") not in ROOM_TYPES:
            errors.append(f"[{room_id}] tipo '{data.get('type')}' inválido (usar {sorted(ROOM_TYPES)}).")

        if len(layout) != ROWS:
            return errors + [f"[{room_id}] tiene {len(layout)} filas, debe tener {ROWS}."]
        bad_rows = [i for i, line in enumerate(layout) if not isinstance(line, str)]
        if bad_rows:
            return errors + [f"[{room_id}] las filas {bad_rows} deben ser texto."]
        bad_width = [i for i, line in enumerate(layout) if len(line) != COLS]
        if bad_width:
            return errors + [f"[{room_id}] filas {bad_width} no miden {COLS} caracteres."]

        for row, line in enumerate(layout):
            for col, ch in enumerate(line):
                if ch not in valid_chars:
                    errors.append(f"[{room_id}] carácter desconocido '{ch}' en fila {row}, col {col}.")
                on_border = row in (0, ROWS - 1) or col in (0, COLS - 1)
                if on_border and ch != "#":
                    errors.append(f"[{room_id}] el borde debe ser '#' (fila {row}, col {col}).")

        for direction, (col, row) in APPROACH_TILE.items():
            if layout[row][col] != ".":
                errors.append(
                    f"[{room_id}] la baldosa de entrada '{direction}' (fila {row}, col {col}) "
                    f"debe ser '.', hay '{layout[row][col]}'."
                )
        return errors

    def _validate_enemy_spacing(self, room_ids, enemy_letters):
        """Ningún enemigo puede quedar pegado al punto de entrada de una puerta real."""
        errors = []
        for cell, room_id in sorted(self.cells.items()):
            if not isinstance(room_id, str) or room_id not in room_ids:
                continue
            layout = self.rooms[room_id]["layout"]
            for direction in sorted(self.doors(cell)):
                col, row = DOOR_TILE[direction]
                dx, dy = DIRECTIONS[direction]
                # Igual que Room.entry_point: 2 casillas hacia adentro de la puerta
                spawn_x, spawn_y = col + 0.5 - dx * 2, row + 0.5 - dy * 2
                for r, line in enumerate(layout):
                    for c, ch in enumerate(line):
                        if ch not in enemy_letters:
                            continue
                        dist = math.hypot(spawn_x - (c + 0.5), spawn_y - (r + 0.5))
                        if dist < MIN_ENEMY_DOOR_DISTANCE:
                            errors.append(
                                f"[{room_id}] el enemigo '{ch}' (fila {r}, col {c}) está a {dist:.1f} "
                                f"casillas de donde aparece el jugador por la puerta '{direction}' "
                                f"(mínimo {MIN_ENEMY_DOOR_DISTANCE})."
                            )
        return errors

    def _validate_connectivity(self):
        if self.start not in self.cells:
            return []
        seen = {self.start}
        queue = deque([self.start])
        while queue:
            cell = queue.popleft()
            for d in DIRECTIONS:
                nxt = self.neighbor(cell, d)
                if nxt and nxt not in seen:
                    seen.add(nxt)
                    queue.append(nxt)
        unreachable = sorted(set(self.cells) - seen)
        if unreachable:
            return [f"Salas inalcanzables desde el inicio: {unreachable}."]
        return []


def load_floor_layout(name="floor1"):
    with open(DATA_DIR / f"{name}.json", encoding="utf-8") as f:
        floor_data = json.load(f)
    with open(DATA_DIR / "rooms.json", encoding="utf-8") as f:
        rooms_data = json.load(f)
    return FloorLayout(floor_data, rooms_data)


if __name__ == "__main__":
    import sys

    floor_name = sys.argv[1] if len(sys.argv) > 1 else "floor1"
    layout = load_floor_layout(floor_name)
    layout.validate()
    print(f"OK: {layout.name} ({len(layout.cells)} salas, inicio en {layout.start})")
