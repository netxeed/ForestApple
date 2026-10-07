from core import settings as S
from core.controls import CONFIRM_KEYS, PAUSE_KEY, move_cursor_with_key
from states.base import State
from states.cursor import MenuCursor

PAUSE_OPTIONS = ("Continuar", "Reiniciar", "Salir")


class PauseState(State):
    """Menú de pausa. Se dibuja encima de lo que esté abajo, que queda congelado."""

    transparent = True
    pauses_below = True
    touch_overlay = False  # sin botones táctiles mientras está la pausa

    def __init__(self):
        self.cursor = MenuCursor(len(PAUSE_OPTIONS))

    def handle_key(self, game, key):
        if key == PAUSE_KEY:
            game.states.pop()
        elif move_cursor_with_key(self.cursor, key):
            pass
        elif key in CONFIRM_KEYS:
            self.choose(game)

    def handle_touch(self, game, action, position):
        if action == "pause":
            game.states.pop()
        elif action == "tap" and position is not None:
            top = S.SCREEN_H // 2 - 12
            if top - 18 <= position[1] <= top + 80:
                self.cursor.index = max(0, min(len(PAUSE_OPTIONS) - 1, round((position[1] - top) / 32)))
                self.choose(game)

    def choose(self, game):
        if self.cursor.index == 0:
            game.states.pop()
        elif self.cursor.index == 1:
            game.start_run()
        else:
            game.return_to_menu()

    def draw(self, game):
        game.menu_view.draw_pause(game, PAUSE_OPTIONS, self.cursor.index)
