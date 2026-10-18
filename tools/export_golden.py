"""Exporta los "valores dorados": lo que calcula el código Python, para que Godot lo compare.

Guía de migración: docs/migracion-godot.md (sección 7). Los archivos van a
`godot/tests/golden/` y se commitean. Cuando algo cambia en la lógica pura de Python,
se vuelven a generar:

    python tools/export_golden.py            # escribe los archivos
    python tools/export_golden.py --check    # solo comprueba que estén al día (código 1 si no)

Los valores de movimiento y proyectiles se calculan con el prototipo pygame y se incorporan
cuando se migran en la etapa 3. Los datos no alteran la lógica Python del juego.
"""

import json
import random
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
from entities.player import Player  # noqa: E402
from entities.projectile import Projectile  # noqa: E402
from entities.strawberry import Strawberry  # noqa: E402
from entities.pineapple import Pineapple  # noqa: E402
from entities.banana import Banana  # noqa: E402
from entities.lemon import Lemon, AcidDrop, AcidPuddle  # noqa: E402
from entities.peach import Peach  # noqa: E402
from entities.patterns import fan, shot_at_angle  # noqa: E402
import pygame  # noqa: E402
from entities.watermelon import Watermelon  # noqa: E402
from core.phases import phase_for_hp  # noqa: E402

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


def _broken(name, floor_data, rooms):
    """Un piso mal armado con su entrada y los mensajes que da Python (para que Godot repita el caso)."""
    return {"name": name, "floor": floor_data, "rooms": rooms, "errors": _errors_for(floor_data, rooms)}


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
    broken.append(_broken("sala_inalcanzable", {"name": "t", "start": [0, 0], "grid": [["a", None, "b"]]}, two_rooms))
    broken.append(_broken("inicio_inexistente", {"name": "t", "start": [5, 5], "grid": [["a"]]}, {"a": _blank_room()}))
    short = _blank_room()
    short["layout"] = short["layout"][:-1]
    broken.append(_broken("faltan_filas", {"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": short}))
    bad_char = _blank_room()
    bad_char["layout"][2] = bad_char["layout"][2][:3] + "Z" + bad_char["layout"][2][4:]
    broken.append(_broken("caracter_desconocido", {"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": bad_char}))
    border = _blank_room()
    border["layout"][0] = "#" * 3 + "." + "#" * (COLS - 4)
    broken.append(_broken("borde_abierto", {"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": border}))
    # Más pisos mal armados: enemigo pegado a la puerta, entrada ocupada, tipo inválido, sala faltante
    # y varios problemas a la vez (el validador los junta todos y los ordena).
    pegado = _blank_room()
    pegado["layout"][4] = "#" + "." * 11 + "S" + "." + "#"  # fila 4, col 12: justo donde aparece el jugador
    broken.append(_broken("enemigo_pegado", {"name": "t", "start": [0, 0], "grid": [["a", "b"]]}, {"a": pegado, "b": _blank_room()}))
    ocupada = _blank_room()
    ocupada["layout"][1] = "#" + "." * 6 + "X" + "." * 6 + "#"  # fila 1, col 7: la entrada de arriba
    broken.append(_broken("entrada_ocupada", {"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": ocupada}))
    tipo = _blank_room()
    tipo["type"] = "secreta"
    broken.append(_broken("tipo_invalido", {"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": tipo}))
    broken.append(_broken("sala_faltante", {"name": "t", "start": [0, 0], "grid": [["a", "zzz"]]}, {"a": _blank_room()}))
    ancho = _blank_room()
    ancho["layout"][3] = ancho["layout"][3] + "."
    ancho["layout"][5] = ancho["layout"][5][:-1]
    broken.append(_broken("filas_de_otro_ancho", {"name": "t", "start": [0, 0], "grid": [["a"]]}, {"a": ancho}))
    varios = _blank_room()
    varios["layout"][0] = "#" * 3 + "." + "#" * (COLS - 4)
    varios["layout"][2] = varios["layout"][2][:3] + "Z" + varios["layout"][2][4:]
    broken.append(_broken("varios_problemas", {"name": "t", "start": [9, 9], "grid": [["b", None, "a"]]}, {"a": varios, "b": _blank_room()}))

    # Errores al armar la estructura (antes de validar): el mensaje es el de la excepción de Python.
    init_cases = []
    for name, floor_data, rooms in [
        ("grilla_vacia", {"start": [0, 0], "grid": []}, {}),
        ("fila_no_lista", {"start": [0, 0], "grid": ["x"]}, {}),
        ("filas_desparejas", {"start": [0, 0], "grid": [["a"], ["a", "a"]]}, {}),
        ("inicio_mal", {"start": [0], "grid": [["a"]]}, {}),
        ("inicio_no_entero", {"start": [0, "x"], "grid": [["a"]]}, {}),
    ]:
        try:
            FloorLayout(floor_data, rooms)
            message = ""
        except ValueError as error:
            message = str(error)
        init_cases.append({"name": name, "floor": floor_data, "rooms": rooms, "error": message})

    return {
        "init_cases": init_cases,
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


# ---------- jugador y proyectiles ----------
class _Keys:
    """Estado mínimo de teclado para ejecutar Player.update sin cambiar el prototipo."""

    def __init__(self, pressed=()):
        self.pressed = set(pressed)

    def __getitem__(self, key):
        return int(key in self.pressed)


def player_snapshot(player, shots):
    return {
        "pos": [player.pos.x, player.pos.y],
        "velocity": [player.velocity.x, player.velocity.y],
        "rect": [player.rect.x, player.rect.y, player.rect.w, player.rect.h],
        "hp": player.hp,
        "alive": player.alive,
        "cooldown": player._cooldown,
        "invuln": player._invuln,
        "image_alpha": player.image.get_alpha(),
        "shots": [
            {
                "pos": [shot.pos.x, shot.pos.y],
                "velocity": [shot.velocity.x, shot.velocity.y],
                "rect": [shot.rect.x, shot.rect.y, shot.rect.w, shot.rect.h],
                "damage": shot.damage,
                "lifetime": shot.lifetime,
            }
            for shot in shots
        ],
    }


def player_golden():
    shots = pygame.sprite.Group()
    player = Player((100, 100), shots)
    walls = [pygame.Rect(0, 0, 480, 8), pygame.Rect(0, 280, 480, 8),
             pygame.Rect(0, 0, 8, 288), pygame.Rect(472, 0, 8, 288),
             pygame.Rect(150, 72, 20, 72)]
    schedule = []
    for tick in range(72):
        pressed = []
        if tick < 24:
            pressed.append(pygame.K_d)
        elif tick < 42:
            pressed.extend((pygame.K_d, pygame.K_s))
        elif tick < 54:
            pressed.append(pygame.K_s)
        elif tick < 66:
            pressed.append(pygame.K_a)
        if tick % 12 < 6:
            pressed.append(pygame.K_RIGHT)
        else:
            pressed.append(pygame.K_DOWN)
        schedule.append(pressed)

    trace = []
    sample_ticks = {0, 5, 11, 17, 23, 29, 35, 41, 47, 53, 59, 65, 71}
    for tick, pressed in enumerate(schedule):
        with __import__("unittest.mock", fromlist=["patch"]).patch("pygame.key.get_pressed", return_value=_Keys(pressed)):
            player.update(1 / 60, walls)
        shots.update(1 / 60)
        if tick in sample_ticks:
            trace.append({"tick": tick, **player_snapshot(player, shots)})

    # Daño, inmunidad y teletransporte se fotografían aparte para cubrir esos métodos puros.
    damage_player = Player((50, 50), pygame.sprite.Group())
    damage_player.take_damage(2)
    first_hit = {"hp": damage_player.hp, "invuln": damage_player._invuln}
    damage_player.take_damage(2)
    blocked_hit = {"hp": damage_player.hp, "invuln": damage_player._invuln}
    with __import__("unittest.mock", fromlist=["patch"]).patch("pygame.key.get_pressed", return_value=_Keys()):
        damage_player.update(0.5, [])
    after_half_second = {"hp": damage_player.hp, "invuln": damage_player._invuln, "image_alpha": damage_player.image.get_alpha()}
    damage_player.teleport((201.5, 80.5))
    teleported = {"pos": [damage_player.pos.x, damage_player.pos.y], "velocity": [damage_player.velocity.x, damage_player.velocity.y], "rect": [damage_player.rect.x, damage_player.rect.y, damage_player.rect.w, damage_player.rect.h]}

    # Proyectil con dirección diagonal para verificar normalización, rectángulo, tiempo y muerte.
    projectile = Projectile((10.5, 20.5), (3, 4), 100, 2, (255, 140, 140), size=7, lifetime=0.25)
    projectile_group = pygame.sprite.Group(projectile)
    projectile_trace = []
    for step in (0.1, 0.1, 0.1):
        projectile_group.update(step)
        projectile_trace.append({
            "pos": [projectile.pos.x, projectile.pos.y],
            "velocity": [projectile.velocity.x, projectile.velocity.y],
            "rect": [projectile.rect.x, projectile.rect.y, projectile.rect.w, projectile.rect.h],
            "damage": projectile.damage,
            "lifetime": projectile.lifetime,
            "alive": projectile.alive(),
        })

    return {
        "constants": {"size": Player.SIZE, "hp": player.max_hp, "speed": player.speed,
                      "acceleration": player.acceleration, "friction": player.friction,
                      "fire_rate": player.fire_rate, "shot_speed": player.shot_speed,
                      "shot_damage": player.damage},
        "movement": {"dt": [1, 60], "initial_pos": [100, 100], "walls": [[w.x, w.y, w.w, w.h] for w in walls], "trace": trace},
        "damage": {"first_hit": first_hit, "blocked_hit": blocked_hit,
                   "after_half_second": after_half_second, "teleported": teleported},
        "projectile": {"start": [10.5, 20.5], "direction": [3, 4], "speed": 100,
                       "size": 7, "lifetime_start": 0.25, "steps": [[1, 10]] * 3,
                       "trace": projectile_trace},
    }


def _enemy_snapshot(enemy, shots, extra=None):
    value = {
        "pos": [enemy.pos.x, enemy.pos.y],
        "rect": [enemy.rect.x, enemy.rect.y, enemy.rect.w, enemy.rect.h],
        "hp": enemy.hp,
        "alive": enemy.alive(),
        "flash": enemy._flash,
        "shots": [
            {"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y],
             "rect": [shot.rect.x, shot.rect.y, shot.rect.w, shot.rect.h],
             "damage": shot.damage, "lifetime": shot.lifetime}
            for shot in shots
        ],
    }
    if extra:
        value.update(extra)
    return value


def enemies_golden():
    dt = 1 / 60
    walls = [pygame.Rect(0, 0, 480, 8), pygame.Rect(0, 280, 480, 8),
             pygame.Rect(0, 0, 8, 288), pygame.Rect(472, 0, 8, 288),
             pygame.Rect(145, 70, 20, 70)]
    target = Player((220, 100), pygame.sprite.Group())
    trace = {}

    shots = pygame.sprite.Group()
    strawberry = Strawberry((100, 100), shots)
    enemies = pygame.sprite.Group(strawberry)
    strawberry_trace = []
    for tick in range(78):
        strawberry.update(dt, target, walls)
        shots.update(dt)
        if tick in {0, 35, 70, 71, 77}:
            strawberry_trace.append({"tick": tick, **_enemy_snapshot(strawberry, shots, {"cooldown": strawberry._cooldown})})
    trace["strawberry"] = {"start": [100, 100], "target": [220, 100], "dt": [1, 60], "trace": strawberry_trace}

    shots = pygame.sprite.Group()
    pineapple = Pineapple((100, 100), shots)
    enemies = pygame.sprite.Group(pineapple)
    pineapple_trace = []
    for tick in range(48):
        pineapple.update(dt, target, walls)
        shots.update(dt)
        if tick in {0, 5, 11, 17, 23, 31, 39, 47}:
            pineapple_trace.append({"tick": tick, **_enemy_snapshot(pineapple, shots)})
    trace["pineapple"] = {"start": [100, 100], "target": [220, 100], "dt": [1, 60],
                          "walls": [[w.x, w.y, w.w, w.h] for w in walls], "trace": pineapple_trace}

    banana_target = Player((220, 100), pygame.sprite.Group())
    shots = pygame.sprite.Group()
    banana = Banana((100, 100), shots)
    enemies = pygame.sprite.Group(banana)
    banana_trace = []
    for tick in range(54):
        banana.update(dt, banana_target, walls[:4])
        if tick in {0, 1, 5, 11, 17, 18, 23, 29, 35, 41, 47, 53}:
            banana_trace.append({"tick": tick, **_enemy_snapshot(banana, shots, {
                "charge_time": banana._charge_time,
                "charge_cooldown": banana._charge_cooldown,
                "charge_direction": [banana._charge_direction.x, banana._charge_direction.y],
            })})
    trace["banana"] = {"start": [100, 100], "target": [220, 100], "dt": [1, 60], "trace": banana_trace}

    pattern_cases = []
    for origin, destination, count, spread, speed in [
        ((20, 30), (120, 90), 5, 50, 115), ((4, -7), (4, -7), 1, 180, 12),
        ((0, 0), (-20, 4), 4, 90, 35),
    ]:
        projectiles = fan(origin, destination, count, spread, speed, 1, (250, 230, 120))
        pattern_cases.append({"origin": list(origin), "target": list(destination), "count": count,
                              "spread_deg": spread, "speed": speed,
                              "shots": [{"pos": [shot.pos.x, shot.pos.y],
                                         "velocity": [shot.velocity.x, shot.velocity.y],
                                         "rect": [shot.rect.x, shot.rect.y, shot.rect.w, shot.rect.h]}
                                        for shot in projectiles]})
    angle_cases = []
    for angle in (0, 45, 90, 180, -90, 270):
        shot = shot_at_angle((12, 18), angle, 80, 2, (255, 140, 140), size=5, lifetime=3.0)
        angle_cases.append({"angle": angle, "velocity": [shot.velocity.x, shot.velocity.y]})
    # Limón, gota y charco comparten grupos en ese mismo orden en Room.update.
    lemon_shots = pygame.sprite.Group()
    puddles = pygame.sprite.Group()
    lemon = Lemon((100, 100), lemon_shots, puddles)
    lemon_group = pygame.sprite.Group(lemon)
    lemon_trace = []
    for tick in range(120):
        lemon_group.update(dt, target, walls)
        lemon_shots.update(dt)
        puddles.update(dt)
        if tick in {0, 35, 70, 106, 107, 108, 119}:
            lemon_trace.append({"tick": tick, **_enemy_snapshot(lemon, lemon_shots, {
                "cooldown": lemon._cooldown,
                "puddles": [{"pos": [p.rect.centerx, p.rect.centery], "lifetime": p.lifetime,
                             "alpha": p.image.get_alpha()} for p in puddles],
            })})
    trace["lemon"] = {"start": [100, 100], "target": [220, 100], "dt": [1, 60],
                      "walls": [[w.x, w.y, w.w, w.h] for w in walls], "trace": lemon_trace}

    peach_shots = pygame.sprite.Group()
    peach = Peach((100, 100), peach_shots)
    peach_group = pygame.sprite.Group(peach)
    peach_trace = []
    for tick in range(72):
        peach_group.update(dt, Player((220, 136), pygame.sprite.Group()), walls)
        if tick in {0, 5, 11, 17, 23, 29, 35, 41, 47, 59, 71}:
            peach_trace.append({"tick": tick, **_enemy_snapshot(peach, peach_shots, {
                "velocity": [peach.velocity.x, peach.velocity.y], "aimed": peach._aimed})})
    trace["peach"] = {"start": [100, 100], "target": [220, 136], "dt": [1, 60],
                      "walls": [[w.x, w.y, w.w, w.h] for w in walls], "trace": peach_trace}

    direct_puddles = pygame.sprite.Group()
    drop = AcidDrop((10, 20), (3, 4), 100, direct_puddles)
    drop_group = pygame.sprite.Group(drop)
    direct_drop_trace = []
    for tick in range(14):
        drop_group.update(1 / 10)
        direct_puddles.update(1 / 10)
        if tick in {0, 1, 2, 5, 8, 13}:
            direct_drop_trace.append({
                "tick": tick, "pos": [drop.pos.x, drop.pos.y],
                "velocity": [drop.velocity.x, drop.velocity.y],
                "rect": [drop.rect.x, drop.rect.y, drop.rect.w, drop.rect.h],
                "lifetime": drop.lifetime, "trail_timer": drop._trail_timer,
                "alive": drop.alive(),
                "puddles": [{"pos": [p.rect.centerx, p.rect.centery], "lifetime": p.lifetime,
                             "alpha": p.image.get_alpha()} for p in direct_puddles],
            })

    puddle = AcidPuddle((40, 50))
    puddle_group = pygame.sprite.Group(puddle)
    puddle_trace = [{"lifetime": puddle.lifetime, "alpha": puddle.image.get_alpha(), "alive": puddle.alive()}]
    for step in (0.5, 1.0, 1.0, 0.2):
        puddle_group.update(step)
        puddle_trace.append({"lifetime": puddle.lifetime, "alpha": puddle.image.get_alpha(), "alive": puddle.alive()})

    return {"trace": trace, "patterns": {"fans": pattern_cases, "angles": angle_cases},
            "acid_drop": {"start": [10, 20], "direction": [3, 4], "speed": 100,
                          "dt": [1, 10], "trace": direct_drop_trace},
            "acid_puddle": {"start": [40, 50], "lifetime": 2.6,
                            "steps": [0.5, 1.0, 1.0, 0.2], "trace": puddle_trace}}


class _BossRoom:
    def __init__(self, player=None, layout=None):
        self.current_player = player
        self.layout = layout or (["#" * 15] + ["#" + "." * 13 + "#" for _ in range(7)] + ["#" * 15])
        self.acid_puddles = pygame.sprite.Group()
        self.pending_dialogues = []
        self.spawned = []

    def say(self, key):
        self.pending_dialogues.append(key)

    def spawn_enemy(self, kind, pos):
        self.spawned.append({"kind": kind, "pos": list(pos)})


def _boss_snapshot(boss, shots, room):
    return {
        "phase": boss.phase, "state": boss.state, "timer": boss.timer, "attack": boss.attack,
        "pos": [boss.pos.x, boss.pos.y], "rect": [boss.rect.x, boss.rect.y, boss.rect.w, boss.rect.h],
        "hp": boss.hp, "alive": boss.alive(), "grace": boss.grace,
        "velocity": [boss.velocity.x, boss.velocity.y], "bounces": boss.bounces,
        "roll_bounces_target": boss.roll_bounces_target, "flash": boss._flash,
        "color": list(boss.color), "blink": boss._blink,
        "spiral_angle": boss._spiral_angle, "spiral_left": boss._spiral_left,
        "spiral_tick": boss._spiral_tick, "spiral_next": boss._spiral_next,
        "juice_timer": boss._juice_timer,
        "shots": [{"pos": [shot.pos.x, shot.pos.y], "velocity": [shot.velocity.x, shot.velocity.y],
                   "rect": [shot.rect.x, shot.rect.y, shot.rect.w, shot.rect.h],
                   "damage": shot.damage, "lifetime": shot.lifetime} for shot in shots],
        "puddles": [{"pos": [p.rect.centerx, p.rect.centery], "lifetime": p.lifetime,
                     "alpha": p.image.get_alpha()} for p in room.acid_puddles],
        "dialogues": list(room.pending_dialogues),
        "spawned": room.spawned,
    }


def boss_golden():
    dt = 1 / 60
    walls = [pygame.Rect(0, 0, 480, 8), pygame.Rect(0, 280, 480, 8),
             pygame.Rect(0, 0, 8, 288), pygame.Rect(472, 0, 8, 288)]
    trace = {}

    shots = pygame.sprite.Group()
    player = Player((100, 144), pygame.sprite.Group())
    room = _BossRoom(player)
    boss = Watermelon((240, 144), shots)
    boss.attach(room)
    boss_group = pygame.sprite.Group(boss)
    phase1_trace = []
    for tick in range(125):
        boss_group.update(dt, player, walls)
        shots.update(dt)
        if tick in {0, 1, 30, 60, 83, 90, 112, 113, 119, 124}:
            phase1_trace.append({"tick": tick, **_boss_snapshot(boss, shots, room)})
    trace["phase1"] = {"player": [100, 144], "trace": phase1_trace}

    random.seed(20261018)
    shots = pygame.sprite.Group()
    player = Player((400, 144), pygame.sprite.Group())
    room = _BossRoom(player)
    boss = Watermelon((240, 144), shots)
    boss.attach(room)
    boss.phase = 2
    boss.hp = 70
    boss.grace = 0.0
    boss.state = "telegraph"
    boss.attack = "roll"
    boss.timer = dt
    boss_group = pygame.sprite.Group(boss)
    roll_trace = []
    target_bounces = None
    for tick in range(140):
        boss_group.update(dt, player, walls)
        if target_bounces is None and boss.state == "roll":
            target_bounces = boss.roll_bounces_target
        shots.update(dt)
        if tick in {0, 1, 20, 40, 60, 63, 64, 80, 100, 127, 128, 139}:
            roll_trace.append({"tick": tick, **_boss_snapshot(boss, shots, room)})
    trace["phase2_roll"] = {"player": [400, 144], "roll_bounces_target": target_bounces,
                            "trace": roll_trace}

    shots = pygame.sprite.Group()
    player = Player((100, 100), pygame.sprite.Group())
    room = _BossRoom(player)
    boss = Watermelon((240, 144), shots)
    boss.attach(room)
    boss.phase = 2
    boss.hp = 30
    boss.grace = 0.0
    shots.add(Projectile((50, 50), (1, 0), 20, 1, (250, 230, 120)))
    room.acid_puddles.add(AcidPuddle((60, 60)))
    boss_group = pygame.sprite.Group(boss)
    phase3_trace = []
    for tick in range(8):
        boss_group.update(dt, player, walls)
        shots.update(dt)
        room.acid_puddles.update(dt)
        phase3_trace.append({"tick": tick, **_boss_snapshot(boss, shots, room)})
    trace["phase3_start"] = {"player": [100, 100], "trace": phase3_trace}

    # Ataque espiral aislado para capturar ángulos, cadencia, final y retorno a walk.
    shots = pygame.sprite.Group()
    player = Player((100, 144), pygame.sprite.Group())
    room = _BossRoom(player)
    boss = Watermelon((240, 144), shots)
    boss.attach(room)
    boss.phase = 3
    boss.hp = 20
    boss.grace = 0.0
    boss.state = "telegraph"
    boss.attack = "spiral"
    boss.timer = 0.01
    boss_group = pygame.sprite.Group(boss)
    spiral_trace = []
    for tick in range(20):
        boss_group.update(0.1, player, walls)
        shots.update(0.1)
        if tick in {0, 1, 2, 5, 10, 19}:
            spiral_trace.append({"tick": tick, **_boss_snapshot(boss, shots, room)})
    trace["phase3_spiral"] = {"player": [100, 144], "trace": spiral_trace}

    return {"phase_dialogue": {"1": "sandia_intro", "2": "sandia_fase2", "3": "sandia_fase3"},
            "death_dialogue": "sandia_death", "trace": trace,
            "damage": {"phase_for_hp": [phase_for_hp(70, 110, [0.66, 0.33]), phase_for_hp(30, 110, [0.66, 0.33])],
                       "hp_after_phase3_stunned_hit": 27.2}}


FILES = {"phases.json": phases, "layout.json": layout, "dialogue.json": dialogue,
         "player.json": player_golden, "enemies.json": enemies_golden, "boss.json": boss_golden}


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
