import pygame

from core import settings as S
from core.controls import CONFIRM_KEYS, PAUSE_KEY, move_cursor_with_key
from states.base import State
from states.cursor import MenuCursor, row_at

MENU_OPTIONS = ("Jugar", "Opciones", "Salir")

# Filas del menú principal (para tocarlas con el dedo)
MENU_FIRST_Y = 126
MENU_SPACING = 34
MENU_TOLERANCE = 16
# Entradas de opciones que se cambian con izquierda/derecha
ADJUSTABLE = ("fps", "move", "aim", "dynamic", "travel", "size")
LEFT_KEYS = (pygame.K_LEFT, pygame.K_a)
RIGHT_KEYS = (pygame.K_RIGHT, pygame.K_d)


def _row_hit(position, first_y, spacing, count, tolerance):
    return row_at(position, first_y, spacing, count, tolerance, S.SCREEN_W // 2, S.SCREEN_W * 0.44)


class MenuState(State):
    """Menú principal."""

    def __init__(self, game):
        self.cursor = MenuCursor(len(MENU_OPTIONS), game.idle_selection())

    def resume(self, game):
        # Al volver de Opciones no queda nada resaltado en pantalla táctil
        self.cursor.index = game.idle_selection()

    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.quit()
        elif move_cursor_with_key(self.cursor, key):
            pass
        elif key in CONFIRM_KEYS:
            self.choose(game)

    def handle_pointer(self, game, position):
        self.cursor.index = self._row_at(position)

    def handle_touch(self, game, action, position):
        if action == "tap":
            self.cursor.index = self._row_at(position)
            if self.cursor.index is not None:
                self.choose(game)

    def choose(self, game):
        if self.cursor.index is None:
            self.cursor.index = 0
        if self.cursor.index == 0:
            game.start_run()
        elif self.cursor.index == 1:
            game.open_options()
        else:
            game.quit()

    @staticmethod
    def _row_at(position):
        return _row_hit(position, MENU_FIRST_Y, MENU_SPACING, len(MENU_OPTIONS), MENU_TOLERANCE)

    def draw(self, game):
        game.menu_view.draw_main(game, MENU_OPTIONS, self.cursor.index)


class OptionsState(State):
    """Opciones: se abre encima del menú principal y vuelve a él al salir.

    Las filas salen de `game.option_entries()` (cambian según sea escritorio o móvil).
    """

    def __init__(self, game):
        self.cursor = MenuCursor(len(game.option_entries()), game.idle_selection())

    def handle_key(self, game, key):
        entries = game.option_entries()
        if key == PAUSE_KEY:
            game.states.pop()
        elif move_cursor_with_key(self.cursor, key):
            pass
        elif key in LEFT_KEYS + RIGHT_KEYS + CONFIRM_KEYS:
            if self.cursor.index is None:
                self.cursor.index = 0
            name = entries[self.cursor.index][0]
            if key in LEFT_KEYS:
                if name in ADJUSTABLE:
                    game.change_option(name, -1)
            elif key in RIGHT_KEYS:
                if name in ADJUSTABLE:
                    game.change_option(name, 1)
            else:
                self.choose(game, name)

    def handle_pointer(self, game, position):
        self.cursor.index = self._row_at(game, position)

    def handle_touch(self, game, action, position):
        if action == "tap":
            self.cursor.index = self._row_at(game, position)
            if self.cursor.index is not None:
                self.choose(game, game.option_entries()[self.cursor.index][0])

    def choose(self, game, name):
        if name == "fullscreen":
            game.toggle_fullscreen()
        elif name == "debug":
            game.toggle_debug()
        elif name in ADJUSTABLE:
            game.change_option(name, 1)
        else:  # "back"
            game.states.pop()

    @staticmethod
    def _row_at(game, position):
        spacing = 20 if game.is_mobile else 30
        tolerance = 10 if game.is_mobile else 15
        return _row_hit(position, game.option_row_y(0), spacing, len(game.option_entries()), tolerance)

    def draw(self, game):
        game.menu_view.draw_options(game, [text for _, text in game.option_entries()], self.cursor.index)
