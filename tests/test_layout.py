"""Tests de la estructura del piso (no necesitan pygame).

Correr desde la carpeta del proyecto:

    python -m unittest discover tests -v
"""

import json
import unittest

from rooms.layout import (
    APPROACH_TILE,
    COLS,
    DATA_DIR,
    DIRECTIONS,
    DOOR_TILE,
    ENEMY_LETTERS,
    MIN_ENEMY_DOOR_DISTANCE,
    OPPOSITE,
    ROWS,
    FloorLayout,
    load_floor_layout,
)


def blank_room(kind="normal"):
    rows = ["#" * COLS] + ["#" + "." * (COLS - 2) + "#" for _ in range(ROWS - 2)] + ["#" * COLS]
    return {"type": kind, "layout": rows}


def small_floor(grid, start=(0, 0)):
    ids = {cell for row in grid for cell in row if cell}
    rooms = {room_id: blank_room() for room_id in ids}
    return FloorLayout({"name": "test", "start": list(start), "grid": grid}, rooms)


class RealFloorTests(unittest.TestCase):
    def setUp(self):
        self.layout = load_floor_layout("floor1")

    def test_floor1_is_valid(self):
        self.layout.validate()

    def test_floor1_has_one_start_and_one_boss(self):
        kinds = [self.layout.room_data(c).get("type") for c in self.layout.cells]
        self.assertEqual(kinds.count("start"), 1)
        self.assertEqual(kinds.count("boss"), 1)

    def test_start_room_is_the_start_type_and_has_no_enemies(self):
        data = self.layout.room_data(self.layout.start)
        self.assertEqual(data["type"], "start")
        self.assertFalse(any(ch in ENEMY_LETTERS for line in data["layout"] for ch in line))

    def test_every_door_is_symmetric(self):
        for cell in self.layout.cells:
            for d in self.layout.doors(cell):
                other = self.layout.neighbor(cell, d)
                self.assertIn(OPPOSITE[d], self.layout.doors(other))


class ValidationTests(unittest.TestCase):
    def test_neighbors_and_doors(self):
        layout = small_floor([["a", "b"], [None, "c"]])
        self.assertEqual(layout.doors((0, 0)), {"right"})
        self.assertEqual(layout.doors((1, 0)), {"left", "down"})
        self.assertEqual(layout.neighbor((1, 1), "up"), (1, 0))
        self.assertIsNone(layout.neighbor((1, 1), "left"))

    def test_valid_small_floor(self):
        small_floor([["a", "b"]]).validate()

    def test_unknown_room_id(self):
        layout = small_floor([["a", "b"]])
        layout.cells[(1, 0)] = "fantasma"
        with self.assertRaisesRegex(ValueError, "fantasma"):
            layout.validate()

    def test_unreachable_room(self):
        layout = small_floor([["a", None, "b"]])
        with self.assertRaisesRegex(ValueError, "inalcanzables"):
            layout.validate()

    def test_start_must_exist(self):
        layout = small_floor([["a", "b"]], start=(5, 5))
        with self.assertRaisesRegex(ValueError, "inicial"):
            layout.validate()

    def test_wrong_row_count(self):
        layout = small_floor([["a"]])
        layout.rooms["a"]["layout"].pop()
        with self.assertRaisesRegex(ValueError, "filas"):
            layout.validate()

    def test_wrong_row_width(self):
        layout = small_floor([["a"]])
        layout.rooms["a"]["layout"][3] += "."
        with self.assertRaisesRegex(ValueError, "no miden"):
            layout.validate()

    def test_broken_border(self):
        layout = small_floor([["a"]])
        row = list(layout.rooms["a"]["layout"][0])
        row[3] = "."
        layout.rooms["a"]["layout"][0] = "".join(row)
        with self.assertRaisesRegex(ValueError, "borde"):
            layout.validate()

    def test_unknown_character(self):
        layout = small_floor([["a"]])
        row = list(layout.rooms["a"]["layout"][2])
        row[2] = "Z"
        layout.rooms["a"]["layout"][2] = "".join(row)
        with self.assertRaisesRegex(ValueError, "desconocido"):
            layout.validate()

    def test_blocked_approach_tile(self):
        for direction, (col, row) in APPROACH_TILE.items():
            with self.subTest(direction=direction):
                layout = small_floor([["a"]])
                line = list(layout.rooms["a"]["layout"][row])
                line[col] = "X"
                layout.rooms["a"]["layout"][row] = "".join(line)
                with self.assertRaisesRegex(ValueError, "entrada"):
                    layout.validate()

    def test_invalid_room_type(self):
        layout = small_floor([["a"]])
        layout.rooms["a"]["type"] = "tienda"
        with self.assertRaisesRegex(ValueError, "tipo"):
            layout.validate()

    def test_reports_all_problems_at_once(self):
        layout = small_floor([["a", "b"]])
        layout.rooms["a"]["type"] = "tienda"
        layout.rooms["b"]["type"] = "otra"
        with self.assertRaises(ValueError) as ctx:
            layout.validate()
        self.assertIn("[a]", str(ctx.exception))
        self.assertIn("[b]", str(ctx.exception))


def place_enemy(rows, col, row, letter="S"):
    line = list(rows[row])
    line[col] = letter
    rows[row] = "".join(line)


class SpacingTests(unittest.TestCase):
    def test_enemy_next_to_door_entry_is_rejected(self):
        layout = small_floor([["a", "b"]])  # 'a' tiene puerta derecha: el jugador aparece en col 12, fila 4
        place_enemy(layout.rooms["a"]["layout"], 11, 4)
        with self.assertRaisesRegex(ValueError, "puerta 'right'"):
            layout.validate()

    def test_enemy_far_from_door_entry_is_accepted(self):
        layout = small_floor([["a", "b"]])
        place_enemy(layout.rooms["a"]["layout"], 3, 4)
        layout.validate()

    def test_only_real_doors_count(self):
        # 'a' no tiene puerta izquierda: un enemigo pegado a ese lado no molesta
        layout = small_floor([["a", "b"]])
        place_enemy(layout.rooms["a"]["layout"], 2, 4)
        layout.validate()

    def test_message_names_room_enemy_and_distance(self):
        layout = small_floor([["a", "b"]])
        place_enemy(layout.rooms["a"]["layout"], 11, 4, "P")
        with self.assertRaises(ValueError) as ctx:
            layout.validate()
        message = str(ctx.exception)
        self.assertIn("[a]", message)
        self.assertIn("'P'", message)
        self.assertIn("1.0", message)

    def test_spacing_is_skipped_for_malformed_rooms(self):
        # Una sala mal armada reporta su propio error y no rompe el chequeo de distancia
        layout = small_floor([["a", "b"]])
        layout.rooms["a"]["layout"].pop()
        with self.assertRaisesRegex(ValueError, "filas"):
            layout.validate()

    def test_minimum_distance_is_at_least_two_tiles(self):
        self.assertGreaterEqual(MIN_ENEMY_DOOR_DISTANCE, 2)


class EnemyLettersTests(unittest.TestCase):
    def test_every_letter_has_stats_in_enemies_json(self):
        with open(DATA_DIR / "enemies.json", encoding="utf-8") as f:
            stats = json.load(f)
        for letter, kind in ENEMY_LETTERS.items():
            self.assertIn(kind, stats, f"la letra '{letter}' usa '{kind}', que falta en enemies.json")

    def test_letters_do_not_clash_with_base_tiles(self):
        self.assertFalse(set(ENEMY_LETTERS) & set("#.X"))


class ConstantsTests(unittest.TestCase):
    def test_door_and_approach_tiles_are_consistent(self):
        for d in DIRECTIONS:
            dc, dr = DOOR_TILE[d]
            ac, ar = APPROACH_TILE[d]
            dx, dy = DIRECTIONS[d]
            # la baldosa de entrada está una casilla hacia adentro de la puerta
            self.assertEqual((ac, ar), (dc - dx, dr - dy))

    def test_opposite_is_involution(self):
        for d, o in OPPOSITE.items():
            self.assertEqual(OPPOSITE[o], d)


if __name__ == "__main__":
    unittest.main()
