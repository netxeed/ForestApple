from core import settings as S
from core.controls import CONFIRM_KEYS, PAUSE_KEY, move_cursor_with_key
from states.base import State
from states.cursor import MenuCursor

MENU_OPTIONS = ("Jugar", "Opciones", "Salir")


class MenuState(State):
    """Menú principal."""

    def __init__(self):
        self.cursor = MenuCursor(len(MENU_OPTIONS))

    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.quit()
        elif move_cursor_with_key(self.cursor, key):
            pass
        elif key in CONFIRM_KEYS:
            if self.cursor.index == 0:
                game.start_run()
            elif self.cursor.index == 1:
                game.open_options()
            else:
                game.quit()

    def draw(self, game):
        game.menu_view.draw_main(game, MENU_OPTIONS, self.cursor.index)


class OptionsState(State):
    """Opciones: se abre encima del menú principal y vuelve a él al salir."""

    ROWS = 3

    def __init__(self):
        self.cursor = MenuCursor(self.ROWS)

    def labels(self, game):
        return (
            f"Pantalla completa: {'Sí' if game.fullscreen else 'No'}",
            f"Modo debug: {'Sí' if S.DEBUG_KEYS else 'No'}",
            "Volver",
        )

    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.states.pop()
        elif move_cursor_with_key(self.cursor, key):
            pass
        elif key in CONFIRM_KEYS:
            if self.cursor.index == 0:
                game.toggle_fullscreen()
            elif self.cursor.index == 1:
                S.DEBUG_KEYS = not S.DEBUG_KEYS
            else:
                game.states.pop()

    def draw(self, game):
        game.menu_view.draw_options(game, self.labels(game), self.cursor.index)
