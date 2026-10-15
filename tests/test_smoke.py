"""Corre la partida de humo (`tests/smoke_game.py`) con pygame real, en otro proceso."""

import subprocess
import sys
import unittest
from pathlib import Path

try:
    import pygame  # noqa: F401
    HAS_PYGAME = hasattr(pygame, "Surface") and hasattr(pygame, "display")
except ImportError:  # pragma: no cover
    HAS_PYGAME = False

ROOT = Path(__file__).resolve().parent.parent


@unittest.skipUnless(HAS_PYGAME, "necesita pygame")
class SmokeGameTest(unittest.TestCase):
    def test_a_full_session_runs_without_errors(self):
        # Otro proceso: así pygame.init/quit y las variables de entorno no pisan al resto de los tests
        result = subprocess.run(
            [sys.executable, "-m", "tests.smoke_game"],
            cwd=ROOT, capture_output=True, text=True, timeout=300,
        )
        self.assertEqual(
            result.returncode, 0,
            f"\n--- salida ---\n{result.stdout}\n--- errores ---\n{result.stderr}",
        )


if __name__ == "__main__":
    unittest.main()
