"""Pantalla de game over (usa los controles del juego, así que necesita pygame)."""

import unittest

try:
    import pygame
    HAS_PYGAME = True
except ImportError:  # pragma: no cover
    HAS_PYGAME = False


@unittest.skipUnless(HAS_PYGAME, "necesita pygame")
class GameOverTests(unittest.TestCase):
    def setUp(self):
        from states.gameover import GameOverState

        self.calls = []

        class FakeGame:
            def start_run(inner):
                self.calls.append("retry")

            def return_to_menu(inner):
                self.calls.append("menu")

        self.game = FakeGame()
        self.state = GameOverState()

    def test_enter_retries_by_default(self):
        self.state.handle_key(self.game, pygame.K_RETURN)
        self.assertEqual(self.calls, ["retry"])

    def test_down_then_enter_goes_to_menu(self):
        self.state.handle_key(self.game, pygame.K_DOWN)
        self.state.handle_key(self.game, pygame.K_SPACE)
        self.assertEqual(self.calls, ["menu"])

    def test_escape_does_nothing(self):
        self.state.handle_key(self.game, pygame.K_ESCAPE)
        self.assertEqual(self.calls, [])

    def test_tap_on_a_row_chooses_it(self):
        from states.gameover import FIRST_Y, SPACING
        self.state.handle_touch(self.game, "tap", (240, FIRST_Y + SPACING))
        self.assertEqual(self.calls, ["menu"])

    def test_tap_elsewhere_does_nothing(self):
        self.state.handle_touch(self.game, "tap", (10, 10))
        self.state.handle_touch(self.game, "pause", None)
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
