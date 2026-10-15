"""Partida de humo con el juego real y pygame de verdad, sin ventana.

Abre `Game`, recorre los menús, juega, pausa, lee diálogos, pelea con el jefe y
muere, mandando teclas por la cola de eventos como si las apretara una persona.
No juzga el balance ni cómo se ve: solo que nada se rompa y que las pantallas
cambien como deben.

    python -m tests.smoke_game

(En una máquina sin pantalla: SDL_VIDEODRIVER=dummy; ya se configura solo.)
Lo corre `tests/test_smoke.py`, y por lo tanto el CI de GitHub.
"""

import os
import sys
import tempfile

# Sin ventana, sin sonido y sin tocar las preferencias reales de quien lo corra
os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"
_home = tempfile.mkdtemp(prefix="forestapple-smoke-")
for _var in ("HOME", "APPDATA", "XDG_CONFIG_HOME"):
    os.environ[_var] = _home

import pygame  # noqa: E402

from core import settings as S  # noqa: E402
from core.game import Game  # noqa: E402

DT = 1 / 60
failures = []


def check(condition, message):
    print(("ok   " if condition else "FAIL ") + message, flush=True)
    if not condition:
        failures.append(message)


def names(game):
    return [type(state).__name__ for state in game.states.states]


def frame(game, count=1):
    for _ in range(count):
        game.handle_events()
        game.tick(DT)


def press(game, key):
    pygame.event.post(pygame.event.Event(pygame.KEYDOWN, key=key))
    frame(game)


def pump(game, frames, heal=True):
    """Avanza `frames` cuadros; pasa los diálogos que aparezcan y mantiene viva a la manzana."""
    for _ in range(frames):
        if heal:
            game.player.hp = game.player.max_hp
        if names(game)[-1] == "DialogueState":
            press(game, pygame.K_SPACE)
        else:
            frame(game)


def run():
    game = Game()

    # ---------- menús ----------
    check(names(game) == ["MenuState"], "el juego arranca en el menú")
    frame(game, 5)
    press(game, pygame.K_DOWN)
    press(game, pygame.K_RETURN)
    check(names(game) == ["MenuState", "OptionsState"], "Opciones se abre")
    frame(game, 3)
    press(game, pygame.K_ESCAPE)
    check(names(game) == ["MenuState"], "Esc vuelve al menú")

    # ---------- partida ----------
    press(game, pygame.K_UP)    # el cursor da la vuelta hasta "Salir"...
    press(game, pygame.K_DOWN)  # ...y vuelve a "Jugar"
    press(game, pygame.K_RETURN)
    check(names(game) == ["PlayState"], "Jugar empieza la partida")
    frame(game, 120)
    check(game.player.alive, "la manzana sigue viva en la sala inicial")

    # ---------- pausa ----------
    press(game, pygame.K_ESCAPE)
    check(names(game) == ["PlayState", "PauseState"], "Esc pausa")
    frame(game, 10)
    press(game, pygame.K_ESCAPE)
    check(names(game) == ["PlayState"], "Esc continúa")
    press(game, pygame.K_ESCAPE)
    press(game, pygame.K_DOWN)
    press(game, pygame.K_RETURN)
    check(names(game) == ["PlayState"], "Reiniciar deja una partida nueva")
    press(game, pygame.K_ESCAPE)
    press(game, pygame.K_DOWN)
    press(game, pygame.K_DOWN)
    press(game, pygame.K_RETURN)
    check(names(game) == ["MenuState"], "Salir de la pausa vuelve al menú")

    # ---------- diálogos ----------
    press(game, pygame.K_RETURN)
    check(names(game) == ["PlayState"], "Jugar otra vez")
    closed = []
    game.say("sandia_fase3", on_close=lambda: closed.append(True))
    frame(game, 2)
    check(names(game) == ["PlayState", "DialogueState"], "se abre un diálogo (con pausas y velocidad)")
    press(game, pygame.K_ESCAPE)
    check(names(game) == ["PlayState", "DialogueState", "PauseState"], "se puede pausar durante un diálogo")
    press(game, pygame.K_ESCAPE)
    for _ in range(60):
        if "DialogueState" not in names(game):
            break
        frame(game, 90)  # deja escribir la línea (y sus pausas)
        press(game, pygame.K_SPACE)
    check(names(game) == ["PlayState"] and closed == [True], "el diálogo termina y avisa")

    # ---------- todas las salas del piso 1 ----------
    game.start_run()
    frame(game, 2)
    floor = game.floor
    boss_cell = None
    for cell in sorted(floor.layout.cells):
        floor.pos = cell
        floor.visited.add(cell)
        room = floor.current_room
        room.enter()
        game.player_shots.empty()
        game.player.teleport((S.SCREEN_W // 2, S.SCREEN_H // 2))
        if room.kind == "boss":
            boss_cell = cell
            continue
        pump(game, 150)
    check(boss_cell is not None, "el piso tiene sala del jefe")
    check(names(game) == ["PlayState"], "recorrer las salas no deja pantallas abiertas")

    # ---------- el jefe ----------
    floor.pos = boss_cell
    room = floor.current_room  # ya se la hizo entrar en el recorrido de arriba
    game.player.teleport((S.SCREEN_W // 2, S.SCREEN_H - 2 * S.TILE))
    boss = next((e for e in room.enemies if getattr(e, "is_boss", False)), None)
    check(boss is not None, "la sandía está en su sala")
    if boss is not None:
        phases_seen = set()
        for step in range(4000):
            pump(game, 1)
            if boss.alive():
                phases_seen.add(getattr(boss, "phase", None))
                if step % 15 == 0:
                    boss.take_damage(boss.max_hp * 0.08)
            elif not room.pending_dialogues and names(game) == ["PlayState"]:
                break
        check(not boss.alive(), "la sandía muere")
        for enemy in list(room.enemies):  # los refuerzos de la fase 3, si quedaron
            enemy.kill()
        pump(game, 120)
        check(room.cleared, "la sala del jefe queda despejada")
        check(len(phases_seen) >= 2, "la sandía pasó por varias fases")
        check(names(game) == ["PlayState"], "sin diálogos pendientes al terminar")

    # ---------- game over ----------
    game.start_run()
    frame(game, 5)
    game.player.hp = 0
    frame(game, 150)
    check(names(game) == ["PlayState", "GameOverState"], "al morir se abre el game over")
    press(game, pygame.K_RETURN)
    check(names(game) == ["PlayState"] and game.player.alive, "Reintentar empieza de nuevo")
    game.player.hp = 0
    frame(game, 150)
    press(game, pygame.K_DOWN)
    press(game, pygame.K_RETURN)
    check(names(game) == ["MenuState"], "Salir al menú desde el game over")

    # ---------- cerrar ----------
    pygame.event.post(pygame.event.Event(pygame.QUIT))
    frame(game)
    check(game.running is False, "cerrar la ventana termina el juego")


if __name__ == "__main__":
    run()
    pygame.quit()
    if failures:
        print(f"\n{len(failures)} comprobación(es) fallaron:", file=sys.stderr)
        for message in failures:
            print(f"  - {message}", file=sys.stderr)
        sys.exit(1)
    print("\nPartida de humo: todo bien")
