from core.controls import CONFIRM_KEYS, PAUSE_KEY, move_cursor_with_key
from states.base import State
from states.cursor import MenuCursor

PAUSE_OPTIONS = ("Continuar", "Reiniciar", "Salir")


class PauseState(State):
    """Menú de pausa. Se dibuja encima de lo que esté abajo, que queda congelado."""

    transparent = True
    pauses_below = True

    def __init__(self):
        self.cursor = MenuCursor(len(PAUSE_OPTIONS))

    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.states.pop()
        elif move_cursor_with_key(self.cursor, key):
            pass
        elif key in CONFIRM_KEYS:
            if self.cursor.index == 0:
                game.states.pop()
            elif self.cursor.index == 1:
                game.start_run()
            else:
                game.quit()

    def draw(self, game):
        game.menu_view.draw_pause(game, PAUSE_OPTIONS, self.cursor.index)
