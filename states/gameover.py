from core import settings as S
from core.controls import CONFIRM_KEYS, move_cursor_with_key
from states.base import State
from states.cursor import MenuCursor, row_at

GAME_OVER_OPTIONS = ("Reintentar", "Salir al menú")

# Filas (para tocarlas con el dedo)
FIRST_Y = S.SCREEN_H // 2 + 26
SPACING = 32


class GameOverState(State):
    """Se abre encima de la partida cuando el jugador muere. Reintentar o volver al menú."""

    transparent = True
    pauses_below = True
    touch_overlay = False

    def __init__(self):
        self.cursor = MenuCursor(len(GAME_OVER_OPTIONS))

    def handle_key(self, game, key):
        # Esc no hace nada acá: no hay nada que pausar
        if move_cursor_with_key(self.cursor, key):
            pass
        elif key in CONFIRM_KEYS:
            self.choose(game)

    def handle_touch(self, game, action, position):
        if action != "tap":
            return
        index = row_at(position, FIRST_Y, SPACING, len(GAME_OVER_OPTIONS), 16, S.SCREEN_W // 2, S.SCREEN_W * 0.44)
        if index is not None:
            self.cursor.index = index
            self.choose(game)

    def choose(self, game):
        if self.cursor.index == 0:
            game.start_run()
        else:
            game.return_to_menu()

    def draw(self, game):
        game.menu_view.draw_game_over(game, GAME_OVER_OPTIONS, self.cursor.index, FIRST_Y, SPACING)
