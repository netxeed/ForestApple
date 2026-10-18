"""Exporta los "valores dorados": lo que calcula el código Python, para que Godot lo compare.

Guía de migración: docs/migracion-godot.md (sección 7). Los archivos van a
`godot/tests/golden/` y se commitean. Cuando algo cambia en la lógica pura de Python,
se vuelven a generar:

    python tools/export_golden.py            # escribe los archivos
    python tools/export_golden.py --check    # solo comprueba que estén al día (código 1 si no)

Solo usa módulos sin pygame (fases, estructura del piso, diálogos). Los valores de movimiento,
patrones de proyectiles y del jefe dependen de pygame y se agregan en las etapas 3 y 4.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from core.phases import DEATH_DIALOGUE, PHASE_DIALOGUE, phase_for_hp  # noqa: E402
from dialogue.lines import dialogue_keys, load_dialogue  # noqa: E402
from dialogue.lines import Dialogue  # noqa: E402
from dialogue.runner import DEFAULT_SPEED, DialogueRunner  # noqa: E402
from dialogue.text import parse_text, tag_errors, wrap_spans  # noqa: E402
from rooms.layout import (  # noqa: E402
    APPROACH_TILE,
    COLS,
    DIRECTIONS,
    DOOR_TILE,
    ENEMY_LETTERS,
    MIN_ENEMY_DOOR_DISTANCE,
    ROWS,
    FloorLayout,
    load_floor_layout,
)

GOLDEN_DIR = ROOT / "godot" / "tests" / "golden"


# ---------- fases del jefe ----------
def phases():
    cases = []
    for max_hp in (110, 90, 3, 1):
        for thresholds in ([0.66, 0.33], [0.5], []):
            table = [phase_for_hp(hp, max_hp, thresholds) for hp in range(max_hp + 1)]
            cases.append({"max_hp": max_hp, "thresholds": thresholds, "phase_by_hp": table})
    return {
        "phase_dialogue": {str(k): v for k, v in PHASE_DIALOGUE.items()},
        "death_dialogue": DEATH_DIALOGUE,
        "cases": cases,
    }


# ---------- estructura del piso ----------
def _blank_room():
    rows = ["#" * COLS] + ["#" + "." * (COLS - 2) + "#" for _ in range(ROWS - 2)] + ["#" * COLS]
    return {"type": "normal", "layout": rows}


def _errors_for(floor_data, rooms):
    try:
        FloorLayout(floor_data, rooms).validate()
    except ValueError as error:
        return str(error).splitlines()
    return []


def layout():
    floor = load_floor_layout("floor1")
    floor.validate(enemy_letters=ENEMY_LETTERS.keys())
    cells = sorted(floor.cells.items(), key=lambda item: (item[0][1], item[0][0]))
    real = {
        "name": floor.name,
        "start": list(floor.start),
        "cells": [{"col": c, "row": r, "room": room} for (c, r), room in cells],
        "doors": [
            {"col": c, "row": r, "doors": sorted(floor.doors((c, r)))}
            for (c, r), _ in cells
        ],
        "neighbors": [
            {"col": c, "row": r, "dir": d, "to": list(floor.neighbor((c, r), d)) if floor.neighbor((c, r), d) else None}
            for (c, r), _ in cells
            for d in sorted(DIRECTIONS)
        ],
        "validate_errors": [],
    }

    # Pisos mal armados: el validador junta TODOS los problemas y los mensajes se conservan.
    broken = []
    two_rooms = {"a": _blank_room(), "b": _blank_room()}
    broken.append({
        "name": "sala_inalcanzable",
        "errors": _errors_for({"name": "t", "start": [0, 0], "grid": [["a", None, "b"]]}, two_rooms),
    })
    broken.append({
        "name": "inicio_inexistente",
        "errors": _errors_for({"name": "t", "start": [5, 5], "grid": [["a"]]}, {"a": _blank_room()}),
    })
    short = _blank_room()
    short["layout"] = short["layout"][:-1]
    broken.append({
        "name": "faltan_filas",
        "errors": _errors_for({"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": short}),
    })
    bad_char = _blank_room()
    bad_char["layout"][2] = bad_char["layout"][2][:3] + "Z" + bad_char["layout"][2][4:]
    broken.append({
        "name": "caracter_desconocido",
        "errors": _errors_for({"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": bad_char}),
    })
    border = _blank_room()
    border["layout"][0] = "#" * 3 + "." + "#" * (COLS - 4)
    broken.append({
        "name": "borde_abierto",
        "errors": _errors_for({"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": border}),
    })
    return {
        "constants": {
            "cols": COLS,
            "rows": ROWS,
            "directions": {d: list(v) for d, v in DIRECTIONS.items()},
            "door_tile": {d: list(v) for d, v in DOOR_TILE.items()},
            "approach_tile": {d: list(v) for d, v in APPROACH_TILE.items()},
            "enemy_letters": ENEMY_LETTERS,
            "min_enemy_door_distance": MIN_ENEMY_DOOR_DISTANCE,
        },
        "floor1": real,
        "broken": broken,
    }


# ---------- diálogos ----------
PARSE_CASES = [
    "Hola.",
    "Mira manzana...{pause=0.6} estoy abierta.",
    "{pause=0.5}Empieza con pausa.",
    "Termina con pausa.{pause=0.5}",
    "Dos{pause=0.3} pausas{pause=1} seguidas.",
    "Etiqueta {rara} desconocida.",
    "Salto\nde renglón{pause=0.2} y pausa.",
    "Pausa doble{pause=0.2}{pause=0.3} juntas.",
    "Sin letras {pause=0.4}",
]


TAG_CASES = [
    "Hola{pause=0.5}", "Hola{pausa=1}", "Hola{pause=0}", "Hola{pause=99}", "Hola {pause=1", "Hola pause=1}",
    "{pause=5}x", "{pause=5.1}x", "{pause=abc}", "a{b}c{pause=1}d", "{}", "{pause=1}{pause=2}",
]
TOY_MEASURE = lambda s: len(s) * 9  # noqa: E731
BOX_TEXT_WIDTH = 480 - 2 * 8 - 2 * 10  # igual que DialogueBox.text_width()
WRAP_CASES = [
    ("uno dos", 200), ("uno dos tres cuatro", 80), ("uno\ndos tres", 200), ("uno\n\ndos", 200),
    ("extraordinariamente corto", 30), ("uno dos\ntres cuatro cinco", 80), ("", 100), ("   ", 100),
]
# Cada paso `dt` se escribe como [numerador, denominador] para que Python y Godot calculen
# exactamente el mismo número (dividir dos enteros da el mismo double; leer "0.1" de un JSON, quizá no).
RUNNER_CASES = [
    ("a" * 100, 45, [[1, 60]] * 30),
    ("ab{pause=1}cd", 10, [[1, 2], [6, 10], [2, 10], [10, 10]]),
    ("a{pause=1}b{pause=1}c", 10, [[10, 1]]),
    ("Mira...{pause=0.6} estoy{pause=1} abierta.", 45, [[1, 60]] * 140),
    ("hola mundo", 20, [[0, 1], [1, 10], [1, 10], [1, 2], [1, 1]]),
]


def dialogue():
    parse_cases = []
    for raw in PARSE_CASES:
        visible, pauses = parse_text(raw)
        parse_cases.append({"raw": raw, "text": visible, "pauses": [[pos, secs] for pos, secs in pauses]})

    dialogues = {}
    for key in dialogue_keys():
        d = load_dialogue(key)
        lines = []
        for line in d.all_lines():
            lines.append({
                "text": line.plain,
                "pauses": [[pos, secs] for pos, secs in line.pauses],
                "speaker": line.speaker,
                # velocidad efectiva: la de la línea/diálogo o, si no hay, la del runner
                "speed": float(line.speed or DEFAULT_SPEED),
            })
        dialogues[key] = {"speaker": d.speaker, "lines": lines}

    tag_cases = [{"raw": raw, "errors": tag_errors(raw)} for raw in TAG_CASES]

    # Corte en renglones con una fuente de juguete (9 px por letra) y el ancho útil de la caja.
    wrap_cases = []
    for key in dialogue_keys():
        for number, line in enumerate(load_dialogue(key).all_lines()):
            spans = wrap_spans(line.plain, TOY_MEASURE, BOX_TEXT_WIDTH)
            wrap_cases.append({"key": key, "line": number, "spans": [[a, b] for a, b in spans]})
    for text, width in WRAP_CASES:
        wrap_cases.append({"text": text, "width": width, "spans": [[a, b] for a, b in wrap_spans(text, TOY_MEASURE, width)]})

    return {
        "default_speed": DEFAULT_SPEED,
        "parse_cases": parse_cases,
        "tag_cases": tag_cases,
        "wrap_width": BOX_TEXT_WIDTH,
        "wrap_cases": wrap_cases,
        "runner_cases": runner_cases(),
        "dialogues": dialogues,
    }


def runner_cases():
    """Avance del efecto de escritura paso a paso: letras visibles y si está en pausa tras cada `dt`."""
    cases = []
    for text, speed, steps in RUNNER_CASES:
        runner = DialogueRunner(Dialogue("X", (text,), (None,), (speed,), None))
        trace = []
        for numerator, denominator in steps:
            runner.update(numerator / denominator)
            trace.append({"shown": runner.shown_count, "waiting": runner.waiting, "complete": runner.line_complete})
        cases.append({"text": text, "speed": speed, "steps": steps, "trace": trace})
    return cases


FILES = {"phases.json": phases, "layout.json": layout, "dialogue.json": dialogue}


def render(data):
    return json.dumps(data, ensure_ascii=False, indent=1, sort_keys=True) + "\n"


def main(argv):
    check = "--check" in argv
    stale = []
    for name, build in FILES.items():
        text = render(build())
        path = GOLDEN_DIR / name
        if check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                stale.append(name)
        else:
            GOLDEN_DIR.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
            print(f"escrito {path.relative_to(ROOT)}")
    if check:
        if stale:
            print("Desactualizados (corre `python tools/export_golden.py`): " + ", ".join(stale))
            return 1
        print("OK: los valores dorados están al día.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
