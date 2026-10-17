"""Los valores dorados de godot/tests/golden/ tienen que estar al día con el código Python.

Si falla, corre `python tools/export_golden.py` y commitea los archivos que cambien: así Godot
se compara siempre contra lo que Python calcula hoy (ver docs/migracion-godot.md, sección 7).
"""

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import export_golden  # noqa: E402


class GoldenTests(unittest.TestCase):
    def test_los_valores_dorados_estan_al_dia(self):
        for name, build in export_golden.FILES.items():
            with self.subTest(archivo=name):
                path = export_golden.GOLDEN_DIR / name
                self.assertTrue(path.exists(), f"Falta {name}: corre python tools/export_golden.py")
                self.assertEqual(
                    path.read_text(encoding="utf-8"),
                    export_golden.render(build()),
                    f"{name} está desactualizado: corre python tools/export_golden.py",
                )


if __name__ == "__main__":
    unittest.main()
